#!/bin/sh
# THE TRAP CONTRACT, kept. A trap is a VERDICT (exit 2) and its words
# name the fault — laws no corpus program can hold, because the corpus
# runs every program in one process and a trap ends it. Each row builds
# a program, runs it, and demands the exact words and the exact status.
#
# A ROW IS A PACKAGE, NEVER A BARE FILE. A bare file cannot `use` one
# — F3015, "this file is not in a package" — so a bare-file harness
# reaches only contracts that touch no package, which is half the
# tree and not the half where a driver holds a transaction open. The
# package is scaffolded under build/, so a dependency path climbs to
# `packages/`, and the whole directory is swept at the end.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

ROOT=build/traps
fails=0
rows=0

# `deps` is a manifest fragment, empty for a row that needs none.
# `avra build <dir>` answers the binary at <dir>/src/main.
trapped() {
    name="$1"; want_msg="$2"; want_status="$3"; deps="$4"; src="$5"
    rows=$((rows + 1))
    dir="$ROOT/$name"
    mkdir -p "$dir/src"
    printf '[package]\nname    = "zz-trap-%s"\nversion = "0.0.1"\n%s' "$name" "$deps" > "$dir/avra.toml"
    printf '%s' "$src" > "$dir/src/main.av"
    if ! ./avra build "$dir" > "$dir/build.out" 2>&1; then
        echo "traps: $name did not COMPILE"; sed -n '1,4p' "$dir/build.out"
        fails=$((fails + 1)); return
    fi
    got=$("$dir/src/main" 2>&1) && status=0 || status=$?
    if [ "$status" != "$want_status" ]; then
        echo "traps: $name exited $status, the contract says $want_status"
        fails=$((fails + 1))
    elif [ "$got" != "$want_msg" ]; then
        echo "traps: $name said"; echo "  $got"; echo "  the contract says"; echo "  $want_msg"
        fails=$((fails + 1))
    fi
}

trapped past_end "avra: index 3 is out of bounds (length 3)" 2 '' 'let xs = [1, 2, 3]
xs[3]
'
trapped negative "avra: index -1 is out of bounds (length 3)" 2 '' 'let xs = [1, 2, 3]
mut i = 0
i = i - 1
xs[i]
'
trapped empty "avra: index 0 is out of bounds (length 0)" 2 '' 'let xs: List<int> = []
xs[0]
'
# A SHIFT COUNT the compiler cannot read. A literal one is refused
# where it is written (F2057); this is its twin — the count arrives at
# run time, so one C body decides the edge and BOTH engines call it.
# The words name the LAW, never the mechanism that would enforce it.
trapped bytes_at "avra: index 3 is out of bounds (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
b.at(3)
'
trapped bytes_slice "avra: slice 2..4 is out of bounds (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
let s = b.slice(2, 4)
s.length
'
trapped bytes_from "avra: index 4 is out of bounds (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
b.index_of([2].bytes()!, 4)
'
trapped bytes_table "avra: a class table holds 256 bytes (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
b.run(0, b)
'
trapped bytes_eq_at "avra: slice 1..4 is out of bounds (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
b.eq_at(1, 4, b)
'
trapped shift_wide "avra: a shift count must be between 0 and 63" 2 '' 'let a = 1
mut n = 0
n = n + 64
a << n
'
trapped shift_negative "avra: a shift count must be between 0 and 63" 2 '' 'let a = 1
mut n = 0
n = n - 1
a >> n
'

# A trap raised with a PACKAGE in use is still a verdict — the row
# that proves this harness reaches past a bare file, so the capability
# is exercised rather than merely available.
trapped in_package "avra: index 5 is out of bounds (length 1)" 2 '
[dependencies]
"@std/text" = { path = "../../../packages/std-text" }
' 'use @std.text.{from_codepoint}
let a = from_codepoint(65)
let xs = [a]
xs[5]
'

rm -rf "$ROOT"
if [ "$fails" -gt 0 ]; then
    echo "traps: $fails of $rows contracts broken"
    exit 1
fi
echo "traps: $rows contracts held"
