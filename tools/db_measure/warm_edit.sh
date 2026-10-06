#!/bin/sh
# THE ONE-EDIT CHECK, MEASURED. Run from a tree's root, over its own
# build/avra (or AVRA_BIN):
#   sh tools/db_measure/warm_edit.sh [rounds]
# One cold `check packages/cli` with every store removed, two no-op
# checks, then per scenario `rounds` warm checks, each after ONE string
# literal in ONE body moved to text no earlier round wrote (a repeated
# text is a store hit and measures nothing). The file is restored after
# its scenario. Each line: label, wall ms, exit status, the compiler's
# own `--time` line. A scenario whose literal this tree lacks says so.
set -u
A=${AVRA_BIN:-build/avra}
R=${1:-3}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
out=${TMPDIR:-/tmp}/dbm_warm.$$
now() { date +%s%N; }
checked() {
    s=$(now)
    "$A" check --time packages/cli > "$out" 2>&1
    st=$?
    e=$(now)
    echo "$1	wall_ms=$(((e - s) / 1000000))	status=$st	$(grep '^time:' "$out" | tail -n 1)"
}
# Counts the kernel's own trace of one run: asks by outcome, settles, files parsed.
traced() {
    AVRA_QTRACE=1 "$A" check packages/cli 2> "$out.q" > /dev/null
    echo "$1	$(awk -F'\t' '$1 == "Q" && $2 == "ask" { n[$5]++ } $1 == "Q" && $2 == "settle" { s++ }
        $1 == "Q" && $2 == "parse" { p++ } END { printf "reuse=%d compute=%d cycle=%d settle=%d parse=%d", n["reuse"], n["compute"], n["cycle"], s, p }' "$out.q")"
    rm -f "$out.q"
}
# scenario <label> <file> <literal>: the literal gains a fresh word each round.
scenario() {
    label=$1
    f=$2
    lit=$3
    grep -qF "$lit" "$f" 2>/dev/null || { echo "$label	absent: $f lacks \`$lit\`"; return; }
    cp "$f" "$out.orig"
    checked "$label.settle"
    i=1
    while [ "$i" -le "$R" ]; do
        python3 - "$out.orig" "$f" "$lit" "$label$i$(now)" <<'PY'
import sys
orig, dest, lit, word = sys.argv[1:5]
text = open(orig, encoding="utf-8").read()
open(dest, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
        checked "$label.edit$i"
        i=$((i + 1))
    done
    python3 - "$out.orig" "$f" "$lit" "$label-traced$(now)" <<'PY'
import sys
orig, dest, lit, word = sys.argv[1:5]
text = open(orig, encoding="utf-8").read()
open(dest, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
    traced "$label.qtrace"
    cp "$out.orig" "$f"
    rm -f "$out.orig"
}

echo "tree	$(pwd)	files=$(find packages -name '*.av' | wc -l | tr -d ' ')	binary=$A"
find . -name .avra-cache -type d -prune -exec rm -rf {} +
checked cold
checked noop1
checked noop2
scenario cli packages/cli/src/commands/shared.av '· memo'
scenario avrac packages/std-avrac/src/diagnostics/render.av '<source>'
scenario receipt packages/std-avrac/src/compiler/format/receipt.av 'a token moved at position'
rm -f "$out"
