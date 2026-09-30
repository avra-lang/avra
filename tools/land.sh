#!/bin/sh
# `sh tools/land.sh [--dry-run] <branch>` — ONE fail-closed command that
# lands a lane branch onto LOCAL main: merges main into the branch,
# rebuilds the compiler, tests what the merge touched, pays the
# whole-tree keepers, re-emits the seed if it moved, and fast-forwards
# main onto the branch. Chained under `set -eu`, no `;` before the
# land and no pipe into a step's own status (a pipe answers the PIPE'S
# last command, never the one that mattered) — every step's real exit
# status is what land.sh reads, and a failure prints the step's name,
# its log path, and the log's last 30 lines before the script stops.
#
# `--dry-run` runs every step but the final fast-forward.
#
# THE LOCK covers LANDING alone, never an ordinary build — a FIFO
# TICKET QUEUE under /tmp, so contenders land in ARRIVAL order rather
# than in whatever order a bare `mkdir` race happens to wake. Each
# ticket carries its own holder's pid; one whose pid has died — a
# crashed holder, or a waiter killed before its turn — is reclaimed by
# whoever next scans past it, so a dead contender never blocks the
# ones behind it. Two landings never interleave a merge, a rebuild
# and a fast-forward. `slot.sh` is the OTHER limiter, machine-wide and
# finer: a build and cache-attacks each take a slot first, so a
# landing shares the machine with whatever else is building rather
# than owning it. The parallel checks phase (run_checks) is bounded by
# AVRA_LAND_JOBS instead — slot.sh's "2" was sized for a landing that
# ran one heavy step at a time, which that phase deliberately does not.
#
# EVERY HEAVY COMMAND'S LOG IS CAPPED (tools/capped.sh) so a runaway
# does not fill the disk — the law `make avra`'s own 43 GB log paid
# for once already. The quick git plumbing around a merge is not
# capped: it neither loops nor emits without bound, and capping an
# artifact that is DIFFED (never true here) is the one shape that
# must stay uncapped instead.
#
# THE BUILD RECIPE, per the generation law: the runtime and package C
# objects are built first (a bare `build/avra build packages/cli` has
# nothing to link against on a tree that never ran `make avra`), then
# ONE compile-and-copy cycle — TWICE when the merge touched
# packages/std-avrac, packages/cli, packages/std-meta or runtime/,
# since a compiler change only reaches the product on the SECOND
# build. A compiler-untouched batch skips that second build AND
# seed-check outright — a seed whose compiler-relevant files never
# moved compiles HEAD exactly as it did on the landing before this one.
#
# fmt-lossless RUNS BEFORE THE BUILD, WITH THE STANDING COMPILER: the
# formatter's own cache means a warm tree-wide `avra fmt --check
# packages` answers in well under a second (compiler/build.av's
# `compiler_print` used to re-hash this binary once per PACKAGE in
# that walk — 23 hashes of an 8 MB file for one check — memoized once
# a process now), so there is no longer a reason to pay for a build
# before learning the tree is unformatted. The standing compiler's
# formatter output equals a freshly-built one's UNLESS this landing
# moves the formatter itself, which `compiler_reached` already answers
# as "the compiler changed" — so this fail-fast run stands alone for
# an ordinary landing, and a compiler-changing one also gets the
# ordinary post-build run (in the pool below), since only the NEW
# compiler can answer whether ITS OWN rules are met tree-wide.
#
# ONCE THE BUILD IS DONE, every affected package's tests, idioms
# (scoped the same way — see run_checks), a compiler-changing
# landing's own fmt-lossless re-check, and (when the compiler changed)
# seed-check run TOGETHER, bounded by AVRA_LAND_JOBS (default 4,
# env-overridable). cache-attacks stands apart, sequential: it clears
# the shared .avra-cache as its own first act, which a concurrently-
# reading check would read as a vanished store, not a real failure.
#
# `sh tools/land.sh --call <function> [args...]` calls one function
# below directly, standing where the real script stands (so `$0`-based
# paths still resolve) — the seam tools/land_test.sh's fixtures use to
# exercise the merge, the cache sweep and the lock in a throwaway
# repo, never the real one.
#
# THREE MORE GATES SHARE THE SAME POOL, each ratcheted in
# tools/land.baseline (key=value) or tools/speed.baseline (PERF's own
# line format — see speed_gate below): the warm-reuse gate
# (AVRA_LAND_WARM_GATE, default 1), the Linux gate
# (AVRA_LAND_LINUX, default 1, runs affected packages' suites on a
# Sprite), and the speed gate (AVRA_LAND_SPEED_GATE=1, off by default,
# instructions retired and peak memory footprint over a fixed input).
# Each prints its own NUMBER and VERDICT; a regression past a gate's
# own threshold needs that gate's own override env var
# (AVRA_LAND_WARM_OK, AVRA_LAND_SPEED_OK) with a reason, signed into
# the chore commit (commit_chore_if_moved) that carries the seed and
# every moved baseline together — at most one per landing.
set -eu
verdict_ok=0
# THE LANDING POOL: every Sprite no session keeps for itself, the idlest
# chosen per leg (sprites_by_load); PERF's quiet census box is never in it.
land_sprite_pool="avra-idioms-pay avra-comptime avra-phase-d avra-cores"

LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}"
export LLVM_PREFIX
AVRA_WATCH_HELD=1
export AVRA_WATCH_HELD

# AVRA_LAND_JOBS bounds how many of a LANDING'S OWN heavy steps run at
# once (default 4) — a package's tests, idioms, fmt-lossless and
# seed-check, once the build is done. Sized for a 16 GB / 8-core
# machine shared with other sessions, never the whole box. This
# replaces slot.sh's machine-wide "2" for exactly these steps: that
# gate was sized for a landing that ran ONE heavy thing at a time and
# left room for one more elsewhere; running several of a landing's own
# steps together is what it was never asked to allow. memcap still caps
# every one of them individually (`heavy()`, unchanged) — AVRA_LAND_JOBS
# is the count, memcap is the ceiling, and both apply.
: "${AVRA_LAND_JOBS:=4}"

usage() {
    cat <<'EOF'
usage: sh tools/land.sh [--dry-run] <branch>
       sh tools/land.sh [--dry-run] <branch> <branch> [<branch>...]

Lands one branch, or a BATCH of several at once: merges them all into
one scratch integration branch, builds and checks that ONCE, then
fast-forwards main to it. A batch that fails BISECTS — it lands the
largest subset that passes together and names the branch(es) that
broke it, exiting non-zero when anything was excluded. Each branch
lands alone, so a red blocks only itself; AVRA_LAND_ABSORB=1 batches
the queue — whoever takes the lock lands every branch still queued
behind it in the same run, and each waiter exits with its own verdict. Never pushes
anywhere, never rewrites a branch's own history.

  --dry-run   run every step but the final fast-forward merge.
EOF
}

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
tools_dir="$(dirname "$self")"
branch="${branch:-}"

# ── LOGS AND SCRATCH ─────────────────────────────────────────────────
run_id="$$-$(date +%s)"
scratch_root="${AVRA_LAND_SCRATCH_ROOT:-/tmp/avra-land-scratch}"
# A re-exec (`--call`) inherits its caller's scratch, never mints one.
scratch_owned=0
if [ -z "${AVRA_LAND_SCRATCH:-}" ]; then scratch_owned=1; fi
scratch="${AVRA_LAND_SCRATCH:-$scratch_root/$run_id}"
export AVRA_LAND_SCRATCH="$scratch"
mkdir -p "$scratch/logs"
trash="$scratch/trash"
mkdir -p "$trash"

