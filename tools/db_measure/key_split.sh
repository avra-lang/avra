# Cold build of packages/cli, a one-literal edit, then a traced rebuild: the two key spellings per file, compared.
cd "$(dirname "$0")/../.."
S=build/keys
mkdir -p $S
F=packages/cli/src/commands/shared.av
cp $F $S/shared.orig
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.keys.$$.$i"
done
./avra build packages/cli > $S/cold.out 2>&1; echo "cold build exit $?"
python3 - $F "$(date +%s%N)" <<'PY'
import sys
p, stamp = sys.argv[1], sys.argv[2]
text = open(p, encoding="utf-8").read()
assert text.count("· memo") == 1
open(p, "w", encoding="utf-8").write(text.replace("· memo", "· memo " + stamp, 1))
PY
AVRA_QTRACE=1 ./avra build packages/cli > $S/rebuild.out 2> $S/rebuild.err; echo "rebuild exit $?"
cp $S/shared.orig $F && cmp -s $S/shared.orig $F && echo "restored $F"
echo "files probed: $(grep -c -P '^Q\tkeys' $S/rebuild.err)"
echo "keys differ: $(awk -F'\t' '$1=="Q" && $2=="keys" && $5!=$6' $S/rebuild.err | wc -l)"
echo "differing with gatherings: $(awk -F'\t' '$1=="Q" && $2=="keys" && $5!=$6 && $7>0' $S/rebuild.err | wc -l)"
awk -F'\t' '$1=="Q" && $2=="keys" && $5!=$6 {print $3; print "  obj_key_cached " $5; print "  read_okey       " $6; print "  gatherings " $7}' $S/rebuild.err | sed 's|/home/sprite/avra-build/avra-db-said/tree/||'
