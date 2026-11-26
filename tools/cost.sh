#!/bin/sh
# THE EXACT-COUNT GATE'S MEASUREMENT: the census compiler of this tree, run over FIXED workloads whose
# sources are one pinned commit (the `snapshot` row of tools/cost.baseline): cold, each run's census
# kept as build/cost/<workload>.out; and warm after each edit of a fixed set, the answers it worked out
# again kept as build/cost/edit-<kind>.out. `avra-tools cost` judges them.
#   sh tools/cost.sh [judge|accept]       the baseline's snapshot, then (named) its verdict or its accept
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
case "${1:-}" in judge | accept | '') verdict=${1:-} ;; *) echo "cost: \`sh tools/cost.sh\` takes judge, accept or nothing, never $1"; exit 2 ;; esac
cd "$(dirname "$0")/.."
root=$(pwd)
out=build/cost
snapshot=${COST_SNAPSHOT:-$(awk '$1 == "snapshot" { print $2 }' tools/cost.baseline 2> /dev/null)}
[ -n "$snapshot" ] || { echo "cost: tools/cost.baseline names no snapshot"; exit 1; }
# A SHALLOW CLONE FETCHES THE ONE COMMIT IT PINS.
git cat-file -e "$snapshot^{commit}" 2> /dev/null || git fetch -q --depth=1 origin "$snapshot" 2> /dev/null || :
git cat-file -e "$snapshot^{commit}" 2> /dev/null || {
    echo "cost: snapshot $snapshot is not in this clone and could not be fetched"; exit 1; }
# AN ACCEPT PINS ONLY WHAT THE GATE CAN FETCH (`make cost-accept` sets COST_ACCEPTING): the gate's clone
# fetches the snapshot from origin by its sha, so a commit only this clone holds — a local one, or a
# branch's own sha where origin holds its mirror — passes here and reds every gate. It is asked of
# origin in a scratch repository, so this clone never turns shallow.
if [ "${COST_ACCEPTING:-0}" = 1 ]; then
    probe=$(mktemp -d)
    if ! { git init -q "$probe" && git -C "$probe" fetch -q --depth=1 "$(git remote get-url origin)" "$snapshot"; } 2> /dev/null; then
        find "$probe" -delete
        echo "cost: snapshot $snapshot can't be fetched from origin ($(git remote get-url origin 2> /dev/null || echo 'no origin')): the gate's clone could not measure it — name the commit by the sha origin holds"
        exit 1
    fi
    find "$probe" -delete
fi
command -v taskset > /dev/null || { echo "cost: no taskset to hold the run to one core"; exit 1; }

# The cold workloads: a name, the part it is measured in, the machine's store it runs over, the census
# tables it takes, then the command the census compiler runs in the snapshot. PARTS, each a gate slice
# of its own (COST_PART=cold-a|cold-b|laid|warm|ledger-cold|ledger-cold-a|ledger-cold-b|ledger-warm; all by default): `warm` is the
# cli's cold check and the warm edits it leaves a store for — COST_EDITS=<k>/<n> deals them, the k-th
# share of n, the noop in every share — the cold runs are two, and the pass ledger's are two more
# (`ledgered`, below). A STORE IS NOT THE COMPILER: every run but one has
# the machine's store off, so its rows are what the compiler does, whatever a store holds;
# `cold-with-store-fill` is the cli's cold check over an empty store, which it fills — the store's own
# price, ratcheted apart, its sites the check's own and so read once, from check-cli;
# `check-cli-laid` is the cli's cold check over the std answers the census compiler made of the
# snapshot's std (tools/std_answers.sh, as `make avra` makes a checkout's), laid into an empty store —
# a user's cold check, ratcheted beside the worst case the others measure. The death
# census stamps a word per 16 bytes of slab, half again the memory a run holds, so the build — the
# largest run, its fns the check's own — takes the site tables alone, under the cap.
workloads() {
    cat << 'EOF'
check-cli warm off deaths check --counts packages/cli
build-cli cold-a off sites build packages/cli
check-program cold-b off deaths check --counts packages/std-program
cold-with-store-fill cold-b filled none check --counts packages/cli
check-cli-laid laid laid none check --counts packages/cli
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

# this run's share of a list of edits on stdin: COST_EDITS=<k>/<n>, the k-th (from 1) of n dealt in
# turn, the noop — the first, which edits nothing — in every share; every edit where it names none
shared() {
    case ${COST_EDITS:-} in
        '') cat ;;
        */*) awk -v k="${COST_EDITS%/*}" -v n="${COST_EDITS#*/}" 'NR == 1 || (NR - 2) % n == k - 1' ;;
        *) echo "cost: COST_EDITS is <k>/<n>, never $COST_EDITS" >&2; exit 2 ;;
    esac
}
shared_edits() { edits | shared; }

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

