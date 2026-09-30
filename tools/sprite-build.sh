#!/bin/sh
# Run a worktree's build on a Sprite. A heavy build belongs to the
# Sprite, never the machine that holds the session.
#
#   sh tools/sprite-build.sh <sprite> <worktree> [--pull <remote>:<local>]... -- <command...>
#
# ONE PERSISTENT TREE PER (sprite, worktree slug):
# /home/sprite/avra-build/$slug/tree is synced IN PLACE by rsync over
# `sprite exec` (tools/sprite-rsh.sh) — an edit moves only what changed
# and a file the worktree no longer has is deleted. build/, .avra-cache/,
# .claude/ and .git are never touched by the sync, at any depth, so a
# warm build/ and test cache survive every run. Only one build may touch a given persistent tree
# at a time — nothing here serialises concurrent callers.
#
# A SHARED COMPILER CACHE PER SPRITE, keyed by the hash of the
# COMPILER'S OWN SOURCE (runtime/, backend/, bootstrap/, the Makefile,
# packages/cli and the std packages its `use` graph actually reaches —
# never every packages/std-*, and never a package's tests/, which
# `avra build` never reads), lives under /home/sprite/avra-compilers/
# <hash>/. A stale or missing build/avra is restored from that cache,
# or — when this exact hash was never cached — ADVANCED AND CACHED,
# BEFORE the caller's command runs: a stale build/avra already on disk
# would otherwise pass the caller's own `test -x build/avra` and the
# command would test the PREVIOUS compiler. THE FIXED-POINT INVARIANT:
# only a compiler built by `make avra` run twice more (or `make
# bootstrap` from nothing) — the same two-generation climb `make
# bootstrap`'s gen-2 takes from the seed — is cached; a binary that
# fails either build is never stored. Not verified by diffing the
# binary: this toolchain's linker embeds a build id that differs
# between two builds of the same source, so byte equality would refuse
# a real fixed point.
#
# The command runs in the synced tree and its exit status comes
# straight back; a --receipt is written for the CALLER's worktree,
# never the Sprite's copy, which carries no git history.
set -eu

sprite=
worktree=
pulls=
receipt=
prebuild=
# A worktree may predate the provisioning script, so the helper carries
# its own copy and seeds it into the synced tree.
here=$(cd "$(dirname "$0")" && pwd)
provision_script="$here/sprite-provision.sh"
while [ "$#" -gt 0 ]; do
    case $1 in
        --pull) pulls="$pulls $2"; shift 2 ;;
        --receipt) receipt=1; shift ;;
        --prebuild) prebuild=1; shift ;;
        --) shift; break ;;
        *) [ -z "$sprite" ] && sprite=$1 || worktree=$1; shift ;;
    esac
done
[ -n "$sprite" ] && [ -n "$worktree" ] && [ "$#" -gt 0 ] || {
    echo "usage: sprite-build.sh <sprite> <worktree> [--receipt] [--prebuild] [--pull <remote>:<local>]... -- <command...>" >&2
    exit 2
}

worktree=$(cd "$worktree" && pwd)
slug=$(basename "$worktree")

info_script=$(mktemp -t avra-sprite-info.XXXXXX)
run_script=$(mktemp -t avra-sprite-run.XXXXXX)
trap 'rm -f "$info_script" "$run_script"' EXIT

# THE COMPILER'S SOURCE CLOSURE: packages/cli plus every package its
# `use @std.x` graph reaches, walked breadth-first over real `use`
# lines only (grammar/DSL test fixtures spell `use @std . x` with
# spaces and never match). @std/prelude binds to every file with no
# `use` at all, so it is always in scope. A package the walk cannot
# find on disk is dropped, never guessed.
compiler_source_paths() {
    (
        cd "$worktree"
        pending="cli"
        seen=""
        while [ -n "$pending" ]; do
            d=${pending%% *}
            case $pending in *' '*) pending=${pending#* } ;; *) pending= ;; esac
            case " $seen " in *" $d "*) continue ;; esac
            seen="$seen $d"
            dir=packages/$d
            [ -d "$dir/src" ] || continue
            for dep in $(grep -rhoE 'use +@std\.[A-Za-z0-9_]+' "$dir/src" 2>/dev/null \
                         | sed -E 's/^use +@std\.//' | sort -u); do
                pending="$pending std-$dep"
            done
        done
        for d in $seen; do
            [ -d "packages/$d/src" ] && printf 'packages/%s\n' "$d"
        done
        printf '%s\n' Makefile backend runtime bootstrap packages/std-prelude
    )
}

