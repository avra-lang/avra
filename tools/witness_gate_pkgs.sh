#!/bin/sh
# THE PKGS FAMILY REACHES WHAT IMPORTS A CHANGE: a commit that touches std-http alone selects
# std-queue_store's suite (it imports `@std.http` with no manifest row) and no suite a slice names
# (std-http's own is doors-b's). Over a worktree of HEAD with that commit made, this tree's own
# `gate.sh pkgs-suites` and the closure it reads — so what it judges is the selection the tree holds now.
#   sh tools/witness_gate_pkgs.sh
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-pkgs-witness.XXXXXX")
trap 'git worktree remove --force "$work/tree" >/dev/null 2>&1 || :; find "$work" -delete 2>/dev/null || :' EXIT
git worktree add -q --detach "$work/tree" HEAD
mkdir -p "$work/tree/build"
[ ! -d build/wisp ] || cp -R build/wisp "$work/tree/build/"
[ ! -x build/avra ] || cp build/avra build/.avra-built-from "$work/tree/build/" 2>/dev/null || :
cd "$work/tree"
echo "// a change std-http alone holds" >> packages/std-http/src/assets.av
git -c user.email=witness@avra -c user.name=witness commit -qam "witness: std-http alone"
cp "$root/tools/gate.sh" "$root/tools/affected_packages.sh" tools/
sh tools/gate.sh pkgs-suites HEAD~1 > "$work/picked" || { echo "witness_gate_pkgs: pkgs-suites refused" >&2; exit 1; }
n=$(wc -l < "$work/picked" | tr -d ' ')
grep -qx packages/std-queue_store "$work/picked" || { cat "$work/picked"; echo "witness_gate_pkgs: a std-http change did not select std-queue_store" >&2; exit 1; }
if grep -qxE 'packages/(std-http|std-ui|std-avrac|cli)' "$work/picked"; then
    cat "$work/picked"
    echo "witness_gate_pkgs: the family selected a suite a slice names" >&2
    exit 1
fi
echo "witness_gate_pkgs: a std-http change selects std-queue_store among $n suites, and none a slice names"
