#!/bin/sh
# The wasm proof: build each fixture package native and for wasm32, run both,
# and require identical stdout. Native equality with the evaluator is
# `avra test`'s job, so native == wasm here makes eval == native == wasm.
#
# The wasm toolchain is a BUILD dependency, not a source one: when `clang`
# cannot target wasm32 or `node` is absent the check SKIPS with a spoken
# reason — never silently green (CLAUDE.md, a check that examined nothing).
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
node=${NODE:-node}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-wasm.XXXXXX")}
fixtures=$here/wasm-fixtures

say() { echo "wasm-check: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v "$node" >/dev/null 2>&1 || skip "node not on PATH"
command -v clang >/dev/null 2>&1 || skip "clang not on PATH"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
command -v wasm-opt >/dev/null 2>&1 || skip "wasm-opt (binaryen) not on PATH"

if [ ! -f "$tree/build/wasm32/libavra_runtime.a" ]; then
    ( cd "$tree" && make -s wasm-runtime ) || skip "the wasm runtime archive did not build"
fi

fail=0
for src in "$fixtures"/*/; do
    name=$(basename "$src")
    pkg=$work/$name
    cp -R "$src" "$pkg"
    err=$work/$name.err
    if ! "$avra" build "$pkg" >"$work/$name.native.build" 2>"$err"; then
        say "$name: native build failed"; cat "$err" >&2; fail=1; continue
    fi
    native=$(tail -1 "$work/$name.native.build")
    if ! "$avra" build --target wasm32 "$pkg" >"$work/$name.wasm.build" 2>"$err"; then
        say "$name: wasm build failed"; cat "$err" >&2; fail=1; continue
    fi
    wasm=$(tail -1 "$work/$name.wasm.build")
    [ -f "$wasm" ] || { say "$name: no .wasm was written ($wasm)"; fail=1; continue; }
    "$avra" run "$pkg" >"$work/$name.eval.out" 2>"$work/$name.eval.err" || { say "$name: eval run failed"; cat "$work/$name.eval.err" >&2; fail=1; continue; }
    "$native" >"$work/$name.native.out" 2>&1 || true
    "$node" --no-warnings "$here/wasm-node.mjs" "$wasm" >"$work/$name.wasm.out" 2>"$work/$name.wasm.err" || true
    if ! diff -u "$work/$name.native.out" "$work/$name.wasm.out" >"$work/$name.diff" 2>&1; then
        say "$name: wasm stdout differs from native"
        cat "$work/$name.diff" >&2
        fail=1
    elif ! diff -u "$work/$name.eval.out" "$work/$name.native.out" >"$work/$name.evaldiff" 2>&1; then
        say "$name: native stdout differs from the evaluator"
        cat "$work/$name.evaldiff" >&2
        fail=1
    else
        say "$name: eval == native == wasm"
    fi
done

[ "$fail" -eq 0 ] || exit 1
say "all fixtures agree"
