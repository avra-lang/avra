#!/bin/sh
# TWO CENSUS COMPILERS OVER ONE SOURCE, cold and after one body edit.
# Run on a Sprite from the candidate's tree, after ab.sh <base> built both:
#   sh tools/db_measure/hist/census_two.sh <base sha>
# Each compiler is built with the counting runtime in its own tree, then
# stands in the base's build/ and checks the base's packages/cli.
set -u
base=$1
tree=$(pwd)
at=$HOME/dbm-hist/$base
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
f=packages/cli/src/commands/shared.av
lit='· memo'
aside() { find "$at" "$tree" -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null; }
built() {
    # $1 label, $2 tree, $3 the compiler that builds it
    (cd "$2" && cp "$3" build/avra && sh tools/census.sh check packages/std-text > "census.$1.log" 2>&1) || {
        echo "$1	census build failed"; tail -n 20 "$2/census.$1.log"; exit 3; }
    cp "$2/build/avra.census" "$at/build/avra.census.$1"
    echo "$1	census compiler built"
}
counted() {
    # $1 label
    AVRA_MEM_STATS=1 "$at/build/avra.census.$bin" check packages/cli 2> "$HOME/census.$1" > /dev/null
    echo "$1	status=$?"
    grep -Ev '^(mem:|memcap:)' "$HOME/census.$1" | grep -Ev ': site |^ *$' | head -n 40
}
built base "$at" "$at/build/avra.gen2"
built cand "$tree" "$tree/build/avra.gen3"
cd "$at" || exit 2
cp "$f" "$HOME/shared.orig"
for bin in base cand; do
    aside
    cp "$HOME/shared.orig" "$f"
    counted "$bin.cold"
    counted "$bin.noop"
    python3 - "$HOME/shared.orig" "$f" "$lit" <<'PY'
import sys
orig, dest, lit = sys.argv[1:4]
text = open(orig, encoding="utf-8").read()
assert lit in text
open(dest, "w", encoding="utf-8").write(text.replace(lit, lit + " census-edit", 1))
PY
    counted "$bin.edit"
    cp "$HOME/shared.orig" "$f"
done
