#!/bin/sh
# FIXTURES FOR tools/work's lanes and its PR state — no Sprite and no
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

. "$here/lib/checks.sh"

# The land guard's decision, proved on fixtures: the non-draft PRs of OTHER
# branches whose test check is still running.
midci_fn=$(sed -n '/^midci_of() {/,/^}$/p' "$here/work")
midci() { printf '%s' "$1" | sh -c "$midci_fn; midci_of mine"; }
check "$(midci '[{"number":5,"headRefName":"a","isDraft":false,"statusCheckRollup":[{"name":"test","status":"IN_PROGRESS"}]},{"number":6,"headRefName":"mine","isDraft":false,"statusCheckRollup":[{"name":"test","status":"IN_PROGRESS"}]},{"number":7,"headRefName":"d","isDraft":true,"statusCheckRollup":[{"name":"test","status":"IN_PROGRESS"}]},{"number":8,"headRefName":"e","isDraft":false,"statusCheckRollup":[{"name":"test","status":"COMPLETED"}]}]')" "#5" "land guard: names the other non-draft PR mid-CI, not its own branch, a draft, or a finished one"
check "$(midci '[{"number":9,"headRefName":"f","isDraft":false,"statusCheckRollup":[{"name":"gate","status":"IN_PROGRESS"},{"name":"test","status":"QUEUED"}]}]')" "#9" "land guard: a queued test check counts as mid-CI"
check "$(midci '[{"number":10,"headRefName":"g","isDraft":false,"statusCheckRollup":[]}]')" "" "land guard: a PR with no checks yet is not mid-CI"

# The scratch repository: origin, a main checkout carrying the tools
# under test, and room beside it for lanes.
git init -q --bare "$scratch/origin.git"
git init -q -b main "$scratch/avra"
main=$scratch/avra
mkdir -p "$main/tools" "$main/.github/ci"
cp "$here/work" "$here/compiler_paths.sh" "$here/sprite-lib.sh" "$here/sprite-remote.sh" "$here/sprite-rsh.sh" "$main/tools/"
# No fixture installs anything: the toolchain list is empty.
echo "# none" > "$main/.github/ci/packages.txt"
git -C "$main" add -A
git -C "$main" -c user.name=t -c user.email=t@t commit -q -m seed
git -C "$main" remote add origin "$scratch/origin.git"
git -C "$main" push -q -u origin main
work="$main/tools/work"

# WHAT A SPRITE MUST CARRY IS MAIN'S LIST: a lane branched before a package joined packages.txt has the
# older file, and provisioning or judging health by it leaves a Sprite without what newer trees need.
# A run installs main's list plus the checkout's own; health judges main's alone.
pk=$scratch/pk
git init -q --bare "$pk/origin.git"
git init -q -b main "$pk/lane"
mkdir -p "$pk/lane/tools" "$pk/lane/.github/ci"
cp "$here/sprite-lib.sh" "$pk/lane/tools/"
printf 'shared\nfrommain\n' > "$pk/lane/.github/ci/packages.txt"
git -C "$pk/lane" add -A && git -C "$pk/lane" -c user.name=t -c user.email=t@t commit -q -m main
git -C "$pk/lane" remote add origin "$pk/origin.git" && git -C "$pk/lane" push -q -u origin main
printf 'shared\nlocalonly\n' > "$pk/lane/.github/ci/packages.txt"
pkg_lists() { (here="$pk/lane/tools"; . "$here/sprite-lib.sh"; printf '%s|%s' "$(sprite_packages_list | tr ' ' '\n' | sort | tr '\n' ' ')" "$(health_packages_list | tr ' ' '\n' | sort | tr '\n' ' ')"); }
check "$(pkg_lists)" "frommain localonly shared |frommain shared " "packages: a run installs main's list plus the checkout's own; health judges main's alone, never the checkout's stale or extra lines"
printf 'webkitlib\n' > "$pk/lane/.github/ci/packages-browser.txt"
browser_list() { (here="$pk/lane/tools"; . "$here/sprite-lib.sh"; browser_packages_list | tr ' ' '\n' | sort | tr '\n' ' '); }
check "$(browser_list)" "webkitlib " "packages: the browser leg's libraries are a list of their own, never part of a run's or of health's"

cat > "$scratch/sprite" <<'STUB'
#!/bin/sh
# sprite -s <name> exec … : answers unless the name is in SILENT; the
# provider's own list answers unless OFFLINE is set.
case " ${SILENT:-} " in *" $2 "*) exit 1 ;; esac
if [ "$1" = api ]; then
    [ -z "${OFFLINE:-}" ] || exit 1
    echo "{\"data\":[{\"name\":\"A\",\"status\":\"${A_STATE:-running}\"},{\"name\":\"B\",\"status\":\"warm\"}]}"
    exit 0
