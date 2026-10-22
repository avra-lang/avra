#!/bin/sh
# One census round of a one-edit check on this tree's own compiler.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
f=packages/cli/src/commands/shared.av
sh tools/census.sh check packages/std-text > "$HOME/ce.build.log" 2>&1 || { echo "census build failed"; tail -n 15 "$HOME/ce.build.log"; exit 3; }
b=build/avra.census
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
cp "$f" "$HOME/shared.orig"
"$b" check packages/cli > /dev/null 2>&1; echo "cold status=$?"
python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace("· memo", "· memo census-edit", 1))
PY
AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 "$b" check packages/cli 2> "$HOME/ce.edit" > /dev/null; echo "edit status=$?"
grep -a '^rc:' "$HOME/ce.edit"
grep -a '^push: site 0x' "$HOME/ce.edit" | sort -t' ' -k4 -n -r | head -n 6 | while IFS= read -r line; do
    addr=$(echo "$line" | sed 's/.*site \(0x[0-9a-f]*\).*/\1/')
    echo "$line	$(addr2line -f -e "$b" "$addr" | head -1 | cut -c1-120)"
done
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
cp "$HOME/shared.orig" "$f"
build/avra check packages/cli > /dev/null 2>&1
for i in 1 2 3; do
    python3 - "$f" "$i" <<'PY'
import sys
p, i = sys.argv[1:3]
t = open(sys.argv[1].replace("packages", "packages"), encoding="utf-8").read()
import re
t = re.sub(r"· memo( wall\d)?", "· memo wall" + i, t, count=1)
open(p, "w", encoding="utf-8").write(t)
PY
    s=$(date +%s%N); build/avra check --time packages/cli > "$HOME/ce.t" 2>&1; e=$(date +%s%N)
    echo "edit$i wall_ms=$(( (e - s) / 1000000 )) $(grep -a '^time:' "$HOME/ce.t" | tail -n 1 | cut -c1-230)"
done
cp "$HOME/shared.orig" "$f"
