#ifndef ANALYZER_CONFIG_H
#define ANALYZER_CONFIG_H

#include <string>

namespace analyzer {

/// Global configuration for analysis thresholds and behavior.
struct Config {
  /// If true, analyze all functions; otherwise only kernel-like candidates.
  bool analyzeAllFunctions = false;
  /// Emit verbose diagnostics.
  bool verbose = false;
  /// Emit JSON instead of human-readable report.
  bool jsonOutput = false;
  /// Optional function name filter (empty = no filter).
  std::string functionFilter;
};

}  // namespace analyzer

#endif