# A CONTENT HASH, NEVER A TARBALL HASH: the compiler cache is keyed by
# what each file HOLDS, so a touch with no edit still hits the cache —
# unlike the tree hash above, where that distinction does not matter.
# `tests/` is excluded at any depth: `avra build packages/cli` never
# reaches a package's test files (`avra test` feeds them to the
# compiler as DATA, after it exists), so a test-only edit must not
# name a new hash. `xargs` batches the digests — one `shasum` per file
# cost 17s over 1300 files; batched, 0.7s.
compiler_hash() {
    (
        cd "$worktree"
        compiler_source_paths | sort -u | while IFS= read -r p; do
            find "$p" -type f ! -path '*/build/*' ! -path '*/.avra-cache/*' ! -path '*/.claude/*' ! -path '*/tests/*' 2>/dev/null
        done | LC_ALL=C sort -u | xargs shasum -a 256
    ) | shasum -a 256 | cut -d' ' -f1
}
compiler_hash=$(compiler_hash)

remote="/home/sprite/avra-build/$slug/tree"
info_remote="/home/sprite/.avra-info-$slug.sh"
run_remote="/home/sprite/.avra-run-$slug.sh"

# A Sprite waking from sleep answers before its home is mounted, and a
# first exec can drop its connection: wait until /home/sprite stands.
sprite_ready() {
    i=0
    while [ $i -lt 30 ]; do
        sprite -s "$sprite" exec --no-port-forward -- sh -c 'test -d /home/sprite' >/dev/null 2>&1 && return 0
        i=$((i + 1))
        sleep 4
    done
    echo "sprite-build: $sprite never readied /home/sprite after 120s" >&2
    return 1
}
sprite_ready || exit 3

sprite -s "$sprite" file push "$provision_script" "/home/sprite/.avra-provision.sh" >/dev/null

# RT1: what the persistent tree and the shared cache already hold, so
# the push and the compiler restore can each be skipped when nothing
# would change. Marks live under build/, which the sync never scans.
cat > "$info_script" <<'SCRIPT'
#!/bin/sh
set -eu
remote=$1
chash=$2
mkdir -p "$remote/build"
printf 'BUILD:%s\n' "$(cat "$remote/build/.avra-compiler-hash" 2>/dev/null || echo none)"
if [ -x "/home/sprite/avra-compilers/$chash/avra" ]; then
    printf 'CACHE:yes\n'
else
    printf 'CACHE:no\n'
fi
SCRIPT
sprite -s "$sprite" file push "$info_script" "$info_remote" >/dev/null
info=$(sprite -s "$sprite" exec --no-port-forward -- bash -lc "sh '$info_remote' '$remote' '$compiler_hash'" 2>/dev/null) || info=""
build_marker=$(printf '%s\n' "$info" | sed -n 's/^BUILD://p')
cache_flag=$(printf '%s\n' "$info" | sed -n 's/^CACHE://p')
[ -n "$build_marker" ] || build_marker=none
[ -n "$cache_flag" ] || cache_flag=no

do_restore=0; [ "$cache_flag" = yes ] && [ "$build_marker" != "$compiler_hash" ] && do_restore=1
do_store=0; [ "$cache_flag" = no ] && do_store=1
do_prebuild=0; [ -n "$prebuild" ] && do_prebuild=1

# The doctrine files travel with the source: the gate reads them as data
# (tools/idioms.baseline, tools/cited.py). rsync is its own no-op check.
sync_paths=$(cd "$worktree" && for p in Makefile avra avra.toml CLAUDE.md DOGFOODING.md ROADMAP.md docs \
    backend runtime packages tools bootstrap corpus; do [ ! -e "$p" ] || printf "%s " "$p"; done)
sync_t0=$(date +%s)
changes=$(cd "$worktree" && rsync -az --delete -i -e "sh $here/sprite-rsh.sh" \
    --exclude build/ --exclude .avra-cache/ --exclude .claude/ --exclude .git \
    $sync_paths "$sprite:$remote/") || { echo "sprite-build: rsync to $sprite failed" >&2; exit 3; }
