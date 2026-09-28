#!/bin/sh
# `MEMCAP=<memcap.sh> sh tools/dep_audit.sh [check|suite|both]` (default both)
#
# THE DEPENDENCY AUDIT, RUN AND KEPT. Every table read of a declaration's facts that
# skips the Kernel's `ask` (`features/bypass.av`) and that no query open at the time
# records a cover for is one no durable row's witness can see. `AVRA_DEP_AUDIT` makes
# the compiler write those reads; this runs it over `check packages/std-avrac` (every
# file typed, resolved and lowered as a program) and over the package's own suite
# (every spec's workspace), merges the runs, and writes tools/dep_audit.tsv: the list
# M5 migrates. A line leaves the file when the read is routed through `ask` or
# licensed at its site, so the file only shrinks.
#
# Columns: verb, scope (own | foreign | -), the query stack the read was made in,
# how many distinct reads at least (a power of two, the last count the run wrote),
# the file the first read was in, the declaration's name. The file's own header line
# names the runs. A run that examined nothing leaves no lines and this fails.
#
# A standalone run, never a gate step: two whole-package runs. MEMCAP names the
# memory-cap wrapper (cap 4000 MB).
set -u

memcap="${MEMCAP:?MEMCAP must name the memory-cap wrapper, memcap.sh}"
which="${1:-both}"
tree="$(cd "$(dirname "$0")/.." && pwd)"
logs="$(mktemp -d "${TMPDIR:-/tmp}/avra-dep-audit.XXXXXX")"
package=packages/std-avrac

export LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}"
AVRA_WATCH_HELD=1
export AVRA_WATCH_HELD

cd "$tree" || exit 1

# A cold store is what makes every read happen in this run.
mkdir -p "$logs/caches-aside"
find . -name .avra-cache -type d -prune | while read -r c; do
    mv "$c" "$logs/caches-aside/$(echo "${c#./}" | tr / _)"
done

status=0
run() { # run <label> <avra args...>
    label="$1"; shift
    AVRA_DEP_AUDIT="$logs/$label.tsv" sh "$memcap" 4000 build/avra "$@" > "$logs/$label.log" 2>&1
    echo $? > "$logs/$label.exit"
    printf '%s: exit %s, %s lines\n' "$label" "$(cat "$logs/$label.exit")" "$(grep -vc '^#' "$logs/$label.tsv" 2> /dev/null || echo 0)"
}

case "$which" in check | both) run check check "$package" ;; esac
case "$which" in suite | both) run suite test "$package" ;; esac

python3 - "$logs" "$tree/tools/dep_audit.tsv" "$which" <<'PY' || status=1
import glob, os, sys
logs, out, which = sys.argv[1:4]
rows = {}
runs = []
for path in sorted(glob.glob(os.path.join(logs, "*.tsv"))):
    label = os.path.basename(path)[:-4]
    runs.append(label)
    for line in open(path).read().split("\n"):
        if not line or line.startswith("#"):
            continue
        f = line.split("\t")
        if len(f) < 6:
            continue
        verb, scope, stack, n, home, name = f[0], f[1], f[2], int(f[3]), f[4], f[5]
        marker = "/packages/"
        if marker in home:
            home = "packages/" + home.split(marker, 1)[1]
        key = (verb, scope, stack)
        held = rows.get(key)
        if held is None or n > held[0]:
            rows[key] = (n, home if held is None else held[1], name if held is None else held[2])
if not rows:
    sys.stderr.write("dep_audit: the run examined nothing — no unrecorded read was written\n")
    sys.exit(1)
lines = ["\t".join((v, s, st, str(n), h, nm)) for (v, s, st), (n, h, nm) in sorted(rows.items())]
head = "# dep_audit: verb, scope, query stack, at least this many distinct reads, first file, first name — runs: " + ", ".join(runs)
open(out, "w").write(head + "\n" + "\n".join(lines) + "\n")
print("dep_audit: %d shapes -> %s" % (len(rows), out))
PY

echo "logs: $logs"
exit "$status"
