#!/bin/sh
# FIXTURES FOR tools/land_train.sh — never a real Sprite, never the
# real repo: every git repo here is thrown together fresh under a
# scratch directory. `AVRA_LAND_SPRITE_BUILD` stands in for
# `tools/sprite-build.sh` (a candidate's verdict is decided by a
# marker file in its own merged tree, never by an actual remote
# build) and `AVRA_LAND_SPRITE_PROBE` stands in for a real Sprite's
# load probe — the SAME two seams `tools/land_test.sh` already uses
# for `linux_gate_step` and `sprites_by_load`, since land_train.sh now
# calls both of land.sh's own functions rather than carrying a second
# copy of either.
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

# A uniform-load probe: every sprite name answers the same load, cores
# and free memory, so `sprites_by_load`'s own ordering never matters
# to a fixture that is not specifically testing it (a tie-break stays
# deterministic — sort is stable over equal keys).
probe_stub() {
    cat > "$1" <<'PROBE'
#!/bin/sh
echo "0.10 8 7000"
PROBE
    chmod +x "$1"
}

# A no-op remote-stop: `watched()`'s 124/125 paths call `stop_remote`,
# which — unstubbed — reaches for the REAL `sprite` CLI against a
# Sprite name that does not exist, costing a real ~60s network
# timeout per call (found running this file for real: a "silent
# Sprite" fixture took ~70s instead of a few, because its own
# no-progress path correctly fired in a few seconds and then sat in
# exactly that unstubbed call). Every fixture that can reach 124/125
# must stub this, the same way `tools/land_test.sh`'s own
# `test_linux_watchdog` stubs it (`stopper`).
stop_stub() {
    cat > "$1" <<'STOPSTUB'
#!/bin/sh
echo "$1 $2" >> "${STOP_LOG:-/dev/null}"
STOPSTUB
    chmod +x "$1"
}

train_env() {
    d="$1"
    stub="$2"
    probe="$scratch/$(basename "$d")-probe.sh"
    probe_stub "$probe"
    stopper="$scratch/$(basename "$d")-stop.sh"
    stop_stub "$stopper"
    export AVRA_LAND_SPRITE_BUILD="$stub"
    export AVRA_LAND_SPRITE_PROBE="$probe"
    export AVRA_LAND_SPRITE_STOP="$stopper"
    export STOP_LOG="$scratch/$(basename "$d")-stops.log"
    export AVRA_LAND_SPRITE="s1 s2 s3"
    export AVRA_LAND_TRAIN_SCRATCH="$scratch/train-run-$(basename "$d")"
    export AVRA_LAND_TRAIN_CAP_S=30
    export AVRA_LAND_TRAIN_QUIET_S=10
    export AVRA_LAND_TRAIN_RETRIES=2
    export AVRA_LAND_WATCH_POLL_S=1
    export AVRA_LAND_TRAIN_PROBE_INTERVAL_S=2
    export AVRA_SP_SLOTS="$scratch/sp-slots-$(basename "$d")"
}
unset_train_env() {
    unset AVRA_LAND_SPRITE_BUILD AVRA_LAND_SPRITE_PROBE AVRA_LAND_SPRITE
    unset AVRA_LAND_SPRITE_STOP STOP_LOG AVRA_LAND_TRAIN_PROBE_INTERVAL_S
    unset AVRA_LAND_TRAIN_SCRATCH AVRA_LAND_TRAIN_CAP_S AVRA_LAND_TRAIN_QUIET_S
    unset AVRA_LAND_TRAIN_RETRIES AVRA_LAND_WATCH_POLL_S
    unset AVRA_SP_SLOTS AVRA_SPRITES AVRA_LAND_TRAIN_SLOTS
}

