#!/bin/sh
# EVERY PACKAGE, one name a line: each directory under packages/. A package
# with no src/ is refused, since a run over every package would pass it by
# untested.
#
#   sh tools/packages.sh
#   sh tools/packages.sh --self-test
# A root other than the tree is `PACKAGES_ROOT=<dir>`.

root="${PACKAGES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

packages() {
    for d in "$root"/packages/*/; do
        [ -d "${d}src" ] || { echo "${GITHUB_ACTIONS:+::error::}packages/$(basename "$d") has no src — a run over every package would pass it by untested" >&2; return 1; }
    done
    for d in "$root"/packages/*/; do basename "$d"; done
}

self_test() {
    t=$(mktemp -d) || exit 1
    trap 'find "$t" -delete' EXIT
    fails=0
    mkdir -p "$t/packages/a/src" "$t/packages/b/src"
    got=$(PACKAGES_ROOT=$t sh "$0" | tr '\n' ' ')
    [ "$got" = "a b " ] || { fails=$((fails + 1)); echo "packages: FAIL — every package: got '$got'"; }
    mkdir -p "$t/packages/c"
    PACKAGES_ROOT=$t sh "$0" > /dev/null 2>&1 && { fails=$((fails + 1)); echo "packages: FAIL — a package with no src was listed"; }
    [ "$fails" = 0 ] || exit 1
    echo "packages: self-test passed — 2 fixtures (every package, one with no src refused)"
}

case "$1" in
    --self-test) self_test ;;
    "") packages ;;
    *) echo "usage: sh tools/packages.sh [--self-test]" >&2; exit 2 ;;
esac
