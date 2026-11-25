#!/bin/sh
. /etc/profile.d/avra.sh
S=/tmp/claude-0/gate55.sum; : > $S
cd /work/b53
cp -pn /work/ctx-wt/build/*.o build/ 2>/dev/null
timeout 1200 build/avra-try test packages/std-avrac/src/features/ctxs/tests > /tmp/claude-0/x-ctx.log 2>&1; echo "ctx programs exit $? $(tail -1 /tmp/claude-0/x-ctx.log)" >> $S
AVRA_BIN=build/avra-try sh tools/witness_program_refusal.sh build/avra-try $(ls tools/program-refusals | grep ctx) > /tmp/claude-0/x-ctxcases.log 2>&1; echo "ctx cases: $(tail -1 /tmp/claude-0/x-ctxcases.log)" >> $S
for prog in /tmp/claude-0/irdiff/closures.av /tmp/claude-0/irdiff/term/src/main.av /tmp/claude-0/irdiff/knob/src/main.av ui-board board; do
  case $prog in ui-board) rel=tools/ui-board/src/main.av;; board) rel=packages/std-ui/src/tests/board/board.av;; *) rel=;; esac
  a=${rel:+/work/b53a2/$rel}; a=${a:-$prog}; b=${rel:+/work/b53/$rel}; b=${b:-$prog}
  n=$(echo $prog | tr '/' '_')
  (cd /work/b53a2 && AVRA_PROGRAM_NET=0 timeout 900 build/avra-try ir $a > /tmp/claude-0/irdiff/x.$n.base.ir 2>&1)
  (cd /work/b53 && AVRA_PROGRAM_NET=0 timeout 900 build/avra-try ir $b > /tmp/claude-0/irdiff/x.$n.a2.ir 2>&1)
  for t in base a2; do sed -E 's/lambda-?[0-9]+\$/lambda#$/g; s/^(  [0-9]+: \["[^"]*", )[0-9]+, [0-9]+\]/\1#, #]/' /tmp/claude-0/irdiff/x.$n.$t.ir > /tmp/claude-0/irdiff/x.$n.$t.norm; done
  echo "ir $prog: $(wc -l < /tmp/claude-0/irdiff/x.$n.a2.ir) lines, normalized diff $(diff /tmp/claude-0/irdiff/x.$n.base.norm /tmp/claude-0/irdiff/x.$n.a2.norm | wc -l)" >> $S
  find /tmp/claude-0/irdiff -maxdepth 1 -name "x.$n.*" -delete
done
AVRA_PROGRAM_NET=0 build/avra-try build packages/cli > /tmp/claude-0/x-net0.log 2>&1; echo "cli NET=0 exit $?" >> $S
find packages/cli/src -maxdepth 1 \( -name main -o -name main.av.ll \) -delete
AVRA_SUITE_ALL=1 build/avra-try test packages/std-ui > /tmp/claude-0/x-ui.log 2>&1; echo "std-ui exit $? $(grep -E 'tests passed|programs? proved' /tmp/claude-0/x-ui.log | tr '\n' ' ')" >> $S
AVRA_BIN=build/avra-try AVRA_SUITE_ALL=1 build/avra-try test packages/cli > /tmp/claude-0/x-cli.log 2>&1; echo "cli suite exit $? $(grep -E 'tests passed' /tmp/claude-0/x-cli.log | tr '\n' ' ')" >> $S
AVRA_PROGRAM=0 AVRA_MEM_CEILING_MB=12000 build/avra-try check packages/cli --baseline tools/idioms.baseline > /tmp/claude-0/x-idioms-cli.log 2>&1; echo "idioms cli exit $?" >> $S
build/avra-try check packages/std-ui --baseline tools/idioms.baseline > /tmp/claude-0/x-idioms-ui.log 2>&1; echo "idioms std-ui exit $?" >> $S
AVRA_MEM_POOL_MB=15000 AVRA_PROGRAM=0 AVRA_MEM_CEILING_MB=14000 build/avra-try check packages/std-avrac --baseline tools/idioms.baseline > /tmp/claude-0/x-idioms-avrac0.log 2>&1; echo "idioms std-avrac (old path) exit $? ctx.old_path: $(grep -c 'error\[ctx.old_path\]' /tmp/claude-0/x-idioms-avrac0.log)" >> $S
AVRA_SUITE_ALL=1 AVRA_MEM_POOL_MB=15000 AVRA_MEM_CEILING_MB=14000 build/avra-try test packages/std-avrac > /tmp/claude-0/x-avrac.log 2>&1; echo "std-avrac exit $? $(grep -E "tests passed|programs? proved" /tmp/claude-0/x-avrac.log | tr "\n" " ")" >> $S
AVRA_BIN=build/avra-try sh tools/witness_program_refusal.sh build/avra-try > /tmp/claude-0/x-refusal.log 2>&1; echo "refusal: $(grep 'cases hold' /tmp/claude-0/x-refusal.log | tail -1)" >> $S
make rt-ns 2>&1 | tail -1 >> $S
make rt-header 2>&1 | tail -1 >> $S
build/avra-try fmt --check $(git diff --name-only batch53 -- '*.av') > /tmp/claude-0/x-fmt.log 2>&1; echo "fmt exit $? $(tail -1 /tmp/claude-0/x-fmt.log)" >> $S
echo DONE >> $S
