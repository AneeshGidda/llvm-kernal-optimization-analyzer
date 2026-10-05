#include "analyzer/GpuAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/IRNames.h"
#include "analyzer/LLVMAnalyses.h"
#include "analyzer/LoopCatalog.h"

#include <llvm/ADT/Triple.h>
#include <llvm/Analysis/ScalarEvolutionExpressions.h>
#include <llvm/Analysis/ValueTracking.h>
#include <llvm/Demangle/Demangle.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/InstIterator.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/IntrinsicInst.h>
#include <llvm/IR/IntrinsicsAMDGPU.h>
#include <llvm/IR/IntrinsicsNVPTX.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Operator.h>

#include <map>
#include <optional>
#include <set>

namespace analyzer {

bool isGpuModule(const llvm::Module& M) {
  llvm::Triple T(M.getTargetTriple());
  return T.isNVPTX() || T.isAMDGPU();
}

bool isGpuKernel(const llvm::Function& F) {
  if (F.getCallingConv() == llvm::CallingConv::PTX_Kernel ||
      F.getCallingConv() == llvm::CallingConv::AMDGPU_KERNEL)
    return true;
  const llvm::NamedMDNode* N =
      F.getParent()->getNamedMetadata("nvvm.annotations");
  if (!N)
    return false;
  for (const llvm::MDNode* Op : N->operands()) {
    if (Op->getNumOperands() < 3)
      continue;
    auto* fn = llvm::mdconst::dyn_extract_or_null<llvm::Function>(
        Op->getOperand(0));
    auto* key = llvm::dyn_cast_or_null<llvm::MDString>(Op->getOperand(1));
    auto* val =
        llvm::mdconst::dyn_extract_or_null<llvm::ConstantInt>(Op->getOperand(2));
    if (fn == &F && key && key->getString() == "kernel" && val &&
        !val->isZero())
      return true;
  }
  return false;
}

namespace {

/// "transpose_tiled(float const*, float*, int)" -> "transpose_tiled";
/// "_ZZ15transpose_tiledPKfPfiE4tile" -> "tile". Unmangled names unchanged.
std::string demangledShort(const std::string& name, bool lastComponent) {
  if (name.rfind("_Z", 0) != 0)
    return name;
  std::string d = llvm::demangle(name);
  if (lastComponent) {
    size_t colons = d.rfind("::");
    return colons == std::string::npos ? d : d.substr(colons + 2);
  }
  size_t paren = d.find('(');
  return paren == std::string::npos ? d : d.substr(0, paren);
}

}  // namespace

std::string kernelDisplayName(const llvm::Function& F) {
  return demangledShort(F.getName().str(), false);
}

namespace {

// ---------------------------------------------------------------------------
// Target facts
// ---------------------------------------------------------------------------

/// Hardware parameters the findings depend on. They aren't in the IR; these
/// are the vendors' documented values.
struct GpuTarget {
  bool amd = false;
  /// Threads that execute together (NVIDIA warp, AMD wavefront).
  unsigned warp = 32;
  /// Smallest unit global memory moves: 32-byte sectors on NVIDIA, 64-byte
  /// lines on AMD.
  unsigned segment = 32;
  std::string cpu;

  const char* warpWord() const {
    return amd ? "wavefront" : "warp";
  }
};

/// Shared memory (NVIDIA) and LDS (AMD GCN/CDNA): 32 banks of 4 bytes.
constexpr unsigned kBanks = 32;
constexpr unsigned kBankBytes = 4;

/// Address spaces, the same numbers on NVPTX and AMDGPU.
constexpr unsigned kSharedAS = 3;
constexpr unsigned kConstantAS = 4;
constexpr unsigned kPrivateAS = 5;

GpuTarget gpuTarget(const llvm::Function& F) {
  GpuTarget t;
  llvm::Attribute cpu = F.getFnAttribute("target-cpu");
  if (cpu.isValid())
    t.cpu = cpu.getValueAsString().str();
  if (!llvm::Triple(F.getParent()->getTargetTriple()).isAMDGPU())
    return t;
  t.amd = true;
  t.segment = 64;
  llvm::Attribute feat = F.getFnAttribute("target-features");
  std::string features = feat.isValid() ? feat.getValueAsString().str() : "";
  if (features.find("+wavefrontsize64") != std::string::npos)
    t.warp = 64;
  else if (features.find("+wavefrontsize32") != std::string::npos)
    t.warp = 32;
  else  // gfx10+ (RDNA) default to wave32; GCN/CDNA (gfx9 and older) to 64.
    t.warp = t.cpu.rfind("gfx1", 0) == 0 ? 32 : 64;
  return t;
}

/// threadIdx.x, or the lane ID: the value that differs between neighbouring
/// threads of one warp.
bool isLaneId(const llvm::Value* V) {
  const auto* II = llvm::dyn_cast<llvm::IntrinsicInst>(V);
  if (!II)
    return false;
  switch (II->getIntrinsicID()) {
    case llvm::Intrinsic::nvvm_read_ptx_sreg_tid_x:
    case llvm::Intrinsic::nvvm_read_ptx_sreg_laneid:
    case llvm::Intrinsic::amdgcn_workitem_id_x:
      return true;
    default:
      return false;
  }
}

bool isBarrier(const llvm::Instruction& I) {
  const auto* II = llvm::dyn_cast<llvm::IntrinsicInst>(&I);
  if (!II)
    return false;
  switch (II->getIntrinsicID()) {
    case llvm::Intrinsic::nvvm_barrier0:
    case llvm::Intrinsic::nvvm_barrier0_and:
    case llvm::Intrinsic::nvvm_barrier0_or:
    case llvm::Intrinsic::nvvm_barrier0_popc:
    case llvm::Intrinsic::nvvm_barrier_sync:
    case llvm::Intrinsic::nvvm_barrier_sync_cnt:
    case llvm::Intrinsic::nvvm_barrier:
    case llvm::Intrinsic::nvvm_barrier_n:
    case llvm::Intrinsic::amdgcn_s_barrier:
      return true;
    default:
      return false;
  }
}

/// "50%", "12.5%", "33.3%".
std::string percent(unsigned num, unsigned den) {
  unsigned tenths = den ? (num * 1000 + den / 2) / den : 0;
  std::string out = std::to_string(tenths / 10);
  if (tenths % 10)
    out += "." + std::to_string(tenths % 10);
  return out + "%";
}

int64_t floorDiv(int64_t a, int64_t b) {
  int64_t q = a / b;
  return (a % b != 0 && ((a < 0) != (b < 0))) ? q - 1 : q;
}

// ---------------------------------------------------------------------------
// Which values differ between threads of a warp
// ---------------------------------------------------------------------------

/// Forward propagation from threadIdx.x (and atomics, which return a
/// different value to each thread) through the def-use graph. A load only
/// becomes per-thread when its address is; it is then the "source load" of
/// everything computed from it, which lets findings say "depends on data
/// each thread loads (load of col)".
class LaneDeps {
public:
  explicit LaneDeps(llvm::Function& F) {
    std::vector<const llvm::Instruction*> work;
    for (llvm::Instruction& I : llvm::instructions(F))
      if (isLaneId(&I) || llvm::isa<llvm::AtomicRMWInst>(I) ||
          llvm::isa<llvm::AtomicCmpXchgInst>(I)) {
        varying_[&I] = nullptr;
        work.push_back(&I);
      }
    while (!work.empty()) {
      const llvm::Instruction* I = work.back();
      work.pop_back();
      const llvm::LoadInst* origin = varying_[I];
      for (const llvm::User* U : I->users()) {
        const auto* user = llvm::dyn_cast<llvm::Instruction>(U);
        if (!user || user->getType()->isVoidTy() || varying_.count(user))
          continue;
        const auto* Ld = llvm::dyn_cast<llvm::LoadInst>(user);
        varying_[user] = Ld ? Ld : origin;
        work.push_back(user);
      }
    }
  }

