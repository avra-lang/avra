#!/bin/sh
# Run a worktree's build on a Sprite. A heavy build belongs to the
# Sprite, never the machine that holds the session.
#
#   sh tools/sprite-build.sh <sprite> <worktree> [--pull <remote>:<local>]... -- <command...>
#
# ONE PERSISTENT TREE PER (sprite, worktree slug):
# /home/sprite/avra-build/$slug/tree is synced IN PLACE — the pushed
# archive extracts over it and a file the archive no longer lists is
# removed, so an unchanged tree skips the push and an edit updates only
# what moved. build/, .avra-cache/ and .claude/ are never scanned or
# touched by the sync, at any depth, so a warm build/ and test cache
# survive every run. Only one build may touch a given persistent tree
# at a time — nothing here serialises concurrent callers.
#
# A SHARED COMPILER CACHE PER SPRITE, keyed by the hash of the
# COMPILER'S OWN SOURCE (runtime/, backend/, bootstrap/, the Makefile,
# packages/cli and the std packages its `use` graph actually reaches —
# never every packages/std-*, and never a package's tests/, which
# `avra build` never reads), lives under /home/sprite/avra-compilers/
# <hash>/. Before the caller's command runs, a stale or missing
# build/avra is restored from that cache when a matching entry exists;
# after the command, a build/avra the cache does not yet hold is
# advanced and stored. THE FIXED-POINT INVARIANT: only a compiler
# built by `make avra` run twice more from whatever the command leaves
# behind — the same two-generation climb `make bootstrap`'s gen-2
# takes from the seed — is cached; a binary that fails either build is
# never stored. Not verified by diffing the binary: this toolchain's
# linker embeds a build id that differs between two builds of the same
# source, so byte equality would refuse a real fixed point.
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

tarfile=$(mktemp -t avra-sprite.XXXXXX)
info_script=$(mktemp -t avra-sprite-info.XXXXXX)
run_script=$(mktemp -t avra-sprite-run.XXXXXX)
trap 'rm -f "$tarfile" "$info_script" "$run_script"' EXIT

# The archive IS the tree's identity: hashing it means a changed file,
# a new file and a deleted file all name a different tree. The gate
# reads doctrine as data (tools/idioms.baseline, tools/cited.py), so
# those files travel even though they are not source.
(
    cd "$worktree"
    find Makefile avra avra.toml CLAUDE.md DOGFOODING.md ROADMAP.md docs \
         backend runtime packages tools bootstrap corpus \
        -type f ! -path '*/build/*' ! -path '*/.claude/*' ! -path '*/.avra-cache/*' 2>/dev/null \
        | LC_ALL=C sort \
        | COPYFILE_DISABLE=1 tar --no-mac-metadata -cf "$tarfile" -T -
)
tree_hash=$(shasum -a 256 "$tarfile" | cut -d' ' -f1)

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
staging="/home/sprite/.avra-sprite-$slug.tar"
info_remote="/home/sprite/.avra-info-$slug.sh"
run_remote="/home/sprite/.avra-run-$slug.sh"

sprite -s "$sprite" file push "$provision_script" "/home/sprite/.avra-provision.sh" >/dev/null

# RT1: what the persistent tree and the shared cache already hold, so
# the push and the compiler restore can each be skipped when nothing
# would change. Marks live under build/, which the sync never scans.
cat > "$info_script" <<'SCRIPT'
#!/bin/sh
set -eu
remote=$1
chash=$2
printf 'TREE:%s\n' "$(cat "$remote/build/.avra-tree-hash" 2>/dev/null || echo none)"
printf 'BUILD:%s\n' "$(cat "$remote/build/.avra-compiler-hash" 2>/dev/null || echo none)"
if [ -x "/home/sprite/avra-compilers/$chash/avra" ]; then
    printf 'CACHE:yes\n'
else
    printf 'CACHE:no\n'
fi
SCRIPT
sprite -s "$sprite" file push "$info_script" "$info_remote" >/dev/null
info=$(sprite -s "$sprite" exec --no-port-forward -- bash -lc "sh '$info_remote' '$remote' '$compiler_hash'" 2>/dev/null) || info=""
tree_marker=$(printf '%s\n' "$info" | sed -n 's/^TREE://p')
build_marker=$(printf '%s\n' "$info" | sed -n 's/^BUILD://p')
cache_flag=$(printf '%s\n' "$info" | sed -n 's/^CACHE://p')
[ -n "$tree_marker" ] || tree_marker=none
[ -n "$build_marker" ] || build_marker=none
[ -n "$cache_flag" ] || cache_flag=no

do_sync=1; [ "$tree_marker" = "$tree_hash" ] && do_sync=0
do_restore=0; [ "$cache_flag" = yes ] && [ "$build_marker" != "$compiler_hash" ] && do_restore=1
do_store=0; [ "$cache_flag" = no ] && do_store=1
do_prebuild=0; [ -n "$prebuild" ] && do_prebuild=1

