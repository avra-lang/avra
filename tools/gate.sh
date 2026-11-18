#!/bin/sh
# THE GATE, IN SLICES: every receipt a landing is held to, cut into slices that each run alone in a
# tree of their own, so N machines run N slices at once and the gate takes as long as its longest
# slice. A slice builds the compiler of HEAD itself when build/avra was built from anything else,
# runs every row on the program layer, the net off but where a row's claim is the net, empties the
# stores a cold row reads, bounds every command, keeps each row's words under build/gate/<slice>/, and
# ends with ONE line:
#   GATE <slice> <sha8> PASS|FAIL rows=<n> failed=<n> <seconds>s
# exiting 0 on PASS, 1 on FAIL.
#
#   sh tools/gate.sh list               each slice, one a line, with what it holds
#   sh tools/gate.sh <slice> [arg]      one slice; the idioms slices take the base sha their diff starts at
#   sh tools/gate.sh seed               build/gate/compiler-<sha8>.tar.gz: HEAD's compiler — ONE generation, built
#                                       here first where none of HEAD's stands — and every object a tree
#                                       links with; `pack` is its other name. Run it once; every slice
#                                       then starts from `unpack` and builds nothing.
#   sh tools/gate.sh unpack <file>      seeds this tree from a pack, and holds its stamp to HEAD's: a
#                                       seeded slice builds no compiler
#
# A test row runs every suite (AVRA_SUITE_ALL=1), so it names every failing case, never only the first.
#
# GATE_OLD_PATH=0 drops every row that compares against the old path (they read AVRA_PROGRAM=0);
# when the old path goes, its default goes to 0 and those rows go with one line each.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1
unset AVRA_PROGRAM AVRA_PROGRAM_MODE
export AVRA_SUITE_ALL=1
# THE NET IS OFF unless a row's claim is the net: the old path's check before every program-layer
# compile doubles what each row costs and proves nothing a row here asks of it. The rows that keep it
# (AVRA_PROGRAM_NET=1) are the ones that count what it says: the build slice's net-on cli builds and
# their "program-layer false refusal" count, the findings slices' build of every package, held to that
# same count, and the cli's suite, which holds the words a user meets through a child build/avra (at
# slice_cli). `tapes --findings` passes no door, so the net never stood in it.
export AVRA_PROGRAM_NET=0

OLD_PATH=${GATE_OLD_PATH:-1}
# the bound of one row, and of a compiler build
ROW_SECS=${GATE_ROW_SECS:-2400}
# every `test` row's failing NAMES are held to tools/gate/<package>.names, the cases a sandbox fails
# the packages whose tests the doors slices run
DOORS_A="std-json std-task std-validate std-text std-sql std-queue std-time"
DOORS_B="std-ui std-http"

