# Cold check then build under AVRA_QTRACE: which parts of stands_in the build's files lack.
cd "$(dirname "$0")/../.."
S=build/stands
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.stands.$$.$i"
done
AVRA_QTRACE=1 ./avra check packages/cli > /dev/null 2> $S/check.err; echo "check exit $?"
AVRA_QTRACE=1 ./avra build packages/cli > /dev/null 2> $S/build.err; echo "build exit $?"
echo "stands lines in build: $(grep -c -P '^Q\tstands' $S/build.err)"
echo "said/asks/codes/obj combos (said asks codes obj : count):"
awk -F'\t' '$1=="Q" && $2=="stands" {print $4, $5, $6, $7}' $S/build.err | sort | uniq -c | sort -rn | head -n 8
