#!/bin/sh
# The exact path's own tests, run natively under AVRA_EXACT=check: each program
# in std-ui's realize/dom/tests that has a `.check` file must print exactly
# that, which names how many turns the exact path answered and how many it
# declined. With the flag unset the same programs print their `.expected`
# (the path is off), so eval == native == expected holds for the suite as it is.
# usage: sh tools/exact-patches/check_tests.sh [avra-binary]
set -eu
cd "$(dirname "$0")/../.."
avra=${1:-build/avra-try}
bad=0
n=0
for check in packages/std-ui/src/realize/dom/tests/*/*.check; do
    src=${check%.check}.av
    "$avra" build "$src" > /dev/null 2>&1 || { echo "build failed: $src"; bad=$((bad + 1)); continue; }
    got=$(AVRA_EXACT=check "${src%.av}" 2>&1 || true)
    want=$(cat "$check")
    n=$((n + 1))
    if [ "$got" != "$want" ]; then
        echo "$src under AVRA_EXACT=check:"
        echo "  want: $want"
        echo "  got:  $got"
        bad=$((bad + 1))
    fi
done
echo "exact-patches check tests: $n program(s), $bad failing"
[ "$bad" -eq 0 ]
