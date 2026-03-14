#include "cli/CommandLine.h"

#include <cstring>
#include <iostream>

namespace analyzer {
namespace cli {

bool parseCommandLine(int argc, char** argv, Config& config,
                      std::string& inputPath) {
  inputPath.clear();
  for (int i = 1; i < argc; ++i) {
    const char* arg = argv[i];
    if (strcmp(arg, "--help") == 0 || strcmp(arg, "-h") == 0) {
      printUsage(argv[0]);
      return true;  // caller should exit 0
    }
    if (strcmp(arg, "--all") == 0) {
      config.analyzeAllFunctions = true;
      continue;
    }
    if (strcmp(arg, "--verbose") == 0 || strcmp(arg, "-v") == 0) {
      config.verbose = true;
      continue;
    }
    if (strcmp(arg, "--json") == 0) {
      config.jsonOutput = true;
      continue;
    }
    if (strcmp(arg, "--function") == 0 || strcmp(arg, "-f") == 0) {
      if (i + 1 >= argc) {
        std::cerr << "Error: --function requires an argument\n";
        return false;
      }
      config.functionFilter = argv[++i];
      continue;
    }
    if (arg[0] != '-') {
      inputPath = arg;
      continue;
    }
    std::cerr << "Unknown option: " << arg << '\n';
    return false;
  }
  return true;
}

void printUsage(const char* programName) {
  std::cout
      << "Usage: " << programName << " [options] <input.ll|input.bc>\n"
      << "\n"
      << "Analyze LLVM IR or bitcode for kernel optimization opportunities.\n"
      << "\n"
      << "Options:\n"
      << "  -h, --help          Show this help\n"
      << "  --all                Analyze all functions (default: kernel-like "
         "only)\n"
      << "  -f, --function NAME  Analyze only the given function\n"
      << "  -v, --verbose        Verbose diagnostics\n"
      << "  --json               Emit JSON report\n"
      << "\n"
      << "Example:\n"
      << "  " << programName << " kernel.ll\n"
      << "  " << programName << " --json --verbose kernel.bc\n";
}

}  // namespace cli
}  // namespace analyzer
