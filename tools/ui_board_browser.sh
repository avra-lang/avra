#!/bin/sh
# THE BOARD IN A REAL BROWSER: tools/ui-board/web built as a wasm reactor,
# served over an HTTP origin and driven in headless Firefox by
# tools/ui-board/browser.mjs, which checks each claim and exits 1 on the
# first that fails. `make ui-board` proves the wire over a stub document;
# this proves what only an engine can.
#
# It needs what `make ui-board` needs, and Firefox (FIREFOX names one that is
# not in a usual place). Where one is absent this SKIPS, spoken, naming what
# is missing. UI_BOARD_TARGET names another wasm triple (default `wasm`);
# UI_BROWSER_SHOTS names a directory the run leaves screenshots in.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
target=${UI_BOARD_TARGET:-wasm}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-ui-browser.XXXXXX")

skip() { echo "ui-browser: SKIPPED — $* ; the board did not run in a browser"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v node >/dev/null 2>&1 || skip "no \`node\` on this machine"
node -e 'process.exit(typeof WebSocket === "function" ? 0 : 1)' || skip "this \`node\` has no WebSocket of its own (22 or later has)"
node --input-type=module -e "import { firefoxBinary } from '$here/ui-board/firefox.mjs'; process.exit(firefoxBinary() ? 0 : 1)" || skip "no Firefox on this machine (FIREFOX names one)"
[ -f "$tree/build/wasm32/libavra_runtime.a" ] || skip "no wasm runtime archive (\`make ui-board\` builds it, or says why it cannot)"

mkdir -p "$work/tools"
cp -R "$tree/tools/ui-board" "$work/tools/ui-board"
if ! "$avra" build --target "$target" --wasm_reactor "$work/tools/ui-board/web" >"$work/build.out" 2>"$work/build.err"; then
    echo "ui-browser: the board did not build for $target"; cat "$work/build.err"; tail -20 "$work/build.out"; exit 1
fi
wasm=$(tail -1 "$work/build.out")
[ -f "$wasm" ] || { echo "ui-browser: the build named no module ($wasm)"; exit 1; }

node "$here/ui-board/origin.mjs" "$tree/runtime/dom" "$wasm" >"$work/origin.out" 2>"$work/origin.err" &
origin=$!
trap 'kill "$origin" 2>/dev/null || true' EXIT
tries=0
until [ -s "$work/origin.out" ]; do
    tries=$((tries + 1))
    [ "$tries" -lt 100 ] || { echo "ui-browser: the origin never said its address"; cat "$work/origin.err"; exit 1; }
    sleep 0.1
done
url=$(head -1 "$work/origin.out")

if ! out=$(node "$here/ui-board/browser.mjs" "$url" ${UI_BROWSER_SHOTS:+"$UI_BROWSER_SHOTS"} 2>&1); then
    echo "$out" | grep -v '^ok ' ; echo "ui-browser: the board failed in the browser"; exit 1
fi
echo "ui-browser: $(echo "$out" | grep -c '^ok ') claims hold in Firefox at $url"
