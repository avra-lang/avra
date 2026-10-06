#!/bin/sh
# THE COMPILER'S SOURCE, as paths: packages/cli plus every std package its
# `use @std.x` graph reaches, the runtime, the backend, the seed and the
# Makefile. ONE definition — a lane's Sprite (`tools/work`) and the checks'
# compiler cache both ask it, so "did the compiler change" has one answer.
#
#   sh tools/compiler_paths.sh [<root>]          # one path per line
#   sh tools/compiler_paths.sh --key [<root>]    # a hash of what git holds there
#
# A package's tests/ are never the compiler's: a build never reads them, and
# the key leaves them out. The key reads the INDEX, so it names a commit's
# tree; a caller hashing a dirty tree walks the paths itself.
set -eu
key=0
[ "${1:-}" != --key ] || { key=1; shift; }
cd "${1:-.}"
paths() {
    pending="cli"
    seen=""
    while [ -n "$pending" ]; do
        d=${pending%% *}
        case $pending in *' '*) pending=${pending#* } ;; *) pending= ;; esac
        case " $seen " in *" $d "*) continue ;; esac
        seen="$seen $d"
        [ -d "packages/$d/src" ] || continue
        for dep in $(grep -rhoE 'use +@std\.[A-Za-z0-9_]+' "packages/$d/src" 2>/dev/null | sed -E 's/^use +@std\.//' | sort -u); do
            pending="$pending std-$dep"
        done
    done
    {
        for d in $seen; do [ ! -d "packages/$d/src" ] || echo "packages/$d"; done
        printf '%s\n' Makefile backend runtime bootstrap packages/std-prelude
    } | sort -u
}
if [ "$key" = 1 ]; then
    git ls-files -s -- $(paths) ':(exclude,glob)**/tests/**' | git hash-object --stdin
else
    paths
fi
