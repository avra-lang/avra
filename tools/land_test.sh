#!/bin/sh
# FIXTURES FOR THE LAND TOOLING ITSELF — never the real repo, never a
# real worktree: every git repo here is thrown together fresh under a
# scratch directory and discarded. `sh tools/land_test.sh` runs every
# fixture and prints a PASS/FAIL summary; a non-zero exit is a real
# failure.
#
# A SELF-TEST MUST NOT BE REACHABLE FROM LAND.SH ITSELF: this file is
# never called BY land.sh or its own steps — land.sh's `--call <fn>`
# seam is what these fixtures drive it through, one function per call,
# never the other direction.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
land="$here/land.sh"
slot="$here/slot.sh"
affected="$here/affected_packages.sh"

scratch="/tmp/avra-land-test-$$"
mkdir -p "$scratch"
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT INT TERM

total=0
failed=0

ok() {
    total=$((total + 1))
    echo "ok    $1"
}
bad() {
    total=$((total + 1))
    failed=$((failed + 1))
    echo "FAIL  $1"
}

# A throwaway git repo, initialized and committed once, so a fixture's
# own edits land on a real ref a merge can target.
# NEITHER PARAMETER IS NAMED `d`: every call site below binds its own
# repo path to `d`, and POSIX sh has no per-function scope — a helper
# that also called its own local `d` would silently overwrite the
# caller's, exactly the trap that once made this file's own ff test
# commit "main moved independently" into the wrong worktree.
git_repo() {
    repo="$scratch/$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
    # The default branch name is a matter of the machine's git config
    # (`init.defaultBranch`) — pin it here so "main" always exists,
    # whatever this machine defaults to.
    git -C "$repo" symbolic-ref HEAD refs/heads/main
    git -C "$repo" config user.email test@example.com
    git -C "$repo" config user.name "land test"
    echo "$repo"
}
commit_all() {
    repo="$1"
    msg="$2"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "$msg"
}

# ══ THE LANDING LOCK: A FIFO TICKET QUEUE ═══════════════════════════
# Three contenders, A then B then C, each acquired through
# `hold_lock_for` (--call's composable acquire-hold-release, driven
# by a signal file this fixture touches when it wants a holder to let
# go). PLAIN FIFO: A acquires first, B and C wait behind it in
# arrival order. THE STRESS CASE: B is killed WHILE WAITING (its
# ticket outlives it, pid now dead) — C must not wait for a B that
# will never come; the moment A releases, C's turn comes next.
wait_for_line() {
    # wait_for_line <file> <pattern> <tries>
    i=0
    while [ "$i" -lt "$3" ]; do
        grep -q "$2" "$1" 2>/dev/null && return 0
        sleep 0.1
        i=$((i + 1))
    done
    return 1
}

