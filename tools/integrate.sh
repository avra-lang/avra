#!/bin/sh
# THE INTEGRATOR: `sh tools/integrate.sh <lane> <message-file>` lands
# one lane on main, the lanes' rule 5 as a mechanism. From the lane's
# worktree (../avra-lane-<lane>) it commits the working tree with the
# message, rebases the lane onto main WHEN MAIN HAS MOVED, runs the
# FULL gate ALWAYS, merges with a merge commit, rebuilds main's
# compiler twice (the fixed point), refreshes the seed, bootstraps
# from it (byte-identical, or it is not a seed), commits the seed, and
# rebases the lane onto the new main, rebuilding its compiler from
# whichever of its own product or the seed can read the rebased tree.
# Before the merge it PRE-FLIGHTS main's
# compiler against the lane's tree, so a lane that lands a language change never
# leaves main merged and unbuildable. Every heavy step runs through
# the watchdog and its lock. Edits another session left on main's
# working tree are NEVER touched: the merge, the builds, the gate and
# the seed happen in an integration worktree of main, born clean, and
# the primary is fast-forwarded onto the result at the end.
# The first red stops everything, with main untouched past that point.
set -e
lane="$1"; msg="$2"
[ -n "$lane" ] && [ -f "$msg" ] || { echo "usage: integrate.sh <lane> <message-file>" >&2; exit 2; }
root="$(cd "$(dirname "$0")/.." && pwd)"
main="$(dirname "$root")/avra"
worktree="$(dirname "$root")/avra-lane-$lane"
[ -d "$main/.git" ] && [ -d "$worktree" ] || { echo "integrate: no main at $main or no worktree at $worktree" >&2; exit 2; }

# THE WORKTREE MUST BE ON `lane/<name>`, or this is not the lane's
# worktree. The path is derived from the name, so a directory that
# merely matches the pattern — another session's, on its own branch —
# would be rebased in place. Checked, not assumed.
on="$(git -C "$worktree" branch --show-current)"
[ "$on" = "lane/$lane" ] || {
    echo "integrate: $worktree is on '${on:-a detached HEAD}', not lane/$lane — refusing to touch a worktree that is not this lane's" >&2
    exit 2
}
cap=4000
# EVERY TEMP PATH CARRIES THE LANE. They were shared across worktrees —
# and three of them are BINARIES: `-lane-product` is copied straight
# into a worktree's `build/avra`, and `-avra1`/`-preboot` back the
# fixed-point `cmp`. Two lanes integrating in one window could seed one
# lane's compiler from the other's product, or compare a fixed point
# against a stranger's binary, with no tell either way. The log half
# already misled a reader once: a red `-gate.out` could not say whose
# run wrote it, and was nearly reported as this script ignoring its own
# exit code.
tmp="/tmp/integrate-$lane"

cd "$worktree"

# A COMPILER THAT READS THE REBASED TREE. `make bootstrap` alone assumes
# main's SEED can read the lane — false for a lane that ADDS a construct
# and USES it in the same slice, which is the normal shape of a language
# change. The lane's own product knows its constructs; the seed knows
# main's. Try the product first, the seed second: each single-sided case
# is covered, and only a lane that adds syntax WHILE main added syntax
# defeats both.
rebuilt_lane() {
    if [ -x "$tmp-lane-product" ]; then
        cp "$tmp-lane-product" build/avra
        codesign -f -s - build/avra 2>/dev/null || true
        if sh tools/watch.sh $cap make -s avra > "$tmp-lane-rebuild.out" 2>&1; then
            echo "integrate: lane/$lane rebuilt with its own product"
            return 0
        fi
    fi
    if sh tools/watch.sh $cap make bootstrap > "$tmp-bootstrap.out" 2>&1; then
        echo "integrate: lane/$lane bootstrapped from the seed"
        return 0
    fi
    echo "integrate: no compiler reads the rebased lane — its product cannot read main's tree"
    echo "integrate:   and the seed cannot read the lane's. Land the construct and its USES as"
    echo "integrate:   two slices: drop the uses, \`make bootstrap\`, restore them, \`make avra\`"
    echo "integrate:   with that product, then gate. (CLAUDE.md, A SYNTAX CHANGE TO THE COMPILER'S"
    echo "integrate:   OWN SOURCE.) Main is untouched."
    tail -12 "$tmp-bootstrap.out"
    return 1
}

