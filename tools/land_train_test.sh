#!/bin/sh
# FIXTURES FOR tools/land_train.sh — never a real Sprite, never the
# real repo: every git repo here is thrown together fresh under a
# scratch directory, and `AVRA_LAND_TRAIN_SPRITE_BUILD` stands in for
# `tools/sprite-build.sh` so a candidate's verdict is decided by a
# marker file in its own merged tree, never by an actual remote build
# — the same seam `tools/land_test.sh` already uses for the Linux gate
# (`sprite_stub_write`), applied to the train's own wider gate set.
#
# `sh tools/land_train_test.sh` runs every fixture and prints a
# PASS/FAIL summary; a non-zero exit is a real failure.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
land_train="$here/land_train.sh"
land="$here/land.sh"

scratch="/tmp/avra-land-train-test-$$"
mkdir -p "$scratch"
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT INT TERM

ok() { echo "ok    $1"; }
bad() { echo "FAIL  $1"; [ -n "${2:-}" ] && sed 's/^/      | /' "$2" 2>/dev/null; }

# A throwaway repo with `main` plus one branch per name given, each
# committing a MARKER file under packages/<name>/marker — the stub
# Sprite decides a candidate's verdict by testing for one branch's
# marker in the merged tree, never by running a real build.
git_repo() {
    repo="$scratch/$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" symbolic-ref HEAD refs/heads/main
    git -C "$repo" config user.email test@example.com
    git -C "$repo" config user.name "land-train test"
    echo "$repo"
}
commit_all() {
    git -C "$1" add -A
    git -C "$1" commit -q -m "$2"
}

# ladder_repo <name> <branch> [<branch>...] — main plus one commit-only
# branch per name, each off main, each adding packages/<b>/marker.
ladder_repo() {
    name="$1"
    shift
    d="$(git_repo "$name")"
    mkdir -p "$d/packages/base/src"
    printf '[package]\nname = "base"\nversion = "0.1.0"\n' > "$d/packages/base/avra.toml"
    printf 'export fn base() -> int { 0 }\n' > "$d/packages/base/src/lib.av"
    commit_all "$d" "base"
    for b in "$@"; do
        git -C "$d" checkout -q -b "$b" main
        mkdir -p "$d/packages/$b"
        printf '%s\n' "$b" > "$d/packages/$b/marker"
        commit_all "$d" "$b adds its marker"
    done
    git -C "$d" checkout -q main
    echo "$d"
}

# The Sprite stub: `$1`=sprite, `$2`=worktree, the rest is the real
# `bash -lc "<body>"` invocation, ignored — this stub answers from the
# WORKTREE's own content and two env vars, never from the body script,
# so a fixture never needs a real Linux compiler to run.
#   BAD_SPRITE   — this sprite name always fails before printing the
#                  start marker (a TOOL failure, never a branch's).
#   CULPRIT_MARK — a candidate whose merged tree carries
#                  packages/<CULPRIT_MARK>/marker fails for real.
sprite_stub() {
    cat > "$1" <<'STUB'
#!/bin/sh
sprite="$1"
wt="$2"
if [ -n "${BAD_SPRITE:-}" ] && [ "$sprite" = "$BAD_SPRITE" ]; then
    echo "sprite-build: could not reach $sprite (connection refused)" >&2
    exit 1
fi
echo "land-train: body started"
if [ -n "${CULPRIT_MARK:-}" ] && [ -f "$wt/packages/$CULPRIT_MARK/marker" ]; then
    echo "land-train: fake-check FAILED (exit 1) 0s"
    exit 1
fi
echo "land-train: fake-check OK 0s"
exit 0
STUB
    chmod +x "$1"
}

train_env() {
    d="$1"
    stub="$2"
    export AVRA_LAND_TRAIN_SPRITE_BUILD="$stub"
    export AVRA_LAND_TRAIN_SPRITES="s1 s2 s3"
    export AVRA_LAND_TRAIN_MEM_CMD='echo 4096'
    export AVRA_LAND_TRAIN_SCRATCH="$scratch/train-run-$(basename "$d")"
    export AVRA_TRAIN_STEP_TIMEOUT=30
    export AVRA_TRAIN_HEARTBEAT=10
    export AVRA_LAND_TRAIN_RETRIES=2
}

