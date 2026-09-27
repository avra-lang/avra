#!/bin/sh
# WHETHER THE COMMITTED SEED NAMES THE COMMITTED TREE. `make seed` records
# the source set's hash beside the seed, and the Sprite fast path — the
# seed taken whole, no build — is honest only while that hash IS the
# tree's. `make sprite-check` compares the same hashes before taking it,
# so a seed that LAGS the tree costs a fresh Sprite one build, never a
# wrong compiler. What keeps the tree buildable is `seed-check`'s other
# half, "the seed compiles HEAD", which stays a hard gate. So a lagging
# seed is REPORTED here and refreshed on a cadence, not on every landing,
# because a refresh per landing conflicts every other branch on the seed.
# SEED_STRICT=1 restores the refusal, for a release.
#
# HEAD-VS-HEAD. When there is history, BOTH sides are read from HEAD, so
# a dirty working tree never fires this: the guard asks one question,
# "does the committed seed name the committed tree", and a dev-time
# mismatch is not that question.
#
# AND IT SAYS WHICH MODE IT RAN. A Sprite is a synced copy with no git,
# so there the comparison is the synced tree against its own
# bootstrap/seed.sources — the same question about the content that is
# actually gate-ing. A guard that silently changes what it compares is
# the class it exists to catch.
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if git rev-parse --git-dir >/dev/null 2>&1; then
    where="HEAD"
    want="$(sh tools/sources_hash.sh --head)"
    got="$(git show HEAD:bootstrap/seed.sources 2>/dev/null || true)"
else
    where="this tree (no git history here)"
    want="$(sh tools/sources_hash.sh)"
    got="$(cat bootstrap/seed.sources 2>/dev/null || true)"
fi

if [ "$want" != "$got" ]; then
    echo "seed-guard: the committed seed LAGS $where — a fresh Sprite takes one build, not the fast path"
    echo "seed-guard:   tree $want"
    echo "seed-guard:   seed $got"
    echo "seed-guard: \`make seed\` on a CLEAN tree restores the fast path (commit bootstrap/seed.ll"
    echo "seed-guard: and bootstrap/seed.sources together); whether the seed still COMPILES HEAD is checked next"
    if [ "${SEED_STRICT:-0}" = "1" ]; then exit 1; fi
    exit 0
fi
echo "seed-guard: the seed IS $where ($want)"
