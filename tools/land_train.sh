#!/bin/sh
# THE LAND TRAIN — a speculative, parallel merge queue in front of
# `tools/land.sh`'s own FIFO ticket lock. Design: docs/2026_09_29_LAND_TRAIN.md.
#
#   sh tools/land_train.sh [--dry-run] <branch> [<branch>...]
#   sh tools/land_train.sh --call <function> [args...]
#
# GIVEN branches b1..bN (in FIFO arrival order, the same order
# `tools/land.sh`'s ticket queue already keeps), this builds the
# candidate ladder C1=main+b1, C2=main+b1+b2, ... CN=main+b1..bN, and
# verifies every candidate IN ONE WAVE, one Sprite each, concurrently
# — never one Mac bisecting them one attempt at a time. A wave's
# verdict is the longest all-green PREFIX; a red candidate drops its
# OWN branch (never an earlier one — a prefix that already answered
# green stays trusted) and a NEW wave verifies the tail again, on top
# of the now-shorter good prefix. This repeats until a wave is wholly
# green (the train lands `good_branches`, `good_head`) or the tail is
# empty (nothing left to land).
#
# WHAT RUNS ON A SPRITE, PER CANDIDATE — the Linux-portable half of
# what `land.sh` runs locally today: the compiler build itself
# (`make bootstrap`/`objects`/`-o avra libs`, exactly `linux_gate_step`'s
# own body — a Sprite already proves this daily), every affected
# package's suite, idioms, fmt-lossless, seed-check, cache-attacks.
# None of these five calls a macOS-only tool (grepped, not assumed —
# see the design doc's own audit).
#
# WHAT NEVER RUNS ON A SPRITE: the speed gate (`/usr/bin/time -l` is
# BSD/macOS-only, and `tools/speed.baseline`'s whole history is this
# Mac's arm64 instruction counts — a Sprite's x86_64 counts are a
# different currency, not a faster reading of the same one), the
# warm-reuse gate (ratchets a Mac-measured floor the same way), the
# codesign step, and the real fast-forward. Those stay ONE Mac pass —
# `land.sh`'s own pipeline, unchanged — over the train's WINNING
# combined head, never per candidate. This script never performs that
# pass itself; `--call train_core` (land.sh's own hand-off point) is
# where a real landing chains into it.
#
# NEVER TOUCHES REAL MAIN ON ITS OWN: every candidate lives in its own
# throwaway worktree+branch under this run's scratch dir. The one
# function that would move main (`train_core`, called FROM land.sh,
# which already holds the FIFO lock) is exercised only by fixtures
# and by land.sh's own opt-in hand-off — never by this file's own
# `main()`, which always stops at printing the winning candidate.
set -eu

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
tools_dir="$(dirname "$self")"
land="$tools_dir/land.sh"

: "${AVRA_LAND_TRAIN_SPRITES:=avra-idioms-pay avra-comptime}"
: "${AVRA_LAND_TRAIN_SPRITE_BUILD:=$tools_dir/sprite-build.sh}"
: "${AVRA_TRAIN_STEP_TIMEOUT:=1200}"
# sprite-build.sh is legitimately SILENT for minutes at a time before
# the remote command's own first line ever reaches this log: waking a
# sleeping Sprite (sprite_ready's own retry ceiling is 120s), then the
# tree sync and file pushes, print nothing of their own. MEASURED
# against a real Sprite (docs/2026_09_29_LAND_TRAIN.md's proof run):
# 90s killed a healthy wake-and-sync outright. 420s clears a cold wake
# plus a real sync with room left, while still catching a step that is
# ACTUALLY wedged (which stays silent for the rest of the hard
# timeout, never just a few extra minutes).
: "${AVRA_TRAIN_HEARTBEAT:=420}"
: "${AVRA_LAND_TRAIN_RETRIES:=2}"
: "${AVRA_LAND_TRAIN_MIN_MEM_MB:=512}"

run_id="$$-$(date +%s)"
scratch_root="${AVRA_LAND_TRAIN_SCRATCH_ROOT:-/tmp/avra-land-train-scratch}"
train_scratch_owned=0
if [ -z "${AVRA_LAND_TRAIN_SCRATCH:-}" ]; then train_scratch_owned=1; fi
scratch="${AVRA_LAND_TRAIN_SCRATCH:-$scratch_root/$run_id}"
export AVRA_LAND_TRAIN_SCRATCH="$scratch"
mkdir -p "$scratch/logs" "$scratch/candidates"

