set -u
for k in vocab fingerprints rt-header rt-ns externs; do echo "## make $k"; make -s $k > /tmp/k.out 2>&1; echo "rc=$?"; tail -2 /tmp/k.out | cut -c1-250; done
echo "## suites"; build/avra test packages/std-avrac/src/features/defers packages/std-avrac/src/compiler/memory packages/std-avrac/src/compiler/soundness packages/std-avrac/src/compiler/backend 2>&1 | grep -E "tests passed|programs? proved|✗|native !=|eval !=|STOPPED" | head -20