# Scratch a dead run left: its trash always goes; its logs go after a
# day, so a failed run's logs outlive it long enough to be read.
prune_dead_scratch() {
    [ -d "$scratch_root" ] || return 0
    for d in "$scratch_root"/*; do
        [ -d "$d" ] || continue
        [ "$d" = "$scratch" ] && continue
        pid="$(basename "$d" | cut -d- -f1)"
        case "$pid" in ''|*[!0-9]*) continue ;; esac
        kill -0 "$pid" 2>/dev/null && continue
        if [ -n "$(find "$d" -maxdepth 0 -mtime +0 2>/dev/null)" ]; then rm -rf "$d"; else rm -rf "$d/trash"; fi
    done
}

# This run's own scratch at exit: a green run leaves nothing, a failed
# one keeps its logs and drops the rest.
clean_own_scratch() {
    [ "$scratch_owned" -eq 1 ] || return 0
    if [ "$1" -eq 0 ]; then
        rm -rf "$scratch"
    else
        rm -rf "$trash"
        echo "land: this run's logs stay at $scratch/logs" >&2
    fi
}
if [ "$scratch_owned" -eq 1 ]; then prune_dead_scratch; fi

log_of() { echo "$scratch/logs/$1.log"; }

# ── THE TIMELINE — every step's own start offset and duration ────────
# `t0` is this run's own start; every heavy() and light() step reports
# against it. A --call fixture never installs finish_lock, so it never
# prints a total — only a real landing (main/main_batch) does, once.
t0="$(date +%s)"
timeline_emit() {
    name="$1"
    start="$2"
    status="$3"
    now="$(date +%s)"
    echo "land: timeline: $name start=+$((start - t0))s dur=$((now - start))s exit=$status" >&2
}

# Prints a step's failure — never exits itself, so a caller that means
# to catch it (`build_generation`'s own restore) still can.
fail_report() {
    name="$1"
    st="$2"
    log="$3"
    echo "land: FAILED at '$name' (exit $st) — log: $log" >&2
    echo "land: last 30 lines:" >&2
    tail -30 "$log" >&2
}

# A HEAVY STEP: an argv command, capped and slotted (2 of tools/slot.sh's
# machine-wide slots — two heavy commands run comfortably beside a
# landing). A bare call left unchecked under `set -eu` stops the whole
# script the instant it fails; a caller meaning to catch it (a build
# generation's own restore) wraps it in `if ! heavy …`.
heavy() {
    name="$1"
    shift
    log="$(log_of "$name")"
    # Progress goes to stderr: batch mode reads a function's stdout as its value.
    echo "land: $name …" >&2
    t_start="$(date +%s)"
    st=0
    # A HARD CAP per step: past it the step is killed and the landing
    # stops as a TOOL failure naming it. The Linux leg is bounded by its
    # own per-Sprite cap instead.
    step_cap="${AVRA_LAND_STEP_CAP_S:-2700}"
    case "$name" in linux*) step_cap=0 ;; esac
    if [ "${AVRA_LAND_PARALLEL_SLOT:-0}" = "1" ]; then
        # A step running inside the parallel job pool (job_launch) is
        # already bounded by AVRA_LAND_JOBS — the machine-wide slot.sh(2)
        # gate is for a landing that runs ONE heavy step at a time, which
        # this one no longer does. memcap still applies, per step.
        capped_step "$step_cap" sh "$tools_dir/capped.sh" "$log" 2000000 \
            sh "$tools_dir/memcap.sh" "${AVRA_MEMCAP_MB:-4000}" "$@" || st=$?
    else
        capped_step "$step_cap" sh "$tools_dir/capped.sh" "$log" 2000000 \
            sh "$tools_dir/slot.sh" 2 \
            sh "$tools_dir/memcap.sh" "${AVRA_MEMCAP_MB:-4000}" "$@" || st=$?
    fi
    timeline_emit "$name" "$t_start" "$st"
    if [ "$st" -eq 124 ] && [ "$step_cap" -gt 0 ]; then
        tool_failed "the step $name ran past its $((step_cap / 60)) min cap"
        return 1
    fi
    if [ "$st" -eq 0 ]; then
        echo "land: $name OK" >&2
        return 0
    fi
    # 137 is the memory cap's kill: a finding about the change, never a retry.
    fail_report "$name" "$st" "$log"
    return "$st"
}

# A command under a hard cap of `$1` seconds (0: none).
capped_step() {
    cap="$1"
    shift
    if [ "$cap" -gt 0 ]; then watched "$cap" 0 true "$@"; else "$@"; fi
}

# A step's exit status is read as `cmd || st=$?`: after `if cmd; then …
# fi` with no else, `$?` is 0 whatever cmd answered.

# A LIGHT STEP: quick git/file plumbing with its own control flow — no
# loop, no unbounded output, so no cap and no slot. `body` is a shell
# function name, called in a SUBSHELL so its own `cd` never leaks into
# the step after it; its stdout+stderr land in the step's log.
light() {
    name="$1"
    body="$2"
    shift 2
    log="$(log_of "$name")"
    echo "land: $name …" >&2
    t_start="$(date +%s)"
    st=0
    ( "$body" "$@" ) > "$log" 2>&1 || st=$?
    timeline_emit "$name" "$t_start" "$st"
    if [ "$st" -ne 0 ]; then
        fail_report "$name" "$st" "$log"
        return "$st"
    fi
    echo "land: $name OK" >&2
}

# ── THE LANDING LOCK — A FIFO TICKET QUEUE ───────────────────────────
# Landers are served in ARRIVAL order, not in whatever order the kernel
# happens to wake a `mkdir` race in. Each contender takes a ticket
# directory named by a number nobody has claimed yet (`mkdir` is the
# atomic test, so two contenders racing the same number can never both
# win it), writes its own pid inside, then waits until its own ticket
# is the LOWEST one whose pid is still a live process. A ticket whose
# pid has died — the holder crashed, or a waiter was killed before its
# turn — is reclaimed by whoever next scans past it, so a dead
# contender never blocks the ones behind it, however long ago it died.
lock_dir="${AVRA_LAND_LOCK:-/tmp/avra-land.lock}"
ticket=""

# The queue's own directory, made once.
tickets_dir() { echo "$lock_dir/tickets"; }

# The lowest ticket still waiting or holding, every dead ticket removed
# on the way past, so asking cleans the queue. It answers one value and
# pipes nothing: a caller reading only the first of a listed queue would
# leave the rest writing into a closed pipe.
lowest_live_ticket() {
    d="$(tickets_dir)"
    lowest=""
    for t in $(ls "$d" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do
        # A ticket is made before its pid is written: an absent pid is
        # a waiter mid-arrival, never a reason to stop scanning.
        pid="$(cat "$d/$t/pid" 2>/dev/null)" || pid=""
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            [ -z "$lowest" ] && lowest="$t"
        elif [ -n "$pid" ]; then
            echo "land: reclaiming a dead ticket ($t, pid $pid is not running)" >&2
            rm -rf "$d/$t" 2>/dev/null
        fi
    done
    echo "$lowest"
}

acquire_lock() {
    d="$(tickets_dir)"
    mkdir -p "$d" 2>/dev/null
    n=1
    while :; do
        highest="$(ls "$d" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)"
        [ -n "$highest" ] && [ "$highest" -ge "$n" ] && n=$((highest + 1))
        if mkdir "$d/$n" 2>/dev/null; then
            ticket="$n"
            break
        fi
        n=$((n + 1))
    done
    {
        echo "pid=$$"
        echo "branch=$branch"
        echo "dry_run=${dry_run:-0}"
        echo "time=$(date)"
    } > "$d/$ticket/info"
    echo "$$" > "$d/$ticket/pid"

    printed_wait=0
    while :; do
        [ -f "$d/$ticket/verdict" ] && absorbed_exit "$d/$ticket"
        lowest="$(lowest_live_ticket)"
        [ "$lowest" = "$ticket" ] && return 0
        if [ "$printed_wait" -eq 0 ]; then
            echo "land: ticket $ticket taken — waiting behind ticket $lowest" >&2
            printed_wait=1
        fi
        sleep 1
    done
}
release_lock() { [ -n "$ticket" ] && rm -rf "$(tickets_dir)/$ticket" 2>/dev/null; }

# ── THE QUEUE BATCHES ITSELF ─────────────────────────────────────────
# The lander that takes the lock absorbs every waiter queued behind it
# that asked to land for real, and runs one batch over all their
# branches: one build, one check, a bisection on failure. Each absorbed
# waiter is handed its own branch's verdict and exits with it.

# A ticket's `key=value` line.
ticket_field() { sed -n "s/^$2=//p" "$1/info" 2>/dev/null | head -n 1; }

# Marks every live, real waiter behind this ticket as absorbed and
# prints its ticket number.
absorb_waiters() {
    d="$(tickets_dir)"
    for t in $(ls "$d" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do
        pid="$(cat "$d/$t/pid" 2>/dev/null)"
        if [ "$t" -gt "$ticket" ] && [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null &&
            [ "$(ticket_field "$d/$t" dry_run)" = "0" ]; then
            echo "$ticket" > "$d/$t/absorbed_by"
            echo "$t"
        fi
    done
}

# Hands one absorbed waiter its verdict: the status first, the words
# last, since the words' arrival is what the waiter watches for.
give_verdict() {
    echo "$2" > "$1/status"
    printf '%s\n' "$3" > "$1/verdict.tmp"
    mv "$1/verdict.tmp" "$1/verdict"
}

# An absorbed waiter's end: the batch that took its branch answered.
absorbed_exit() {
    cat "$1/verdict"
    st="$(cat "$1/status" 2>/dev/null)"
    [ "${st:-1}" = 0 ] && verdict_ok=1
    release_lock
    exit "${st:-1}"
}

# A holder leaving before it answered strands no waiter.
release_absorbed() {
    d="$(tickets_dir)"
    for t in $absorbed; do
        [ -f "$d/$t/verdict" ] || give_verdict "$d/$t" 1 "land: the batch that absorbed this branch stopped before a verdict — land again"
    done
}
finish_lock() {
    exit_st="${1:-$?}"
    release_absorbed
    release_lock
    echo "land: timeline: total wall=$(($(date +%s) - t0))s" >&2
    tool_reason=""
    [ -f "$scratch/tool-failure" ] && tool_reason="$(cat "$scratch/tool-failure")"
    final_st=0
    exit_verdict "$exit_st" "${verdict_ok:-0}" "$tool_reason" || final_st=$?
    [ "$final_st" -eq 0 ] || restore_generated "${branch_wt:-}"
    clean_own_scratch "$final_st"
    exit "$final_st"
}

# A STATUS IS A VERDICT. 0 only where a verdict said so (a landing, a
# dry run's OK); a tool failure is 3 and says NOT LANDED; a run that
# ended 0 with no verdict is 3 too, never a silent success.
exit_verdict() {
    if [ "$2" -eq 1 ] && [ "$1" -eq 0 ]; then return 0; fi
    if [ -n "$3" ]; then
        echo "NOT LANDED — tool failure: $3"
        return 3
    fi
    if [ "$1" -eq 0 ]; then
        echo "NOT LANDED — the run ended with no verdict"
        return 3
    fi
    return "$1"
}

# A failed run leaves the branch tree as it found it: the seed is
# regenerated by every landing, so an emit a failure stranded there
# goes — a landing starts only from a clean tree, so nothing else
# wrote these files.
restore_generated() {
    [ -n "$1" ] && [ -d "$1" ] || return 0
    git -C "$1" diff --quiet -- bootstrap/seed.ll bootstrap/seed.sources 2>/dev/null && return 0
    git -C "$1" checkout -- bootstrap/seed.ll bootstrap/seed.sources 2>/dev/null &&
        echo "land: restored the seed this failed run regenerated in $1" >&2
    return 0
}

# A TRAP ON A SIGNAL RESUMES AFTER THE HANDLER, IT DOES NOT EXIT — a
# `trap release_lock INT TERM` alone frees the ticket on Ctrl-C or a
# kill, then the script carries straight on from wherever it was
# interrupted (witnessed: a killed `--dry-run` had its ticket cleaned
# up correctly and kept running anyway). INT/TERM need their own
# handler that exits afterward, at the conventional 128+signal code.
release_lock_and_exit() {
    sig="$1"
    case "$sig" in INT) finish_lock 130 ;; *) finish_lock 143 ;; esac
    case "$sig" in
        INT) exit 130 ;;
        *) exit 143 ;;
    esac
}

# ACQUIRE, HOLD UNTIL A SIGNAL FILE APPEARS (OR A TIMEOUT), RELEASE —
# one process that stays alive for the whole hold, the shape a real
# landing's lock hold has and a bare `--call acquire_lock` does not
# (that process exits the instant it acquires, which is nobody
# holding anything). Reachable only through `--call`; land_test.sh's
# FIFO fixture is the one caller.
hold_lock_for() {
    signal="$1"
    order="${2:-/dev/null}"
    acquire_lock
    echo "acquired ticket $ticket"
    echo "acquired $branch $ticket" >> "$order"
    while [ ! -f "$signal" ]; do sleep 0.2; done
    echo "released $branch" >> "$order"
    release_lock
    echo "released ticket $ticket"
}

# ── WORKTREE DISCOVERY ───────────────────────────────────────────────
# Neither worktree is assumed to be the one land.sh runs from — a
# session invoking this from a THIRD lane must still find main's
# checkout and the landing branch's, by branch name alone.
worktree_for_branch() {
    want="refs/heads/$1"
    git worktree list --porcelain | awk -v want="$want" '
        /^worktree / { wt = substr($0, 10) }
        /^branch /   { if (substr($0, 8) == want) { print wt; exit } }
    '
}

# ── ONE MERGE, INCLUDING THE SEED'S OWN LICENSED CONFLICT ────────────
# The seed is RE-EMITTED later in this same run (make seed), so a
# conflict confined to bootstrap/seed.ll and/or bootstrap/seed.sources
# is not a real disagreement — it is two commits that each re-emitted
# a seed the other did not have. Any OTHER conflicting file aborts the
# merge and names every file, rather than guess at code. Takes the
# REF to merge as its own argument — a single landing merges main in,
# a batch merges main AND then every branch in the batch, one at a
# time, through this same door.
merge_ref_in() {
    wt="$1"
    ref="$2"
    cd "$wt"
    if git merge --no-edit "$ref"; then
        echo "land: merge $ref OK (no conflicts, or already up to date)" >&2
        return 0
    fi
    conflicts="$(git diff --name-only --diff-filter=U)"
    others="$(printf '%s\n' "$conflicts" | grep -v -E '^bootstrap/seed\.(ll|sources)$' || true)"
    if [ -n "$(printf '%s' "$others" | tr -d '[:space:]')" ]; then
        echo "land: merge conflict outside the seed ($ref) — aborting" >&2
        echo "$conflicts"
        git merge --abort
        return 1
    fi
    echo "land: merge conflict confined to the seed ($ref) — taking main's side" >&2
    for f in bootstrap/seed.ll bootstrap/seed.sources; do
        case "$conflicts" in *"$f"*) git checkout --theirs -- "$f" && git add "$f" ;; esac
    done
    git commit --no-edit
}

# The single-landing shape land_test.sh's fixtures already call by
# name — unchanged behavior, just merge_ref_in with the ref fixed.
merge_main_in() { merge_ref_in "$1" "refs/heads/main"; }

# ── EVERY .avra-cache MOVED ASIDE (mv, never rm) ──────────────────────
# A landing tree keeps its warm cache: every durable key carries the
# compiler's print and each held record its own fingerprint. A gate
# whose question is COLD (the speed gate) moves its own side tree's
# cache aside with this.
move_caches_aside() {
    wt="$1"
    found="$(find "$wt" -maxdepth 4 -name .avra-cache -type d 2>/dev/null)"
    if [ -z "$(printf '%s' "$found" | tr -d '[:space:]')" ]; then
        echo "land: no .avra-cache under $wt" >&2
        return 0
    fi
    mkdir -p "$trash/avra-cache"
    n=0
    printf '%s\n' "$found" | while read -r d; do
        [ -z "$d" ] && continue
        n=$((n + 1))
        to="$trash/avra-cache/cache-$$-$(date +%s)-$n"
        mv "$d" "$to"
        echo "land: moved $d -> $to" >&2
    done
}

# ── THE SEED, RE-EMITTED AND COMMITTED TOGETHER IF IT MOVED ──────────
# `make seed` itself is the heavy half (an `avra emit` over the whole
# cli package) and is run separately, capped and slotted, before this
# light step decides whether the two files actually moved.
commit_seed_if_moved() {
    wt="$1"
    label="${2:-$branch}"
    cd "$wt"
    if git diff --quiet -- bootstrap/seed.ll bootstrap/seed.sources; then
        echo "land: seed unchanged" >&2
        return 0
    fi
    git add bootstrap/seed.ll bootstrap/seed.sources
    git commit -m "chore(seed): the compiler re-emitted for ${label}'s landing

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
}

# ── THE RATCHET BASELINE — tools/land.baseline, key=value lines ──────
# A gate's number that IMPROVES is recorded automatically; one that
# REGRESSES is recorded only when the landing sets its own override
# env var with a reason, and without one the gate FAILS. A missing
# file or key records the first number and passes — there is nothing
# yet to ratchet against.
baseline_get() {
    file="$1"
    key="$2"
    [ -f "$file" ] || return 0
    sed -n "s/^${key}=//p" "$file" | tail -n 1
}

# Portable in-place update (no `sed -i`, whose flag differs BSD/GNU):
# rewrite through a temp file, replacing the key's line or appending it.
baseline_set() {
    file="$1"
    key="$2"
    value="$3"
    mkdir -p "$(dirname "$file")"
    touch "$file"
    if grep -q "^${key}=" "$file" 2>/dev/null; then
        awk -v k="$key" -v v="$value" -F= 'BEGIN{OFS="="} $1==k{print k,v; next} {print}' "$file" > "$file.tmp"
    else
        cp "$file" "$file.tmp"
        echo "${key}=${value}" >> "$file.tmp"
    fi
    mv "$file.tmp" "$file"
}

# ratchet_check <file> <key> <value> <up|down> [<override-reason>] —
# `up` means higher is better (a held-file count); `down` means lower
# is better (instructions, bytes). Prints one PASS/FAIL line on
# stdout, updates the baseline on an improvement OR a signed
# regression, and appends `<key>: <reason>` to
# `$scratch/ratchet-overrides` so the chore commit can sign it.
ratchet_check() {
    file="$1"
    key="$2"
    value="$3"
    direction="$4"
    reason="${5:-}"
    old="$(baseline_get "$file" "$key")"
    if [ -z "$old" ]; then
        baseline_set "$file" "$key" "$value"
        echo "PASS $value (no prior baseline for $key — recorded)"
        return 0
    fi
    improved=0
    case "$direction" in
        up) [ "$value" -ge "$old" ] 2>/dev/null && improved=1 ;;
        down) [ "$value" -le "$old" ] 2>/dev/null && improved=1 ;;
    esac
    if [ "$improved" -eq 1 ]; then
        baseline_set "$file" "$key" "$value"
        echo "PASS $value (was $old)"
        return 0
    fi
    if [ -n "$reason" ]; then
        baseline_set "$file" "$key" "$value"
        echo "$key: $reason" >> "$scratch/ratchet-overrides"
        echo "PASS $value (was $old, regressed WITH override: $reason)"
        return 0
    fi
    echo "FAIL $value (was $old, regressed with no override)"
    return 1
}

# ── THE CHORE COMMIT — the seed and every moved ratchet baseline,
# together, so one landing makes AT MOST ONE chore commit. Run once,
# after every gate in the parallel pool has finished (never from
# inside a gate's own job — two gates finishing at different times
# would otherwise race the same commit).
chore_commit_message() {
    label="$1"
    seed_moved="$2"
    subject="chore(seed): the compiler re-emitted for ${label}'s landing"
    [ "$seed_moved" -eq 1 ] || subject="chore(land): the ratchet baseline moved for ${label}'s landing"
    if [ -s "$scratch/ratchet-overrides" ]; then
        overrides="$(printf 'Override reason(s), signed on this landing:\n'; sed 's/^/- /' "$scratch/ratchet-overrides")"
        printf '%s\n\n%s\n\nCo-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>' "$subject" "$overrides"
    else
        printf '%s\n\nCo-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>' "$subject"
    fi
}

# A ratchet baseline a gate advances, staged in this run's scratch and
# applied to the landing tree only once every check is green — a run
# that fails leaves no baseline behind, in any tree.
stage_baseline() {
    staged="$scratch/baseline/$2"
    if [ ! -f "$staged" ]; then
        mkdir -p "$scratch/baseline"
        if [ -f "$1/tools/$2" ]; then cp "$1/tools/$2" "$staged"; else : > "$staged"; fi
    fi
    echo "$staged"
}

apply_staged_baselines() {
    [ -d "$scratch/baseline" ] || return 0
    for f in "$scratch/baseline"/*; do
        [ -f "$f" ] && cp "$f" "$1/tools/$(basename "$f")"
    done
}

commit_chore_if_moved() {
    wt="$1"
    label="${2:-$branch}"
    cd "$wt"
    seed_moved=0
    git diff --quiet -- bootstrap/seed.ll bootstrap/seed.sources || seed_moved=1
    baseline_paths=""
    for f in tools/land.baseline tools/speed.baseline; do
        [ -f "$f" ] || continue
        git diff --quiet -- "$f" || baseline_paths="$baseline_paths $f"
    done
    if [ "$seed_moved" -eq 0 ] && [ -z "$baseline_paths" ]; then
        echo "land: seed and ratchet baseline(s) unchanged" >&2
        return 0
    fi
    [ "$seed_moved" -eq 1 ] && git add bootstrap/seed.ll bootstrap/seed.sources
    # A short, known-safe word list — every element is a path this
    # same function just found changed under `tools/`.
    [ -n "$baseline_paths" ] && git add $baseline_paths
    msg="$(chore_commit_message "$label" "$seed_moved")"
    git commit -m "$msg"
}

# ── THE WARM-REUSE GATE (behind AVRA_LAND_WARM_GATE=1) ───────────────
# Held-file reuse is a correctness property of the compiler's own
# cache, not of any one landing's diff: `build/avra check
# packages/std-avrac --time` prints a `held N/M` count (compiler/
# derive.av's `Derived.timed`) — N of M files answered from the
# store rather than re-derived. A body-only edit to ONE leaf file
# (its text digest moves, its interface does not) should still leave
# every OTHER file held, so a second check's `held` count is the
# signal: a floor it must clear, ratcheted in tools/land.baseline
# under `warm_held_floor`.
#
# compiler/format/receipt.av backs `avra fmt --write`'s own lossless
# gate — nothing in analysis, typing or lowering reads it — so
# editing one of its message strings cannot itself change what any
# OTHER file's record depends on; a leaf by construction, not by luck.
warm_gate_edit_path="packages/std-avrac/src/compiler/format/receipt.av"

warm_gate_step() {
    land_wt="$1"
    wt="${AVRA_LAND_WARM_WT:-$(cd "$land_wt/.." && pwd -P)/$(basename "$land_wt")-warm}"
    side_tree "$wt" "$land_wt" "$(git -C "$land_wt" rev-parse HEAD)" || return 1
    mkdir -p "$wt/build"
    cp "$land_wt/build/avra" "$wt/build/avra"
    cd "$wt"
    edit="$warm_gate_edit_path"
    backup="$scratch/warm-gate-orig"
    cp "$edit" "$backup"
    restore_warm_edit() { [ -f "$backup" ] && cp "$backup" "$edit"; }
    trap restore_warm_edit EXIT INT TERM

    echo "land: warm-reuse: first check (warms the cache) …"
    if ! build/avra check packages/std-avrac --time > "$scratch/warm-1.out" 2>&1; then
        cat "$scratch/warm-1.out"
        echo "land: warm-reuse: the first check failed" >&2
        return 1
    fi

    sed 's/a token moved at position/a token moved, position/' "$edit" > "$edit.tmp" && mv "$edit.tmp" "$edit"
    if cmp -s "$backup" "$edit"; then
        echo "land: warm-reuse: the scripted edit did not change $edit — pick another literal" >&2
        return 1
    fi

    echo "land: warm-reuse: second check (one file's body edited) …"
    if ! build/avra check packages/std-avrac --time > "$scratch/warm-2.out" 2>&1; then
        cat "$scratch/warm-2.out"
        echo "land: warm-reuse: the second check failed" >&2
        return 1
    fi
    cat "$scratch/warm-2.out"
    restore_warm_edit

    pair="$(grep -oE 'held [0-9]+/[0-9]+' "$scratch/warm-2.out" | head -1)"
    if [ -z "$pair" ]; then
        echo "land: warm-reuse: no 'held N/M' line in the second check's own --time output" >&2
        return 1
    fi
    nm="${pair#held }"
    n="${nm%/*}"
    m="${nm#*/}"

    cd "$land_wt"
    floor_file="$(stage_baseline "$land_wt" land.baseline)"
    old_floor="$(baseline_get "$floor_file" warm_held_floor)"
    # `st=$?` AFTER the assignment reads 0 unconditionally (the
    # assignment itself, once its substitution has run, always
    # "succeeds" as a shell command) — worse under `set -eu`, a
    # substitution answering non-zero aborts the whole script right
    # here, before `st=$?` is ever reached. `|| st=$?` on the
    # assignment itself is the only safe capture (heavy()'s own note).
    st=0
    out="$(ratchet_check "$floor_file" warm_held_floor "$n" up "${AVRA_LAND_WARM_OK:-}")" || st=$?
    word="PASS"
    [ "$st" -ne 0 ] && word="FAIL"
    echo "land: warm-reuse: held $n/$m (floor ${old_floor:-none}) — $word ($out)"
    return "$st"
}

