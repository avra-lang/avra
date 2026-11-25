#!/bin/sh
# tool-witness: run by the gate's witness-b slice
# THE BOARD'S SERVER PAGE BUILDS NATIVE WHOLE AND DRAWS WHAT THE EVALUATOR DRAWS: tools/ui-board
# with its hydrate main (the page `ui_board_browser.sh` serves), built cold — no store, no cache, no
# layer kept from before — must report no body left unlowered (a trap standing in for one), and its
# binary's page must be the evaluator's, byte for byte. A browser run is a Mac's; this is any host's.
#   sh tools/witness_board_native.sh [compiler]
set -u
. "$(dirname "$0")/lib/tree.sh"
[ $# -gt 0 ] && avra=$1
[ -x "$avra" ] || { echo "board-native: no compiler at $avra"; exit 1; }
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-board-native.XXXXXX")
trap 'rm -rf "$work"' EXIT INT TERM
mkdir -p "$work/tools" "$work/cache/home"
cp -R "$here/ui-board" "$work/tools/ui-board"
cp "$here/ui-board/hydrate/main.av" "$work/tools/ui-board/src/main.av"
find "$work/tools/ui-board" -name '.avra-cache' -prune -exec rm -rf {} + 2> /dev/null
find "$work/tools/ui-board" -path '*/src/main' -type f -delete
# cold <name> <command...>: the command with no store, no cache, and a task file of its own
cold() {
    db="$work/$1.db"
    shift
    HOME="$work/cache/home" AVRA_CACHE_DIR="$work/cache" AVRA_MACHINE_STORE=0 BOARD_DB="$db" "$@"
}
board="$work/tools/ui-board"
if ! (cd "$tree" && cold build "$avra" build "$board") > "$work/build.out" 2> "$work/build.err"; then
    echo "board-native: the board's server page did not build"
    grep -v '^warning' "$work/build.err" | tail -5
    exit 1
fi
if grep -q "bodies not lowered yet\|a body not lowered yet" "$work/build.err"; then
    echo "board-native: the native build left bodies unlowered:"
    grep "not lowered yet" "$work/build.err" | cut -c1-600
    exit 1
fi
(cd "$work" && cold native "$board/src/main") > "$work/native.out" 2> "$work/native.err" || {
    echo "board-native: the native page ended in failure"; tail -3 "$work/native.err"; exit 1; }
(cd "$tree" && cold eval "$avra" run --eval "$board") > "$work/eval.out" 2> "$work/eval.err" || {
    echo "board-native: the evaluator's page ended in failure"; grep -v '^warning' "$work/eval.err" | tail -3; exit 1; }
grep -q '^<!doctype html>' "$work/native.out" || { echo "board-native: the native page drew no document"; exit 1; }
cmp -s "$work/native.out" "$work/eval.out" || {
    echo "board-native: the native page differs from the evaluator's:"
    diff "$work/eval.out" "$work/native.out" | head -6 | cut -c1-200
    exit 1
}
echo "board-native: the board's server page builds with every body lowered, and draws as the evaluator does ($(wc -c < "$work/native.out") bytes)"
