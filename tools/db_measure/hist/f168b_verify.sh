#!/bin/sh
# avra-8sb5.57.168 (A): the windowed statement columns. Targeted tests,
# then one cold `check packages/cli` for memory and two for speed.
set -u
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-6000}
tree=$(pwd)
out=build/f168b
pkg=packages/cli
mkdir -p "$out"
aside() { find "$tree" "$tree/$pkg" -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null; }
[ -x build/avra-try ] || { echo "no build/avra-try"; exit 1; }
fails=0
for t in \
 packages/std-avrac/src/features/tests/facts_test.av \
 packages/std-avrac/src/features/tests/decl_facts_test.av \
 packages/std-avrac/src/features/tests/doc_fact_test.av \
 packages/std-avrac/src/compiler/tests/facts_block_test.av \
 packages/std-avrac/src/compiler/tests/facts_family_test.av \
 packages/std-avrac/src/compiler/tests/held_facts_test.av \
 packages/std-avrac/src/features/mutation/tests/mutation_test.av \
 packages/std-avrac/src/features/mutation/tests/mutation_adversarial_test.av \
 packages/std-avrac/src/features/mutation/tests/mutation_mechanical_test.av \
 packages/std-avrac/src/features/let_stmt/tests/let_stmt_test.av \
 packages/std-avrac/src/features/let_stmt/tests/let_stmt_mechanical_test.av ; do
  log="$out/t.$(basename "$t").log"
  build/avra-try test "$t" > "$log" 2>&1
  st=$?
  echo "TEST	$(basename "$t")	status=$st	$(grep -a 'tests passed' "$log")"
  if [ "$st" -ne 0 ]; then
    fails=$((fails + 1))
    grep -a "✗\|^error\|^avra:" -A6 "$log" | head -20 | cut -c1-200
  fi
done
echo "tests failing: $fails"
echo "== memory: one cold check packages/cli =="
aside
AVRA_MEM_STATS=1 build/avra-try check "$pkg" > /dev/null 2> "$out/mem"
grep -aE "^mem:" "$out/mem" | head -12
python3 tools/memsites.py build/avra-try "$out/mem" 2>/dev/null | head -10
echo "== speed: two cold rounds =="
run() { aside; TIMEFORMAT="$1 cold$2 %R real %U user %S sys"; { time build/avra-try check "$pkg" > /dev/null 2>&1 ; } 2>&1; }
run new 1
run new 2
echo "== done =="
