# Methods (family 7) asks on a warm `check` of packages/cli, before and after one literal edit.
cd "$(dirname "$0")/../.."
F=packages/cli/src/commands/shared.av
S=build/m192
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
grep -h "did not stabilize" $S/after.out $S/after.txt | cut -c1-160
for t in before after; do echo "== $t"; awk -F'\t' '$2=="ask" && $3=="7" {c[$5]++} END{for(k in c) print "family7", k, c[k]}' $S/$t.txt; awk -F'\t' '$2=="ask" {n++} END{print "all asks", n+0}' $S/$t.txt; done
