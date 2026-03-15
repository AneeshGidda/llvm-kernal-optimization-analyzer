#include "analyzer/LoopAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/LoopContext.h"
#include "analyzer/LoopSummary.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/Dominators.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>

#include <functional>
#include <utility>

namespace analyzer {

namespace {

void summarizeLoop(llvm::Loop* L, unsigned depth, unsigned index,
                   LoopSummary& out) {
  out.depth = depth;
  out.loopIndex = index;
  llvm::StringRef nameRef = L->getHeader()->getName();
  out.headerBlockName = nameRef.empty() ? "unnamed." + std::to_string(index)
                                        : nameRef.str();
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
  std::string fnName = F.getName().str();

  std::vector<std::pair<LoopSummary, LoopContext>> summaries;
  unsigned index = 0;
  std::function<void(llvm::Loop*, unsigned)> collect =
      [&](llvm::Loop* L, unsigned depth) {
        LoopSummary s;
        summarizeLoop(L, depth, index, s);
        LoopContext lctx = buildLoopContext(L, fnName, index);
        summaries.push_back({s, lctx});
        ++index;
        for (llvm::Loop* sub : L->getSubLoops())
          collect(sub, depth + 1);
      };
  for (llvm::Loop* L : LI) {
    collect(L, 0);
  }

  unsigned maxDepth = 0;
  for (const auto& p : summaries)
    if (p.first.depth > maxDepth)
      maxDepth = p.first.depth;

  if (!summaries.empty()) {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Note;
    d.category = DiagnosticCategory::Loop;
    d.functionName = fnName;
    d.message = "Function has " + std::to_string(summaries.size()) +
                " loop(s), max nesting depth " + std::to_string(maxDepth) + ".";
    std::string headerList;
    for (size_t i = 0; i < summaries.size(); ++i) {
      if (i) headerList += ", ";
      headerList += "%" + summaries[i].second.headerBlockName;
    }
    d.evidence = std::to_string(summaries.size()) + " loops in preorder, max depth " +
                 std::to_string(maxDepth) + "; headers: " + headerList + ".";
    d.confidence = 1.0f;
    ctx.getEmitter().add(d);
  }

  if (summaries.empty())
    return;

  size_t idxDeepest = 0, idxMostMemory = 0, idxMostArith = 0;
  for (size_t i = 1; i < summaries.size(); ++i) {
    const auto& s = summaries[i].first;
    if (s.depth > summaries[idxDeepest].first.depth) idxDeepest = i;
    if (s.memoryOpCount > summaries[idxMostMemory].first.memoryOpCount)
      idxMostMemory = i;
    if (s.arithmeticCount > summaries[idxMostArith].first.arithmeticCount)
      idxMostArith = i;
  }

  const auto& deepest = summaries[idxDeepest].first;
  const auto& lctxDeepest = summaries[idxDeepest].second;
  {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Note;
    d.category = DiagnosticCategory::Loop;
    d.functionName = fnName;
    d.loopOrRegionContext = formatLoopContext(lctxDeepest);
    d.message = "Deepest loop (depth " + std::to_string(deepest.depth) +
                ") is an analysis hotspot.";
    d.evidence = "Loop at header %" + deepest.headerBlockName + " has " +
                 std::to_string(deepest.instructionCount) + " instructions, " +
                 std::to_string(deepest.memoryOpCount) + " memory ops; depth " +
                 std::to_string(lctxDeepest.depth) +
                 ", innermost=" + (lctxDeepest.innermost ? "true" : "false") + ".";
    d.suggestions.push_back("Consider tiling or fusion for this loop.");
    d.confidence = 0.8f;
    ctx.getEmitter().add(d);
  }

  const auto& mostMemory = summaries[idxMostMemory].first;
  const auto& lctxMem = summaries[idxMostMemory].second;
  if (mostMemory.memoryOpCount > 4 && mostMemory.instructionCount > 0 &&
      (float)mostMemory.memoryOpCount / mostMemory.instructionCount > 0.3f) {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Warning;
    d.category = DiagnosticCategory::Loop;
    d.functionName = fnName;
    d.loopOrRegionContext = formatLoopContext(lctxMem);
    d.message = "Loop has high memory op density; may be memory-bound.";
    d.evidence = std::to_string(mostMemory.memoryOpCount) + " memory ops, " +
                 std::to_string(mostMemory.instructionCount) +
                 " total instructions in loop body.";
    d.suggestions.push_back("Consider loop tiling to improve reuse.");
    d.suggestions.push_back("Review data layout for contiguous access.");
    d.confidence = 0.6f;
    ctx.getEmitter().add(d);
  }

  const auto& mostArith = summaries[idxMostArith].first;
  const auto& lctxArith = summaries[idxMostArith].second;
  if (mostArith.arithmeticCount > 8 && mostArith.instructionCount > 0 &&
      (float)mostArith.arithmeticCount / mostArith.instructionCount > 0.4f) {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Note;
    d.category = DiagnosticCategory::Loop;
    d.functionName = fnName;
    d.loopOrRegionContext = formatLoopContext(lctxArith);
    d.message = "Loop has high arithmetic intensity; compute-bound candidate.";
    d.evidence = std::to_string(mostArith.arithmeticCount) + " arithmetic ops in loop body.";
    d.suggestions.push_back("Good candidate for vectorization or unrolling.");
    d.confidence = 0.6f;
    ctx.getEmitter().add(d);
  }
}

}  // namespace analyzer
