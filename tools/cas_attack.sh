#!/bin/sh
# THE SHARED CONTENT STORE, ATTACKED ACROSS PROCESSES (DB 11). Two store roots under one
# AVRA_CACHE_DIR keep the same 5 MB value: the shared store holds ONE blob, both roots are
# registered as its readers, and a second process reads the value back. A deleted blob is a
# MISS, never an error, and the next keep puts it back. `avra cache gc` frees a blob no live
# store names and keeps one that is named. Every phase is a process of its own, and a phase
# that asserts nothing would pass vacuously, so the script first holds the assertion to a
# phase that must FAIL (the miss phase while the blob stands).
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
T=packages/std-avrac/src/compiler/tests/cas_phase_test.av
D="$(pwd)/build/cas-attack"; fails=0; steps=0
[ -d "$D" ] && find "$D" -depth -delete
mkdir -p "$D/stores"
export AVRA_CACHE_DIR="$D/cache" AVRA_CAS_DIR="$D/stores"
say() { steps=$((steps + 1)); echo "cas-attack: $1"; }
fail() { fails=$((fails + 1)); echo "cas-attack: FAILED — $1"; }
phase() { AVRA_CAS_PHASE=$1 AVRA_CLOCK=real build/avra test $T 2>&1; }
# the 5 MB value's blob, and the registrations of its two roots: the build's own store may share too
blobs() { find "$D/cache/cas" -mindepth 2 -maxdepth 2 -type f -size 5242880c 2>/dev/null | wc -l | tr -d ' '; }
readers() { grep -l -F "$D/stores/" "$D"/cache/cas/stores/* 2>/dev/null | wc -l | tr -d ' '; }

phase put | grep -q "1/1 tests passed" && say "two roots kept the value" || fail "the put phase did not pass"
[ "$(blobs)" = 1 ] && say "the shared store holds ONE 5 MB blob" || fail "the shared store holds $(blobs) blobs, not one"
[ "$(readers)" = 2 ] && say "both roots are registered as readers" || fail "$(readers) readers registered, not two"
phase read | grep -q "1/1 tests passed" && say "a second process reads the value back" || fail "the value did not read back"
phase miss | grep -q "1/1 tests passed" && fail "the miss phase passed while the blob stands: the assertion examines nothing" || say "the miss phase fails while the blob stands"
out=$(build/avra cache gc 2>&1); echo "$out" | grep -q "freed 0 blob" && say "gc keeps a blob a live store names" || fail "gc freed a named blob: $out"
[ "$(blobs)" = 1 ] || fail "gc left $(blobs) blobs"
find "$D/cache/cas" -mindepth 2 -maxdepth 2 -type f -size 5242880c -delete
phase miss | grep -q "1/1 tests passed" && say "a deleted blob is a miss, never an error" || fail "a deleted blob was not a miss"
phase again | grep -q "1/1 tests passed" && say "the next keep puts the blob back" || fail "the blob was not put back"
[ "$(blobs)" = 1 ] && say "one blob again" || fail "$(blobs) blobs after the keep"
find "$D/stores" -depth -delete
mkdir -p "$D/stores"
out=$(build/avra cache gc 2>&1); echo "$out" | grep -q "freed 1 blob" && say "gc frees a blob no live store names" || fail "gc did not free the orphan: $out"
[ "$(blobs)" = 0 ] && say "no blob stands" || fail "$(blobs) blobs after the sweep"
[ $fails -eq 0 ] || { echo "cas-attack: $fails of $steps FAILED"; exit 1; }
echo "cas-attack: $steps steps passed"
