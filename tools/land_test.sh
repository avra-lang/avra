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

# The Linux gate defaults ON for a real landing, and the speed gate
# may (land.sh's own header) — a bare run_checks call in a fixture below must never
# reach a live Sprite or run a real cold build. OFF here, by default;
# the fixtures that exercise these two gates re-arm them locally
# (env-var prefix on that one command), each with its own stub.
AVRA_LAND_LINUX=0
AVRA_LAND_SPEED_GATE=0
export AVRA_LAND_LINUX AVRA_LAND_SPEED_GATE

scratch="/tmp/avra-land-test-$$"
mkdir -p "$scratch"
# No fixture prunes the machine's real scratch root.
export AVRA_LAND_SCRATCH_ROOT="$scratch/scratch-root"
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

# ══ THE TEST POOL — every test_* fn in its own subshell, bounded by
# AVRA_LAND_TEST_JOBS (default 8), the same job-list/status-file shape
# land.sh's own run_checks uses for its parallel gates. `total`/
# `failed` above are updated by ok()/bad() inside each fn's OWN
# subshell and never reach this process — a fork's globals die with
# it — so the real counts are read back from every captured log once
# every job has finished, and printed back in LAUNCH order (never
# completion order) so the report reads exactly as the serial one did.
test_logs="$scratch/test-logs"
test_status="$scratch/test-status"
mkdir -p "$test_logs" "$test_status"
: > "$scratch/test-jobs.list"

tests_running() {
    n=0
    while read -r pid name; do
        [ -z "$pid" ] && continue
        [ -f "$test_status/$name.status" ] || n=$((n + 1))
    done < "$scratch/test-jobs.list"
    echo "$n"
}

run_test() {
    name="$1"
    cap="${AVRA_LAND_TEST_JOBS:-8}"
    while [ "$(tests_running)" -ge "$cap" ]; do sleep 0.2; done
    ( set +e; "$name" > "$test_logs/$name.log" 2>&1; st=$?; echo "$st" > "$test_status/$name.status"; exit "$st" ) &
    echo "$! $name" >> "$scratch/test-jobs.list"
}

# Waits for every launched test (each `wait $pid` returns whenever
# THAT job finishes, whatever order that happens in), prints its
# captured output the moment it is ready to print IN LIST ORDER, and
# tallies every `ok`/`FAIL` line across every log — a scan, never a
# counter, for the reason ok()/bad() are commented on above.
report_tests() {
    while read -r pid name; do
        [ -z "$pid" ] && continue
        wait "$pid" 2>/dev/null
        cat "$test_logs/$name.log"
    done < "$scratch/test-jobs.list"
    total="$(cat "$test_logs"/*.log 2>/dev/null | grep -cE '^(ok|FAIL)  ')"
    failed="$(cat "$test_logs"/*.log 2>/dev/null | grep -cE '^FAIL  ')"
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
    sleep 3
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
    if ! wait_for_line "$scratch/lock-c.out" "^acquired ticket 3$" 1800; then
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

# ══ run_checks: THE PARALLEL JOB POOL ═════════════════════════════════
# The write race that once forced every check to run one at a time
# (avra-8sb5.57.41) is fixed (content-keyed objects, publish by
# rename), so run_checks now launches a package's tests, idioms and
# fmt-lossless TOGETHER, bounded by AVRA_LAND_JOBS. A throwaway tree
# with a STUB `build/avra` (test AND check, each sleeping and logging
# a timestamped start/end line) and `Makefile` (fmt-lossless) makes
# this observable without a real build.
#
# `pa`/`pb`/`pc` — never `std-avrac`/`cli`: those names trip
# affected_packages.sh's OWN compiler-changed detection (a path
# prefix, not a fixture accident to route around).
parallel_checks_repo() {
    d="$(git_repo "$1")"
    for p in pa pb pc; do
        mkdir -p "$d/packages/$p/src"
        printf '[package]\nname = "%s"\nversion = "0.1.0"\n' "$p" > "$d/packages/$p/avra.toml"
        printf 'export fn seed_%s() -> int { 0 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    mkdir -p "$d/build"
    timeline="$2"
    cat > "$d/build/avra" <<STUB
#!/bin/sh
cmd="\$1"; path="\$2"
pkg="\$(basename "\$path")"
echo "start \$cmd \$pkg \$(date +%s)" >> "$timeline"
sleep "\${SLEEP_S:-1}"
echo "end \$cmd \$pkg \$(date +%s)" >> "$timeline"
case " \${FAIL_PKGS:-} " in
    *" \$pkg "*) echo "FAILED \$cmd \$pkg"; exit 1 ;;
esac
echo "\$cmd-ok \$pkg"
STUB
    chmod +x "$d/build/avra"
    printf 'fmt-lossless:\n\t@echo "start fmt-lossless $$(date +%%s)" >> %s && sleep "$${SLEEP_S:-1}" && echo "end fmt-lossless $$(date +%%s)" >> %s && echo fmt-ok\n' \
        "$timeline" "$timeline" > "$d/Makefile"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    for p in pa pb pc; do
        printf 'export fn seed_%s() -> int { 1 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    commit_all "$d" "touch all three"
    echo "$d $base_sha"
}

# ALL PASSING, AND CONCURRENT: 3 tests (1s each) + idioms (one job,
# 3 sequential checks inside it, ~3s) + fmt-lossless (1s) sum to ~6s
# run one at a time; AVRA_LAND_JOBS=4 launches all four TOP-LEVEL jobs
# together, so wall time tracks the LONGEST one (idioms), not the sum.
test_run_checks_parallel() {
    timeline="$scratch/checks-parallel-timeline"
    rm -f "$timeline"
    read -r d base_sha <<EOF
$(parallel_checks_repo checks-parallel "$timeline")
EOF
    scr="$scratch/checks-parallel-scratch"
    slots="$scratch/checks-parallel-slots"
    rm -rf "$scr" "$slots"

    if AVRA_LAND_JOBS=4 AVRA_LAND_SCRATCH="$scr" AVRA_SLOTS_DIR="$slots" branch=x \
        sh "$land" --call run_checks "$d" "$base_sha" HEAD "" 0 \
        > "$scratch/checks-parallel.out" 2>&1; then
        ok "run_checks: the all-passing case succeeds"
    else
        bad "run_checks: the all-passing case failed"
        cat "$scratch/checks-parallel.out"
    fi
    # Parallel means a second job STARTED before the first one ENDED —
    # read from the order jobs wrote their marks, never from a clock a
    # loaded machine can stretch.
    before_first_end="$(awk '/^end /{exit} /^start /{n++} END{print n+0}' "$timeline")"
    if [ "$before_first_end" -ge 2 ]; then
        ok "run_checks: $before_first_end jobs started before the first one ended — jobs ran together"
    else
        bad "run_checks: only $before_first_end job started before the first one ended — the checks ran serially"
        cat "$timeline"
    fi
}

# ONE FAILURE, NAMED WITH ITS LOG.
test_run_checks_one_fails() {
    timeline="$scratch/checks-one-fail-timeline"
    rm -f "$timeline"
    read -r d base_sha <<EOF
$(parallel_checks_repo checks-one-fail "$timeline")
EOF
    scr="$scratch/checks-one-fail-scratch"
    slots="$scratch/checks-one-fail-slots"
    rm -rf "$scr" "$slots"

    st=0
    FAIL_PKGS=pb AVRA_LAND_JOBS=4 AVRA_LAND_SCRATCH="$scr" AVRA_SLOTS_DIR="$slots" branch=x \
        sh "$land" --call run_checks "$d" "$base_sha" HEAD "" 0 \
        > "$scratch/checks-one-fail.out" 2>&1 || st=$?
    if [ "$st" -ne 0 ]; then
        ok "run_checks: a single failing package fails the whole run"
    else
        bad "run_checks: a failing package's test did not fail the run"
    fi
    # heavy() ALSO prints its own inline "FAILED at" the moment test-pb
    # fails, so a bare grep for the line would pass even with a broken
    # report_parallel_failures — isolate the text AFTER the consolidated
    # report's own marker to test THAT specifically.
    tail_report="$(sed -n '/^land: a parallel check failed:/,$p' "$scratch/checks-one-fail.out")"
    if printf '%s' "$tail_report" | grep -q "FAILED at 'test-pb' (exit 1) — log: $scr/logs/test-pb.log"; then
        ok "run_checks: the CONSOLIDATED report names test-pb and its own log path"
    else
        bad "run_checks: the consolidated report did not name test-pb by name and log"
        cat "$scratch/checks-one-fail.out"
    fi
}

