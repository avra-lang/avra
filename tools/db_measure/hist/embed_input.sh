#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
T=packages/std-avrac/src/compiler
F=packages/std-avrac/src/features
build/avra fmt --check $T/cache_walk.av $T/interface.av $T/record.av $T/host/host.av $T/build.av $T/host/input.av $T/whole.av $T/workspace_analysis.av $T/world.av | tail -n 1
for t in $F/fns/tests/embed_test.av $T/tests/input_door_test.av $T/tests/input_host_test.av $T/tests/world_test.av $T/tests/run_reads_test.av $T/tests/references_refused_test.av; do
    build/avra test "$t" > "$HOME/ei.log" 2>&1; echo "PROOF	$(basename "$t")	status=$?	$(grep -a 'tests passed' "$HOME/ei.log")"
    grep -a "✗\|^error\|^avra:" -A8 "$HOME/ei.log" | head -n 30 | cut -c1-260
done
sh tools/cache_attacks.sh > "$HOME/ei.attacks.log" 2>&1; echo "PROOF	cache_attacks	status=$?	$(tail -n 1 "$HOME/ei.attacks.log")"
grep -a "^FAIL" "$HOME/ei.attacks.log" | head -n 12 | cut -c1-300
build/avra check packages/std-avrac --baseline tools/idioms.baseline > "$HOME/ei.idioms.log" 2>&1; echo "PROOF	idioms std-avrac	status=$?"; grep -a "NEW violation\|^error" -A6 "$HOME/ei.idioms.log" | head -n 20 | cut -c1-220
build/avra check packages/cli > "$HOME/ei.v1.log" 2>&1; echo "PROOF	check cli	status=$?"
build/avra check --verify-held packages/cli > "$HOME/ei.v2.log" 2>&1; echo "PROOF	verify-held cli	status=$?	$(grep -a '^avra:\|held' "$HOME/ei.v2.log" | tail -n 2 | tr '\n' ' ' | cut -c1-250)"
sh tools/db_measure/stale_embed_ctl.sh
