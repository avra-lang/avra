set -u
f=packages/cli/src/commands/shared.av
build/avra check packages/cli >/dev/null 2>&1
cp $f /tmp/shared.orig
for i in 1 2; do
  python3 - $i <<'P'
import sys
f='packages/cli/src/commands/shared.av'
t=open(f).read(); open(f,'w').write(t.replace('· memo','· memo e'+sys.argv[1],1))
P
  AVRA_QTRACE=1 build/avra check packages/cli 2>&1 >/dev/null | grep "rule-" | head -8
  echo ---
done
cp /tmp/shared.orig $f
