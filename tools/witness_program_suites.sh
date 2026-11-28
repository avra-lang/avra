#!/bin/sh
# A PACKAGE'S SUITE ON THE PROGRAM LAYER SAYS WHAT THE OLD RUNNER SAID, AND AN EDIT OF ONE CASE
# WORKS OUT THAT CASE ALONE. tools/program-suites/suited holds a spec whose cases pass but one,
# which is wrong on purpose, a lone case in no group, a program test and a test run as a child:
#   `avra test` of it, cold — its exit `suited.exit` and its stdout `suited.expected`, byte for byte,
#     the failing case's sides and the runner's verdict included: the old runner's last word on it,
#     frozen at cbc437f4 before its deletion;
#   then one `then` body edited and the suite tested warm: exactly one case lowered again, and the
#     same stdout as the edited tree tested cold.
#   sh tools/witness_program_suites.sh [compiler]   (default build/avra-try)
. "$(dirname "$0")/lib/scratch.sh"
set -u
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
# the runner's words on a failing case depend on whether every suite runs on past it: every one does,
# as the gate runs them, and suited.expected says the runner's words under it
export AVRA_SUITE_ALL=1
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_suites: no compiler at $avra" >&2; exit 1; }
scratch_dir tmp
failed=0
missed() { echo "witness_program_suites: $1" >&2; failed=$((failed + 1)); }

# `avra test suited` in the copy $2 — a fresh one with no store, `edited.av` standing as the edited
# file where $3 is `edited`, or the copy as it stands where $3 is `warm`: its stdout said with the
# copy's path as <w>, its exit, its stderr
tested() {
    if [ "${3:-}" != warm ]; then
        find "$tmp/$2" "$tmp/$2.machine" -depth -delete 2>/dev/null
        mkdir -p "$tmp/$2" "$tmp/$2.machine"
        cp -R "$root/tools/program-suites/suited" "$tmp/$2/"
        [ "${3:-}" = edited ] && cp "$tmp/edited.av" "$tmp/$2/$edited"
    fi
    (cd "$tmp/$2" && AVRA_CACHE_DIR="$tmp/$2.machine" AVRA_QUERY_TIMES=1 "$avra" test suited >"$tmp/$2.out" 2>"$tmp/$2.err"
        echo $? >"$tmp/$2.code")
    sed "s#$tmp/$2#<w>#g" "$tmp/$2.out" >"$tmp/$2.said"
}

edited=suited/src/tests/twice_test.av
tested 1 new
suites="$root/tools/program-suites"
[ "$(cat "$suites/suited.exit")" = "$(cat "$tmp/new.code")" ] || missed "the old runner exited $(cat "$suites/suited.exit"), the program layer $(cat "$tmp/new.code")"
cmp -s "$suites/suited.expected" "$tmp/new.said" || { missed "the program layer says otherwise than the old runner did"; diff "$suites/suited.expected" "$tmp/new.said" >&2; }
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

# A SUITE SAYS THE REFUSAL THE LAWS FOUND IN WHAT ITS CASES REACH, AS A RUN OF THEM DOES, NEVER A
# GAP OF THE LAYER IN ITS PLACE: tools/program-suites/lib_refused's library chains `?.` onto a
# `Result`, which a law refuses; `avra test` and `avra run` of it, each cold on the program layer,
# exit 1 saying the same words.
said_by() {
    find "$tmp/lr-$1" "$tmp/lr-$1.machine" -depth -delete 2>/dev/null
    mkdir -p "$tmp/lr-$1" "$tmp/lr-$1.machine"
    cp -R "$root/tools/program-suites/lib_refused" "$tmp/lr-$1/"
    (cd "$tmp/lr-$1" && AVRA_CACHE_DIR="$tmp/lr-$1.machine" AVRA_PROGRAM=1 "$avra" "$1" lib_refused >"$tmp/lr-$1.out" 2>&1
        echo $? >"$tmp/lr-$1.code")
    sed "s#$tmp/lr-$1#<w>#g" "$tmp/lr-$1.out" | grep -v '^watch:' >"$tmp/lr-$1.said"
}
said_by test
said_by run
[ "$(cat "$tmp/lr-test.code")" = 1 ] || missed "a suite whose library a law refuses exits $(cat "$tmp/lr-test.code"), not 1"
grep -q 'error\[type.chain\]' "$tmp/lr-test.said" || { missed "a suite whose library a law refuses does not say the law's refusal"; cat "$tmp/lr-test.said" >&2; }
cmp -s "$tmp/lr-test.said" "$tmp/lr-run.said" || { missed "the suite says otherwise than a run of it"; diff "$tmp/lr-run.said" "$tmp/lr-test.said" >&2; }

[ "$failed" = 0 ] && echo "witness_program_suites: the old runner's words on the program layer; one case edited, one case lowered again; a refused library said as a run says it"
[ "$failed" = 0 ]
