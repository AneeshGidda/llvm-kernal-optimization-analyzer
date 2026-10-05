#ifndef ANALYZER_LLVM_ANALYSES_H
#define ANALYZER_LLVM_ANALYSES_H

#include <llvm/Analysis/AliasAnalysis.h>
#include <llvm/Analysis/DivergenceAnalysis.h>
#include <llvm/Analysis/LoopAccessAnalysis.h>
#include <llvm/Analysis/LoopInfo.h>
#include <llvm/Analysis/PostDominators.h>
#include <llvm/Analysis/ScalarEvolution.h>
#include <llvm/Analysis/TargetLibraryInfo.h>
#include <llvm/Analysis/TargetTransformInfo.h>
#include <llvm/IR/Dominators.h>
#include <llvm/IR/PassManager.h>
#include <llvm/Passes/PassBuilder.h>
#include <llvm/Target/TargetMachine.h>

#include <map>
#include <memory>
#include <string>

namespace analyzer {

/// Creates a TargetMachine for the module's target triple so that cost
/// queries (TargetTransformInfo) describe the real hardware. Returns nullptr
/// and sets `error` if the triple is missing or its target isn't built into
/// this LLVM.
std::unique_ptr<llvm::TargetMachine>
createTargetMachineFor(const llvm::Module& M, std::string& error);

/// A new-pass-manager analysis stack (the same one `opt` uses) over a module.
/// All analyses are computed lazily and cached; nothing here mutates the IR.
class AnalysisStack {
public:
  /// `TM` may be null; TTI then falls back to LLVM's target-independent
  /// defaults.
  explicit AnalysisStack(llvm::TargetMachine* TM);
  ~AnalysisStack();
  AnalysisStack(const AnalysisStack&) = delete;
  AnalysisStack& operator=(const AnalysisStack&) = delete;

  llvm::FunctionAnalysisManager& fam() {
    return FAM;
  }

private:
  llvm::LoopAnalysisManager LAM;
  llvm::FunctionAnalysisManager FAM;
  llvm::CGSCCAnalysisManager CGAM;
  llvm::ModuleAnalysisManager MAM;
  llvm::PassBuilder PB;
};

/// Per-function accessors over an AnalysisStack, plus a cache of
/// LoopAccessInfo (LLVM's memory-dependence analysis for one loop).
class FunctionAnalyses {
public:
  FunctionAnalyses(llvm::Function& F, AnalysisStack& stack);

  llvm::Function& function() {
    return F;
  }
  llvm::LoopInfo& loopInfo();
  llvm::ScalarEvolution& scev();
  llvm::DominatorTree& domTree();
  llvm::PostDominatorTree& postDomTree();
  /// Which values and branches can differ between GPU threads, judged with
  /// the target's divergence sources (thread IDs, atomics, ...). Only
  /// meaningful with a GPU TargetMachine.
  llvm::DivergenceInfo& divergence();
  llvm::AAResults& alias();
  llvm::TargetTransformInfo& tti();
  llvm::TargetLibraryInfo& tli();
  /// LLVM's dependence/runtime-check analysis for `L` (the one the loop
  /// vectorizer consults). Cached per loop.
  const llvm::LoopAccessInfo& loopAccess(llvm::Loop* L);

private:
  llvm::Function& F;
  llvm::FunctionAnalysisManager& FAM;
  std::map<llvm::Loop*, std::unique_ptr<llvm::LoopAccessInfo>> laiCache;
};

}  // namespace analyzer

#endif
