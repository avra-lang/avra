#!/bin/sh
# THE GATE, IN SLICES: every receipt a landing is held to, cut into slices that each run alone in a
# tree of their own, so N machines run N slices at once and the gate takes as long as its longest
# slice. A slice builds the compiler of HEAD itself when build/avra was built from anything else,
# runs every row on the program layer, the net off but where a row's claim is the net, empties the
# stores a cold row reads, bounds every command, keeps each row's words under build/gate/<slice>/, and
# ends with ONE line:
#   GATE <slice> <sha8> PASS|FAIL|OVER rows=<n> failed=<n> <seconds>s
# exiting 0 on PASS, 1 on FAIL or OVER. A SLICE HAS A WALL BUDGET (GATE_SLICE_SECS, 900 s; 1500 s for an edit-f or edit-g part), its
# compiler build included: one past it is stopped, its rows say `row <slice> OVER`, its verdict OVER.
#
#   sh tools/gate.sh list               each slice, one a line, with what it holds
#   sh tools/gate.sh jobs               the runner jobs: each job, then the slices it runs, dealt by seconds
#   sh tools/gate.sh pkgs-suites [<base>]   the suites the pkgs family runs over the diff from <base> (every one, with none)
#   sh tools/gate.sh seconds <log…>     each suite row's measured seconds (`fact path <path> <n>`) kept in
#                                       tools/gate/path.seconds, which the cli's shares are dealt by
#   sh tools/gate.sh <slice> [arg]      one slice; the idioms slices take the base sha their diff starts at
#   sh tools/gate.sh seed               build/gate/compiler-<sha8>.tar.gz: HEAD's compiler of generation 2,
#                                       built here first where none of HEAD's stands, and every object a
#                                       tree links with; `pack` is its other name. Run it once; every slice
#                                       then starts from `unpack` and builds no compiler but a cost slice's
#                                       census compiler.
#   sh tools/gate.sh unpack <file>      seeds this tree from a pack, and holds its stamp to HEAD's: a
#                                       seeded slice builds no compiler
#   sh tools/gate.sh census             build/gate/census-<sha8>.tar.gz: the census compiler, built by the
#                                       seed's compiler of generation 2, with its record. Run once after
#                                       the seed; a cost slice that holds it builds no census compiler.
#
# A test row runs every suite (AVRA_SUITE_ALL=1), so it names every failing case, never only the first.
#
. "$(dirname "$0")/lib/scratch.sh"
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1
unset AVRA_PROGRAM AVRA_PROGRAM_MODE
export AVRA_SUITE_ALL=1
# wisp is built once, by HEAD's compiler, the one this gate seeds: ./wisp would otherwise
# take main's published compiler on a Linux runner, a stranger to this tree's laws
./wisp --compiler "$root/build/avra" --path >/dev/null || :

# the bound of one row, and of a compiler build
ROW_SECS=${GATE_ROW_SECS:-2400}
# every `test` row's failing NAMES are held to tools/gate/<package>.names, the cases a sandbox fails
# the packages whose tests the doors slices run
DOORS_A="std-json std-task std-validate std-text std-sql std-queue std-time"
DOORS_B="std-ui std-http"

