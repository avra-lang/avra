#!/bin/sh
# read_cost.sh in the base tree ab.sh unpacked: sh .../base_read_cost.sh <base sha>
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
cd "$HOME/dbm-hist/$1" && cp build/avra.gen2 build/avra && sh tools/db_measure/read_cost.sh
