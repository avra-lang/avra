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
# peak's composition can be read. A gate is ~0.3 GB honestly
# measured; the cap is 4000 by default, a wreck-catcher.
# PROFILING runs under the lock too: AVRA_SAMPLE=<seconds> samples
# the step (after AVRA_SAMPLE_AFTER seconds, default 0) into
# AVRA_SAMPLE_FILE (default build/avra-sample.txt, PER-WORKTREE — a
# shared one hands you another lane's profile as your own, and a
# wrong measurement read as yours is this tree's costliest shape).
# The window must
# END before the step does, or `sample` writes nothing.
# Exit status is the command's, or 137 when the cap fired.

# THE TREE WALKERS, DEFINED BEFORE ANY TRAP OR SELF-TEST CAN CALL
# THEM: no state, safe wherever a trap needs them, and callable from
# fixture 3 below.
#
# MEMBERSHIP IS BY PROCESS GROUP, NEVER A ppid WALK. A pgid is
# assigned once and never goes stale; a ppid does, the instant a
# parent dies and is reparented away — and once that freed pid is
# reused by an unrelated process elsewhere on a loaded machine, a
# walk matching on ppid attributes the reused pid's whole subtree to
# the wrong root. `tree_pids` takes a `ps -eo pid=,pgid=` snapshot on
# stdin so a hand-built one can prove this by construction.
tree_pids() {
    awk -v root="$1" '$2 == root { print $1 }'
}
tree_mem() {
    pids=$(ps -eo pid=,pgid= | tree_pids "$1")
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
    ps -eo pid=,pgid= | tree_pids "$1" | xargs kill -9 2>/dev/null
}
# THE TRIPWIRE IS RSS, read by ps in milliseconds; the footprint —
# `footprint` walks the process's whole map, seconds on a big one —
# is read every fourth poll for the honest peak. A process once grew
# from 7 GB to 16 GB between two footprint polls.
tree_rss() {
    ps -eo pid=,pgid=,rss= | awk -v root="$1" '$2 == root { s += $3 } END { print int(s/1024) }'
}
# THE GUARDED COMMAND BECOMES A PROCESS-GROUP LEADER, WITH OR WITHOUT A
# TTY: its own pgid, equal to its own pid, is what the tree walkers
# above key on — never a ppid chain. `setsid` is preferred, because it
# gives the child a group with no terminal at all; job control is the
# fallback for macOS (no `setsid`), and its stderr is shut because dash
# without a tty answers `set -m` with "can't access tty; job control
# turned off" and leaves it off — a line a caller's output diff reads
# as content, which is how this cost cache-attacks 2/117 on a Sprite.
if command -v setsid >/dev/null 2>&1; then
    leader() { setsid "$@" & }
else
    set -m 2>/dev/null
    leader() { "$@" & }
fi

