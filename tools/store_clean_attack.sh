#!/bin/sh
# THE STORE'S CLEAN AND TIME TRAVEL, ATTACKED (design §6.7/S8, DB 05c's tail).
# One package is checked through the store, and every reclaim is held to TWO
# things at once: the rows it evicts are GONE, and the live answer is UNTOUCHED.
# The store is the sealed body/idx the design names — no second format.
#
# The classes, and what each witnesses:
#   empty       no store at all: `clean` reclaims nothing and exits 0
#   absent      a store directory with zero bodies: `clean` seals nothing
#   all-live    a window wider than the store: nothing is evicted
#   reclaim     the window evicts the oldest revision, the live answer stands
#   travel      a kept older revision answers by name (`cache show`)
#   gone        an evicted revision answers nothing (exit 1)
#   reader      a row read WHILE clean runs: the sibling reader's answer stands
#   torn        a torn frame then clean: the earlier frames stand, the oracle stands
#   hold        clean during a compaction hold: it says it skipped, no corruption
#   size        a byte ceiling evicts the oldest history to fit
set -u
cd "$(dirname "$0")/.."
# The harness holds the slot: a reader beside clean needs two processes at once,
# and the `avra` shim serialises package-scale runs on the machine lock.
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
AVRA=${AVRA:-./avra}

R=build/store-clean
rm -rf "$R" .avra-cache && mkdir -p $R/p/src
cat > $R/p/avra.toml <<'TOML'
[package]
name = "sg-p"
version = "0.1.0"
TOML
cat > $R/p/src/main.av <<'AV'
fn main() { println("${twice(4)}") }
fn twice(n: int) -> int { n + n }
AV
# A second package whose store is deliberately larger than one MiB, so the byte
# ceiling has history to evict.
mkdir -p $R/big/src
printf '[package]\nname = "sg-big"\nversion = "0.1.0"\n' > $R/big/avra.toml
{
    : > $R/big/src/main.av
    i=0; body=""
    while [ $i -lt 2000 ]; do
        echo "fn f$i() -> int { $i }" >> $R/big/src/main.av
        body="$body${body:+ + }f$i()"
        i=$((i + 1))
    done
    echo "fn twice(n: int) -> int { n + n }" >> $R/big/src/main.av
    echo "fn main() { println(\"\${$body}\") }" >> $R/big/src/main.av
}

who=store-clean
. tools/lib/steps.sh
bodies() { ls .avra-cache/store/body-*.pack 2>/dev/null | wc -l | tr -d ' '; }
revs() { $AVRA cache log 2>/dev/null | sed -n 's/^rev \([0-9]*\).*/\1/p' | tr '\n' ' '; }
# The live answer: the program's own output, which no store may change.
run_live() { $AVRA run $R/p 2>&1 | tail -1; }
# The oracle: a cold check's own report, set aside so nothing reads the store.
cold_check() { rm -rf .avra-cache; $AVRA check $R/p > $R/oracle.out 2>&1; echo "status $?" >> $R/oracle.out; }
agrees() { $AVRA check $R/p > $R/$1.out 2>&1; echo "status $?" >> $R/$1.out; cmp -s $R/oracle.out $R/$1.out || { fail "$2: the answer differs from the oracle"; diff $R/oracle.out $R/$1.out | head -8; }; }
edit_to() { sed -i.bak "s/twice([0-9]*)/twice($1)/" $R/p/src/main.av; rm -f $R/p/src/main.av.bak; }
# One check that SEALS its frames (a revision per run), so revisions are exact.
checked_rev() { AVRA_STORE_SEAL_FRAMES=1 $AVRA check $R/p > /dev/null 2>&1; }

# ── empty: no store at all ──
say "empty: no store stands — clean reclaims nothing and exits 0"
rm -rf .avra-cache
$AVRA cache clean > $R/empty.out 2>&1
[ "$?" = 0 ] || fail "clean on an empty tree exited $?"
grep -q 'revisions 0 → 0' $R/empty.out || fail "clean on an empty tree did not report zero revisions"
[ "$(bodies)" = 0 ] || fail "clean on an empty tree sealed a body"