# THE SNAPSHOT IS MEASURED WHERE NO CHECKOUT DECIDES: its sources, its stores and its HOME stand
# under one absolute directory, whatever path this tree was cloned to. Paths are text the compiler
# keeps and splits, so a checkout at another depth (a runner's /__w/avra/avra beside a sandbox's
# /work/x) moves the counts. One run holds the directory at a time; a second refuses while the
# first lives.
place=/tmp/avra-cost
if ! mkdir "$place.held" 2> /dev/null; then
    holder=$(cat "$place.held/pid" 2> /dev/null || :)
    if [ -n "$holder" ] && kill -0 "$holder" 2> /dev/null; then echo "cost: run $holder measures in $place"; exit 1; fi
fi
echo $$ > "$place.held/pid"
trap 'find "$place.held" -delete 2> /dev/null || :' EXIT
[ ! -e "$place" ] || find "$place" -delete
src=$place/src
mkdir -p "$src/build"
git archive "$snapshot" | tar -x -C "$src"
cp "$compiler" "$src/build/avra"
find build -maxdepth 1 -type f \( -name '*.o' -o -name '*.a' -o -name '*.so' -o -name 'avra_hot.bc' -o -name 'avra_hot.inc' \) \
    -exec cp {} "$src/build/" \;
printf '%s\n' "$snapshot" > "$out/snapshot"
cache=$place/cache

# One run of the census compiler in the snapshot, once what it reads is older than the stamp window:
# its census to <name>.out, what it printed to <name>.stdout. The machine's store is off unless the
# workload's `store` is `filled` or `laid`: then on, in the run's own cache, which every cold run
# starts bare.
counted() {
    name=$1; shift
    machine=0
    [ "${store:-off}" = off ] || machine=1
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

# THE PASS LEDGER IS MEASURED APART FROM THE COUNTS, which an instrument must not move: no counted run
# keeps a ledger, and the ledger's parts (`ledger-cold`, the cold runs of `cold-a` and `cold-b` — or
# `ledger-cold-a` and `ledger-cold-b`, each one's alone;
# `ledger-warm`, the cli's cold check and the warm edits) make the same runs again, each its own slice
# beside the counted ones, over the same snapshot by the same census compiler, uncounted, with
# `--passes --passes-rows`. ledgered <name> <command…>: one such run, its `pass-row` lines the rows of
# the workload <name> (`avra-tools cost`), its table the step's summary.
ledgered() {
    ran=$1; sub=$2; shift 2
    machine=0
    [ "${store:-off}" = off ] || machine=1
    # as a counted run is made, past the stamp window and on one core, so its asks are the same
    sleep 3
    mkdir -p "$cache/home"
    started=$(date +%s)
    (cd "$src" && unset AVRA_MACHINE_STORE_DIR && \
        HOME="$cache/home" AVRA_MACHINE_STORE=$machine AVRA_WORK_AHEAD_OFF=1 AVRA_PROGRAM_NET=0 AVRA_CACHE_DIR="$cache" AVRA_STORE_KEPT_HERE=1 \
        taskset -c 0 build/avra "$sub" --passes --passes-rows "$@" > /dev/null 2> "$root/$out/$ran.ledger") || {
        tail -20 "$out/$ran.ledger"; echo "cost: $ran's ledger run failed"; exit 1; }
    # its pass rows, and the work it did — the queries it computed, the answers an edit worked out again
    # — which its counted twin did too, to the one (`avra-tools cost`, `same_work`)
    grep -E '^(pass-row|counts: |worked: )' "$out/$ran.ledger" > "$out/$ran.out" || :
    grep -q '^pass-row' "$out/$ran.out" || { echo "cost: $ran's ledger run printed no pass rows"; exit 1; }
    # the settle and each edit undone are no rows, and no table of the ledger
    case $ran in ledger-settle | ledger-back-*) ;; *) ledger_summary "$ran" "$out/$ran.ledger" ;; esac
    rm -f "$out/$ran.ledger"
    echo "cost: $ran $(($(date +%s) - started)) s"
}

