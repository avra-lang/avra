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
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-wasm.XXXXXX")}
fixtures=$here/wasm-fixtures

say() { echo "wasm-check: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }
. "$here/jspi_node.sh"

[ -x "$avra" ] || skip "no compiler at $avra"
command -v "$node" >/dev/null 2>&1 || skip "node not on PATH"
command -v clang >/dev/null 2>&1 || skip "clang not on PATH"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
command -v wasm-opt >/dev/null 2>&1 || skip "wasm-opt (binaryen) not on PATH"

( cd "$tree" && make -s wasm-runtime wasm-packages ) || skip "the wasm runtime archive did not build"
# each fixture is built for the host too, and a gate job may hold only the compiler: the host
# runtime AND the package C objects and archives a fixture's `[link]` rows name (std_time.o)
sh "$here/wasm-host-objects.sh" "$tree"
# each fixture is built for the host too, and a gate job may hold only the compiler
if [ ! -f "$tree/build/libavra_runtime.a" ]; then
    ( cd "$tree" && make -s build/libavra_runtime.a ) || { say "the host runtime archive did not build"; exit 1; }
fi

# A module with tasks runs under JSPI; Node before it ships on needs the flag.
jspi=""
if "$node" --experimental-wasm-jspi -e 0 >/dev/null 2>&1; then jspi="--experimental-wasm-jspi"; fi

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
    if [ -f "$src/refuses.txt" ]; then
        # a fixture whose proof is a TRAP: native and wasm end with status 2 and the
        # words; the evaluator ends too, in its own words (its recursion limit)
        want=$(cat "$src/refuses.txt")
        ns=0
        ws=0
        "$native" >"$work/$name.native.out" 2>&1 || ns=$?
        "$node" --no-warnings $jspi "$here/wasm-node.mjs" "$wasm" >"$work/$name.wasm.out" 2>&1 || ws=$?
        fb="${wasm%.wasm}.asyncify.wasm"
        fs=0
        if [ -f "$fb" ]; then "$node" --no-warnings "$here/wasm-node.mjs" --asyncify "$fb" >"$work/$name.asyncify.out" 2>&1 || fs=$?; else fs=2; echo "(no fallback built)" >"$work/$name.asyncify.out"; fi
        if "$avra" run "$pkg" >/dev/null 2>&1; then say "$name: the evaluator ran it to the end, and it must refuse"; fail=1; continue; fi
        if [ "$ns" -eq 2 ] && [ "$ws" -eq 2 ] && [ "$fs" -eq 2 ] && grep -q "$want" "$work/$name.native.out" && grep -q "$want" "$work/$name.wasm.out" && grep -q "$want" "$work/$name.asyncify.out"; then
            say "$name: eval refuses; native, wasm and its fallback end 2 saying \`$want\`"
        else
            say "$name: native status $ns, wasm status $ws, and each must end 2 saying \`$want\`"
            tail -3 "$work/$name.native.out" "$work/$name.wasm.out" >&2
            fail=1
        fi
        continue
    fi
    "$avra" run "$pkg" >"$work/$name.eval.out" 2>"$work/$name.eval.err" || { say "$name: eval run failed"; cat "$work/$name.eval.err" >&2; fail=1; continue; }
    "$native" >"$work/$name.native.out" 2>&1 || true
    "$node" --no-warnings $jspi "$here/wasm-node.mjs" "$wasm" >"$work/$name.wasm.out" 2>"$work/$name.wasm.err" || true
    if [ -f "$src/expected.txt" ] && ! diff -u "$src/expected.txt" "$work/$name.native.out" >"$work/$name.diff" 2>&1; then
        say "$name: native stdout differs from its expected.txt (all three engines could share the mistake)"
        cat "$work/$name.diff" >&2
        fail=1
    elif ! diff -u "$work/$name.native.out" "$work/$name.wasm.out" >"$work/$name.diff" 2>&1; then
        say "$name: wasm stdout differs from native"
        cat "$work/$name.diff" "$work/$name.wasm.err" >&2
        fail=1
    elif ! diff -u "$work/$name.eval.out" "$work/$name.native.out" >"$work/$name.evaldiff" 2>&1; then
        say "$name: native stdout differs from the evaluator"
        cat "$work/$name.evaldiff" >&2
        fail=1
    else
        say "$name: eval == native == wasm"
        # THE FALLBACK says the same: a program that runs tasks has an asyncified twin
        fb="${wasm%.wasm}.asyncify.wasm"
        if [ -f "$fb" ]; then
            "$node" --no-warnings "$here/wasm-node.mjs" --asyncify "$fb" >"$work/$name.asyncify.out" 2>"$work/$name.asyncify.err" || true
            if diff -u "$work/$name.native.out" "$work/$name.asyncify.out" >"$work/$name.diff" 2>&1; then
                say "$name: ... and its asyncified fallback ($(stat -c%s "$wasm" 2>/dev/null || stat -f%z "$wasm") B clean, $(stat -c%s "$fb" 2>/dev/null || stat -f%z "$fb") B asyncified)"
            else
                say "$name: the asyncified fallback differs from native"
                cat "$work/$name.diff" >&2
                fail=1
            fi
        elif [ -f "$src/expected.txt" ] && grep -q "avra_host" "$wasm"; then
            say "$name: a program that runs tasks built no fallback"
            fail=1
        fi
    fi
done

[ "$fail" -eq 0 ] || exit 1
sh "$here/wasm-size-guard.sh"
say "all fixtures agree"
