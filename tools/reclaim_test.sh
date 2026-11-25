#!/bin/sh
# FIXTURES FOR tools/reclaim.sh — never the real repo: every repo and
# worktree here is made fresh under a mktemp directory, and the ticket
# queue and batch tree are pointed inside it too.
#
# `sh tools/reclaim_test.sh` runs every fixture and prints a PASS/FAIL
# summary; a non-zero exit is a real failure. AVRA_RECLAIM_SCRIPT
# names another script to test, so a broken copy can be witnessed
# failing.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
reclaim="${AVRA_RECLAIM_SCRIPT:-$here/reclaim.sh}"

scratch="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/avra-reclaim-test.XXXXXX")" && pwd -P)"
cleanup() {
    [ -n "${sleeper:-}" ] && kill "$sleeper" 2>/dev/null
    rm -rf "$scratch"
}
trap cleanup EXIT INT TERM

ok() { echo "ok    $1"; }
bad() { echo "FAIL  $1"; [ -n "${2:-}" ] && sed 's/^/      | /' "$2" 2>/dev/null; }

# A repo at $scratch/<name> on `main`, one commit.
git_repo() {
    repo="$scratch/$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" symbolic-ref HEAD refs/heads/main
    git -C "$repo" config user.email test@example.com
    git -C "$repo" config user.name "reclaim test"
    echo base > "$repo/file"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m base
    echo "$repo"
}

# worktree <repo> <branch> — a linked tree at <repo>-<branch> on a new
# branch off main.
worktree() {
    git -C "$1" worktree add -q -b "$2" "$1-$2" main
    echo "$1-$2"
}

# A commit on the worktree's own branch that main lacks.
unmerge() {
    echo "$2" > "$1/own"
    git -C "$1" add -A
    git -C "$1" commit -q -m "unmerged work"
}

# Runs reclaim over repo `$d` from `$from` (default `$d`), with every
# shared path inside the scratch directory.
run() {
    ( cd "${from:-$d}" && AVRA_LAND_LOCK="$scratch/lock" AVRA_LAND_BATCH_WT="${AVRA_LAND_BATCH_WT:-$scratch/none}" \
        sh "$reclaim" "$@" )
}

# kept <out> <tree> [<env>...] — reclaim neither names the tree under
# --dry-run nor removes it for real. The dry-run half sees the rule
# alone; the real half would also meet git's own refusals.
kept() {
    out="$1"
    wt="$2"
    shift 2
    run --now --dry-run > "$out" 2>&1
    grep -qF "would retire $wt " "$out" && return 1
    run --now >> "$out" 2>&1
    [ -d "$wt" ]
}

has_branch() { git -C "$1" rev-parse -q --verify "refs/heads/$2" > /dev/null; }

test_merged_clean_retired() {
    d="$(git_repo merged)"
    wt="$(worktree "$d" done)"
    out="$scratch/merged.out"
    run --now > "$out" 2>&1
    if [ ! -d "$wt" ] && grep -q "^retired .*merged-done (done)$" "$out"; then
        ok "a merged, clean, idle tree is retired and named"
    else
        bad "a merged, clean, idle tree was not retired" "$out"
    fi
    if has_branch "$d" done; then
        ok "the retired tree's branch is kept"
    else
        bad "the retired tree's branch is gone"
    fi
    if grep -q "^reclaim: looked at 2 worktree(s), retired 1$" "$out"; then
        ok "the count names what it looked at and what it retired"
    else
        bad "the count line is wrong" "$out"
    fi
}

test_dirty_kept() {
    d="$(git_repo dirty)"
    wt="$(worktree "$d" wip)"
    echo scribble > "$wt/untracked"
    out="$scratch/dirty.out"
    if kept "$out" "$wt" && [ -f "$wt/untracked" ]; then
        ok "a dirty tree is kept"
    else
        bad "a dirty tree was retired" "$out"
    fi
}

test_unmerged_kept() {
    d="$(git_repo unmerged)"
    wt="$(worktree "$d" lane)"
    unmerge "$wt" lane
    out="$scratch/unmerged.out"
    if kept "$out" "$wt"; then
        ok "an unmerged tree is kept"
    else
        bad "an unmerged tree was retired" "$out"
    fi
}

