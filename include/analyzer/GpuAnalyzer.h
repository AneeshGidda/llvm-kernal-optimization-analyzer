#ifndef ANALYZER_GPU_ANALYZER_H
#define ANALYZER_GPU_ANALYZER_H

#include <string>

namespace llvm {
class Function;
class Module;
}  // namespace llvm

namespace analyzer {

class AnalysisContext;
class FunctionAnalyses;
class LoopCatalog;

/// Whether the module is GPU device code (NVPTX or AMDGPU). Its parallelism
/// is in the thread grid, not in loops, so the CPU analyzers don't apply.
bool isGpuModule(const llvm::Module& M);

/// Whether F is a kernel entry point: PTX/AMDGPU kernel calling convention,
/// or listed as a kernel in !nvvm.annotations (what clang 15 emits for
/// CUDA).
bool isGpuKernel(const llvm::Function& F);

/// Demangled name without parameters: "transpose_tiled" for
/// _Z15transpose_tiledPKfPfi.
std::string kernelDisplayName(const llvm::Function& F);

/// Reports, per GPU kernel:
///  - global loads/stores whose threads in one warp don't access neighbouring
///    addresses (uncoalesced), with the fraction of memory traffic used;
///  - shared-memory accesses with bank conflicts;
///  - branches and loop exits where threads of one warp disagree
///    (divergence), ignoring bounds checks that split only one warp;
///  - barriers that only some threads reach.
///
/// How an address or condition changes from thread to thread comes from
/// ScalarEvolution: the expression is evaluated with threadIdx.x set to each
/// lane of a warp. Divergence candidates come from LLVM's DivergenceAnalysis
/// for the IR's target. Hardware parameters (warp size, segment size, 32
/// banks of 4 bytes) are the vendors' documented values; the tool assumes
/// blockDim.x is a multiple of the warp size, so a warp is consecutive
/// threadIdx.x values.
class GpuAnalyzer {
public:
  /// `catalog` may be null when the kernel has no loops. Without a target
  /// (`haveTarget` false), DivergenceAnalysis can't identify divergence
  /// sources and branches are judged by the lane evaluation alone.
  void run(FunctionAnalyses& FA, const LoopCatalog* catalog, bool haveTarget,
           AnalysisContext& ctx);
};

}  // namespace analyzer

#endif
