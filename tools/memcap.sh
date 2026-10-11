#!/bin/sh
# Run a command with a resident-memory ceiling over its whole process tree.
# Polls every second; past the cap the tree is killed and the exit is 137.
# Usage: sh memcap.sh <cap-MB> <command> [args...]
# Default cap for a compiler build or suite: 4000 MB (a healthy one peaks ~2 GB).
#
# THE COMMAND IS A PROCESS-GROUP LEADER, WITH OR WITHOUT A TTY: `setsid`
# gives a background job its own pgid, equal to its own pid, that every
# descendant inherits — job control is the fallback for macOS (no `setsid`).
# Membership is one `ps` column, never a ppid chain. A ppid goes stale the
# instant a parent dies and is reparented away; once that freed pid is
# reused by an unrelated process elsewhere on a loaded machine, a
# ppid-chain walk attributes the reused pid's whole subtree to the wrong
# root. A pgid does not go stale this way. A shell that cannot take a tty
# answers `set -m` with "job control turned off" and leaves the job in its
# caller's group, so the pgid filter matches nothing and the cap never
# fires — the fallback's stderr is shut for that reason.
#
# AVRA_WATCH_HELD IS SET BEFORE THE COMMAND RUNS, unconditionally —
# tools/watch.sh's own name for "do not fork a nested watch.sh", read
# by the `./avra` shim and by watch.sh's own entry check. A guarded
# command that itself runs a heavy `./avra` step (`make seed`'s
# `./avra emit packages/cli`, for one) would otherwise hand that step
# to a NESTED watch.sh, whose own `set -m` mints a second process
# group this cap's pgid filter cannot see — a real cost going
# uncounted, the same blindness as the reported bug but in the other
# direction. The var suppresses a nested WATCHDOG, never a nested CAP,
# so memcap never reads it to excuse its own loop.
tree_pids() {
    awk -v root="$1" '$2 == root { print $1 }'
}
tree_rss() {
    ps -axo pid=,pgid=,rss= | awk -v root="$1" '$2 == root { s += $3 } END { print int(s/1024) }'
}
kill_tree() {
    ps -axo pid=,pgid= | tree_pids "$1" | xargs kill -9 2>/dev/null
}
# THE GUARDED COMMAND'S GROUP, ALWAYS ITS OWN. `setsid` is preferred;
# job control is the fallback for macOS, and its stderr is shut because
# dash without a tty answers `set -m` with "can't access tty; job control
# turned off" — a line a caller's output diff would read as content.
if command -v setsid >/dev/null 2>&1; then
    leader() { setsid "$@" & }
else
    set -m 2>/dev/null
    leader() { "$@" & }
fi
if [ "$1" = "--self-test" ]; then
    # A REUSED pid IS A DECOY'S ppid field STILL NAMING A NUMBER THAT
    # NOW BELONGS TO A LIVE TREE MEMBER — proven by construction, never
    # by winning a real race. 501 is a genuine child of root 500; the
    # decoy at 777 is unrelated, in an unrelated group, with a ppid
    # that coincides with 501 and an rss that dwarfs the real tree's.
    snapshot="500 500 500 1024
501 500 500 2048
777 501 9999 999999"
    got=$(printf '%s\n' "$snapshot" | awk '{print $1, $3}' | tree_pids 500 | sort -n | tr '\n' ' ')
    if [ "$got" != "500 501 " ]; then
        echo "memcap: self-test: wanted pids '500 501 ', got '$got'"
        exit 1
    fi
    rss=$(printf '%s\n' "$snapshot" | awk '{print $1, $3, $4}' | awk -v root=500 '$2 == root { s += $3 } END { print int(s/1024) }')
    if [ "$rss" != 3 ]; then
        echo "memcap: self-test: wanted 3 MB, the decoy's rss leaked in as $rss MB"
        exit 1
    fi
    # A CAP KEYED ON A pgid NEEDS THE GUARDED TREE TO HAVE ONE. A leader
    # with a grandchild proves the group exists, where a refused `set -m`
    # would leave every process in the caller's group and tree_rss would
    # count none of them.
    leader sh -c 'sleep 30 & wait' >/dev/null 2>&1
    lead=$!
    i=0; n=0
    while [ $i -lt 40 ]; do
        n=$(ps -axo pid=,pgid= | tree_pids "$lead" | wc -l | tr -d ' ')
        [ "$n" -ge 2 ] && break
        sleep 0.25; i=$((i + 1))
    done
    if [ "$n" -lt 2 ]; then
        echo "memcap: self-test: the guarded tree has no process group of its own (pgid $lead holds $n pid(s))"
        kill_tree "$lead"; kill -9 "$lead" 2>/dev/null
        exit 1
    fi
    kill_tree "$lead"
    echo "memcap: self-test passed — 2 fixtures"
    exit 0
fi
cap_mb="$1"; shift
AVRA_WATCH_HELD=$$
export AVRA_WATCH_HELD
leader "$@"
root=$!
peak=0
while kill -0 "$root" 2>/dev/null; do
    mb=$(tree_rss "$root")
    [ "$mb" -gt "$peak" ] && peak=$mb
    if [ "$mb" -gt "$cap_mb" ]; then
        echo "memcap: KILLED at ${mb} MB (cap ${cap_mb} MB): $*" >&2
        kill_tree "$root"
        wait "$root" 2>/dev/null
        exit 137
    fi
    sleep 1
done
wait "$root"
st=$?
echo "memcap: peak ${peak} MB, exit $st: $*" >&2
exit $st
