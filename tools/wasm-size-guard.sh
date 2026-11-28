#!/bin/sh
# THE SIZE RECEIPT, on every wasm-check: what the target carries, section by
# section, printed UNCONDITIONALLY — a rise is visible before it is fatal.
#
# TWO QUANTITIES, TWO LAWS:
#   THE FLOOR (the minimal program) is the compiler's SHARED cost and must not
#   creep; its row is exact within its toolchain and a floor rise is the loud regression.
#   THE BOARD (tools/ui-board, the board mounted on a page) is the UI library's SHOWCASE and is SUPPOSED to
#   grow with every component; its row is a `grows` row, TOLD with its move
#   against the last accepted value and NEVER judged — a cap there would train a
#   re-baseline on every feature, which is how a guard dies.
. "$(dirname "$0")/lib/scratch.sh"
set -eu
. "$(dirname "$0")/lib/tree.sh"
scratch_dir work
# WASM_TARGET names another wasm triple, for a machine whose sysroot is not the default's.
target=${WASM_TARGET:-wasm}
wasm_who=wasm-size-guard; . "$here/lib/wasm.sh"

needs_wasm_clang
needs wasm-opt
needs wasm-objdump
needs_compiler
wasm_ready || skip "the wasm runtime archive did not build"

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
    w=$(sh "$here/capped.sh" --last "$avra" build --target "$target" $flag "$work/pkg/$entry" 2>/dev/null) || w=""
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

# THE ROWS, judged by the ledger's reader (`wisp cost`, the record under cost/), keyed by the wasm
# toolchain: the floor's bytes and globals exact within their key, the board's told and never judged.
. "$here/lib/toolchain.sh"
key=$(wasm_toolchain_key)
rows=$tree/build/ledger/wasm-size
mkdir -p "$rows"
find "$rows" -mindepth 1 -delete
{
    echo "bytes:$key:wasm-floor bytes $fb"
    echo "bytes:$key:wasm-floor globals $fg"
    if [ -n "$board" ]; then
        echo "grows:$key:wasm-board bytes $bb"
        echo "grows:$key:wasm-board globals $bg"
        echo "grows:$key:wasm-board code $bc"
        echo "grows:$key:wasm-board data $bd"
    fi
} > "$rows/rows"
verb=judge
[ "${1:-}" != --accept ] || verb=accept
if [ "$verb" = accept ]; then exec sh "$here/../wisp" cost accept "$rows" "${2:-}"; else exec sh "$here/../wisp" cost "$verb" "$rows"; fi
