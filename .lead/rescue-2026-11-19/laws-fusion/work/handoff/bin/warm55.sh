#!/bin/sh
# warm55.sh <compiler> <tag>: cold cli findings, a literal edited in cache.av, warm findings counted.
. /etc/profile.d/avra.sh
cd /work/fixed55
C=build/$1
for d in packages/*/.avra-cache .avra-cache /root/.avra/cache; do [ -d "$d" ] && find "$d" -delete; done
$C tapes /work/fixed55/packages/cli --findings > /dev/null 2>&1
f=packages/cli/src/commands/cache.av
cp $f /work/out/cache.av.orig
python3 - "$f" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
m=re.search(r'"([^"\\$]{3,})"',s); s=s[:m.start(1)]+m.group(1)+" edited"+s[m.end(1):]; open(p,'w').write(s)
PY
AVRA_QUERY_TIMES=1 $C tapes /work/fixed55/packages/cli --findings > /work/out/warm-$2.txt 2> /work/out/warm-$2.err
cp /work/out/cache.av.orig $f
grep '^time:' /work/out/warm-$2.err | tr ',' '\n' | grep -v '(outside)\|reused' | grep -o '([0-9]*)' | tr -d '()' | paste -sd+ | bc | sed "s/^/$2 worked out: /"
grep '^time:' /work/out/warm-$2.err | tr ',' '\n' | grep 'reused' | grep -o '([0-9]*)' | tr -d '()' | paste -sd+ | bc | sed "s/^/$2 reused: /"
grep '^split' /work/out/warm-$2.err | cut -c1-60
