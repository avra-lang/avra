#!/bin/sh
# What a non-host target does with a row or a package it has no body for: a
# core ROW, or a package whose manifest names no `wasm_objects`, is
# refused BY NAME — never a linker's "undefined symbol", which accuses the
# innocent. A package that DOES name a wasm object links instead.
set -eu

. "$(dirname "$0")/lib/tree.sh"
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-refuses.XXXXXX")}

wasm_who=wasm-refuses; . "$here/lib/wasm.sh"
[ -x "$avra" ] || { say "no compiler at $avra"; exit 1; }
needs_wasm_clang
needs wasm-opt
wasm_ready || { say "the package wasm objects did not build"; exit 1; }

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

# A package that names a wasm object must LINK, not refuse; so must a program
# whose only mention of a row this target lacks sits in a body nothing reaches,
# and one that stands on a package's C without calling any of it.
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
check package '@std/process' || fail=1
builds spawn || fail=1
builds io || fail=1
builds unreached || fail=1
builds untouched || fail=1
builds time || fail=1
check sqlite_call '@std/sqlite (`@std.sqlite.opened` calls `avra_sqlite_sleeps_held`)' || fail=1
builds model_text || fail=1
[ "$fail" -eq 0 ] || exit 1
say "refusals speak, and a wasm-named package links"
