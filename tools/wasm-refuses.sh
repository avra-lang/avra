#!/bin/sh
# What a non-host target does with a row or a package it has no body for: a
# fiber or a core ROW, or a package whose manifest names no `wasm_objects`, is
# refused BY NAME — never a linker's "undefined symbol", which accuses the
# innocent. A package that DOES name a wasm object links instead.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-refuses.XXXXXX")}

say() { echo "wasm-refuses: $*" >&2; }
[ -x "$avra" ] || { say "no compiler at $avra"; exit 1; }
command -v clang >/dev/null 2>&1 || { say "clang not on PATH — skipped"; exit 0; }
clang --print-targets 2>/dev/null | grep -q wasm32 || { say "clang has no wasm32 target — skipped"; exit 0; }
command -v wasm-opt >/dev/null 2>&1 || { say "wasm-opt (binaryen) not on PATH — skipped"; exit 0; }
( cd "$tree" && make -s wasm-runtime wasm-packages ) || { say "the package wasm objects did not build"; exit 1; }

# fixture name -> the symbol the refusal must name
check() {
    name=$1
    want=$2
    rm -rf "$work/$name"
    cp -R "$here/wasm-refuses/$name" "$work/$name"
    if "$avra" build --target wasm "$work/$name" >"$work/$name.out" 2>"$work/$name.err"; then
        say "$name: the build succeeded, and it must refuse"
        return 1
    fi
    if ! cat "$work/$name.out" "$work/$name.err" | grep -q "a wasm module has no body for .*${want}"; then
        say "$name: the refusal does not name ${want}"
        cat "$work/$name.out" "$work/$name.err" | tail -3 >&2
        return 1
    fi
    say "$name: refused, naming ${want}"
}

# A package that names a wasm object must LINK, not refuse.
builds() {
    name=$1
    rm -rf "$work/$name"
    cp -R "$here/wasm-refuses/$name" "$work/$name"
    if ! "$avra" build --target wasm "$work/$name" >"$work/$name.out" 2>"$work/$name.err"; then
        say "$name: the build refused, and it must link"
        cat "$work/$name.out" "$work/$name.err" | tail -3 >&2
        return 1
    fi
    say "$name: linked"
}

fail=0
check fiber 'avra_task_spawn' || fail=1
check package '@std/process' || fail=1
builds io || fail=1
[ "$fail" -eq 0 ] || exit 1
say "refusals speak, and a wasm-named package links"
