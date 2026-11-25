# Cold `check --time packages/cli`: the rule pass's total ns against the phase total.
cd "$(dirname "$0")/../.."
S=build/rule
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.rule.$$.$i"
done
AVRA_QTRACE=1 ./avra check --time packages/cli > $S/out.txt 2> $S/err.txt; echo "check exit $?"
echo "rule passes: $(grep -c -P '^Q\trules\t' $S/err.txt)"
echo "rule ns total: $(awk -F'\t' '$1=="Q" && $2=="rules" {s+=$3} END{print s+0}' $S/err.txt)"
grep -h "^time:" $S/out.txt $S/err.txt | tail -n 1 | cut -c1-400
