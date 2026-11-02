#!/bin/bash
# A/B on one store: the edit run plain vs under AVRA_DB_VERIFY=typed.
A=./build/avra-try
F=packages/cli/src/commands/shared.av
cp $F /tmp/shared.orig
find .avra-cache -mindepth 1 -delete
$A check packages/cli >/dev/null 2>&1; echo "cold $?"; $A check packages/cli >/dev/null 2>&1; echo "warm $?"
du -sh .avra-cache
find /tmp/cacheA -mindepth 1 -delete 2>/dev/null; mkdir -p /tmp/cacheA; cp -a .avra-cache/. /tmp/cacheA/
python3 -c "
import pathlib
p=pathlib.Path('$F'); s=open('/tmp/shared.orig').read()
p.write_text(s.replace(\"names no declaration — write\",'names no declaration7 — write',1))"
s0=$(date +%s.%N); AVRA_QTRACE=1 timeout 120 $A check packages/cli >/dev/null 2>/tmp/tA.txt; echo "A exit $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
find .avra-cache -mindepth 1 -delete; cp -a /tmp/cacheA/. .avra-cache/
s0=$(date +%s.%N); AVRA_DB_VERIFY=typed AVRA_QTRACE=1 timeout 300 $A check packages/cli >/dev/null 2>/tmp/tB.txt; echo "B exit $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
cp /tmp/shared.orig $F
for x in A B; do echo "== $x"; grep -a $'^Q\tattempt' /tmp/t$x.txt; grep -a $'^Q\tturnread' /tmp/t$x.txt | cut -f3 | sort | uniq -c; grep -a $'^Q\tturnread' /tmp/t$x.txt | grep -v "nothing kept" | head -4 | cut -c1-200; done
python3 - <<'PY'
# first divergence of the non-store event streams up to A's first turn
def ev(p):
    out=[]
    for l in open(p,errors='replace'):
        if l.startswith(('Q\tstore','Q\tdb','Q row moved','Q\tsaved','Q\tsettle','Q\tleaf')): continue
        if '\treuse' in l: continue
        out.append(l.rstrip()[:220])
    return out
a=ev('/tmp/tA.txt'); b=ev('/tmp/tB.txt')
i=0
while i<min(len(a),len(b)) and a[i]==b[i]: i+=1
print("first divergence at event",i,"of",len(a),len(b))
for x in a[max(0,i-15):i+8]: print("A ",x)
print("----")
for x in b[i:i+8]: print("B ",x)
PY
for x in A B; do echo "== buckets $x"; grep -a $'^Q\tbucketprobe' /tmp/t$x.txt | sed "s|/home/sprite/avra-build/avra-hd-saved/tree/packages/||g" | sort | uniq -c | sort -rn | cut -c1-700 | head -6; done