# FOUR FIXTURES. Fixtures 1 and 2 each take a LOCK OF THEIR OWN
# (AVRA_BUILD_LOCK), so a self-test never contends the real
# machine-wide queue every other session on this box is standing in.
# Fixture 1 proves a QUEUED waiter's ticket is dropped and the process
# actually exits on TERM, never just detouring through the trap and
# looping on. Fixture 2 proves a HOLDING watcher's TERM kills the
# guarded child before releasing the lock, rather than orphaning it
# unwatched. Fixture 3 takes no lock at all — it feeds `tree_pids` a
# hand-built snapshot and proves a decoy sharing a coincidental pid or
# ppid with the watched tree is never counted, by construction rather
# than by winning a real pid-reuse race. Fixture 4 needs no lock
# either: it proves the GUARDED TREE GETS A PROCESS GROUP OF ITS OWN
# with no tty, the property the memory cap and both TERM traps rest on,
# by launching a leader with a grandchild and tree-killing it.
self_test() {
    # A self-test run FROM INSIDE a held lock (`make gate` under this
    # very watchdog) inherits AVRA_WATCH_HELD, and the re-entrancy
    # check at the top of the file would exec every fixture straight
    # through with no lock, no ticket, no "waiting" line at all —
    # not a failure of the fix, a self-test that never exercised it.
    unset AVRA_WATCH_HELD
    here="$(cd "$(dirname "$0")" && pwd)"
    watch="$here/$(basename "$0")"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    lock1="$tmp/lock1"
    mkdir -p "$lock1"
    echo $$ > "$lock1/pid"
    AVRA_BUILD_LOCK="$lock1" AVRA_BUILD_SLOTS=1 sh "$watch" 4000 sleep 30 \
        > "$tmp/waiter.out" 2>&1 &
    waiter=$!
    i=0
    while [ $i -lt 40 ] && ! grep -q "busy — waiting" "$tmp/waiter.out" 2>/dev/null; do
        sleep 0.25; i=$((i + 1))
    done
    if ! grep -q "busy — waiting" "$tmp/waiter.out" 2>/dev/null; then
        echo "watch: self-test: fixture 1 never reported waiting"; kill -9 "$waiter" 2>/dev/null
        return 1
    fi
    kill -TERM "$waiter"
    i=0
    while [ $i -lt 40 ] && kill -0 "$waiter" 2>/dev/null; do sleep 0.25; i=$((i + 1)); done
    if kill -0 "$waiter" 2>/dev/null; then
        echo "watch: self-test: a QUEUED waiter ignored TERM"; kill -9 "$waiter" 2>/dev/null
        return 1
    fi
    if [ -n "$(ls "$lock1.q" 2>/dev/null)" ]; then
        echo "watch: self-test: a TERM'd waiter's ticket was not dropped"
        return 1
    fi

    lock2="$tmp/lock2"
    AVRA_BUILD_LOCK="$lock2" AVRA_BUILD_SLOTS=1 sh "$watch" 4000 sleep 30 \
        > "$tmp/holder.out" 2>&1 &
    holder=$!
    i=0
    while [ $i -lt 40 ] && [ ! -f "$lock2/pid" ]; do sleep 0.25; i=$((i + 1)); done
    if [ ! -f "$lock2/pid" ]; then
        echo "watch: self-test: fixture 2 never acquired the lock"; kill -9 "$holder" 2>/dev/null
        return 1
    fi
    child=$(ps -eo pid=,ppid=,comm= | awk -v p="$holder" '$2==p && $3=="sleep"{print $1; exit}')
    if [ -z "$child" ]; then
        echo "watch: self-test: fixture 2's guarded child was never found"; kill -9 "$holder" 2>/dev/null
        return 1
    fi
    kill -TERM "$holder"
    i=0
    while [ $i -lt 40 ] && kill -0 "$holder" 2>/dev/null; do sleep 0.25; i=$((i + 1)); done
    if kill -0 "$holder" 2>/dev/null; then
        echo "watch: self-test: a HOLDING watcher ignored TERM"; kill -9 "$holder" 2>/dev/null
        return 1
    fi
    if [ -d "$lock2" ]; then
        echo "watch: self-test: a TERM'd holder left the lock in place"
        return 1
    fi
    sleep 0.3
    if kill -0 "$child" 2>/dev/null; then
        echo "watch: self-test: a TERM'd holder orphaned its guarded child"; kill -9 "$child" 2>/dev/null
        return 1
    fi

    # A REUSED pid IS A DECOY'S ppid field STILL NAMING A NUMBER THAT
    # NOW BELONGS TO A LIVE TREE MEMBER. 501 is a genuine child of root
    # 500; the decoy at 777 is an unrelated process, in an unrelated
    # group, whose own ppid happens to equal 501 (as an exited child's
    # freed pid, reused elsewhere, would) and whose rss dwarfs the real
    # tree's. A ppid-chain walk would follow 501 straight to it; pgid
    # membership cannot, because pgid is never consulted from a stale
    # number.
    snapshot="500 500 500 1024
501 500 500 2048
777 501 9999 999999"
    got=$(printf '%s\n' "$snapshot" | awk '{print $1, $3}' | tree_pids 500 | sort -n | tr '\n' ' ')
    if [ "$got" != "500 501 " ]; then
        echo "watch: self-test: fixture 3 wanted pids '500 501 ', got '$got'"
        return 1
    fi
    rss=$(printf '%s\n' "$snapshot" | awk '{print $1, $3, $4}' | awk -v root=500 '$2 == root { s += $3 } END { print int(s/1024) }')
    if [ "$rss" != 3 ]; then
        echo "watch: self-test: fixture 3 wanted 3 MB, the decoy's rss leaked in as $rss MB"
        return 1
    fi

    # Fixture 4: a leader and the grandchild it spawns share one pgid,
    # and tree_kill on the leader's pid takes both. Without a group of
    # its own the root pgid matches no process, so tree_kill reaches
    # nothing and the cap never fires — the exact weakening dash's
    # refused `set -m` left behind.
    leader sh -c 'sleep 30 & wait' >/dev/null 2>&1
    lead=$!
    i=0
    n=0
    while [ $i -lt 40 ]; do
        n=$(ps -eo pid=,pgid= | tree_pids "$lead" | wc -l | tr -d ' ')
        [ "$n" -ge 2 ] && break
        sleep 0.25; i=$((i + 1))
    done
    if [ "$n" -lt 2 ]; then
        echo "watch: self-test: fixture 4 — the guarded tree has no process group of its own (pgid $lead holds $n pid(s))"
        tree_kill "$lead"; kill -9 "$lead" 2>/dev/null
        return 1
    fi
    tree_kill "$lead"
    sleep 0.3
    if ps -eo pid=,pgid= | awk -v root="$lead" '$2 == root { found=1 } END { exit !found }'; then
        echo "watch: self-test: fixture 4 — tree_kill left the guarded tree alive"
        kill -9 "$lead" 2>/dev/null
        return 1
    fi
    echo "watch: self-test passed — 4 fixtures"
}
if [ "$1" = "--self-test" ]; then
    self_test
    exit $?
