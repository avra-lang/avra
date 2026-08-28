#!/bin/sh
# The world's-best curve starts by being MEASURED: wall times for
# the suite and the native corpus, printed. A curve, not a gate —
# watch it across commits; a 10x regression should be news.
set -e
cd "$(dirname "$0")/.."
ms() { perl -MTime::HiRes=time -e 'printf("%d", time()*1000)'; }
t0=$(ms)
make -s test > /dev/null
t1=$(ms)
make -s corpus > /dev/null
t2=$(ms)
echo "bench: suite $((t1 - t0))ms | corpus (16 programs, build+run native) $((t2 - t1))ms"