slices() {
    cat <<'EOF'
build      make try; make avra twice, the second cold, the two binaries one; cli build cold+warm, net on and off, 0 false refusals
avrac-a    test packages/std-avrac — half of src/compiler/tests, dealt in turn, and every dir of src/compiler but tests and soundness
avrac-g    test packages/std-avrac — the other half of src/compiler/tests, and src/compiler/soundness
avrac-b    test packages/std-avrac — src/features/[a-e]*
avrac-c    test packages/std-avrac — src/features/[f-m]*
avrac-d    test packages/std-avrac — src/features/[n-r]*
avrac-e    test packages/std-avrac — src/features/[s-z]*
avrac-f    test packages/std-avrac — src/features' own files, and every dir of src/ but compiler and features
cli        test packages/cli, its failing names held to tools/gate/cli.names
program    test packages/std-program and std-relation; make runtime-tests
idioms-avrac  check --baseline tools/idioms.baseline on std-avrac, when the diff from <base> touches it
idioms-cli    the same on cli
idioms     the same on every other package the diff from <base> touches
sound      AVRA_SOUND_CHECK=1 check packages/cli, the memory pass's proof run over the program, 0 defects
doors-a    test std-json std-task std-validate std-text std-sql std-queue std-time
doors-b    test std-ui std-http; make ui-host-test and ui-host, std-ui's program tests built and run
findings-a tapes --findings on std-avrac and cli, 0 refusals; std-avrac built, 0 program-layer false refusals
findings-b the same on a third of every other package, dealt in turn
findings-c the next third
findings-d the last third
refusal-a  witness_program_refusal over a third of its cases, dealt in turn
refusal-b  the next third
refusal-c  the last third
witness-b  witness_program_runs, heir_save_attack, share_merge_attack, wave_share_attack, beside_attack, _ledger, _suites, _doors; witness_program_differential; make flow-trace; witness_compiler_key
warnings-a witness_program_warnings — the cli built cold and again with no change, on both paths
warnings-b witness_program_warnings — the cli's check on both paths, and the cases under tools/program-warnings/
warnings-c witness_program_warnings — the cli edited, built warm on the program layer
edit-a     witness_program_edit, WITNESS_ONLY="embed infer composed gathered"
edit-b     witness_program_edit, WITNESS_ONLY=1
edit-c     witness_program_edit, WITNESS_ONLY=5
edit-d     witness_program_edit, WITNESS_ONLY=10
edit-e     witness_program_edit, WITNESS_ONLY=rename
edit-f     witness_program_edit, WITNESS_ONLY=modes-whole
edit-g     witness_program_edit, WITNESS_ONLY=modes-layered
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
        mv -f "$stage/$f" "$f"
    done
    find "$stage" -delete
    compiler_stands || { echo "gate: build/avra does not stand as HEAD's compiler after the unpack" >&2; exit 1; }
    echo "gate: seeded from $(basename "$pack") — build/avra stands as HEAD's compiler"
    exit 0
}

