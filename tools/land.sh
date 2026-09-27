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

Lands <branch> onto LOCAL main. Never pushes anywhere, never rewrites
the branch's own history — main advances by a fast-forward onto it.

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
    echo "land: $name …"
    if sh "$tools_dir/capped.sh" "$log" 2000000 sh "$tools_dir/slot.sh" 2 "$@"; then
        echo "land: $name OK"
        return 0
    fi
    st=$?
    fail_report "$name" "$st" "$log"
    return "$st"
}

# A LIGHT STEP: quick git/file plumbing with its own control flow — no
# loop, no unbounded output, so no cap and no slot. `body` is a shell
# function name, called in a SUBSHELL so its own `cd` never leaks into
# the step after it; its stdout+stderr land in the step's log.
light() {
    name="$1"
    body="$2"
    shift 2
    log="$(log_of "$name")"
    echo "land: $name …"
    st=0
    ( "$body" "$@" ) > "$log" 2>&1 || st=$?
    if [ "$st" -ne 0 ]; then
        fail_report "$name" "$st" "$log"
        return "$st"
    fi
    echo "land: $name OK"
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

# Every ticket number waiting or holding, ascending, with a dead one's
# directory removed on the way past it — so a caller scanning for the
# lowest LIVE ticket cleans the queue as a side effect of asking.
live_tickets() {
    d="$(tickets_dir)"
    for t in $(ls "$d" 2>/dev/null | grep -E '^[0-9]+$' | sort -n); do
        pid="$(cat "$d/$t/pid" 2>/dev/null)"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "$t"
        elif [ -n "$pid" ]; then
            echo "land: reclaiming a dead ticket ($t, pid $pid is not running)" >&2
            rm -rf "$d/$t" 2>/dev/null
        fi
    done
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
        echo "time=$(date)"
    } > "$d/$ticket/info"
    echo "$$" > "$d/$ticket/pid"

    printed_wait=0
    while :; do
        lowest="$(live_tickets | head -1)"
        [ "$lowest" = "$ticket" ] && return 0
        if [ "$printed_wait" -eq 0 ]; then
            echo "land: ticket $ticket taken — waiting behind ticket $lowest"
            printed_wait=1
        fi
        sleep 1
    done
}
release_lock() { [ -n "$ticket" ] && rm -rf "$(tickets_dir)/$ticket" 2>/dev/null; }

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
# merge and names every file, rather than guess at code.
merge_main_in() {
    wt="$1"
    cd "$wt"
    if git merge --no-edit "refs/heads/main"; then
        echo "land: merge OK (no conflicts, or already up to date)"
        return 0
    fi
    conflicts="$(git diff --name-only --diff-filter=U)"
    others="$(printf '%s\n' "$conflicts" | grep -v -E '^bootstrap/seed\.(ll|sources)$' || true)"
    if [ -n "$(printf '%s' "$others" | tr -d '[:space:]')" ]; then
        echo "land: merge conflict outside the seed — aborting"
        echo "$conflicts"
        git merge --abort
        return 1
    fi
    echo "land: merge conflict confined to the seed — taking main's side"
    for f in bootstrap/seed.ll bootstrap/seed.sources; do
        case "$conflicts" in *"$f"*) git checkout --theirs -- "$f" && git add "$f" ;; esac
    done
    git commit --no-edit
}

# ── EVERY .avra-cache MOVED ASIDE (mv, never rm) ──────────────────────
# A cache entry is not yet keyed by the compiler that wrote it, so a
# newer compiler can decode an older one's (avra-8sb5.57.24/.25) —
# drop this step once every entry carries the compiler print.
move_caches_aside() {
    wt="$1"
    found="$(find "$wt" -maxdepth 4 -name .avra-cache -type d 2>/dev/null)"
    if [ -z "$(printf '%s' "$found" | tr -d '[:space:]')" ]; then
        echo "land: no .avra-cache under $wt"
        return 0
    fi
    mkdir -p "$trash/avra-cache"
    n=0
    printf '%s\n' "$found" | while read -r d; do
        [ -z "$d" ] && continue
        n=$((n + 1))
        mv "$d" "$trash/avra-cache/cache-$n"
        echo "land: moved $d -> $trash/avra-cache/cache-$n"
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
        echo "land: seed unchanged"
        return 0
    fi
    git add bootstrap/seed.ll bootstrap/seed.sources
    git commit -m "chore(seed): the compiler re-emitted for ${label}'s landing

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
}

