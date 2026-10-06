#!/bin/sh
# EVERY PACKAGE'S ONE-EDIT CHECK, AND WHAT IT THREW AWAY. From a tree's root:
#   sh tools/db_measure/discarded_sweep.sh [package...]      (default: every package)
# Per package: a check to warm the store, then a comment line appended to one
# source file that is not the entry (the first by name; the only file when
# there is one), then `check --time` twice more, each on fresh text. Printed:
# the second edit's wall ms, its held count, and each attempt that did not
# stand with what it cost and why. The file is restored.
set -u
A=${AVRA_BIN:-build/avra}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
out=${TMPDIR:-/tmp}/dbm_sweep.$$
[ "$#" -gt 0 ] || set -- $(ls packages)
for p in "$@"; do
    pkg=packages/$p
    [ -d "$pkg/src" ] || continue
    f=$(find "$pkg/src" -name '*.av' ! -path '*/tests/*' ! -name main.av ! -name lib.av | LC_ALL=C sort | head -n 1)
    [ -n "$f" ] || f=$(find "$pkg/src" -name '*.av' ! -path '*/tests/*' | LC_ALL=C sort | head -n 1)
    [ -n "$f" ] || { echo "$p	no source"; continue; }
    "$A" check "$pkg" > /dev/null 2>&1
    cp "$f" "$out.orig"
    for i in 1 2; do
        { cat "$out.orig"; echo "// swept $i $(date +%s%N)"; } > "$f"
        s=$(date +%s%N)
        "$A" check --time "$pkg" > "$out" 2>&1
        st=$?
        e=$(date +%s%N)
    done
    cp "$out.orig" "$f"
    echo "$p	wall_ms=$(((e - s) / 1000000))	status=$st	$(grep -o 'held [0-9]*/[0-9]*' "$out" | tail -n 1)	$(grep -o 'discarded [0-9]*, refused [0-9]*' "$out" | tail -n 1)	edited=${f#$pkg/}"
    grep '^  discarded: ' "$out" | cut -c1-400
done
rm -f "$out" "$out.orig"
