#!/bin/sh
# avra-8sb5.57.195/198: the gate, no-git form (a Sprite has no refs).
cd "$(dirname "$0")/../.." || exit 1
sh tools/gate_changed.sh \
    --files packages/std-avrac/src/features/code.av \
            packages/std-avrac/src/features/facts.av \
            packages/std-avrac/src/compiler/idioms.av \
    --packages std-avrac \
    --no-keepers > build/gate2.txt 2>&1
rc=$?
echo "gate exit $rc"
tail -25 build/gate2.txt