# ── THE LINUX GATE (behind AVRA_LAND_LINUX, default 1) ────────────────
# Every package the landing's diff affects, run on a Sprite — ONE
# sprite-build call for the whole set, since a Sprite bootstraps a
# changed source tree once (~4-5 min) and a second call would pay
# that again for nothing. `AVRA_LAND_SPRITE_BUILD` stands in for
# tools/sprite-build.sh's own path so a fixture can stub it; a Sprite
# name comes from AVRA_LAND_SPRITE (default avra-idioms-pay — this
# gate's own Sprite, SPRITES.md).
#
# UNREACHABLE IS A TOOL FAILURE, NEVER A BRANCH'S: sprite-build.sh
# runs under `set -eu`, so a connectivity failure (the file push, or
# the exec that tests for a synced tree) stops it before its own
# trailing "sprite-build: … -> exit N" line — which a REAL remote
# command failure, guarded by `|| status=$?`, always reaches. Absence
# of that line is the tell.
# A WATCHED COMMAND: `watched <cap_s> <quiet_s> <progress_fn> <cmd…>`
# runs the command and polls it every AVRA_LAND_WATCH_POLL_S seconds,
# noticing its exit within a second. Past `cap_s` seconds it is killed and
# answers 124; with `quiet_s` above 0, a `progress_fn` answer that has
# not changed for `quiet_s` seconds kills it too and answers 125. An
# empty progress answer measures nothing yet and never trips. Otherwise
# the command's own status.
watched() {
    cap_s="$1"
    quiet_s="$2"
    progress_fn="$3"
    shift 3
    poll="${AVRA_LAND_WATCH_POLL_S:-10}"
    "$@" &
    wpid=$!
    w0="$(date +%s)"
    wlast=""
    wlast_t="$w0"
    wnext=$((w0 + poll))
    while kill -0 "$wpid" 2>/dev/null; do
        sleep 1
        kill -0 "$wpid" 2>/dev/null || break
        wnow="$(date +%s)"
        [ "$wnow" -ge "$wnext" ] || continue
        wnext=$((wnow + poll))
        if [ $((wnow - w0)) -ge "$cap_s" ]; then
            kill_tree "$wpid"
            wait "$wpid" 2>/dev/null
            return 124
        fi
        [ "$quiet_s" -gt 0 ] || continue
        wp="$("$progress_fn")"
        if [ -z "$wp" ] || [ "$wp" != "$wlast" ]; then
            wlast="$wp"
            wlast_t="$wnow"
        elif [ $((wnow - wlast_t)) -ge "$quiet_s" ]; then
            kill_tree "$wpid"
            wait "$wpid" 2>/dev/null
            return 125
        fi
    done
    wst=0
    wait "$wpid" || wst=$?
    return "$wst"
}

# A process and every descendant, children first. A TRAILING `:` ON
# ITS OWN LINE GUARDS NOTHING BEFORE IT — `set -e` aborts the instant
# the PRECEDING command fails, never waiting to see whether a later
# line would have absorbed it. The KILL right above one is exactly
# that command: it finds nothing to kill (ESRCH) in the ORDINARY case
# where the TERM just above it already worked, so the trailing `:`
# was a no-op every time this function was about to return cleanly —
# `watched()`'s own two callers (the cap and the no-progress paths)
# never reached their `return 124`/`return 125` at all, the whole
# process dying with `kill -KILL`'s own exit status instead. Found
# calling `watched()` directly (`sh land.sh --call watched …`, exactly
# tools/land_train.sh's own calling convention) and confirmed with a
# five-line reproduction before touching this function. Each kill now
# guards ITSELF.
kill_tree() {
    for kid in $(pgrep -P "$1" 2>/dev/null); do kill_tree "$kid"; done
    kill -TERM "$1" 2>/dev/null || :
    sleep 1
    kill -KILL "$1" 2>/dev/null || :
}

# THE IDLEST SPRITE FIRST: every Sprite in the pool is asked, in
# parallel, for its load and free memory; the answer orders them by
# load per core, then free memory, with any that did not answer last.
# Each probe is one exec under a timeout, and each answer is printed; a
# pool of one is not probed.
sprites_by_load() {
    if [ "$#" -le 1 ]; then echo "$* "; return 0; fi
    probe="${AVRA_LAND_SPRITE_PROBE:-sprite_probe}"
    d="$(mktemp -d "${TMPDIR:-/tmp}/avra-sprite-load.XXXXXX")"
    for s in "$@"; do
        ( "$probe" "$s" > "$d/$s" 2>/dev/null || : ) &
    done
    wait
    for s in "$@"; do
        read -r load cores avail < "$d/$s" 2>/dev/null || load=""
        if [ -n "$load" ] && [ -n "$cores" ] && [ -n "$avail" ]; then
            echo "land-linux: $s load $load on $cores cores, $avail MB free" >&2
            awk -v s="$s" -v l="$load" -v c="$cores" -v a="$avail" 'BEGIN { printf "%012.4f %012d %s\n", l / c, 999999999 - a, s }'
        else
            echo "land-linux: $s did not answer its load probe" >&2
            printf '%012.4f %012d %s\n' 99999 999999999 "$s"
        fi
    done | sort | awk '{ print $3 }' | tr '\n' ' '
    rm -rf "$d"
}

# One Sprite's load, cores and MB free, as three words.
sprite_probe() {
    timeout 30 sprite exec -s "$1" -- sh -c 'set -- $(cat /proc/loadavg); l=$1; c=$(nproc); a=$(awk "/^MemAvailable:/ { print int(\$2 / 1024) }" /proc/meminfo); echo "$l $c $a"'
}

