# Which dependency moved, for each cell a warm cli `check` recomputes after one literal edit.
cd "$(dirname "$0")/../.."
F=packages/cli/src/commands/shared.av
S=build/m192m
mkdir -p $S
./avra check packages/cli > $S/warm.out 2>&1; echo "warm exit $?"
cp $F $S/shared.orig
python3 - $F "$(date +%s)" <<'PY'
import sys
p, stamp = sys.argv[1], sys.argv[2]
text = open(p, encoding="utf-8").read()
assert text.count("· memo") == 1
open(p, "w", encoding="utf-8").write(text.replace("· memo", "· memo " + stamp, 1))
PY
AVRA_QTRACE=1 ./avra check packages/cli 2> $S/after.txt > $S/after.out; echo "after exit $?"
cp $S/shared.orig $F && cmp -s $S/shared.orig $F && echo "restored $F"
echo "moved lines: $(grep -c -P '^Q\tmoved\t' $S/after.txt)"
echo "moved by family:"; awk -F'\t' '$1=="Q" && $2=="moved" {print $3}' $S/after.txt | sort | uniq -c | sort -rn | head -n 5
echo "moved by (family, arg), top 5:"; awk -F'\t' '$1=="Q" && $2=="moved" {print $3, $4}' $S/after.txt | sort | uniq -c | sort -rn | head -n 5
