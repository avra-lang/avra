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
# finer: every heavy command this script runs (a build, a test, `make
# idioms`) takes a slot first, so a landing shares the machine with
# whatever else is building, rather than owning it.
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
# build.
#
# `sh tools/land.sh --call <function> [args...]` calls one function
# below directly, standing where the real script stands (so `$0`-based
# paths still resolve) — the seam tools/land_test.sh's fixtures use to
# exercise the merge, the cache sweep and the lock in a throwaway
# repo, never the real one.
set -eu

LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}"
export LLVM_PREFIX
AVRA_WATCH_HELD=1
export AVRA_WATCH_HELD

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
scratch="${AVRA_LAND_SCRATCH:-/tmp/avra-land-scratch/$run_id}"
mkdir -p "$scratch/logs"
trash="$scratch/trash"
mkdir -p "$trash"

log_of() { echo "$scratch/logs/$1.log"; }

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
    st=0
    sh "$tools_dir/capped.sh" "$log" 2000000 \
        sh "$tools_dir/slot.sh" 2 \
        sh "$tools_dir/memcap.sh" "${AVRA_MEMCAP_MB:-4000}" "$@" || st=$?
    if [ "$st" -eq 0 ]; then
        echo "land: $name OK" >&2
        return 0
    fi
    # 137 is the memory cap's kill: a finding about the change, never a retry.
    fail_report "$name" "$st" "$log"
    return "$st"
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
    st=0
    ( "$body" "$@" ) > "$log" 2>&1 || st=$?
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
        pid="$(cat "$d/$t/pid" 2>/dev/null)"
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
    release_absorbed
    release_lock
}