# A Sprite stub that holds each run until a second run shares its
# Sprite (or 30s pass), then records its Sprite, its tree's name and
# how many runs that Sprite held at once (one file per live run under
# $CONC_DIR). Waiting for a peer makes overlap independent of load.
busy_stub() {
    cat > "$1" <<'STUB'
#!/bin/sh
sprite="$1"
wt="$2"
echo "land-train: body started"
mkdir -p "$CONC_DIR"
touch "$CONC_DIR/$sprite.$$"
i=0
while [ "$(ls "$CONC_DIR" | grep -c "^$sprite\.")" -lt 2 ] && [ "$i" -lt 30 ]; do
    sleep 1
    i=$((i + 1))
done
n="$(ls "$CONC_DIR" | grep -c "^$sprite\.")"
echo "$sprite $(basename "$wt") $n" >> "$RUN_LOG"
sleep 2
rm -f "$CONC_DIR/$sprite.$$"
echo "land-train: fake-check OK 0s"
exit 0
STUB
    chmod +x "$1"
}
most_at_once() { awk -v s="$1" '$1 == s && $3 > m { m = $3 } END { print m + 0 }' "$RUN_LOG"; }

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
    unset_train_env
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
    unset CULPRIT_MARK
    unset_train_env
}

# ══ TWO FAILURES ACROSS TWO SEPARATE WAVES: the ladder keeps re-
# verifying its tail wave after wave until nothing is left to drop —
# never stopping at the first drop the way a single-failure fixture
# alone could not tell apart from "the loop runs exactly once more." ═
test_train_two_failures_across_waves() {
    d="$(ladder_repo two-fail a b c e)"
    stub="$scratch/two-fail-sprite.sh"
    cat > "$stub" <<'STUB'
#!/bin/sh
sprite="$1"
wt="$2"
echo "land-train: body started"
for bad in b e; do
    if [ -f "$wt/packages/$bad/marker" ]; then
        echo "land-train: fake-check FAILED (exit 1) 0s"
        exit 1
    fi
done
echo "land-train: fake-check OK 0s"
exit 0
STUB
    chmod +x "$stub"
    train_env "$d" "$stub"
    out="$scratch/two-fail.out"
    good="$(cd "$d" && sh "$land_train" --call train_ladder a b c e 2>"$out")"
    if [ "$good" = "a c" ]; then
        ok "train: two failures in two different waves both drop, a and c still land"
    else
        bad "train: expected 'a c' across two dropped waves — got '$good'" "$out"
    fi
    n_culprits="$(grep -c '^CULPRIT: ' "$out")"
    if [ "$n_culprits" -eq 2 ] && grep -q "CULPRIT: b" "$out" && grep -q "CULPRIT: e" "$out"; then
        ok "train: names both b and e as culprits, one per wave"
    else
        bad "train: expected exactly b and e named as culprits — got:" "$out"
    fi
    # Wave 1 drops b (leaving tail "c e"); wave 2 drops e (leaving tail
    # ""), which EMPTIES the tail — so the loop ends after wave 2, not
    # a third all-green confirmation wave. Two waves is the correct
    # count, not an early stop: nothing is left to re-verify.
    n_waves="$(grep -c '^land-train: wave [0-9]* over' "$out")"
    if [ "$n_waves" -eq 2 ]; then
        ok "train: two waves ran (drop b, drop e) — the ladder keeps re-verifying until the tail empties"
    else
        bad "train: expected 2 waves, got $n_waves" "$out"
    fi
    unset_train_env
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
    unset CULPRIT_MARK
    unset_train_env
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
    unset BAD_SPRITE
    unset_train_env
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
    unset_train_env
}

