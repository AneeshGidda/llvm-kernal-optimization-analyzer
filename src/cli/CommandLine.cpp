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
    if (strcmp(arg, "--remarks") == 0) {
      if (i + 1 >= argc) {
        std::cerr << "Error: --remarks requires a file\n";
        return false;
      }
      config.remarksPath = argv[++i];
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
      << "Explains which loops LLVM failed to optimize, why, and what source\n"
      << "change fixes it. Input should be optimized IR from clang 15, e.g.:\n"
      << "  clang -O2 -gline-tables-only -fno-discard-value-names \\\n"
      << "        -fsave-optimization-record \\\n"
      << "        -foptimization-record-file=kernel.opt.yaml \\\n"
      << "        -S -emit-llvm kernel.c -o kernel.ll\n"
      << "\n"
      << "CUDA/HIP device IR (nvptx64, amdgcn) is analyzed for coalescing,\n"
      << "shared-memory bank conflicts, divergence and barriers instead:\n"
      << "  clang -x cuda --cuda-device-only --cuda-gpu-arch=sm_80 -O2 ...\n"
      << "\n"
      << "Options:\n"
      << "  -h, --help           Show this help\n"
      << "  -f, --function NAME  Analyze only the given function\n"
      << "  -v, --verbose        Also show access-pattern notes and the LLVM\n"
      << "                       analysis behind each finding\n"
      << "  --remarks FILE       clang's optimization record (.opt.yaml) from\n"
      << "                       the same compile: explain each loop with the\n"
      << "                       vectorizer's real decision instead of a rerun\n"
      << "  --json               Emit JSON report\n";
}

}  // namespace cli
}  // namespace analyzer
