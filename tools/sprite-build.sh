#!/bin/sh
# Run a worktree's build on a Sprite. A heavy build belongs to the
# Sprite, never the machine that holds the session.
#
#   sh tools/sprite-build.sh <sprite> <worktree> [--pull <remote>:<local>]... -- <command...>
#   sh tools/sprite-build.sh --stop <sprite> <run...>
#
# ONE PERSISTENT TREE PER (sprite, worktree slug):
# /home/sprite/avra-build/$slug/tree is synced IN PLACE by rsync over
# `sprite exec` (tools/sprite-rsh.sh) — an edit moves only what changed
# and a file the worktree no longer has is deleted. build/, .avra-cache/,
# .claude/ and .git are never touched by the sync, at any depth, so a
# warm build/ and test cache survive every run. One run stands in a tree
# at a time; tools/sp's tree lease is what holds that.
#
# A SHARED COMPILER CACHE PER SPRITE, keyed by the hash of the
# COMPILER'S OWN SOURCE (runtime/, backend/, bootstrap/, the Makefile,
# packages/cli and the std packages its `use` graph actually reaches —
# never a package's tests/, which `avra build` never reads), lives under
# /home/sprite/avra-compilers/<hash>/. A stale or missing build/avra is
# restored from that cache, copied from a Sprite that holds it, or built
# and cached, BEFORE the caller's command runs — a stale build/avra would
# otherwise answer for the previous compiler.
#
# THE SPRITE'S HALF IS tools/sprite-remote.sh, carried in each call: a
# run is marked, kept and stopped there, and never outlives this process.
# Every call is bounded: a Sprite is waited for AVRA_SP_WAKE_S (90)
# seconds to wake, and a run gets AVRA_SP_RUN_S (1800) seconds.
#
# EXIT 3 WITH "unreached" IN $AVRA_SB_VERDICT says the Sprite failed
# before the command began — the caller may take another Sprite. Any
# other status is the command's own.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
. "$here/sprite-lib.sh"
wake_s=${AVRA_SP_WAKE_S:-90}
run_s=${AVRA_SP_RUN_S:-1800}

# Stops each named run on the Sprite; a dropped connection is retried once.
stop_runs() {
    s=$1
    shift
    for _ in 1 2; do
        remote "$s" 30 stop "$@" >/dev/null 2>&1 && return 0
        sleep 2
    done
    echo "sprite-build: could not stop run(s) $* on $s" >&2
    return 1
}
if [ "${1:-}" = --stop ]; then
    shift
    stop_runs "$@"
    exit $?
fi

sprite=
worktree=
pulls=
receipt=
prebuild=
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

host=$(hostname -s)
run="$host-$$-$(date +%s)"
owner="$host $$ $(born $$)"
hash_lock=
started=
xpid=
# The Sprite failed before the command began.
unreached() {
    echo "sprite-build: $sprite: $*" >&2
    [ -z "${AVRA_SB_VERDICT:-}" ] || echo unreached > "$AVRA_SB_VERDICT"
    exit 3
}
# Leaving with a remote run still standing stops it from a detached
# process, so a KILL that follows this one's TERM cannot cancel the stop.
leave() {
    [ -z "$hash_lock" ] || rm -rf "$hash_lock"
    # The exec's own client, then the shell that waits on it.
    [ -z "$xpid" ] || { pkill -TERM -P "$xpid"; kill "$xpid"; } 2>/dev/null || :
    [ -z "$started" ] || nohup sh "$here/sprite-build.sh" --stop "$sprite" "$started" >/dev/null 2>&1 &
}
trap leave EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

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

tree="/home/sprite/avra-build/$slug/tree"

# A dropped connection is retried twice, each retry said in one line.
retried() {
    what=$1
    shift
    n=0
    until "$@"; do
        n=$((n + 1))
        [ "$n" -le 2 ] || { echo "sprite-build: $what failed 3 times on $sprite" >&2; return 1; }
        echo "sprite-build: $what failed on $sprite — retry $n of 2" >&2
        sleep 2
    done
}

