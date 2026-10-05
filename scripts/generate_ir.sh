#!/usr/bin/env bash
# Generate analyzer input from a C/C++ source. Usage:
#   ./scripts/generate_ir.sh source.c [output.ll] [extra clang flags...]
#
# -O2: analyze the code you actually ship; the tool explains what the
#      optimizer did and didn't do.
# -gline-tables-only: source locations, and lets the tool match the copies
#      of a loop the vectorizer creates.
# -fno-discard-value-names: keeps parameter names (A, B, n) in the IR.
# -fsave-optimization-record: writes output.opt.yaml next to the IR with the
#      vectorizer's real decisions; pass it to the analyzer with --remarks.
#
# The analyzer reads LLVM 15 IR. CLANG defaults to the clang next to
# `llvm-config` (override with CLANG=... or LLVM_CONFIG=...).
set -e
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <source.c|source.cpp> [output.ll] [clang flags...]"
  exit 1
fi
SRC="$1"
OUT="${2:-${SRC%.*}.ll}"
shift; [[ $# -gt 0 ]] && shift
if [[ -z "$CLANG" ]]; then
  LLVM_CONFIG="${LLVM_CONFIG:-llvm-config}"
  if command -v "$LLVM_CONFIG" >/dev/null; then
    CLANG="$("$LLVM_CONFIG" --bindir)/clang"
  else
    CLANG=clang
  fi
fi
if ! "$CLANG" --version | grep -q "clang version 15\."; then
  echo "warning: $CLANG is not clang 15; the analyzer reads LLVM 15 IR." \
       "Set CLANG or LLVM_CONFIG to an LLVM 15 install." >&2
fi
SYSROOT=()
if [[ "$(uname)" == "Darwin" ]] && command -v xcrun >/dev/null; then
  SYSROOT=(-isysroot "$(xcrun --show-sdk-path)")
fi
REMARKS="${OUT%.ll}.opt.yaml"
"$CLANG" -O2 -gline-tables-only -fno-discard-value-names "${SYSROOT[@]}" \
  -fsave-optimization-record -foptimization-record-file="$REMARKS" \
  -foptimization-record-passes=loop-vectorize \
  -S -emit-llvm "$@" -o "$OUT" "$SRC"
echo "Generated: $OUT (remarks: $REMARKS)"
echo "Analyze:   analyzer --remarks $REMARKS $OUT"