[ -x build/avra ] && cp build/avra "$tmp-lane-product"
if [ -n "$(git status --porcelain)" ]; then
    git add -A && git commit -q -F "$msg"
    committed=1
    echo "integrate: committed $(git log -1 --format=%h) on lane/$lane"
fi
base="$(git -C "$main" rev-parse HEAD)"
if ! git merge-base --is-ancestor "$base" HEAD; then
    echo "integrate: main moved to $(git -C "$main" log -1 --format=%h) — rebasing lane/$lane"
    git rebase main
    rebuilt_lane || exit 1
fi

# THE GATE IS NOT CONDITIONAL, and it used to be. It lived inside the
# branch above, which asks "did main move" — a question about whether a
# REBASE is needed, never about whether VERIFICATION is. A lane already
# sitting on current main merged with no gate run at all, and the skip
# printed nothing, so it was invisible for as long as anyone re-ran an
# interrupted integrate: run one commits and rebases, run two dies
# mid-gate, run three finds nothing to rebase and merges ungated.
# A verification conditional on an event unrelated to whether
# verification is needed is not a verification.
#
# The receipt is NAMED PER LANE. `/tmp/integrate-gate.out` was one path
# every worktree wrote, so a red file could not say whose run made it —
# it sent a reader after the wrong mechanism once already.
gate_out="$tmp-gate.out"

# THE GATE PROVES THE TREE THAT MERGES, OR IT PROVES NOTHING. The
# commit above is the tree the merge takes; `make gate` reads the
# WORKING TREE. Edit a file while the gate runs and the two are
# different — the gate compiles a mixture nobody wrote and the merge
# lands the pre-edit commit, so a green verdict describes neither.
# It happened: a lane edited its worktree during its own gate, which
# is tempting precisely because the gate is long.
# HEAD, the tracked CONTENT, and the untracked list — before and
# after. The porcelain alone is not enough and the first draft of this
# proved it: it names WHICH files are dirty, not what is in them, so a
# further edit to an already-dirty file passes it unchanged. Here the
# commit above empties the porcelain first, so the weak form would
# have worked BY CIRCUMSTANCE — which is how a check comes to be
# trusted for a reason that is not its own. `git diff HEAD` carries
# the content.
pinned() {
    echo "$(git rev-parse HEAD)"
    git diff HEAD | shasum -a 256
    git status --porcelain | shasum -a 256
}
before="$(pinned)"

# THE LANE'S OWN GREEN, WHEN THIS INTEGRATION TAKES THE VERY SAME
# TREE. `git merge-tree --write-tree` answers the tree the merge would
# land, without merging; when the lane's receipt names that exact
# hash, the gate below would read the tree that receipt already
# describes. Main having moved, a ledger conflict resolved, one byte
# anywhere: the hash differs and the gate runs in full.
# A SKIP IS ANNOUNCED WITH WHAT IT TRUSTED — the receipt's commit, its
# date and the tree — because a verification that is sometimes skipped
# and never says so is one nobody can audit.
# THE STATUS IS THE ANSWER, NEVER THE OUTPUT. `trusts` prints its
# REASON on refusal as well as its receipt on trust, so reading stdout
# read every refusal as permission — the skip fired exactly when it
# must not. The status is the only channel that says yes.
merged_tree="$(git -C "$main" merge-tree --write-tree main "lane/$lane" 2>/dev/null || true)"
trusted=""
why=""
if [ -n "$merged_tree" ]; then
    # STDOUT IS CONSENT, STDERR IS THE REASON, and BOTH are announced:
    # a skip says what it trusted, and a refusal to skip says what it
    # read. Discarding the reason here would have made the gate that
    # follows look like an unexplained choice.
    if said="$(sh tools/gate_receipt.sh trusts "$worktree" "$merged_tree" 2>"$tmp-receipt.err")"; then
        trusted="$said"
    else
        why="$(cat "$tmp-receipt.err" 2>/dev/null || true)"
    fi
