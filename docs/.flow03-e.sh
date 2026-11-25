#!/bin/sh
set -u
t=packages/std-avrac/src/compiler/tests/unbroken_test.av
cp packages/std-avrac/src/compiler/typing/unbroken.av build/new-unbroken.av
cp docs/.flow03-old-unbroken.av packages/std-avrac/src/compiler/typing/unbroken.av
echo "== the new tests against the law as it stood (its own walk; the fact's per-node answer is the new one)"
AVRA_MEM_CEILING_MB=5000 build/avra test $t > build/old.out 2>&1; grep -E 'tests passed|✗|avra:|^error' build/old.out | sed 's/@ .*//' | head -12
cp build/new-unbroken.av packages/std-avrac/src/compiler/typing/unbroken.av
