#!/bin/sh
# The stale-embed control with a compiler built from an older main.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
c=$1; here=$(pwd); at=$HOME/old/$c
if [ ! -x "$at/build/avra" ]; then
    mkdir -p "$at" && tar -xzf "$here/tools/db_measure/hist/$c.tar.gz" -C "$at" || exit 2
    (cd "$at" && make bootstrap > build.log 2>&1) || { echo "old compiler did not build"; tail -n 20 "$at/build.log"; exit 3; }
fi
echo "== old compiler $c"
AVRA_BIN=$at/build/avra sh tools/db_measure/stale_embed_ctl.sh
echo "== this tree's compiler, 2-second gap before each data edit"
STALE_GAP=2 sh tools/db_measure/stale_embed_ctl.sh
