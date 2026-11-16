#!/bin/sh
# THE GATE, IN SLICES: every receipt a landing is held to, cut into slices that each run alone in a
# tree of their own, so N machines run N slices at once and the gate takes as long as its longest
# slice. A slice builds the compiler of HEAD itself when build/avra was built from anything else,
# runs every row under no env — the program layer, the net on — unless the row names one, empties the
# stores a cold row reads, bounds every command, keeps each row's words under build/gate/<slice>/, and
# ends with ONE line:
#   GATE <slice> <sha8> PASS|FAIL rows=<n> failed=<n> <seconds>s
# exiting 0 on PASS, 1 on FAIL.
#
#   sh tools/gate.sh list               each slice, one a line, with what it holds
#   sh tools/gate.sh <slice> [arg]      one slice; `idioms` takes the base sha its diff starts at
#
# GATE_OLD_PATH=0 drops every row that compares against the old path (they read AVRA_PROGRAM=0);
# when the old path goes, its default goes to 0 and those rows go with one line each.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1
unset AVRA_PROGRAM AVRA_PROGRAM_NET AVRA_PROGRAM_MODE

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
avrac-a    test packages/std-avrac — src/compiler
avrac-b    test packages/std-avrac — everything but src/compiler
cli        test packages/cli, its failing names held to tools/gate/cli.names
program    test packages/std-program and std-relation; make runtime-tests
idioms     check --baseline tools/idioms.baseline on each package the diff from <base> touches; the cli's sound check
doors-a    test std-json std-task std-validate std-text std-sql std-queue std-time
doors-b    test std-ui std-http
findings   tapes --findings on every package, 0 refusals; every package but the cli built, 0 program-layer false refusals
witness-a  witness_program_refusal; witness_program_doors
witness-b  witness_program_runs, _ledger, _suites; witness_program_differential
warnings   witness_program_warnings
edit       witness_program_edit, WITNESS_ONLY="embed infer composed 1 5 10 rename"
EOF
}

