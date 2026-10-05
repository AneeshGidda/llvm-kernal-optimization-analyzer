# LLVM Loop Optimization Analyzer

A command-line tool that explains **why LLVM didn't vectorize or optimize a
loop**, in terms of your source code, and suggests a fix that it has checked
against LLVM itself.

It also reads **CUDA and HIP device code**, where the questions are different:
uncoalesced memory accesses, shared-memory bank conflicts, warp divergence,
and barriers that not every thread reaches ([GPU kernels](#gpu-kernels-cuda-and-hip)).

Built in C++17 on LLVM 15's analysis libraries (ScalarEvolution,
LoopAccessAnalysis, DependenceAnalysis, DivergenceAnalysis, alias analysis,
LoopVectorize).

## The problem

Performance-critical C/C++ kernels (numerics, ML ops, image processing) rely
on the compiler turning loops into SIMD code. When it doesn't, the compiler's
own explanation is usually one line:

```
$ clang -O2 -Rpass-analysis=loop-vectorize reduction.c
reduction.c:4:3: remark: the cost-model indicates that vectorization is not beneficial
```

That doesn't say which variable is the problem, whether it can be fixed, or
how. This tool answers those questions:

```
$ analyzer --remarks reduction.opt.yaml reduction.ll

loop at reduction.c:4 (depth 1, innermost)
  [Warning] [Vectorization] Not vectorized: float sum `s` (reduction.c:5) must be added in source order
      clang reported during compilation: "the cost-model indicates that vectorization is not beneficial"
      LLVM processed this loop but chose vector width 1 (it only unrolled it, no SIMD)
      checked: with reassociation allowed, LLVM's vectorizer vectorizes this loop (vectorization width: 4, interleaved count: 2)
    Fix:
      - Allow reordering for just this loop: put `#pragma clang fp reassociate(on)` at the top of the
        loop body. The result can differ in the last bits, because additions happen in a different order.
```

(Output abridged; [`test/fixtures/src/reduction.c`](test/fixtures/src/reduction.c)
reproduces it.) The fix wasn't guessed: the tool applied it to a copy of the program, reran
LLVM's vectorizer, and confirmed that the loop then vectorizes.

## What it does

- **Explains missed vectorization:** names the responsible variable, pointer,
  call or memory access, and quotes LLVM's own reason.
- **Checks fixes before suggesting them:** suggestions like `restrict` or
  allowing float reassociation are applied to a copy of the IR and the LLVM
  analysis is rerun. A fix is labeled `Checked:` if it works; if it doesn't,
  the tool says so instead of suggesting it.
- **Finds poor memory access patterns:** strided and column-wise walks, with
  exact per-loop strides, and whether swapping two loops would fix them.
- **Proves loop swaps safe, or shows they're illegal:** uses LLVM's
  DependenceAnalysis, so it never recommends a swap that would change results.
- **Explains values stuck in memory:** loads and stores that stay inside a
  loop because something might alias them, and what that something is.
- **Says when it can't be sure:** when the evidence is indirect, it lists
  "possible contributors" instead of naming a cause, and it labels results
  that come from a rerun rather than from the real compile.

Typical findings:

| Situation | What the tool reports |
|---|---|
| Float sum not vectorized | The accumulator and the pragma that fixes it (checked) |
| Pointers that might overlap | Which parameters, and whether `restrict` would actually help (checked) |
| Vectorized only behind run-time checks | The overlap check or stride condition (`only runs when incx == 1`) guarding the fast path |
| Column-wise matrix walk | The stride, the loop swap that makes it sequential, and whether that swap is legal |
| Calls in the loop | Opaque function, math call blocked by `errno`, or a C library call with no vector version |
| Loop-carried dependence | Whether it's a running total, a linear recurrence or an argmax, each with different advice |
| Code that is already SIMD | Recognized (intrinsics, SLP, unrolled vector loops) and not reported as a missed optimization |

## How it works

```
kernel.c ──clang -O2──► kernel.ll (optimized IR) + kernel.opt.yaml (clang's remarks)
                              │
                              ▼
          1. Group loop copies   vector body, remainder and unrolled copies → one source loop
          2. Get the verdict     clang's recorded decision, or a rerun of LoopVectorize
          3. Explain it          LLVM analyses pinpoint the variable/pointer/call
          4. Check each fix      apply it to a cloned module, rerun the analysis
                              │
                              ▼
                 report (terminal or JSON)
```

The tool reads **optimized IR**, the code that actually ships. At `-O2` every
optimization LLVM could safely make has already happened, so whatever is left
is worth explaining. (`-O0` IR is refused: it keeps every variable in memory
and would produce misleading findings.)

| Question | Answered by |
|---|---|
| Was this loop vectorized? | Vector types and `llvm.loop.isvectorized` metadata in the IR |
| If not, why? | clang's optimization record from the same compile (`--remarks`); otherwise LLVM's own LoopVectorize pass is rerun on a private copy of the module |
| Which variable, pointer or call is responsible? | IVDescriptors (reductions, recurrences), LoopAccessAnalysis (dependences, run-time checks), TargetLibraryInfo (library calls, errno), TargetTransformInfo (target costs, gather support) |
| Would the fix work? | Rerun with the fix applied: `restrict` becomes `noalias`, the reassociate pragma becomes `reassoc` flags |
| How does each access move through memory? | ScalarEvolution: the exact stride at every loop level |
| Is swapping two loops safe? | DependenceAnalysis direction vectors, normalized the way LLVM's LoopInterchange does |
| Why is a value reloaded every iteration? | Alias analysis: what in the loop might touch the same address |

Every finding names the analysis behind it (`-v` prints it as `Basis:`).

**Matching loops back to the source.** Optimized IR contains several copies
of each source loop: the vector body, a scalar remainder, unrolled copies, and
separate copies for each place a function was inlined. The tool regroups them
by debug location (including the inlining chain) and by the CFG layout LLVM's
vectorizer and unroller produce. This works on x86-64 and AArch64 output.

## GPU kernels (CUDA and HIP)

GPU code is still LLVM IR, but for an `nvptx64` or `amdgcn` target, and it
runs differently: there is usually no loop to vectorize. Each thread runs
the kernel body once, and groups of 32 threads (a *warp*; 64-thread
*wavefronts* on AMD CDNA) execute each instruction together. What makes a
kernel slow is how those threads interact:

| Question | Answered by |
|---|---|
| Do neighbouring threads access neighbouring addresses (coalescing)? | ScalarEvolution: the address is evaluated with `threadIdx.x` set to each lane of a warp, then counted in memory segments (32 B on NVIDIA, 64 B on AMD) |
| Do threads hit the same shared-memory bank? | The same per-lane offsets, against 32 banks of 4 bytes |
| Do threads of a warp take different branches? | LLVM's DivergenceAnalysis for the IR's target finds candidates; the per-lane evaluation drops bounds checks like `i < n`, which split at most one warp, and names the cause (`tid % 2`, data each thread loads) |
| Does every thread reach `__syncthreads()`? | Dominator and post-dominator trees: a barrier that only runs on one side of a divergent branch is reported as an error |

The CPU analyzers don't run on GPU IR. Example, a tiled transpose
([`test/fixtures/src/gpu_transpose.cu`](test/fixtures/src/gpu_transpose.cu)):

```
=== transpose_tiled ===
  [Warning] [Shared memory] 32-way bank conflict on tile: each access by a warp is split into 32 serialized steps
      load of tile (gpu_transpose.cu:22): neighbouring threads are 128 bytes apart
      shared memory has 32 banks of 4 bytes, so addresses 128 bytes apart are in the same bank; 32 threads hit different words of one bank
    Fix:
      - Pad each row by one element: declare tile[32][33] instead of [32][32]. Computed: then no bank conflict.
```

Generate device IR (no host code) with clang 15:

```bash
./scripts/generate_ir.sh kernel.cu kernel.ll -x cuda --cuda-device-only --cuda-gpu-arch=sm_80
./scripts/generate_ir.sh kernel.hip kernel.ll -x hip --cuda-device-only --offload-arch=gfx90a
./build/analyzer kernel.ll
```

Without a CUDA or ROCm install, add `-nocudainc -nocudalib` (CUDA) or
`-nogpuinc -nogpulib` (HIP); kernels that only need `threadIdx` and friends
can include [`test/fixtures/src/cuda_shim.h`](test/fixtures/src/cuda_shim.h)
instead of the CUDA headers, as the fixtures do.

| Kernel | Finding |
|---|---|
| `gpu_strided.cu` | array of structs (33.3% of traffic used, structure of arrays fixes it); one row per thread (stride `n`); stride 2 (50%) |
| `gpu_matmul.cu` | `threadIdx.x` on the column: coalesced, `A` broadcast; on the row: `A` and `C` uncoalesced |
| `gpu_transpose.cu` | naive transpose's strided store; 32-way bank conflict in the tiled version; padded version clean |
| `gpu_divergence.cu` | interleaved reduction (16, 8, 4, 2 of 32 threads active); CSR SpMV: per-row loop length and per-thread ranges; a branch `-O2` already turned into a select is *not* reported |
| `gpu_barrier.cu` | `__syncthreads()` inside `if (i < n)` |
| `hip_strided.hip` | the same column walk on a 64-thread wavefront |

## Quick start

**Requirements:** LLVM 15 with development headers, CMake 3.20+, and a C++17
compiler.

```bash
# macOS:  brew install llvm@15
# Ubuntu: sudo apt-get install llvm-15-dev clang-15

cmake -S . -B build -DLLVM_DIR=$(llvm-config --cmakedir)
cmake --build build
ctest --test-dir build
```

Analyze your own code:

```bash
./scripts/generate_ir.sh kernel.c kernel.ll
./build/analyzer --remarks kernel.opt.yaml kernel.ll
```

`generate_ir.sh` compiles with clang 15 at `-O2`, using the flags the tool
needs:
- `-gline-tables-only` for source locations;
- `-fno-discard-value-names` to keep variable names;
- `-fsave-optimization-record` for clang's own decisions, saved as
  `kernel.opt.yaml`.

Pass any extra flags (target, `-march`, `-ffast-math`, ...) after the output
name.

### Options

| Option | Description |
|---|---|
| `--remarks FILE` | clang's optimization record from the same compile; gives the vectorizer's real decisions instead of a rerun (recommended) |
| `-f`, `--function NAME` | Analyze only this function |
| `-v`, `--verbose` | Also show per-loop access patterns and the analysis behind each finding |
| `--json` | Machine-readable output, e.g. for CI or editor integration |

## Testing

`ctest` runs 66 tests over small C, CUDA and HIP kernels in `test/fixtures/src/`. Each kernel
contains one known problem. Each test asserts the specific finding **and
rejects known false positives**, such as recommending an illegal loop swap or
suggesting `restrict` where it can't help.

- C fixtures are compiled for **AArch64 (Apple M1)**, **x86-64 Linux** and
  **without debug info**, because unrolling decisions and libm defaults
  differ between targets. GPU fixtures are compiled for **NVIDIA sm_70** and
  **AMD gfx90a**.
- The checked-in IR is regenerated with `scripts/regenerate_fixtures.sh`.
- `scripts/crosscheck_remarks.sh` prints clang's own remarks next to the
  tool's verdicts for every fixture.

## Limitations

- **LLVM 15 only.** The tool reads LLVM 15 IR and reports LLVM 15's
  decisions. IR from another clang version is flagged, and newer IR may not
  parse.
- **Use `--remarks` for exact verdicts.** Without it, the vectorizer is rerun
  on already-optimized IR. That usually agrees with the original compile, but
  can differ, and the report says when it's a rerun.
- **Build flags aren't in the IR.** Flags like `-fveclib` and
  `-fno-math-errno` aren't recorded, so advice about them is conditional.
- **Debug info matters.** Without it, loops are named by IR block, and
  copies made by runtime unrolling are reported separately.
- **No hot-spot ranking.** Static IR can't tell which loops matter most; use
  a profiler to choose which ones to look at.
- **GPU launch configuration isn't in the IR.** The GPU findings assume
  `blockDim.x` is a multiple of the warp size (so a warp is 32 consecutive
  `threadIdx.x` values) and that arrays start at a segment boundary. Warp
  size, segment size and bank layout are the vendors' documented values.
  Occupancy and register pressure are decided after LLVM IR (by `ptxas` or
  the AMDGPU backend) and aren't analyzed.

## Project layout

```
src/core/          LLVM pass setup, loop-copy grouping (LoopCatalog),
                   vectorizer rerun and what-if checks (VectorizerOracle),
                   clang remark loading, source naming
src/analyzers/     VectorizationAnalyzer, MemoryAccessAnalyzer (CPU);
                   GpuAnalyzer (CUDA/HIP device code)
src/diagnostics/   Report ordering and terminal/JSON output
test/fixtures/     C, CUDA and HIP kernels and their compiled IR
scripts/           IR generation, fixture regeneration, remark cross-check
```
