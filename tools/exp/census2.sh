#!/bin/sh
# make census CMD="check packages/cli" on the tree with B2's runtime, then on
# the same tree with rung A's runtime files swapped in, and the counts side by
# side. The shipping runtime is rebuilt on exit by the census itself.
set -u
cd "$(dirname "$0")/../.."
cp build/avra.base build/avra
run() {
  tag=$1
  make census CMD="check packages/cli" > "build/census-$tag.out" 2>&1
  echo "census $tag rc=$?"
}
run B2
mkdir -p build/B2files
for f in avra_box.h avra_runtime.c avra_hot.c avra_rt.h; do cp runtime/$f build/B2files/$f; cp tools/exp/A_runtime/runtime/$f runtime/$f; done
run A
for f in avra_box.h avra_runtime.c avra_hot.c avra_rt.h; do cp build/B2files/$f runtime/$f; done
for t in B2 A; do echo "== $t"; grep -a "^rc:\|^list\|^boxes\|retains\|releases\|writes" build/census-$t.out | head -8; done
