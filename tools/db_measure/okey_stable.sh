# Two checks with one edit between: which files' object keys move between them, and whether the equal branch holds.
cd "$(dirname "$0")/../.."
S=build/okey
mkdir -p $S
F=packages/cli/src/commands/shared.av
cp $F $S/shared.orig
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.okey.$$.$i"
done
AVRA_QTRACE=1 ./avra check --time packages/cli > $S/first.out 2> $S/first.err; echo "first check exit $?"; grep -h -o "held [0-9]*/[0-9]*" $S/first.out $S/first.err | head -n 1
python3 - $F "$(date +%s%N)" <<'PY'
import sys
p, stamp = sys.argv[1], sys.argv[2]
text = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(text.replace("· memo", "· memo " + stamp, 1))
PY
AVRA_QTRACE=1 ./avra check --time packages/cli > $S/second.out 2> $S/second.err; echo "second check exit $?"; grep -h -o "held [0-9]*/[0-9]*" $S/second.out $S/second.err | head -n 1
cp $S/shared.orig $F
for t in first second; do awk -F'\t' '$1=="Q" && $2=="okey" {print $3"\t"$4"\t"$5}' $S/$t.err | sort -u -k1,1 > $S/$t.keys; echo "$t keys: $(wc -l < $S/$t.keys)"; done
echo "keys moved: $(awk -F'\t' 'FNR==NR {k[$1]=$3; next} ($1 in k) && k[$1]!=$3 {n++} END {print n+0}' $S/first.keys $S/second.keys)"
echo "equal-branch files (first): $(awk -F'\t' '$2=="true"' $S/first.keys | wc -l) of $(wc -l < $S/first.keys)"
awk -F'\t' 'FNR==NR {k[$1]=$3; next} ($1 in k) && k[$1]!=$3 {print $1, $2}' $S/first.keys $S/second.keys | head -n 3 | sed 's|/home/sprite/avra-build/avra-db-said/tree/||'