linux_gate_step() {
    wt="$1"
    shift
    pkgs="$*"
    sprites="$(sprites_by_load ${AVRA_LAND_SPRITE:-$land_sprite_pool})"
    sprite_build="${AVRA_LAND_SPRITE_BUILD:-$tools_dir/sprite-build.sh}"
    # `-o avra` skips avra's OWN prerequisites too (libavra_runtime.a
    # among them, COMPILER_OBJS) — `make objects` first, whether or
    # not bootstrap just ran, is what keeps a warm persistent tree
    # (compiler cached, build/ synced) from failing `libs`'s link the
    # same way speed_base_tree once did for real.
    # WARM: the Sprite tree keeps its .avra-cache, as a landing tree
    # does; the warm gate and --verify-held guard warm answers. Each
    # remote phase prints its seconds.
    # The first word the body says is the boundary: before it, a failure
    # is the Sprite's (unreachable, reset, a sync that died); after it,
    # the branch's own.
    # A HEARTBEAT: every 30 s the body prints how many bytes its logs
    # hold, so the watcher reads progress as a number that grows, never
    # as time passing.
    body="echo 'land-linux: body started'; d=\$(mktemp -d); ( while sleep 30; do echo \"land-linux: progress \$(cat /tmp/land-linux-*.log \"\$d\"/*.log 2>/dev/null | wc -c)\"; done ) & hb=\$!; trap 'pkill -P \$hb 2>/dev/null; kill \$hb 2>/dev/null' EXIT; export LLVM_PREFIX=/usr/lib/llvm-22; t=\$(date +%s); test -x build/avra || make bootstrap > /tmp/land-linux-boot.log 2>&1 || { tail -50 /tmp/land-linux-boot.log; exit 1; }; echo \"land-linux: bootstrap \$((\$(date +%s) - t))s\"; t=\$(date +%s); make objects > /tmp/land-linux-objects.log 2>&1 || { tail -50 /tmp/land-linux-objects.log; exit 1; }; make -o avra libs > /tmp/land-linux-libs.log 2>&1 || { tail -50 /tmp/land-linux-libs.log; exit 1; }; echo \"land-linux: objects+libs \$((\$(date +%s) - t))s\""
    # The suites run in parallel on the Sprite, the longest first; each
    # keeps its own log and status, and every failure is printed after
    # all have finished. The cap is AVRA_LAND_SPRITE_JOBS when set, else
    # what the Sprite's MemAvailable holds at AVRA_LAND_SPRITE_SUITE_MB
    # per suite, between 1 and 4 — a Sprite's memory is read, never assumed;
    # an unreadable one runs one suite at a time.
    first=""
    rest=""
    for p in $pkgs; do
        case "$p" in std-avrac|cli) first="$first $p" ;; *) rest="$rest $p" ;; esac
    done
    body="$body; pkgs='$first $rest'; cap='${AVRA_LAND_SPRITE_JOBS:-}'; per=${AVRA_LAND_SPRITE_SUITE_MB:-1800}; meminfo='${AVRA_LAND_SPRITE_MEMINFO:-/proc/meminfo}'"
    body="$body"'; if [ -z "$cap" ]; then avail=$(awk '"'"'/^MemAvailable:/ { print int($2 / 1024) }'"'"' "$meminfo" 2>/dev/null); cap=$(( ${avail:-0} / per )); [ "$cap" -ge 1 ] || cap=1; [ "$cap" -le 4 ] || cap=4; fi; echo "land-linux: $cap suites at once"'
    body="$body"'; running() { n=0; for q in $pids; do kill -0 "$q" 2>/dev/null && n=$((n + 1)); done; echo "$n"; }; pids=""; for p in $pkgs; do while [ "$(running)" -ge "$cap" ]; do sleep 0.2; done; ( t=$(date +%s); build/avra test "packages/$p" > "$d/$p.log" 2>&1; echo $? > "$d/$p.st"; echo "land-linux: test $p $(( $(date +%s) - t ))s" > "$d/$p.time" ) & pids="$pids $!"; done; wait $pids; fail=0; for p in $pkgs; do cat "$d/$p.time" 2>/dev/null; st=$(cat "$d/$p.st" 2>/dev/null || echo 1); if [ "$st" -ne 0 ]; then fail=1; echo "land-linux: FAILED $p (exit $st)"; tail -40 "$d/$p.log"; fi; done; exit $fail'

    # A Sprite that fails before the body starts, that stops making
    # progress, or that runs past the leg's cap is a TOOL failure that
    # names it; its remote run is stopped and the next Sprite is tried.
    # A failure after the body started is the branch's.
    tried=""
    leg_cap="${AVRA_LAND_LINUX_CAP_S:-1500}"
    leg_quiet="${AVRA_LAND_LINUX_QUIET_S:-300}"
    slug="$(basename "$wt")"
    for sprite in $sprites; do
        out="$scratch/linux-sprite-$sprite.out"
        linux_out="$out"
        st=0
        watched "$leg_cap" "$leg_quiet" linux_progress sh "$sprite_build" "$sprite" "$wt" -- bash -lc "$body" > "$out" 2>&1 || st=$?
        cat "$out"
        next="$(next_after "$sprite" $sprites)"
        if [ "$st" -eq 125 ]; then
            echo "land-linux: no progress on $sprite for $((leg_quiet / 60)) min — moved to ${next:-no other Sprite}"
            stop_remote "$sprite" "$slug"
        elif [ "$st" -eq 124 ]; then
            echo "land-linux: $sprite ran past the leg's $((leg_cap / 60)) min cap — moved to ${next:-no other Sprite}"
            stop_remote "$sprite" "$slug"
        elif grep -q '^land-linux: body started' "$out"; then
            echo "land-linux: ran on $sprite"
            return "$st"
        else
            echo "land: linux: the Sprite $sprite failed before the command ran (exit $st)" >&2
        fi
        tried="$tried $sprite"
    done
    tool_failed "no Linux Sprite could run the suites (tried:$tried)"
    return 1
}

# The leg's progress: the heartbeat's last byte count once the body has
# started, nothing measurable before it (a sync and a compiler advance
# print nothing while they work; the leg's cap bounds them).
linux_progress() {
    grep -q '^land-linux: body started' "$linux_out" 2>/dev/null || return 0
    grep '^land-linux: progress ' "$linux_out" | tail -1 | awk '{ print $3 }'
    grep -c '' "$linux_out"
}

# The train's own leg, `linux_progress`'s twin over a `land-train:`
# log — one `watched()` covers every remote step regardless of which
# gate's own body it is running (docs/2026_09_29_LAND_TRAIN.md).
train_progress() {
    grep -q '^land-train: body started' "$train_out" 2>/dev/null || return 0
    grep '^land-train: progress ' "$train_out" | tail -1 | awk '{ print $3 }'
    grep -c '' "$train_out"
}

# The landing pool's own list — the ONE place tools/land_train.sh
# reads it, so it never drifts from `linux_gate_step`'s own default
# (`${AVRA_LAND_SPRITE:-$land_sprite_pool}`) and never names a Sprite
# (avra-unions-* included) that is not this pool's to claim.
land_pool() { printf '%s' "${AVRA_LAND_SPRITE:-$land_sprite_pool}"; }

# The Sprite after `$1` in the rest of the list.
next_after() {
    want="$1"
    shift
    seen=0
    for s in "$@"; do
        [ "$seen" -eq 1 ] && { echo "$s"; return 0; }
        [ "$s" = "$want" ] && seen=1
    done
    :
}

# Stops a leg's run on the Sprite: the runner sprite-build started for
# this tree, and every process under it.
stop_remote() {
    remote_stop="${AVRA_LAND_SPRITE_STOP:-sprite_stop}"
    "$remote_stop" "$1" "$2" || echo "land: linux: could not stop the run on $1" >&2
}

sprite_stop() {
    timeout 60 sprite exec -s "$1" -- sh -c 'kids() { for c in $(ps -o pid= --ppid "$1"); do kids "$c"; echo "$c"; done; }; for r in $(pgrep -f "\.avra-run-$0\.sh"); do t="$(kids "$r") $r"; kill -TERM $t 2>/dev/null; sleep 2; kill -KILL $t 2>/dev/null; done; :' "$2"
}

# ── THE SPEED GATE (PERF's method): instructions retired and peak memory footprint
# from `/usr/bin/time -l`, over a FIXED input — main's own
# packages/cli at the landing's BASE sha, never the branch's own —
# compiled by THIS landing's product. One scratch worktree at the
# base sha, its runtime and package C built once (`make -o avra
# libs`); the product is copied in as build/avra.land and run FROM
# THERE, since a compiler resolves @std/* from its own binary's
# directory — run it from the branch's tree instead and it would
# compile the branch's OWN (possibly changed) std-avrac, not the
# fixed input.
#
# tools/speed.baseline is PERF's own format: one line per landing,
# `<main-sha> <instructions> <footprint-bytes> <reason-or-dash>`, the
# newest line the comparison. tools/land.baseline (key=value) stays
# the warm-reuse floor's alone.
speed_base_wt=""

# A SIDE TREE: a worktree of its own at `$3`, beside the landing's.
# A gate that moves a cache aside or edits a source does it THERE —
# the landing tree is shared by every pool job, and a cache moved or a
# file edited under a sibling's feet fails that sibling. `$1` is the
# side tree's path, `$2` any worktree of the same repo.
side_tree() {
    side="$1"
    src_wt="$2"
    at_sha="$3"
    if [ -e "$side" ] && [ ! -d "$side/.git" ] && [ ! -f "$side/.git" ]; then
        mkdir -p "$trash"
        mv "$side" "$trash/side-tree-$$-$(date +%s)"
    fi
    if [ ! -d "$side/.git" ] && [ ! -f "$side/.git" ]; then
        mkdir -p "$(dirname "$side")"
        git -C "$src_wt" worktree add -q --detach "$side" "$at_sha" ||
            { tool_failed "could not make a side tree at $side"; return 1; }
    fi
    if [ "$(git -C "$side" rev-parse HEAD)" != "$(git -C "$src_wt" rev-parse "$at_sha")" ]; then
        git -C "$side" checkout -q -f --detach "$at_sha" ||
            { tool_failed "could not check out $at_sha in the side tree $side"; return 1; }
        git -C "$side" clean -q -fd
        rm -f "$side/build/libavra_runtime.a"
    fi
    move_caches_aside "$side"
}

