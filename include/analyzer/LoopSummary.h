#ifndef ANALYZER_LOOP_SUMMARY_H
#define ANALYZER_LOOP_SUMMARY_H

#include <string>
#include <vector>

namespace analyzer {

/// Per-loop summary for diagnostics.
struct LoopSummary {
  unsigned loopIndex = 0;
  unsigned depth = 0;
  unsigned blockCount = 0;
  unsigned instructionCount = 0;
  unsigned memoryOpCount = 0;
  unsigned arithmeticCount = 0;
  std::string headerBlockName;
};

}  // namespace analyzer

#endif
