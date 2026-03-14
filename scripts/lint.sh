#!/usr/bin/env bash
# Run clang-tidy on sources. Usage: ./scripts/lint.sh [path...]
# Requires a compile_commands.json (run from build dir: cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
if [[ $# -eq 0 ]]; then
  PATHS=("$ROOT/src" "$ROOT/include")
else
  PATHS=("$@")
fi
if [[ ! -f "$BUILD_DIR/compile_commands.json" ]]; then
  echo "Run from build dir: cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON $ROOT"
  exit 1
fi
for path in "${PATHS[@]}"; do
  find "$path" -type f -name '*.cpp' -print0 \
    | xargs -0 -I {} clang-tidy {} -p "$BUILD_DIR" --format-style=file 2>/dev/null || true
done
echo "Lint completed for: ${PATHS[*]}"
