#!/bin/sh
# THE STORE, ATTACKED (DB 05). One package is checked through the store and
# every answer is held to the ORACLE — the same check over no store at all.
# Each attack breaks the store a different way, and a run that answers
# differently from the oracle, or fails to say what it saw, is a failure.
#
# What the store says, under AVRA_QTRACE, and what each attack reads:
#   Q store open <path>      the store mapped — once per process
#   Q store skipped <why>    a writer that did not get the lock saved nothing
#   Q store torn <offset>    a tail that failed its check, ignored from there
#   Q store foreign          a store whose header names another compiler
# and two hooks: AVRA_STORE_KILL=commit kills the writer after a segment's
# bytes and before its commit marker; AVRA_STORE_HOLD_MS=n holds the lock
# n ms before appending.
set -u
cd "$(dirname "$0")/.."

R=build/store-attacks; fails=0; steps=0
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

say() { steps=$((steps + 1)); echo "store-attacks: $1"; }
fail() { fails=$((fails + 1)); echo "store-attacks: FAILED — $1"; }

# A run's own words: no trace, and none of the shim's — its `watch:` reports
# and the warning a shell with no terminal prints for job control.
words() { grep -v -e '^Q	' -e '^watch:' -e 'job control turned off' "$1"; }
# A check's words and status, the trace set aside.
checked() { AVRA_QTRACE=1 ./avra check $R/p > $R/$1.out 2> $R/$1.err; echo "status $?" >> $R/$1.out; words $R/$1.err >> $R/$1.out; grep '^Q	' $R/$1.err > $R/$1.trace; }
# Lines of one store event in a run's trace.
heard() { grep -c "^Q	store	$2" $R/$1.trace; }
agrees() { cmp -s $R/oracle.out $R/$1.out || { fail "$2: the answer differs from the oracle"; diff $R/oracle.out $R/$1.out | head -10; }; }
the_store() { ls -d .avra-cache/*/ | head -1 | sed 's|/$||'; }

# THE ORACLE: a cold check, then the store set aside so nothing else reads it.
checked oracle
rm -rf .avra-cache

say "a cold check writes ONE store file beside obj/ and bin/"
checked cold
agrees cold "cold"
dir=$(the_store)
extra=$(ls "$dir" | grep -v -x -e store -e obj -e bin | tr '\n' ' ')
[ -z "$extra" ] || fail "the store directory holds more than store, obj and bin: $extra"
[ -f "$dir/store" ] || fail "no store file in $dir"

say "a warm no-op check derives nothing and opens the store once"
checked warm
agrees warm "warm"
[ "$(grep -c '^Q	attempt' $R/warm.trace)" = 0 ] || fail "a warm no-op check derived again"
[ "$(heard warm open)" = 1 ] || fail "a warm no-op check opened the store $(heard warm open) times, not once"

say "an edit is seen through the store"
sed -i.bak 's/{ 4 }/{ 5 }/' $R/p/src/more.av
checked edited
grep -q 'never fires' $R/edited.out || fail "the edited check lost the warning"
[ "$(grep -c '^Q	attempt' $R/edited.trace)" -gt 0 ] || fail "an edited check derived nothing"
mv $R/p/src/more.av.bak $R/p/src/more.av

say "a writer killed between a segment and its marker leaves the last whole state"
rm -rf .avra-cache
checked cold2
sed -i.bak 's/{ 4 }/{ 6 }/' $R/p/src/more.av
AVRA_STORE_KILL=commit ./avra check $R/p > /dev/null 2>&1
st=$?
[ "$st" = 137 ] || fail "the kill hook did not kill the writer (status $st)"
mv $R/p/src/more.av.bak $R/p/src/more.av
checked after_kill
agrees after_kill "after a kill"
[ "$(heard after_kill torn)" = 1 ] || fail "the torn tail was not seen ($(heard after_kill torn) lines)"
checked after_kill2
agrees after_kill2 "two runs after a kill"
[ "$(heard after_kill2 torn)" = 0 ] || fail "the torn tail is still there a run later"

say "two checks at once: both answer the oracle, and the one without the lock says it saved nothing"
rm -rf .avra-cache
AVRA_STORE_HOLD_MS=3000 AVRA_QTRACE=1 ./avra check $R/p > $R/first.out 2> $R/first.err &
held=$!
sleep 1
checked second
wait $held
echo "status $?" >> $R/first.out; words $R/first.err >> $R/first.out; grep '^Q	' $R/first.err > $R/first.trace
agrees first "the lock's holder"
agrees second "the run refused the lock"
[ "$(heard second skipped)" = 1 ] || fail "the run without the lock did not say it skipped saving"
[ "$(heard first skipped)" = 0 ] || fail "the lock's holder skipped saving"
checked after_two
agrees after_two "after two at once"
[ "$(grep -c '^Q	attempt' $R/after_two.trace)" = 0 ] || fail "the holder's save did not stand"

say "a flipped byte in the last segment is torn, never read"
for at in last middle; do
    rm -rf .avra-cache
    checked flip_seed
    store="$(the_store)/store"
    [ -f "$store" ] || { fail "no store to flip"; continue; }
    python3 -I - "$store" "$at" <<'PY'
import sys
p, at = sys.argv[1], sys.argv[2]
b = bytearray(open(p, "rb").read())
i = len(b) - 1 if at == "last" else len(b) // 2
b[i] ^= 0x01
open(p, "wb").write(bytes(b))
PY
    checked flip_$at
    agrees flip_$at "a flipped $at byte"
    [ "$(heard flip_$at torn)" = 1 ] || fail "a flipped $at byte was not seen as torn"
done

say "a store whose header names another compiler is never read"
rm -rf .avra-cache
checked foreign_seed
dir=$(the_store)
print=$(basename "$dir")
python3 -I - "$dir/store" "$print" <<'PY'
import sys
p, print_ = sys.argv[1], sys.argv[2].encode()
b = open(p, "rb").read()
if print_ not in b:
    sys.exit("the header does not carry the compiler print")
other = (b"9" if print_[:1] != b"9" else b"8") + print_[1:]
open(p, "wb").write(b.replace(print_, other, 1))
PY
[ $? = 0 ] || fail "the store's header does not repeat the compiler print"
checked foreign
agrees foreign "a foreign store"
[ "$(heard foreign foreign)" = 1 ] || fail "a foreign header was not refused"
[ "$(grep -c '^Q	attempt' $R/foreign.trace)" -gt 0 ] || fail "a foreign store was read as a hit"

echo "store-attacks: $steps attack(s), $fails failure(s)"
[ "$fails" = 0 ]
