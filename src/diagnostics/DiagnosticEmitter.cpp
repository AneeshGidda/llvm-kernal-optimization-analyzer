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

static std::string categoryKey(DiagnosticCategory c) {
  switch (c) {
    case DiagnosticCategory::Loop:
      return "Loop";
    case DiagnosticCategory::Memory:
      return "Memory";
    case DiagnosticCategory::Vectorization:
      return "Vectorization";
    case DiagnosticCategory::InstructionMix:
      return "InstructionMix";
    case DiagnosticCategory::RedundantLoad:
      return "RedundantLoad";
    case DiagnosticCategory::Simplification:
      return "Simplification";
    case DiagnosticCategory::General:
      return "General";
  }
  return "?";
}

std::vector<Diagnostic> DiagnosticEmitter::getDiagnosticsForReport(
    bool /*verbose*/) const {
  std::set<std::string> seen;
  std::vector<Diagnostic> out;
  for (const auto& d : diagnostics_) {
    std::string key = d.functionName + "\n" + categoryKey(d.category) + "\n" +
                      d.message + "\n" + d.loopOrRegionContext;
    if (seen.count(key))
      continue;
    seen.insert(key);
    out.push_back(d);
  }
  std::sort(out.begin(), out.end(), [](const Diagnostic& a, const Diagnostic& b) {
    if (severityOrder(a.severity) != severityOrder(b.severity))
      return severityOrder(a.severity) < severityOrder(b.severity);
    return categoryKey(a.category) < categoryKey(b.category);
  });
  return out;
}

}  // namespace analyzer
