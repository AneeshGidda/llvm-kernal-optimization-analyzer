#ifndef ANALYZER_REPORT_FORMATTER_H
#define ANALYZER_REPORT_FORMATTER_H

#include "analyzer/Diagnostic.h"

#include <ostream>
#include <vector>

namespace analyzer {

/// Formats diagnostics for terminal or JSON output.
class ReportFormatter {
public:
  void formatTerminal(std::ostream& out,
                      const std::vector<Diagnostic>& diagnostics,
                      bool verbose) const;
  void formatJSON(std::ostream& out,
                  const std::vector<Diagnostic>& diagnostics) const;
};

}  // namespace analyzer

#endif
