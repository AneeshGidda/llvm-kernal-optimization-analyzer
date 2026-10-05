#include "analyzer/ReportFormatter.h"

#include <ostream>
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

const char* categoryStr(DiagnosticCategory c) {
  switch (c) {
    case DiagnosticCategory::Vectorization:
      return "Vectorization";
    case DiagnosticCategory::Memory:
      return "Memory";
    case DiagnosticCategory::Coalescing:
      return "Coalescing";
    case DiagnosticCategory::SharedMemory:
      return "Shared memory";
    case DiagnosticCategory::Divergence:
      return "Divergence";
    case DiagnosticCategory::General:
      return "General";
  }
  return "?";
}

/// Access-pattern summaries are context, not findings; shown with -v.
bool isDetailNote(const Diagnostic& d) {
  return d.severity == DiagnosticSeverity::Note &&
         d.category == DiagnosticCategory::Memory;
}

void escapeJson(std::ostream& out, const std::string& s) {
  for (char c : s) {
    if (c == '"')
      out << "\\\"";
    else if (c == '\\')
      out << "\\\\";
    else if (c == '\n')
      out << "\\n";
    else if ((unsigned char)c < 32) {
      static const char* hex = "0123456789abcdef";
      out << "\\u00" << hex[(c >> 4) & 0xf] << hex[c & 0xf];
    }
    else
      out << c;
  }
}

void jsonString(std::ostream& out, const char* key, const std::string& value) {
  out << "\"" << key << "\":\"";
  escapeJson(out, value);
  out << "\"";
}

void jsonArray(std::ostream& out, const char* key,
               const std::vector<std::string>& values) {
  out << "\"" << key << "\":[";
  for (size_t i = 0; i < values.size(); ++i) {
    if (i)
      out << ",";
    out << "\"";
    escapeJson(out, values[i]);
    out << "\"";
  }
  out << "]";
}

}  // namespace

void ReportFormatter::formatTerminal(std::ostream& out,
                                     const std::vector<Diagnostic>& diagnostics,
                                     bool verbose) const {
  unsigned errors = 0, warnings = 0, notes = 0, hidden = 0;
  std::vector<const Diagnostic*> shown;
  for (const auto& d : diagnostics) {
    if (!verbose && isDetailNote(d)) {
      ++hidden;
      continue;
    }
    shown.push_back(&d);
    if (d.severity == DiagnosticSeverity::Note)
      ++notes;
    else if (d.severity == DiagnosticSeverity::Error)
      ++errors;
    else
      ++warnings;
  }
  if (shown.empty()) {
    out << "No findings.\n";
    if (hidden)
      out << "(" << hidden << " access-pattern note(s) hidden; use -v)\n";
    return;
  }

  std::string lastFn, lastLoop;
  for (const Diagnostic* d : shown) {
    if (d->functionName != lastFn) {
      out << (lastFn.empty() ? "" : "\n") << "=== " << d->functionName
          << " ===\n";
      lastFn = d->functionName;
      lastLoop.clear();
    }
    if (!d->loop.empty() && d->loop != lastLoop) {
      out << "\n" << d->loop << "\n";
      lastLoop = d->loop;
    }
    out << "  [" << severityStr(d->severity) << "] ["
        << categoryStr(d->category) << "] " << d->message << "\n";
    for (const auto& e : d->evidence)
      out << "      " << e << "\n";
    if (!d->suggestions.empty()) {
      out << "    Fix:\n";
      for (const auto& s : d->suggestions)
        out << "      - " << s << "\n";
    }
    if (verbose && !d->basis.empty())
      out << "    Basis: " << d->basis << "\n";
  }

  out << "\n=== Summary: ";
  if (errors)
    out << errors << " error(s), ";
  out << warnings << " warning(s), " << notes << " note(s)";
  if (hidden)
    out << "; " << hidden << " access-pattern note(s) hidden (use -v)";
  out << " ===\n";
}

void ReportFormatter::formatJSON(
    std::ostream& out, const std::vector<Diagnostic>& diagnostics) const {
  out << "{\"diagnostics\":[";
  for (size_t i = 0; i < diagnostics.size(); ++i) {
    const auto& d = diagnostics[i];
    if (i)
      out << ",";
    out << "{";
    jsonString(out, "severity", severityStr(d.severity));
    out << ",";
    jsonString(out, "category", categoryStr(d.category));
    out << ",";
    jsonString(out, "function", d.functionName);
    out << ",";
    jsonString(out, "loop", d.loop);
    out << ",";
    jsonString(out, "message", d.message);
    out << ",";
    jsonArray(out, "evidence", d.evidence);
    out << ",";
    jsonArray(out, "suggestions", d.suggestions);
    out << ",";
    jsonString(out, "basis", d.basis);
    out << "}";
  }
  out << "]}\n";
}

}  // namespace analyzer
