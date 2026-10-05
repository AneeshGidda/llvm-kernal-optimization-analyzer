#include "analyzer/LLVMAnalyses.h"

#include <llvm/IR/Module.h>
#include <llvm/MC/TargetRegistry.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/Target/TargetOptions.h>

namespace analyzer {

std::unique_ptr<llvm::TargetMachine>
createTargetMachineFor(const llvm::Module& M, std::string& error) {
  static bool initialized = [] {
    llvm::InitializeAllTargetInfos();
    llvm::InitializeAllTargets();
    llvm::InitializeAllTargetMCs();
    return true;
  }();
  (void)initialized;

  const std::string& triple = M.getTargetTriple();
  if (triple.empty()) {
    error = "module has no target triple";
    return nullptr;
  }
  std::string lookupError;
  const llvm::Target* T =
      llvm::TargetRegistry::lookupTarget(triple, lookupError);
  if (!T) {
    error = "target '" + triple + "' is not available in this LLVM build (" +
            lookupError + ")";
    return nullptr;
  }
  // CPU and features are left empty here: TTI picks up each function's own
  // "target-cpu"/"target-features" attributes, which is what clang emitted.
  llvm::TargetOptions options;
  return std::unique_ptr<llvm::TargetMachine>(
      T->createTargetMachine(triple, "", "", options, llvm::None));
}

AnalysisStack::AnalysisStack(llvm::TargetMachine* TM) : PB(TM) {
  PB.registerModuleAnalyses(MAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.registerFunctionAnalyses(FAM);
  // Not part of the default function analyses in LLVM 15.
  FAM.registerPass([] { return llvm::DivergenceAnalysis(); });
  PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
}

AnalysisStack::~AnalysisStack() {
  // Results hold references into each other; clear inner-to-outer.
  LAM.clear();
  FAM.clear();
  CGAM.clear();
  MAM.clear();
}

FunctionAnalyses::FunctionAnalyses(llvm::Function& F, AnalysisStack& stack)
    : F(F), FAM(stack.fam()) {}

llvm::LoopInfo& FunctionAnalyses::loopInfo() {
  return FAM.getResult<llvm::LoopAnalysis>(F);
}
llvm::ScalarEvolution& FunctionAnalyses::scev() {
  return FAM.getResult<llvm::ScalarEvolutionAnalysis>(F);
}
llvm::DominatorTree& FunctionAnalyses::domTree() {
  return FAM.getResult<llvm::DominatorTreeAnalysis>(F);
}
llvm::PostDominatorTree& FunctionAnalyses::postDomTree() {
  return FAM.getResult<llvm::PostDominatorTreeAnalysis>(F);
}
llvm::DivergenceInfo& FunctionAnalyses::divergence() {
  return FAM.getResult<llvm::DivergenceAnalysis>(F);
}
llvm::AAResults& FunctionAnalyses::alias() {
  return FAM.getResult<llvm::AAManager>(F);
}
llvm::TargetTransformInfo& FunctionAnalyses::tti() {
  return FAM.getResult<llvm::TargetIRAnalysis>(F);
}
llvm::TargetLibraryInfo& FunctionAnalyses::tli() {
  return FAM.getResult<llvm::TargetLibraryAnalysis>(F);
}

const llvm::LoopAccessInfo& FunctionAnalyses::loopAccess(llvm::Loop* L) {
  auto& slot = laiCache[L];
  if (!slot)
    slot = std::make_unique<llvm::LoopAccessInfo>(L, &scev(), &tli(), &alias(),
                                                  &domTree(), &loopInfo());
  return *slot;
}

}  // namespace analyzer
