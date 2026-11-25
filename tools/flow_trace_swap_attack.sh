#!/bin/sh
# A COMPILER SWAP COSTS FLOW-TRACE NO SITE. The fixtures' stores outlive the compiler that wrote
# them, so the first flow-trace after a swap builds over a standing world whose kept keys name
# nothing the new compiler makes: every object lands in the overlay. Held here with two compilers
# of one code and two identities — the compiler, and a copy one byte longer, whose print and so
# every key differ — swapped in place of build/avra: flow-trace run ONCE after each swap names
# every spawn at its file and line (0 refused), the swap made back and forth.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=flow-trace-swap-attack
. tools/lib/steps.sh
here=build/avra
keep=build/.flow-trace-swap-own
other=build/.flow-trace-swap-other
cp "$here" "$keep" && cp "$here" "$other" && printf 'x' >> "$other"
trap 'cp "$keep" "$here.swap" && mv "$here.swap" "$here"; find "$keep" "$other" build/..flow-trace-swap-own.print build/..flow-trace-swap-other.print -delete 2>/dev/null' EXIT
for c in "$other" "$keep" "$other"; do
    cp "$c" "$here.swap" && mv "$here.swap" "$here"
    said=$(make -s -o avra flow-trace 2>&1)
    case "$said" in
        *" 0 refused"*) say "flow-trace once after a swap to $(basename "$c"): every spawn at its place" ;;
        *) fail "flow-trace once after a swap to $(basename "$c"): $(echo "$said" | grep -E 'not |refused' | head -3 | tr '\n' ' ')" ;;
    esac
done
verdict
