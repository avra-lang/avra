#!/bin/sh
# THE STORE, ATTACKED (DB 05). One package is checked through the store and
# every answer is held to the ORACLE — the same check over no store at all.
# Each attack breaks the store a different way, and a run that answers
# differently from the oracle, or fails to say what it saw, is a failure.
#
# The store is a DIRECTORY (design §6.1), one per TREE for every compiler (S2):
#   .avra-cache/store/body-<rev>.pack   SEALED (stage 2; stage 1 writes it empty)
#   .avra-cache/store/body-<rev>.idx    the sealed body's index
#   .avra-cache/store/seg-<writer>.log  LIVE TAIL, one per writer process (S7)
#   .avra-cache/store/lock              flock, taken by compaction only
# beside `.avra-cache/obj/` and `.avra-cache/bin/`, which stay files.
#
# What the store says, under AVRA_QTRACE, and what each attack reads:
#   Q store open <path>      the store mapped — once per process
#   Q store skipped <why>    a process that did not take the compaction lock
#   Q store torn <offset>    a tail that failed its check, ignored from there
#   Q store foreign          a segment written under another pack format
#   Q store hit|miss <family>  a lookup of one row, by the family it asked
#   Q db hit|miss <kind>       a durable DbRow recalled, by its kind
# and two hooks: AVRA_STORE_KILL=commit kills the writer after a segment's
# frame octets and before its commit marker; AVRA_STORE_HOLD_MS=n holds the
# compaction lock n ms before appending.
#
# §6.8 maps its eight attacks here; a check that changes names the row it still
# enforces, and a row stage 1 cannot satisfy FAILS by name rather than passing
# vacuously:
#   one store · one open · kill mid-append · two writers · compaction contended ·
#   a flipped byte · another compiler · a claim conflict
set -u
cd "$(dirname "$0")/.."
# THE HARNESS HOLDS THE SLOT: two writers and a contended compaction need two
# processes AT ONCE, and the `avra` shim serialises package-scale runs on the
# machine lock. `AVRA_WATCH_HELD` tells the shim this harness is the slot —
# the same door `tools/store_baseline.sh` and `tools/cache_attacks.sh` use.
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0

R=build/store-attacks
rm -rf "$R" .avra-cache && mkdir -p $R/p/src
cat > $R/p/avra.toml <<'TOML'
[package]
name = "sa-p"
version = "0.1.0"
TOML
cat > $R/p/src/main.av <<'AV'
use more.{helper}

fn twice(n: int) -> int {
    n ?? 3
}

fn main() {
    println("${twice(helper())}")
}
AV
cat > $R/p/src/more.av <<'AV'
export fn helper() -> int { 4 }
AV

who=store-attacks
. tools/lib/steps.sh

# A run's own words: no trace, and none of the shim's — its `watch:` reports
# and the warning a shell with no terminal prints for job control.
words() { grep -v -e '^Q	' -e '^watch:' -e 'job control turned off' "$1"; }
# A check's words and status, the trace set aside.
checked() { AVRA_QTRACE=1 ./avra check $R/p > $R/$1.out 2> $R/$1.err; echo "status $?" >> $R/$1.out; words $R/$1.err >> $R/$1.out; grep '^Q	' $R/$1.err > $R/$1.trace; }
# Lines of one store event in a run's trace.
heard() { grep -c "^Q	store	$2" $R/$1.trace; }
agrees() { cmp -s $R/oracle.out $R/$1.out || { fail "$2: the answer differs from the oracle"; diff $R/oracle.out $R/$1.out | head -10; }; }
# THE STORE, under `.avra-cache/` — one directory, not one per compiler.
the_store() { echo .avra-cache/store; }
segment() { ls "$(the_store)"/seg-*.log 2>/dev/null | head -1; }
body() { ls "$(the_store)"/body-*.pack 2>/dev/null | head -1; }

# THE ORACLE: a cold check, then the store set aside so nothing else reads it.
checked oracle
rm -rf .avra-cache

# ── §6.8 one store ──
say "§6.8 one store: a cold check leaves .avra-cache/{store,obj,bin} and nothing else"
checked cold
agrees cold "cold"
extra=$(ls .avra-cache | grep -v -x -e store -e obj -e bin | tr '\n' ' ')
[ -z "$extra" ] || fail "the cache holds more than store, obj and bin: $extra"
[ -d "$(the_store)" ] || fail "no store directory under .avra-cache"
[ -f "$(the_store)/lock" ] || fail "the store has no lock file"

# ── §6.8 one open ──
say "§6.8 one open: a warm no-op check derives nothing and opens the store once"
checked warm
agrees warm "warm"
[ "$(grep -c '^Q	attempt' $R/warm.trace)" = 0 ] || fail "a warm no-op check derived again"
[ "$(heard warm open)" = 1 ] || fail "a warm no-op check opened the store $(heard warm open) times, not once"

