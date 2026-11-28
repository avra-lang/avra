#!/bin/sh
# tool-witness: run by the gate's witness-b slice
# A PAGE'S WASM CLOSURE REACHES NO PACKAGE C THAT HAS NO WASM BODY, read on a host with no wasm
# toolchain and nothing linked: the page's IR (`avra emit`) declares each symbol its reached fns
# call, and no package whose manifest names objects but no `wasm_objects` may define one of them —
# the wasm build's own refusal (backend/llvm.av `wasm_missing`), which a gate with no wasm run never
# reaches.
#   ui-board                   the board's page: reaches none
#   page-closure/hashes        a page hashing through @std/hash's C: caught, naming std-hash
#   sh tools/witness_page_closure.sh [compiler]
. "$(dirname "$0")/lib/scratch.sh"
set -u
. "$(dirname "$0")/lib/tree.sh"
[ $# -gt 0 ] && avra=$1
[ -x "$avra" ] || { echo "page-closure: no compiler at $avra"; exit 1; }
scratch_dir work
export LC_ALL=C

# `<symbol> <package>` for each symbol a package without a wasm body defines in its own objects.
unbodied() {
    for m in "$tree"/packages/*/avra.toml; do
        pkg=$(basename "$(dirname "$m")")
        [ -z "$(sh "$here/manifest_objects.sh" --wasm "$pkg")" ] || continue
        for o in $(sh "$here/manifest_objects.sh" "$pkg"); do
            [ -f "$tree/$o" ] || (cd "$tree" && make -s "$o" > /dev/null 2>&1) || {
                echo "page-closure: $o did not build" >&2
                return 1
            }
            nm --defined-only -g "$tree/$o" 2> /dev/null | awk -v p="$pkg" '$2 ~ /^[TD]$/ { print $3, p }'
        done
    done | sort -u
}

# check <page under tools/> <package it must name, or none>
check() {
    if ! (cd "$tree" && AVRA_PROGRAM_NET=0 "$avra" emit "tools/$1") > "$work/ir.ll" 2> "$work/emit.err"; then
        echo "page-closure: $1 did not emit"
        tail -3 "$work/emit.err"
        return 1
    fi
    sed -n 's/^declare [^@]*@\([A-Za-z0-9_$.]*\).*/\1/p' "$work/ir.ll" | sort -u > "$work/reached"
    join "$work/reached" "$work/unbodied" > "$work/carried"
    if [ "$2" = none ]; then
        [ ! -s "$work/carried" ] && return 0
        echo "page-closure: $1 reaches package C a wasm module has no body for (symbol, package):"
        cat "$work/carried"
        return 1
    fi
    awk -v p="$2" '$2 == p { found = 1 } END { exit !found }' "$work/carried" && return 0
    echo "page-closure: $1 reaches $2's C, and the witness did not say so"
    return 1
}

unbodied > "$work/unbodied" || exit 1
[ -s "$work/unbodied" ] || { echo "page-closure: no package without a wasm body defines a symbol, so nothing is read"; exit 1; }
failed=0
check ui-board none || failed=1
check page-closure/hashes std-hash || failed=1
[ "$failed" = 0 ] && echo "page-closure: the board reaches no package C without a wasm body; a page that hashes is caught"
exit "$failed"
