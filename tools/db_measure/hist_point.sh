#!/bin/sh
# ONE HISTORIC POINT of the one-edit curve. Run on a Sprite, from a tree
# that carries tools/db_measure/hist/<sha>.tar.gz (a `git archive` of that
# commit):  sh tools/db_measure/hist_point.sh <sha> [rounds]
# The commit is unpacked beside the tree, its compiler bootstrapped from its
# OWN seed and rebuilt twice from its own source (the generation law), and
# warm_edit.sh — this tree's copy, one instrument for every point — run over it.
set -u
sha=$1
R=${2:-3}
here=$(cd "$(dirname "$0")" && pwd)
at=$HOME/dbm-hist/$sha
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_WATCH_HELD=1 AVRA_MEM_CEILING_MB=5000
if [ ! -x "$at/build/avra.gen2" ]; then
    mkdir -p "$at" && tar -xzf "$here/hist/$sha.tar.gz" -C "$at" || exit 2
    cd "$at" || exit 2
    t0=$(date +%s)
    make bootstrap > build.log 2>&1 || { mkdir -p build; echo "bootstrap failed"; tail -n 30 build.log; exit 3; }
    make avra >> build.log 2>&1 || { echo "second build failed"; tail -n 30 build.log; exit 3; }
    cp build/avra build/avra.gen2
    echo "built	$sha	$(($(date +%s) - t0))s"
fi
cd "$at" || exit 2
sh "$here/warm_edit.sh" "$R"