fi
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
            ready | status) echo "holds=yes"; echo "disk_free_mb=2048"; echo "mem_avail_mb=7000"; [ ! -f "$FAKE/live" ] || echo "run=$(cat "$FAKE/live") live host 1 x $(cat "$FAKE/idle" 2>/dev/null)" ;;
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
                size=$(wc -c < "$FAKE/out" | tr -d ' ')
                if [ "$n" -gt 0 ]; then echo $((n - 1)) > "$FAKE/ending"; echo "running $size"; else echo "status $(cat "$FAKE/status") $size"; fi
                ;;
            stop) echo 143 > "$FAKE/status"; rm -f "$FAKE/hang" ;;
            # A Sprite the fake rsync "reached" holds the worktree it was asked about.
            manifest)
                shift
                sh -c 'AVRA_REMOTE_SCRIPT=$1; shift; eval "$AVRA_REMOTE_SCRIPT"' avra-remote "$(cat "$(dirname "$0")/avra/tools/sprite-remote.sh")" manifest "$(git rev-parse --show-toplevel)" "$@"
                ;;
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
    *"pr list --state open"*) printf '7\tlane-a\tarmed\tCLEAN\tsuccess\ta title\n' ;;
esac
STUB
chmod +x "$scratch/sprite" "$scratch/gh"
export AVRA_WAKE_S=3 AVRA_HEALTH_S=3
export AVRA_SPRITE_CLI="$scratch/sprite" AVRA_SPRITES="A B" AVRA_GH="$scratch/gh" GH_LOG="$scratch/gh.log"
unset SILENT

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
(cd "$scratch/avra-two" && sh "$work" done --remove-worktree) > /dev/null 2>&1
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

# ══ DONE REFUSES WITHOUT --remove-worktree, and UNBIND frees the Sprite and keeps the worktree
before=$(holder "$scratch/avra-two")
(cd "$scratch/avra-two" && sh "$work" done) > "$scratch/out" 2>&1
st=$?
[ -e "$scratch/avra-two" ] && stands=stands || stands=absent
check "$st $stands $(holder "$scratch/avra-two") $(grep -c 'REMOVES this worktree' "$scratch/out")" "1 stands $before 1" "work done: without --remove-worktree it refuses, says the worktree goes, and removes nothing" "$scratch/out"
(cd "$scratch/avra-two" && sh "$work" unbind) > "$scratch/out" 2>&1
st=$?
[ -e "$scratch/avra-two" ] && stands=stands || stands=absent
check "$st $stands $(holder "$scratch/avra-two" | tr -d ' ')" "0 stands " "work unbind: the Sprite is freed and the worktree stays" "$scratch/out"
(cd "$scratch/avra-two" && sh "$work" bind "$before") > /dev/null 2>&1

# ══ DONE: the lane goes, its Sprite is free ═══════════════════════════
(cd "$scratch/avra-two" && sh "$work" done --remove-worktree) > "$scratch/out" 2>&1
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

# ══ A NEW LANE'S LOCAL COMPILER: the one built from its tree, the nearest behind, or none
sl=$scratch/seedlab
git clone -q "$scratch/origin.git" "$sl/main" 2>/dev/null
mkdir -p "$sl/main/tools"
cp "$here/work" "$here/compiler_paths.sh" "$here/sprite-lib.sh" "$here/sprite-remote.sh" "$here/sprite-rsh.sh" "$sl/main/tools/"
slc() { git -C "$sl/main" -c user.name=t -c user.email=t@t "$@"; }
echo one > "$sl/main/Makefile"; slc add -A; slc commit -q -m one
old_at=$(slc rev-parse HEAD)
echo two > "$sl/main/Makefile"; slc commit -q -am two
slc update-ref refs/remotes/origin/main HEAD
slw="$sl/main/tools/work"
lane() { rm -rf "$sl/$1"; slc worktree prune; slc worktree add -q --detach "$sl/$1" "${2:-HEAD}"; }
holds() { lane held "${2:-HEAD}"; mkdir -p "$sl/held/build"; echo bin > "$sl/held/build/avra"; chmod +x "$sl/held/build/avra"; [ -z "$1" ] || echo "$1" > "$sl/held/build/.avra-built-from"; }
seeds() { lane fresh; (cd "$sl/main" && "$@" sh "$slw" seed-local "$sl/fresh") > "$scratch/out" 2>&1; [ -x "$sl/fresh/build/avra" ] && echo copied || echo none; }
holds ""
check "$(seeds env) $(grep -c 'starts with none' "$scratch/out")" "none 1" "work new: a compiler that does not say what it was built from is never copied" "$scratch/out"
holds "$(sh "$slw" compiler-hash "$sl/main") edited"
check "$(seeds env) $(grep -c 'it is this tree.s' "$scratch/out")" "copied 1" "work new: the compiler built from this tree's compiler source is taken, and said" "$scratch/out"
holds "somethingelse edited"
check "$(seeds env)" "none" "work new: a compiler built from a lane's own edits is never copied" "$scratch/out"
holds "olderhash $old_at" "$old_at"
check "$(seeds env) $(grep -c '1 compiler commit(s) behind' "$scratch/out")" "copied 1" "work new: failing that, the nearest behind origin/main is a start, and says how far" "$scratch/out"
check "$(seeds env AVRA_SEED_BEHIND=0) $(grep -c 'not copied' "$scratch/out")" "none 1" "work new: one past the bound is refused with the distance, never copied" "$scratch/out"

