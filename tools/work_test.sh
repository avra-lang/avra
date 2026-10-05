#!/bin/sh
# FIXTURES FOR tools/work's lanes and its queue watch — no Sprite and no
# GitHub: a scratch repository with its own origin, AVRA_SPRITES naming a
# pool of two, AVRA_SPRITE_CLI standing in for `sprite` (the names in
# SILENT do not answer) and AVRA_GH for `gh`.
#
# `sh tools/work_test.sh` prints a summary; a non-zero exit is a failure.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
scratch=$(mktemp -d "${TMPDIR:-/tmp}/avra-work-test.XXXXXX")
scratch=$(cd "$scratch" && pwd -P)
trap 'rm -rf "$scratch"' EXIT
trap 'exit 130' INT TERM

total=0
failed=0
ok() { total=$((total + 1)); echo "ok    $1"; }
bad() { total=$((total + 1)); failed=$((failed + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && sed 's/^/      | /' "$2" 2>/dev/null; }
check() { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3 (got '$1', wanted '$2')" "${4:-}"; fi; }

# The scratch repository: origin, a main checkout carrying the tools
# under test, and room beside it for lanes.
git init -q --bare "$scratch/origin.git"
git init -q -b main "$scratch/avra"
main=$scratch/avra
mkdir -p "$main/tools" "$main/.github/ci"
cp "$here/work" "$here/sprite-lib.sh" "$here/sprite-remote.sh" "$here/sprite-rsh.sh" "$main/tools/"
cp "$here/../.github/ci/packages.txt" "$main/.github/ci/"
git -C "$main" add -A
git -C "$main" -c user.name=t -c user.email=t@t commit -q -m seed
git -C "$main" remote add origin "$scratch/origin.git"
git -C "$main" push -q -u origin main
work="$main/tools/work"

cat > "$scratch/sprite" <<'STUB'
#!/bin/sh
# sprite -s <name> exec … : answers unless the name is in SILENT.
case " ${SILENT:-} " in *" $2 "*) exit 1 ;; esac
exit 0
STUB
cat > "$scratch/gh" <<'STUB'
#!/bin/sh
echo "$*" >> "$GH_LOG"
case "$*" in
    *"pr list --state open"*) printf '7\tPR_7\tlane-a\tsuccess\ta title\n' ;;
    *dequeuePullRequest*) ;;
    *enqueuePullRequest*) echo "queued at position 1" ;;
    *mergeQueueEntry*) [ -z "${QUEUED:-}" ] || echo "$QUEUED" ;;
    *"run list"*) [ -z "${TRAINS:-}" ] || echo "$TRAINS" ;;
esac
STUB
chmod +x "$scratch/sprite" "$scratch/gh"
export AVRA_SPRITE_CLI="$scratch/sprite" AVRA_SPRITES="A B" AVRA_GH="$scratch/gh" GH_LOG="$scratch/gh.log"
unset SILENT QUEUED TRAINS

holder() { cat "$(git -C "$1" rev-parse --absolute-git-dir)/avra-sprite" 2>/dev/null; }

# ══ NEW: a lane and its Sprite ════════════════════════════════════════
sh "$work" new one > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-one")" "0 A" "work new: the lane stands and holds the first free Sprite" "$scratch/out"
sh "$work" new two > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-two")" "0 B" "work new: the second lane holds the next one" "$scratch/out"

# ══ ALL BOUND: the next lane is refused, the holders named ════════════
sh "$work" new three > "$scratch/out" 2>&1
st=$?
[ -e "$scratch/avra-three" ] && stands=stands || stands=absent
check "$st $stands $(grep -c 'avra-one\|avra-two' "$scratch/out")" "1 absent 2" "work new: with every Sprite bound it refuses, names both lanes and makes no worktree" "$scratch/out"

# ══ BIND: idempotent, and one Sprite never serves two lanes ═══════════
(cd "$scratch/avra-one" && sh "$work" bind) > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-one")" "0 A" "work bind: a lane that holds a Sprite keeps it"
git -C "$main" worktree add -q -b loose "$scratch/avra-loose" main
(cd "$scratch/avra-loose" && sh "$work" bind) > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-loose")" "1 " "work bind: with none free it refuses and binds nothing" "$scratch/out"

