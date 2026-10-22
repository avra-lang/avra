#!/bin/sh
# avra-8sb5.57.195: replay one empty_index sample's life on a minimal
# program, where the retain/release log is short enough to read whole.
# Requires the runtime's sample point lowered (probe only).
cd "$(dirname "$0")/../.." || exit 1
prog=/tmp/eimin/src/main.av
mkdir -p /tmp/eimin/src
printf '[package]\nname = "eimin"\nversion = "0.1.0"\n' > /tmp/eimin/avra.toml
printf 'fn main() -> int { 0 }\nmain()\n' > "$prog"
t=$$
clearcache() { if [ -d /tmp/eimin/.avra-cache ]; then mv /tmp/eimin/.avra-cache "/tmp/eimin-cache.$$.$1"; fi }
clearcache 0

echo "== unguarded: find the empty_index sites =="
AVRA_MEM_STATS=1 AVRA_MEM_SITES=4000 ./avra check "$prog" > build/eimin_unguarded.txt 2>&1
python3 tools/memsites.py build/avra build/eimin_unguarded.txt > build/eimin_sites.txt 2>/dev/null
grep empty_index build/eimin_sites.txt | sed 's/^ *//' | sort -t' ' -k12 -n | tail -4

site=$(grep 'empty_index+60' build/eimin_sites.txt | head -1 | grep -o '0x[0-9a-f]*' | head -1)
echo "== aimed site: $site =="
clearcache 1

echo "== guarded: full life of the sample =="
AVRA_RC_GUARD=1 AVRA_MEM_SITE="$site" AVRA_MEM_STATS=1 AVRA_MEM_SITES=4000 \
    ./avra check "$prog" > build/eimin_guarded.txt 2>&1
grep -nE "LEAK at site|retain from|release from|history truncated|RELEASED box" build/eimin_guarded.txt | head -60
echo "-- aimed site / peak --"
grep -E "site $site|^mem: peak|^mem: live" build/eimin_guarded.txt | head