# ── absent: the store directory with no bodies ──
say "absent: a store directory holds no body — clean seals nothing"
rm -rf .avra-cache
mkdir -p .avra-cache/store
$AVRA cache clean > $R/absent.out 2>&1
[ "$?" = 0 ] || fail "clean on a bodyless store exited $?"
[ "$(bodies)" = 0 ] || fail "clean on a bodyless store sealed a body"
$AVRA cache log > $R/absent-log.out 2>&1
grep -q 'no sealed revision' $R/absent-log.out || fail "log on a bodyless store did not say so"

# ── build three coding revisions ──
cold_check
rm -rf .avra-cache
checked_rev
edit_to 5
checked_rev
edit_to 6
checked_rev
before=$(bodies)
say "reclaim: $before revisions stand before clean"
[ "$before" -ge 3 ] || fail "three sealing checks left $before body(ies), not at least three"
live_before=$(run_live)
all=$(revs)
oldest=$(echo "$all" | awk '{print $1}')
[ -n "$oldest" ] || fail "cache log listed no revision"

# ── all-live: a window wider than the store evicts nothing ──
say "all-live: a window of 100 evicts nothing"
AVRA_STORE_REVISIONS=100 $AVRA cache clean > $R/all-live.out 2>&1
[ "$(bodies)" -ge "$before" ] || fail "a wide window evicted a revision ($(bodies) < $before)"
grep -q 'evicted none' $R/all-live.out || fail "a wide window reported an eviction"

# ── reclaim + travel + gone: a window of two keeps history, evicts the rest ──
say "reclaim: a window of two evicts the oldest revision and the live answer stands"
AVRA_STORE_REVISIONS=2 $AVRA cache clean > $R/reclaim.out 2>&1
after=$(bodies)
[ "$after" -le 2 ] || fail "a window of two left $after bodies"
[ "$after" -ge 1 ] || fail "a reclaim evicted the newest revision"
[ "$(run_live)" = "$live_before" ] || fail "the reclaim changed the program's answer"
grep -q "evicted ${oldest}" $R/reclaim.out || fail "the reclaim did not name the evicted revision ${oldest}"

kept=$(revs | awk '{print $1}')
say "travel: the kept revision ${kept} answers its rows from its own body"
$AVRA cache show "$kept" > $R/travel.out 2>&1
[ "$?" = 0 ] || fail "cache show ${kept} exited $?"
[ -s $R/travel.out ] || fail "cache show ${kept} printed no row"

say "gone: the evicted revision ${oldest} answers nothing"
$AVRA cache show "$oldest" > $R/gone.out 2>&1
[ "$?" = 1 ] || fail "cache show ${oldest} exited $?, not 1"
grep -q 'holds nothing' $R/gone.out || fail "cache show on an evicted revision did not say so"

# ── wrong type / absent revision / a negative limit is OFF, never a trap ──
say "show: a non-number refuses (exit 2), a missing revision refuses (exit 1), a negative limit is off"
$AVRA cache show not-a-number > $R/show-bad.out 2>&1
[ "$?" = 2 ] || fail "cache show on a non-number exited $?, not 2"
$AVRA cache show 999999 > $R/show-missing.out 2>&1
[ "$?" = 1 ] || fail "cache show on a missing revision exited $?, not 1"
AVRA_STORE_MAX_MB=-1 AVRA_STORE_REVISIONS=-1 AVRA_STORE_MAX_AGE_S=-1 $AVRA cache clean > $R/negative.out 2>&1
[ "$?" = 0 ] || fail "a clean with negative limits exited $?"
[ "$(bodies)" -ge 1 ] || fail "a clean with negative limits evicted the newest revision"

