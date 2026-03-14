#include "analyzer/KernelClassifier.h"

#include <llvm/Analysis/LoopInfo.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Dominators.h>

namespace analyzer {

bool KernelClassifier::isKernelLike(llvm::Function& F) const {
  if (F.isDeclaration() || F.empty())
    return false;

  unsigned instCount = 0;
  unsigned memoryOps = 0;

  for (const auto& BB : F) {
    for (const auto& I : BB) {
      ++instCount;
      if (I.mayReadOrWriteMemory())
        ++memoryOps;
    }
  }

  bool hasLoop = false;
  llvm::DominatorTree DT(F);
  llvm::LoopInfo LI(DT);
  hasLoop = !LI.empty();

  if (instCount < 8)
    return false;
  if (memoryOps >= 2 && instCount >= 15)
    return true;
  if (hasLoop && instCount >= 20)
    return true;

  std::string name = F.getName().str();
  if (name.find("kernel") != std::string::npos ||
      name.find("Kernel") != std::string::npos ||
      name.find("matmul") != std::string::npos ||
      name.find("reduce") != std::string::npos ||
      name.find("launch") != std::string::npos)
    return true;

  return instCount >= 30;
}

}  // namespace analyzer
