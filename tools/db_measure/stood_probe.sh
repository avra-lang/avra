# Cold check then build under AVRA_QTRACE: whether the build's object keys stand in the store, and what the check kept.
cd "$(dirname "$0")/../.."
S=build/stood
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.stood.$$.$i"
done
AVRA_QTRACE=1 ./avra check packages/cli > /dev/null 2> $S/check.err; echo "check exit $?"
grep -P '^Q\tkept' $S/check.err
AVRA_QTRACE=1 ./avra build packages/cli > /dev/null 2> $S/build.err; echo "build exit $?"
echo "build keyed files: $(grep -c -P '^Q\tokey' $S/build.err)"
echo "stood: $(grep -c 'stood=true' $S/build.err)  not stood: $(grep -c 'stood=false' $S/build.err)"
