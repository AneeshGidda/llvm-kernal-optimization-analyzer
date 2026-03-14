#ifndef ANALYZER_DIAGNOSTIC_H
#define ANALYZER_DIAGNOSTIC_H

#include <string>
#include <vector>

namespace analyzer {

enum class DiagnosticSeverity { Note, Warning, Error };
enum class DiagnosticCategory {
  Loop,
  Memory,
  Vectorization,
  InstructionMix,
  RedundantLoad,
  Simplification,
  General
};

struct Diagnostic {
  DiagnosticSeverity severity = DiagnosticSeverity::Warning;
  DiagnosticCategory category = DiagnosticCategory::General;
  std::string message;
  std::string functionName;
  std::string loopOrRegionContext;
  std::string evidence;
  std::vector<std::string> suggestions;
  /// 0.0 = heuristic, 1.0 = high confidence
  float confidence = 0.5f;
};

}  // namespace analyzer

#endif
