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
#   3. built here by $AVRA_TOOLS_COMPILER (main's published compiler), for a
#      tree whose tools/ differs from anything published;
#   4. the Python tool of the same name (tools/<command with _>.py), while no
#      binary answers — said on stderr, so a fallback is never silent.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"
if [ "${1:-}" = --path ]; then want_path=1; shift; else want_path=0; fi
key=$(sh tools/tools_key.sh)
dir=build/avra-tools/$key
bin=$dir/avra-tools
if [ ! -x "$bin" ]; then
    mkdir -p "$dir"
    python3 tools/compiler_release.py --asset avra-tools fetch "tools-$key" "$bin" >/dev/null 2>&1 && chmod +x "$bin" || true
fi
if [ ! -x "$bin" ] && [ -n "${AVRA_TOOLS_COMPILER:-}" ] && [ -x "$AVRA_TOOLS_COMPILER" ]; then
    built=$("$AVRA_TOOLS_COMPILER" build tools | tail -n 1) && cp "$built" "$bin" && chmod +x "$bin" || true
fi
if [ "$want_path" = 1 ]; then [ -x "$bin" ] && echo "$bin" || exit 1; exit 0; fi
if [ -x "$bin" ]; then exec "$bin" "$@"; fi
cmd=$(printf '%s' "${1:?avra_tools: a command}" | tr - _)
shift
echo "avra_tools: no avra-tools for key $key — the Python $cmd answers" >&2
exec python3 "tools/$cmd.py" "$@"