# TWO FAILURES, BOTH NAMED — the consolidated report at the end lists
# every failed job, not just the first one seen.
test_run_checks_two_fail() {
    timeline="$scratch/checks-two-fail-timeline"
    rm -f "$timeline"
    read -r d base_sha <<EOF
$(parallel_checks_repo checks-two-fail "$timeline")
EOF
    scr="$scratch/checks-two-fail-scratch"
    slots="$scratch/checks-two-fail-slots"
    rm -rf "$scr" "$slots"

    st=0
    FAIL_PKGS="pa pc" AVRA_LAND_JOBS=4 AVRA_LAND_SCRATCH="$scr" AVRA_SLOTS_DIR="$slots" branch=x \
        sh "$land" --call run_checks "$d" "$base_sha" HEAD "" 0 \
        > "$scratch/checks-two-fail.out" 2>&1 || st=$?
    if [ "$st" -ne 0 ]; then
        ok "run_checks: two failing packages still fail the whole run"
    else
        bad "run_checks: two failing packages did not fail the run"
    fi
    # Isolate the CONSOLIDATED report (after its own marker line) — heavy()
    # already prints its own inline "FAILED at" per job as it happens, so
    # checking the whole output would pass even if the consolidated report
    # silently dropped one, or all, of the failures.
    tail_report="$(sed -n '/^land: a parallel check failed:/,$p' "$scratch/checks-two-fail.out")"
    if printf '%s' "$tail_report" | grep -q "FAILED at 'test-pa' (exit 1) — log: $scr/logs/test-pa.log" &&
        printf '%s' "$tail_report" | grep -q "FAILED at 'test-pc' (exit 1) — log: $scr/logs/test-pc.log"; then
        ok "run_checks: the CONSOLIDATED report names BOTH test-pa and test-pc with their own logs"
    else
        bad "run_checks: the consolidated report did not name both failing jobs with their logs"
        cat "$scratch/checks-two-fail.out"
    fi
}

# AVRA_LAND_JOBS BOUNDS CONCURRENCY. AVRA_LAND_JOBS=1 is the
# order-independent proof: with one slot, whatever job_launch's own
# launch order does, only ONE job ever runs at a time, so the wall
# time must land near the SUM of every job's own duration — never near
# the LONGEST one, which is what a broken (or ignored) cap would give.
# Two packages (test-pa, test-pb, 1s each), idioms (its own two 1s
# checks, sequential inside ONE job — 2s) and fmt-lossless (1s):
# serial sum ~5s; run_checks_parallel already pins the cap=4 (~max)
# side of this contrast.
test_run_checks_slash_label() {
    d="$(git_repo checks-slash)"
    for p in pa pb; do
        mkdir -p "$d/packages/$p/src"
        printf '[package]\nname = "%s"\nversion = "0.1.0"\n' "$p" > "$d/packages/$p/avra.toml"
        printf 'export fn seed_%s() -> int { 0 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    mkdir -p "$d/build"
    printf '#!/bin/sh\necho "$1-ok"\n' > "$d/build/avra"
    chmod +x "$d/build/avra"
    printf 'fmt-lossless:\n\t@echo fmt-ok\n' > "$d/Makefile"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    for p in pa pb; do printf 'export fn seed_%s() -> int { 1 }\n' "$p" > "$d/packages/$p/src/lib.av"; done
    commit_all "$d" "touch"
    scr="$scratch/checks-slash-scratch"
    rm -rf "$scr" "$scratch/checks-slash-slots"
    ( AVRA_LAND_JOBS=1 AVRA_LAND_SCRATCH="$scr" AVRA_SLOTS_DIR="$scratch/checks-slash-slots" branch=x \
        exec sh "$land" --call run_checks "$d" "$base_sha" HEAD "-batch-fix/slashed" 0 ) > "$scratch/checks-slash.out" 2>&1 &
    pid=$!
    n=0
    while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 40 ]; do sleep 0.5; n=$((n + 1)); done
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        bad "run_checks: a job label holding '/' never freed its slot — the pool deadlocked"
        cat "$scratch/checks-slash.out"
    else
        ok "run_checks: a job label holding '/' frees its slot"
    fi
}

test_run_checks_jobs_cap() {
    d="$(git_repo checks-jobs-cap)"
    for p in pa pb; do
        mkdir -p "$d/packages/$p/src"
        printf '[package]\nname = "%s"\nversion = "0.1.0"\n' "$p" > "$d/packages/$p/avra.toml"
        printf 'export fn seed_%s() -> int { 0 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    mkdir -p "$d/build"
    cat > "$d/build/avra" <<'STUB'
#!/bin/sh
sleep 1
echo "$1-ok $(basename "$2")"
STUB
    chmod +x "$d/build/avra"
    printf 'fmt-lossless:\n\t@sleep 1 && echo fmt-ok\n' > "$d/Makefile"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    for p in pa pb; do printf 'export fn seed_%s() -> int { 1 }\n' "$p" > "$d/packages/$p/src/lib.av"; done
    commit_all "$d" "touch"

    scr="$scratch/checks-jobs-cap-scratch"
    slots="$scratch/checks-jobs-cap-slots"
    rm -rf "$scr" "$slots"
    t_start=$(date +%s)
    AVRA_LAND_JOBS=1 AVRA_LAND_SCRATCH="$scr" AVRA_SLOTS_DIR="$slots" branch=x \
        sh "$land" --call run_checks "$d" "$base_sha" HEAD "" 0 > "$scratch/checks-jobs-cap.out" 2>&1
    elapsed=$(($(date +%s) - t_start))
    # Serial sum is ~5s (1+1+2+1); a cap that let even 2 run together
    # would land near 3-4s (2s idioms overlapping a 1s test). >=4s is
    # the floor that tells the two apart with room for poll overhead.
    if [ "$elapsed" -ge 4 ]; then
        ok "run_checks: AVRA_LAND_JOBS=1 takes ~the serial sum ($elapsed s) — the cap is a real ceiling, not advisory"
    else
        bad "run_checks: AVRA_LAND_JOBS=1 took only ${elapsed}s — jobs ran concurrently despite a cap of 1"
        cat "$scratch/checks-jobs-cap.out"
    fi
}

