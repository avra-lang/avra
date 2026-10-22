# t168 reference: std-avrac test-process peak on current main, and a warm
# one-edit `check packages/cli` phase line.
cd "$(dirname "$0")/../.." || exit 1

echo "== clear stores =="
n=0
find . -name .avra-cache -type d -prune | while read -r d; do
  n=$((n + 1))
  mv "$d" "build/aside.t168.$$.$n"
done

echo "== AVRA_MEM_STATS: expr_gathered_test (one file) =="
AVRA_MEM_STATS=1 ./avra test packages/std-avrac/src/core/tests/expr_gathered_test.av > build/t168mem.log 2>&1
echo "exit $?"
grep -c '^mem: peak' build/t168mem.log | sed 's/^/mem peaks reported: /'
grep '^mem: peak' build/t168mem.log
grep '^mem: live' build/t168mem.log
echo "-- peak/live by category"
grep -E '^mem:   [a-z]' build/t168mem.log | grep -v '^mem:   site' | grep -v '^mem:     cap' | head -20
echo "-- top sites"
grep '^mem:   site' build/t168mem.log | head -12
echo "-- top sites resolved"
for a in $(grep '^mem:   site' build/t168mem.log | awk '{print $3}' | head -12); do
  echo "$a $(addr2line -f -C -e build/avra "$a" 2>/dev/null | paste -sd' ' -)"
done

echo "== warm one-edit check packages/cli =="
LEAF=packages/cli/src/commands/rules.av
cp "$LEAF" build/leaf.t168.keep
./avra check packages/cli > /dev/null 2>&1
printf '\n// t168 ref %s\n' "$(date +%s%N)" >> "$LEAF"
./avra check --time packages/cli > build/t168chk.log 2>&1
echo "check exit $?"
grep '^time:' build/t168chk.log | tail -1
cp build/leaf.t168.keep "$LEAF"
