#!/bin/sh
# avra-8sb5.57.168 second half: name the merged word-sized SideTable site.
# A throwaway compiler carries F168 probes in core/side_table.av's four
# constructors (side_table, side_table_of, side_grow, side_put); one COLD
# `check packages/cli` aggregates cells by table name.
set -u
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
out=build/f168
mkdir -p "$out"
aside() { find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null; }
aside
make try > "$out/st-build.log" 2>&1 || { echo "BUILD FAILED"; tail -n 30 "$out/st-build.log"; exit 1; }
aside
echo "probe compiler built; caches cleared"
build/avra-try check packages/cli > /dev/null 2> "$out/st.err"
echo "check exit=$? stderr lines=$(wc -l < "$out/st.err")"
python3 - "$out/st.err" <<'PY'
import sys
from collections import defaultdict
cells = defaultdict(int); count = defaultdict(int); kind = {}
for line in open(sys.argv[1], errors='replace'):
    if 'F168S' not in line:
        continue
    p = line.rstrip('\n').split('\t')
    if len(p) < 3:
        continue
    k0, name, n = p[0], p[1], p[2]
    try:
        k = int(n)
    except ValueError:
        continue
    cells[name] += max(k, 0); count[name] += 1; kind[name] = k0
rows = sorted(cells.items(), key=lambda kv: -kv[1])
print(f"{'kind':7s} {'table':38s} {'calls':>9s} {'cells':>12s} {'~MB':>8s}")
for name, c in rows[:30]:
    print(f"{kind[name]:7s} {name:38s} {count[name]:9d} {c:12d} {c*8/1e6:8.2f}")
print("TOTAL cells", sum(cells.values()), "~MB", round(sum(cells.values())*8/1e6, 1))
PY
