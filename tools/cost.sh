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

# The cold workloads: a name, the part it is measured in, the machine's store it runs over, the census
# tables it takes, then the command the census compiler runs in the snapshot. PARTS, each a gate slice
# of its own (COST_PART=cold-a|cold-b|warm; all by default): `warm` is the cli's cold check and the
# warm edits it leaves a store for — COST_EDITS=<k>/<n> deals them, the k-th share of n, the noop in
# every share — and the cold runs are two. A STORE IS NOT THE COMPILER: every run but one has
# the machine's store off, so its rows are what the compiler does, whatever a store holds;
# `cold-with-store-fill` is the cli's cold check over an empty store, which it fills — the store's own
# price, ratcheted apart, its sites the check's own and so read once, from check-cli. The death
# census stamps a word per 16 bytes of slab, half again the memory a run holds, so the build — the
# largest run, its fns the check's own — takes the site tables alone, under the cap.
workloads() {
    cat << 'EOF'
check-cli warm off deaths check --counts packages/cli
build-cli cold-a off sites build packages/cli
check-program cold-b off deaths check --counts packages/std-program
cold-with-store-fill cold-b filled none check --counts packages/cli
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

# this run's share of the edits: COST_EDITS=<k>/<n>, the k-th (from 1) of n dealt in turn, the noop —
# the first, which edits nothing — in every share; every edit where it names none
shared_edits() {
    case ${COST_EDITS:-} in
        '') edits ;;
        */*) edits | awk -v k="${COST_EDITS%/*}" -v n="${COST_EDITS#*/}" 'NR == 1 || (NR - 2) % n == k - 1' ;;
        *) echo "cost: COST_EDITS is <k>/<n>, never $COST_EDITS" >&2; exit 2 ;;
    esac
}

mkdir -p "$out"
find "$out" -mindepth 1 -delete
compiler=${COST_COMPILER:-build/avra.census}
# THE CENSUS COMPILER'S BUILDER IS THIS TREE'S OWN, TWICE OVER: a compiler built once from another
# source's (generation 1) lays this tree's code as that one would, and moves the counts it builds. The
# builder's record (`make avra` writes it beside the binary, tools/work built-from) names its source
# and its generation; one built from another source, of generation 1, or with no record is refused.
# A census compiler built elsewhere (COST_COMPILER, a gate's seed) carries its builder's record beside
# it (tools/census_compiler.sh) and is held to the same: one rule, the builder's.
held_builder() { # <what it is> <its record>
    read -r b_hash _b_at b_gen _b_more < "$2" 2> /dev/null || { echo "cost: $1 has no record of what built it ($2) — \`make avra\` twice"; exit 1; }
    [ "$b_hash" = "$(sh tools/work built-from . | cut -d' ' -f1)" ] || { echo "cost: $1 was built from another compiler source — \`make avra\` twice"; exit 1; }
    [ "${b_gen:-1}" -ge 2 ] || { echo "cost: $1 is generation ${b_gen:-1} of this tree — \`make avra\` once more"; exit 1; }
}
builder=${CENSUS_BUILDER:-build/avra}
if [ -z "${COST_COMPILER:-}" ]; then
    held_builder "the census builder $builder" "$(dirname "$builder")/.$(basename "$builder")-built-from"
    sh tools/census_compiler.sh "$compiler"
