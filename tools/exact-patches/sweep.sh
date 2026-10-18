#!/bin/sh
# The oracle's driver: for each seed, the generated program runs as a package
# on a headless screen with the full paint as the reference, once with
# AVRA_EXACT unset and once set, and the frames of every turn must match byte
# for byte. A seed that differs, or a program the compiler refuses, fails the
# sweep. Each run gets its own package directory, so no kept answer of one
# mode is read as the other's.
# usage: sh tools/exact-patches/sweep.sh [first-seed] [last-seed] [avra-binary]
set -eu
cd "$(dirname "$0")/../.."
first=${1:-1}
last=${2:-20}
avra=${3:-build/avra-try}
gen=tools/exact-patches/src/main
[ -x "$gen" ] || "$avra" build tools/exact-patches > /dev/null
work=$(mktemp -d)
bad=0
seed=$first
while [ "$seed" -le "$last" ]; do
    "$gen" package "$seed" "$work/ref$seed" > /dev/null
    "$gen" package "$seed" "$work/exact$seed" > /dev/null
    ref=$(env -u AVRA_EXACT "$avra" run "$work/ref$seed" 2>&1 | sed -n '/^column/,$p' || true)
    got=$(AVRA_EXACT=1 "$avra" run "$work/exact$seed" 2>&1 | sed -n '/^column/,$p' || true)
    if [ "$ref" != "$got" ] || ! printf '%s\n' "$ref" | grep -q '^column'; then
        echo "seed $seed: frames differ or the program did not run"
        bad=$((bad + 1))
    fi
    seed=$((seed + 1))
done
echo "exact-patches sweep: seeds $first..$last, $bad failing (work in $work)"
[ "$bad" -eq 0 ]
