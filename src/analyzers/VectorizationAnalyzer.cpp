#include "analyzer/VectorizationAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/LoopContext.h"

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

unsigned countBranches(llvm::Loop* L) {
  unsigned n = 0;
  for (llvm::BasicBlock* BB : L->blocks())
    for (llvm::Instruction& I : *BB)
      if (llvm::isa<llvm::BranchInst>(I) || llvm::isa<llvm::SwitchInst>(I))
        ++n;
  return n;
}

bool loopHasComplexControl(llvm::Loop* L) {
  return countBranches(L) > 1;
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

/// Simple reduction-like pattern: phi in header with one incoming from loop body that uses the phi (e.g. add acc, x).
bool loopHasReductionLike(llvm::Loop* L) {
  llvm::BasicBlock* header = L->getHeader();
  for (llvm::Instruction& I : *header) {
    llvm::PHINode* phi = llvm::dyn_cast<llvm::PHINode>(&I);
    if (!phi) continue;
    for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i) {
      llvm::Value* inc = phi->getIncomingValue(i);
      if (L->contains(phi->getIncomingBlock(i))) {
        if (llvm::Instruction* incI = llvm::dyn_cast<llvm::Instruction>(inc)) {
          if (incI->getOpcode() == llvm::Instruction::Add ||
              incI->getOpcode() == llvm::Instruction::FAdd ||
              incI->getOpcode() == llvm::Instruction::Mul ||
              incI->getOpcode() == llvm::Instruction::FMul) {
            if (incI->getOperand(0) == phi || incI->getOperand(1) == phi)
              return true;
          }
        }
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

  unsigned preorderIndex = 0;
  for (llvm::Loop* L : LI.getLoopsInPreorder()) {
    LoopContext lctx = buildLoopContext(L, fnName, preorderIndex++);
    std::string loopCtxStr = formatLoopContext(lctx);

    bool hasCall = loopHasCall(L);
    unsigned branchCount = countBranches(L);
    bool hasComplexControl = branchCount > 1;
    bool hasIrregularMem = loopHasStridedOrIrregularMemory(L);
    bool hasReductionLike = loopHasReductionLike(L);

    Diagnostic d;
    d.functionName = fnName;
    d.loopOrRegionContext = loopCtxStr;
    d.category = DiagnosticCategory::Vectorization;

    if (hasCall) {
      d.severity = DiagnosticSeverity::Warning;
      d.message = "Vectorization likely blocked: call inside loop.";
      d.evidence = "Call instruction(s) in loop body (e.g. to external or non-inlined function).";
      d.suggestions.push_back("Inline the call or move it outside the loop if possible.");
      d.suggestions.push_back("Use compiler flags to enable inlining (e.g. -O3).");
      d.confidence = 0.8f;
      ctx.getEmitter().add(d);
    } else if (hasComplexControl) {
      d.severity = DiagnosticSeverity::Warning;
      d.message = "Vectorization likely blocked: multiple conditional branches in loop body.";
      d.evidence = std::to_string(branchCount) + " branch/switch instructions in loop body.";
      d.suggestions.push_back("Simplify control flow or use predication.");
      d.suggestions.push_back("Consider restructuring to reduce branches.");
      d.confidence = 0.6f;
      ctx.getEmitter().add(d);
    } else if (hasIrregularMem) {
      d.severity = DiagnosticSeverity::Warning;
      d.message = "Vectorization likely blocked: irregular memory access.";
      d.evidence = "Load/store through non-GEP pointer or multi-variant indexing.";
      d.suggestions.push_back("Use contiguous indexing where possible.");
      d.suggestions.push_back("Consider restrict/__builtin_assume_aligned for alias disambiguation.");
      d.confidence = 0.5f;
      ctx.getEmitter().add(d);
    } else if (hasReductionLike) {
      d.severity = DiagnosticSeverity::Note;
      d.message = "Vectorization uncertain: reduction-like pattern (phi update in loop).";
      d.evidence = "Reduction-like pattern detected (phi in header updated by binary op in loop); may need special handling.";
      d.suggestions.push_back("Ensure -O3 or -ftree-vectorize is enabled; compiler may vectorize reduction.");
      d.confidence = 0.5f;
      ctx.getEmitter().add(d);
    } else {
      d.severity = DiagnosticSeverity::Note;
      d.message = "Likely vectorizable: straight-line loop body, no calls, affine memory indexing.";
      d.evidence = "No calls, single branch (latch), memory through GEP; straight-line body in loop blocks.";
      d.suggestions.push_back("Ensure -O3 or -ftree-vectorize is enabled.");
      d.confidence = 0.6f;
      ctx.getEmitter().add(d);
    }
  }
}

}  // namespace analyzer