  bool varies(const llvm::Value* V) const {
    return varying_.count(V) != 0;
  }
  /// The per-thread load V is computed from, if any.
  const llvm::LoadInst* sourceLoad(const llvm::Value* V) const {
    auto it = varying_.find(V);
    return it == varying_.end() ? nullptr : it->second;
  }

private:
  std::map<const llvm::Value*, const llvm::LoadInst*> varying_;
};

/// How an expression changes from one lane to the next, assuming no
/// wrap-around in its casts. coeff is null when it doesn't change.
struct LinearStep {
  bool affine = true;
  const llvm::SCEV* coeff = nullptr;
};

/// Evaluates ScalarEvolution expressions per lane of a warp.
class LaneModel {
public:
  LaneModel(llvm::Function& F, llvm::ScalarEvolution& SE, unsigned warp)
      : SE(SE), deps_(F), warp_(warp) {
    for (llvm::Instruction& I : llvm::instructions(F))
      if (isLaneId(&I))
        laneIds_.push_back(&I);
    while ((1u << warpBits_) < warp)
      ++warpBits_;
  }

  const LaneDeps& deps() const {
    return deps_;
  }
  unsigned warp() const {
    return warp_;
  }
  llvm::ScalarEvolution& scev() {
    return SE;
  }

  /// A per-thread value inside S that ScalarEvolution treats as opaque (a
  /// load, a select, ...), or null. S's per-lane values can't be computed
  /// when there is one.
  const llvm::Value* opaqueLaneValue(const llvm::SCEV* S) const {
    const llvm::Value* found = nullptr;
    llvm::SCEVExprContains(S, [&](const llvm::SCEV* E) {
      const auto* U = llvm::dyn_cast<llvm::SCEVUnknown>(E);
      if (U && !isLaneId(U->getValue()) && deps_.varies(U->getValue()))
        found = U->getValue();
      return found != nullptr;
    });
    return found;
  }

  /// S(lane) - S(lane 0) for every lane of the first warp, if all are
  /// constants.
  bool offsets(const llvm::SCEV* S, std::vector<int64_t>* out) {
    out->clear();
    const llvm::SCEV* base = atLane(S, 0);
    for (unsigned k = 0; k < warp_; ++k) {
      const llvm::SCEV* d = SE.getMinusSCEV(atLane(S, k), base);
      const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(d);
      if (!C)
        return false;
      out->push_back(C->getAPInt().getSExtValue());
    }
    return true;
  }

  /// S at every lane of the first warp, if all are constants.
  bool values(const llvm::SCEV* S, std::vector<llvm::APInt>* out) {
    out->clear();
    for (unsigned k = 0; k < warp_; ++k) {
      const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(atLane(S, k));
      if (!C)
        return false;
      out->push_back(C->getAPInt());
    }
    return true;
  }

  /// The per-lane step of S, looking through casts (which offsets() can't
  /// fold when a zext/sext of a sum has no no-wrap flags).
  LinearStep linear(const llvm::SCEV* S) {
    using namespace llvm;
    LinearStep r;
    LinearStep bad;
    bad.affine = false;
    switch (S->getSCEVType()) {
      case scConstant:
        return r;
      case scUnknown: {
        Value* V = cast<SCEVUnknown>(S)->getValue();
        if (isLaneId(V))
          r.coeff = SE.getOne(V->getType());
        else if (deps_.varies(V))
          return bad;
        return r;
      }
      case scTruncate:
      case scZeroExtend:
      case scSignExtend:
      case scPtrToInt: {
        const auto* C = cast<SCEVCastExpr>(S);
        LinearStep in = linear(C->getOperand());
        if (!in.affine || !in.coeff)
          return in;
        Type* ty = C->getType();
        // x mod 2^bits wraps around within a warp.
        if (S->getSCEVType() == scTruncate &&
            ty->getScalarSizeInBits() < warpBits_)
          return bad;
        in.coeff = S->getSCEVType() == scZeroExtend
                       ? SE.getTruncateOrZeroExtend(in.coeff, ty)
                       : SE.getTruncateOrSignExtend(in.coeff, ty);
        return in;
      }
      case scAddExpr: {
        for (const SCEV* Op : cast<SCEVAddExpr>(S)->operands()) {
          LinearStep o = linear(Op);
          if (!o.affine)
            return o;
          r.coeff = addCoeffs(r.coeff, o.coeff);
        }
        return r;
      }
      case scMulExpr: {
        const SCEV* moving = nullptr;
        SmallVector<const SCEV*, 4> fixed;
        for (const SCEV* Op : cast<SCEVMulExpr>(S)->operands()) {
          LinearStep o = linear(Op);
          if (!o.affine)
            return o;
          if (!o.coeff) {
            fixed.push_back(Op);
          } else if (moving) {
            return bad;  // lane * lane
          } else {
            moving = o.coeff;
          }
        }
        if (moving) {
          fixed.push_back(moving);
          r.coeff = SE.getMulExpr(fixed);
        }
        return r;
      }
      case scAddRecExpr: {
        // A loop inside the kernel: the lane step is the start's, as long as
        // every thread steps by the same amount.
        const auto* AR = cast<SCEVAddRecExpr>(S);
        for (unsigned i = 1; i < AR->getNumOperands(); ++i) {
          LinearStep o = linear(AR->getOperand(i));
          if (!o.affine || o.coeff)
            return bad;
        }
        return linear(AR->getStart());
      }
      case scUDivExpr:
      case scSMaxExpr:
      case scUMaxExpr:
      case scSMinExpr:
      case scUMinExpr:
      case scSequentialUMinExpr: {
        // Fine when no operand moves with the lane.
        SmallVector<const SCEV*, 4> ops;
        if (const auto* D = dyn_cast<SCEVUDivExpr>(S))
          ops = {D->getLHS(), D->getRHS()};
        else
          ops.append(cast<SCEVNAryExpr>(S)->op_begin(),
                     cast<SCEVNAryExpr>(S)->op_end());
        for (const SCEV* Op : ops) {
          LinearStep o = linear(Op);
          if (!o.affine || o.coeff)
            return bad;
        }
        return r;
      }
      case scCouldNotCompute:
        return bad;
    }
    return bad;
  }

private:
  const llvm::SCEV* atLane(const llvm::SCEV* S, unsigned lane) {
    llvm::ValueToSCEVMapTy map;
    for (const llvm::Value* V : laneIds_)
      map[V] = SE.getConstant(V->getType(), lane);
    return llvm::SCEVParameterRewriter::rewrite(S, SE, map);
  }