# A JOB THAT DIES BEFORE IT CAN REPORT MUST STILL FAIL THE RUN. Killing
# its own wrapper (the pid job_launch records) before it writes its
# status file is the sharpest form of "the status is missing" — the
# wrapper's own exit is never observed except through `wait`, so this
# also pins that job_wait_all reads THAT, never the status file, as
# its verdict.
test_job_wait_fails_closed_on_killed_job() {
    d="$(git_repo job-kill)"
    for p in pa pb; do
        mkdir -p "$d/packages/$p/src"
        printf '[package]\nname = "%s"\nversion = "0.1.0"\n' "$p" > "$d/packages/$p/avra.toml"
        printf 'export fn seed_%s() -> int { 0 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    mkdir -p "$d/build"
    cat > "$d/build/avra" <<'STUB'
#!/bin/sh
pkg="$(basename "$2")"
if [ "$1" = "test" ] && [ "$pkg" = "${HANG_PKG:-}" ]; then
    sleep 2
    exit 0
fi
sleep 0.2
echo "$1-ok $pkg"
STUB
    chmod +x "$d/build/avra"
    printf 'fmt-lossless:\n\t@echo fmt-ok\n' > "$d/Makefile"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    for p in pa pb; do printf 'export fn seed_%s() -> int { 1 }\n' "$p" > "$d/packages/$p/src/lib.av"; done
    commit_all "$d" "touch"

    scr="$scratch/job-kill-scratch"
    slots="$scratch/job-kill-slots"
    rm -rf "$scr" "$slots"
    ( HANG_PKG=pb AVRA_LAND_JOBS=4 AVRA_LAND_SCRATCH="$scr" AVRA_SLOTS_DIR="$slots" branch=x \
        sh "$land" --call run_checks "$d" "$base_sha" HEAD "" 0 > "$scratch/job-kill.out" 2>&1 ) &
    rc_pid=$!

    target_pid=""
    i=0
    while [ "$i" -lt 100 ]; do
        target_pid="$(awk '$2=="test-pb"{print $1}' "$scr/jobs.list" 2>/dev/null | head -1)"
        [ -n "$target_pid" ] && break
        sleep 0.1
        i=$((i + 1))
    done
    if [ -z "$target_pid" ]; then
        bad "job-kill: never saw test-pb's own job registered"
    else
        kill -9 "$target_pid" 2>/dev/null
        ok "job-kill: killed test-pb's wrapper before it could write its own status file"
    fi

    rc_st=0
    wait "$rc_pid" || rc_st=$?
    if [ "$rc_st" -ne 0 ]; then
        ok "job-kill: run_checks still fails closed when a job dies unreported"
    else
        bad "job-kill: run_checks read a killed, unreported job as a pass"
        cat "$scratch/job-kill.out"
    fi
    if [ -f "$scr/jobs/test-pb.status" ]; then
        bad "job-kill: the killed job's status file should never have been written"
    else
        ok "job-kill: confirms the killed job never wrote a status file — a real 'missing status' case"
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
objects:
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
end = time.time() + 5
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
    export AVRA_LAND_LOCK="$scratch/auto-stop-lock" AVRA_LAND_BATCH_WT="$scratch/auto-stop-wt" AVRA_SLOTS_DIR="$scratch/auto-stop-slots" SLOW_BUILD=3 AVRA_LAND_ABSORB=1
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
    # A leftover directory, not a worktree, standing at the batch path.
    mkdir -p "$scratch/batch-stale-new/build"
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

# ══ COMPILER-UNTOUCHED: NO SECOND BUILD, NO SEED-CHECK ═══════════════
# `batch_repo`'s packages (a, b, c) live outside packages/std-avrac,
# packages/cli, packages/std-meta and runtime/, so landing one alone
# is a compiler-untouched batch by construction — no fixture-only flag
# needed to reach that path.
# One landing of `branch` in a copy of batch_repo, its stderr at $scratch/<tag>.out.
land_scoped() {
    d="$1"; branch="$2"; tag="$3"
    wt="$scratch/$tag-wt"
    git -C "$d" worktree add -q "$wt" "$branch" > /dev/null 2>&1
    mkdir -p "$wt/build"
    cp "$d/build/avra" "$wt/build/avra"
    rm -rf "$scratch/$tag-lock" "$scratch/$tag-slots"
    st=0
    ( cd "$wt" && AVRA_LAND_LOCK="$scratch/$tag-lock" AVRA_LAND_BATCH_WT="$scratch/$tag-batchwt" AVRA_SLOTS_DIR="$scratch/$tag-slots" AVRA_LAND_ABSORB=0 \
        exec sh "$land" "$branch" ) > "$scratch/$tag.out" 2>&1 || st=$?
    git -C "$d" worktree remove -f "$wt" > /dev/null 2>&1
    return "$st"
}

# Whether the landing's log holds a line, else a failure naming the case.
logged() {
    if grep -q "$2" "$scratch/$1.out"; then ok "$3"; else bad "$3"; cat "$scratch/$1.out"; fi
}
unlogged() {
    if grep -q "$2" "$scratch/$1.out"; then bad "$3"; cat "$scratch/$1.out"; else ok "$3"; fi
}

test_failed_run_restores_the_seed() {
    d="$(batch_repo seed-restore)"
    printf 'regenerated\n' > "$d/bootstrap/seed.ll"
    sh "$land" --call restore_generated "$d" > "$scratch/seed-restore.out" 2>&1
    if git -C "$d" diff --quiet -- bootstrap/seed.ll bootstrap/seed.sources; then
        ok "restore: a failed run's stranded seed is restored in the branch tree"
    else
        bad "restore: a failed run left its regenerated seed in the branch tree"
    fi
    if grep -q "restored the seed" "$scratch/seed-restore.out"; then ok "restore: says what it restored"; else bad "restore: restored silently"; fi
}

test_scratch_lifecycle() {
    d="$(batch_repo lifecycle)"
    git -C "$d" checkout -q -b dc main
    mkdir -p "$d/docs"
    printf 'words\n' > "$d/docs/note.md"
    commit_all "$d" "docs only"
    git -C "$d" checkout -q main
    root="$scratch/lifecycle-root"
    mkdir -p "$root/999991-1/trash/big" "$root/999991-1/logs" "$root/999992-1/trash" "$root/999992-1/logs"
    touch -t 202001010000 "$root/999992-1"
    wt="$scratch/lifecycle-wt"
    git -C "$d" worktree add -q "$wt" dc > /dev/null 2>&1
    mkdir -p "$wt/build" && cp "$d/build/avra" "$wt/build/avra"
    ( cd "$wt" && AVRA_LAND_SCRATCH_ROOT="$root" AVRA_LAND_LOCK="$scratch/lifecycle-lock" AVRA_LAND_BATCH_WT="$scratch/lifecycle-batchwt" \
        AVRA_SLOTS_DIR="$scratch/lifecycle-slots" exec sh "$land" dc ) > "$scratch/lifecycle.out" 2>&1 || bad "scratch: a docs-only landing failed"
    git -C "$d" worktree remove -f "$wt" > /dev/null 2>&1
    if [ -d "$root/999991-1/trash" ]; then bad "scratch: a dead run's trash survived the prune"; else ok "scratch: a dead run's trash is pruned at start"; fi
    if [ -d "$root/999991-1/logs" ]; then ok "scratch: a fresh dead run's logs stay for a day"; else bad "scratch: a fresh dead run's logs were pruned"; fi
    if [ -d "$root/999992-1" ]; then bad "scratch: a day-old dead run's scratch survived"; else ok "scratch: a day-old dead run's scratch is pruned"; fi
    left="$(find "$root" -mindepth 1 -maxdepth 1 -type d ! -name '99999*' | wc -l | tr -d ' ')"
    if [ "$left" -eq 0 ]; then ok "scratch: a green run leaves no scratch of its own"; else bad "scratch: a green run left $left scratch dir(s)"; ls "$root"; fi
}

test_diff_scope_skips() {
    d="$(batch_repo scope)"
    git -C "$d" checkout -q -b t main
    mkdir -p "$d/tools"
    printf 'echo land-test-ok\n' > "$d/tools/land_test.sh"
    commit_all "$d" "tools only"
    git -C "$d" checkout -q -b dc main
    mkdir -p "$d/docs"
    printf 'words\n' > "$d/docs/note.md"
    commit_all "$d" "docs only"
    git -C "$d" checkout -q -b cc main
    printf 'int x;\n' > "$d/packages/a/src/x.c"
    commit_all "$d" "c only"
    git -C "$d" checkout -q -b bk main
    mkdir -p "$d/backend"
    printf 'int y;\n' > "$d/backend/wrap.c"
    commit_all "$d" "backend only"
    git -C "$d" checkout -q main

    land_scoped "$d" bk scope-bk || bad "scope: a backend-only landing failed"
    logged scope-bk "compiler changed in this landing: 1" "scope: backend C reaches the compiler"
    unlogged scope-bk "skipped cache-attacks" "scope: a backend-only diff runs cache-attacks"

    land_scoped "$d" t scope-t || bad "scope: a tools-only landing failed"
    logged scope-t "skipped builds and package checks: diff touches no code outside tools/ or docs/" "scope: a tools-only diff skips builds and checks"
    logged scope-t "land-test OK" "scope: a tools-only diff runs land_test.sh"
    unlogged scope-t "build-1" "scope: a tools-only diff runs no build"

    land_scoped "$d" dc scope-dc || bad "scope: a docs-only landing failed"
    logged scope-dc "skipped land-test: diff touches no tools/" "scope: a docs-only diff runs not even land_test.sh"
    unlogged scope-dc "build-1" "scope: a docs-only diff runs no build"

    land_scoped "$d" cc scope-cc || bad "scope: a C-only landing failed"
    logged scope-cc "skipped idioms and fmt-lossless: diff touches no .av file" "scope: a diff with no .av file skips idioms and fmt-lossless"
    logged scope-cc "build-1" "scope: a diff with code still builds"

    land_scoped "$d" a scope-a || bad "scope: an .av landing failed"
    logged scope-a "idioms" "scope: an .av diff runs idioms"
    logged scope-a "skipped cache-attacks: diff touches no compiler source" "scope: a compiler-untouched diff skips cache-attacks"
}

test_compiler_untouched_skips_second_build_and_seedcheck() {
    d="$(batch_repo skip-seed)"
    wt_a="$scratch/skip-seed-a"
    git -C "$d" worktree add -q "$wt_a" a > /dev/null 2>&1
    # A fresh worktree has no build/ (gitignored, untracked) — a real
    # lane's worktree already carries one from earlier work; this
    # fixture's stub stands in for that.
    mkdir -p "$wt_a/build"
    cp "$d/build/avra" "$wt_a/build/avra"
    lockdir="$scratch/skip-seed-lock"
    slots="$scratch/skip-seed-slots"
    batchwt="$scratch/skip-seed-batchwt"
    rm -rf "$lockdir" "$slots"
    st=0
    ( cd "$wt_a" && AVRA_LAND_LOCK="$lockdir" AVRA_LAND_BATCH_WT="$batchwt" AVRA_SLOTS_DIR="$slots" AVRA_LAND_ABSORB=0 \
        exec sh "$land" a ) > "$scratch/skip-seed.out" 2>&1 || st=$?
    if [ "$st" -eq 0 ]; then
        ok "skip-seed: a compiler-untouched landing still lands"
    else
        bad "skip-seed: a compiler-untouched landing failed"
        cat "$scratch/skip-seed.out"
    fi
    if grep -q "skipped the second build and seed-check: diff touches no compiler source" "$scratch/skip-seed.out"; then
        ok "skip-seed: announces skipping the second build and seed-check"
    else
        bad "skip-seed: did not announce skipping"
        cat "$scratch/skip-seed.out"
    fi
    if grep -q "build-2" "$scratch/skip-seed.out"; then
        bad "skip-seed: a second build ran despite the compiler being untouched"
    else
        ok "skip-seed: no second build ran"
    fi
    if grep -q "land: seed-check" "$scratch/skip-seed.out"; then
        bad "skip-seed: seed-check ran despite the compiler being untouched"
    else
        ok "skip-seed: seed-check did not run"
    fi
    git -C "$d" worktree remove -f "$wt_a" > /dev/null 2>&1
}

# ══ THE TIMELINE: A LINE PER STEP, A TOTAL AT THE END ═════════════════
test_timeline_lines_present() {
    d="$(batch_repo timeline)"
    wt_a="$scratch/timeline-a"
    git -C "$d" worktree add -q "$wt_a" a > /dev/null 2>&1
    mkdir -p "$wt_a/build"
    cp "$d/build/avra" "$wt_a/build/avra"
    lockdir="$scratch/timeline-lock"
    slots="$scratch/timeline-slots"
    batchwt="$scratch/timeline-batchwt"
    rm -rf "$lockdir" "$slots"
    ( cd "$wt_a" && AVRA_LAND_LOCK="$lockdir" AVRA_LAND_BATCH_WT="$batchwt" AVRA_SLOTS_DIR="$slots" AVRA_LAND_ABSORB=0 \
        exec sh "$land" a ) > "$scratch/timeline.out" 2>&1
    if grep -q "^land: timeline: build-1-objects start=+[0-9]*s dur=[0-9]*s exit=[0-9]*$" "$scratch/timeline.out"; then
        ok "timeline: a per-step timeline line is printed (build-1-objects)"
    else
        bad "timeline: no per-step timeline line seen"
        cat "$scratch/timeline.out"
    fi
    if grep -qE "^land: timeline: total wall=[0-9]+s$" "$scratch/timeline.out"; then
        ok "timeline: a total wall-time line closes the run"
    else
        bad "timeline: no total wall-time line seen"
        cat "$scratch/timeline.out"
    fi
    git -C "$d" worktree remove -f "$wt_a" > /dev/null 2>&1
}

# ══ THE RATCHET BASELINE — improve, regress, override, missing ══════
test_ratchet_improve() {
    f="$scratch/ratchet-improve.baseline"
    rm -f "$f"
    printf 'some_metric=10\n' > "$f"
    out="$(branch=x sh "$land" --call ratchet_check "$f" some_metric 15 up 2>&1)"
    st=$?
    if [ "$st" -eq 0 ] && printf '%s' "$out" | grep -q '^PASS 15'; then
        ok "ratchet: an improving value passes"
    else
        bad "ratchet: an improving value should pass — got ($st): $out"
    fi
    got="$(sh "$land" --call baseline_get "$f" some_metric)"
    if [ "$got" = "15" ]; then
        ok "ratchet: the improved value is recorded"
    else
        bad "ratchet: the baseline was not updated to 15 — got $got"
    fi
}

test_ratchet_missing_baseline() {
    f="$scratch/ratchet-missing.baseline"
    rm -f "$f"
    out="$(branch=x sh "$land" --call ratchet_check "$f" new_metric 42 up 2>&1)"
    st=$?
    if [ "$st" -eq 0 ] && printf '%s' "$out" | grep -q 'no prior baseline'; then
        ok "ratchet: a missing baseline records the first number and passes"
    else
        bad "ratchet: a missing baseline should record+pass — got ($st): $out"
    fi
    got="$(sh "$land" --call baseline_get "$f" new_metric)"
    if [ "$got" = "42" ]; then
        ok "ratchet: the first-ever value for a key is recorded"
    else
        bad "ratchet: the first value was not recorded — got $got"
    fi
}

test_ratchet_regress_no_override() {
    f="$scratch/ratchet-regress.baseline"
    rm -f "$f"
    printf 'some_metric=20\n' > "$f"
    out="$(branch=x sh "$land" --call ratchet_check "$f" some_metric 10 up 2>&1)"
    st=$?
    if [ "$st" -ne 0 ] && printf '%s' "$out" | grep -q '^FAIL 10'; then
        ok "ratchet: a regression with no override fails, named"
    else
        bad "ratchet: expected a named FAIL — got ($st): $out"
    fi
    got="$(sh "$land" --call baseline_get "$f" some_metric)"
    if [ "$got" = "20" ]; then
        ok "ratchet: the baseline is untouched by a failed regression"
    else
        bad "ratchet: the baseline moved despite a failed regression — got $got"
    fi
}

test_ratchet_regress_with_override() {
    f="$scratch/ratchet-override.baseline"
    rm -f "$f"
    printf 'some_metric=20\n' > "$f"
    scr="$scratch/ratchet-override-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" branch=x sh "$land" --call ratchet_check "$f" some_metric 10 up "known slowdown, tracked in avra-8sb5.99" 2>&1)"
    st=$?
    if [ "$st" -eq 0 ] && printf '%s' "$out" | grep -q '^PASS 10.*override'; then
        ok "ratchet: a signed regression passes, named as an override"
    else
        bad "ratchet: expected a signed PASS — got ($st): $out"
    fi
    got="$(sh "$land" --call baseline_get "$f" some_metric)"
    if [ "$got" = "10" ]; then
        ok "ratchet: a signed regression's value IS recorded"
    else
        bad "ratchet: a signed regression's value was not recorded — got $got"
    fi
    if grep -q "some_metric: known slowdown, tracked in avra-8sb5.99" "$scr/ratchet-overrides" 2>/dev/null; then
        ok "ratchet: the override reason is queued for the chore commit"
    else
        bad "ratchet: the override reason was not queued"
    fi
}

