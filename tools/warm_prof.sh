#!/bin/sh
# Warm-path phase profile for the DB performance question. Prints numbers
# only; no fixes. Run from a tree's root over its own build/avra.
set -u
A=${AVRA_BIN:-build/avra}
PKG=${1:-packages/cli}
F=${2:-packages/cli/src/commands/shared.av}
LIT=${3:-· memo}
FAM=packages/std-avrac/src/compiler/families/families.av
now() { date +%s%N; }
emit() {
    s=$(now)
    "$A" check --time "$PKG" > /tmp/wp.out 2>&1
    st=$?
    e=$(now)
    echo "$1	wall_ms=$(( (e - s) / 1000000 ))	status=$st"
    grep -E '^(time:|  discarded:|  held)' /tmp/wp.out | sed 's/^/    /'
}
bump() {
    python3 - "$F" "$LIT" "$1$(now)" <<'PY'
import sys
f, lit, word = sys.argv[1:4]
t = open(f, encoding='utf-8').read()
open(f, 'w', encoding='utf-8').write(t.replace(lit, lit + " " + word, 1))
PY
}
state() {
    echo "=== state ==="
    cat build/.avra-built-from 2>/dev/null; echo
}
state
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
echo "=== COLD (no check key) ==="
emit cold
echo "=== UNCHANGED (check key warm) ==="
emit unchanged1
emit unchanged2

cp "$F" /tmp/wp.orig
echo "=== ONE BODY EDIT ==="
bump e1; emit edit1
bump e2; emit edit2
cp /tmp/wp.orig "$F"

echo "=== LOWERINGS: qtrace on one edit ==="
bump q; AVRA_QTRACE=1 "$A" check "$PKG" 2> /tmp/wp.q > /dev/null
python3 tools/db_measure/graph.py --qtrace /tmp/wp.q "$FAM"
cp /tmp/wp.orig "$F"

echo "=== FAMILIES: dbgraph on one edit (M1) ==="
bump g; AVRA_DB_GRAPH=1 "$A" check "$PKG" 2> /tmp/wp.g > /dev/null
python3 tools/db_measure/graph.py --m1 /tmp/wp.g "$FAM"
cp /tmp/wp.orig "$F"

echo "=== MEM: check on one edit ==="
bump m
AVRA_MEM_STATS=1 "$A" check "$PKG" 2>&1 >/dev/null | grep -iE 'live|peak|total|category|list|string|record|enum|box|static' | head -40
cp /tmp/wp.orig "$F"
rm -f /tmp/wp.out /tmp/wp.orig
