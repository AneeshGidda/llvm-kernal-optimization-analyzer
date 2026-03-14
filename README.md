# LLVM Kernel Optimization Analyzer

A practical LLVM-based analysis tool that inspects compiled AI and HPC kernels, detects optimization opportunities, and produces actionable diagnostics around **vectorization**, **memory access behavior**, **instruction mix**, **loop structure**, and compiler-driven performance bottlenecks.

## What it does

- **Load** LLVM IR (`.ll`) and bitcode (`.bc`) from C++, CUDA-host, or SYCL-compatible compilation flows
- **Identify** likely kernel-like functions using heuristics (loops, instruction count, naming, memory density)
- **Analyze** loops, instruction mix, memory access patterns, vectorization blockers, and redundant loads
- **Report** structured diagnostics with severity, evidence, and actionable suggestions
- **Output** human-readable terminal reports and machine-readable JSON for tooling

## Who it's for

- Performance-oriented C++ and kernel developers  
- CUDA / GPU / ML systems engineers  
- Compiler and runtime engineers  
- Anyone learning LLVM optimization behavior  

## Quick start

### Prerequisites

- **LLVM** (17+ recommended), with development headers and libraries  
- **CMake** 3.20+  
- **C++17**-capable compiler (Clang or GCC)

### Build

```bash
mkdir build && cd build
cmake ..
cmake --build .
```

Run the analyzer (placeholder for now):

```bash
./analyzer --help
```

### Using a custom LLVM install

```bash
cmake -DLLVM_DIR=/path/to/llvm/lib/cmake/llvm ..
cmake --build .
```

## Repository layout

- `include/analyzer/` — Public API headers  
- `src/` — Implementation (CLI, core, analyzers, diagnostics)  
- `test/` — Unit and integration tests  
- `examples/kernels/` — Sample kernels  
- `scripts/` — Build, format, lint, test, and IR generation helpers  

---

*A practical compiler-analysis tool for developers who want to understand why performance-critical kernels are slow and what compiler-visible optimizations are most likely to help.*
