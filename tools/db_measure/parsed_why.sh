#!/bin/sh
# WHY EACH FILE IS READ ON A ONE-FILE EDIT. From a tree's root, the store warm
# or not:  sh tools/db_measure/parsed_why.sh <package> <file> <literal>
# One fresh-text edit checked with `--time` (the compiler's own list of files
# read anyway, each with why), then another under AVRA_QTRACE, each parse
# printed with the queries that reached it. The file is restored.
set -u
A=${AVRA_BIN:-build/avra}
pkg=$1
f=$2
lit=$3
here=$(cd "$(dirname "$0")" && pwd)
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
out=${TMPDIR:-/tmp}/dbm_why.$$
edited() {
    python3 - "$out.orig" "$f" "$lit" "$1$(date +%s%N)" <<'PY'
import sys
orig, dest, lit, word = sys.argv[1:5]
text = open(orig, encoding="utf-8").read()
open(dest, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
}
"$A" check "$pkg" > /dev/null 2>&1
cp "$f" "$out.orig"
edited a
"$A" check "$pkg" > /dev/null 2>&1
edited b
echo "== check --time, one edit of $f"
"$A" check --time "$pkg" 2>&1 | sed -n '/^time:/,$p'
edited c
AVRA_QTRACE=1 "$A" check "$pkg" 2> "$out.q" > /dev/null
echo "== parses under AVRA_QTRACE, one edit of $f"
python3 "$here/parse_why.py" "$out.q" packages/std-avrac/src/compiler/families/families.av
cp "$out.orig" "$f"
rm -f "$out.orig" "$out.q"
"$A" check "$pkg" > /dev/null 2>&1
