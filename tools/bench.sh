#!/bin/sh
# The world's-best curve starts by being MEASURED: the suites' wall
# time, printed — every spec case and every corpus program, both
# engines. A curve, not a gate — watch it across commits; a 10x
# regression should be news.
set -e
cd "$(dirname "$0")/.."
ms() { perl -MTime::HiRes=time -e 'printf("%d", time()*1000)'; }
t0=$(ms)
make -s test > /dev/null
t1=$(ms)
n=$(ls packages/*/corpus/*.av | wc -l | tr -d ' ')
echo "bench: suites $((t1 - t0))ms (cases + ${n} corpus programs, eval and native)"
