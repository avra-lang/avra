#!/bin/sh
# Rung B with the two-instruction touch (the observed test is a byte compared
# in place): build it with rung A's product, check its leaf code, count
# instructions, branches and branch-misses on a cold cli check against base
# and A, and bench the write leaf against A's runtime.
set -eu
cd "$(dirname "$0")/../.."
cp tools/exp/box_B2.h runtime/avra_box.h
cp build/avra.A build/avra
make avra > build/exp-B2-build.out 2>&1 || { tail -20 build/exp-B2-build.out; echo "B2: build failed"; exit 1; }
cp build/avra build/avra.B2
rm -rf .avra-cache
build/avra.B2 check packages/std-text > build/exp-B2-run.out 2>&1 && echo "B2: runs" || { echo "B2: crashes"; exit 1; }
for f in avra_slot_set avra_slot_unique; do
  echo "== $f (B2)"
  objdump -d --disassemble=$f build/avra.B2 | grep -a '^ ' | cut -f3 | head -14
done
for i in 1 2 3; do
  for which in base A B2; do
    rm -rf .avra-cache
    perf stat -x, -e instructions,branches,branch-misses -o "build/perf-$which-$i.txt" build/avra.$which check packages/cli > /dev/null 2>&1 || echo "$which rc=$?"
    echo "$which $(grep -a instructions build/perf-$which-$i.txt | cut -d, -f1) $(grep -a ',branches' build/perf-$which-$i.txt | cut -d, -f1) $(grep -a branch-misses build/perf-$which-$i.txt | cut -d, -f1)"
  done
done
(cd tools/exp/A_runtime/runtime && for f in avra_runtime avra_hot avra_fiber avra_cores; do cc -c -O2 -fPIC -fstack-clash-protection -ffunction-sections -fdata-sections -o /tmp/A_$f.o $f.c; done)
cc -O2 -o build/bench_A tools/exp/bench_touch.c /tmp/A_avra_runtime.o /tmp/A_avra_hot.o /tmp/A_avra_fiber.o /tmp/A_avra_cores.o -lm -lpthread -ldl
cc -O2 -DWITH_OBS -o build/bench_B2 tools/exp/bench_touch.c build/libavra_runtime.a -lm -lpthread -ldl
for i in 1 2 3; do echo "A:"; build/bench_A; echo "B2:"; build/bench_B2; done
