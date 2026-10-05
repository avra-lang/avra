#!/bin/sh
# THE BOARD IN A REAL BROWSER: tools/ui-board/web served by `avra dev` and
# driven in headless Firefox by
# tools/ui-board/browser.mjs, which checks each claim and exits 1 on the
# first that fails. `make ui-board` proves the wire over a stub document;
# this proves what only an engine can — and the dev loop: the view's file is
# edited and the running page must follow.
#
# It needs what `make ui-board` needs, and Firefox (FIREFOX names one that is
# not in a usual place). Where one is absent this SKIPS, spoken, naming what
# is missing. UI_BOARD_TARGET names one wasm triple (default `wasm`);
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
if [ ! -f "$tree/build/wasm32/libavra_runtime.a" ]; then
    ( cd "$tree" && make -s wasm-runtime wasm-packages ) >/dev/null 2>&1 || skip "the wasm runtime archive did not build"
fi

# A COPY is served, so the run edits no file of the tree's.
mkdir -p "$work/tools"
cp -R "$tree/tools/ui-board" "$work/tools/ui-board"
"$avra" dev --target "$target" --port 0 "$work/tools/ui-board/web" >"$work/dev.out" 2>"$work/dev.err" &
dev=$!
trap 'kill "$dev" 2>/dev/null || true' EXIT
tries=0
until grep -q '^dev: .* at http' "$work/dev.out" 2>/dev/null; do
    if ! kill -0 "$dev" 2>/dev/null; then
        wait "$dev" || ended=$?
        [ "${ended:-0}" -ne 2 ] || skip "$(sed 's/^avra: //' "$work/dev.err" | head -1)"
        echo "ui-browser: \`avra dev\` ended before it served"; cat "$work/dev.err" "$work/dev.out"; exit 1
    fi
    tries=$((tries + 1))
    [ "$tries" -lt 600 ] || { echo "ui-browser: \`avra dev\` never said where it serves"; cat "$work/dev.err"; exit 1; }
    sleep 0.1
done
url=$(sed -n 's/^dev: .* at \(http[^ ]*\).*$/\1/p' "$work/dev.out" | head -1)

if ! out=$(node "$here/ui-board/browser.mjs" "$url" --source "$work/tools/ui-board/src/board.av" ${UI_BROWSER_SHOTS:+--shots "$UI_BROWSER_SHOTS"} 2>&1); then
    echo "$out" | grep -v '^ok ' ; echo "ui-browser: the board failed in the browser"; exit 1
fi
echo "ui-browser: $(echo "$out" | grep -c '^ok ') claims hold in Firefox, served by \`avra dev\` at $url"
