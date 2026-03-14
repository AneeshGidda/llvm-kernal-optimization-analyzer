#ifndef ANALYZER_FUNCTION_INFO_H
#define ANALYZER_FUNCTION_INFO_H

#include <string>

namespace llvm {
class Function;
}

namespace analyzer {

/// Metadata for a single function, used by inventory and analyzers.
struct FunctionInfo {
  std::string name;
  std::string linkage;
  unsigned instructionCount = 0;
  unsigned basicBlockCount = 0;
  bool isDeclaration = false;
};

/// Build FunctionInfo for a given function.
FunctionInfo getFunctionInfo(const llvm::Function& F);

}  // namespace analyzer

#endif
