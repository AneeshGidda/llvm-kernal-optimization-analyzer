#include "analyzer/RedundantLoadAnalyzer.h"

#include "analyzer/AnalysisContext.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/LoopContext.h"

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

/// Value is loop-invariant (constant, argument, or defined outside L).
bool isLoopInvariant(llvm::Value* V, llvm::Loop* L) {
  if (llvm::isa<llvm::Constant>(V)) return true;
  if (llvm::isa<llvm::Argument>(V)) return true;
  if (auto* I = llvm::dyn_cast<llvm::Instruction>(V))
    return !L->contains(I->getParent());
  return true;
}

/// Check for repeated load from same address inside loop (same block, no intervening store).
bool hasRepeatedLoadInLoop(llvm::Loop* L) {
  std::vector<std::pair<llvm::LoadInst*, llvm::LoadInst*>> pairs;
  for (llvm::BasicBlock* BB : L->blocks())
    findRedundantLoadsInBlock(*BB, pairs);
  return !pairs.empty();
}

/// Instruction whose operands are all loop-invariant (candidate for hoisting).
bool isInvariantRecompute(llvm::Instruction* I, llvm::Loop* L) {
  if (llvm::isa<llvm::PHINode>(I) || I->isTerminator())
    return false;
  if (!llvm::isa<llvm::BinaryOperator>(I) && !llvm::isa<llvm::UnaryOperator>(I) &&
      !llvm::isa<llvm::GetElementPtrInst>(I) && !llvm::isa<llvm::CmpInst>(I))
    return false;
  for (unsigned i = 0; i < I->getNumOperands(); ++i) {
    if (!isLoopInvariant(I->getOperand(i), L))
      return false;
  }
  return true;
}

}  // namespace

void RedundantLoadAnalyzer::run(llvm::Function& F, AnalysisContext& ctx) {
  std::string fnName = F.getName().str();
  llvm::DominatorTree DT(F);
  llvm::LoopInfo LI(DT);

  std::vector<std::pair<llvm::LoadInst*, llvm::LoadInst*>> redundantPairs;
  for (llvm::BasicBlock& BB : F)
    findRedundantLoadsInBlock(BB, redundantPairs);

  for (const auto& p : redundantPairs) {
    llvm::BasicBlock* BB = p.first->getParent();
    if (LI.getLoopFor(BB)) continue;
    llvm::StringRef blockName = BB->getName();
    std::string blockStr = blockName.empty() ? "block" : blockName.str();
    Diagnostic d;
    d.severity = DiagnosticSeverity::Warning;
    d.category = DiagnosticCategory::RedundantLoad;
    d.functionName = fnName;
    d.message = "Possible redundant load from same pointer in same block.";
    d.evidence = "Two loads from same pointer value with no intervening store in block %" + blockStr + ".";
    d.suggestions.push_back("Reuse first load result or hoist to common point.");
    d.confidence = 0.6f;
    ctx.getEmitter().add(d);
  }

  unsigned preorderIndex = 0;
  for (llvm::Loop* L : LI.getLoopsInPreorder()) {
    LoopContext lctx = buildLoopContext(L, fnName, preorderIndex++);

    if (hasRepeatedLoadInLoop(L)) {
      Diagnostic d;
      d.severity = DiagnosticSeverity::Warning;
      d.category = DiagnosticCategory::RedundantLoad;
      d.functionName = fnName;
      d.loopOrRegionContext = formatLoopContext(lctx);
      d.message = "Repeated load from same address in loop body.";
      d.evidence = "Repeated load from same address in loop (no intervening store).";
      d.suggestions.push_back("Reuse first load result or hoist to common point.");
      d.confidence = 0.6f;
      ctx.getEmitter().add(d);
    }

    bool foundInvariantRecompute = false;
    for (llvm::BasicBlock* BB : L->blocks()) {
      if (foundInvariantRecompute) break;
      for (llvm::Instruction& I : *BB) {
        if (isInvariantRecompute(&I, L)) {
          Diagnostic d;
          d.severity = DiagnosticSeverity::Note;
          d.category = DiagnosticCategory::RedundantLoad;
          d.functionName = fnName;
          d.loopOrRegionContext = formatLoopContext(lctx);
          d.message = "Value derived from invariant operands recomputed each iteration.";
          d.evidence = "Instruction with all loop-invariant operands inside loop body.";
          d.suggestions.push_back("Hoist to loop preheader if safe.");
          d.confidence = 0.6f;
          ctx.getEmitter().add(d);
          foundInvariantRecompute = true;
          break;
        }
      }
    }

    bool foundInvariant = false;
    for (llvm::BasicBlock* BB : L->blocks()) {
      if (foundInvariant) break;
      for (llvm::Instruction& I : *BB) {
        if (auto* load = llvm::dyn_cast<llvm::LoadInst>(&I)) {
          if (isLoopInvariantLoad(load, L)) {
            std::string ptrName;
            if (load->getPointerOperand()->hasName())
              ptrName = " (e.g. " + load->getPointerOperand()->getName().str() + ")";
            Diagnostic d;
            d.severity = DiagnosticSeverity::Note;
            d.category = DiagnosticCategory::RedundantLoad;
            d.functionName = fnName;
            d.loopOrRegionContext = formatLoopContext(lctx);
            d.message = "Loop-invariant load may be hoistable.";
            d.evidence = "Load pointer is defined outside loop (argument or instruction in preheader)" + ptrName + ".";
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
