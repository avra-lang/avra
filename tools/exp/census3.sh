#!/bin/sh
# The census of rung A's runtime (B2's ran already), after the clean B2 perf
# rounds. Objects the first census removed are rebuilt first.
set -u
cd "$(dirname "$0")/../.."
sh tools/exp/perf3.sh
for f in avra_box.h avra_runtime.c avra_hot.c avra_rt.h; do cp runtime/$f build/B2files/$f; cp tools/exp/A_runtime/runtime/$f runtime/$f; done
make build/llvm_wrapper.o build/ffi.o build/libavra_runtime.a > build/census3-prep.out 2>&1 || tail -5 build/census3-prep.out
cp build/avra.base build/avra
make census CMD="check packages/cli" > build/census-A.out 2>&1
echo "census A rc=$?"
for f in avra_box.h avra_runtime.c avra_hot.c avra_rt.h; do cp build/B2files/$f runtime/$f; done
for t in B2 A; do echo "== $t"; grep -a "^rc:" build/census-$t.out | head -3; done
