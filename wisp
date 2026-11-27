#!/bin/sh
# THE wisp COMMAND — the repo's internal CLI (packages/wisp), run.
#
#   ./wisp <command> [args…]               stdin and the status pass through
#   ./wisp --path                          where the binary stands, built if need be
#   ./wisp --key                           the package's key: a hash of its manifest and src/, tests aside, as
#                                          the tree holds them (git's where the tree is the index)
#   ./wisp --compiler <avra> <command> …   build with that compiler when no binary stands for the key
#
# A KEEPER IS NEVER JUDGED BY THE COMPILER UNDER TEST. The binary is main's:
# built by main's compiler from the package's source and published beside the
# compiler as the `wisp` asset under `wisp-<key>` (tools/compiler_release.py).
# One key is one source, so a published binary under it is immutable, and a PR
# that does not touch the package has main's key. Resolved in order:
#   1. build/wisp/<key>/wisp, already here;
#   1b. in a tree of program's, the wisp the landing publishes beside the gate's builder for the key, else one
#      built by `--compiler` or this tree's own standing compiler, else a refusal saying why — never steps 2-4,
#      whose compilers predate program's source;
#   2. the published asset for the key, fetched — on Linux x86-64 only, the one platform CI
#      publishes for; any other machine builds its own;
#   3. built here by `--compiler`, else by main's published compiler (Linux x86-64) or
#      the standing build/avra (any other machine);
#   4. the Python tool of the same name (tools/<command with _>.py), while no
#      binary answers — said on stderr, so a fallback is never silent.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"
package=packages/wisp

# THE KEY IS WHAT A BUILD READS. Where the working tree is git's index, it is what git holds, so a clean tree's
# key is the one published for its commit. Where it is not — a file edited or deleted and not staged, or a new
# one git does not track — the index no longer says what a build reads, so the key is the bytes the tree
# holds, said on stderr: no published or cached binary was built from them, and wisp is built again rather
# than served from an older source.
key() {
    if git rev-parse --git-dir >/dev/null 2>&1; then
        set -- "$package/avra.toml" "$package/src" ":(exclude,glob)$package/**/tests/**"
        files=$(git ls-files -s -- "$@")
        [ -n "$files" ] || { echo "wisp: git lists no $package here" >&2; exit 1; }
        moved=$(git diff --name-only -- "$@"; git ls-files -o --exclude-standard -- "$@")
        if [ -z "$moved" ]; then
            printf '%s\n' "$files" | git hash-object --stdin
            return 0
        fi
        echo "wisp: $package holds $(printf '%s\n' "$moved" | grep -c .) file(s) git's index does not — keyed by the bytes the tree holds" >&2
        git ls-files -co --exclude-standard -- "$@" | LC_ALL=C sort -u | while IFS= read -r f; do
            [ ! -f "$f" ] || printf '%s %s\n' "$(git hash-object -- "$f")" "$f"
        done | { echo "the working tree"; cat; } | git hash-object --stdin
    else
        files=$(find "$package/avra.toml" "$package/src" -type f -not -path '*/tests/*' | sort)
        [ -n "$files" ] || { echo "wisp: no $package here" >&2; exit 1; }
        for f in $files; do printf '%s ' "$f"; cksum < "$f"; done | cksum | tr -d ' '
    fi
}

want_path=0 compiler=
if [ -n "${AVRA_TOOLS_COMPILER:-}" ]; then
    echo "wisp: AVRA_TOOLS_COMPILER is deprecated — pass ./wisp --compiler <avra>" >&2
    compiler=$AVRA_TOOLS_COMPILER
fi
while :; do
    case "${1:-}" in
        --key) key; exit 0 ;;
        --path) want_path=1; shift ;;
        --compiler) compiler=${2:?wisp: --compiler takes a path}; shift 2 ;;
        *) break ;;
    esac
done

# A COMPILER FINDS ITS STD ROOT AND ITS TOOLCHAIN BESIDE ITSELF (`<self>/../packages`),
# so it builds from a copy standing in the tree's build/, after the runtime library
# and the reached packages' objects it links. A failed build says why, on stderr.
build_wisp() {
    cp "$1" build/wisp-compiler
    make -s build/libavra_runtime.a build/libavra_runtime_uninstrumented.a $(sh tools/manifest_objects.sh --closure "$package") >&2 || { echo "wisp: the runtime library or a std object did not build" >&2; return 1; }
    if out=$(AVRA_PROGRAM_MODE=release build/wisp-compiler build "$package" 2>&1); then
        cp "$(printf '%s\n' "$out" | tail -n 1)" "$bin" && chmod +x "$bin"
    else
        printf '%s\n' "$out" | tail -n 20 >&2
        echo "wisp: $package did not build" >&2
        return 1
    fi
}

