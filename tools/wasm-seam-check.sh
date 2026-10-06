#!/bin/sh
# The M1 host seam's proof: `avra build --target wasm` on a program that
# declares a host row `extern` and a host fn (an `extern fn` with a body) must
# leave a module that IMPORTS that row from `avra:rt` and EXPORTS the host fn
# under its own name, the length accessor the glue reads the header through,
# and memory. A HOST FN IS EXPORTED FROM WHEREVER IT IS DECLARED — a module
# the entry never names included — and an `export fn` is exported from
# nowhere: one nothing reaches is not in the module at all.
# `--wasm-reactor` must drop `_start` (no `main`), keep the exports, and export
# the program's own statements as `avra_main` for the host to run.
#
# The module cannot run under plain WASI — its import is the browser host's to
# satisfy — so this inspects the module instead, with wasm-objdump.
#
# The compiler finds the wasm toolchain or says what is missing (`avra build
# --target wasm` exits 2); this SKIPS, spoken, in its words then, and when
# wabt is absent.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-seam.XXXXXX")}
# WASM_TARGET names one wasm triple (default `wasm`: the one this machine's toolchain links).
target=${WASM_TARGET:-wasm}

say() { echo "wasm-seam: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v wasm-objdump >/dev/null 2>&1 || skip "wasm-objdump (wabt) not on PATH"
if [ ! -f "$tree/build/wasm32/libavra_runtime.a" ]; then
    ( cd "$tree" && make -s wasm-runtime wasm-packages ) >/dev/null 2>&1 || skip "the wasm runtime archive did not build"
fi

cp -R "$here/wasm-seam" "$work/seam"
"$avra" build --target "$target" "$work/seam" >"$work/build.out" 2>"$work/build.err" || built=$?
[ "${built:-0}" -ne 2 ] || skip "$(sed 's/^avra: //' "$work/build.err" | head -1)"
if [ "${built:-0}" -ne 0 ]; then
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
need_export 'avra_far_event'
no_export() { if grep -q "\"$1\"" "$work/objdump.txt"; then say "exported, and no host fn: $1"; fail=1; fi; }
no_export 'relayed'
no_export 'offered'
no_export 'reached'
no_export 'unreached'
# An `export fn` nothing reaches is not in the module, whoever imports its module.
if grep -q 'seam-offered' "$wasm"; then say "an unreached export's body is in the module"; fail=1; fi
if grep -q 'seam-unreached' "$wasm"; then say "an unreached export's body is in the module"; fail=1; fi
# A command module's `main` runs the statements: it exports no second door to them.
if grep -q '"avra_main"' "$work/objdump.txt"; then say "a command module exports avra_main"; fail=1; fi

# A reactor drops `_start` and keeps the exports the host calls.
if ! "$avra" build --target "$target" --wasm_reactor "$work/seam" >"$work/reactor.out" 2>"$work/reactor.err"; then
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
say "seam ok: avra:rt.avra_dom_frame imported; avra_event, avra_bytes_len, memory and a deeper module's host fn exported, no export fn exported and none carried unreached; reactor drops _start and exports avra_main"
