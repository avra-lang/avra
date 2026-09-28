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
# Every process a fixture started names the scratch dir; none outlives the run.
cleanup() {
    pkill -9 -f "$scratch" 2>/dev/null
    rm -rf "$scratch"
}
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
    if ! wait_for_line "$scratch/lock-a.out" "^acquired ticket 1$" 150; then
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
    # A deep queue, with SIGPIPE ignored as a harness's children inherit
    # it: a waiter's scan writes into no pipe, so its log stays a few
    # lines however long it waits.
    for w in d e f; do
        ( trap '' PIPE; export AVRA_LAND_LOCK="$lockdir" branch=$w; exec sh "$land" --call hold_lock_for "$scratch/sig-$w-never" ) \
            > "$scratch/lock-$w.out" 2>&1 &
        eval "${w}_pid=\$!"
    done
    sleep 8
    grown=0
    for w in c d e f; do
        [ "$(wc -l < "$scratch/lock-$w.out")" -le 3 ] || grown=1
    done
    if [ "$grown" -eq 0 ]; then
        ok "lock-fifo: every waiter's log stays a few lines over a long wait"
    else
        bad "lock-fifo: a waiter's log grew while waiting"
    fi
    for w in d e f; do eval "kill -9 \$${w}_pid" 2>/dev/null; done

    touch "$sig_a"
    if ! wait_for_line "$scratch/lock-c.out" "^acquired ticket 3$" 150; then
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

# ══ run_checks: std-avrac, cli AND idioms RUN ONE AT A TIME ═════════
# SEQUENTIAL is the LAW here, not an optimization not yet made: two
# avra processes compiling into one .avra-cache AT ONCE corrupt it
# (avra-8sb5.57.41 — tried as a concurrent batch, both suites failed
# to link with undefined av_ symbols). This fixture pins the opposite
# property a concurrent version would have broken: std-avrac (or
# cli), whichever runs first, must FULLY FINISH before idioms starts
# — never an overlap, whatever the machine's speed. A throwaway tree
# with a STUB `build/avra` and `Makefile` (each just sleeps and logs
# a timestamped start/end line) makes this observable without a real
# build.
test_run_checks_sequential() {
    d="$(git_repo checks-sequential)"
    write_pkg "$d" "std-avrac" "avrac"
    write_pkg "$d" "cli" ""
    write_pkg "$d" "other" ""
    mkdir -p "$d/build"
    timeline="$scratch/checks-sequential-timeline"
    cat > "$d/build/avra" <<STUB
#!/bin/sh
pkg="\$(basename "\$2")"
echo "start \$pkg \$(date +%s)" >> "$timeline"
sleep 1
echo "end \$pkg \$(date +%s)" >> "$timeline"
if [ "\$pkg" = "\${FAIL_PKG:-}" ]; then
    echo "FAILED \$pkg"
    exit 1
fi
echo "tested \$pkg"
STUB
    chmod +x "$d/build/avra"
    printf 'idioms:\n\techo "start idioms $$(date +%%s)" >> %s && sleep 1 && echo "end idioms $$(date +%%s)" >> %s && echo idioms-ok\n' \
        "$timeline" "$timeline" > "$d/Makefile"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    for p in std-avrac cli other; do
        printf 'export fn seed_%s() -> int { 1 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    commit_all "$d" "touch all three"

    slots="$scratch/checks-sequential-slots"
    rm -rf "$slots"
    rm -f "$timeline"

    if AVRA_SLOTS_DIR="$slots" branch=x sh "$land" --call run_checks "$d" "$base_sha" HEAD "" \
        > "$scratch/checks-sequential.out" 2>&1; then
        # Every "end" must precede the NEXT line's "start" — a total
        # order, not just idioms-after-the-rest: nothing may overlap.
        overlap=0
        prev_end=""
        while read -r kind pkg ts; do
            case "$kind" in
                start)
                    if [ -n "$prev_end" ] && [ "$ts" -lt "$prev_end" ]; then overlap=1; fi
                    ;;
                end) prev_end="$ts" ;;
            esac
        done < "$timeline"
        if [ "$overlap" -eq 0 ]; then
            ok "run_checks: std-avrac/cli and idioms never overlap — strictly sequential"
        else
            bad "run_checks: two steps overlapped — this must stay sequential (avra-8sb5.57.41)"
            cat "$timeline"
        fi
    else
        bad "run_checks: the all-passing case failed"
        cat "$scratch/checks-sequential.out"
    fi

    # Now make cli fail — the run must fail closed and NAME cli.
    if FAIL_PKG=cli AVRA_SLOTS_DIR="$slots" branch=x sh "$land" --call run_checks "$d" "$base_sha" HEAD "" \
        > "$scratch/checks-sequential-fail.out" 2>&1; then
        bad "run_checks: a failing package's test did not fail the run"
    else
        ok "run_checks: a failing package's test fails the whole run"
    fi
    if grep -q "FAILED at 'test-cli" "$scratch/checks-sequential-fail.out" 2>/dev/null; then
        ok "run_checks: the failure report names test-cli specifically"
    else
        bad "run_checks: the failure was not attributed to test-cli by name"
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

