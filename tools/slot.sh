#!/bin/sh
# A COUNTING BUILD-CONCURRENCY LIMITER: `sh tools/slot.sh [<n>] <command…>`
# runs <command…> once one of <n> slots is free, waiting and printing
# while every slot stays taken. Slots are lock DIRECTORIES under
# /tmp/avra-slots — `mkdir` is one atomic syscall, so acquiring one
# races nobody, machine-wide, across every worktree and session.
#
# A slot's holder writes its own pid inside it. A slot whose pid is no
# longer a running process is nobody's — the same law watch.sh's lock
# holds for its own directory — and the next taker reclaims it before
# trying the next slot, rather than waiting out a crashed holder
# forever.
#
#   sh tools/slot.sh [<n>] <command> [args...]
#
# n defaults to 3 when the first argument is not itself a number, so
# `sh tools/slot.sh make gate` and `sh tools/slot.sh 2 make gate` both
# read as intended. Exit status is the command's own.
set -u

base="${AVRA_SLOTS_DIR:-/tmp/avra-slots}"
mkdir -p "$base" 2>/dev/null

n=3
case "${1:-}" in
    ''|*[!0-9]*) ;;
    *) n="$1"; shift ;;
esac

if [ "$#" -eq 0 ]; then
    echo "usage: sh tools/slot.sh [<n>] <command> [args...]" >&2
    exit 2
fi

slot=""

# One pass over every slot: take the first free one, reclaiming a
# stale one (its pid is dead) on the way rather than skipping past it.
try_slots() {
    i=0
    while [ "$i" -lt "$n" ]; do
        d="$base/slot-$i"
        if mkdir "$d" 2>/dev/null; then
            echo $$ > "$d/pid" 2>/dev/null
            slot="$d"
            return 0
        fi
        pid="$(cat "$d/pid" 2>/dev/null)"
        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            rm -rf "$d"
            if mkdir "$d" 2>/dev/null; then
                echo $$ > "$d/pid" 2>/dev/null
                slot="$d"
                return 0
            fi
        fi
        i=$((i + 1))
    done
    return 1
}

release() { [ -n "$slot" ] && rm -rf "$slot" 2>/dev/null; }
trap release EXIT INT TERM

waited=0
while ! try_slots; do
    if [ "$waited" -eq 0 ]; then
        echo "slot: all $n slot(s) busy under $base — waiting" >&2
    fi
    waited=1
    sleep 0.5
done

"$@"
status=$?
exit "$status"
