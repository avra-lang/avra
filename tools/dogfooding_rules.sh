#!/bin/sh
# DOGFOODING.md's registry keeps a GENERATED block between two
# markers: one bullet per rule that carries its own `///` doc
# (`avra rules --markdown`, packages/cli/src/commands/rules.av). A
# rule's doc changing and the block not being refreshed is the same
# staleness the exemption law refuses everywhere else — this reads
# the committed block, asks the LIVE compiler for the same listing,
# and refuses the two disagreeing.
set -eu
avra=${AVRA:-build/avra}
doc=${1:-DOGFOODING.md}
start='<!-- GENERATED:RULES:START -->'
end='<!-- GENERATED:RULES:END -->'

committed=$(mktemp)
live=$(mktemp)
diffed=$(mktemp)
trap 'rm -f "$committed" "$live" "$diffed"' EXIT

if ! grep -qF "$start" "$doc" || ! grep -qF "$end" "$doc"; then
    echo "dogfooding-rules: ${doc} carries no ${start} / ${end} markers"
    exit 1
fi

awk -v s="$start" -v e="$end" '
    $0 == e { inside = 0 }
    inside { print }
    $0 == s { inside = 1 }
' "$doc" > "$committed"

"$avra" rules --markdown > "$live"

if diff -u "$committed" "$live" > "$diffed"; then
    n=$(wc -l < "$live" | tr -d ' ')
    echo "dogfooding-rules: ${doc}'s generated block matches avra rules --markdown (${n} rule(s))"
    exit 0
else
    echo "dogfooding-rules: ${doc}'s generated block is STALE against avra rules --markdown — regenerate it:"
    cat "$diffed"
    exit 1
fi
