#ifndef ANALYZER_DIAGNOSTIC_H
#define ANALYZER_DIAGNOSTIC_H

#include <string>
#include <vector>

namespace analyzer {

/// Warning: the compiler missed an optimization and we can name why.
/// Note: informational (e.g. "this loop was vectorized").
enum class DiagnosticSeverity { Note, Warning, Error };

/// Coalescing, SharedMemory and Divergence are GPU findings.
enum class DiagnosticCategory {
  Vectorization,
  Memory,
  Coalescing,
  SharedMemory,
  Divergence,
  General,
};

struct Diagnostic {
  DiagnosticSeverity severity = DiagnosticSeverity::Note;
  DiagnosticCategory category = DiagnosticCategory::General;
  std::string functionName;
  /// Human description of the loop, e.g. "loop at matmul.c:8 (depth 3)".
  /// Empty for function-level diagnostics.
  std::string loop;
  /// Preorder position of the loop in its function; keeps report order stable.
  unsigned loopOrder = 0;
  /// One-line finding.
  std::string message;
  /// Facts that support the finding, one per line.
  std::vector<std::string> evidence;
  /// Concrete source-level changes that address the finding.
  std::vector<std::string> suggestions;
  /// Which LLVM analysis established the finding (instead of a made-up
  /// confidence score), e.g. "LLVM LoopVectorize (rerun on this IR)".
  std::string basis;
};

}  // namespace analyzer

#endif
