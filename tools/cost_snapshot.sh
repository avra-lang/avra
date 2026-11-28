#!/bin/sh
# THE PINNED SNAPSHOT STILL CHECKS. cost/SNAPSHOT is the fixed input every count is
# measured over (tools/cost.sh), so a law change that refuses something in it passes every check of
# the tree it was written in and then fails every cost slice of the train that carries it. This checks
# the snapshot's packages/cli with this tree's compiler, as the cost workloads do — the snapshot laid
# down whole, the compiler beside it, so its std is the snapshot's — and a refusal is named with its
# two remedies.
#   sh tools/cost_snapshot.sh
set -eu
. "$(dirname "$0")/lib/tree.sh"
cd "$tree"
snapshot=$(cat "$tree/cost/SNAPSHOT" 2> /dev/null)
[ -n "$snapshot" ] || { echo "cost-snapshot: cost/SNAPSHOT pins no snapshot" >&2; exit 1; }
[ -x "$avra" ] || { echo "cost-snapshot: no compiler at $avra — build it first" >&2; exit 1; }
# by its tag, as tools/cost.sh fetches it; a pin from before the tags by its sha
tag=cost-snapshot-$(printf '%.8s' "$snapshot")
git cat-file -e "$snapshot^{commit}" 2> /dev/null || git fetch -q --depth=1 origin "refs/tags/$tag:refs/tags/$tag" 2> /dev/null ||
    git fetch -q --depth=1 origin "$snapshot" 2> /dev/null || :
git cat-file -e "$snapshot^{commit}" 2> /dev/null || { echo "cost-snapshot: the snapshot $snapshot is not in this clone and did not fetch" >&2; exit 1; }
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-snap.XXXXXX")
trap 'find "$work" -delete 2> /dev/null || :' EXIT
git archive "$snapshot" | tar -x -C "$work"
mkdir -p "$work/build" "$work/cache/home"
cp "$avra" "$work/build/avra"
t0=$(date +%s)
st=0
(cd "$work" && HOME="$work/cache/home" AVRA_CACHE_DIR="$work/cache" AVRA_PROGRAM_NET=0 build/avra check packages/cli) > "$work/check.log" 2>&1 || st=$?
took=$(( $(date +%s) - t0 ))
short=$(printf '%.8s' "$snapshot")
if [ "$st" = 0 ]; then
    echo "cost-snapshot: the snapshot $short's cli checks clean with this tree's compiler (${took}s)"
    exit 0
fi
tail -40 "$work/check.log"
echo "cost-snapshot: REFUSED — this tree's compiler refuses the pinned snapshot $short's cli (exit $st, ${took}s), so every cost slice would fail; keep the form it refuses recognised until the snapshot moves, or move the snapshot (COST_SNAPSHOT=<sha> make cost-accept, a whole run)" >&2
exit 1
