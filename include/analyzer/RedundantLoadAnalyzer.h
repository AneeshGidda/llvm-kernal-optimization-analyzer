#ifndef ANALYZER_REDUNDANT_LOAD_ANALYZER_H
#define ANALYZER_REDUNDANT_LOAD_ANALYZER_H

namespace llvm {
class Function;
}

namespace analyzer {

class AnalysisContext;

/// Detects redundant loads and hoistable invariant access.
class RedundantLoadAnalyzer {
public:
  void run(llvm::Function& F, AnalysisContext& ctx);
};

}  // namespace analyzer

#endif
