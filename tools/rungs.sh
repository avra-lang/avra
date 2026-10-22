#!/bin/sh
# tool-witness: --self-test
# THE RUNGS OF A BRANCH: its commits that carry a `Rung: <why>` trailer, oldest first, HEAD excluded
# (HEAD is built by the last rung's product whatever it says). A row and its first reader ride one
# landing as two commits; the first is marked `Rung:`, and CI builds the tree at each mark with the
# product of the one before it, so a compiler is never asked to read what only a newer one can.
#
#   sh tools/rungs.sh <base> <head>     one commit per line, oldest first
#   sh tools/rungs.sh --pr <number>     the same for a landed PR: its head ref against main's parent
#   sh tools/rungs.sh --self-test
set -eu
if [ "${1:-}" = --self-test ]; then
    me=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
    d=$(mktemp -d "${TMPDIR:-/tmp}/avra-rungs.XXXXXX")
    git init -q -b main "$d"
    g() { git -C "$d" -c user.name=t -c user.email=t@t "$@"; }
    echo 0 > "$d/f"; g add -A; g commit -q -m base
    base=$(g rev-parse HEAD)
    echo 1 > "$d/f"; g commit -q -am "row

Rung: the row"
    r1=$(g rev-parse HEAD)
    echo 2 > "$d/f"; g commit -q -am "an ordinary commit mentioning Rung: in prose"
    echo 3 > "$d/f"; g commit -q -am "second row

rung: lower case is no trailer
Rung: the second row"
    r2=$(g rev-parse HEAD)
    echo 4 > "$d/f"; g commit -q -am "reader

Rung: the head itself is no rung"
    got=$(cd "$d" && sh "$me" "$base" HEAD | tr '\n' ' ')
    [ "$got" = "$r1 $r2 " ] || { echo "rungs: wanted '$r1 $r2 ' got '$got'"; exit 1; }
    none=$(cd "$d" && sh "$me" "$base" "$r1" | wc -l | tr -d ' ')
    [ "$none" = 0 ] || { echo "rungs: the head commit counted as a rung"; exit 1; }
    echo "rungs: self-test passed — trailers only, oldest first, HEAD excluded"
    exit 0
fi
if [ "${1:-}" = --pr ]; then
    n=${2:?usage: rungs.sh --pr <number>}
    git fetch -q origin "refs/pull/$n/head:refs/rungs/pr-$n" 2>/dev/null || { echo "rungs: pull/$n/head is not fetchable" >&2; exit 1; }
    set -- "$(git merge-base "refs/rungs/pr-$n" HEAD^)" "refs/rungs/pr-$n"
fi
base=${1:?usage: rungs.sh <base> <head>}
head=${2:-HEAD}
tip=$(git rev-parse "$head")
git rev-list --reverse "$base..$head" | while IFS= read -r c; do
    [ "$c" != "$tip" ] || continue
    git log -1 --format=%B "$c" | grep -q '^Rung: ' && echo "$c"
done
exit 0
