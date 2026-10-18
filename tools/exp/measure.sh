#!/bin/sh
# Experiment: cost of the header version bump (exp2.patch) in the runtime's
# slot write leaves. base = the tree's runtime. Cold `check packages/cli`
# wall, alternating, on identical input; then the leaves' disassembly.
set -eu
cd "$(dirname "$0")/../.."
make avra > build/exp-base-build.out 2>&1 || { tail -20 build/exp-base-build.out; exit 1; }
cp build/avra build/avra.base
git apply tools/exp/exp2.patch
make avra > build/exp-build.out 2>&1 || { tail -20 build/exp-build.out; exit 1; }
cp build/avra build/avra.exp
cp build/avra.base build/avra
for i in 1 2 3 4; do
  for which in base exp; do
    rm -rf .avra-cache
    s=$(date +%s.%N)
    build/avra.$which check packages/cli > /dev/null 2>&1 || true
    e=$(date +%s.%N)
    echo "$which $(echo "$e - $s" | bc)"
  done
done
for f in avra_slot_set avra_slot_unique avra_rc_retain; do
  echo "== $f (exp)"
  objdump -d --disassemble-symbols=$f build/avra.exp | sed -n 1,24p
  echo "== $f (base)"
  objdump -d --disassemble-symbols=$f build/avra.base | sed -n 1,24p
done
