#!/bin/sh
# THE TOOLS PACKAGE'S KEY: a hash of what git holds under tools/'s Avra
# package (its manifest and `src/`). One key is one source, so a published
# `avra-tools` under it is immutable, and a PR that does not touch the
# package has main's key.
#
#   sh tools/tools_key.sh [<root>]
set -eu
cd "${1:-.}"
if git rev-parse --git-dir >/dev/null 2>&1; then
    files=$(git ls-files -s -- tools/avra.toml tools/src ':(exclude,glob)**/tests/**')
    [ -n "$files" ] || { echo "tools_key: git lists no tools package here" >&2; exit 1; }
    printf '%s\n' "$files" | git hash-object --stdin
else
    # a tree with no .git (a Sprite's copy): the same files, hashed by content
    files=$(find tools/avra.toml tools/src -type f -not -path '*/tests/*' | sort)
    [ -n "$files" ] || { echo "tools_key: no tools package here" >&2; exit 1; }
    for f in $files; do printf '%s ' "$f"; cksum < "$f"; done | cksum | tr -d ' '
fi
