#!/bin/sh
# THE WATCHDOG AND THE BUILD LOCK: `sh tools/watch.sh <cap_mb> <cmd…>`
# runs one heavy step — a gate, a suite, a whole-package check —
# and polls the RSS of it and every descendant twice a second,
# killing the whole tree past the cap and printing the peak. The
# machine is shared with a loaded desktop; a step that grows past
# its cap is a defect, and a wreck that names its peak beats a
# stall the kernel panics on.
#
# ONE HEAVY STEP AT A TIME, MACHINE-WIDE: the lock is a directory
# in /tmp, so every worktree and every session queues on the same
# one. A waiting step says who holds it. The lock dies with the
# step, however the step dies.
# Exit status is the command's, or 137 when the cap fired.
cap_mb="$1"; shift
lock=/tmp/avra-build.lock
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
"$@" &
pid=$!
peak=0
fired=0
tree_rss() {
    ps -eo pid=,ppid=,rss= | awk -v root="$1" '
        { pp[$1]=$2; rss[$1]=$3 }
        END {
            n=0; q[n++]=root; s=0
            for (i=0; i<n; i++) { s+=rss[q[i]]; for (p in pp) if (pp[p]==q[i]) q[n++]=p }
            print int(s/1024)
        }'
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
    rss=$(tree_rss "$pid")
    [ -z "$rss" ] && rss=0
    [ "$rss" -gt "$peak" ] && peak=$rss
    if [ "$rss" -gt "$cap_mb" ]; then
        fired=1
        tree_kill "$pid"
        break
    fi
    sleep 0.5
done
wait "$pid" 2>/dev/null
status=$?
[ "$fired" -eq 1 ] && status=137
echo "watch: peak ${peak} MB, status ${status}" >&2
exit $status
