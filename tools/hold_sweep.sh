#!/bin/sh
# THE HOLD, SWEPT. The gate never edits a file, so it cannot see a hold that is wrong
# for an edit nobody tried. This touches EVERY source the program's build reads, one
# at a time, builds through the hold, and files the outcome by class. The tree is
# clean, so any refusal is the hold's.
#   sh tools/hold_sweep.sh [package dir] [path filter]     (default: packages/cli)
set -u
cd "$(dirname "$0")/.."
pkg="${1:-packages/cli}"; filter="${2:-}"; out=build/hold-sweep.out; : > "$out"; : > build/hold-sweep.said
./avra build "$pkg" > /dev/null 2>&1 || { echo "hold-sweep: $pkg does not build clean — nothing to sweep"; exit 1; }
files=$(git ls-files 'packages/*.av' | grep -v '/tests/' | grep "$filter")
n=0; bad=0
for f in $files; do
    [ -f "$f" ] || continue   # listed by git, deleted in the tree
    n=$((n+1)); cp "$f" "$f.sweep"; printf '\n// swept\n' >> "$f"
    msg=$(./avra build --time "$pkg" 2>&1); st=$?
    mv "$f.sweep" "$f"
    class=ok
    [ "$st" -ne 0 ] && class=$(printf '%s\n' "$msg" | grep -oE 'error\[F[0-9]{4}\]|avra: [a-z `A-Z]{0,40}|Undefined symbols' | head -1)
    printf '%s' "$msg" | grep -q "the hold was refused" && class="refused-then-ok"
    # A CLEAN BUILD THAT HELD ALMOST NOTHING IS A FINDING TOO: the hold collapsed
    # once to 25/292 on a correct build, and "clean" said nothing about it.
    held=$(printf '%s\n' "$msg" | grep -oE "held [0-9]+/[0-9]+" | tail -1 | sed 's/held //')
    if [ "$class" = ok ] && [ -n "$held" ] && [ $(( ${held%/*} * 100 / ${held#*/} )) -lt 85 ]; then class="thin-hold $held"; fi
    # a finding keeps its words: a class alone cannot be reproduced
    [ "$class" = ok ] || { bad=$((bad+1)); echo "$class	$f" >> "$out"; { echo "== $f (status $st)"; printf '%s\n' "$msg" | grep -vE '^[[:space:]]|^warning|^───|^help|^$|│' | tail -12; } >> build/hold-sweep.said; }
done
sort "$out" | cut -f1 | uniq -c | sort -rn
echo "hold-sweep: $n files touched under $pkg's build, $bad not a clean held build — $out"
[ "$bad" -eq 0 ]