  const llvm::SCEV* addCoeffs(const llvm::SCEV* a, const llvm::SCEV* b) {
    if (!a || !b)
      return a ? a : b;
    llvm::Type* ty = SE.getWiderType(a->getType(), b->getType());
    return SE.getAddExpr(SE.getNoopOrSignExtend(a, ty),
                         SE.getNoopOrSignExtend(b, ty));
  }

  llvm::ScalarEvolution& SE;
  LaneDeps deps_;
  unsigned warp_;
  unsigned warpBits_ = 0;
  std::vector<const llvm::Value*> laneIds_;
};

// ---------------------------------------------------------------------------
// Memory accesses
// ---------------------------------------------------------------------------

enum class Space { Global, Shared, Other };

Space spaceOf(const llvm::Value* ptr) {
  unsigned as = ptr->getType()->getPointerAddressSpace();
  if (as == kSharedAS)
    return Space::Shared;
  if (as == kConstantAS || as == kPrivateAS)
    return Space::Other;
  // Generic pointers: look at what they point into.
  const llvm::Value* base = llvm::getUnderlyingObject(ptr);
  if (const auto* GV = llvm::dyn_cast<llvm::GlobalVariable>(base)) {
    unsigned gas = GV->getAddressSpace();
    if (gas == kSharedAS)
      return Space::Shared;
    if (gas == kConstantAS || gas == kPrivateAS)
      return Space::Other;
  }
  if (llvm::isa<llvm::AllocaInst>(base))
    return Space::Other;
  return Space::Global;
}

std::string baseName(const llvm::Value* ptr) {
  std::string n = demangledShort(pointerBaseName(ptr), true);
  // HIP passes pointer arguments as "m.coerce" and casts them to global.
  const std::string suffix = ".coerce";
  if (n.size() > suffix.size() &&
      n.compare(n.size() - suffix.size(), suffix.size(), suffix) == 0)
    n.resize(n.size() - suffix.size());
  return n;
}

/// "4 * n" bytes with 4-byte elements -> "n elements".
std::string elementsText(const llvm::SCEV* bytes, uint64_t elem) {
  if (const auto* M = llvm::dyn_cast<llvm::SCEVMulExpr>(bytes))
    if (const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(M->getOperand(0))) {
      int64_t c = C->getAPInt().getSExtValue();
      if (elem && c % (int64_t)elem == 0) {
        std::string rest;
        for (unsigned i = 1; i < M->getNumOperands(); ++i)
          rest += (rest.empty() ? "" : " * ") + prettySCEV(M->getOperand(i));
        int64_t k = c / (int64_t)elem;
        return (k == 1 ? rest : std::to_string(k) + " * " + rest) +
               " elements";
      }
    }
  return prettySCEV(bytes) + " bytes";
}

/// The per-thread step alone: "n" rather than "n elements".
std::string stepText(const llvm::SCEV* bytes, uint64_t elem) {
  std::string t = elementsText(bytes, elem);
  const std::string suffix = " elements";
  if (t.size() > suffix.size() &&
      t.compare(t.size() - suffix.size(), suffix.size(), suffix) == 0)
    return t.substr(0, t.size() - suffix.size());
  return t;
}

std::string bytesText(int64_t bytes, unsigned elem) {
  if (elem && bytes % elem == 0) {
    int64_t k = bytes / elem;
    return std::to_string(k) + (k == 1 || k == -1 ? " element" : " elements") +
           " (" + std::to_string(bytes) + " bytes)";
  }
  return std::to_string(bytes) + " bytes";
}

struct Access {
  llvm::Instruction* inst = nullptr;
  bool isStore = false;
  /// A load and a store of the same address on one line (`p[i].x += dx`).
  bool readWrite = false;
  Space space = Space::Global;
  unsigned elem = 0;
  std::string base;
  unsigned loopDepth = 0;

  enum class Kind {
    Uniform,     // every thread of the warp uses the same address
    Exact,       // per-lane byte offsets known: `offsets`
    Symbolic,    // linear, with a symbolic per-thread step: `step`
    OwnRange,    // each thread walks a range starting at a loaded value
    Scattered,   // address computed from per-thread loaded data
    Irregular,   // per-thread, but not computable here
  };
  Kind kind = Kind::Irregular;
  std::vector<int64_t> offsets;
  const llvm::SCEV* step = nullptr;
  const llvm::LoadInst* sourceLoad = nullptr;

