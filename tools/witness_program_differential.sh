#!/bin/sh
# THE PROGRAM LAYER REFUSES WHAT THE OLD PATH REFUSES, CODE BY CODE: every registered code's witness
# (packages/std-avrac/src/compiler/dev/witnesses.av, dumped by tools/witness-files) laid out on disk
# as a package, checked on the old path — built, for a witness the old path judges by building —
# and built on the program layer — checked, where the old refusal stands in a test file, which a
# build reads only where its entry reaches it — then judged by the first line each says:
#   SAME            both refuse, in the same first line
#   DIFFERENT       the program layer refuses under the old kind, in other words
#   OTHER-ERROR     the program layer refuses under another kind
#   ACCEPTED        the program layer builds what the old path refuses
#   UNBUILT         the program layer says it doesn't build the program yet, and refuses nothing
#   COMPILER-DEFECT the program layer crashed, ran out its time, or failed saying no refusal
#   OLD-SILENT      the old path refuses nothing over the witness either
#   WARNED / WARN-MISSING   a warning's witness: the program layer says the old warning, or doesn't
#   BEYOND / ABSENT no source reaches the code / no witness is written yet
#   STD-ROOT        the witness lays out a std of its own, which a compiler on disk reads only beside
#                   itself — not run
# Prints one row per code that isn't SAME (code, verdict, the lane whose kinds it is — a guess from
# the kind — and both first lines), then the counts. With --bar N it exits 1 where fewer than N are
# SAME, else 0.
#   sh tools/witness_program_differential.sh [compiler] [--bar N] [--jobs J] [code…]
#   (default build/avra-try; J defaults to 3; naming codes judges only those)
set -u
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
(cd "$tmp/dump" && AVRA_PROGRAM=0 "$avra" run . >"$tmp/witnesses.jsonl" 2>"$tmp/dump.err") || {
    echo "witness_program_differential: the witnesses could not be dumped:" >&2
    cat "$tmp/dump.err" >&2
    exit 1
}
python3 -I "$root/tools/witness_program_differential.py" "$avra" "$tmp" "$bar" "$jobs" "$@"
