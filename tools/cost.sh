#!/bin/sh
# THE EXACT-COUNT GATE'S MEASUREMENT: the census compiler of this tree, run over FIXED workloads whose
# sources are one pinned commit (the `snapshot` row of tools/cost.baseline): cold, each run's census
# kept as build/cost/<workload>.out; and warm after each edit of a fixed set, the answers it worked out
# again kept as build/cost/edit-<kind>.out. tools/cost_ratchet.py judges them.
#   sh tools/cost.sh                      the baseline's snapshot
#   COST_SNAPSHOT=<sha> sh tools/cost.sh  another snapshot (what `make cost-accept` records)
#   COST_COMPILER=<file> sh tools/cost.sh a census compiler already built from this tree
#
# A FIXED INPUT MEASURES THE COMPILER: the snapshot is exported whole, std included, and the census
# compiler stands at its build/avra beside the objects a build links, so every package it reads is
# the snapshot's.
# ONE PROCESS ON ONE CORE DOES ALL THE WORK: a forked worker's counts are its own, so no body is
# lowered ahead (AVRA_WORK_AHEAD_OFF) and the run is held to one core (`taskset`), the width every
# emitter reads, so objects are made in this process by one worker.
# EVERY COLD RUN STARTS BARE: an empty store, and no product a run before it left, which a build reads.
# A FILE IS READ ONLY ONCE IT IS OLDER THAN THE STAMP WINDOW (io.stamp withholds a stamp from a path
# changed in the last two seconds), so what a run stamps never depends on how fast it began.
set -eu
cd "$(dirname "$0")/.."
root=$(pwd)
out=build/cost
snapshot=${COST_SNAPSHOT:-$(awk '$1 == "snapshot" { print $2 }' tools/cost.baseline 2> /dev/null)}
[ -n "$snapshot" ] || { echo "cost: tools/cost.baseline names no snapshot"; exit 1; }
# A SHALLOW CLONE FETCHES THE ONE COMMIT IT PINS.
git cat-file -e "$snapshot^{commit}" 2> /dev/null || git fetch -q --depth=1 origin "$snapshot" 2> /dev/null || :
git cat-file -e "$snapshot^{commit}" 2> /dev/null || {
    echo "cost: snapshot $snapshot is not in this clone and could not be fetched"; exit 1; }
command -v taskset > /dev/null || { echo "cost: no taskset to hold the run to one core"; exit 1; }

# The cold workloads: a name, then the command the census compiler runs in the snapshot.
workloads() {
    cat << 'EOF'
check-cli check --counts packages/cli
build-cli build packages/cli
check-program check --counts packages/std-program
EOF
}

# THE WARM RE-RUN WORK OF AN EDIT: over the store the cold cli check left, `tapes --findings` of the
# cli is settled; then each edit of one file is made, the findings run warm and the answers it worked
# out again kept (its `worked:` line), and the file put back and the findings warmed back, so each edit
# meets the store the one before it left. The edits and their file are the warm lane's measured
# table's, so a row reads against its design budget.
# kind|text|what it becomes, `\n` between lines; a noop edits nothing.
edited=packages/cli/src/commands/cache.av
edits() {
    cat << 'EOF'
noop||
inline|//! in, its own verbs. The store is a directory of immutable packs, each the|//! in, its own verbs. The store is a folder of immutable packs, each the
literal|    println("avra cache clean: ${compacted_said(dir)}")|    println("avra cache cleaned: ${compacted_said(dir)}")
comment|    let shared? = machine_layer() else { return 0 }|    // a note\n    let shared? = machine_layer() else { return 0 }
body|    let shared? = machine_layer() else { return 0 }|    let shared? = machine_layer() else { return 0 }\n    let _ = cache_dir().length
signature|fn octets_of(packs: List<PackListed>) -> int {|fn octets_of(packs: List<PackListed>, most: int = 0) -> int {
added|fn cache_dir() -> string {|fn cache_unused() -> int { 3 }\n\nfn cache_dir() -> string {
added_after|fn octets_of(packs: List<PackListed>) -> int { packs.fold(0, (sum, p) -> sum + p.octets) }|fn octets_of(packs: List<PackListed>) -> int { packs.fold(0, (sum, p) -> sum + p.octets) }\n\nfn spare_one() -> int { 1 }
EOF
}

mkdir -p "$out"
find "$out" -mindepth 1 -delete
compiler=${COST_COMPILER:-build/avra.census}
if [ -z "${COST_COMPILER:-}" ]; then
    sh tools/census_compiler.sh "$compiler"
fi
[ -x "$compiler" ] || { echo "cost: no census compiler at $compiler"; exit 1; }

src=$out/src
mkdir -p "$src/build"
git archive "$snapshot" | tar -x -C "$src"
cp "$compiler" "$src/build/avra"
find build -maxdepth 1 -type f \( -name '*.o' -o -name '*.a' -o -name '*.so' -o -name 'avra_hot.bc' -o -name 'avra_hot.inc' \) \
    -exec cp {} "$src/build/" \;
printf '%s\n' "$snapshot" > "$out/snapshot"
cache=$root/$out/cache

# One run of the census compiler in the snapshot, once what it reads is older than the stamp window:
# its census to <name>.out, what it printed to <name>.stdout.
counted() {
    name=$1; shift
    sleep 3
    started=$(date +%s)
    # the census reports at exit only where the run accounts (AVRA_MEM_STATS)
    (cd "$src" && AVRA_MEM_STATS=1 AVRA_WORK_AHEAD_OFF=1 AVRA_PROGRAM_NET=0 AVRA_CACHE_DIR="$cache" AVRA_STORE_KEPT_HERE=1 \
        sh "$root/tools/memcap.sh" "${COST_CAP_MB:-8000}" taskset -c 0 build/avra "$@" \
        > "$root/$out/$name.stdout" 2> "$root/$out/$name.out") || {
        tail -20 "$out/$name.out"; echo "cost: $name failed ($*)"; exit 1; }
    echo "cost: $name $(($(date +%s) - started)) s"
}

# One warm findings run of the cli, its `worked:` line kept as <name>.out, its census beside it.
warm() {
    counted "$1" tapes --findings packages/cli
    mv "$out/$1.out" "$out/$1.census"
    grep '^worked: ' "$out/$1.census" > "$out/$1.out" || { echo "cost: $1 printed no worked line"; exit 1; }
}

# Each edit of the warm lane's table, over the store the cli check left.
warm_edits() {
    warm settle
    cp "$src/$edited" "$out/edited.orig"
    edits | while IFS='|' read -r kind text becomes; do
        [ -z "$text" ] || python3 "$root/tools/cost_ratchet.py" --edit "$src/$edited" "$kind" "$text" "$becomes"
        warm "edit-$kind"
        if [ -n "$text" ]; then
            cp "$out/edited.orig" "$src/$edited"
            warm "back-$kind"
        fi
    done
    find "$out/settle.out" "$out"/back-*.out -delete
}

bare() {
    find "$src" -path '*/.avra-cache*' -delete
    find "$src/packages" \( -path '*/src/main' -o -name '*.av.ll' \) -type f -delete
    mkdir -p "$cache"
    find "$cache" -mindepth 1 -delete
}

workloads | while read -r name command; do
    bare
    # shellcheck disable=SC2086
    counted "$name" $command
    [ "$name" != check-cli ] || warm_edits
done
find "$out/cache" "$src" "$out/edited.orig" -delete
