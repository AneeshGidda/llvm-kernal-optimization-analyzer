#ifndef ANALYZER_CONFIG_H
#define ANALYZER_CONFIG_H

#include <string>

namespace analyzer {

/// Command-line options for one run.
struct Config {
  /// Also print informational notes (access patterns) and the LLVM analysis
  /// behind each finding.
  bool verbose = false;
  /// Emit JSON instead of human-readable report.
  bool jsonOutput = false;
  /// Optional function name filter (empty = every function with loops).
  std::string functionFilter;
  /// clang's optimization record for the same compile
  /// (-fsave-optimization-record); gives the vectorizer's real decisions.
  std::string remarksPath;
};

}  // namespace analyzer

#endif
