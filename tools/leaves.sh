#!/bin/sh
# THE SAVED-ANSWER METER: how many settled answers stand on names, by blocking family, cold
# checks of the compiler's own packages. `sh tools/leaves.sh` prints the lines;
# `sh tools/leaves.sh --check` fails when a package's named count falls or a blocking
# family's count rises against tools/leaves.baseline; `--accept` rewrites the baseline
# (only after the counts improved).
set -u
cd "$(dirname "$0")/.."
A=${AVRA_BIN:-build/avra}
mode=${1:-}
out=${TMPDIR:-/tmp}/leaves.$$
: > "$out"
# The store is the tree root's one `.avra-cache`: the run's own is cold and the tree's own is
# put back, however the run ends.
held=${TMPDIR:-/tmp}/leaves-held.$$
mkdir -p "$held"
[ -d .avra-cache ] && mv .avra-cache "$held/kept"
restore() {
    [ -d .avra-cache ] && mv .avra-cache "$held/used.last"
    [ -d "$held/kept" ] && mv "$held/kept" .avra-cache
    find "$held" -delete
}
trap restore EXIT
for pkg in packages/cli packages/std-avrac; do
    [ -d .avra-cache ] && mv .avra-cache "$held/used.first"
    lines=$(AVRA_LEAVES=1 "$A" check "$pkg" 2>&1 | grep -a '^leaves ')
    [ -n "$lines" ] || { echo "leaves: $pkg answered no meter line"; exit 1; }
    echo "$lines" | while IFS= read -r line; do echo "$pkg $line" >> "$out"; done
done
cat "$out"
case "$mode" in
--accept) cp "$out" tools/leaves.baseline ;;
--check)
    python3 - "$out" tools/leaves.baseline <<'PY'
import re, sys
def parse(path):
    r = {}
    for line in open(path):
        pkg, rest = line.split(" ", 1)
        pkg = pkg + " " + rest.split(":")[0]
        m = re.search(r"(\d+) of (\d+) answers", rest)
        blocked = dict((a, int(b)) for a, b in re.findall(r"(\w+) (\d+)", rest.split("family:")[1])) if "family:" in rest else {}
        r[pkg] = (int(m.group(1)), int(m.group(2)), blocked)
    return r
now, was = parse(sys.argv[1]), parse(sys.argv[2])
bad = []
for pkg, (named, total, blocked) in now.items():
    if pkg not in was: continue
    wn, wt, wb = was[pkg]
    if named * wt < wn * total: bad.append("%s: named share fell (%d/%d against %d/%d)" % (pkg, named, total, wn, wt))
    for fam, n in blocked.items():
        if n * wt > wb.get(fam, 0) * total: bad.append("%s: %s blocks a larger share (%d/%d against %d/%d)" % (pkg, fam, n, total, wb.get(fam, 0), wt))
if bad:
    print("leaves: the meter rose\n  " + "\n  ".join(bad)); sys.exit(1)
print("leaves: no blocked share rose")
PY
    ;;
esac
