#!/bin/sh
# tool-witness: run by the gate's ui-browser slice
# `avra dev` OVER THE BOARD BUILDS ITS PAGE AND SERVES IT: tools/ui-board, copied cold (no store, no
# cache), run under `avra dev --port 0` — its server beside it, its page module built by the build
# dev asks for, never one the other claims build — must say its module built, report no body left
# unlowered, and answer its page with a document. With no wasm toolchain the route builds no page:
# under CI that is a failure naming what is missing, since a check that examined nothing passed
# nothing; elsewhere the witness says it skipped.
#   sh tools/witness_board_dev.sh [compiler]
set -u
. "$(dirname "$0")/lib/tree.sh"
[ $# -gt 0 ] && avra=$1
[ -x "$avra" ] || { echo "board-dev: no compiler at $avra"; exit 1; }
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-board-dev.XXXXXX")
dev=""
trap 'kill $dev 2>/dev/null; pkill -P "${dev:-0}" 2>/dev/null; rm -rf "$work"' EXIT INT TERM
mkdir -p "$work/tools" "$work/cache/home"
cp -R "$here/ui-board" "$work/tools/ui-board"
find "$work/tools/ui-board" -name '.avra-cache' -prune -exec rm -rf {} + 2> /dev/null
(cd "$tree" && HOME="$work/cache/home" AVRA_CACHE_DIR="$work/cache" AVRA_MACHINE_STORE=0 \
    BOARD_DB="$work/board.db" exec "$avra" dev --port 0 "$work/tools/ui-board") > "$work/dev.out" 2> "$work/dev.err" &
dev=$!
tries=0
while ! grep -q "^dev: built module\|the build failed\|^dev: .* at http://" "$work/dev.out" 2> /dev/null; do
    if ! kill -0 "$dev" 2> /dev/null; then
        wait "$dev"; ended=$?
        if [ "$ended" -eq 2 ]; then
            missing=$(sed 's/^avra: //' "$work/dev.err" | head -1)
            [ "${CI:-}" = true ] && { echo "board-dev: FAILED — this runner cannot build a page: $missing"; exit 1; }
            echo "board-dev: skipped, nothing examined — $missing"
            exit 0
        fi
        echo "board-dev: \`avra dev\` ended before it served"; tail -5 "$work/dev.err" "$work/dev.out"; exit 1
    fi
    tries=$((tries + 1))
    [ "$tries" -lt 900 ] || { echo "board-dev: \`avra dev\` built nothing in 900 s"; tail -5 "$work/dev.err"; exit 1; }
    sleep 1
done
until grep -q "^dev: .* at http://" "$work/dev.out" 2> /dev/null || [ "$tries" -ge 900 ]; do tries=$((tries + 1)); sleep 1; done
if grep -q "not lowered yet\|the build failed" "$work/dev.out" "$work/dev.err"; then
    echo "board-dev: dev's page build failed or left bodies unlowered:"
    grep -h "not lowered yet\|the build failed" "$work/dev.out" "$work/dev.err" | cut -c1-600
    exit 1
fi
grep -q "^dev: built module" "$work/dev.out" || { echo "board-dev: dev never said its module built"; tail -5 "$work/dev.out"; exit 1; }
url=$(sed -n 's#^dev: .* at \(http://[^ ]*\).*#\1#p' "$work/dev.out" | head -1)
[ -n "$url" ] || { echo "board-dev: dev never said where it serves"; exit 1; }
curl -s --max-time 30 "$url" > "$work/page.html" || { echo "board-dev: $url did not answer"; exit 1; }
grep -qi '^<!doctype html>' "$work/page.html" || { echo "board-dev: $url answered no document:"; head -c 300 "$work/page.html"; exit 1; }
echo "board-dev: \`avra dev\` built the board's module and served its page ($(sed -n 's/^dev: built module 1 — \([0-9]*\) bytes.*/\1/p' "$work/dev.out") bytes of module)"
