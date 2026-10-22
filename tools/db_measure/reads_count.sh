# Build a cold cli, then a check over its records with the per-file reads probe on: count each reason.
cd "$(dirname "$0")/../.."
S=build/rc
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.rc.$$.$i"
done
./avra build packages/cli > $S/build.out 2>&1; echo "build exit $?"
AVRA_QTRACE=1 ./avra check packages/cli 2> $S/check.err > /dev/null; echo "check exit $?"
echo "reads by reason:"; awk -F'\t' '$1=="Q" && $2=="reads" {print $3}' $S/check.err | sort | uniq -c | sort -rn
echo "Unkept by file (top 5):"; awk -F'\t' '$1=="Q" && $2=="reads" && $3=="Unkept" {print $4}' $S/check.err | sed 's|.*/src/||' | sort | uniq -c | sort -rn | head -n 5
echo "moved by file (top 5):"; awk -F'\t' '$1=="Q" && $2=="reads" && $3=="Moved" {print $4}' $S/check.err | sed 's|.*/src/||' | sort | uniq -c | sort -rn | head -n 5
grep -h "^time" $S/check.err | tail -n 1 | cut -c1-300
