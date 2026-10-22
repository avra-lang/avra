#!/bin/sh
# avra-8sb5.57.195/198: after closing each file's assign_roots Db with
# the table, measure the relation.empty_index live count.
cd "$(dirname "$0")/../.." || exit 1
t=$$

echo "== AFTER: avra test runtime_reach_test.av =="
AVRA_MEM_STATS=1 AVRA_MEM_SITES=4000 ./avra test packages/std-avrac/src/core/tests/runtime_reach_test.av > build/after_reach.txt 2>&1
echo "exit $?"
python3 tools/memsites.py build/avra build/after_reach.txt 2>/dev/null |
    grep empty_index | sed 's/^ *//' | sort -t' ' -k12 -n | tail -4
grep -E "^mem: peak|^mem: live" build/after_reach.txt

echo "== AFTER scaling (cold) =="
for pkg in std-http std-grammar std-validate; do
    if [ -d .avra-cache ]; then mv .avra-cache "build/cache-aside.after.$t.$pkg"; fi
    AVRA_MEM_STATS=1 AVRA_MEM_SITES=4000 ./avra check "packages/$pkg" > "build/after_$pkg.txt" 2>&1
    echo "-- $pkg --"
    python3 tools/memsites.py build/avra "build/after_$pkg.txt" 2>/dev/null |
        grep empty_index | sed 's/^ *//' | sort -t' ' -k12 -n | tail -2
done
