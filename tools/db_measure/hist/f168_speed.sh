#!/bin/sh
# avra-8sb5.57.168, part three: cold speed rounds, alternating, on the
# binaries part two built. base cold1=465.970 user is already recorded;
# this adds cand1, base2, cand2 so each has two samples.
set -u
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-6000}
tree=$(pwd)
pkg=packages/cli
aside() { find "$tree" "$tree/packages/cli" -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null; }
run() {
  aside
  TIMEFORMAT="$1 cold$3 %R real %U user %S sys"
  { time "$2" check "$pkg" > /dev/null 2>&1 ; } 2>&1
}
run cand build/avra.cand168 1
run base build/avra.base168 2
run cand build/avra.cand168 2
echo "== speed done =="
