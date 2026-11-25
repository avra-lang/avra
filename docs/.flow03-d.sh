#!/bin/sh
set -u
t=packages/std-avrac/src/compiler/tests/unbroken_test.av
cp packages/std-avrac/src/compiler/typing/unbroken.av build/new-unbroken.av
cp packages/std-avrac/src/compiler/cancel_reach.av build/new-cancel.av
cp docs/.flow03-old-unbroken.av packages/std-avrac/src/compiler/typing/unbroken.av
cp docs/.flow03-old-cancel.av packages/std-avrac/src/compiler/cancel_reach.av
echo "== the new tests against the law as it stood"
AVRA_MEM_CEILING_MB=5000 build/avra test $t 2>&1 | grep -E 'tests passed|✗|avra:' | sed 's/@ .*//'
cp build/new-unbroken.av packages/std-avrac/src/compiler/typing/unbroken.av
cp build/new-cancel.av packages/std-avrac/src/compiler/cancel_reach.av
echo "== after"
AVRA_MEM_CEILING_MB=5000 build/avra test $t 2>&1 | grep -E 'tests passed|✗|avra:' | sed 's/@ .*//'
AVRA_MEM_CEILING_MB=5000 build/avra test packages/std-avrac/src/compiler/tests/cancel_reach_test.av 2>&1 | grep -E 'tests passed|✗|avra:' | sed 's/@ .*//'
AVRA_MEM_CEILING_MB=5000 build/avra check packages/std-avrac --baseline tools/idioms.baseline > build/idioms.out 2>&1; echo "idioms $?"; grep -A3 NEW build/idioms.out | head
build/avra diagnostics > build/D.md 2>/dev/null; cmp -s build/D.md docs/DIAGNOSTICS.md && echo "diagnostics: generated doc matches" || echo "diagnostics: DIFFERS"
make keepers > build/keepers.out 2>&1; echo "keepers $?"; grep -E 'keepers: [a-z-]+ refused' build/keepers.out
echo done
