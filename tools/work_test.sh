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
# The Sprite's half, played from $FAKE: `out` is the run's whole output,
# `status` its exit status once `ending` attaches have passed; `cut` makes
# the next attach deliver that many bytes and drop; `lost` makes the
# Sprite stop answering after the next attach; `live` names a run that stands.
if [ -n "${FAKE:-}" ]; then
    a="$*"
    while [ "$#" -gt 0 ] && [ "$1" != avra-remote ]; do shift; done
    if [ "$#" -gt 2 ]; then
        verb=$3
        shift 3
        echo "$verb $*" | cut -c1-60 >> "$FAKE/calls"
        case $verb in
            ready | status) echo "holds=yes"; [ ! -f "$FAKE/live" ] || echo "run=$(cat "$FAKE/live") live host 1 x" ;;
            start) echo "started=$1" ;;
            attach)
                [ ! -f "$FAKE/hang" ] || sleep 30
                if [ -f "$FAKE/cut" ]; then
                    n=$(cat "$FAKE/cut"); rm -f "$FAKE/cut"
                    tail -c +$(($2 + 1)) "$FAKE/out" | head -c "$n"
                    exit 1
                fi
                tail -c +$(($2 + 1)) "$FAKE/out"
                ;;
            result)
                [ ! -f "$FAKE/lost" ] || exit 1
                n=$(cat "$FAKE/ending" 2>/dev/null || echo 0)
                if [ "$n" -gt 0 ]; then echo $((n - 1)) > "$FAKE/ending"; echo running; else echo "status $(cat "$FAKE/status")"; fi
                ;;
            stop) echo 143 > "$FAKE/status"; rm -f "$FAKE/hang" ;;
        esac
        exit 0
    fi
    set -- $a
fi
[ -z "${SPRITE_LOG:-}" ] || echo "$*" >> "$SPRITE_LOG"
case "$*" in
    *"ls -t /home/sprite/avra-compilers"*) case " ${HOLDERS:-} " in *" $2 "*) echo /home/sprite/avra-compilers/h/avra ;; esac ;;
    *"cat > "*) cat > /dev/null ;;
esac
exit 0
STUB
cat > "$scratch/gh" <<'STUB'
#!/bin/sh
echo "$*" >> "$GH_LOG"
case "$*" in
    *"run list --workflow checks"*) [ -z "${CI_RUN:-}" ] || echo "$CI_RUN ${CI_SHA:-0000000}" ;;
    *"run download"*) [ -n "${CI_RUN:-}" ] || exit 1; while [ "$1" != -D ]; do shift; done; echo binary > "$2/avra" ;;
    *"pr list --state open"*) printf '7\tPR_7\tlane-a\tsuccess\ta title\n' ;;
    *dequeuePullRequest*) ;;
    *enqueuePullRequest*) echo "queued at position 1" ;;
    *mergeQueueEntry*) [ -z "${QUEUED:-}" ] || echo "$QUEUED" ;;
    *"run list"*) [ -z "${TRAINS:-}" ] || echo "$TRAINS" ;;
esac
STUB
chmod +x "$scratch/sprite" "$scratch/gh"
export AVRA_WAKE_S=3 AVRA_HEALTH_S=3
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

