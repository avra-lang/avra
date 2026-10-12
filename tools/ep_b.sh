A=build/avra
F=packages/cli/src/commands/shared.av
cp $F /tmp/shared.orig
trap 'cp /tmp/shared.orig $F' EXIT
find . -name .avra-cache -type d -prune -exec rm -rf {} +
$A build --time packages/cli >/dev/null 2>/tmp/b0.txt; grep "^time" /tmp/b0.txt | cut -c1-400
$A build --time packages/cli >/dev/null 2>/tmp/b1.txt; grep "^time" /tmp/b1.txt | cut -c1-300
for i in 1 2; do
n=$(date +%s)$i
python3 - $F x$n <<'PY'
import sys
p,w=sys.argv[1:3]
t=open(p).read()
i=t.index('fn timings'); j=t.index('"',i)
open(p,'w').write(t[:j+1]+w+t[j+1:])
PY
s=$(date +%s%N)
AVRA_QTRACE=1 $A build --time packages/cli >/dev/null 2>/tmp/b2.txt
e=$(date +%s%N)
echo "edit$i wall_ms=$(( (e-s)/1000000 ))"; grep -v "^Q\|^I\|^K" /tmp/b2.txt | cut -c1-600 | head -20
awk -F'\t' '$1=="Q"&&$2=="parse"{n++} $1=="Q"&&$2=="attempt"{a++} END{print "parsed",n,"attempts",a}' /tmp/b2.txt
done
