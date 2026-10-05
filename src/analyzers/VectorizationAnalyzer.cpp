#include "analyzer/VectorizationAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/IRNames.h"
#include "analyzer/LLVMAnalyses.h"
#include "analyzer/LoopCatalog.h"
#include "analyzer/MemoryAccessAnalyzer.h"
#include "analyzer/VectorizerOracle.h"

#include <llvm/ADT/MapVector.h>
#include <llvm/Analysis/IVDescriptors.h>
#include <llvm/Analysis/ScalarEvolutionExpressions.h>
#include <llvm/Analysis/ValueTracking.h>
#include <llvm/Analysis/VectorUtils.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/IntrinsicInst.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Operator.h>

#include <set>

namespace analyzer {

namespace {

enum class Blocker {
  Call,
  Instruction,
  EarlyExit,
  ControlFlow,
  ArrayBounds,
  Recurrence,
  MemoryDependence,
  FloatOrder,
  CostModel,
  Disabled,
  Other,
};

/// Classify a vectorizer remark by its stable remark name. Message text is
/// only a fallback for names we haven't mapped.
bool classify(const VectorizerRemark& R, Blocker* out) {
  static const std::map<std::string, Blocker> byName = {
      {"CantVectorizeLibcall", Blocker::Call},
      {"CantVectorizeCall", Blocker::Call},
      {"CantVectorizeInstruction", Blocker::Instruction},
      {"CantComputeNumberOfIterations", Blocker::EarlyExit},
      {"CFGNotUnderstood", Blocker::ControlFlow},
      {"NoCFGForSelect", Blocker::ControlFlow},
      {"LoopContainsSwitch", Blocker::ControlFlow},
      {"CantIdentifyArrayBounds", Blocker::ArrayBounds},
      {"NonReductionValueUsedOutsideLoop", Blocker::Recurrence},
      {"UnsafeDep", Blocker::MemoryDependence},
      {"UnsafeMemDep", Blocker::MemoryDependence},
      {"CantCheckMemDepsAtRunTime", Blocker::MemoryDependence},
      {"CantReorderMemOps", Blocker::MemoryDependence},
      {"CantReorderFPOps", Blocker::FloatOrder},
      {"VectorizationNotBeneficial", Blocker::CostModel},
      {"AllDisabled", Blocker::Disabled},
      {"MissedExplicitlyDisabled", Blocker::Disabled},
  };
  const std::string& n = R.name;
  if (n == "MissedDetails" || n.rfind("Interleav", 0) == 0 ||
      n == "Vectorized")
    return false;  // Generic "loop not vectorized" / interleave-only notes.
  auto it = byName.find(n);
  if (it != byName.end()) {
    *out = it->second;
    return true;
  }
  const std::string& m = R.message;
  auto has = [&](const char* s) { return m.find(s) != std::string::npos; };
  if (has("call instruction"))
    *out = Blocker::Call;
  else if (has("control flow") || has("switch"))
    *out = Blocker::ControlFlow;
  else if (has("could not be identified as reduction"))
    *out = Blocker::Recurrence;
  else if (has("dependen") || has("reorder memory"))
    *out = Blocker::MemoryDependence;
  else if (has("floating-point"))
    *out = Blocker::FloatOrder;
  else if (has("explicitly disabled"))
    *out = Blocker::Disabled;
  else
    *out = Blocker::Other;
  return true;
}

/// LLVM messages can contain line breaks; evidence lines can't.
std::string oneLine(std::string s) {
  for (char& c : s)
    if (c == '\n')
      c = ' ';
  return s;
}

/// "s.05" -> "s": clang names SSA values after the source variable.
/// Returns "<expr>" for compiler temporaries ("add5", "mul", "vec.phi").
std::string sourceVarName(const llvm::Value* V) {
  std::string n = valueName(V);
  size_t dot = n.find('.');
  if (dot != std::string::npos && dot > 0)
    n = n.substr(0, dot);
  std::string stem = n.substr(0, n.find_first_of("0123456789"));
  static const char* temporaries[] = {
      "",    "add", "sub",   "mul",  "div", "conv",      "call", "tmp",
      "phi", "vec", "index", "bin",  "rdx", "induction", "wide", "broadcast",
      "red", "res", "lcssa", "epil", "unr", "prol"};
  for (const char* t : temporaries)
    if (stem == t)
      return "<expr>";
  return n;
}

bool derivesFromLoadIn(const llvm::Value* V, const llvm::Loop* L,
                       unsigned depth = 0) {
  const auto* I = llvm::dyn_cast<llvm::Instruction>(V);
  if (!I || !L->contains(I) || depth > 8)
    return false;
  if (llvm::isa<llvm::LoadInst>(I))
    return true;
  if (llvm::isa<llvm::PHINode>(I))
    return false;
  for (const llvm::Value* Op : I->operands())
    if (derivesFromLoadIn(Op, L, depth + 1))
      return true;
  return false;
}

/// Does V (inside L) use `phi`, directly or through other instructions?
bool dependsOn(const llvm::Value* V, const llvm::PHINode* phi,
               const llvm::Loop* L, unsigned depth = 0) {
  if (V == phi)
    return true;
  const auto* I = llvm::dyn_cast<llvm::Instruction>(V);
  if (!I || !L->contains(I) || depth > 8 || llvm::isa<llvm::PHINode>(I))
    return false;
  for (const llvm::Value* Op : I->operands())
    if (dependsOn(Op, phi, L, depth + 1))
      return true;
  return false;
}

std::string joinNames(const std::set<std::string>& names) {
  std::string out;
  for (const auto& n : names)
    out += (out.empty() ? "" : ", ") + n;
  return out;
}

/// The pointer argument a pointer comes from, if it lacks `noalias`.
const llvm::Argument* unrestrictedArg(const llvm::Value* ptr) {
  const auto* A =
      llvm::dyn_cast<llvm::Argument>(llvm::getUnderlyingObject(ptr));
  return A && !A->hasNoAliasAttr() ? A : nullptr;
}

/// Pointer parameters without `noalias` that the loop accesses.
std::set<std::string> unrestrictedParams(llvm::Loop* L) {
  std::set<std::string> out;
  for (llvm::BasicBlock* BB : L->blocks())
    for (llvm::Instruction& I : *BB)
      if (const llvm::Value* ptr = llvm::getLoadStorePointerOperand(&I))
        if (const llvm::Argument* A = unrestrictedArg(ptr))
          out.insert(valueName(A));
  return out;
}

std::string restrictAdvice(const std::set<std::string>& params) {
  return "Add `restrict` (C) / `__restrict` (C++) to " + joinNames(params) +
         " if they never overlap.";
}

std::string targetCPU(llvm::Function& F) {
  llvm::Attribute A = F.getFnAttribute("target-cpu");
  return A.isValid() ? A.getValueAsString().str() : "";
}

/// IV/reduction descriptors require a preheader and a single latch.
bool hasCanonicalShape(const llvm::Loop* L) {
  return L->getLoopPreheader() && L->getLoopLatch();
}

struct Explanation {
  std::string message;
  std::vector<std::string> evidence;
  std::vector<std::string> suggestions;
  std::string basis;
};

/// Everything an explanation needs about the loop being explained.
struct LoopCtx {
  FunctionAnalyses& FA;
  const LogicalLoop& LL;
  llvm::Loop* L;  // The scalar copy analyses run on.
  const VectorizerOracle* oracle;
};

// --- Checking a suggested fix ----------------------------------------------

/// Result of rerunning the vectorizer with a suggested change applied.
struct FixCheck {
  enum class Outcome { Works, DoesNotWork, Unchecked };
  Outcome outcome = Outcome::Unchecked;
  std::string message;  // What the vectorizer said with the change.

