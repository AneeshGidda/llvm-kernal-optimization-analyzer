#include "analyzer/RedundantLoadAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/Dominators.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Value.h>

namespace analyzer {

namespace {

/// Conservative check: same pointer operand, same block, no store in between.
void findRedundantLoadsInBlock(llvm::BasicBlock& BB,
                               std::vector<std::pair<llvm::LoadInst*, llvm::LoadInst*>>& pairs) {
  std::vector<llvm::LoadInst*> loads;
  for (llvm::Instruction& I : BB) {
    if (auto* store = llvm::dyn_cast<llvm::StoreInst>(&I)) {
      loads.clear();
      continue;
    }
    if (auto* load = llvm::dyn_cast<llvm::LoadInst>(&I)) {
      llvm::Value* ptr = load->getPointerOperand();
      for (llvm::LoadInst* prev : loads) {
        if (prev->getPointerOperand() == ptr) {
          pairs.push_back({prev, load});
          break;
        }
      }
      loads.push_back(load);
    }
  }
}

/// Simple loop-invariant: load's pointer is not defined inside the loop.
bool isLoopInvariantLoad(llvm::LoadInst* load, llvm::Loop* L) {
  llvm::Value* ptr = load->getPointerOperand();
  if (llvm::isa<llvm::Argument>(ptr))
    return true;
  if (auto* inst = llvm::dyn_cast<llvm::Instruction>(ptr)) {
    llvm::BasicBlock* block = inst->getParent();
    return !L->contains(block);
  }
  return true;
}

}  // namespace

void RedundantLoadAnalyzer::run(llvm::Function& F, AnalysisContext& ctx) {
  std::string fnName = F.getName().str();

  std::vector<std::pair<llvm::LoadInst*, llvm::LoadInst*>> redundantPairs;
  for (llvm::BasicBlock& BB : F)
    findRedundantLoadsInBlock(BB, redundantPairs);

  for (const auto& p : redundantPairs) {
    Diagnostic d;
    d.severity = DiagnosticSeverity::Warning;
    d.category = DiagnosticCategory::RedundantLoad;
    d.functionName = fnName;
    d.message = "Possible redundant load from same pointer in same block.";
    d.evidence = "Two loads from same pointer with no intervening store.";
    d.suggestions.push_back("Consider reusing the first load result or hoisting.");
    d.confidence = 0.6f;
    ctx.getEmitter().add(d);
  }

  llvm::DominatorTree DT(F);
  llvm::LoopInfo LI(DT);
  for (llvm::Loop* L : LI.getLoopsInPreorder()) {
    bool foundInvariant = false;
    for (llvm::BasicBlock* BB : L->blocks()) {
      if (foundInvariant)
        break;
      for (llvm::Instruction& I : *BB) {
        if (auto* load = llvm::dyn_cast<llvm::LoadInst>(&I)) {
          if (isLoopInvariantLoad(load, L)) {
            Diagnostic d;
            d.severity = DiagnosticSeverity::Note;
            d.category = DiagnosticCategory::RedundantLoad;
            d.functionName = fnName;
            d.loopOrRegionContext = "loop " + L->getHeader()->getName().str();
            d.message = "Loop-invariant load may be hoistable.";
            d.evidence = "Load pointer is invariant in loop.";
            d.suggestions.push_back("Hoist this load to the loop preheader.");
            d.confidence = 0.7f;
            ctx.getEmitter().add(d);
            foundInvariant = true;
            break;
          }
        }
      }
    }
  }
}

}  // namespace analyzer