# ══ THE CACHE SWEEP IS SAFE TO RUN TWICE IN A ROW ═════════════════════
# move_caches_aside is no longer wired into a landing (avra-8sb5.57.24
# and .25, the two bugs it existed to guard against, are both closed
# on main) but stays a callable utility — this pins the property that
# made it safe to call more than once when it WAS in the pipeline: a
# second call over an already-clean tree finds nothing left to move
# and says so, rather than treating that as a failure.
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

# ══ BATCH MODE: THREE BRANCHES, ONE HAS A FAILING TEST ═══════════════
# A full stub toolchain (build/avra, Makefile) so main_batch's real
# pipeline — merge, build, run_checks, fmt-lossless, cache-attacks,
# seed_policy — runs against a throwaway repo, never the real one.
# Branch b's own package always fails its "test"; a and c always
# pass. The batch must land a+c, name b as the culprit, and exit
# non-zero (a batch that excludes anything did not fully succeed).
# A repo whose `build/avra` and Makefile stand in for the real ones:
# branches a, b and c each change their own package, and a package
# named by CULPRIT_PKG fails its tests.
batch_repo() {
    d="$(git_repo "$1")"
    for p in a b c; do
        mkdir -p "$d/packages/$p/src"
        printf '[package]\nname = "%s"\nversion = "0.1.0"\n' "$p" > "$d/packages/$p/avra.toml"
        printf 'export fn seed_%s() -> int { 0 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    mkdir -p "$d/build" "$d/packages/cli/src" "$d/bootstrap"
    cat > "$d/build/avra" <<'STUB'
#!/bin/sh
# build_generation copies packages/cli/src/main OVER build/avra after
# a successful "build" — the "new" compiler it thinks it produced —
# so the build case must leave a COPY OF THIS WHOLE STUB there, self-
# replicating, or every later "test" invocation runs a dumb placeholder
# with no test/culprit logic at all (found exactly this way: every
# package's test silently reported OK because build/avra had been
# overwritten with a one-line "echo built" stand-in).
case "$1" in
    build)
        [ -n "${SLOW_BUILD:-}" ] && sleep "$SLOW_BUILD"
        mkdir -p packages/cli/src
        cp "$0" packages/cli/src/main
        chmod +x packages/cli/src/main
        exit 0
        ;;
    test)
        pkg="$(basename "$2")"
        if [ "$pkg" = "${CULPRIT_PKG:-}" ]; then
            echo "FAILED $pkg"
            exit 1
        fi
        echo "tested $pkg"
        exit 0
        ;;
esac
STUB
    chmod +x "$d/build/avra"
    cat > "$d/Makefile" <<'MK'
build/libavra_runtime.a:
	@touch build/libavra_runtime.a
libs:
	@echo libs-ok
idioms:
	@echo idioms-ok
fmt-lossless:
	@echo fmt-ok
cache-attacks:
	@echo cache-attacks-ok
seed:
	@echo seed-src > bootstrap/seed.ll
	@echo seed-src > bootstrap/seed.sources
seed-check:
	@test -f bootstrap/seed.ll && echo seed-check-ok
MK
    printf 'seed-src\n' > "$d/bootstrap/seed.ll"
    printf 'seed-src\n' > "$d/bootstrap/seed.sources"
    # build/ is untracked, as in the real tree: a fresh worktree has no compiler.
    printf 'build/\n' > "$d/.gitignore"
    commit_all "$d" "base"

    for p in a b c; do
        git -C "$d" checkout -q -b "$p" main
        printf 'export fn seed_%s() -> int { 1 }\n' "$p" > "$d/packages/$p/src/lib.av"
        commit_all "$d" "$p's own change"
    done
    git -C "$d" checkout -q main

    echo "$d"
}