# A COMPILER AND ITS RUNTIME ARE ONE PAIR: the candidate's product
# links the candidate's runtime and backend objects, never the base
# tree's — the input stays the base's source, only the toolchain moves.
# Package C is the input's own and stays.
pair_toolchain() {
    for f in libavra_runtime.a llvm_wrapper.o ffi.o avra_hot.bc avra_hot.inc; do
        [ -f "$1/build/$f" ] && cp "$1/build/$f" "$2/build/$f"
    done
    for c in "$1"/runtime/*.c; do
        [ -f "$c" ] || continue
        o="$(basename "$c" .c).o"
        [ -f "$1/build/$o" ] && cp "$1/build/$o" "$2/build/$o"
    done
    return 0
}

# The speed gate's side tree, beside the landing tree `$1`.
speed_side_path() { echo "${AVRA_LAND_SPEED_WT:-$(cd "$1/.." && pwd -P)/avra-land-speed-wt}"; }

# The speed gate's side tree at `$2`, C-built once: `$1` is any
# worktree of the same repo.
speed_base_tree() {
    side_tree "$speed_base_wt" "$1" "$2" || return 1
    if [ ! -f "$speed_base_wt/build/libavra_runtime.a" ]; then
        # `-o avra` skips avra's OWN prerequisites too (COMPILER_OBJS,
        # libavra_runtime.a among them) — `make objects` first is what
        # build_generation's own two-step sequence already does, and
        # `libs` alone silently produced a build/avra.land that could
        # never link (clang: no such file: build/libavra_runtime.a).
        if ! heavy "speed-base-objects" sh -c "cd '$speed_base_wt' && make objects"; then
            tool_failed "could not build objects in the speed base tree"
            return 1
        fi
        if ! heavy "speed-base-libs" sh -c "cd '$speed_base_wt' && make -o avra libs"; then
            tool_failed "could not build libs in the speed base tree"
            return 1
        fi
    fi
}

# ONE COLD `/usr/bin/time -l` run of `$1/build/avra.land build --time
# packages/cli`, tagged `$2` for its own log. Asserts a cold `held
# 0/` — a warm hit would have examined nothing, which is a TOOL
# failure, never a measurement. Answers through globals
# (`speed_run_instr`, `speed_run_footprint`, `speed_run_wall_ms`,
# `speed_run_phases`), the shape a POSIX fn returns a small record in.
speed_one_run() {
    tree="$1"
    tag="$2"
    cd "$tree"
    move_caches_aside "$tree" > /dev/null 2>&1
    log="$(log_of "speed-$tag")"
    /usr/bin/time -l build/avra.land build --time packages/cli > "$log" 2>&1
    st=$?
    if [ "$st" -ne 0 ]; then
        echo "land: speed: the $tag build failed (exit $st) — $log" >&2
        return 1
    fi
    if ! grep -q 'held 0/' "$log" || grep -q 'cache hit' "$log"; then
        tool_failed "the speed gate's $tag run was not cold — a held file or a cached object in $log"
        return 1
    fi
    speed_run_instr="$(grep -oE '[0-9]+ +instructions retired' "$log" | awk '{print $1}' | head -1)"
    speed_run_footprint="$(grep -oE '[0-9]+ +peak memory footprint' "$log" | awk '{print $1}' | head -1)"
    speed_run_wall_ms="$(awk '{for(i=1;i<=NF;i++) if($i=="real"){printf "%.0f", $(i-1)*1000; exit}}' "$log")"
    speed_run_phases="$(grep -oE '^time: .*' "$log" | tail -1)"
    if [ -z "$speed_run_instr" ] || [ -z "$speed_run_footprint" ]; then
        tool_failed "the speed gate's $tag run has no instructions/footprint in $log (\`/usr/bin/time -l\` is macOS-only)"
        return 1
    fi
    return 0
}

median3() { printf '%s\n%s\n%s\n' "$1" "$2" "$3" | sort -n | sed -n '2p'; }

# The baseline's newest (last) data line, comments dropped, or empty
# when there is none yet. `||`, never `&&`: a missing file must answer
# empty at exit 0, not fail the assignment that reads it under `set -e`
# (the same trap `out="$(ratchet_check …)"` fell into above).
speed_baseline_last() {
    [ -f "$1" ] || return 0
    grep -v '^#' "$1" 2>/dev/null | tail -n 1
    return 0
}

# 1 when `instr`/`rss` cross either threshold against the baseline's
# last line (+1.0% instructions, +10% peak footprint) — the trigger for a
# median-of-3 remeasurement, never itself a verdict.
speed_over_threshold() {
    file="$1"
    instr="$2"
    rss="$3"
    line="$(speed_baseline_last "$file")"
    [ -z "$line" ] && { echo 0; return; }
    old_instr="$(printf '%s' "$line" | awk '{print $2}')"
    old_footprint="$(printf '%s' "$line" | awk '{print $3}')"
    over=0
    if [ -n "$old_instr" ] && [ "$old_instr" -gt 0 ] 2>/dev/null; then
        awk -v n="$instr" -v o="$old_instr" 'BEGIN{exit !(((n-o)*100.0/o)>1.0)}' && over=1
    fi
    if [ -n "$old_footprint" ] && [ "$old_footprint" -gt 0 ] 2>/dev/null; then
        awk -v n="$rss" -v o="$old_footprint" 'BEGIN{exit !(((n-o)*100.0/o)>10.0)}' && over=1
    fi
    echo "$over"
}

# THE GATE ITSELF — standalone-callable: `sh tools/land.sh --call
# speed_gate <base-sha-tree> <product> [<baseline-wt>] [<label>]`.
# `<base-sha-tree>` is already `make -o avra libs`-built (speed_base_tree,
# or PERF's own); `<baseline-wt>`, default `<base-sha-tree>` itself,
# is where tools/speed.baseline is read (never written here — see
# speed_refresh, the only writer, run only after a green landing).
speed_gate() {
    tree="$1"
    product="$2"
    baseline_wt="${3:-$tree}"
    label="${4:-standalone}"
    baseline_file="$baseline_wt/tools/speed.baseline"

    mkdir -p "$tree/build"
    cp "$product" "$tree/build/avra.land"
    chmod +x "$tree/build/avra.land"

    speed_one_run "$tree" run1 || return 1
    instr="$speed_run_instr"
    rss="$speed_run_footprint"
    wall_ms="$speed_run_wall_ms"
    phases="$speed_run_phases"
    note="one run"
    if [ "$(speed_over_threshold "$baseline_file" "$instr" "$rss")" -eq 1 ]; then
        echo "land: speed: run1 crossed a threshold — remeasuring twice more for a median of 3" >&2
        speed_one_run "$tree" run2 || return 1
        i2="$speed_run_instr"; r2="$speed_run_footprint"
        speed_one_run "$tree" run3 || return 1
        i3="$speed_run_instr"; r3="$speed_run_footprint"
        instr="$(median3 "$instr" "$i2" "$i3")"
        rss="$(median3 "$rss" "$r2" "$r3")"
        note="median of 3 runs"
    fi

    line="$(speed_baseline_last "$baseline_file")"
    old_sha=""
    old_instr=""
    old_footprint=""
    if [ -n "$line" ]; then
        old_sha="$(printf '%s' "$line" | awk '{print $1}')"
        old_instr="$(printf '%s' "$line" | awk '{print $2}')"
        old_footprint="$(printf '%s' "$line" | awk '{print $3}')"
    fi
    reason="${AVRA_LAND_SPEED_OK:-}"
    ipct="n/a"
    rpct="n/a"
    # `regressed` and `fail` are DIFFERENT questions: a run past
    # threshold is a regression whether or not a reason excuses it,
    # and only a regression with NO reason is a FAIL — collapsing them
    # into one flag (an earlier draft's `&& [ -z "$reason" ] &&
    # fail=1`) meant a signed run never set anything, so its own
    # reason was never queued for the chore commit to sign.
    regressed=0
    fail=0
    if [ -n "$old_instr" ] && [ "$old_instr" -gt 0 ] 2>/dev/null; then
        ipct="$(awk -v n="$instr" -v o="$old_instr" 'BEGIN{printf "%+.2f", (n-o)*100.0/o}')"
        if awk -v p="$ipct" 'BEGIN{exit !(p>1.0)}'; then
            regressed=1
            [ -z "$reason" ] && fail=1
        fi
    fi
    if [ -n "$old_footprint" ] && [ "$old_footprint" -gt 0 ] 2>/dev/null; then
        rpct="$(awk -v n="$rss" -v o="$old_footprint" 'BEGIN{printf "%+.2f", (n-o)*100.0/o}')"
        if awk -v p="$rpct" 'BEGIN{exit !(p>10.0)}'; then
            regressed=1
            [ -z "$reason" ] && fail=1
        fi
    fi
    if [ "$regressed" -eq 1 ] && [ -n "$reason" ]; then
        echo "speed: ${reason}" >> "$scratch/ratchet-overrides"
    fi
    word="PASS"
    [ "$fail" -eq 1 ] && word="FAIL"
    echo "land: speed: $instr instr (${ipct}% vs ${old_sha:-none}), footprint $rss (${rpct}%) — $word ($note, wall ${wall_ms}ms)" >&2
    [ -n "$phases" ] && echo "land: speed: $phases" >&2
    speed_gate_instr="$instr"
    speed_gate_footprint="$rss"
    [ "$fail" -eq 0 ]
}

# Runs ONLY after a green speed_gate: the product this landing built,
# over ITS OWN packages/cli (main's own input the moment this landing
# lands) — the row the NEXT landing's fixed input will compare
# against. `$1` is the landing's own worktree (already built).
speed_refresh() {
    # NEVER named `wt`: move_caches_aside (called inside speed_one_run,
    # below) sets a GLOBAL of that exact name — POSIX sh has no
    # function-local scope — which clobbered this fn's own caller's
    # `wt` the first time this was written, before the rename.
    land_wt="$1"
    sha="$(git -C "$land_wt" rev-parse HEAD)"
    [ -n "$speed_base_wt" ] || speed_base_wt="$(speed_side_path "$land_wt")"
    if ! speed_base_tree "$land_wt" "$sha"; then
        echo "land: speed: the refresh tree could not be made — the baseline was not advanced" >&2
        return 0
    fi
    cp "$land_wt/build/avra" "$speed_base_wt/build/avra.land"
    if ! speed_one_run "$speed_base_wt" refresh; then
        echo "land: speed: the refresh run failed — the baseline was not advanced" >&2
        return 0
    fi
    reason="${AVRA_LAND_SPEED_OK:--}"
    printf '%s %s %s %s\n' "$sha" "$speed_run_instr" "$speed_run_footprint" "$reason" >> "$(stage_baseline "$land_wt" speed.baseline)"
    echo "land: speed: baseline advanced — $sha $speed_run_instr $speed_run_footprint $reason" >&2
}

# The job-pool wrapper: the base tree (once), the copy in, the gate,
# then — only on a pass — the refresh. `land_wt`, not `wt` — see
# speed_refresh's own note.
speed_gate_step() {
    land_wt="$1"
    base_sha="$2"
    label="${3:-$branch}"
    speed_base_wt="$(speed_side_path "$land_wt")"
    speed_base_tree "$land_wt" "$base_sha" || return 1
    cd "$land_wt"
    if [ ! -x build/avra ]; then
        tool_failed "no product at $land_wt/build/avra for the speed gate"
        return 1
    fi
    st=0
    pair_toolchain "$land_wt" "$speed_base_wt"
    speed_gate "$speed_base_wt" "$land_wt/build/avra" "$speed_base_wt" "$label" || st=$?
    if [ "$st" -eq 0 ]; then
        speed_refresh "$land_wt"
    fi
    return "$st"
}

# ── ONE BUILD GENERATION ──────────────────────────────────────────────
# A failure of the landing machinery itself, never a branch's verdict:
# recorded so a batch reports it instead of bisecting it into culprits.
tool_failed() {
    echo "$1" > "$scratch/tool-failure"
    echo "land: TOOL FAILURE — $1" >&2
}

build_generation() {
    wt="$1"
    n="$2"
    cd "$wt"
    if [ ! -x build/avra ]; then
        echo "land: no standing compiler at $wt/build/avra — bootstrapping one from the seed" >&2
        if ! heavy "bootstrap-$n" make bootstrap || [ ! -x build/avra ]; then
            tool_failed "could not bootstrap a compiler at $wt/build/avra"
            return 1
        fi
    fi
    cp build/avra "build/avra.pre.$n" 2>/dev/null || true
    # Every C object, not only the runtime: a tree's own objects lag
    # the C a merge brought in.
    if ! heavy "build-$n-objects" make objects; then
        [ -f "build/avra.pre.$n" ] && cp "build/avra.pre.$n" build/avra
        return 1
    fi
    st=0
    heavy "build-$n-compile" build/avra build packages/cli || st=$?
    if [ "$st" -ne 0 ]; then
        [ -f "build/avra.pre.$n" ] && cp "build/avra.pre.$n" build/avra
        # 126/127: the compiler could not be run at all.
        if [ "$st" -eq 126 ] || [ "$st" -eq 127 ]; then tool_failed "the compiler at $wt/build/avra could not run (exit $st)"; fi
        return 1
    fi
    cp packages/cli/src/main build/avra
    codesign -f -s - build/avra
    rm -f packages/cli/src/main packages/cli/src/main.av.ll
    # A package's C library is linked by the suites that bind it; `-o avra`
    # keeps make from rebuilding the compiler under it.
    heavy "build-$n-libs" make -o avra libs
}

# ── THE PARALLEL JOB POOL — bounded by AVRA_LAND_JOBS, private to this
# run. The write race that once forced every check to run one at a
# time (avra-8sb5.57.41) is fixed (content-keyed objects, publish by
# rename); a job's own slot is freed by a STATUS FILE, never `kill -0`
# on its pid — a finished-but-unwaited child is still a live pid to
# `kill -0` (a zombie), so polling pids would never see a slot free.
# Whether a landing reaches the compiler: its build (the Makefile),
# its seed, any C outside packages/ (package C is its package's own,
# reached through the import closure; every other C file links into
# the compiler or its runtime), or any package the cli (the
# compiler's root) imports, however deep — the closure
# affected_packages.sh already computes names packages/cli exactly then.
compiler_reached() {
    if printf '%s\n' "$4" | grep -qE '^Makefile$|^bootstrap/|^(runtime|backend)/'; then return 0; fi
    if [ -n "$(printf '%s\n' "$4" | grep -E '\.[ch]$' | grep -v '^packages/')" ]; then return 0; fi
    reached="$(sh "$tools_dir/affected_packages.sh" "$2" "$3" "$1" 2>/dev/null)" || return 0
    printf '%s\n' "$reached" | grep -qxE '(packages/)?cli'
}

job_pool_reset() {
    : > "$scratch/jobs.list"
    rm -rf "$scratch/jobs"
    mkdir -p "$scratch/jobs"
}

# A job's status file, its label made one path segment.
job_status_file() { echo "$scratch/jobs/$(printf '%s' "$1" | tr '/ ' '__').status"; }

job_running() {
    n=0
    while read -r pid label; do
        [ -z "$pid" ] && continue
        [ -f "$(job_status_file "$label")" ] || n=$((n + 1))
    done < "$scratch/jobs.list"
    echo "$n"
}

# job_launch <label> <command...> — backgrounds <command...>, waiting
# for a free slot first. `set +e` inside the subshell: `;`-joined under
# an inherited errexit ends the subshell at the command's own failure,
# before the status file is written — the same trap capped.sh's own
# capture guards against, one level up. AVRA_LAND_PARALLEL_SLOT tells a
# nested heavy() call to skip the machine-wide slot.sh(2) gate, which
# this pool replaces for its own jobs.
job_launch() {
    label="$1"
    shift
    cap="$AVRA_LAND_JOBS"
    case "$cap" in ''|*[!0-9]*) cap=4 ;; esac
    [ "$cap" -ge 1 ] || cap=1
    while [ "$(job_running)" -ge "$cap" ]; do sleep 0.5; done
    status_file="$(job_status_file "$label")"
    ( set +e; AVRA_LAND_PARALLEL_SLOT=1 "$@"; st=$?; echo "$st" > "$status_file"; exit "$st" ) &
    echo "$! $label" >> "$scratch/jobs.list"
}

# Waits for every launched job, fail-closed: a wait whose status cannot
# be read counts as a failure, never a pass (`wait … || st=$?`, never
# `st=$?` after an else-less `if`).
job_wait_all() {
    : > "$scratch/jobs.result"
    overall=0
    while read -r pid label; do
        [ -z "$pid" ] && continue
        st=0
        wait "$pid" || st=$?
        echo "$label $st" >> "$scratch/jobs.result"
        [ "$st" -ne 0 ] && overall=1
    done < "$scratch/jobs.list"
    return "$overall"
}

# Every failed job, named with its log path — printed once every job
# is collected, so no two failures' own output can interleave (the
# "land: FAILED at '<name>' (exit N) — log: …" shape other tools grep
# for stays exactly as fail_report already writes it).
report_parallel_failures() {
    while read -r label st; do
        [ "$st" -eq 0 ] && continue
        fail_report "$label" "$st" "$(log_of "$label")"
    done < "$scratch/jobs.result"
}

# One package's idioms check — `--call`-invoked (never a bare function
# name) because heavy() hands its command to memcap.sh, a SEPARATE
# process that never sourced this script and knows no shell function.
idioms_step() {
    wt="$1"
    shift
    cd "$wt"
    st=0
    for pkg in "$@"; do
        ./build/avra check "packages/$pkg" --baseline tools/idioms.baseline || st=1
    done
    return "$st"
}

# ── AFFECTED-PACKAGE TESTS, IDIOMS, FMT-LOSSLESS AND SEED-CHECK — ONE
# PARALLEL BATCH, bounded by AVRA_LAND_JOBS. cache-attacks stands
# apart, sequential: it `rm -rf`s the shared .avra-cache as its own
# first line (tools/cache_attacks.sh), and a store yanked out from
# under a concurrently-reading test or idioms job is a spurious
# failure, not a finding — a different hazard than the write race the
# content-keyed/rename-publish fix closed.
#
# IDIOMS OVER `affected` IS SOUND, NOT JUST FASTER: the baseline lists
# sites per FILE, so an untouched package's own files cannot gain one.
# Checking a package also reports its DEPENDENCIES' sites, so a changed
# dependency can change findings in every DEPENDENT — but `affected`
# already closes over exactly that (every touched package, plus every
# package that depends on one, to a fixed point), the same reasoning
# `affected_packages.sh` already applies for tests. A package outside
# that closure depends on nothing that changed, so nothing it is
# checked over changed either. A compiler change makes `affected` every
# package already (affected_packages.sh's own compiler_changed case),
# so this needs no separate "checked everything" branch.
run_checks() {
    wt="$1"
    base_sha="$2"
    head_sha="$3"
    suffix="$4"
    compiler_changed="$5"
    has_av="${6:-1}"
    # Space-joined, not newline-separated: `listed` (a plain " $x "
    # substring test) needs a space on both sides of every name, which
    # a bare newline-separated capture does not give it — `for pkg in
    # $affected` word-splits on either, so this changes nothing there.
    affected="$(sh "$tools_dir/affected_packages.sh" "$base_sha" "$head_sha" "$wt" | tr '\n' ' ')"

    job_pool_reset
    # LONGEST JOBS LAUNCH FIRST — under a job cap, a job LAUNCHED late
    # STARTS late: a timed landing showed idioms starting at +51s and
    # seed-check at +98s, purely because shorter jobs were called
    # ahead of them in this loop. Measured on the same tree: std-avrac
    # 165s, idioms 148s, seed-check 114s, cli 105s, std-relation 48s,
    # fmt-lossless 29s, everything else <=12s — the speed and Linux
    # gates run a full second build (or a whole Sprite) each, so they
    # slot in right after seed-check, ahead of cli.
    if listed std-avrac "$affected"; then
        job_launch "test-std-avrac$suffix" heavy "test-std-avrac$suffix" sh -c "cd '$wt' && build/avra test packages/std-avrac"
    fi
    if [ "$has_av" -eq 1 ]; then
        job_launch "idioms$suffix" heavy "idioms$suffix" sh "$self" --call idioms_step "$wt" $affected
    else
        skipped "idioms and fmt-lossless$suffix" ".av file"
    fi
    if [ "$compiler_changed" -eq 1 ]; then
        job_launch "seed-check$suffix" seed_policy "$wt" "$suffix" "$branch"
    fi
    if [ "${AVRA_LAND_SPEED_GATE:-1}" = "1" ]; then
        job_launch "speed$suffix" heavy "speed$suffix" sh "$self" --call speed_gate_step "$wt" "$base_sha" "$branch"
    else
        echo "land: skipped the speed gate$suffix: AVRA_LAND_SPEED_GATE is off" >&2
    fi
    if listed cli "$affected"; then
        job_launch "test-cli$suffix" heavy "test-cli$suffix" sh -c "cd '$wt' && build/avra test packages/cli"
    fi

    # Everything else, in any order.
    for pkg in $affected; do
        [ "$pkg" = "std-avrac" ] && continue
        [ "$pkg" = "cli" ] && continue
        job_launch "test-$pkg$suffix" heavy "test-$pkg$suffix" sh -c "cd '$wt' && build/avra test packages/$pkg"
    done
    if [ "$has_av" -eq 1 ] && [ "$compiler_changed" -eq 1 ]; then
        # The fail-fast pre-build run (check_phase, standing compiler)
        # already answered for a compiler-unchanged landing; this one
        # re-asks with the compiler THIS landing built, the only copy
        # that can speak for a formatter this landing itself moved.
        job_launch "fmt-lossless$suffix" heavy "fmt-lossless$suffix" sh -c "cd '$wt' && make fmt-lossless"
    fi
    if [ "${AVRA_LAND_WARM_GATE:-1}" = "1" ]; then
        job_launch "warm-reuse$suffix" heavy "warm-reuse$suffix" sh "$self" --call warm_gate_step "$wt"
    else
        echo "land: skipped warm-reuse gate$suffix: AVRA_LAND_WARM_GATE is off" >&2
    fi

    if ! job_wait_all; then
        echo "land: a parallel check failed:" >&2
        report_parallel_failures
        return 1
    fi
}

# ── THE WHOLE PIPELINE, RUN ONCE AND RE-RUN ONCE ON A LOST RACE ───────
# `suffix` keeps a re-run's logs apart from the first attempt's.
run_pipeline() {
    suffix="$1"
    old_main_sha="$(git -C "$main_wt" rev-parse HEAD)"

    light "merge$suffix" merge_main_in "$branch_wt"

    new_branch_sha="$(git -C "$branch_wt" rev-parse HEAD)"
    diff_files="$(git -C "$branch_wt" diff --name-only "$old_main_sha...$new_branch_sha")"
    check_phase "$branch_wt" "$old_main_sha" "$new_branch_sha" "$suffix" "$diff_files"
}

# ── WHAT A DIFF CAN AFFECT DECIDES WHAT RUNS ──────────────────────────
# Every step a diff cannot affect is skipped, and says so. A diff of
# tools/ and docs/ alone runs land_test.sh (when tools/ moved) and
# nothing else; no .av file skips idioms and fmt-lossless; a compiler
# the diff does not reach skips the second build, seed-check and
# cache-attacks.
diff_touches() { printf '%s\n' "$1" | grep -qE "$2"; }
diff_beyond() { printf '%s\n' "$1" | grep -vE "$2" | grep -q .; }
skipped() { echo "land: skipped $1: diff touches no $2" >&2; }

# ── A GATE SCRIPT'S OWN CHANGE RUNS ITS OWN GATE ─────────────────────
# The tools-only rule above runs land_test.sh (land.sh's own fixtures)
# for ANY tools/ touch, which proves land.sh's OWN mechanics — never
# that a changed GATE SCRIPT still behaves against the real tree. A
# tools-only landing that edited tools/cache_attacks.sh once reached
# main having run only land_test.sh, the script itself untested.
gate_script_step() {
    case "$1" in
        tools/cache_attacks.sh) echo cache-attacks ;;
        tools/idioms*) echo idioms ;;
        tools/fmt_lossless.sh) echo fmt-lossless ;;
        tools/seed_guard.sh) echo seed-check ;;
        *) echo "" ;;
    esac
}

# Every DISTINCT step the diff's changed files map to, in one FIXED
# order — never the diff's own file order, which a log or a test
# reading it must not have to depend on.
gate_steps_touched() {
    diff="$1"
    steps=""
    for want in cache-attacks idioms fmt-lossless seed-check; do
        for f in $(printf '%s\n' "$diff"); do
            [ "$(gate_script_step "$f")" = "$want" ] || continue
            steps="$steps $want"
            break
        done
    done
    printf '%s' "$steps"
}

# A mapped step needs a real compiler, which a tools-only diff never
# built — gen 1 only (the compiler source did not change, so a second
# build would compile nothing new).
gate_scripts_step() {
    wt="$1"
    suffix="$2"
    diff="$3"
    steps="$(gate_steps_touched "$diff")"
    [ -n "$(printf '%s' "$steps" | tr -d '[:space:]')" ] || return 0
    echo "land: a changed tools/ script is itself a gate ($(printf '%s' "$steps" | sed 's/^ //')) — building gen 1 to run it for real" >&2
    if ! ( build_generation "$wt" "1$suffix" ); then
        echo "land: build generation 1$suffix failed (needed for:$steps)" >&2
        return 1
    fi
    st=0
    for step in $steps; do
        case "$step" in
            cache-attacks) heavy "cache-attacks$suffix" sh -c "cd '$wt' && make cache-attacks" || st=1 ;;
            idioms) heavy "idioms$suffix" sh "$self" --call idioms_step "$wt" $(cd "$wt" && for p in packages/*/; do basename "$p"; done) || st=1 ;;
            fmt-lossless) heavy "fmt-lossless$suffix" sh -c "cd '$wt' && make fmt-lossless" || st=1 ;;
            seed-check) heavy "seed-check$suffix" sh -c "cd '$wt' && make seed-check" || st=1 ;;
        esac
    done
    return "$st"
}

