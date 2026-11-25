#!/bin/sh
set -u
B=build/avra.tip
D=$(mktemp -d)
AVRA_CACHE_DIR=$D AVRA_CAS_PHASE=put AVRA_QTRACE=1 $B test --time packages/std-avrac/src/compiler/tests/cas_phase_test.av > build/cp.out 2> build/cp.q
echo "cas_phase put: $(tail -1 build/cp.out)"; grep -a "hold was refused\|discarded:" build/cp.out build/cp.q | cut -c1-220 | head -4
grep -a "^Q	attempt" build/cp.q | head