test_batch_mode() {
    d="$(batch_repo batch)"
    lockdir="$scratch/batch-lock"
    batchwt="$scratch/batch-integration-wt"
    slots="$scratch/batch-slots"
    rm -rf "$lockdir" "$batchwt" "$slots"

    st=0
    ( cd "$d" && AVRA_LAND_LOCK="$lockdir" AVRA_LAND_BATCH_WT="$batchwt" AVRA_SLOTS_DIR="$slots" \
        CULPRIT_PKG=b branch=x sh "$land" --call main_batch 0 a b c ) \
        > "$scratch/batch.out" 2>&1 || st=$?

    if [ "$st" -ne 0 ]; then
        ok "batch: exits non-zero when a culprit was excluded"
    else
        bad "batch: exited 0 despite excluding a culprit"
    fi
    if grep -q "CULPRIT: b" "$scratch/batch.out"; then
        ok "batch: names b as the culprit"
    else
        bad "batch: did not name b as the culprit"
        cat "$scratch/batch.out"
    fi
    if grep -qE "green subset: (a c|c a)" "$scratch/batch.out"; then
        ok "batch: the green subset is exactly a and c"
    else
        bad "batch: the green subset was not reported as a and c"
        cat "$scratch/batch.out"
    fi
    if grep -q "^LANDED" "$scratch/batch.out"; then
        ok "batch: still lands the green subset despite the culprit"
    else
        bad "batch: did not land anything"
    fi
    main_head_a="$(git -C "$d" show main:packages/a/src/lib.av 2>/dev/null)"
    main_head_b="$(git -C "$d" show main:packages/b/src/lib.av 2>/dev/null)"
    if printf '%s' "$main_head_a" | grep -q "int { 1 }" && ! printf '%s' "$main_head_b" | grep -q "int { 1 }"; then
        ok "batch: main carries a's change but not b's"
    else
        bad "batch: main's content after landing does not match a-in, b-out"
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

test_heavy_status() {
    slots="$scratch/heavy-slots"
    out="$scratch/heavy.out"
    st=0
    AVRA_SLOTS_DIR="$slots" branch=x sh "$land" --call heavy failing sh -c "exit 3" > "$out" 2>&1 || st=$?
    if [ "$st" -eq 3 ] && grep -q "FAILED at 'failing' (exit 3)" "$out"; then
        ok "heavy answers a failing step's own status"
    else
        bad "heavy answers a failing step's own status (got $st)"
    fi
    st=0
    AVRA_SLOTS_DIR="$slots" branch=x sh "$land" --call heavy passing sh -c "exit 0" > "$out" 2>&1 || st=$?
    if [ "$st" -eq 0 ] && grep -q "land: passing OK" "$out"; then
        ok "heavy answers 0 for a passing step"
    else
        bad "heavy answers 0 for a passing step (got $st)"
    fi
    st=0
    AVRA_MEMCAP_MB=200 AVRA_SLOTS_DIR="$slots" branch=x sh "$land" --call heavy hog \
        python3 -c "import time
x = bytearray(400 * 1024 * 1024)
end = time.time() + 8
while time.time() < end:
    for i in range(0, len(x), 4096): x[i] = 1" > "$out" 2>&1 || st=$?
    if [ "$st" -eq 137 ] && grep -q "memcap: KILLED" "$out"; then
        ok "heavy kills a step past the memory cap with 137"
    else
        bad "heavy kills a step past the memory cap with 137 (got $st)"
    fi
}

test_ff_refused_not_moved() {
    d="$(git_repo ff-refused)"
    printf 'a\n' > "$d/f.txt"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    wt="$scratch/ff-refused-wt"
    git -C "$d" worktree add -q -b adds "$wt" main > /dev/null 2>&1
    printf 'new\n' > "$wt/added.txt"
    commit_all "$wt" "adds a file"
    printf 'squatter\n' > "$d/added.txt"
    log="$scratch/ff-refused.log"
    ( main_wt="$d" branch=adds sh "$land" --call try_ff ) > "$log" 2>&1
    if ( main_wt="$d" sh "$land" --call main_moved_since "$base_sha" ); then
        bad "ff: a refused fast-forward with main standing still reads as main moved"
    else
        ok "ff: a refused fast-forward with main standing still is not main moving"
    fi
    st=0
    ( main_wt="$d" sh "$land" --call ff_refused "$log" ) > "$scratch/ff-refused.out" 2>&1 || st=$?
    if [ "$st" -ne 0 ] && grep -q "untracked working tree files would be overwritten" "$scratch/ff-refused.out"; then
        ok "ff: a refusal stops with git's own words"
    else
        bad "ff: a refusal stops with git's own words (got $st)"
    fi
    git -C "$d" worktree remove -f "$wt" > /dev/null 2>&1
}

test_auto_batch() {
    d="$(batch_repo auto-batch)"
    wt_a="$scratch/auto-batch-a"
    git -C "$d" worktree add -q "$wt_a" a > /dev/null 2>&1
    lockdir="$scratch/auto-batch-lock"
    batchwt="$scratch/auto-batch-integration-wt"
    slots="$scratch/auto-batch-slots"
    hold="$scratch/auto-batch-hold"
    export AVRA_LAND_LOCK="$lockdir" AVRA_LAND_BATCH_WT="$batchwt" AVRA_SLOTS_DIR="$slots" CULPRIT_PKG=c AVRA_LAND_ABSORB=1
    ( branch=holder exec sh "$land" --call hold_lock_for "$hold" ) > "$scratch/auto-holder.out" 2>&1 &
    wait_for_line "$scratch/auto-holder.out" "^acquired ticket 1$" 150 > /dev/null
    ( cd "$wt_a" && exec sh "$land" a ) > "$scratch/auto-a.out" 2>&1 &
    a_pid=$!
    wait_for_line "$scratch/auto-a.out" "waiting behind" 150 > /dev/null
    ( cd "$d" && exec sh "$land" b ) > "$scratch/auto-b.out" 2>&1 &
    b_pid=$!
    wait_for_line "$scratch/auto-b.out" "waiting behind" 150 > /dev/null
    ( cd "$d" && exec sh "$land" c ) > "$scratch/auto-c.out" 2>&1 &
    c_pid=$!
    wait_for_line "$scratch/auto-c.out" "waiting behind" 150 > /dev/null
    touch "$hold"
    a_st=0; wait "$a_pid" || a_st=$?
    b_st=0; wait "$b_pid" || b_st=$?
    c_st=0; wait "$c_pid" || c_st=$?
    unset AVRA_LAND_LOCK AVRA_LAND_BATCH_WT AVRA_SLOTS_DIR CULPRIT_PKG AVRA_LAND_ABSORB
    if [ "$(grep -c "absorbing the queue" "$scratch/auto-a.out")" -eq 1 ] && ! grep -q "absorbing" "$scratch/auto-b.out"; then
        ok "auto-batch: the lock's taker absorbs the queue behind it, once"
    else
        bad "auto-batch: the queue was not absorbed by exactly one run"
        cat "$scratch/auto-a.out"
    fi
    if [ "$a_st" -eq 0 ] && [ "$b_st" -eq 0 ] && grep -q "^LANDED" "$scratch/auto-b.out"; then
        ok "auto-batch: the taker and an absorbed waiter both land, each told so"
    else
        bad "auto-batch: a ($a_st) or b ($b_st) did not land"
        cat "$scratch/auto-b.out"
    fi
    if [ "$c_st" -ne 0 ] && grep -q "bisected out" "$scratch/auto-c.out"; then
        ok "auto-batch: the bad branch is bisected out and its waiter exits red"
    else
        bad "auto-batch: c ($c_st) was not bisected out"
        cat "$scratch/auto-c.out"
    fi
    on_main() { git -C "$d" show "main:packages/$1/src/lib.av" 2>/dev/null | grep -q "int { 1 }"; }
    if on_main a && on_main b && ! on_main c; then
        ok "auto-batch: main carries a and b and not c"
    else
        bad "auto-batch: main's content does not match a and b in, c out"
    fi
}

test_auto_batch_holder_stopped() {
    d="$(batch_repo auto-stop)"
    wt_a="$scratch/auto-stop-a"
    git -C "$d" worktree add -q "$wt_a" a > /dev/null 2>&1
    hold="$scratch/auto-stop-hold"
    export AVRA_LAND_LOCK="$scratch/auto-stop-lock" AVRA_LAND_BATCH_WT="$scratch/auto-stop-wt" AVRA_SLOTS_DIR="$scratch/auto-stop-slots" SLOW_BUILD=20 AVRA_LAND_ABSORB=1
    ( branch=holder exec sh "$land" --call hold_lock_for "$hold" ) > "$scratch/auto-stop-holder.out" 2>&1 &
    wait_for_line "$scratch/auto-stop-holder.out" "^acquired ticket 1$" 150 > /dev/null
    ( cd "$wt_a" && exec sh "$land" a ) > "$scratch/auto-stop-a.out" 2>&1 &
    a_pid=$!
    wait_for_line "$scratch/auto-stop-a.out" "waiting behind" 150 > /dev/null
    ( cd "$d" && exec sh "$land" b ) > "$scratch/auto-stop-b.out" 2>&1 &
    b_pid=$!
    wait_for_line "$scratch/auto-stop-b.out" "waiting behind" 150 > /dev/null
    touch "$hold"
    wait_for_line "$scratch/auto-stop-a.out" "absorbing the queue" 150 > /dev/null
    kill -TERM "$a_pid"
    b_st=0; wait "$b_pid" || b_st=$?
    wait "$a_pid" 2>/dev/null
    unset AVRA_LAND_LOCK AVRA_LAND_BATCH_WT AVRA_SLOTS_DIR SLOW_BUILD AVRA_LAND_ABSORB
    if [ "$b_st" -ne 0 ] && grep -q "stopped before a verdict" "$scratch/auto-stop-b.out"; then
        ok "auto-batch: a holder stopped mid-batch hands its absorbed waiters a verdict"
    else
        bad "auto-batch: an absorbed waiter was stranded or misled by a stopped holder ($b_st)"
        cat "$scratch/auto-stop-b.out"
    fi
}

test_batch_tool_failure() {
    d="$(batch_repo batch-tool)"
    mv "$d/build/avra" "$scratch/batch-tool-avra-aside"
    st=0
    ( cd "$d" && AVRA_LAND_LOCK="$scratch/batch-tool-lock" AVRA_LAND_BATCH_WT="$scratch/batch-tool-wt" \
        AVRA_SLOTS_DIR="$scratch/batch-tool-slots" branch=x sh "$land" --call main_batch 0 a b ) \
        > "$scratch/batch-tool.out" 2>&1 || st=$?
    if [ "$st" -ne 0 ] && grep -q "TOOL FAILURE" "$scratch/batch-tool.out" && ! grep -q "CULPRIT" "$scratch/batch-tool.out"; then
        ok "batch: a missing compiler is a tool failure, and no branch is blamed"
    else
        bad "batch: a missing compiler was not reported as a tool failure ($st)"
        cat "$scratch/batch-tool.out"
    fi
}

test_batch_stale_registration() {
    d="$(batch_repo batch-stale)"
    git -C "$d" worktree add -q -b land/batch-integration "$scratch/batch-stale-old" main > /dev/null 2>&1
    st=0
    ( cd "$d" && AVRA_LAND_LOCK="$scratch/batch-stale-lock" AVRA_LAND_BATCH_WT="$scratch/batch-stale-new" \
        AVRA_SLOTS_DIR="$scratch/batch-stale-slots" branch=x sh "$land" --call main_batch 0 a c ) \
        > "$scratch/batch-stale.out" 2>&1 || st=$?
    if [ "$st" -eq 0 ] && grep -q "^LANDED" "$scratch/batch-stale.out" && ! grep -q "CULPRIT" "$scratch/batch-stale.out"; then
        ok "batch: a batch branch still registered to an older tree does not block the batch"
    else
        bad "batch: a stale batch-branch registration blocked the batch ($st)"
        cat "$scratch/batch-stale.out"
    fi
}

echo "=== land tooling fixtures ==="
test_lock_fifo
test_merge_seed_conflict
test_merge_real_conflict
test_affected_packages
test_run_checks_sequential
test_slot_limit
test_slot_stale_reclaim
test_caches_aside_twice
test_commit_seed_if_moved
test_try_ff
test_batch_mode
test_batch_tool_failure
test_batch_stale_registration
test_heavy_status
test_auto_batch
test_auto_batch_holder_stopped
test_ff_refused_not_moved

echo
echo "land_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
