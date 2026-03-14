#include "analyzer/ReportFormatter.h"

#include <iostream>
#include <sstream>

namespace analyzer {

namespace {

const char* severityStr(DiagnosticSeverity s) {
  switch (s) {
    case DiagnosticSeverity::Note:
      return "Note";
    case DiagnosticSeverity::Warning:
      return "Warning";
    case DiagnosticSeverity::Error:
      return "Error";
  }
  return "?";
}

const char* categoryStr(DiagnosticCategory c) {
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

void escapeJson(std::ostream& out, const std::string& s) {
  for (char c : s) {
    if (c == '"')
      out << "\\\"";
    else if (c == '\\')
      out << "\\\\";
    else if (c == '\n')
      out << "\\n";
    else if ((unsigned char)c < 32)
      out << "\\u" << std::hex << (int)c << std::dec;
    else
      out << c;
  }
}

}  // namespace

void ReportFormatter::formatTerminal(std::ostream& out,
                                     const std::vector<Diagnostic>& diagnostics,
                                     bool verbose) const {
  if (diagnostics.empty()) {
    out << "No diagnostics.\n";
    return;
  }
  unsigned warn = 0, err = 0, note = 0;
  for (const auto& d : diagnostics) {
    if (d.severity == DiagnosticSeverity::Warning) ++warn;
    else if (d.severity == DiagnosticSeverity::Error) ++err;
    else ++note;
  }
  out << "=== Summary ===\n";
  out << "Total: " << diagnostics.size() << " (";
  if (err) out << err << " error(s) ";
  if (warn) out << warn << " warning(s) ";
  if (note) out << note << " note(s)";
  out << ")\n\n--- Diagnostics ---\n";

  std::string lastFn;
  for (const auto& d : diagnostics) {
    if (!lastFn.empty() && lastFn != d.functionName)
      out << "\n";
    lastFn = d.functionName;
    if (!d.functionName.empty())
      out << "[" << d.functionName << "] ";
    out << "[" << severityStr(d.severity) << "] [" << categoryStr(d.category)
        << "] " << d.message;
    if (verbose && !d.evidence.empty())
      out << "\n  Evidence: " << d.evidence;
    if (verbose && !d.suggestions.empty()) {
      out << "\n  Suggestions:";
      for (const auto& s : d.suggestions)
        out << "\n    - " << s;
    }
    out << "\n";
  }
}

void ReportFormatter::formatJSON(
    std::ostream& out, const std::vector<Diagnostic>& diagnostics) const {
  out << "{\"diagnostics\":[";
  for (size_t i = 0; i < diagnostics.size(); ++i) {
    const auto& d = diagnostics[i];
    if (i)
      out << ",";
    out << "{\"severity\":\"" << severityStr(d.severity) << "\",\"category\":\""
        << categoryStr(d.category) << "\",\"message\":\"";
    escapeJson(out, d.message);
    out << "\",\"function\":\"";
    escapeJson(out, d.functionName);
    out << "\",\"loopOrRegion\":\"";
    escapeJson(out, d.loopOrRegionContext);
    out << "\",\"evidence\":\"";
    escapeJson(out, d.evidence);
    out << "\",\"confidence\":" << d.confidence << ",\"suggestions\":[";
    for (size_t j = 0; j < d.suggestions.size(); ++j) {
      if (j) out << ",";
      out << "\"";
      escapeJson(out, d.suggestions[j]);
      out << "\"";
    }
    out << "]}";
  }
  out << "]}\n";
}

}  // namespace analyzer