# ══ MOVE: a named bind on a bound lane moves it, cleanly or not at all
(cd "$scratch/avra-one" && sh "$work" bind B) > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-one")" "1 A" "work bind <sprite>: a Sprite another lane holds is refused, and the lane keeps its own" "$scratch/out"
(cd "$scratch/avra-two" && sh "$work" done) > /dev/null 2>&1
git -C "$main" worktree add -q -b two-again "$scratch/avra-two" main
gd=$(git -C "$scratch/avra-one" rev-parse --absolute-git-dir)
echo "$$ $(LC_ALL=C ps -o lstart= -p $$ | tr -s ' ' '_')" > "$gd/avra-run"
(cd "$scratch/avra-one" && sh "$work" bind B) > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-one")" "1 A" "work bind <sprite>: a lane with a run going does not move" "$scratch/out"
rm -f "$gd/avra-run"
(cd "$scratch/avra-one" && SILENT=B sh "$work" bind B) > "$scratch/out" 2>&1
check "$? $(holder "$scratch/avra-one")" "1 A" "work bind <sprite>: it does not move to a Sprite that does not answer" "$scratch/out"
(cd "$scratch/avra-one" && sh "$work" bind B) > "$scratch/out" 2>&1
(cd "$scratch/avra-two" && sh "$work" bind) >> "$scratch/out" 2>&1
check "$(holder "$scratch/avra-one") $(holder "$scratch/avra-two") $(grep -c 'holds B — A is free' "$scratch/out")" "B A 1" "work bind <sprite>: the lane moves, and the Sprite it left goes to the next lane" "$scratch/out"
(cd "$scratch/avra-one" && sh "$work" bind A) > /dev/null 2>&1
(cd "$scratch/avra-two" && sh "$work" bind B && cd "$scratch/avra-one" && sh "$work" bind A) > "$scratch/out" 2>&1
check "$(holder "$scratch/avra-one") $(holder "$scratch/avra-two")" "B A" "work bind <sprite>: two lanes cannot swap through each other — each keeps what it holds" "$scratch/out"
(cd "$scratch/avra-two" && rm -f "$(git rev-parse --absolute-git-dir)/avra-sprite"; cd "$scratch/avra-one" && sh "$work" bind A; cd "$scratch/avra-two" && sh "$work" bind) > /dev/null 2>&1

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

# ══ BUSY IS NOT UNREACHABLE, and a held Sprite is its lane's ══════════
(cd "$scratch/avra-after" && sh "$work" bind A) > /dev/null 2>&1
gd=$(git -C "$scratch/avra-after" rev-parse --absolute-git-dir)
echo "$$ $(LC_ALL=C ps -o lstart= -p $$ | tr -s ' ' '_')" > "$gd/avra-run"
(cd "$main" && SILENT="A B" sh "$work" sprites) > "$scratch/out" 2>&1
check "$(grep -c '^A  *BUSY' "$scratch/out") $(grep -c '^B  *NO ' "$scratch/out")" "1 1" "work sprites: a silent Sprite whose lane has a run going is BUSY, one with none is NO" "$scratch/out"
(cd "$main" && sh "$work" sprites --fix A) > "$scratch/out" 2>&1
check "$(grep -c 'A is running something for lane avra-after — left alone' "$scratch/out")" 1 "work sprites --fix: a Sprite with a run going is left alone even when named" "$scratch/out"
rm -f "$gd/avra-run"
(cd "$main" && sh "$work" sprites --fix) > "$scratch/out" 2>&1
check "$(grep -c 'A is held by lane avra-after — left alone' "$scratch/out")" 1 "work sprites --fix: unnamed, it passes by a Sprite a lane holds, and says so" "$scratch/out"