  /// "load of B", "store to C", "load and store of p".
  std::string what() const {
    return std::string(readWrite ? "load and store of "
                       : isStore ? "store to "
                                 : "load of ") +
           base;
  }
  std::string describe() const {
    std::string where = sourceLine(inst);
    return what() + (where.empty() ? "" : " (" + where + ")");
  }
  bool sameShape(const Access& o) const {
    return kind == o.kind && offsets == o.offsets && step == o.step &&
           base == o.base && space == o.space;
  }
  /// Constant per-thread byte step, if the offsets are linear.
  bool linearStride(int64_t* stride) const {
    if (kind != Kind::Exact || offsets.size() < 2)
      return false;
    for (size_t k = 0; k < offsets.size(); ++k)
      if (offsets[k] != (int64_t)k * offsets[1])
        return false;
    *stride = offsets[1];
    return true;
  }
};

/// Global memory segments one warp touches, assuming lane 0's address is
/// segment-aligned.
unsigned segmentsTouched(const std::vector<int64_t>& offsets, unsigned elem,
                         unsigned segment) {
  std::set<int64_t> segs;
  for (int64_t o : offsets)
    for (int64_t s = floorDiv(o, segment); s <= floorDiv(o + elem - 1, segment);
         ++s)
      segs.insert(s);
  return segs.size();
}

std::vector<int64_t> linearOffsets(int64_t stride, unsigned lanes) {
  std::vector<int64_t> out;
  for (unsigned k = 0; k < lanes; ++k)
    out.push_back((int64_t)k * stride);
  return out;
}

/// Serialized steps for one shared-memory access by 32 lanes: threads that
/// hit different 4-byte words of the same bank wait for each other.
unsigned bankConflictWays(const std::vector<int64_t>& offsets, unsigned elem) {
  std::map<int64_t, std::set<int64_t>> words;
  for (size_t k = 0; k < offsets.size() && k < kBanks; ++k)
    for (int64_t w = floorDiv(offsets[k], kBankBytes);
         w <= floorDiv(offsets[k] + elem - 1, kBankBytes); ++w) {
      int64_t bank = w % kBanks;
      words[bank < 0 ? bank + kBanks : bank].insert(w);
    }
  unsigned ways = 1;
  for (const auto& entry : words)
    ways = std::max<unsigned>(ways, entry.second.size());
  return ways;
}

/// The structure type an access indexes into (p[i].x), if any.
llvm::StructType* accessedStruct(const llvm::Value* ptr) {
  const auto* GEP = llvm::dyn_cast<llvm::GEPOperator>(ptr);
  if (!GEP)
    return nullptr;
  return llvm::dyn_cast<llvm::StructType>(GEP->getSourceElementType());
}

std::string structName(llvm::StructType* ST) {
  if (!ST->hasName())
    return "a struct";
  std::string n = ST->getName().str();
  for (const char* prefix : {"struct.", "class."})
    if (n.rfind(prefix, 0) == 0)
      return n.substr(strlen(prefix));
  return n;
}

Access analyzeAccess(llvm::Instruction* I, LaneModel& lanes) {
  Access a;
  a.inst = I;
  a.isStore = llvm::isa<llvm::StoreInst>(I);
  llvm::Value* ptr = llvm::getLoadStorePointerOperand(I);
  a.space = spaceOf(ptr);
  a.base = baseName(ptr);
  const llvm::DataLayout& DL = I->getModule()->getDataLayout();
  a.elem = DL.getTypeStoreSize(llvm::getLoadStoreType(I)).getFixedSize();

  llvm::ScalarEvolution& SE = lanes.scev();
  const llvm::SCEV* S = SE.getSCEV(ptr);
  if (const llvm::Value* opaque = lanes.opaqueLaneValue(S)) {
    a.sourceLoad = lanes.deps().sourceLoad(opaque);
    if (!a.sourceLoad) {
      a.kind = Access::Kind::Irregular;
      return a;
    }
    // The opaque value is the start of a per-thread loop counter: each
    // thread walks its own range (CSR rows).
    bool ownRange = llvm::SCEVExprContains(S, [&](const llvm::SCEV* E) {
      const auto* AR = llvm::dyn_cast<llvm::SCEVAddRecExpr>(E);
      return AR && AR->isAffine() &&
             lanes.opaqueLaneValue(AR->getStart()) != nullptr &&
             !lanes.opaqueLaneValue(AR->getStepRecurrence(SE));
    });
    a.kind = ownRange ? Access::Kind::OwnRange : Access::Kind::Scattered;
    return a;
  }
  if (lanes.offsets(S, &a.offsets)) {
    bool same = std::all_of(a.offsets.begin(), a.offsets.end(),
                            [](int64_t o) { return o == 0; });
    a.kind = same ? Access::Kind::Uniform : Access::Kind::Exact;
    return a;
  }
  LinearStep step = lanes.linear(S);
  if (!step.affine) {
    a.kind = Access::Kind::Irregular;
  } else if (!step.coeff) {
    a.kind = Access::Kind::Uniform;
  } else if (const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(step.coeff)) {
    a.kind = Access::Kind::Exact;
    a.offsets = linearOffsets(C->getAPInt().getSExtValue(), lanes.warp());
  } else {
    a.kind = Access::Kind::Symbolic;
    a.step = step.coeff;
  }
  return a;
}

// ---------------------------------------------------------------------------
// Branches
// ---------------------------------------------------------------------------

/// Why the threads of one warp can disagree on a branch condition.
struct Disagreement {
  enum class Cause {
    Remainder,  // threadIdx.x through %, & or / (lanes alternate)
    Data,       // data each thread loads
    Irregular,  // per-thread, not evaluated
  };
  Cause cause = Cause::Irregular;
  const llvm::LoadInst* load = nullptr;
  /// Threads of the first warp taking the branch, when computable.
  std::optional<unsigned> taken;
};

/// Number of places where neighbouring lanes switch between true and false.
unsigned transitions(const std::vector<bool>& v) {
  unsigned n = 0;
  for (size_t k = 1; k < v.size(); ++k)
    n += v[k] != v[k - 1];
  return n;
}

bool monotone(const std::vector<int64_t>& v) {
  bool up = true, down = true;
  for (size_t k = 1; k < v.size(); ++k) {
    up &= v[k] >= v[k - 1];
    down &= v[k] <= v[k - 1];
  }
  return up || down;
}

Disagreement fromData(const llvm::Value* V, const LaneDeps& deps) {
  Disagreement d;
  d.load = deps.sourceLoad(V);
  d.cause = d.load ? Disagreement::Cause::Data : Disagreement::Cause::Irregular;
  return d;
}

/// nullopt when every warp agrees, or when the threads split at a single
/// point (`i < n`, `tid == 0`): that splits at most one warp.
std::optional<Disagreement> classifyCondition(const llvm::Value* C,
                                              LaneModel& lanes) {
  const LaneDeps& deps = lanes.deps();
  if (!deps.varies(C))
    return std::nullopt;
  if (const auto* BO = llvm::dyn_cast<llvm::BinaryOperator>(C))
    if (BO->getType()->isIntegerTy(1) &&
        (BO->getOpcode() == llvm::Instruction::And ||
         BO->getOpcode() == llvm::Instruction::Or)) {
      for (const llvm::Value* Op : BO->operands())
        if (auto d = classifyCondition(Op, lanes))
          return d;
      return std::nullopt;
    }
  if (const auto* Sel = llvm::dyn_cast<llvm::SelectInst>(C)) {
    for (const llvm::Value* Op : Sel->operands())
      if (auto d = classifyCondition(Op, lanes))
        return d;
    return std::nullopt;
  }
  const auto* Cmp = llvm::dyn_cast<llvm::ICmpInst>(C);
  llvm::ScalarEvolution& SE = lanes.scev();
  if (!Cmp || !SE.isSCEVable(Cmp->getOperand(0)->getType()))
    return fromData(C, deps);

  const llvm::SCEV* L = SE.getSCEV(Cmp->getOperand(0));
  const llvm::SCEV* R = SE.getSCEV(Cmp->getOperand(1));
  for (const llvm::SCEV* side : {L, R})
    if (const llvm::Value* opaque = lanes.opaqueLaneValue(side))
      return fromData(opaque, deps);

  Disagreement remainder;
  remainder.cause = Disagreement::Cause::Remainder;
  std::vector<llvm::APInt> lv, rv;
  if (Cmp->getOperand(0)->getType()->isIntegerTy() && lanes.values(L, &lv) &&
      lanes.values(R, &rv)) {
    std::vector<bool> taken;
    for (size_t k = 0; k < lv.size(); ++k)
      taken.push_back(
          llvm::ICmpInst::compare(lv[k], rv[k], Cmp->getPredicate()));
    if (transitions(taken) <= 1)
      return std::nullopt;
    remainder.taken = std::count(taken.begin(), taken.end(), true);
    return remainder;
  }
  const llvm::SCEV* diff = SE.getMinusSCEV(L, R);
  std::vector<int64_t> offsets;
  if (lanes.offsets(diff, &offsets)) {
    if (monotone(offsets))
      return std::nullopt;
    return remainder;
  }
  if (lanes.linear(diff).affine)
    return std::nullopt;
  return remainder;
}

// ---------------------------------------------------------------------------
// Reporting
// ---------------------------------------------------------------------------

class KernelReport {
public:
  KernelReport(FunctionAnalyses& FA, const LoopCatalog* catalog,
               bool haveTarget, AnalysisContext& ctx)
      : FA(FA),
        catalog(catalog),
        haveTarget(haveTarget),
        ctx(ctx),
        target(gpuTarget(FA.function())),
        lanes(FA.function(), FA.scev(), target.warp) {}

