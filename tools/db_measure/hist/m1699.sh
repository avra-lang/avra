#!/bin/sh
# Independent memory receipts on current origin/main: .195 one-file test
# (#497) and cold check packages/cli (#500). #506 is not merged.
set -u
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-6000}
tree=$(pwd)
out=build/m1699
pkg=packages/cli
mkdir -p "$out"
aside() { find "$tree" "$tree/$pkg" -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null; }
[ -x build/avra ] || { echo "no build/avra"; exit 1; }

echo "== .195 one-file test: expr_gathered_test.av =="
aside
AVRA_MEM_STATS=1 build/avra test packages/std-avrac/src/core/tests/expr_gathered_test.av > "$out/test.out" 2> "$out/test.mem"
echo "test exit=$?"
grep -aE "^mem:" "$out/test.mem" | head -10
python3 tools/memsites.py build/avra "$out/test.mem" 2>/dev/null | head -8

echo "== #500 cold check packages/cli =="
aside
AVRA_MEM_STATS=1 build/avra check "$pkg" > /dev/null 2> "$out/check.mem"
echo "check exit=$?"
grep -aE "^mem:" "$out/check.mem" | head -10
python3 tools/memsites.py build/avra "$out/check.mem" 2>/dev/null | head -6

echo "== .195 one-file test: runtime_reach_test.av =="
aside
AVRA_MEM_STATS=1 build/avra test packages/std-avrac/src/core/tests/runtime_reach_test.av > "$out/reach.out" 2> "$out/reach.mem"
echo "reach exit=$?"
grep -aE "^mem:" "$out/reach.mem" | head -10
python3 tools/memsites.py build/avra "$out/reach.mem" 2>/dev/null | head -8
echo "== done =="
