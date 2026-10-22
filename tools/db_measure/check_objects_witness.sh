# (a) cold build (reference), then cold check, then build over the check's store: held, phases, cmp.
cd "$(dirname "$0")/../.."
S=build/co
mkdir -p $S
clear() {
  i=0
  find . -name .avra-cache -type d -prune | while read -r d; do
    i=$((i + 1)); mv "$d" "build/aside.co.$1.$$.$i"
  done
}
clear ref
./avra build packages/cli > $S/ref.out 2>&1; echo "ref build exit $?"
cp packages/cli/src/main $S/ref.bin
clear chk
s=$(date +%s); ./avra check --time packages/cli > $S/check.out 2> $S/check.err; echo "cold check exit $? wall $(( $(date +%s) - s )) s"
grep -h "^time:" $S/check.out $S/check.err | tail -n 1 | cut -c1-400
s=$(date +%s); ./avra build --time packages/cli > $S/build.out 2> $S/build.err; echo "build after check exit $? wall $(( $(date +%s) - s )) s"
grep -h "^time:" $S/build.out $S/build.err | tail -n 1 | cut -c1-400
cp packages/cli/src/main $S/after.bin
cmp $S/ref.bin $S/after.bin && echo "binary: IDENTICAL to a cold build"
echo "ref $(wc -c < $S/ref.bin) bytes, after $(wc -c < $S/after.bin) bytes"
