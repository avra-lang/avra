#!/bin/sh
# The dev loop without a browser: serve a copy of the board, edit its view, and the served module must change.
set -u
avra=${AVRA:-build/avra-try}
work=$(mktemp -d "${TMPDIR:-/tmp}/devprobe.XXXXXX")
cp -R tools/ui-board "$work/ui-board"
"$avra" dev --target wasm --port 0 "$work/ui-board" >"$work/out" 2>"$work/err" &
dev=$!
trap 'kill "$dev" 2>/dev/null || true' EXIT
tries=0
until grep -q '^dev: .* at http' "$work/out" 2>/dev/null; do
    tries=$((tries + 1)); [ "$tries" -lt 1200 ] || { echo "devprobe: never served"; cat "$work/err"; exit 1; }
    sleep 0.1
done
url=$(sed -n 's/^dev: .* at \(http[^ ]*\).*$/\1/p' "$work/out" | head -1)
sum() { curl -s "${url}app.wasm" | cksum | cut -d' ' -f1; }
before=$(sum)
sleep 1
sed -i 's/"Tasks"/"Chores"/' "$work/ui-board/src/board.av"
grep -c '"Chores"' "$work/ui-board/src/board.av"
n=0
while [ "$n" -lt 240 ]; do
    now=$(sum)
    if [ "$now" != "$before" ]; then echo "devprobe: the served module followed the edit (${n} polls)"; exit 0; fi
    n=$((n + 1)); sleep 0.5
done
echo "devprobe: the served module never followed the edit"; tail -5 "$work/out" "$work/err"; exit 1