  void run() {
    reportAccesses();
    reportBranches();
    reportBarriers();
  }

private:
  Diagnostic makeDiag(DiagnosticCategory category, DiagnosticSeverity severity,
                      const llvm::Instruction* at) {
    Diagnostic d;
    d.category = category;
    d.severity = severity;
    d.functionName = kernelDisplayName(FA.function());
    if (catalog)
      if (llvm::Loop* L = FA.loopInfo().getLoopFor(at->getParent()))
        if (const LogicalLoop* LL = catalog->find(L)) {
          d.loop = LL->describe();
          d.loopOrder = LL->order;
        }
    return d;
  }

  std::string targetName() const {
    std::string vendor = target.amd ? "AMD" : "NVIDIA";
    return vendor + (target.cpu.empty() ? "" : " " + target.cpu);
  }

  std::string warpText() const {
    return std::string("one ") + target.warpWord() + " (" +
           std::to_string(target.warp) + " threads)";
  }

  /// Unrolled copies of one source access are the same finding.
  bool firstTime(const std::string& what, const llvm::Instruction* I) {
    std::string line = sourceLine(I);
    std::string key =
        what + "\n" +
        (line.empty() ? std::to_string(reinterpret_cast<uintptr_t>(I)) : line);
    return reported.insert(key).second;
  }

  // --- Accesses ------------------------------------------------------------

  void reportAccesses() {
    // Copies of one source access (unrolling, loop guards) share a line;
    // keep the copy in the deepest loop, which shows the steady state (the
    // unroller's prologue copy of a CSR row walk has no loop counter).
    std::vector<Access> accesses;
    std::map<std::string, size_t> index;
    for (llvm::Instruction& I : llvm::instructions(FA.function())) {
      if (!llvm::isa<llvm::LoadInst>(I) && !llvm::isa<llvm::StoreInst>(I))
        continue;
      Access a = analyzeAccess(&I, lanes);
      if (a.space == Space::Other)
        continue;
      a.loopDepth = FA.loopInfo().getLoopDepth(I.getParent());
      std::string line = sourceLine(&I);
      std::string key =
          a.describe() + "\n" +
          (line.empty() ? std::to_string(reinterpret_cast<uintptr_t>(&I))
                        : line);
      auto it = index.find(key);
      if (it == index.end()) {
        index[key] = accesses.size();
        accesses.push_back(std::move(a));
      } else if (a.loopDepth > accesses[it->second].loopDepth) {
        accesses[it->second] = std::move(a);
      }
    }
    // A load and store of the same address on one line are one finding.
    for (size_t i = 0; i < accesses.size(); ++i)
      for (size_t j = i + 1; j < accesses.size(); ++j) {
        Access& a = accesses[i];
        const Access& b = accesses[j];
        std::string line = sourceLine(a.inst);
        if (!line.empty() && line == sourceLine(b.inst) &&
            a.isStore != b.isStore && !a.readWrite && a.sameShape(b)) {
          a.readWrite = true;
          accesses.erase(accesses.begin() + j);
          break;
        }
      }
    if (accesses.empty())
      return;

    Diagnostic summary = makeDiag(DiagnosticCategory::Memory,
                                  DiagnosticSeverity::Note,
                                  accesses.front().inst);
    summary.loop.clear();
    summary.loopOrder = 0;
    unsigned good = 0;
    for (const Access& a : accesses) {
      std::string verdict = a.space == Space::Shared ? reportShared(a)
                                                     : reportGlobal(a);
      if (verdict.rfind("ok:", 0) == 0) {
        ++good;
        verdict = verdict.substr(4);
      }
      summary.evidence.push_back(
          a.describe() + (a.space == Space::Shared ? " [shared]" : " [global]") +
          ": " + verdict);
    }
    summary.message = "GPU memory accesses: " + std::to_string(good) + " of " +
                      std::to_string(accesses.size()) +
                      " are coalesced, broadcast, or conflict-free";
    summary.basis = "ScalarEvolution (address evaluated per lane)";
    ctx.getEmitter().add(std::move(summary));
  }