test_chore_commit_carries_override_reason() {
    d="$(git_repo chore-commit)"
    mkdir -p "$d/tools"
    printf 'warm_held_floor=10\n' > "$d/tools/land.baseline"
    commit_all "$d" "base"
    scr="$scratch/chore-commit-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    printf 'warm_held_floor: known regression, tracked in avra-8sb5.99\n' > "$scr/ratchet-overrides"
    printf 'warm_held_floor=8\n' > "$d/tools/land.baseline"
    if AVRA_LAND_SCRATCH="$scr" branch=x sh "$land" --call commit_chore_if_moved "$d" "my-branch" > "$scratch/chore-commit.out" 2>&1; then
        ok "chore-commit: a moved baseline with a queued override commits"
    else
        bad "chore-commit: committing a moved baseline failed"
        cat "$scratch/chore-commit.out"
    fi
    msg="$(git -C "$d" log -1 --format=%B)"
    if printf '%s' "$msg" | grep -q "known regression, tracked in avra-8sb5.99"; then
        ok "chore-commit: the commit message carries the override reason"
    else
        bad "chore-commit: the commit message did not carry the override reason: $msg"
    fi
    if printf '%s' "$msg" | grep -q "ratchet baseline moved"; then
        ok "chore-commit: a baseline-only move gets its own subject (no seed change)"
    else
        bad "chore-commit: wrong subject for a baseline-only move: $msg"
    fi
}

