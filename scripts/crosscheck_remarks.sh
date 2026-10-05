#!/usr/bin/env bash
# Print clang's own vectorizer remarks next to the analyzer's verdicts for
# every fixture, to confirm they agree. Usage: ./scripts/crosscheck_remarks.sh
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANALYZER="${ANALYZER:-$ROOT/build/analyzer}"
SYSROOT=()
if [[ "$(uname)" == "Darwin" ]] && command -v xcrun >/dev/null; then
  SYSROOT=(-isysroot "$(xcrun --show-sdk-path)")
fi
CLANG="${CLANG:-$("${LLVM_CONFIG:-llvm-config}" --bindir)/clang}"
cd "$ROOT/test/fixtures/src"
for src in *.c; do
  echo "=== $src"
  echo "--- clang -O2 -Rpass*=loop-vectorize"
  "$CLANG" --target=arm64-apple-macos13 -mcpu=apple-m1 -O2 "${SYSROOT[@]}" \
    -Rpass=loop-vectorize -Rpass-missed=loop-vectorize \
    -Rpass-analysis=loop-vectorize -S -o /dev/null "$src" 2>&1 |
    grep remark || echo "(no remarks)"
  echo "--- analyzer"
  "$ANALYZER" "$ROOT/test/fixtures/ir/${src%.c}.ll" | grep -E '\[Vectorization\]'
done