# ── S5 validity (the oracle's own edit corpus, not a §6.8 row) ──
say "S5 validity: a warm check sees an edit through the store"
sed -i.bak 's/{ 4 }/{ 5 }/' $R/p/src/more.av
checked edited
grep -q 'never fires' $R/edited.out || fail "the edited check lost the warning"
[ "$(grep -c '^Q	attempt' $R/edited.trace)" -gt 0 ] || fail "an edited check derived nothing"
mv $R/p/src/more.av.bak $R/p/src/more.av

# ── §6.8 kill mid-append ──
say "§6.8 kill mid-append: a writer killed between a frame and its marker leaves every earlier frame"
rm -rf .avra-cache
checked cold2
sed -i.bak 's/{ 4 }/{ 6 }/' $R/p/src/more.av
AVRA_STORE_KILL=commit ./avra check $R/p > /dev/null 2>&1
st=$?
[ "$st" = 137 ] || fail "the kill hook did not kill the writer (status $st)"
mv $R/p/src/more.av.bak $R/p/src/more.av
checked after_kill
agrees after_kill "after a kill"
[ "$(heard after_kill torn)" = 1 ] || fail "the torn frame was not seen ($(heard after_kill torn) lines)"
checked after_kill2
agrees after_kill2 "two runs after a kill"
[ "$(heard after_kill2 torn)" = 0 ] || fail "the torn frame is still there a run later"

# ── §6.8 two writers ──
# The design (S7) gives each writer its OWN segment and no lock; the flock is
# compaction's alone. Both must stand, and the next reader merges both.
say "§6.8 two writers: two checks at once both answer the oracle, and both their segments stand"
rm -rf .avra-cache
# The first writer holds the compaction lock long enough that the second opens
# while it is still deriving, so both write — each to its own segment (S7).
AVRA_STORE_HOLD_MS=2000 AVRA_QTRACE=1 ./avra check $R/p > $R/w1.out 2> $R/w1.err & p1=$!
sleep 1
AVRA_QTRACE=1 ./avra check $R/p > $R/w2.out 2> $R/w2.err & p2=$!
wait $p1; s1=$?
wait $p2; s2=$?
echo "status $s1" >> $R/w1.out; words $R/w1.err >> $R/w1.out; grep '^Q	' $R/w1.err > $R/w1.trace
echo "status $s2" >> $R/w2.out; words $R/w2.err >> $R/w2.out; grep '^Q	' $R/w2.err > $R/w2.trace
agrees w1 "the first writer"
agrees w2 "the second writer"
segs=$(ls "$(the_store)"/seg-*.log 2>/dev/null | wc -l | tr -d ' ')
[ "$segs" = 2 ] || fail "two writers left $segs segment(s), not two"

# ── §6.8 compaction contended ──
say "§6.8 compaction contended: the process without the lock says it did not compact, and both answer the oracle"
rm -rf .avra-cache
AVRA_STORE_HOLD_MS=3000 AVRA_QTRACE=1 ./avra check $R/p > $R/c1.out 2> $R/c1.err & held=$!
sleep 1
checked c2
wait $held; s=$?
echo "status $s" >> $R/c1.out; words $R/c1.err >> $R/c1.out; grep '^Q	' $R/c1.err > $R/c1.trace
agrees c1 "the lock's holder"
agrees c2 "the run refused the lock"
[ "$(heard c2 skipped)" = 1 ] || fail "the run without the lock did not say it skipped"
[ "$(heard c1 skipped)" = 0 ] || fail "the lock's holder skipped"
checked after_two
agrees after_two "after two at once"
[ "$(grep -c '^Q	attempt' $R/after_two.trace)" = 0 ] || fail "the holder's save did not stand"

# ── §6.8 a flipped byte ──
# In the last frame of a LIVE SEGMENT, and in the middle of a SEALED BODY. The
# tail's own commit marker is what makes a flip tear; a body is read at open.
say "§6.8 a flipped byte: one in a live segment's last frame, one in a sealed body — each seen as torn, never read"
rm -rf .avra-cache
checked flip_seed
seg="$(segment)"
[ -f "$seg" ] || fail "no segment to flip"
if [ -f "$seg" ]; then
    python3 -I - "$seg" <<'PY'
import sys
p = sys.argv[1]
b = bytearray(open(p, "rb").read())
b[len(b) - 1] ^= 0x01
open(p, "wb").write(bytes(b))
PY
    checked flip_last
    agrees flip_last "a flipped byte in the last frame"
    [ "$(heard flip_last torn)" = 1 ] || fail "a flipped last byte was not seen as torn"
fi
bodyf="$(body)"
if [ -z "$bodyf" ] || [ ! -s "$bodyf" ]; then
    fail "§6.8 a flipped byte (middle of a body): stage 1 writes an empty body-*.pack — the mid-body flip is owed when compaction seals a body"
else
    python3 -I - "$bodyf" <<'PY'
