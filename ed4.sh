#!/bin/sh
set -u
B=build/avra
F=packages/cli/src/commands/shared.av
[ -d .avra-cache ] && find .avra-cache -delete
cp $F build/ed.orig
$B check packages/cli > build/ed0.out 2>&1
$B check packages/cli > build/ed0.out 2>&1
for i in 1 2 3; do
  python3 - $F build/ed.orig "· memo" "t$i$(date +%s%N)" <<'PY'
import sys
d,o,a,s=sys.argv[1:5]
t=open(o,encoding="utf-8").read()
open(d,"w",encoding="utf-8").write(t.replace(a,a+" "+s,1))
PY
  python3 ru.py build/ed$i.out build/ed$i.err $B check --time packages/cli
  grep -ah "^time:" build/ed$i.out build/ed$i.err | cut -c1-900
done
cp build/ed.orig $F
