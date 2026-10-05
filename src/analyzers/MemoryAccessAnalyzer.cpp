#include "analyzer/MemoryAccessAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/IRNames.h"
#include "analyzer/LLVMAnalyses.h"
#include "analyzer/LoopCatalog.h"

#include <llvm/Analysis/AssumptionCache.h>
#include <llvm/Analysis/BasicAliasAnalysis.h>
#include <llvm/Analysis/DependenceAnalysis.h>
#include <llvm/Analysis/IVDescriptors.h>
#include <llvm/Analysis/MemoryLocation.h>
#include <llvm/Analysis/ScalarEvolutionExpressions.h>
#include <llvm/Analysis/ScopedNoAliasAA.h>
#include <llvm/Analysis/TypeBasedAliasAnalysis.h>
#include <llvm/Analysis/ValueTracking.h>
#include <llvm/IR/CFG.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Module.h>
#include <llvm/Transforms/Utils/Cloning.h>

#include <algorithm>
#include <functional>
#include <map>
#include <set>

namespace analyzer {

namespace {

/// Does `V` come (through arithmetic/casts) from a load inside `L`?
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

/// Express a byte step in elements, e.g. "4 * n" bytes with 4-byte floats
/// becomes "n".
std::string symbolicElements(const llvm::SCEV* step, uint64_t elemBytes) {
  if (const auto* M = llvm::dyn_cast<llvm::SCEVMulExpr>(step)) {
    if (const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(M->getOperand(0))) {
      int64_t c = C->getAPInt().getSExtValue();
      if (elemBytes && c % (int64_t)elemBytes == 0) {
        int64_t k = c / (int64_t)elemBytes;
        std::string rest;
        for (unsigned i = 1; i < M->getNumOperands(); ++i)
          rest += (rest.empty() ? "" : " * ") + prettySCEV(M->getOperand(i));
        return k == 1 ? rest : std::to_string(k) + " * " + rest;
      }
    }
  }
  return prettySCEV(step) + " bytes";
}

/// A phi whose every incoming value is invariant in X. The vectorizer's
/// scalar remainder loop starts its counter from such a "resume value"
/// (vector-loop end or 0); ScalarEvolution can't fold it, but it doesn't
/// move as X advances.
bool isResumeValue(const llvm::Value* V, const llvm::Loop* X,
                   llvm::ScalarEvolution& SE) {
  const auto* Phi = llvm::dyn_cast<llvm::PHINode>(V);
  if (!Phi || !SE.isSCEVable(Phi->getType()))
    return false;
  for (const llvm::Value* In : Phi->incoming_values())
    if (!SE.isLoopInvariant(SE.getSCEV(const_cast<llvm::Value*>(In)), X))
      return false;
  return true;
}

/// Does E change as loop X advances (ignoring resume values)?
bool variesWith(const llvm::SCEV* E, const llvm::Loop* X,
                llvm::ScalarEvolution& SE) {
  return llvm::SCEVExprContains(E, [&](const llvm::SCEV* T) {
    if (const auto* U = llvm::dyn_cast<llvm::SCEVUnknown>(T)) {
      const auto* I = llvm::dyn_cast<llvm::Instruction>(U->getValue());
      return I && X->contains(I) && !isResumeValue(I, X, SE);
    }
    if (const auto* AR = llvm::dyn_cast<llvm::SCEVAddRecExpr>(T))
      return X->contains(AR->getLoop());
    return false;
  });
}

/// Find the per-iteration step of S along loop X. Returns false if S is not
/// affine in X; `*step` is null when S doesn't move with X.
///
/// SCEV writes a nested-loop address as an add-recurrence per loop, inner
/// loops outermost: {{B,+,4n}<i>,+,4}<k>. The recurrence for an outer loop
/// sits in the start value, possibly under sums and constant factors
/// (4 * (n*r + {0,+,1}<j>)), so we recurse through those.
bool findStep(const llvm::SCEV* S, const llvm::Loop* X,
              llvm::ScalarEvolution& SE, const llvm::SCEV** step) {
  *step = nullptr;
  if (const auto* AR = llvm::dyn_cast<llvm::SCEVAddRecExpr>(S)) {
    if (AR->getLoop() == X) {
      if (!AR->isAffine())
        return false;
      *step = AR->getStepRecurrence(SE);
      return true;
    }
    return findStep(AR->getStart(), X, SE, step);
  }
  if (const auto* Add = llvm::dyn_cast<llvm::SCEVAddExpr>(S)) {
    for (const llvm::SCEV* Op : Add->operands()) {
      const llvm::SCEV* s = nullptr;
      if (!findStep(Op, X, SE, &s))
        return false;
      if (s)
        *step = *step ? SE.getAddExpr(*step, s) : s;
    }
    return true;
  }
  if (const auto* Mul = llvm::dyn_cast<llvm::SCEVMulExpr>(S)) {
    // Affine only if a single factor moves with X.
    const llvm::SCEV* moving = nullptr;
    llvm::SmallVector<const llvm::SCEV*, 4> factors;
    for (const llvm::SCEV* Op : Mul->operands()) {
      if (!variesWith(Op, X, SE)) {
        factors.push_back(Op);
      } else if (moving) {
        return false;
      } else {
        moving = Op;
      }
    }
    if (!moving)
      return true;
    const llvm::SCEV* s = nullptr;
    if (!findStep(moving, X, SE, &s))
      return false;
    if (s) {
      factors.push_back(s);
      *step = SE.getMulExpr(factors);
    }
    return true;
  }
  return !variesWith(S, X, SE);
}

/// Stride for a known per-iteration byte step.
Stride strideFromStep(const llvm::SCEV* step, uint64_t elemBytes) {
  Stride out;
  if (const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(step)) {
    int64_t bytes = C->getAPInt().getSExtValue();
    int64_t e = (int64_t)elemBytes;
    if (bytes == 0)
      out.kind = Stride::Kind::Invariant;
    else if (bytes == e)
      out.kind = Stride::Kind::Sequential;
    else if (bytes == -e)
      out.kind = Stride::Kind::Reverse;
    else {
      out.kind = Stride::Kind::Constant;
      out.elements = (e && bytes % e == 0) ? bytes / e : bytes;
    }
    return out;
  }
  out.kind = Stride::Kind::Symbolic;
  out.symbolic = symbolicElements(step, elemBytes);
  return out;
}

/// Stride of address expression `S` with respect to loop `X`.
Stride strideFor(const llvm::SCEV* S, const llvm::Loop* X,
                 llvm::ScalarEvolution& SE, uint64_t elemBytes,
                 const llvm::Loop* innermost) {
  Stride out;
  const llvm::SCEV* step = nullptr;
  if (!findStep(S, X, SE, &step)) {
    // Not affine in X. Note whether that's because it's built from loaded
    // data (x[idx[i]]).
    out.dataDependent = llvm::SCEVExprContains(S, [&](const llvm::SCEV* E) {
      const auto* U = llvm::dyn_cast<llvm::SCEVUnknown>(E);
      return U && derivesFromLoadIn(U->getValue(), innermost);
    });
    return out;
  }
  if (!step) {
    out.kind = Stride::Kind::Invariant;
    return out;
  }
  return strideFromStep(step, elemBytes);
}

Diagnostic makeLoopDiag(FunctionAnalyses& FA, const LogicalLoop& LL) {
  Diagnostic d;
  d.category = DiagnosticCategory::Memory;
  d.functionName = FA.function().getName().str();
  d.loop = LL.describe();
  d.loopOrder = LL.order;
  return d;
}

std::string strideInLoop(const MemoryAccess& A, const llvm::Loop* L) {
  for (const auto& [loop, stride] : A.strides)
    if (loop == L)
      return stride.text();
  return "?";
}

const Stride* strideFor(const MemoryAccess& A, const llvm::Loop* L) {
  for (const auto& entry : A.strides)
    if (entry.first == L)
      return &entry.second;
  return nullptr;
}

std::string restrictAdvice(const std::set<std::string>& params) {
  std::string names;
  for (const auto& p : params)
    names += (names.empty() ? "" : ", ") + p;
  return "Add `restrict` (C) / `__restrict` (C++) to " + names +
         " if they never overlap.";
}

/// Pointer parameters (without noalias) that the given pointers come from.
void collectParams(const llvm::Value* ptr, std::set<std::string>& out) {
  const llvm::Value* base = llvm::getUnderlyingObject(ptr);
  if (const auto* A = llvm::dyn_cast<llvm::Argument>(base))
    if (!A->hasNoAliasAttr())
      out.insert(valueName(A));
}

// ---------------------------------------------------------------------------
// Access pattern summary
// ---------------------------------------------------------------------------

void reportAccessPattern(FunctionAnalyses& FA, const LoopCatalog& catalog,
                         const LogicalLoop& LL,
                         const std::vector<MemoryAccess>& accesses,
                         AnalysisContext& ctx) {
  Diagnostic d = makeLoopDiag(FA, LL);
  d.severity = DiagnosticSeverity::Note;
  unsigned friendly = 0;
  for (const MemoryAccess& A : accesses) {
    std::string line = A.describe() + ": " + A.inner().text();
    for (size_t i = 1; i < A.strides.size(); ++i) {
      const LogicalLoop* outer = catalog.find(A.strides[i].first);
      line += "; " + A.strides[i].second.text() + " across " +
              (outer ? outer->label() : std::string("enclosing loop"));
    }
    d.evidence.push_back(line);
    if (A.inner().isCacheFriendly())
      ++friendly;
  }
  d.message = "Memory access pattern: " + std::to_string(friendly) + " of " +
              std::to_string(accesses.size()) +
              " accesses are sequential or fixed-address";
  d.basis = "ScalarEvolution (address as a function of loop counters)";
  ctx.getEmitter().add(std::move(d));
}

// ---------------------------------------------------------------------------
// Loop interchange
// ---------------------------------------------------------------------------

struct SwapSafety {
  bool proven = true;
  /// DependenceAnalysis found an exact dependence the swap would reverse:
  /// swapping changes results, not merely "unproven".
  bool reversesDependence = false;
  std::vector<std::string> reasons;
  /// Unrestricted pointer parameters in pairs of *different* arrays that
  /// DependenceAnalysis couldn't tell apart. Only these can be fixed by
  /// `restrict`.
  std::set<std::string> overlapParams;
  void fail(std::string reason) {
    proven = false;
    if (std::find(reasons.begin(), reasons.end(), reason) == reasons.end())
      reasons.push_back(std::move(reason));
  }
};

bool isMemoryAccess(const llvm::Instruction& I) {
  return llvm::isa<llvm::LoadInst>(I) || llvm::isa<llvm::StoreInst>(I);
}

std::string describeInst(const llvm::Instruction* I) {
  std::string what;
  if (const auto* Ld = llvm::dyn_cast<llvm::LoadInst>(I))
    what = "load of " + pointerBaseName(Ld->getPointerOperand());
  else if (const auto* St = llvm::dyn_cast<llvm::StoreInst>(I))
    what = "store to " + pointerBaseName(St->getPointerOperand());
  else if (const auto* CB = llvm::dyn_cast<llvm::CallBase>(I))
    what = "call to " + valueName(CB->getCalledOperand());
  else
    what = I->getOpcodeName();
  std::string line = sourceLine(I);
  return line.empty() ? what : what + " (" + line + ")";
}

/// Direction sets use DependenceAnalysis's encoding: LT=1, EQ=2, GT=4, and
/// unions of those (LE=3, NE=5, GE=6, ALL=7).
const unsigned kLT = llvm::Dependence::DVEntry::LT;
const unsigned kEQ = llvm::Dependence::DVEntry::EQ;
const unsigned kGT = llvm::Dependence::DVEntry::GT;

/// First non-"=" entry of a concrete direction vector, or kEQ if all are.
unsigned leading(const std::vector<unsigned>& v) {
  for (unsigned d : v)
    if (d != kEQ)
      return d;
  return kEQ;
}

/// Is swapping levels `a` and `b` legal for every concrete direction vector
/// DependenceAnalysis allows?
///
/// LLVM 15's DependenceAnalysis doesn't normalize: a vector whose first
/// non-"=" entry is ">" describes a dependence running from Dst to Src, so
/// it is reversed first (as LoopInterchange does). The dependence must then
/// still run forward after the swap.
bool swapPreservesOrder(const std::vector<unsigned>& dirs, unsigned a,
                        unsigned b) {
  std::vector<unsigned> v(dirs.size());
  std::function<bool(size_t)> all = [&](size_t i) -> bool {
    if (i == dirs.size()) {
      std::vector<unsigned> w = v;
      if (leading(w) == kGT)
        for (unsigned& d : w)
          d = d == kLT ? kGT : d == kGT ? kLT : d;
      std::swap(w[a], w[b]);
      return leading(w) != kGT;
    }
    for (unsigned d : {kLT, kEQ, kGT})
      if (dirs[i] & d) {
        v[i] = d;
        if (!all(i + 1))
          return false;
      }
    return true;
  };
  return all(0);
}

std::string directionText(const std::vector<unsigned>& dirs) {
  static const char* names[] = {"", "<", "=", "<=", ">", "!=", ">=", "*"};
  std::string out = "(";
  for (size_t i = 0; i < dirs.size(); ++i)
    out += (i ? "," : "") + std::string(names[dirs[i] & 7]);
  return out + ")";
}

/// Exact source locations (with inlining) of the memory accesses in `inner`.
/// The unroller can leave a remainder iteration as straight-line code
/// after the loop; accesses there with the same location are copies of the
/// inner loop's body, not work between the two loops.
std::set<std::string> accessLocations(const llvm::Loop* inner) {
  std::set<std::string> out;
  for (llvm::BasicBlock* BB : inner->blocks())
    for (llvm::Instruction& I : *BB)
      if (isMemoryAccess(I)) {
        std::string loc = formatDebugLoc(I.getDebugLoc());
        if (!loc.empty())
          out.insert(loc + "|" + inlinedAtChain(I.getDebugLoc()));
      }
  return out;
}

bool copiesInnerAccess(const llvm::Instruction& I,
                       const std::set<std::string>& innerLocs) {
  std::string loc = formatDebugLoc(I.getDebugLoc());
  return !loc.empty() &&
         innerLocs.count(loc + "|" + inlinedAtChain(I.getDebugLoc()));
}

/// Swapping `outer` with its child `inner` is safe if no memory dependence
/// would run backwards afterwards and the inner loop's bounds don't depend
/// on the outer loop's counter.
SwapSafety checkSwapIn(llvm::Function& F, llvm::LoopInfo& LI,
                       llvm::ScalarEvolution& SE, llvm::AAResults& AA,
                       llvm::Loop* outer, llvm::Loop* inner,
                       const std::set<const llvm::Loop*>& skip) {
  SwapSafety result;

  // A triangular nest (for j < i) can't be swapped by reordering the loop
  // headers alone.
  const llvm::SCEV* btc = SE.getBackedgeTakenCount(inner);
  if (llvm::isa<llvm::SCEVCouldNotCompute>(btc))
    result.fail("the inner loop's iteration count can't be computed");
  else if (!SE.isLoopInvariant(btc, outer))
    result.fail("the inner loop's bounds depend on the outer loop's counter "
                "(a triangular nest); both loops' bounds would need "
                "rewriting");
  for (llvm::PHINode& Phi : inner->getHeader()->phis()) {
    if (!SE.isSCEVable(Phi.getType()))
      continue;
    const auto* AR = llvm::dyn_cast<llvm::SCEVAddRecExpr>(SE.getSCEV(&Phi));
    if (AR && AR->getLoop() == inner &&
        !SE.isLoopInvariant(AR->getStart(), outer))
      result.fail("the inner loop's start depends on the outer loop's "
                  "counter (a triangular nest); both loops' bounds would "
                  "need rewriting");
  }

  llvm::DependenceInfo DI(&F, &AA, &SE, &LI);
  std::vector<llvm::Instruction*> mem;
  std::set<std::string> innerLocs = accessLocations(inner);
  for (llvm::BasicBlock* BB : outer->blocks()) {
    if (skip.count(LI.getLoopFor(BB)))
      continue;
    bool inInner = inner->contains(BB);
    for (llvm::Instruction& I : *BB) {
      if (!inInner && copiesInnerAccess(I, innerLocs))
        continue;
      if (isMemoryAccess(I))
        mem.push_back(&I);
      else if (I.mayReadOrWriteMemory() &&
               !llvm::isa<llvm::DbgInfoIntrinsic>(I))
        result.fail(describeInst(&I) +
                    " has effects DependenceAnalysis can't see");
    }
  }

  unsigned levelOuter = outer->getLoopDepth();
  unsigned levelInner = inner->getLoopDepth();
  for (size_t i = 0; i < mem.size(); ++i) {
    for (size_t j = i; j < mem.size(); ++j) {
      llvm::Instruction* Src = mem[i];
      llvm::Instruction* Dst = mem[j];
      if (!Src->mayWriteToMemory() && !Dst->mayWriteToMemory())
        continue;
      std::unique_ptr<llvm::Dependence> D = DI.depends(Src, Dst, true);
      if (!D)
        continue;  // Proven independent.
      std::string pair = Src == Dst
                             ? describeInst(Src) + " in different iterations"
                             : describeInst(Src) + " and " + describeInst(Dst);
      const llvm::Value* sp = llvm::getLoadStorePointerOperand(Src);
      const llvm::Value* dp = llvm::getLoadStorePointerOperand(Dst);
      bool differentArrays =
          llvm::getUnderlyingObject(sp) != llvm::getUnderlyingObject(dp);
      if (D->isConfused()) {
        result.fail(pair + " may touch the same memory");
        if (differentArrays) {
          collectParams(sp, result.overlapParams);
          collectParams(dp, result.overlapParams);
        }
        continue;
      }
      bool bothInner = inner->contains(Src) && inner->contains(Dst);
      if (!bothInner || D->getLevels() < levelInner) {
        result.fail(pair + " depend on each other across the two loops");
        continue;
      }
      std::vector<unsigned> dirs;
      bool exact = D->isConsistent();
      for (unsigned l = 1; l <= D->getLevels(); ++l) {
        unsigned dir = D->getDirection(l) & 7;
        dirs.push_back(dir);
        exact &= dir == kLT || dir == kEQ || dir == kGT;
      }
      if (swapPreservesOrder(dirs, levelOuter - 1, levelInner - 1))
        continue;
      if (exact) {
        result.reversesDependence = true;
        result.fail(pair + ": dependence direction " + directionText(dirs) +
                    " would run backwards after the swap");
      } else {
        result.fail(pair + ": dependence direction " + directionText(dirs) +
                    " may run backwards after the swap");
      }
      if (differentArrays) {
        collectParams(sp, result.overlapParams);
        collectParams(dp, result.overlapParams);
      }
    }
  }
  return result;
}

/// A throwaway copy of a function with its own analyses. Erased on
/// destruction, so the input module is left as it was.
class ScratchFunction {
public:
  explicit ScratchFunction(llvm::Function& F)
      : clone(llvm::CloneFunction(&F, VMap)),
        TLII(llvm::Triple(F.getParent()->getTargetTriple())), TLI(TLII),
        AC(*clone), DT(*clone), LI(DT), SE(*clone, TLI, AC, DT, LI),
        BasicAA(F.getParent()->getDataLayout(), *clone, TLI, AC, &DT), AA(TLI) {
    AA.addAAResult(BasicAA);
    AA.addAAResult(TBAA);
    AA.addAAResult(ScopedAA);
  }
  ~ScratchFunction() {
    clone->eraseFromParent();
  }

