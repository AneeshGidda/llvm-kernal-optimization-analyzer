#ifndef ANALYZER_CLI_COMMAND_LINE_H
#define ANALYZER_CLI_COMMAND_LINE_H

#include "analyzer/Config.h"

#include <string>

namespace analyzer {
namespace cli {

/// Parse argc/argv into config and input path. Returns false on error or
/// --help.
bool parseCommandLine(int argc, char** argv, Config& config,
                      std::string& inputPath);

void printUsage(const char* programName);

}  // namespace cli
}  // namespace analyzer

#endif
