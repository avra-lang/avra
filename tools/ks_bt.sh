#!/bin/bash
set -u
export LLVM_PREFIX=/usr/lib/llvm-22
make -s avra > /tmp/m1.log 2>&1 && make -s avra > /tmp/m2.log 2>&1 || { grep -E '^error|─\[' /tmp/m1.log /tmp/m2.log | head; exit 2; }
find . -name .avra-cache -type d -prune -exec rm -rf {} +
build/avra check packages/cli > /tmp/c.out 2> /tmp/c.err
f=packages/cli/src/commands/fmt.av; cp "$f" /tmp/o
sed -i 's/"avra: ${path}: ${e.describe/"avra - ${path}: ${e.describe/' "$f"
which gdb || { apt-get install -y gdb > /dev/null 2>&1 || sudo apt-get install -y gdb > /dev/null 2>&1; }
gdb -batch -ex "break avra_trap" -ex run -ex "bt 40" --args build/avra check packages/cli 2>&1 | grep -E "^#" | cut -c1-200
cp /tmp/o "$f"
