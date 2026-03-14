#include "analyzer/FunctionInfo.h"

#include <llvm/IR/Function.h>
#include <llvm/IR/GlobalValue.h>

namespace analyzer {

FunctionInfo getFunctionInfo(const llvm::Function& F) {
  FunctionInfo info;
  info.name = F.getName().str();
  info.isDeclaration = F.isDeclaration();

  switch (F.getLinkage()) {
    case llvm::GlobalValue::ExternalLinkage:
      info.linkage = "external";
      break;
    case llvm::GlobalValue::InternalLinkage:
      info.linkage = "internal";
      break;
    case llvm::GlobalValue::PrivateLinkage:
      info.linkage = "private";
      break;
    case llvm::GlobalValue::WeakAnyLinkage:
    case llvm::GlobalValue::WeakODRLinkage:
      info.linkage = "weak";
      break;
    default:
      info.linkage = "other";
      break;
  }

  if (!F.empty()) {
    info.basicBlockCount = 0;
    info.instructionCount = 0;
    for (const auto& BB : F) {
      ++info.basicBlockCount;
      for (const auto& I : BB)
        ++info.instructionCount;
    }
  }

  return info;
}

}  // namespace analyzer
