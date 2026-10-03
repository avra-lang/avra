#!/bin/sh
# ONE DECLARATION OF "NO WASM BODY". A runtime row marked `wasm: false` claims
# the runtime does not carry it on a non-host target — and the Makefile excludes
# avra_fiber.c and avra_cores.c from the archive. If the two drift, either a
# reachable row links to nothing or a body is dropped for no reason. This is
# the keeper that ties them.
set -eu
tree=$(cd "$(dirname "$0")/.." && pwd)
rows=$(cd "$tree" && awk '/name: "/{ n=$0; sub(/.*name: "/,"",n); sub(/".*/,"",n) } /wasm: false/{ print n }' packages/std-avrac/src/core/runtime_api.av)
[ -n "$rows" ] || { echo "wasm-body: no row says wasm: false — the column is unread"; exit 1; }
fail=0
for s in $rows; do
    if ! grep -qE "^[A-Za-z_].*[ *]$s\(" "$tree/runtime/avra_fiber.c" "$tree/runtime/avra_cores.c" 2>/dev/null; then
        echo "wasm-body: \`$s\` says wasm: false, but neither avra_fiber.c nor avra_cores.c defines it" >&2
        fail=1
    fi
done
excluded=$(cd "$tree" && sed -n 's/^WASM_RUNTIME_SRCS :=.*filter-out \(.*\),\$(wildcard.*/\1/p' Makefile)
case "$excluded" in
    *avra_fiber.c*avra_cores.c*|*avra_cores.c*avra_fiber.c*) : ;;
    *) echo "wasm-body: the Makefile does not exclude avra_fiber.c and avra_cores.c — found: $excluded" >&2; fail=1 ;;
esac
[ "$fail" -eq 0 ] || exit 1
echo "wasm-body: $(echo "$rows" | wc -l | tr -d ' ') row(s) and the archive exclusion agree"
