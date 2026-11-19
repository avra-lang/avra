#!/bin/sh
# ONE WARM BODY EDIT, TRACED: the phase split, then every file QTRACE
# reads — the instrument for "a one-file edit must not parse the tree".
#
#   sh tools/db_measure/parse_trace.sh [<package> <file> <literal>]
#
# A FRESH edit text per trace: a repeated text is a store hit, and a hit
# parses nothing, so the trace would report the absence of the work it
# exists to measure. The trace is a SEPARATE run from the timed one, over
# its own fresh edit.
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
A=${AVRA_BIN:-build/avra}
pkg=${1:-packages/cli}
file=${2:-packages/cli/src/commands/shared.av}
lit=${3:-· memo}
orig=$(mktemp)
cp "$file" "$orig"
restore() { cp "$orig" "$file"; rm -f "$orig"; }
trap restore EXIT INT TERM

edit() { # <word>
    cp "$orig" "$file"
    python3 - "$file" "$lit" "$1" <<'PY'
import sys
path, lit, word = sys.argv[1:4]
text = open(path, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
}

nonce=$(date +%s)-$$
echo "=== phase split (one warm edit) ==="
edit "timed$nonce"
"$A" check --time "$pkg" 2>&1 | grep '^time:' | tail -1

echo "=== QTRACE (one FRESH warm edit) ==="
edit "traced$nonce-second"
AVRA_QTRACE=1 "$A" check "$pkg" 2> build/qtrace.txt >/dev/null
parsed=$(awk -F'\t' '$1=="Q" && $2=="parse" {print $3}' build/qtrace.txt)
echo "files parsed: $(printf '%s\n' "$parsed" | grep -c .)"
echo "--- first 40 paths ---"
printf '%s\n' "$parsed" | head -40
echo "--- distinct directories ---"
printf '%s\n' "$parsed" | sed 's#/[^/]*$##' | sort | uniq -c | sort -rn | head -30
