#!/bin/sh
set -u
B=build/avra
F=packages/cli/src/commands/shared.av
[ -d .avra-cache ] && find .avra-cache -delete
cp $F build/ed.orig
$B check packages/cli > build/ed0.out 2>&1
$B check packages/cli > build/ed0.out 2>&1
for i in 1 2 3 4; do
  python3 - $F build/ed.orig "· memo" "t$i$(date +%s%N)" <<'PY'
import sys
d,o,a,s=sys.argv[1:5]
t=open(o,encoding="utf-8").read()
open(d,"w",encoding="utf-8").write(t.replace(a,a+" "+s,1))
PY
  AVRA_QTRACE=1 $B check --time packages/cli > build/ed$i.out 2> build/ed$i.q
  echo "run $i"; grep -a "^Q	keep" build/ed$i.q | cut -f3,4 | tr '\t' ' ' | awk 'NR>1{printf "%s +%d  ", $1, $2-p} {p=$2}'; echo
  grep -ah "^time:" build/ed$i.out build/ed$i.q | tr ',' '\n' | grep -a "keep\|load" | tr '\n' ' '; echo
done
cp build/ed.orig $F