# A TRAP ON A SIGNAL RESUMES AFTER THE HANDLER, IT DOES NOT EXIT — a
# `trap release_lock INT TERM` alone frees the ticket on Ctrl-C or a
# kill, then the script carries straight on from wherever it was
# interrupted (witnessed: a killed `--dry-run` had its ticket cleaned
# up correctly and kept running anyway). INT/TERM need their own
# handler that exits afterward, at the conventional 128+signal code.
release_lock_and_exit() {
    sig="$1"
    finish_lock
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
    acquire_lock
    echo "acquired ticket $ticket"
    i=0
    while [ ! -f "$signal" ] && [ "$i" -lt 300 ]; do
        sleep 0.2
        i=$((i + 1))
    done
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
# avra-8sb5.57.25 (compiler print folded into every durable key) and
# avra-8sb5.57.24 (a held module's record decoder now enforces its own
# fingerprint, so a test-then-check sequence in one tree no longer
# indexes a stale shape) are BOTH closed, on main — nothing in the
# pipeline forces a cache sweep any more. Kept as a callable utility
# (land_test.sh's own fixture still exercises it, and it is a
# reasonable manual escape hatch), just not wired into a landing.
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
        tool_failed "no standing compiler at $wt/build/avra"
        return 1
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

# ── AFFECTED-PACKAGE TESTS ─────────────────────────────────────────────
# THE AFFECTED PACKAGES' TESTS, TOGETHER WITH `make idioms` — ALL
# SEQUENTIAL: two avra processes compiling into one .avra-cache AT
# ONCE corrupt it (avra-8sb5.57.41 — tried as a concurrent batch here
# first, and both suites failed to link with undefined av_ symbols).
# Parallelize once concurrent writers into one store are safe; until
# then every affected package's suite runs one at a time, then idioms.
run_checks() {
    wt="$1"
    base_sha="$2"
    head_sha="$3"
    suffix="$4"
    affected="$(sh "$tools_dir/affected_packages.sh" "$base_sha" "$head_sha" "$wt")"

    fails=0
    for pkg in $affected; do
        heavy "test-$pkg$suffix" sh -c "cd '$wt' && build/avra test packages/$pkg" || fails=1
    done
    heavy "idioms$suffix" sh -c "cd '$wt' && make idioms" || fails=1

    [ "$fails" -eq 0 ]
}

# ── THE WHOLE PIPELINE, RUN ONCE AND RE-RUN ONCE ON A LOST RACE ───────
# `suffix` keeps a re-run's logs apart from the first attempt's.
run_pipeline() {
    suffix="$1"
    old_main_sha="$(git -C "$main_wt" rev-parse HEAD)"

    light "merge$suffix" merge_main_in "$branch_wt"
    # A warm cache does not yet follow every edit a merge makes, so the
    # merged tree starts cacheless; drop this once it does.
    move_caches_aside "$branch_wt"

    new_branch_sha="$(git -C "$branch_wt" rev-parse HEAD)"
    diff_files="$(git -C "$branch_wt" diff --name-only "$old_main_sha...$new_branch_sha")"
    compiler_changed=0
    case "$diff_files" in
        *"packages/std-avrac/"*|*"packages/cli/"*|*"packages/std-meta/"*|*"runtime/"*) compiler_changed=1 ;;
    esac
    echo "land: compiler changed in this landing: $compiler_changed" >&2

    # A SUBSHELL each: `build_generation`'s own `cd "$wt"` must not
    # leak into the steps after it.
    if ! ( build_generation "$branch_wt" "1$suffix" ); then
        echo "land: build generation 1$suffix failed" >&2
        return 1
    fi
    if [ "$compiler_changed" -eq 1 ]; then
        if ! ( build_generation "$branch_wt" "2$suffix" ); then
            echo "land: build generation 2$suffix failed" >&2
            return 1
        fi
    fi

    if ! run_checks "$branch_wt" "$old_main_sha" "$new_branch_sha" "$suffix"; then
        echo "land: a check failed (an affected package's tests, or idioms)" >&2
        return 1
    fi

    heavy "fmt-lossless$suffix" sh -c "cd '$branch_wt' && make fmt-lossless"
    heavy "cache-attacks$suffix" sh -c "cd '$branch_wt' && make cache-attacks"

    seed_policy "$branch_wt" "$suffix"
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
seed_policy() {
    wt="$1"
    suffix="$2"
    log1="$(log_of "seed-check$suffix")"
    echo "land: seed-check (first pass) …" >&2
    if sh "$tools_dir/capped.sh" "$log1" 2000000 sh "$tools_dir/slot.sh" 2 sh -c "cd '$wt' && make seed-check"; then
        echo "land: seed-check passed on the first try — seed already matches HEAD, no emit" >&2
        return 0
    fi
    echo "land: seed-check failed on the first try — the seed lags HEAD; re-emitting" >&2
    heavy "seed-emit$suffix" sh -c "cd '$wt' && make seed"
    light "seed-commit$suffix" commit_seed_if_moved "$wt" "$branch"
    heavy "seed-check-2$suffix" sh -c "cd '$wt' && make seed-check"
    echo "land: seed-check passed after a fresh emit" >&2
}

try_ff() { git -C "$main_wt" merge --ff-only "$branch"; }

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
# times over. A batch failure BISECTS: the whole set failed, so it is
# split in half and each half tried FRESH from main; a half that still
# fails splits again, down to a single branch, which is named a
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
    # Each attempt merges different content: a cache kept from the last
    # one describes files that are no longer there.
    move_caches_aside "$batch_wt"
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
    compiler_changed=0
    case "$diff_files" in
        *"packages/std-avrac/"*|*"packages/cli/"*|*"packages/std-meta/"*|*"runtime/"*) compiler_changed=1 ;;
    esac

    if ! ( build_generation "$batch_wt" "batch-1-$label" ); then return 1; fi
    if [ "$compiler_changed" -eq 1 ]; then
        if ! ( build_generation "$batch_wt" "batch-2-$label" ); then return 1; fi
    fi
    if ! run_checks "$batch_wt" "$old_main_sha" "$new_sha" "-batch-$label"; then return 1; fi
    if ! heavy "batch-fmt-lossless-$label" sh -c "cd '$batch_wt' && make fmt-lossless"; then return 1; fi
    if ! heavy "batch-cache-attacks-$label" sh -c "cd '$batch_wt' && make cache-attacks"; then return 1; fi
    if ! seed_policy "$batch_wt" "-batch-$label"; then return 1; fi
    echo "land: batch attempt [$label] GREEN: $*" >&2
    return 0
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
    if git -C "$main_wt" merge --ff-only "$batch_branch" > "$ff_log" 2>&1; then
        landed="$(git -C "$main_wt" rev-parse HEAD)"
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
    batch_core "$dry_run" "$@"
    if [ -n "$batch_note" ] && [ -z "$landed" ]; then
        echo "$batch_note" >&2
        [ "$dry_run" -eq 1 ] && [ -n "$good" ] && [ -z "$(printf '%s' "$culprits" | tr -d '[:space:]')" ] && exit 0
        exit 1
    fi
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
    batch_core 0 "$branch" $riders
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
        echo "land: DRY RUN OK for $branch (would land as $(git -C "$branch_wt" rev-parse --short HEAD))"
        exit 0
    fi

    ff_log="$(log_of ff)"
    if try_ff > "$ff_log" 2>&1; then
        echo "LANDED $(git -C "$main_wt" rev-parse HEAD)"
        exit 0
    fi
    main_moved_since "$old_main_sha" || ff_refused "$ff_log"

    echo "land: main moved during the checks — re-merging and re-running once" >&2
    tail -10 "$ff_log" >&2

    run_pipeline "-retry"

    ff_retry_log="$(log_of ff-retry)"
    if try_ff > "$ff_retry_log" 2>&1; then
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