[ $# -ge 1 ] || { echo "gate: name a slice, or \`list\`" >&2; exit 2; }
slice=$1
shift
if [ "$slice" = list ]; then slices; exit 0; fi
slices | awk '{ print $1 }' | grep -qx "$slice" || { echo "gate: no slice \`$slice\` — \`sh tools/gate.sh list\` names them" >&2; exit 2; }

sha8=$(git rev-parse --short=8 HEAD)
out="$root/build/gate/$slice"
mkdir -p "$out"
find "$out" -mindepth 1 -delete
export AVRA_CACHE_DIR="$out/machine"
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

# the stores of the packages named emptied, so the rows after read them cold
cold() { for p in "$@"; do [ -d "packages/$p/.avra-cache" ] && find "packages/$p/.avra-cache" -delete; done; return 0; }

# build/avra as HEAD's compiler: kept when it was built from this tree's compiler source, else made —
# from the seed where none stands, else two generations from the one that does
compiler() {
    now=$(sh tools/work built-from .)
    if [ -x build/avra ] && [ "$(cat build/.avra-built-from 2>/dev/null)" = "$now" ]; then return 0; fi
    if [ ! -x build/avra ]; then
        row compiler-bootstrap make bootstrap || return 1
    else
        row compiler-gen1 make avra || return 1
        row compiler-gen2 make avra || return 1
    fi
    row compiler-libs make libs
}

# what `$1`'s cold build of packages/cli took, in seconds, net on or off by `$2`
cli_built() {
    cold cli
    find "$AVRA_CACHE_DIR" -mindepth 1 -delete
    c0=$(date +%s)
    row "cli-build-$1-cold" env AVRA_PROGRAM_NET="$2" build/avra build packages/cli || return 1
    c1=$(date +%s)
    row "cli-build-$1-warm" env AVRA_PROGRAM_NET="$2" build/avra build packages/cli || return 1
    echo "cli build net $1: cold $((c1 - c0))s, warm $(( $(date +%s) - c1 ))s" >>"$out/seconds"
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

# the std-avrac suite over `$@`, its paths under the package
avrac() {
    cold std-avrac
    tested std-avrac "$@"
}
slice_avrac_a() { avrac packages/std-avrac/src/compiler; }
slice_avrac_b() { avrac $(find packages/std-avrac/src -mindepth 1 -maxdepth 1 ! -name compiler | sort); }

# `test` over `$2…` as the row `$1`, judged by the NAMES that fail: each must be one
# tools/gate/<package>.names pins (a case a sandbox's environment fails — root writes any directory, no
# terminal, no network), never a count. With no pin file, every failure fails the row.
tested() {
    name=$1; shift
    pkg=$(echo "$1" | cut -d/ -f2)
    sh tools/bounded.sh "$ROW_SECS" build/avra test "$@" >"$out/$name.log" 2>&1
    ran=$?
    grep '^    ✗' "$out/$name.log" | sed 's/ @ .*//; s/^    ✗ //' | sort -u >"$out/$name.failed"
    if [ -f "tools/gate/$pkg.names" ]; then grep -v '^#' "tools/gate/$pkg.names" | sort -u >"$out/$name.known"; else : >"$out/$name.known"; fi
    comm -23 "$out/$name.failed" "$out/$name.known" >"$out/$name.unpinned"
    # a run that fails no case must have exited clean; one that fails only pinned cases stopped on them
    if [ ! -s "$out/$name.failed" ]; then judged "$name" "$ran"; return; fi
    judged "$name" "$(wc -l <"$out/$name.unpinned" | tr -d ' ')"
}

slice_cli() {
    cold cli
    tested cli-suite packages/cli
}

slice_program() {
    cold std-program std-relation
    tested std-program packages/std-program
    tested std-relation packages/std-relation
    row runtime-tests make runtime-tests
}

slice_idioms() {
    base=${1:-}
    [ -n "$base" ] || { echo "gate: idioms needs the base sha its diff starts at" >&2; exit 2; }
    touched=$(git diff --name-only "$base" HEAD -- packages | cut -d/ -f2 | sort -u)
    for p in $touched; do
        [ -d "packages/$p/src" ] || continue
        cold "$p"
        row "idioms-$p" build/avra check "packages/$p" --baseline tools/idioms.baseline
    done
    old_row sound-check-run env AVRA_PROGRAM=0 AVRA_SOUND_CHECK=1 build/avra check packages/cli
    if [ "$OLD_PATH" = 1 ]; then
        judged sound-check-defects "$(grep -c 'defect: in' "$out/sound-check-run.log")"
    fi
}

doors() { for p in "$@"; do cold "$p"; tested "test-$p" "packages/$p"; done; }
slice_doors_a() { doors $DOORS_A; }
slice_doors_b() { doors $DOORS_B; }

slice_findings() {
    for d in packages/*/; do
        p=$(basename "$d")
        [ -d "$d/src" ] || continue
        cold "$p"
        row "findings-$p" build/avra tapes "$root/packages/$p" --findings
        judged "refusals-$p" "$(grep -c '^error\[' "$out/findings-$p.log")"
        # a library's build stops at "declares no entry point", which is no refusal; the cli's builds
        # are the build slice's
        [ "$p" != cli ] || continue
        sh tools/bounded.sh "$ROW_SECS" build/avra build "packages/$p" >"$out/build-$p.log" 2>&1
        judged "false-refusals-$p" "$(grep -c 'program-layer false refusal' "$out/build-$p.log")"
    done
}

slice_witness_a() {
    old_row refusal-witness sh tools/witness_program_refusal.sh build/avra
    old_row doors-witness sh tools/witness_program_doors.sh build/avra
}

slice_witness_b() {
    row runs-witness sh tools/witness_program_runs.sh build/avra
    old_row ledger-witness sh tools/witness_program_ledger.sh build/avra
    old_row suites-witness sh tools/witness_program_suites.sh build/avra
    old_row differential-witness sh tools/witness_program_differential.sh build/avra
}

slice_warnings() { old_row warnings-witness sh tools/witness_program_warnings.sh build/avra; }

slice_edit() { row edit-witness env WITNESS_ONLY="embed infer composed 1 5 10 rename" sh tools/witness_program_edit.sh build/avra; }

if compiler; then
    case $slice in
        build) slice_build ;;
        avrac-a) slice_avrac_a ;;
        avrac-b) slice_avrac_b ;;
        cli) slice_cli ;;
        program) slice_program ;;
        idioms) slice_idioms "$@" ;;
        doors-a) slice_doors_a ;;
        doors-b) slice_doors_b ;;
        findings) slice_findings ;;
        witness-a) slice_witness_a ;;
        witness-b) slice_witness_b ;;
        warnings) slice_warnings ;;
        edit) slice_edit ;;
    esac
fi

find "$AVRA_CACHE_DIR" -delete
verdict=PASS
[ "$failed" = 0 ] || verdict=FAIL
[ -z "$failures" ] || echo "gate: failed:$failures — their words under build/gate/$slice/"
echo "GATE $slice $sha8 $verdict rows=$rows failed=$failed $(( $(date +%s) - began ))s"
[ "$verdict" = PASS ]
