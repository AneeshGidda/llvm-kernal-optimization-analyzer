cmake_minimum_required(VERSION 3.20)

enable_testing()

set(FIXTURE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/ir")

# --- CLI basics -------------------------------------------------------------
add_test(NAME cli_help COMMAND $<TARGET_FILE:analyzer> --help)
add_test(NAME cli_missing_file COMMAND $<TARGET_FILE:analyzer> /nonexistent.ll)
set_tests_properties(cli_missing_file PROPERTIES WILL_FAIL true)
add_test(NAME cli_json COMMAND $<TARGET_FILE:analyzer> --json
         "${FIXTURE_DIR}/saxpy.ll")
set_tests_properties(cli_json PROPERTIES
  PASS_REGULAR_EXPRESSION "\"diagnostics\":\\[\\{\"severity\"")

# --- Fixture expectations ---------------------------------------------------
# Patterns are CMake regexes, where `.` also matches newlines: use [^\n]* to
# stay on one line.
# Each fixture is a small C kernel (fixtures/src) with one known problem,
# compiled at -O2 (scripts/regenerate_fixtures.sh). Tests check the specific
# finding AND that known false positives don't come back. The expected
# vectorizer verdicts match `clang -O2 -Rpass-analysis=loop-vectorize` on the
# same sources (scripts/crosscheck_remarks.sh).
function(analyzer_case name fixture)
  cmake_parse_arguments(C "" "FUNCTION;REMARKS" "EXPECT;REJECT" ${ARGN})
  if(C_REMARKS)
    set(C_REMARKS ${FIXTURE_DIR}/${C_REMARKS})
  endif()
  add_test(NAME ${name}
    COMMAND ${CMAKE_COMMAND}
      -DANALYZER=$<TARGET_FILE:analyzer>
      -DINPUT=${FIXTURE_DIR}/${fixture}.ll
      -DFUNCTION=${C_FUNCTION}
      -DREMARKS=${C_REMARKS}
      "-DEXPECT=${C_EXPECT}"
      "-DREJECT=${C_REJECT}"
      -P ${CMAKE_CURRENT_SOURCE_DIR}/check_output.cmake)
endfunction()

analyzer_case(matmul matmul
  EXPECT "Not vectorized: LLVM's cost model predicted no speedup"
         "possible contributors, not ranked"
         "load of B \\(matmul.c:9\\): stride n elements"
         # The float sum is not the cause: allowing reordering was checked.
         "checked: allowing reassociation alone doesn't make LLVM vectorize"
         "swapping this loop with loop at matmul.c:6 makes it sequential"
         "could not prove the swap safe"
         "restrict[^\n]* to A, B, C [^\n]*Checked: with them, DependenceAnalysis proves the swap safe"
  # The old analyzer called llvm.fmuladd a blocking call, and blamed (and
  # "fixed") the float sum.
  REJECT "call" "Vectorized \\(width" "Not vectorized: float sum"
         "fp reassociate")

analyzer_case(reduction_f32 reduction FUNCTION sum_f32
  EXPECT "float sum `s` \\(reduction.c:5\\) must be added in source order"
         "only unrolled it, no SIMD"
         "checked: with reassociation allowed, LLVM's vectorizer vectorizes this loop"
         "fp reassociate\\(on\\)"
  REJECT "Vectorized \\(width")
analyzer_case(reduction_i32 reduction FUNCTION sum_i32
  EXPECT "Vectorized \\(width 4\\)"
  REJECT "Warning\\]")

analyzer_case(saxpy_runtime_check saxpy FUNCTION saxpy
  EXPECT "Vectorized \\(width 4\\), but only behind a run-time check that x, y don't overlap")
analyzer_case(saxpy_restrict saxpy FUNCTION saxpy_restrict
  EXPECT "Vectorized \\(width 4\\)"
  REJECT "run-time check" "Warning\\]")

analyzer_case(recurrence recurrence
  EXPECT "each iteration needs the previous iteration's result"
         "intermediate value is stored to a")

analyzer_case(accumulate_in_memory accumulate FUNCTION accumulate
  EXPECT "out is written to memory every iteration"
         "load of a \\(accumulate.c:5\\) might access out's memory"
         "restrict[^\n]* to a, out [^\n]*Checked: alias analysis then rules out every conflict"
         "If nothing else in the loop touches out's memory")
analyzer_case(scale_by_ptr accumulate FUNCTION scale_by_ptr
  EXPECT "run-time check that scale, y don't overlap")

analyzer_case(scalarized_math calls FUNCTION apply_sin
  EXPECT "math calls are still done one element at a time" "-fveclib")
analyzer_case(opaque_call calls FUNCTION apply_transform
  EXPECT "the call to transform has no vector version"
         "only declared here" "declare simd")

analyzer_case(gather gather
  EXPECT "overlap can't be checked at run time"
         "load of x \\(gather.c:4\\): address depends on data loaded in the loop"
         "no vector gather instruction"
         # restrict is only suggested together with what the rerun showed.
         "restrict")

analyzer_case(early_exit search
  EXPECT "can stop early" "exit test at search.c:4 depends on data")

analyzer_case(column_walk column_walk
  EXPECT "swapping this loop with loop at column_walk.c:4 makes it sequential"
         "no memory dependence is reversed by the swap")

analyzer_case(refuses_O0 unoptimized
  EXPECT "Compiled at -O0"
  REJECT "Vectorization\\]" "Memory\\]")

# --- Regressions from review: each source in fixtures/src documents the case.

# Loop swap that reverses a dependence: must not be advised.
analyzer_case(interchange_illegal interchange_illegal
  EXPECT "swapping would reverse a dependence, changing the results"
         "dependence direction \\(>,<\\) would run backwards"
         "Don't swap these loops"
  REJECT "Reorder the loops" "no memory dependence is reversed")

# A helper inlined twice: two loops, two verdicts.
analyzer_case(inlined_copies inlined
  EXPECT "loop at inlined.c:6 \\(inlined at inlined.c:12:3\\)[^\n]*\n  \\[Note\\] \\[Vectorization\\] Vectorized \\(width 4\\)"
         "loop at inlined.c:6 \\(inlined at inlined.c:13:3\\)[^\n]*\n  \\[Warning\\] \\[Vectorization\\] Not vectorized: the call to transform")

# Code that is already SIMD is not a missed vectorization.
analyzer_case(simd_intrinsics simd FUNCTION add_neon
  EXPECT "Already uses SIMD \\(4-wide vector code\\), but not from LLVM's loop vectorizer"
  REJECT "Not vectorized" "Warning\\]")
analyzer_case(simd_slp_after_interleave simd FUNCTION scale_disabled
  EXPECT "Already uses SIMD \\(2-wide" "only interleaved this loop"
  REJECT "Vectorized \\(width" "Not vectorized")
analyzer_case(simd_unrolled_inner simd FUNCTION rows
  EXPECT "Already uses SIMD \\(4-wide" "vector operations at simd.c:22"
  REJECT "Not vectorized")

# restrict only where it can help.
analyzer_case(self_dependence overlap FUNCTION self_dep
  EXPECT "accesses to a may overlap each other"
         "same array, so `restrict` can't help"
  REJECT "Add `restrict`")
analyzer_case(histogram overlap FUNCTION histogram
  EXPECT "h is updated at data-dependent positions"
         "checked: marking h, idx `restrict` alone doesn't make LLVM vectorize"
  REJECT "Add `restrict`")
analyzer_case(same_array_runtime_check overlap FUNCTION stencil_rows
  EXPECT "run-time check that A don't overlap"
         "same array, so `restrict` can't remove it"
  REJECT "Add `restrict`")

# Library calls: no -fveclib advice for non-math functions.
analyzer_case(non_math_libcall libcalls FUNCTION release_all
  EXPECT "the call to free has no vector version"
         "C library function with no vector version"
  REJECT "veclib" "math")

# Conditional fixed-address accesses aren't blamed on aliasing.
analyzer_case(conditional_store conditional FUNCTION last_positive
  REJECT "written to memory every iteration" "local variable")
analyzer_case(conditional_load conditional FUNCTION add_bias
  REJECT "Load of bias repeats" "local variable")
# A written slot read by a pure call needs `const`, not `pure`.
analyzer_case(pure_call_blocks_promotion conditional FUNCTION count
  EXPECT "counter is written to memory every iteration"
         "Mark peek `__attribute__\\(\\(const\\)\\)`"
  REJECT "Mark peek `__attribute__\\(\\(pure")

# Recurrences that aren't running totals don't get scan advice.
analyzer_case(linear_recurrence recurrences FUNCTION shift_add
  EXPECT "fmuladd at recurrences.c:4" "algebraic rewrite"
  REJECT "scan" "becomes a reduction" "call at")
analyzer_case(argmax recurrences FUNCTION argmax
  EXPECT "argmax" "then its position in a second loop"
  REJECT "scan")

# Vectorized only when a run-time stride is 1.
analyzer_case(stride_versioning strided
  EXPECT "Vectorized \\(width 4\\), and the vector code only runs when incx == 1")

# The only copy is interleaved x2: strides per source iteration, no duplicates.
analyzer_case(interleave_only_strides interleave_only
  EXPECT "load of in \\(interleave_only.c:8\\): stride 256 elements"
         "no memory dependence is reversed by the swap"
  REJECT "stride 512")

# The remark points at the loop; the volatile store is the blocker.
analyzer_case(volatile_store volatile
  EXPECT "volatile access to y \\(volatile.c:5\\)"
  REJECT "an instruction at")

# clang's optimization record is the verdict when given.
analyzer_case(compile_remarks fixed_trip REMARKS fixed_trip.opt.yaml
  EXPECT "clang reported during compilation: \"the cost-model indicates"
         "checked: with reassociation allowed"
  REJECT "CantReorderFPOps" "rerunning LLVM's vectorizer")
analyzer_case(rerun_is_labeled fixed_trip
  EXPECT "verdict from rerunning LLVM's vectorizer on this optimized IR")

# Other targets: x86 unrolls differently (remainders without preheaders,
# remainders as straight-line code) and has math-errno on by default.
analyzer_case(x86_reduction x86/reduction
  EXPECT "float sum `s` \\(reduction.c:5\\)"
         "Checked: with this change LLVM's vectorizer vectorizes the loop"
         "sum_i32 ===\n\nloop at reduction.c:12 \\(depth 1, innermost\\)\n  \\[Note\\] \\[Vectorization\\] Vectorized \\(width 4\\)"
  REJECT "Already uses SIMD")
analyzer_case(x86_matmul x86/matmul
  EXPECT "load of B \\(matmul.c:9\\): stride n elements")
analyzer_case(x86_column_walk x86/column_walk
  EXPECT "no memory dependence is reversed by the swap"
         "rerun's only conflict comes from unrolling"
  REJECT "stride 2 \\* n")
analyzer_case(x86_accumulate x86/accumulate
  EXPECT "out is written to memory every iteration")
analyzer_case(x86_recurrence x86/recurrence
  EXPECT "each iteration needs the previous iteration's result")
analyzer_case(x86_saxpy x86/saxpy FUNCTION saxpy
  EXPECT "run-time check that x, y don't overlap")
analyzer_case(x86_libm_errno x86/libcalls FUNCTION apply_sin
  EXPECT "sinf may set errno" "-fno-math-errno"
  REJECT "is a C math library function; no vector math library was enabled")

# Without debug info.
analyzer_case(nodebug_saxpy nodebug/saxpy FUNCTION saxpy
  EXPECT "Vectorized \\(width 4\\), but only behind a run-time check"
  REJECT "can't tell whether")
analyzer_case(nodebug_reduction nodebug/reduction FUNCTION sum_f32
  EXPECT "float sum `s` must be added in source order"
  REJECT "can't tell whether")
analyzer_case(nodebug_warning nodebug/saxpy
  EXPECT "No debug info")

# IR from another clang version is flagged.
analyzer_case(ident_mismatch ident_mismatch
  EXPECT "IR was produced by a different compiler version")

# --- GPU kernels --------------------------------------------------------------
# CUDA (gpu_*.cu, nvptx64 sm_70) and HIP (hip_*.hip, gfx90a) device code.
# The CPU analyzers must not run on it: there are no loops to vectorize, the
# parallelism is the thread grid.
analyzer_case(gpu_coalesced gpu_saxpy
  REJECT "Warning\\]" "Vectorization\\]" "Divergence\\]")
analyzer_case(gpu_array_of_structs gpu_strided FUNCTION shift_x
  EXPECT "Uncoalesced load and store of p: neighbouring threads are 3 elements \\(12 bytes\\) apart, so only 33.3%"
         "12 32-byte segments for 128 useful bytes; consecutive elements would need 4"
         "array of Particle \\(12 bytes each\\)"
         "structure of arrays")
analyzer_case(gpu_row_per_thread gpu_strided FUNCTION row_sums
  EXPECT "Uncoalesced load of m: neighbouring threads are n elements apart"
         "once n >= 8[^\n]*only 12.5%"
  REJECT "store to out")
analyzer_case(gpu_stride_two gpu_strided FUNCTION take_even
  EXPECT "neighbouring threads are 2 elements \\(8 bytes\\) apart, so only 50%"
  REJECT "store to out")
analyzer_case(gpu_matmul_coalesced gpu_matmul FUNCTION matmul
  REJECT "Warning\\]")
analyzer_case(gpu_matmul_swapped gpu_matmul FUNCTION matmul_swapped
  EXPECT "Uncoalesced load of A: neighbouring threads are n elements apart"
         "Uncoalesced store to C"
  REJECT "load of B: ")
analyzer_case(gpu_transpose_naive gpu_transpose FUNCTION transpose_naive
  EXPECT "Uncoalesced store to out: neighbouring threads are n elements apart"
  REJECT "load of in")
analyzer_case(gpu_bank_conflict gpu_transpose FUNCTION transpose_tiled
  EXPECT "32-way bank conflict on tile"
         "neighbouring threads are 128 bytes apart"
         "declare tile\\[32\\]\\[33\\] instead of \\[32\\]\\[32\\]. Computed: then no bank conflict"
  REJECT "Coalescing\\]" "store to tile")
analyzer_case(gpu_bank_padded gpu_transpose FUNCTION transpose_padded
  REJECT "Warning\\]")
analyzer_case(gpu_divergent_reduction gpu_divergence FUNCTION reduce_interleaved
  EXPECT "take different sides of this branch"
         "threadIdx.x through a remainder"
         "16, 8, 4, 2 of 32 \\(one count per unrolled copy\\)"
         "if \\(tid < s\\)")
analyzer_case(gpu_sequential_reduction gpu_divergence FUNCTION reduce_sequential
  REJECT "Warning\\]")
analyzer_case(gpu_csr_scalar gpu_divergence FUNCTION spmv_csr_scalar
  EXPECT "run this loop different numbers of times"
         "depends on data each thread loads: load of rowStart"
         "Uncoalesced load of val: each thread walks its own range"
         "Uncoalesced load of col: each thread walks its own range"
         "Data-dependent addresses for load of x[^\n]*\n[^\n]*computed from load of col"
         "one warp per row")
analyzer_case(gpu_if_converted gpu_divergence FUNCTION odd_even_select
  REJECT "Divergence\\]")
analyzer_case(gpu_odd_even_branch gpu_divergence FUNCTION odd_even_branch
  EXPECT "take different sides of this branch" "16 of 32")
# LLVM's NVPTX divergence model treats every generic load as divergent; a
# load from one address for all threads is not.
analyzer_case(gpu_uniform_load gpu_divergence FUNCTION uniform_flag
  REJECT "Divergence\\]")
analyzer_case(gpu_barrier_in_branch gpu_barrier FUNCTION stencil_bad
  EXPECT "\\[Error\\] \\[Divergence\\] Barrier reached by only some threads"
         "barrier at gpu_barrier.cu:10 runs only on one side of the branch at gpu_barrier.cu:8"
         "1 error\\(s\\)")
analyzer_case(gpu_barrier_ok gpu_barrier FUNCTION stencil_ok
  REJECT "Error\\]" "Warning\\]")
analyzer_case(hip_wavefront hip_strided FUNCTION scale_column
  EXPECT "Uncoalesced load and store of m: neighbouring threads are n elements apart"
         "every thread of a wavefront touches its own 64-byte segment"
  REJECT "coerce")
analyzer_case(hip_coalesced hip_strided FUNCTION scale_row
  REJECT "Warning\\]")