log_of() { echo "$scratch/logs/$1.log"; }

usage() {
    cat <<'EOF'
usage: sh tools/land_train.sh [--dry-run] <branch> [<branch>...]

Builds the candidate ladder over `main`, verifies every candidate
concurrently (one Sprite each), and prints the winning green prefix
and its head sha. `--dry-run` (the default shape this file's own
`main()` always takes) never touches real main — see train_core in
tools/land.sh for the real hand-off.
EOF
}

# ── REPO PLUMBING, THROUGH land.sh's OWN FUNCTIONS ──────────────────
# Reused, never duplicated: land.sh's `worktree_for_branch` and
# `merge_ref_in` are the one place each of those questions is answered
# (CLAUDE.md's "the third copy names the concept" — this file's job is
# scheduling, not re-deriving git plumbing land.sh already owns).
repo_root="$(git rev-parse --show-toplevel)"
worktree_for() { ( cd "$repo_root" && sh "$land" --call worktree_for_branch "$1" ); }
merge_into() { ( branch="merge" sh "$land" --call merge_ref_in "$1" "$2" ); }

main_wt=""
resolve_main_wt() {
    main_wt="$(worktree_for main)"
    if [ -z "$main_wt" ]; then
        echo "land-train: no worktree has 'main' checked out — \`git worktree list\`" >&2
        return 1
    fi
}

# ── THE SPRITE POOL — one lease per Sprite, mkdir as the atomic claim ─
pool_list() { printf '%s' "$AVRA_LAND_TRAIN_SPRITES"; }

# A Sprite's own health: MemAvailable in MB, or empty when unreachable.
# Stubbed in tests via AVRA_LAND_TRAIN_MEM_CMD (prints "<sprite> <mb>"
# lines) so a fixture never dials a real Sprite to answer this.
sprite_mem_mb() {
    if [ -n "${AVRA_LAND_TRAIN_MEM_CMD:-}" ]; then
        # "$0" for the stub's own sh -c is the literal word `mem-check`,
        # never the sprite name — the sprite is `$1` inside the stub,
        # exactly as it is inside this function.
        sh -c "$AVRA_LAND_TRAIN_MEM_CMD" mem-check "$1" 2>/dev/null | tail -1
        return 0
    fi
    timeout 15 sprite -s "$1" exec --no-port-forward -- \
        awk '/^MemAvailable:/ { printf "%d", int($2/1024) }' /proc/meminfo 2>/dev/null || true
}

# Blocks until a Sprite in the pool is both FREE (no lease held) and
# HEALTHY (answers, with enough memory) — a Sprite that never answers
# is a TOOL failure for whoever asked, never grounds to wait forever,
# so a caller passes its own deadline. `$2`, optional: Sprites this
# CANDIDATE already tried and failed on — a retry prefers any OTHER
# Sprite first (a Sprite that just refused a candidate is the least
# likely to take it next), and only falls back to one of them once
# every other pool member is busy or unhealthy, so a small pool never
# deadlocks waiting for a Sprite this candidate is told to avoid.
claim_sprite() {
    deadline="$1"
    avoid="${2:-}"
    while :; do
        for pass in fresh any; do
            for s in $(pool_list); do
                if [ "$pass" = fresh ]; then
                    case " $avoid " in *" $s "*) continue ;; esac
                fi
                [ -d "$scratch/lease-$s" ] && continue
                mkdir "$scratch/lease-$s" 2>/dev/null || continue
                mb="$(sprite_mem_mb "$s")"
                case "$mb" in
                    ''|*[!0-9]*) rmdir "$scratch/lease-$s" 2>/dev/null; continue ;;
                esac
                if [ "$mb" -lt "$AVRA_LAND_TRAIN_MIN_MEM_MB" ]; then
                    rmdir "$scratch/lease-$s" 2>/dev/null
                    continue
                fi
                echo "$s"
                return 0
            done
        done
        [ "$(date +%s)" -lt "$deadline" ] || return 1
        sleep 1
    done
}
release_sprite() { rmdir "$scratch/lease-$1" 2>/dev/null || true; }

