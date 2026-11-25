#!/bin/sh
# One lane's work, landed alone: replayed onto the landed head, gated on GitHub, landed when green.
#   sh .lead/land_lane.sh <name> <bundle> <ref> [--no-wait]
# Green: origin `program` and the release builder move to it. Red: the failing slices print, nothing moves.
set -eu
name=$1 bundle=$2 ref=$3
land=/Users/tristan/projects/tristanMatthias/avra-ho-land
main=/Users/tristan/projects/tristanMatthias/avra
scratch=${TMPDIR:-/tmp}/land-$name
cd "$land"

git fetch -q "$bundle" "$ref"
tip=$(git rev-parse FETCH_HEAD)
head=$(git rev-parse program)
picks=$(git rev-list --reverse --no-merges "$head..$tip")
[ -n "$picks" ] || { echo "land: $name has nothing past the landed head"; exit 1; }

[ -d "$scratch" ] || git worktree add -q --detach "$scratch" "$head"
cd "$scratch"
git checkout -q -f --detach "$head"
for c in $picks; do
    git cherry-pick -x "$c" >/dev/null 2>&1 && continue
    if [ -z "$(git diff --name-only --diff-filter=U)" ] && git diff --cached --quiet; then
        git cherry-pick --skip >/dev/null 2>&1; continue
    fi
    git cherry-pick --abort
    echo "land: $name does not replay onto the landed head at $c — back to the lane"; exit 1
done
src=$(git rev-parse HEAD)
cd "$land"
git update-ref "refs/lanes/$name/landing" "$src"

mirror=$(git commit-tree "${src}^{tree}" -p program-gh -m "land: $name at $src")
branch=gate/lane-$name-$(echo "$src" | cut -c1-8)
git push -q origin "${mirror}:refs/heads/$branch" 2>&1 | grep -v -iE 'token|pull request|visiting|^remote: *$' || true
echo "land: $name gating as $branch (source $src)"
[ "${4:-}" = "--no-wait" ] && exit 0

sleep 30
run=$(gh run list --repo avra-lang/avra --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch "$run" --repo avra-lang/avra --interval 120 > /dev/null 2>&1 || true
bad=$(gh run view "$run" --repo avra-lang/avra --json jobs --jq '.jobs[] | select(.conclusion != "success" and .conclusion != "skipped") | .name')
if [ -n "$bad" ]; then
    echo "land: $name RED (run $run) — back to the lane:"; echo "$bad"; exit 1
fi

[ "$(git rev-parse "${mirror}^")" = "$(git rev-parse program-gh)" ] || { echo "land: program-gh moved under the gate; re-run"; exit 1; }
git push -q origin "${mirror}:refs/heads/program" 2>&1 | grep -v -iE 'token|^remote: *$' || true
git update-ref refs/heads/program-gh "$mirror"
git update-ref refs/heads/program "$src" "$head"
git -C "$main" merge -q --ff-only "$src"
pack=$(mktemp -d)
gh run download "$run" --repo avra-lang/avra -n gate-pack -D "$pack" >/dev/null 2>&1 \
    && gh release upload gate-builder "$pack"/compiler-*.tar.gz#compiler.tar.gz --repo avra-lang/avra --clobber >/dev/null 2>&1 \
    && echo "land: release builder is $name's compiler" || echo "land: release builder NOT updated"
find "$pack" -delete
git push -q origin --delete "$branch" 2>&1 | grep -v -i token || true
echo "land: $name LANDED — program is $src"