# THE PASS LEDGER OF EVERY RUN, as markdown a landing posts: the table `--passes` printed, its times
# the census compiler's own — shown, never a row; its asks and asks per unit are rows. It is kept as
# ledger.md beside the rows, and shown where the gate keeps a step's summary.
ledger_summary() {
    grep -q '^passes:' "$2" || return 0
    { echo "#### passes — $1"; echo '```'; awk '/^passes:/ { p = 1 } p && /^pass-row/ { exit } p' "$2"; echo '```'; } > "$out/$1.md"
    cat "$out/$1.md" >> "$out/ledger.md"
    [ -z "${GITHUB_STEP_SUMMARY:-}" ] || cat "$out/$1.md" >> "$GITHUB_STEP_SUMMARY"
    rm -f "$out/$1.md"
}

# One warm findings run of the cli: counted (`$how` counted), its `worked:` line kept as <name>.out,
# its census beside it; or the ledger's (`$how` ledgered), its pass rows as ledger-<name>.out.
warm() {
    if [ "$how" = ledgered ]; then ledgered "ledger-$1" tapes --findings packages/cli; return; fi
    counted "$1" tapes --findings packages/cli
    mv "$out/$1.out" "$out/$1.census"
    grep '^worked: ' "$out/$1.census" > "$out/$1.out" || { echo "cost: $1 printed no worked line"; exit 1; }
}

# Each edit of the warm lane's table, over the store the cli check left. An edit undone is built back,
# so the next edit stands on the store the check left; the share's last edit has no next, and its
# undoing builds nothing.
# THE NOOP CHECK: the cli's check again over the store its cold check left, nothing edited — what a
# user's second `avra check` does, which the warm edits (`tapes --findings`) never ask. Counted as a
# cold run is, its census the rows of `noop-check`. The store and the run's cache the cold check left
# are kept aside as they stand (`noop_kept`), with the edited file as it stood, the warm edits run on
# the store itself, and the noop check runs last, over what was kept: no edit stands on a store the
# noop moved, and the noop meets no file an edit touched.
noop_kept() {
    [ ! -e "$place/noop-held" ] || find "$place/noop-held" -delete
    mkdir -p "$place/noop-held"
    cp -a "$src/packages/cli/.avra-cache" "$place/noop-held/store"
    cp -a "$cache" "$place/noop-held/cache"
    cp -a "$src/$edited" "$place/noop-held/edited"
}
noop_check() {
    find "$src/packages/cli/.avra-cache" "$cache" -delete
    mv "$place/noop-held/store" "$src/packages/cli/.avra-cache"
    mv "$place/noop-held/cache" "$cache"
    cp -a "$place/noop-held/edited" "$src/$edited"
    find "$place/noop-held" -delete
    counted noop-check check --counts packages/cli
}

# edit_in_place <file> <kind> <text> <becomes>: one edit (`avra-tools cost edit`), made on a copy and written back
# INTO the file, never over it. A file's stamp carries its inode, so an edit published by a rename is a
# different event to the store than one written in place, and its taking back (`cp -p` of the original)
# would not return the original stamp: what a warm run asks would depend on how the edit was written.
edit_in_place() {
    cp -p "$1" "$out/edit.next"
    sh "$root/tools/avra_tools.sh" cost edit "$out/edit.next" "$2" "$3" "$4" || return 1
    cat "$out/edit.next" > "$1"
    rm -f "${out:?}/edit.next"
}

