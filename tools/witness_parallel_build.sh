#!/bin/sh
# `MEMCAP=<memcap.sh> sh tools/witness_parallel_build.sh [<package> <package>]`
#
# THREE claims about concurrent runs over ONE tree, each a run of its own:
#
#   1. Two package suites over the .avra-cache at once, from a cold cache: both
#      must pass. Objects a build links are named by content, so concurrent
#      builds share a file only when they would write the same bytes.
#   2. The SAME package twice at once, cold: both must pass, since both write
#      one `<package>/build/suite`.
#   3. That shared output is never seen unfinished. A binary is staged beside
#      its path and renamed on, so a reader of `<package>/build/suite` meets
#      the old file or the new one, whole. A poller samples the file's mode and
#      size in one `stat` while the package's suite is run over and over warm
#      (the store places its kept binary each time); a sample that finds it
#      missing, not executable, or of another size than the kept one is a
#      failure. A poller that read nothing is no witness: it must have sampled.
#
# Heavy runs by design, so it is a standalone witness — never a gate step and
# never a land step.
#
# MEMCAP names the memory-cap wrapper each run goes under (cap 4000 MB).
# PUBLISH_PACKAGE (default packages/std-text) and PUBLISH_ROUNDS (default 6,
# 0 skips claims 2 and 3) name the small package they run.
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

status=0
[ "$(cat "$logs/first.log.exit")" = 0 ] && [ "$(cat "$logs/second.log.exit")" = 0 ] || status=1

same="${PUBLISH_PACKAGE:-packages/std-text}"
rounds="${PUBLISH_ROUNDS:-6}"

# The mode and size of one path, from ONE stat so the two cannot disagree.
sample() {
    if stat -c '%a %s' / > /dev/null 2>&1; then stat -c '%a %s' "$1" 2>/dev/null
    else stat -f '%Lp %z' "$1" 2>/dev/null; fi
}

# Samples $1 until $3.stop exists; writes "reads gone noexec wrong_size" to $3.
poll() {
    bin="$1"; want="$2"; out="$3"
    reads=0; gone=0; noexec=0; wrong=0
    while [ ! -f "$out.stop" ]; do
        s="$(sample "$bin")"
        reads=$((reads + 1))
        if [ -z "$s" ]; then gone=$((gone + 1)); continue; fi
        case "${s% *}" in *[1357]*) ;; *) noexec=$((noexec + 1)) ;; esac
        [ "${s#* }" = "$want" ] || wrong=$((wrong + 1))
    done
    echo "$reads $gone $noexec $wrong" > "$out"
}

if [ "$rounds" -gt 0 ]; then
    find . -name .avra-cache -type d -prune | while read -r c; do
        mv "$c" "$logs/caches-aside/same_$(echo "${c#./}" | tr / _)"
    done
    half "$same" "$logs/same_a.log" &
    half "$same" "$logs/same_b.log" &
    wait
    report "$same (a)" "$logs/same_a.log"
    report "$same (b)" "$logs/same_b.log"
    [ "$(cat "$logs/same_a.log.exit")" = 0 ] && [ "$(cat "$logs/same_b.log.exit")" = 0 ] || status=1

    bin="$same/build/suite"
    want="$(sample "$bin" | cut -d' ' -f2)"
    poll "$bin" "$want" "$logs/poll" &
    poller=$!
    r=1
    while [ "$r" -le "$rounds" ]; do
        half "$same" "$logs/warm_$r.log"
        [ "$(cat "$logs/warm_$r.log.exit")" = 0 ] || status=1
        r=$((r + 1))
    done
    touch "$logs/poll.stop"
    wait "$poller"
    set -- $(cat "$logs/poll")
    printf 'published %s: %s samples, %s missing, %s not executable, %s of another size\n' "$bin" "$1" "$2" "$3" "$4"
    [ "$1" -ge 50 ] && [ "$2" = 0 ] && [ "$3" = 0 ] && [ "$4" = 0 ] || status=1
fi

echo "logs: $logs"
exit "$status"
