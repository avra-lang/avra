#!/bin/bash
export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
: > /tmp/empty.base
ms() { echo $(( ($(date +%s%N) - $1) / 1000000 )); }
s=$(date +%s%N); build/avra check --time --baseline /tmp/empty.base packages/cli > /tmp/cold.txt 2>/tmp/cold.err; echo "cold exit $? $(ms $s) ms"; grep -E "^time:|^DIAG" /tmp/cold.err | cut -c1-600
s=$(date +%s%N); build/avra check --time packages/cli >/dev/null 2>/tmp/hit.err; echo "hit $(ms $s) ms"; grep -E "^time:" /tmp/hit.err
sed -i "275s/eprintln(\"/eprintln(\"y/" packages/cli/src/commands/fmt.av
s=$(date +%s%N); build/avra check --time --baseline /tmp/empty.base packages/cli > /tmp/warm.txt 2>/tmp/warm.err; echo "warm-edit exit $? $(ms $s) ms"; grep -E "^time:|^DIAG" /tmp/warm.err | cut -c1-900
grep -A12 "^read:" /tmp/warm.err
echo "cold sites $(wc -l < /tmp/cold.txt), warm sites $(wc -l < /tmp/warm.txt)"
head -3 /tmp/cold.txt
diff <(sort /tmp/cold.txt) <(sort /tmp/warm.txt) | head -20; echo "diff lines: $(diff <(sort /tmp/cold.txt) <(sort /tmp/warm.txt) | wc -l)"
s=$(date +%s%N); build/avra check --baseline /tmp/empty.base packages/cli > /tmp/hit2.txt 2>&1; echo "hit2 $(ms $s) ms; hit sites $(grep -c . /tmp/hit2.txt)"; diff <(sort /tmp/warm.txt) <(sort /tmp/hit2.txt) | wc -l