  /// Emits a finding for a problematic global access. Returns the one-line
  /// verdict for the summary, prefixed "ok: " when there is no problem.
  std::string reportGlobal(const Access& a) {
    switch (a.kind) {
      case Access::Kind::Uniform:
        return "ok: same address for the whole " + std::string(target.warpWord()) +
               " (one transaction, broadcast)";
      case Access::Kind::Exact:
        return reportExactGlobal(a);
      case Access::Kind::Symbolic:
        reportSymbolicGlobal(a);
        return "neighbouring threads " + elementsText(a.step, a.elem) +
               " apart";
      case Access::Kind::OwnRange:
      case Access::Kind::Scattered:
        reportDataDependent(a);
        return "address depends on data each thread loads";
      case Access::Kind::Irregular:
        return "per-thread address this tool can't evaluate";
    }
    return "";
  }

  std::string reportExactGlobal(const Access& a) {
    unsigned segs = segmentsTouched(a.offsets, a.elem, target.segment);
    unsigned ideal = segmentsTouched(linearOffsets(a.elem, target.warp),
                                     a.elem, target.segment);
    int64_t stride = 0;
    bool linear = a.linearStride(&stride);
    if (segs <= ideal)
      return "ok: coalesced (" + std::to_string(segs) + " " +
             std::to_string(target.segment) + "-byte segments per " +
             target.warpWord() + ")";

    std::string useful = percent(ideal, segs);
    Diagnostic d = makeDiag(DiagnosticCategory::Coalescing,
                            DiagnosticSeverity::Warning, a.inst);
    std::string what = a.what();
    if (linear) {
      d.message = "Uncoalesced " + what + ": neighbouring threads are " +
                  bytesText(stride, a.elem) + " apart, so only " + useful +
                  " of the memory traffic is used";
      d.evidence.push_back(a.describe() + ": address advances " +
                           bytesText(stride, a.elem) + " per thread");
    } else {
      d.message = "Uncoalesced " + what +
                  ": threads of a " + target.warpWord() +
                  " access scattered addresses, so only " + useful +
                  " of the memory traffic is used";
      std::string first;
      for (size_t k = 0; k < 8 && k < a.offsets.size(); ++k)
        first += (k ? ", " : "") + std::to_string(a.offsets[k]);
      d.evidence.push_back(a.describe() + ": byte offsets of the first lanes: " +
                           first + ", ...");
    }
    d.evidence.push_back(
        warpText() + " touches " + std::to_string(segs) + " " +
        std::to_string(target.segment) + "-byte segments for " +
        std::to_string(target.warp * a.elem) +
        " useful bytes; consecutive elements would need " +
        std::to_string(ideal));
    llvm::StructType* ST =
        accessedStruct(llvm::getLoadStorePointerOperand(a.inst));
    const llvm::DataLayout& DL = a.inst->getModule()->getDataLayout();
    if (linear && ST &&
        (uint64_t)std::abs(stride) == DL.getTypeAllocSize(ST).getFixedSize()) {
      d.evidence.push_back(
          a.base + " is an array of " + structName(ST) + " (" +
          std::to_string(DL.getTypeAllocSize(ST).getFixedSize()) +
          " bytes each) and each thread uses one " + std::to_string(a.elem) +
          "-byte field");
      d.suggestions.push_back(
          "Store each field in its own array (structure of arrays) so thread i "
          "reads field[i]. Computed: that touches " +
          std::to_string(ideal) + " segments per " + target.warpWord() +
          " instead of " + std::to_string(segs) + ".");
    } else {
      addLayoutAdvice(d);
    }
    d.basis = "ScalarEvolution (address evaluated per lane), " + targetName() +
              " " + std::to_string(target.segment) +
              "-byte segments; assumes blockDim.x is a multiple of " +
              std::to_string(target.warp);
    ctx.getEmitter().add(std::move(d));
    return "uncoalesced (" + std::to_string(segs) + " segments per " +
           target.warpWord() + " instead of " + std::to_string(ideal) + ")";
  }

  void reportSymbolicGlobal(const Access& a) {
    Diagnostic d = makeDiag(DiagnosticCategory::Coalescing,
                            DiagnosticSeverity::Warning, a.inst);
    std::string apart = elementsText(a.step, a.elem);
    d.message = "Uncoalesced " + a.what() + ": neighbouring threads are " +
                apart + " apart";
    d.evidence.push_back(a.describe() + ": address advances " + apart +
                         " per thread");
    unsigned perSegment = target.segment / std::max(1u, a.elem);
    d.evidence.push_back(
        "once " + stepText(a.step, a.elem) + " >= " +
        std::to_string(perSegment) + ", every thread of a " +
        target.warpWord() + " touches its own " +
        std::to_string(target.segment) + "-byte segment, so only " +
        percent(a.elem, target.segment) + " of the memory traffic is used");
    addLayoutAdvice(d);
    d.basis = "ScalarEvolution (per-lane step of the address), " +
              targetName() + "; assumes blockDim.x is a multiple of " +
              std::to_string(target.warp);
    ctx.getEmitter().add(std::move(d));
  }

  void addLayoutAdvice(Diagnostic& d) {
    d.suggestions.push_back(
        "Let threadIdx.x pick the last (fastest-varying) index, e.g. "
        "`A[row * n + col]` with `col = blockIdx.x * blockDim.x + "
        "threadIdx.x`.");
    d.suggestions.push_back(
        "If this order is inherent (e.g. a transpose), stage a tile through "
        "shared memory: read it coalesced, `__syncthreads()`, then write it "
        "out coalesced in the other order.");
  }

