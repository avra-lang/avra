#!/bin/sh
# tool-witness: run by the gate's witness-b slice
# A BUILD REFUSED FOR AN EDIT LEAVES NO ANSWER A GOOD BUILD READS WRONGLY: on one machine store of
# its own, the board's server page (tools/ui-board with its hydrate main) is built, built again with
# an unterminated declaration appended to the board's file — the edit a dev loop makes mid-typing,
# refused — and then a fresh copy of the untouched board is built. That last build must make its
# program and draw its page: a stored answer the refused build wrote under a key the good file's
# declaration shares (its item's id, its face) would be read for it. And the edit then FIXED —
# the declaration closed, the file balanced again — builds on that store as a fresh one does.
#   sh tools/witness_store_broken_edit.sh [compiler]
. "$(dirname "$0")/lib/scratch.sh"
set -u
. "$(dirname "$0")/lib/tree.sh"
[ $# -gt 0 ] && avra=$1
[ -x "$avra" ] || { echo "store-broken-edit: no compiler at $avra"; exit 1; }
scratch_dir work
mkdir -p "$work/home"
# board <name>: a copy of the board, its hydrate main as its main, under $work/<name>
board() {
    mkdir -p "$work/$1/tools"
    cp -R "$here/ui-board" "$work/$1/tools/ui-board"
    find "$work/$1/tools/ui-board" -name '.avra-cache' -prune -exec rm -rf {} + 2> /dev/null
    cp "$here/ui-board/hydrate/main.av" "$work/$1/tools/ui-board/src/main.av"
}
# built <name>: the copy built on the witness's own store
built() {
    (cd "$tree" && HOME="$work/home" AVRA_CACHE_DIR="$work/home/cache" AVRA_MACHINE_STORE_DIR="$work/store" \
        AVRA_PROGRAM_NET=0 "$avra" build "$work/$1/tools/ui-board") > "$work/$1.out" 2> "$work/$1.err"
}
board edited
built edited || { echo "store-broken-edit: the board's server page did not build at first"; grep -v '^warning' "$work/edited.err" | tail -3; exit 1; }
printf '\nfn half_typed( {\n' >> "$work/edited/tools/ui-board/src/board.av"
if built edited; then echo "store-broken-edit: the board built with an unterminated declaration, and must be refused"; exit 1; fi
# page <name>: the copy's program drew a document
page() {
    (cd "$work" && "$work/$1/tools/ui-board/src/main") > "$work/$1.page" 2> /dev/null && grep -q '^<!doctype html>' "$work/$1.page"
}
sed -i 's/^fn half_typed( {$/fn half_typed() -> int { 1 }/' "$work/edited/tools/ui-board/src/board.av"
if ! built edited || ! page edited; then
    echo "store-broken-edit: the edit fixed (its declaration closed) did not build and draw on the same store:"
    grep -h "untyped\|not lowered\|program layer\|^error" "$work/edited.err" "$work/edited.out" | head -3 | cut -c1-300
    exit 1
fi
board untouched
if ! built untouched; then
    echo "store-broken-edit: after a refused edit, the untouched board did not build on the same store:"
    grep -h "untyped\|not lowered\|program layer\|^error" "$work/untouched.err" "$work/untouched.out" | head -3 | cut -c1-300
    exit 1
fi
page untouched || { echo "store-broken-edit: the untouched board drew no document"; exit 1; }
echo "store-broken-edit: after a refused edit, the edit fixed and the untouched board both build on the store as on a fresh one"
