#include "analyzer/LoopAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/LoopSummary.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/Dominators.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>

#include <functional>

namespace analyzer {

namespace {

void summarizeLoop(llvm::Loop* L, unsigned depth, unsigned index,
                   LoopSummary& out) {
  out.depth = depth;
  out.loopIndex = index;
  out.headerBlockName = L->getHeader()->getName().str();
  out.blockCount = 0;
  out.instructionCount = 0;
  out.memoryOpCount = 0;
  out.arithmeticCount = 0;

  for (llvm::BasicBlock* BB : L->blocks()) {
    ++out.blockCount;
    for (llvm::Instruction& I : *BB) {
      ++out.instructionCount;
      if (I.mayReadOrWriteMemory())
        ++out.memoryOpCount;
      if (llvm::isa<llvm::BinaryOperator>(I) ||
          llvm::isa<llvm::UnaryOperator>(I) ||
          llvm::isa<llvm::GetElementPtrInst>(I))
        ++out.arithmeticCount;
    }
  }
}

}  // namespace

void LoopAnalyzer::run(llvm::Function& F, AnalysisContext& ctx) {
  llvm::DominatorTree DT(F);
  llvm::LoopInfo LI(DT);

  std::vector<LoopSummary> summaries;
  unsigned index = 0;
  std::function<void(llvm::Loop*, unsigned)> collect =
      [&](llvm::Loop* L, unsigned depth) {
        LoopSummary s;
        summarizeLoop(L, depth, index++, s);
        summaries.push_back(s);
        for (llvm::Loop* sub : L->getSubLoops())
          collect(sub, depth + 1);
      };
  for (llvm::Loop* L : LI) {
    collect(L, 0);
  }

  unsigned maxDepth = 0;
  for (const auto& s : summaries)
    if (s.depth > maxDepth)
      maxDepth = s.depth;

  std::string fnName = F.getName().str();

  if (!summaries.empty()) {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Note;
    d.category = DiagnosticCategory::Loop;
    d.functionName = fnName;
    d.message = "Function has " + std::to_string(summaries.size()) +
                " loop(s), max nesting depth " + std::to_string(maxDepth) + ".";
    d.evidence = "LoopInfo analysis.";
    d.confidence = 1.0f;
    ctx.getEmitter().add(d);
  }

  if (summaries.empty())
    return;

  LoopSummary* deepest = &summaries[0];
  LoopSummary* mostMemory = &summaries[0];
  LoopSummary* mostArith = &summaries[0];
  for (auto& s : summaries) {
    if (s.depth > deepest->depth)
      deepest = &s;
    if (s.memoryOpCount > mostMemory->memoryOpCount)
      mostMemory = &s;
    if (s.arithmeticCount > mostArith->arithmeticCount)
      mostArith = &s;
  }

  if (deepest->depth >= 1) {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Note;
    d.category = DiagnosticCategory::Loop;
    d.functionName = fnName;
    d.loopOrRegionContext = "loop depth " + std::to_string(deepest->depth);
    d.message = "Deepest loop (depth " + std::to_string(deepest->depth) +
                ") is an analysis hotspot.";
    d.evidence = "Block " + deepest->headerBlockName + ", " +
                 std::to_string(deepest->instructionCount) + " instructions.";
    d.suggestions.push_back("Consider tiling or fusion for this loop.");
    d.confidence = 0.8f;
    ctx.getEmitter().add(d);
  }

  if (mostMemory->memoryOpCount > 4 &&
      mostMemory->instructionCount > 0 &&
      (float)mostMemory->memoryOpCount / mostMemory->instructionCount > 0.3f) {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Warning;
    d.category = DiagnosticCategory::Loop;
    d.functionName = fnName;
    d.loopOrRegionContext = "loop with high memory density";
    d.message = "Loop has high memory op density; may be memory-bound.";
    d.evidence = std::to_string(mostMemory->memoryOpCount) + " memory ops, " +
                 std::to_string(mostMemory->instructionCount) + " total instructions.";
    d.suggestions.push_back("Consider loop tiling to improve reuse.");
    d.suggestions.push_back("Review data layout for contiguous access.");
    d.confidence = 0.6f;
    ctx.getEmitter().add(d);
  }

  if (mostArith->arithmeticCount > 8 &&
      mostArith->instructionCount > 0 &&
      (float)mostArith->arithmeticCount / mostArith->instructionCount > 0.4f) {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Note;
    d.category = DiagnosticCategory::Loop;
    d.functionName = fnName;
    d.loopOrRegionContext = "loop with high arithmetic intensity";
    d.message = "Loop has high arithmetic intensity; compute-bound candidate.";
    d.evidence = std::to_string(mostArith->arithmeticCount) + " arithmetic ops.";
    d.suggestions.push_back("Good candidate for vectorization or unrolling.");
    d.confidence = 0.6f;
    ctx.getEmitter().add(d);
  }
}

}  // namespace analyzer
