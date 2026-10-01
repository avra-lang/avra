#!/bin/sh
# FIXTURES FOR tools/sp's queue, leases and liveness cache — never a real
# Sprite: AVRA_SP_BUILD stands in for sprite-build.sh, AVRA_SP_ALIVE for
# the liveness probe, AVRA_LAND_SPRITE_PROBE for the load probe, and
# AVRA_SP_SLOTS keeps every slot and queue file under this run's scratch.
#
# `sh tools/sp_test.sh` prints a summary; a non-zero exit is a failure.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
sp="${SP_UNDER_TEST:-$here/sp}"
scratch="/tmp/avra-sp-test-$$"
mkdir -p "$scratch"
trap 'rm -rf "$scratch"' EXIT INT TERM

total=0
failed=0
ok() { total=$((total + 1)); echo "ok    $1"; }
bad() { total=$((total + 1)); failed=$((failed + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && sed 's/^/      | /' "$2" 2>/dev/null; }

# Every run logs "<sprite> <epoch>"; every liveness probe logs its Sprite
# and fails for the names in DEAD_SPRITES; X answers idler than anyone.
cat > "$scratch/build.sh" <<'STUB'
#!/bin/sh
echo "$1 $(date +%s)" >> "$RUNS"
STUB
cat > "$scratch/alive.sh" <<'STUB'
#!/bin/sh
echo "$1" >> "$PROBES"
case " ${DEAD_SPRITES:-} " in *" $1 "*) exit 1 ;; esac
STUB
cat > "$scratch/load.sh" <<'STUB'
#!/bin/sh
[ "$1" = X ] && echo "0.01 8 7000" || echo "0.50 8 7000"
STUB
chmod +x "$scratch"/*.sh
export AVRA_SP_BUILD="$scratch/build.sh" AVRA_SP_ALIVE="$scratch/alive.sh"
export AVRA_LAND_SPRITE_PROBE="$scratch/load.sh"

fresh() {
    export AVRA_SP_SLOTS="$scratch/$1/slots" RUNS="$scratch/$1/runs" PROBES="$scratch/$1/probes"
    mkdir -p "$AVRA_SP_SLOTS/.queue"
    : > "$RUNS"
    : > "$PROBES"
}
# A queue entry ahead of everyone: its pid, then the Sprites it can use.
queued() { printf '%s\n%s\n' "$1" "$2" > "$AVRA_SP_SLOTS/.queue/1000000000-$1-1"; }

# Waits up to $1 seconds for a line starting "$2 " in RUNS, or for the
# queue to hold $3 entries; answers which came first ("ran", "queued", "").
first_of() {
    i=0
    while [ "$i" -lt "$1" ]; do
        grep -q "^$2 " "$RUNS" && { echo ran; return; }
        [ "$(ls "$AVRA_SP_SLOTS/.queue" | wc -l | tr -d ' ')" -ge "$3" ] && { echo queued; return; }
        sleep 1
        i=$((i + 1))
    done
}

# ══ REAP: a dead waiter's queue entry is removed on sight ═════════════
fresh reap
sh -c 'exit 0' &
gone=$!
wait "$gone"
queued "$gone" "A"
AVRA_SPRITES=A sh "$sp" true 2>/dev/null &
job=$!
seen="$(first_of 120 A 99)"
sh "$here/land.sh" --call kill_tree "$job" 2>/dev/null
if [ "$seen" = ran ] && [ ! -e "$AVRA_SP_SLOTS/.queue/1000000000-$gone-1" ]; then
    ok "sp: a dead waiter's queue entry is reaped, and blocks nobody"
else
    bad "sp: the dead waiter's entry still stands (first: '$seen')" "$RUNS"
fi

# ══ FIFO PER SPRITE: a newcomer never jumps a live waiter for its Sprite
fresh fifo
sleep 600 &
waiter=$!
queued "$waiter" "B"
AVRA_SPRITES=B sh "$sp" true 2>/dev/null &
job=$!
seen="$(first_of 120 B 2)"
[ "$seen" = queued ] && sleep 11
early="$(grep -c '^B ' "$RUNS")"
kill "$waiter" 2>/dev/null
[ "$(first_of 120 B 99)" = ran ] && late=1 || late=0
sh "$here/land.sh" --call kill_tree "$job" 2>/dev/null
if [ "$seen" = queued ] && [ "$early" -eq 0 ] && [ "$late" -eq 1 ]; then
    ok "sp: a newcomer queues behind the live waiter for its Sprite, then runs"
else
    bad "sp: a newcomer jumped the queue (first: '$seen', ran early: $early)" "$RUNS"
fi

# ══ NO HEAD-OF-LINE BLOCKING: a waiter pinned to A never holds up B ═══
fresh hol
sleep 600 &
pinned=$!
for n in 1 2 3; do mkdir -p "$AVRA_SP_SLOTS/A/slot-$n"; echo "$pinned" > "$AVRA_SP_SLOTS/A/slot-$n/pid"; done
queued "$pinned" "A"
AVRA_SPRITES="A B" sh "$sp" true 2>/dev/null &
job=$!
seen="$(first_of 120 B 99)"
kill "$pinned" 2>/dev/null
sh "$here/land.sh" --call kill_tree "$job" 2>/dev/null
if [ "$seen" = ran ]; then
    ok "sp: a waiter pinned to a busy Sprite blocks nobody who can use another"
else
    bad "sp: held behind a waiter for another Sprite" "$RUNS"
fi

# ══ LIVENESS CACHE: a Sprite that fails its probe is skipped by everyone
fresh dead
export DEAD_SPRITES=X
AVRA_SPRITES="X Y" sh "$sp" true 2>/dev/null
AVRA_SPRITES="X Y" sh "$sp" true 2>/dev/null
if [ "$(grep -c '^X$' "$PROBES")" -eq 1 ] && [ "$(grep -c '^Y ' "$RUNS")" -eq 2 ]; then
    ok "sp: a Sprite that failed its probe is not probed again inside the window"
else
    bad "sp: X was probed $(grep -c '^X$' "$PROBES") times over two runs" "$PROBES"
fi
slot="$(sh "$sp" --lease 2 $$ X Y)"
if [ "$slot" = "$AVRA_SP_SLOTS/Y/slot-1" ]; then
    ok "sp: a lease skips a Sprite marked dead"
else
    bad "sp: the lease answered '$slot'"
fi
AVRA_SP_DEAD_S=0 AVRA_SPRITES="X Y" sh "$sp" true 2>/dev/null
if [ "$(grep -c '^X$' "$PROBES")" -eq 2 ]; then
    ok "sp: past the window the dead mark lapses and the Sprite is probed again"
else
    bad "sp: X was probed $(grep -c '^X$' "$PROBES") times, expected 2 after the window" "$PROBES"
fi
unset DEAD_SPRITES

# ══ LEASE: behind a queued waiter's Sprite, the lease goes elsewhere ══
fresh lease
sleep 60 &
w=$!
queued "$w" "P"
slot="$(sh "$sp" --lease 2 $$ P Q)"
kill "$w" 2>/dev/null
if [ "$slot" = "$AVRA_SP_SLOTS/Q/slot-1" ]; then
    ok "sp: a lease leaves a queued waiter's Sprite to that waiter"
else
    bad "sp: the lease answered '$slot'"
fi

echo "----------------------------------------"
echo "sp_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
