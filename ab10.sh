#!/bin/sh
# a store written by compiler A, then checked by compiler B
set -u
A=$1; B=$2
[ -d .avra-cache ] && find .avra-cache -delete
$A check packages/cli > build/fa.out 2>&1; echo "A done: $(grep -a 'hold was refused' build/fa.out | cut -c1-80)"
AVRA_QTRACE=1 $B check --time --counts packages/cli > build/fb.out 2> build/fb.q
grep -ah "^time\|hold was refused\|discarded:" build/fb.out build/fb.q | cut -c1-300
grep -a "^Q	attempt" build/fb.q
grep -an "Q	mint	@std.process" build/fb.q | head -3