# ══ THE FIRST BUILD'S START: main's compiler, else a free Sprite's, else the seed
export SPRITE_LOG="$scratch/sprite.log"
seeded() { : > "$SPRITE_LOG"; (cd "$main" && "$@" sh "$work" seed B /tree "$main" HASH) > "$scratch/out" 2>&1; }
seeded env CI_RUN=41 HOLDERS=C AVRA_SPRITES="A B C"
check "$(grep -c "starts from main's compiler at 0000000$" "$scratch/out") $(grep -c -- '-s B exec.*cat > ./tree/build/avra' "$SPRITE_LOG") $(grep -c 'avra-compilers' "$SPRITE_LOG")" "1 1 0" "work seed: main's own compiler is fetched and handed to the Sprite; no other Sprite is asked" "$scratch/out"
seeded env CI_RUN=41 CI_SHA="$(git -C "$main" rev-parse HEAD)" AVRA_SPRITES="A B C"
check "$(grep -c 'which is this tree.s — nothing to build' "$scratch/out") $(grep -c 'printf %s .HASH. > ./tree/build/.avra-compiler-hash' "$SPRITE_LOG")" "1 1" "work seed: when the tree's compiler sources are that run's, its compiler is the tree's and is marked so" "$scratch/out"
echo change >> "$main/Makefile"
seeded env CI_RUN=41 CI_SHA="$(git -C "$main" rev-parse HEAD)" AVRA_SPRITES="A B C"
check "$(grep -c 'nothing to build' "$scratch/out") $(grep -c 'avra-compiler-hash' "$SPRITE_LOG")" "0 0" "work seed: one edit to a compiler source and it is only a start, never marked as the tree's" "$scratch/out"
rm -f "$main/Makefile"
seeded env HOLDERS="A C" AVRA_SPRITES="A B C"
check "$(grep -c "starts from C's newest compiler" "$scratch/out") $(grep -c -- '-s A exec' "$SPRITE_LOG")" "1 0" "work seed: with no CI compiler it copies a free Sprite's, never one a lane holds" "$scratch/out"
seeded env AVRA_SPRITES="A B C"
check "$(grep -c 'bootstrapping from the seed' "$scratch/out") $(grep -c 'cat > ' "$SPRITE_LOG")" "1 0" "work seed: with neither, it says the Sprite bootstraps and hands it nothing" "$scratch/out"
unset SPRITE_LOG

# ══ HELP: asked after any verb it prints that verb's line, and touches nothing
export SPRITE_LOG="$scratch/sprite.log"
: > "$SPRITE_LOG"; : > "$GH_LOG"
before=$(git -C "$main" worktree list | wc -l)
cd "$scratch/avra-after" || exit 1
for v in new run test land status sprites done bind wait attach stop; do
    for h in -h --help help; do
        sh "$work" "$v" "$h" > "$scratch/out" 2> "$scratch/err"
        st=$?
        [ "$st" = 0 ] && [ "$(wc -l < "$scratch/out" | tr -d ' ')" = 1 ] && grep -q "^usage: sh tools/work $v" "$scratch/out" && [ ! -s "$scratch/err" ] ||
            { echo "$v $h -> $st" >> "$scratch/helpfail"; cat "$scratch/out" "$scratch/err" >> "$scratch/helpfail"; }
    done
done
[ -d "$scratch/avra-after" ] && lane=stands || lane=gone
check "$(cat "$scratch/helpfail" 2>/dev/null | head -n 3 | tr '\n' ' ')|$(cat "$SPRITE_LOG" "$GH_LOG" | wc -l | tr -d ' ')|$lane|$(($(git -C "$main" worktree list | wc -l) - before))" "|0|stands|0" "work <verb> -h/--help/help: one usage line, exit 0, and no Sprite, no GitHub, no worktree is touched" "$scratch/helpfail"
for h in "" -h --help help; do sh "$work" $h > "$scratch/out.$total.$h" 2>&1 || echo "bare '$h' failed" >> "$scratch/helpfail"; done
check "$(cat "$scratch/helpfail" 2>/dev/null | wc -l | tr -d ' ') $(grep -c 'sh tools/work' "$scratch/out.$total.")" "0 7" "work, bare or asked for help: the seven verbs, exit 0" "$scratch/helpfail"
sh "$work" run --verbose true > "$scratch/out" 2>&1
check "$? $(grep -c 'has no flag .--verbose' "$scratch/out") $(grep -c '^usage: sh tools/work run' "$scratch/out") $(cat "$SPRITE_LOG" | wc -l | tr -d ' ')" "64 1 1 0" "work run: a flag it does not know is refused with the usage and 64, and nothing runs" "$scratch/out"
sh "$work" run --for soon true > "$scratch/out" 2>&1
st=$?
sh "$work" run > "$scratch/out2" 2>&1
check "$st $? $(cat "$SPRITE_LOG" | wc -l | tr -d ' ')" "64 64 0" "work run: a --for that is no number, and no command at all, are refused the same way" "$scratch/out"
sh "$work" frobnicate > "$scratch/out" 2>&1
check "$? $(grep -c 'no verb .frobnicate' "$scratch/out")" "64 1" "work: an unknown verb is named, with the usage and 64" "$scratch/out"
unset SPRITE_LOG

