#!/bin/sh
# The M1 host seam's proof: `avra build --target wasm` on a program that
# declares a host row `extern` and an `export fn` must leave a module that
# IMPORTS that row from `avra:rt` and EXPORTS the handler under its written
# name. The module cannot run under plain WASI — its import is the browser
# host's to satisfy — so this inspects the module instead, with wasm-objdump.
#
# Skips, spoken, when the wasm toolchain, node or wabt is absent.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-seam.XXXXXX")}

say() { echo "wasm-seam: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v clang >/dev/null 2>&1 || skip "clang not on PATH"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
command -v wasm-objdump >/dev/null 2>&1 || skip "wasm-objdump (wabt) not on PATH"
if [ ! -f "$tree/build/wasm32/libavra_runtime.a" ]; then
    ( cd "$tree" && make -s wasm-runtime ) || skip "the wasm runtime archive did not build"
fi

cp -R "$here/wasm-seam" "$work/seam"
if ! "$avra" build --target wasm "$work/seam" >"$work/build.out" 2>"$work/build.err"; then
    say "wasm build failed"; cat "$work/build.err" >&2; cat "$work/build.out" >&2; exit 1
fi
wasm=$(tail -1 "$work/build.out")
[ -f "$wasm" ] || { say "no .wasm was written ($wasm)"; exit 1; }

wasm-objdump -x "$wasm" >"$work/objdump.txt" 2>&1
fail=0
if ! grep -q 'avra:rt.*avra_dom_frame' "$work/objdump.txt"; then
    say "the host row is not imported from avra:rt"; grep -i "import" "$work/objdump.txt" | head; fail=1
fi
if ! grep -qE 'Export.*avra_event|avra_event' "$work/objdump.txt"; then
    say "avra_event is not exported"; fail=1
fi
if [ "$fail" -ne 0 ]; then
    say "--- imports/exports ---"; grep -iE "import|export" "$work/objdump.txt" | head -20
    exit 1
fi
say "seam ok: avra:rt.avra_dom_frame imported, avra_event exported"