  bool works() const {
    return outcome == Outcome::Works;
  }
  bool fails() const {
    return outcome == Outcome::DoesNotWork;
  }
};

FixCheck checkFix(const LoopCtx& c, const VectorizerOracle::Change& change) {
  FixCheck out;
  if (!c.oracle || !c.LL.oracleCopy)
    return out;
  VectorizerOracle::Retry r = c.oracle->retry(c.FA.function(), c.LL, change);
  out.outcome = r.vectorized ? FixCheck::Outcome::Works
                             : FixCheck::Outcome::DoesNotWork;
  out.message = oneLine(r.message);
  return out;
}

/// Mark the named pointer parameters `noalias` (what `restrict` does).
FixCheck checkRestrict(const LoopCtx& c, const std::set<std::string>& params) {
  return checkFix(c, [&](llvm::Function& F, llvm::Loop&) {
    for (llvm::Argument& A : F.args())
      if (A.getType()->isPointerTy() && params.count(valueName(&A)))
        A.addAttr(llvm::Attribute::NoAlias);
  });
}

/// Allow reassociation of the loop's floating-point operations (what
/// `#pragma clang fp reassociate(on)` in the loop body does).
FixCheck checkReassociate(const LoopCtx& c) {
  return checkFix(c, [](llvm::Function&, llvm::Loop& L) {
    for (llvm::BasicBlock* BB : L.blocks())
      for (llvm::Instruction& I : *BB)
        if (llvm::isa<llvm::FPMathOperator>(I))
          I.setHasAllowReassoc(true);
  });
}

std::string checkedNote(const FixCheck& f) {
  switch (f.outcome) {
    case FixCheck::Outcome::Works:
      return " Checked: with this change LLVM's vectorizer vectorizes the "
             "loop (" +
             f.message + ").";
    case FixCheck::Outcome::DoesNotWork:
      return "";
    case FixCheck::Outcome::Unchecked:
      return " (Not checked: no target available to rerun the vectorizer.)";
  }
  return "";
}

std::string notEnough(const std::string& change, const FixCheck& f) {
  return "checked: " + change +
         " alone doesn't make LLVM vectorize this loop" +
         (f.message.empty() ? std::string("")
                            : " (it then reports: \"" + f.message + "\")");
}

// --- Calls -----------------------------------------------------------------

std::vector<llvm::CallBase*> blockingCalls(llvm::Loop* L) {
  std::vector<llvm::CallBase*> out;
  for (llvm::BasicBlock* BB : L->blocks())
    for (llvm::Instruction& I : *BB) {
      auto* CB = llvm::dyn_cast<llvm::CallBase>(&I);
      if (!CB)
        continue;
      if (auto* II = llvm::dyn_cast<llvm::IntrinsicInst>(CB))
        if (llvm::isTriviallyVectorizable(II->getIntrinsicID()) ||
            II->isAssumeLikeIntrinsic())
          continue;
      out.push_back(CB);
    }
  return out;
}

/// libm functions a vector math library can provide. Other library
/// functions (free, strlen, printf...) have no vector versions anywhere.
bool isMathFunction(llvm::StringRef name) {
  static const std::set<std::string> math = {
      "sin",   "cos",   "tan",   "asin",  "acos",   "atan",  "atan2",
      "sinh",  "cosh",  "tanh",  "asinh", "acosh",  "atanh", "exp",
      "exp2",  "exp10", "expm1", "log",   "log2",   "log10", "log1p",
      "pow",   "sqrt",  "cbrt",  "erf",   "erfc",   "lgamma", "tgamma",
      "fmod",  "hypot", "sincos", "ceil", "floor",  "trunc", "round",
      "fabs",  "fmin",  "fmax",  "ldexp", "rint",   "nearbyint"};
  std::string n = name.str();
  if (math.count(n))
    return true;
  if (!n.empty() && (n.back() == 'f' || n.back() == 'l'))
    return math.count(n.substr(0, n.size() - 1)) > 0;
  return false;
}

/// "f.c:7:23" from a remark matches an instruction at f.c:7:23 (or f.c:7
/// when the remark has no column).
bool atLocation(const llvm::Instruction* I, const std::string& location) {
  if (location.empty())
    return false;
  std::string loc = formatDebugLoc(I->getDebugLoc());
  return !loc.empty() &&
         (loc == location || loc.rfind(location + ":", 0) == 0);
}

const char* kVeclibAdvice =
    "-fveclib=Accelerate on macOS, -fveclib=libmvec or SVML on x86 Linux "
    "(the options available depend on your clang version)";

Explanation explainCalls(const LoopCtx& c, const VectorizerRemark& R) {
  Explanation e;
  e.basis = "LLVM LoopVectorize + TargetLibraryInfo";
  std::vector<llvm::CallBase*> calls = blockingCalls(c.L);
  // The remark points at the offending call; describe only that one when
  // we can find it.
  std::vector<llvm::CallBase*> atRemark;
  for (llvm::CallBase* CB : calls)
    if (atLocation(CB, R.location))
      atRemark.push_back(CB);
  if (!atRemark.empty())
    calls = atRemark;
  if (calls.empty()) {
    e.message = "Not vectorized: an instruction in the loop has no vector form";
    return e;
  }
  llvm::Function* callee = calls.front()->getCalledFunction();
  std::string name = callee ? callee->getName().str() : "a function pointer";
  e.message = "Not vectorized: the call to " + name +
              " has no vector version the compiler knows about";
  bool sawMath = false, sawErrno = false, sawLib = false, sawOpaque = false,
       sawDefined = false;
  for (llvm::CallBase* CB : calls) {
    llvm::Function* F = CB->getCalledFunction();
    std::string where = sourceLine(CB);
    std::string at = where.empty() ? "" : " (" + where + ")";
    llvm::LibFunc LF;
    bool isLib = F && c.FA.tli().getLibFunc(*F, LF) && c.FA.tli().has(LF);
    if (!F) {
      e.evidence.push_back("indirect call through a function pointer" + at);
    } else if (isLib && isMathFunction(F->getName())) {
      if (!CB->onlyReadsMemory()) {
        sawErrno = true;
        e.evidence.push_back(
            F->getName().str() + at +
            " is a math library function declared as possibly writing "
            "memory (errno), so it can't be replaced by a vector version");
      } else {
        sawMath = true;
        e.evidence.push_back(
            F->getName().str() + at +
            " is a math library function; LLVM knows no vector version "
            "for it in this configuration");
      }
    } else if (isLib) {
      sawLib = true;
      e.evidence.push_back(F->getName().str() + at +
                           " is a C library function with no vector version");
    } else if (F->isDeclaration()) {
      sawOpaque = true;
      e.evidence.push_back(F->getName().str() + at +
                           " is only declared here; its body isn't visible, so "
                           "it can't be inlined or vectorized");
    } else {
      sawDefined = true;
      e.evidence.push_back(F->getName().str() + at +
                           " is defined in this file but was not inlined");
    }
  }
  if (sawErrno) {
    e.message = "Not vectorized: " + name +
                " may set errno, so it can't be replaced by a vector version";
    e.suggestions.push_back(
        "Compile with -fno-math-errno (implied by -ffast-math) if nothing "
        "reads errno after these calls; that lets LLVM treat them as pure.");
    e.suggestions.push_back(
        std::string("Then, if you don't already pass a vector math library "
                    "(the IR doesn't record -fveclib), add one: ") +
        kVeclibAdvice + ".");
  }
  if (sawMath)
    e.suggestions.push_back(
        std::string("If you don't already pass a vector math library (the IR "
                    "doesn't record -fveclib), tell clang which one you link: ") +
        kVeclibAdvice + ".");
  if (sawLib)
    e.suggestions.push_back(
        "Move the call out of the loop, or split the loop so the call runs "
        "in its own scalar loop and the arithmetic in a separate one.");
  if (sawOpaque) {
    e.suggestions.push_back(
        "Make the definition visible so it can be inlined: define it "
        "`static inline` in a header, or build with -flto.");
    e.suggestions.push_back(
        "Or provide a SIMD version: put `#pragma omp declare simd` on its "
        "declaration and definition and compile with -fopenmp-simd.");
  }
  if (sawDefined)
    e.suggestions.push_back(
        "Mark it `inline` / `__attribute__((always_inline))`, or make it "
        "smaller so the inliner accepts it.");
  return e;
}

/// "instruction cannot be vectorized": name the instruction the remark
/// points at instead of assuming it's a call.
Explanation explainInstruction(const LoopCtx& c, const VectorizerRemark& R) {
  // The remark names the instruction's location, or just the loop start
  // when that instruction has none; then a volatile access is the likely
  // culprit if there is exactly one kind of candidate.
  bool exact = false;
  for (llvm::BasicBlock* BB : c.L->blocks())
    for (llvm::Instruction& I : *BB)
      exact |= atLocation(&I, R.location) &&
               (llvm::isa<llvm::LoadInst>(I) || llvm::isa<llvm::StoreInst>(I) ||
                llvm::isa<llvm::CallBase>(I));
  for (llvm::BasicBlock* BB : c.L->blocks())
    for (llvm::Instruction& I : *BB) {
      if (exact && !atLocation(&I, R.location))
        continue;
      if (exact && llvm::isa<llvm::CallBase>(I) &&
          !llvm::isa<llvm::IntrinsicInst>(I))
        return explainCalls(c, R);
      bool isVolatile =
          (llvm::isa<llvm::LoadInst>(I) &&
           llvm::cast<llvm::LoadInst>(I).isVolatile()) ||
          (llvm::isa<llvm::StoreInst>(I) &&
           llvm::cast<llvm::StoreInst>(I).isVolatile());
      if (isVolatile) {
        Explanation e;
        e.basis = "LLVM LoopVectorize";
        const llvm::Value* ptr = llvm::getLoadStorePointerOperand(&I);
        e.message = "Not vectorized: volatile access to " +
                    pointerBaseName(ptr) + " (" + sourceLine(&I) +
                    ") must happen one element at a time";
        e.suggestions.push_back(
            "Drop `volatile` if the memory isn't a device register or shared "
            "with a signal handler; otherwise this loop stays scalar.");
        return e;
      }
    }
  // No specific instruction at the remark's location (LLVM repeats this
  // remark at the loop start after a call blocker): it's the call.
  if (!blockingCalls(c.L).empty())
    return explainCalls(c, VectorizerRemark{});
  Explanation e;
  e.basis = "LLVM LoopVectorize";
  e.message = "Not vectorized: an instruction" +
              (R.location.empty() ? std::string("")
                                  : " at " + R.location) +
              " has no vector form";
  return e;
}

// --- Early exit / unknown trip count ----------------------------------------

Explanation explainEarlyExit(llvm::Loop* L) {
  Explanation e;
  e.basis = "LLVM LoopVectorize + ScalarEvolution";
  llvm::SmallVector<llvm::BasicBlock*, 4> exiting;
  L->getExitingBlocks(exiting);
  bool dataExit = false;
  for (llvm::BasicBlock* BB : exiting) {
    auto* Br = llvm::dyn_cast<llvm::BranchInst>(BB->getTerminator());
    if (!Br || !Br->isConditional())
      continue;
    if (derivesFromLoadIn(Br->getCondition(), L)) {
      dataExit = true;
      std::string where = sourceLine(Br);
      e.evidence.push_back("exit test" + (where.empty() ? "" : " at " + where) +
                           " depends on data read inside the loop");
    }
  }
  e.evidence.push_back("the loop has " + std::to_string(exiting.size()) +
                       " exit point(s)");
  if (exiting.size() > 1 || dataExit) {
    e.message = "Not vectorized: the loop can stop early, so its iteration "
                "count isn't known when it starts";
    e.suggestions.push_back(
        "LLVM 15 cannot vectorize loops with an early exit. Scan fixed-size "
        "blocks without breaking out (compute a match mask per block), then "
        "locate the exact match inside the first block that hit.");
  } else {
    e.message = "Not vectorized: the iteration count can't be computed";
    e.suggestions.push_back(
        "Use a simple `for (i = 0; i < n; ++i)` loop with a counter at least "
        "as wide as the bound (e.g. size_t), and don't modify the bound or "
        "the counter inside the loop.");
  }
  return e;
}

// --- Control flow -----------------------------------------------------------

Explanation explainControlFlow(const LoopCtx& c) {
  Explanation e;
  e.basis = "LLVM LoopVectorize + DominatorTree";
  e.message = "Not vectorized: the loop body branches in a way the vectorizer "
              "can't turn into straight-line code";
  llvm::BasicBlock* latch = c.L->getLoopLatch();
  for (llvm::BasicBlock* BB : c.L->blocks()) {
    if (latch && c.FA.domTree().dominates(BB, latch))
      continue;  // Runs on every iteration.
    for (llvm::Instruction& I : *BB)
      if (llvm::isa<llvm::LoadInst>(I) || llvm::isa<llvm::StoreInst>(I)) {
        std::string where = sourceLine(&I);
        e.evidence.push_back(
            std::string(llvm::isa<llvm::StoreInst>(I) ? "store to "
                                                      : "load of ") +
            pointerBaseName(llvm::getLoadStorePointerOperand(&I)) +
            (where.empty() ? "" : " (" + where + ")") +
            " only happens on some iterations");
      }
  }
  e.suggestions.push_back(
      "Make memory accesses unconditional and select the value instead, e.g. "
      "`b[i] = cond ? x : b[i];`, when that access is always safe.");
  return e;
}

// --- Array bounds (runtime checks impossible) -------------------------------

Explanation explainArrayBounds(const LoopCtx& c) {
  Explanation e;
  e.basis = "LLVM LoopVectorize + LoopAccessAnalysis + ScalarEvolution";
  std::set<std::string> params = unrestrictedParams(c.L);
  e.message =
      "Not vectorized: " +
      (params.empty() ? std::string("the pointers") : joinNames(params)) +
      " might overlap, and the overlap can't be checked at run time";
  llvm::Type* scatteredTy = nullptr;
  llvm::Align align;
  std::vector<MemoryAccess> accesses =
      collectAccesses(c.L, c.FA.scev(), c.FA.loopInfo());
  for (const MemoryAccess& A : accesses) {
    if (A.inner().kind != Stride::Kind::Irregular)
      continue;
    e.evidence.push_back(A.describe() + ": " + A.inner().text() +
                         ", so its address range can't be computed up front");
    if (!A.isStore && !scatteredTy) {
      scatteredTy = llvm::getLoadStoreType(A.inst);
      align = llvm::getLoadStoreAlignment(A.inst);
    }
  }
  // h[idx[i]]++: a store and a load of the same array at data-dependent
  // positions. Two iterations may hit the same element; no annotation on
  // pointers can rule that out.
  std::string conflictArray;
  for (const MemoryAccess& St : accesses) {
    if (!St.isStore || St.inner().kind != Stride::Kind::Irregular)
      continue;
    const llvm::Value* base =
        llvm::getUnderlyingObject(llvm::getLoadStorePointerOperand(St.inst));
    for (const MemoryAccess& Ld : accesses)
      if (!Ld.isStore && Ld.inner().kind != Stride::Kind::Invariant &&
          llvm::getUnderlyingObject(llvm::getLoadStorePointerOperand(
              Ld.inst)) == base) {
        e.evidence.push_back(
            St.describe() + " and " + Ld.describe() +
            " touch data-dependent positions of the same array: two "
            "iterations may update the same element, which `restrict` can't "
            "rule out");
        conflictArray = St.base;
        break;
      }
  }
  if (!params.empty()) {
    FixCheck fix = checkRestrict(c, params);
    if (fix.fails())
      e.evidence.push_back(notEnough("marking " + joinNames(params) +
                                         " `restrict`",
                                     fix));
    else
      e.suggestions.push_back(restrictAdvice(params) +
                              " Then no run-time overlap check is needed." +
                              checkedNote(fix));
    if (fix.fails() && !conflictArray.empty()) {
      e.message = "Not vectorized: " + conflictArray +
                  " is updated at data-dependent positions, and two "
                  "iterations may update the same element";
      e.suggestions.push_back(
          "If the indices within each group of iterations are known to be "
          "distinct, there's no portable way to tell LLVM 15; otherwise "
          "privatize: give each vector lane its own copy of " +
          conflictArray + " and combine them after the loop.");
    }
  }
  if (scatteredTy && scatteredTy->getScalarSizeInBits()) {
    unsigned bits = c.FA.tti()
                        .getRegisterBitWidth(
                            llvm::TargetTransformInfo::RGK_FixedWidthVector)
                        .getFixedSize();
    unsigned lanes = bits / scatteredTy->getScalarSizeInBits();
    if (lanes > 1) {
      bool gather = c.FA.tti().isLegalMaskedGather(
          llvm::FixedVectorType::get(scatteredTy, lanes), align);
      e.evidence.push_back(
          std::string("target ") + (gather ? "has" : "has no") +
          " vector gather instruction" +
          (gather ? ""
                  : ": scattered reads stay one element at a time, so "
                    "the gain may be small even after the fix"));
    }
  }
  return e;
}

// --- Recurrences --------------------------------------------------------------

/// "fadd", "fmuladd", "select": what computes the next value.
std::string operationName(const llvm::Instruction* I) {
  if (const auto* II = llvm::dyn_cast<llvm::IntrinsicInst>(I)) {
    std::string n = II->getCalledFunction()->getName().str();
    if (n.rfind("llvm.", 0) == 0)
      n = n.substr(5);
    return n.substr(0, n.find('.'));
  }
  if (const auto* CB = llvm::dyn_cast<llvm::CallBase>(I))
    return "call to " + valueName(CB->getCalledOperand());
  return I->getOpcodeName();
}

bool isFloatWithoutReassoc(const llvm::Instruction* I) {
  return I->getType()->isFloatingPointTy() &&
         !(llvm::isa<llvm::FPMathOperator>(I) && I->hasAllowReassoc());
}

Explanation explainRecurrence(const LoopCtx& c) {
  Explanation e;
  e.basis = "LLVM LoopVectorize + IVDescriptors";
  e.message = "Not vectorized: each iteration needs the previous iteration's "
              "result";
  llvm::Loop* L = c.L;
  enum Kind { None = 0, Scan = 1, Select = 2, General = 4 };
  unsigned kinds = None;
  bool storesIntermediates = false, floatScan = false;
  std::set<std::string> seen;
  auto note = [&](std::string line) {
    if (seen.insert(line).second)
      e.evidence.push_back(std::move(line));
  };
  if (!hasCanonicalShape(L))
    return e;
  for (llvm::PHINode& Phi : L->getHeader()->phis()) {
    llvm::InductionDescriptor ID;
    if (llvm::InductionDescriptor::isInductionPHI(&Phi, L, &c.FA.scev(), ID))
      continue;
    llvm::RecurrenceDescriptor RD;
    if (llvm::RecurrenceDescriptor::isReductionPHI(
            &Phi, L, RD, nullptr, nullptr, &c.FA.domTree(), &c.FA.scev()))
      continue;
    llvm::MapVector<llvm::Instruction*, llvm::Instruction*> sinkAfter;
    if (llvm::RecurrenceDescriptor::isFirstOrderRecurrence(&Phi, L, sinkAfter,
                                                           &c.FA.domTree()))
      continue;
    auto* next = llvm::dyn_cast<llvm::Instruction>(
        Phi.getIncomingValueForBlock(L->getLoopLatch()));
    if (!next)
      continue;
    // x = x op y, where y doesn't depend on x: a running total/product.
    bool scanLike = false;
    if (const auto* BO = llvm::dyn_cast<llvm::BinaryOperator>(next)) {
      unsigned op = BO->getOpcode();
      bool assoc = op == llvm::Instruction::Add ||
                   op == llvm::Instruction::FAdd ||
                   op == llvm::Instruction::Mul ||
                   op == llvm::Instruction::FMul;
      for (unsigned i = 0; i < 2 && assoc; ++i)
        if (BO->getOperand(i) == &Phi &&
            !dependsOn(BO->getOperand(1 - i), &Phi, L))
          scanLike = true;
    }
    std::string where = sourceLine(next);
    std::string what = operationName(next);
    note(what + (where.empty() ? "" : " at " + where) +
         " computes this iteration's value from the previous one");
    for (llvm::User* U : next->users())
      if (auto* St = llvm::dyn_cast<llvm::StoreInst>(U)) {
        if (!L->contains(St))
          continue;
        storesIntermediates = true;
        std::string sl = sourceLine(St);
        note("every intermediate value is stored to " +
             pointerBaseName(St->getPointerOperand()) +
             (sl.empty() ? "" : " (" + sl + ")") +
             (scanLike ? ", so this is a running total (scan), not a "
                         "reduction"
                       : ""));
      }
    if (scanLike) {
      kinds |= Scan;
      floatScan |= isFloatWithoutReassoc(next);
    } else if (llvm::isa<llvm::SelectInst>(next)) {
      kinds |= Select;
    } else {
      kinds |= General;
    }
  }
  e.suggestions.push_back(
      "This dependence is real: as written, iterations can't run side by "
      "side.");
  if (kinds & Scan) {
    if (storesIntermediates)
      e.suggestions.push_back(
          "For a running total (prefix sum), use a SIMD scan (shift-and-add "
          "within a vector, carry the last lane to the next vector) or a "
          "two-pass blocked scan.");
    e.suggestions.push_back(
        std::string("If only the final value is needed, stop storing the "
                    "intermediates; it becomes a reduction, ") +
        (floatScan ? "which LLVM vectorizes only if reordering the float "
                     "operations is allowed (`#pragma clang fp "
                     "reassociate(on)` or -ffast-math)."
                   : "which LLVM can vectorize."));
  }
  if (kinds & Select)
    e.suggestions.push_back(
        "This looks like tracking a best value and where it was found (e.g. "
        "argmax), which LLVM 15 can't vectorize. Find the best value in one "
        "loop (a plain min/max reduction vectorizes), then its position in a "
        "second loop.");
  if (kinds & General)
    e.suggestions.push_back(
        "A recurrence like x = a*x + b only vectorizes after an algebraic "
        "rewrite (e.g. computing several steps at once); no compiler flag "
        "does this.");
  return e;
}

// --- Memory dependences -------------------------------------------------------

Explanation explainMemoryDependence(const LoopCtx& c) {
  using Dep = llvm::MemoryDepChecker::Dependence;
  Explanation e;
  e.basis = "LLVM LoopVectorize + LoopAccessAnalysis";
  const llvm::LoopAccessInfo& LAI = c.FA.loopAccess(c.L);
  const auto* deps = LAI.getDepChecker().getDependences();
  bool trueDep = false, forwarding = false, sameObjectOnly = true;
  bool artifactsOnly = true;
  unsigned unrolledBy = 1;
  collectAccesses(c.L, c.FA.scev(), c.FA.loopInfo(), &unrolledBy);
  std::set<std::string> candidates;  // Unrestricted params in cross pairs.
  std::set<std::string> sameArrays;
  int64_t forwardingDistance = 0;
  if (deps) {
    for (const auto& D : *deps) {
      if (Dep::isSafeForVectorization(D.Type) ==
          llvm::MemoryDepChecker::VectorizationSafetyStatus::Safe)
        continue;
      llvm::Instruction* Src = D.getSource(LAI);
      llvm::Instruction* Dst = D.getDestination(LAI);
      const llvm::Value* sp = llvm::getLoadStorePointerOperand(Src);
      const llvm::Value* dp = llvm::getLoadStorePointerOperand(Dst);
      bool sameObject =
          llvm::getUnderlyingObject(sp) == llvm::getUnderlyingObject(dp);
      std::string pair = pointerBaseName(sp) + " (" + sourceLine(Src) +
                         ") and " + pointerBaseName(dp) + " (" +
                         sourceLine(Dst) + ")";
      std::string dist;
      int64_t elems = -1;
      const llvm::SCEV* diff = c.FA.scev().getMinusSCEV(
          c.FA.scev().getSCEV(const_cast<llvm::Value*>(dp)),
          c.FA.scev().getSCEV(const_cast<llvm::Value*>(sp)));
      if (const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(diff)) {
        uint64_t elem = c.L->getHeader()
                            ->getModule()
                            ->getDataLayout()
                            .getTypeStoreSize(llvm::getLoadStoreType(Src))
                            .getFixedSize();
        int64_t d = C->getAPInt().getSExtValue();
        if (elem) {
          elems = std::abs(d) / (int64_t)elem;
          dist = ", " + std::to_string(elems) + " element(s) apart";
        }
      }
      // Two stores from one source statement in an unrolled copy: a conflict
      // made by unrolling after vectorization, not one in the source loop.
      std::string srcLoc = formatDebugLoc(Src->getDebugLoc());
      if (unrolledBy > 1 && Src != Dst && sameObject && !srcLoc.empty() &&
          llvm::isa<llvm::StoreInst>(Src) && llvm::isa<llvm::StoreInst>(Dst) &&
          srcLoc == formatDebugLoc(Dst->getDebugLoc()) &&
          inlinedAtChain(Src->getDebugLoc()) ==
              inlinedAtChain(Dst->getDebugLoc())) {
        e.evidence.push_back(
            pair + ": two unrolled copies of the same store; this conflict "
                   "was made by unrolling after vectorization and isn't in "
                   "the source loop");
        continue;
      }
      artifactsOnly = false;
      if (D.Type == Dep::Unknown) {
        if (sameObject) {
          sameArrays.insert(pointerBaseName(sp));
          e.evidence.push_back(pair +
                               ": same array, positions LLVM can't relate");
        } else {
          sameObjectOnly = false;
          for (const llvm::Value* p : {sp, dp})
            if (const llvm::Argument* A = unrestrictedArg(p))
              candidates.insert(valueName(A));
          e.evidence.push_back(pair + ": can't tell whether they overlap");
        }
        continue;
      }
      if (D.Type == Dep::ForwardButPreventsForwarding ||
          D.Type == Dep::BackwardVectorizableButPreventsForwarding) {
        forwarding = true;
        forwardingDistance = elems;
        e.evidence.push_back(pair + dist +
                             ": vector stores would defeat the CPU's "
                             "store-to-load forwarding at this distance");
        continue;
      }
      trueDep = true;
      e.evidence.push_back(pair +
                           ": a later iteration reads what an earlier "
                           "one wrote" +
                           dist);
    }
  } else {
    // LoopAccessAnalysis keeps no list when there are too many dependences;
    // the restrict check below decides whether overlap is the problem.
    sameObjectOnly = false;
    candidates = unrestrictedParams(c.L);
  }
  if (const auto* report = LAI.getReport())
    e.evidence.push_back("LoopAccessAnalysis: " + oneLine(report->getMsg()));

  if (deps && artifactsOnly && unrolledBy > 1) {
    e.message = "Not vectorized here, but the rerun's only conflict comes from "
                "unrolling done after vectorization";
    e.evidence.push_back("this copy is unrolled x" +
                         std::to_string(unrolledBy) +
                         "; the vectorizer saw the loop before that, so this "
                         "verdict says nothing about the source loop");
    e.suggestions.push_back(
        "Pass --remarks with clang's -fsave-optimization-record output to see "
        "the decision the vectorizer actually made.");
    return e;
  }
  if (trueDep) {
    e.message = "Not vectorized: a later iteration depends on memory an "
                "earlier iteration writes";
    e.suggestions.push_back(
        "This is a true loop-carried dependence; vectorizing it needs an "
        "algorithm change, not a compiler flag.");
    return e;
  }
  if (forwarding) {
    e.message = "Not vectorized: LLVM treats this dependence as unsafe because "
                "vector code would defeat store-to-load forwarding";
    e.evidence.push_back(
        "this is a performance rule in LLVM 15's dependence analysis, not a "
        "correctness problem; loop pragmas don't override it");
    if (forwardingDistance > 0)
      e.suggestions.push_back(
          "The loop reads what it wrote " +
          std::to_string(forwardingDistance) +
          " element(s) earlier. Restructure it so the distance is larger than "
          "a vector (or zero), e.g. by reading from a separate input array.");
    return e;
  }
  if (sameObjectOnly && !sameArrays.empty()) {
    e.message = "Not vectorized: accesses to " + joinNames(sameArrays) +
                " may overlap each other, and LLVM can't tell where";
    e.evidence.push_back("both sides are the same array, so `restrict` can't "
                         "help");
    e.suggestions.push_back(
        "If no iteration touches an element another iteration uses, make "
        "that visible: write results to a separate output array, or use "
        "index expressions LLVM can compare (affine in the loop counter).");
    return e;
  }
  e.message =
      "Not vectorized: " +
      (candidates.empty() ? std::string("memory accesses")
                          : joinNames(candidates)) +
      " might overlap";
  if (!candidates.empty()) {
    FixCheck fix = checkRestrict(c, candidates);
    if (fix.fails())
      e.evidence.push_back(notEnough("marking " + joinNames(candidates) +
                                         " `restrict`",
                                     fix));
    else
      e.suggestions.push_back(restrictAdvice(candidates) + checkedNote(fix));
  }
  return e;
}

// --- Floating-point order and the cost model -------------------------------

struct OrderedReduction {
  llvm::PHINode* phi;
  llvm::Instruction* op;
  llvm::Loop* loop;
};

/// Float reductions whose operations lack `reassoc`: vector code would
/// change the order of additions, which IEEE semantics forbid by default.
std::vector<OrderedReduction> orderedReductions(FunctionAnalyses& FA,
                                                llvm::Loop* L) {
  std::vector<OrderedReduction> out;
  if (!hasCanonicalShape(L))
    return out;
  for (llvm::PHINode& Phi : L->getHeader()->phis()) {
    llvm::RecurrenceDescriptor RD;
    if (!llvm::RecurrenceDescriptor::isReductionPHI(
            &Phi, L, RD, nullptr, nullptr, &FA.domTree(), &FA.scev()))
      continue;
    if (llvm::Instruction* exact = RD.getExactFPMathInst())
      out.push_back({&Phi, exact, L});
  }
  return out;
}

std::string reassociateAdvice() {
  return "Allow reordering for just this loop: put `#pragma clang fp "
         "reassociate(on)` at the top of the loop body (or use "
         "-ffast-math / -fassociative-math file-wide). The result can differ "
         "in the last bits, because additions happen in a different order.";
}

std::string reductionPhrase(const OrderedReduction& R) {
  std::string var = sourceVarName(R.phi);
  if (var == "<expr>") {
    // Unnamed accumulator kept in memory (`*out += ...`): name it after the
    // address it is stored to.
    for (const llvm::User* U : R.op->users())
      if (const auto* St = llvm::dyn_cast<llvm::StoreInst>(U))
        if (R.loop->contains(St))
          var = "*" + pointerBaseName(St->getPointerOperand());
  }
  std::string where = sourceLine(R.op);
  std::string what =
      R.op->getOpcode() == llvm::Instruction::FMul ? "product" : "sum";
  return "float " + what +
         (var == "<expr>" ? std::string("") : " `" + var + "`") +
         (where.empty() ? "" : " (" + where + ")");
}

Explanation explainFloatOrder(const LoopCtx& c) {
  Explanation e;
  e.basis = "LLVM LoopVectorize + IVDescriptors (reduction analysis)";
  std::vector<OrderedReduction> reds = orderedReductions(c.FA, c.L);
  e.message = "Not vectorized: " +
              (reds.empty() ? std::string("float operations")
                            : reductionPhrase(reds.front())) +
              " must be computed in source order";
  for (const auto& R : reds)
    e.evidence.push_back(reductionPhrase(R) + ": the operation has no "
                                              "`reassoc` flag");
  FixCheck fix = checkReassociate(c);
  if (fix.fails()) {
    e.evidence.push_back(notEnough("allowing reassociation", fix));
    e.suggestions.push_back(reassociateAdvice() +
                            " This is needed, but something else also blocks "
                            "vectorization (see above).");
  } else {
    e.suggestions.push_back(reassociateAdvice() + checkedNote(fix));
  }
  return e;
}

Explanation explainCostModel(const LoopCtx& c) {
  Explanation e;
  e.basis = "LLVM LoopVectorize cost model (TargetTransformInfo) + "
            "IVDescriptors + ScalarEvolution";
  std::string cpu = targetCPU(c.FA.function());
  e.evidence.push_back(
      "LLVM's cost model predicted vector code would not be faster" +
      (cpu.empty() ? std::string("") : " on " + cpu));

  // The cost model doesn't report its reasons. A factor is named as *the*
  // cause only if removing it (in a rerun) flips the decision.
  std::vector<OrderedReduction> reds = orderedReductions(c.FA, c.L);
  FixCheck reassoc;
  if (!reds.empty())
    reassoc = checkReassociate(c);

  std::vector<std::string> factors;
  for (const auto& R : reds)
    factors.push_back(reductionPhrase(R) +
                      " must be added in source order: a vector version has "
                      "to add one element at a time");
  for (const MemoryAccess& A :
       collectAccesses(c.L, c.FA.scev(), c.FA.loopInfo())) {
    const Stride& s = A.inner();
    if (s.isStrided() || s.kind == Stride::Kind::Irregular)
      factors.push_back(A.describe() + ": " + s.text() +
                        ", so it can't use contiguous vector loads/stores");
    else if (s.kind == Stride::Kind::Invariant && A.isStore)
      factors.push_back(A.describe() + " writes the same address every "
                                       "iteration");
  }

  if (reassoc.works()) {
    e.message = "Not vectorized: " + reductionPhrase(reds.front()) +
                " must be added in source order";
    e.evidence.push_back("checked: with reassociation allowed, LLVM's "
                         "vectorizer vectorizes this loop (" +
                         reassoc.message + ")");
    e.suggestions.push_back(reassociateAdvice());
  } else {
    e.message = "Not vectorized: LLVM's cost model predicted no speedup";
    if (factors.empty()) {
      e.evidence.push_back("no specific expensive pattern identified in this "
                           "loop");
    } else {
      e.evidence.push_back(
          "observed in this loop (possible contributors, not ranked):");
      for (const auto& f : factors)
        e.evidence.push_back("  " + f);
    }
    if (reassoc.fails())
      e.evidence.push_back(notEnough("allowing reassociation", reassoc));
    else if (!reds.empty())
      e.suggestions.push_back(reassociateAdvice() + checkedNote(reassoc));
  }
  e.suggestions.push_back(
      "To test the prediction, force it with `#pragma clang loop "
      "vectorize(enable)` and benchmark.");
  return e;
}

// ---------------------------------------------------------------------------

Diagnostic makeDiag(FunctionAnalyses& FA, const LogicalLoop& LL) {
  Diagnostic d;
  d.category = DiagnosticCategory::Vectorization;
  d.functionName = FA.function().getName().str();
  d.loop = LL.describe();
  d.loopOrder = LL.order;
  return d;
}

void reportVectorized(FunctionAnalyses& FA, const LogicalLoop& LL,
                      AnalysisContext& ctx) {
  Diagnostic d = makeDiag(FA, LL);
  d.severity = DiagnosticSeverity::Note;
  std::string width =
      (LL.scalable ? "vscale x " : "") + std::to_string(LL.vectorWidth);
  d.message = "Vectorized (width " + width + ")";
  d.basis = "vector types in the loop + llvm.loop.isvectorized metadata";

  // Vector math intrinsics have no CPU instruction. When the vectorizer
  // knows a vector math library it calls that instead, so seeing the
  // intrinsic means the backend will split it into one libm call per lane.
  std::set<std::string> scalarized;
  for (llvm::BasicBlock* BB : LL.vectorBody->blocks())
    for (llvm::Instruction& I : *BB)
      if (auto* II = llvm::dyn_cast<llvm::IntrinsicInst>(&I)) {
        if (!II->getType()->isVectorTy())
          continue;
        switch (II->getIntrinsicID()) {
          case llvm::Intrinsic::sin:
          case llvm::Intrinsic::cos:
          case llvm::Intrinsic::exp:
          case llvm::Intrinsic::exp2:
          case llvm::Intrinsic::log:
          case llvm::Intrinsic::log2:
          case llvm::Intrinsic::log10:
          case llvm::Intrinsic::pow:
            scalarized.insert(II->getCalledFunction()->getName().str());
            break;
          default:
            break;
        }
      }
  if (!scalarized.empty()) {
    d.severity = DiagnosticSeverity::Warning;
    d.message += ", but the math calls are still done one element at a time";
    for (const auto& name : scalarized)
      d.evidence.push_back(name + " has no vector instruction on this target; "
                                  "codegen splits it into scalar libm calls");
    d.suggestions.push_back(
        std::string("Tell clang which vector math library you link: e.g. ") +
        kVeclibAdvice + ". With one, LLVM calls its vector versions instead.");
    d.basis += " + vector math intrinsics left in the vector loop";
  }

  // Run-time conditions guarding the vector code. They're only possible
  // with a scalar fallback copy; ask LoopAccessAnalysis about it.
  if (LL.scalar) {
    const llvm::LoopAccessInfo& LAI = FA.loopAccess(LL.scalar);
    const llvm::RuntimePointerChecking* RPC = LAI.getRuntimePointerChecking();
    if (RPC && RPC->Need) {
      std::set<std::string> pairs, names, params;
      bool sameArrayOnly = true;
      for (const auto& check : RPC->getChecks()) {
        std::set<std::string> a, b;
        std::set<const llvm::Value*> objA, objB;
        std::set<std::string> argsHere;
        for (unsigned idx : check.first->Members) {
          const llvm::Value* p = RPC->Pointers[idx].PointerValue;
          a.insert(pointerBaseName(p));
          objA.insert(llvm::getUnderlyingObject(p));
          if (const llvm::Argument* A = unrestrictedArg(p))
            argsHere.insert(valueName(A));
        }
        for (unsigned idx : check.second->Members) {
          const llvm::Value* p = RPC->Pointers[idx].PointerValue;
          b.insert(pointerBaseName(p));
          objB.insert(llvm::getUnderlyingObject(p));
          if (const llvm::Argument* A = unrestrictedArg(p))
            argsHere.insert(valueName(A));
        }
        pairs.insert(joinNames(a) + " vs " + joinNames(b));
        names.insert(a.begin(), a.end());
        names.insert(b.begin(), b.end());
        if (objA != objB || objA.size() > 1) {
          sameArrayOnly = false;
          params.insert(argsHere.begin(), argsHere.end());
        }
      }
      d.message += ", but only behind a run-time check that " +
                   joinNames(names) + " don't overlap";
      for (const auto& p : pairs)
        d.evidence.push_back("overlap check: " + p);
      d.evidence.push_back(
          "if the check fails, the original scalar loop runs instead");
      if (sameArrayOnly)
        d.evidence.push_back("the check compares different parts of the same "
                             "array, so `restrict` can't remove it");
      else if (!params.empty())
        d.suggestions.push_back(
            restrictAdvice(params) +
            " That removes the check and the fallback copy.");
      d.basis += " + LoopAccessAnalysis (runtime pointer checks)";
    }
    // x[i*incx]: LoopAccessAnalysis versions the loop on the stride being 1.
    std::set<std::string> strides;
    for (const auto& entry : LAI.getSymbolicStrides()) {
      const llvm::Value* v = entry.second;
      while (const auto* Cast = llvm::dyn_cast<llvm::CastInst>(v))
        v = Cast->getOperand(0);  // sext i32 %incx -> incx
      strides.insert(valueName(v));
    }
    if (!strides.empty()) {
      std::string conds;
      for (const auto& s : strides)
        conds += (conds.empty() ? "" : " and ") + s + " == 1";
      d.message += ", and the vector code only runs when " + conds;
      d.evidence.push_back(
          "LoopAccessAnalysis versioned the loop on the stride " +
          joinNames(strides) + "; for other values the scalar loop runs");
      d.suggestions.push_back(
          "If the stride is usually something else, the vector code rarely "
          "runs. Copy strided data into a contiguous buffer first, or write a "
          "separate unit-stride version for the common case.");
      d.basis += " + LoopAccessAnalysis (symbolic strides)";
    }
  }
  ctx.getEmitter().add(std::move(d));
}

/// The vectorizer's decision for a loop it didn't vectorize: clang's record
/// of the real compile when available, else the oracle's rerun.
const std::vector<VectorizerRemark>*
verdictFor(FunctionAnalyses& FA, const LogicalLoop& LL,
           const VectorizerOracle* oracle, const CompileRemarks* compiled,
           std::string* source, std::vector<std::string>* notes) {
  if (compiled) {
    llvm::DebugLoc start;
    for (llvm::Loop* L : LL.copies)
      if ((start = loopStartLoc(L)))
        break;
    bool ambiguous = false;
    if (const auto* r =
            compiled->find(FA.function().getName().str(), start, &ambiguous)) {
      *source = "compile";
      return r;
    }
    notes->push_back(
        ambiguous
            ? "clang's optimization record has different outcomes for loops "
              "at this location (code inlined more than once); showing the "
              "rerun instead"
            : "clang's optimization record has no vectorizer remark for this "
              "loop; showing the rerun instead");
  }
  *source = "rerun";
  return oracle && LL.oracleCopy
             ? oracle->remarksFor(LL.oracleCopy->getHeader())
             : nullptr;
}

const char* kRerunCaveat =
    "verdict from rerunning LLVM's vectorizer on this optimized IR; it "
    "approximates the decision made during compilation (pass --remarks with "
    "clang's -fsave-optimization-record output for the real one)";

void reportVerdict(FunctionAnalyses& FA, const LogicalLoop& LL,
                   const VectorizerOracle* oracle,
                   const CompileRemarks* compiled, AnalysisContext& ctx) {
  std::string source;
  std::vector<std::string> notes;
  const std::vector<VectorizerRemark>* remarks =
      verdictFor(FA, LL, oracle, compiled, &source, &notes);
  if (!remarks)
    return;  // No verdict available; main reports why once per run.
  bool fromCompile = source == "compile";
  std::string says = fromCompile ? "clang reported during compilation: \""
                                 : "LLVM says: \"";
  std::string basisSuffix = fromCompile
                                ? " (clang's optimization record)"
                                : " (vectorizer rerun on this IR)";
  if (!fromCompile && compiled == nullptr)
    notes.push_back(kRerunCaveat);
  if (!fromCompile && LL.oracleCopy) {
    unsigned k = 1;
    collectAccesses(LL.oracleCopy, FA.scev(), FA.loopInfo(), &k);
    if (k > 1)
      notes.push_back("the rerun sees a copy that was already unrolled x" +
                      std::to_string(k) +
                      " (by interleaving or the loop unroller); problems it "
                      "reports may come from that unrolling rather than the "
                      "source loop");
  }
  LoopCtx c{FA, LL, LL.scalar, oracle};

  std::string prefix =
      LL.state == VectorizerState::InterleavedOnly
          ? "LLVM processed this loop but chose vector width 1 (it only "
            "unrolled it, no SIMD)"
          : "";

  for (const VectorizerRemark& R : *remarks) {
    if (R.kind == VectorizerRemark::Kind::Passed && R.name == "Vectorized") {
      Diagnostic d = makeDiag(FA, LL);
      d.severity = DiagnosticSeverity::Note;
      d.message = "Vectorizable: LLVM's vectorizer succeeds on this loop as it "
                  "appears in this IR, but the IR has no vectorized copy";
      d.evidence.push_back(says + oneLine(R.message) + "\"");
      d.evidence.push_back(
          "the IR doesn't record why: vectorization may have been off for "
          "this compile (-fno-vectorize, -O1, a pragma), or the loop looked "
          "different when the vectorizer ran");
      d.basis = "LLVM LoopVectorize" + basisSuffix;
      ctx.getEmitter().add(std::move(d));
      return;
    }
  }

  std::set<Blocker> seen;
  for (const VectorizerRemark& R : *remarks) {
    Blocker b;
    if (R.kind == VectorizerRemark::Kind::Passed)
      continue;  // e.g. "interleaved loop": already covered by `prefix`.
    if (!classify(R, &b) || !seen.insert(b).second)
      continue;
    Explanation e;
    switch (b) {
      case Blocker::Call:
        e = explainCalls(c, R);
        break;
      case Blocker::Instruction:
        e = explainInstruction(c, R);
        break;
      case Blocker::EarlyExit:
        e = explainEarlyExit(c.L);
        break;
      case Blocker::ControlFlow:
        e = explainControlFlow(c);
        break;
      case Blocker::ArrayBounds:
        e = explainArrayBounds(c);
        break;
      case Blocker::Recurrence:
        e = explainRecurrence(c);
        break;
      case Blocker::MemoryDependence:
        e = explainMemoryDependence(c);
        break;
      case Blocker::FloatOrder:
        e = explainFloatOrder(c);
        break;
      case Blocker::CostModel:
        e = explainCostModel(c);
        break;
      case Blocker::Disabled:
        e.message = "Not vectorized: vectorization is disabled for this loop "
                    "(pragma or loop metadata)";
        e.basis = "LLVM LoopVectorize";
        break;
      case Blocker::Other:
        e.message = "Not vectorized: " + oneLine(R.message);
        e.basis = "LLVM LoopVectorize";
        break;
    }
    Diagnostic d = makeDiag(FA, LL);
    d.severity = b == Blocker::Disabled ? DiagnosticSeverity::Note
                                        : DiagnosticSeverity::Warning;
    d.message = e.message;
    d.evidence.push_back(says + oneLine(R.message) + "\" [" + R.name + "]");
    if (!prefix.empty())
      d.evidence.push_back(prefix);
    for (auto& line : e.evidence)
      d.evidence.push_back(std::move(line));
    for (const auto& n : notes)
      d.evidence.push_back(n);
    d.suggestions = std::move(e.suggestions);
    d.basis = e.basis + basisSuffix;
    ctx.getEmitter().add(std::move(d));
  }
}

void reportAlreadySimd(FunctionAnalyses& FA, const LogicalLoop& LL,
                       const CompileRemarks* compiled, AnalysisContext& ctx) {
  Diagnostic d = makeDiag(FA, LL);
  d.severity = DiagnosticSeverity::Note;
  d.message = "Already uses SIMD (" + std::string(LL.scalable ? "vscale x " : "") +
              std::to_string(LL.vectorWidth) +
              "-wide vector code), but not from LLVM's loop vectorizer";
  std::string lines;
  for (const auto& l : LL.simdLines)
    lines += (lines.empty() ? "" : ", ") + l;
  if (!lines.empty())
    d.evidence.push_back("vector operations at " + lines);
  if (LL.interleavedThenSlp)
    d.evidence.push_back(
        "the loop vectorizer only interleaved this loop (width 1); the SLP "
        "vectorizer then packed the interleaved copies into vectors");
  else
    d.evidence.push_back(
        "they come from the SLP vectorizer, intrinsics or vector types in the "
        "source, or an inner loop that was vectorized and then fully "
        "unrolled");
  d.basis = "vector types in a loop without llvm.loop.isvectorized";
  if (compiled) {
    std::string source;
    std::vector<std::string> notes;
    if (const auto* remarks =
            verdictFor(FA, LL, nullptr, compiled, &source, &notes))
      for (const VectorizerRemark& R : *remarks)
        if (R.kind != VectorizerRemark::Kind::Passed &&
            R.name != "MissedDetails" && R.name.rfind("Interleav", 0) != 0)
          d.evidence.push_back("the loop vectorizer's own decision during "
                               "compilation: \"" +
                               oneLine(R.message) + "\" [" + R.name + "]");
  } else {
    d.evidence.push_back(
        "rerunning the loop vectorizer on code that is already SIMD doesn't "
        "say what it decided originally, so no verdict is given");
  }
  ctx.getEmitter().add(std::move(d));
}

}  // namespace

void VectorizationAnalyzer::run(FunctionAnalyses& FA,
                                const LoopCatalog& catalog,
                                const VectorizerOracle* oracle,
                                const CompileRemarks* remarks,
                                AnalysisContext& ctx) {
  for (const LogicalLoop& LL : catalog.loops()) {
    // LLVM's vectorizer only handles innermost loops by default.
    if (!LL.innermost)
      continue;
    switch (LL.state) {
      case VectorizerState::Vectorized:
        reportVectorized(FA, LL, ctx);
        break;
      case VectorizerState::NotVectorized:
      case VectorizerState::InterleavedOnly:
        if (LL.scalar)
          reportVerdict(FA, LL, oracle, remarks, ctx);
        break;
      case VectorizerState::AlreadySimd:
        reportAlreadySimd(FA, LL, remarks, ctx);
        break;
      case VectorizerState::Disabled: {
        Diagnostic d = makeDiag(FA, LL);
        d.severity = DiagnosticSeverity::Note;
        d.message = "Not vectorized: disabled for this loop by `#pragma clang "
                    "loop vectorize(disable)` or equivalent loop metadata";
        d.basis = "llvm.loop.vectorize.* metadata";
        ctx.getEmitter().add(std::move(d));
        break;
      }
      case VectorizerState::Unknown: {
        Diagnostic d = makeDiag(FA, LL);
        d.severity = DiagnosticSeverity::Note;
        d.message = "Scalar copy left by the vectorizer; can't tell whether "
                    "the loop was vectorized";
        d.suggestions.push_back("Recompile with -gline-tables-only so loop "
                                "copies can be matched by source location.");
        d.basis = "llvm.loop.isvectorized metadata";
        ctx.getEmitter().add(std::move(d));
        break;
      }
    }
  }
}

}  // namespace analyzer
