#!/bin/sh
# tool-witness: run by keepers
# A KEEPER SHOWN TO REFUSE: the keeper a plant names, run over a copy of this tree (HEAD, as a
# worktree of its own) with that one fault planted in what the keeper judges. It holds — exit 0 —
# only where the keeper refuses AND its words name the plant; a keeper that passes over its fault,
# or refuses for some other reason, fails the row. Each part of the gate's keepers slices ends with
# one, so a part whose runner swallowed a refusal is no part that passes.
#
#   sh tools/keeper_planted.sh <plant>      a plant of PLANTS
#   sh tools/keeper_planted.sh --list       each plant, one a line
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
PLANTS="pipeline-doc http-cites tail-status workflows-yaml"
if [ "${1:-}" = --list ]; then printf '%s\n' $PLANTS; exit 0; fi
plant=${1:?a plant: one of $PLANTS}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/avra-keeper-planted.XXXXXX")
tree="$tmp/tree"
ended() {
    git -C "$root" worktree remove --force "$tree" > /dev/null 2>&1 || :
    find "$tmp" -delete 2> /dev/null || :
    git -C "$root" worktree prune > /dev/null 2>&1 || :
}
trap ended EXIT
git -C "$root" worktree add -q --detach "$tree" HEAD || { echo "keeper_planted: no worktree of HEAD at $tree"; exit 1; }
cd "$tree" || exit 1
# each plant: the fault written into the copy, and the words the keeper's refusal must hold
case $plant in
    pipeline-doc)
        printf '\nPlanted: `tools/planted_missing.sh` runs the planted step.\n' >> docs/2026_10_11_THE_PIPELINE.md
        word='tools/planted_missing.sh'
        ;;
    http-cites)
        sed -i.planted 's/C › "a HEAD route answers before the GET route"/C › "a planted case no suite holds"/' docs/2026_09_29_HTTP_CONFORMANCE.md
        word='a planted case no suite holds'
        ;;
    tail-status)
        printf '#!/bin/sh\nmake -s planted 2>&1 | tail -n 3\n' > tools/planted_tail.sh
        word='planted_tail.sh'
        ;;
    workflows-yaml)
        printf 'name: planted\non: [push]\njobs:\n  planted:\n    runs-on: ubuntu-latest\n    steps:\n      - name: planted: a colon unquoted\n        run: echo planted\n' > .github/workflows/planted.yml
        word='planted.yml'
        ;;
    *) echo "keeper_planted: no plant named $plant — one of $PLANTS"; exit 1 ;;
esac
out=$(make -s -o avra "$plant" 2>&1)
st=$?
if [ "$st" = 0 ]; then
    echo "keeper_planted: $plant PASSED over its planted fault — a keeper that can't refuse proves nothing"
    printf '%s\n' "$out" | tail -n 5
    exit 1
fi
if ! printf '%s\n' "$out" | grep -qF "$word"; then
    echo "keeper_planted: $plant refused, but not at its plant (\`$word\`) — it refused for another reason:"
    printf '%s\n' "$out" | tail -n 5
    exit 1
fi
echo "keeper_planted: $plant refused its planted fault, naming it (\`$word\`)"
