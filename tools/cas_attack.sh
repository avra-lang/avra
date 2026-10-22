#!/bin/sh
# THE SHARED CONTENT STORE, ATTACKED ACROSS PROCESSES (DB 11). Two store roots under one
# AVRA_CACHE_DIR keep the same 5 MB value: the shared store holds ONE blob, both roots are
# registered as its readers, and a second process reads the value back. A deleted blob is a
# MISS, never an error, and the next keep puts it back. `avra cache clean` sweeps the shared
# store: it frees a blob no live store names and keeps one that is named. A blob removed under
# a live reader is a miss too. Every phase is a process of its own, and a phase
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
out=$(build/avra cache clean 2>&1); echo "$out" | grep -q "shared store kept .* freed 0 blob" && say "clean keeps a blob a live store names" || fail "clean freed a named blob: $out"
[ "$(blobs)" = 1 ] || fail "clean left $(blobs) blobs"
find "$D/cache/cas" -mindepth 2 -maxdepth 2 -type f -size 5242880c -delete
phase miss | grep -q "1/1 tests passed" && say "a deleted blob is a miss, never an error" || fail "a deleted blob was not a miss"
phase again | grep -q "1/1 tests passed" && say "the next keep puts the blob back" || fail "the blob was not put back"
[ "$(blobs)" = 1 ] && say "one blob again" || fail "$(blobs) blobs after the keep"
phase removed | grep -q "1/1 tests passed" && say "a blob removed under a live reader is a miss, never a wrong answer" || fail "a removed blob was not a miss"
phase again | grep -q "1/1 tests passed" || fail "the blob was not put back after the removal"
find "$D/stores" -depth -delete
mkdir -p "$D/stores"
out=$(build/avra cache clean 2>&1); echo "$out" | grep -q "shared store kept .* freed 1 blob" && say "clean frees a blob no live store names" || fail "clean did not free the orphan: $out"
[ "$(blobs)" = 0 ] && say "no blob stands" || fail "$(blobs) blobs after the sweep"
# A 5 MB file `embed`ded by two worktrees: the settled const names ONE blob between them.
E="$D/embed"; mkdir -p "$E"
# a program's answers are kept in the tree's own store by its source, so each run's programs differ
stamp="$$-$(date +%s)"
for w in a b; do
    mkdir -p "$E/$w/src"
    printf '[package]\nname = "embeds"\nversion = "0.1.0"\n' > "$E/$w/avra.toml"
    head -c 5242880 /dev/zero | tr '\0' 'x' > "$E/$w/src/big.txt"
    printf 'use @std.meta.{embed}\nconst A: string = embed("big.txt")\nprintln("${A.length}")\n// %s\n' "$stamp" > "$E/$w/src/main.av"
done
mkdir -p "$E/c/src"; cp "$E/a/avra.toml" "$E/c/avra.toml"; cp "$E/a/src/big.txt" "$E/c/src/big.txt"
printf 'use @std.meta.{embed}\nconst B: Bytes = embed("big.txt").bytes()\nprintln("${B.length}")\n// %s\n' "$stamp" > "$E/c/src/main.av"
built() { AVRA_CACHE_DIR="$E/cache" AVRA_CLOCK=real build/avra build "$E/$1" 2>&1 && "$E/$1/src/main"; }
[ "$(built a | tail -1)" = 5242880 ] && [ "$(built b | tail -1)" = 5242880 ] && say "both worktrees build the embedding program" || fail "an embedding program did not build"
n=$(find "$E/cache/cas" -mindepth 2 -maxdepth 2 -type f -size +1000k | wc -l | tr -d ' ')
[ "$n" = 1 ] && say "two worktrees' 5 MB embed is ONE blob" || fail "$n blobs over 1 MB for one embedded file"
[ "$(built a | tail -1)" = 5242880 ] && say "a warm build reads the embed back through the blob" || fail "the warm build did not answer"
find "$E/cache/cas" -mindepth 2 -maxdepth 2 -type f -size +1000k -delete
[ "$(built b | tail -1)" = 5242880 ] && say "an embed whose blob is gone is rebuilt, never wrong" || fail "a missing embed blob broke the build"
# The same file settled as `Bytes` in two worktrees: its octets are ONE blob.
cp -R "$E/c" "$E/d"
sized() { AVRA_CACHE_DIR="$E/cache2" AVRA_CLOCK=real build/avra build "$E/$1" 2>&1 && "$E/$1/src/main"; }
[ "$(sized c | tail -1)" = 5242880 ] && [ "$(sized d | tail -1)" = 5242880 ] && say "both worktrees build the Bytes program" || fail "a Bytes program did not build"
n=$(find "$E/cache2/cas" -mindepth 2 -maxdepth 2 -type f -size +1000k | wc -l | tr -d ' ')
[ "$n" = 1 ] && say "two worktrees' Bytes const is ONE blob of its octets" || fail "$n blobs over 1 MB for one Bytes const"
[ "$(sized c | tail -1)" = 5242880 ] && say "a warm build reads the octets back through the blob" || fail "the warm Bytes build did not answer"
[ $fails -eq 0 ] || { echo "cas-attack: $fails of $steps FAILED"; exit 1; }
echo "cas-attack: $steps steps passed"
