#!/usr/bin/env bash
# Run tests. Usage: ./scripts/test.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
cd "$BUILD_DIR"
ctest --output-on-failure
echo "Tests passed."
