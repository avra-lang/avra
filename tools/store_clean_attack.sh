#!/bin/sh
# THE STORE'S CLEAN, ATTACKED: `avra cache` over the program layer's store of one
# package — a directory of immutable packs. Every clean is held to TWO things at
# once: the store is no bigger for it, and the live answer is UNTOUCHED.
#
# The classes, and what each witnesses:
#   empty       no store at all: `clean` compacts nothing and exits 0, `log` lists no pack
#   listed      a checked package: `log` lists its packs, `show` names the questions one answers
#   gone        a number no pack wears answers nothing (exit 1); a word that is no number, exit 2
#   compact     packs from several edits fold: no more packs than before, the answer stands
#   warm        the check after a clean reads its answers from the pack the clean wrote
#   reader      a check run WHILE clean runs: the reader's answer stands
set -u
. "$(dirname "$0")/lib/attack.sh"
AVRA=${AVRA:-./avra}

R=build/store-clean
rm -rf "$R" && mkdir -p $R/p/src
own_store $R
cat > $R/p/avra.toml <<'TOML'
[package]
name = "sg-p"
version = "0.1.0"
TOML
cat > $R/p/src/main.av <<'AV'
fn main() { println("${twice(4)}") }
fn twice(n: int) -> int { n + n }
main()
AV

who=store-clean
. tools/lib/steps.sh
store=$R/p/.avra-cache/tapes
packs() { ls $store/pack-*.pack 2>/dev/null | wc -l | tr -d ' '; }
bytes() { cat $store/pack-*.pack 2>/dev/null | wc -c | tr -d ' '; }
# `avra cache` answers for the package it stands in.
case "$AVRA" in /*) avra_at=$AVRA ;; *) avra_at=$PWD/$AVRA ;; esac
cache() { (cd $R/p && "$avra_at" cache "$@"); }
# The oracle: a cold check's own report, set aside so nothing reads the store.
cold_check() { rm -rf $R/p/.avra-cache; $AVRA check $R/p > $R/oracle.out 2>&1; echo "status $?" >> $R/oracle.out; }
agrees() { $AVRA check $R/p > $R/$1.out 2>&1; echo "status $?" >> $R/$1.out; cmp -s $R/oracle.out $R/$1.out || { fail "$2: the answer differs from the oracle"; diff $R/oracle.out $R/$1.out | head -8; }; }
edit_to() { sed -i.bak "s/twice([0-9]*)/twice($1)/" $R/p/src/main.av; rm -f $R/p/src/main.av.bak; }

# ── empty: no store at all ──
say "empty: no store stands — clean compacts nothing and exits 0"
rm -rf $R/p/.avra-cache
cache clean > $R/empty.out 2>&1
[ "$?" = 0 ] || fail "clean of no store exited $?"
grep -q 'packs 0 → 0' $R/empty.out || fail "clean of no store did not say it held no pack: $(cat $R/empty.out)"
cache log > $R/empty-log.out 2>&1
grep -q 'no pack' $R/empty-log.out || fail "log of no store listed a pack: $(cat $R/empty-log.out)"

# ── listed: a checked package ──
say "listed: log lists the packs a check wrote, show names what one answers"
cold_check
[ "$(packs)" -ge 1 ] || fail "a check wrote no pack"
cache log > $R/log.out 2>&1
[ "$(grep -c '^pack ' $R/log.out)" = "$(packs)" ] || fail "log lists $(grep -c '^pack ' $R/log.out) packs, the store holds $(packs)"
cache show 1 > $R/show.out 2>&1
[ "$?" = 0 ] || fail "show 1 exited $?"
grep -q '^source_text' $R/show.out || fail "show 1 names no source_text question"

# ── gone: no such pack ──
say "gone: a number no pack wears answers nothing; a word that is no number is refused"
cache show 99 > $R/gone.out 2>&1
[ "$?" = 1 ] || fail "show 99 exited $? (want 1)"
cache show nope > $R/bad.out 2>&1
[ "$?" = 2 ] || fail "show nope exited $? (want 2)"

# ── compact: several edits' packs fold ──
say "compact: packs from several edits fold, the live answer stands"
for n in 5 6 7 8 9; do edit_to $n; $AVRA check $R/p > /dev/null 2>&1; done
edit_to 4
$AVRA check $R/p > /dev/null 2>&1
before_packs=$(packs); before_bytes=$(bytes)
cache clean > $R/compact.out 2>&1
[ "$?" = 0 ] || fail "clean exited $?"
[ "$(packs)" -le "$before_packs" ] || fail "clean grew the pack count ($(packs) > $before_packs)"
[ "$(packs)" -ge 1 ] || fail "clean left no pack"
[ "$(bytes)" -le "$before_bytes" ] || fail "clean grew the store ($(bytes) > $before_bytes bytes)"
agrees compact "compact"

# ── warm: the answers survive the clean ──
say "warm: the check after a clean computes nothing again"
$AVRA check $R/p --counts > $R/warm.out 2>&1
grep -q 'files_parsed=0 ' $R/warm.out || fail "the check after a clean parsed again: $(grep -i parsed $R/warm.out | head -2)"

# ── reader: a check beside the clean ──
say "reader: a check run while clean runs answers as the oracle does"
cache clean > $R/reader-clean.out 2>&1 &
agrees reader "reader"
wait
agrees after-reader "after the clean beside a reader"

verdict