# ══ THE WARM-REUSE GATE ═══════════════════════════════════════════════
# `warm_gate_step` reads its own hard-coded leaf file
# (compiler/format/receipt.av) — a fixture repo carries a stand-in at
# that same path with the exact literal the real sed edit targets, so
# the scripted edit really moves the file's text.
warm_gate_edit_rel="packages/std-avrac/src/compiler/format/receipt.av"

# `$2` is a file this stub's `check --time` answer reads its `held
# N/M` words from, so one fixture repo serves every warm-gate case.
warm_gate_repo() {
    d="$(git_repo "$1")"
    mkdir -p "$(dirname "$d/$warm_gate_edit_rel")"
    printf 'fn token_mismatch() -> string? {\n    return "a token moved at position 0"\n}\n' > "$d/$warm_gate_edit_rel"
    mkdir -p "$d/build" "$d/tools"
    heldfile="$2"
    cat > "$d/build/avra" <<STUB
#!/bin/sh
if [ "\$1" = "check" ]; then
    echo "time: parse 1ms, \$(cat "$heldfile"), attempt 1"
    exit 0
fi
exit 0
STUB
    chmod +x "$d/build/avra"
    commit_all "$d" "base"
    echo "$d"
}

test_gates_never_touch_the_landing_cache() {
    d="$(speed_repo gate-cache cold)"
    printf 'objects:\n\t@mkdir -p build && touch build/libavra_runtime.a\nlibs:\n\t@echo libs-ok\n' > "$d/Makefile"
    printf '.avra-cache/\nbuild/\n' > "$d/.gitignore"
    mkdir -p "$d/tools" && : > "$d/tools/speed.baseline"
    commit_all "$d" "make targets"
    mkdir -p "$d/.avra-cache/objects"
    echo live > "$d/.avra-cache/objects/sibling-write"
    out="$(AVRA_LAND_SPEED_WT="$scratch/gate-cache-speed-wt" branch=x sh "$land" --call speed_refresh "$d" 2>&1)"
    if [ -f "$d/.avra-cache/objects/sibling-write" ]; then
        ok "side tree: the speed refresh leaves the landing tree's cache where a sibling job writes"
    else
        bad "side tree: the speed refresh moved the landing tree's cache out from under a sibling — $out"
    fi
    if git -C "$d" diff --quiet -- tools/speed.baseline; then
        ok "staged: the refresh leaves the landing tree's baseline untouched until every check is green"
    else
        bad "staged: the refresh wrote the landing tree's baseline mid-run"
    fi
    if printf '%s' "$out" | grep -q "baseline advanced"; then
        ok "side tree: the refresh ran and measured"
    else
        bad "side tree: the refresh never measured — $out"
    fi
    if [ -f "$scratch/gate-cache-speed-wt/.git" ] || [ -d "$scratch/gate-cache-speed-wt/.git" ]; then
        ok "side tree: the refresh measured in a tree of its own"
    else
        bad "side tree: no side tree was made for the refresh — $out"
    fi
}

test_warm_gate_off() {
    d="$(git_repo warm-off)"
    mkdir -p "$d/build"
    printf '#!/bin/sh\nexit 0\n' > "$d/build/avra"
    chmod +x "$d/build/avra"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    scr="$scratch/warm-off-scratch"
    slots="$scratch/warm-off-slots"
    rm -rf "$scr" "$slots"
    AVRA_LAND_JOBS=2 AVRA_LAND_SCRATCH="$scr" AVRA_SLOTS_DIR="$slots" branch=x \
        sh "$land" --call run_checks "$d" "$base_sha" HEAD "" 0 0 \
        > "$scratch/warm-off.out" 2>&1
    logged warm-off "skipped warm-reuse gate: AVRA_LAND_WARM_GATE is off" "warm-gate: off by default — skipped, and says so"
}

test_warm_gate_prints_held_pass() {
    heldfile="$scratch/warm-held-pass-value"
    echo "held 41/42" > "$heldfile"
    d="$(warm_gate_repo warm-held-pass "$heldfile")"
    printf 'warm_held_floor=5\n' > "$d/tools/land.baseline"
    scr="$scratch/warm-held-pass-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" branch=x sh "$land" --call warm_gate_step "$d" 2>&1)"
    st=$?
    if [ "$st" -eq 0 ] && printf '%s' "$out" | grep -qE 'land: warm-reuse: held 41/42 \(floor 5\) — PASS'; then
        ok "warm-gate: prints held N/M, the floor, and PASS"
    else
        bad "warm-gate: expected the held/floor/PASS line — got ($st): $out"
    fi
    if git -C "$d" diff --quiet -- "$warm_gate_edit_rel"; then
        ok "warm-gate: the scripted body edit is restored after the run"
    else
        bad "warm-gate: the scripted edit was left in the tree"
    fi
}

test_warm_gate_fails_below_floor() {
    heldfile="$scratch/warm-held-fail-value"
    echo "held 41/42" > "$heldfile"
    d="$(warm_gate_repo warm-held-fail "$heldfile")"
    printf 'warm_held_floor=100\n' > "$d/tools/land.baseline"
    scr="$scratch/warm-held-fail-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" branch=x sh "$land" --call warm_gate_step "$d" 2>&1)"
    st=$?
    if [ "$st" -ne 0 ] && printf '%s' "$out" | grep -q '— FAIL'; then
        ok "warm-gate: held below the floor fails, with no override"
    else
        bad "warm-gate: expected a FAIL below the floor — got ($st): $out"
    fi
}

test_warm_gate_override_passes() {
    heldfile="$scratch/warm-held-override-value"
    echo "held 41/42" > "$heldfile"
    d="$(warm_gate_repo warm-held-override "$heldfile")"
    printf 'warm_held_floor=100\n' > "$d/tools/land.baseline"
    scr="$scratch/warm-held-override-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" AVRA_LAND_WARM_OK="known, tracked" branch=x sh "$land" --call warm_gate_step "$d" 2>&1)"
    st=$?
    if [ "$st" -eq 0 ] && printf '%s' "$out" | grep -q '— PASS'; then
        ok "warm-gate: a signed regression below the floor passes"
    else
        bad "warm-gate: expected a signed PASS — got ($st): $out"
    fi
}

