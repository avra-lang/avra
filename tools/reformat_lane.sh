#!/bin/sh
# Carry a lane across the one-time layout change. The lane is formatted by
# the NEW printer before the reformat commit is merged, so both sides share
# one layout and only real edits can conflict.
#
#   tools/reformat_lane.sh [<printer-commit> <reformat-commit>]
#
# The 100-column change is P 2b5cb3c (the printer, the tree-walking
# `fmt --write`, the lexer fix) and R a72146d (the tree reformat); with no
# arguments the script carries a lane across exactly that pair.
set -eu
P=${1:-2b5cb3c86b258861c653575b11a50bcabcecc0d1}
R=${2:-a72146de86bdba68d4e941c33c78d40a5d068072}
export LLVM_PREFIX=${LLVM_PREFIX:-/opt/homebrew/opt/llvm} AVRA_WATCH_HELD=1

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "reformat_lane: the tree has uncommitted changes — commit or park them first" >&2
    exit 1
fi

stop() {
    echo "reformat_lane: $1" >&2
    git diff --name-only --diff-filter=U | sed 's/^/  conflicted: /' >&2
    echo "  resolve each real edit, then: ./build/avra fmt --write <file> && git add <file> && git commit" >&2
    exit 1
}

settle_seed() {
    # The seed is regenerated, never merged by hand.
    for s in bootstrap/seed.ll bootstrap/seed.sources; do
        if git diff --name-only --diff-filter=U | grep -qx "$s"; then git checkout --theirs "$s" && git add "$s"; fi
    done
}

build() {
    cp build/avra build/avra.pre
    for _ in 1 2; do
        ./build/avra build packages/cli > build/reformat_lane.log 2>&1 || { cp build/avra.pre build/avra; echo "reformat_lane: the build failed — see build/reformat_lane.log" >&2; exit 1; }
        cp packages/cli/src/main build/avra && codesign -f -s - build/avra 2>/dev/null || true
    done
    rm -f packages/cli/src/main packages/cli/src/main.av.ll
}

if ! git merge --no-edit "$P"; then
    settle_seed
    [ -z "$(git diff --name-only --diff-filter=U)" ] || stop "merging the printer commit conflicted"
    git commit --no-edit -q
fi
build

./build/avra fmt --write packages
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    git commit -qam "style: canonical layout (lane side)"
fi

if ! git merge --no-edit "$R"; then
    settle_seed
    [ -z "$(git diff --name-only --diff-filter=U)" ] || stop "merging the reformat commit left real conflicts"
    git commit --no-edit -q
fi
echo "reformat_lane: done — rebuild twice and run your checks"
