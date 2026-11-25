#!/bin/sh
# Find a small package whose cold check makes >=100 relation.empty_index
# boxes at one site, so the guard can replay the sample cheaply.
cd "$(dirname "$0")/../.." || exit 1
t=$$
for pkg in std-json std-url std-path std-toml std-validate std-process std-io; do
    if [ -d .avra-cache ]; then mv .avra-cache "build/cache-aside.ei.$t.$pkg"; fi
    AVRA_MEM_STATS=1 AVRA_MEM_SITES=4000 ./avra check "packages/$pkg" > "build/ei_scan_$pkg.txt" 2>&1
    peak=$(grep -E "^mem: peak" "build/ei_scan_$pkg.txt" | sort -t' ' -k3 -n | tail -1)
    python3 tools/memsites.py build/avra "build/ei_scan_$pkg.txt" 2>/dev/null |
        grep empty_index | sed 's/^ *//' | sort -t' ' -k12 -n | tail -2 > "build/ei_scan_${pkg}_top.txt"
    echo "== $pkg  $peak =="
    cat "build/ei_scan_${pkg}_top.txt"
done
