#ifndef ANALYZER_VECTORIZATION_ANALYZER_H
#define ANALYZER_VECTORIZATION_ANALYZER_H

namespace analyzer {

class AnalysisContext;
class CompileRemarks;
class FunctionAnalyses;
class LoopCatalog;
class VectorizerOracle;

/// For every innermost loop: did LLVM vectorize it, and if not, why, in
/// terms of the source (which call, which pointers, which variable) and what
/// to change.
///
/// The verdict comes from LLVM's own loop vectorizer: clang's optimization
/// record when given (CompileRemarks), else a rerun of the vectorizer on the
/// IR (VectorizerOracle). This class doesn't re-implement legality or cost
/// rules. Suggested fixes are checked with the oracle where possible (rerun
/// with the change applied) and labeled when they couldn't be. It adds the specifics
/// the vectorizer's one-line remarks leave out, using LLVM analyses:
/// LoopAccessAnalysis (dependences, runtime checks), IVDescriptors
/// (reductions and recurrences), TargetLibraryInfo (math library calls), and
/// TargetTransformInfo (gather support).
class VectorizationAnalyzer {
public:
  /// `oracle` may be null when no target is available; verdicts for
  /// non-vectorized loops are then reported as unavailable. `remarks` may be
  /// null when no optimization record was given.
  void run(FunctionAnalyses& FA, const LoopCatalog& catalog,
           const VectorizerOracle* oracle, const CompileRemarks* remarks,
           AnalysisContext& ctx);
};

}  // namespace analyzer

#endif
