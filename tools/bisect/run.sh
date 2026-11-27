#!/bin/sh
# cutoff-witness over program alone, then over program with each suspect applied alone.
set -u
cp build/avra build/avra.base
run() {
    echo "== $1: $(date +%T)"
    make -s -o avra cutoff-witness > "build/bisect-$1.log" 2>&1; echo "== $1 witness status $?"
    grep -E 'cutoff-witness:|FAIL|ok ' "build/bisect-$1.log" | tail -4
}
run base
for c in e66fd1d2 dae2d9b2 5c6a69fd 76b5c592; do
    cp build/avra.base build/avra
    git apply tools/bisect/$c.patch || { echo "== $c does not apply"; continue; }
    if make -s avra > "build/bisect-$c-build.log" 2>&1; then run "$c"; else echo "== $c: compiler did not build"; tail -20 "build/bisect-$c-build.log"; fi
    git apply -R tools/bisect/$c.patch
done
cp build/avra.base build/avra