# ══ DONE: the lane goes, its Sprite is free ═══════════════════════════
(cd "$scratch/avra-two" && sh "$work" done) > "$scratch/out" 2>&1
st=$?
[ -e "$scratch/avra-two" ] && stands=stands || stands=absent
(cd "$scratch/avra-loose" && sh "$work" bind) >> "$scratch/out" 2>&1
check "$st $stands $(holder "$scratch/avra-loose")" "0 absent B" "work done: the worktree is removed and its Sprite goes to the next lane" "$scratch/out"

# ══ A DELETED WORKTREE: its binding holds nothing ═════════════════════
mv "$scratch/avra-one" "$scratch/gone"
git -C "$main" worktree add -q -b after "$scratch/avra-after" main
(cd "$scratch/avra-after" && sh "$work" bind) > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-after")" "0 A" "work bind: a Sprite bound to a worktree that is gone is free" "$scratch/out"

# ══ A SILENT SPRITE: never bound while it does not answer ═════════════
(cd "$scratch/avra-after" && rm -f "$(git rev-parse --absolute-git-dir)/avra-sprite" && SILENT=A sh "$work" bind) > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-after")" "1 " "work bind: a free Sprite that does not answer is not bound" "$scratch/out"

# ══ THE RACE: two lanes, one free Sprite, one winner ══════════════════
git -C "$main" worktree add -q -b race "$scratch/avra-race" main
(cd "$scratch/avra-after" && sh "$work" bind) > "$scratch/out.1" 2>&1 &
(cd "$scratch/avra-race" && sh "$work" bind) > "$scratch/out.2" 2>&1 &
wait
check "$(echo $(holder "$scratch/avra-after") $(holder "$scratch/avra-race"))" "A" "work bind: of two lanes binding at once, one holds the Sprite" "$scratch/out.1"

# ══ RUN: a lane with no Sprite is told the one command ════════════════
(cd "$scratch/avra-race" && rm -f "$(git rev-parse --absolute-git-dir)/avra-sprite" && sh "$work" run true) > "$scratch/out" 2>&1
check "$? $(grep -c 'tools/work bind' "$scratch/out")" "1 1" "work run: a worktree with no Sprite is refused, with the command that binds one" "$scratch/out"

# ══ THE QUEUE: a PR queued with no train is taken out and put back ════
cd "$main" || exit 1
: > "$GH_LOG"
QUEUED="2 400" TRAINS= sh "$work" status > "$scratch/out" 2>&1
check "$(grep -c dequeuePullRequest "$GH_LOG") $(grep -c enqueuePullRequest "$GH_LOG") $(grep -c 'NO TRAIN for 400s' "$scratch/out") $(grep -c 'queueing it again' "$scratch/out")" "1 1 1 1" "work status: a PR queued 400 s with no train is requeued, and it says so" "$scratch/out"
: > "$GH_LOG"
QUEUED="2 400" TRAINS="gh-readonly-queue/main/pr-7-abc" sh "$work" status > "$scratch/out" 2>&1
check "$(grep -c dequeuePullRequest "$GH_LOG") $(grep -c 'train running' "$scratch/out")" "0 1" "work status: one a train carries is left alone" "$scratch/out"
: > "$GH_LOG"
QUEUED="2 60" TRAINS="gh-readonly-queue/main/pr-70-abc" sh "$work" status > "$scratch/out" 2>&1
check "$(grep -c dequeuePullRequest "$GH_LOG")" 0 "work status: one queued a minute is given its time; another PR's train is not its own" "$scratch/out"
: > "$GH_LOG"
QUEUED= sh "$work" status > "$scratch/out" 2>&1
check "$(grep -c dequeuePullRequest "$GH_LOG") $(grep -c '#7  lane-a  open' "$scratch/out")" "0 1" "work status: a PR outside the queue is only shown" "$scratch/out"

echo "----------------------------------------"
echo "work_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]
