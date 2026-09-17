#!/bin/sh
# THE SURVIVOR BASELINE KEEPER. `avra attack <feature>` prints every
# malformed mutant the compiler ACCEPTS to stderr as
# `survivor<TAB>feature<TAB>source`. A survivor is not a failure — it
# may be a VALID program — so the malformed class's law stays TOLERANCE,
# and THIS holds the accepted set against tools/attack.baseline: a NEW
# survivor is refused (a decision must be made), and a baseline entry
# that now REFUSES is stale. The baseline lists sites, never counts.
set -eu
cd "$(dirname "$0")/.."
now=$(mktemp)
base=$(mktemp)
diffout=$(mktemp)
trap 'rm -f "$now" "$base" "$diffout"' EXIT
for f in $(find packages/std-avrac/src/features -name '*_mechanical_test.av' | LC_ALL=C sort); do
    n=$(echo "$f" | sed 's|.*/features/||; s|/tests/.*||')
    ./avra attack "$n" 2>>"$now" >/dev/null || true
done
grep '^survivor' "$now" 2>/dev/null | cut -f2,3 | LC_ALL=C sort > "$now.now" || :
grep -v '^#' tools/attack.baseline | grep -v '^$' | cut -f1,2 | LC_ALL=C sort > "$now.base" || :
if ! diff -u "$now.base" "$now.now" > "$diffout" 2>&1; then
    echo "attack: the survivor baseline moved — a NEW mutant is accepted, or an entry is stale:"
    sed 's/^/    /' "$diffout" | head -40
    echo "  A new survivor is a DECISION: file it, then add a line"
    echo "  <feature><TAB><source><TAB><task id | valid mutant: why>."
    echo "  Do NOT narrow the class to hide it."
    exit 1
fi
echo "attack: $(wc -l < "$now.now" | tr -d ' ') survivor(s), all in the baseline"
