#!/bin/sh
# THE SEALED STORE, ATTACKED. Four invariants of store/pack.av and store/body.av,
# each proved by a run whose answer is held to the program's own output:
#   a write seals once SEAL_FRAMES frames are in segments: a large cold check
#   writes a body-<rev>.pack beside its .val, and a warm check after it seals nothing;
#   an open reads only the newest body: a damaged newest body falls back to
#     the next whole one, and the program's answer does not change;
#   a value is read by its slot and checked against its digest: a damaged
#     .val byte answers absent, the derivation runs again, the answer does not
#     change;
#   a warm run reads one body.
set -u
. "$(dirname "$0")/lib/attack.sh"

R=build/store-seal
rm -rf "$R" .avra-cache && mkdir -p $R/small/src $R/big/src
printf '[package]\nname = "ss-small"\nversion = "0.1.0"\n' > $R/small/avra.toml
printf 'fn main() -> int { 1 + 2 }\n' > $R/small/src/main.av
printf '[package]\nname = "ss-big"\nversion = "0.1.0"\n' > $R/big/avra.toml
: > $R/big/src/main.av
i=0; sum=""
while [ $i -lt 60 ]; do
    echo "fn f$i() -> int { $i }" >> $R/big/src/main.av
    sum="$sum${sum:+ + }f$i()"
    i=$((i + 1))
done
echo "println(\"\${$sum}\")" >> $R/big/src/main.av
WANT=1770

who=store-seal
. tools/lib/steps.sh
bodies() { ls .avra-cache/store/body-*.pack 2>/dev/null | wc -l | tr -d ' '; }
flip() { python3 -I - "$1" "$2" <<'PY'
import sys
path, which = sys.argv[1], sys.argv[2]
data = bytearray(open(path, 'rb').read())
if which == 'all':
    data = bytearray(b ^ 0x01 for b in data)
else:
    data[20 if which == 'head' else len(data) // 2 if which == 'mid' else len(data) - 1] ^= 0x01
open(path, 'wb').write(bytes(data))
PY
}
newest() { ls .avra-cache/store/body-*.pack | sort -t- -k2 -n | tail -1; }
newest_val() { ls .avra-cache/store/body-*.val | sort -t- -k2 -n | tail -1; }

./avra check $R/big > $R/big.out 2>&1 || fail "the big cold check did not pass"
[ "$(bodies)" -ge 1 ] || fail "a big cold check sealed no body past SEAL_FRAMES"
before="$(bodies)"
./avra check $R/big > $R/big2.out 2>&1
[ "$(bodies)" = "$before" ] || fail "a warm check sealed another body: a seal ran without a write"
[ -f "$(newest_val)" ] || fail "the sealed body has no .val beside its .pack"

run_big() {
    AVRA_QTRACE=1 ./avra build $R/big > $R/$1.bin 2> $R/$1.err
    $(tail -1 $R/$1.bin) > $R/$1.out 2>&1
}

run_big warm
run_big clean
[ "$(tail -1 $R/clean.out)" = "$WANT" ] || fail "a clean run printed '$(tail -1 $R/clean.out)', wanted $WANT"
[ "$(grep -c '^Q	store	body	' $R/clean.err)" = 1 ] || fail "a warm run read $(grep -c '^Q	store	body	' $R/clean.err) bodies, not one"

# A body is read lazily: its head and index are checked at open, a section when first read,
# a row when decoded. A damaged HEAD is a torn body at open; damage past it is answered absent
# where it is read — either way the answer is right.
cp "$(newest)" $R/pack.saved
flip "$(newest)" head
run_big torn_pack
[ "$(tail -1 $R/torn_pack.out)" = "$WANT" ] || fail "a damaged newest body's head changed the answer to '$(tail -1 $R/torn_pack.out)'"
[ "$(grep -c '^Q	store	torn' $R/torn_pack.err)" -ge 1 ] || fail "a damaged newest body's head was not seen as torn"
cp $R/pack.saved "$(newest)"
flip "$(newest)" mid
run_big mid_pack
[ "$(tail -1 $R/mid_pack.out)" = "$WANT" ] || fail "a damaged newest body's middle changed the answer to '$(tail -1 $R/mid_pack.out)'"
cp $R/pack.saved "$(newest)"

# A process seals once, at its first write: a LATER process that writes anything folds every
# earlier segment into one body, so the rows of the runs before it all stand in the newest body.
sealed=0
seal_all() { sealed=$((sealed + 1)); printf 'fn main() -> int { %s }\n' "$sealed" > $R/small/src/main.av; AVRA_STORE_SEAL_FRAMES=1 ./avra check $R/small > /dev/null 2>&1; }

# A value is read by its slot and checked against its digest. Every row is SEALED here
# (a seal after each write, the segment removed), so a damaged `.val` leaves rows whose
# value cannot be read: they are absent, and the derivation runs again.
rm -rf .avra-cache
AVRA_STORE_SEAL_FRAMES=1 ./avra check $R/big > /dev/null 2>&1
AVRA_STORE_SEAL_FRAMES=1 ./avra build $R/big > /dev/null 2>&1
seal_all
rm -f .avra-cache/store/seg-*.log
cp -R .avra-cache/store $R/store.sealed
val="$(newest_val)"
flip "$val" all
run_big torn_val
[ "$(tail -1 $R/torn_val.out)" = "$WANT" ] || fail "a damaged value changed the answer to '$(tail -1 $R/torn_val.out)'"
[ "$(grep -c '^Q	store	value	' $R/torn_val.err)" -ge 1 ] || fail "a damaged value was never read through its slot"
[ "$(grep -c '^Q	attempt' $R/torn_val.err)" -ge 1 ] || fail "a damaged value answered present: nothing ran again"

# the same damage met by a CHECK, which keeps no binary
rm -rf .avra-cache/store && cp -R $R/store.sealed .avra-cache/store
flip "$val" all
AVRA_QTRACE=1 ./avra check $R/big > $R/torn_check.out 2> $R/torn_check.err
[ "$(grep -c '^Q	attempt' $R/torn_check.err)" -ge 1 ] || fail "a check over a damaged value answered a hit: nothing ran again"

verdict "seal threshold, newest body, slot values and warm reads"