warm_edits() {
    warm settle
    cp "$src/$edited" "$out/edited.orig"
    last=$(shared_edits | tail -1 | cut -d'|' -f1)
    shared_edits | while IFS='|' read -r kind text becomes; do
        [ -z "$text" ] || edit_in_place "$src/$edited" "$kind" "$text" "$becomes"
        warm "edit-$kind"
        if [ -n "$text" ]; then
            cp "$out/edited.orig" "$src/$edited"
            [ "$kind" = "$last" ] || warm "back-$kind"
        fi
    done
    find "$out" -maxdepth 1 \( -name settle.out -o -name 'back-*.out' -o -name ledger-settle.out -o -name 'ledger-back-*.out' \) -delete
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

# no std answers beside the census compiler: what a run reads of std it works out itself
unlaid() { [ ! -e "$src/build/answers" ] || find "$src/build/answers" -delete; }

bare() {
    find "$src" -path '*/.avra-cache*' -delete
    find "$src/packages" \( -path '*/src/main' -o -name '*.av.ll' \) -type f -delete
    mkdir -p "$cache"
    find "$cache" -mindepth 1 -delete
}

# the snapshot's std answers beside the census compiler, made once a run by the writer `make avra`
# runs, as it runs, outside any count: a package the compiler refuses (the snapshot's own compiler,
# under today's laws) ships its answers and no verdict. Only the std packages the cli's sources reach
# are written: the others the check never reads, and writing them is most of the slice's wall.
# THEY ARE KEPT ACROSS RUNS at COST_ANSWERS_KEPT (a gate lays the landed run's from the builder's release): laid beside
# the census compiler first, they stand where the writer's key (the compiler's bytes, the paths, every
# file judged) is theirs, and are written again only where it isn't — then kept again, with
# `<kept>.fresh` beside them saying so.
laid() {
    [ ! -f "$src/build/answers/inputs" ] || return 0
    kept=${COST_ANSWERS_KEPT:-$root/build/cost-answers}
    if [ -f "$kept/inputs" ]; then mkdir -p "$src/build/answers" && cp -R "$kept/." "$src/build/answers/"; fi
    started=$(date +%s)
    # shellcheck disable=SC2046
    (unset AVRA_MACHINE_STORE_DIR && HOME="$cache/home" STD_ANSWERS_REFUSED=skip \
        sh "$root/tools/std_answers.sh" "$src/build/avra" "$src/packages" "$src/build/answers" $(reached packages/cli)) ||
        { echo "cost: the snapshot's std answers were not made"; exit 1; }
    echo "cost: the snapshot's std answers $(($(date +%s) - started)) s"
    # the std packages a verdict stands for, which the ratchet holds to the baseline's
    # (tools/cost.verdicts): one losing its verdict means today's compiler refuses the snapshot's
    cat "$src/build/answers"/verdict-* 2> /dev/null | cut -f1 | sort -u > "$root/$out/verdicts"
    if ! cmp -s "$src/build/answers/inputs" "$kept/inputs" 2> /dev/null; then
        [ ! -e "$kept" ] || find "$kept" -delete
        mkdir -p "$kept" && cp -R "$src/build/answers/." "$kept/" && : > "$kept.fresh"
    fi
    bare
}

# the std packages the package at `$1` in the snapshot reaches, its `use @std.<name>` lines closed over
# the packages they name, the prelude always, one a line
reached() {
    todo=$1; seen=" std-prelude "
    while [ -n "$todo" ]; do
        # shellcheck disable=SC2086
        set -- $todo; at=$1; shift; todo="$*"
        for n in $(grep -rhoE '@std\.[a-z_]+' "$src/$at/src" --include='*.av' 2> /dev/null | sed 's/@std\.//' | sort -u); do
            [ -d "$src/packages/std-$n" ] || continue
            case "$seen" in *" std-$n "*) continue ;; esac
            seen="$seen std-$n "; todo="$todo packages/std-$n"
        done
    done
    printf '%s\n' $seen
}

