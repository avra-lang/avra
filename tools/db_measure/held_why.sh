#!/bin/sh
# WHAT THE HOLD SAYS ABOUT EACH FILE after one edit, before any check keeps it:
#   sh tools/db_measure/held_why.sh <package> <file> <literal>
# `avra cache` (the summary) and `avra cache held`, asked of the package with
# the store warm and one literal moved. The file is restored.
set -u
root=$(pwd)
A=${AVRA_BIN:-$root/build/avra}
pkg=$1
f=$2
lit=$3
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
"$A" check "$pkg" > /dev/null 2>&1
cp "$f" "$f.dbm"
python3 - "$f.dbm" "$f" "$lit" "held$(date +%s%N)" <<'PY'
import sys
orig, dest, lit, word = sys.argv[1:5]
text = open(orig, encoding="utf-8").read()
open(dest, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
(cd "$pkg" && AVRA_CWD=$(pwd) "$A" cache 2>&1 | head -n 80; echo "== held"; AVRA_CWD=$(pwd) "$A" cache held 2>&1 | grep -v ' held$' | head -n 120)
mv "$f.dbm" "$f"
