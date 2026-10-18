#!/bin/sh
# B2's leaf code and the write leaf's cost against A's runtime (B2 is built).
set -eu
cd "$(dirname "$0")/../.."
(cd tools/exp/A_runtime/runtime && for f in avra_runtime avra_hot avra_fiber avra_cores; do cc -c -O2 -fPIC -fstack-clash-protection -ffunction-sections -fdata-sections -o /tmp/A_$f.o $f.c; done)
cc -O2 -o build/bench_A tools/exp/bench_touch.c /tmp/A_avra_runtime.o /tmp/A_avra_hot.o /tmp/A_avra_fiber.o /tmp/A_avra_cores.o -Wl,--unresolved-symbols=ignore-all -lm -lpthread -ldl
cc -O2 -DWITH_OBS -o build/bench_B2 tools/exp/bench_touch.c build/libavra_runtime.a -Wl,--unresolved-symbols=ignore-all -lm -lpthread -ldl
for i in 1 2 3; do echo "A:"; build/bench_A; echo "B2:"; build/bench_B2; done
