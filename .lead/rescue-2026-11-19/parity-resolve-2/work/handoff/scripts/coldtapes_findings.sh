#!/bin/sh
# coldtapes.sh NAME COMPILER — a fresh copy of the tree, `avra tapes packages/std-avrac` cold, query times kept
N=$1; BIN=$2; D=/tmp/claude-0/cold/$N
find $D -depth -delete 2>/dev/null; mkdir -p $D
(cd /work/avra && tar --exclude=.avra-cache --exclude='*/build' -cf - packages) | (cd $D && tar -xf -)
cd $D && /usr/bin/time -f "wall %e s, user %U s" env ${LAWT:+AVRA_LAW_TIMES=$LAWT} AVRA_CACHE_DIR=$D/machine AVRA_QUERY_TIMES=1 AVRA_PROGRAM_NET=0 AVRA_MEM_POOL_MB=12000 AVRA_MEM_CEILING_MB=12000 $BIN tapes packages/cli --findings > /dev/null 2> $D/err
grep -v "^warning\|^ \|^─\|^$\|^help\|^[0-9]* │" $D/err | tail -40 | cut -c1-600