check_phase() {
    wt="$1"
    base_sha="$2"
    head_sha="$3"
    suffix="$4"
    diff="$5"
    if ! diff_beyond "$diff" '^(tools|docs)/'; then
        skipped "builds and package checks$suffix" "code outside tools/ or docs/"
        if diff_touches "$diff" '^tools/'; then
            heavy "land-test$suffix" sh -c "cd '$wt' && sh tools/land_test.sh"
            if ! gate_scripts_step "$wt" "$suffix" "$diff"; then
                return 1
            fi
            return 0
        fi
        skipped "land-test$suffix" "tools/"
        return 0
    fi
    compiler_changed=0
    if compiler_reached "$wt" "$base_sha" "$head_sha" "$diff"; then compiler_changed=1; fi
    echo "land: compiler changed in this landing: $compiler_changed" >&2
    has_av=0
    if diff_touches "$diff" '\.av$'; then has_av=1; fi

    # FAIL FAST: a whole-tree fmt-lossless check, BEFORE any build, with
    # whatever compiler already stands here — the formatter's own cache
    # makes this cheap now (see the file header), so there is nothing
    # to gain by waiting for a build first. Skipped exactly like idioms
    # when the diff touches no `.av` file at all.
    if [ "$has_av" -eq 1 ]; then
        if ! heavy "fmt-lossless-fast$suffix" sh -c "cd '$wt' && make fmt-lossless"; then
            return 1
        fi
    else
        skipped "fmt-lossless (fast)$suffix" ".av file"
    fi

    linux_launch "$wt" "$base_sha" "$head_sha" "$suffix"
    st=0
    local_checks "$wt" "$base_sha" "$head_sha" "$suffix" || st=$?
    linux_collect "$st" || st=1
    [ "$st" -eq 0 ] || return 1

    # Every check is green: the staged baselines land in the tree, and
    # one commit carries them with the seed.
    apply_staged_baselines "$wt"
    light "chore-commit$suffix" commit_chore_if_moved "$wt" "$branch"
}

# THE LINUX GATE RUNS REMOTELY, so it takes no local slot and starts
# before the local builds: the Sprite builds its own compiler from the
# merged tree while this machine builds ours.
linux_pid=""
linux_launch() {
    linux_pid=""
    if [ "${AVRA_LAND_LINUX:-1}" != "1" ]; then
        echo "land: skipped the Linux gate$4: AVRA_LAND_LINUX is off" >&2
        return 0
    fi
    linux_pkgs="$(sh "$tools_dir/affected_packages.sh" "$2" "$3" "$1" 2>/dev/null)" || linux_pkgs=""
    if [ -z "$(printf '%s' "$linux_pkgs" | tr -d '[:space:]')" ]; then
        skipped "the Linux gate$4" "affected package"
        return 0
    fi
    linux_suffix="$4"
    linux_wt="$1"
    ( AVRA_LAND_PARALLEL_SLOT=1 heavy "linux$4" sh "$self" --call linux_gate_step "$1" $linux_pkgs ) &
    linux_pid=$!
}

# Whether a failed Linux leg ran against a seed this landing has since
# re-emitted: the leg synced the tree before seed-check moved the seed,
# so a Sprite whose compiler cannot read HEAD had no seed that could.
linux_saw_old_seed() {
    [ "$2" -ne 0 ] || return 1
    ! git -C "$1" diff --quiet -- bootstrap/seed.ll bootstrap/seed.sources 2>/dev/null
}

# The Linux gate's verdict, once the local checks are done; a local
# failure stops it rather than waiting it out.
linux_collect() {
    [ -n "$linux_pid" ] || return 0
    if [ "$1" -ne 0 ]; then
        kill "$linux_pid" 2>/dev/null
        wait "$linux_pid" 2>/dev/null
        return 0
    fi
    lst=0
    wait "$linux_pid" || lst=$?
    grep -h '^land-linux: ' "$(log_of "linux$linux_suffix")" 2>/dev/null | sed 's/^land-linux: /land: linux: /' >&2
    if linux_saw_old_seed "$linux_wt" "$lst"; then
        echo "land: linux: the leg ran before the seed was re-emitted — once more, with the new seed" >&2
        rm -f "$scratch/tool-failure"
        lst=0
        AVRA_LAND_PARALLEL_SLOT=1 heavy "linux-reseeded$linux_suffix" sh "$self" --call linux_gate_step "$linux_wt" $linux_pkgs || lst=$?
        grep -h '^land-linux: ' "$(log_of "linux-reseeded$linux_suffix")" 2>/dev/null | sed 's/^land-linux: /land: linux: /' >&2
    fi
    return "$lst"
}

# Builds, the local pool and cache-attacks.
local_checks() {
    wt="$1"
    base_sha="$2"
    head_sha="$3"
    suffix="$4"
    # A SUBSHELL each: `build_generation`'s own `cd "$wt"` must not
    # leak into the steps after it.
    if ! ( build_generation "$wt" "1$suffix" ); then
        echo "land: build generation 1$suffix failed" >&2
        return 1
    fi
    if [ "$compiler_changed" -eq 1 ]; then
        if ! ( build_generation "$wt" "2$suffix" ); then
            echo "land: build generation 2$suffix failed" >&2
            return 1
        fi
    else
        skipped "the second build and seed-check$suffix" "compiler source"
    fi

    if ! run_checks "$wt" "$base_sha" "$head_sha" "$suffix" "$compiler_changed" "$has_av"; then
        echo "land: a check failed (an affected package's tests, idioms, fmt-lossless, or seed-check)" >&2
        return 1
    fi

    if [ "$compiler_changed" -eq 0 ]; then
        skipped "cache-attacks$suffix" "compiler source"
    elif ! heavy "cache-attacks$suffix" sh -c "cd '$wt' && make cache-attacks"; then
        return 1
    fi
}