fi
cap_mb="$1"; shift
if [ -n "$AVRA_WATCH_HELD" ]; then
    exec "$@"
fi
# The guarded command becomes a process-group leader through `leader`,
# defined with the tree walkers above; the tree walkers key on that
# pgid, never on a ppid chain.
slots="${AVRA_BUILD_SLOTS:-1}"
lock="${AVRA_BUILD_LOCK:-/tmp/avra-build.lock}"
floor="${AVRA_MEM_FLOOR:-20}"

# A LINK THAT RUNS OUT OF DISK DELETES `build/avra`. `make bootstrap`
# links straight at it (`-o build/avra`), so an ENOSPC there leaves the
# tree with NO COMPILER — the same class this file's memory floor
# exists to prevent, on the other resource, with a worse ending.
# AND DISK DOES NOT FREE ITSELF, which is why this REFUSES where the
# memory floor WAITS: memory pressure passes when a process exits, a
# full volume stays full, and a wait loop there spins forever while
# looking like patience. Checked BEFORE the lock, so a refusal does
# not queue behind someone else's build.
disk_floor="${AVRA_DISK_FLOOR_MB:-2048}"
free_mb=$(df -Pm . 2>/dev/null | awk 'NR==2 {print $4}')
if [ -n "$free_mb" ] && [ "$free_mb" -lt "$disk_floor" ]; then
    echo "watch: ${free_mb} MB free, under the ${disk_floor} MB floor — refusing to start" >&2
    echo "watch:   a link that runs out of disk DELETES build/avra, and \`make bootstrap\`" >&2
    echo "watch:   links straight at it. Free space first; AVRA_DISK_FLOOR_MB moves the floor." >&2
    exit 2
