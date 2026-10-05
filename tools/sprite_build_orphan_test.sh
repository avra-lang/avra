#!/bin/sh
# A LIVE FIXTURE for tools/sprite-build.sh: a run never outlives its
# driver. Runs against one real Sprite, with nothing heavier than `sleep`
# there — one of them in a session of its own, as the watchdog's child is.
#
#   sh tools/sprite_build_orphan_test.sh <sprite>
#
# TERM: the driver's own trap stops the run. KILL: no trap runs, and the
# run's keeper on the Sprite stops it once the session is gone. LIMIT:
# the keeper ends a run past its time, and the status says so.
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
remote_count() { timeout -k 1 30 sprite -s "$s" exec --no-port-forward --no-stdin -- sh -c "pgrep -fc '^sleep $1\$' || :" 2>/dev/null | tr -d '[:space:]'; }
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
    sh "$sb" "$s" "$tree" -- sh -c "setsid sleep $n & sleep $n" > "/tmp/avra-orphan-$tag-$n.log" 2>&1 &
    echo $!
}

t=$((40000 + tag % 10000))
p="$(started "$t")"
if await "$t" 240 2; then
    if sh "$sb" "$s" "$tree" -- true > "/tmp/avra-orphan-$tag-beside.log" 2>&1; then
        ok "sprite-build: a second run beside a live one from this host runs"
    else
        bad "sprite-build: a run beside a live one failed (see /tmp/avra-orphan-$tag-beside.log)"
    fi
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
if await "$k" 240 2; then
    for c in $(pgrep -P "$p"); do kill -KILL "$c" 2>/dev/null; done
    kill -KILL "$p"
    if await "$k" 120 0; then
        ok "sprite-build: after a KILL of the driver, the Sprite's keeper stops the run"
    else
        bad "sprite-build: sleep $k survived its driver's KILL on $s"
    fi
else
    bad "sprite-build: sleep $k never started on $s"
    kill -KILL "$p" 2>/dev/null
fi

l=$((t + 2))
AVRA_SP_RUN_S=5 sh "$sb" "$s" "$tree" -- sleep "$l" > "/tmp/avra-orphan-$tag-limit.log" 2>&1
st=$?
if [ "$st" = 124 ] && grep -q "past its 5s limit" "/tmp/avra-orphan-$tag-limit.log" && [ "$(remote_count "$l")" = 0 ]; then
    ok "sprite-build: a run past its limit is stopped, with 124 and the reason"
else
    bad "sprite-build: the limit answered $st (see /tmp/avra-orphan-$tag-limit.log)"
fi

echo "----------------------------------------"
echo "sprite_build_orphan_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
