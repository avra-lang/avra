#!/bin/sh
# THE INTEGRATOR: `sh tools/integrate.sh <lane> <message-file>` lands
# one lane on main, the lanes' rule 5 as a mechanism. From the lane's
# worktree (../avra-lane-<lane>) it commits the working tree with the
# message, rebases the lane onto main and runs the FULL gate there
# when main has moved, merges with a merge commit, rebuilds main's
# compiler twice (the fixed point), refreshes the seed, bootstraps
# from it (byte-identical, or it is not a seed), commits the seed, and
# rebases the lane onto the new main, rebuilding its compiler from
# whichever of its own product or the seed can read the rebased tree.
# Before the merge it PRE-FLIGHTS main's
# compiler against the lane's tree, so a lane that lands a language change never
# leaves main merged and unbuildable. Every heavy step runs through
# the watchdog and its lock. Edits another session left on main's
# working tree are stashed around the merge and restored, uncommitted.
# The first red stops everything, with main untouched past that point.
set -e
lane="$1"; msg="$2"
[ -n "$lane" ] && [ -f "$msg" ] || { echo "usage: integrate.sh <lane> <message-file>" >&2; exit 2; }
root="$(cd "$(dirname "$0")/.." && pwd)"
main="$(dirname "$root")/avra"
worktree="$(dirname "$root")/avra-lane-$lane"
[ -d "$main/.git" ] && [ -d "$worktree" ] || { echo "integrate: no main at $main or no worktree at $worktree" >&2; exit 2; }
cap=4000

cd "$worktree"

# A COMPILER THAT READS THE REBASED TREE. `make bootstrap` alone assumes
# main's SEED can read the lane — false for a lane that ADDS a construct
# and USES it in the same slice, which is the normal shape of a language
# change. The lane's own product knows its constructs; the seed knows
# main's. Try the product first, the seed second: each single-sided case
# is covered, and only a lane that adds syntax WHILE main added syntax
# defeats both.
rebuilt_lane() {
    if [ -x /tmp/integrate-lane-product ]; then
        cp /tmp/integrate-lane-product build/avra
        codesign -f -s - build/avra 2>/dev/null || true
        if sh tools/watch.sh $cap make -s avra > /tmp/integrate-lane-rebuild.out 2>&1; then
            echo "integrate: lane/$lane rebuilt with its own product"
            return 0
        fi
    fi
    if sh tools/watch.sh $cap make bootstrap > /tmp/integrate-bootstrap.out 2>&1; then
        echo "integrate: lane/$lane bootstrapped from the seed"
        return 0
    fi
    echo "integrate: no compiler reads the rebased lane — its product cannot read main's tree"
    echo "integrate:   and the seed cannot read the lane's. Land the construct and its USES as"
    echo "integrate:   two slices: drop the uses, \`make bootstrap\`, restore them, \`make avra\`"
    echo "integrate:   with that product, then gate. (CLAUDE.md, A SYNTAX CHANGE TO THE COMPILER'S"
    echo "integrate:   OWN SOURCE.) Main is untouched."
    tail -12 /tmp/integrate-bootstrap.out
    return 1
}

[ -x build/avra ] && cp build/avra /tmp/integrate-lane-product
if [ -n "$(git status --porcelain)" ]; then
    git add -A && git commit -q -F "$msg"
    committed=1
    echo "integrate: committed $(git log -1 --format=%h) on lane/$lane"
fi
base="$(git -C "$main" rev-parse HEAD)"
if ! git merge-base --is-ancestor "$base" HEAD; then
    echo "integrate: main moved to $(git -C "$main" log -1 --format=%h) — rebasing lane/$lane and gating"
    git rebase main
    rebuilt_lane || exit 1
    sh tools/watch.sh $cap make gate > /tmp/integrate-gate.out 2>&1 || { echo "integrate: the gate is RED on the rebased lane"; grep -n "✗\|FAILED\|error" /tmp/integrate-gate.out | head -12; exit 1; }
    echo "integrate: gate green on the rebased lane ($(grep -c 'tests passed' /tmp/integrate-gate.out) suites)"
fi

# THE PRE-FLIGHT: can MAIN's standing compiler READ the lane's tree? A lane that
# lands a language change AND uses it (lane C's `self`, its `mut` seats) leaves a
# tree main's binary cannot parse; `make avra` after the merge then fails with main
# already merged and its seed stale — recoverable only by hand. Detect it here and
# seed main's compiler from the lane's own product below, which built and gated this
# very tree. The binary is NAMED, never the shim: `../avra/avra` cds to main's root
# and would check MAIN's tree, and for the same reason the path must be absolute.
seed_from_lane=""
if [ -x "$main/build/avra" ]; then
    if LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}" \
       sh tools/watch.sh $cap "$main/build/avra" check "$worktree/packages/cli" > /tmp/integrate-preflight.out 2>&1; then
        echo "integrate: main's compiler reads the lane's tree"
    elif sh tools/watch.sh $cap ./avra check packages/cli > /tmp/integrate-preflight-lane.out 2>&1; then
        # main's compiler is BEHIND: the lane's own product reads this tree, so it is
        # the compiler main needs until main re-derives its own.
        seed_from_lane=1
        echo "integrate: main's compiler CANNOT read the lane's tree — seeding main from the lane's product"
        grep -m2 "^error" /tmp/integrate-preflight.out | sed "s/^/integrate:   /"
    else
        # NEITHER compiler reads it: the tree is broken, not ahead. Main is untouched.
        echo "integrate: the lane's tree checks with NEITHER compiler — main untouched"
        grep -m3 "^error" /tmp/integrate-preflight-lane.out | sed "s/^/integrate:   /"
        exit 1
    fi
