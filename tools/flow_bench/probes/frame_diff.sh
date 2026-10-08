#!/bin/sh
# THE FRAME PROOF, as one command: two copies of runtime/avra_fiber.c
# built with the runtime's own flags under build/frame-diff, and every function's instructions
# compared — addresses and symbol offsets masked — so a change says
# which functions it touched and by how many instructions.
#
#     sh tools/flow_bench/probes/frame_diff.sh <base.c> <change.c>
set -e
cd "$(dirname "$0")/../../.."
base="$1"; change="$2"
out=build/frame-diff
mkdir -p "$out"
probes=$( [ "$(uname -s)" = Darwin ] || echo -fstack-clash-protection )
for side in base change; do
    src=$(eval echo \$$side)
    cp "$src" "$out/$side.c"
    cc -c -O2 -fPIC $probes -ffunction-sections -fdata-sections -Iruntime -o "$out/$side.o" "$out/$side.c"
    objdump -d --no-show-raw-insn "$out/$side.o" | python3 -c '
import re, sys
fn, out = None, {}
for line in sys.stdin:
    head = re.match(r"^[0-9a-f]+ <(.+)>:$", line.strip())
    if head:
        fn = head.group(1).lstrip("_"); out[fn] = []; continue
    ins = re.match(r"^\s*[0-9a-f]+:\s+(.*)$", line)
    if fn and ins:
        text = re.sub(r"0x[0-9a-f]+|<[^>]*>|[;#].*$", "X", ins.group(1)).replace("\t", " ").strip()
        out[fn].append(text)
for k in sorted(out):
    print(k + "\t" + str(len(out[k])) + "\t" + "|".join(out[k]))
' > "$out/$side.txt"
done
python3 - "$out/base.txt" "$out/change.txt" <<'PY'
import sys
def read(p):
    return {l.split("\t")[0]: l.rstrip("\n").split("\t") for l in open(p)}
a, b = read(sys.argv[1]), read(sys.argv[2])
same = [k for k in a if k in b and a[k][2] == b[k][2]]
print(f"frame-diff: {len(same)} of {len(a)} base functions identical")
for k in sorted(set(a) | set(b)):
    if k in a and k in b and a[k][2] == b[k][2]:
        continue
    print(f"  {k}: {a[k][1] if k in a else '-'} -> {b[k][1] if k in b else '-'}")
PY
