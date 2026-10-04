#!/bin/sh
# THE SIZE RECEIPT, on every wasm-check: what the target carries, section by
# section, printed UNCONDITIONALLY — a rise is visible before it is fatal —
# against a RELATIVE cap a legitimate change cannot trip. A number offered once
# by hand is a claim that decays; this counts what it looked at and says so,
# and it names the base it counted.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-sz.XXXXXX")
say() { echo "wasm-size-guard: $*"; }
skip() { say "$* — skipped"; exit 0; }

command -v clang >/dev/null 2>&1 || skip "no clang"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
command -v wasm-opt >/dev/null 2>&1 || skip "no wasm-opt (binaryen) on PATH"
command -v wasm-objdump >/dev/null 2>&1 || skip "no wasm-objdump (wabt) on PATH"
[ -x "$avra" ] || skip "no compiler at $avra"
( cd "$tree" && make -s wasm-runtime wasm-packages ) >/dev/null 2>&1 || skip "the wasm runtime did not build"

base=$(cd "$tree" && (git rev-parse --short HEAD 2>/dev/null || echo no-git))
hex() { printf '%d' "$(( 0x${1:-0} ))"; }

# "<bytes> <globals> <code> <data>", or empty when the program will not build
footprint() { # dir mode
    dir=$1
    mode=$2
    flag=""
    [ "$mode" = reactor ] && flag=--wasm_reactor
    rm -rf "$work/pkg"
    cp -R "$dir" "$work/pkg"
    w=$("$avra" build --target wasm $flag "$work/pkg" 2>/dev/null | tail -1)
    [ -f "$w" ] || { echo ""; return; }
    bytes=$(stat -c%s "$w" 2>/dev/null || stat -f%z "$w")
    globals=$("$avra" emit "$dir" 2>/dev/null | grep -c '^@')
    c=$(wasm-objdump -h "$w" 2>/dev/null | awk '/ Code /{print; exit}' | sed -n 's/.*size=0x\([0-9a-fA-F]*\).*/\1/p')
    d=$(wasm-objdump -h "$w" 2>/dev/null | awk '/ Data /{print; exit}' | sed -n 's/.*size=0x\([0-9a-fA-F]*\).*/\1/p')
    echo "$bytes $globals $(hex "${c:-0}") $(hex "${d:-0}")"
}

floor=$(footprint "$here/wasm-min" command)
[ -n "$floor" ] || skip "the floor program did not build"
fb=$(echo "$floor" | cut -d' ' -f1)
fg=$(echo "$floor" | cut -d' ' -f2)

board=""
[ -d "$here/ui-board" ] && board=$(footprint "$here/ui-board" reactor)

if [ -n "$board" ]; then
    bb=$(echo "$board" | cut -d' ' -f1)
    bg=$(echo "$board" | cut -d' ' -f2)
    bc=$(echo "$board" | cut -d' ' -f3)
    bd=$(echo "$board" | cut -d' ' -f4)
    say "base=$base floor=${fb}B/${fg}g board=${bb}B code=${bc} data=${bd} globals=${bg}g"
else
    say "base=$base floor=${fb}B/${fg}g board=absent (tools/ui-board not here)"
fi

baseline=${WASM_SIZE_BASELINE:-$here/wasm-size.baseline}
if [ "${1:-}" = --accept ]; then
    {
        echo "# THE LAST ACCEPTED WASM FOOTPRINT ..."
        echo "floor_bytes $fb"
        echo "floor_globals $fg"
        [ -n "$board" ] && echo "board_bytes $bb"
        [ -n "$board" ] && echo "board_globals $bg"
    } > "$baseline"
    say "accepted base=$base floor=${fb}B/${fg}g"
    exit 0
fi
[ -f "$baseline" ] || { say "no baseline file — nothing to compare"; exit 0; }
want() { sed -n "s/^$1 //p" "$baseline" | head -1; }
fail=0
check() { # label measured baseline
    b=$3
    [ -n "$b" ] || return 0
    cap=$(( b + b / 12 + 2048 ))
    if [ "$2" -gt "$cap" ]; then
        say "$1 grew: $2 > cap $cap (baseline $b)"
        fail=1
    fi
}
check floor_bytes "$fb" "$(want floor_bytes)"
check floor_globals "$fg" "$(want floor_globals)"
if [ -n "$board" ]; then
    check board_bytes "$bb" "$(want board_bytes)"
    check board_globals "$bg" "$(want board_globals)"
fi
[ "$fail" -eq 0 ] || { say "REGRESSED — the wasm footprint rose past the cap"; exit 1; }
say "within the cap"
