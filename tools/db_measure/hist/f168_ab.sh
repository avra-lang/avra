#!/bin/sh
# avra-8sb5.57.168: the packed flags column, A/B on one Sprite.
# Builds the candidate two generations, runs the fact/mutation/let tables
# against it, builds the base (origin/main's two files, carried in
# hist/f168_base_*.av) two generations for comparison, then measures one
# cold check of packages/cli each: AVRA_MEM_STATS for live bytes by
# category and memsites.py for the making sites, then two cold
# alternating speed rounds. The Sprite has no .git and no ./avra-try
# wrapper, so the binaries are called bare and the base source is copied.
set -u
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-6000}
tree=$(pwd)
hist=tools/db_measure/hist
facts=packages/std-avrac/src/features/facts.av
voices=packages/std-avrac/src/compiler/voices.av
pkg=packages/cli
out=build/f168
mkdir -p "$out"

aside() { find "$tree" "$tree/packages/cli" -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null; }

echo "== candidate: two generations =="
cp build/avra build/avra.pre168
make try > "$out/cand1.log" 2>&1 || { echo "CAND gen1 FAILED"; tail -30 "$out/cand1.log"; exit 1; }
cp build/avra-try build/avra
make try > "$out/cand2.log" 2>&1 || { echo "CAND gen2 FAILED"; tail -30 "$out/cand2.log"; exit 1; }
cp build/avra-try build/avra
cp build/avra build/avra.cand168
echo "candidate built"

echo "== tests: candidate (build/avra-try is the candidate) =="
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
    grep -a "✗\|^error\|^avra:" -A8 "$log" | head -30 | cut -c1-240
  fi
done
echo "tests failing: $fails"

echo "== base: origin/main's two files, two generations =="
cp "$facts" "$out/head_facts.av"
cp "$voices" "$out/head_voices.av"
cp "$hist/f168_base_facts.av" "$facts"
cp "$hist/f168_base_voices.av" "$voices"
make try > "$out/base1.log" 2>&1 || { echo "BASE gen1 FAILED"; tail -30 "$out/base1.log"; cp "$out/head_facts.av" "$facts"; cp "$out/head_voices.av" "$voices"; cp build/avra.cand168 build/avra; exit 1; }
cp build/avra-try build/avra
make try > "$out/base2.log" 2>&1 || { echo "BASE gen2 FAILED"; tail -30 "$out/base2.log"; cp "$out/head_facts.av" "$facts"; cp "$out/head_voices.av" "$voices"; cp build/avra.cand168 build/avra; exit 1; }
cp build/avra-try build/avra.base168
cp "$out/head_facts.av" "$facts"
cp "$out/head_voices.av" "$voices"
cp build/avra.cand168 build/avra
echo "base built; restored head source ($(wc -l < "$facts") + $(wc -l < "$voices") lines)"

echo "== memory: one cold check packages/cli each =="
for label in base cand; do
  bin="build/avra.${label}168"
  aside
  AVRA_MEM_STATS=1 "$bin" check "$pkg" > /dev/null 2> "$out/mem.$label"
  echo "--- $label ---"
  grep -aE "^mem:" "$out/mem.$label" | head -12
  python3 tools/memsites.py "$bin" "$out/mem.$label" 2>/dev/null | head -16
done

echo "== speed: two cold alternating rounds =="
run() {
  aside
  TIMEFORMAT="$1 cold$3 %R real %U user %S sys"
  { time "$2" check "$pkg" > /dev/null 2>&1 ; } 2>&1
}
for i in 1 2; do
  run base build/avra.base168 "$i"
  run cand build/avra.cand168 "$i"
done
echo "== done =="
