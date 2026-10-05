#include "analyzer/AnalysisContext.h"
#include "analyzer/Config.h"
#include "analyzer/Diagnostic.h"
#include "analyzer/GpuAnalyzer.h"
#include "analyzer/IRLoader.h"
#include "analyzer/LLVMAnalyses.h"
#include "analyzer/LoopCatalog.h"
#include "analyzer/MemoryAccessAnalyzer.h"
#include "analyzer/ReportFormatter.h"
#include "analyzer/VectorizationAnalyzer.h"
#include "analyzer/VectorizerOracle.h"

#include "cli/CommandLine.h"

#include <llvm/Config/llvm-config.h>
#include <llvm/IR/PassManager.h>
#include <llvm/Transforms/Utils/LoopSimplify.h>

#include <iostream>
#include <memory>
#include <regex>

namespace {

analyzer::Diagnostic functionNote(const llvm::Function& F, std::string message,
                                  std::string suggestion) {
  analyzer::Diagnostic d;
  d.severity = analyzer::DiagnosticSeverity::Warning;
  d.category = analyzer::DiagnosticCategory::General;
  d.functionName = F.getName().str();
  d.message = std::move(message);
  if (!suggestion.empty())
    d.suggestions.push_back(std::move(suggestion));
  return d;
}

analyzer::Diagnostic moduleWarning(std::string message,
                                   std::vector<std::string> evidence,
                                   std::string suggestion) {
  analyzer::Diagnostic d;
  d.severity = analyzer::DiagnosticSeverity::Warning;
  d.category = analyzer::DiagnosticCategory::General;
  d.functionName = "(module)";
  d.message = std::move(message);
  d.evidence = std::move(evidence);
  if (!suggestion.empty())
    d.suggestions.push_back(std::move(suggestion));
  return d;
}

/// "clang version 17.0.0 ..." -> 17, or 0 if the IR doesn't say.
unsigned producerMajorVersion(const llvm::Module& M, std::string* ident) {
  const llvm::NamedMDNode* N = M.getNamedMetadata("llvm.ident");
  if (!N || N->getNumOperands() == 0)
    return 0;
  const auto* S =
      llvm::dyn_cast<llvm::MDString>(N->getOperand(0)->getOperand(0));
  if (!S)
    return 0;
  *ident = S->getString().str();
  std::smatch m;
  static const std::regex version("clang version ([0-9]+)");
  if (std::regex_search(*ident, m, version))
    return std::stoul(m[1]);
  return 0;
}

}  // namespace

