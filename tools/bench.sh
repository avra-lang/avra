#!/bin/sh
# The world's-best curve starts by being MEASURED: the suites' wall
# time, printed — every spec case and every program test, both
# engines. A curve, not a gate — watch it across commits; a 10x
# regression should be news.
set -e
cd "$(dirname "$0")/.."
ms() { perl -MTime::HiRes=time -e 'printf("%d", time()*1000)'; }
t0=$(ms)
make -s test > /dev/null
t1=$(ms)
n=$(find packages -path "*/tests/*" -name "*.av" -not -name "*_test.av" | wc -l | tr -d ' ')
echo "bench: suites $((t1 - t0))ms (cases + ${n} program tests, eval and native)"
