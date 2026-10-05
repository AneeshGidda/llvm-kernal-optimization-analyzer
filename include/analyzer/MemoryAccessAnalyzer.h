#ifndef ANALYZER_MEMORY_ACCESS_ANALYZER_H
#define ANALYZER_MEMORY_ACCESS_ANALYZER_H

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

namespace llvm {
class Instruction;
class Loop;
class LoopInfo;
class ScalarEvolution;
}  // namespace llvm

namespace analyzer {

class AnalysisContext;
class FunctionAnalyses;
class LoopCatalog;

/// How an address changes when one particular loop advances by one
/// iteration, derived from ScalarEvolution (not from the IR's shape).
struct Stride {
  enum class Kind {
    Invariant,   // same address every iteration
    Sequential,  // +1 element
    Reverse,     // -1 element
    Constant,    // +k elements, |k| > 1
    Symbolic,    // +expr elements, e.g. a row length "n"
    Irregular,   // not an affine function of the loop counter
  };
  Kind kind = Kind::Irregular;
  int64_t elements = 0;  // for Constant
  std::string symbolic;  // for Symbolic
  /// The address depends on a value loaded inside the loop (x[idx[i]]).
  bool dataDependent = false;

  bool isCacheFriendly() const {
    return kind == Kind::Invariant || kind == Kind::Sequential ||
           kind == Kind::Reverse;
  }
  bool isStrided() const {
    return kind == Kind::Constant || kind == Kind::Symbolic;
  }
  std::string text() const;
};

/// One load or store inside a loop and its stride at every nesting level.
struct MemoryAccess {
  llvm::Instruction* inst = nullptr;
  bool isStore = false;
  std::string base;  // array the address points into ("B")
  std::string line;  // "matmul.c:9"
  /// strides[0] is for the innermost loop containing the access, then each
  /// enclosing loop outward.
  std::vector<std::pair<llvm::Loop*, Stride>> strides;

  const Stride& inner() const {
    return strides.front().second;
  }
  std::string describe() const;  // "load of B (matmul.c:9)"
};

/// Every load/store directly inside L, with strides for L and its parents.
///
/// When L is an unrolled copy (by the vectorizer's interleaving or the loop
/// unroller), each source access appears k times with an identical debug
/// location, one source iteration apart. Those are folded back into one
/// access with the per-source-iteration stride, and `*unrolledBy` is set to
/// k (1 when nothing was folded). Without debug info nothing is folded.
std::vector<MemoryAccess> collectAccesses(llvm::Loop* L,
                                          llvm::ScalarEvolution& SE,
                                          llvm::LoopInfo& LI,
                                          unsigned* unrolledBy = nullptr);

/// Reports, per loop:
///  - the access pattern of every load/store in innermost loops;
///  - loop swaps that turn strided accesses sequential, checked for safety
///    with LLVM's DependenceAnalysis (and the swap advice is only given
///    unconditionally when that check proves it safe);
///  - loads/stores at a fixed address that run on every iteration yet stay
///    inside the loop because something in it might touch that address
///    (alias analysis names it).
class MemoryAccessAnalyzer {
public:
  void run(FunctionAnalyses& FA, const LoopCatalog& catalog,
           AnalysisContext& ctx);
};

}  // namespace analyzer

#endif
