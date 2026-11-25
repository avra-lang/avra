#!/bin/bash
# THE STORE'S BASELINE (M4, M6), from a tree's root, on Linux:
#   bash tools/db_measure/store_baseline.sh
# A cold check of the cli, then a no-op one. For each: wall time, and the
# store's file syscalls by kind (strace). After the cold one: files and bytes
# per family — count, total, median, p95, max.
export AVRA_MEM_CEILING_MB=5000 AVRA_WATCH_HELD=1 LLVM_PREFIX=/usr/lib/llvm-22
make -s -o avra objects libs > /dev/null 2>&1
command -v strace > /dev/null || sudo apt-get install -y -qq strace > /dev/null 2>&1
P=packages/cli
clear() { find . -name .avra-cache -type d -prune -exec rm -rf {} +; }

# Syscalls that touched .avra-cache, by name.
traced() {
    local t0 t1
    t0=$(date +%s%N)
    strace -f -qq -e trace=%file,read,write,pread64,pwrite64,mmap,close -o /tmp/sb_$1.trace build/avra check $P > /tmp/sb_$1.out 2>&1
    local st=$?
    t1=$(date +%s%N)
    echo "$1: exit $st, wall $(( (t1 - t0) / 1000000 )) ms (under strace)"
    python3 -I - /tmp/sb_$1.trace <<'PY'
import re, sys, collections
fds, by = {}, collections.Counter()
for line in open(sys.argv[1], errors="replace"):
    m = re.match(r"(\d+)\s+(\w+)\((.*)\)\s+=\s+(-?\d+)", line)
    if not m:
        continue
    pid, call, args, ret = m.group(1), m.group(2), m.group(3), int(m.group(4))
    if ".avra-cache" in args:
        by[call] += 1
        if call in ("open", "openat") and ret >= 0:
            fds[(pid, ret)] = True
    elif call in ("read", "write", "pread64", "pwrite64", "close", "mmap"):
        fd = args.split(",")[0].strip()
        if fd.isdigit() and (pid, int(fd)) in fds:
            by[call] += 1
            if call == "close":
                del fds[(pid, int(fd))]
print("  store syscalls: " + ", ".join(f"{k} {v}" for k, v in sorted(by.items())) + f"; total {sum(by.values())}")
PY
}

timed() {
    local t0 t1
    t0=$(date +%s%N)
    build/avra check $P > /dev/null 2>&1
    t1=$(date +%s%N)
    echo "$1: wall $(( (t1 - t0) / 1000000 )) ms"
}

clear
timed "cold check"
python3 -I - <<'PY'
import os, statistics
root = ".avra-cache"
for print_ in sorted(os.listdir(root)):
    d = os.path.join(root, print_)
    if not os.path.isdir(d):
        continue
    for fam in sorted(os.listdir(d)):
        fd = os.path.join(d, fam)
        sizes = []
        if os.path.isdir(fd):
            for base, _, files in os.walk(fd):
                sizes += [os.path.getsize(os.path.join(base, f)) for f in files]
        else:
            sizes = [os.path.getsize(fd)]
        if not sizes:
            continue
        s = sorted(sizes)
        print(f"  {fam}: files {len(s)}, bytes {sum(s)}, median {statistics.median(s):.0f}, "
              f"p95 {s[int(len(s) * 0.95) - 1 if len(s) > 1 else 0]}, max {s[-1]}")
PY
timed "no-op check"
clear
traced cold
traced noop
echo FIN
