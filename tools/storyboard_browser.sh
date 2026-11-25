#!/bin/sh
# THE STORYBOARD IN A REAL BROWSER: tools/storyboard served by `avra dev` and judged by
# tools/storyboard/claims.mjs — every case of every view std-ui declares, under every dial, held to
# the claims table, and each claim family shown failing on a page broken in what it asserts.
#
# Like the board's browser keeper, A RUN THAT CANNOT JUDGE FAILS: a missing browser, node or wasm
# toolchain is a broken machine on the checks' machine (CI=true); a local machine may stand it down
# by name, UI_BROWSER_SKIP=<reason>. STORYBOARD_ENGINES names the engines, in order (default
# `firefox`); `webkit` and `chromium` come from the Playwright PLAYWRIGHT_DIR holds.
set -eu
. "$(dirname "$0")/lib/tree.sh"

skip() {
    if [ "${CI:-}" = true ]; then echo "storyboard: ran 0 claims — $* ; the checks' machine must carry them"; exit 1; fi
    if [ -n "${UI_BROWSER_SKIP:-}" ]; then echo "storyboard: ran 0 claims — STOOD DOWN ($UI_BROWSER_SKIP): $*"; exit 0; fi
    echo "storyboard: ran 0 claims — $* ; set UI_BROWSER_SKIP=<reason> to stand it down here"
    exit 1
}

[ -x "$avra" ] || skip "no compiler at $avra"
command -v node >/dev/null 2>&1 || skip "no \`node\` on this machine"
. "$here/lib/wasm_ready.sh"
wasm_ready || skip "the wasm runtime archive did not build"

work=$(mktemp -d "${TMPDIR:-/tmp}/avra-storyboard.XXXXXX")
# A COPY is served, so the run edits no file of the tree's.
mkdir -p "$work/tools"
cp -R "$tree/tools/storyboard" "$work/tools/storyboard"
"$avra" dev --target "${UI_BOARD_TARGET:-wasm}" --port 0 "$work/tools/storyboard" >"$work/dev.out" 2>"$work/dev.err" &
dev=$!
trap 'kill "$dev" 2>/dev/null || true' EXIT
tries=0
until grep -q '^dev: .* at http' "$work/dev.out" 2>/dev/null; do
    kill -0 "$dev" 2>/dev/null || { cat "$work/dev.err" "$work/dev.out"; echo "storyboard: \`avra dev\` ended before it served"; exit 1; }
    tries=$((tries + 1))
    [ "$tries" -lt 1200 ] || { cat "$work/dev.err"; echo "storyboard: \`avra dev\` never said where it serves"; exit 1; }
    sleep 0.1
done
url=$(sed -n 's/^dev: .* at \(http[^ ]*\).*$/\1/p' "$work/dev.out" | head -1)

for engine in ${STORYBOARD_ENGINES:-firefox}; do
    status=0
    node "$here/storyboard/claims.mjs" "$url" --engine "$engine" || status=$?
    [ "$status" -ne 3 ] || skip "$engine could not launch"
    [ "$status" -eq 0 ] || { echo "storyboard: the claims failed in $engine"; exit 1; }
done
