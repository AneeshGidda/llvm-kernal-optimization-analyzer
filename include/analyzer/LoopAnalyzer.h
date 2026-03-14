#ifndef ANALYZER_LOOP_ANALYZER_H
#define ANALYZER_LOOP_ANALYZER_H

namespace llvm {
class Function;
}

namespace analyzer {

class AnalysisContext;

/// Discovers loops and summarizes structure (nesting, depth, hot regions).
class LoopAnalyzer {
public:
  void run(llvm::Function& F, AnalysisContext& ctx);
};

}  // namespace analyzer

#endif
