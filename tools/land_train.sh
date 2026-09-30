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
# verifies every candidate IN ONE WAVE, concurrently, up to two per Sprite
# — never one Mac bisecting them one attempt at a time. A wave's
# verdict is the longest all-green PREFIX; a red candidate drops its
# OWN branch (never an earlier one — a prefix that already answered
# green stays trusted) and a NEW wave verifies the tail again, on top
# of the now-shorter good prefix. This repeats until a wave is wholly
# green (the train lands `good_branches`, `good_head`) or the tail is
# empty (nothing left to land).
#
# ONE WATCHDOG, NEVER TWO: every remote step runs through land.sh's
# OWN `watched()` (cap + no-progress quiet window, one poll loop) via
# its `--call` seam — this file defines no timeout primitive of its
# own. The Sprite POOL and its ORDERING are shared too:
# `sh "$land" --call sprites_by_load $(pool_list)` ranks the pool by
# load per core then free memory, and `pool_list` answers
# `AVRA_LAND_SPRITE` when set, else `tools/sp --pool` — every awake
# Sprite but avra-bench and web-terminal, the same pool `sp` jobs use.
# What THIS file adds beyond those primitives is EXCLUSIVITY across
# several CONCURRENT candidates: a lease is one of `sp`'s own slots
# (`sp --lease`, in its shared slot directory), up to
# AVRA_LAND_TRAIN_SLOTS (default 2) per Sprite, so train candidates and
# `sp` jobs never oversubscribe one Sprite. Each candidate syncs into
# its own remote tree, since sprite-build.sh keys the tree by the
# candidate worktree's unique name.
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
# throwaway worktree+branch under this run's scratch dir, named with
# THIS run's own id so two overlapping trains never collide on the
# same Sprite-side synced-tree slug. The one function that would move
# main (`train_core`, called FROM land.sh, which already holds the
# FIFO lock) is exercised only by fixtures and by land.sh's own opt-in
# hand-off — never by this file's own `main()`, which always stops at
# printing the winning candidate. An INT/TERM here frees every
# candidate worktree, stops every in-flight remote run, and kills this
# run's own local job tree before exiting — mirroring land.sh's own
# trap shape (`train_interrupt`, below) so a killed train leaves
# nothing running on a Sprite for nobody.
set -eu

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
tools_dir="$(dirname "$self")"
land="$tools_dir/land.sh"

: "${AVRA_LAND_SPRITE_BUILD:=$tools_dir/sprite-build.sh}"
# watched()'s own cap_s/quiet_s, named to match land.sh's
# AVRA_LAND_LINUX_CAP_S/_QUIET_S convention. MEASURED against a real
# Sprite (docs/2026_09_29_LAND_TRAIN.md's proof run): a 90s quiet
# window killed a healthy cold wake-and-sync outright (sprite_ready's
# own retry ceiling is 120s, before the tree sync or the first push
# ever prints a byte); 420s clears that with room left, while still
# catching a step that is ACTUALLY wedged (silent for the rest of the
# cap, never just a few extra minutes).
: "${AVRA_LAND_TRAIN_CAP_S:=1200}"
: "${AVRA_LAND_TRAIN_QUIET_S:=420}"
: "${AVRA_LAND_TRAIN_RETRIES:=2}"
: "${AVRA_LAND_TRAIN_SLOTS:=2}"
sp="$tools_dir/sp"

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
concurrently (up to AVRA_LAND_TRAIN_SLOTS per Sprite), and prints the winning green prefix
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

# ── THE SPRITE POOL — sp's pool, main's load order, sp's slots ─────
# `AVRA_LAND_SPRITE` overrides exactly as it already does for
# `linux_gate_step`; unset, `sp --pool` answers, asked once per run and
# kept in the scratch dir. An empty answer (the Sprites API down) falls
# back to land.sh's `land_pool`, so this file names no Sprite of its own.
pool_list() {
    if [ -n "${AVRA_LAND_SPRITE:-}" ]; then
        printf '%s' "$AVRA_LAND_SPRITE"
        return 0
    fi
    [ -s "$scratch/pool" ] || {
        p="$(sh "$sp" --pool 2>/dev/null || true)"
        [ -n "$(printf '%s' "$p" | tr -d '[:space:]')" ] || p="$(sh "$land" --call land_pool)"
        printf '%s' "$p" > "$scratch/pool"
    }
    cat "$scratch/pool"
}

