#!/bin/bash
# THE STORE'S BASELINE (M4, M6), from a tree's root, on Linux:
#   bash tools/store_baseline.sh
# A cold check of the cli, then a no-op one. For each: wall time, and the
# store's file syscalls by kind (strace). After the cold one: files and bytes
# per part — `.avra-cache/store/` (body-*.pack, body-*.idx, seg-*.log, lock),
# and the `obj/` and `bin/` files beside it — count, total, median, p95, max.
export AVRA_MEM_CEILING_MB=5000 AVRA_WATCH_HELD=1
: "${LLVM_PREFIX:=/usr/lib/llvm-22}"
export LLVM_PREFIX
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

# Files and bytes per part of one store. The store is ONE directory per tree
# (design §6.1), not one per compiler, so this walks `.avra-cache/store/`
# directly and files each name by the part it is.
report() {
python3 -I - <<'PY'
import os, statistics
root = ".avra-cache"
parts = {}
def add(kind, size):
    parts.setdefault(kind, []).append(size)
store = os.path.join(root, "store")
if os.path.isdir(store):
    for name in sorted(os.listdir(store)):
        p = os.path.join(store, name)
        if not os.path.isfile(p):
            continue
        if name.startswith("body-") and name.endswith(".pack"):
            kind = "body-*.pack"
        elif name.startswith("body-") and name.endswith(".idx"):
            kind = "body-*.idx"
        elif name.startswith("seg-") and name.endswith(".log"):
            kind = "seg-*.log"
        elif name == "lock":
            kind = "lock"
        else:
            kind = "store/other"
        add(kind, os.path.getsize(p))
for kind in ("obj", "bin"):
    d = os.path.join(root, kind)
    if not os.path.isdir(d):
        continue
    for base, _, files in os.walk(d):
        for f in files:
            add(kind, os.path.getsize(os.path.join(base, f)))
for kind in sorted(parts):
    s = sorted(parts[kind])
    p95 = s[int(len(s) * 0.95) - 1 if len(s) > 1 else 0]
    print(f"  {kind}: files {len(s)}, bytes {sum(s)}, median {statistics.median(s):.0f}, p95 {p95}, max {s[-1]}")
PY
}

clear
timed "cold check"
report
timed "no-op check"
clear
traced cold
traced noop
echo FIN