else
    held_builder "the census compiler $compiler's builder" "$(dirname "$compiler")/.$(basename "$compiler")-built-from"
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
# its census to <name>.out, what it printed to <name>.stdout. The machine's store is off unless the
# workload's `store` is `filled`: then on, in the run's own cache, which every cold run starts bare.
counted() {
    name=$1; shift
    machine=0
    [ "${store:-off}" != filled ] || machine=1
    sleep 3
    started=$(date +%s)
    # the census reports at exit only where the run accounts (AVRA_MEM_STATS), and the tables the
    # workload takes (the C side's own counts, which move no counter of the run's); NO STORE IS
    # INHERITED: the machine's cache is this run's own and its HOME is empty
    mkdir -p "$cache/home"
    (cd "$src" && unset AVRA_MACHINE_STORE_DIR && export AVRA_CENSUS_SITES=1 AVRA_CENSUS_DEATHS=1 && \
        { [ "${census:-deaths}" = deaths ] || unset AVRA_CENSUS_DEATHS; } && \
        { [ "${census:-deaths}" != none ] || unset AVRA_CENSUS_SITES; } && \
        HOME="$cache/home" AVRA_MACHINE_STORE=$machine AVRA_MEM_STATS=1 AVRA_CENSUS_TOP=1000000 AVRA_WORK_AHEAD_OFF=1 AVRA_PROGRAM_NET=0 AVRA_CACHE_DIR="$cache" AVRA_STORE_KEPT_HERE=1 \
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

# Each edit of the warm lane's table, over the store the cli check left. An edit undone is built back,
# so the next edit stands on the store the check left; the share's last edit has no next, and its
# undoing builds nothing.
warm_edits() {
    warm settle
    cp "$src/$edited" "$out/edited.orig"
    last=$(shared_edits | tail -1 | cut -d'|' -f1)
    shared_edits | while IFS='|' read -r kind text becomes; do
        [ -z "$text" ] || python3 "$root/tools/cost_ratchet.py" --edit "$src/$edited" "$kind" "$text" "$becomes"
        warm "edit-$kind"
        if [ -n "$text" ]; then
            cp "$out/edited.orig" "$src/$edited"
            [ "$kind" = "$last" ] || warm "back-$kind"
        fi
    done
    find "$out" -maxdepth 1 \( -name settle.out -o -name 'back-*.out' \) -delete
}

# A cold run's site lines with every address its census binary's symbol: <name>.sites, which
# `avra census --candidates` reads.
resolved() {
    grep -E '^(typed|streq|empty-open): site 0x|^(pair|move|reuse): ' "$out/$1.out" > "$out/$1.raw" || :
    grep -oE '0x[0-9a-f]+' "$out/$1.raw" | sort -u > "$out/$1.addrs"
    xargs addr2line -f -e "$src/build/avra" < "$out/$1.addrs" | awk 'NR % 2 == 1' | paste -d' ' "$out/$1.addrs" - > "$out/$1.names"
    awk 'NR == FNR { name[$1] = $2; next } { for (i = 1; i <= NF; i++) if ($i in name) $i = name[$i]; print }' \
        "$out/$1.names" "$out/$1.raw" > "$out/$1.sites"
    find "$out/$1.raw" "$out/$1.addrs" "$out/$1.names" -delete
}

bare() {
    find "$src" -path '*/.avra-cache*' -delete
    find "$src/packages" \( -path '*/src/main' -o -name '*.av.ll' \) -type f -delete
    mkdir -p "$cache"
    find "$cache" -mindepth 1 -delete
}

# the part this run measures, and every workload it measures — what tools/cost_ratchet.py judges
part=${COST_PART:-all}
case $part in all | cold-a | cold-b | warm) ;; *) echo "cost: COST_PART is all, cold-a, cold-b or warm, never $part"; exit 2 ;; esac
if [ -n "${COST_EDITS:-}" ]; then printf '%s edits %s\n' "$part" "$COST_EDITS"; else printf '%s\n' "$part"; fi > "$out/part"
: > "$out/workloads"
workloads | while read -r name in_part store census command; do
    [ "$part" = all ] || [ "$part" = "$in_part" ] || continue
    echo "$name" >> "$out/workloads"
    [ "$name" != check-cli ] || shared_edits | while IFS='|' read -r kind _ _; do echo "edit-$kind" >> "$out/workloads"; done
    bare
    # shellcheck disable=SC2086
    counted "$name" $command
    [ "$census" = none ] || resolved "$name"
    [ "$name" != check-cli ] || warm_edits
done
# THE CANDIDATES: every cold run's sites classified to the zero-cost technique that would remove their
# cost, the top of each named where the snapshot declares it (docs/ZERO_COST.md)
"$src/build/avra" census --candidates --root "$src" "$out"/*.sites > "$out/candidates.txt"
for made in "$out/cache" "$src" "$out/edited.orig"; do [ ! -e "$made" ] || find "$made" -delete; done
