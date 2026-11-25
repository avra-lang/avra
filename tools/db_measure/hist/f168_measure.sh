#!/bin/sh
# avra-8sb5.57.168, part two: build the base (origin/main's two files,
# carried in hist/f168_base_*.av) if absent, then memory and speed A/B
# over one cold check packages/cli each. The candidate binary and the
# targeted test results are already in build/f168/ from part one.
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

[ -x build/avra.cand168 ] || { echo "no candidate binary"; exit 1; }

if [ ! -x build/avra.base168 ]; then
  echo "== base: origin/main's two files, two generations =="
  cp "$facts" "$out/head_facts.av"
  cp "$voices" "$out/head_voices.av"
  cp "$hist/f168_base_facts.av" "$facts"
  cp "$hist/f168_base_voices.av" "$voices"
  cp build/avra.cand168 build/avra
  make try > "$out/base1.log" 2>&1 || { echo "BASE gen1 FAILED"; tail -n 30 "$out/base1.log"; cp "$out/head_facts.av" "$facts"; cp "$out/head_voices.av" "$voices"; exit 1; }
  cp build/avra-try build/avra
  make try > "$out/base2.log" 2>&1 || { echo "BASE gen2 FAILED"; tail -n 30 "$out/base2.log"; cp "$out/head_facts.av" "$facts"; cp "$out/head_voices.av" "$voices"; exit 1; }
  cp build/avra-try build/avra.base168
  cp "$out/head_facts.av" "$facts"
  cp "$out/head_voices.av" "$voices"
  echo "base built"
else
  echo "base binary already present"
fi

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