# ══ ORDERING: three good branches all pass — the whole ladder lands ═
test_train_all_green() {
    d="$(ladder_repo all-green a b c)"
    stub="$scratch/all-green-sprite.sh"
    sprite_stub "$stub"
    train_env "$d" "$stub"
    out="$scratch/all-green.out"
    ( cd "$d" && sh "$land_train" --call train_ladder a b c ) > "$out" 2>&1
    good="$(tail -1 "$out")"
    if [ "$good" = "a b c" ]; then
        ok "train: three good branches all land, in FIFO order"
    else
        bad "train: expected 'a b c', got '$good'" "$out"
    fi
    unset AVRA_LAND_TRAIN_SPRITE_BUILD AVRA_LAND_TRAIN_SPRITES AVRA_LAND_TRAIN_MEM_CMD AVRA_LAND_TRAIN_SCRATCH
}

# ══ A MID-TRAIN FAILURE: b is dropped, a and c still land ═══════════
test_train_mid_failure_rebase() {
    d="$(ladder_repo mid-fail a b c)"
    stub="$scratch/mid-fail-sprite.sh"
    sprite_stub "$stub"
    train_env "$d" "$stub"
    export CULPRIT_MARK=b
    out="$scratch/mid-fail.out"
    ( cd "$d" && sh "$land_train" --call train_ladder a b c ) > "$out" 2>&1
    good="$(tail -1 "$out")"
    if [ "$good" = "a c" ]; then
        ok "train: a mid-train failure drops its own branch, the rest re-verify and land"
    else
        bad "train: expected 'a c', got '$good'" "$out"
    fi
    if grep -q "CULPRIT: b" "$out"; then
        ok "train: names b as the culprit"
    else
        bad "train: did not name b as the culprit" "$out"
    fi
    if grep -q "wave 2" "$out"; then
        ok "train: a second wave re-verifies the tail without the culprit"
    else
        bad "train: no second wave ran after the drop" "$out"
    fi
    unset CULPRIT_MARK AVRA_LAND_TRAIN_SPRITE_BUILD AVRA_LAND_TRAIN_SPRITES AVRA_LAND_TRAIN_MEM_CMD AVRA_LAND_TRAIN_SCRATCH
}

# ══ THE FIRST CANDIDATE FAILS: it drops, and the tail BEHIND it still
# gets its own honest verification — b has nothing to do with a's
# failure, so it lands. (A batch where EVERYTHING traces to the first
# branch, e.g. every later branch depends on it, would instead fail
# every subsequent candidate for its OWN reason — that is a normal
# wave, not a special case, and needs no separate fixture.) ═════════
test_train_first_fails() {
    d="$(ladder_repo first-fail a b)"
    stub="$scratch/first-fail-sprite.sh"
    sprite_stub "$stub"
    train_env "$d" "$stub"
    export CULPRIT_MARK=a
    out="$scratch/first-fail.out"
    good="$(cd "$d" && sh "$land_train" --call train_ladder a b 2>"$out")"
    if [ "$good" = "b" ] && grep -q "CULPRIT: a" "$out"; then
        ok "train: the leading candidate failing drops it, b still verifies and lands"
    else
        bad "train: expected 'b' to land with a named as culprit — got '$good'" "$out"
    fi
    unset CULPRIT_MARK AVRA_LAND_TRAIN_SPRITE_BUILD AVRA_LAND_TRAIN_SPRITES AVRA_LAND_TRAIN_MEM_CMD AVRA_LAND_TRAIN_SCRATCH
}

