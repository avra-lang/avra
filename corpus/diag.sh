#!/bin/bash
# Warm-recheck probe: clear caches, cold check, hit, one-line body edit, timed recheck.
export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
cp packages/cli/src/commands/fmt.av /tmp/fmt.av.orig
echo "== cold"; /usr/bin/time -f "%e s %M KB" build/avra check --time packages/cli 2>&1 | tail -${TAILN:-15}
echo "== hit";  /usr/bin/time -f "%e s %M KB" build/avra check --time packages/cli 2>&1 | tail -${TAILN:-15}
sed -i '275s/avra: /avra! /' packages/cli/src/commands/fmt.av
sed -n 275p packages/cli/src/commands/fmt.av
echo "== edit"; /usr/bin/time -f "%e s %M KB" build/avra check --time packages/cli 2>&1 | tail -${TAILN:-15}
cp /tmp/fmt.av.orig packages/cli/src/commands/fmt.av
find . -name .avra-cache -type d -prune | head