[ $# -ge 1 ] || { echo "gate: name a slice, or \`list\`" >&2; exit 2; }
slice=$1
shift
if [ "$slice" = list ]; then slices; exit 0; fi
if [ "$slice" = unpack ]; then unpacked "$@"; fi
[ "$slice" = seed ] && slice=pack
[ "$slice" = pack ] || slices | awk '{ print $1 }' | grep -qx "$slice" || { echo "gate: no slice \`$slice\` — \`sh tools/gate.sh list\` names them" >&2; exit 2; }

sha8=$(git rev-parse --short=8 HEAD)
out="$root/build/gate/$slice"
mkdir -p "$out"
find "$out" -mindepth 1 -delete
export AVRA_CACHE_DIR="$out/machine"
# a slice copies, counts and empties stores between builds, so each build saves its own before it
# answers; the build slice's timing rows alone leave the save to an heir, as a user's build does
export AVRA_STORE_KEPT_HERE=1
mkdir -p "$AVRA_CACHE_DIR"
began=$(date +%s)
rows=0
failed=0
failures=""

# one row: `$1` its name, the rest its command, bounded; its words at $out/<name>.log
row() {
    name=$1; shift
    rows=$((rows + 1))
    t0=$(date +%s)
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
    if [ "$2" = 0 ]; then echo "row $1 pass" >>"$out/rows"; return 0; fi
    failed=$((failed + 1))
    failures="$failures $1"
    echo "row $1 FAIL" >>"$out/rows"
    return 1
}

# a row that compares against the old path: run only while the old path stands
old_row() { [ "$OLD_PATH" = 1 ] || return 0; row "$@"; }

# every store under the packages named emptied — a nested package's and a program test's too — so the
# rows after read them cold
cold() { for p in "$@"; do find "packages/$p" -name .avra-cache -prune -exec find {} -delete \; ; done; return 0; }

# build/avra as HEAD's compiler: kept when it was built from this tree's compiler source, else made in
# ONE generation — from the committed seed's link where no compiler stands, else from the one that does
# — with the package libraries beside it, built without building the compiler again. A gate's
# compiler makes no claim of the net, so it is built without it; the two-generation fixed point is the
# build slice's.
compiler() {
    if compiler_stands; then return 0; fi
    if [ ! -x build/avra ]; then row compiler-recover make recover || return 1; fi
    row compiler-gen1 env AVRA_PROGRAM_NET=0 make avra || return 1
    row compiler-libs env AVRA_PROGRAM_NET=0 make -o avra libs
}

# what `$1`'s cold build of packages/cli took, in seconds, net on or off by `$2`
cli_built() {
    cold cli
    find "$AVRA_CACHE_DIR" -mindepth 1 -delete
    c0=$(date +%s)
    row "cli-build-$1-cold" env -u AVRA_STORE_KEPT_HERE AVRA_PROGRAM_NET="$2" build/avra build packages/cli || return 1
    c1=$(date +%s)
    row "cli-build-$1-warm" env -u AVRA_STORE_KEPT_HERE AVRA_PROGRAM_NET="$2" build/avra build packages/cli || return 1
    echo "cli build net $1: cold $((c1 - c0))s, warm $(( $(date +%s) - c1 ))s" >>"$out/seconds"
    # the warm build's heir waited out, before a row after empties the store it saves
    env AVRA_PROGRAM_NET="$2" build/avra build packages/cli >/dev/null 2>&1 || :
}

slice_build() {
    row try make try
    row avra-a make avra && cp build/avra "$out/avra-a"
    cold cli
    row avra-b make avra && { cmp -s build/avra "$out/avra-a"; judged fixed-point $?; }
    cli_built on 1
    cli_built off 0
    judged cli-build-false-refusals "$(cat "$out"/cli-build-*.log | grep -c 'program-layer false refusal')"
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
slice_avrac_b() { avrac $(find packages/std-avrac/src/features -mindepth 1 -maxdepth 1 -type d -name '[a-e]*' | sort); }
slice_avrac_c() { avrac $(find packages/std-avrac/src/features -mindepth 1 -maxdepth 1 -type d -name '[f-m]*' | sort); }
slice_avrac_d() { avrac $(find packages/std-avrac/src/features -mindepth 1 -maxdepth 1 -type d -name '[n-r]*' | sort); }
slice_avrac_e() { avrac $(find packages/std-avrac/src/features -mindepth 1 -maxdepth 1 -type d -name '[s-z]*' | sort); }
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

# `test` over `$2…` as the row `$1`, judged by the NAMES that fail: each must be one
# tools/gate/<package>.names pins (a case a sandbox's environment fails — root writes any directory, no
# terminal, no network), never a count. With no pin file, every failure fails the row.
# A CASE THAT ENDS THE SUITE'S PROCESS (`avra: while running <case>`) fails no case by name and leaves
# every case after it unrun, so it is never passed over: each must be one tools/gate/<package>.traps
# lists, by the first line the runner says it under.
tested() {
    name=$1; shift
    pkg=$(echo "$1" | cut -d/ -f2)
    sh tools/bounded.sh "$ROW_SECS" build/avra test "$@" >"$out/$name.log" 2>&1
    ran=$?
    grep '^    ✗' "$out/$name.log" | sed 's/ @ .*//; s/^    ✗ //' | sort -u >"$out/$name.failed"
    listed "tools/gate/$pkg.names" >"$out/$name.known"
    comm -23 "$out/$name.failed" "$out/$name.known" >"$out/$name.unpinned"
    grep '^avra: while running ' "$out/$name.log" | sed 's/ @ .*//; s/^avra: while running //' | sort -u >"$out/$name.trapped"
    listed "tools/gate/$pkg.traps" >"$out/$name.traps"
    comm -23 "$out/$name.trapped" "$out/$name.traps" >"$out/$name.untrapped"
    if [ -s "$out/$name.untrapped" ]; then judged "$name" "$(wc -l <"$out/$name.untrapped" | tr -d ' ')"; return; fi
    # a run that fails no case and ends none must have exited clean; one that fails only pinned cases
    # or ends at a listed one stopped on them
    if [ ! -s "$out/$name.failed" ] && [ ! -s "$out/$name.trapped" ]; then judged "$name" "$ran"; return; fi
    judged "$name" "$(wc -l <"$out/$name.unpinned" | tr -d ' ')"
}

# the lines the pin file `$1` lists, sorted, each once; none where there is no such file
listed() { if [ -f "$1" ]; then grep -v '^#' "$1" | sort -u; fi; }

# THE CLI'S SUITE RUNS WITH THE NET: its cases run build/avra as a user does and hold the words a user
# meets, refusals among them, and where the program layer accepts a program the old path refuses, those
# words are the net's — so the suite holds the shipped default, the net on. The one suite that runs the
# compiler as a child; every other test row holds what it runs in-process.
slice_cli() {
    cold cli
    export AVRA_PROGRAM_NET=1
    children_kept tested cli-suite packages/cli
    export AVRA_PROGRAM_NET=0
    children_of_failed cli-suite
}

# A SUITE WHOSE CASES RUN THE COMPILER AS A CHILD KEEPS WHAT EACH CHILD DID: `$@` with every child
# `<tree>/avra` filed under $out/children/<case> by tools/gate/child_kept.sh — its arguments, its
# streams and its exit — so a red row has the words its children said.
children_kept() {
    find "$out/children" -delete 2>/dev/null || :
    export AVRA_BIN="$root/tools/gate/child_kept.sh" AVRA_CHILD_BIN="$root/build/avra" AVRA_CHILDREN="$out/children"
    "$@"
    unset AVRA_BIN AVRA_CHILD_BIN AVRA_CHILDREN
}

# the children of the cases row `$1` failed, kept; every other case's dropped
children_of_failed() {
    for d in "$out"/children/*/; do
        [ -f "$d/case" ] || continue
        grep -qxF "$(sed 's/ @ .*//' "$d/case")" "$out/$1.failed" || find "$d" -delete
    done
}

slice_program() {
    cold std-program std-relation
    tested std-program packages/std-program
    tested std-relation packages/std-relation
    row runtime-tests make runtime-tests
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

slice_sound() {
    row sound-check-run env AVRA_SOUND_CHECK=1 build/avra check packages/cli
    judged sound-check-defects "$(grep -c 'language.defect' "$out/sound-check-run.log")"
}

doors() { for p in "$@"; do cold "$p"; tested "test-$p" "packages/$p"; done; }
slice_doors_a() { doors $DOORS_A; }
slice_doors_b() {
    doors $DOORS_B
    row ui-host-test make -s -o avra ui-host-test
    row ui-host make -s -o avra ui-host
}

# each package named: tapes --findings with no refusal; built — a library stops at "declares no entry
# point", which is no refusal — with no program-layer false refusal; the cli's builds are the build slice's
findings_on() {
    for p in "$@"; do
        cold "$p"
        row "findings-$p" build/avra tapes "$root/packages/$p" --findings
        judged "refusals-$p" "$(grep -c '^error\[' "$out/findings-$p.log")"
        [ "$p" != cli ] || continue
        sh tools/bounded.sh "$ROW_SECS" env AVRA_PROGRAM_NET=1 build/avra build "packages/$p" >"$out/build-$p.log" 2>&1
        judged "false-refusals-$p" "$(grep -c 'program-layer false refusal' "$out/build-$p.log")"
    done
}
HEAVY_FINDINGS="std-avrac cli"
slice_findings_a() { findings_on $HEAVY_FINDINGS; }
# a third of every other package, the `$1`-th (from 0)
findings_third() {
    findings_on $(for d in packages/*/src; do basename "$(dirname "$d")"; done | grep -vxE "$(echo $HEAVY_FINDINGS | tr ' ' '|')" | dealt "$1" 3)
}

# the refusal witness over a third of its cases — its directories, each a case — the `$1`-th (from 0)
refusal_third() {
    old_row refusal-witness sh tools/witness_program_refusal.sh build/avra $(find tools/program-refusals -mindepth 1 -maxdepth 1 -type d | sed 's#.*/##' | sort | dealt "$1" 3)
}

slice_witness_b() {
    row runs-witness sh tools/witness_program_runs.sh build/avra
    row heir-save-attack env HEIR_ATTACK_AVRA="$root/build/avra" sh tools/heir_save_attack.sh
    row share-merge-attack env SHARE_ATTACK_AVRA="$root/build/avra" sh tools/share_merge_attack.sh
    row beside-attack env BESIDE_ATTACK_AVRA="$root/build/avra" sh tools/beside_attack.sh
    row wave-share-attack env WAVE_ATTACK_AVRA="$root/build/avra" sh tools/wave_share_attack.sh
    row flow-trace make -s -o avra flow-trace
    row compiler-key sh tools/witness_compiler_key.sh build/avra
    old_row ledger-witness sh tools/witness_program_ledger.sh build/avra
    old_row suites-witness sh tools/witness_program_suites.sh build/avra
    old_row doors-witness sh tools/witness_program_doors.sh build/avra
    old_row differential-witness sh tools/witness_program_differential.sh build/avra
}

# the warnings witness's part `$1`
warnings_part() { old_row warnings-witness env WITNESS_ONLY="$1" sh tools/witness_program_warnings.sh build/avra; }

# the edit witness's edits `$1`
edit_part() { row edit-witness env WITNESS_ONLY="$1" sh tools/witness_program_edit.sh build/avra; }

if compiler; then
    case $slice in
        pack)
            tarball="build/gate/compiler-$sha8.tar.gz"
            packed >"$out/files"
            row pack tar -czf "$tarball" -T "$out/files" && echo "pack: $tarball, $(wc -l <"$out/files" | tr -d ' ') files, $(du -k "$tarball" | cut -f1) KB" >>"$out/rows"
            ;;
        build) slice_build ;;
        avrac-a) slice_avrac_a ;;
        avrac-b) slice_avrac_b ;;
        avrac-c) slice_avrac_c ;;
        avrac-g) slice_avrac_g ;;
        avrac-d) slice_avrac_d ;;
        avrac-e) slice_avrac_e ;;
        avrac-f) slice_avrac_f ;;
        cli) slice_cli ;;
        program) slice_program ;;
        idioms-avrac) idioms_on "${1:-}" keep std-avrac ;;
        idioms-cli) idioms_on "${1:-}" keep cli ;;
        idioms) idioms_on "${1:-}" drop 'std-avrac|cli' ;;
        sound) slice_sound ;;
        doors-a) slice_doors_a ;;
        doors-b) slice_doors_b ;;
        findings-a) slice_findings_a ;;
        findings-b) findings_third 0 ;;
        findings-c) findings_third 1 ;;
        findings-d) findings_third 2 ;;
        refusal-a) refusal_third 0 ;;
        refusal-b) refusal_third 1 ;;
        refusal-c) refusal_third 2 ;;
        witness-b) slice_witness_b ;;
        warnings-a) warnings_part cold ;;
        warnings-b) warnings_part "check cases" ;;
        warnings-c) warnings_part edit ;;
        edit-a) edit_part "embed infer composed gathered" ;;
        edit-b) edit_part 1 ;;
        edit-c) edit_part 5 ;;
        edit-d) edit_part 10 ;;
        edit-e) edit_part rename ;;
        edit-f) edit_part modes-whole ;;
        edit-g) edit_part modes-layered ;;
    esac
fi

find "$AVRA_CACHE_DIR" -delete
verdict=PASS
[ "$failed" = 0 ] || verdict=FAIL
[ -z "$failures" ] || echo "gate: failed:$failures — their words under build/gate/$slice/"
echo "GATE $slice $sha8 $verdict rows=$rows failed=$failed $(( $(date +%s) - began ))s"
[ "$verdict" = PASS ]
