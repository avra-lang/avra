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
work=${WASM_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/avra-whost.XXXXXX")}
wasm_who=wasm-host-check; . "$here/lib/wasm.sh"
. "$here/jspi_node.sh"

needs_compiler
needs "$node"
needs_wasm_clang
needs wasm-opt
wasm_ready || skip "the wasm runtime archive did not build"

"$node" --no-warnings --experimental-wasm-jspi "$tree/runtime/dom/tasks_unit_test.js"
# both hosts against one freestanding module: JSPI against the plain build, asyncify against the asyncified one
clang --target=wasm32 -O2 -nostdlib -Wl,--no-entry -Wl,--export-table -Wl,--allow-undefined -o "$work/proxy.wasm" "$here/wasm-host/proxy.c" || { say "the proxy module did not build"; exit 1; }
wasm-opt --enable-sign-ext --enable-mutable-globals --enable-bulk-memory --enable-nontrapping-float-to-int -O2 --asyncify --pass-arg=asyncify-imports@avra_host.switch,avra_host.idle "$work/proxy.wasm" -o "$work/proxy.asyncify.wasm" || { say "the proxy did not asyncify"; exit 1; }
"$node" --no-warnings --experimental-wasm-jspi "$tree/runtime/dom/tasks_proxy_test.js" "$work/proxy.wasm" "$work/proxy.asyncify.wasm"
cp -R "$here/wasm-host" "$work/pkg"
"$avra" build --target wasm32 --wasm_reactor "$work/pkg" >"$work/build.out" 2>"$work/build.err" || { say "the reactor did not build"; cat "$work/build.err" >&2; exit 1; }
wasm=$(grep -v '\.asyncify\.wasm$' "$work/build.out" | tail -1)
[ -f "$wasm" ] || { say "no .wasm was written ($wasm)"; exit 1; }
"$node" --no-warnings --experimental-wasm-jspi "$tree/runtime/dom/tasks_test.js" "$wasm"