# THE WARM-EDIT MATRIX: every kind of edit a person makes, and its taking back, met by a check and by
# a build of the cli, with the std answers laid beside the compiler and without — each part
# (`matrix-<check|build>-<laid|bare>`) a slice of its own. A part starts its command cold over the
# snapshot, then makes each edit and runs the command warm, then takes it back and runs it again,
# every run uncounted with `--passes --passes-rows`: its pass rows are the rows of
# `matrix-<command>-<laid|bare>-<kind>` (and `…-back-<kind>`), its wall in ms said in the ledger's
# markdown, never a row, a wall over WARM_FLAG_MS flagged. A run the compiler refuses (the broken
# edit) is measured as it stands: its wall said, its rows kept where it printed them.
# kind|file|text|becomes: `text` stands in the file once and becomes `becomes` (`\n` a line
# break; several places apart by `&&&`); `renamed` renames the word through the file; `newfile`
# writes `becomes` as a file that wasn't there; `none` edits nothing.
WARM_FLAG_MS=300
matrix_edits() {
    cat << 'EOF'
none|packages/cli/src/commands/cache.av||
body|packages/cli/src/commands/cache.av|    let shared? = machine_layer() else { return 0 }|    let shared? = machine_layer() else { return 0 }\n    let _ = cache_dir().length
signature|packages/cli/src/commands/cache.av|fn octets_of(packs: List<PackListed>) -> int {|fn octets_of(packs: List<PackListed>, most: int = 0) -> int {
added|packages/cli/src/commands/cache.av|fn cache_dir() -> string {|fn cache_unused() -> int { 3 }\n\nfn cache_dir() -> string {
deleted|packages/cli/src/commands/cache.av|fn octets_of(packs: List<PackListed>) -> int { packs.fold(0, (sum, p) -> sum + p.octets) }&&&${octets_of(before)} → ${octets_of(after)}|&&&${before.fold(0, (sum, p) -> sum + p.octets)} → ${after.fold(0, (sum, p) -> sum + p.octets)}
renamed|packages/cli/src/commands/cache.av|octets_of|octets_in
newfile|packages/cli/src/commands/cache_note.av||/// A note the cache command keeps.\nexport fn cache_note() -> int { 1 }
fanout|packages/std-avrac/src/core/span.av|export type Span = { lo: int, hi: int }|export type Span = { lo: int, hi: int, mark: int = 0 }
std|packages/std-text/src/text.av|    s + repeat(" ", width - cells(s))|    let room = width - cells(s)\n    s + repeat(" ", room)
broken|packages/cli/src/commands/cache.av|fn cache_dir() -> string { joined_path(package_root(here()) ?? here(), ".avra-cache/tapes") }|fn cache_dir() -> string { joined_path(package_root(here()) ?? here(), ".avra-cache/tapes")
EOF
}

# cell <name> <command…>: one run of the matrix, uncounted, past the stamp window and on one core as a
# counted run is: its pass rows to <name>.out (and <name> among the workloads where it printed any),
# its wall in `$cell_ms`
cell() {
    ran=$1; shift
    machine=0
    [ "${store:-off}" = off ] || machine=1
    sleep 3
    mkdir -p "$cache/home"
    t0=$(date +%s%N)
    st=0
    (cd "$src" && unset AVRA_MACHINE_STORE_DIR && \
        HOME="$cache/home" AVRA_MACHINE_STORE=$machine AVRA_WORK_AHEAD_OFF=1 AVRA_PROGRAM_NET=0 AVRA_CACHE_DIR="$cache" AVRA_STORE_KEPT_HERE=1 \
        taskset -c 0 build/avra "$@" > /dev/null 2> "$root/$out/$ran.ledger") || st=$?
    cell_ms=$((($(date +%s%N) - t0) / 1000000))
    if grep '^pass-row' "$out/$ran.ledger" > "$out/$ran.out"; then echo "$ran" >> "$out/workloads"; else rm -f "${out:?}/${ran:?}.out"; fi
    [ "$st" = 0 ] || cell_said=" (refused, exit $st)"
    rm -f "${out:?}/${ran:?}.ledger"
}

# `<ms>` with the flag a wall over WARM_FLAG_MS wears
walled() { if [ "$1" -gt "$WARM_FLAG_MS" ]; then printf '**%s ms ⚠**' "$1"; else printf '%s ms' "$1"; fi; }

# one part of the matrix: `matrix-<check|build>-<laid|bare>`
matrix() {
    verb=${1#matrix-}; verb=${verb%-*}
    lay=${1##*-}
    store=off
    case $verb in check | build) ;; *) echo "cost: no matrix part $1"; exit 2 ;; esac
    bare
    if [ "$lay" = laid ]; then store=laid; laid; else unlaid; fi
    cell_said=""
    cell "matrix-$verb-$lay-cold" "$verb" --passes --passes-rows packages/cli
    rm -f "${out:?}/matrix-${verb:?}-${lay:?}-cold.out"
    sed -i "/^matrix-$verb-$lay-cold\$/d" "$out/workloads"
    printf '\n#### %s %s — %s cold, `%s packages/cli`\n\n| edit | warm | taken back |\n|---|---|---|\n' \
        "$verb" "$lay" "$(walled "$cell_ms")" "$verb" >> "$out/ledger.md"
    matrix_edits | shared | while IFS='|' read -r kind file text becomes; do
        name="matrix-$verb-$lay-$kind"
        cell_said=""
        case $kind in
            none) ;;
            newfile) printf '%b\n' "$becomes" > "$src/$file" ;;
            renamed) cp -p "$src/$file" "$out/matrix.orig" && edit_in_place "$src/$file" rename "$text" "$becomes" ;;
            *) cp -p "$src/$file" "$out/matrix.orig" && edit_in_place "$src/$file" "$kind" "$text" "$becomes" ;;
        esac
        cell "$name" "$verb" --passes --passes-rows packages/cli
        edit_ms=$cell_ms; edit_said=$cell_said
        if [ "$kind" = none ]; then
            printf '| %s | %s%s | — |\n' "$kind" "$(walled "$edit_ms")" "$edit_said" >> "$out/ledger.md"
            continue
        fi
        if [ "$kind" = newfile ]; then rm -f "${src:?}/${file:?}"; else cp -p "$out/matrix.orig" "$src/$file"; fi
        cell_said=""
        cell "matrix-$verb-$lay-back-$kind" "$verb" --passes --passes-rows packages/cli
        printf '| %s | %s%s | %s%s |\n' "$kind" "$(walled "$edit_ms")" "$edit_said" "$(walled "$cell_ms")" "$cell_said" >> "$out/ledger.md"
    done
    rm -f "${out:?}/matrix.orig"
}

# the parts this run measures, in the order named, and every workload they measure — what
# `avra-tools cost` judges. Several parts in one run (`COST_PART="laid ledger-cold"`) meet in one
# measurement as the whole run's do, so a run that depends on another before it shows.
part=${COST_PART:-all}
for p in $part; do
    case $p in all | answers | cold-a | cold-b | laid | warm | ledger-cold | ledger-cold-a | ledger-cold-b | ledger-warm | matrix-check-bare | matrix-check-laid | matrix-build-bare | matrix-build-laid) ;;
        *) echo "cost: COST_PART names all, answers, cold-a, cold-b, laid, warm, ledger-cold, ledger-cold-a, ledger-cold-b, ledger-warm or a matrix-<check|build>-<laid|bare>, never $p"; exit 2 ;; esac
