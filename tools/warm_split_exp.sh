#!/bin/bash
# Runs INSIDE a Sprite tree: a cold check, then a warm check after one
# edit, printing wall time and --time, plus the recomputes per query
# family (AVRA_QTRACE) of the edited check.
set -u
export LLVM_PREFIX=/usr/lib/llvm-22
clear() { find . -name .avra-cache -type d -prune -exec rm -rf {} +; }
secs() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.1f", (b-a)/1e9}'; }
clear
s=$(date +%s%N); build/avra check --time packages/cli > /tmp/ws.out 2>&1; e=$(date +%s%N)
echo "cold: $(secs $s $e) s"; grep '^time:' /tmp/ws.out | head -1
f=packages/cli/src/commands/fmt.av
cp "$f" /tmp/ws.orig
sed -i 's/"avra: ${path}: ${e.describe/"avra - ${path}: ${e.describe/' "$f"
cmp -s /tmp/ws.orig "$f" && echo "EDIT DID NOT APPLY"
s=$(date +%s%N); AVRA_QTRACE=1 build/avra check --time packages/cli > /tmp/wq.out 2> /tmp/wq.err; e=$(date +%s%N)
echo "fmt.av edit (traced): $(secs $s $e) s"
grep -h -A14 '^time:' /tmp/wq.out /tmp/wq.err | head -16
echo "== trace lines: $(wc -l < /tmp/wq.err)"
head -4 /tmp/wq.err
echo "== computes by family"
grep -i "compute" /tmp/wq.err | awk '{print $1, $2, $3}' | sort | uniq -c | sort -rn | head -25
cp /tmp/ws.orig "$f"
