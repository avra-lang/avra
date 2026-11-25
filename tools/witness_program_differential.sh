#!/bin/sh
# THE PROGRAM LAYER REFUSES WHAT THE OLD PATH REFUSED, CODE BY CODE: every registered code's witness
# (packages/std-avrac/src/compiler/dev/witnesses.av, dumped by tools/witness-files) laid out on disk
# as a package and built on the program layer — checked, where the old refusal stood in a test file,
# which a build reads only where its entry reaches it — then judged by its first line against what
# the old path said of that witness, frozen in tools/witness_program_differential.old (asked once, at
# cbc437f4, before the old path's deletion):
#   SAME            both refuse, in the same first line
#   DIFFERENT       the program layer refuses under the old kind, in other words
#   OTHER-ERROR     the program layer refuses under another kind
#   ACCEPTED        the program layer builds what the old path refused
#   UNBUILT         the program layer says it doesn't build the program yet, and refuses nothing
#   COMPILER-DEFECT the program layer crashed, ran out its time, or failed saying no refusal
#   OLD-SILENT      the old path refused nothing over the witness either
#   WARNED / WARN-MISSING   a warning's witness: the program layer says the old warning, or doesn't
#   BEYOND / ABSENT no source reaches the code / no witness is written yet
#   STD-ROOT        the witness lays out a std of its own, which a compiler on disk reads only beside
#                   itself — not run
#   UNFROZEN        the old path never judged the witness, or it changed since its word was frozen:
#                   counted, its program-layer first line shown
# Prints one row per code that isn't SAME (code, verdict, the lane whose kinds it is — a guess from
# the kind — and both first lines), then the counts. With --bar N it exits 1 where fewer than N are
# SAME, else 0.
#   sh tools/witness_program_differential.sh [compiler] [--bar N] [--jobs J] [code…]
#   (default build/avra-try; J defaults to 3; naming codes judges only those)
set -u
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
avra=build/avra-try
case "${1:-}" in --*|"") ;; *) avra=$1; shift ;; esac
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_differential: no compiler at $avra" >&2; exit 1; }
bar=0
jobs=3
while [ $# -gt 0 ]; do
    case $1 in
        --bar) bar=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        *) break ;;
    esac
done
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
cp -R "$root/tools/witness-files" "$tmp/dump"
find "$tmp/dump" -name .avra-cache -prune -exec find {} -delete \;
(cd "$tmp/dump" && "$avra" run . >"$tmp/witnesses.jsonl" 2>"$tmp/dump.err") || {
    echo "witness_program_differential: the witnesses could not be dumped:" >&2
    cat "$tmp/dump.err" >&2
    exit 1
}
python3 -I "$root/tools/witness_program_differential.py" "$avra" "$tmp" "$bar" "$jobs" "$@"
