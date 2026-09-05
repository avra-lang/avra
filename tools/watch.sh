#!/bin/sh
# THE WATCHDOG AND THE BUILD LOCK: `sh tools/watch.sh <cap_mb> <cmd…>`
# runs one heavy step — a gate, a suite, a whole-package check —
# and polls the footprint of it and every descendant twice a second,
# killing the whole tree past the cap and printing the peak. The
# machine is shared with a loaded desktop; a step that grows past
# its cap is a defect, and a wreck that names its peak beats a
# stall the kernel panics on.
#
# ONE HEAVY STEP AT A TIME, MACHINE-WIDE: the lock is a directory
# in /tmp, so every worktree and every session queues on the same
# one. A waiting step says who holds it. The lock dies with the
# step, however the step dies. `./avra` takes this lock ITSELF for
# any package-scale run, so no path around it exists; a step that
# already runs under the lock (AVRA_WATCH_HELD set) runs its
# children directly.
#
# THE MEMORY FLOOR: a step does not START while the machine has
# less than AVRA_MEM_FLOOR percent available (kern.memorystatus_level,
# which counts what the compressor can give back) — the belt against
# heavy work another session runs outside the lock. Two compilers
# beside a loaded desktop panicked a 16 GB machine twice.
#
# AVRA_WATCH_TRACE=1 prints each poll's per-process footprint, so a
# peak's composition can be read. A gate is ~2.4 GB honestly
# measured; the cap is 4000 by default.
# PROFILING runs under the lock too: AVRA_SAMPLE=<seconds> samples
# the step (after AVRA_SAMPLE_AFTER seconds, default 0) into
# AVRA_SAMPLE_FILE (default /tmp/avra-sample.txt). The window must
# END before the step does, or `sample` writes nothing.
# Exit status is the command's, or 137 when the cap fired.
cap_mb="$1"; shift
if [ -n "$AVRA_WATCH_HELD" ]; then
    exec "$@"
fi
lock=/tmp/avra-build.lock
floor="${AVRA_MEM_FLOOR:-20}"
until mkdir "$lock" 2>/dev/null; do
    holder=$(cat "$lock/pid" 2>/dev/null)
    if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
        rm -rf "$lock"
        continue
    fi
    echo "watch: waiting for the build lock (held by pid ${holder:-?})" >&2
    sleep 5
done
echo $$ > "$lock/pid"
trap 'rm -rf "$lock"' EXIT INT TERM
while :; do
    level=$(sysctl -n kern.memorystatus_level 2>/dev/null || echo 100)
    [ "$level" -ge "$floor" ] && break
    echo "watch: the machine has ${level}% available, under the ${floor}% floor — waiting" >&2
    sleep 5
done
AVRA_WATCH_HELD=$$
export AVRA_WATCH_HELD
"$@" &
pid=$!
if [ -n "$AVRA_SAMPLE" ]; then
    ( sleep "${AVRA_SAMPLE_AFTER:-0}"; sample "$pid" "$AVRA_SAMPLE" -file "${AVRA_SAMPLE_FILE:-/tmp/avra-sample.txt}" > "${AVRA_SAMPLE_FILE:-/tmp/avra-sample.txt}.log" 2>&1 ) &
    sampler=$!
fi
peak=0
fired=0
# The tree's PHYSICAL FOOTPRINT in MB — `footprint`'s number, which
# counts a page the compressor holds. RSS does not, and read a
# 2.4 GB compiler as 1.4 GB on a machine that then panicked.
tree_mem() {
    pids=$(ps -eo pid=,ppid= | awk -v root="$1" '
        { pp[$1]=$2 }
        END {
            n=0; q[n++]=root
            for (i=0; i<n; i++) { printf "%s ", q[i]; for (p in pp) if (pp[p]==q[i]) q[n++]=p }
        }')
    [ -n "$AVRA_WATCH_TRACE" ] && footprint $pids 2>/dev/null | awk '/\[[0-9]+\]:.*Footprint:/ { for (i=1; i<=NF; i++) if ($i=="Footprint:") printf "%s %s%s  ", $1, $(i+1), $(i+2) } END { print "" }' >&2
    # a per-process header reads `name [pid]: … Footprint: N MB`; the
    # Summary that follows several pids repeats their total
    footprint $pids 2>/dev/null | awk '
        /\[[0-9]+\]:.*Footprint:/ {
            for (i=1; i<=NF; i++) if ($i=="Footprint:") {
                v=$(i+1)+0; u=$(i+2)
                if (u=="GB") v*=1024; else if (u=="KB") v/=1024; else if (u=="B") v=0
                s+=v
            }
        }
        END { print int(s) }'
}
tree_kill() {
    ps -eo pid=,ppid= | awk -v root="$1" '
        { pp[$1]=$2 }
        END {
            n=0; q[n++]=root
            for (i=0; i<n; i++) { print q[i]; for (p in pp) if (pp[p]==q[i]) q[n++]=p }
        }' | xargs kill -9 2>/dev/null
}
while kill -0 "$pid" 2>/dev/null; do
    mem=$(tree_mem "$pid")
    [ -z "$mem" ] && mem=0
    [ "$mem" -gt "$peak" ] && peak=$mem
    if [ "$mem" -gt "$cap_mb" ]; then
        fired=1
        tree_kill "$pid"
        break
    fi
    sleep 0.5
done
wait "$pid" 2>/dev/null
status=$?
[ -n "$sampler" ] && wait "$sampler" 2>/dev/null
[ "$fired" -eq 1 ] && status=137
echo "watch: peak ${peak} MB, status ${status}" >&2
exit $status
