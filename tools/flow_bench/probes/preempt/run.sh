#!/bin/sh
# Prices preemption (ticket .24) and the tick (.28): a check on every
# loop back-edge (loops.c), one test after a call (aftercall.c), a 1 ms
# tick by thread and by signal (tick.c), and the switch's "is anything
# due" by clock and by flag (switchpath.c).
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
out=$root/build/flow-bench/preempt
mkdir -p "$out"
cc=${FLOW_CC:-$(command -v clang || command -v cc)}
echo "== $(uname -srm), $($cc --version | head -1), $(getconf _NPROCESSORS_ONLN) cpus"
body() { objdump -d --no-show-raw-insn "$1" | awk -v f="<$2>:" '$2 == f { on=1; next } on && /^$/ { exit } on && /^ / { print }' | cut -c1-80; }
echo "== loop back-edges: ns a turn, least of five, two rounds"
for v in plain FLAG TASK COUNT CLOCK CHUNK; do $cc -O2 -D$v -o "$out/loops_$v" "$here/loops.c" || exit 1; done
for round in 1 2; do for v in plain FLAG TASK COUNT CLOCK CHUNK; do "$out/loops_$v" "$v"; done; done
for f in fnv collatz; do for v in plain FLAG COUNT; do echo "-- $f, $v: $(body "$out/loops_$v" $f | wc -l) instructions"; body "$out/loops_$v" $f | head -${BODY_LINES:-30}; done; done
echo "== one test after a call: ns a call, least of five, two rounds"
for v in plain BYTE TASK; do $cc -O2 -D$v -o "$out/after_$v" "$here/aftercall.c" || exit 1; done
for round in 1 2; do for v in plain BYTE TASK; do "$out/after_$v" "$v"; done; done
for v in plain BYTE TASK; do echo "-- calls, $v"; body "$out/after_$v" calls; done
for v in plain TASK; do echo "-- fib, $v: $(body "$out/after_$v" fib | wc -l) instructions"; done
echo "== the switch's question"
$cc -O2 -o "$out/switchpath" "$here/switchpath.c" || exit 1
"$out/switchpath"; "$out/switchpath"
for f in due_by_clock due_by_tick; do echo "-- $f"; body "$out/switchpath" $f; done
echo "== a 1 ms tick"
$cc -O2 -pthread -o "$out/tick" "$here/tick.c" || exit 1
"$out/tick"
