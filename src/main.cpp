#include "analyzer/AnalysisContext.h"
#include "analyzer/Config.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/IRLoader.h"
#include "analyzer/InstructionMixAnalyzer.h"
#include "analyzer/KernelClassifier.h"
#include "analyzer/LoopAnalyzer.h"
#include "analyzer/MemoryAccessAnalyzer.h"
#include "analyzer/RedundantLoadAnalyzer.h"
#include "analyzer/ReportFormatter.h"
#include "analyzer/VectorizationAnalyzer.h"

#include "cli/CommandLine.h"

#include <iostream>
#include <memory>

int main(int argc, char** argv) {
  analyzer::Config config;
  std::string inputPath;
  if (!analyzer::cli::parseCommandLine(argc, argv, config, inputPath)) {
    return 1;
  }

  if (inputPath.empty()) {
    analyzer::cli::printUsage(argv[0]);
    return 0;
  }

  analyzer::IRLoader loader;
  auto module = loader.loadFromFile(inputPath);
  if (!module) {
    std::cerr << "Error: " << loader.getLastError() << '\n';
    return 1;
  }

  analyzer::AnalysisContext ctx(std::move(module));
  ctx.getConfig() = config;
  ctx.buildFunctionInventory();

  analyzer::KernelClassifier classifier;
  analyzer::LoopAnalyzer loopAnalyzer;
  analyzer::MemoryAccessAnalyzer memoryAnalyzer;
  analyzer::InstructionMixAnalyzer mixAnalyzer;
  analyzer::VectorizationAnalyzer vecAnalyzer;
  analyzer::RedundantLoadAnalyzer redundantLoadAnalyzer;
  analyzer::ReportFormatter formatter;

  for (auto& F : ctx.getModule()->functions()) {
    if (F.isDeclaration())
      continue;
    if (!config.analyzeAllFunctions && !classifier.isKernelLike(F))
      continue;
    if (!config.functionFilter.empty() && F.getName() != config.functionFilter)
      continue;

    loopAnalyzer.run(F, ctx);
    mixAnalyzer.run(F, ctx);
    memoryAnalyzer.run(F, ctx);
    vecAnalyzer.run(F, ctx);
    redundantLoadAnalyzer.run(F, ctx);
  }

  std::vector<analyzer::Diagnostic> diagnostics =
      ctx.getEmitter().getDiagnosticsForReport(config.verbose);
  if (config.jsonOutput)
    formatter.formatJSON(std::cout, diagnostics);
  else
    formatter.formatTerminal(std::cout, diagnostics, config.verbose);

  return 0;
}
