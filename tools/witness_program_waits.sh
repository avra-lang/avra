#!/bin/sh
# A DEFER'S CALL WAITS AS THE TASK SURVEY SAYS, READ OFF THE ITEMS' SUMMARIES: the defer law asks
# whether a fn it calls may switch the task out of the summaries each item keeps
# (packages/std-avrac/src/compiler/item_waits.av), and asks the task survey, which lowers bodies,
# only where they can't say. Here every fn of each package's program is held both ways
# (`avra tapes --waits`): a fn the summaries answer otherwise than the survey is named and fails
# the witness; how many each package held and the summaries answered is said.
#   sh tools/witness_program_waits.sh [compiler] [package…]
#   (default build/avra-try; with no package, the packages whose code defers, spawns or waits, and
#   the refusal witnesses that do)
set -u
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
avra=build/avra-try
case "${1:-}" in packages/*|tools/*|"") ;; *) avra=$1; shift ;; esac
[ -x "$avra" ] || { echo "witness_program_waits: no compiler at $avra" >&2; exit 1; }
if [ $# -eq 0 ]; then
    set -- packages/std-process packages/std-program packages/std-task packages/std-time packages/std-net \
        packages/std-io packages/std-http packages/std-db packages/std-queue packages/std-queue_store \
        $(ls -d tools/program-refusals/* | grep -E 'defer|task|wait|spawn|select|cancel|produce|within|channel|await')
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0
for p in "$@"; do
    [ -d "$p" ] || { echo "witness_program_waits: no package at $p" >&2; failed=1; continue; }
    mkdir -p "$tmp/cache"
    AVRA_CACHE_DIR="$tmp/cache" "$avra" tapes --waits "$p" > "$tmp/out" 2> "$tmp/err"
    code=$?
    rm -rf "$tmp/cache" "$p/.avra-cache"
    said=$(grep '^waits:' "$tmp/out" | tail -1)
    if [ -z "$said" ]; then
        echo "$p: no hold said (exit $code)"; tail -3 "$tmp/err"; failed=1; continue
    fi
    echo "$p: ${said#waits: }"
    grep '^apart:' "$tmp/out"
    [ "$code" = 0 ] || failed=1
done
[ "$failed" = 0 ] && echo "witness_program_waits: every summary that answers agrees with the survey"
exit "$failed"
