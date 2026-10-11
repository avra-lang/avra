#!/bin/sh
# WHETHER THE COMMITTED SEED IS THIS TREE'S COMPILER: the tree's own
# source hash against the hash `make seed` recorded beside the seed.
#
# Equal and non-empty answers `seed`: the seed was emitted from exactly
# this source, so linking it (`make recover`) already yields the compiler
# this tree emits — a self-compile would rebuild, byte for byte, the
# compiler the seed names, which is why `make bootstrap` may stop there.
#
# Unequal answers `twice`: the seed's codegen MAY lag the source, and the
# generation law owes two builds — the source compiled by the seed, then
# that result compiling the source again. An empty or unreadable hash is
# never "equal": a hash that was not computed names no tree.
#
#   sh tools/seed_is_tree.sh <tree-hash> <seed-hash>
#   sh tools/seed_is_tree.sh --self-test
set -eu

if [ "${1:-}" = --self-test ]; then
    fail=0
    check() {
        got=$(sh "$0" "$1" "$2")
        [ "$got" = "$3" ] || { echo "seed_is_tree self-test: '$1'/'$2' -> $got, want $3" >&2; fail=1; }
    }
    check abc abc seed
    check abc def twice
    check "" abc twice
    check abc "" twice
    check "" "" twice
    [ "$fail" = 0 ] || exit 1
    echo "seed_is_tree: self-test passes"
    exit 0
fi

[ $# -eq 2 ] || { echo "usage: sh tools/seed_is_tree.sh <tree-hash> <seed-hash>" >&2; exit 64; }
if [ -n "$1" ] && [ "$1" = "$2" ]; then echo seed; else echo twice; fi
