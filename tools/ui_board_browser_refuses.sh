#!/bin/sh
# THE BROWSER RUN REFUSES A BOARD THAT DOES NOT BUILD: a board whose source
# has a syntax error is served by `avra dev` as nothing, and the run must exit 1 within a
# minute with the build's words instead of waiting out the page. Where the browser run skips
# (no Firefox, no node), so does this.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-ui-refuses.XXXXXX")
trap 'find "$work" -delete 2>/dev/null || true' EXIT

cp -R "$tree/tools/ui-board" "$work/board"
printf '\nlet = = broken\n' >> "$work/board/src/board.av"

began=$(date +%s)
status=0
out=$(UI_BOARD_DIR="$work/board" sh "$here/ui_board_browser.sh" 2>&1) || status=$?
took=$(( $(date +%s) - began ))

case "$out" in
    *SKIPPED*) echo "ui-browser-refuses: SKIPPED — $(echo "$out" | head -1)"; exit 0 ;;
esac
[ "$status" -eq 1 ] || { echo "ui-browser-refuses: exit $status, wanted 1: $out"; exit 1; }
[ "$took" -le 60 ] || { echo "ui-browser-refuses: refused after ${took}s, wanted at most 60"; exit 1; }
case "$out" in
    *"the board's build failed"*) ;;
    *) echo "ui-browser-refuses: the refusal does not say the build failed: $out"; exit 1 ;;
esac
case "$out" in
    *"<pre>"*) ;;
    *) echo "ui-browser-refuses: the build's words are not in the page body: $out"; exit 1 ;;
esac
echo "ui-browser-refuses: a board that does not build is refused in ${took}s with the build's words"
