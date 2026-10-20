set -u
f=packages/cli/src/commands/shared.av
build/avra check packages/cli >/dev/null 2>&1
build/avra check packages/cli >/dev/null 2>&1
cp $f /tmp/p272.orig
for i in 1 2 3; do
python3 - $i <<'P'
import sys,re,time
f="packages/cli/src/commands/shared.av"
t=open(f).read()
t=re.sub("· memo( [a-z0-9]+)?","· memo e"+sys.argv[1]+time.strftime("%H%M%S"),t,1)
open(f,"w").write(t)
P
AVRA_QTRACE=1 build/avra check --counts --time packages/cli 2>/tmp/p272.q >/dev/null
grep -a "^counts" /tmp/p272.q | tr ' ' '\n' | grep -a "minted_\|computed\|fallback"
grep -a "^time" /tmp/p272.q | cut -c1-900
grep -a "^Q.ask" /tmp/p272.q | grep -a compute | cut -f3 | sort | uniq -c | sort -rn | head -6
echo =====
done
cp /tmp/p272.orig $f