# ── ONE CANDIDATE'S TREE — a fresh worktree at main's tip, every
# branch in ITS OWN ORDER merged in through land.sh's real merge_ref_in
# (the seed-conflict amnesty included, exactly as a real landing gets
# it). Prints the candidate's own worktree path.
build_candidate_tree() {
    label="$1"
    shift
    path="$scratch/candidates/$label"
    rm -rf "$path"
    git -C "$main_wt" worktree add -q --detach "$path" main
    for b in "$@"; do
        if ! merge_into "$path" "refs/heads/$b" > "$(log_of "merge-$label-$(printf '%s' "$b" | tr '/ ' '__')")" 2>&1; then
            echo "land-train: [$label] merge of $b failed" >&2
            return 1
        fi
    done
    echo "$path"
}

# ── THE PER-CANDIDATE REMOTE BODY — the Linux-portable gate set,
# exactly the five checks named in the file header, each timed and
# named on its own line so a failure names the STEP, not just the
# candidate. `land-train: body started` is the tool-failure boundary,
# the same convention `linux_gate_step`'s `land-linux: body started` is.
candidate_body() {
    pkgs="$*"
    cat <<BODY
echo 'land-train: body started'
export LLVM_PREFIX=/usr/lib/llvm-22
run_step() {
    n="\$1"; shift
    t=\$(date +%s)
    if "\$@" > "/tmp/land-train-\$n.log" 2>&1; then
        echo "land-train: \$n OK \$(( \$(date +%s) - t ))s"
    else
        st=\$?
        echo "land-train: \$n FAILED (exit \$st) \$(( \$(date +%s) - t ))s"
        tail -60 "/tmp/land-train-\$n.log"
        exit 1
    fi
}
test -x build/avra || run_step bootstrap make bootstrap
run_step objects make objects
run_step libs make -o avra libs
run_step fmt-lossless make fmt-lossless
run_step seed-check-1 make seed-check || { run_step seed-emit make seed; run_step seed-check-2 make seed-check; }
for p in $pkgs; do
    run_step "idioms-\$p" ./build/avra check "packages/\$p" --baseline tools/idioms.baseline
done
d=\$(mktemp -d)
for p in $pkgs; do
    ( t=\$(date +%s); build/avra test "packages/\$p" > "\$d/\$p.log" 2>&1; echo \$? > "\$d/\$p.st"; \
      echo "land-train: test-\$p \$(( \$(date +%s) - t ))s" > "\$d/\$p.time" ) &
done
wait
fail=0
for p in $pkgs; do
    cat "\$d/\$p.time" 2>/dev/null
    st=\$(cat "\$d/\$p.st" 2>/dev/null || echo 1)
    if [ "\$st" -ne 0 ]; then
        fail=1
        echo "land-train: test-\$p FAILED (exit \$st)"
        tail -40 "\$d/\$p.log"
    fi
done
run_step cache-attacks make cache-attacks
exit \$fail
BODY
}

# ── ONE CANDIDATE, DISPATCHED, WITH RETRIES ON A TOOL FAILURE ────────
# Writes `$3/status` (0/1) and `$3/log`; a Sprite that never printed
# `land-train: body started` is a TOOL failure — retried on a
# different Sprite, up to AVRA_LAND_TRAIN_RETRIES times, before the
# CANDIDATE itself (never the branch alone) is marked a tool failure.
run_candidate() {
    tree="$1"
    label="$2"
    out_dir="$3"
    pkgs="$4"
    mkdir -p "$out_dir"
    tried=""
    attempt=0
    while :; do
        attempt=$((attempt + 1))
        deadline=$(( $(date +%s) + AVRA_TRAIN_STEP_TIMEOUT ))
        sprite="$(claim_sprite "$deadline" "$tried")" || {
            echo "no Sprite in the pool became free/healthy within ${AVRA_TRAIN_STEP_TIMEOUT}s" > "$out_dir/tool-failure"
            echo 1 > "$out_dir/status"
            return 1
        }
        tried="$tried $sprite"
        body_file="$scratch/body-$label.sh"
        candidate_body $pkgs > "$body_file"
        log="$out_dir/attempt-$attempt.log"
        sprite_build="$AVRA_LAND_TRAIN_SPRITE_BUILD"
        st=0
        watchdog_run "$log" "$deadline" \
            sh "$sprite_build" "$sprite" "$tree" -- bash -lc "$(cat "$body_file")" || st=$?
        release_sprite "$sprite"
        if grep -q '^land-train: body started' "$log" 2>/dev/null; then
            echo "$st" > "$out_dir/status"
            cp "$log" "$out_dir/log"
            echo "$sprite" > "$out_dir/sprite"
            return 0
        fi
        echo "land-train: [$label] Sprite $sprite failed before the command ran (exit $st, attempt $attempt) — $log" >&2
        if [ "$attempt" -gt "$AVRA_LAND_TRAIN_RETRIES" ]; then
            echo "no Sprite could run candidate $label (tried:$tried)" > "$out_dir/tool-failure"
            echo 1 > "$out_dir/status"
            return 1
        fi
    done
}

