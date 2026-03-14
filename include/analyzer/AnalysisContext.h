#ifndef ANALYZER_ANALYSIS_CONTEXT_H
#define ANALYZER_ANALYSIS_CONTEXT_H

#include "analyzer/Config.h"
#include "analyzer/DiagnosticEmitter.h"
#include "analyzer/FunctionInfo.h"

#include <llvm/IR/Module.h>

#include <memory>
#include <vector>

namespace analyzer {

/// Holds the current module, config, diagnostic sink, and function inventory
/// for a single analysis run.
class AnalysisContext {
public:
  explicit AnalysisContext(std::unique_ptr<llvm::Module> module);

  llvm::Module* getModule() const {
    return module_.get();
  }
  Config& getConfig() {
    return config_;
  }
  const Config& getConfig() const {
    return config_;
  }
  DiagnosticEmitter& getEmitter() {
    return emitter_;
  }
  const DiagnosticEmitter& getEmitter() const {
    return emitter_;
  }

  /// Build inventory of all functions (definitions only). Idempotent.
  void buildFunctionInventory();
  const std::vector<FunctionInfo>& getFunctionInventory() const {
    return functionInventory_;
  }

private:
  std::unique_ptr<llvm::Module> module_;
  Config config_;
  DiagnosticEmitter emitter_;
  std::vector<FunctionInfo> functionInventory_;
};

}  // namespace analyzer

#endif