test_lock_fifo() {
    lockdir="$scratch/lock-fifo"
    rm -rf "$lockdir"
    sig_a="$scratch/sig-a"
    sig_c="$scratch/sig-c"
    rm -f "$sig_a" "$sig_c"

    ( AVRA_LAND_LOCK="$lockdir" branch=A sh "$land" --call hold_lock_for "$sig_a" ) \
        > "$scratch/lock-a.out" 2>&1 &
    a_pid=$!
    if ! wait_for_line "$scratch/lock-a.out" "^acquired ticket 1$" 50; then
        bad "lock-fifo: A (first arrival) never acquired ticket 1"
    else
        ok "lock-fifo: A, arriving first, acquires ticket 1 immediately"
    fi

    ( AVRA_LAND_LOCK="$lockdir" branch=B sh "$land" --call hold_lock_for "$scratch/sig-b-never" ) \
        > "$scratch/lock-b.out" 2>&1 &
    b_pid=$!
    if wait_for_line "$scratch/lock-b.out" "^acquired" 10; then
        bad "lock-fifo: B acquired while A still holds the lock"
    else
        ok "lock-fifo: B waits behind A, as arrival order demands"
    fi

    # B dies WHILE WAITING — its ticket (2) is now nobody's.
    kill -9 "$b_pid" 2>/dev/null
    wait "$b_pid" 2>/dev/null

    ( AVRA_LAND_LOCK="$lockdir" branch=C sh "$land" --call hold_lock_for "$sig_c" ) \
        > "$scratch/lock-c.out" 2>&1 &
    c_pid=$!
    if wait_for_line "$scratch/lock-c.out" "^acquired" 10; then
        bad "lock-fifo: C acquired before A released — order violated"
    else
        ok "lock-fifo: C also waits, behind A (not stuck behind dead B)"
    fi

    touch "$sig_a"
    if ! wait_for_line "$scratch/lock-c.out" "^acquired ticket 3$" 50; then
        bad "lock-fifo: C never acquired ticket 3 after A released"
    else
        ok "lock-fifo: once A releases, C (ticket 3) is served next — B's dead ticket 2 never blocked it"
    fi
    if grep -q "reclaiming a dead ticket" "$scratch/lock-c.out" 2>/dev/null; then
        ok "lock-fifo: B's dead ticket is named as reclaimed"
    else
        bad "lock-fifo: nothing said B's dead ticket was reclaimed"
    fi

    touch "$sig_c"
    wait "$c_pid" 2>/dev/null
    wait "$a_pid" 2>/dev/null
    if [ -d "$lockdir/tickets" ] && [ -n "$(ls "$lockdir/tickets" 2>/dev/null)" ]; then
        bad "lock-fifo: a ticket was left behind after every holder released"
    else
        ok "lock-fifo: no ticket outlives its holder's release"
    fi
    rm -rf "$lockdir"
}

# ══ THE MERGE: A SEED-ONLY CONFLICT RESOLVES, ANY OTHER ABORTS ═══════
test_merge_seed_conflict() {
    d="$(git_repo merge-seed)"
    mkdir -p "$d/bootstrap"
    printf 'seed A\n' > "$d/bootstrap/seed.ll"
    printf 'digest A\n' > "$d/bootstrap/seed.sources"
    printf 'fn a\n' > "$d/other.txt"
    commit_all "$d" "base"

    git -C "$d" checkout -q -b lane
    printf 'seed LANE\n' > "$d/bootstrap/seed.ll"
    commit_all "$d" "lane re-emits the seed"

    git -C "$d" checkout -q main
    printf 'seed MAIN\n' > "$d/bootstrap/seed.ll"
    commit_all "$d" "main re-emits the seed too"

    git -C "$d" checkout -q lane
    if branch=lane sh "$land" --call merge_main_in "$d" > "$scratch/merge-seed.out" 2>&1; then
        ok "merge: a conflict confined to the seed resolves"
    else
        bad "merge: a seed-only conflict was not auto-resolved"
        cat "$scratch/merge-seed.out"
    fi
    if [ "$(cat "$d/bootstrap/seed.ll")" = "seed MAIN" ]; then
        ok "merge: the resolved seed is main's own words"
    else
        bad "merge: the resolved seed is not main's — $(cat "$d/bootstrap/seed.ll" 2>/dev/null)"
    fi
    if git -C "$d" status --porcelain | grep -q .; then
        bad "merge: the tree is not clean after a resolved seed conflict"
    else
        ok "merge: the tree is clean after a resolved seed conflict"
    fi
}

