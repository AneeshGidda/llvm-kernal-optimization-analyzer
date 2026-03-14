#ifndef ANALYZER_INSTRUCTION_MIX_ANALYZER_H
#define ANALYZER_INSTRUCTION_MIX_ANALYZER_H

namespace llvm {
class Function;
}

namespace analyzer {

class AnalysisContext;

/// Characterizes function as compute-heavy, memory-heavy, or control-heavy.
class InstructionMixAnalyzer {
public:
  void run(llvm::Function& F, AnalysisContext& ctx);
};

}  // namespace analyzer

#endif
