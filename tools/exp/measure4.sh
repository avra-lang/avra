#!/bin/sh
# Experiment, the ladder form: rung A (every kind read through avra_kind)
# built by the standing compiler, then rung B (the version in the kind word's
# other bytes) built by rung A's product, in two forms: counter (version + 1)
# and epoch (version = the global epoch). Then cold `check packages/cli`
# wall, alternating all four, on identical input, and the leaves' code.
set -eu
cd "$(dirname "$0")/../.."
build() {
    make avra > "build/exp-$1-build.out" 2>&1 || { tail -20 "build/exp-$1-build.out"; echo "$1: build failed"; exit 1; }
    cp build/avra "build/avra.$1"
}
cp build/avra.base build/avra
build A
cold() { rm -rf .avra-cache; build/avra.$1 check packages/std-text > "build/exp-$1-run.out" 2>&1 && echo "$1: runs" || { echo "$1: crashes"; exit 1; }; }
cold A
cp build/avra.A build/avra
git apply tools/exp/rungB_counter.patch
build counter
git apply -R tools/exp/rungB_counter.patch
cold counter
cp build/avra.A build/avra
git apply tools/exp/rungB_epoch.patch
build epoch
git apply -R tools/exp/rungB_epoch.patch
cold epoch
cp build/avra.base build/avra
for i in 1 2 3 4; do
  for which in base A counter epoch; do
    rm -rf .avra-cache
    s=$(date +%s.%N)
    build/avra.$which check packages/cli > /dev/null 2>&1 || true
    e=$(date +%s.%N)
    echo "$which $(echo "$e - $s" | bc)"
  done
done
for f in avra_slot_set avra_slot_unique avra_rc_retain; do
  for which in base counter epoch; do
    echo "== $f ($which)"
    objdump -d --disassemble=$f "build/avra.$which" | grep -a '^ ' | cut -f3 | head -16
  done
done
