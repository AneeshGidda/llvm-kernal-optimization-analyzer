#ifndef ANALYZER_VECTORIZER_ORACLE_H
#define ANALYZER_VECTORIZER_ORACLE_H

#include "analyzer/LoopCatalog.h"

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace llvm {
class BasicBlock;
class DebugLoc;
class Function;
class Loop;
class Module;
class TargetMachine;
}  // namespace llvm

namespace analyzer {

/// One optimization remark emitted by LLVM's loop vectorizer.
struct VectorizerRemark {
  enum class Kind { Passed, Missed, Analysis };
  Kind kind = Kind::Analysis;
  /// Stable identifier, e.g. "CantComputeNumberOfIterations". We classify on
  /// this rather than on message text.
  std::string name;
  /// The message as clang would print it with -Rpass-analysis=loop-vectorize.
  std::string message;
  /// "file.c:9:3" (the instruction the remark is about, or the loop start).
  std::string location;
};

/// Asks LLVM's own loop vectorizer why it did or didn't vectorize each loop,
/// instead of re-implementing its legality and cost rules.
///
/// It runs LoopVectorizePass on a private clone of the module (the input is
/// never modified) with a diagnostic handler that captures every remark.
/// With remarks enabled, the vectorizer keeps analyzing after the first
/// failure, so all blockers of a loop are reported, not just the first.
///
/// Caveat: the clone is the *optimized* IR, which later passes (SLP, LICM,
/// unrolling...) have already changed. The vectorizer's verdict on it
/// approximates, and can differ from, the decision it made during the real
/// compile. CompileRemarks gives the real decision when clang's
/// optimization record is available.
///
/// For loops the vectorizer only interleaved (width 1), the "already
/// processed" tag is removed from the clone first so it re-explains its
/// decision.
class VectorizerOracle {
public:
  using Work = std::vector<std::pair<llvm::Function*, const LoopCatalog*>>;

  VectorizerOracle(llvm::Module& M, llvm::TargetMachine* TM, const Work& work);

  /// Remarks for the logical loop whose oracle copy has this header.
  /// Null if the loop wasn't asked about.
  const std::vector<VectorizerRemark>*
  remarksFor(const llvm::BasicBlock* header) const;

  /// What-if: apply `change` to a fresh clone of the loop's function, rerun
  /// the vectorizer, and report whether it now vectorizes the loop. Used to
  /// check a suggested fix before printing it.
  struct Retry {
    bool vectorized = false;
    /// The vectorizer's "vectorized loop (...)" message, or its first
    /// blocker otherwise.
    std::string message;
  };
  using Change = std::function<void(llvm::Function& clone, llvm::Loop& loop)>;
  Retry retry(llvm::Function& F, const LogicalLoop& LL,
              const Change& change) const;

private:
  llvm::Module& M;
  llvm::TargetMachine* TM;
  std::map<const llvm::BasicBlock*, std::vector<VectorizerRemark>> remarks_;
};

/// Loop-vectorizer remarks clang recorded during the real compile
/// (`-fsave-optimization-record`), grouped per loop. These are ground truth
/// for "why wasn't this vectorized"; the oracle's rerun is the fallback.
class CompileRemarks {
public:
  /// Loads a YAML optimization record. Returns null and sets `error` on
  /// failure.
  static std::unique_ptr<CompileRemarks> load(const std::string& path,
                                              std::string& error);

  /// Remarks for a loop the IR shows was *not* vectorized, in `function`,
  /// starting at `start`. Null if the record has none. Outcomes that ended
  /// in "vectorized loop" are skipped (they belong to another copy of the
  /// same source loop). When several remaining outcomes share that location
  /// (a helper inlined more than once) and differ, sets `*ambiguous` and
  /// returns null.
  const std::vector<VectorizerRemark>*
  find(const std::string& function, const llvm::DebugLoc& start,
       bool* ambiguous) const;

  size_t size() const {
    return byLoop_.size();
  }

private:
  std::map<std::string, std::vector<std::vector<VectorizerRemark>>> byLoop_;
};

}  // namespace analyzer

#endif
