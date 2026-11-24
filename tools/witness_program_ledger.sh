#!/bin/sh
# ONLY THE JUDGED PROCESS SPEAKS ITS LEDGER. tools/program-ledger/ is a program whose forked child
# leaves (`avra_cores_leave`) holding boxes it never freed, while the program frees all it made;
# built on the program layer and run under AVRA_MEM_STATS=1, it says exactly one "mem: live" line,
# and it is the program's: 0 bytes.
#   sh tools/witness_program_ledger.sh [compiler]   (default build/avra-try)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_ledger: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
failed=0
path=program
mkdir -p "$tmp/$path"
cp -R "$root/tools/program-ledger/." "$tmp/$path/"
if ! (cd "$tmp/$path" && "$avra" build . >"$tmp/$path.build" 2>&1); then
    echo "witness_program_ledger: the program layer did not build it" >&2; cat "$tmp/$path.build" >&2; failed=1
else
    AVRA_MEM_STATS=1 "$tmp/$path/src/main" >"$tmp/$path.out" 2>&1
    lines=$(grep -c "^mem: live " "$tmp/$path.out")
    if [ "$lines" != 1 ] || ! grep -q "^mem: live 0 bytes at exit" "$tmp/$path.out"; then
        echo "witness_program_ledger: the run said its ledger otherwise:" >&2
        grep "^mem: live " "$tmp/$path.out" >&2
        failed=1
    fi
fi
[ "$failed" = 0 ] && echo "witness_program_ledger: one ledger, the program's, 0 bytes live"
[ "$failed" = 0 ]