  llvm::Loop* mapLoop(const llvm::Loop* L) {
    auto* header = llvm::cast<llvm::BasicBlock>(VMap[L->getHeader()]);
    return LI.getLoopFor(header);
  }
  llvm::Instruction* map(const llvm::Instruction* I) {
    return llvm::cast<llvm::Instruction>(VMap[I]);
  }
  /// What `restrict` on these parameters would tell alias analysis.
  void markNoAlias(const std::set<std::string>& params) {
    for (llvm::Argument& A : clone->args())
      if (A.getType()->isPointerTy() && params.count(valueName(&A)))
        A.addAttr(llvm::Attribute::NoAlias);
  }

  llvm::ValueToValueMapTy VMap;
  llvm::Function* clone;
  llvm::TargetLibraryInfoImpl TLII;
  llvm::TargetLibraryInfo TLI;
  llvm::AssumptionCache AC;
  llvm::DominatorTree DT;
  llvm::LoopInfo LI;
  llvm::ScalarEvolution SE;
  llvm::BasicAAResult BasicAA;
  llvm::TypeBasedAAResult TBAA;
  llvm::ScopedNoAliasAAResult ScopedAA;
  llvm::AAResults AA;
};

/// `noalias`: also check as if these parameters were `restrict`.
SwapSafety checkSwap(FunctionAnalyses& FA, const LogicalLoop& LL,
                     llvm::Loop* outer, llvm::Loop* inner,
                     const std::set<std::string>& noalias = {}) {
  // The vectorizer's other copies of the inner loop are the same source loop,
  // not extra work between the two loops.
  std::set<const llvm::Loop*> skip;
  for (llvm::Loop* C : LL.copies)
    if (C != inner)
      skip.insert(C);
  if (skip.empty() && noalias.empty())
    return checkSwapIn(FA.function(), FA.loopInfo(), FA.scev(), FA.alias(),
                       outer, inner, skip);

  ScratchFunction scratch(FA.function());
  scratch.markNoAlias(noalias);
  llvm::Loop* sInner = scratch.mapLoop(inner);
  // The scalar copy left by the vectorizer starts at a "resume" value merged
  // from the vector loop's exit, which DependenceAnalysis can't see through.
  // In the scratch copy, start it where the source loop starts instead;
  // that is the loop whose dependences we care about.
  std::set<const llvm::BasicBlock*> fromCopies;
  std::set<const llvm::Loop*> sSkip;
  for (const llvm::Loop* C : skip) {
    llvm::Loop* SC = scratch.mapLoop(C);
    sSkip.insert(SC);
    llvm::SmallVector<llvm::BasicBlock*, 4> exits;
    SC->getExitBlocks(exits);
    for (llvm::BasicBlock* E : exits) {
      fromCopies.insert(E);
      // LLVM's vectorizer exits into a "middle block" that then branches on.
      if (llvm::BasicBlock* next = E->getSingleSuccessor())
        fromCopies.insert(next);
      for (llvm::BasicBlock* S : llvm::successors(E))
        fromCopies.insert(S);
    }
  }
  if (!skip.empty())
    if (llvm::BasicBlock* pre = sInner->getLoopPreheader()) {
      std::vector<llvm::PHINode*> resumes;
      for (llvm::PHINode& Phi : pre->phis())
        resumes.push_back(&Phi);
      for (llvm::PHINode* Phi : resumes) {
        llvm::Value* original = nullptr;
        for (unsigned i = 0; i < Phi->getNumIncomingValues(); ++i)
          if (!fromCopies.count(Phi->getIncomingBlock(i)))
            original = Phi->getIncomingValue(i);
        if (original) {
          Phi->replaceAllUsesWith(original);
          Phi->eraseFromParent();
        }
      }
    }
  scratch.SE.forgetLoop(sInner);
  return checkSwapIn(*scratch.clone, scratch.LI, scratch.SE, scratch.AA,
                     sInner->getParentLoop(), sInner, sSkip);
}

void reportInterchange(FunctionAnalyses& FA, const LoopCatalog& catalog,
                       const LogicalLoop& LL,
                       const std::vector<MemoryAccess>& accesses,
                       AnalysisContext& ctx) {
  llvm::Loop* L = LL.scalar;
  llvm::Loop* P = L->getParentLoop();
  if (!P)
    return;
  const LogicalLoop* parent = catalog.find(P);

  // Which inner-loop accesses get better or worse if P becomes innermost?
  std::vector<const MemoryAccess*> improves, worsens;
  for (const MemoryAccess& A : accesses) {
    const Stride* inP = strideFor(A, P);
    if (!inP)
      continue;
    bool nowGood = A.inner().isCacheFriendly();
    bool thenGood = inP->isCacheFriendly();
    if (!nowGood && thenGood)
      improves.push_back(&A);
    else if (nowGood && !thenGood)
      worsens.push_back(&A);
  }
  if (improves.empty() || improves.size() <= worsens.size())
    return;

  Diagnostic d = makeLoopDiag(FA, LL);
  d.severity = DiagnosticSeverity::Warning;
  std::string parentLabel = parent ? parent->label() : "the enclosing loop";
  d.message = improves.front()->base + " is walked with a stride (" +
              improves.front()->inner().text() + "); swapping this loop with " +
              parentLabel + " makes it sequential";

  for (const MemoryAccess* A : improves)
    d.evidence.push_back(A->describe() + ": " + A->inner().text() + " now -> " +
                         strideInLoop(*A, P) + " after the swap");
  for (const MemoryAccess* A : worsens)
    d.evidence.push_back(A->describe() + ": " + A->inner().text() + " now -> " +
                         strideInLoop(*A, P) + " after the swap (gets worse)");

  // Work sitting between the two loops means they aren't perfectly nested.
  std::vector<std::string> between;
  std::set<std::string> innerLocs = accessLocations(L);
  for (llvm::BasicBlock* BB : P->blocks()) {
    if (FA.loopInfo().getLoopFor(BB) != P)
      continue;
    bool inCopy = false;
    for (llvm::Loop* C : LL.copies)
      inCopy |= C->contains(BB);
    if (inCopy)
      continue;
    for (llvm::Instruction& I : *BB)
      if (isMemoryAccess(I) && !copiesInnerAccess(I, innerLocs))
        between.push_back(describeInst(&I));
  }
  // A running value carried by the inner loop (e.g. `sum`) must become a
  // memory update once the loops are swapped.
  bool carriesValue = false;
  if (L->getLoopPreheader() && L->getLoopLatch())
    for (llvm::PHINode& Phi : L->getHeader()->phis()) {
      llvm::InductionDescriptor ID;
      if (!llvm::InductionDescriptor::isInductionPHI(&Phi, L, &FA.scev(),
                                                     ID)) {
        carriesValue = true;
        break;
      }
    }
  bool perfect = between.empty() && !carriesValue;

  SwapSafety safety = checkSwap(FA, LL, P, L);
  std::string reorder =
      "reorder the loops so " + LL.label() + " is outside " + parentLabel;
  if (safety.proven) {
    d.evidence.push_back(
        std::string("DependenceAnalysis: no memory dependence is reversed by "
                    "the swap") +
        (perfect ? "" : " (checked for the accesses as written now)"));
  } else {
    d.evidence.push_back(safety.reversesDependence
                             ? "DependenceAnalysis: swapping would reverse a "
                               "dependence, changing the results:"
                             : "DependenceAnalysis could not prove the swap "
                               "safe:");
    for (size_t i = 0; i < safety.reasons.size() && i < 3; ++i)
      d.evidence.push_back("  " + safety.reasons[i]);
  }
  d.evidence.push_back(
      "LLVM's loop-interchange pass is not in the default -O2 pipeline, so "
      "the compiler will not do this for you");

  if (safety.reversesDependence) {
    d.suggestions.push_back(
        "Don't swap these loops as they are: a later iteration needs a value "
        "an earlier one computes in the current order. Improving locality "
        "here needs a different traversal (e.g. skewing or blocking), "
        "written by hand.");
  } else if (safety.proven) {
    std::string r = reorder;
    r[0] = 'R';
    d.suggestions.push_back(r + ".");
  } else {
    std::set<std::string> params = safety.overlapParams;
    bool restrictWorks = false;
    if (!params.empty()) {
      SwapSafety withRestrict = checkSwap(FA, LL, P, L, params);
      restrictWorks = withRestrict.proven;
      if (restrictWorks)
        d.suggestions.push_back(
            restrictAdvice(params) +
            " Checked: with them, DependenceAnalysis proves the swap safe; "
            "then " + reorder + ".");
    }
    if (!restrictWorks)
      d.suggestions.push_back(
          "Only if you know the reasons above can't happen (no iteration "
          "uses a value that the swap would compute later): " + reorder +
          ". Otherwise the swap changes results.");
  }
  if (!perfect && !safety.reversesDependence)
    d.suggestions.push_back(
        "The loops aren't perfectly nested" +
        (between.empty() ? std::string("")
                         : " (" + between.front() + " sits between them)") +
        (carriesValue ? "; the inner loop's running value must be "
                        "accumulated in memory instead (e.g. C[i][j] += ...)"
                      : "") +
        ". Re-check the swap on the rewritten loops.");
  d.basis = "ScalarEvolution strides + DependenceAnalysis direction vectors";
  ctx.getEmitter().add(std::move(d));
}

// ---------------------------------------------------------------------------
// Fixed-address accesses that stay in the loop
// ---------------------------------------------------------------------------

/// Does the vectorized copy still access this object at a fixed address?
/// If not, the fast path hoisted it and only the fallback copy has it.
bool stillInVectorBody(const LogicalLoop& LL, const llvm::Value* base,
                       FunctionAnalyses& FA) {
  if (!LL.vectorBody)
    return true;
  for (llvm::BasicBlock* BB : LL.vectorBody->blocks())
    for (llvm::Instruction& I : *BB)
      if (llvm::Value* ptr = llvm::getLoadStorePointerOperand(&I))
        if (llvm::getUnderlyingObject(ptr) == base &&
            FA.scev().isLoopInvariant(FA.scev().getSCEV(ptr), LL.vectorBody))
          return true;
  return false;
}

/// Does `I` run on every iteration of L that completes? LICM can only
/// hoist a load or sink a store under that condition, so only then is
/// aliasing the reason it stayed.
bool runsEveryIteration(const llvm::Instruction* I, llvm::Loop* L,
                        llvm::DominatorTree& DT) {
  llvm::BasicBlock* latch = L->getLoopLatch();
  if (!latch || !DT.dominates(I->getParent(), latch))
    return false;
  llvm::SmallVector<llvm::BasicBlock*, 4> exiting;
  L->getExitingBlocks(exiting);
  for (llvm::BasicBlock* E : exiting)
    if (!DT.dominates(I->getParent(), E))
      return false;
  return true;
}

struct SlotUse {
  std::vector<llvm::Instruction*> sameSlot, blockers;
  bool written = false;
};

/// Accesses to the same address as `I` in L, and everything else in L that
/// might touch it according to `AA`.
SlotUse slotUse(llvm::Instruction* I, llvm::Loop* L, llvm::AAResults& AA) {
  SlotUse u;
  llvm::MemoryLocation loc = llvm::MemoryLocation::get(I);
  for (llvm::BasicBlock* B : L->blocks())
    for (llvm::Instruction& A : *B)
      if (isMemoryAccess(A) && AA.alias(llvm::MemoryLocation::get(&A), loc) ==
                                   llvm::AliasResult::MustAlias) {
        u.sameSlot.push_back(&A);
        u.written |= llvm::isa<llvm::StoreInst>(A);
      }
  for (llvm::BasicBlock* B : L->blocks())
    for (llvm::Instruction& A : *B) {
      if (!A.mayReadOrWriteMemory() ||
          std::find(u.sameSlot.begin(), u.sameSlot.end(), &A) !=
              u.sameSlot.end())
        continue;
      llvm::ModRefInfo mr = AA.getModRefInfo(&A, loc);
      // A read-only slot is blocked only by writers; a written slot is
      // also blocked by anything that might read it.
      if (u.written ? llvm::isModOrRefSet(mr) : llvm::isModSet(mr))
        u.blockers.push_back(&A);
    }
  return u;
}

/// In optimized IR, LICM has already hoisted every fixed-address load and
/// sunk every fixed-address store it legally could (and GVN has replaced
/// repeated loads with registers). A fixed-address access that runs on
/// every iteration and is still inside the loop means something in the loop
/// might touch the same memory. Alias analysis tells us what.
void reportFixedAddressAccesses(FunctionAnalyses& FA, const LogicalLoop& LL,
                                AnalysisContext& ctx) {
  llvm::Loop* L = LL.scalar;
  llvm::ScalarEvolution& SE = FA.scev();
  std::set<const llvm::Value*> reported;

  for (llvm::BasicBlock* BB : L->blocks()) {
    if (FA.loopInfo().getLoopFor(BB) != L)
      continue;
    for (llvm::Instruction& I : *BB) {
      llvm::Value* ptr = llvm::getLoadStorePointerOperand(&I);
      if (!ptr || !SE.isLoopInvariant(SE.getSCEV(ptr), L))
        continue;
      if (auto* Ld = llvm::dyn_cast<llvm::LoadInst>(&I); Ld && !Ld->isSimple())
        continue;
      if (auto* St = llvm::dyn_cast<llvm::StoreInst>(&I); St && !St->isSimple())
        continue;
      const llvm::Value* base = llvm::getUnderlyingObject(ptr);
      if (reported.count(base) || !stillInVectorBody(LL, base, FA))
        continue;

      SlotUse use = slotUse(&I, L, FA.alias());
      if (use.blockers.empty())
        continue;  // Something else kept it here; don't guess.
      // A conditional access stays in the loop regardless of aliasing.
      bool everyIteration = true;
      for (llvm::Instruction* A : use.sameSlot)
        if (llvm::isa<llvm::StoreInst>(A) || A == &I)
          everyIteration &= runsEveryIteration(A, L, FA.domTree());
      if (!everyIteration)
        continue;

      Diagnostic d = makeLoopDiag(FA, LL);
      d.severity = DiagnosticSeverity::Warning;
      std::string name = pointerBaseName(ptr);
      std::set<std::string> params;
      collectParams(ptr, params);

      if (use.written) {
        d.message = name + " is written to memory every iteration instead of "
                           "being kept in a register";
        for (llvm::Instruction* A : use.sameSlot)
          d.evidence.push_back(describeInst(A) +
                               ": same address every iteration");
      } else {
        d.message = "Load of " + name +
                    " repeats every iteration; it can't be hoisted because "
                    "the loop might overwrite it";
        d.evidence.push_back(describeInst(&I) +
                             ": same address every iteration");
      }
      for (llvm::Instruction* B : use.blockers) {
        d.evidence.push_back(
            describeInst(B) +
            (use.written ? " might access " : " might overwrite ") + name +
            "'s memory");
        if (const auto* bp = llvm::getLoadStorePointerOperand(B)) {
          collectParams(bp, params);
          continue;
        }
        const auto* CB = llvm::dyn_cast<llvm::CallBase>(B);
        if (!CB)
          continue;
        std::string callee = valueName(CB->getCalledOperand());
        // A value kept in a register must not be read behind its back
        // either, so a written slot needs `const`; `pure` (reads only) is
        // enough for a slot the loop only reads.
        if (use.written) {
          if (!CB->doesNotAccessMemory())
            d.suggestions.push_back(
                "Mark " + callee + " `__attribute__((const))` if it neither "
                "reads nor writes memory (`pure` isn't enough: it could still "
                "read " + name + ").");
        } else if (!CB->onlyReadsMemory()) {
          d.suggestions.push_back("Mark " + callee +
                                  " `__attribute__((pure))` (or `const`) if "
                                  "it doesn't write memory.");
        }
      }
      d.suggestions.push_back(
          use.written
              ? "If nothing else in the loop touches " + name +
                    "'s memory, keep the value in a local variable: read it "
                    "before the loop, update the local, and write it back "
                    "once after the loop."
              : "If the loop never writes " + name +
                    "'s memory, read it into a local variable before the "
                    "loop.");
      if (!params.empty()) {
        // Would `restrict` let alias analysis rule out every blocker?
        ScratchFunction scratch(FA.function());
        scratch.markNoAlias(params);
        llvm::Loop* sL = scratch.mapLoop(L);
        SlotUse after = slotUse(scratch.map(&I), sL, scratch.AA);
        if (after.blockers.empty())
          d.suggestions.push_back(
              restrictAdvice(params) +
              " Checked: alias analysis then rules out every conflict, so "
              "LICM can keep " + name + " in a register.");
      }
      d.basis = "alias analysis (BasicAA + TBAA): what may touch this address";
      reported.insert(base);
      ctx.getEmitter().add(std::move(d));
    }
  }
}

}  // namespace

std::string Stride::text() const {
  switch (kind) {
    case Kind::Invariant:
      return "same address every iteration";
    case Kind::Sequential:
      return "sequential";
    case Kind::Reverse:
      return "sequential (backwards)";
    case Kind::Constant:
      return "stride " + std::to_string(elements) + " elements";
    case Kind::Symbolic:
      return "stride " + symbolic + " elements";
    case Kind::Irregular:
      return dataDependent ? "address depends on data loaded in the loop"
                           : "not an affine function of the loop counter";
  }
  return "?";
}

std::string MemoryAccess::describe() const {
  std::string out = (isStore ? "store to " : "load of ") + base;
  return line.empty() ? out : out + " (" + line + ")";
}

namespace {

/// If the k addresses in `ptrs` are one source iteration apart, i.e. they
/// are S, S+d, ..., S+(k-1)d in some order and the loop advances them by
/// k*d, returns d.
const llvm::SCEV* unrolledStep(const std::vector<llvm::Value*>& ptrs,
                               const llvm::Loop* L,
                               llvm::ScalarEvolution& SE) {
  unsigned k = ptrs.size();
  const llvm::SCEV* S0 = SE.getSCEV(ptrs[0]);
  const llvm::SCEV* step = nullptr;
  if (!findStep(S0, L, SE, &step) || !step)
    return nullptr;
  std::vector<const llvm::SCEV*> diffs;
  for (unsigned j = 1; j < k; ++j)
    diffs.push_back(SE.getMinusSCEV(SE.getSCEV(ptrs[j]), S0));
  const llvm::SCEV* K = SE.getConstant(step->getType(), k);
  for (const llvm::SCEV* d : diffs) {
    for (const llvm::SCEV* cand : {d, SE.getNegativeSCEV(d)}) {
      if (SE.getMulExpr(K, cand) != step)
        continue;
      // Every copy must sit a distinct whole number of steps from S0.
      std::set<int> offsets{0};
      bool ok = true;
      for (const llvm::SCEV* other : diffs) {
        bool found = false;
        for (int m = -(int)k + 1; m < (int)k && !found; ++m)
          if (m && SE.getMulExpr(SE.getConstant(step->getType(), m, true),
                                 cand) == other)
            found = offsets.insert(m).second;
        ok &= found;
      }
      if (ok)
        return cand;
    }
  }
  return nullptr;
}

}  // namespace

std::vector<MemoryAccess> collectAccesses(llvm::Loop* L,
                                          llvm::ScalarEvolution& SE,
                                          llvm::LoopInfo& LI,
                                          unsigned* unrolledBy) {
  std::vector<MemoryAccess> out;
  if (unrolledBy)
    *unrolledBy = 1;
  const llvm::DataLayout& DL = L->getHeader()->getModule()->getDataLayout();
  for (llvm::BasicBlock* BB : L->blocks()) {
    if (LI.getLoopFor(BB) != L)
      continue;
    for (llvm::Instruction& I : *BB) {
      llvm::Value* ptr = llvm::getLoadStorePointerOperand(&I);
      if (!ptr)
        continue;
      MemoryAccess A;
      A.inst = &I;
      A.isStore = llvm::isa<llvm::StoreInst>(I);
      A.base = pointerBaseName(ptr);
      A.line = sourceLine(&I);
      uint64_t elemBytes =
          DL.getTypeStoreSize(llvm::getLoadStoreType(&I)).getFixedSize();
      const llvm::SCEV* S = SE.getSCEV(ptr);
      for (llvm::Loop* X = L; X; X = X->getParentLoop())
        A.strides.push_back({X, strideFor(S, X, SE, elemBytes, L)});
      out.push_back(std::move(A));
    }
  }

  // Fold unrolled copies: same debug location (line, column, inlining),
  // same kind, same array. Only when every access has the same number of
  // copies and they line up one source iteration apart.
  std::map<std::string, std::vector<size_t>> copies;
  for (size_t i = 0; i < out.size(); ++i) {
    const llvm::DebugLoc& DLoc = out[i].inst->getDebugLoc();
    std::string loc = formatDebugLoc(DLoc);
    if (loc.empty())
      return out;
    copies[loc + "|" + inlinedAtChain(DLoc) + "|" +
           (out[i].isStore ? "s" : "l") + "|" + out[i].base]
        .push_back(i);
  }
  size_t k = copies.empty() ? 0 : copies.begin()->second.size();
  if (k < 2)
    return out;
  std::vector<std::pair<size_t, const llvm::SCEV*>> folded;
  for (const auto& [key, idx] : copies) {
    if (idx.size() != k)
      return out;
    std::vector<llvm::Value*> ptrs;
    for (size_t i : idx)
      ptrs.push_back(llvm::getLoadStorePointerOperand(out[i].inst));
    const llvm::SCEV* d = unrolledStep(ptrs, L, SE);
    if (!d)
      return out;
    folded.push_back({idx.front(), d});
  }
  std::sort(folded.begin(), folded.end(),
            [](const auto& a, const auto& b) { return a.first < b.first; });
  std::vector<MemoryAccess> result;
  for (const auto& [i, d] : folded) {
    MemoryAccess A = std::move(out[i]);
    uint64_t elemBytes =
        DL.getTypeStoreSize(llvm::getLoadStoreType(A.inst)).getFixedSize();
    A.strides.front().second = strideFromStep(d, elemBytes);
    result.push_back(std::move(A));
  }
  if (unrolledBy)
    *unrolledBy = k;
  return result;
}

void MemoryAccessAnalyzer::run(FunctionAnalyses& FA, const LoopCatalog& catalog,
                               AnalysisContext& ctx) {
  for (const LogicalLoop& LL : catalog.loops()) {
    if (!LL.scalar)
      continue;
    reportFixedAddressAccesses(FA, LL, ctx);
    if (!LL.innermost)
      continue;
    std::vector<MemoryAccess> accesses =
        collectAccesses(LL.scalar, FA.scev(), FA.loopInfo());
    if (accesses.empty())
      continue;
    reportAccessPattern(FA, catalog, LL, accesses, ctx);
    reportInterchange(FA, catalog, LL, accesses, ctx);
  }
}

}  // namespace analyzer
