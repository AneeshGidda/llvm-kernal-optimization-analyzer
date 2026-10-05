#ifndef ANALYZER_DIAGNOSTIC_EMITTER_H
#define ANALYZER_DIAGNOSTIC_EMITTER_H

#include "analyzer/Diagnostic.h"

#include <vector>

namespace analyzer {

/// Collects diagnostics from analyzers.
class DiagnosticEmitter {
public:
  void add(Diagnostic d);
  const std::vector<Diagnostic>& getDiagnostics() const {
    return diagnostics_;
  }
  /// Deduplicated diagnostics in report order: function, loop, severity.
  std::vector<Diagnostic> getDiagnosticsForReport() const;

private:
  std::vector<Diagnostic> diagnostics_;
};

}  // namespace analyzer

#endif
