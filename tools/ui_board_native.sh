#!/bin/sh
# THE BOARD'S NATIVE BINARY CARRIES ONLY THE C IT CALLS: the board's terminal program
# (tools/ui-board/term) is built `--release` and its symbols read. A package's `[link]` objects
# ride only a program that calls an extern the package declares, so the board — which reaches
# @std/sqlite through its model's @std/crud and calls no database fn — holds no `sqlite3_` symbol,
# and its bytes stay within tools/ui-board/term/native.budget, a line per `uname -sm` that is only
# ever lowered. A machine with no line is said, and holds the symbol claim alone.
. "$(dirname "$0")/lib/scratch.sh"
set -eu

. "$(dirname "$0")/lib/tree.sh"
scratch_dir work
# The copy of the tree it builds in is this run's alone, and goes when the run ends.

[ -x "$avra" ] || { echo "ui-board-native: no compiler at $avra"; exit 1; }
nm=$(command -v llvm-nm-22 || command -v llvm-nm || command -v nm) || { echo "ui-board-native: no nm on this machine"; exit 1; }

# A COPY is built, so the tree's own sources never hold a binary.
mkdir -p "$work/tools"
cp -R "$tree/tools/ui-board" "$work/tools/ui-board"
"$avra" build --release "$work/tools/ui-board/term" >"$work/build.out" 2>"$work/build.err" || {
    cat "$work/build.err"; tail -20 "$work/build.out"; echo "ui-board-native: the board's terminal program did not build"; exit 1
}
binary=$(tail -1 "$work/build.out")
[ -f "$binary" ] || { echo "ui-board-native: the build named no binary ($binary)"; exit 1; }

carried=$("$nm" "$binary" | grep -c 'sqlite3_' || true)
[ "$carried" -eq 0 ] || { echo "ui-board-native: the board calls no database fn and carries $carried sqlite3_ symbols"; exit 1; }

bytes=$(wc -c <"$binary" | tr -d ' ')
machine=$(uname -sm | tr ' ' '-')
ceiling=$(sed -n "s/^$machine \([0-9][0-9]*\)$/\1/p" "$tree/tools/ui-board/term/native.budget")
if [ -z "$ceiling" ]; then
    echo "ui-board-native: no sqlite3_ symbol in a $bytes-byte binary; native.budget holds no line for $machine"
    exit 0
fi
[ "$bytes" -le "$ceiling" ] || {
    echo "ui-board-native: the board's binary is $bytes bytes, past the recorded $ceiling for $machine — a change that grew it raises native.budget, and says why"
    exit 1
}
echo "ui-board-native: no sqlite3_ symbol in a $bytes-byte binary, within the recorded $ceiling for $machine"
