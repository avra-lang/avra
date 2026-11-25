#!/bin/sh
# qt.sh <compiler in /work/fixed53/build> <tag>: cold cli findings with query times.
. /etc/profile.d/avra.sh
cd /work/fixed53
for d in packages/*/.avra-cache .avra-cache /root/.avra/cache; do [ -d "$d" ] && find "$d" -delete; done
AVRA_QUERY_TIMES=1 build/$1 tapes /work/fixed53/packages/cli --findings > /work/out/qt-$2.txt 2> /work/out/qt-$2.err
echo "$2 $(grep '^time:' /work/out/qt-$2.err | cut -c1-60) | $(grep '^split' /work/out/qt-$2.err | cut -c1-40)"
