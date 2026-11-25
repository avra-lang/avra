# where a one-leaf `make try` goes: the build's own phases and the steps around it
cd "$(dirname "$0")/../.."
LEAF=packages/cli/src/commands/rules.av
make -s try >/dev/null 2>&1
for i in 1 2; do
  cp $LEAF build/leaf.keep; printf '\n// split %s\n' "$(date +%s%N)" >> $LEAF
  t0=$(date +%s%N); make -s try > build/split.out 2>&1; t1=$(date +%s%N)
  echo "make try (one leaf edit): $(( (t1-t0)/1000000 )) ms"
  grep -E "^time:" build/avra-try-build.out | cut -c1-400
  grep -A12 "^read:" build/avra-try-build.out | head -8 | cut -c1-160
  cp build/leaf.keep $LEAF
done
t0=$(date +%s%N); ./avra build --time packages/cli > build/split2.out 2>&1; echo "bare ./avra build (no edit, warm): $(( ($(date +%s%N)-t0)/1000000 )) ms"; grep "^time:" build/split2.out | cut -c1-300
t0=$(date +%s%N); cp build/avra-try build/split.copy; echo "cp binary: $(( ($(date +%s%N)-t0)/1000000 )) ms ($(du -h build/avra-try | cut -f1))"
t0=$(date +%s%N); ./avra --version >/dev/null 2>&1; echo "shim + binary start: $(( ($(date +%s%N)-t0)/1000000 )) ms"