[ "$do_sync" = 1 ] && sprite -s "$sprite" file push "$tarfile" "$staging" >/dev/null

# RT2: sync (if needed), idempotent provisioning, compiler restore or
# a verified store, then the caller's own command, timed. Nothing here
# writes to the command's stdout or stderr — outcomes land in
# build/.avra-run-info, read back after.
cat > "$run_script" <<'SCRIPT'
#!/bin/sh
set -eu
remote=$1; chash=$2; tree_hash=$3; do_sync=$4; do_restore=$5; do_store=$6; do_prebuild=$7
shift 7

mkdir -p "$remote/build"
cd "$remote"
slug=$(basename "$(dirname "$remote")")
staging="/home/sprite/.avra-sprite-$slug.tar"

# THE SYNC: a file the archive no longer lists is stale and removed;
# build/, .avra-cache/ and .claude/ are pruned from the scan at any
# depth, so a warm build/ and test cache never touch this path.
if [ "$do_sync" = 1 ] && [ -f "$staging" ]; then
    tar -tf "$staging" | LC_ALL=C sort > "/tmp/.avra-expect-$$"
    tar -xf "$staging" -C "$remote"
    find "$remote" \( -name build -o -name .avra-cache -o -name .claude \) -type d -prune -o -type f -print \
        | sed "s#^$remote/##" | LC_ALL=C sort > "/tmp/.avra-present-$$"
    comm -23 "/tmp/.avra-present-$$" "/tmp/.avra-expect-$$" > "/tmp/.avra-stale-$$"
    while IFS= read -r f; do rm -f "$remote/$f"; done < "/tmp/.avra-stale-$$"
    find "$remote" \( -name build -o -name .avra-cache -o -name .claude \) -prune -o -type d -empty -print \
        | awk '{ print gsub(/\//,"/"), $0 }' | sort -rn | cut -d' ' -f2- \
        | while IFS= read -r d; do [ "$d" = "$remote" ] || rmdir "$d" 2>/dev/null || true; done
    rm -f "/tmp/.avra-expect-$$" "/tmp/.avra-present-$$" "/tmp/.avra-stale-$$" "$staging"
    printf '%s' "$tree_hash" > build/.avra-tree-hash
fi

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

if [ "$do_prebuild" = 1 ]; then
    test -x build/avra || make avra
fi

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

# ONLY A FIXED POINT IS CACHED: `make bootstrap` reaches gen-2 by
# recovering from the seed and then running `make avra` twice, so
# running `make avra` twice more from WHATEVER build/avra the command
# leaves behind reaches the same generation relative to the current
# source — the first pass compiles the new source with a compiler that
# may still be one generation behind it, the second compiles it with a
# compiler that already reflects it. Attempted regardless of the
# command's own exit status — a compiler earlier in the chain may be
# good even when a later test step is not.
# NOT VERIFIED BY DIFFING THE BINARY: this toolchain's linker embeds a
# build id (or similar) that differs byte-for-byte between two
# otherwise-identical builds — confirmed by building an unchanged tree
# twice and comparing, same length, first difference at byte 321 — so
# byte equality is a false negative here, not a stronger check.
store_result=none
if [ "$do_store" = 1 ] && [ -x build/avra ]; then
    set +e
    make -s avra > "/tmp/.avra-fplog-$$" 2>&1
    mk1=$?
    make -s avra >> "/tmp/.avra-fplog-$$" 2>&1
    mk2=$?
    set -e
    if [ "$mk1" = 0 ] && [ "$mk2" = 0 ]; then
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
    rm -f "/tmp/.avra-fplog-$$"
fi

{
    printf 'WALL:%s\n' "$wall"
    printf 'STORE:%s\n' "$store_result"
} > build/.avra-run-info

exit "$status"
SCRIPT
sprite -s "$sprite" file push "$run_script" "$run_remote" >/dev/null

status=0
remote_run_cmd="sh '$run_remote' '$remote' '$compiler_hash' '$tree_hash' '$do_sync' '$do_restore' '$do_store' '$do_prebuild' \"\$@\""
sprite -s "$sprite" exec --no-port-forward -- bash -lc "$remote_run_cmd" avra-sprite-run "$@" || status=$?

# RT3: the run's own report — timing and the store outcome — never
# read from stdout or stderr, which stayed the command's alone.
run_info=$(sprite -s "$sprite" exec --no-port-forward -- bash -lc "cat '$remote/build/.avra-run-info' 2>/dev/null" 2>/dev/null) || run_info=""
wall=$(printf '%s\n' "$run_info" | sed -n 's/^WALL://p')
store_result=$(printf '%s\n' "$run_info" | sed -n 's/^STORE://p')
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

if [ "$do_sync" = 1 ]; then sync_state=synced; else sync_state=unchanged; fi
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

echo "sprite-build: $slug@$compiler_hash tree=$sync_state compiler=$compiler_state cmd=${wall}s -> exit $status" >&2
exit "$status"
