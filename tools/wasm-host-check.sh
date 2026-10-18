#!/bin/sh
# THE HOST HALF OF THE HOSTED SCHEDULER, under JSPI: tools/wasm-host is built as
# a reactor and runtime/dom/tasks_test.js drives it — a plain call that parks is
# refused in the scheduler's words, an entered one runs, and the artifact a page
# fetches follows what the host can suspend. SKIPS, spoken, where the toolchain
# or a JSPI Node is absent.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
node=${NODE:-node}
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-whost.XXXXXX")}
say() { echo "wasm-host-check: $*" >&2; }
skip() { say "$* — skipped"; exit 0; }

[ -x "$avra" ] || skip "no compiler at $avra"
command -v "$node" >/dev/null 2>&1 || skip "node not on PATH"
command -v clang >/dev/null 2>&1 || skip "clang not on PATH"
clang --print-targets 2>/dev/null | grep -q wasm32 || skip "clang has no wasm32 target"
command -v wasm-opt >/dev/null 2>&1 || skip "wasm-opt (binaryen) not on PATH"
"$node" --experimental-wasm-jspi -e 0 >/dev/null 2>&1 || skip "this Node has no JSPI"
[ -f "$tree/build/wasm32/libavra_runtime.a" ] || ( cd "$tree" && make -s wasm-runtime ) >/dev/null 2>&1 || skip "the wasm runtime archive did not build"

cp -R "$here/wasm-host" "$work/pkg"
"$avra" build --target wasm32 --wasm_reactor "$work/pkg" >"$work/build.out" 2>"$work/build.err" || { say "the reactor did not build"; cat "$work/build.err" >&2; exit 1; }
wasm=$(tail -1 "$work/build.out")
[ -f "$wasm" ] || { say "no .wasm was written ($wasm)"; exit 1; }
"$node" --no-warnings --experimental-wasm-jspi "$tree/runtime/dom/tasks_test.js" "$wasm"
