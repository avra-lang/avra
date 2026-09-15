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

# THE COMPILER'S OWN SOURCE IS THE LARGEST PROGRAM THE TREE HAS, so it
# belongs in the curve the day the compiler can read it. The suites
# above are many small programs; this is one big one, and the two
# move for different reasons — a parse or resolve regression shows
# here first and can hide in the suites' noise.
#
# A CHECK, NOT A BUILD: the front end is the compiler's own work, and
# a build's seconds are mostly clang's, which this curve cannot act
# on. `make avra` already times the whole path for anyone who wants
# it.
t2=$(ms)
./avra check packages/cli > /dev/null
t3=$(ms)
lines=$(find packages/cli/src packages/std-avrac/src -name "*.av" -not -path "*/tests/*" -exec cat {} + | wc -l | tr -d ' ')
echo "bench: the compiler's own source $((t3 - t2))ms (check of packages/cli, ${lines} lines of Avra)"
