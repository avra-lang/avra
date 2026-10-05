#!/bin/sh
# The M1 host seam's proof: `avra build --target wasm` on a program that
# declares a host row `extern` and an `export fn` must leave a module that
# IMPORTS that row from `avra:rt` and EXPORTS the handler under its written
# name, the length accessor the glue reads the header through, and memory.
# `--wasm-reactor` must drop `_start` (no `main`), keep the exports, and export
# the program's own statements as `avra_main` for the host to run.
#
# The module cannot run under plain WASI — its import is the browser host's to
# satisfy — so this inspects the module instead, with wasm-objdump.
#
# Skips, spoken, when the wasm toolchain or wabt is absent.
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
command -v wasm-opt >/dev/null 2>&1 || skip "wasm-opt (binaryen) not on PATH"
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
need_import() { grep -q "$1" "$work/objdump.txt" || { say "not imported: $1"; fail=1; }; }
need_export() { grep -q "\"$1\"" "$work/objdump.txt" || { say "not exported: $1"; fail=1; }; }
need_import 'avra:rt.*avra_dom_frame'
need_export 'avra_event'
need_export 'avra_bytes_len'
need_export 'memory'

# A reactor drops `_start` and keeps the exports the host calls.
if ! "$avra" build --target wasm --wasm_reactor "$work/seam" >"$work/reactor.out" 2>"$work/reactor.err"; then
    say "reactor build failed"; cat "$work/reactor.err" >&2; cat "$work/reactor.out" >&2; exit 1
fi
rwasm=$(tail -1 "$work/reactor.out")
wasm-objdump -x "$rwasm" >"$work/reactor.objdump" 2>&1
if ! grep -q '"avra_event"' "$work/reactor.objdump"; then say "reactor does not export avra_event"; fail=1; fi
if grep -q '"_start"' "$work/reactor.objdump"; then say "reactor still exports _start"; fail=1; fi
if ! grep -q '"avra_main"' "$work/reactor.objdump"; then say "reactor does not export avra_main"; fail=1; fi

if [ "$fail" -ne 0 ]; then
    say "--- imports/exports ---"; grep -iE "import|export" "$work/objdump.txt" | head -20
    exit 1
fi
say "seam ok: avra:rt.avra_dom_frame imported; avra_event, avra_bytes_len, memory exported; reactor drops _start and exports avra_main"
