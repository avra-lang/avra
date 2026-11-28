#!/bin/sh
# one fresh edit, then WHY the hold breaks, from `explain --why`'s moved parts.
. "$(dirname "$0")/../../tools/lib/scratch.sh"
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
A=${AVRA_BIN:-build/avra}
file=${1:-packages/cli/src/commands/shared.av}
lit=${2:-· memo}
scratch_dir orig; orig="$orig/file"; cp "$file" "$orig"
scratch_dir why; why="$why/file"
restore() { cp "$orig" "$file"; rm -f "$orig" "$why"; }
scratch_also restore
nonce=$(date +%s)-$$
python3 - "$file" "$lit" "$nonce" <<'PY'
import sys
path, lit, word = sys.argv[1:4]
t = open(path, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(t.replace(lit, lit + " " + word, 1))
PY
"$A" explain --why packages/cli > "$why" 2>&1
echo "exit $?; lines $(wc -l < "$why")"
head -n 80 "$why"