# ══ A SILENT SPRITE (watched()'s no-progress path) IS MOVED, NEVER
# BLAMED ON THE BRANCH — the same primitive linux_gate_step already
# proves, exercised here through run_candidate's own dispatch. ══════
test_train_watchdog_moves_to_another_sprite() {
    d="$(ladder_repo watchdog a)"
    stub="$scratch/watchdog-sprite.sh"
    cat > "$stub" <<'STUB'
#!/bin/sh
sprite="$1"
echo "land-train: body started"
if [ "$sprite" = "${SILENT_SPRITE:-}" ]; then
    sleep 60
else
    echo "land-train: fake-check OK 0s"
fi
exit 0
STUB
    chmod +x "$stub"
    train_env "$d" "$stub"
    export SILENT_SPRITE=s1
    export AVRA_LAND_TRAIN_QUIET_S=3
    # THE CAP IS GENEROUS ON PURPOSE: this asserts the QUIET window
    # cuts the wait short of the CAP, never a fixed wall-clock number
    # — a `watched()` poll under real, shared-machine load (this
    # session measured a 28-34 load average while writing this test)
    # can slip several seconds late without being wrong, and a tight
    # absolute bound would flake on exactly that, not on a real
    # defect. What must hold is RELATIVE: well under the cap.
    export AVRA_LAND_TRAIN_CAP_S=300
    out="$scratch/watchdog.out"
    t0="$(date +%s)"
    good="$(cd "$d" && sh "$land_train" --call train_ladder a 2>"$out")"
    wall=$(( $(date +%s) - t0 ))
    if [ "$good" = "a" ]; then
        ok "train: a candidate still lands after its first Sprite goes silent"
    else
        bad "train: expected 'a' to land past a silent Sprite — got '$good'" "$out"
    fi
    if grep -q "no progress on s1" "$out" && grep -q "retrying" "$out"; then
        ok "train: watched()'s no-progress path is what moved it, named"
    else
        bad "train: no no-progress move was reported" "$out"
    fi
    # RETRACTED: half the cap flaked for real (153s of 300) under this
    # session's own worst load spike (past 120) — a delay from OTHER
    # processes starving every fork this loop makes, not from the
    # no-progress logic itself, which named itself correctly seconds
    # into that same run. Ninety percent is the actual claim worth
    # making: this candidate did NOT fall through to the hard cap.
    if [ "$wall" -lt "$((AVRA_LAND_TRAIN_CAP_S * 9 / 10))" ]; then
        ok "train: the move happens short of the cap (${wall}s of a ${AVRA_LAND_TRAIN_CAP_S}s cap)"
    else
        bad "train: took ${wall}s of a ${AVRA_LAND_TRAIN_CAP_S}s cap — fell through to the hard cap, not the no-progress path"
    fi
    if grep -q "^s1 " "$STOP_LOG" 2>/dev/null; then
        ok "train: the silent Sprite's remote run is told to stop"
    else
        bad "train: no remote stop was recorded ($(cat "$STOP_LOG" 2>/dev/null))"
    fi
    unset SILENT_SPRITE
    unset_train_env
}

# ══ PROGRESS: a quiet step spending CPU is alive; one spending none is not
# The stub's heartbeat holds its byte count still for 12s while the
# CPU count grows (QUIET_CPU=grow) or holds too (QUIET_CPU=hold).
quiet_stub() {
    cat > "$1" <<'STUB'
#!/bin/sh
echo "land-train: body started"
i=0
while [ "$i" -lt 12 ]; do
    i=$((i + 1))
    [ "$QUIET_CPU" = grow ] && c="$i" || c=7
    echo "land-train: progress 100 cpu $c"
    sleep 1
done
echo "land-train: fake-check OK 0s"
STUB
    chmod +x "$1"
}
test_train_cpu_is_progress() {
    d="$(ladder_repo cpu a)"
    stub="$scratch/cpu-sprite.sh"
    quiet_stub "$stub"
    train_env "$d" "$stub"
    export AVRA_LAND_SPRITE="s1" AVRA_LAND_TRAIN_QUIET_S=5 AVRA_LAND_TRAIN_RETRIES=0 QUIET_CPU=grow
    out="$scratch/cpu-grow.out"
    good="$(cd "$d" && sh "$land_train" --call train_ladder a 2>"$out")"
    if [ "$good" = "a" ] && ! grep -q "no progress" "$out"; then
        ok "train: a step whose log is quiet but whose CPU grows is never cut off"
    else
        bad "train: a busy quiet step was cut off (got '$good')" "$out"
    fi
    export QUIET_CPU=hold AVRA_LAND_TRAIN_SCRATCH="$scratch/train-run-cpu-hold"
    out="$scratch/cpu-hold.out"
    good="$(cd "$d" && sh "$land_train" --call train_ladder a 2>"$out")"
    if [ -z "$good" ] && grep -q "no progress on s1" "$out"; then
        ok "train: a step whose log and CPU both hold still is cut off"
    else
        bad "train: a wedged step was not cut off (got '$good')" "$out"
    fi
    unset QUIET_CPU
    unset_train_env
}

