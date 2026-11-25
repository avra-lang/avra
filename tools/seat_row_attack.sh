#!/bin/sh
# A GATHERED ROW FOLLOWS ITS MEMBER'S EDIT, across processes. `seat_rows` gathers the
# seat consts the View derive writes beside each component, over the program's import
# closure. Adding an argument to the dialog's `@host(...)` changes one row and no
# name: a warm run through the same `.avra-cache` must read what a cold run reads.
set -u
cd "$(dirname "$0")/.."
AVRA=${AVRA_BIN:-build/avra}
T=packages/std-ui/src/terminal/tests/seat_row_probe_test.av
M=packages/std-ui/src/components/dialog.av
K=build/seat-row-attack.orig
cp $M $K
trap 'cp $K $M' EXIT
reads() { $AVRA test $T 2>&1 | grep -ao 'seat-rows .*' | head -1; }
$AVRA test $T > /dev/null 2>&1
before=$(reads)
sed -i.bak 's/@host(web: .Cancel, always: true)/@host(web: .Cancel, terminal: .Escape, always: true)/' $M
find $M.bak -delete
warm=$(reads)
find .avra-cache -mindepth 1 -delete
cold=$(reads)
echo "seat-row-attack: before '$before', warm '$warm', cold '$cold'"
if [ -z "$cold" ] || [ "$warm" != "$cold" ] || [ "$before" = "$cold" ]; then
    echo "seat-row-attack: FAILED — the warm row is not the cold one, or the edit changed nothing"
    exit 1
fi
