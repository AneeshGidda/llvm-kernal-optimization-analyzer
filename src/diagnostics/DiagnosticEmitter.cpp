#include "analyzer/DiagnosticEmitter.h"

#include <algorithm>
#include <set>
#include <string>

namespace analyzer {

void DiagnosticEmitter::add(Diagnostic d) {
  diagnostics_.push_back(std::move(d));
}

static int severityOrder(DiagnosticSeverity s) {
  switch (s) {
    case DiagnosticSeverity::Error:
      return 0;
    case DiagnosticSeverity::Warning:
      return 1;
    case DiagnosticSeverity::Note:
      return 2;
  }
  return 3;
}

std::vector<Diagnostic> DiagnosticEmitter::getDiagnosticsForReport() const {
  std::set<std::string> seen;
  std::vector<Diagnostic> out;
  for (const auto& d : diagnostics_) {
    std::string key = d.functionName + "\n" + d.loop + "\n" + d.message;
    if (!seen.insert(key).second)
      continue;
    out.push_back(d);
  }
  // Function-level diagnostics (no loop) first, then loops in source order.
  std::stable_sort(
      out.begin(), out.end(), [](const Diagnostic& a, const Diagnostic& b) {
        if (a.functionName != b.functionName)
          return a.functionName < b.functionName;
        if (a.loop.empty() != b.loop.empty())
          return a.loop.empty();
        if (a.loopOrder != b.loopOrder)
          return a.loopOrder < b.loopOrder;
        return severityOrder(a.severity) < severityOrder(b.severity);
      });
  return out;
}

}  // namespace analyzer
