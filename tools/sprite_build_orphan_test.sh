#!/bin/sh
# A LIVE FIXTURE for tools/sprite-build.sh: killing the local driver
# leaves no remote process. Runs against one real Sprite, with nothing
# heavier than `sleep` there.
#
#   sh tools/sprite_build_orphan_test.sh <sprite>
#
# TERM: the driver's own trap stops the remote group. KILL: no trap
# runs, so the next sprite-build to reach the Sprite stops it.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
sb="${SB_UNDER_TEST:-$here/sprite-build.sh}"
s="${1:?usage: sprite_build_orphan_test.sh <sprite>}"
tree="$(cd "$here/.." && pwd)"
tag=$$
total=0
failed=0
ok() { total=$((total + 1)); echo "ok    $1"; }
bad() { total=$((total + 1)); failed=$((failed + 1)); echo "FAIL  $1"; }

# How many remote processes run `sleep <n>`.
remote_count() { timeout -k 1 30 sprite -s "$s" exec --no-port-forward -- sh -c "pgrep -fc '^sleep $1\$' || :" 2>/dev/null | tr -d '[:space:]'; }
# Waits up to $2 seconds for `remote_count $1` to equal $3.
await() {
    i=0
    while [ "$i" -lt "$2" ]; do
        [ "$(remote_count "$1")" = "$3" ] && return 0
        sleep 5
        i=$((i + 5))
    done
    return 1
}
started() {
    n=$1
    sh "$sb" "$s" "$tree" -- sleep "$n" > "/tmp/avra-orphan-$tag-$n.log" 2>&1 &
    echo $!
}

t=$((40000 + tag % 10000))
p="$(started "$t")"
if await "$t" 240 1; then
    kill -TERM "$p"
    if await "$t" 90 0; then
        ok "sprite-build: a TERM of the driver stops its remote run"
    else
        bad "sprite-build: sleep $t still runs on $s after the driver's TERM"
    fi
else
    bad "sprite-build: sleep $t never started on $s (see /tmp/avra-orphan-$tag-$t.log)"
    kill -TERM "$p" 2>/dev/null
fi

k=$((t + 1))
p="$(started "$k")"
if await "$k" 240 1; then
    for c in $(pgrep -P "$p"); do kill -KILL "$c" 2>/dev/null; done
    kill -KILL "$p"
    sleep 5
    if [ "$(remote_count "$k")" = 1 ]; then
        sh "$sb" "$s" "$tree" -- true > "/tmp/avra-orphan-$tag-next.log" 2>&1
        if await "$k" 60 0 && grep -q "owner is gone" "/tmp/avra-orphan-$tag-next.log"; then
            ok "sprite-build: after a KILL, the next run on the Sprite stops the orphan"
        else
            bad "sprite-build: sleep $k survived the next run on $s"
        fi
    else
        bad "sprite-build: sleep $k was already gone — the KILL case proved nothing"
    fi
else
    bad "sprite-build: sleep $k never started on $s"
    kill -KILL "$p" 2>/dev/null
fi

echo "----------------------------------------"
echo "sprite_build_orphan_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