slices() {
    cat <<'EOF'
build      make try; make avra twice, the second cold, the two binaries one; cli build cold+warm
avrac-a    test packages/std-avrac — half of src/compiler/tests, dealt in turn, and every dir of src/compiler but tests and soundness
avrac-g    test packages/std-avrac — the other half of src/compiler/tests, and src/compiler/soundness
avrac-d    test packages/std-avrac — src/features/[n-r]*
avrac-f    test packages/std-avrac — src/features' own files, and every dir of src/ but compiler and features
idioms-avrac  check --baseline tools/idioms.baseline on std-avrac, when the diff from <base> touches it
idioms-cli    the same on cli
idioms     the same on every other package the diff from <base> touches
store-fuzz the store fuzzer's model self-test, then seeds 1-8 of 12 edits each over build/avra: warm == cold byte for byte, the store clean (`cache check`), the walk held, a fresh copy over the same machine store as the tree, nothing worked where nothing moved
fmt        fmt --check on every .av the diff from <base> changes (tools/fmt_changed.sh); <base> is the program landed last, never a batch's own base
sound      AVRA_SOUND_CHECK=1 check packages/cli, the memory pass's proof run over the program, 0 defects; AVRA_VERIFY_LLVM=1 build packages/cli, every emitted fn verified
cost-answers the snapshot's std answers, made once by the census compiler (COST_PART=answers) for every slice that lays them
cost-cold-a make cost, COST_PART=cold-a: the census compiler (built here by this tree's of generation 2) over the record under cost/'s snapshot — build-cli; every count within 0.05% of its row
cost-cold-b make cost, COST_PART=cold-b: check-program, and the cli's check over an empty store, the store's fill
cost-laid  make cost, COST_PART=laid: the cli's cold check over the std answers the census compiler makes of the snapshot's std, laid into an empty store
cost-ledger-cold-a make cost, COST_PART=ledger-cold-a: the pass ledger of cold-a's run, made again uncounted beside it; each pass's asks and asks per unit within 0.05% of its row
cost-ledger-cold-b make cost, COST_PART=ledger-cold-b: the same of cold-b's runs
cost-ledger-warm make cost, COST_PART=ledger-warm: the pass ledger of the cli's cold check and every warm edit, made again uncounted beside cost-warm; asks per moved item
cost-matrix-check-bare make cost, COST_PART=matrix-check-bare: the warm-edit matrix — every kind of edit and its taking back, met by a warm check of the cli, no std answers laid; each pass's asks per cell a row, each wall said
cost-matrix-check-laid make cost, COST_PART=matrix-check-laid: the same, the std answers laid beside the compiler
doors-a    test std-json std-task std-validate std-text std-sql std-queue std-time
doors-b    test std-ui std-http; make ui-host-test and ui-host, std-ui's program tests built and run
ui-browser the UI board: its wasm claims over the page glue (tools/ui_board.sh), its native binary's symbols and bytes (tools/ui_board_native.sh), then its claims in headless Firefox (tools/ui_board_browser.sh)
storyboard test std-ui_gallery: every view std-ui declares told by a story, every case's semantic snapshot on each target held to its golden; then every case under every dial judged in headless Firefox (tools/storyboard_browser.sh)
findings-a tapes --findings on std-avrac and cli, 0 refusals
findings-b the same on a third of every other package, dealt in turn
findings-c the next third
findings-d the last third
warnings-a witness_program_warnings — the cli built cold and again with no change
warnings-b witness_program_warnings — the cases under tools/program-warnings/, against their frozen warnings
warnings-c witness_program_warnings — the cli edited, built warm on the program layer
edit-a     witness_program_edit, WITNESS_ONLY="embed infer composed gathered check lawed derived", the frontier walk checked
edit-e     witness_program_edit, WITNESS_ONLY=rename, the frontier walk checked
keepers-a1 every keeper of KEEPERS_A1 no other slice runs, a row each
keepers-a2 the same of KEEPERS_A2
keepers-wasm the same of KEEPERS_WASM, the browser's libraries beside it
keepers-clock clock-holds, the keeper that reads a stopwatch, alone on its runner
keepers-heavy-1 witness_place_kill, a tools witness too long to share (892 s on train35), alone, its budget 1500 s
keepers-heavy-2 witness_machine_store, a tools witness too long to share (412-712 s), alone
EOF
    splits | while IFS='|' read -r family parts what; do
        n=1
        while [ "$n" -le "$parts" ]; do
            printf '%-10s %s — part %d of %d\n' "$family-$n" "$what" "$n" "$parts"
            n=$((n + 1))
        done
    done
}

# THE SPLITS: a slice too long for one runner is the parts of its own list, dealt in turn — its family,
# how many parts, what the list holds. `list` names each part (the workflow's matrix is that list) and a
# part runs its share; a row, a case or a path added joins its family's list, never one part's.
splits() {
    cat <<'EOF'
avrac-b|3|test packages/std-avrac — src/features/[a-e]*, its dirs dealt in turn
avrac-c|2|test packages/std-avrac — src/features/[f-m]*, its dirs dealt in turn
avrac-e|2|test packages/std-avrac — src/features/[s-z]*, its dirs dealt in turn
edit-n|13|witness_program_edit's numbered edits, each alone over its own cold product, the frontier walk checked; the witness's edit count held to the parts
edit-f|2|witness_program_edit's whole-mode cases (modes-whole), each alone over its own cold product, the frontier walk checked
edit-g|2|witness_program_edit's layered-mode cases (modes-layered), each alone over its own cold product, the frontier walk checked
cli|7|test packages/cli, a row a test, dealt by their measured seconds (tools/gate/path.seconds), failing names held to tools/gate/cli.names
program|6|the rows of program_rows — std-program, std-relation, rt-header, rt-ns and each runtime test (runtime/tests/*.c) — dealt in turn
refusal|8|witness_program_refusal over its cases, dealt in turn
needs|6|witness_program_needs over every package and refusal witness, dealt in turn
witness-b|5|the witnesses and attacks of witness_b_rows, dealt in turn
pkgs|2|test every package's suite no slice above names, of the packages the diff from <base> reaches (tools/affected_packages.sh; every one where there is no <base>), dealt by their measured seconds; an owed one (tools/gate/suites.owed) judged by its line
cost-warm|7|make cost, COST_PART=warm: the cli's cold check, then the warm edits (COST_EDITS) dealt in turn, the noop in every part
cost-matrix-build-bare|2|make cost, COST_PART=matrix-build-bare: the warm-edit matrix met by a warm build, each part the cold build and a share of the edits (COST_EDITS) dealt in turn
cost-matrix-build-laid|2|make cost, COST_PART=matrix-build-laid: the same, the std answers laid
keepers-b|3|every keeper of KEEPERS_B no other slice runs, a row each, dealt in turn, the browser's libraries beside it
keepers-tw|4|tool-witnesses, a share of its witnesses each (TOOL_WITNESS_SHARD), every witness its seconds
keepers-alone|2|KEEPERS_ALONE, held to a clock and alone on its runner: runtime-tests, and runtime-mutations' part (MUTATION_SHARD)
EOF
}

# whether build/avra was built from this tree's compiler source: the stamp's hash of that source, the
# commit it stood at aside — a commit that moves no compiler source moves no compiler
compiler_stands() {
    [ -x build/avra ] && [ "$(cut -d' ' -f1 build/.avra-built-from 2>/dev/null)" = "$(sh tools/work built-from . | cut -d' ' -f1)" ]
}

# what a built tree holds that a fresh one needs to stand as built: the compiler, its hot leaves, its
# stamp, and every object, archive, library, content stamp and dependency list build/ keeps at its top
packed() {
    for f in build/avra build/avra_hot.bc build/avra_hot.inc build/.avra-built-from; do [ ! -f "$f" ] || echo "$f"; done
    # the tree's instruments, built once by this compiler: every keeper and the verdict's ledger read them
    find build/wisp -maxdepth 2 -type f -name wisp 2>/dev/null | sort
    find build -maxdepth 1 -type f \( -name '*.o' -o -name '*.a' -o -name '*.so' -o -name '*.sha' -o -name '*.d' \) | sort
}

# a tree seeded from the pack `$1`, or left as it was: a pack is proved whole first — gzip's own check,
# a listing to its end, the compiler and its stamp in it — and refused when its stamp is not this
# tree's compiler source; then laid down in a staging directory and moved into build/ only once every
# file is out, so a truncated pack never seeds half a tree. Every file moved is touched to one instant,
# so make finds no object older than its own stamp — the content stamps decide what moved.
unpacked() {
    [ -f "${1:-}" ] || { echo "gate: unpack names a pack — sh tools/gate.sh unpack <file>" >&2; exit 2; }
    pack=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
    refused() { echo "gate: $(basename "$pack") $1 — not seeded" >&2; exit 1; }
    gzip -t "$pack" 2>/dev/null || refused "is not whole (gzip -t)"
    list=$(tar -tzf "$pack" 2>/dev/null) || refused "does not list to its end"
    for f in build/avra build/.avra-built-from; do printf '%s\n' "$list" | grep -qx "$f" || refused "holds no $f"; done
    packed_hash=$(tar -xzOf "$pack" build/.avra-built-from | cut -d' ' -f1)
    tree_hash=$(sh tools/work built-from . | cut -d' ' -f1)
    [ "$packed_hash" = "$tree_hash" ] || refused "was built from compiler source $packed_hash, this tree's is $tree_hash"
    stage=build/gate/unpacking
    mkdir -p build/gate
    [ ! -e "$stage" ] || find "$stage" -delete
    mkdir -p "$stage"
    if ! tar -xzf "$pack" -C "$stage"; then find "$stage" -delete; refused "did not extract"; fi
    touch build/gate/.unpacked
    printf '%s\n' "$list" | while IFS= read -r f; do
        [ -f "$stage/$f" ] || continue
        touch -r build/gate/.unpacked "$stage/$f"
        mkdir -p "$(dirname "$f")"
        mv -f "$stage/$f" "$f"
    done
    find "$stage" -delete
    compiler_stands || { echo "gate: build/avra does not stand as HEAD's compiler after the unpack" >&2; exit 1; }
    echo "gate: seeded from $(basename "$pack") — build/avra stands as HEAD's compiler"
    exit 0
}

# THE RUNNER JOBS: the slices dealt into jobs by their measured seconds (tools/gate/slice.seconds; a slice
# it does not name weighs 300), heaviest first, each into the first job it fits under the budget
# (GATE_JOB_SECS, 420 s) — a slice past the budget is a job alone, and so is a cost slice, which holds
# the one measuring directory and the census compiler. One a line: the job, then its slices;
# a job of one slice is named by it, a job of several `jobs-<n>`. Each slice of a job still runs alone,
# in a tree of its own (gate.yml lays the unpacked tree down afresh before each).
jobs() {
    budget=${GATE_JOB_SECS:-420}
    slices | awk '{ print $1 }' | awk -v budget="$budget" '
        NR == FNR { if ($0 !~ /^#/ && NF == 2) secs[$1] = $2; next }
        { n++; name[n] = $1; w[n] = ($1 in secs) ? secs[$1] : 300 }
        END {
            # heaviest first; ties by name, so a tree deals one way
            for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++)
                if (w[j] > w[i] || (w[j] == w[i] && name[j] < name[i])) { t = w[i]; w[i] = w[j]; w[j] = t; t = name[i]; name[i] = name[j]; name[j] = t }
            bins = 0
            for (i = 1; i <= n; i++) {
                placed = 0
                alone = (w[i] >= budget || name[i] ~ /^cost-/ || name[i] ~ /^keepers-(alone|clock|heavy)/)
                if (!alone) for (b = 1; b <= bins; b++) if (open[b] && load[b] + w[i] <= budget) { load[b] += w[i]; held[b] = held[b] " " name[i]; count[b]++; placed = 1; break }
                if (!placed) { bins++; load[bins] = w[i]; held[bins] = name[i]; count[bins] = 1; open[bins] = !alone }
            }
            k = 0
            for (b = 1; b <= bins; b++) if (count[b] == 1) print held[b], held[b]; else print "jobs-" (++k), held[b]
        }' "$root/tools/gate/slice.seconds" -
}

# A SUITE LOG'S CASES, each once: those it failed by name, and those that ended its process
failed_names() { grep '^    ✗' "$1" | sed 's/ @ .*//; s/^    ✗ //' | sort -u; }
trapped_names() { grep '^avra: while running ' "$1" | sed 's/ @ .*//; s/^avra: while running //' | sort -u; }

# the names the pin file `$1` lists, sorted, each once; none where there is no such file. A `.names` line is
# `<case>\t<file> <owner> <ticket>`, the case before the tab
listed() { if [ -f "$1" ]; then grep -v '^#' "$1" | cut -f1 | grep . | sort -u; fi; }

# pins_said <package> <failed> <trapped> [<scope>…]: every pin of tools/gate/<package>.names that does not
# hold, a line each — one with no owner and ticket, one whose file is gone, and, where the row ran
# `<scope>` whole and ended no case, one whose file the scope holds and whose case did not fail: a pin
# only shrinks, so a case that passes is a line to strike
pins_said() {
    pins_pkg=$1 pins_failed=$2 pins_trapped=$3
    shift 3
    pins_file="tools/gate/$pins_pkg.names"
    [ -f "$pins_file" ] || return 0
    awk -F'\t' -v pkg="$pins_pkg" -v pin="$pins_file" -v failed_at="$pins_failed" -v ended="$([ -s "$pins_trapped" ] && echo 1 || echo 0)" -v scope="$(printf '%s ' "$@" | sed 's|/ | |g')" '
        BEGIN { while ((getline c < failed_at) > 0) failed[c] = 1; close(failed_at) }
        /^#/ || NF == 0 { next }
        {
            n = split($2, w, " ")
            if (n < 3) { print "a pin with no owner and ticket — " pin ": " $1; next }
            f = "packages/" pkg "/src/" w[1]
            if ((getline line < f) < 0) { print "a pin whose file is gone — strike its line in " pin ": " $1 " (" w[1] ")"; next }
            close(f)
            if (ended || ($1 in failed)) next
            k = split(scope, s, " ")
            for (i = 1; i <= k; i++) if (f == s[i] || index(f, s[i] "/") == 1) { print "passes, and " pin " still pins it (" w[2] " " w[3] ") — strike its line: " $1; next }
        }' "$pins_file"
}

# held <package> <log> <status>: whether a suite run of `package` that exited `status` holds as a gate's
# row holds it — every failed case one tools/gate/<package>.names pins, every ended one its .traps lists,
# and a run that failed or ended none exited clean. Each case that does not hold is said.
held() {
    scratch_dir d
    for k in names traps; do
        listed "tools/gate/$1.$k" >"$d/$k"
    done
    failed_names "$2" >"$d/failed"
    trapped_names "$2" >"$d/trapped"
    comm -23 "$d/failed" "$d/names" | sed 's/^/unpinned failure: /' >"$d/said"
    comm -23 "$d/trapped" "$d/traps" | sed 's/^/unlisted trap: /' >>"$d/said"
    pins_said "$1" "$d/failed" "$d/trapped" >>"$d/said"
    cat "$d/said"
    st=0
    if [ -s "$d/said" ]; then st=1; elif [ "$3" != 0 ] && [ ! -s "$d/failed" ] && [ ! -s "$d/trapped" ]; then st=1; fi
    find "$d" -delete
    return "$st"
}

# THE SUITES A SLICE NAMES: every other package's suite is the pkgs family's
named_suites() { printf '%s\n' std-avrac cli std-program std-relation std-ui_gallery $DOORS_A $DOORS_B; }

# THE PKGS FAMILY'S SUITES, as package paths into `$2`: of `wisp suites`, those the diff from `$1` reaches
# (every one where `$1` is empty), less the ones a slice names; 1 where the suites could not be listed
pkgs_suites() {
    ./wisp suites | sort -u >"$2.all" || return 1
    [ -s "$2.all" ] || return 1
    if [ -n "$1" ]; then
        sh tools/affected_packages.sh "$1" HEAD . 2>"$2.affected.log" | sed 's|^|packages/|' | sort -u >"$2.reached"
    else
        cp "$2.all" "$2.reached"
    fi
    named_suites | sed 's|^|packages/|' | sort -u >"$2.named"
    comm -12 "$2.all" "$2.reached" | comm -23 - "$2.named" >"$2"
}

[ $# -ge 1 ] || { echo "gate: name a slice, or \`list\`" >&2; exit 2; }
slice=$1
shift
if [ "$slice" = list ]; then slices; exit 0; fi
if [ "$slice" = jobs ]; then jobs; exit 0; fi
if [ "$slice" = held ]; then held "$@"; exit $?; fi
if [ "$slice" = pkgs-suites ]; then
    scratch_dir out
    pkgs_suites "${1:-}" "$out/pkgs" && cat "$out/pkgs"
    st=$?
    find "$out" -delete
    exit "$st"
fi
if [ "$slice" = seconds ]; then
    [ $# -ge 1 ] || { echo "gate: seconds names the gate logs it reads" >&2; exit 2; }
    kept="$root/tools/gate/path.seconds"
    { grep '^#' "$kept"; { grep -v '^#' "$kept"; cat "$@" | sed -n 's/.*gate: fact path \([^ ]*\) \([0-9][0-9]*\)$/\1 \2/p'; } |
        awk '{ w[$1] = $2 } END { for (p in w) print p, w[p] }' | LC_ALL=C sort; } > "$kept.new"
    mv "$kept.new" "$kept"
    echo "gate: $(grep -vc '^#' "$kept") path(s) in tools/gate/path.seconds"
    exit 0
fi
if [ "$slice" = unpack ]; then unpacked "$@"; fi
[ "$slice" = seed ] && slice=pack
[ "$slice" = pack ] || [ "$slice" = census ] || slices | awk '{ print $1 }' | grep -qx "$slice" || { echo "gate: no slice \`$slice\` — \`sh tools/gate.sh list\` names them" >&2; exit 2; }

sha8=$(git rev-parse --short=8 HEAD)
# THE WALL BUDGET: the slice runs again inside it, under tools/bounded.sh; past it, the slice is named.
# Every process the slice starts carries its budget's token in its environment, so a row's own bound
# (another `timeout`, another process group) is stopped with it, not left running past the verdict.
# A whole- or layered-mode edit part makes three cli builds, two of them cold, one alone in a process:
# 640-780 s on the fastest runner, past 900 s on a slower one with nothing failing, so its budget is
# its own.
case $slice in edit-f-* | edit-g-* | keepers-heavy-1) slice_budget=1500 ;; *) slice_budget=900 ;; esac
SLICE_SECS=${GATE_SLICE_SECS:-$slice_budget}
if [ -z "${GATE_IN_BUDGET:-}" ] && [ "$slice" != pack ]; then
    started=$(date +%s)
    token="$slice-$$"
    GATE_IN_BUDGET=$token sh "$root/tools/bounded.sh" "$SLICE_SECS" sh "$root/tools/gate.sh" "$slice" "$@"
    st=$?
    case $st in
        124 | 137)
            for p in /proc/[0-9]*; do
                tr '\0' '\n' < "$p/environ" 2> /dev/null | grep -qx "GATE_IN_BUDGET=$token" && kill -9 "${p#/proc/}" 2> /dev/null
            done
            mkdir -p "$root/build/gate/$slice"
            echo "row $slice OVER ${SLICE_SECS}s" >> "$root/build/gate/$slice/rows"
            echo "gate: $slice ran past its ${SLICE_SECS} s wall budget — stopped"
            # what it finished, and the row it was in when stopped: the row an OVER is planned by
            sed 's/^/gate: /' "$root/build/gate/$slice/rows"
            [ ! -s "$root/build/gate/$slice/.running" ] || echo "gate: row $(cat "$root/build/gate/$slice/.running") was running"
            echo "GATE $slice $sha8 OVER rows=$(grep -c '^row ' "$root/build/gate/$slice/rows") failed=1 $(( $(date +%s) - started ))s"
            exit 1
            ;;
    esac
    exit "$st"
fi
out="$root/build/gate/$slice"
mkdir -p "$out"
find "$out" -mindepth 1 -delete
# A SLICE WRITES NO CORE: the rows crash children on purpose (a fault, an overflow, a trap), and a
# process of this runtime reserves its address space up front (~128 GB), which a core then holds
# whole; a runner's host reads each through its core handler for minutes, a verdict the wait status
# already says
ulimit -c 0
export AVRA_CACHE_DIR="$out/machine"
# a slice copies, counts and empties stores between builds, so each build saves its own before it
# answers; the build slice's timing rows alone leave the save to an heir, as a user's build does
export AVRA_STORE_KEPT_HERE=1
mkdir -p "$AVRA_CACHE_DIR"
# THE SEED'S GENERATION 1 READS THE BUILDER'S OWN STORES where the landing kept them (gate.yml lays them at
# build/gate/builder-store): the cli's in place, the machine's into this run's
if [ "$slice" = pack ] && [ -d build/gate/builder-store ]; then
    laid=$(find build/gate/builder-store -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
    for d in build/gate/builder-store/packages/cli/.avra-cache; do [ ! -d "$d" ] || { mkdir -p packages/cli/.avra-cache && cp -R "$d/." packages/cli/.avra-cache/; }; done
    for d in build/gate/builder-store/build/gate/*/machine; do [ ! -d "$d" ] || cp -R "$d/." "$AVRA_CACHE_DIR/"; done
    echo "fact builder-store laid ($laid part(s))" >>"$out/rows"
fi
began=$(date +%s)
rows=0
failed=0
failures=""

# one row: `$1` its name, the rest its command, bounded; its words at $out/<name>.log
row() {
    name=$1; shift
    rows=$((rows + 1))
    t0=$(date +%s)
    echo "$name" >"$out/.running"
    if sh tools/bounded.sh "$ROW_SECS" "$@" >"$out/$name.log" 2>&1; then
        echo "row $name pass $(( $(date +%s) - t0 ))s" >>"$out/rows"
        return 0
    fi
    failed=$((failed + 1))
    failures="$failures $name"
    echo "row $name FAIL $(( $(date +%s) - t0 ))s" >>"$out/rows"
    return 1
}

# a row that judges what an earlier row left: `$1` its name, `$2` the verdict (0 holds)
judged() {
    rows=$((rows + 1))
    # a suite's seconds, where `tested` timed it; the row's alone, never the next judged row's
    secs=${took:+ $took}
    took=
    if [ "$2" = 0 ]; then echo "row $1 pass$secs" >>"$out/rows"; return 0; fi
    failed=$((failed + 1))
    failures="$failures $1"
    echo "row $1 FAIL$secs" >>"$out/rows"
    return 1
}

# a row that compares against the old path: run only while the old path stands

# every store under the packages named emptied — a nested package's and a program test's too — so the
# rows after read them cold
cold() { for p in "$@"; do find "packages/$p" -name .avra-cache -prune -exec find {} -delete \; ; done; return 0; }

# build/avra as HEAD's compiler: kept when it was built from this tree's compiler source, else made in
# ONE generation — from the committed seed's link where no compiler stands, else from the one that does
# — with the package libraries beside it, built without building the compiler again. A gate's
# two-generation fixed point is the build slice's.
compiler() {
    if compiler_stands; then return 0; fi
    if [ ! -x build/avra ]; then row compiler-recover make recover || return 1; fi
    rungs_read
    if [ -n "$rungs" ]; then
        # A RUNG IS A TREE THE STANDING COMPILER CANNOT READ: each is built by the product of the one
        # before (`make compiler`, `./wisp ladder`), as a pull request's check builds it, and HEAD's
        # generation 1 by the last
        echo "fact rungs $(echo $rungs | wc -w) over $(printf '%.8s' "$rung_base"): $rungs" >>"$out/rows"
        row compiler-ladder env AVRA_STD_ANSWERS=0 make -s compiler RUNGS="$rungs" LADDER_BASE="$rung_base" LADDER_BOUND=1800 GENS=1 || return 1
    else
        row compiler-gen1 env AVRA_STD_ANSWERS=0 make avra || return 1
    fi
    row compiler-libs make -o avra libs
}

# THE RUNGS THIS BRANCH CARRIES over the program it lands on (tools/rungs.sh), oldest first, into
# `rungs`, and that program's commit into `rung_base`; none where the program cannot be told. A gate's
# checkout is shallow, and a rung is found in the history between them.
rungs_read() {
    rungs=""
    [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" != true ] || git fetch -q --unshallow origin 2>/dev/null || :
    git fetch -q origin program:refs/remotes/origin/program 2>/dev/null || :
    rung_base=$(git merge-base origin/program HEAD 2>/dev/null) || return 0
    rungs=$(sh tools/rungs.sh "$rung_base" HEAD | tr '\n' ' ')
}

# what the cold build of packages/cli took, in seconds, and the warm one after it
cli_built() {
    cold cli
    find "$AVRA_CACHE_DIR" -mindepth 1 -delete
    c0=$(date +%s)
    row cli-build-cold env -u AVRA_STORE_KEPT_HERE build/avra build packages/cli || return 1
    c1=$(date +%s)
    row cli-build-warm env -u AVRA_STORE_KEPT_HERE build/avra build packages/cli || return 1
    echo "cli build: cold $((c1 - c0))s, warm $(( $(date +%s) - c1 ))s" >>"$out/seconds"
    # the warm build's heir waited out, before a row after empties the store it saves
    build/avra build packages/cli >/dev/null 2>&1 || :
}

slice_build() {
    row try make try
    # THE FIXED POINT IS ONE GENERATION'S PRODUCT BUILT AGAIN BY ITSELF: the pack's compiler is this
    # tree's generation 2 and `make try` builds generation 3 with it, as `make avra` does. Where they
    # are one binary the fixed point stands and no generation is built again; where they differ, the
    # tree builds generations 3 and 4 as `make avra` makes them, and they must be one.
    if cmp -s build/avra build/avra-try; then
        echo "fact gen3-is-gen2 yes" >>"$out/rows"
        judged fixed-point 0
        builder_stores
    else
        echo "fact gen3-is-gen2 no $(differs_at build/avra build/avra-try)" >>"$out/rows"
        row avra-a env AVRA_STD_ANSWERS=0 make avra && cp build/avra "$out/avra-a"
        builder_stores
        cold cli
        row avra-b env AVRA_STD_ANSWERS=0 make avra && { cmp -s build/avra "$out/avra-a"; judged fixed-point $?; }
    fi
    cli_built
}

# THE NEXT GATE'S GENERATION 1 STARTS WARM: this gate's compiler of generation 2 is what landing makes
# the next gate's builder, and the cli's stores it has just filled building the cli are the ones that
# builder reads first (a store answers only the compiler whose print it holds); the landing keeps them
# beside the builder as builder-store.tar.gz
builder_stores() {
    { find packages/cli -name .avra-cache -type d -prune; echo "${AVRA_CACHE_DIR#"$root"/}"; } > "$out/stores"
    row builder-store tar -czf build/gate/builder-store.tar.gz -T "$out/stores" &&
        echo "fact builder-store $(du -k build/gate/builder-store.tar.gz | cut -f1) KB" >>"$out/rows"
}

# the std-avrac suite over `$@`, its paths under the package: one row for every path of std-avrac's
# own, and a row each for a path that is a package of its own nested in it, which `test` proves apart
avrac() {
    cold std-avrac
    own=""
    for p in "$@"; do
        if [ -f "$p/avra.toml" ]; then tested "std-avrac-$(basename "$p")" "$p"; else own="$own $p"; fi
    done
    [ -z "$own" ] || tested std-avrac $own
}
# half of std-avrac's src/compiler/tests, the `$1`-th (from 0), dealt in turn
compiler_tests_half() { find packages/std-avrac/src/compiler/tests -mindepth 1 -maxdepth 1 ! -name '.*' | sort | dealt "$1" 2; }
slice_avrac_a() {
    avrac $(
        {
            compiler_tests_half 0
            find packages/std-avrac/src/compiler -mindepth 1 -maxdepth 1 ! -name tests ! -name soundness ! -name '.*'
        } | sort
    )
}
slice_avrac_g() { avrac $({ compiler_tests_half 1; echo packages/std-avrac/src/compiler/soundness; } | sort); }
slice_avrac_d() { avrac $(find packages/std-avrac/src/features -mindepth 1 -maxdepth 1 -type d -name '[n-r]*' | sort); }
slice_avrac_f() {
    avrac $(
        {
            find packages/std-avrac/src/features -mindepth 1 -maxdepth 1 -name '*.av'
            find packages/std-avrac/src -mindepth 1 -maxdepth 1 ! -name compiler ! -name features ! -name '.*'
        } | sort
    )
}

# the words on its lines that `dealt k n` keeps: every n-th, starting at the k-th (from 0), so a
# list's parts share its weight in turn
dealt() { awk -v k="$1" -v n="$2" '(NR - 1) % n == k'; }

# the `$1`-th (from 0) of `$2` shares of the paths on stdin, dealt by their measured seconds
# (tools/gate/path.seconds; a path it does not name weighs the median of those it does, or 60): heaviest
# first, each into the lightest share so far, ties by path, so a tree deals one way
dealt_by_seconds() {
    awk -v k="$1" -v n="$2" '
        NR == FNR { if ($0 !~ /^#/ && NF == 2) { secs[$1] = $2; known[++m] = $2 } next }
        NF { p[++c] = $1 }
        END {
            for (i = 1; i <= m; i++) for (j = i + 1; j <= m; j++) if (known[j] < known[i]) { t = known[i]; known[i] = known[j]; known[j] = t }
            dflt = m ? known[int((m + 1) / 2)] : 60
            for (i = 1; i <= c; i++) w[i] = (p[i] in secs) ? secs[p[i]] : dflt
            for (i = 1; i <= c; i++) for (j = i + 1; j <= c; j++)
                if (w[j] > w[i] || (w[j] == w[i] && p[j] < p[i])) { t = w[i]; w[i] = w[j]; w[j] = t; t = p[i]; p[i] = p[j]; p[j] = t }
            for (b = 0; b < n; b++) load[b] = 0
            for (i = 1; i <= c; i++) {
                best = 0
                for (b = 1; b < n; b++) if (load[b] < load[best]) best = b
                load[best] += w[i]
                if (best == k) print p[i]
            }
        }' "$root/tools/gate/path.seconds" -
}

# `test` over `$2…` as the row `$1`, judged by the NAMES that fail: each must be one
# tools/gate/<package>.names pins (a case a sandbox's environment fails — root writes any directory, no
# terminal, no network), never a count. With no pin file, every failure fails the row.
# A CASE THAT ENDS THE SUITE'S PROCESS (`avra: while running <case>`) fails no case by name and leaves
# every case after it unrun, so it is never passed over: each must be one tools/gate/<package>.traps
# lists, by the first line the runner says it under.
tested() {
    name=$1; shift
    pkg=$(echo "$1" | cut -d/ -f2)
    t0=$(date +%s)
    echo "$name" >"$out/.running"
    # every suite of the scope runs on past a red one, so each pin is judged by a run of its file
    sh tools/bounded.sh "$ROW_SECS" env AVRA_SUITE_ALL=1 build/avra test "$@" >"$out/$name.log" 2>&1
    ran=$?
    took="$(( $(date +%s) - t0 ))s"
    failed_names "$out/$name.log" >"$out/$name.failed"
    listed "tools/gate/$pkg.names" >"$out/$name.known"
    comm -23 "$out/$name.failed" "$out/$name.known" >"$out/$name.unpinned"
    trapped_names "$out/$name.log" >"$out/$name.trapped"
    listed "tools/gate/$pkg.traps" >"$out/$name.traps"
    comm -23 "$out/$name.trapped" "$out/$name.traps" >"$out/$name.untrapped"
    # EVERY PRINTING PROGRAM THE ROW DOES NOT PROVE, said by its path under src/ — unmade, trapped in the
    # making, or apart from its text: the suite exits 1 for each, and once a case fails by a pinned name
    # that exit is passed over, so the row says them here
    sed -n "s|^packages/$pkg/src/\([^ :]*\): .*|\1|p" "$out/$name.log" | sort -u >"$out/$name.programs"
    sed -n "s|^packages/$pkg/src/\([^ :]*\): .* == expected\$|\1|p" "$out/$name.log" | sort -u >"$out/$name.proved"
    comm -23 "$out/$name.programs" "$out/$name.proved" >"$out/$name.unproved"
    sed "s|^|fact unproved $pkg |" "$out/$name.unproved" >>"$out/rows"
    # THE PIN FILE HOLDS THEM: tools/gate/<package>.unproved names each program the package's suites may
    # leave unproved, `<path> <owner> <why>` a line. One the row leaves unproved that the file does not
    # name fails, and one it names that the row proves fails too, until its line is struck; a package with
    # no pin file has its programs said and none judged, as a ledger key with no rows is told
    pin="tools/gate/$pkg.unproved"
    if [ -f "$pin" ]; then
        awk '!/^#/ && NF { print $1 }' "$pin" | sort -u >"$out/$name.pinned"
        comm -23 "$out/$name.unproved" "$out/$name.pinned" | sed 's/^/unpinned unproved program: /' >"$out/$name.unproved-words"
        comm -12 "$out/$name.proved" "$out/$name.pinned" | sed "s|^|proved, and $pin still pins it — strike its line: |" >>"$out/$name.unproved-words"
        # the suite's seconds are the row's below, never this judgement's
        kept_took=$took
        took=
        judged "$name-unproved" "$(wc -l <"$out/$name.unproved-words" | tr -d ' ')"
        took=$kept_took
        sed 's/^/fact /' "$out/$name.unproved-words" >>"$out/rows"
    fi
    pins_said "$pkg" "$out/$name.failed" "$out/$name.trapped" "$@" >"$out/$name.pins"
    if [ -s "$out/$name.pins" ]; then
        kept_took=$took
        took=
        judged "$name-pins" "$(wc -l <"$out/$name.pins" | tr -d ' ')"
        took=$kept_took
        sed 's/^/fact /' "$out/$name.pins" >>"$out/rows"
    fi
    if [ -s "$out/$name.untrapped" ]; then judged "$name" "$(wc -l <"$out/$name.untrapped" | tr -d ' ')"; return; fi
    # a scope that holds no proof, where the caller counts that as none here: refused by that voice alone
    if [ "$ran" != 0 ] && [ -n "${EMPTY_SCOPE_PASSES:-}" ] && [ ! -s "$out/$name.failed" ] && [ ! -s "$out/$name.trapped" ] &&
        grep -q 'names no test' "$out/$name.log" && ! grep -qE '^    (✓|✗)' "$out/$name.log"; then
        : >"$out/$name.empty"
        judged "$name" 0
        return
    fi
    # a run that fails no case and ends none must have exited clean; one that fails only pinned cases
    # or ends at a listed one stopped on them
    if [ ! -s "$out/$name.failed" ] && [ ! -s "$out/$name.trapped" ]; then
        # a suite whose only reds are programs its pin file names exits 1 for them, and holds
        if [ "$ran" != 0 ] && [ -s "$out/$name.unproved" ] && [ -f "tools/gate/$pkg.unproved" ] && [ ! -s "$out/$name.unproved-words" ]; then
            judged "$name" 0
            return
        fi
        judged "$name" "$ran"
        return
    fi
    judged "$name" "$(wc -l <"$out/$name.unpinned" | tr -d ' ')"
}


# one row of a suite share: `tested`, an empty scope counted as no proof here rather than a failure, and
# the row's seconds said beside its path (`fact path <path> <n>`), which tools/gate/path.seconds keeps
share_row() {
    rows_held=$((rows_held + 1))
    t0=$(date +%s)
    EMPTY_SCOPE_PASSES=1
    tested "$@"
    EMPTY_SCOPE_PASSES=
    [ ! -f "$out/$1.empty" ] || rows_empty=$((rows_empty + 1))
    [ "$#" != 2 ] || echo "fact path $2 $(( $(date +%s) - t0 ))" >>"$out/rows"
}

# THE CLI'S SUITE: the one suite that runs the compiler as a child; every other test row holds what it
# runs in-process.
slice_cli() {
    cold cli
    find "$out/children" -delete 2>/dev/null || :
    rows_held=0
    rows_empty=0
    # a row each of the share's tests, its children kept apart (children/<row>/), each row its seconds
    for p in "${@:-packages/cli}"; do
        name="cli@$(echo "${p#packages/cli/src/}" | tr '/' '+')"
        children_kept "$name" share_row "$name" "$p"
        children_of_failed "$name"
    done
    [ "$rows_held" -gt "$rows_empty" ] || judged cli-held-no-proof 1
    ci_captured
    export AVRA_PROGRAM_NET=0
}

# WHAT A RED CLI SLICE STOOD ON, kept under $out/capture for its artifact: for each failed case whose
# child checked an embedding package (embed_law_test), that package's own store and the machine's
# (`$AVRA_CACHE_DIR`) as they were, this machine's cores, its AVRA_ environment and the compiler's
# print; then that one check run again under the suite's own environment with the query and trap
# traces on, its stderr held to 20 MB. A green slice keeps nothing.
ci_captured() {
    grep -q '^row cli-suite FAIL' "$out/rows" 2>/dev/null || return 0
    cap="$out/capture"
    mkdir -p "$cap"
    { echo "nproc: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null)"; "$root/build/avra" --version 2>&1 | head -3; env | grep '^AVRA' | sort; } > "$cap/facts.txt"
    n=0
    for d in "$out"/children/*/; do
        grep -q 'embed_law_test' "$d/case" 2>/dev/null || continue
        for a in "$d"*.args; do
            [ "$(head -1 "$a")" = check ] || continue
            pkg=$(sed -n 2p "$a")
            [ -d "$pkg" ] || continue
            n=$((n + 1))
            mkdir -p "$cap/$n"
            cp "$d/case" "$a" "$cap/$n/"
            [ -d "$pkg/.avra-cache" ] && cp -R "$pkg/.avra-cache" "$cap/$n/pkg-avra-cache"
            [ -n "${AVRA_CACHE_DIR:-}" ] && [ -d "$AVRA_CACHE_DIR" ] && cp -R "$AVRA_CACHE_DIR" "$cap/$n/machine-cache"
            AVRA_QTRACE=1 AVRA_TRAP_TRACE=1 "$root/build/avra" check "$pkg" > "$cap/$n/rerun.out" 2> "$cap/$n/rerun.err.full"
            echo "exit $?" >> "$cap/$n/rerun.out"
            head -c 20971520 "$cap/$n/rerun.err.full" > "$cap/$n/rerun.err"
            find "$cap/$n/rerun.err.full" -delete
            break
        done
    done
    echo "captured: $n embed check(s)" >> "$cap/facts.txt"
}

# A SUITE WHOSE CASES RUN THE COMPILER AS A CHILD KEEPS WHAT EACH CHILD DID: the row `$1` run as `$2…`, every child
# `<tree>/avra` filed under $out/children/<row>/<case> by tools/gate/child_kept.sh — its arguments, its
# streams and its exit — so a red row has the words its children said.
children_kept() {
    kept="$out/children/$1"
    shift
    export AVRA_BIN="$root/tools/gate/child_kept.sh" AVRA_CHILD_BIN="$root/build/avra" AVRA_CHILDREN="$kept"
    "$@"
    unset AVRA_BIN AVRA_CHILD_BIN AVRA_CHILDREN
}

# the children of the cases row `$1` failed, kept; every other case's dropped
children_of_failed() {
    for d in "$out/children/$1"/*/; do
        [ -f "$d/case" ] || continue
        grep -qxF "$(sed 's/ @ .*//' "$d/case")" "$out/$1.failed" || find "$d" -delete
    done
}

# THE ROWS' CLAIMS among them, generated from rt_sigs(): the C header and the typed methods. A row added
# without its regeneration is refused here, never left for the next lane to find.
program_rows() {
    cat <<'EOF'
tested std-program packages/std-program
tested std-relation packages/std-relation
row rt-header make rt-header
row rt-ns make rt-ns
EOF
    # every runtime test a row of its own, so a part holds a share of them and a slow one is named
    for t in runtime/tests/*.c; do t=${t##*/}; echo "row runtime-${t%.c} make -s runtime-test-${t%.c}"; done
}

# each package the diff from the base sha `$1` touches, whose name the pattern `$3` matches (`$2` keep)
# or doesn't (`$2` drop), checked against the baseline
idioms_on() {
    [ -n "${1:-}" ] || { echo "gate: $slice needs the base sha its diff starts at" >&2; exit 2; }
    if [ "$2" = drop ]; then pick=-vxE; else pick=-xE; fi
    for p in $(git diff --name-only "$1" HEAD -- packages | cut -d/ -f2 | sort -u | grep $pick "$3"); do
        [ -d "packages/$p/src" ] || continue
        cold "$p"
        row "idioms-$p" build/avra check "packages/$p" --baseline tools/idioms.baseline
    done
}

# every `.av` the diff from the base sha `$1` changes, canonical as the tree's own compiler prints it.
# The base is the program landed last: a batch gated against its own base would hold none of what
# its lanes wrote to the printer's word
fmt_on() {
    [ -n "${1:-}" ] || { echo "gate: $slice needs the base sha its diff starts at — the program landed last" >&2; exit 2; }
    row fmt-changed env AVRA=build/avra sh tools/fmt_changed.sh "$1" HEAD
}

# THE STORE FUZZED BY A MODEL, on a bounded budget: a failing seed is shrunk and said as a line that
# replays it. Each store bug it exists for is found by it with its fix taken back
# (`make store-fuzz-regressions`, a compiler built a bug, too long for a slice).
slice_store_fuzz() {
    row store-fuzz-model python3 tools/store_fuzz.py --self-test
    row store-fuzz python3 tools/store_fuzz.py --compiler build/avra --seeds 1-8 --steps 12
}

slice_sound() {
    row sound-check-run env AVRA_SOUND_CHECK=1 build/avra check packages/cli
    cold cli
    row llvm-verified-build env AVRA_VERIFY_LLVM=1 build/avra build packages/cli
    judged sound-check-defects "$(grep -c 'language.defect' "$out/sound-check-run.log")"
}

# a cost part `$1` (with its edits' share `$2`), counted by the census compiler this slice builds from
# the seed's compiler of generation 2 (tools/cost.sh refuses one less), or the one it already holds
slice_cost() {
    census_stands || census_made || return 1
    row "cost-$1" env COST_PART="$1" COST_EDITS="${2:-}" COST_COMPILER=build/avra.census make -s -o avra cost
    st=$?
    # each workload's seconds and the std answers', as cost.sh says them: what a cost split is dealt by
    grep -E '^cost: [^ ]+ [0-9]+ s$|^cost: the snapshot.s std answers [0-9]+ s$' "$out/cost-$1.log" | sed 's/^cost: /fact cost /' >>"$out/rows"
    return $st
}

# build/avra of generation 2, this tree's compiler built by this tree's compiler — as it stands where it
# is already: a seed unpacked from the release of a tree of the same compiler source takes it as it is
gen2_made() {
    read -r _h _a gen _ < build/.avra-built-from 2> /dev/null || gen=1
    [ "${gen:-1}" -ge 2 ] || row compiler-gen2 env AVRA_PROGRAM_NET=0 AVRA_STD_ANSWERS=0 make avra
}
# the census compiler, built by this tree's compiler of generation 2
census_made() {
    gen2_made || return 1
    census_stands || row census-compiler env CENSUS_BUILDER=build/avra sh tools/census_compiler.sh build/avra.census
}

# whether build/avra.census is this tree's: built by a compiler of this compiler source, of generation
# 2, by this tools/census_compiler.sh
census_stands() {
    [ -x build/avra.census ] || return 1
    read -r c_hash _c_at c_gen c_script < build/.avra.census-built-from 2> /dev/null || return 1
    [ "$c_hash" = "$(sh tools/work built-from . | cut -d' ' -f1)" ] && [ "${c_gen:-1}" -ge 2 ] &&
        [ "$c_script" = "$(sha256sum tools/census_compiler.sh | cut -d' ' -f1)" ]
}

doors() { for p in "$@"; do cold "$p"; tested "test-$p" "packages/$p"; done; }
slice_doors_a() { doors $DOORS_A; }

# part `$1` of `$2` of the pkgs family over the diff from `$3`: each suite dealt here, a row each; an owed
# one (tools/gate/suites.owed) runs as any, its red the line's debt, its green a line to strike
pkgs_part() {
    judged suites-owed-lines "$(awk '!/^#/ && NF > 0 && NF < 3' "$root/tools/gate/suites.owed" | wc -l | tr -d ' ')"
    pkgs_suites "$3" "$out/pkgs" || { judged pkgs-suites-listed 1; return; }
    suites=$(dealt_by_seconds "$(($1 - 1))" "$2" <"$out/pkgs")
    if [ -z "$suites" ]; then
        echo "fact pkgs-$1: no suite the diff reaches is dealt to this part" >>"$out/rows"
        return 0
    fi
    for path in $suites; do
        p=${path#packages/}
        cold "$p"
        owner=$(awk -v p="$p" '$1 == p { print $2; exit }' "$root/tools/gate/suites.owed")
        if [ -z "$owner" ]; then
            tested "test-$p" "$path"
            continue
        fi
        rows=$((rows + 1))
        t0=$(date +%s)
        if sh tools/bounded.sh "$ROW_SECS" build/avra test "$path" >"$out/test-$p.log" 2>&1; then
            failed=$((failed + 1))
            failures="$failures test-$p"
            echo "row test-$p FAIL $(( $(date +%s) - t0 ))s (passes, and tools/gate/suites.owed still owes it — strike its line)" >>"$out/rows"
        else
            echo "row test-$p OWED $(( $(date +%s) - t0 ))s ($owner: $(awk -v p="$p" '$1 == p { $1 = ""; $2 = ""; sub(/^  /, ""); print; exit }' "$root/tools/gate/suites.owed"))" >>"$out/rows"
        fi
    done
}
slice_doors_b() {
    doors $DOORS_B
    row ui-host-test make -s -o avra ui-host-test
    row ui-host make -s -o avra ui-host
}

# THE UI BOARD WHERE A BROWSER RUNS: its wasm claims over the real page glue, then its claims in
# headless Firefox, which no machine but a runner holds for every lane. First, what the run stood on,
# in its own row's log: node, the browser, the wasm linker and the libc it links (a libc without
# setjmp cannot link the board). A board that SKIPPED ran no claim, and is no pass.
slice_ui_browser() {
    row ui-machine sh -c 'node --version && firefox --version && wasm-ld-22 --version 2>/dev/null | head -1; for d in /usr/lib/wasm32-wasi /usr/lib/wasm32-wasip1 "${WASI_SYSROOT:-/nonexistent}/lib/wasm32-wasip1"; do [ ! -d "$d" ] || echo "libc $d: setjmp $(ls "$d"/libsetjmp.a 2>/dev/null || echo absent)"; done'
    row ui-board sh tools/ui_board.sh
    row ui-board-native sh tools/ui_board_native.sh
    judged ui-board-ran "$(grep -c 'SKIPPED' "$out/ui-board.log")"
    row ui-browser env CI=true sh tools/ui_board_browser.sh
    row board-dev env CI=true sh tools/witness_board_dev.sh build/avra
}

# THE STORYBOARD (docs/2026_11_24_STORYBOARD.md): every view the View derive made, each told by a
# story, and what every case says on the web, headless and in a terminal, held line by line to the
# golden its program test prints. A row of its own, so a red one names the storyboard.
slice_storyboard() {
    cold std-ui_gallery
    tested test-std-ui_gallery packages/std-ui_gallery
    row storyboard-browser env CI=true sh tools/storyboard_browser.sh
}

# each package named: tapes --findings with no refusal
findings_on() {
    for p in "$@"; do
        cold "$p"
        row "findings-$p" build/avra tapes "$root/packages/$p" --findings
        judged "refusals-$p" "$(grep -c '^error\[' "$out/findings-$p.log")"
    done
}
HEAVY_FINDINGS="std-avrac cli"
slice_findings_a() { findings_on $HEAVY_FINDINGS; }
# a third of every other package, the `$1`-th (from 0)
findings_third() {
    findings_on $(for d in packages/*/src; do basename "$(dirname "$d")"; done | grep -vxE "$(echo $HEAVY_FINDINGS | tr ' ' '|')" | dealt "$1" 3)
}


witness_b_rows() {
    cat <<'EOF'
row runs-witness sh tools/witness_program_runs.sh build/avra
row page-closure-witness sh tools/witness_page_closure.sh build/avra
row board-native-witness sh tools/witness_board_native.sh build/avra
row store-broken-edit-witness sh tools/witness_store_broken_edit.sh build/avra
row waits-witness sh tools/witness_program_waits.sh build/avra
row flow-trace make -s -o avra flow-trace
row compiler-key sh tools/witness_compiler_key.sh build/avra
row docs-cache-attack sh tools/docs_cache_attack.sh
row obj-gone-attack sh tools/obj_gone_attack.sh
row chunk-owed-attack sh tools/chunk_owed_attack.sh
row frame-place-attack sh tools/frame_place_attack.sh
row wrapper-marks-attack sh tools/wrapper_marks_attack.sh
row moved-tree-attack sh tools/moved_tree_attack.sh
row layer-sites-attack sh tools/layer_sites_attack.sh
row closure-gather-attack sh tools/closure_gather_attack.sh
row store-bound-attack sh tools/store_bound_attack.sh
row path-leak-attack sh tools/path_leak_attack.sh
row case-leftover-attack sh tools/case_leftover_attack.sh
row fixes-witness sh tools/witness_program_fixes.sh build/avra
row root-listing-attack sh tools/root_listing_attack.sh
row two-compilers-attack sh tools/two_compilers_attack.sh
row flow-trace-swap-attack sh tools/flow_trace_swap_attack.sh
row queue-witness build/avra run tools/queue-witness
row std-answers-attack sh tools/std_answers_attack.sh build/avra
row std-answers-checkout-witness sh tools/std_answers_checkout_witness.sh build/avra
row carried-store-attack env CARRIED_ATTACK_AVRA="$root/build/avra" sh tools/carried_store_attack.sh
row derive-members-witness sh tools/derive_members_witness.sh build/avra
row ledger-witness sh tools/witness_program_ledger.sh build/avra
row suites-witness sh tools/witness_program_suites.sh build/avra
row differential-witness sh tools/witness_program_differential.sh build/avra
EOF
    # the doors witness a row for each of its cases, so a part holds a share of the doors
    sh tools/witness_program_doors.sh --cases | while read -r c; do echo "row doors-witness-$c sh tools/witness_program_doors.sh build/avra $c"; done
}

# THE PART `$2` OF `$3` OF A LIST OF ROWS `$1` NAMES, each line a row as the script would write it: read
# from a file, in this shell, so every row is counted, and handed no input of the list's
rows_dealt() {
    "$1" | dealt "$(($2 - 1))" "$3" > "$out/dealt"
    while IFS= read -r line; do eval "$line" < /dev/null; done < "$out/dealt"
}

# std-avrac's feature dirs whose names match `$1`, sorted
features() { find packages/std-avrac/src/features -mindepth 1 -maxdepth 1 -type d -name "$1" | sort; }

# THE KEEPERS ON THE GATE: every keeper the registry's KEEPERS names, each a row `keeper-<name>` run as
# checks.yml runs it (`make -s -o avra <name>`), in the slice of its own list. Those another slice
# already runs, as the same target over the same tree, are its rows and are not run twice; speed-ratchet
# is the one keeper no slice runs, which keepers-clock says every gate.
KEEPERS_RUN_ELSEWHERE="speed-ratchet cost flow-trace rt-header rt-ns ui-host ui-host-test ui-board"
# the keepers the registry's set `$1` names (`./wisp keepers --sets`), those run elsewhere left out, one a line
keepers_of() {
    ./wisp keepers --sets | awk -v v="$1" '$1 == v && $2 == "=" { $1 = ""; $2 = ""; print; exit }' | tr ' ' '\n' | grep . |
        grep -vxF "$(printf '%s\n' $KEEPERS_RUN_ELSEWHERE)"
}
# what a keeper's checks.yml job sets beside it, one `NAME=value` a word: speed-ratchet's budgets are
# keyed to the one stable host name, and its warm store stands at .avra-cache (speed_measure warms it)
keeper_env() {
    case $1 in
        speed-ratchet) mkdir -p .avra-cache && echo SPEED_HOST=ci-warm ;;
    esac
}
# what a keeper wants built before it: dev-server serves a page, so the wasm runtime and packages
# stand first; the tools' witnesses build with build/avra-try, the generation after the builder, which
# the seed's generation-2 compiler already is
keeper_wants() {
    case $1 in
        dev-server) make -s -o avra wasm-runtime wasm-packages >"$out/keeper-$1.wants.log" 2>&1 ;;
        tool-witnesses) [ -x build/avra-try ] || cp build/avra build/avra-try ;;
    esac
}
# each keeper named, a row, under the words `keeper_via` names before its make; an owed one (tools/gate/keepers.owed) is judged by its line, not its run
keepers_run() {
    for k in "$@"; do
        keeper_wants "$k" || { judged "keeper-$k-wants" 1; continue; }
        # A RUNG TRAIN'S SEED IS OWED BY THE NEXT ONE: no seed reads a rung, so seed-check stands down, said,
        # and the train's own compiler emits the seed (`make seed`) for the landing to commit as the next train
        if [ "$k" = seed-check ]; then
            rungs_read
            if [ -n "$rungs" ]; then
                echo "fact keeper seed-check SKIPPED: this train carries $(echo $rungs | wc -w) rung(s) ($rungs) — no seed reads a rung; its seed is emitted beside the verdict (seed.ll.gz), and the next train commits it" >>"$out/rows"
                # the cli's whole IR is the largest thing a compiler is asked for (about 8 GB at its peak),
                # past the shim's default cap: the emit is let take the runner, less a margin, as the Mac's seed is
                row keeper-seed-emitted env AVRA_CAP_MB="$(awk '/^MemTotal:/ { print int($2 / 1024) - 1200 }' /proc/meminfo)" make -s -o avra seed &&
                    cp bootstrap/seed.ll.gz bootstrap/seed.sources "$out/" &&
                    git checkout -q -- bootstrap/seed.ll.gz bootstrap/seed.sources
                continue
            fi
        fi
        owed=$(awk -v k="$k" '$1 == k { print $2; exit }' "$root/tools/gate/keepers.owed")
        if [ -z "$owed" ]; then
            row "keeper-$k" env AVRA_NO_SUPERVISOR_TESTS=1 UI_BROWSER_ENGINES="firefox webkit webkit-iphone" $(keeper_env "$k") ${keeper_via:-} make -s -o avra "$k"
            continue
        fi
        # OWED: run as any keeper, its words kept; red is the owner's debt, green means strike the line
        rows=$((rows + 1))
        t0=$(date +%s)
        if sh tools/bounded.sh "$ROW_SECS" env AVRA_NO_SUPERVISOR_TESTS=1 UI_BROWSER_ENGINES="firefox webkit webkit-iphone" $(keeper_env "$k") ${keeper_via:-} make -s -o avra "$k" >"$out/keeper-$k.log" 2>&1; then
            # a share of an owed keeper that passes owes nothing here: its line is struck when every share passes
            if [ -n "${keeper_share:-}" ]; then
                echo "row keeper-$k OWED $(( $(date +%s) - t0 ))s (share $keeper_share passes; $owed owes the others)" >>"$out/rows"
                continue
            fi
            failed=$((failed + 1))
            failures="$failures keeper-$k"
            echo "row keeper-$k FAIL $(( $(date +%s) - t0 ))s (passes, and tools/gate/keepers.owed still owes it — strike its line)" >>"$out/rows"
        else
            echo "row keeper-$k OWED $(( $(date +%s) - t0 ))s ($owed: $(awk -v k="$k" '$1 == k { $1 = ""; $2 = ""; sub(/^  /, ""); print; exit }' "$root/tools/gate/keepers.owed"))" >>"$out/rows"
        fi
    done
}
# a keeper list that names nothing fails: a renamed set keeps nothing silently
keepers_list() {
    judged keepers-owed-lines "$(awk '!/^#/ && NF > 0 && NF < 3' "$root/tools/gate/keepers.owed" | wc -l | tr -d ' ')"
    names=$(keepers_of "$1")
    [ -n "$names" ] || { judged "keepers-$1-named" 1; return; }
    keepers_run $names
}

# A KEEPER SLICE ENDS ON A PLANTED FAULT its keeper must refuse, naming it (tools/keeper_planted.sh):
# a slice whose keepers examined nothing is no slice that passes. `$1` is the plant; a part that
# names no keeper with a plant fails rather than passing unproved.
# THE KEEPERS ON STDIN, those with a plant first: dealt in turn, the first n go one to each of n parts, so
# every part holds a plant whatever keeper the set gains
planted_first() {
    all=$(cat)
    plants=$(sh tools/keeper_planted.sh --list)
    printf '%s\n' $all | grep -xF "$(printf '%s\n' $plants)" || :
    printf '%s\n' $all | grep -vxF "$(printf '%s\n' $plants)" || :
}

# whether the set `$1`, dealt into `$2` parts, holds a planted keeper for each: a set with fewer plants
# than parts fails by that name, never a part's planted row
planted_enough() {
    held=$(keepers_of "$1" | grep -vx tool-witnesses | planted_first | head -n "$2" | grep -cxF "$(sh tools/keeper_planted.sh --list)" || :)
    [ "$held" -ge "$2" ] && return 0
    echo "fact keepers-planted: $1 holds $held planted keeper(s) for its $2 parts — give the set another plant (tools/keeper_planted.sh)" >>"$out/rows"
    judged "keepers-planted-enough" 1
    return 1
}

planted_row() {
    [ -n "$1" ] || { judged "$slice-planted" 1; return; }
    row "planted-$1" sh tools/keeper_planted.sh "$1"
}

# the part `$2` of `$3` of the split family `$1`; a family `splits` doesn't name, or a part past its
# count, fails rather than passing on no rows
part_of() {
    case $2 in '' | *[!0-9]*) judged "part-$slice" 1; return ;; esac
    [ -n "$3" ] && [ "$2" -ge 1 ] && [ "$2" -le "$3" ] || { judged "part-$slice" 1; return; }
    case $1 in
        avrac-b) avrac $(features '[a-e]*' | dealt "$(($2 - 1))" "$3") ;;
        avrac-c) avrac $(features '[f-m]*' | dealt "$(($2 - 1))" "$3") ;;
        avrac-e) avrac $(features '[s-z]*' | dealt "$(($2 - 1))" "$3") ;;
        edit-n)
            # every numbered edit a part: a witness that holds another count than the parts runs none
            have=$(sed -n "/^edits='/,/'\$/p" tools/witness_program_edit.sh | wc -l | tr -d ' ')
            [ "$have" = "$3" ] || { echo "fact edit-n: witness_program_edit holds $have numbered edits, the gate deals $3" >>"$out/rows"; judged edit-n-count 1; return; }
            edit_part "$2"
            ;;
        edit-f) edit_part "modes-whole-$2" ;;
        edit-g) edit_part "modes-layered-$2" ;;
        pkgs) pkgs_part "$2" "$3" "${4:-}" ;;
        cli) slice_cli $(find packages/cli/src/tests packages/cli/src/commands/tests -mindepth 1 -maxdepth 1 ! -name '.*' | sort | dealt_by_seconds "$(($2 - 1))" "$3") ;;
        program)
            cold std-program std-relation
            rows_dealt program_rows "$2" "$3"
            ;;
        refusal) row refusal-witness sh tools/witness_program_refusal.sh build/avra $(sh tools/witness_program_refusal.sh --cases | dealt "$(($2 - 1))" "$3") ;;
        needs) row needs-witness sh tools/witness_program_needs.sh build/avra $(sh tools/witness_program_needs.sh --cases | dealt "$(($2 - 1))" "$3") ;;
        witness-b) rows_dealt witness_b_rows "$2" "$3" ;;
        cost-warm) slice_cost warm "$2/$3" ;;
        cost-matrix-build-bare | cost-matrix-build-laid) slice_cost "${1#cost-}" "$2/$3" ;;
        keepers-b)
            planted_enough KEEPERS_B "$3" || return
            names=$(keepers_of KEEPERS_B | grep -vx tool-witnesses | planted_first | dealt "$(($2 - 1))" "$3")
            [ -n "$names" ] || { judged "keepers-b-named" 1; return; }
            keepers_run $names
            planted_row "$(sh tools/keeper_planted.sh --pick $names)"
            ;;
        keepers-tw)
            export TOOL_WITNESS_SHARD="$(($2 - 1))/$3"
            # the witnesses this gate runs by rows of its own (the edit witness's every part: edit-a, -e, -f, -g, -n)
            export TOOL_WITNESS_ELSEWHERE="witness_compiler_key.sh witness_program_differential.sh witness_program_doors.sh witness_program_fixes.sh witness_program_ledger.sh witness_program_needs.sh witness_program_refusal.sh witness_program_runs.sh witness_program_suites.sh witness_program_waits.sh witness_program_warnings.sh witness_program_edit.sh witness_place_kill.sh witness_machine_store.sh"
            keeper_share=$TOOL_WITNESS_SHARD keepers_run tool-witnesses
            planted_row tool-witnesses
            ;;
        keepers-alone)
            names=$(keepers_of KEEPERS_ALONE)
            [ -n "$names" ] || { judged "keepers-alone-named" 1; return; }
            # THE MUTATIONS RUN WHERE WHAT THEY READ MOVED, as the one table of what a check reads says
            # (`wisp ci_path_gate`): a diff from the program landed last (`$4`) that touches none of
            # it would kill the same breaks again; said every gate
            if [ -n "${4:-}" ] && [ "$(git diff --name-only "$4" HEAD | ./wisp ci_path_gate runtime-mutations --event pull_request)" = 0 ]; then
                names=$(printf '%s\n' $names | grep -vx runtime-mutations || :)
                echo "fact keeper runtime-mutations not run: nothing it reads moved since $(git rev-parse --short=8 "$4")" >>"$out/rows"
            fi
            [ -n "$names" ] || return 0
            export MUTATION_SHARD="$(($2 - 1))/$3"
            keeper_share=$MUTATION_SHARD keeper_via="sh tools/memcap.sh 6000" keepers_run $names
            planted_row runtime-tests
            ;;
    esac
}

# the warnings witness's part `$1`
warnings_part() { row warnings-witness env WITNESS_ONLY="$1" sh tools/witness_program_warnings.sh build/avra; }

# the edit witness's edits `$1`
# THE WALK IS CHECKED WHERE IT IS WRITTEN: every warm build an edit witness makes checks a frontier
# write's walk from where reads were cut against the whole walk from the roots, and says a mismatch in
# the row's trips file — a save that traps after its process answered fails no build, so the trips
# are judged apart: none holds.
edit_part() {
    trips="$out/walk-check.trips"
    : >"$trips"
    row edit-witness env WITNESS_ONLY="$1" AVRA_FRONTIER_WALK_CHECK="$trips" sh tools/witness_program_edit.sh build/avra
    judged edit-walk-check "$([ -s "$trips" ] && echo 1 || echo 0)"
}

# where two binaries differ: `<bytes differing> first=<offset> in <section>`, the sections by readelf
differs_at() {
    n=$(cmp -l "$1" "$2" 2>/dev/null | wc -l | tr -d ' ')
    first=$(cmp "$1" "$2" 2>/dev/null | awk '{ sub(/,$/, "", $5); print $5 - 1 }')
    sect=$(readelf -S -W "$2" 2>/dev/null | python3 -c '
import re, sys
at = int(sys.argv[1])
for line in sys.stdin:
    m = re.match(r"\s*\[\s*\d+\]\s+(\S+)\s+\S+\s+[0-9a-f]+\s+([0-9a-f]+)\s+([0-9a-f]+)", line)
    if m and int(m.group(2), 16) <= at < int(m.group(2), 16) + int(m.group(3), 16):
        print(m.group(1)); break' "${first:-0}")
    echo "$n first=${first:-?} in ${sect:-?}"
}

# WHAT THIS MACHINE IS, the first line of the slice's rows: its cores as a process may use them and as
# the machine has them, its cgroup's cpu and memory bounds, its load, the memory pool's slot files,
# and what one process costs to start — a plain one, and the compiler asked its version, a program
# of this runtime. A slice slower than its rows' own work says why here first.
facts() {
    t0=$(date +%s%N)
    for _ in 1 2 3 4 5 6 7 8 9 10; do /bin/true; done
    t1=$(date +%s%N)
    for _ in 1 2 3 4 5 6 7 8 9 10; do build/avra --version >/dev/null 2>&1; done
    t2=$(date +%s%N)
    echo "facts cpu=$(awk -F': ' '/^model name/ { gsub(/ +/, "_", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null) cores=$(nproc) of $(nproc --all) cpu.max=$(cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo -)" \
        "memory.max=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo -) load=$(cut -d' ' -f1-3 /proc/loadavg)" \
        "pool-slots=$(find "/tmp/avra-$(id -u)/avra-pool" -name 'slot-*' 2>/dev/null | wc -l)" \
        "start=$(( (t1 - t0) / 10000000 ))ms avra-version=$(( (t2 - t1) / 10000000 ))ms" >>"$out/rows"
}
[ ! -x build/avra ] || facts

if compiler; then
    case $slice in
        pack)
            # THE SEED ENDS AT GENERATION 2: every slice runs this tree's own compiler of its fixed point.
            # The census compiler is the cost slices' alone, built in each of them beside the others,
            # never before every slice starts and never in the pack every slice unpacks
            # WHETHER GENERATION 2 IS GENERATION 1'S BYTES, said beside the rows: where it is, a slice run on
            # generation 1 judged the very binary generation 2 is
            read -r _h _a seed_gen _ < build/.avra-built-from 2> /dev/null || seed_gen=1
            [ "${seed_gen:-1}" -ge 2 ] || cp build/avra "$out/avra-gen1"
            gen2_made || { echo "GATE $slice $sha8 FAIL rows=$rows failed=$failed $(( $(date +%s) - began ))s"; exit 1; }
            if [ -f "$out/avra-gen1" ]; then
                if cmp -s build/avra "$out/avra-gen1"; then same=yes; else same=no; fi
                echo "fact gen2-is-gen1 $same $(wc -c < "$out/avra-gen1" | tr -d ' ') $(wc -c < build/avra | tr -d ' ')" >>"$out/rows"
                # WHERE THEY DIFFER: how many bytes, the first, and the ELF section it falls in — a stamp or one
                # constant reads otherwise than a lowering that moved
                [ "$same" = yes ] || echo "fact gen2-differs $(differs_at "$out/avra-gen1" build/avra)" >>"$out/rows"
                find "$out/avra-gen1" -delete
            else
                echo "fact gen2-is-gen1 - (the seed stood at generation 2)" >>"$out/rows"
            fi
            # the package libraries as this tree's sources make them: nothing rebuilt where none moved
            row compiler-libs env AVRA_PROGRAM_NET=0 make -o avra libs
            row wisp ./wisp --path
            tarball="build/gate/compiler-$sha8.tar.gz"
            packed >"$out/files"
            row pack tar -czf "$tarball" -T "$out/files" && echo "pack: $tarball, $(wc -l <"$out/files" | tr -d ' ') files, $(du -k "$tarball" | cut -f1) KB" >>"$out/rows"
            ;;
        census)
            # THE CENSUS COMPILER IS ONE BUILD A GATE: every cost slice counts with the same binary, so
            # it is made here once and each cost slice unpacks it, held by census_stands as a built one is
            census_made || { echo "GATE $slice $sha8 FAIL rows=$rows failed=$failed $(( $(date +%s) - began ))s"; exit 1; }
            row census-pack tar -czf "build/gate/census-$sha8.tar.gz" build/avra.census build/.avra.census-built-from
            ;;
        build) slice_build ;;
        avrac-a) slice_avrac_a ;;
        avrac-g) slice_avrac_g ;;
        avrac-d) slice_avrac_d ;;
        avrac-f) slice_avrac_f ;;
        idioms-avrac) idioms_on "${1:-}" keep std-avrac ;;
        idioms-cli) idioms_on "${1:-}" keep cli ;;
        idioms) idioms_on "${1:-}" drop 'std-avrac|cli' ;;
        fmt) fmt_on "${1:-}" ;;
        store-fuzz) slice_store_fuzz ;;
        sound) slice_sound ;;
        doors-a) slice_doors_a ;;
        doors-b) slice_doors_b ;;
        ui-browser) slice_ui_browser ;;
        storyboard) slice_storyboard ;;
        findings-a) slice_findings_a ;;
        findings-b) findings_third 0 ;;
        findings-c) findings_third 1 ;;
        findings-d) findings_third 2 ;;
        warnings-a) warnings_part cold ;;
        warnings-b) warnings_part cases ;;
        warnings-c) warnings_part edit ;;
        edit-a) edit_part "embed infer composed gathered check lawed derived" ;;
        edit-e) edit_part rename ;;
        keepers-a1) keepers_list KEEPERS_A1; planted_row fmt-lossless ;;
        keepers-a2) keepers_list KEEPERS_A2; planted_row traps ;;
        keepers-wasm) keepers_list KEEPERS_WASM; planted_row wasm-refuses ;;
        keepers-heavy-1) [ -x build/avra-try ] || cp build/avra build/avra-try; row witness-place-kill env AVRA_NO_SUPERVISOR_TESTS=1 sh tools/witness_place_kill.sh; planted_row witness-place-kill ;;
        keepers-heavy-2) [ -x build/avra-try ] || cp build/avra build/avra-try; row witness-machine-store env AVRA_NO_SUPERVISOR_TESTS=1 sh tools/witness_machine_store.sh; planted_row witness-machine-store ;;
        keepers-clock)
            keepers_run clock-holds
            planted_row clock-holds
            # SPEED-RATCHET GATES NOTHING YET: the ledger holds no `speed:ci-warm:` row for the phases it
            # measures, so it would spend ~800 s measuring and compare none; said every gate until it has rows
            echo "fact keeper speed-ratchet not run: the record under cost/ holds no speed:ci-warm row for its phases" >>"$out/rows"
            ;;
        cost-cold-a) slice_cost cold-a ;;
        cost-cold-b) slice_cost cold-b ;;
        cost-answers)
            census_stands || census_made || { judged census 1; return; }
            row cost-answers env COST_PART=answers COST_COMPILER=build/avra.census sh tools/cost.sh
            grep -E '^cost: the snapshot.s std answers [0-9]+ s$' "$out/cost-answers.log" | sed 's/^cost: /fact cost /' >>"$out/rows"
            ;;
        cost-laid) slice_cost laid ;;
        cost-ledger-cold-a) slice_cost ledger-cold-a ;;
        cost-ledger-cold-b) slice_cost ledger-cold-b ;;
        cost-ledger-warm) slice_cost ledger-warm ;;
        cost-matrix-check-bare | cost-matrix-check-laid) slice_cost "${slice#cost-}" ;;
        *) part_of "${slice%-*}" "${slice##*-}" "$(splits | awk -F'|' -v f="${slice%-*}" '$1 == f { print $2 }')" "${1:-}" ;;
    esac
fi

find "$AVRA_CACHE_DIR" -delete
verdict=PASS
[ "$failed" = 0 ] || verdict=FAIL
[ -z "$failures" ] || echo "gate: failed:$failures — their words under build/gate/$slice/"
# every row and its seconds, in the job's own log: what a split is planned by
sed 's/^/gate: /' "$out/rows"
echo "GATE $slice $sha8 $verdict rows=$rows failed=$failed $(( $(date +%s) - began ))s"
[ "$verdict" = PASS ]
