# Workspace.methods calls and compute branches on a warm cli `check`, before and after one literal edit.
cd "$(dirname "$0")/../.."
F=packages/cli/src/commands/shared.av
S=build/m192p
mkdir -p $S
./avra check packages/cli > $S/warm.out 2>&1; echo "warm exit $?"
AVRA_QTRACE=1 ./avra check packages/cli 2> $S/before.txt > /dev/null; echo "before exit $?"
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
for t in before after; do echo "== $t"; awk -F'\t' '$1=="Q" && $2=="methods" {n++} $1=="Q" && $2=="methods-compute" {c++} END{print "calls", n+0, "computes", c+0}' $S/$t.txt; done
awk -F'\t' '$1=="Q" && $2=="methods-compute" {print $3}' $S/after.txt | sort | uniq -c | sort -rn | head -n 5