# A HARD TIMEOUT AND A NO-PROGRESS WATCHDOG, TOGETHER: the remote
# command is killed (SIGTERM, then SIGKILL) the moment either the
# absolute deadline passes OR the log stops growing for
# AVRA_TRAIN_HEARTBEAT seconds past its own start — a stuck sync or a
# wedged remote shell never hangs the whole train.
# Owns `$log` outright — a caller must never ALSO redirect onto it
# (two independent truncations of the same path would desync the
# offset the child's own inherited fd is writing at).
watchdog_run() {
    log="$1"
    deadline="$2"
    shift 2
    : > "$log"
    ( "$@" ) >> "$log" 2>&1 &
    cmd_pid=$!
    last_size=-1
    stable_since="$(date +%s)"
    killed=0
    while kill -0 "$cmd_pid" 2>/dev/null; do
        now="$(date +%s)"
        size="$(wc -c < "$log" 2>/dev/null || echo 0)"
        if [ "$size" != "$last_size" ]; then
            last_size="$size"
            stable_since="$now"
        fi
        if [ "$now" -ge "$deadline" ]; then
            echo "land-train: watchdog: hard timeout — killing" >> "$log"
            killed=1
        elif [ $((now - stable_since)) -ge "$AVRA_TRAIN_HEARTBEAT" ]; then
            echo "land-train: watchdog: no progress for ${AVRA_TRAIN_HEARTBEAT}s — killing" >> "$log"
            killed=1
        fi
        if [ "$killed" -eq 1 ]; then
            kill -TERM "$cmd_pid" 2>/dev/null; sleep 2; kill -KILL "$cmd_pid" 2>/dev/null
            break
        fi
        sleep 2
    done
    st=0
    wait "$cmd_pid" 2>/dev/null || st=$?
    [ "$killed" -eq 1 ] && [ "$st" -eq 0 ] && st=124
    return "$st"
}

# ── ONE WAVE — every candidate for the given tail, launched together,
# bounded only by the Sprite pool's own size (claim_sprite blocks a
# launch until a lease is free). Prints, on stdout, the longest green
# PREFIX of `tail` (space-separated branch names; empty when even the
# first fails), and leaves per-candidate results under
# `$scratch/wave-$id/C<k>/`.
run_wave() {
    wave_id="$1"
    good_prefix="$2"
    shift 2
    tail_branches="$*"
    wdir="$scratch/wave-$wave_id"
    mkdir -p "$wdir"
    pids=""
    # Cumulative branch lists, computed up front so every candidate's
    # tree is independent of another candidate's own progress — C<k>
    # is main + good_prefix + tail[1..k], never a diff against C<k-1>.
    cum=""
    k=0
    for b in $tail_branches; do
        k=$((k + 1))
        cum="$cum $b"
        cdir="$wdir/C$k"
        mkdir -p "$cdir"
        printf '%s\n' "$b" > "$cdir/added-branch"
        printf '%s' "$good_prefix$cum" > "$cdir/branches"
        (
            label="wave$wave_id-C$k"
            # A merge conflict here is an ORDINARY red, the same way
            # land.sh's own try_integration treats one — never a tool
            # failure. The branch that added the conflicting content
            # is this candidate's OWN last branch, so it is named the
            # same as any other red candidate, no special-casing.
            tree="$(build_candidate_tree "$label" $good_prefix $cum)" || {
                echo 1 > "$cdir/status"
                exit 0
            }
            base_sha="$(git -C "$main_wt" rev-parse main)"
            head_sha="$(git -C "$tree" rev-parse HEAD)"
            pkgs="$(sh "$tools_dir/affected_packages.sh" "$base_sha" "$head_sha" "$tree" 2>/dev/null | tr '\n' ' ')"
            echo "$head_sha" > "$cdir/head-sha"
            run_candidate "$tree" "$label" "$cdir" "$pkgs"
        ) &
        pids="$pids $!"
    done
    for p in $pids; do wait "$p" 2>/dev/null || true; done

    # Read verdicts IN ORDER — the first non-zero status ends the
    # prefix; a missing status file (a job that never wrote one) reads
    # as failed, fail-closed.
    good=""
    k=0
    for b in $tail_branches; do
        k=$((k + 1))
        cdir="$wdir/C$k"
        st="$(cat "$cdir/status" 2>/dev/null || echo 1)"
        if [ -f "$cdir/tool-failure" ]; then
            msg="wave $wave_id, candidate C$k ($b): $(cat "$cdir/tool-failure")"
            echo "TOOLFAIL C$k: $msg" >&2
            echo "$msg" > "$scratch/tool-failure"
            break
        fi
        if [ "$st" -ne 0 ]; then
            echo "CULPRIT: $b" >&2
            break
        fi
        good="$good $b"
    done
    # The all-green case names its own winning head, in a file — every
    # caller of run_wave reads this through a command substitution,
    # which forks a subshell, so a plain variable never crosses back.
    n_tail="$(printf '%s' "$tail_branches" | wc -w | tr -d ' ')"
    n_good="$(printf '%s' "$good" | wc -w | tr -d ' ')"
    if [ "$n_good" -eq "$n_tail" ] && [ "$n_tail" -gt 0 ]; then
        cat "$wdir/C$n_tail/head-sha" > "$scratch/final-head-sha" 2>/dev/null || true
    fi
    printf '%s\n' "${good# }"
}

