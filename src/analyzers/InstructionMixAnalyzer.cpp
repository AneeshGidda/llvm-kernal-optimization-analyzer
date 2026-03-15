#include "analyzer/InstructionMixAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"

#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>

namespace analyzer {

void InstructionMixAnalyzer::run(llvm::Function& F, AnalysisContext& ctx) {
  unsigned arithmetic = 0;
  unsigned memory = 0;
  unsigned branch = 0;
  unsigned calls = 0;
  unsigned other = 0;

  for (const auto& BB : F) {
    for (const auto& I : BB) {
      if (llvm::isa<llvm::CallBase>(I))
        ++calls;
      else if (llvm::isa<llvm::LoadInst>(I) || llvm::isa<llvm::StoreInst>(I))
        ++memory;
      else if (llvm::isa<llvm::BranchInst>(I) || llvm::isa<llvm::SwitchInst>(I) ||
               llvm::isa<llvm::IndirectBrInst>(I) ||
               llvm::isa<llvm::CmpInst>(I))
        ++branch;
      else if (llvm::isa<llvm::BinaryOperator>(I) ||
               llvm::isa<llvm::UnaryOperator>(I) ||
               llvm::isa<llvm::GetElementPtrInst>(I) ||
               llvm::isa<llvm::PHINode>(I))
        ++arithmetic;
      else
        ++other;
    }
  }

  unsigned total = arithmetic + memory + branch + calls + other;
  if (total == 0)
    return;

  std::string fnName = F.getName().str();
  Diagnostic d;
  d.severity = DiagnosticSeverity::Note;
  d.category = DiagnosticCategory::InstructionMix;
  d.functionName = fnName;
  float memRatio = (float)memory / total;
  float arithRatio = (float)arithmetic / total;
  float ctrlRatio = (float)branch / total;

  if (memRatio >= 0.35f) {
    d.message = "Function appears memory-heavy (high load/store density).";
    d.evidence = "arithmetic=" + std::to_string(arithmetic) + ", memory=" +
                 std::to_string(memory) + ", compare/branch=" + std::to_string(branch) +
                 ", calls=" + std::to_string(calls) + " (high memory intensity).";
    d.suggestions.push_back("Consider improving locality or reducing memory traffic.");
  } else if (arithRatio >= 0.4f) {
    d.message = "Function appears compute-heavy (high arithmetic density).";
    d.evidence = "arithmetic=" + std::to_string(arithmetic) + ", memory=" +
                 std::to_string(memory) + ", compare/branch=" + std::to_string(branch) +
                 " (high arithmetic intensity).";
    d.suggestions.push_back("Good candidate for vectorization or parallelization.");
  } else if (ctrlRatio >= 0.2f) {
    d.message = "Function has significant control flow (branches/cmp).";
    d.evidence = "arithmetic=" + std::to_string(arithmetic) + ", memory=" +
                 std::to_string(memory) + ", compare/branch=" + std::to_string(branch) +
                 " (significant control flow).";
    d.suggestions.push_back("Simplifying control flow may help vectorization.");
  } else {
    d.message = "Mixed instruction mix; review loop and memory patterns.";
    d.evidence = "arithmetic=" + std::to_string(arithmetic) + ", memory=" +
                 std::to_string(memory) + ", compare/branch=" + std::to_string(branch) +
                 ", calls=" + std::to_string(calls) + ".";
  }
  d.confidence = 0.6f;
  ctx.getEmitter().add(d);
}

}  // namespace analyzer
