#!/usr/bin/env bash
# Generate LLVM IR or bitcode from a C/C++ source. Usage:
#   ./scripts/generate_ir.sh source.c [output.ll]
#   ./scripts/generate_ir.sh source.cpp kernel.ll
# Uses clang; optional second arg is output path (default: input.ll).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <source.c|source.cpp> [output.ll|output.bc]"
  exit 1
fi
SRC="$1"
OUT="${2:-${SRC%.*}.ll}"
clang -S -emit-llvm -O2 -o "$OUT" "$SRC"
echo "Generated: $OUT"