  void reportDataDependent(const Access& a) {
    bool own = a.kind == Access::Kind::OwnRange;
    std::string from = a.sourceLoad ? loadText(a.sourceLoad) : "loaded data";
    Diagnostic d = makeDiag(DiagnosticCategory::Coalescing,
                            own ? DiagnosticSeverity::Warning
                                : DiagnosticSeverity::Note,
                            a.inst);
    std::string what = a.what();
    if (own) {
      d.message = "Uncoalesced " + what +
                  ": each thread walks its own range, starting at a value it "
                  "loaded, so neighbouring threads read unrelated addresses";
      d.evidence.push_back(a.describe() + ": the range starts at " + from);
      d.suggestions.push_back(
          "Give each range to a whole " + std::string(target.warpWord()) +
          " instead of one thread, so its threads read consecutive elements "
          "(for CSR SpMV: one warp per row, then a warp-level sum).");
    } else {
      d.message = "Data-dependent addresses for " + what +
                  ": whether neighbouring threads coalesce depends on the "
                  "values they loaded";
      d.evidence.push_back(a.describe() + ": address computed from " + from);
      d.suggestions.push_back(
          "Reordering the data so neighbouring threads use nearby indices "
          "(e.g. sorting, or a bandwidth-reducing reordering of a sparse "
          "matrix) makes more of these accesses coalesce.");
    }
    const auto* A = llvm::dyn_cast<llvm::Argument>(llvm::getUnderlyingObject(
        llvm::getLoadStorePointerOperand(a.inst)));
    if (!target.amd && !a.isStore && A && !A->hasNoAliasAttr() &&
        A->onlyReadsMemory())
      d.suggestions.push_back(
          "Declare " + valueName(A) +
          " as `const T* __restrict__` so these loads can use the read-only "
          "data cache (ld.global.nc), which handles scattered reads better.");
    d.basis = "ScalarEvolution + def-use from threadIdx.x (the address uses "
              "a per-thread loaded value)";
    ctx.getEmitter().add(std::move(d));
  }

  std::string reportShared(const Access& a) {
    if (a.kind == Access::Kind::Uniform)
      return "ok: same word for every thread (broadcast)";
    if (a.kind != Access::Kind::Exact)
      return "bank conflicts not evaluated (address not computable per lane)";
    unsigned ways = bankConflictWays(a.offsets, a.elem);
    unsigned ideal = bankConflictWays(linearOffsets(a.elem, kBanks), a.elem);
    if (ways <= ideal)
      return "ok: no bank conflict";

    Diagnostic d = makeDiag(DiagnosticCategory::SharedMemory,
                            DiagnosticSeverity::Warning, a.inst);
    d.message = std::to_string(ways) + "-way bank conflict on " + a.base +
                ": each access by a " + target.warpWord() +
                " is split into " + std::to_string(ways) +
                " serialized steps" +
                (ideal > 1 ? " instead of " + std::to_string(ideal) : "");
    int64_t stride = 0;
    bool linear = a.linearStride(&stride);
    if (linear)
      d.evidence.push_back(a.describe() + ": neighbouring threads are " +
                           std::to_string(stride) + " bytes apart");
    d.evidence.push_back(
        "shared memory has " + std::to_string(kBanks) + " banks of " +
        std::to_string(kBankBytes) + " bytes, so addresses " +
        std::to_string(kBanks * kBankBytes) + " bytes apart are in the same "
        "bank; " + std::to_string(ways) + " threads hit different words of "
        "one bank");

    // tile[R][C] indexed with threadIdx.x on the row: pad each row.
    const auto* GV = llvm::dyn_cast<llvm::GlobalVariable>(
        llvm::getUnderlyingObject(llvm::getLoadStorePointerOperand(a.inst)));
    auto* outer =
        GV ? llvm::dyn_cast<llvm::ArrayType>(GV->getValueType()) : nullptr;
    auto* inner =
        outer ? llvm::dyn_cast<llvm::ArrayType>(outer->getElementType())
              : nullptr;
    const llvm::DataLayout& DL = a.inst->getModule()->getDataLayout();
    if (linear && inner &&
        (uint64_t)std::abs(stride) ==
            DL.getTypeAllocSize(inner).getFixedSize()) {
      uint64_t cols = inner->getNumElements();
      uint64_t elemSize =
          DL.getTypeAllocSize(inner->getElementType()).getFixedSize();
      unsigned padded = bankConflictWays(
          linearOffsets(stride + (stride < 0 ? -1 : 1) * (int64_t)elemSize,
                        kBanks),
          a.elem);
      d.suggestions.push_back(
          "Pad each row by one element: declare " + a.base + "[" +
          std::to_string(outer->getNumElements()) + "][" +
          std::to_string(cols + 1) + "] instead of [" +
          std::to_string(outer->getNumElements()) + "][" +
          std::to_string(cols) + "]. Computed: " +
          (padded <= ideal ? std::string("then no bank conflict")
                           : std::to_string(padded) + "-way conflict") +
          ".");
    } else {
      d.suggestions.push_back(
          "Index so that consecutive threads access consecutive 4-byte words "
          "(threadIdx.x on the last index).");
    }
    d.basis = "ScalarEvolution (address evaluated per lane), " +
              std::to_string(kBanks) + " banks x " +
              std::to_string(kBankBytes) + " bytes";
    ctx.getEmitter().add(std::move(d));
    return std::to_string(ways) + "-way bank conflict";
  }

  // --- Branches --------------------------------------------------------------

  bool divergentPerLLVM(const llvm::Value* C) {
    return !haveTarget || FA.divergence().isDivergent(*C);
  }

  struct BranchGroup {
    const llvm::BranchInst* at = nullptr;
    bool loopExit = false;
    Disagreement why;
    std::vector<unsigned> taken;
  };

  void reportBranches() {
    llvm::LoopInfo& LI = FA.loopInfo();
    // Grouped by source line: unrolled copies and the compiler's loop guards
    // share the loop's line.
    std::map<std::string, BranchGroup> groups;
    std::vector<std::string> order;
    for (llvm::BasicBlock& BB : FA.function()) {
      auto* Br = llvm::dyn_cast<llvm::BranchInst>(BB.getTerminator());
      if (!Br || !Br->isConditional())
        continue;
      const llvm::Value* C = Br->getCondition();
      if (!divergentPerLLVM(C))
        continue;
      std::optional<Disagreement> why = classifyCondition(C, lanes);
      if (!why)
        continue;
      llvm::Loop* L = LI.getLoopFor(&BB);
      bool exits = L && L->isLoopExiting(&BB) &&
                   (!L->contains(Br->getSuccessor(0)) ||
                    !L->contains(Br->getSuccessor(1)));
      std::string line = sourceLine(Br);
      std::string key =
          line.empty() ? std::to_string(reinterpret_cast<uintptr_t>(Br)) : line;
      auto [it, inserted] = groups.try_emplace(key);
      BranchGroup& g = it->second;
      if (inserted)
        order.push_back(key);
      if (inserted || (exits && !g.loopExit)) {
        g.at = Br;
        g.loopExit = exits;
        g.why = *why;
      }
      if (why->taken)
        g.taken.push_back(*why->taken);
    }
    for (const std::string& key : order)
      emitBranch(groups[key]);
  }