# ── THE SEED POLICY: CHECK FIRST, EMIT ONLY ON FAILURE ────────────────
# `tools/seed_guard.sh` now REPORTS a lagging seed rather than
# refusing it (SEED_STRICT=1 restores the refusal) — "the seed
# compiles HEAD" stays the hard gate, which `make seed-check` alone
# still tests. Re-emitting on EVERY landing paid for a whole-package
# `avra emit` whether or not the seed had actually moved; checking
# first and emitting only when the check fails pays that cost only
# when it is owed. The FIRST check's own failure is not reported as a
# land failure — it is the ordinary signal to refresh — so it runs
# quietly, capped and slotted like any heavy step, but through its own
# name; only a check that STILL fails after a fresh emit is fatal.
# `label` is the landing branch's own name, taken as an argument (never
# the global `branch`) so a call through job_launch — a fork of this
# same process, never a `--call` re-exec — reads the right one even
# when nothing exported `branch` into a re-exec's environment.
seed_policy() {
    wt="$1"
    suffix="$2"
    label="${3:-$branch}"
    log1="$(log_of "seed-check$suffix")"
    echo "land: seed-check (first pass) …" >&2
    t_start="$(date +%s)"
    st=0
    sh "$tools_dir/capped.sh" "$log1" 2000000 sh "$tools_dir/memcap.sh" "${AVRA_MEMCAP_MB:-4000}" sh -c "cd '$wt' && make seed-check" || st=$?
    timeline_emit "seed-check$suffix" "$t_start" "$st"
    if [ "$st" -eq 0 ]; then
        echo "land: seed-check passed on the first try — seed already matches HEAD, no emit" >&2
        return 0
    fi
    echo "land: seed-check failed on the first try — the seed lags HEAD; re-emitting" >&2
    heavy "seed-emit$suffix" sh -c "cd '$wt' && make seed"
    # Committed once, later, alongside any moved ratchet baseline —
    # see commit_chore_if_moved, run by check_phase after every job in
    # the pool (this one included) has finished.
    heavy "seed-check-2$suffix" sh -c "cd '$wt' && make seed-check"
    echo "land: seed-check passed after a fresh emit" >&2
}

try_ff() { AVRA_LANDING=1 git -C "$main_wt" merge --ff-only "$branch"; }

# MAIN'S CHECKOUT RUNS WHAT MAIN SAYS: after a landing that reached the
# compiler, the landing tree's fixed-point compiler and runtime library
# replace main's own, so a probe run from main answers for main. Each is
# staged beside its target and renamed into place, so a process already
# running the old binary keeps its file.
refresh_main_compiler() {
    src="$1"
    dst="$2"
    [ "${compiler_changed:-0}" -eq 1 ] || return 0
    if [ ! -x "$src/build/avra" ]; then
        echo "land: no compiler in $src to refresh main's with" >&2
        return 0
    fi
    mkdir -p "$dst/build"
    for f in build/avra build/libavra_runtime.a; do
        [ -f "$src/$f" ] || continue
        cp -p "$src/$f" "$dst/$f.land-$$" && mv -f "$dst/$f.land-$$" "$dst/$f" ||
            { echo "land: could not refresh $dst/$f" >&2; return 0; }
    done
    echo "land: refreshed main's compiler from $src"
}

# Whether main's ref moved off `base`. A fast-forward that fails while
# the ref stands still failed for its own reason, and git's words say it.
main_moved_since() { [ "$(git -C "$main_wt" rev-parse refs/heads/main)" != "$1" ]; }

# Stops the landing with git's own refusal when main did not move.
ff_refused() {
    echo "land: the fast-forward was refused and main did not move — git says:" >&2
    cat "$1" >&2
    exit 1
}

# ══ BATCH MODE: SEVERAL BRANCHES, ONE TREE, ONE BUILD, ONE CHECK ═════
# `land.sh a b c` merges main and every named branch into ONE scratch
# integration branch, builds and checks that ONCE, then fast-forwards
# main to it — never the per-branch dance a single landing runs three
# times over. A batch failure first tries DROP BY FILE (bisect_land's
# own `batch_failed_files`/`sole_owner`): when the failing step's log
# names source files (fmt-lossless's differing paths, idioms' violation
# lines) and every one of them traces to ONE branch's own diff, that
# branch is the culprit with no further building needed — dropped, and
# the rest retried as one attempt. Only when the named files do not
# settle on one branch (or nothing failed in a file-naming way) does it
# fall back to BISECTING: the whole set splits in half and each half is
# tried FRESH from main; a half that still fails splits again (drop by
# file tried again at each node), down to a single branch, named a
# CULPRIT rather than retried further. The surviving halves are
# recombined into one final integration and built/checked once more
# (two branches that are each fine alone can still disagree combined,
# so that combination gets its own real answer, not an assumption).
#
# The batch integration lives in ONE reusable worktree+branch — reset
# to main's CURRENT tip before every attempt, never removed and
# re-added, since a bisection tries many attempts in one run. Its
# path is overridable (AVRA_LAND_BATCH_WT) so a fixture never touches
# the real one. By default it stands beside main's own worktree, at a
# physical path: a tree under a symlinked directory (/tmp is one) reads
# every file path relative to the wrong root, and no baseline matches.
batch_wt="${AVRA_LAND_BATCH_WT:-}"
batch_branch="land/batch-integration"

# Resets the integration worktree to main's current tip — creating it
# first if this is the first attempt this process has made.
reset_batch_wt() {
    [ -n "$batch_wt" ] || batch_wt="$(cd "$main_wt/.." && pwd -P)/avra-land-batch-wt"
    if [ ! -d "$batch_wt/.git" ] && [ ! -f "$batch_wt/.git" ]; then
        # Whatever stands at the path and is not a worktree is moved aside.
        if [ -e "$batch_wt" ]; then
            mkdir -p "$trash"
            mv "$batch_wt" "$trash/batch-tree-$$-$(date +%s)"
        fi
        mkdir -p "$(dirname "$batch_wt")"
        git -C "$main_wt" worktree add -q --detach "$batch_wt" main ||
            { tool_failed "could not make the batch tree at $batch_wt"; return 1; }
    fi
    # The batch branch may still be registered to an older tree.
    git -C "$batch_wt" checkout -q -f --ignore-other-worktrees -B "$batch_branch" main ||
        { tool_failed "could not check out the batch branch in $batch_wt"; return 1; }
    git -C "$batch_wt" reset -q --hard main && git -C "$batch_wt" clean -q -fd ||
        { tool_failed "could not reset the batch tree at $batch_wt"; return 1; }
    seed_compiler "$batch_wt"
}

# A fresh tree has no build/: it gets the newest standing compiler and
# its built objects, from the landing branch's own tree or main's.
seed_compiler() {
    from=""
    for w in "${branch_wt:-}" "$main_wt"; do
        [ -n "$w" ] && [ -x "$w/build/avra" ] || continue
        if [ -z "$from" ] || [ "$w/build/avra" -nt "$from/build/avra" ]; then from="$w"; fi
    done
    [ -n "$from" ] || return 0
    mkdir -p "$1/build"
    for f in "$from"/build/avra "$from"/build/*.o "$from"/build/*.a "$from"/build/*.dylib "$from"/build/*.d "$from"/build/*.sha; do
        [ -f "$f" ] && cp -p "$f" "$1/build/"
    done
    return 0
}

# ONE ATTEMPT: reset to main, merge every given branch in order, then
# the same build/check pipeline a single landing runs. Returns 0/1;
# never touches main itself — only try_ff, at the very end, does.
try_integration() {
    label="$1"
    shift
    echo "land: batch attempt [$label]: $*" >&2
    reset_batch_wt || return 1
    for b in "$@"; do
        b_safe="$(printf '%s' "$b" | tr '/ ' '__')"
        if ! merge_ref_in "$batch_wt" "refs/heads/$b" > "$(log_of "batch-merge-$label-$b_safe")" 2>&1; then
            echo "land: [$label] merge of $b failed" >&2
            return 1
        fi
    done

    old_main_sha="$(git -C "$main_wt" rev-parse HEAD)"
    new_sha="$(git -C "$batch_wt" rev-parse HEAD)"
    diff_files="$(git -C "$batch_wt" diff --name-only "$old_main_sha...$new_sha")"
    if ! check_phase "$batch_wt" "$old_main_sha" "$new_sha" "-batch-$label" "$diff_files"; then return 1; fi
    echo "land: batch attempt [$label] GREEN: $*" >&2
    return 0
}

# DROP BY FILE, NOT BISECT: a failing step whose LOG NAMES SOURCE
# FILES (fmt-lossless prints each differing path bare; idioms prints
# "  <file>\t[<kind>]\t<text>" per new violation) often already says
# who broke it, with no rebuild needed to find out. Two shapes read:
# an ABSOLUTE `.av` path alone on its line, under the batch tree's own
# root (fmt-lossless's `t.diffs`, `rooted()`-absolute); and idioms'
# own two-space-indented, tab-separated violation line. Both are
# stripped to a repo-relative path.
batch_failed_files() {
    label="$1"
    for name in "fmt-lossless-fast-batch-$label" "fmt-lossless-batch-$label" "idioms-batch-$label"; do
        log="$(log_of "$name")"
        [ -f "$log" ] || continue
        # `|| true` on each: a pattern that matches NOTHING in this log
        # exits 1 under `set -e`, which would otherwise abort this whole
        # function on the first empty pattern and never reach the ones
        # after it — a grep finding nothing is not a script failure.
        sed -n "s#^${batch_wt}/##p" "$log" 2>/dev/null | grep -E '\.av$' || true
        grep -E '^packages/.*\.av$' "$log" 2>/dev/null || true
        sed -n 's/^  \([^\t]*\)\t\[.*/\1/p' "$log" 2>/dev/null || true
    done | sort -u
}

# The one branch (of `$2..`) whose diff against `batch_base` touches
# `$1` — "" when no branch does, or more than one does, either of
# which is a file drop_by_file must not guess past.
file_owner() {
    f="$1"
    shift
    owner=""
    for b in "$@"; do
        if git -C "$main_wt" diff --name-only "$batch_base...refs/heads/$b" 2>/dev/null | grep -qxF "$f"; then
            if [ -n "$owner" ] && [ "$owner" != "$b" ]; then
                echo ""
                return 0
            fi
            owner="$b"
        fi
    done
    echo "$owner"
}

# The one branch (of `$2..`) that owns EVERY file `$1` names (space or
# newline separated) — "" the moment any file's owner is unclear,
# which is exactly when a plain drop is not honest and bisection is
# owed instead.
sole_owner() {
    files="$1"
    shift
    owner=""
    for f in $files; do
        b="$(file_owner "$f" "$@")"
        if [ -z "$b" ]; then
            echo ""
            return 0
        fi
        if [ -n "$owner" ] && [ "$owner" != "$b" ]; then
            echo ""
            return 0
        fi
        owner="$b"
    done
    echo "$owner"
}

# THE BISECTION: prints the surviving GREEN branch names (space
# separated) on stdout; prints each isolated CULPRIT, one per line,
# to stderr as "CULPRIT: <branch>". Recurses on halves, then on a
# recombination that itself turns out red — the same procedure
# either way, since "a set that fails" is the only fact it acts on.
bisect_land() {
    # shellcheck: word-splits on purpose — every element is one ref name
    set -- $*
    n=$#
    label="bisect-$n-$(echo "$*" |  tr ' /' '__'| cut -c1-40)"
    [ -f "$scratch/tool-failure" ] && return 1
    if try_integration "$label" "$@"; then
        echo "$@"
        return 0
    fi
    # The machinery failed, so no branch is judged.
    [ -f "$scratch/tool-failure" ] && return 1
    if [ "$n" -gt 1 ]; then
        files="$(batch_failed_files "$label")"
        if [ -n "$(printf '%s' "$files" | tr -d '[:space:]')" ]; then
            culprit="$(sole_owner "$files" "$@")"
            if [ -n "$culprit" ]; then
                echo "land: [$label] every named file traces to one branch — dropping it, no bisection" >&2
                echo "CULPRIT: $culprit" >&2
                rest=""
                for b in "$@"; do
                    [ "$b" = "$culprit" ] && continue
                    rest="$rest $b"
                done
                rest="${rest# }"
                if [ -z "$rest" ]; then return 1; fi
                drop_label="drop-$(echo "$rest" | tr ' /' '__' | cut -c1-40)"
                if try_integration "$drop_label" $rest; then
                    echo "$rest"
                    return 0
                fi
                [ -f "$scratch/tool-failure" ] && return 1
                # Red for a different reason now — the ordinary
                # bisection below takes it from here, over what remains.
                set -- $rest
                n=$#
            fi
        fi
    fi
    if [ "$n" -eq 1 ]; then
        echo "CULPRIT: $1" >&2
        return 1
    fi
    half=$(((n + 1) / 2))
    left=""
    right=""
    i=0
    for b in "$@"; do
        i=$((i + 1))
        if [ "$i" -le "$half" ]; then left="$left $b"; else right="$right $b"; fi
    done
    # `|| true` on EACH: a recursive call answering "no green branches
    # here" is a LEGITIMATE outcome (a lone culprit, or a half that is
    # all culprits), not a script error — but `set -e` does not know
    # that, and a bare `var=$(cmd)` assignment IS one of the shapes
    # -e treats as fatal even though it sits nowhere near an `if`.
    # Without this, isolating the very first culprit unwound the
    # WHOLE bisection immediately: main_batch's own top-level
    # `good=$(bisect_land …)` is exactly this shape, one level up.
    good_left="$(bisect_land $left)" || true
    good_right="$(bisect_land $right)" || true
    combined="$(printf '%s %s' "$good_left" "$good_right" | tr -s ' ')"
    combined="${combined# }"
    combined="${combined% }"
    if [ -z "$combined" ]; then
        return 1
    fi
    set -- $combined
    if [ "$#" -eq 1 ]; then
        # a single survivor needs no recombination check — it already
        # passed alone, in its own bisect_land call above.
        echo "$combined"
        return 0
    fi
    if try_integration "recombine-$(echo "$combined" |  tr ' /' '__'| cut -c1-40)" $combined; then
        echo "$combined"
        return 0
    fi
    echo "land: the surviving branches disagree recombined — bisecting them too" >&2
    bisect_land $combined
}

