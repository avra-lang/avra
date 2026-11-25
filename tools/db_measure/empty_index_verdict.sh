#!/bin/sh
# avra-8sb5.57.195: is relation.empty_index's live-at-exit block a
# refcount leak or Rows held by open relation families? Cold check of
# a small package, unguarded to find the site, then guarded with
# AVRA_MEM_SITE aimed at it so the sample's retain/release life prints.
cd "$(dirname "$0")/../.." || exit 1
t=$$

if [ -d .avra-cache ]; then mv .avra-cache "build/cache-aside.ei.$t.1"; fi

echo "== cold unguarded: find the empty_index sites =="
AVRA_MEM_STATS=1 AVRA_MEM_SITES=4000 ./avra check packages/std-text > build/ei_unguarded.txt 2>&1
echo "exit $?"
python3 tools/memsites.py build/avra build/ei_unguarded.txt > build/ei_sites.txt 2>/dev/null
echo "-- empty_index sites (live of made) --"
grep -E "empty_index" build/ei_sites.txt | head -12

site=$(grep -E "empty_index" build/ei_sites.txt | head -1 | grep -o '0x[0-9a-f]*' | head -1)
echo "== aimed site: $site =="
if [ -z "$site" ]; then
    echo "NO empty_index site found"
    exit 1
fi

if [ -d .avra-cache ]; then mv .avra-cache "build/cache-aside.ei.$t.2"; fi

echo "== guarded replay =="
AVRA_RC_GUARD=1 AVRA_MEM_SITE="$site" AVRA_MEM_STATS=1 AVRA_MEM_SITES=4000 \
    ./avra check packages/std-text > build/ei_guarded.txt 2>&1
echo "exit $?"
echo "-- the aimed site, then its sample's life --"
grep -E "site $site|LEAK at site|retain from|release from|history truncated|RELEASED box" build/ei_guarded.txt | head -100
echo "-- peak/live --"
grep -E "^mem: peak|^mem: live" build/ei_guarded.txt
