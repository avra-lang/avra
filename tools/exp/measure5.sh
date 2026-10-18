#!/bin/sh
# Rung B (observed bit + change log), built by rung A's product: the cold cli
# check against base and A, then the write leaf's three states in C, B against
# the A runtime.
set -eu
cd "$(dirname "$0")/../.."
cp build/avra.A build/avra
make avra > build/exp-B-build.out 2>&1 || { tail -20 build/exp-B-build.out; echo "B: build failed"; exit 1; }
cp build/avra build/avra.B
rm -rf .avra-cache
build/avra.B check packages/std-text > build/exp-B-run.out 2>&1 && echo "B: runs" || { echo "B: crashes"; exit 1; }
cp build/avra.base build/avra
for i in 1 2 3 4 5; do
  for which in base A B; do
    rm -rf .avra-cache
    s=$(date +%s%N)
    build/avra.$which check packages/cli > /dev/null 2>&1 || echo "$which rc=$?"
    e=$(date +%s%N)
    echo "$which $(( (e - s) / 1000000 ))"
  done
done
cc -O2 -o build/bench_touch tools/exp/bench_touch.c build/libavra_runtime.a -lm -lpthread -ldl 2>&1 | tail -3
build/bench_touch
for f in avra_slot_set avra_slot_unique; do
  echo "== $f (B)"
  objdump -d --disassemble=$f build/avra.B | grep -a '^ ' | cut -f3 | head -20
done