# THE DEPOT: a stamped compiler kept after its worktree is gone is a start too (a Mac has no published one).
dp=$scratch/depot
mkdir -p "$dp/h1"
echo bin > "$dp/h1/avra"; chmod +x "$dp/h1/avra"; echo "olderhash $old_at" > "$dp/h1/.avra-built-from"
holds ""
check "$(seeds env AVRA_COMPILER_DEPOT="$dp") $(grep -c '1 compiler commit(s) behind' "$scratch/out")" "copied 1" "work new: a stamped compiler in the depot is a start when no worktree holds one" "$scratch/out"
holds "somethingelse edited"
dp2=$scratch/depot2
check "$(seeds env AVRA_COMPILER_DEPOT="$dp2")" "none" "work new: an empty depot and an edited worktree compiler start none" "$scratch/out"
# deposit keeps a clean tree's stamped compiler, never an edited one, and only the newest AVRA_DEPOT_KEEP
holds "hashA $old_at"
AVRA_COMPILER_DEPOT="$dp2" sh "$slw" deposit "$sl/held"
holds "hashB edited"
AVRA_COMPILER_DEPOT="$dp2" sh "$slw" deposit "$sl/held"
check "$(ls "$dp2" | tr '\n' ' ')" "hashA " "work deposit: a clean stamped compiler is kept, one built from edits is not" "$scratch/out"
sleep 1
holds "hashC $old_at"
AVRA_DEPOT_KEEP=1 AVRA_COMPILER_DEPOT="$dp2" sh "$slw" deposit "$sl/held"
check "$(ls "$dp2" | tr '\n' ' ')" "hashC " "work deposit: only the newest AVRA_DEPOT_KEEP entries stay" "$scratch/out"

# THE BUILDER IS MATCHED BY COMPILER KEY: the merge-base's own key when published, else the nearest published
# ancestor key and how far back it is, else nothing. The fetch tool is a stub keyed by a file in each commit.
bk=$scratch/bk
git init -q -b main "$bk"
mkdir -p "$bk/tools"
cat > "$bk/tools/compiler_release.py" <<'STUB'
import os, subprocess, sys
if sys.argv[1] == "key-of":
    print("k-" + subprocess.check_output(["git", "show", sys.argv[2] + ":keyfile"], text=True).strip())
elif sys.argv[1] == "probe":
    sys.exit(0 if sys.argv[2] in open(os.environ["PUBLISHED"]).read().split() else 1)
STUB
bkg() { git -C "$bk" -c user.name=t -c user.email=t@t "$@"; }
echo old > "$bk/keyfile"; bkg add -A; bkg commit -q -m a
echo new > "$bk/keyfile"; bkg commit -q -am b
echo new > "$bk/keyfile2"; bkg add -A; bkg commit -q -m c
bkg update-ref refs/remotes/origin/main HEAD
echo k-old > "$scratch/published"
check "$(PUBLISHED="$scratch/published" sh "$slw" builder-key "$bk")" "k-old ancestor 2" "work builder-key: an unpublished key takes the nearest published ancestor, and says how far back" "$scratch/out"
printf 'k-old\nk-new\n' > "$scratch/published"
check "$(PUBLISHED="$scratch/published" sh "$slw" builder-key "$bk")" "k-new exact" "work builder-key: the merge-base's own key, published, is exact (a commit with no compiler change shares it)" "$scratch/out"
: > "$scratch/published"
check "$(PUBLISHED="$scratch/published" sh "$slw" builder-key "$bk")" "" "work builder-key: nothing published answers nothing" "$scratch/out"

# `compiler --get`: a held compiler for this source needs no build; none held and none published builds.
lane getme
mkdir -p "$sl/getme/build"; echo bin > "$sl/getme/build/avra"; chmod +x "$sl/getme/build/avra"
echo "$(sh "$slw" compiler-hash "$sl/getme") $(git -C "$sl/getme" rev-parse HEAD)" > "$sl/getme/build/.avra-built-from"
(cd "$sl/getme" && AVRA_GET_BUILD="echo BUILT >> $scratch/get-built" sh "$slw" compiler --get) > "$scratch/out" 2>&1
check "$(grep -c "this tree's, from" "$scratch/out") $(grep -c BUILT "$scratch/get-built" 2>/dev/null || echo 0)" "1 0" "work compiler --get: a compiler held for this source is taken, nothing builds" "$scratch/out"
find "$sl/getme/build" -type f -delete
(cd "$sl/getme" && AVRA_COMPILER_DEPOT="$scratch/emptydepot" AVRA_GET_BUILD="echo BUILT >> $scratch/get-built" sh "$slw" compiler --get) > "$scratch/out" 2>&1
check "$(grep -c BUILT "$scratch/get-built" 2>/dev/null || echo 0)" "1" "work compiler --get: none held and none published builds with make compiler" "$scratch/out"