  std::string loadText(const llvm::LoadInst* Ld) {
    std::string where = sourceLine(Ld);
    return "load of " + baseName(Ld->getPointerOperand()) +
           (where.empty() ? "" : " (" + where + ")");
  }

  void emitBranch(const BranchGroup& g) {
    Diagnostic d = makeDiag(DiagnosticCategory::Divergence,
                            DiagnosticSeverity::Warning, g.at);
    std::string where = sourceLine(g.at);
    std::string cond =
        "the condition" + (where.empty() ? "" : " at " + where);
    std::string warp = target.warpWord();
    if (g.loopExit)
      d.message = "Threads of a " + warp + " run this loop different numbers "
                  "of times; the " + warp + " keeps going until its last "
                  "thread finishes";
    else
      d.message = "Threads of a " + warp + " take different sides of this "
                  "branch, so the " + warp + " runs both sides one after the "
                  "other";
    switch (g.why.cause) {
      case Disagreement::Cause::Data:
        d.evidence.push_back(cond + " depends on data each thread loads: " +
                             loadText(g.why.load));
        if (g.loopExit)
          d.suggestions.push_back(
              "Balance the work per thread: give each long item (row, list) "
              "to a whole " + warp + " whose threads split it, or sort/bin "
              "items by length so a " + warp + "'s threads get similar "
              "counts.");
        else
          d.suggestions.push_back(
              "If the data allows, sort or bucket it so neighbouring threads "
              "take the same path; if both sides are short, compute both and "
              "select, leaving no branch.");
        break;
      case Disagreement::Cause::Remainder: {
        d.evidence.push_back(cond + " depends on threadIdx.x through a "
                             "remainder, bit mask or division, so "
                             "neighbouring threads disagree");
        if (!g.taken.empty()) {
          std::string counts;
          for (size_t i = 0; i < g.taken.size(); ++i)
            counts += (i ? ", " : "") + std::to_string(g.taken[i]);
          d.evidence.push_back(
              "threads of the first " + warp + " taking the branch: " +
              counts + " of " + std::to_string(target.warp) +
              (g.taken.size() > 1 ? " (one count per unrolled copy)" : ""));
        }
        d.suggestions.push_back(
            "Make the condition the same for all threads of a " + warp +
            ": select work by warp index (`threadIdx.x / warpSize`) or keep "
            "the active threads contiguous. In a tree reduction, use "
            "`if (tid < s)` with s halving each step instead of "
            "`if (tid % (2 * s) == 0)`.");
        break;
      }
      case Disagreement::Cause::Irregular:
        d.evidence.push_back(cond + " varies between threads in a way this "
                             "tool can't evaluate per lane");
        d.suggestions.push_back(
            "Make the condition the same for all threads of a " + warp + ".");
        break;
    }
    d.basis = std::string(haveTarget ? "LLVM DivergenceAnalysis (" +
                                           targetName() + ") + "
                                     : "") +
              "ScalarEvolution (condition evaluated per lane)";
    ctx.getEmitter().add(std::move(d));
  }

  // --- Barriers ------------------------------------------------------------

  void reportBarriers() {
    llvm::DominatorTree& DT = FA.domTree();
    llvm::PostDominatorTree& PDT = FA.postDomTree();
    for (llvm::Instruction& I : llvm::instructions(FA.function())) {
      if (!isBarrier(I))
        continue;
      llvm::BasicBlock* B = I.getParent();
      // The closest conditional branch that decides whether B runs.
      const llvm::BranchInst* guard = nullptr;
      unsigned level = 0;
      for (llvm::BasicBlock& P : FA.function()) {
        auto* Br = llvm::dyn_cast<llvm::BranchInst>(P.getTerminator());
        if (!Br || !Br->isConditional() || &P == B ||
            !DT.dominates(&P, B) || PDT.dominates(B, &P))
          continue;
        const llvm::Value* C = Br->getCondition();
        if (!lanes.deps().varies(C) || !divergentPerLLVM(C))
          continue;
        unsigned l = DT.getNode(&P)->getLevel();
        if (!guard || l > level) {
          guard = Br;
          level = l;
        }
      }
      if (!guard || !firstTime("barrier", &I))
        continue;
      Diagnostic d = makeDiag(DiagnosticCategory::Divergence,
                              DiagnosticSeverity::Error, &I);
      std::string where = sourceLine(&I);
      std::string guardLine = sourceLine(guard);
      d.message = "Barrier reached by only some threads: threads for which "
                  "the condition" +
                  (guardLine.empty() ? "" : " at " + guardLine) +
                  " goes the other way skip `__syncthreads()`, which is "
                  "undefined behaviour (the block can hang or read stale "
                  "data)";
      const llvm::LoadInst* load =
          lanes.deps().sourceLoad(guard->getCondition());
      d.evidence.push_back(
          "barrier" + (where.empty() ? "" : " at " + where) +
          " runs only on one side of the branch" +
          (guardLine.empty() ? "" : " at " + guardLine));
      d.evidence.push_back(
          "that condition depends on " +
          (load ? "data each thread loads: " + loadText(load)
                : std::string("threadIdx.x")));
      d.suggestions.push_back(
          "Move the barrier out of the conditional so every thread of the "
          "block reaches it, and guard only the work: `if (i < n) s[t] = "
          "...; __syncthreads(); if (i < n) ...`.");
      d.basis = std::string(haveTarget ? "LLVM DivergenceAnalysis + " : "") +
                "dominator / post-dominator trees";
      ctx.getEmitter().add(std::move(d));
    }
  }

  FunctionAnalyses& FA;
  const LoopCatalog* catalog;
  bool haveTarget;
  AnalysisContext& ctx;
  GpuTarget target;
  LaneModel lanes;
  std::set<std::string> reported;
};

}  // namespace

void GpuAnalyzer::run(FunctionAnalyses& FA, const LoopCatalog* catalog,
                      bool haveTarget, AnalysisContext& ctx) {
  KernelReport(FA, catalog, haveTarget, ctx).run();
}

}  // namespace analyzer
