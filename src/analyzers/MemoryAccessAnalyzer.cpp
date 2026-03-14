#include "analyzer/MemoryAccessAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/Dominators.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>

namespace analyzer {

namespace {

/// Heuristic: check if a pointer value is likely strided (loop-variant GEP).
bool isLikelyStrided(llvm::Value* ptr, llvm::Loop* L) {
  llvm::GetElementPtrInst* GEP = llvm::dyn_cast<llvm::GetElementPtrInst>(ptr);
  if (!GEP)
    return false;
  for (unsigned i = 1; i < GEP->getNumOperands(); ++i) {
    llvm::Value* idx = GEP->getOperand(i);
    if (llvm::isa<llvm::PHINode>(idx) || (L && L->isLoopInvariant(idx) == false))
      return true;
  }
  return false;
}

/// Count memory ops in loop and classify access pattern.
void analyzeLoopMemory(llvm::Loop* L, unsigned& loadCount, unsigned& storeCount,
                      bool& hasStrided, bool& hasIrregular) {
  loadCount = 0;
  storeCount = 0;
  hasStrided = false;
  hasIrregular = false;

  for (llvm::BasicBlock* BB : L->blocks()) {
    for (llvm::Instruction& I : *BB) {
      if (auto* load = llvm::dyn_cast<llvm::LoadInst>(&I)) {
        ++loadCount;
        if (isLikelyStrided(load->getPointerOperand(), L))
          hasStrided = true;
        if (!llvm::isa<llvm::GetElementPtrInst>(load->getPointerOperand()))
          hasIrregular = true;
      } else if (auto* store = llvm::dyn_cast<llvm::StoreInst>(&I)) {
        ++storeCount;
        if (isLikelyStrided(store->getPointerOperand(), L))
          hasStrided = true;
        if (!llvm::isa<llvm::GetElementPtrInst>(store->getPointerOperand()))
          hasIrregular = true;
      }
    }
  }
}

}  // namespace

void MemoryAccessAnalyzer::run(llvm::Function& F, AnalysisContext& ctx) {
  llvm::DominatorTree DT(F);
  llvm::LoopInfo LI(DT);
  std::string fnName = F.getName().str();

  for (llvm::Loop* L : LI.getLoopsInPreorder()) {
    unsigned loadCount = 0, storeCount = 0;
    bool hasStrided = false, hasIrregular = false;
    analyzeLoopMemory(L, loadCount, storeCount, hasStrided, hasIrregular);

    unsigned memOps = loadCount + storeCount;
    if (memOps == 0)
      continue;

    if (hasStrided) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Warning;
      d.category = DiagnosticCategory::Memory;
      d.functionName = fnName;
      d.loopOrRegionContext = "loop " + L->getHeader()->getName().str();
      d.message = "Strided memory access in loop; may hurt locality.";
      d.evidence = std::to_string(loadCount) + " loads, " +
                   std::to_string(storeCount) + " stores; GEP uses loop-variant index.";
      d.suggestions.push_back("Consider loop tiling to improve reuse.");
      d.suggestions.push_back("Review data layout (e.g. row-major vs column-major).");
      d.confidence = 0.6f;
      ctx.getEmitter().add(d);
    }

    if (hasIrregular) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Warning;
      d.category = DiagnosticCategory::Memory;
      d.functionName = fnName;
      d.loopOrRegionContext = "loop " + L->getHeader()->getName().str();
      d.message = "Irregular or non-GEP memory addressing in loop.";
      d.evidence = "Load/store through non-GEP pointer.";
      d.suggestions.push_back("Consider contiguous buffer layout or index simplification.");
      d.confidence = 0.5f;
      ctx.getEmitter().add(d);
    }

    if (memOps >= 4) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Note;
      d.category = DiagnosticCategory::Memory;
      d.functionName = fnName;
      d.loopOrRegionContext = "loop " + L->getHeader()->getName().str();
      d.message = "Loop has high memory op density; may be memory-bound.";
      d.evidence = std::to_string(memOps) + " memory ops in loop.";
      d.suggestions.push_back("Consider loop tiling for better cache reuse.");
      d.suggestions.push_back("Check if invariant loads can be hoisted.");
      d.confidence = 0.5f;
      ctx.getEmitter().add(d);
    }
  }
}

}  // namespace analyzer
