#!/bin/sh
# The wasm runtime archive's law, counted rather than assumed: it carries the
# runtime minus the two objects that HAVE no wasm body. A fiber switches
# stacks and a core forks, so neither may appear — and a program links only
# the members it reaches, so an unreached one costs nothing anyway.
set -eu

tree=$(cd "$(dirname "$0")/.." && pwd)
lib=$tree/build/wasm32/libavra_runtime.a

[ -f "$lib" ] || { echo "wasm-archive: no archive at $lib — run 'make wasm-runtime'"; exit 1; }

members=$(ar t "$lib")
echo "wasm-archive: $lib ($(echo "$members" | wc -l | tr -d ' ') member(s))"

fail=0
for banned in avra_fiber avra_cores; do
    if echo "$members" | grep -q "$banned"; then
        echo "wasm-archive: the archive carries $banned, which has no wasm body" >&2
        fail=1
    fi
done
for needed in avra_runtime; do
    if ! echo "$members" | grep -q "$needed"; then
        echo "wasm-archive: the archive is missing $needed" >&2
        fail=1
    fi
done
# THE INSTRUMENTS ARE NOT IN IT: each is switched on by an environment name,
# and a runtime built without them spells none. `WASM_INSTRUMENTS=1` is the
# archive that carries them, and then every name is there.
# An archive is its members end to end, so the names are read from it whole.
want=${WASM_INSTRUMENTS:-0}
switches=0
for name in AVRA_MEM_STATS AVRA_RC_GUARD AVRA_ALIAS_LOG AVRA_HASH_SEED; do
    if grep -q "$name" "$lib"; then
        switches=$((switches + 1))
        [ "$want" = 1 ] || { echo "wasm-archive: the archive reads $name — it was built with the instruments" >&2; fail=1; }
    else
        [ "$want" = 0 ] || { echo "wasm-archive: WASM_INSTRUMENTS=1, and the archive does not read $name" >&2; fail=1; }
    fi
done
[ "$fail" -eq 0 ] || exit 1
echo "wasm-archive: no fiber, no core, $switches of 4 instrument switches"