import sys
p = sys.argv[1]
b = bytearray(open(p, "rb").read())
b[len(b) // 2] ^= 0x01
open(p, "wb").write(bytes(b))
PY
    checked flip_mid
    agrees flip_mid "a flipped byte in a body"
    [ "$(heard flip_mid torn)" = 1 ] || fail "a flipped body byte was not seen as torn"
fi

# ── §6.8 another compiler ──
# Two cases. A compiler whose print differs while its module-record producer, its codec and
# the toolchain do not (AVRA_INLINE_RUNTIME=0 moves the print alone) READS the first one's
# module records and answers as a cold compute does. A segment written under another pack
# FORMAT is never read, and the check recomputes. A producer, codec or toolchain part that
# moved is pinned where the stamp is folded (compiler/tests/store_test.av).
say "§6.8 another compiler, same producer: its module records are read, and the answer is the cold one"
rm -rf .avra-cache
checked share_seed
export AVRA_INLINE_RUNTIME=0
checked share
unset AVRA_INLINE_RUNTIME
agrees share "a second print with the same producer"
[ "$(grep -c '^Q	store	hit	sig' $R/share.trace)" -ge 1 ] || fail "the second compiler read none of the first one's module records"
[ "$(grep -c '^Q	store	hit	unit' $R/share.trace)" -le "$(grep -c '^Q	store	hit	unit' $R/share_seed.trace)" ] || fail "a compiler-keyed row crossed prints"

say "§6.8 another compiler, another format: a segment written under another pack format is never read, and the check recomputes"
rm -rf .avra-cache
checked foreign_seed
seg="$(segment)"
python3 -I - "$seg" <<'PY'
import sys
p = sys.argv[1]
b = open(p, "rb").read()

def varint(b, i):
    v, k = 0, 0
    while True:
        o = b[i]; i += 1
        v |= (o & 0x7F) << (7 * k); k += 1
        if o < 128:
            return v, i

i = 0
n, i = varint(b, i)
magic = b[i:i + n]; i += n
assert magic == b"AVRAPACK", magic
at = i
v, i = varint(b, i)
assert i == at + 1 and v < 63, (at, i, v)
open(p, "wb").write(b[:at] + bytes([(v + 2) & 127]) + b[i:])
PY
[ $? = 0 ] || fail "the segment's header does not carry a format to flip"
checked foreign
agrees foreign "a foreign format"
[ "$(heard foreign foreign)" -ge 1 ] || fail "a segment of another format was not refused"
[ "$(grep -c '^Q	attempt' $R/foreign.trace)" -gt 0 ] || fail "a store of another format was read as a hit"

say "§6.8 another compiler (a one-query rebuild recomputes that query only)"
# `stamp_of` gives each family ONE stamp: sig stands under its producer's code hashes, every
# other family under the compiler's own print (`own ${print}`). So a rebuild that moved one
# leaf re-keys every row of every other family at once — measured by tools/db06_step6_rebuild.sh:
# 0 store rows written by a warm check of an unchanged tree, 30,320 after one leaf of one query
# moved and the compiler was rebuilt. The row asks for a row keyed by the code hash of the
# query that ANSWERS it: S2 (§6.4), DB 05b's receipt — not DB 09, which is the settlement.
fail "the families are keyed per FAMILY (sig by its producer's code hashes, every other by the compiler's print), so a rebuild that changed one query rewrites the whole store — the per-query recompute is S2's, DB 05b's receipt"

say "§6.8 another compiler, another C: a compiler whose runtime C differs reads none of the first one's module records"
if sh tools/db06_step5_witness.sh > "$R/step5.log" 2>&1; then
    [ "$(tail -1 "$R/step5.log")" = PASS ] || fail "§6.8 another compiler, another C: the witness ended without its verdict"
else
    fail "§6.8 another compiler, another C: $(tail -1 "$R/step5.log")"
fi

# ── §6.8 a claim conflict ──
# Two segments with DIFFERENT content digests for THE SAME action key trigger
# the conflict detector. We hold the compaction lock externally while a second
# check writes its segment, preventing the first segment from being retired.
# A third check then scans both and sees the conflict.
say "§6.8 claim conflict: two values for one key are reported, naming both digests and their writers (S7)"
rm -rf .avra-cache
checked seed_a
# Hold the lock externally so the next check skips compaction
python3 -I - "$(the_store)" "$R" <<'PY' &
import sys, os, fcntl, time
store_dir = sys.argv[1]
out_dir = sys.argv[2]
lock_path = os.path.join(store_dir, "lock")
fd = os.open(lock_path, os.O_RDWR | os.O_CREAT)
fcntl.flock(fd, fcntl.LOCK_EX)
# Record the fd path for cleanup (the shell gets the pid)
with open(os.path.join(out_dir, "lock_holder_pid"), "w") as f:
    f.write(str(os.getpid()))
time.sleep(5)
os.close(fd)
PY
lock_pid=$!
sleep 0.5
# With the lock held externally, this check cannot compact. It writes its segment
# and skips compaction, leaving seg-1 alive along with its own seg-2.
sed -i.bak 's/4/7/' $R/p/src/more.av
checked seed_b
mv $R/p/src/more.av.bak $R/p/src/more.av
wait $lock_pid
# Now both segments exist: seg-1 (original source) and seg-2 (modified source).
# A third check scans both and should detect the conflict.
checked cc_read
agrees cc_read "after a claim conflict"
[ "$(heard cc_read claim-conflict)" -ge 1 ] || fail "a claim conflict was not reported when two segments held different values for one key"

verdict
