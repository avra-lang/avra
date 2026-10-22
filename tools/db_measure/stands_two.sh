# Two checks with one edit between: the stands_in parts each check asks for, by combination.
cd "$(dirname "$0")/../.."
S=build/stands2
mkdir -p $S
F=packages/cli/src/commands/shared.av
cp $F $S/shared.orig
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.st2.$$.$i"
done
AVRA_QTRACE=1 ./avra check --time packages/cli > $S/first.out 2> $S/first.err; echo "first check exit $?"
python3 - $F "$(date +%s%N)" <<'PY'
import sys
p, stamp = sys.argv[1], sys.argv[2]
text = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(text.replace("· memo", "· memo " + stamp, 1))
PY
AVRA_QTRACE=1 ./avra check --time packages/cli > $S/second.out 2> $S/second.err; echo "second check exit $?"
cp $S/shared.orig $F
grep -h -o "held [0-9]*/[0-9]*" $S/second.out $S/second.err | head -n 1
echo "second check stands combos (said asks codes obj):"
awk -F'\t' '$1=="Q" && $2=="stands" {print $4, $5, $6, $7}' $S/second.err | sort | uniq -c | sort -rn | head -n 6
