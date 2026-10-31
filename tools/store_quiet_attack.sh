#!/bin/sh
# A WARM NO-OP CHECK WRITES NOTHING TO THE STORE. The cold check of an
# unchanged package writes its frames; the next check over the same bytes
# answers from the store and touches no file under .avra-cache/store.
# Held by mtime against a marker taken after the cold check, so a rewrite of
# an existing file counts as a write, not only a new file.
set -u
. "$(dirname "$0")/lib/attack.sh"

R=build/store-quiet
rm -rf "$R" && mkdir -p $R/p/src
cat > $R/p/avra.toml <<'TOML'
[package]
name = "sq-p"
version = "0.1.0"
TOML
cat > $R/p/src/main.av <<'AV'
fn main() -> int { 1 + 2 }
AV

./avra check $R/p > $R/cold.out 2>&1 || { echo "store-quiet: FAILED — the cold check did not pass"; cat $R/cold.out; exit 1; }
[ "$(ls .avra-cache/store/seg-*.log 2>/dev/null | wc -l)" -ge 1 ] || { echo "store-quiet: FAILED — the cold check wrote no segment, so the warm check proves nothing"; exit 1; }
sleep 1
touch $R/marker

AVRA_QTRACE=1 ./avra check $R/p --time > $R/warm.out 2>&1
[ $? = 0 ] || { echo "store-quiet: FAILED — the warm check did not pass"; cat $R/warm.out; exit 1; }
grep -q 'cache hit' $R/warm.out || { echo "store-quiet: FAILED — the warm check was not a cache hit"; cat $R/warm.out; exit 1; }

written="$(find .avra-cache/store -newer $R/marker -type f)"
if [ -n "$written" ]; then
    echo "store-quiet: FAILED — a warm no-op check wrote to the store:"
    echo "$written"
    fails=1
fi

[ "$fails" = 0 ] && echo "store-quiet: a warm no-op check wrote nothing to the store" || exit 1
