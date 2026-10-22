#!/bin/sh
# A SAVED ANSWER'S READS, ATTACKED ACROSS PROCESSES (DB 06). Process A keeps an answer
# with the digest of an input it read and seals the store. Process B asks it back:
# a HIT while the input is as it was, a MISS once the input moved, a HIT again when the
# input is restored. Every phase is a process of its own over one directory, and a
# phase that asserts nothing would pass vacuously, so the script first holds the
# assertion to a phase that must FAIL (the answer asked as a miss while the input stands).
# The last phase prices `get_valid`: 10,000 calls, 3 reads each, over 70,000 records.
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
T=packages/std-avrac/src/compiler/tests/store_reads_process_test.av
D="$(pwd)/build/store-reads-attack"
rm -rf "$D" && mkdir -p "$D"
who=store-reads-attack
. tools/lib/steps.sh
phase() { AVRA_READS_PHASE=$1 AVRA_READS_DIR=$D AVRA_CLOCK=real build/avra test $T 2>&1; }

printf 'v1' > "$D/input"
phase keep | grep -q "1/1 tests passed" && say "kept and sealed" || fail "the keep phase did not pass"
ls "$D/store" | grep -q '^body-.*\.pack$' && say "the answer stands in a sealed body" || fail "no sealed body"
phase hit | grep -q "1/1 tests passed" && say "input unmoved: HIT in a second process" || fail "an answer whose input did not move missed"
phase miss | grep -q "1/1 tests passed" && fail "the miss phase passed while the input stands: the assertion examines nothing" || say "the miss phase fails while the input stands"
printf 'v2' > "$D/input"
phase miss | grep -q "1/1 tests passed" && say "input moved: MISS, the bytes still there" || fail "an answer whose input moved was served"
phase hit | grep -q "1/1 tests passed" && fail "an answer whose input moved was a hit" || say "input moved: the hit phase fails"
printf 'v1' > "$D/input"
phase hit | grep -q "1/1 tests passed" && say "input restored: HIT again" || fail "a restored input did not hit"
rm -rf "$D/store"
phase fill | grep -q "1/1 tests passed" || fail "70,000 records were not kept"
out=$(phase cost); echo "$out" | grep "store-reads:"
echo "$out" | grep -q "1/1 tests passed" && say "priced" || fail "the cost phase did not pass"
verdict
