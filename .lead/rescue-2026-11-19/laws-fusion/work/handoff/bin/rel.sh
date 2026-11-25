#!/bin/sh
# rel.sh <compiler in /work/fixed/build> <tag>: cold --release build of cli on the fixed tree.
. /etc/profile.d/avra.sh
cd /work/fixed
for d in packages/*/.avra-cache .avra-cache /root/.avra/cache; do [ -d "$d" ] && find "$d" -delete; done
touch /work/out/rel-$2.stamp
AVRA_PROGRAM=1 /usr/bin/time -f '%e s %M KB' build/$1 build packages/cli --release > /work/out/rel-$2.log 2>&1
echo "exit $?"
find /work/fixed -newer /work/out/rel-$2.stamp -type f -perm -u+x -size +1M -not -path '*/.avra-cache/*' | head
