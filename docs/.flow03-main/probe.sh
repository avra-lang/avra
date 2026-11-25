# run the probe, as a program test of std-http, under the compiler at build/avra
D=packages/std-http/src/tests/flow03_probe
mkdir -p $D
cp docs/.flow03-main/probe.av $D/flow03_probe.av
cp docs/.flow03-main/probe.expected $D/flow03_probe.expected
echo "== $1 probe, eval and native"
build/avra test $D > build/probe-$1.log 2>&1; echo "probe exit $?"
grep -vE "^\s*$" build/probe-$1.log | tail -12
rm -r $D
echo "== $1 std-http client_adversarial_test"
build/avra test packages/std-http/src/tests/client_adversarial_test.av > build/t-$1.log 2>&1; echo "test exit $?"; grep -E "passed|failed|FAIL" build/t-$1.log | tail -3
