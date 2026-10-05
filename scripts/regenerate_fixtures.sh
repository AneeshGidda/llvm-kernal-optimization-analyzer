#!/usr/bin/env bash
# Regenerate test/fixtures/ir from test/fixtures/src/*.c with clang 15.
#   ir/*.ll, ir/*.opt.yaml   arm64-apple-macos (the main expectations)
#   ir/x86/*.ll              x86_64-linux-gnu: other unrolling decisions,
#                            and math-errno on by default
#   ir/nodebug/*.ll          no debug info
#   ir/gpu_*.ll              CUDA kernels (gpu_*.cu) for nvptx64 sm_70
#   ir/hip_*.ll              HIP kernels (hip_*.hip) for amdgcn gfx90a
#   ir/unoptimized.ll        -O0: the tool must refuse it
#   ir/ident_mismatch.ll     claims another clang version
# Expectations in test/CMakeLists.txt assume these targets.
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "$CLANG" ]]; then
  CLANG="$("${LLVM_CONFIG:-llvm-config}" --bindir)/clang"
fi
export CLANG
GEN="$ROOT/scripts/generate_ir.sh"
IR="$ROOT/test/fixtures/ir"
ARM=(--target=arm64-apple-macos13 -mcpu=apple-m1)
X86=(--target=x86_64-unknown-linux-gnu)
mkdir -p "$IR/x86" "$IR/nodebug"
# Compile from inside src/ so debug locations read "matmul.c:8", not an
# absolute path from whoever regenerated them.
cd "$ROOT/test/fixtures/src"
for src in *.c; do
  "$GEN" "$src" "$IR/${src%.c}.ll" "${ARM[@]}" -fdebug-compilation-dir=.
done
for name in reduction matmul column_walk accumulate recurrence saxpy libcalls; do
  "$GEN" "$name.c" "$IR/x86/$name.ll" "${X86[@]}" -fdebug-compilation-dir=.
done
rm -f "$IR"/x86/*.opt.yaml
# GPU device code only (no host side). Neither needs a CUDA or ROCm install:
# cuda_shim.h stands in for the CUDA headers.
for src in *.cu; do
  "$GEN" "$src" "$IR/${src%.cu}.ll" -x cuda --cuda-device-only \
    -nocudainc -nocudalib --cuda-gpu-arch=sm_70 -fdebug-compilation-dir=.
done
for src in *.hip; do
  "$GEN" "$src" "$IR/${src%.hip}.ll" -x hip --cuda-device-only \
    -nogpuinc -nogpulib --offload-arch=gfx90a -fdebug-compilation-dir=.
done
rm -f "$IR"/gpu_*.opt.yaml "$IR"/hip_*.opt.yaml
# Not through generate_ir.sh: saving remarks makes clang keep locations.
for name in saxpy reduction; do
  "$CLANG" "${ARM[@]}" -O2 -fno-discard-value-names -S -emit-llvm \
    -o "$IR/nodebug/$name.ll" "$name.c"
done
# One deliberately unoptimized fixture: the tool must refuse to analyze -O0.
"$CLANG" "${ARM[@]}" -O0 -S -emit-llvm -fno-discard-value-names \
  -o "$IR/unoptimized.ll" reduction.c
sed 's/clang version 15\.[0-9.]*/clang version 17.0.0/' "$IR/saxpy.ll" \
  > "$IR/ident_mismatch.ll"
echo "Generated fixtures in $IR"
