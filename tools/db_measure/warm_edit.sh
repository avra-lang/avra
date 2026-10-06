#!/bin/sh
# THE ONE-EDIT CHECK, MEASURED. Run from a tree's root, over its own
# build/avra (or AVRA_BIN):
#   sh tools/db_measure/warm_edit.sh [rounds] [<package> <label> <file> <literal>]
# With no scenario named: packages/cli, edited in the cli, in std-avrac's
# diagnostics, and in the formatter's receipt. For the package: every store
# removed, one cold `check`, two no-op checks, then per scenario `rounds` warm
# checks, each after ONE string literal in ONE body moved to text no earlier
# round wrote (a repeated text is a store hit and measures nothing). Then the
# same edit twice more, once under AVRA_QTRACE and once under AVRA_DB_GRAPH,
# counted per family by graph.py when this tree's compiler carries the flag.
# The file is restored after its scenario. Each timed line: label, wall ms,
# exit status, the compiler's own `--time` line.
set -u
A=${AVRA_BIN:-build/avra}
R=${1:-3}
here=$(cd "$(dirname "$0")" && pwd)
families=packages/std-avrac/src/compiler/families/families.av
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
out=${TMPDIR:-/tmp}/dbm_warm.$$
now() { date +%s%N; }
checked() {
    s=$(now)
    "$A" check --time "$pkg" > "$out" 2>&1
    st=$?
    e=$(now)
    echo "$1	wall_ms=$(((e - s) / 1000000))	status=$st	$(grep '^time:' "$out" | tail -n 1)"
}
edited() {
    python3 - "$out.orig" "$1" "$2" "$3$(now)" <<'PY'
import sys
orig, dest, lit, word = sys.argv[1:5]
text = open(orig, encoding="utf-8").read()
open(dest, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
}
# The same run again under each of the kernel's two traces, counted per family.
traced() {
    [ -f "$families" ] && [ -f "$here/graph.py" ] || return 0
    edited "$2" "$3" "$1-q"
    AVRA_QTRACE=1 "$A" check "$pkg" 2> "$out.q" > /dev/null
    echo "$1.qtrace"
    python3 "$here/graph.py" --qtrace "$out.q" "$families"
    edited "$2" "$3" "$1-g"
    AVRA_DB_GRAPH=1 "$A" check "$pkg" 2> "$out.g" > /dev/null
    echo "$1.graph"
    python3 "$here/graph.py" --m1 "$out.g" "$families"
    rm -f "$out.q" "$out.g"
}
scenario() {
    label=$1
    f=$2
    lit=$3
    grep -qF "$lit" "$f" 2>/dev/null || { echo "$label	absent: $f lacks \`$lit\`"; return; }
    cp "$f" "$out.orig"
    i=1
    while [ "$i" -le "$R" ]; do
        edited "$f" "$lit" "$label$i"
        checked "$label.edit$i"
        i=$((i + 1))
    done
    traced "$label" "$f" "$lit"
    cp "$out.orig" "$f"
    rm -f "$out.orig"
    checked "$label.restored"
}
opened() {
    pkg=$1
    echo "tree	$(pwd)	package=$pkg	files=$(find packages -name '*.av' | wc -l | tr -d ' ')	binary=$A"
    find . -name .avra-cache -type d -prune -exec rm -rf {} +
    checked cold
    checked noop1
    checked noop2
}

if [ "$#" -ge 5 ]; then
    opened "$2"
    scenario "$3" "$4" "$5"
else
    opened packages/cli
    scenario cli packages/cli/src/commands/shared.av '· memo'
    scenario avrac packages/std-avrac/src/diagnostics/render.av '<source>'
    scenario receipt packages/std-avrac/src/compiler/format/receipt.av 'a token moved at position'
fi
rm -f "$out"
