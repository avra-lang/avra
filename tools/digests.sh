#!/bin/sh
# DURABLE DIGESTS: `sh tools/digests.sh [package]` checks the package in two fresh processes
# with AVRA_LEAVES=digests and prints, per named family, how many settled answers wear the
# same digest in both ("digest equal across processes: N of M"). An answer is the same one
# when its family and spelled name agree; a digest that folds a per-process index differs.
set -u
cd "$(dirname "$0")/.."
A=${AVRA_BIN:-build/avra}
pkg=${1:-packages/cli}
out=${TMPDIR:-/tmp}/digests.$$
mkdir -p "$out"
for n in 1 2; do
    [ -e .avra-cache ] && mv .avra-cache "/tmp/avra-cache-old-$$-$n-$(date +%s)"
    AVRA_LEAVES=digests "$A" check "$pkg" 2>&1 | grep -a '^digest	' > "$out/$n" || true
done
python3 - "$out/1" "$out/2" <<'PY'
import sys
def load(path):
    d = {}
    for line in open(path):
        parts = line.rstrip("\n").split("\t")
        if len(parts) == 4:
            d[(parts[1], parts[2])] = parts[3]
    return d
a, b = load(sys.argv[1]), load(sys.argv[2])
fams = sorted(set(k[0] for k in a))
for f in fams:
    ka = [k for k in a if k[0] == f]
    same = sum(1 for k in ka if b.get(k) == a[k])
    print("digest equal across processes: %s %d of %d" % (f, same, len(ka)))
PY
