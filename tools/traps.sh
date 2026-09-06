#!/bin/sh
# THE TRAP CONTRACT, kept. A trap is a VERDICT (exit 2) and its words
# name the fault — laws no corpus program can hold, because the corpus
# runs every program in one process and a trap ends it. Each row builds
# a program, runs it, and demands the exact words and the exact status.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

fails=0
rows=0

# `avra build x.av` writes x.av.ll beside the binary, so the swept
# name is the SOURCE's, not the stem's.
clean() {
    rm -f "zz_trap_$1.av" "zz_trap_$1.av.ll" "zz_trap_$1"
}

trapped() {
    name="$1"; want_msg="$2"; want_status="$3"; src="$4"
    rows=$((rows + 1))
    printf '%s' "$src" > "zz_trap_$name.av"
    if ! ./avra build "zz_trap_$name.av" > "/tmp/trap_$name.build" 2>&1; then
        echo "traps: $name did not COMPILE"; sed -n '1,3p' "/tmp/trap_$name.build"
        fails=$((fails + 1)); clean "$name"; return
    fi
    got=$("./zz_trap_$name" 2>&1) && status=0 || status=$?
    if [ "$status" != "$want_status" ]; then
        echo "traps: $name exited $status, the contract says $want_status"
        fails=$((fails + 1))
    elif [ "$got" != "$want_msg" ]; then
        echo "traps: $name said"; echo "  $got"; echo "  the contract says"; echo "  $want_msg"
        fails=$((fails + 1))
    fi
    clean "$name"
}

trapped past_end "avra: index 3 is out of bounds (length 3)" 2 'let xs = [1, 2, 3]
xs[3]
'
trapped negative "avra: index -1 is out of bounds (length 3)" 2 'let xs = [1, 2, 3]
mut i = 0
i = i - 1
xs[i]
'
trapped empty "avra: index 0 is out of bounds (length 0)" 2 'let xs: List<int> = []
xs[0]
'

if [ "$fails" -gt 0 ]; then
    echo "traps: $fails of $rows contracts broken"
    exit 1
fi
echo "traps: $rows contracts held"
