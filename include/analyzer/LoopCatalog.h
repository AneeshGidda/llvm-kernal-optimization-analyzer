#ifndef ANALYZER_LOOP_CATALOG_H
#define ANALYZER_LOOP_CATALOG_H

#include <map>
#include <string>
#include <vector>

namespace llvm {
class Loop;
class LoopInfo;
class ScalarEvolution;
}  // namespace llvm

namespace analyzer {

/// What the loop vectorizer already did to a source loop in this IR.
enum class VectorizerState {
  /// No sign the vectorizer transformed it (it gave up, or never ran).
  NotVectorized,
  /// A copy of the loop operates on vector types.
  Vectorized,
  /// The vectorizer processed it but chose width 1: it only unrolled
  /// ("interleaved") the loop. No SIMD.
  InterleavedOnly,
  /// Not processed by the loop vectorizer, but the loop already contains
  /// vector code: SLP-vectorized, written with intrinsics/vector types, or an
  /// inner loop that was vectorized and then fully unrolled.
  AlreadySimd,
  /// Vectorization turned off for this loop by a pragma or loop metadata
  /// (`llvm.loop.vectorize.enable` false or `llvm.loop.vectorize.width` 1).
  Disabled,
  /// A scalar copy marked as processed by the vectorizer whose siblings we
  /// couldn't find (no debug info and no recognizable vectorizer layout).
  Unknown,
};

/// One loop as the programmer wrote it. Optimized IR can contain several
/// copies of a source loop (vector body, scalar remainder, runtime-unrolled
/// copies); we group them back together by source location (including the
/// call sites it was inlined through) and by the vectorizer's CFG layout.
struct LogicalLoop {
  unsigned order = 0;
  /// The copy analyses run on: the smallest scalar copy in loop-simplify
  /// form. Unrolling and interleaving duplicate the body, so the smallest
  /// copy is usually the original body; when the only copy is unrolled,
  /// collectAccesses() folds the duplicated accesses back together.
  /// Null only if every copy is vectorized (no scalar remainder).
  llvm::Loop* scalar = nullptr;
  /// The copy LLVM's vectorizer is rerun on (VectorizerOracle). Usually
  /// `scalar`, but not an unroll remainder whose iteration count is bounded
  /// by the unroll factor: the vectorizer would judge that bound, not the
  /// source loop.
  llvm::Loop* oracleCopy = nullptr;
  /// The copy that operates on vectors, if the loop was vectorized.
  llvm::Loop* vectorBody = nullptr;
  std::vector<llvm::Loop*> copies;
  VectorizerState state = VectorizerState::NotVectorized;
  /// Vector width (elements) of the vectorized copy, or of the existing SIMD
  /// code for AlreadySimd; `scalable` for SVE/RVV.
  unsigned vectorWidth = 0;
  bool scalable = false;
  /// For AlreadySimd: source lines ("f.c:9") of the vector instructions.
  std::vector<std::string> simdLines;
  /// For AlreadySimd: the loop vectorizer processed the loop but only
  /// interleaved it; the vector code came from the SLP vectorizer.
  bool interleavedThenSlp = false;
  /// "matmul.c:8:7", or "" without debug info.
  std::string location;
  /// Call sites the loop was inlined through ("f.c:10:3"), or "".
  std::string inlinedAt;
  unsigned depth = 0;
  bool innermost = false;
  /// Iteration count as an expression ("n", "100"), or "" if not computable.
  /// Only filled for loops with a single copy (copies have altered counts).
  std::string tripCount;

  /// "loop at matmul.c:8" (or by IR block name without debug info), plus
  /// "(inlined at ...)" for inlined copies.
  std::string label() const;
  /// label() plus depth, innermost, and trip count.
  std::string describe() const;
};

/// All logical loops of one function, in preorder.
class LoopCatalog {
public:
  LoopCatalog(llvm::LoopInfo& LI, llvm::ScalarEvolution& SE);

  const std::vector<LogicalLoop>& loops() const {
    return loops_;
  }
  /// The logical loop a given IR loop (any copy) belongs to.
  const LogicalLoop* find(const llvm::Loop* L) const;

private:
  std::vector<LogicalLoop> loops_;
  std::map<const llvm::Loop*, size_t> index_;
};

}  // namespace analyzer

#endif