# ONE BATCH RUN over `branches`, the lock already held: sets `good` (the
# branches it landed or would land), `culprits`, and `landed` (main's new
# head, or empty), and `batch_note` (why nothing landed).
batch_core() {
    dry_run="$1"
    shift
    branches="$*"
    good=""
    culprits=""
    landed=""
    batch_note=""
    batch_base="$(git -C "$main_wt" rev-parse refs/heads/main)"
    [ -n "$batch_wt" ] || batch_wt="$(cd "$main_wt/.." && pwd -P)/avra-land-batch-wt"
    echo "land: batch of: $branches (tree $batch_wt)"

    # A whole batch failing is a truthful answer, never a script error.
    good="$(bisect_land $branches 2>"$(log_of batch-bisect-stderr)")" || true
    culprits="$(grep -h '^CULPRIT: ' "$(log_of batch-bisect-stderr)" 2>/dev/null | sed 's/^CULPRIT: //' | tr '\n' ' ')"
    cat "$(log_of batch-bisect-stderr)" >&2
    if [ -f "$scratch/tool-failure" ]; then
        good=""
        culprits=""
        batch_note="land: TOOL FAILURE, no branch judged — $(cat "$scratch/tool-failure")"
        return 0
    fi

    if [ -z "$(printf '%s' "$good" | tr -d '[:space:]')" ]; then
        batch_note="land: every branch in the batch failed — nothing to land"
        return 0
    fi
    echo "land: green subset: $good"
    if [ -n "$(printf '%s' "$culprits" | tr -d '[:space:]')" ]; then
        echo "land: culprit(s), excluded: $culprits"
    fi
    if [ "$dry_run" -eq 1 ]; then
        batch_note="land: --dry-run — skipping the fast-forward"
        return 0
    fi
    ff_log="$(log_of batch-ff)"
    if AVRA_LANDING=1 git -C "$main_wt" merge --ff-only "$batch_branch" > "$ff_log" 2>&1; then
        landed="$(git -C "$main_wt" rev-parse HEAD)"
        refresh_main_compiler "$batch_wt" "$main_wt"
        return 0
    fi
    if main_moved_since "$batch_base"; then
        batch_note="land: main moved during the batch — land it again once it settles"
    else
        batch_note="land: the fast-forward was refused and main did not move — git says: $(cat "$ff_log")"
    fi
}

# Whether `b` is among the space-separated `set`.
listed() { case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }

# ── THE TRAIN HAND-OFF (AVRA_LAND_TRAIN=1) ───────────────────────────
# docs/2026_09_29_LAND_TRAIN.md. Drop-in for `batch_core`, same
# contract (sets `good`, `culprits`, `landed`, `batch_note` — never a
# return value, exactly as batch_core's own callers already read it):
# tools/land_train.sh verifies the WHOLE queue's candidate ladder on
# Sprites, in parallel, and hands back the longest green prefix — this
# function never re-enters the FIFO lock train_ladder runs under none
# of (it takes none), and runs the ordinary local pipeline exactly
# ONCE, over that prefix alone, for the Mac-only half (speed, warm-
# reuse, codesign, the real fast-forward) — AVRA_LAND_LINUX=0 for that
# one pass, since the Linux suites already ran, MORE of them, once per
# candidate, on the Sprites the train just used.
train_core() {
    train_dry_run="$1"
    shift
    branches="$*"
    good=""
    culprits=""
    landed=""
    batch_note=""
    batch_base="$(git -C "$main_wt" rev-parse refs/heads/main)"
    [ -n "$batch_wt" ] || batch_wt="$(cd "$main_wt/.." && pwd -P)/avra-land-batch-wt"
    echo "land: train over: $branches"

    # A DETERMINISTIC scratch, named from THIS run's own — never left
    # for land_train.sh to mint its own under /tmp, which this
    # function could then never point back at to read its tool-failure
    # marker (a temp var read only from the ENVIRONMENT, never from a
    # child process's own private default).
    train_scratch="$scratch/train-ladder"
    ladder_log="$(log_of train-ladder)"
    good="$(AVRA_LAND_TRAIN_SCRATCH="$train_scratch" sh "$tools_dir/land_train.sh" --call train_ladder $branches 2>"$ladder_log")" || true
    cat "$ladder_log" >&2
    culprits="$(grep -h '^CULPRIT: ' "$ladder_log" 2>/dev/null | sed 's/^CULPRIT: //' | tr '\n' ' ')"
    if grep -q '^TOOLFAIL' "$ladder_log" 2>/dev/null || [ -f "$train_scratch/tool-failure" ]; then
        good=""
        culprits=""
        reason="$(cat "$train_scratch/tool-failure" 2>/dev/null || grep -h '^TOOLFAIL' "$ladder_log" | head -1)"
        batch_note="land: TOOL FAILURE in the train, no branch judged — see $ladder_log"
        # THE TOP-LEVEL SCRATCH, not the ladder's own nested one — this
        # is what finish_lock's exit_verdict reads to answer exit 3
        # ("NOT LANDED — tool failure") rather than the generic exit 1
        # a plain batch_note alone would fall through to.
        tool_failed "$reason"
        return 0
    fi
    if [ -z "$(printf '%s' "$good" | tr -d '[:space:]')" ]; then
        batch_note="land: every branch failed the train — nothing to land"
        return 0
    fi
    echo "land: train green prefix: $good"
    [ -n "$(printf '%s' "$culprits" | tr -d '[:space:]')" ] && echo "land: culprit(s), excluded: $culprits"
    if [ "$train_dry_run" -eq 1 ]; then
        batch_note="land: --dry-run — skipping the Mac finalization pass and the fast-forward"
        return 0
    fi
    AVRA_LAND_LINUX=0
    export AVRA_LAND_LINUX
    if ! try_integration "train-final" $good; then
        [ -f "$scratch/tool-failure" ] || batch_note="land: the train's own green prefix disagreed once combined and Mac-finalized — logs: $scratch/logs"
        return 0
    fi
    if git -C "$main_wt" merge --ff-only "$batch_branch" > "$(log_of train-ff)" 2>&1; then
        landed="$(git -C "$main_wt" rev-parse HEAD)"
        refresh_main_compiler "$batch_wt" "$main_wt"
        return 0
    fi
    if main_moved_since "$batch_base"; then
        batch_note="land: main moved during the train's finalization — land it again once it settles"
    else
        batch_note="land: the fast-forward was refused and main did not move — git says: $(cat "$(log_of train-ff)")"
    fi
}

# batch_core, or the train when AVRA_LAND_TRAIN=1 — the ONE place that
# decides which, so a queue is served identically either way from both
# of this file's own call sites.
dispatch_batch() {
    if [ "${AVRA_LAND_TRAIN:-0}" = "1" ]; then
        train_core "$@"
    else
        batch_core "$@"
    fi
}

main_batch() {
    dry_run="$1"
    shift
    branch="batch($*)"
    absorbed=""

    trap finish_lock EXIT
    trap 'release_lock_and_exit INT' INT
    trap 'release_lock_and_exit TERM' TERM
    acquire_lock

    main_wt="$(worktree_for_branch main)"
    if [ -z "$main_wt" ]; then
        echo "land: no worktree has 'main' checked out — \`git worktree list\`" >&2
        exit 1
    fi
    for b in "$@"; do
        if ! git -C "$main_wt" show-ref --verify --quiet "refs/heads/$b"; then
            echo "land: no branch '$b' — \`git branch --list\`" >&2
            exit 1
        fi
    done
    dispatch_batch "$dry_run" "$@"
    if [ -n "$batch_note" ] && [ -z "$landed" ]; then
        echo "$batch_note" >&2
        [ "$dry_run" -eq 1 ] && [ -n "$good" ] && [ -z "$(printf '%s' "$culprits" | tr -d '[:space:]')" ] && { verdict_ok=1; exit 0; }
        exit 1
    fi
    verdict_ok=1
    echo "LANDED $landed — $good"
    [ -z "$(printf '%s' "$culprits" | tr -d '[:space:]')" ]
}

# The holder with absorbed waiters: one batch over its own branch and
# theirs, each waiter handed its own branch's verdict.
land_absorbed() {
    d="$(tickets_dir)"
    riders=""
    for t in $absorbed; do riders="$riders $(ticket_field "$d/$t" branch)"; done
    echo "land: absorbing the queue behind ticket $ticket:$riders"
    dispatch_batch 0 "$branch" $riders
    for t in $absorbed; do
        b="$(ticket_field "$d/$t" branch)"
        if [ -n "$landed" ] && listed "$b" "$good"; then
            give_verdict "$d/$t" 0 "LANDED $landed — in a batch with: $good"
        elif listed "$b" "$culprits"; then
            give_verdict "$d/$t" 1 "land: $b failed in a batch and was bisected out — logs: $scratch/logs"
        else
            give_verdict "$d/$t" 1 "${batch_note:-land: the batch did not land $b} — logs: $scratch/logs"
        fi
    done
    if [ -n "$landed" ] && listed "$branch" "$good"; then
        verdict_ok=1
        echo "LANDED $landed — in a batch with: $good"
        exit 0
    fi
    listed "$branch" "$culprits" && echo "land: $branch failed in the batch and was bisected out" >&2
    [ -n "$batch_note" ] && echo "$batch_note" >&2
    exit 1
}

# ── MAIN ──────────────────────────────────────────────────────────────
main() {
    dry_run=0
    if [ "${1:-}" = "--dry-run" ]; then
        dry_run=1
        shift
    fi
    if [ "$#" -eq 0 ]; then
        usage >&2
        exit 2
    fi
    if [ "$#" -gt 1 ]; then
        main_batch "$dry_run" "$@"
        exit $?
    fi
    branch="${1:-}"
    absorbed=""

    trap finish_lock EXIT
    trap 'release_lock_and_exit INT' INT
    trap 'release_lock_and_exit TERM' TERM
    acquire_lock

    main_wt="$(worktree_for_branch main)"
    if [ -z "$main_wt" ]; then
        echo "land: no worktree has 'main' checked out — \`git worktree list\`" >&2
        exit 1
    fi
    branch_wt="$(worktree_for_branch "$branch")"
    if [ -z "$branch_wt" ]; then
        echo "land: no worktree has '$branch' checked out — \`git worktree list\`" >&2
        exit 1
    fi
    echo "land: main worktree   $main_wt"
    echo "land: branch worktree $branch_wt ($branch)"

    # AVRA_LAND_ABSORB=1 batches the queue behind this branch.
    if [ "$dry_run" -eq 0 ] && [ "${AVRA_LAND_ABSORB:-0}" = "1" ]; then
        absorbed="$(absorb_waiters | tr '\n' ' ')"
        [ -n "$(printf '%s' "$absorbed" | tr -d '[:space:]')" ] && land_absorbed
    fi

    run_pipeline ""

    if [ "$dry_run" -eq 1 ]; then
        echo "land: --dry-run — skipping the fast-forward"
        verdict_ok=1
        echo "land: DRY RUN OK for $branch (would land as $(git -C "$branch_wt" rev-parse --short HEAD))"
        exit 0
    fi

    ff_log="$(log_of ff)"
    if try_ff > "$ff_log" 2>&1; then
        refresh_main_compiler "$branch_wt" "$main_wt"
        verdict_ok=1
        echo "LANDED $(git -C "$main_wt" rev-parse HEAD)"
        exit 0
    fi
    main_moved_since "$old_main_sha" || ff_refused "$ff_log"

    echo "land: main moved during the checks — re-merging and re-running once" >&2
    tail -10 "$ff_log" >&2

    run_pipeline "-retry"

    ff_retry_log="$(log_of ff-retry)"
    if try_ff > "$ff_retry_log" 2>&1; then
        refresh_main_compiler "$branch_wt" "$main_wt"
        verdict_ok=1
        echo "LANDED $(git -C "$main_wt" rev-parse HEAD)"
        exit 0
    fi
    main_moved_since "$old_main_sha" || ff_refused "$ff_retry_log"

    echo "land: main moved again after the retry — giving up. Land manually once it settles." >&2
    tail -30 "$ff_retry_log" >&2
    exit 1
}

if [ "${1:-}" = "--call" ]; then
    shift
    fn="${1:?--call needs a function name}"
    shift
    "$fn" "$@"
    exit $?
fi

main "$@"
