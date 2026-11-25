set -u
S=/tmp/claude-0/-home-user/b070374e-a97e-5ce7-b4c0-0401871fa94b/scratchpad/we
cd /work/cut45 && . /etc/profile.d/avra.sh && export AVRA_STORE_KEPT_HERE=1
step() { make avra > $S/lad54_$1.out 2>&1 && cp build/avra build/keep-$1 && echo "built $1 $(sha1sum build/avra | cut -c1-12)" || { echo "FAIL $1"; tail -20 $S/lad54_$1.out; exit 1; }; }
git checkout -q alloc54 || exit 1
cp build/keep-b53g2 build/avra
step h1
make rt-header rt-ns 2>&1 | tail -3
step h2
step h3
cmp -s build/keep-h2 build/keep-h3 && echo FIXPOINT || echo "NO FIXPOINT"
make runtime-tests > $S/rtt54.out 2>&1; echo "runtime-tests rc=$?"; grep -E "enum_wide|stride_list" $S/rtt54.out
./avra test packages/std-avrac/src/core/tests/runtime_counts_test.av 2>&1 | grep -E "tests passed|FAIL"
echo LADDERDONE
