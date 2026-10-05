#ifndef ANALYZER_ANALYSIS_CONTEXT_H
#define ANALYZER_ANALYSIS_CONTEXT_H

#include "analyzer/Config.h"
#include "analyzer/DiagnosticEmitter.h"

namespace analyzer {

/// Configuration and diagnostic sink for a single analysis run.
class AnalysisContext {
public:
  explicit AnalysisContext(Config config) : config_(std::move(config)) {}

  const Config& getConfig() const {
    return config_;
  }
  DiagnosticEmitter& getEmitter() {
    return emitter_;
  }
  const DiagnosticEmitter& getEmitter() const {
    return emitter_;
  }

private:
  Config config_;
  DiagnosticEmitter emitter_;
};

}  // namespace analyzer

#endif