sync_state=unchanged; [ -n "$changes" ] && sync_state=synced
sync_s=$(( $(date +%s) - sync_t0 ))

# RT2: sync (if needed), idempotent provisioning, compiler restore or
# a verified store, then the caller's own command, timed. Nothing here
# writes to the command's stdout or stderr — outcomes land in
# build/.avra-run-info, read back after.
cat > "$run_script" <<'SCRIPT'
#!/bin/sh
set -eu
remote=$1; chash=$2; do_restore=$3; do_store=$4; do_prebuild=$5
shift 5

mkdir -p "$remote/build"
cd "$remote"

# Idempotent toolchain provisioning: a Sprite is a stock Ubuntu image.
test -f tools/sprite-provision.sh || { mkdir -p tools; cp /home/sprite/.avra-provision.sh tools/sprite-provision.sh; }
test -f /usr/lib/llvm-22/lib/libLLVM.so || sh tools/sprite-provision.sh >/dev/null 2>&1 || true

# THE COMPILER'S OWN OBJECT SET, read from the Makefile's COMPILER_OBJS
# — the runtime's objects (globbed, one per runtime/*.c, as the
# Makefile globs them) plus its four named ones — never a wildcard
# over build/, which would sweep in unrelated packages' objects too.
objs="build/avra build/libavra_runtime.a build/avra_hot.bc build/avra_hot.inc"
for f in runtime/*.c; do
    [ -f "$f" ] || continue
    stem=$(basename "$f" .c)
    objs="$objs build/$stem.o build/$stem.sha build/$stem.d"
done
for stem in llvm_wrapper ffi std_io std_process; do
    objs="$objs build/$stem.o build/$stem.sha build/$stem.d"
done

compile_t0=$(date +%s)
if [ "$do_restore" = 1 ]; then
    cache="/home/sprite/avra-compilers/$chash"
    if [ -d "$cache" ]; then
        for f in $objs; do
            b=$(basename "$f")
            [ -e "$cache/$b" ] || continue
            cp -p "$cache/$b" "$f"
            touch "$f"
        done
        printf '%s' "$chash" > build/.avra-compiler-hash
    fi
fi

# ONLY A FIXED POINT IS CACHED: `make bootstrap` reaches gen-2 by
# recovering from the seed and then running `make avra` twice, so
# running `make avra` twice more from an EXISTING build/avra reaches
# the same generation relative to the current source — the first pass
# compiles the new source with a compiler that may still be one
# generation behind it, the second compiles it with a compiler that
# already reflects it. With no build/avra at all, `make bootstrap` is
# that same climb from the seed. NOT VERIFIED BY DIFFING THE BINARY:
# this toolchain's linker embeds a build id (or similar) that differs
# byte-for-byte between two otherwise-identical builds — confirmed by
# building an unchanged tree twice and comparing, same length, first
# difference at byte 321 — so byte equality is a false negative here,
# not a stronger check.
advance_and_cache() {
    set +e
    if [ -x build/avra ]; then
        make -s avra > "/tmp/.avra-adv-$$" 2>&1
        a1=$?
        make -s avra >> "/tmp/.avra-adv-$$" 2>&1
        a2=$?
        # A standing compiler that cannot build this source may be a
        # broken generation; the seed climbs from nothing.
        if [ "$a1" != 0 ] || [ "$a2" != 0 ]; then
            make bootstrap >> "/tmp/.avra-adv-$$" 2>&1
            a1=$?
            a2=$a1
        fi
    else
        make bootstrap > "/tmp/.avra-adv-$$" 2>&1
        a1=$?
        a2=$a1
    fi
    set -e
    if [ "$a1" = 0 ] && [ "$a2" = 0 ] && [ -x build/avra ]; then
        cache="/home/sprite/avra-compilers/$chash"
        tmp="/home/sprite/avra-compilers/.tmp-$chash-$$"
        rm -rf "$tmp"
        mkdir -p "$tmp"
        for f in $objs; do
            [ -e "$f" ] || continue
            cp -p "$f" "$tmp/$(basename "$f")"
        done
        rm -rf "$cache"
        mv "$tmp" "$cache"
        printf '%s' "$chash" > build/.avra-compiler-hash
        store_result=built
    else
        store_result=unverified
    fi
    rm -f "/tmp/.avra-adv-$$"
}

# THE COMMAND MUST RUN ON THE COMPILER IT IS TESTING: a hash the cache
# does not hold yet is advanced and cached BEFORE the timed run, not
# after — a `build/avra` already on disk from a stale hash would
# otherwise pass `test -x build/avra` in the caller's own command and
# the command would run on the PREVIOUS compiler.
store_result=none
if [ "$do_store" = 1 ]; then
    advance_and_cache
fi

if [ "$do_prebuild" = 1 ]; then
    test -x build/avra || make avra
fi

compile_s=$(( $(date +%s) - compile_t0 ))

# THE TIMED RUN: the caller's own command, isolated from our own
# bookkeeping below — nothing past this point writes to its stdout or
# stderr.
set +e
start=$(date +%s.%N)
"$@"
status=$?
end=$(date +%s.%N)
set -e
wall=$(awk -v a="$start" -v b="$end" 'BEGIN{printf "%.1f", b-a}')

# A SECOND ATTEMPT ONLY COVERS A COMMAND THAT BUILT THE COMPILER
# ITSELF: the pre-command advance above already cached this hash on
# the ordinary path, so this runs only when that attempt failed and
# the caller's own command (its own `make bootstrap` fallback, say)
# leaves a build/avra the cache still does not hold.
if [ "$do_store" = 1 ] && [ "$store_result" != built ] && [ -x build/avra ]; then
    advance_and_cache
fi

{
    printf 'WALL:%s\n' "$wall"
    printf 'STORE:%s\n' "$store_result"
    printf 'COMPILE:%s\n' "$compile_s"
} > build/.avra-run-info

exit "$status"
SCRIPT
sprite -s "$sprite" file push "$run_script" "$run_remote" >/dev/null

status=0
remote_run_cmd="sh '$run_remote' '$remote' '$compiler_hash' '$do_restore' '$do_store' '$do_prebuild' \"\$@\""
sprite -s "$sprite" exec --no-port-forward -- bash -lc "$remote_run_cmd" avra-sprite-run "$@" || status=$?

# RT3: the run's own report — timing and the store outcome — never
# read from stdout or stderr, which stayed the command's alone.
run_info=$(sprite -s "$sprite" exec --no-port-forward -- bash -lc "cat '$remote/build/.avra-run-info' 2>/dev/null" 2>/dev/null) || run_info=""
wall=$(printf '%s\n' "$run_info" | sed -n 's/^WALL://p')
store_result=$(printf '%s\n' "$run_info" | sed -n 's/^STORE://p')
compile_s=$(printf '%s\n' "$run_info" | sed -n 's/^COMPILE://p')
[ -n "$compile_s" ] || compile_s="?"
[ -n "$wall" ] || wall="?"
[ -n "$store_result" ] || store_result=none

for spec in $pulls; do
    from=${spec%%:*}
    to=${spec#*:}
    if sprite -s "$sprite" exec --no-port-forward -- test -e "$remote/$from" 2>/dev/null; then
        mkdir -p "$(dirname "$to")"
        sprite -s "$sprite" file pull "$remote/$from" "$to" >/dev/null
    fi
done

# The receipt names the CALLER's clean tree: the Sprite has no history,
# so a receipt written there could not name the commit the gate read.
if [ -n "$receipt" ]; then
    if [ "$status" != 0 ]; then
        echo "sprite-build: receipt: the command failed (exit $status) — no receipt written" >&2
    elif [ -f "$here/gate_receipt.sh" ]; then
        sh "$here/gate_receipt.sh" write "$worktree" || true
    else
        echo "sprite-build: receipt: no gate_receipt.sh beside the helper — no receipt written" >&2
    fi
fi

if [ "$do_restore" = 1 ]; then
    compiler_state=restored
elif [ "$do_store" = 1 ]; then
    case "$store_result" in
        built) compiler_state=built ;;
        unverified) compiler_state=unverified ;;
        *) compiler_state=none ;;
    esac
else
    compiler_state=cached
fi

echo "sprite-build: $slug@$compiler_hash tree=$sync_state compiler=$compiler_state sync=${sync_s}s build=${compile_s}s cmd=${wall}s -> exit $status" >&2
exit "$status"
