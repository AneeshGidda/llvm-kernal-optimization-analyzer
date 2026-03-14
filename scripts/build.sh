#!/usr/bin/env bash
# Build the analyzer. Usage: ./scripts/build.sh [build_dir]
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${1:-$ROOT/build}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake "$ROOT"
cmake --build .
