#!/bin/sh
# `MEMCAP=<memcap.sh> sh tools/witness_parallel_build.sh [<package> <package>]`
#
# Two package suites over ONE tree's .avra-cache at once, from a cold cache:
# both must pass. Objects a build links are named by content, so concurrent
# builds share a file only when they would write the same bytes; this is the
# run that witnesses it. Two heavy runs by design, so it is a standalone
# witness — never a gate step and never a land step.
#
# MEMCAP names the memory-cap wrapper each half runs under (cap 4000 MB).
set -u

memcap="${MEMCAP:?MEMCAP must name the memory-cap wrapper, memcap.sh}"
first="${1:-packages/std-avrac}"
second="${2:-packages/cli}"
tree="$(cd "$(dirname "$0")/.." && pwd)"
logs="$(mktemp -d "${TMPDIR:-/tmp}/avra-witness-parallel.XXXXXX")"

export LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}"
AVRA_WATCH_HELD=1
export AVRA_WATCH_HELD

cd "$tree" || exit 1

# A cold cache is what makes both halves build the same objects at once.
mkdir -p "$logs/caches-aside"
find . -name .avra-cache -type d -prune | while read -r c; do
    mv "$c" "$logs/caches-aside/$(echo "${c#./}" | tr / _)"
done

half() {
    sh "$memcap" 4000 build/avra test "$1" > "$2" 2>&1
    echo $? > "$2.exit"
}

half "$first" "$logs/first.log" &
half "$second" "$logs/second.log" &
wait

report() {
    printf '%s: exit %s | %s | %s\n' "$1" "$(cat "$2.exit")" \
        "$(grep 'tests passed' "$2" | tail -1)" \
        "$(grep 'memcap: peak' "$2" | tail -1)"
}

report "$first" "$logs/first.log"
report "$second" "$logs/second.log"
echo "logs: $logs"

[ "$(cat "$logs/first.log.exit")" = 0 ] && [ "$(cat "$logs/second.log.exit")" = 0 ]
