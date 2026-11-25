#!/bin/sh
set -u
build/avra diagnostics > docs/DIAGNOSTICS.md 2> build/diag.err; echo "diagnostics $?"
echo "DIAGB64:$(gzip -c docs/DIAGNOSTICS.md | base64 -w0)"
AVRA_MEM_CEILING_MB=5000 build/avra test packages/std-avrac/src/compiler/tests/unbroken_test.av > build/u.out 2>&1; grep -E 'tests passed|✗|avra:' build/u.out | sed 's/@ .*//'
AVRA_MEM_CEILING_MB=5000 build/avra test packages/std-avrac/src/compiler/tests/cancel_reach_test.av > build/c.out 2>&1; grep -E 'tests passed|✗|avra:' build/c.out | sed 's/@ .*//'
AVRA_MEM_CEILING_MB=5000 build/avra check packages/std-avrac --baseline tools/idioms.baseline > build/idioms.out 2>&1; echo "idioms $?"; grep -A3 NEW build/idioms.out | head
make keepers > build/keepers.out 2>&1; echo "keepers $?"; grep -E 'keepers: [a-z-]+ refused' build/keepers.out
echo done
