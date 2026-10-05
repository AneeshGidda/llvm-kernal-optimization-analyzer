#include "analyzer/LoopCatalog.h"

#include "analyzer/IRNames.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/Analysis/ScalarEvolution.h>
#include <llvm/Analysis/ScalarEvolutionExpressions.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/CFG.h>
#include <llvm/IR/Instructions.h>

#include <algorithm>

namespace analyzer {

namespace {

/// Blocks that belong to L itself, not to a nested loop.
template <typename Fn>
void forEachOwnInstruction(llvm::Loop* L, llvm::LoopInfo& LI, Fn fn) {
  for (llvm::BasicBlock* BB : L->blocks()) {
    if (LI.getLoopFor(BB) != L)
      continue;
    for (llvm::Instruction& I : *BB)
      fn(I);
  }
}

/// Widest vector a load or store in L moves, in elements. 0 if none.
unsigned vectorWidthOf(llvm::Loop* L, llvm::LoopInfo& LI, bool* scalable) {
  unsigned width = 0;
  forEachOwnInstruction(L, LI, [&](llvm::Instruction& I) {
    llvm::Type* T = nullptr;
    if (auto* Ld = llvm::dyn_cast<llvm::LoadInst>(&I))
      T = Ld->getType();
    else if (auto* St = llvm::dyn_cast<llvm::StoreInst>(&I))
      T = St->getValueOperand()->getType();
    else if (I.getType()->isVectorTy())
      T = I.getType();
    if (auto* VT = llvm::dyn_cast_or_null<llvm::VectorType>(T)) {
      unsigned n = VT->getElementCount().getKnownMinValue();
      if (n > width) {
        width = n;
        *scalable = llvm::isa<llvm::ScalableVectorType>(VT);
      }
    }
  });
  return width;
}

unsigned ownInstructionCount(llvm::Loop* L, llvm::LoopInfo& LI) {
  unsigned n = 0;
  forEachOwnInstruction(L, LI, [&](llvm::Instruction&) { ++n; });
  return n;
}

std::string tripCountOf(llvm::Loop* L, llvm::ScalarEvolution& SE) {
  if (unsigned c = SE.getSmallConstantTripCount(L))
    return std::to_string(c);
  const llvm::SCEV* BTC = SE.getBackedgeTakenCount(L);
  if (llvm::isa<llvm::SCEVCouldNotCompute>(BTC))
    return "";
  // Trip count = backedge-taken count + 1.
  return prettySCEV(SE.getAddExpr(BTC, SE.getOne(BTC->getType())));
}

}  // namespace

std::string LogicalLoop::label() const {
  std::string out;
  if (!location.empty()) {
    // Drop the column: "loop at matmul.c:8".
    std::string loc = location;
    size_t lastColon = loc.rfind(':');
    if (lastColon != std::string::npos && loc.find(':') != lastColon)
      loc = loc.substr(0, lastColon);
    out = "loop at " + loc;
  } else {
    llvm::Loop* any = scalar ? scalar : (copies.empty() ? nullptr : copies[0]);
    if (any && any->getHeader()->hasName())
      out = "loop %" + any->getHeader()->getName().str();
    else
      out = "loop #" + std::to_string(order);
  }
  if (!inlinedAt.empty())
    out += " (inlined at " + inlinedAt + ")";
  return out;
}

std::string LogicalLoop::describe() const {
  std::string out = label() + " (depth " + std::to_string(depth);
  if (innermost)
    out += ", innermost";
  if (!tripCount.empty())
    out += ", runs " + tripCount + " times";
  return out + ")";
}

namespace {

bool isProcessedByVectorizer(const llvm::Loop* L) {
  // The vectorizer tags every loop it has processed (vector body,
  // remainder, or interleave-only) with llvm.loop.isvectorized.
  return llvm::getBooleanLoopAttribute(L, "llvm.loop.isvectorized");
}

bool vectorizationDisabled(const llvm::Loop* L) {
  if (llvm::Optional<bool> enable =
          llvm::getOptionalBoolLoopAttribute(L, "llvm.loop.vectorize.enable"))
    if (!*enable)
      return true;
  llvm::Optional<int> width =
      llvm::getOptionalIntLoopAttribute(L, "llvm.loop.vectorize.width");
  return width && *width == 1;
}

/// Source location of the loop including the inlining chain, so that two
/// inlined copies of one helper's loop stay separate.
std::string locationKey(const llvm::Loop* L) {
  llvm::DebugLoc DL = loopStartLoc(L);
  std::string loc = formatDebugLoc(DL);
  if (loc.empty())
    return loc;
  std::string chain = inlinedAtChain(DL);
  return chain.empty() ? loc : loc + " @ " + chain;
}

/// A remainder loop made by runtime unrolling: its loop ID only says "don't
/// unroll again" and carries no source location.
bool isUnrollRemainder(const llvm::Loop* L) {
  llvm::MDNode* LoopID = L->getLoopID();
  if (!LoopID || !llvm::getBooleanLoopAttribute(L, "llvm.loop.unroll.disable"))
    return false;
  for (unsigned i = 1, e = LoopID->getNumOperands(); i < e; ++i)
    if (llvm::isa<llvm::DILocation>(LoopID->getOperand(i)))
      return false;
  return true;
}

/// The loop whose preheader is `B` (or `B`'s single successor), if any.
llvm::Loop* loopEnteredFrom(llvm::BasicBlock* B, llvm::LoopInfo& LI) {
  for (int hop = 0; B && hop < 2; ++hop, B = B->getSingleSuccessor()) {
    llvm::BasicBlock* next = B->getSingleSuccessor();
    if (!next)
      return nullptr;
    llvm::Loop* R = LI.getLoopFor(next);
    if (R && R->getHeader() == next && R->getLoopPreheader() == B)
      return R;
  }
  return nullptr;
}

struct UnionFind {
  std::map<llvm::Loop*, llvm::Loop*> parent;
  llvm::Loop* find(llvm::Loop* L) {
    auto it = parent.find(L);
    if (it == parent.end() || it->second == L)
      return L;
    return it->second = find(it->second);
  }
  void unite(llvm::Loop* a, llvm::Loop* b) {
    a = find(a);
    b = find(b);
    if (a != b)
      parent[b] = a;
  }
};

}  // namespace

LoopCatalog::LoopCatalog(llvm::LoopInfo& LI, llvm::ScalarEvolution& SE) {
  llvm::SmallVector<llvm::Loop*, 8> all = LI.getLoopsInPreorder();
  UnionFind uf;

  // 1. Same source location, including where it was inlined.
  std::map<std::string, llvm::Loop*> byLocation;
  for (llvm::Loop* L : all) {
    std::string key = locationKey(L);
    if (key.empty())
      continue;
    auto [it, inserted] = byLocation.emplace(key, L);
    if (!inserted)
      uf.unite(it->second, L);
  }

  // 2. The vectorizer's layout, which needs no debug info: a processed loop
  //    exits into a "middle block" that branches to the preheader of the
  //    scalar remainder (also tagged as processed).
  for (llvm::Loop* V : all) {
    if (!isProcessedByVectorizer(V))
      continue;
    llvm::BasicBlock* middle = V->getExitBlock();
    if (!middle)
      continue;
    for (llvm::BasicBlock* S : llvm::successors(middle)) {
      llvm::Loop* R = loopEnteredFrom(S, LI);
      if (R && R != V && R->getParentLoop() == V->getParentLoop() &&
          isProcessedByVectorizer(R))
        uf.unite(V, R);
    }
  }

  // 3. Runtime unrolling: the main copy's exit leads (through the
  //    unroller's "unr-lcssa" block) straight into the remainder's
  //    preheader. Its backedge location can differ from the main loop ID's.
  for (llvm::Loop* M : all) {
    llvm::SmallVector<llvm::BasicBlock*, 4> exits;
    M->getUniqueExitBlocks(exits);
    std::vector<llvm::BasicBlock*> frontier(exits.begin(), exits.end());
    for (int hop = 0; hop < 2; ++hop) {
      std::vector<llvm::BasicBlock*> next;
      for (llvm::BasicBlock* B : frontier)
        for (llvm::BasicBlock* S : llvm::successors(B)) {
          llvm::Loop* R = loopEnteredFrom(S, LI);
          if (R && R != M && R->getParentLoop() == M->getParentLoop() &&
              isUnrollRemainder(R))
            uf.unite(M, R);
          next.push_back(S);
        }
      frontier = std::move(next);
    }
  }

  // Groups in preorder of their first copy.
  std::vector<std::vector<llvm::Loop*>> groups;
  std::map<llvm::Loop*, size_t> groupOf;
  for (llvm::Loop* L : all) {
    llvm::Loop* root = uf.find(L);
    auto [it, inserted] = groupOf.emplace(root, groups.size());
    if (inserted)
      groups.emplace_back();
    groups[it->second].push_back(L);
  }

  for (auto& group : groups) {
    LogicalLoop LL;
    LL.order = loops_.size();
    LL.copies = group;
    llvm::DebugLoc start;
    for (llvm::Loop* L : group)
      if ((start = loopStartLoc(L)))
        break;
    LL.location = formatDebugLoc(start);
    LL.inlinedAt = inlinedAtChain(start);

    bool anyMarked = false, anyDisabled = false;
    unsigned bestSize = ~0u;
    bool bestSimplified = false;
    unsigned simdWidth = 0;
    bool simdScalable = false;
    llvm::Loop* simdCopy = nullptr;
    for (llvm::Loop* L : group) {
      bool marked = isProcessedByVectorizer(L);
      anyMarked |= marked;
      anyDisabled |= vectorizationDisabled(L);
      bool scalable = false;
      unsigned width = vectorWidthOf(L, LI, &scalable);
      if (marked && width > 1) {
        if (width > LL.vectorWidth) {
          LL.vectorBody = L;
          LL.vectorWidth = width;
          LL.scalable = scalable;
        }
        continue;
      }
      if (width > simdWidth) {
        simdWidth = width;
        simdScalable = scalable;
        simdCopy = L;
      }
      // A runtime-unrolled copy of the vector body isn't a scalar copy.
      if (width > 1 && group.size() > 1)
        continue;
      // Prefer copies LLVM's loop analyses accept (loop-simplify form),
      // then the smallest.
      bool simplified = L->isLoopSimplifyForm();
      unsigned size = ownInstructionCount(L, LI);
      if ((simplified && !bestSimplified) ||
          (simplified == bestSimplified && size < bestSize)) {
        bestSize = size;
        bestSimplified = simplified;
        LL.scalar = L;
      }
    }

    // Rerun the vectorizer on a copy whose iteration count isn't capped by
    // an unroll factor (remainders run fewer than VF*IC or UF times).
    LL.oracleCopy = LL.scalar;
    auto bounded = [&](llvm::Loop* L) {
      unsigned max = SE.getSmallConstantMaxTripCount(L);
      return max != 0 && max <= 64 && group.size() > 1;
    };
    if (LL.scalar && bounded(LL.scalar)) {
      unsigned best = 0;
      for (llvm::Loop* L : group) {
        if (L == LL.vectorBody || !L->isLoopSimplifyForm() || bounded(L))
          continue;
        bool sc = false;
        if (vectorWidthOf(L, LI, &sc) > 1)
          continue;
        unsigned size = ownInstructionCount(L, LI);
        if (!best || size < best) {
          best = size;
          LL.oracleCopy = L;
        }
      }
    }

    // When the loop vectorizer widens a loop (VF > 1) without run-time
    // checks, it tags the scalar remainder llvm.loop.unroll.runtime.disable;
    // when it only interleaves, it doesn't. Interleaving by k and then SLP
    // packing the k copies also leaves a counter stepping by exactly the
    // vector width, while a real vector body steps by VF * interleave.
    // Both together mean the vector code came from the SLP vectorizer.
    if (LL.vectorBody) {
      bool sawRemainder = false, remainderOfVectorized = false;
      for (llvm::Loop* L : group) {
        if (L == LL.vectorBody || !isProcessedByVectorizer(L))
          continue;
        bool sc = false;
        if (vectorWidthOf(L, LI, &sc) > 1)
          continue;
        sawRemainder = true;
        remainderOfVectorized |= llvm::getBooleanLoopAttribute(
            L, "llvm.loop.unroll.runtime.disable");
      }
      bool stepIsWidth = false;
      for (llvm::PHINode& Phi : LL.vectorBody->getHeader()->phis()) {
        if (!Phi.getType()->isIntegerTy() || !SE.isSCEVable(Phi.getType()))
          continue;
        const auto* AR =
            llvm::dyn_cast<llvm::SCEVAddRecExpr>(SE.getSCEV(&Phi));
        if (!AR || AR->getLoop() != LL.vectorBody)
          continue;
        if (const auto* C = llvm::dyn_cast<llvm::SCEVConstant>(
                AR->getStepRecurrence(SE)))
          stepIsWidth |= C->getAPInt() == LL.vectorWidth;
      }
      if (sawRemainder && !remainderOfVectorized && stepIsWidth &&
          !LL.scalable) {
        LL.interleavedThenSlp = true;
        simdCopy = LL.vectorBody;
        simdWidth = LL.vectorWidth;
        simdScalable = LL.scalable;
        LL.vectorBody = nullptr;
        LL.vectorWidth = 0;
        anyMarked = false;  // Report as SIMD code, not as a verdict.
      }
    }

    if (LL.vectorBody) {
      LL.state = VectorizerState::Vectorized;
    } else if (anyMarked) {
      LL.state = LL.location.empty() && group.size() == 1
                     ? VectorizerState::Unknown
                     : VectorizerState::InterleavedOnly;
    } else if (simdWidth > 1) {
      LL.state = VectorizerState::AlreadySimd;
      LL.vectorWidth = simdWidth;
      LL.scalable = simdScalable;
      forEachOwnInstruction(simdCopy, LI, [&](llvm::Instruction& I) {
        if (!I.getType()->isVectorTy() &&
            !(llvm::isa<llvm::StoreInst>(I) &&
              I.getOperand(0)->getType()->isVectorTy()))
          return;
        std::string line = sourceLine(&I);
        if (!line.empty() && std::find(LL.simdLines.begin(), LL.simdLines.end(),
                                       line) == LL.simdLines.end())
          LL.simdLines.push_back(line);
      });
    } else if (anyDisabled) {
      LL.state = VectorizerState::Disabled;
    } else {
      LL.state = VectorizerState::NotVectorized;
    }

    llvm::Loop* rep = LL.scalar ? LL.scalar : LL.vectorBody;
    LL.depth = rep->getLoopDepth();
    LL.innermost = rep->isInnermost();
    // A vectorizer or unroller copy's count ("n mod 4"...) isn't the source
    // loop's.
    if (group.size() == 1 && !anyMarked) {
      LL.tripCount = tripCountOf(rep, SE);
      if (LL.tripCount.find("<") != std::string::npos)
        LL.tripCount.clear();  // Involves values we can't name.
    }

    for (llvm::Loop* L : group)
      index_[L] = loops_.size();
    loops_.push_back(std::move(LL));
  }
}

const LogicalLoop* LoopCatalog::find(const llvm::Loop* L) const {
  auto it = index_.find(L);
  return it == index_.end() ? nullptr : &loops_[it->second];
}

}  // namespace analyzer
