#!/bin/sh
# THE NO-OP SPLIT. From a tree's root, over a built binary:
#   sh tools/noop_profile.sh <package>
# A warm check of an unchanged package (the store answers it). Printed: the
# wall time of 10 runs, startup alone, the compiler's `--time` phases, syscall
# counts from strace (opens, stats, reads, mmaps, bytes read), perf's own
# counts, the QTRACE line count, and AVRA_MEM_STATS's total and top sites.
set -u
A=${AVRA_BIN:-build/avra}
pkg=$1
tmp=${TMPDIR:-/tmp}/noop.$$
mkdir -p "$tmp"
clock() { date +%s%N; }
"$A" check "$pkg" > /dev/null 2>&1
echo "check $pkg: $("$A" check --time "$pkg" 2>&1 | grep '^time: ' | tail -n 1)"
i=1
while [ "$i" -le 10 ]; do
    s=$(clock); "$A" check "$pkg" > /dev/null 2>&1; e=$(clock)
    echo "run $i: $(((e - s) / 1000000)) ms"
    i=$((i + 1))
done
s=$(clock); "$A" --help > /dev/null 2>&1; e=$(clock)
echo "startup (--help): $(((e - s) / 1000000)) ms"
"$A" check --time "$pkg" 2>&1 | grep -E '^time|^  [a-z]' | head -n 20
strace -c -f -o "$tmp/sc" "$A" check "$pkg" > /dev/null 2>&1
echo "strace syscalls (top 8):"; head -n 12 "$tmp/sc"
strace -f -e trace=openat,stat,newfstatat,statx,access,getdents64 -o "$tmp/files" "$A" check "$pkg" > /dev/null 2>&1
echo "path calls: $(grep -c 'openat\|stat\|access\|getdents' "$tmp/files")"
echo "opens that succeeded: $(grep 'openat' "$tmp/files" | grep -vc ENOENT)"
echo "read bytes:"; strace -f -e trace=read -o "$tmp/rd" "$A" check "$pkg" > /dev/null 2>&1
awk '/= [0-9]+$/ { n++; b += $NF } END { print "  read calls " n ", bytes " b }' "$tmp/rd"
echo "mmap calls: $(strace -f -e trace=mmap -o /dev/stdout "$A" check "$pkg" 2>/dev/null | grep -c mmap)"
perf stat -e task-clock,page-faults,context-switches -r 10 "$A" check "$pkg" > /dev/null 2> "$tmp/perf"; grep -E 'task-clock|faults|switches|elapsed' "$tmp/perf"
echo "QTRACE lines: $(AVRA_QTRACE=1 "$A" check "$pkg" 2>&1 >/dev/null | grep -c '^[QFICGAE]	')"
AVRA_MEM_STATS=1 "$A" check "$pkg" > /dev/null 2> "$tmp/mem"
echo "mem stats:"; head -n 14 "$tmp/mem"
rm -rf "$tmp"