test_merge_real_conflict() {
    d="$(git_repo merge-real)"
    printf 'fn a\n' > "$d/real.txt"
    commit_all "$d" "base"

    git -C "$d" checkout -q -b lane
    printf 'lane change\n' > "$d/real.txt"
    commit_all "$d" "lane edits real.txt"

    git -C "$d" checkout -q main
    printf 'main change\n' > "$d/real.txt"
    commit_all "$d" "main edits real.txt too"

    git -C "$d" checkout -q lane
    before_sha="$(git -C "$d" rev-parse HEAD)"
    if branch=lane sh "$land" --call merge_main_in "$d" > "$scratch/merge-real.out" 2>&1; then
        bad "merge: a real conflict was silently resolved (should abort)"
    else
        ok "merge: a real conflict refuses"
    fi
    if grep -q "real.txt" "$scratch/merge-real.out"; then
        ok "merge: the refusal names the conflicting file"
    else
        bad "merge: the refusal did not name real.txt"
    fi
    after_sha="$(git -C "$d" rev-parse HEAD)"
    if [ "$before_sha" = "$after_sha" ] && ! git -C "$d" status --porcelain | grep -q .; then
        ok "merge: the tree is back to clean after an aborted real conflict"
    else
        bad "merge: the tree was left mid-merge after an aborted conflict"
    fi
}

# ══ AFFECTED-PACKAGE COMPUTATION ══════════════════════════════════════
write_pkg() {
    root="$1"
    name="$2"
    std_name="$3"   # empty for a package with no @std/ name (like "cli")
    mkdir -p "$root/packages/$name/src"
    if [ -n "$std_name" ]; then
        printf '[package]\nname = "@std/%s"\nversion = "0.1.0"\n' "$std_name" > "$root/packages/$name/avra.toml"
    else
        printf '[package]\nname = "%s"\nversion = "0.1.0"\n' "$name" > "$root/packages/$name/avra.toml"
    fi
    printf 'export fn seed_%s() -> int { 0 }\n' "$name" > "$root/packages/$name/src/lib.av"
}

test_affected_packages() {
    d="$(git_repo affected)"
    write_pkg "$d" "std-leaf" "leaf"
    write_pkg "$d" "std-mid" "mid"
    printf 'use @std.leaf.{seed_std-leaf}\n' > "$d/packages/std-mid/src/lib.av"
    write_pkg "$d" "cli" ""
    printf 'use @std.mid.{x}\n' > "$d/packages/cli/src/lib.av"
    mkdir -p "$d/packages/std-avrac/src" "$d/runtime"
    printf '[package]\nname = "@std/avrac"\nversion = "0.1.0"\n' > "$d/packages/std-avrac/avra.toml"
    printf 'export fn c() -> int { 0 }\n' > "$d/packages/std-avrac/src/lib.av"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"

    # Only the leaf moves: the affected set is the leaf, its direct
    # dependent std-mid, AND cli — a THREE-deep chain (cli uses
    # std-mid, std-mid uses std-leaf), so the closure must not stop
    # after one round of reverse-lookup.
    printf 'export fn seed_std-leaf() -> int { 1 }\n' > "$d/packages/std-leaf/src/lib.av"
    commit_all "$d" "leaf edit"
    got="$(sh "$affected" "$base_sha" HEAD "$d" | sort | tr '\n' ' ')"
    want="cli std-leaf std-mid "
    if [ "$got" = "$want" ]; then
        ok "affected: a leaf's edit closes over a three-deep dependency chain"
    else
        bad "affected: wanted [$want] got [$got]"
    fi

    # A compiler-path change (packages/std-avrac) means test everything.
    git -C "$d" checkout -q -b compiler-change "$base_sha"
    printf 'export fn c() -> int { 1 }\n' > "$d/packages/std-avrac/src/lib.av"
    commit_all "$d" "compiler edit"
    got="$(sh "$affected" "$base_sha" HEAD "$d" | sort | tr '\n' ' ')"
    want="$(cd "$d" && for p in packages/*/; do basename "$p"; done | sort | tr '\n' ' ')"
    if [ "$got" = "$want" ]; then
        ok "affected: a packages/std-avrac edit tests every package"
    else
        bad "affected: a compiler edit did not test every package — got [$got]"
    fi

    # A file outside any package (e.g. docs/) touches nothing.
    git -C "$d" checkout -q -b nothing "$base_sha"
    mkdir -p "$d/docs"
    printf 'x\n' > "$d/docs/note.md"
    commit_all "$d" "a doc, nothing else"
    got="$(sh "$affected" "$base_sha" HEAD "$d" | tr -d '[:space:]')"
    if [ -z "$got" ]; then
        ok "affected: a doc-only change tests nothing"
    else
        bad "affected: a doc-only change wrongly named [$got]"
    fi
}