fi
# THE SLOTS, AND THE QUEUE IN FRONT OF THEM. The lock is N
# directories, not one: a gate peaks at ~0.83 GB on a 16 GB machine,
# so serialising every heavy step was a cap set for a tree whose gate
# cost 2.4 GB and leaked, and the guard outlived its reason. SLOT 1
# KEEPS THE OLD PATH, so a worktree still running the one-slot script
# contends for it and the two exclude each other during a rollout.
# AND THE SLOTS ARE ENTERED IN ARRIVAL ORDER, because N slots taken by
# `mkdir` alone is still a race: a lane running back-to-back steps
# re-takes a slot before a waiting lane's next poll, and one lane lost
# 161 times while queueing correctly. A waiter takes a TICKET above
# every ticket outstanding and tries the slots only when no older
# ticket is WAITING — a ticket is dropped the moment a slot is taken,
# or the queue would serve one lane at a time and the slots would buy
# nothing. A ticket or a slot whose holder died is reaped, or it
# blocks the queue forever.
#
# ONE SLOT BY DEFAULT: a full build is CPU-bound on a shared box, so
# concurrent slots serialise work rather than parallelising it. Raise
# AVRA_BUILD_SLOTS deliberately, never as the default. A waiting
# caller is told who holds each slot — its pid and its command.
qdir=$lock.q
mkdir -p "$qdir"
last=$(ls "$qdir" 2>/dev/null | sort -n | tail -1)
mine=$(( ${last:--1} + 1 ))
while ! mkdir "$qdir/$mine" 2>/dev/null; do mine=$(( mine + 1 )); done
echo $$ > "$qdir/$mine/pid"
# Until a slot is held, the trap clears the TICKET alone: `$lock` still
# names slot 1, and removing it here would free another lane's slot.
# A SIGNAL TRAP THAT NEVER EXITS IS NOT A HANDLER, IT IS A DETOUR: a
# bare `trap 'cleanup' EXIT INT TERM` runs `cleanup` on a signal and
# then RESUMES the script at the next statement, because nothing in
# that body says to stop. Ctrl-C on a queued waiter dropped its
# ticket and kept polling forever, invisibly — proven live (a
# `sleep`-loop orphan survived its own TERM). EXIT gets its own
# cleanup-only trap; INT and TERM get the same cleanup AND an exit,
# so a queued wait actually stops when told to.
trap 'rm -rf "$qdir/$mine"' EXIT
trap 'rm -rf "$qdir/$mine"; echo "watch: signalled while queued (ticket $mine) — ticket dropped, exiting" >&2; exit 143' INT TERM
# WHO HOLDS WHAT, so a caller told to wait sees the cost rather than
# a bare ticket number. Scans every held slot that exists, not only
# 1..$slots — a caller running fewer slots than another's still sees
# the slots that other one holds.
slot_holders() {
    for cand in "$lock" "$lock".[0-9]*; do
        [ -d "$cand" ] || continue
        case "$cand" in
            "$lock") n=1 ;;
            *) n="${cand##*.}" ;;
        esac
        h=$(cat "$cand/pid" 2>/dev/null)
        if [ -n "$h" ] && kill -0 "$h" 2>/dev/null; then
            c=$(cat "$cand/cmd" 2>/dev/null)
            echo "watch:   slot $n: pid $h — ${c:-?}" >&2
        fi
    done
}
held=""
said=no
while [ -z "$held" ]; do
    ahead=no
    for t in "$qdir"/*; do
        [ -d "$t" ] || continue
        h=$(cat "$t/pid" 2>/dev/null)
        if [ -n "$h" ] && ! kill -0 "$h" 2>/dev/null; then
            rm -rf "$t"
            continue
        fi
        n=${t##*/}
        [ "$n" -lt "$mine" ] 2>/dev/null && ahead=yes
    done
    if [ "$ahead" = no ]; then
        n=1
        while [ "$n" -le "$slots" ]; do
            [ "$n" = 1 ] && cand="$lock" || cand="$lock.$n"
            if mkdir "$cand" 2>/dev/null; then held="$cand"; break; fi
            holder=$(cat "$cand/pid" 2>/dev/null)
            if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
                rm -rf "$cand"
                continue
            fi
            n=$(( n + 1 ))
        done
    fi
    [ -n "$held" ] && break
    if [ "$said" = no ]; then
        echo "watch: all $slots build slots busy — waiting (ticket $mine)" >&2
        slot_holders
        said=yes
    fi
    sleep 5
done
lock="$held"
# A TICKET MEANS "WAITING", NOT "RUNNING". Dropping it at the moment a
# slot is taken is what lets the other slots fill: a ticket held for
# the whole run would make every later arrival wait behind THIS one,
# and N slots would serve one lane at a time — the queue defeating the
# capacity it was put in front of (witnessed: four runs, no overlap).
rm -rf "$qdir/$mine"
# THE SAME DETOUR, ONE STAGE LATER, AND WORSE: a bare EXIT INT TERM
# trap here only released the LOCK on a signal and fell through to
# keep running — the memory floor wait, then `"$@" &` regardless of
# whether the lock was still this process's to hold. Proven live in
# an isolated repro of this exact shape: TERM during `wait "$pid"`
# freed the lock while the backgrounded child kept running, unkilled
# and unwatched — ONE HEAVY PROCESS AT A TIME held only as long as
# nobody presses Ctrl-C. `pid` is unset until `"$@" &` runs below, so
# the INT/TERM handler kills the tree only once there is one.
trap 'rm -rf "$lock"' EXIT
trap '[ -n "$pid" ] && tree_kill "$pid"; rm -rf "$lock"; echo "watch: signalled — the guarded tree was killed, the lock released" >&2; exit 143' INT TERM
echo $$ > "$lock/pid"
printf '%s\n' "$*" > "$lock/cmd"
while :; do
    level=$(sysctl -n kern.memorystatus_level 2>/dev/null || echo 100)
    [ "$level" -ge "$floor" ] && break
    echo "watch: the machine has ${level}% available, under the ${floor}% floor — waiting" >&2
    sleep 5
