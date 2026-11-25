#!/bin/sh
# findings.sh <compiler name in /work/fixed55/build> <tag>: cold findings for cli, std-avrac, std-program over the fixed tree.
C=/work/fixed55/build/$1; T=$2
. /etc/profile.d/avra.sh
cd /work/fixed55
for p in std-program std-avrac cli; do
  for d in packages/*/.avra-cache .avra-cache /root/.avra/cache; do [ -d "$d" ] && find "$d" -delete; done
  /usr/bin/time -f "$p %e s %U user %M KB" $C tapes /work/fixed55/packages/$p --findings > /work/out/$T-findings-$p.txt 2>/work/out/$T-findings-$p.err
  echo "$p exit $? lines $(wc -l < /work/out/$T-findings-$p.txt) $(tail -1 /work/out/$T-findings-$p.err)"
done
