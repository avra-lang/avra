#!/bin/bash
# the interface edit that throws three attempts away: per attempt, which held file's body was asked, by whose run
export AVRA_MEM_CEILING_MB=5000 LLVM_PREFIX=/usr/lib/llvm-22
make -s -o avra objects libs > /dev/null 2>&1
P=packages/cli; F=$P/src/commands/shared.av; cp $F /tmp/shared.orig
ed() { python3 - "$F" "$1" "$2" <<'PY'
import sys
p, old, new = sys.argv[1:4]; t = open(p).read(); assert t.count(old) >= 1, old; open(p, "w").write(t.replace(old, new, 1))
PY
}
find . -name .avra-cache -type d -prune -exec rm -rf {} +
build/avra check $P > /dev/null 2>&1; ./avra build $P > /dev/null 2>&1
ed '· memo' '· memo one'; build/avra check $P > /dev/null 2>&1
ed '· memo one' '· memo two'; build/avra check $P > /dev/null 2>&1
ed 'description: "the source file"' 'description: "the source file PROBE"'
ed 'description: "print phase timings and memo hits"' 'description: "print phase timings and memo hits PROBE"'
s=$(date +%s%N); AVRA_QTRACE=1 build/avra check --time $P > /tmp/tp_out.txt 2> /tmp/tp_err.txt; e=$(date +%s%N)
echo "exit $? wall_ms $(((e-s)/1000000)) (under QTRACE)"
cp /tmp/shared.orig $F
python3 - <<'PY'
import os, re
root = os.getcwd() + "/"
rel = lambda p: p.replace(root, "").replace("packages/", "")
att = -1; asks = {}; adrift = {}
for l in open("/tmp/tp_err.txt", errors="replace"):
    f = l.rstrip("\n").split("\t")
    if f[:2] == ["Q", "attempt"]: att = int(f[2]); print("ATTEMPT", att, f[3]); continue
    if f[0] != "M": continue
    if f[1] == "bodyask": asks.setdefault(att, []).append((rel(f[2]), f[3].split("/")[-1][-60:], rel(f[4])))
    if f[1] == "adrift": adrift.setdefault(att, []).append(rel(f[2]))
    if f[1] == "forced" and "/cli/src/commands/" in f[2] and "/tests/" not in f[2] and int(f[3]) + int(f[4]) > 0: print("   forced_runs att %d %s: record lists %s run files, %s consts, every const has a kept verdict so NONE forced: %s" % (att, rel(f[2]), f[3], f[4], f[5]))
for a in sorted(set(asks) | set(adrift)):
    xs = asks.get(a, [])
    print("== attempt %d: %d body asks, %d distinct files asked, %d distinct askers; %d adrift" % (a, len(xs), len({x[0] for x in xs}), len({x[2] for x in xs}), len(adrift.get(a, []))))
    byasker = {}
    for f, d, by in xs: byasker.setdefault(by, set()).add(f)
    for by in sorted(byasker): print("   run of %s asked bodies in: %s" % (by, ", ".join(sorted(byasker[by]))))
    seen = set()
    for f, d, by in xs:
        if f not in seen: seen.add(f); print("      first ask in %s: %s" % (f, d))
    for p in adrift.get(a, []): print("   adrift: " + p)
PY
cat /tmp/tp_out.txt /tmp/tp_err.txt | grep -a '^time:\|^  discarded:' | sed 's/, sublang.*bodies [0-9]*ms//' | cut -c1-3000
echo FINISHED
