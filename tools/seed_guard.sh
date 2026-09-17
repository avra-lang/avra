#!/bin/sh
# THE COMMITTED SEED MUST NAME THE COMMITTED TREE. `make seed` records
# the source set's hash beside the seed, and the fast path — a fresh
# Sprite takes the seed whole, no build — is honest only while that hash
# IS the tree's. A committed seed naming a different tree is the lie the
# seed mechanism exists to prevent, and the fast path must never be
# taken on it.
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
    echo "seed-guard: the committed seed names a DIFFERENT tree than $where"
    echo "seed-guard:   tree $want"
    echo "seed-guard:   seed $got"
    echo "seed-guard: a committed seed that is not this tree makes the fast path a lie"
    echo "seed-guard: run \`make seed\` on a CLEAN tree, commit bootstrap/seed.ll"
    echo "seed-guard: and bootstrap/seed.sources together, and re-gate"
    exit 1
fi
echo "seed-guard: the seed IS $where ($want)"
