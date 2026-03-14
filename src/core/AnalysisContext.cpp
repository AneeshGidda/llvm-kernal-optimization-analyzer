#include "analyzer/AnalysisContext.h"

#include <llvm/IR/Function.h>

namespace analyzer {

AnalysisContext::AnalysisContext(std::unique_ptr<llvm::Module> module)
    : module_(std::move(module)) {}

void AnalysisContext::buildFunctionInventory() {
  if (!module_ || !functionInventory_.empty())
    return;
  for (const auto& F : module_->functions()) {
    if (F.isDeclaration())
      continue;
    functionInventory_.push_back(getFunctionInfo(F));
  }
}

}  // namespace analyzer
