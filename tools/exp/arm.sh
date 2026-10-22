#!/bin/sh
# the arm's witness in both engines under AVRA_MEM_STATS, then the keepers that read rows and hosts
[ -d tools ] || { echo "not at the tree root"; exit 70; }
[ -x build/avra ] || { echo "build/avra missing"; exit 70; }
echo "tree: $(git rev-parse --short HEAD 2>/dev/null)"
p=packages/std-avrac/src/compiler/tests/changes_take
build/avra run $p/changes_take.av > /tmp/eval.out 2>/tmp/eval.err; echo "eval status $?"; cat /tmp/eval.out; head -3 /tmp/eval.err | cut -c1-200
build/avra build $p/changes_take.av > /tmp/nat.build 2>&1; echo "build status $?"; tail -1 /tmp/nat.build | cut -c1-200
bin=$(tail -1 /tmp/nat.build); AVRA_MEM_STATS=1 $bin > /tmp/nat.out 2>/tmp/nat.err; echo "native status $?"; cat /tmp/nat.out; cat /tmp/nat.err | head -20 | cut -c1-200
diff $p/changes_take.expected /tmp/eval.out > /dev/null && echo "eval == expected" || echo "eval DIFFERS"
diff $p/changes_take.expected /tmp/nat.out > /dev/null && echo "native == expected" || echo "native DIFFERS"
for t in inputs vocab externs rt-ns rt-header; do make $t > /tmp/mk.$t.log 2>&1 && v=PASS || v=FAIL; echo "$v make $t"; tail -3 /tmp/mk.$t.log | cut -c1-250; done
