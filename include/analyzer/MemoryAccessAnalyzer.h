#ifndef ANALYZER_MEMORY_ACCESS_ANALYZER_H
#define ANALYZER_MEMORY_ACCESS_ANALYZER_H

namespace llvm {
class Function;
}

namespace analyzer {

class AnalysisContext;

/// Analyzes load/store behavior and identifies inefficient access patterns.
class MemoryAccessAnalyzer {
public:
  void run(llvm::Function& F, AnalysisContext& ctx);
};

}  // namespace analyzer

#endif