int main(int argc, char** argv) {
  analyzer::Config config;
  std::string inputPath;
  if (!analyzer::cli::parseCommandLine(argc, argv, config, inputPath))
    return 1;
  if (inputPath.empty()) {
    analyzer::cli::printUsage(argv[0]);
    return 0;
  }

  analyzer::IRLoader loader;
  std::unique_ptr<llvm::Module> module = loader.loadFromFile(inputPath);
  if (!module) {
    std::cerr << "Error: " << loader.getLastError() << '\n'
              << "note: this analyzer reads LLVM " << LLVM_VERSION_MAJOR
              << " IR; newer clang versions write IR it can't parse. "
                 "Generate it with clang "
              << LLVM_VERSION_MAJOR << " (scripts/generate_ir.sh does).\n";
    return 1;
  }

  analyzer::AnalysisContext ctx(config);

  // Verdicts are LLVM 15's; IR from another clang may have been optimized
  // differently.
  std::string ident;
  unsigned producer = producerMajorVersion(*module, &ident);
  if (producer && producer != LLVM_VERSION_MAJOR)
    ctx.getEmitter().add(moduleWarning(
        "IR was produced by a different compiler version than the LLVM " +
            std::to_string(LLVM_VERSION_MAJOR) + " this tool asks",
        {"llvm.ident: " + ident},
        "Generate the IR with clang " + std::to_string(LLVM_VERSION_MAJOR) +
            " so the verdicts describe the compiler that built it."));

  if (module->debug_compile_units().empty())
    ctx.getEmitter().add(moduleWarning(
        "No debug info: loops are named by IR block, and copies of a loop are "
        "matched only by the vectorizer's CFG layout",
        {"copies made by runtime unrolling are reported as separate loops, "
         "and their iteration counts describe the copy, not the source loop"},
        "Recompile with -gline-tables-only."));

  std::unique_ptr<analyzer::CompileRemarks> compileRemarks;
  if (!config.remarksPath.empty()) {
    std::string error;
    compileRemarks = analyzer::CompileRemarks::load(config.remarksPath, error);
    if (!compileRemarks) {
      std::cerr << "Error: " << error << '\n';
      return 1;
    }
    if (compileRemarks->size() == 0)
      std::cerr << "warning: " << config.remarksPath
                << " has no loop-vectorize remarks\n";
  }

  // Cost decisions depend on the hardware, so analyze for the target the IR
  // was compiled for.
  std::string targetError;
  std::unique_ptr<llvm::TargetMachine> TM =
      analyzer::createTargetMachineFor(*module, targetError);
  // GPU device code: parallelism is in the thread grid, so the questions
  // are coalescing, bank conflicts and divergence, not loop vectorization.
  const bool gpu = analyzer::isGpuModule(*module);
  if (!TM)
    std::cerr << "warning: " << targetError
              << (gpu ? "; divergence is judged without LLVM's "
                        "DivergenceAnalysis\n"
                      : "; vectorization verdicts for non-vectorized loops "
                        "are unavailable\n");

  // Put every loop in the canonical form LLVM's loop analyses require
  // (dedicated preheader and exits). Unroll remainders often lack it. This
  // adds empty blocks only; LoopVectorize does the same before it looks at
  // a loop.
  {
    analyzer::AnalysisStack canonical(TM.get());
    llvm::FunctionPassManager FPM;
    FPM.addPass(llvm::LoopSimplifyPass());
    for (llvm::Function& F : *module)
      if (!F.isDeclaration() && !F.hasOptNone())
        FPM.run(F, canonical.fam());
  }

  analyzer::AnalysisStack stack(TM.get());
  std::vector<std::unique_ptr<analyzer::FunctionAnalyses>> analyses;
  std::vector<std::unique_ptr<analyzer::LoopCatalog>> catalogs;
  analyzer::VectorizerOracle::Work work;

  for (llvm::Function& F : *module) {
    if (F.isDeclaration())
      continue;
    if (!config.functionFilter.empty() &&
        F.getName() != config.functionFilter &&
        (!gpu || analyzer::kernelDisplayName(F) != config.functionFilter))
      continue;
    if (gpu && !analyzer::isGpuKernel(F))
      continue;  // Device functions are analyzed where they're inlined.
    auto FA = std::make_unique<analyzer::FunctionAnalyses>(F, stack);
    if (!gpu && FA->loopInfo().empty())
      continue;  // Nothing loop-related to say.
    if (F.hasOptNone()) {
      // -O0 IR keeps every variable in stack memory; any memory or
      // vectorization finding would describe code that never ships.
      ctx.getEmitter().add(functionNote(
          F,
          "Compiled at -O0 (optnone): skipped, results would describe "
          "unoptimized code",
          "Regenerate the IR with -O2 (or the flags you ship with)."));
      continue;
    }
    catalogs.push_back(
        std::make_unique<analyzer::LoopCatalog>(FA->loopInfo(), FA->scev()));
    if (!gpu)
      work.push_back({&F, catalogs.back().get()});
    analyses.push_back(std::move(FA));
  }

  std::unique_ptr<analyzer::VectorizerOracle> oracle;
  if (TM && !gpu)
    oracle =
        std::make_unique<analyzer::VectorizerOracle>(*module, TM.get(), work);

  analyzer::MemoryAccessAnalyzer memoryAnalyzer;
  analyzer::VectorizationAnalyzer vectorizationAnalyzer;
  analyzer::GpuAnalyzer gpuAnalyzer;
  for (size_t i = 0; i < analyses.size(); ++i) {
    if (gpu) {
      gpuAnalyzer.run(*analyses[i], catalogs[i].get(), TM != nullptr, ctx);
      continue;
    }
    vectorizationAnalyzer.run(*analyses[i], *catalogs[i], oracle.get(),
                              compileRemarks.get(), ctx);
    memoryAnalyzer.run(*analyses[i], *catalogs[i], ctx);
  }

  analyzer::ReportFormatter formatter;
  std::vector<analyzer::Diagnostic> diagnostics =
      ctx.getEmitter().getDiagnosticsForReport();
  if (config.jsonOutput)
    formatter.formatJSON(std::cout, diagnostics);
  else
    formatter.formatTerminal(std::cout, diagnostics, config.verbose);
  return 0;
}
