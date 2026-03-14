#!/usr/bin/env bash
# Format source with clang-format. Usage: ./scripts/format.sh [path...]
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ $# -eq 0 ]]; then
  PATHS=("$ROOT/include" "$ROOT/src")
else
  PATHS=("$@")
fi
for path in "${PATHS[@]}"; do
  while IFS= read -r -d '' f; do
    clang-format -i "$f"
  done < <(find "$path" -type f \( -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) -print0 2>/dev/null)
done
echo "Formatted: ${PATHS[*]}"
