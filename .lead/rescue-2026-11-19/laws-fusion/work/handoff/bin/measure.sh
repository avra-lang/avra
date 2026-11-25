#!/bin/sh
# measure.sh <compiler in /work/fixed/build> <tag>: cold tapes --findings of cli with the law tally.
. /etc/profile.d/avra.sh
cd /work/fixed
for d in packages/*/.avra-cache .avra-cache /root/.avra/cache; do [ -d "$d" ] && find "$d" -delete; done
AVRA_LAW_TALLY=1 /usr/bin/time -f 'wall %e s user %U s maxrss %M KB' build/$1 tapes /work/fixed/packages/cli --findings > /work/out/meas-$2.txt 2> /work/out/meas-$2.err
echo "$2 exit $? $(grep '^law TOTAL' /work/out/meas-$2.err) $(tail -1 /work/out/meas-$2.err)"
