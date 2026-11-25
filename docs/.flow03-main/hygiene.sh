# a user's `scope` inside a `within`, as a program test of std-time
D=packages/std-time/src/tests/flow03_hygiene
mkdir -p $D
cp docs/.flow03-main/hygiene.av $D/flow03_hygiene.av
cp docs/.flow03-main/hygiene.expected $D/flow03_hygiene.expected
build/avra test $D > build/hygiene.log 2>&1; echo "hygiene exit $?"
grep -E "proved|differ|expected|error" build/hygiene.log | tail -4
rm -r $D