# ── THE FULL LADDER — repeat waves until the tail is empty or wholly
# green. Prints the final winning branch list (space-separated, FIFO
# order preserved) on stdout; every dropped branch is named
# "CULPRIT: <name>" on stderr, exactly as land.sh's own bisector names
# one, so a caller's existing log-scraping needs no new pattern.
train_ladder() {
    resolve_main_wt
    good=""
    tail="$*"
    wave=0
    while [ -n "$(printf '%s' "$tail" | tr -d '[:space:]')" ]; do
        wave=$((wave + 1))
        echo "land-train: wave $wave over:$tail (good so far:${good:- none})" >&2
        wave_good="$(run_wave "$wave" "$good" $tail)"
        if [ -f "$scratch/tool-failure" ]; then
            return 1
        fi
        if [ "$(printf '%s' "$wave_good" | wc -w | tr -d ' ')" -eq "$(printf '%s' "$tail" | wc -w | tr -d ' ')" ]; then
            good="$good $wave_good"
            good="${good# }"
            tail=""
            break
        fi
        # Drop exactly the first branch this wave did not vouch for,
        # and retry the rest — `wave_good`'s own length names it.
        n_good="$(printf '%s' "$wave_good" | wc -w | tr -d ' ')"
        set -- $tail
        i=0
        dropped=""
        rest=""
        for b in "$@"; do
            i=$((i + 1))
            if [ "$i" -le "$n_good" ]; then continue; fi
            if [ -z "$dropped" ]; then dropped="$b"; continue; fi
            rest="$rest $b"
        done
        good="$good $wave_good"
        good="${good# }"
        tail="${rest# }"
        echo "land-train: wave $wave dropped $dropped — $(printf '%s' "$tail" | tr -d '[:space:]' | wc -c | tr -d ' ') chars remain queued" >&2
    done
    printf '%s\n' "$good"
}

# ── STAGE 1 ENTRY POINT — dry run only, never moves main. ────────────
main() {
    dry_run=1
    if [ "${1:-}" = "--dry-run" ]; then shift; fi
    [ "$#" -ge 1 ] || { usage >&2; exit 2; }
    good="$(train_ladder "$@")"
    if [ -z "$(printf '%s' "$good" | tr -d '[:space:]')" ]; then
        echo "land-train: nothing survived — no branch lands" >&2
        exit 1
    fi
    head_sha="$(cat "$scratch/final-head-sha" 2>/dev/null || true)"
    echo "land-train: DRY RUN — would fast-forward main to: $good"
    echo "land-train: candidate head: ${head_sha:-unknown}"
    exit 0
}

if [ "${1:-}" = "--call" ]; then
    shift
    fn="${1:?--call needs a function name}"
    shift
    "$fn" "$@"
    exit $?
fi

main "$@"