# ══ THE LINUX GATE — a stubbed sprite-build.sh: pass, fail, unreachable ══
# The trailing "sprite-build: … -> exit N" line is the tell a REAL
# remote command reached and answered (guarded by `|| status=$?` in
# tools/sprite-build.sh); its absence is what a connectivity failure
# under `set -eu` looks like — never printed.
sprite_stub_write() {
    path="$1"
    mode="$2"
    case "$mode" in
        unreachable)
            cat > "$path" <<'STUB'
#!/bin/sh
echo "sprite-build: could not reach the sprite (connection refused)" >&2
exit 1
STUB
            ;;
        fail)
            cat > "$path" <<'STUB'
#!/bin/sh
echo "sprite-build: pa-slug@stub-hash on stub -> exit 1" >&2
exit 1
STUB
            ;;
        *)
            cat > "$path" <<'STUB'
#!/bin/sh
echo "sprite-build: pa-slug@stub-hash on stub -> exit 0" >&2
exit 0
STUB
            ;;
    esac
    chmod +x "$path"
}

test_linux_gate_runs_cold() {
    d="$(git_repo linux-cold)"
    mkdir -p "$d/packages/pa/src"
    commit_all "$d" "base"
    stub="$scratch/linux-cold-sprite.sh"
    body_file="$scratch/linux-cold-body"
    printf '#!/bin/sh\nfor a in "$@"; do last="$a"; done\nprintf "%%s" "$last" > "%s"\necho "sprite-build: stub -> exit 0" >&2\n' "$body_file" > "$stub"
    chmod +x "$stub"
    AVRA_LAND_SPRITE_BUILD="$stub" branch=x sh "$land" --call linux_gate_step "$d" pa > /dev/null 2>&1
    body="$(cat "$body_file" 2>/dev/null)"
    clear_at="$(printf '%s' "$body" | awk '{print index($0, "-name .avra-cache")}')"
    test_at="$(printf '%s' "$body" | awk '{print index($0, "build/avra test")}')"
    if [ "${clear_at:-0}" -gt 0 ] && [ "${test_at:-0}" -gt "$clear_at" ]; then
        ok "linux-gate: the Sprite tree's .avra-cache is cleared before any suite runs"
    else
        bad "linux-gate: the Sprite command runs a suite over a warm cache — body: $body"
    fi
}

test_linux_gate_starts_before_the_builds() {
    d="$(batch_repo linux-early)"
    stub="$scratch/linux-early-sprite.sh"
    mark="$scratch/linux-early-mark"
    printf '#!/bin/sh\ndate +%%s%%N > "%s"\necho "sprite-build: stub -> exit 0" >&2\n' "$mark" > "$stub"
    chmod +x "$stub"
    wt="$scratch/linux-early-wt"
    git -C "$d" worktree add -q "$wt" a > /dev/null 2>&1
    mkdir -p "$wt/build" && cp "$d/build/avra" "$wt/build/avra"
    ( cd "$wt" && AVRA_LAND_LINUX=1 AVRA_LAND_SPRITE_BUILD="$stub" AVRA_LAND_JOBS=1 SLOW_BUILD=2 \
        AVRA_LAND_LOCK="$scratch/linux-early-lock" AVRA_LAND_BATCH_WT="$scratch/linux-early-batchwt" \
        AVRA_SLOTS_DIR="$scratch/linux-early-slots" exec sh "$land" a ) > "$scratch/linux-early.out" 2>&1 || bad "linux-early: the landing failed"
    git -C "$d" worktree remove -f "$wt" > /dev/null 2>&1
    linux_ok="$(grep -n 'linux OK' "$scratch/linux-early.out" | head -1 | cut -d: -f1)"
    b1_done="$(grep -n 'build-1-compile OK' "$scratch/linux-early.out" | head -1 | cut -d: -f1)"
    if [ -n "$linux_ok" ] && [ -n "$b1_done" ] && [ "$linux_ok" -lt "$b1_done" ]; then
        ok "linux-early: the Sprite run finishes while the first local build is still going"
    else
        bad "linux-early: the Linux gate waited for the local builds (linux OK at line ${linux_ok:-none}, build-1 done at ${b1_done:-none})"
        cat "$scratch/linux-early.out"
    fi
}

test_linux_gate_failure_refuses_the_landing() {
    d="$(batch_repo linux-red)"
    stub="$scratch/linux-red-sprite.sh"
    printf '#!/bin/sh\necho "sprite-build: stub -> exit 1" >&2\nexit 1\n' > "$stub"
    chmod +x "$stub"
    wt="$scratch/linux-red-wt"
    git -C "$d" worktree add -q "$wt" a > /dev/null 2>&1
    mkdir -p "$wt/build" && cp "$d/build/avra" "$wt/build/avra"
    st=0
    ( cd "$wt" && AVRA_LAND_LINUX=1 AVRA_LAND_SPRITE_BUILD="$stub" \
        AVRA_LAND_LOCK="$scratch/linux-red-lock" AVRA_LAND_BATCH_WT="$scratch/linux-red-batchwt" \
        AVRA_SLOTS_DIR="$scratch/linux-red-slots" exec sh "$land" a ) > "$scratch/linux-red.out" 2>&1 || st=$?
    git -C "$d" worktree remove -f "$wt" > /dev/null 2>&1
    if [ "$st" -ne 0 ] && grep -q "FAILED at 'linux" "$scratch/linux-red.out" && ! grep -q "^LANDED" "$scratch/linux-red.out"; then
        ok "linux-early: a red Sprite run refuses the landing, named"
    else
        bad "linux-early: a red Sprite run did not refuse the landing ($st)"
        cat "$scratch/linux-red.out"
    fi
}

test_linux_gate_pass() {
    d="$(git_repo linux-pass)"
    mkdir -p "$d/packages/pa/src"
    commit_all "$d" "base"
    stub="$scratch/linux-pass-sprite.sh"
    sprite_stub_write "$stub" pass
    out="$(AVRA_LAND_SPRITE_BUILD="$stub" branch=x sh "$land" --call linux_gate_step "$d" pa 2>&1)"
    st=$?
    if [ "$st" -eq 0 ]; then
        ok "linux-gate: a passing Sprite run succeeds"
    else
        bad "linux-gate: expected success — got ($st): $out"
    fi
}

test_linux_gate_fail() {
    d="$(git_repo linux-fail)"
    mkdir -p "$d/packages/pa/src"
    commit_all "$d" "base"
    stub="$scratch/linux-fail-sprite.sh"
    sprite_stub_write "$stub" fail
    scr="$scratch/linux-fail-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" AVRA_LAND_SPRITE_BUILD="$stub" branch=x sh "$land" --call linux_gate_step "$d" pa 2>&1)"
    st=$?
    if [ "$st" -ne 0 ] && ! printf '%s' "$out" | grep -q "TOOL FAILURE" && [ ! -f "$scr/tool-failure" ]; then
        ok "linux-gate: a real suite failure refuses the landing, and is never blamed as a tool failure"
    else
        bad "linux-gate: expected a non-tool failure — got ($st): $out"
    fi
}

test_linux_gate_unreachable() {
    d="$(git_repo linux-unreachable)"
    mkdir -p "$d/packages/pa/src"
    commit_all "$d" "base"
    stub="$scratch/linux-unreachable-sprite.sh"
    sprite_stub_write "$stub" unreachable
    scr="$scratch/linux-unreachable-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" AVRA_LAND_SPRITE_BUILD="$stub" branch=x sh "$land" --call linux_gate_step "$d" pa 2>&1)"
    st=$?
    if [ "$st" -ne 0 ] && printf '%s' "$out" | grep -q "TOOL FAILURE" && [ -f "$scr/tool-failure" ]; then
        ok "linux-gate: an unreachable Sprite is a TOOL failure, no branch blamed"
    else
        bad "linux-gate: expected a TOOL FAILURE — got ($st): $out"
    fi
}

