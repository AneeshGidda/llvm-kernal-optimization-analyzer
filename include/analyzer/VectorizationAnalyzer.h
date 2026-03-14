#ifndef ANALYZER_VECTORIZATION_ANALYZER_H
#define ANALYZER_VECTORIZATION_ANALYZER_H

namespace llvm {
class Function;
}

namespace analyzer {

class AnalysisContext;

/// Estimates vectorization eligibility and identifies blockers.
class VectorizationAnalyzer {
public:
  void run(llvm::Function& F, AnalysisContext& ctx);
};

}  // namespace analyzer

#endif
