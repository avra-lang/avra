#!/bin/sh
# Does the live relation.empty_index count scale with a package's file
# count? (per-file `filed_assign_roots` Dbs are never closed.)
cd "$(dirname "$0")/../.." || exit 1
t=$$
for pkg in std-http std-grammar; do
    if [ -d .avra-cache ]; then mv .avra-cache "build/cache-aside.ei.$t.$pkg"; fi
    AVRA_MEM_STATS=1 AVRA_MEM_SITES=4000 ./avra check "packages/$pkg" > "build/ei_files_$pkg.txt" 2>&1
    peak=$(grep -E "^mem: peak" "build/ei_files_$pkg.txt" | sort -t' ' -k3 -n | tail -1)
    echo "== $pkg  $peak =="
    python3 tools/memsites.py build/avra "build/ei_files_$pkg.txt" 2>/dev/null |
        grep empty_index | sed 's/^ *//' | sort -t' ' -k12 -n | tail -3
done
