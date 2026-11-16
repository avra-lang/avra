#!/bin/sh
# A PACKAGE'S SUITE ON THE PROGRAM LAYER SAYS WHAT THE OLD RUNNER SAYS, AND AN EDIT OF ONE CASE
# WORKS OUT THAT CASE ALONE. tools/program-suites/suited holds a spec whose cases pass but one,
# which is wrong on purpose, a lone case in no group, a program test and a test run as a child:
#   `avra test` of it on the old path and on the program layer (each cold) — the same exit, the same
#     stdout byte for byte, the failing case's sides and the runner's verdict included;
#   then, on the program layer, one `then` body edited and the suite tested warm: exactly one case
#     lowered again, and the same stdout as the edited tree tested cold.
#   sh tools/witness_program_suites.sh [compiler]   (default build/avra-try)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_suites: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
failed=0
missed() { echo "witness_program_suites: $1" >&2; failed=$((failed + 1)); }

# `avra test suited` under AVRA_PROGRAM=$1 in the copy $2 — a fresh one with no store, `edited.av`
# standing as the edited file where $3 is `edited`, or the copy as it stands where $3 is `warm`: its
# stdout said with the copy's path as <w>, its exit, its stderr
tested() {
    if [ "${3:-}" != warm ]; then
        find "$tmp/$2" "$tmp/$2.machine" -depth -delete 2>/dev/null
        mkdir -p "$tmp/$2" "$tmp/$2.machine"
        cp -R "$root/tools/program-suites/suited" "$tmp/$2/"
        [ "${3:-}" = edited ] && cp "$tmp/edited.av" "$tmp/$2/$edited"
    fi
    (cd "$tmp/$2" && AVRA_CACHE_DIR="$tmp/$2.machine" AVRA_PROGRAM=$1 AVRA_QUERY_TIMES=1 "$avra" test suited >"$tmp/$2.out" 2>"$tmp/$2.err"
        echo $? >"$tmp/$2.code")
    sed "s#$tmp/$2#<w>#g" "$tmp/$2.out" >"$tmp/$2.said"
}

edited=suited/src/tests/twice_test.av
tested 0 old
tested 1 new
[ "$(cat "$tmp/old.code")" = "$(cat "$tmp/new.code")" ] || missed "the old path exits $(cat "$tmp/old.code"), the program layer $(cat "$tmp/new.code")"
cmp -s "$tmp/old.said" "$tmp/new.said" || { missed "the program layer says otherwise than the old runner"; diff "$tmp/old.said" "$tmp/new.said" >&2; }
grep -q "actual:   4" "$tmp/new.said" || missed "the failing case's sides are not shown"

sed 's/then "it doubles" { twice(2) == 4 }/then "it doubles" { twice(3) == 6 }/' "$tmp/new/$edited" >"$tmp/edited.av"
cmp -s "$tmp/edited.av" "$tmp/new/$edited" && missed "the case edit found nothing to edit"
cp "$tmp/edited.av" "$tmp/new/$edited"
tested 1 new warm
lowered=$(grep "^worked:" "$tmp/new.err" | grep -o "lowered_case [0-9]*" | awk '{ s += $2 } END { print s + 0 }')
[ "$lowered" = 1 ] || missed "one case edited, $lowered cases lowered again"
cp "$tmp/new.said" "$tmp/warm.said"
tested 1 cold edited
cmp -s "$tmp/warm.said" "$tmp/cold.said" || { missed "the edited suite tested warm says otherwise than tested cold"; diff "$tmp/warm.said" "$tmp/cold.said" >&2; }

[ "$failed" = 0 ] && echo "witness_program_suites: the old runner's words on the program layer; one case edited, one case lowered again"
[ "$failed" = 0 ]