# ══ THE SPEED GATE ═════════════════════════════════════════════════
# `speed_gate` alone (never `speed_gate_step`, which also wires a real
# git-worktree base tree) is the unit under test: `$1` doubles as both
# the tree and the product's own source, needing no worktree at all.
speed_repo() {
    d="$(git_repo "$1")"
    mode="$2"   # cold | warm
    mkdir -p "$d/build" "$d/packages/cli/src"
    held_line="held 0/5"
    [ "$mode" = "warm" ] && held_line="held 5/5"
    hit_line=""
    [ "$mode" = "objhit" ] && hit_line='echo "time: lower+emit · cache hit"'
    cat > "$d/build/avra" <<STUB
#!/bin/sh
if [ "\$1" = "build" ]; then
    echo "time: parse 1ms, $held_line, attempt 1"
    $hit_line
    exit 0
fi
exit 0
STUB
    chmod +x "$d/build/avra"
    commit_all "$d" "base"
    echo "$d"
}

test_speed_gate_improve() {
    d="$(speed_repo speed-improve cold)"
    mkdir -p "$d/tools"
    printf 'sha0 999999999 999999999 -\n' > "$d/tools/speed.baseline"
    out="$(branch=x sh "$land" --call speed_gate "$d" "$d/build/avra" "$d" test-label 2>&1)"
    st=$?
    if [ "$st" -eq 0 ] && printf '%s' "$out" | grep -q '— PASS'; then
        ok "speed-gate: an improving measurement passes"
    else
        bad "speed-gate: expected PASS — got ($st): $out"
    fi
}

test_speed_gate_regress_no_override() {
    d="$(speed_repo speed-regress cold)"
    mkdir -p "$d/tools"
    printf 'sha0 1 1 -\n' > "$d/tools/speed.baseline"
    out="$(branch=x sh "$land" --call speed_gate "$d" "$d/build/avra" "$d" test-label 2>&1)"
    st=$?
    if [ "$st" -ne 0 ] && printf '%s' "$out" | grep -q 'land: speed:.*— FAIL'; then
        ok "speed-gate: a regression past threshold with no override fails, named"
    else
        bad "speed-gate: expected a named FAIL — got ($st): $out"
    fi
}

test_speed_gate_regress_with_override() {
    d="$(speed_repo speed-override cold)"
    mkdir -p "$d/tools"
    printf 'sha0 1 1 -\n' > "$d/tools/speed.baseline"
    scr="$scratch/speed-override-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" AVRA_LAND_SPEED_OK="known, tracked in avra-9.1" branch=x sh "$land" --call speed_gate "$d" "$d/build/avra" "$d" test-label 2>&1)"
    st=$?
    if [ "$st" -eq 0 ] && printf '%s' "$out" | grep -q '— PASS'; then
        ok "speed-gate: a signed regression passes"
    else
        bad "speed-gate: expected a signed PASS — got ($st): $out"
    fi
    if grep -q "speed: known, tracked in avra-9.1" "$scr/ratchet-overrides" 2>/dev/null; then
        ok "speed-gate: the override reason is queued for the chore commit"
    else
        bad "speed-gate: the override reason was not queued"
    fi
}

test_speed_gate_links_the_candidates_runtime() {
    d="$(git_repo speed-pair)"
    record="$scratch/speed-pair-record"
    : > "$record"
    mkdir -p "$d/build" "$d/packages/cli/src" "$d/runtime" "$d/tools"
    printf 'int r;\n' > "$d/runtime/r.c"
    : > "$d/tools/speed.baseline"
    printf 'objects:\n\t@mkdir -p build && echo BASE > build/libavra_runtime.a && echo BASEO > build/r.o\nlibs:\n\t@echo libs-ok\n' > "$d/Makefile"
    printf '.avra-cache/\nbuild/\n' > "$d/.gitignore"
    cat > "$d/build/avra" <<STUB
#!/bin/sh
if [ "\$1" = "build" ]; then
    cat build/libavra_runtime.a build/r.o >> "$record"
    echo "time: parse 1ms, held 0/1, attempt 1"
fi
exit 0
STUB
    chmod +x "$d/build/avra"
    commit_all "$d" "base"
    echo CAND > "$d/build/libavra_runtime.a"
    echo CANDO > "$d/build/r.o"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    AVRA_LAND_SPEED_WT="$scratch/speed-pair-wt" branch=x sh "$land" --call speed_gate_step "$d" "$base_sha" > "$scratch/speed-pair.out" 2>&1
    if [ "$(head -2 "$record" | tr '\n' ' ')" = "CAND CANDO " ]; then
        ok "speed-gate: the candidate's product links the candidate's runtime and runtime objects"
    else
        bad "speed-gate: the candidate linked another tree's runtime — saw: $(tr '\n' ' ' < "$record")"
        cat "$scratch/speed-pair.out"
    fi
}

test_speed_gate_object_hit_tool_failure() {
    d="$(speed_repo speed-objhit objhit)"
    mkdir -p "$d/tools"
    scr="$scratch/speed-objhit-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    AVRA_LAND_SCRATCH="$scr" branch=x sh "$land" --call speed_gate "$d" "$d/build/avra" "$d" test-label > "$scratch/speed-objhit.out" 2>&1
    if [ -f "$scr/tool-failure" ] && grep -q "was not cold" "$scr/tool-failure"; then
        ok "speed-gate: a cached object under 'held 0/' is still not cold — a TOOL failure"
    else
        bad "speed-gate: a run reusing cached objects was measured as cold"
        cat "$scratch/speed-objhit.out"
    fi
}

test_speed_gate_held_assertion_tool_failure() {
    d="$(speed_repo speed-warm warm)"
    mkdir -p "$d/tools"
    scr="$scratch/speed-warm-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" branch=x sh "$land" --call speed_gate "$d" "$d/build/avra" "$d" test-label 2>&1)"
    st=$?
    if [ "$st" -ne 0 ] && [ -f "$scr/tool-failure" ] && grep -q "was not cold" "$scr/tool-failure"; then
        ok "speed-gate: a warm hit (no 'held 0/') is a TOOL failure, not a measurement"
    else
        bad "speed-gate: expected a TOOL failure — got ($st): $out"
    fi
}

test_speed_gate_median_of_three() {
    d="$(speed_repo speed-median cold)"
    mkdir -p "$d/tools"
    printf 'sha0 1 1 -\n' > "$d/tools/speed.baseline"
    scr="$scratch/speed-median-scratch"
    rm -rf "$scr"
    mkdir -p "$scr"
    out="$(AVRA_LAND_SCRATCH="$scr" AVRA_LAND_SPEED_OK=known branch=x sh "$land" --call speed_gate "$d" "$d/build/avra" "$d" test-label 2>&1)"
    if printf '%s' "$out" | grep -q "remeasuring twice more" && printf '%s' "$out" | grep -q "median of 3 runs"; then
        ok "speed-gate: crossing a threshold on the first run triggers a median-of-3 remeasurement"
    else
        bad "speed-gate: expected a median-of-3 path — got: $out"
    fi
}

# ══ THE JOB POOL LAUNCHES ITS LONGEST STEPS FIRST ═════════════════════
# jobs.list records CALL order (job_launch appends before backgrounding),
# independent of AVRA_LAND_JOBS or actual completion timing — a
# generous cap here just keeps the fixture itself fast.
gates_order_repo() {
    d="$(git_repo "$1")"
    for p in std-avrac cli pa; do
        mkdir -p "$d/packages/$p/src"
        printf '[package]\nname = "%s"\nversion = "0.1.0"\n' "$p" > "$d/packages/$p/avra.toml"
        printf 'export fn seed_%s() -> int { 0 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    mkdir -p "$d/build" "$d/bootstrap"
    cat > "$d/build/avra" <<'STUB'
#!/bin/sh
case "$1" in
    build)
        mkdir -p packages/cli/src
        cp "$0" packages/cli/src/main
        chmod +x packages/cli/src/main
        echo "time: parse 1ms, held 0/1, attempt 1"
        exit 0
        ;;
    test)
        sleep 0.1
        echo "tested $(basename "$2")"
        exit 0
        ;;
    check) exit 0 ;;
esac
STUB
    chmod +x "$d/build/avra"
    cat > "$d/Makefile" <<'MK'
objects:
	@mkdir -p build && touch build/libavra_runtime.a
