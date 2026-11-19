#!/bin/sh
# ONE DECLARATION OF "NO WASM BODY". A runtime row marked `wasm: false` claims
# the runtime does not carry it on a non-host target — a core, or a wait on a
# descriptor or a signal, which a hosted scheduler has no poller for — and the
# Makefile excludes avra_cores.c from the archive (avra_fiber.c is in, hosted).
# If the two drift, either a reachable row links to nothing or a body is
# dropped for no reason. This is the keeper that ties them.
set -eu
tree=$(cd "$(dirname "$0")/.." && pwd)
rows=$(cd "$tree" && awk '/name: "/{ n=$0; sub(/.*name: "/,"",n); sub(/".*/,"",n) } /wasm: false/{ print n }' packages/std-avrac/src/core/runtime_api.av)
[ -n "$rows" ] || { echo "wasm-body: no row says wasm: false — the column is unread"; exit 1; }
excluded=$(cd "$tree" && sed -n 's/^WASM_RUNTIME_SRCS :=.*filter-out \(.*\),\$(wildcard.*/\1/p' Makefile)
# A definition is accounted for when its file is not in the wasm archive, when
# the file itself branches on wasm to a hosted mode (`define AVRA_HOSTED`), or
# when a conditional naming __wasm32__ encloses it (its stub or refusal).
accounted=$(cd "$tree" && for f in runtime/*.c; do
    if [ "$f" = "$excluded" ] || grep -q '^#define AVRA_HOSTED' "$f"; then awk -v f="$f" '/^[A-Za-z_].*[ *][A-Za-z_0-9]+\(/{ n=$0; sub(/\(.*/,"",n); sub(/.*[ *]/,"",n); print n }' "$f"; continue; fi
    awk '
        /^#[ \t]*if/ { d++; w[d] = ($0 ~ /__wasm32__/) }
        /^#[ \t]*el(se|if)/ { if ($0 ~ /__wasm32__/) w[d] = 1 }
        /^#[ \t]*endif/ { d-- }
        /^[A-Za-z_].*[ *][A-Za-z_0-9]+\(/ {
            g = 0; for (i = 1; i <= d; i++) g += w[i]
            if (g) { n=$0; sub(/\(.*/,"",n); sub(/.*[ *]/,"",n); print n }
        }' "$f"
done | sort -u)
fail=0
for s in $rows; do
    if ! printf '%s\n' "$accounted" | grep -qx "$s"; then
        echo "wasm-body: \`$s\` says wasm: false, but no body of it sits under a __wasm32__ guard or in an excluded file" >&2
        fail=1
    fi
done
case "$excluded" in
    "runtime/avra_cores.c") : ;;
    *) echo "wasm-body: the Makefile must exclude exactly runtime/avra_cores.c — found: $excluded" >&2; fail=1 ;;
esac
[ "$fail" -eq 0 ] || exit 1
echo "wasm-body: $(echo "$rows" | wc -l | tr -d ' ') row(s) and the archive exclusion agree"
