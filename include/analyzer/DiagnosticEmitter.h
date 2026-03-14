#ifndef ANALYZER_DIAGNOSTIC_EMITTER_H
#define ANALYZER_DIAGNOSTIC_EMITTER_H

#include "analyzer/Diagnostic.h"

#include <vector>

namespace analyzer {

/// Collects diagnostics from analyzers and supports
/// deduplication/prioritization.
class DiagnosticEmitter {
public:
  void add(Diagnostic d);
  const std::vector<Diagnostic>& getDiagnostics() const {
    return diagnostics_;
  }
  /// Deduplicate and sort by severity then category; use for reporting.
  std::vector<Diagnostic> getDiagnosticsForReport(bool verbose) const;
  void clear() {
    diagnostics_.clear();
  }

private:
  std::vector<Diagnostic> diagnostics_;
};

}  // namespace analyzer

#endif
