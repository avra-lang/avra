#!/bin/bash
set -u
export LLVM_PREFIX=/usr/lib/llvm-22
make -s avra > /tmp/m1.log 2>&1 && make -s avra > /tmp/m2.log 2>&1 || { grep -E '^error|─\[' /tmp/m1.log /tmp/m2.log | head; exit 2; }
find . -name .avra-cache -type d -prune -exec rm -rf {} +
AVRA_QTRACE=1 build/avra check packages/cli > /tmp/c.out 2> /tmp/c.err
echo "== cold"; grep "^KS" /tmp/c.err | grep -E "fmt.av|nokeep" | sort | uniq -c | head -20
f=packages/cli/src/commands/fmt.av; cp "$f" /tmp/o
sed -i 's/"avra: ${path}: ${e.describe/"avra - ${path}: ${e.describe/' "$f"
AVRA_QTRACE=1 build/avra check --time packages/cli > /tmp/w.out 2> /tmp/w.err
cp /tmp/o "$f"
echo "== warm"; grep "^KS" /tmp/w.err | grep -v "KS forced" | cut -c1-900 | head -20; echo "warm exit: $(tail -c 300 /tmp/w.err | tr "\n" " ")"
grep -h -A10 '^time:' /tmp/w.out /tmp/w.err | head -12
