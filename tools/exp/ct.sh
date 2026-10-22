#!/bin/sh
[ -d tools ] || { echo "not at the tree root"; exit 70; }
echo "tree: $(git rev-parse --short HEAD)"
for n in changes_take changes_take_lists changes_take_maps changes_take_records; do
  p=packages/std-avrac/src/compiler/tests/$n
  echo "== $n"
  build/avra run $p/$n.av > /tmp/ct.eval 2>/tmp/ct.eval.err; echo "eval status $?"; cat /tmp/ct.eval; grep -a "^avra:\|^error\|defect\|trap" /tmp/ct.eval.err | head -4 | cut -c1-300; tail -n 3 /tmp/ct.eval.err | cut -c1-300
  build/avra build $p/$n.av > /tmp/ct.build 2>&1; echo "build status $?"
  bin=$(tail -1 /tmp/ct.build)
  AVRA_MEM_STATS=1 $bin > /tmp/ct.nat 2>/tmp/ct.nat.err; echo "native status $?"; cat /tmp/ct.nat; grep -a "live\|^error" /tmp/ct.nat.err | head -3
  diff $p/$n.expected /tmp/ct.eval > /dev/null && echo "eval == expected" || { echo "eval DIFFERS from expected"; diff $p/$n.expected /tmp/ct.eval; }
  diff /tmp/ct.eval /tmp/ct.nat > /dev/null && echo "eval == native" || echo "eval DIFFERS from native"
done
