#!/bin/sh
# Run a command with a resident-memory ceiling over its whole process tree.
# Polls every second; past the cap the tree is killed and the exit is 137.
# Usage: sh memcap.sh <cap-MB> <command> [args...]
# Default cap for a compiler build or suite: 4000 MB (a healthy one peaks ~2 GB).
cap_mb="$1"; shift
"$@" &
root=$!
tree_rss() {
    # every descendant of $root, summed in MB
    ps -axo pid=,ppid=,rss= | awk -v r="$root" '
        { pp[$1]=$2; rs[$1]=$3 }
        END { for (p in pp) { q=p; while (q != "" && q != 1 && q != 0) { if (q == r) { s += rs[p]; break } q = pp[q] } } print int(s/1024) }'
}
kill_tree() {
    pids=$(ps -axo pid=,ppid= | awk -v r="$root" '{ pp[$1]=$2 } END { for (p in pp) { q=p; while (q != "" && q != 1 && q != 0) { if (q == r) { print p; break } q = pp[q] } } }')
    kill -9 $pids 2>/dev/null
}
peak=0
while kill -0 "$root" 2>/dev/null; do
    mb=$(tree_rss)
    [ "$mb" -gt "$peak" ] && peak=$mb
    if [ "$mb" -gt "$cap_mb" ]; then
        echo "memcap: KILLED at ${mb} MB (cap ${cap_mb} MB): $*" >&2
        kill_tree
        wait "$root" 2>/dev/null
        exit 137
    fi
    sleep 1
done
wait "$root"
st=$?
echo "memcap: peak ${peak} MB, exit $st: $*" >&2
exit $st