test_busy_kept() {
    d="$(git_repo busy)"
    wt="$(worktree "$d" held)"
    mkdir -p "$wt/deep"
    ( cd "$wt/deep" && exec sleep 60 ) &
    sleeper=$!
    sleep 1
    out="$scratch/busy.out"
    kept "$out" "$wt"
    st=$?
    kill "$sleeper" 2>/dev/null
    wait "$sleeper" 2>/dev/null
    sleeper=""
    if [ "$st" -eq 0 ]; then
        ok "a tree a process stands inside is kept"
    else
        bad "a busy tree was retired" "$out"
    fi
}

# The repo's own tree sits on another branch, so main's checkout is a
# linked tree that is merged, clean and idle — only its rule keeps it.
# The own tree's half runs from main's tree, so it is idle too.
test_main_checkout_untouched() {
    d="$(git_repo mainwt)"
    git -C "$d" checkout -q -b home
    git -C "$d" worktree add -q "$d-main" main
    out="$scratch/mainwt.out"
    if kept "$out" "$d-main"; then
        ok "main's checkout is never touched"
    else
        bad "main's checkout was named or touched" "$out"
    fi
    from="$d-main"
    if kept "$out" "$d" && [ "$(git -C "$d" rev-parse --abbrev-ref HEAD)" = "home" ]; then
        ok "the repo's own tree is never touched"
    else
        bad "the repo's own tree was named or touched" "$out"
    fi
    from=""
}

test_detached_kept() {
    d="$(git_repo detached)"
    git -C "$d" worktree add -q --detach "$d-side" main
    out="$scratch/detached.out"
    if kept "$out" "$d-side"; then
        ok "a detached tree is kept"
    else
        bad "a detached tree was named or retired" "$out"
    fi
}

test_ticket_and_batch_kept() {
    d="$(git_repo guarded)"
    queued="$(worktree "$d" queued)"
    batch="$(worktree "$d" batch)"
    mkdir -p "$scratch/lock/tickets/7"
    printf 'pid=1\nbranch=queued\ndry_run=0\n' > "$scratch/lock/tickets/7/info"
    out="$scratch/guarded.out"
    export AVRA_LAND_BATCH_WT="$batch"
    if kept "$out" "$queued"; then
        ok "a tree whose branch a land ticket names is kept"
    else
        bad "a ticket's tree was named or retired" "$out"
    fi
    rm -rf "$scratch/lock"
    if kept "$out" "$batch"; then
        ok "the land batch tree is kept"
    else
        bad "the batch tree was named or retired" "$out"
    fi
    unset AVRA_LAND_BATCH_WT
}

test_dry_run_moves_nothing() {
    d="$(git_repo dry)"
    wt="$(worktree "$d" done)"
    out="$scratch/dry.out"
    run --now --dry-run > "$out" 2>&1
    if [ -d "$wt" ] && [ "$(git -C "$d" worktree list | wc -l | tr -d ' ')" = 2 ] &&
        grep -q "^would retire .*dry-done (done)$" "$out"; then
        ok "dry-run names the tree and moves nothing"
    else
        bad "dry-run moved a tree or named nothing" "$out"
    fi
}

test_threshold() {
    d="$(git_repo threshold)"
    wt="$(worktree "$d" done)"
    out="$scratch/threshold.out"
    export AVRA_RECLAIM_FREE_GB=0
    run > "$out" 2>&1
    if [ -d "$wt" ] && grep -q "nothing to do" "$out"; then
        ok "free space at or over the threshold retires nothing"
    else
        bad "free space over the threshold still retired" "$out"
    fi
    export AVRA_RECLAIM_FREE_GB=1000000
    run > "$out" 2>&1
    unset AVRA_RECLAIM_FREE_GB
    if [ ! -d "$wt" ]; then
        ok "free space under the threshold retires"
    else
        bad "free space under the threshold retired nothing" "$out"
    fi
}

run_test() {
    log="$scratch/$1.run.log"
    "$1" > "$log" 2>&1 || echo "FAIL  $1 (the fixture itself errored)" >> "$log"
    cat "$log"
}

run_test test_merged_clean_retired
run_test test_dirty_kept
run_test test_unmerged_kept
run_test test_busy_kept
run_test test_main_checkout_untouched
run_test test_detached_kept
run_test test_ticket_and_batch_kept
run_test test_dry_run_moves_nothing
run_test test_threshold

total="$(cat "$scratch"/*.run.log | grep -cE '^(ok|FAIL)  ')"
failed="$(cat "$scratch"/*.run.log | grep -cE '^FAIL  ')"
echo "----------------------------------------"
echo "reclaim_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