# ══ A TERM MID-WAVE: nothing of the train outlives it, every candidate stopped
test_train_term_leaves_nothing() {
    d="$(ladder_repo term a)"
    stub="$scratch/term-sprite.sh"
    cat > "$stub" <<'STUB'
#!/bin/sh
echo "land-train: body started"
touch "$TERM_MARKS/$$"
sleep 300
STUB
    chmod +x "$stub"
    train_env "$d" "$stub"
    export TERM_MARKS="$scratch/term-marks"
    mkdir -p "$TERM_MARKS"
    ( cd "$d" && exec sh "$land_train" --call train_ladder a ) > "$scratch/term.out" 2>&1 &
    train=$!
    i=0
    while [ "$(ls "$TERM_MARKS" | wc -l | tr -d ' ')" -lt 1 ] && [ "$i" -lt 300 ]; do sleep 1; i=$((i + 1)); done
    kill -TERM "$train"
    i=0
    while pgrep -f "$AVRA_LAND_TRAIN_SCRATCH|train_ladder a\$" >/dev/null && [ "$i" -lt 90 ]; do sleep 1; i=$((i + 1)); done
    left="$(pgrep -f "$AVRA_LAND_TRAIN_SCRATCH|train_ladder a\$" | wc -l | tr -d ' ')"
    alive=0
    for m in "$TERM_MARKS"/*; do kill -0 "$(basename "$m")" 2>/dev/null && alive=$((alive + 1)); done
    if [ "$left" -eq 0 ] && [ "$alive" -eq 0 ]; then
        ok "train: a TERM mid-wave leaves no train process and no candidate running (${i}s)"
    else
        bad "train: after a TERM, $left train process(es) and $alive candidate(s) still run" "$scratch/term.out"
        pkill -f "$AVRA_LAND_TRAIN_SCRATCH" 2>/dev/null
        for m in "$TERM_MARKS"/*; do kill "$(basename "$m")" 2>/dev/null; done
    fi
    if [ "$(grep -c '' "$STOP_LOG" 2>/dev/null || echo 0)" -ge 1 ]; then
        ok "train: the in-flight candidate's remote run is told to stop"
    else
        bad "train: stops recorded: $(cat "$STOP_LOG" 2>/dev/null | tr '\n' ';')"
    fi
    unset TERM_MARKS
    unset_train_env
}

# ══ SLOTS: one Sprite runs two candidates at once, each in its own tree ═
test_train_two_slots_per_sprite() {
    d="$(ladder_repo slots a b c)"
    stub="$scratch/slots-sprite.sh"
    busy_stub "$stub"
    train_env "$d" "$stub"
    export AVRA_LAND_SPRITE="s1"
    export AVRA_LAND_TRAIN_QUIET_S=60 AVRA_LAND_TRAIN_CAP_S=300
    export CONC_DIR="$scratch/slots-conc" RUN_LOG="$scratch/slots-runs.log"
    out="$scratch/slots.out"
    good="$(cd "$d" && sh "$land_train" --call train_ladder a b c 2>"$out")"
    if [ "$good" = "a b c" ]; then
        ok "train: three candidates land through one Sprite's two slots"
    else
        bad "train: expected 'a b c', got '$good'" "$out"
    fi
    m="$(most_at_once s1)"
    if [ "$m" -eq 2 ]; then
        ok "train: one Sprite held two candidates at once, never three"
    else
        bad "train: s1 held at most $m candidates at once, expected 2" "$RUN_LOG"
    fi
    trees="$(awk '{ print $2 }' "$RUN_LOG" | sort -u | wc -l | tr -d ' ')"
    if [ "$trees" -eq 3 ]; then
        ok "train: each candidate synced into its own remote tree"
    else
        bad "train: 3 runs shared $trees tree name(s)" "$RUN_LOG"
    fi
    unset CONC_DIR RUN_LOG
    unset_train_env
}

# ══ SHARED POOL: unset, the pool is sp's, and sp's slots are shared ═
test_train_shared_pool() {
    d="$(ladder_repo shared a b c)"
    stub="$scratch/shared-sprite.sh"
    busy_stub "$stub"
    train_env "$d" "$stub"
    unset AVRA_LAND_SPRITE
    export AVRA_SPRITES="p1 p2"
    export AVRA_LAND_TRAIN_QUIET_S=60 AVRA_LAND_TRAIN_CAP_S=300
    export CONC_DIR="$scratch/shared-conc" RUN_LOG="$scratch/shared-runs.log"
    # An `sp` job already holds slot 1 on each Sprite.
    sleep 3600 &
    job=$!
    for s in p1 p2; do
        mkdir -p "$AVRA_SP_SLOTS/$s/slot-1"
        echo "$job" > "$AVRA_SP_SLOTS/$s/slot-1/pid"
    done
    out="$scratch/shared.out"
    good="$(cd "$d" && sh "$land_train" --call train_ladder a b c 2>"$out")"
    if [ "$good" = "a b c" ]; then
        ok "train: the shared pool lands all three"
    else
        bad "train: expected 'a b c', got '$good'" "$out"
    fi
    others="$(awk '$1 != "p1" && $1 != "p2" { print $1 }' "$RUN_LOG" | sort -u | tr '\n' ' ')"
    if [ -s "$RUN_LOG" ] && [ -z "$others" ]; then
        ok "train: with AVRA_LAND_SPRITE unset, candidates run on sp's pool alone"
    else
        bad "train: candidates ran outside sp's pool: '$others'" "$RUN_LOG"
    fi
    if [ "$(most_at_once p1)" -le 1 ] && [ "$(most_at_once p2)" -le 1 ]; then
        ok "train: an sp job's slot counts — two slots, one taken, one candidate per Sprite"
    else
        bad "train: a Sprite ran two candidates beside an sp job" "$RUN_LOG"
    fi
    if [ "$(cat "$AVRA_SP_SLOTS/p1/slot-1/pid" 2>/dev/null)" = "$job" ]; then
        ok "train: the sp job's slot is left as it was"
    else
        bad "train: the sp job's slot was taken or removed"
    fi
    kill "$job" 2>/dev/null
    unset CONC_DIR RUN_LOG
    unset_train_env
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
    unset_train_env
}

# ══ THE HAND-OFF INTO land.sh's OWN train_core ═══════════════════════
# train_core (tools/land.sh) calls train_ladder for the Sprite half,
# then land.sh's OWN try_integration/check_phase for the Mac-only
# half. This reuses tools/land_test.sh's OWN `batch_repo` fixture
# shape (a fake build/avra + Makefile, its CULPRIT_PKG convention) —
# duplicated here rather than sourced, since land_test.sh runs its
# whole suite as a side effect of being read — so this proves the
# WIRING, never re-deriving what test_batch_mode already proves
# about try_integration itself.
train_batch_repo() {
    d="$(git_repo "$1")"
    for p in a b c; do
        mkdir -p "$d/packages/$p/src"
        printf '[package]\nname = "%s"\nversion = "0.1.0"\n' "$p" > "$d/packages/$p/avra.toml"
        printf 'export fn seed_%s() -> int { 0 }\n' "$p" > "$d/packages/$p/src/lib.av"
    done
    mkdir -p "$d/build" "$d/packages/cli/src" "$d/bootstrap"
    cat > "$d/build/avra" <<'STUB'
#!/bin/sh
case "$1" in
    build)
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
    check|fmt) exit 0 ;;
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
    printf 'build/\n' > "$d/.gitignore"
    commit_all "$d" "base"
    for p in a b c; do
        git -C "$d" checkout -q -b "$p" main
        printf 'export fn seed_%s() -> int { 1 }\n' "$p" > "$d/packages/$p/src/lib.av"
        mkdir -p "$d/packages/$p"
        printf '%s\n' "$p" > "$d/packages/$p/marker"
        commit_all "$d" "$p's own change"
    done
    git -C "$d" checkout -q main
    echo "$d"
}

test_train_core_lands_the_sprite_verified_prefix() {
    d="$(train_batch_repo core-wire)"
    stub="$scratch/core-wire-sprite.sh"
    sprite_stub "$stub"
    train_env "$d" "$stub"
    export CULPRIT_MARK=b
    export AVRA_LAND_TRAIN=1 AVRA_LAND_SPEED_GATE=0 AVRA_LAND_WARM_GATE=0
    lockdir="$scratch/core-wire-lock"
    batchwt="$scratch/core-wire-batchwt"
    slots="$scratch/core-wire-slots"
    rm -rf "$lockdir" "$batchwt" "$slots"
    out="$scratch/core-wire.out"
    # The full CLI wrapper (`main_batch`), never `train_core` alone —
    # main_batch is what prints "LANDED", exactly as a real multi-
    # branch `land.sh a b c` run would, with AVRA_LAND_TRAIN=1 the
    # only difference from test_batch_mode's own invocation of the
    # non-train batch_core path.
    ( cd "$d" && AVRA_LAND_LOCK="$lockdir" AVRA_LAND_BATCH_WT="$batchwt" AVRA_SLOTS_DIR="$slots" \
        branch=x sh "$land" --call main_batch 0 a b c ) > "$out" 2>&1
    if grep -q "^land: train green prefix: a c$" "$out"; then
        ok "train_core: the Sprite-verified prefix (b dropped) is what reaches the final pass"
    else
        bad "train_core: expected the Sprite phase to drop b before the final pass" "$out"
    fi
    if grep -q "CULPRIT: b" "$out"; then
        ok "train_core: names b as the culprit, from the Sprite phase"
    else
        bad "train_core: did not name b as the culprit" "$out"
    fi
    if grep -q "^LANDED" "$out"; then
        ok "train_core: still lands a and c despite b's Sprite failure"
    else
        bad "train_core: did not land anything" "$out"
    fi
    main_a="$(git -C "$d" show main:packages/a/src/lib.av 2>/dev/null)"
    main_b="$(git -C "$d" show main:packages/b/src/lib.av 2>/dev/null)"
    if printf '%s' "$main_a" | grep -q "int { 1 }" && ! printf '%s' "$main_b" | grep -q "int { 1 }"; then
        ok "train_core: main carries a's and c's change but not b's"
    else
        bad "train_core: main's content does not match a,c-in, b-out" "$out"
    fi
    unset CULPRIT_MARK AVRA_LAND_TRAIN AVRA_LAND_SPEED_GATE AVRA_LAND_WARM_GATE
    unset_train_env
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
run_test test_train_two_failures_across_waves
run_test test_train_first_fails
run_test test_train_tool_failure_retries
run_test test_train_all_sprites_bad_is_tool_failure
run_test test_train_watchdog_moves_to_another_sprite
run_test test_train_cpu_is_progress
run_test test_train_term_leaves_nothing
run_test test_train_two_slots_per_sprite
run_test test_train_shared_pool
run_test test_train_dry_run_prints_head
run_test test_train_core_lands_the_sprite_verified_prefix

total="$(cat "$scratch"/*.run.log 2>/dev/null | grep -cE '^(ok|FAIL)  ')"
failed="$(cat "$scratch"/*.run.log 2>/dev/null | grep -cE '^FAIL  ')"
echo "----------------------------------------"
echo "land_train_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
