#include "analyzer/VectorizationAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/Dominators.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>

namespace analyzer {

namespace {

bool loopHasCall(llvm::Loop* L) {
  for (llvm::BasicBlock* BB : L->blocks())
    for (llvm::Instruction& I : *BB)
      if (llvm::isa<llvm::CallBase>(I))
        return true;
  return false;
}

bool loopHasComplexControl(llvm::Loop* L) {
  unsigned branches = 0;
  for (llvm::BasicBlock* BB : L->blocks())
    for (llvm::Instruction& I : *BB)
      if (llvm::isa<llvm::BranchInst>(I) || llvm::isa<llvm::SwitchInst>(I))
        ++branches;
  return branches > 1;
}

bool loopHasStridedOrIrregularMemory(llvm::Loop* L) {
  for (llvm::BasicBlock* BB : L->blocks()) {
    for (llvm::Instruction& I : *BB) {
      if (auto* load = llvm::dyn_cast<llvm::LoadInst>(&I)) {
        if (!llvm::isa<llvm::GetElementPtrInst>(load->getPointerOperand()))
          return true;
      } else if (auto* store = llvm::dyn_cast<llvm::StoreInst>(&I)) {
        if (!llvm::isa<llvm::GetElementPtrInst>(store->getPointerOperand()))
          return true;
      }
    }
  }
  return false;
}

}  // namespace

void VectorizationAnalyzer::run(llvm::Function& F, AnalysisContext& ctx) {
  llvm::DominatorTree DT(F);
  llvm::LoopInfo LI(DT);
  std::string fnName = F.getName().str();

  for (llvm::Loop* L : LI.getLoopsInPreorder()) {
    std::string loopCtx = "loop " + L->getHeader()->getName().str();
    bool hasCall = loopHasCall(L);
    bool hasComplexControl = loopHasComplexControl(L);
    bool hasIrregularMem = loopHasStridedOrIrregularMemory(L);

    if (hasCall) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Warning;
      d.category = DiagnosticCategory::Vectorization;
      d.functionName = fnName;
      d.loopOrRegionContext = loopCtx;
      d.message = "Loop contains a call; may prevent vectorization.";
      d.evidence = "Call instruction in loop body.";
      d.suggestions.push_back("Inline the call or move it outside the loop if possible.");
      d.suggestions.push_back("Use compiler flags to enable inlining (e.g. -O3).");
      d.confidence = 0.8f;
      ctx.getEmitter().add(d);
    }

    if (hasComplexControl) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Warning;
      d.category = DiagnosticCategory::Vectorization;
      d.functionName = fnName;
      d.loopOrRegionContext = loopCtx;
      d.message = "Loop has non-trivial control flow; may limit vectorization.";
      d.evidence = "Multiple branches in loop.";
      d.suggestions.push_back("Simplify control flow or use predication.");
      d.suggestions.push_back("Consider restructuring to reduce branches.");
      d.confidence = 0.6f;
      ctx.getEmitter().add(d);
    }

    if (hasIrregularMem) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Warning;
      d.category = DiagnosticCategory::Vectorization;
      d.functionName = fnName;
      d.loopOrRegionContext = loopCtx;
      d.message = "Possible irregular memory access; vectorization may be limited.";
      d.evidence = "Load/store through non-GEP pointer.";
      d.suggestions.push_back("Use contiguous indexing where possible.");
      d.suggestions.push_back("Consider restrict/__builtin_assume_aligned for alias disambiguation.");
      d.confidence = 0.5f;
      ctx.getEmitter().add(d);
    }

    if (!hasCall && !hasComplexControl && !hasIrregularMem) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Note;
      d.category = DiagnosticCategory::Vectorization;
      d.functionName = fnName;
      d.loopOrRegionContext = loopCtx;
      d.message = "Loop appears vectorization-friendly (no obvious blockers).";
      d.evidence = "No calls, simple control, regular memory in loop.";
      d.suggestions.push_back("Ensure -O3 or -ftree-vectorize is enabled.");
      d.confidence = 0.6f;
      ctx.getEmitter().add(d);
    }
  }
}

}  // namespace analyzer