libs:
	@echo libs-ok
seed-check:
	@test -f bootstrap/seed.ll && echo seed-check-ok
fmt-lossless:
	@echo fmt-ok
MK
    printf 'seed-src\n' > "$d/bootstrap/seed.ll"
    printf 'seed-src\n' > "$d/bootstrap/seed.sources"
    printf 'build/\n' > "$d/.gitignore"
    commit_all "$d" "base"
    base_sha="$(git -C "$d" rev-parse HEAD)"
    for p in std-avrac cli pa; do printf 'export fn seed_%s() -> int { 1 }\n' "$p" > "$d/packages/$p/src/lib.av"; done
    commit_all "$d" "touch all three"
    echo "$d $base_sha"
}

test_run_checks_launch_order() {
    read -r d base_sha <<EOF
$(gates_order_repo checks-order)
EOF
    scr="$scratch/checks-order-scratch"
    slots="$scratch/checks-order-slots"
    sprite_stub="$scratch/checks-order-sprite.sh"
    sprite_stub_write "$sprite_stub" pass
    rm -rf "$scr" "$slots"

    AVRA_LAND_JOBS=8 AVRA_LAND_SCRATCH="$scr" AVRA_SLOTS_DIR="$slots" \
        AVRA_LAND_LINUX=1 AVRA_LAND_SPRITE_BUILD="$sprite_stub" \
        AVRA_LAND_SPEED_GATE=1 AVRA_LAND_SPEED_WT="$scratch/checks-order-speed-wt" \
        branch=x sh "$land" --call run_checks "$d" "$base_sha" HEAD "" 1 1 \
        > "$scratch/checks-order.out" 2>&1

    got="$(awk '{print $2}' "$scr/jobs.list" 2>/dev/null | tr '\n' ' ')"
    want_prefix="test-std-avrac idioms seed-check speed test-cli"
    case "$got" in
        "$want_prefix"*)
            ok "launch-order: std-avrac, idioms, seed-check, speed, cli launch first, in that order"
            ;;
        *)
            bad "launch-order: wanted prefix [$want_prefix], got [$got]"
            cat "$scratch/checks-order.out"
            ;;
    esac
    rest="$(printf '%s' "$got" | sed "s/^$want_prefix //")"
    rest_sorted="$(printf '%s' "$rest" | tr ' ' '\n' | sort | tr '\n' ' ')"
    if [ "$rest_sorted" = "fmt-lossless test-pa " ]; then
        ok "launch-order: the rest (fmt-lossless, test-pa) launch last, in any order"
    else
        bad "launch-order: wanted the rest to be [fmt-lossless test-pa], got [$rest_sorted]"
    fi
}

# ══ A CHANGED GATE SCRIPT RUNS ITS OWN GATE, TOOLS-ONLY ══════════════
test_tools_only_gate_script_runs_its_step() {
    d="$(batch_repo gate-script-one)"
    git -C "$d" checkout -q -b cachefix main
    mkdir -p "$d/tools"
    printf 'echo land-test-ok\n' > "$d/tools/land_test.sh"
    printf '#!/bin/sh\necho cache-attacks-changed\n' > "$d/tools/cache_attacks.sh"
    commit_all "$d" "cache_attacks.sh changes"
    git -C "$d" checkout -q main

    land_scoped "$d" cachefix gate-script-cache || bad "gate-script: a tools-only landing touching a gate script failed"
    logged gate-script-cache "a changed tools/ script is itself a gate (cache-attacks)" "gate-script: names cache-attacks as the mapped step"
    logged gate-script-cache "build-1-objects" "gate-script: a mapped gate step still builds gen 1"
    unlogged gate-script-cache "build-2-objects" "gate-script: never a second build — the compiler itself did not change"
    logged gate-script-cache "land: cache-attacks" "gate-script: the cache-attacks step itself runs"
    logged gate-script-cache "land-test OK" "gate-script: land_test.sh still runs too (any tools/ touch does)"
}

# Three mapped scripts touched TOGETHER: every one of their three
# steps runs, none twice, and the unmapped land_test.sh dependency
# (affected_packages.sh, already covered by the blanket tools/ rule)
# needs no extra step of its own.
test_tools_only_several_gate_scripts_run_all_steps() {
    d="$(batch_repo gate-script-many)"
    git -C "$d" checkout -q -b threefix main
    mkdir -p "$d/tools"
    printf 'echo land-test-ok\n' > "$d/tools/land_test.sh"
    printf '# a baseline entry\n' >> "$d/tools/idioms.baseline"
    printf '#!/bin/sh\necho fmt-lossless-changed\n' > "$d/tools/fmt_lossless.sh"
    printf '#!/bin/sh\necho seed-guard-changed\n' > "$d/tools/seed_guard.sh"
    commit_all "$d" "idioms.baseline, fmt_lossless.sh, seed_guard.sh all change"
    git -C "$d" checkout -q main

    land_scoped "$d" threefix gate-script-many || bad "gate-script: a landing touching three mapped scripts failed"
    logged gate-script-many "is itself a gate (idioms fmt-lossless seed-check)" "gate-script: names all three mapped steps, in the fixed order"
    logged gate-script-many "land: idioms" "gate-script: the idioms step runs"
    logged gate-script-many "land: fmt-lossless" "gate-script: the fmt-lossless step runs"
    logged gate-script-many "land: seed-check" "gate-script: the seed-check step runs"
    st="$(grep -c '^land: idioms …$' "$scratch/gate-script-many.out" 2>/dev/null)"
    if [ "${st:-0}" -eq 1 ]; then
        ok "gate-script: idioms runs exactly once, not once per matching file"
    else
        bad "gate-script: idioms ran $st times, wanted 1"
    fi
}

echo "=== land tooling fixtures (parallel, ${AVRA_LAND_TEST_JOBS:-8} at a time) ==="
run_test test_lock_fifo
run_test test_merge_seed_conflict
run_test test_merge_real_conflict
run_test test_affected_packages
run_test test_run_checks_parallel
run_test test_run_checks_one_fails
run_test test_run_checks_two_fail
run_test test_run_checks_jobs_cap
run_test test_run_checks_slash_label
run_test test_job_wait_fails_closed_on_killed_job
run_test test_compiler_untouched_skips_second_build_and_seedcheck
run_test test_failed_run_restores_the_seed
run_test test_scratch_lifecycle
run_test test_diff_scope_skips
run_test test_timeline_lines_present
run_test test_slot_limit
run_test test_slot_stale_reclaim
run_test test_caches_aside_twice
run_test test_commit_seed_if_moved
run_test test_try_ff
run_test test_batch_mode
run_test test_batch_tool_failure
run_test test_batch_stale_registration
run_test test_heavy_status
run_test test_auto_batch
run_test test_auto_batch_holder_stopped
run_test test_ff_refused_not_moved
run_test test_ratchet_improve
run_test test_ratchet_missing_baseline
run_test test_ratchet_regress_no_override
run_test test_ratchet_regress_with_override
run_test test_chore_commit_carries_override_reason
run_test test_gates_never_touch_the_landing_cache
run_test test_warm_gate_off
run_test test_warm_gate_prints_held_pass
run_test test_warm_gate_fails_below_floor
run_test test_warm_gate_override_passes
run_test test_linux_gate_runs_cold
run_test test_linux_gate_starts_before_the_builds
run_test test_linux_gate_failure_refuses_the_landing
run_test test_linux_gate_pass
run_test test_linux_gate_fail
run_test test_linux_gate_unreachable
run_test test_speed_gate_improve
run_test test_speed_gate_regress_no_override
run_test test_speed_gate_regress_with_override
run_test test_speed_gate_links_the_candidates_runtime
run_test test_speed_gate_object_hit_tool_failure
run_test test_speed_gate_held_assertion_tool_failure
run_test test_speed_gate_median_of_three
run_test test_run_checks_launch_order
run_test test_tools_only_gate_script_runs_its_step
run_test test_tools_only_several_gate_scripts_run_all_steps

report_tests

echo
echo "land_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