# ══ A RUN IS FOLLOWED, NOT HELD: drops, a lost Sprite, a bound, a run that stands
mkdir -p "$scratch/bin" "$scratch/fake"
printf '#!/bin/sh\necho "$*" >> "$FAKE/rsync"\n' > "$scratch/bin/rsync"
chmod +x "$scratch/bin/rsync"
cd "$scratch/avra-after" || exit 1
(sh "$work" bind A) > /dev/null 2>&1
ran() { PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" sh "$work" run "$@" > "$scratch/out" 2> "$scratch/err"; }
scene() { rm -f "$scratch"/fake/*; printf 'one\ntwo\nthree\n' > "$scratch/fake/out"; echo "$1" > "$scratch/fake/status"; }

scene 7; echo 1 > "$scratch/fake/ending"; echo 6 > "$scratch/fake/cut"
ran true
check "$? $(tr '\n' ' ' < "$scratch/out")| $(grep -c 'connection dropped (1 so far' "$scratch/err") $(grep -c '^attach .* 6$' "$scratch/fake/calls")" "7 one two three | 1 1" "work run: a connection dropped mid-run is followed again from its byte: every line once, the command's status" "$scratch/err"

scene 5; echo 0 > "$scratch/fake/cut"
ran true
check "$? $(tr '\n' ' ' < "$scratch/out")" "5 one two three " "work run: a connection dropped after the run ended still delivers its output and its status" "$scratch/err"

scene 124
ran --for 1 true
check "$? $(grep -c 'STOPPED: the command passed its bound' "$scratch/err")" "124 1" "work run: a run the Sprite ended at its bound answers 124 and says so" "$scratch/err"

scene 0; echo Other-9 > "$scratch/fake/live"
ran true
check "$? $(grep -c 'BUSY — A still runs Other-9.*work attach.*work stop' "$scratch/err") $(cat "$scratch/fake/rsync" 2>/dev/null | wc -l | tr -d ' ') $(grep -c '^start' "$scratch/fake/calls")" "76 1 0 0" "work run: a Sprite with a run standing is BUSY — nothing is synced under it, nothing started" "$scratch/err"

scene 0; echo 9 > "$scratch/fake/ending"; : > "$scratch/fake/lost"; echo 3 > "$scratch/fake/cut"
ran true
check "$? $(grep -c 'stopped answering.*the run goes on there.*work attach' "$scratch/err") $(grep -c '^stop' "$scratch/fake/calls")" "75 1 0" "work run: a Sprite that stops answering mid-run is 75, the run left to go on, never stopped" "$scratch/err"

scene 0; echo 99 > "$scratch/fake/ending"; : > "$scratch/fake/hang"
PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" sh "$work" run true > "$scratch/out" 2> "$scratch/err" &
job=$!
i=0; while [ "$i" -lt 50 ] && ! grep -q '^attach' "$scratch/fake/calls" 2>/dev/null; do sleep 0.2; i=$((i + 1)); done
kill -TERM "$job"; wait "$job"
check "$? $(grep -c '^stop' "$scratch/fake/calls") $([ -f "$(git rev-parse --absolute-git-dir)/avra-run" ] && echo locked || echo free)" "143 1 free" "work run: a TERM stops the run on the Sprite and frees the lane" "$scratch/err"

scene 3; echo Mine-1 > "$scratch/fake/live"
PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" sh "$work" attach > "$scratch/out" 2> "$scratch/err"
check "$? $(tr '\n' ' ' < "$scratch/out")| $(grep -c 'following Mine-1 (live)' "$scratch/err")" "3 one two three | 1" "work attach: follows the lane's run from its first byte and answers its status" "$scratch/err"
PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" sh "$work" stop > "$scratch/out" 2>&1
check "$(grep -c 'Mine-1 stopped' "$scratch/out") $(grep -c '^stop Mine-1' "$scratch/fake/calls")" "1 1" "work stop: ends the lane's live run by name"
cd "$main" || exit 1

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