sync_tree() {
    timeout -k 2 600 rsync -az --delete -i -e "sh $here/sprite-rsh.sh" \
        --exclude build/ --exclude .avra-cache/ --exclude .claude/ --exclude .git \
        $sync_paths "$sprite:$tree/"
}

# ONE ASK READIES THE SPRITE AND READS IT: awake, its home standing, the
# checks' toolchain installed, what its cache holds and which runs stand.
info=$(woken "$sprite" "$wake_s" ready "$compiler_hash" $ci_packages) ||
    unreached "did not answer within ${wake_s}s"
field() { printf '%s\n' "$info" | sed -n "s/^$1=//p"; }
[ "$(field home)" = yes ] || unreached "/home/sprite does not stand"
[ "$(field provisioned)" = yes ] || unreached "the toolchain is incomplete: $(field unprovisioned)"
cache_flag=$(field holds)

# A run this host began whose owner is gone, or one whose processes have
# ended, is stopped by every caller that reaches the Sprite.
orphans=$(field run | orphaned)
if [ -n "$orphans" ]; then
    echo "sprite-build: $sprite: stopping runs whose owner is gone: $orphans" >&2
    stop_runs "$sprite" $orphans || :
fi

sync_paths=$(cd "$worktree" && for p in Makefile avra avra.toml CLAUDE.md DOGFOODING.md ROADMAP.md docs \
    backend runtime packages tools bootstrap corpus .github/ci; do [ ! -e "$p" ] || printf "%s " "$p"; done)
echo "sprite-build: $sprite: sync" >&2
sync_t0=$(date +%s)
sx "$sprite" 30 mkdir -p "$tree/build" || unreached "could not make the tree"
changes=$(cd "$worktree" && retried "the rsync" sync_tree) || unreached "the tree did not sync"
sync_state=unchanged; [ -n "$changes" ] && sync_state=synced
sync_s=$(( $(date +%s) - sync_t0 ))
build_marker=$(sx "$sprite" 30 cat "$tree/build/.avra-compiler-hash" 2>/dev/null) || build_marker=none

do_restore=0; [ "$cache_flag" = yes ] && [ "$build_marker" != "$compiler_hash" ] && do_restore=1
do_store=0; [ "$cache_flag" = no ] && do_store=1
do_prebuild=0; [ -n "$prebuild" ] && do_prebuild=1

