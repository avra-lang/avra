# nodes_round.sh <suites…>: witnesses, probes, suites, then a second generation
sh nodes_run.sh
sh nodes_probe.sh | grep -E "^(SAME|DIFF)|^[<>]"
for d in "$@"; do echo "== $d"; ./avra test packages/std-avrac/src/features/$d 2>&1 | grep -E "proved|failed|FAIL|passed|watch:" | tail -n 4; done
echo "== gen2"; cp build/avra build/avra.gen1; make -s avra > /tmp/gen2.log 2>&1; echo "make avra $?"; tail -n 3 /tmp/gen2.log; cmp build/avra build/avra.gen1 && echo GEN2-IDENTICAL
echo "== tree fmt"; find packages -name '*.av' -not -path '*/build/*' | xargs build/avra fmt --check 2>&1 | tail -n 3
