#!/bin/sh
# Prices a stack-limit check in every prologue (tools/flow_bench/probes/
# prologue/calls.c), and what Avra's `probe-stack` attribute costs today.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
out=$root/build/flow-bench/prologue
mkdir -p "$out"
cc=${FLOW_CC:-$(command -v clang || command -v cc)}
echo "== $(uname -srm), $($cc --version | head -1)"
built() {
    tag=$1
    shift
    if $cc -O2 "$@" -o "$out/$tag" "$here/calls.c" 2> "$out/$tag.err"; then return 0; fi
    echo "$tag: does not build — $(head -1 "$out/$tag.err" | cut -c1-140)"
    return 1
}
$cc -O2 -c -o "$out/morestack.o" "$here/morestack.c"
built plain && variants="plain"
built probe -fstack-clash-protection && variants="$variants probe"
built limit_global -DLIMIT_GLOBAL && variants="$variants limit_global"
built limit_tls -DLIMIT_TLS && variants="$variants limit_tls"
built split -fsplit-stack "$out/morestack.o" && variants="$variants split"
for round in 1 2; do
    for v in $variants; do "$out/$v" "$v"; done
done
echo "== one prologue: fib, up to its first call"
for v in $variants; do
    echo "-- $v"
    objdump -d --no-show-raw-insn "$out/$v" | awk '/<fib>:$/ { on=1; next } on && /call/ { print; exit } on && /^ / { print }' | cut -c1-90
done
echo "== leaf, whole"
for v in $variants; do
    echo "-- $v"
    objdump -d --no-show-raw-insn "$out/$v" | awk '/<leaf>:$/ { on=1; next } on && /^$/ { exit } on && /^ / { print }' | cut -c1-90
done
echo "== probe-stack today: functions in a compiled Avra program, and those that probe"
bin=$root/tools/flow_bench/avra/spawn/src/main
[ -x "$bin" ] || "$root/build/avra" build "$root/tools/flow_bench/avra/spawn" > /dev/null 2>&1
if [ -x "$bin" ]; then
    echo "  functions $(objdump -d "$bin" | grep -c '>:$'); with a frame of a page or more (a probe) $(objdump -d --no-show-raw-insn "$bin" | grep -cE 'sub +\$0x[0-9a-f]{4,},%rsp')"
else
    echo "  no compiled bench here — run the flow bench first"
fi
