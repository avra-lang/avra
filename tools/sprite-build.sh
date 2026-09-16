#!/bin/sh
# Run a worktree's build on a Sprite. A heavy build belongs to the
# Sprite, never the machine that holds the session.
#
#   sh tools/sprite-build.sh <sprite> <worktree> [--pull <remote>:<local>]... -- <command...>
#
# The verb is keyed by the source tree's hash: the Sprite keeps one
# persistent directory per (worktree, hash), so a hash already synced
# pays no upload and a re-run is a no-op on the filesystem. Only source
# travels — never build output, history, or another session's checkout —
# and the caller's worktree is never written to. The command runs in the
# synced tree and its exit status comes straight back.
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
    echo "usage: sprite-build.sh <sprite> <worktree> [--receipt] [--pull <remote>:<local>]... -- <command...>" >&2
    exit 2
}

worktree=$(cd "$worktree" && pwd)
slug=$(basename "$worktree")

# The archive IS the identity: hashing it means a changed file, a new
# file and a deleted file all name a different tree.
tarfile=$(mktemp -t avra-sprite.XXXXXX)
trap 'rm -f "$tarfile"' EXIT
# The gate reads doctrine as data (tools/idioms.py, tools/cited.py), so
# those files travel even though they are not source.
(
    cd "$worktree"
    find Makefile avra avra.toml CLAUDE.md DOGFOODING.md ROADMAP.md docs \
         backend runtime packages tools bootstrap corpus \
        -type f ! -path '*/build/*' ! -path '*/.claude/*' 2>/dev/null \
        | LC_ALL=C sort \
        | COPYFILE_DISABLE=1 tar --no-mac-metadata -cf "$tarfile" -T -
)
hash=$(shasum -a 256 "$tarfile" | cut -d' ' -f1)
remote="/home/sprite/avra-build/$slug/$hash"

# `sprite file push` sees only directories that existed when the Sprite
# started, so the archive lands in /home/sprite and is extracted into
# the persistent build directory from there.
staging="/home/sprite/.avra-sprite-$slug.tar"
if ! sprite -s "$sprite" exec --no-port-forward -- test -f "$remote/.synced" 2>/dev/null; then
    sprite -s "$sprite" file push "$tarfile" "$staging" >/dev/null
    sprite -s "$sprite" exec --no-port-forward -- bash -lc \
        "mkdir -p '$remote' && tar -xf '$staging' -C '$remote' && touch '$remote/.synced' && rm -f '$staging'"
fi

status=0
sprite -s "$sprite" file push "$provision_script" "/home/sprite/.avra-provision.sh" >/dev/null
# Provisioning may fail its own seed build on a tree that predates the
# Linux fixes; the toolchain it installs is what the command needs.
# `stems` examines the compiler's own binary, so a gate is only a real
# gate when one is already built — --prebuild builds it once per hash.
remote_cmd="cd '$remote' && { test -f tools/sprite-provision.sh || { mkdir -p tools && cp /home/sprite/.avra-provision.sh tools/sprite-provision.sh; }; } && { test -f /usr/lib/llvm-22/lib/libLLVM.so || sh tools/sprite-provision.sh >/dev/null 2>&1 || true; }"
[ -n "$prebuild" ] && remote_cmd="$remote_cmd && { test -x build/avra || make avra; }"
remote_cmd="$remote_cmd && exec $*"
sprite -s "$sprite" exec --no-port-forward -- bash -lc "$remote_cmd" || status=$?

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
if [ -n "$receipt" ] && [ "$status" = 0 ] && [ -f "$worktree/tools/gate_receipt.sh" ]; then
    (cd "$worktree" && sh tools/gate_receipt.sh write) || true
fi

echo "sprite-build: $slug@$hash on $sprite -> exit $status" >&2
exit "$status"