# Main's compiler, installed beside (never over) the standing build/avra: main's own
# key, else the newest published (main's key is unpublished until its run proves it).
# A checkout of the PR's ref alone holds no origin/main, so it is fetched first.
main_compiler() {
    git rev-parse -q --verify origin/main >/dev/null 2>&1 ||
        git fetch -q --depth 1 origin main:refs/remotes/origin/main >&2 || true
    python3 tools/compiler_release.py install --into "$dir/compiler" >&2 && return 0
    mkdir -p "$dir/compiler"
    python3 tools/compiler_release.py latest "$dir/compiler/avra" >&2 && chmod +x "$dir/compiler/avra"
}

k=$(key)
dir=build/wisp/$k
bin=$dir/wisp
# A TREE OF PROGRAM'S (tools/work program-base) takes the wisp each landing publishes beside the gate's
# builder (.github/workflows/tools-release.yml) where its key is this tree's, else builds it with this tree's
# own compiler — never with main's or the newest published, which predate program's source and build a tool
# that refuses it. Where neither gives one, it says so here and runs nothing older instead.
if [ ! -x "$bin" ] && pb=$(sh tools/work program-base . 2>/dev/null); then
    mkdir -p "$dir"
    t=$(mktemp -d "${TMPDIR:-/tmp}/wisp.XXXXXX")
    url=https://github.com/avra-lang/avra/releases/download/gate-builder/wisp.tar.gz
    # the published binary is a Linux x86-64 ELF: another machine builds its own with its standing compiler
    if [ "$(uname -s)-$(uname -m)" != Linux-x86_64 ]; then
        fetched="no fetch: $url holds a Linux x86-64 binary and this is $(uname -s)-$(uname -m)"
    elif ! curl -fsSL --retry 2 -m 120 -o "$t/wisp.tar.gz" "$url" 2>/dev/null; then
        fetched="$url did not download"
    elif ! tar -xzf "$t/wisp.tar.gz" -C "$t" "build/wisp/$k/wisp" 2>/dev/null; then
        fetched="$url holds no wisp of this key (it carries the last landing's)"
    else
        fetched=""
    fi
    if [ -z "$fetched" ]; then
        cp "$t/build/wisp/$k/wisp" "$bin" && chmod +x "$bin"
        echo "wisp: the wisp of key $(printf '%.12s' "$k") published beside the gate's builder" >&2
    fi
    find "$t" -delete
    c=$compiler
    if [ ! -x "$bin" ] && [ -z "$c" ] && [ -x build/avra ] &&
        [ "$(cut -d' ' -f1 build/.avra-built-from 2>/dev/null)" = "$(sh tools/work built-from . | cut -d' ' -f1)" ]; then
        c=build/avra
    fi
    if [ ! -x "$bin" ] && [ -n "$c" ] && [ -x "$c" ]; then
        build_wisp "$c" && echo "wisp: wisp of key $(printf '%.12s' "$k") built by $c" >&2 || :
    fi
    if [ ! -x "$bin" ]; then
        if [ -n "$c" ]; then why="$c did not build it (above)"; else why="no compiler of this tree's source stands here to build it"; fi
        echo "wisp: a tree of program's (merge-base $(printf '%.8s' "$pb")): no wisp of key $(printf '%.12s' "$k") — $fetched, and $why; nothing older is run instead" >&2
        exit 1
    fi
fi
# THE PUBLISHED BINARIES ARE LINUX X86-64 ELFs: another machine cannot run them, so it builds its own.
published=0
[ "$(uname -s)-$(uname -m)" = Linux-x86_64 ] && published=1
if [ ! -x "$bin" ] && [ "$published" = 1 ]; then
    mkdir -p "$dir"
    python3 tools/compiler_release.py --asset wisp fetch "wisp-$k" "$bin" >&2 && chmod +x "$bin" || true
fi
if [ ! -x "$bin" ] && [ -z "$compiler" ]; then
    if [ "$published" = 1 ]; then
        main_compiler && compiler="$dir/compiler/avra" || true
    elif [ -x build/avra ]; then
        mkdir -p "$dir"
        compiler=build/avra
    fi
fi
if [ ! -x "$bin" ] && [ -n "$compiler" ] && [ -x "$compiler" ]; then
    mkdir -p "$dir"
    build_wisp "$compiler" || true
fi
if [ "$want_path" = 1 ]; then [ -x "$bin" ] && echo "$bin" || exit 1; exit 0; fi
if [ -x "$bin" ]; then exec "$bin" "$@"; fi
cmd=$(printf '%s' "${1:?wisp: a command}" | tr - _)
shift
[ -f "tools/$cmd.py" ] || { echo "wisp: no binary for key $k, and no Python $cmd to answer — the reasons are above" >&2; exit 1; }
echo "wisp: no binary for key $k — the Python $cmd answers" >&2
exec python3 "tools/$cmd.py" "$@"
