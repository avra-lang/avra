#!/bin/bash
# TWO STORES OVER ONE SOURCE, DIFFED. From a tree's root, on Linux:
#   bash tools/db_measure/store_two.sh
# A: a cold check of the cli. B: one test file checked, then the cli. C: a cold build.
# D: a check, then a build. Each pair's stores are compared key by key by
# store_diff.py: a key on one side only, or one key holding two values, is a store
# that depends on more than the source.
export AVRA_MEM_CEILING_MB=5000 AVRA_WATCH_HELD=1 LLVM_PREFIX=/usr/lib/llvm-22
make -s -o avra objects libs > /dev/null 2>&1
clear() { find . -name .avra-cache -type d -prune -exec rm -rf {} +; }
P=packages/cli; T=packages/cli/src/commands/tests/shared_test.av
snap() { rm -rf /tmp/store_$1; cp -r .avra-cache /tmp/store_$1; }
clear; build/avra check $P > /tmp/outA.txt 2>&1; echo "A check exit $?"; snap A
clear; build/avra check $T > /dev/null 2>&1; build/avra check --time $P > /tmp/outB.txt 2>&1; echo "B check exit $? $(grep -a '^time:' /tmp/outB.txt | grep -o 'held [0-9/]*, attempt [0-9]*, discarded [0-9]*')"; snap B
echo "check output identical: $(diff <(grep -v '^time:\|discarded:\|^read:\|^  ' /tmp/outA.txt) <(grep -v '^time:\|discarded:\|^read:\|^  ' /tmp/outB.txt) > /dev/null && echo yes || echo no)"
echo "== stores after check: A cold, B one test file then the package"
python3 tools/db_measure/store_diff.py /tmp/store_A /tmp/store_B
clear; ./avra build $P > /dev/null 2>&1; rm -f $P/src/main $P/src/main.av.ll; snap C
clear; build/avra check $P > /dev/null 2>&1; ./avra build $P > /dev/null 2>&1; rm -f $P/src/main $P/src/main.av.ll; snap D
echo "== stores after build: C cold build, D check then build"
python3 tools/db_measure/store_diff.py /tmp/store_C /tmp/store_D
echo FIN