# ══ SLOT.SH: THE LIMIT, AND STALE-SLOT CLEANUP ════════════════════════
test_slot_limit() {
    dir="$scratch/slots-limit"
    rm -rf "$dir"
    for i in 1 2 3; do
        ( AVRA_SLOTS_DIR="$dir" sh "$slot" 2 sh -c "echo start; sleep 1.5; echo end" \
            > "$scratch/slot-out-$i.txt" 2>&1 ) &
    done
    wait
    waited=0
    for i in 1 2 3; do
        grep -q "busy" "$scratch/slot-out-$i.txt" 2>/dev/null && waited=$((waited + 1))
        grep -q "^start$" "$scratch/slot-out-$i.txt" 2>/dev/null || bad "slot: contender $i never ran"
    done
    if [ "$waited" -eq 1 ]; then
        ok "slot: with 2 slots and 3 contenders, exactly one waits"
    else
        bad "slot: expected exactly 1 waiting contender, saw $waited"
    fi
}

test_slot_stale_reclaim() {
    dir="$scratch/slots-stale"
    rm -rf "$dir"
    mkdir -p "$dir/slot-0"
    echo 999999 > "$dir/slot-0/pid"   # almost certainly no such process
    start="$(date +%s)"
    if AVRA_SLOTS_DIR="$dir" sh "$slot" 1 echo "reclaimed" > "$scratch/slot-stale.out" 2>&1; then
        elapsed=$(($(date +%s) - start))
        if [ "$elapsed" -le 2 ]; then
            ok "slot: a stale slot (dead pid) is reclaimed immediately, not waited out"
        else
            bad "slot: a stale slot took ${elapsed}s to reclaim — looks waited, not reclaimed"
        fi
    else
        bad "slot: a stale slot was never reclaimed at all"
    fi
}

# ══ THE CACHE SWEEP RUNS TWICE, AND THE SECOND RUN IS A CLEAN NO-OP ═══
# land.sh moves every .avra-cache aside BEFORE the build (a compiler
# print collision, avra-8sb5.57.24/.25) AND AGAIN between the test
# suites and the keepers (avra test and avra check sharing a record
# key, the same bug's other face). The second call must find nothing
# left to move — the first already swept everything — and must not
# treat an already-clean tree as a failure.
test_caches_aside_twice() {
    tree="$scratch/caches-twice"
    rm -rf "$tree"
    mkdir -p "$tree/packages/a/.avra-cache/rows" "$tree/packages/b/.avra-cache/rows"

    if ! branch=x sh "$land" --call move_caches_aside "$tree" > "$scratch/caches-1.out" 2>&1; then
        bad "caches-twice: the first sweep failed"
    fi
    left="$(find "$tree" -maxdepth 4 -name .avra-cache -type d 2>/dev/null)"
    if [ -z "$(printf '%s' "$left" | tr -d '[:space:]')" ]; then
        ok "caches-twice: the first sweep moves every .avra-cache aside"
    else
        bad "caches-twice: a .avra-cache survived the first sweep: $left"
    fi

    if branch=x sh "$land" --call move_caches_aside "$tree" > "$scratch/caches-2.out" 2>&1; then
        ok "caches-twice: a second sweep over an already-clean tree still exits clean"
    else
        bad "caches-twice: a second sweep over a clean tree failed"
    fi
    if grep -q "no .avra-cache" "$scratch/caches-2.out" 2>/dev/null; then
        ok "caches-twice: the second sweep says there was nothing left to move"
    else
        bad "caches-twice: the second sweep did not say the tree was already clean"
    fi
}