fi
if [ -n "$trusted" ]; then
    echo "integrate: the merge takes the tree lane/$lane already gated — trusting its receipt"
    echo "integrate:   tree $(echo "$merged_tree" | cut -c1-12), gated at $trusted"
else
    if [ -n "$why" ]; then echo "integrate: gating in full — $why"; fi
    sh tools/watch.sh $cap make gate > "$gate_out" 2>&1 || {
        echo "integrate: the gate is RED on lane/$lane — main untouched ($gate_out)"
        grep -n "✗\|FAILED\|error" "$gate_out" | head -12
        exit 1
    }
    echo "integrate: gate green on lane/$lane ($(grep -c 'tests passed' "$gate_out") suites)"
fi

if [ "$(pinned)" != "$before" ]; then
    echo "integrate: the tree CHANGED under the gate — main untouched"
    echo "integrate:   the gate read one tree and the merge would take another, so its"
    echo "integrate:   green says nothing about what would land. Re-run integrate; it"
    echo "integrate:   will commit the edit and gate the tree that merges."
    git status --short | head -12
    exit 1
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
       sh tools/watch.sh $cap "$main/build/avra" check "$worktree/packages/cli" > "$tmp-preflight.out" 2>&1; then
        echo "integrate: main's compiler reads the lane's tree"
    elif sh tools/watch.sh $cap ./avra check packages/cli > "$tmp-preflight-lane.out" 2>&1; then
        # main's compiler is BEHIND: the lane's own product reads this tree, so it is
        # the compiler main needs until main re-derives its own.
        seed_from_lane=1
        echo "integrate: main's compiler CANNOT read the lane's tree — seeding main from the lane's product"
        grep -m2 "^error" "$tmp-preflight.out" | sed "s/^/integrate:   /"
    else
        # NEITHER compiler reads it: the tree is broken, not ahead. Main is untouched.
        echo "integrate: the lane's tree checks with NEITHER compiler — main untouched"
        grep -m3 "^error" "$tmp-preflight-lane.out" | sed "s/^/integrate:   /"
        exit 1
    fi
fi

# THE INTEGRATION HAPPENS IN A WORKTREE OF ITS OWN, BORN CLEAN. Main's
# primary worktree carries other campaigns' live uncommitted edits, and
# this script used to STASH them around the merge — a debt paid on every
# exit path, holding work whose owner did not know it was taken. It
# never lost any; it was one conflict away from doing so.
#
# AND THE REF IS ADVANCED FROM THE PRIMARY, NEVER BEHIND ITS BACK.
# `git update-ref` moves the branch pointer and leaves the working tree
# where it was, so every file the merge ADDS reads as DELETED in the
# primary — `D path` in `git status` — and the next ordinary commit
# there removes it. Tested; that is worse than the stash it replaces,
# because a stash can strand work while this silently stages its
# removal. `git merge --ff-only` from the primary materialises the
# files, keeps uncommitted edits that do not collide, and REFUSES when
# they would.
integ="$(dirname "$root")/avra-integrate-$lane"
drop_integ() {
    [ -d "$integ" ] || return 0
    git -C "$main" worktree remove --force "$integ" 2>/dev/null ||
        echo "integrate: the integration worktree is still at $integ"
}
trap drop_integ EXIT INT TERM

git -C "$main" worktree add --detach -q "$integ" main ||
    { echo "integrate: could not make an integration worktree at $integ"; exit 1; }
cd "$integ"
echo "integrate: integrating in $integ (main's primary is untouched)"

