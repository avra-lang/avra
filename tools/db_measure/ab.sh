#!/bin/sh
# TWO COMPILERS OVER ONE SOURCE. Run on a Sprite, from the candidate's tree,
# which carries tools/db_measure/hist/<base>.tar.gz (archive.sh):
#   sh tools/db_measure/ab.sh <base sha> [rounds]
# The base is unpacked beside the tree and built from its own seed. The
# candidate is built here three times over: from the seed, by that, and by
# that again. Both then check the BASE's packages/cli — one pinned source, so
# what differs is the compiler alone, and each binary stands in the base's own
# build/ so `@std/*` resolves there too — cold each time, every store moved aside:
# the kernel's graph (which must be the same bytes when the candidate changes
# no behaviour), the runtime's memory account, wall time and peak per round, and
# a warm check after one body edit.
# Last, the candidate's first and second generations trace the same check.
set -u
base=$1
R=${2:-3}
here=$(cd "$(dirname "$0")" && pwd)
tree=$(pwd)
at=$HOME/dbm-hist/$base
out=$HOME/dbm-ab
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
mkdir -p "$out/aside"
families=$at/packages/std-avrac/src/compiler/families/families.av
aside() {
    find "$at" "$tree" -name .avra-cache -type d -prune 2>/dev/null | while read -r c; do
        mv "$c" "$out/aside/c.$(date +%s%N)"
    done
}
if [ ! -x "$at/build/avra.gen2" ]; then
    mkdir -p "$at" && tar -xzf "$here/hist/$base.tar.gz" -C "$at" || exit 2
    (cd "$at" && make bootstrap > build.log 2>&1 && cp build/avra build/avra.gen2) || {
        echo "base: bootstrap failed"
        tail -n 30 "$at/build.log"
        exit 3
    }
fi
echo "base	$base	built"
generation() {
    aside
    make avra > "$out/gen$1.log" 2>&1 || {
        echo "candidate: generation $1 failed"
        tail -n 40 "$out/gen$1.log"
        exit 3
    }
    cp build/avra "build/avra.gen$1"
    echo "candidate	gen$1	built"
}
[ -f build/avra ] && cp build/avra build/avra.pre
make recover > "$out/recover.log" 2>&1 || { echo "candidate: the seed did not build"; tail -n 30 "$out/recover.log"; exit 3; }
generation 1
generation 2
generation 3
cmp -s build/avra.gen2 build/avra.gen3 && echo "candidate	gen2 == gen3	same bytes" || echo "candidate	gen2 != gen3	bytes differ"
pkg=$at/packages/cli
cold() {
    aside
    "$@" check "$pkg"
}
measured() {
    label=$1
    bin=$2
    AVRA_DB_GRAPH=1 cold "$bin" 2> "$out/graph.$label" > /dev/null
    echo "$label	graph	status=$?	lines=$(wc -l < "$out/graph.$label")"
    python3 "$here/graph.py" --m1 "$out/graph.$label" "$families" | tail -n 6
    AVRA_MEM_STATS=1 cold "$bin" 2> "$out/mem.$label" > /dev/null
    echo "$label	mem"
    grep -iE "peak|live|newly_read|closed_frame" "$out/mem.$label" | head -n 12
    [ -f "$tree/tools/memsites.py" ] && python3 "$tree/tools/memsites.py" "$bin" "$out/mem.$label" 2>/dev/null | head -n 14
    i=1
    while [ "$i" -le "$R" ]; do
        aside
        echo "$label	cold$i	$(python3 "$here/spent.py" "$out/t" "$bin" check --time "$pkg")"
        echo "$label	noop$i	$(python3 "$here/spent.py" "$out/t" "$bin" check --time "$pkg")"
        i=$((i + 1))
    done
    if command -v perf > /dev/null 2>&1; then
        aside
        perf stat -x, -e instructions:u "$bin" check "$pkg" > /dev/null 2> "$out/perf.$label"
        echo "$label	instructions	$(grep instructions "$out/perf.$label" | cut -d, -f1)"
    else
        echo "$label	instructions	no perf on this Sprite"
    fi
}
cp "$tree/build/avra.gen1" "$at/build/avra.cand1"
cp "$tree/build/avra.gen2" "$at/build/avra.cand2"
cp "$tree/build/avra.gen3" "$at/build/avra.cand"
measured base "$at/build/avra.gen2"
measured cand "$at/build/avra.cand"
# One body edit, warm, in the base's tree: warm_edit.sh's own rounds, per binary.
for b in gen2 cand; do
    echo "one-edit	$b"
    (cd "$at" && AVRA_BIN="$at/build/avra.$b" sh "$here/warm_edit.sh" "$R" packages/cli cli packages/cli/src/commands/shared.av '· memo' 2>&1 | grep -E "edit[0-9]|noop|restored|absent" | cut -c1-260)
done
# A kernel is named by a count of the kernels its process made, which says nothing
# about the graph: each is renamed by its first appearance before the two are compared.
renamed() { awk -F'\t' -v OFS='\t' '{ if (!($2 in seen)) seen[$2] = ++made; $2 = seen[$2]; print }' "$1" > "$1.n"; }
renamed "$out/graph.base"
renamed "$out/graph.cand"
if cmp -s "$out/graph.base.n" "$out/graph.cand.n"; then
    echo "graph	IDENTICAL	$(grep -c '^G' "$out/graph.cand") cells	$(cmp -s "$out/graph.base" "$out/graph.cand" && echo "kernel ids too" || echo "kernel ids renamed")"
else
    echo "graph	DIFFERS"
    diff "$out/graph.base.n" "$out/graph.cand.n" | head -n 6 | cut -c1-300
fi
for g in 1 2; do
    AVRA_QTRACE=1 cold "$at/build/avra.cand$g" 2> "$out/q.gen$g" > /dev/null
done
AVRA_QTRACE=1 cold "$at/build/avra.cand2" 2> "$out/q.gen2b" > /dev/null
cmp -s "$out/q.gen2" "$out/q.gen2b" && echo "qtrace	gen2 against itself	IDENTICAL	$(wc -l < "$out/q.gen2") lines" || echo "qtrace	gen2 against itself	DIFFERS"
cmp -s "$out/q.gen1" "$out/q.gen2" && echo "qtrace	gen1 against gen2	IDENTICAL" || {
    echo "qtrace	gen1 against gen2	DIFFERS"
    diff "$out/q.gen1" "$out/q.gen2" | head -n 6 | cut -c1-300
}
