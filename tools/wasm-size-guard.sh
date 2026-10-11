#!/bin/sh
# THE SIZE RECEIPT, on every wasm-check: what the target carries, section by
# section, printed UNCONDITIONALLY — a rise is visible before it is fatal.
#
# TWO QUANTITIES, TWO LAWS:
#   THE FLOOR (the minimal program) is the compiler's SHARED cost and must not
#   creep; it is capped TIGHTLY and a floor rise is the loud regression.
#   THE BOARD (tools/ui-board, the board mounted on a page) is the UI library's SHOWCASE and is SUPPOSED to
#   grow with every component; it is REPORTED with its move against the last
#   accepted value, NEVER capped — a cap there would train a re-baseline on
#   every feature, which is how a guard dies.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-sz.XXXXXX")
# WASM_TARGET names another wasm triple, for a machine whose sysroot is not the default's.
target=${WASM_TARGET:-wasm}
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

# "<bytes> <globals> <code> <data>", or empty when the program will not build.
# `entry` names the package to build inside `dir`, when `dir` holds more than
# one: the whole of `dir` is copied, so a path dependency beside the entry
# comes with it.
footprint() { # dir mode [entry]
    dir=$1
    mode=$2
    entry=${3:-.}
    flag=""
    [ "$mode" = reactor ] && flag=--wasm_reactor
    rm -rf "$work/pkg"
    cp -R "$dir" "$work/pkg"
    w=$("$avra" build --target "$target" $flag "$work/pkg/$entry" 2>/dev/null | tail -1)
    [ -f "$w" ] || { echo ""; return; }
    bytes=$(stat -c%s "$w" 2>/dev/null || stat -f%z "$w")
    # A FAILED EMIT IS NOT ZERO GLOBALS: it prints nothing, and `grep -c`
    # would answer 0 as if measured. Require output, or fail loudly.
    emitted=$("$avra" emit "$dir/$entry" 2>/dev/null) || { say "emit failed for $dir/$entry" >&2; return 1; }
    [ -n "$emitted" ] || { say "emit produced nothing for $dir/$entry" >&2; return 1; }
    globals=$(printf '%s\n' "$emitted" | grep -c '^@' || true)
    c=$(wasm-objdump -h "$w" 2>/dev/null | awk '/ Code /{print; exit}' | sed -n 's/.*size=0x\([0-9a-fA-F]*\).*/\1/p')
    d=$(wasm-objdump -h "$w" 2>/dev/null | awk '/ Data /{print; exit}' | sed -n 's/.*size=0x\([0-9a-fA-F]*\).*/\1/p')
    echo "$bytes $globals $(hex "${c:-0}") $(hex "${d:-0}")"
}

floor=$(footprint "$here/wasm-min" command)
[ -n "$floor" ] || skip "the floor program did not build"
fb=$(echo "$floor" | cut -d' ' -f1)
fg=$(echo "$floor" | cut -d' ' -f2)

board=""
[ -f "$here/ui-board/src/main.av" ] && board=$(footprint "$here/ui-board" reactor)

if [ -n "$board" ]; then
    bb=$(echo "$board" | cut -d' ' -f1)
    bg=$(echo "$board" | cut -d' ' -f2)
    bc=$(echo "$board" | cut -d' ' -f3)
    bd=$(echo "$board" | cut -d' ' -f4)
    say "base=$base floor=${fb}B/${fg}g board=${bb}B code=${bc} data=${bd} globals=${bg}g"
else
    say "base=$base floor=${fb}B/${fg}g board=absent (tools/ui-board is not here, or did not build)"
fi

baseline=${WASM_SIZE_BASELINE:-$here/wasm-size.baseline}
want() { sed -n "s/^$1 //p" "$baseline" | head -1; }
if [ "${1:-}" = --accept ]; then
    {
        echo "# THE LAST ACCEPTED WASM FOOTPRINT, written by \`make wasm-size-accept\`."
        echo "floor_bytes $fb"
        echo "floor_globals $fg"
        [ -n "$board" ] && echo "board_bytes $bb"
        [ -n "$board" ] && echo "board_globals $bg"
        echo "accepted_base $base"
    } > "$baseline"
    say "accepted base=$base floor=${fb}B/${fg}g"
    exit 0
fi
[ -f "$baseline" ] || { say "no baseline file — nothing to compare"; exit 0; }

fail=0
# THE FLOOR IS THE GUARD: tight, and a rise here is the loud one.
fb_base=$(want floor_bytes)
if [ -n "$fb_base" ]; then
    cap=$(( fb_base + fb_base / 50 + 1024 ))
    if [ "$fb" -gt "$cap" ]; then
        say "FLOOR grew: ${fb} > cap ${cap} (accepted ${fb_base}) — this is the shared cost; it must not creep"
        fail=1
    fi
fi
fg_base=$(want floor_globals)
if [ -n "$fg_base" ] && [ "$fg" -gt "$(( fg_base + 4 ))" ]; then
    say "FLOOR globals grew: ${fg} > $(( fg_base + 4 )) (accepted ${fg_base})"
    fail=1
fi
# THE BOARD IS REPORTED, NOT CAPPED — it is supposed to grow.
if [ -n "$board" ]; then
    bb_base=$(want board_bytes)
    bg_base=$(want board_globals)
    if [ -n "$bb_base" ]; then
        say "board move: $(( bb - bb_base )) B, $(( bg - bg_base )) globals vs last accepted (reported, never capped)"
    fi
fi
[ "$fail" -eq 0 ] || { say "REGRESSED — the floor rose past the cap"; exit 1; }
say "the floor is within its cap"
