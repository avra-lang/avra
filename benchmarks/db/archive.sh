#!/bin/sh
# Packs historic commits for hist_point.sh: sh benchmarks/db/archive.sh <sha...>
# Each lands in benchmarks/db/hist/ (untracked), which `work run` carries to the Sprite.
set -eu
cd "$(dirname "$0")/../.."
mkdir -p benchmarks/db/hist
for c in "$@"; do
    set --
    for p in Makefile avra avra.toml backend runtime packages tools bootstrap; do
        git cat-file -e "$c:$p" 2>/dev/null && set -- "$@" "$p"
    done
    git archive --format=tar.gz -o "benchmarks/db/hist/$c.tar.gz" "$c" "$@"
    echo "$c	$(git show -s --format='%ad	%s' --date=format:'%Y-%m-%d %H:%M' "$c")"
done
