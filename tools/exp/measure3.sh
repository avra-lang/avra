#!/bin/sh
# Experiment: cost of a box version in the runtime's slot write leaves, in
# two forms. base = the tree's runtime; counter = exp2.patch (version + 1);
# epoch = exp3.patch (version = the global epoch). Cold `check packages/cli`
# wall, alternating all three, on identical input; then the leaves' code.
set -eu
cd "$(dirname "$0")/../.."
build() {
    make avra > "build/exp-$1-build.out" 2>&1 || { tail -20 "build/exp-$1-build.out"; exit 1; }
    cp build/avra "build/avra.$1"
}
build base
git apply tools/exp/exp2.patch
build counter
git apply -R tools/exp/exp2.patch
git apply tools/exp/exp3.patch
build epoch
git apply -R tools/exp/exp3.patch
cp build/avra.base build/avra
for i in 1 2 3 4; do
  for which in base counter epoch; do
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
    objdump -d --disassemble-symbols=$f "build/avra.$which" | sed -n 1,22p
  done
done