# ── ONE BUILD GENERATION ──────────────────────────────────────────────
build_generation() {
    wt="$1"
    n="$2"
    cd "$wt"
    cp build/avra "build/avra.pre.$n" 2>/dev/null || true
    if ! heavy "build-$n-runtime" make build/libavra_runtime.a; then
        [ -f "build/avra.pre.$n" ] && cp "build/avra.pre.$n" build/avra
        return 1
    fi
    if ! heavy "build-$n-compile" build/avra build packages/cli; then
        [ -f "build/avra.pre.$n" ] && cp "build/avra.pre.$n" build/avra
        return 1
    fi
    cp packages/cli/src/main build/avra
    codesign -f -s - build/avra
    rm -f packages/cli/src/main packages/cli/src/main.av.ll
}

# ── AFFECTED-PACKAGE TESTS ─────────────────────────────────────────────
run_affected_tests() {
    wt="$1"
    base_sha="$2"
    head_sha="$3"
    affected="$(sh "$tools_dir/affected_packages.sh" "$base_sha" "$head_sha" "$wt")"
    if [ -z "$(printf '%s' "$affected" | tr -d '[:space:]')" ]; then
        echo "land: no package affected — nothing to test"
        return 0
    fi
    fails=0
    for pkg in $affected; do
        if ! heavy "test-$pkg" sh -c "cd '$wt' && build/avra test packages/$pkg"; then
            fails=1
        fi
    done
    [ "$fails" -eq 0 ]
}

# ── THE WHOLE PIPELINE, RUN ONCE AND RE-RUN ONCE ON A LOST RACE ───────
# `suffix` keeps a re-run's logs apart from the first attempt's.
run_pipeline() {
    suffix="$1"
    old_main_sha="$(git -C "$main_wt" rev-parse HEAD)"

    light "merge$suffix" merge_main_in "$branch_wt"

    new_branch_sha="$(git -C "$branch_wt" rev-parse HEAD)"
    diff_files="$(git -C "$branch_wt" diff --name-only "$old_main_sha...$new_branch_sha")"
    compiler_changed=0
    case "$diff_files" in
        *"packages/std-avrac/"*|*"packages/cli/"*|*"packages/std-meta/"*|*"runtime/"*) compiler_changed=1 ;;
    esac
    echo "land: compiler changed in this landing: $compiler_changed"

    light "caches-aside$suffix" move_caches_aside "$branch_wt"

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

    if ! run_affected_tests "$branch_wt" "$old_main_sha" "$new_branch_sha"; then
        echo "land: an affected package's tests failed" >&2
        return 1
    fi

    heavy "idioms$suffix" sh -c "cd '$branch_wt' && make idioms"
    heavy "fmt-lossless$suffix" sh -c "cd '$branch_wt' && make fmt-lossless"
    heavy "cache-attacks$suffix" sh -c "cd '$branch_wt' && make cache-attacks"

    heavy "seed-emit$suffix" sh -c "cd '$branch_wt' && make seed"
    light "seed-commit$suffix" commit_seed_if_moved "$branch_wt" "$branch"

    heavy "seed-check$suffix" sh -c "cd '$branch_wt' && make seed-check"
}

try_ff() { git -C "$main_wt" merge --ff-only "$branch"; }

# ── MAIN ──────────────────────────────────────────────────────────────
main() {
    dry_run=0
    if [ "${1:-}" = "--dry-run" ]; then
        dry_run=1
        shift
    fi
    branch="${1:-}"
    if [ -z "$branch" ]; then
        usage >&2
        exit 2
    fi

    trap release_lock EXIT INT TERM
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

    echo "land: main moved during the checks — re-merging and re-running once" >&2
    tail -10 "$ff_log" >&2

    run_pipeline "-retry"

    ff_retry_log="$(log_of ff-retry)"
    if try_ff > "$ff_retry_log" 2>&1; then
        echo "LANDED $(git -C "$main_wt" rev-parse HEAD)"
        exit 0
    fi

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