# ══ THE SEED COMMIT: MOVED IS COMMITTED, UNCHANGED IS A NO-OP ═══════
test_commit_seed_if_moved() {
    d="$(git_repo seed-commit)"
    mkdir -p "$d/bootstrap"
    printf 'seed A\n' > "$d/bootstrap/seed.ll"
    printf 'digest A\n' > "$d/bootstrap/seed.sources"
    commit_all "$d" "base"
    before_sha="$(git -C "$d" rev-parse HEAD)"

    # Unchanged: no commit.
    if branch=x sh "$land" --call commit_seed_if_moved "$d" "x" > "$scratch/seed-noop.out" 2>&1; then
        after_sha="$(git -C "$d" rev-parse HEAD)"
        if [ "$before_sha" = "$after_sha" ]; then
            ok "seed-commit: an unchanged seed commits nothing"
        else
            bad "seed-commit: an unchanged seed still made a commit"
        fi
    else
        bad "seed-commit: the unchanged case returned non-zero"
    fi

    # Moved: exactly one commit, naming the branch.
    printf 'seed B\n' > "$d/bootstrap/seed.ll"
    if branch=x sh "$land" --call commit_seed_if_moved "$d" "my-branch" > "$scratch/seed-moved.out" 2>&1; then
        after_sha="$(git -C "$d" rev-parse HEAD)"
        if [ "$before_sha" != "$after_sha" ] && ! git -C "$d" status --porcelain | grep -q .; then
            ok "seed-commit: a moved seed is committed, tree clean after"
        else
            bad "seed-commit: a moved seed left the tree dirty or uncommitted"
        fi
        if git -C "$d" log -1 --format=%s | grep -q "my-branch"; then
            ok "seed-commit: the commit message names the landing branch"
        else
            bad "seed-commit: the commit message did not name the branch"
        fi
    else
        bad "seed-commit: committing a moved seed returned non-zero"
        cat "$scratch/seed-moved.out"
    fi
}

# ══ THE FAST-FORWARD: CLEAN WHEN LINEAR, REFUSED WHEN MAIN ALSO MOVED ═
test_try_ff() {
    d="$(git_repo ff)"
    printf 'a\n' > "$d/f.txt"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"

    branch_wt_dir="$scratch/ff-branch-wt"
    git -C "$d" worktree add -q -b feature "$branch_wt_dir" main > /dev/null 2>&1
    printf 'b\n' >> "$branch_wt_dir/f.txt"
    commit_all "$branch_wt_dir" "feature work"

    if ( main_wt="$d" branch=feature sh "$land" --call try_ff ) > "$scratch/ff-clean.out" 2>&1; then
        ok "ff: a linear branch fast-forwards main cleanly"
    else
        bad "ff: a linear, uncontested branch failed to fast-forward"
        cat "$scratch/ff-clean.out"
    fi

    # Now main ALSO moves, independently — the branch no longer fast-forwards.
    printf 'c\n' >> "$d/f.txt"
    commit_all "$d" "main moved independently"
    git -C "$branch_wt_dir" checkout -q -B feature2 "$base_sha"
    printf 'd\n' >> "$branch_wt_dir/f.txt"
    commit_all "$branch_wt_dir" "a second feature, from the OLD base"
    if ( main_wt="$d" branch=feature2 sh "$land" --call try_ff ) > "$scratch/ff-race.out" 2>&1; then
        bad "ff: a branch behind main's NEW tip fast-forwarded anyway"
    else
        ok "ff: a branch behind main's new tip correctly refuses to fast-forward"
    fi
    git -C "$d" worktree remove -f "$branch_wt_dir" > /dev/null 2>&1
}

echo "=== land tooling fixtures ==="
test_lock_fifo
test_merge_seed_conflict
test_merge_real_conflict
test_affected_packages
test_slot_limit
test_slot_stale_reclaim
test_caches_aside_twice
test_commit_seed_if_moved
test_try_ff

echo
echo "land_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
