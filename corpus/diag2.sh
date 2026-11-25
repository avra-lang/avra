#!/bin/bash
export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
cp packages/cli/src/commands/fmt.av /tmp/fmt.orig; cp packages/cli/src/stage.av /tmp/stage.orig
t() { local s=$(date +%s.%N); "$@"; echo "   took $(echo "$(date +%s.%N) - $s" | bc) s"; }
echo "== cold"; t build/avra check --time packages/cli 2>&1 | tail -4
echo "== hit"; t build/avra check --time packages/cli 2>&1 | tail -4
sed -i '275s/avra: /avra! /' packages/cli/src/commands/fmt.av
echo "== fmt edit"; s=$(date +%s); AVRA_QTRACE=1 build/avra check --time packages/cli >/tmp/fmt.out 2>/tmp/fmt.trace; echo "took $(( $(date +%s)-s ))s"; tail -4 /tmp/fmt.out; grep -v '^\[q' /tmp/fmt.trace | tail -4
cp /tmp/fmt.orig packages/cli/src/commands/fmt.av
echo "== rewarm"; t build/avra check --time packages/cli 2>&1 | tail -3
sed -i '53s/avra: /avra! /' packages/cli/src/stage.av
echo "== stage edit"; s=$(date +%s); AVRA_QTRACE=1 build/avra check --time packages/cli >/tmp/stage.out 2>/tmp/stage.trace; echo "took $(( $(date +%s)-s ))s"; tail -4 /tmp/stage.out
cp /tmp/stage.orig packages/cli/src/stage.av
wc -l /tmp/fmt.trace /tmp/stage.trace
head -3 /tmp/fmt.trace
cp /tmp/fmt.trace /tmp/stage.trace build/ 
