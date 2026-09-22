#!/bin/sh
# THE FORMATTER'S REAL RECEIPT: `fmt(x) == x` for an already-canonical
# file — BYTE EQUALITY, never idempotence (`fmt(fmt(x)) == fmt(x)` stays
# green while a comment is being deleted, because the second pass has
# nothing left to lose — CLAUDE.md, "A CHECK CAN PASS BECAUSE OF THE
# BUG"). `tools/fmt_roundtrip.sh` counts comment CLASSES lost; this
# counts FILES that do not come back at all, whatever the cause —
# comment loss, a reordered annotation, a dropped `export`, layout.
#
# A `--write` over the tree is safe only when this reports 0 differing
# (docs/2026_09_21_FORMATTER_DESIGN.md §4, §10 phase 4). This script
# never fails the gate itself — it REPORTS, the way `idioms` reports
# its debt — because a non-zero count here is a known, tracked gap
# (avra-8sb5.25.11/.12/.19, .11.104, .11.112), not a fresh regression
# with no baseline to compare against.
set -u
avra=${AVRA:-build/avra}
root=${1:-.}
shift || true
if [ "$#" -gt 0 ]; then
    list=$*
else
    list=$(find "$root/packages" -name '*.av' | sort)
fi
files=0
refused=0
differing=0
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

for f in $list; do
    files=$((files + 1))
    out="$work/out.av"
    if ! "$avra" fmt "$f" > "$out" 2>"$work/err"; then
        refused=$((refused + 1))
        echo "$f  REFUSED: $(head -1 "$work/err")"
        continue
    fi
    if ! cmp -s "$f" "$out"; then
        differing=$((differing + 1))
        bytes_in=$(wc -c < "$f" | tr -d ' ')
        bytes_out=$(wc -c < "$out" | tr -d ' ')
        first_diff=$(diff "$f" "$out" 2>/dev/null | head -1)
        echo "$f  $bytes_in -> $bytes_out bytes  ${first_diff}"
    fi
done

echo "fmt_lossless: $files file(s) examined, $differing differing, $refused refused"
