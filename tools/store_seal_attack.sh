#!/bin/sh
# THE SEALED STORE, ATTACKED. Four invariants of store/pack.av and store/body.av,
# each proved by a run whose answer is held to the program's own output:
#   a write seals only past SEAL_FRAMES: a small cold check writes no body;
#   a large one writes at least one body-<rev>.pack beside its .val;
#   an open reads only the newest body: a damaged newest body falls back to
#     the next whole one, and the program's answer does not change;
#   a value is read by its slot and checked against its digest: a damaged
#     .val byte answers absent, the derivation runs again, the answer does not
#     change;
#   a warm run reads one body and no value it did not ask for.
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0

R=build/store-seal; fails=0
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

fail() { fails=$((fails + 1)); echo "store-seal: FAILED — $1"; }
bodies() { ls .avra-cache/store/body-*.pack 2>/dev/null | wc -l | tr -d ' '; }
flip() { python3 -I - "$1" "$2" <<'PY'
import sys
path, which = sys.argv[1], sys.argv[2]
data = bytearray(open(path, 'rb').read())
if which == 'all':
    data = bytearray(b ^ 0x01 for b in data)
else:
    data[len(data) // 2 if which == 'mid' else len(data) - 1] ^= 0x01
open(path, 'wb').write(bytes(data))
PY
}
newest() { ls .avra-cache/store/body-*.pack | sort -t- -k2 -n | tail -1; }

./avra check $R/small > $R/small.out 2>&1 || fail "the small cold check did not pass"
[ "$(bodies)" = 0 ] || fail "a small cold check sealed a body ($(bodies)), so the threshold is not held"

./avra check $R/big > $R/big.out 2>&1 || fail "the big cold check did not pass"
[ "$(bodies)" -ge 1 ] || fail "a big cold check sealed no body past SEAL_FRAMES"
[ -f "$(newest | sed 's/\.pack$/.val/')" ] || fail "the sealed body has no .val beside its .pack"

run_big() {
    AVRA_QTRACE=1 ./avra build $R/big > $R/$1.bin 2> $R/$1.err
    $(tail -1 $R/$1.bin) > $R/$1.out 2>&1
}

run_big warm
run_big clean
[ "$(tail -1 $R/clean.out)" = "$WANT" ] || fail "a clean run printed '$(tail -1 $R/clean.out)', wanted $WANT"
[ "$(grep -c '^Q	store	body	' $R/clean.err)" = 1 ] || fail "a warm run read $(grep -c '^Q	store	body	' $R/clean.err) bodies, not one"
[ "$(grep -c '^Q	store	value	' $R/clean.err)" = 0 ] || fail "a warm run read a value its answer did not need"

cp "$(newest)" $R/pack.saved
flip "$(newest)" mid
run_big torn_pack
[ "$(tail -1 $R/torn_pack.out)" = "$WANT" ] || fail "a damaged newest body changed the answer to '$(tail -1 $R/torn_pack.out)'"
[ "$(grep -c '^Q	store	torn' $R/torn_pack.err)" -ge 1 ] || fail "a damaged newest body was not seen as torn"
cp $R/pack.saved "$(newest)"

val="$(newest | sed 's/\.pack$/.val/')"
cp "$val" $R/val.saved
flip "$val" all
run_big torn_val
[ "$(tail -1 $R/torn_val.out)" = "$WANT" ] || fail "a damaged value changed the answer to '$(tail -1 $R/torn_val.out)'"
[ "$(grep -c '^Q	store	value	' $R/torn_val.err)" -ge 1 ] || fail "a damaged value was never read through its slot"
[ "$(grep -c '^Q	attempt' $R/torn_val.err)" -ge 1 ] || fail "a damaged value answered present: nothing ran again"
cp $R/val.saved "$val"

[ "$fails" = 0 ] && echo "store-seal: seal threshold, newest body, slot values and warm reads all held" || exit 1
