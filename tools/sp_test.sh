#!/bin/sh
# FIXTURES FOR tools/sp's leases, queue, waits and interrupts — never a
# real Sprite: AVRA_SP_BUILD stands in for sprite-build.sh,
# AVRA_SP_LOAD_PROBE for the probe, AVRA_SP_WAKER for the waker, and
# AVRA_SP_SLOTS keeps every lease and queue file under this run's scratch.
#
# `sh tools/sp_test.sh` prints a summary; a non-zero exit is a failure.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
sp="${SP_UNDER_TEST:-$here/sp}"
scratch=$(mktemp -d "${TMPDIR:-/tmp}/avra-sp-test.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
trap 'exit 130' INT TERM

total=0
failed=0
ok() { total=$((total + 1)); echo "ok    $1"; }
bad() { total=$((total + 1)); failed=$((failed + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && sed 's/^/      | /' "$2" 2>/dev/null; }
check() { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3 (got '$1', wanted '$2')" "${4:-}"; fi; }

# A run logs "<sprite> begin|end <epoch>" and "<sprite> term" when
# stopped; it lasts RUN_S seconds, exits RUN_ST, and on the Sprites in
# UNREACHED or DROPPED says so in the verdict file the way sprite-build does.
cat > "$scratch/build.sh" <<'STUB'
#!/bin/sh
s=$1
trap 'echo "$s term" >> "$RUNS"; exit 143' TERM
echo "$s begin $(date +%s)" >> "$RUNS"
case " ${UNREACHED:-} " in *" $s "*) echo unreached > "$AVRA_SB_VERDICT"; exit 3 ;; esac
case " ${DROPPED:-} " in *" $s "*)
    n=$(grep -c "^$s begin" "$RUNS")
    [ "$n" -gt "${DROPS:-99}" ] || { echo dropped > "$AVRA_SB_VERDICT"; exit 1; } ;;
esac
sleep "${RUN_S:-0}" &
wait $!
echo "$s end $(date +%s)" >> "$RUNS"
exit "${RUN_ST:-0}"
STUB
# A probe logs its Sprite; the names in ASLEEP do not answer, the names
# in FULL have no memory to give, X is idler than anyone.
cat > "$scratch/load.sh" <<'STUB'
#!/bin/sh
echo "$1" >> "$PROBES"
case " ${ASLEEP:-} " in *" $1 "*) exit 1 ;; esac
case " ${FULL:-} " in *" $1 "*) echo "0.10 8 100"; exit 0 ;; esac
[ "$1" = X ] && echo "0.01 8 7000" || echo "0.50 8 7000"
STUB
printf '#!/bin/sh\necho "$1" >> "$WAKES"\n' > "$scratch/waker.sh"
chmod +x "$scratch"/*.sh
export AVRA_SP_BUILD="$scratch/build.sh" AVRA_SP_LOAD_PROBE="$scratch/load.sh" AVRA_SP_WAKER="$scratch/waker.sh"
export AVRA_SP_POLL_S=1
unset AVRA_SP_RANKED AVRA_SP_REPORT AVRA_SPRITES RUN_S RUN_ST UNREACHED DROPPED DROPS ASLEEP FULL

fresh() {
    export AVRA_SP_SLOTS="$scratch/$1/slots" RUNS="$scratch/$1/runs" PROBES="$scratch/$1/probes" WAKES="$scratch/$1/wakes"
    mkdir -p "$AVRA_SP_SLOTS/.queue"
    : > "$RUNS"; : > "$PROBES"; : > "$WAKES"
}
born() { LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ' '_'; }
# A lease held by pid $2, and a queue entry ahead of everyone.
held() { mkdir -p "$1"; echo "$2" > "$1/pid"; echo "$2 ${3:-$(born "$2")}" > "$1/owner"; }
queued() { printf '%s\n%s\n' "$1" "$2" > "$AVRA_SP_SLOTS/.queue/1000000000-$1-1"; }
count() { grep -c "$1" "$2" 2>/dev/null; }
leases() { find "$AVRA_SP_SLOTS" -mindepth 2 -maxdepth 2 \( -name 'slot-*' -o -name 'tree-*' \) | wc -l | tr -d ' '; }
# Waits up to $1 seconds for `$2..` to succeed.
until_() { n=$(($1 * 5)); shift; while [ "$n" -gt 0 ]; do "$@" >/dev/null 2>&1 && return 0; sleep 0.2; n=$((n - 1)); done; return 1; }
waiting() { [ "$(find "$AVRA_SP_SLOTS/.queue" -type f ! -name '.*' | wc -l)" -ge "$1" ]; }
begun() { [ "$(count ' begin' "$RUNS")" -ge "$1" ]; }
a_pid_that_is_gone() { sh -c 'exit 0' & wait $!; echo $!; }

# ══ STATUS: sp answers the command's own status ═══════════════════════
fresh status
RUN_ST=7 AVRA_SPRITES=A sh "$sp" true 2>/dev/null
check "$?" 7 "sp: the command's status is sp's"
check "$(leases)" 0 "sp: a finished run holds no lease"

# ══ A DEAD OWNER'S LEASE: reaped by the next caller ═══════════════════
fresh deadlease
gone=$(a_pid_that_is_gone)
held "$AVRA_SP_SLOTS/A/slot-1" "$gone" "Thu_Jan__1_00:00:00_1970"
held "$AVRA_SP_SLOTS/A/slot-2" "$gone" "Thu_Jan__1_00:00:00_1970"
held "$AVRA_SP_SLOTS/A/tree-$(basename "$(cd "$here/.." && pwd)")" "$gone" "Thu_Jan__1_00:00:00_1970"
held "$AVRA_SP_SLOTS/B/tree-elsewhere" "$gone" "Thu_Jan__1_00:00:00_1970"
AVRA_SPRITES=A sh "$sp" true 2>/dev/null
check "$? $(count '^A end' "$RUNS") $(leases)" "0 1 0" "sp: leases whose owner is gone are reaped, everywhere, and block nobody"

# ══ A REUSED PID: alive, but not the owner that took the lease ════════
fresh reuse
held "$AVRA_SP_SLOTS/A/slot-1" $$ "Thu_Jan__1_00:00:00_1970"
slot=$(AVRA_SP_JOBS_PER_SPRITE=1 sh "$sp" --lease 1 $$ A)
check "$slot" "$AVRA_SP_SLOTS/A/slot-1" "sp: a lease whose pid lives under another birth is not held"

# ══ A PID-ONLY LEASE: judged by the pid alone ═════════════════════════
fresh legacy
mkdir -p "$AVRA_SP_SLOTS/A/slot-1"; echo $$ > "$AVRA_SP_SLOTS/A/slot-1/pid"
slot=$(sh "$sp" --lease 1 $$ A)
check "$?:$slot" "1:" "sp: a lease naming only a live pid is held"

# ══ ONE SLOT, ONE HOLDER: twelve takers at once ═══════════════════════
fresh race
i=0
while [ "$i" -lt 12 ]; do
    i=$((i + 1))
    (sh "$sp" --lease 1 $$ A > "$scratch/race/won.$i" 2>/dev/null) &
done
wait
check "$(cat "$scratch"/race/won.* | grep -c slot-1)" 1 "sp: of twelve callers at once, one holds the slot"

# ══ ONE SLOT, ONE RUN: two worktrees never overlap on it ══════════════
fresh serial
mkdir -p "$scratch/serial/t1" "$scratch/serial/t2"
RUN_S=2 AVRA_SP_JOBS_PER_SPRITE=1 AVRA_SP_TREE="$scratch/serial/t1" AVRA_SPRITES=A sh "$sp" true 2>/dev/null &
RUN_S=2 AVRA_SP_JOBS_PER_SPRITE=1 AVRA_SP_TREE="$scratch/serial/t2" AVRA_SPRITES=A sh "$sp" true 2>/dev/null &
wait
check "$(awk '{ print $2 }' "$RUNS" | tr '\n' ' ')" "begin end begin end " "sp: the second run begins when the first has ended" "$RUNS"

# ══ ONE TREE, ONE RUN PER SPRITE: the same worktree takes another ═════
fresh tree
RUN_S=2 AVRA_SPRITES="A B" sh "$sp" true 2>/dev/null &
RUN_S=2 AVRA_SPRITES="A B" sh "$sp" true 2>/dev/null &
wait
check "$(awk '$2 == "begin" { print $1 }' "$RUNS" | sort | tr '\n' ' ')" "A B " "sp: one worktree's two runs stand on two Sprites" "$RUNS"

# ══ A WAITER GIVES UP: no slot within its bound ═══════════════════════
fresh timeout
sleep 60 &
holder=$!
held "$AVRA_SP_SLOTS/A/slot-1" "$holder"
t=$(date +%s)
AVRA_SP_WAIT_S=3 AVRA_SP_JOBS_PER_SPRITE=1 AVRA_SPRITES=A sh "$sp" true 2> "$scratch/timeout/err"
st=$?
took=$(($(date +%s) - t))
kill "$holder" 2>/dev/null
[ "$took" -le 10 ] && took=bounded
check "$st $took $(count 'no Sprite slot in 3s' "$scratch/timeout/err") $(count . "$RUNS")" "75 bounded 1 0" "sp: a waiter leaves with 75 and the reason once its bound passes" "$scratch/timeout/err"
check "$(find "$AVRA_SP_SLOTS/.queue" -type f | wc -l | tr -d ' ')" 0 "sp: a waiter that gave up leaves no queue entry"

# ══ REAP: a dead waiter's queue entry is removed on sight ═════════════
fresh reap
gone=$(a_pid_that_is_gone)
queued "$gone" "A"
AVRA_SPRITES=A sh "$sp" true 2>/dev/null
check "$? $(count '^A end' "$RUNS") $(find "$AVRA_SP_SLOTS/.queue" -type f | wc -l | tr -d ' ')" "0 1 0" "sp: a dead waiter's queue entry is reaped, and blocks nobody"

# ══ FIFO PER SPRITE: a newcomer never jumps a live waiter for its Sprite
fresh fifo
sleep 60 &
waiter=$!
queued "$waiter" "B"
AVRA_SPRITES=B sh "$sp" true 2>/dev/null &
job=$!
until_ 10 waiting 2 && seen=queued || seen=
sleep 2
early=$(count '^B begin' "$RUNS")
kill "$waiter" 2>/dev/null
wait "$job"
check "$seen $early $(count '^B end' "$RUNS")" "queued 0 1" "sp: a newcomer queues behind the live waiter for its Sprite, then runs" "$RUNS"

# ══ NO HEAD-OF-LINE BLOCKING: a waiter pinned to A never holds up B ═══
fresh hol
sleep 60 &
pinned=$!
for n in 1 2 3; do held "$AVRA_SP_SLOTS/A/slot-$n" "$pinned"; done
queued "$pinned" "A"
AVRA_SP_WAIT_S=8 AVRA_SPRITES="A B" sh "$sp" true 2>/dev/null
st=$?
kill "$pinned" 2>/dev/null
check "$st $(count '^B end' "$RUNS")" "0 1" "sp: a waiter pinned to a busy Sprite blocks nobody who can use another"

# ══ ASLEEP: left out, woken, never waited on while another has room ═══
fresh asleep
export ASLEEP=X
AVRA_SPRITES="X Y" sh "$sp" true 2>/dev/null
AVRA_SPRITES="X Y" sh "$sp" true 2>/dev/null
check "$(count '^X$' "$PROBES") $(count '^X$' "$WAKES") $(count '^Y end' "$RUNS")" "1 1 2" "sp: a Sprite that missed its probe is left out and woken once, and the runs go elsewhere"
slot="$(sh "$sp" --lease 2 $$ X Y)"
check "$slot" "$AVRA_SP_SLOTS/Y/slot-1" "sp: a lease skips a Sprite left out"
AVRA_SP_DEAD_S=0 AVRA_SPRITES="X Y" sh "$sp" true 2>/dev/null
check "$(count '^X$' "$PROBES")" 2 "sp: past the window the Sprite is probed again"
unset ASLEEP

# ══ WAKING: a Sprite that answers later is taken by a run still waiting
fresh waking
export ASLEEP=X
(sleep 3; : > "$scratch/waking/up") &
cat > "$scratch/waking/load.sh" <<STUB
#!/bin/sh
[ -e "$scratch/waking/up" ] && echo "0.1 8 7000" || exit 1
STUB
chmod +x "$scratch/waking/load.sh"
AVRA_SP_LOAD_PROBE="$scratch/waking/load.sh" AVRA_SP_DEAD_S=1 AVRA_SP_WAIT_S=15 AVRA_SPRITES=X sh "$sp" true 2>/dev/null
check "$? $(count '^X end' "$RUNS")" "0 1" "sp: a run waits out a waking Sprite and takes it when it answers"
wait
unset ASLEEP

# ══ MEMORY: a Sprite with none to give takes no run ═══════════════════
fresh full
FULL=X AVRA_SPRITES="X Y" sh "$sp" true 2>/dev/null
check "$(count '^X' "$RUNS") $(count '^Y end' "$RUNS")" "0 1" "sp: a Sprite under its memory floor is passed over"

# ══ UNREACHED: the command moves to another Sprite ════════════════════
fresh unreached
UNREACHED=X RUN_ST=5 AVRA_SPRITES="X Y" sh "$sp" true 2> "$scratch/unreached/err"
check "$? $(count '^X begin' "$RUNS") $(count '^Y end' "$RUNS") $(count '^X$' "$WAKES")" "5 1 1 1" "sp: a Sprite that fails before the command began is left out, and the command runs on another" "$scratch/unreached/err"

# ══ DROPPED: a run cut off is run once more, and only once ════════════
fresh dropped
DROPPED=A DROPS=1 AVRA_SPRITES=A sh "$sp" true 2>/dev/null
check "$? $(count '^A begin' "$RUNS") $(count '^A end' "$RUNS")" "0 2 1" "sp: a run whose connection dropped is run again"
fresh dropped2
DROPPED=A AVRA_SPRITES=A sh "$sp" true 2>/dev/null
check "$? $(count '^A begin' "$RUNS")" "1 2" "sp: a run that drops twice fails with its status"

# ══ INTERRUPT: the run is stopped and nothing is left held ════════════
# No INT here: a shell starts its background jobs with INT ignored, and
# an ignored signal cannot be trapped by the job.
for sig in TERM HUP; do
    fresh "sig$sig"
    RUN_S=30 AVRA_SPRITES=A sh "$sp" true 2>/dev/null &
    job=$!
    until_ 10 begun 1
    kill -"$sig" "$job"
    wait "$job"
    st=$?
    check "$st $(count '^A term' "$RUNS") $(count '^A end' "$RUNS") $(leases)" "$((128 + $(kill -l "$sig"))) 1 0 0" "sp: a $sig stops the run and frees its leases" "$RUNS"
done
fresh sigwait
sleep 60 &
holder=$!
held "$AVRA_SP_SLOTS/A/slot-1" "$holder"
AVRA_SP_JOBS_PER_SPRITE=1 AVRA_SPRITES=A sh "$sp" true 2>/dev/null &
job=$!
until_ 10 waiting 1
kill -TERM "$job"
wait "$job"
st=$?
kill "$holder" 2>/dev/null
check "$st $(find "$AVRA_SP_SLOTS/.queue" -type f | wc -l | tr -d ' ')" "143 0" "sp: a TERM while waiting leaves at once, and leaves no queue entry"

# ══ -p: every command on its own Sprite, one failure fails the batch ══
fresh batch
RUN_S=1 AVRA_SPRITES="A B C" sh "$sp" -p "true 1" "true 2" "true 3" > "$scratch/batch/out" 2>&1
check "$? $(awk '$2 == "begin" { print $1 }' "$RUNS" | sort | tr '\n' ' ')" "0 A B C " "sp -p: three commands stand on three Sprites" "$scratch/batch/out"
check "$(grep -cE '^[123] +[ABC] +[0-9]+ +0 +true [123]$' "$scratch/batch/out")" 3 "sp -p: the table names each command's Sprite, seconds and status" "$scratch/batch/out"
fresh batchfail
UNREACHED="A B C" AVRA_SP_WAIT_S=2 AVRA_SPRITES="A B C" sh "$sp" -p "true 1" "true 2" > "$scratch/batchfail/out" 2>&1
check "$?" 1 "sp -p: a command that could not run fails the batch" "$scratch/batchfail/out"
fresh batchterm
RUN_S=30 AVRA_SPRITES="A B" sh "$sp" -p "true 1" "true 2" > "$scratch/batchterm/out" 2>&1 &
job=$!
until_ 10 begun 2
kill -TERM "$job"
wait "$job"
check "$? $(count ' term' "$RUNS") $(leases)" "143 2 0" "sp -p: a TERM stops every run and frees every lease" "$RUNS"

# ══ LEASE: behind a queued waiter's Sprite, the lease goes elsewhere ══
fresh lease
sleep 60 &
w=$!
queued "$w" "P"
slot="$(sh "$sp" --lease 2 $$ P Q)"
kill "$w" 2>/dev/null
check "$slot" "$AVRA_SP_SLOTS/Q/slot-1" "sp: a lease leaves a queued waiter's Sprite to that waiter"

echo "----------------------------------------"
echo "sp_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