done
AVRA_WATCH_HELD=$$
export AVRA_WATCH_HELD
leader "$@"
pid=$!
if [ -n "$AVRA_SAMPLE" ]; then
    mkdir -p build
    prof="${AVRA_SAMPLE_FILE:-build/avra-sample.txt}"
    # A PROFILE NAMES ITS SUBJECT. `$!` is the command this watchdog
    # launched — right when that command EXECS (`./avra` does), and the
    # WRONG process the moment it forks a worker and waits. A profile
    # of the wrong pid does not fail; it reports its subject as idle,
    # and a reader with two hypotheses and no pid cannot tell that from
    # a slow syscall. Say which pid, so the question is answerable.
    # A PROFILE NAMES ITS SUBJECT, FROM THE REPORT ITSELF. `$!` is the
    # command this watchdog launched — the right pid when that command
    # EXECS, as `./avra` does, and the WRONG one the moment something
    # forks a worker and waits on it. A profile of the wrong process
    # does not fail: it reports its subject as IDLE, and a reader with
    # no pid cannot tell that from a slow syscall.
    # ASKING `ps` IS NOT THE WAY. Read at launch it answers `/bin/sh`
    # for every `./avra` run, because the script has not reached its
    # `exec` yet — a diagnostic that lies in the same direction as the
    # defect it exists to expose. `sample`'s own header cannot race:
    # it names what the sampler actually attached to.
    ( sleep "${AVRA_SAMPLE_AFTER:-0}"
      sample "$pid" "$AVRA_SAMPLE" -file "$prof" > "$prof.log" 2>&1
      head -1 "$prof" 2>/dev/null | sed 's/^/watch: profiled /' >&2
      echo "watch: profile at $prof" >&2 ) &
    sampler=$!
fi
peak=0
fired=0
# The tree's PHYSICAL FOOTPRINT in MB — `footprint`'s number, which
# counts a page the compressor holds. RSS does not, and read a
# 2.4 GB compiler as 1.4 GB on a machine that then panicked. (tree_mem,
# tree_kill and tree_rss are defined above, ahead of the traps that
# may need to call tree_kill before this point in the file runs.)
# THE STEP IS WAITED FOR, THE TRIPWIRE POLLS BESIDE IT. A warm build is 80 ms of
# work: a loop that looked for its end between polls cost it the poll, and one
# that slept between looks cost it the sleep. The poller keeps the tripwire's
# cadence — RSS every 0.25 s, the footprint every fourth poll, never the first —
# and says what it saw in the lock's own directory, which dies with the step.
state="$lock/watch"
( polls=0; seen=0
  while kill -0 "$pid" 2>/dev/null; do
      sleep 0.25
      kill -0 "$pid" 2>/dev/null || break
      rss=$(tree_rss "$pid")
      [ -z "$rss" ] && rss=0
      mem=$rss
      if [ $((polls % 4)) -eq 3 ]; then
          fp=$(tree_mem "$pid")
          [ -n "$fp" ] && [ "$fp" -gt "$mem" ] && mem=$fp
      fi
      polls=$((polls + 1))
      if [ "$mem" -gt "$seen" ]; then seen=$mem; echo "$seen" > "$state.peak"; fi
      if [ "$mem" -gt "$cap_mb" ]; then
          echo 1 > "$state.fired"
          tree_kill "$pid"
          break
      fi
  done ) &
poller=$!
wait "$pid" 2>/dev/null
status=$?
kill "$poller" 2>/dev/null
wait "$poller" 2>/dev/null
[ -f "$state.peak" ] && peak=$(cat "$state.peak")
[ -f "$state.fired" ] && fired=1
[ -n "$sampler" ] && wait "$sampler" 2>/dev/null
[ "$fired" -eq 1 ] && status=137
echo "watch: peak ${peak} MB, status ${status}" >&2
exit $status
