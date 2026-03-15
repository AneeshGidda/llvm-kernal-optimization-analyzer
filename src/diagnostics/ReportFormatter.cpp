#include "analyzer/ReportFormatter.h"

#include <algorithm>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

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

int severityOrder(DiagnosticSeverity s) {
  switch (s) {
    case DiagnosticSeverity::Error: return 0;
    case DiagnosticSeverity::Warning: return 1;
    case DiagnosticSeverity::Note: return 2;
  }
  return 3;
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

int categoryOrder(DiagnosticCategory c) {
  switch (c) {
    case DiagnosticCategory::Loop: return 0;
    case DiagnosticCategory::Memory: return 1;
    case DiagnosticCategory::Vectorization: return 2;
    case DiagnosticCategory::InstructionMix: return 3;
    case DiagnosticCategory::RedundantLoad: return 4;
    case DiagnosticCategory::Simplification: return 5;
    case DiagnosticCategory::General: return 6;
  }
  return 7;
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

  std::vector<Diagnostic> sorted = diagnostics;
  std::sort(sorted.begin(), sorted.end(),
            [](const Diagnostic& a, const Diagnostic& b) {
              if (a.functionName != b.functionName)
                return a.functionName < b.functionName;
              if (severityOrder(a.severity) != severityOrder(b.severity))
                return severityOrder(a.severity) < severityOrder(b.severity);
              return categoryOrder(a.category) < categoryOrder(b.category);
            });

  unsigned totalErr = 0, totalWarn = 0, totalNote = 0;
  std::map<std::string, std::tuple<unsigned, unsigned, unsigned>> fnCounts;
  for (const auto& d : sorted) {
    if (d.severity == DiagnosticSeverity::Error) ++totalErr;
    else if (d.severity == DiagnosticSeverity::Warning) ++totalWarn;
    else ++totalNote;
    auto& t = fnCounts[d.functionName];
    if (d.severity == DiagnosticSeverity::Error) ++std::get<0>(t);
    else if (d.severity == DiagnosticSeverity::Warning) ++std::get<1>(t);
    else ++std::get<2>(t);
  }

  out << "=== Summary ===\n";
  out << "Total: " << sorted.size() << " (";
  if (totalErr) out << totalErr << " error(s) ";
  if (totalWarn) out << totalWarn << " warning(s) ";
  if (totalNote) out << totalNote << " note(s)";
  out << ")\n";

  unsigned topCount = 0;
  for (const auto& d : sorted) {
    if (d.severity == DiagnosticSeverity::Note) continue;
    if (topCount++ >= 3) break;
    out << "  Top: [" << d.functionName << "] " << severityStr(d.severity)
        << " - " << d.message << "\n";
  }
  out << "\n--- Diagnostics ---\n";

  std::string lastFn;
  for (const auto& d : sorted) {
    if (lastFn != d.functionName) {
      if (!lastFn.empty()) out << "\n";
      lastFn = d.functionName;
      auto it = fnCounts.find(lastFn);
      unsigned fnErr = 0, fnWarn = 0, fnNote = 0;
      if (it != fnCounts.end()) {
        fnErr = std::get<0>(it->second);
        fnWarn = std::get<1>(it->second);
        fnNote = std::get<2>(it->second);
      }
      out << "--- " << (lastFn.empty() ? "(unknown)" : lastFn) << " (";
      if (fnErr) out << fnErr << " error(s) ";
      if (fnWarn) out << fnWarn << " warning(s) ";
      if (fnNote) out << fnNote << " note(s)";
      out << ") ---\n";
    }

    out << "[" << severityStr(d.severity) << "] [" << categoryStr(d.category)
        << "] " << d.message;
    if (!d.loopOrRegionContext.empty())
      out << " (" << d.loopOrRegionContext << ")";
    out << "\n";
    if (verbose || !d.evidence.empty()) {
      out << "  Evidence: " << d.evidence << "\n";
    }
    if (verbose || !d.suggestions.empty()) {
      out << "  Suggestions:\n";
      for (const auto& s : d.suggestions)
        out << "    - " << s << "\n";
    }
    if (!verbose && d.suggestions.empty() && d.evidence.empty())
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
