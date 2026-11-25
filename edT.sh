#!/bin/sh
set -u
B=build/avra
F=packages/cli/src/commands/shared.av
[ -d .avra-cache ] && find .avra-cache -delete
cp $F build/ed.orig
$B check packages/cli > build/ed0.out 2>&1
$B check packages/cli > build/ed0.out 2>&1
for i in 1 2 3 4 5; do
  python3 - $F build/ed.orig "· memo" "t$i$(date +%s%N)" <<'PY'
import sys
d,o,a,s=sys.argv[1:5]
t=open(o,encoding="utf-8").read()
open(d,"w",encoding="utf-8").write(t.replace(a,a+" "+s,1))
PY
  s=$(date +%s%N)
  AVRA_QTRACE=1 $B check --time --counts packages/cli > build/ed$i.out 2> build/ed$i.q
  e=$(date +%s%N)
  echo "round $i wall $(( (e-s)/1000000 )) $(grep -ah '^time:' build/ed$i.out build/ed$i.q | tr ',' '\n' | grep -a '^ \(keep\|load\|analyze\|lower\)' | tr '\n' ' ') typed_compute $(grep -ac '^Q	ask	Typed	[0-9-]*	compute' build/ed$i.q) typed_reuse $(grep -ac '^Q	ask	Typed	[0-9-]*	reuse' build/ed$i.q) lowered_compute $(grep -ac '^Q	ask	Lowered	[0-9-]*	compute' build/ed$i.q) store_events $(grep -ac '^Q	store' build/ed$i.q) $(grep -ah 'hold was refused' build/ed$i.out | head -1 | cut -c1-60)"
done
cp build/ed.orig $F
