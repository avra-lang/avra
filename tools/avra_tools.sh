#!/bin/sh
# THE TREE'S INSTRUMENTS, RUN: `avra-tools <command> …`, the one program
# the Avra ports of tools/*.py are commands of (tools/avra.toml).
#
#   sh tools/avra_tools.sh <command> [args…]   # stdin and the status pass through
#   sh tools/avra_tools.sh --path              # where the binary stands, built if need be
#
# A KEEPER IS NEVER JUDGED BY THE COMPILER UNDER TEST. The binary is main's:
# built by main's compiler from the package's source and published beside the
# compiler under `tools-<key>` (tools/tools_key.sh, tools/compiler_release.py).
# Resolved in order:
#   1. build/avra-tools/<key>/avra-tools, already here;
#   2. the published asset for the key, fetched;
#   3. built here by $AVRA_TOOLS_COMPILER, else by main's published compiler
#      (tools/fetch_compiler.sh, into $dir/compiler), for a tree whose tools/
#      differs from anything published — run from build/, where a compiler stands;
#   4. the Python tool of the same name (tools/<command with _>.py), while no
#      binary answers — said on stderr, so a fallback is never silent.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"
if [ "${1:-}" = --path ]; then want_path=1; shift; else want_path=0; fi

# The std packages the `use` lines under a directory name, test files aside.
uses() {
    find "$1" -name '*.av' -not -path '*/tests/*' -exec sed -n 's/^\(export \)\{0,1\}use @std\.\([a-z_]*\).*/\2/p' {} + | sort -u
}

# The objects the `[link]` rows of every std package tools/src reaches name.
link_objects() {
    seen=" "
    todo=$(uses tools/src)
    while [ -n "$todo" ]; do
        set -- $todo
        p=$1
        shift
        todo="$*"
        case "$seen" in *" $p "*) continue ;; esac
        seen="$seen$p "
        [ -d "packages/std-$p/src" ] && todo="$todo $(uses "packages/std-$p/src")"
    done
    for p in $seen; do
        sed -n 's/.*objects *= *\[\(.*\)\].*/\1/p' "packages/std-$p/avra.toml" 2>/dev/null
    done | tr ',' '\n' | tr -d ' "' | sed -n 's|.*/|build/|p' | sort -u
}

# A COMPILER FINDS ITS STD ROOT AND ITS TOOLCHAIN BESIDE ITSELF (`<self>/../packages`),
# so it builds from a copy standing in the tree's build/, after the runtime library
# and the reached packages' objects it links. A failed build says why, on stderr.
build_tools() {
    cp "$1" build/avra-tools-compiler
    make -s build/libavra_runtime.a $(link_objects) >&2 || return 1
    if out=$(build/avra-tools-compiler build tools 2>&1); then
        cp "$(printf '%s\n' "$out" | tail -n 1)" "$bin" && chmod +x "$bin"
    else
        printf '%s\n' "$out" | tail -n 20 >&2
        return 1
    fi
}
key=$(sh tools/tools_key.sh)
dir=build/avra-tools/$key
bin=$dir/avra-tools
if [ ! -x "$bin" ]; then
    mkdir -p "$dir"
    python3 tools/compiler_release.py --asset avra-tools fetch "tools-$key" "$bin" >/dev/null 2>&1 && chmod +x "$bin" || true
fi
if [ ! -x "$bin" ] && [ -z "${AVRA_TOOLS_COMPILER:-}" ]; then
    # no compiler named: main's published one, installed beside (never over) the standing build/avra;
    # a checkout of the PR's ref alone holds no origin/main, so it is fetched first
    git rev-parse -q --verify origin/main >/dev/null 2>&1 ||
        git fetch -q --depth 1 origin main:refs/remotes/origin/main >&2 || true
    FETCH_BUILD="$dir/compiler" sh tools/fetch_compiler.sh >&2 && AVRA_TOOLS_COMPILER="$dir/compiler/avra" || true
fi
if [ ! -x "$bin" ] && [ -n "${AVRA_TOOLS_COMPILER:-}" ] && [ -x "$AVRA_TOOLS_COMPILER" ]; then
    build_tools "$AVRA_TOOLS_COMPILER" || true
fi
if [ "$want_path" = 1 ]; then [ -x "$bin" ] && echo "$bin" || exit 1; exit 0; fi
if [ -x "$bin" ]; then exec "$bin" "$@"; fi
cmd=$(printf '%s' "${1:?avra_tools: a command}" | tr - _)
shift
echo "avra_tools: no avra-tools for key $key — the Python $cmd answers" >&2
exec python3 "tools/$cmd.py" "$@"