fi

cd "$main"

# A STASH IS A DEBT AND EVERY EXIT PATH PAYS IT. Main is a worktree
# several sessions write to, so this can be holding work whose owner
# does not know it was taken. A failure between the push and the pop
# — a merge conflict is the one that fired — would strand it, and the
# next run would stash ON TOP, which is how one stranded edit becomes
# two nobody can attribute. The handler is idempotent, so the normal
# path calls it and the trap finds nothing left to do.
restore_main() {
    [ -n "$stashed" ] || return 0
    stashed=""
    if git stash pop -q 2>/dev/null; then
        echo "integrate: main's uncommitted edits restored (they were never committed)"
    else
        echo "integrate: COULD NOT restore main's uncommitted edits — another session's"
        echo "integrate:   work is the newest entry in \`git stash list\`, named"
        echo "integrate:   \"edits another session left on main's working tree\"."
        echo "integrate:   Recover it with \`git stash pop\` once this tree is clean."
    fi
}
trap restore_main EXIT INT TERM

[ -z "$(git status --porcelain --untracked-files=no)" ] || { git stash push -q -m "edits another session left on main's working tree"; stashed=1; }
# the merge is titled by what landed: the message when this run
# committed, else the lane's last subject
[ -n "$committed" ] && title="$(head -1 "$msg")" || title="$(git -C "$worktree" log -1 --format=%s)"
git merge --no-ff -q "lane/$lane" -m "merge: lane $lane — $(echo "$title" | cut -c1-100)"
restore_main
echo "integrate: merged as $(git log -1 --format=%h)"

# The lane's product reads the merged tree BY CONSTRUCTION: the lane was rebased onto
# main and gated green with it, so it is the compiler this tree needs. Main's own
# product is re-derived by the fixed point below.
if [ -n "$seed_from_lane" ]; then
    cp "$worktree/build/avra" build/avra
    codesign -f -s - build/avra 2>/dev/null || true
    echo "integrate: main's compiler seeded from lane/$lane's product"
fi

# THE FIXED POINT: the compiler builds itself until two consecutive
# products agree. Main's standing binary may predate a CODEGEN change
# the lane carries — its first product then has the new source under
# the old codegen, and only the second product's own body wears the
# change — so up to three builds are allowed before the point is
# called missing.
sh tools/watch.sh $cap make -s avra > /tmp/integrate-avra1.out 2>&1 || { echo "integrate: main does not build after the merge"; tail -20 /tmp/integrate-avra1.out; echo "integrate:   by hand: cp $worktree/build/avra $main/build/avra && cd $main && make -s avra && make -s avra && make -s seed"; exit 1; }
cp build/avra /tmp/integrate-avra1
builds=1
until sh tools/watch.sh $cap make -s avra > /tmp/integrate-avra2.out 2>&1 && cmp -s build/avra /tmp/integrate-avra1; do
    builds=$((builds + 1))
    [ "$builds" -lt 4 ] || { echo "integrate: NO FIXED POINT on main (three builds, no two agree)"; echo "integrate:   by hand: cp $worktree/build/avra $main/build/avra && cd $main && make -s avra && make -s avra && make -s seed"; exit 1; }
    cp build/avra /tmp/integrate-avra1
done
echo "integrate: the fixed point after $((builds + 1)) builds"
sh tools/watch.sh $cap make -s seed > /tmp/integrate-seed.out 2>&1
cp build/avra /tmp/integrate-preboot
sh tools/watch.sh $cap make -s bootstrap > /tmp/integrate-boot.out 2>&1 || { echo "integrate: the refreshed seed does not bootstrap"; tail -20 /tmp/integrate-boot.out; exit 1; }
cmp -s build/avra /tmp/integrate-preboot || { echo "integrate: the seed does not CYCLE (bootstrap differs)"; exit 1; }
# a merge that touched no compiler source leaves the seed as it was
git add bootstrap/seed.ll
git diff --quiet --cached -- bootstrap/seed.ll && echo "integrate: the seed is unchanged" || git commit -q -m "chore(seed): refreshed after lane $lane merged

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XXBDccuDA8Ntk55RXKedD2"
echo "integrate: main at $(git log -1 --format=%h), fixed point and seed cycle hold"

cd "$worktree" && git rebase -q main && echo "integrate: lane/$lane rebased onto main"
# the lane's binary must read the tree it now sits on: a rebase past
# another lane's language change leaves a compiler that traps on the
# new spelling
rebuilt_lane || exit 1