# MAIN'S COMPILER, ONCE PER SOURCE: the first run builds and deposits, the second finds the depot holding it.
mcd=$scratch/mc/depot
mcb='mkdir -p build && echo bin > build/avra && chmod +x build/avra && sh '"$slw"' built-from . > build/.avra-built-from && echo built >> '"$scratch"'/mc-builds'
mc() { (cd "$sl/main" && AVRA_COMPILER_DEPOT="$mcd" AVRA_MAIN_TREE="$scratch/mc/tree" AVRA_MAINC_BUILD="$mcb" sh "$slw" main-compiler) > "$scratch/out" 2>&1; }
mc; mc
check "$(ls "$mcd" | wc -l | tr -d ' ') $(grep -c built "$scratch/mc-builds" 2>/dev/null || echo 0) $(grep -c 'nothing to build' "$scratch/out")" "1 1 1" "work main-compiler: built and deposited once, the second run finds the depot holding it" "$scratch/out"
mkdir -p "$scratch/mc"; mkdir "$scratch/mc/main-compiler.lock"; echo 99999999 > "$scratch/mc/main-compiler.lock/pid"
mc
check "$(grep -c 'nothing to build' "$scratch/out")" "1" "work main-compiler: a lock whose pid is dead is taken over" "$scratch/out"

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
# `with VAR=value… -- <args>` is `ran` under those variables, and only it.
with() { (while [ "$1" != -- ]; do export "$1"; shift; done; shift; ran "$@"); }
ran() { PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" sh "$work" run "$@" > "$scratch/out" 2> "$scratch/err"; }
scene() { rm -f "$scratch"/fake/*; printf 'one\ntwo\nthree\n' > "$scratch/fake/out"; echo "$1" > "$scratch/fake/status"; }

scene 7; echo 1 > "$scratch/fake/ending"; echo 6 > "$scratch/fake/cut"
ran true
check "$? $(tr '\n' ' ' < "$scratch/out")| $(grep -c '^work: CONNECTION — dropped (1 so far.*the run goes on, following again from byte 6' "$scratch/err") $(grep -c '^attach .* 6$' "$scratch/fake/calls") $(grep -c '^work: COMMAND — exit 7, on A.*through 1 dropped' "$scratch/err")" "7 one two three | 1 1 1" "work run: a connection dropped mid-run is followed again from its byte: every line once, the command's status, and both said by name" "$scratch/err"

scene 5; echo 0 > "$scratch/fake/cut"
ran true
check "$? $(tr '\n' ' ' < "$scratch/out")" "5 one two three " "work run: a connection dropped after the run ended still delivers its output and its status" "$scratch/err"

scene 124
ran --for 1 true
check "$? $(grep -c '^work: COMMAND — stopped at its bound' "$scratch/err")" "124 1" "work run: a run the Sprite ended at its bound answers 124 and says so" "$scratch/err"

scene 0; echo Other-9 > "$scratch/fake/live"
ran true
check "$? $(grep -c 'BUSY — Other-9 is live on A with nobody here following it.*work attach.*work stop' "$scratch/err") $(cat "$scratch/fake/rsync" 2>/dev/null | wc -l | tr -d ' ') $(grep -c '^start' "$scratch/fake/calls")" "76 1 0 0" "work run: a Sprite with a run standing is BUSY — nothing is synced under it, nothing started" "$scratch/err"

scene 0; echo 9 > "$scratch/fake/ending"; : > "$scratch/fake/lost"; echo 3 > "$scratch/fake/cut"
ran true
check "$? $(grep -c '^work: SPRITE — A stopped answering.*lists it as .running.*The run goes on there.*work attach' "$scratch/err") $(grep -c '^stop' "$scratch/fake/calls")" "75 1 0" "work run: a Sprite that stops answering mid-run, the provider still answering, is SPRITE and 75 — the run left to go on, never stopped" "$scratch/err"

scene 0; echo 9 > "$scratch/fake/ending"; : > "$scratch/fake/lost"; echo 3 > "$scratch/fake/cut"
with OFFLINE=1 -- true
check "$? $(grep -c '^work: CONNECTION — A stopped answering.*api.sprites.dev.*The run goes on there.*work attach' "$scratch/err") $(grep -c '^stop' "$scratch/fake/calls")" "74 1 0" "work run: with the provider silent too it is CONNECTION and 74 — and the run is still left to go on" "$scratch/err"

scene 0; echo 9 > "$scratch/fake/ending"; : > "$scratch/fake/lost"; echo 3 > "$scratch/fake/cut"
with A_STATE=cold -- true
check "$? $(grep -c '^work: SPRITE — A stopped answering.*lists it as .cold.*It went down under the run.*the run is lost' "$scratch/err") $(grep -c 'The run goes on' "$scratch/err")" "75 1 0" "work run: a Sprite the provider lists as down mid-run is said to be down, and the run lost — never 'the run goes on'" "$scratch/err"

scene 75
ran true
check "$? $(grep -c '^work: SPRITE — A restarted under the run, which is lost' "$scratch/err") $(grep -c 'COMMAND' "$scratch/err")" "75 1 0" "work run: a run its Sprite restarted under answers 75 and names the SPRITE, never the command" "$scratch/err"

scene 0
with SILENT=A -- true
check "$? $(grep -c '^work: SPRITE — A did not answer within 3s.*Nothing was started' "$scratch/err") $(cat "$scratch/fake/calls" 2>/dev/null | grep -c '^start')" "75 1 0" "work run: a Sprite that never wakes is SPRITE and 75, and nothing is started" "$scratch/err"
with SILENT=A OFFLINE=1 -- true
check "$? $(grep -c '^work: CONNECTION — A did not answer' "$scratch/err")" "74 1" "work run: a Sprite and a provider both silent is CONNECTION and 74" "$scratch/err"

scene 0
ran true
check "$? $(grep -c '^work: A — passed' "$scratch/err") $(grep -c 'SPRITE\|CONNECTION\|COMMAND' "$scratch/err")" "0 1 0" "work run: a run that passed names none of the three" "$scratch/err"

# The follow holds every byte the Sprite says the run wrote: a last
# connection that delivered half is asked again, never trusted.
scene 0; echo 4 > "$scratch/fake/cut"; echo 0 > "$scratch/fake/ending"
ran true
check "$? $(tr '\n' ' ' < "$scratch/out")| $(grep -c '^attach' "$scratch/fake/calls")" "0 one two three | 2" "work run: a run that ended while its last connection delivered half is read to its last byte" "$scratch/err"

# ONLY A STOP THAT WAS MEANT ENDS A RUN. A client that is terminated or
# hung up — a session that ended, a harness reaping its jobs — detaches,
# and the run goes on; Ctrl-C is the one signal that stops it. A shell's
# background job has INT ignored, so the client is started with it restored.
signalled() {
    scene 0; echo 99 > "$scratch/fake/ending"; : > "$scratch/fake/hang"
    PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" perl -e '$SIG{INT} = "DEFAULT"; exec @ARGV' sh "$work" run true > "$scratch/out" 2> "$scratch/err" &
    job=$!
    i=0; while [ "$i" -lt 50 ] && ! grep -q '^attach' "$scratch/fake/calls" 2>/dev/null; do sleep 0.2; i=$((i + 1)); done
    kill -"$1" "$job"; wait "$job"
    echo "$? $(grep -c '^stop' "$scratch/fake/calls") $(grep -c "^work: detached ($2) — the run goes on on A; .sh tools/work attach. follows it, .sh tools/work stop. ends it" "$scratch/err") $([ -f "$(git rev-parse --absolute-git-dir)/avra-run" ] && echo locked || echo free)"
}
check "$(signalled TERM terminated)" "143 0 1 free" "work run: a TERM to the client detaches — the run goes on, nothing is stopped, and it says how to follow and how to end it" "$scratch/err"
check "$(signalled HUP 'hung up')" "129 0 1 free" "work run: a hangup detaches the same way" "$scratch/err"
check "$(signalled INT -)" "130 1 0 free" "work run: Ctrl-C stops the run on the Sprite and frees the lane" "$scratch/err"

scene 3; echo Mine-1 > "$scratch/fake/live"
PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" sh "$work" attach > "$scratch/out" 2> "$scratch/err"
check "$? $(tr '\n' ' ' < "$scratch/out")| $(grep -c 'following Mine-1 (live)' "$scratch/err")" "3 one two three | 1" "work attach: follows the lane's run from its first byte and answers its status" "$scratch/err"
PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" sh "$work" stop > "$scratch/out" 2>&1
check "$(grep -c 'Mine-1 stopped' "$scratch/out") $(grep -c '^stop Mine-1' "$scratch/fake/calls")" "1 1" "work stop: ends the lane's live run by name"

# ══ NOTHING RUNS FOR NOBODY: a lane that moves or ends takes its run with it
scene 0; echo Mine-2 > "$scratch/fake/live"
(cd "$scratch/avra-loose" && sh "$work" done --remove-worktree) > /dev/null 2>&1
PATH="$scratch/bin:$PATH" FAKE="$scratch/fake" sh "$work" bind B > "$scratch/out" 2>&1
check "$? $(holder .) $(grep -c 'A still runs something for this lane' "$scratch/out")" "1 A 1" "work bind <sprite>: a lane whose Sprite still runs its run does not move away from it" "$scratch/out"
echo "quiet=12 frozen=357" > "$scratch/fake/idle"
(cd "$main" && FAKE="$scratch/fake" sh "$work" sprites) > "$scratch/out" 2>&1
check "$(grep -c '^A .*host(pid 1) quiet 12s — MADE NO PROGRESS FOR 357s, unattended' "$scratch/out")" 1 "work sprites: a live run shows how long it has been quiet, and how long it stood frozen with nobody attached" "$scratch/out"
echo "quiet=3 frozen=0" > "$scratch/fake/idle"
(cd "$main" && FAKE="$scratch/fake" sh "$work" sprites) > "$scratch/out" 2>&1
check "$(grep -c '^A .*host(pid 1) quiet 3s $' "$scratch/out") $(grep -c 'NO PROGRESS' "$scratch/out")" "1 0" "work sprites: a run that never froze says only how long it has been quiet" "$scratch/out"
(cd "$main" && FAKE="$scratch/fake" sh "$work" sprites --fix A) > "$scratch/out" 2>&1
check "$(grep -c 'A is running Mine-2 for lane avra-after — left alone' "$scratch/out") $(grep -c '^stop' "$scratch/fake/calls")" "1 0" "work sprites --fix: a live run on a Sprite its lane holds is left alone, even named" "$scratch/out"
(cd "$main" && FAKE="$scratch/fake" sh "$work" sprites --fix B) > "$scratch/out" 2>&1
check "$(grep -c 'B: stopped Mine-2, which no lane owns' "$scratch/out") $(grep -c '^stop Mine-2' "$scratch/fake/calls")" "1 1" "work sprites --fix: a live run on a Sprite no lane holds is nobody's, and is stopped" "$scratch/out"
: > "$scratch/fake/calls"
FAKE="$scratch/fake" sh "$work" done --remove-worktree > "$scratch/out" 2>&1
st=$?
cd "$main" || exit 1
[ -e "$scratch/avra-after" ] && stands=stands || stands=absent
check "$st $stands $(grep -c 'Mine-2 stopped' "$scratch/out") $(grep -c '^stop Mine-2' "$scratch/fake/calls")" "0 absent 1 1" "work done: the lane's live run is stopped before its Sprite is freed" "$scratch/out"
cd "$main" || exit 1

# ══ THE PR STATE: status shows the check, the merge state and whether
# auto-merge is armed, and reaches no queue mutation ═══════════════════
cd "$main" || exit 1
: > "$GH_LOG"
sh "$work" status > "$scratch/out" 2>&1
check "$(grep -c '#7  lane-a  armed  CLEAN' "$scratch/out") $(grep -c 'queue\|enqueue\|mergeQueue' "$GH_LOG")" "1 0" "work status: a PR shows its armed/CLEAN state and no queue mutation is reached" "$scratch/out"

# ══ THE SYNC, THE SPRITE BEING A DIRECTORY HERE: this machine's own rsync
# carries the tree, and the Sprite's half answers from $scratch/sync-home.
# `DEAF` makes the Sprite ignore a removal.
cat > "$scratch/sprite-dir" <<'STUB'
#!/bin/sh
[ "$1" != api ] || { echo '{"data":[{"name":"S","status":"running"}]}'; exit 0; }
while [ "$#" -gt 0 ] && [ "$1" != -- ]; do shift; done
shift
[ -z "${DEAF:-}" ] || [ "${4:-} ${6:-}" != "avra-remote unlink" ] || exit 0
exec "$@"
STUB
chmod +x "$scratch/sprite-dir"
git -C "$main" worktree add -q -b sync-a "$scratch/avra-sync" main
lane=$scratch/avra-sync
there=$scratch/sync-home/avra-build/avra-sync/tree
echo S > "$(git -C "$lane" rev-parse --absolute-git-dir)/avra-sprite"
echo '**/src/main' > "$lane/.gitignore"
mkdir -p "$lane/packages/p"
echo one > "$lane/packages/p/gone.av"
echo two > "$lane/packages/p/keep.av"
synced() { (cd "$lane" && AVRA_SPRITE_HOME="$scratch/sync-home" AVRA_SPRITE_CLI="$scratch/sprite-dir" sh "$work" sync > "$scratch/out" 2> "$scratch/err"); }
has() { for f in "$@"; do [ -e "$there/$f" ] && printf 'y' || printf 'n'; done; }

synced
check "$? $(has packages/p/gone.av packages/p/keep.av tools/work .github/ci/packages.txt ci) $(grep -c 'holds this worktree, proved' "$scratch/err")" "0 yyyyn 1" "sync: the tree lands under its own names and the Sprite's manifest proves it" "$scratch/err"

# What a run wrote there, and what this worktree's rsync never carries.
mkdir -p "$there/build" "$there/packages/p/.avra-cache" "$there/packages/p/src"
: > "$there/build/avra"; : > "$there/packages/p/.avra-cache/held"; : > "$there/packages/p/src/main"
rm "$lane/packages/p/gone.av"
synced
check "$? $(has packages/p/gone.av packages/p/keep.av) $(has build/avra packages/p/.avra-cache/held packages/p/src/main) $(grep -c '1 it no longer has removed' "$scratch/err")" "0 ny yyy 1" "sync: a file deleted here is gone there; build/, a cache and an ignored product a run wrote are left" "$scratch/err"

mv "$lane/packages/p/keep.av" "$lane/packages/p/kept.av"
synced
check "$? $(has packages/p/keep.av packages/p/kept.av)" "0 ny" "sync: a renamed file is there under its new name only" "$scratch/err"

git -C "$lane" add -A
git -C "$lane" -c user.name=t -c user.email=t@t commit -q -m base
git -C "$lane" checkout -q -b sync-b
mkdir -p "$lane/packages/q"
echo b > "$lane/packages/q/only_b.av"
git -C "$lane" add -A
git -C "$lane" -c user.name=t -c user.email=t@t commit -q -m b
synced
before=$(has packages/q/only_b.av)
git -C "$lane" checkout -q sync-a
synced
check "$? $before$(has packages/q/only_b.av packages/p/kept.av)" "0 yny" "sync: after a branch switch the other branch's files are gone from the Sprite" "$scratch/err"

# The same size and the same time, another content: only a manifest of contents sees it.
echo TWO > "$there/packages/p/kept.av"
touch -r "$lane/packages/p/kept.av" "$there/packages/p/kept.av"
synced
check "$? $(cat "$there/packages/p/kept.av")" "0 two" "sync: a file there that differs only in content is carried again" "$scratch/err"

echo stale > "$there/packages/p/left.av"
(export DEAF=1; synced)
check "$? $(grep -c '^work: SPRITE — sync: S does not hold this worktree.*1 file(s) it should not have.*packages/p/left.av.*Nothing was started' "$scratch/err")" "75 1" "sync: a Sprite left holding a file this worktree lacks is refused with 75 and the file's name — nothing runs on another tree" "$scratch/err"
synced
check "$? $(has packages/p/left.av)" "0 n" "sync: the same Sprite, hearing again, is put right"
git -C "$main" worktree remove --force "$lane"

# ══ END TO END, THE SPRITE BEING THIS MACHINE: the real follower over the
# real supervisor, every exec run here — and its connection killed whole
# when `drop` says after how many seconds. Linux only: the Sprite's half
# reads /proc and takes its own session.
# The end-to-end checks count a run's processes in /proc and need an init
# that reaps what a killed supervisor leaves: a Sprite, never a container
# job, where AVRA_NO_SUPERVISOR_TESTS says so and the skip is spoken.
if [ "$(uname -s)" = Linux ] && [ -n "${AVRA_NO_SUPERVISOR_TESTS:-}" ]; then
    echo "work_test: SKIPPED the supervisor's end-to-end checks and the Sprite's half (tools/sprite_remote_test.sh) — AVRA_NO_SUPERVISOR_TESTS is set; \`sh tools/work run sh tools/work_test.sh\` runs them"
elif [ "$(uname -s)" = Linux ]; then
    carrier=${AVRA_RUN:-none}
    unset AVRA_RUN SILENT OFFLINE FAKE
    cat > "$scratch/sprite-here" <<'STUB'
#!/bin/sh
[ "$1" != api ] || { echo '{"data":[{"name":"L","status":"running"}]}'; exit 0; }
[ "$3" = exec ] || exit 0
while [ "$1" != -- ]; do shift; done
shift
if [ "${6:-}" = attach ] && [ -f "$E2E/drop" ]; then
    n=$(cat "$E2E/drop")
    rm -f "$E2E/drop"
    setsid "$@" &
    sleep "$n"
    kill -KILL "-$!" 2>/dev/null
    exit 1
fi
exec "$@"
STUB
    chmod +x "$scratch/sprite-here"
    export E2E="$scratch/e2e" AVRA_SPRITE_HOME="$scratch/sprite-home" AVRA_SPRITE_CLI="$scratch/sprite-here" AVRA_SPRITES=L AVRA_REATTACH_S=0
    # The real rsync carries the tree here: the sync's proof is part of every run.
    mkdir -p "$E2E"
    git -C "$main" worktree add -q -b e2e "$scratch/avra-e2e" main
    cd "$scratch/avra-e2e" || exit 1
    sh "$work" bind > /dev/null 2>&1
    # The lane's compiler stands already: these runs are about the run.
    there="$AVRA_SPRITE_HOME/avra-build/avra-e2e/tree/build"
    mkdir -p "$there"
    printf '#!/bin/sh\n' > "$there/avra"
    chmod +x "$there/avra"
    sh "$work" compiler-hash | tr -d '\n' > "$there/.avra-compiler-hash"
    # How many processes carry any run's mark but the one carrying these fixtures.
    marked() {
        n=0
        for e in /proc/[0-9]*/environ; do
            m=$(tr '\0' '\n' 2>/dev/null < "$e" | sed -n 's/^AVRA_RUN=//p' | head -n 1)
            [ -z "$m" ] || [ "$m" = "$carrier" ] || n=$((n + 1))
        done
        echo "$n"
    }
    # Up to $1 seconds for every marked process to go.
    quiet() { i=0; while [ "$i" -lt "$1" ] && [ "$(marked)" != 0 ]; do sleep 1; i=$((i + 1)); done; marked; }
    lines='i=0; while [ $i -lt 8 ]; do i=$((i + 1)); echo "line $i"; sleep 1; done'
    want="line 1 line 2 line 3 line 4 line 5 line 6 line 7 line 8 "

    # WHAT A SPRITE IS PROVISIONED FROM: a run provisions again when the recorded hash differs from the
    # tree's, and skips when it is the same.
    phash() { (here="$main/tools" && . "$here/sprite-lib.sh" && provision_hash); }
    stamp="$AVRA_SPRITE_HOME/.avra-provisioned"
    timeout 90 sh "$work" run true > "$scratch/out" 2> "$scratch/err"
    check "$?|$(grep -c 'provisioning again' "$scratch/err")|$(cat "$stamp" 2>/dev/null)" "0|1|$(phash)" \
        "provision hash: a Sprite with no record provisions again before the command, and records the tree's hash" "$scratch/err"
    timeout 90 sh "$work" run true > "$scratch/out" 2> "$scratch/err"
    check "$?|$(grep -c 'provisioning again' "$scratch/err")" "0|0" \
        "provision hash: a Sprite whose record is the tree's skips provisioning" "$scratch/err"
    old=$(phash)
    echo "# changed" >> "$main/tools/sprite-provision.sh"
    timeout 90 sh "$work" run true > "$scratch/out" 2> "$scratch/err"
    check "$?|$(grep -c "provisioned from $old" "$scratch/err")|$([ "$(cat "$stamp")" = "$(phash)" ] && [ "$(phash)" != "$old" ] && echo moved)" "0|1|moved" \
        "provision hash: a changed provisioning script is provisioned from again, and the record moves" "$scratch/err"
    find "$main/tools" -name sprite-provision.sh -delete

    echo 3 > "$E2E/drop"
    timeout 90 sh "$work" run "$lines; exit 7" > "$scratch/out" 2> "$scratch/err"
    check "$?|$(grep '^line' "$scratch/out" | tr '\n' ' ')|$(grep -c '^work: CONNECTION — dropped (1 so far' "$scratch/err")|$(grep -c '^work: COMMAND — exit 7' "$scratch/err")|$(quiet 10)" "7|$want|1|1|0" \
        "end to end: a connection killed mid-run is followed again — every line once and in order, the command's own status, no process left" "$scratch/err"

    echo 1 > "$E2E/drop"
    timeout 90 sh "$work" run 'echo only; exit 5' > "$scratch/out" 2> "$scratch/err"
    check "$?|$(grep -c '^only$' "$scratch/out")|$(quiet 10)" "5|1|0" "end to end: a connection that dropped after the command ended still delivers its output and its status" "$scratch/err"

    # The follower killed outright: the run goes on, a second run is BUSY, attach has it whole.
    setsid timeout 90 sh "$work" run "$lines; exit 9" > "$scratch/out" 2> "$scratch/err" &
    job=$!
    i=0; while [ "$i" -lt 30 ] && ! grep -q '^line 2' "$scratch/out" 2>/dev/null; do sleep 1; i=$((i + 1)); done
    kill -KILL "-$job" 2>/dev/null
    wait "$job" 2>/dev/null
    sleep 1
    going=$(marked)
    timeout 60 sh "$work" run true > "$scratch/out2" 2> "$scratch/busy"
    busy=$?
    timeout 90 sh "$work" attach > "$scratch/out" 2> "$scratch/err"
    check "$?|$([ "$going" -gt 0 ] && echo going)|$busy $(grep -c '^work: BUSY — .* is live on L with nobody here following it' "$scratch/busy")|$(grep '^line' "$scratch/out" | tr '\n' ' ')|$(quiet 10)" "9|going|76 1|$want|0" \
        "end to end: with its follower killed outright the run goes on, a second run is BUSY, and attach has every line and the status" "$scratch/err"

    timeout 90 sh "$work" run 'setsid sleep 4260 & sleep 4261' > "$scratch/out" 2> "$scratch/err" &
    job=$!
    i=0; while [ "$i" -lt 30 ] && [ "$(pgrep -fc '^sleep 426[01]$')" != 2 ]; do sleep 1; i=$((i + 1)); done
    sh "$work" stop > "$scratch/stop" 2>&1
    wait "$job"
    check "$?|$(grep -c 'stopped' "$scratch/stop")|$(grep -c '^work: COMMAND — stopped' "$scratch/err")|$(quiet 10)|$(pgrep -fc '^sleep 426[01]$')" "143|1|1|0|0" \
        "end to end: work stop ends the run, its child in another session too, and the follower answers 143" "$scratch/err"
    cd "$main" || exit 1

    sh "$here/sprite_remote_test.sh" > "$scratch/remote" 2>&1
    rs=$?
    sed 's/^/  /' "$scratch/remote"
    check "$rs" 0 "the Sprite's half: tools/sprite_remote_test.sh"
else
    echo "skip  END TO END and the Sprite's half: they need Linux (/proc, setsid) — \`sh tools/work run sh tools/work_test.sh\` runs them on this lane's Sprite"
fi

checks_done work_test