# BUILD ONCE, COPY EVERYWHERE: a hash this Sprite lacks is copied from a
# pool Sprite whose cache holds it, and built here only when none does.
# The hash's lock makes every other caller wait for that one build, then copy.
cache_root=/home/sprite/avra-compilers
holds() { sx "$1" 10 test -x "$cache_root/$compiler_hash/avra" >/dev/null 2>&1; }
donor() {
    pool=$(sh "$here/sp" --pool)
    found=$(mktemp -d -t avra-sp-donor.XXXXXX)
    pids=
    for s in $pool; do
        [ "$s" = "$sprite" ] && continue
        { holds "$s" && : > "$found/$s"; } &
        pids="$pids $!"
    done
    # The first holder to answer wins; a sleeping or unreachable Sprite is never waited out.
    n=0
    while [ "$n" -lt 20 ] && [ -z "$(find "$found" -type f)" ]; do sleep 0.5; n=$((n + 1)); done
    find "$found" -type f | head -n 1 | sed 's|.*/||'
    kill $pids 2>/dev/null || :
    rm -rf "$found"
}
# The one exec that reads stdin: the archive is its input.
copy_from() {
    sx "$1" 300 tar -C "$cache_root" -czf - "$compiler_hash" |
        timeout -k 2 300 "$sprite_cli" -s "$sprite" exec --no-port-forward -- sh -c "mkdir -p '$cache_root' && tar -C '$cache_root' -xzf -"
}
# One run of the Sprite's half, its status the run's; `started` names it
# for `leave` until its own report says it ended.
run_remote() {
    started=$1
    rr_restore=$2 rr_store=$3 rr_prebuild=$4
    shift 4
    remote "$sprite" $((run_s + 90)) run "$started" "$owner" "$run_s" "$tree" "$compiler_hash" "$rr_restore" "$rr_store" "$rr_prebuild" "$@" &
    xpid=$!
    rr=0
    wait "$xpid" || rr=$?
    xpid=
    return "$rr"
}
copied=
prebuilt=
pre_s=
if [ "$do_store" = 1 ]; then
    lock="/tmp/avra-sp-hash-$compiler_hash"
    until mkdir "$lock" 2>/dev/null; do
        sleep 3
        { read -r lp lb < "$lock/owner"; } 2>/dev/null || lp=
        owner_live "$lp" "${lb:-}" || rm -rf "$lock"
    done
    hash_lock=$lock
    echo "$$ $(born $$)" > "$hash_lock/owner"
    pre_t0=$(date +%s)
    echo "sprite-build: $sprite: compiler — looking for a Sprite that holds it" >&2
    from=$(donor)
    [ -n "$from" ] || echo "sprite-build: no Sprite answered holding compiler ${compiler_hash%"${compiler_hash#????????????}"} — building it on $sprite" >&2
    if [ -n "$from" ] && copy_from "$from" && holds "$sprite"; then
        copied=$from
        do_store=0
        do_restore=1
    else
        run_remote "$run-compiler" 0 1 0 true >/dev/null || :
        if holds "$sprite"; then
            started=
            prebuilt=built
            do_store=0
        fi
    fi
    pre_s=$(( $(date +%s) - pre_t0 ))
    rm -rf "$hash_lock"
    hash_lock=
fi

[ -z "$copied" ] || echo "sprite-build: $sprite: compiler copied from $copied" >&2
echo "sprite-build: $sprite: cmd" >&2
status=0
run_remote "$run" "$do_restore" "$do_store" "$do_prebuild" "$@" || status=$?

# The run's own report — timing and the store outcome — never read from
# stdout or stderr, which stayed the command's alone.
run_info=$(retried "the report" sx "$sprite" 30 cat "$tree/build/.avra-run-info" 2>/dev/null) || run_info=""
wall=$(printf '%s\n' "$run_info" | sed -n 's/^WALL://p')
store_result=$(printf '%s\n' "$run_info" | sed -n 's/^STORE://p')
compile_s=$(printf '%s\n' "$run_info" | sed -n 's/^COMPILE://p')
[ -n "$compile_s" ] || compile_s="?"
[ -n "$wall" ] || wall="?"
[ -n "$store_result" ] || store_result=none
# A run that reported has ended. One that did not was cut off — its
# connection dropped, or this side was — and `leave` stops what is left.
if [ -n "$run_info" ]; then
    started=
else
    [ "$status" != 0 ] || status=1
    echo "sprite-build: $sprite: the run never reported — its connection dropped (exit $status)" >&2
    [ -z "${AVRA_SB_VERDICT:-}" ] || echo dropped > "$AVRA_SB_VERDICT"
fi

for spec in $pulls; do
    from=${spec%%:*}
    to=${spec#*:}
    if sx "$sprite" 30 test -e "$tree/$from" 2>/dev/null; then
        mkdir -p "$(dirname "$to")"
        timeout -k 2 120 "$sprite_cli" -s "$sprite" file pull "$tree/$from" "$to" >/dev/null
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

[ -z "$copied" ] || compiler_state="copied-from-$copied"
[ -z "$prebuilt" ] || compiler_state=$prebuilt
[ -z "$pre_s" ] || compile_s=$pre_s
echo "sprite-build: $slug@$compiler_hash tree=$sync_state compiler=$compiler_state sync=${sync_s}s build=${compile_s}s cmd=${wall}s -> exit $status" >&2
exit "$status"