done
if [ -n "${COST_EDITS:-}" ]; then printf '%s edits %s\n' "$part" "$COST_EDITS"; else printf '%s\n' "$part"; fi > "$out/part"
: > "$out/workloads"
# measure <how> <part>: each workload of the part, counted, or its ledger's run (the ledger of the laid
# check is not kept: its passes are the cli check's, over answers it reads)
measure() {
    how=$1
    workloads | while read -r name in_part store census command; do
        if [ "$how" = ledgered ]; then
            case $2:$in_part in
                all:laid) continue ;;
                all:* | ledger-cold:cold-a | ledger-cold:cold-b | ledger-cold-a:cold-a | ledger-cold-b:cold-b | ledger-warm:warm) ;;
                *) continue ;;
            esac
            lname=ledger-$name
        else
            [ "$2" = all ] || [ "$2" = "$in_part" ] || continue
            lname=$name
        fi
        echo "$lname" >> "$out/workloads"
        [ "$name" != check-cli ] || [ "$how" = ledgered ] || echo noop-check >> "$out/workloads"
        [ "$name" != check-cli ] || shared_edits | while IFS='|' read -r kind _ _; do
            if [ "$how" = ledgered ]; then echo "ledger-edit-$kind"; else echo "edit-$kind"; fi >> "$out/workloads"; done
        bare
        # THE LAID ANSWERS ARE THE LAID WORKLOAD'S ALONE: the compiler reads std answers beside it, so
        # those a laid check leaves would answer every run after it in the same measurement — a run is
        # the same whichever part, or which run before it, the measurement holds
        if [ "$store" = laid ]; then laid; else unlaid; fi
        # shellcheck disable=SC2086
        $how "$lname" $command
        [ "$how" = ledgered ] || [ "$census" = none ] || resolved "$name"
        # THE LAID NOOP: the laid check again over the store it left, the std answers still laid
        # beside the compiler — what a user's second `avra check` does, the toolchain's std vouched for
        if [ "$lname" = check-cli-laid ]; then
            echo laid-noop >> "$out/workloads"
            counted laid-noop check --counts packages/cli
        fi
        [ "$name" != check-cli ] || [ "$how" = ledgered ] || noop_kept
        [ "$name" != check-cli ] || warm_edits
        # the warm edits' runs name themselves (`counted`), so the workload is known by `lname` after them
        [ "$lname" != check-cli ] || noop_check
    done
}
# the ledger's markdown names the program it measured and the snapshot it measured over
case " $part " in *" all "* | *" ledger-"* | *" matrix-"*) ;; *) false ;; esac &&
    printf '### The pass ledger — %s\n\nprogram `%s`, over the snapshot `%s`%s\n\n' "$part" \
        "$(git rev-parse --short=8 HEAD)" "$(printf '%.8s' "$snapshot")" "${COST_EDITS:+, edits $COST_EDITS}" > "$out/ledger.md"
for p in $part; do
    case $p in
        ledger-*) measure ledgered "$p" ;;
        matrix-*) matrix "$p" ;;
        # THE ANSWERS ALONE, made once and kept (COST_ANSWERS_KEPT) for every run that lays them: no
        # workload, nothing counted
        answers) laid ;;
        all)
            measure counted all
            measure ledgered all
            ;;
        *) measure counted "$p" ;;
    esac
done
# THE CANDIDATES: every cold run's sites classified to the zero-cost technique that would remove their
# cost, the top of each named where the snapshot declares it (docs/ZERO_COST.md); a part whose runs
# take no site tables (laid) has none
if ls "$out"/*.sites > /dev/null 2>&1; then
    "$src/build/avra" census --candidates --root "$src" "$out"/*.sites > "$out/candidates.txt"
else
    : > "$out/candidates.txt"
fi
for made in "$place" "$out/edited.orig"; do [ ! -e "$made" ] || find "$made" -delete; done
# THE VERDICT, where one is asked (`make cost` judges, `make cost-accept` records): the run judged by
# `avra-tools cost`, so the measurement and the verdict change together and the Makefile never does
[ -z "$verdict" ] || sh "$root/tools/avra_tools.sh" cost "$verdict" "$out"