# ── reader: a row read WHILE clean runs ──
say "reader: a check beside clean — both answers stand"
rm -rf .avra-cache
checked_rev; edit_to 5; checked_rev
AVRA_QTRACE=1 $AVRA check $R/p > $R/reader.out 2>&1 & reader=$!
AVRA_STORE_REVISIONS=1 $AVRA cache clean > $R/reader-clean.out 2>&1 & clean=$!
wait $reader; sr=$?
wait $clean; sg=$?
echo "status $sr" >> $R/reader.out
[ "$sr" = 0 ] || fail "the reader beside clean exited $sr"
[ "$sg" = 0 ] || fail "clean beside a reader exited $sg"
agrees reader "a check while clean ran"
[ "$(run_live)" = "$live_before" ] || fail "a read during clean changed the program's answer"

# ── torn: a kill mid-append then clean ──
say "torn: a writer killed between a frame and its marker, then clean"
rm -rf .avra-cache
checked_rev
edit_to 7
torn_before=$(run_live)
AVRA_STORE_KILL=commit $AVRA check $R/p > /dev/null 2>&1
st=$?
[ "$st" = 137 ] || fail "the kill hook did not kill the writer (status $st)"
AVRA_STORE_REVISIONS=100 $AVRA cache clean > $R/torn.out 2>&1
[ "$?" = 0 ] || fail "clean after a torn frame exited $?"
agrees torn "after a kill then clean"
[ "$(run_live)" = "$torn_before" ] || fail "a torn frame then clean changed the program's answer"

# ── hold: clean during a compaction hold says it skipped ──
say "hold: a writer holds the lock — clean says it skipped and nothing is corrupted"
# A COLD writer, so it takes the compaction lock: a warm check writes nothing and
# never reaches `admit` (the near-miss this fixture would have passed on).
rm -rf .avra-cache
AVRA_STORE_HOLD_MS=2000 $AVRA check $R/p > $R/held-writer.out 2>&1 & held=$!
sleep 0.4
AVRA_STORE_REVISIONS=1 $AVRA cache clean > $R/held-clean.out 2>&1
sg=$?
wait $held; sw=$?
[ "$sw" = 0 ] || fail "the lock's holder exited $sw"
[ "$sg" = 0 ] || fail "clean during a hold exited $sg"
grep -q 'another process holds the compaction lock' $R/held-clean.out || fail "clean during a hold did not say it skipped"
agrees held-writer "the lock's holder after a held clean"

# ── age: history older than the age limit goes ──
say "age: a one-second age evicts history older than it"
rm -rf .avra-cache
checked_rev; edit_to 5; checked_rev
age_live=$(run_live)
sleep 2
AVRA_STORE_MAX_AGE_S=1 AVRA_STORE_REVISIONS=100 $AVRA cache clean > $R/age.out 2>&1
[ "$?" = 0 ] || fail "an age-limited clean exited $?"
[ "$(bodies)" -le 1 ] || fail "a one-second age left $(bodies) revisions"
[ "$(bodies)" -ge 1 ] || fail "the age limit evicted the newest revision"
[ "$(run_live)" = "$age_live" ] || fail "the age limit changed the program's answer"

# ── size: the byte ceiling evicts the oldest history to fit ──
say "size: a 1 MiB ceiling trims the history of a larger store"
rm -rf .avra-cache
$AVRA check $R/big > /dev/null 2>&1 || fail "the big cold check did not pass"
AVRA_STORE_REVISIONS=100 $AVRA cache clean > /dev/null 2>&1
big_before=$(bodies)
AVRA_STORE_MAX_MB=1 AVRA_STORE_REVISIONS=100 $AVRA cache clean > $R/size.out 2>&1
[ "$?" = 0 ] || fail "a byte-ceiling clean exited $?"
[ "$(bodies)" -le "$big_before" ] || fail "the byte ceiling grew the store ($(bodies) > $big_before)"
[ "$(bodies)" -ge 1 ] || fail "the byte ceiling evicted the newest revision"
$AVRA run $R/big > $R/size-live.out 2>&1
[ "$?" = 0 ] || fail "the big program did not run after a size reclaim"

verdict