# ══ A TOOL FAILURE RETRIES ON ANOTHER SPRITE, NEVER BLAMES THE BRANCH ═
test_train_tool_failure_retries() {
    d="$(ladder_repo tool-fail a)"
    stub="$scratch/tool-fail-sprite.sh"
    sprite_stub "$stub"
    train_env "$d" "$stub"
    export BAD_SPRITE=s1
    out="$scratch/tool-fail.out"
    ( cd "$d" && sh "$land_train" --call train_ladder a ) > "$out" 2>&1
    good="$(tail -1 "$out")"
    if [ "$good" = "a" ]; then
        ok "train: a bad Sprite is skipped and the candidate still lands via another"
    else
        bad "train: expected 'a' to land despite one bad Sprite — got '$good'" "$out"
    fi
    if grep -q "s1" "$out" && grep -q "failed before the command ran" "$out"; then
        ok "train: names the bad Sprite and its own failure, never the branch"
    else
        bad "train: did not report the bad Sprite by name" "$out"
    fi
    unset BAD_SPRITE AVRA_LAND_TRAIN_SPRITE_BUILD AVRA_LAND_TRAIN_SPRITES AVRA_LAND_TRAIN_MEM_CMD AVRA_LAND_TRAIN_SCRATCH
}

# ══ EVERY SPRITE IS BAD: a TOOL FAILURE, never a verdict on the branch ═
test_train_all_sprites_bad_is_tool_failure() {
    d="$(ladder_repo all-bad a)"
    stub="$scratch/all-bad-sprite.sh"
    cat > "$stub" <<'STUB'
#!/bin/sh
echo "sprite-build: could not reach $1 (connection refused)" >&2
exit 1
STUB
    chmod +x "$stub"
    train_env "$d" "$stub"
    out="$scratch/all-bad.out"
    st=0
    good="$(cd "$d" && sh "$land_train" --call train_ladder a 2>"$out")" || st=$?
    if [ "$st" -ne 0 ] && [ -z "$good" ] && ! grep -q "CULPRIT: a" "$out"; then
        ok "train: every Sprite failing is a tool failure, never a culprit verdict on a"
    else
        bad "train: expected a tool failure with no culprit named — got st=$st good='$good'" "$out"
    fi
    unset AVRA_LAND_TRAIN_SPRITE_BUILD AVRA_LAND_TRAIN_SPRITES AVRA_LAND_TRAIN_MEM_CMD AVRA_LAND_TRAIN_SCRATCH
}

# ══ dry-run main(): never touches real main, prints the winning head ═
test_train_dry_run_prints_head() {
    d="$(ladder_repo dry-run a b)"
    stub="$scratch/dry-run-sprite.sh"
    sprite_stub "$stub"
    train_env "$d" "$stub"
    out="$scratch/dry-run.out"
    st=0
    ( cd "$d" && sh "$land_train" --dry-run a b ) > "$out" 2>&1 || st=$?
    if [ "$st" -eq 0 ] && grep -q "DRY RUN — would fast-forward main to: a b" "$out" && grep -q "candidate head:" "$out"; then
        ok "train: dry-run reports the winning branches and head, never moves main"
    else
        bad "train: dry-run did not report as expected" "$out"
    fi
    head_after="$(git -C "$d" rev-parse main)"
    base="$(git -C "$d" log --format=%H main | tail -1)"
    if [ "$head_after" = "$base" ]; then
        ok "train: real main's ref did not move"
    else
        bad "train: main moved during a dry run"
    fi
    unset AVRA_LAND_TRAIN_SPRITE_BUILD AVRA_LAND_TRAIN_SPRITES AVRA_LAND_TRAIN_MEM_CMD AVRA_LAND_TRAIN_SCRATCH
}

# A fixture runs DIRECTLY (never subshelled) so its own env exports
# and unsets take effect for real — `ok`/`bad` write to this log, read
# back afterward by SCANNING it (never by a shared counter a fixture's
# own subshell would fork away from — the exact trap
# `tools/land_test.sh`'s own header names).
run_test() {
    name="$1"
    log="$scratch/$name.run.log"
    if "$name" > "$log" 2>&1; then
        cat "$log"
    else
        cat "$log"
        echo "FAIL  $name (the fixture itself errored — see above)"
    fi
}

run_test test_train_all_green
run_test test_train_mid_failure_rebase
run_test test_train_first_fails
run_test test_train_tool_failure_retries
run_test test_train_all_sprites_bad_is_tool_failure
run_test test_train_dry_run_prints_head

total="$(cat "$scratch"/*.run.log 2>/dev/null | grep -cE '^(ok|FAIL)  ')"
failed="$(cat "$scratch"/*.run.log 2>/dev/null | grep -cE '^FAIL  ')"
echo "----------------------------------------"
echo "land_train_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