# Blocks until a Sprite in the pool has a FREE slot (`sp --lease`,
# owned by this train's process, so a dead train frees it) and is ranked reachable by main's own `sprites_by_load` (an unreachable
# one sorts last, never first) — a Sprite that never answers is what
# `run_candidate`'s own retry-on-tool-failure exists for, so this
# never waits past its OWN deadline. `$2`, optional: Sprites this
# CANDIDATE already tried and failed on — a retry prefers any OTHER
# Sprite first, and only falls back to one of them once every other
# pool member is busy, so a small pool never deadlocks avoiding one.
# Slots fill level by level, so a wave spreads before it stacks. Prints
# "<sprite> <slot dir>".
claim_sprite() {
    deadline="$1"
    avoid="${2:-}"
    # THE ORDER IS CACHED, NEVER RE-PROBED EVERY SECOND: a wave with
    # several candidates all waiting on a busy pool would otherwise
    # have EVERY ONE of them fork `sprites_by_load`'s own per-Sprite
    # probes on EVERY 1s poll — a multiplier that gets WORSE exactly
    # when the machine is already the most loaded (a real load spike
    # measured writing this: 122+ while several waiters re-probed in
    # lockstep). Refreshed only every AVRA_LAND_TRAIN_PROBE_INTERVAL_S
    # seconds (default 10) — stale for at most that long, which only
    # ever costs picking a slightly-less-idle Sprite, never a wrong
    # answer about which ones are FREE (that check is the slot
    # directory, read fresh every iteration, never cached).
    probe_interval="${AVRA_LAND_TRAIN_PROBE_INTERVAL_S:-10}"
    ordered=""
    ordered_at=0
    while :; do
        now="$(date +%s)"
        if [ -z "$ordered" ] || [ $((now - ordered_at)) -ge "$probe_interval" ]; then
            ordered="$(sh "$land" --call sprites_by_load $(pool_list) 2>/dev/null)"
            ordered_at="$now"
        fi
        fresh=""
        for s in $ordered; do
            case " $avoid " in *" $s "*) ;; *) fresh="$fresh $s" ;; esac
        done
        for list in "$fresh" "$ordered"; do
            [ -n "$(printf '%s' "$list" | tr -d '[:space:]')" ] || continue
            slot="$(sh "$sp" --lease "$AVRA_LAND_TRAIN_SLOTS" "$$" $list 2>/dev/null)" &&
                { echo "$(basename "$(dirname "$slot")") $slot"; return 0; }
        done
        [ "$now" -lt "$deadline" ] || return 1
        sleep 1
    done
}
release_sprite() { rm -rf "$1"; }

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
# the same convention `linux_gate_step`'s `land-linux: body started`
# is; the heartbeat (every 30s, a byte count over every log this body
# writes, then the CPU ticks the body's process tree has spent, the
# heartbeat's own excluded) is `train_progress`'s (tools/land.sh) own
# signal, read by `watched()` exactly as `linux_progress` reads
# `linux_gate_step`'s. A suite prints nothing while it builds, for
# longer than the quiet window, so bytes alone would call it wedged;
# a wedged step spends no CPU, so the ticks still stop. Suites run
# line-buffered, so their own lines reach the log as they are said.
candidate_body() {
    pkgs="$*"
    cat <<BODY
echo 'land-train: body started'
d=\$(mktemp -d)
tree() { [ "\$1" = "\${skip:-}" ] && return; echo "\$1"; for c in \$(ps -o pid= --ppid "\$1" 2>/dev/null); do tree "\$c"; done; }
cpu() { for p in \$(tree \$\$); do sed 's/.*) //' "/proc/\$p/stat" 2>/dev/null; done | awk '{ s += \$12 + \$13 + \$14 + \$15 } END { print s + 0 }'; }
( skip=\$BASHPID; while sleep 30; do echo "land-train: progress \$(cat "\$d"/*.log 2>/dev/null | wc -c) cpu \$(cpu)"; done ) &
hb=\$!
trap 'pkill -P \$hb 2>/dev/null; kill \$hb 2>/dev/null' EXIT
export LLVM_PREFIX=/usr/lib/llvm-22
lined=
command -v stdbuf >/dev/null && lined="stdbuf -oL -eL"
run_step() {
    n="\$1"; shift
    t=\$(date +%s)
    if "\$@" > "\$d/step-\$n.log" 2>&1; then
        echo "land-train: \$n OK \$(( \$(date +%s) - t ))s"
    else
        st=\$?
        echo "land-train: \$n FAILED (exit \$st) \$(( \$(date +%s) - t ))s"
        tail -60 "\$d/step-\$n.log"
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
for p in $pkgs; do
    ( t=\$(date +%s); \$lined build/avra test "packages/\$p" > "\$d/\$p.log" 2>&1; echo \$? > "\$d/\$p.st"; \
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

# ── ONE CANDIDATE, DISPATCHED THROUGH land.sh's `watched()` ─────────
# Writes `$3/status` (0/1) and `$3/log`. `watched`'s three outcomes,
# in the SAME priority `linux_gate_step` reads them: 125 (no progress)
# or 124 (past the cap) NEVER settle a verdict — the Sprite is told to
# stop the remote run (`stop_remote`) and another is tried; only once
# neither applies does a missing `body started` marker mean a TOOL
# failure (retried, up to AVRA_LAND_TRAIN_RETRIES times, before the
# CANDIDATE itself is marked unbuildable) and a present one hand back
# the body's own real exit status — the branch's own concern from
# there on.
run_candidate() {
    tree="$1"
    label="$2"
    out_dir="$3"
    pkgs="$4"
    mkdir -p "$out_dir"
    tried=""
    attempt=0
    cap_s="$AVRA_LAND_TRAIN_CAP_S"
    quiet_s="$AVRA_LAND_TRAIN_QUIET_S"
    while :; do
        attempt=$((attempt + 1))
        deadline=$(( $(date +%s) + cap_s ))
        claimed="$(claim_sprite "$deadline" "$tried")" || {
            echo "no Sprite in the pool became free within ${cap_s}s" > "$out_dir/tool-failure"
            echo 1 > "$out_dir/status"
            return 1
        }
        sprite="${claimed%% *}"
        slot="${claimed#* }"
        tried="$tried $sprite"
        echo "$sprite" > "$scratch/inflight-$label"
        body_file="$scratch/body-$label.sh"
        candidate_body $pkgs > "$body_file"
        log="$out_dir/attempt-$attempt.log"
        st=0
        train_out="$log" sh "$land" --call watched "$cap_s" "$quiet_s" train_progress \
            sh "$AVRA_LAND_SPRITE_BUILD" "$sprite" "$tree" -- bash -lc "$(cat "$body_file")" > "$log" 2>&1 || st=$?
        rm -f "$scratch/inflight-$label"
        release_sprite "$slot"
        if [ "$st" -eq 125 ]; then
            echo "land-train: [$label] no progress on $sprite for $((quiet_s / 60)) min — retrying" >&2
            sh "$land" --call stop_remote "$sprite" "$label"
        elif [ "$st" -eq 124 ]; then
            echo "land-train: [$label] $sprite ran past the $((cap_s / 60)) min cap — retrying" >&2
            sh "$land" --call stop_remote "$sprite" "$label"
        elif grep -q '^land-train: body started' "$log" 2>/dev/null; then
            echo "$st" > "$out_dir/status"
            cp "$log" "$out_dir/log"
            echo "$sprite" > "$out_dir/sprite"
            return 0
        else
            echo "land-train: [$label] Sprite $sprite failed before the command ran (exit $st, attempt $attempt) — $log" >&2
        fi
        if [ "$attempt" -gt "$AVRA_LAND_TRAIN_RETRIES" ]; then
            echo "no Sprite could run candidate $label (tried:$tried)" > "$out_dir/tool-failure"
            echo 1 > "$out_dir/status"
            return 1
        fi
    done
}

# ── ONE WAVE — every candidate for the given tail, launched together,
# bounded only by the pool's slots (claim_sprite blocks a launch until
# one is free). Prints, on stdout, the longest green
# PREFIX of `tail` (space-separated branch names; empty when even the
# first fails), and leaves per-candidate results under
# `$scratch/wave-$id/C<k>/`. Every candidate's label carries THIS
# run's own id, so its Sprite-side synced-tree slug (sprite-build.sh's
# `basename` of the local worktree path) never collides with another
# train's run of the same wave/candidate NUMBER.
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
            label="r$run_id-wave$wave_id-C$k"
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

# Every candidate worktree this run minted, removed through git's own
# door (never a bare `rm -rf` — that would leave `.git/worktrees/<x>`
# administrative state behind, which the next `git worktree add`
# reusing the same repo would then trip over). Logs and per-candidate
# status files under `$scratch` are NOT removed — a caller reads
# those after this returns (the winning head sha, every attempt's
# log), the same "keep the logs, drop everything else" split
# land.sh's own clean_own_scratch makes.
train_cleanup_candidates() {
    [ -d "$scratch/candidates" ] || return 0
    for wt in "$scratch/candidates"/*; do
        [ -e "$wt" ] || continue
        git -C "$main_wt" worktree remove -f "$wt" 2>/dev/null || rm -rf "$wt"
    done
}

# ── INTERRUPT CLEANUP — mirrors land.sh's own trap shape (`finish_lock`
# resumed-after-handler style; `release_lock_and_exit`'s signal-then-
# exit). A killed train: (1) kills its WHOLE local process tree — every
# child of this process, through land.sh's own `kill_tree` — since the
# wave and its candidates run in subshells whose pids this process
# never holds; each sprite-build stops its own remote group as it goes; (2) tells every Sprite it currently has a lease on to
# stop that candidate's remote run, through `stop_remote` — `run_candidate`
# records the (sprite, label) pair for exactly this window, in
# `$scratch/inflight-<label>`, removed the instant that candidate's own
# call returns; (3) removes every candidate worktree. Set once, for
# the whole process, wherever that process might be a train's own top
# level (`main`) or the ladder itself (`train_ladder`, called directly
# via `--call` from land.sh's `train_core`).
train_interrupt() {
    sig="$1"
    for p in $(pgrep -P $$); do
        sh "$land" --call kill_tree "$p" 2>/dev/null
    done
    for f in "$scratch"/inflight-*; do
        [ -f "$f" ] || continue
        lbl="$(basename "$f")"
        lbl="${lbl#inflight-}"
        sp="$(cat "$f" 2>/dev/null)" || sp=""
        [ -n "$sp" ] && sh "$land" --call stop_remote "$sp" "$lbl" 2>/dev/null
    done
    [ -n "${main_wt:-}" ] && train_cleanup_candidates 2>/dev/null
    case "$sig" in
        INT) exit 130 ;;
        *) exit 143 ;;
    esac
}
install_interrupt_trap() {
    trap 'train_interrupt INT' INT
    trap 'train_interrupt TERM' TERM
}

# ── THE FULL LADDER — repeat waves until the tail is empty or wholly
# green. Prints the final winning branch list (space-separated, FIFO
# order preserved) on stdout; every dropped branch is named
# "CULPRIT: <name>" on stderr, exactly as land.sh's own bisector names
# one, so a caller's existing log-scraping needs no new pattern. Every
# candidate WORKTREE is cleaned up before this returns, whatever the
# outcome — train_ladder_body never exits early without it.
train_ladder() {
    install_interrupt_trap
    st=0
    train_ladder_body "$@" || st=$?
    train_cleanup_candidates
    return "$st"
}
train_ladder_body() {
    resolve_main_wt
    good=""
    sieve="$scratch/candidates/sieve"
    rm -rf "$sieve"
    mkdir -p "$scratch/candidates"
    git -C "$main_wt" worktree add -q --detach "$sieve" main
    tail="$(sh "$land" --call conflict_sieve "$sieve" "$@")"
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
    install_interrupt_trap
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
