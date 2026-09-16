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
cap_mb="$1"; shift
if [ -n "$AVRA_WATCH_HELD" ]; then
    exec "$@"
fi
lock=/tmp/avra-build.lock
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
slots="${AVRA_BUILD_SLOTS:-3}"
qdir=$lock.q
mkdir -p "$qdir"
last=$(ls "$qdir" 2>/dev/null | sort -n | tail -1)
mine=$(( ${last:--1} + 1 ))
while ! mkdir "$qdir/$mine" 2>/dev/null; do mine=$(( mine + 1 )); done
echo $$ > "$qdir/$mine/pid"
# Until a slot is held, the trap clears the TICKET alone: `$lock` still
# names slot 1, and removing it here would free another lane's slot.
trap 'rm -rf "$qdir/$mine"' EXIT INT TERM
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
trap 'rm -rf "$lock"' EXIT INT TERM
echo $$ > "$lock/pid"
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
# THE TRIPWIRE IS RSS, read by ps in milliseconds; the footprint —
# `footprint` walks the process's whole map, seconds on a big one —
# is read every fourth poll for the honest peak. A process once grew
# from 7 GB to 16 GB between two footprint polls.
tree_rss() {
    ps -eo pid=,ppid=,rss= | awk -v root="$1" '
        { pp[$1]=$2; rss[$1]=$3 }
        END {
            n=0; q[n++]=root; s=0
            for (i=0; i<n; i++) { s+=rss[q[i]]; for (p in pp) if (pp[p]==q[i]) q[n++]=p }
            print int(s/1024)
        }'
}
polls=0
while kill -0 "$pid" 2>/dev/null; do
    rss=$(tree_rss "$pid")
    [ -z "$rss" ] && rss=0
    mem=$rss
    if [ $((polls % 4)) -eq 0 ]; then
        fp=$(tree_mem "$pid")
        [ -n "$fp" ] && [ "$fp" -gt "$mem" ] && mem=$fp
    fi
    polls=$((polls + 1))
    [ "$mem" -gt "$peak" ] && peak=$mem
    if [ "$mem" -gt "$cap_mb" ]; then
        fired=1
        tree_kill "$pid"
        break
    fi
    sleep 0.25
done
wait "$pid" 2>/dev/null
status=$?
[ -n "$sampler" ] && wait "$sampler" 2>/dev/null
[ "$fired" -eq 1 ] && status=137
echo "watch: peak ${peak} MB, status ${status}" >&2
exit $status
