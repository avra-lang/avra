#!/bin/sh
# census-parts.sh <builder compiler> <tag>: census compiler of the tree, cold cli findings, every site, by part.
. /etc/profile.d/avra.sh
cd /work/avra
CENSUS_BUILDER=$1 CENSUS_CAP_MB=7000 sh tools/census.sh tapes $PWD/packages/cli --findings > /work/out/census-$2.out 2>&1 || { tail -5 /work/out/census-$2.out; exit 1; }
export AVRA_CACHE_DIR=/work/avra/.avra-cache.census-run AVRA_STORE_KEPT_HERE=1 AVRA_PROGRAM_NET=0
find /work/avra/.avra-cache.census-run -delete 2>/dev/null; find packages/cli/.avra-cache -delete 2>/dev/null
AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 AVRA_CENSUS_TOP=1000000 build/avra.census tapes $PWD/packages/cli --findings > /dev/null 2> /work/out/census-$2.raw
awk '/: site 0x/ {print $3}' /work/out/census-$2.raw | sort -u > /work/out/census-$2.sites
xargs addr2line -f -e build/avra.census < /work/out/census-$2.sites 2>/dev/null | awk 'NR % 2 == 1' | paste -d' ' /work/out/census-$2.sites - > /work/out/census-$2.names
python3 /work/bin/census-parts.py $2
