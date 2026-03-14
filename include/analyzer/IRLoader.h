#ifndef ANALYZER_IR_LOADER_H
#define ANALYZER_IR_LOADER_H

#include <llvm/IR/Module.h>

#include <memory>
#include <string>

namespace analyzer {

/// Loads LLVM IR (.ll) or bitcode (.bc) from a file into a Module.
class IRLoader {
public:
  IRLoader() = default;

  /// Load from file. Returns nullptr on error; use getLastError() for message.
  std::unique_ptr<llvm::Module> loadFromFile(const std::string& path);

  /// Last error message after a failed load.
  const std::string& getLastError() const {
    return lastError_;
  }

private:
  std::string lastError_;
};

}  // namespace analyzer

#endif