# the merge is titled by what landed: the message when this run
# committed, else the lane's last subject
[ -n "$committed" ] && title="$(head -1 "$msg")" || title="$(git -C "$worktree" log -1 --format=%s)"
git merge --no-ff -q "lane/$lane" -m "merge: lane $lane — $(echo "$title" | cut -c1-100)"
echo "integrate: merged as $(git log -1 --format=%h)"

# The lane's product reads the merged tree BY CONSTRUCTION: the lane was rebased onto
# main and gated green with it, so it is the compiler this tree needs. Main's own
# product is re-derived by the fixed point below.
if [ -n "$seed_from_lane" ]; then
    mkdir -p build
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
sh tools/watch.sh $cap make -s avra > "$tmp-avra1.out" 2>&1 || { echo "integrate: main does not build after the merge"; tail -20 "$tmp-avra1.out"; echo "integrate:   by hand: cp $worktree/build/avra $main/build/avra && cd $main && make -s avra && make -s avra && make -s seed"; exit 1; }
cp build/avra "$tmp-avra1"
builds=1
until sh tools/watch.sh $cap make -s avra > "$tmp-avra2.out" 2>&1 && cmp -s build/avra "$tmp-avra1"; do
    builds=$((builds + 1))
    [ "$builds" -lt 4 ] || { echo "integrate: NO FIXED POINT on main (three builds, no two agree)"; echo "integrate:   by hand: cp $worktree/build/avra $main/build/avra && cd $main && make -s avra && make -s avra && make -s seed"; exit 1; }
    cp build/avra "$tmp-avra1"
done
echo "integrate: the fixed point after $((builds + 1)) builds"
sh tools/watch.sh $cap make -s seed > "$tmp-seed.out" 2>&1
cp build/avra "$tmp-preboot"
sh tools/watch.sh $cap make -s bootstrap > "$tmp-boot.out" 2>&1 || { echo "integrate: the refreshed seed does not bootstrap"; tail -20 "$tmp-boot.out"; exit 1; }
cmp -s build/avra "$tmp-preboot" || { echo "integrate: the seed does not CYCLE (bootstrap differs)"; exit 1; }
# a merge that touched no compiler source leaves the seed as it was
git add bootstrap/seed.ll
git diff --quiet --cached -- bootstrap/seed.ll && echo "integrate: the seed is unchanged" || git commit -q -m "chore(seed): refreshed after lane $lane merged

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01XXBDccuDA8Ntk55RXKedD2"
echo "integrate: integrated at $(git log -1 --format=%h), fixed point and seed cycle hold"

# THE PRIMARY IS FAST-FORWARDED, NOT POINTED. `--ff-only` moves the
# branch AND the files together, keeps uncommitted edits that do not
# collide, and refuses when they would — leaving the integration
# worktree standing so nothing is lost and a person can look.
landed="$(git rev-parse HEAD)"
git -C "$main" merge --ff-only -q "$landed" || {
    echo "integrate: main's PRIMARY worktree would not fast-forward — nothing moved there"
    echo "integrate:   its uncommitted edits collide with what landed, or it is not on main."
    echo "integrate:   The integration is COMPLETE and standing at $integ ($landed);"
    echo "integrate:   settle the primary and \`git merge --ff-only $landed\` it by hand."
    git -C "$main" status --short | head -12
    trap - EXIT INT TERM
    exit 1
}
# the primary keeps a compiler that predates its own HEAD otherwise
cp build/avra "$main/build/avra"
codesign -f -s - "$main/build/avra" 2>/dev/null || true
echo "integrate: main at $(git -C "$main" log -1 --format=%h), its compiler and files with it"

cd "$worktree" && git rebase -q main && echo "integrate: lane/$lane rebased onto main"
# the lane's binary must read the tree it now sits on: a rebase past
# another lane's language change leaves a compiler that traps on the
# new spelling
rebuilt_lane || exit 1
