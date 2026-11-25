#!/bin/sh
# one body edit, per-family trace
set -u
B=${1:-build/avra.tree}
F=packages/cli/src/commands/shared.av
[ -d .avra-cache ] && find .avra-cache -delete
cp $F build/ed.orig
$B check packages/cli > build/ed0.out 2>&1
for i in 1 2 3; do
  python3 - $F build/ed.orig "· memo" "t$i$(date +%s%N)" <<'PY'
import sys
d,o,a,s=sys.argv[1:5]
t=open(o,encoding="utf-8").read()
open(d,"w",encoding="utf-8").write(t.replace(a,a+" "+s,1))
PY
  s=$(date +%s%N)
  AVRA_QTRACE=1 $B check --time --counts packages/cli > build/ed$i.out 2> build/ed$i.q
  e=$(date +%s%N)
  echo "run $i wall $(( (e-s)/1000000 )) ms"
  grep -ah "^time:\|discarded:\|queries" build/ed$i.out build/ed$i.q | cut -c1-1500
done
cp build/ed.orig $F
echo "--- families (run 3)"
grep -a "^Q	ask\|^Q	settle" build/ed3.q | awk -F'\t' '$3!="" {print $2,$3,$5}' | sort | uniq -c | sort -rn | head -50
grep -a "^Q" build/ed3.q | cut -f2 | sort | uniq -c | sort -rn | head
