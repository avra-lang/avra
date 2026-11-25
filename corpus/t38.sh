#!/bin/bash
export LLVM_PREFIX=/usr/lib/llvm-22
build/avra fmt --check packages/std-avrac/src/compiler/derive.av packages/std-avrac/src/compiler/findings.av; echo "fmt exit $?"
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
: > /tmp/empty.base
ms() { echo $(( ($(date +%s%N) - $1) / 1000000 )); }
s=$(date +%s%N); build/avra check --baseline /tmp/empty.base packages/cli > /tmp/cold.txt 2>&1; echo "cold $(ms $s) ms, sites $(wc -l < /tmp/cold.txt)"
s=$(date +%s%N); build/avra check --time packages/cli >/dev/null 2>/tmp/hit.err; echo "hit $(ms $s) ms"
sed -i "275s/eprintln(\"/eprintln(\"y/" packages/cli/src/commands/fmt.av
s=$(date +%s%N); build/avra check --baseline /tmp/empty.base packages/cli > /tmp/warm.txt 2>&1; echo "warm-edit $(ms $s) ms, sites $(wc -l < /tmp/warm.txt)"
echo "cold vs warm diff lines: $(diff <(sort /tmp/cold.txt) <(sort /tmp/warm.txt) | wc -l)"
s=$(date +%s%N); build/avra check --baseline /tmp/empty.base packages/cli > /tmp/hit2.txt 2>&1; echo "hit2 $(ms $s) ms, sites $(wc -l < /tmp/hit2.txt)"
echo "warm vs hit diff lines: $(diff <(sort /tmp/warm.txt) <(sort /tmp/hit2.txt) | wc -l)"
sed -i "275s/eprintln(\"y/eprintln(\"x/" packages/cli/src/commands/fmt.av
s=$(date +%s%N); build/avra check --time packages/cli 2>&1 >/dev/null | grep -E "^time:"; echo "timed-edit $(ms $s) ms"
