#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
T=packages/std-avrac/src/compiler
build/avra fmt --check $T/build.av $T/tests/gathered_root_kind_test.av $T/lower/lower.av $T/codecs.av $T/tests/answers_test.av $T/derive.av $T/workspace.av $T/interface.av $T/record.av $T/whole.av packages/std-avrac/src/features/decls.av | tail -n 1
sh tools/db_measure/hist/kg_probe.sh
for t in $T/tests/gathered_root_kind_test.av $T/tests/answers_test.av $T/tests/cache_walk_test.av $T/tests/run_reads_test.av $T/tests/references_refused_test.av packages/std-avrac/src/features/collects/tests/collects_test.av; do
    build/avra test "$t" > "$HOME/gp.log" 2>&1; echo "PROOF	$(basename "$t")	status=$?	$(grep -a 'tests passed' "$HOME/gp.log")"
    grep -a "✗\|^error\|^avra:" -A6 "$HOME/gp.log" | head -n 20 | cut -c1-260
done
sh tools/cache_attacks.sh > "$HOME/gp.attacks.log" 2>&1; echo "PROOF	cache_attacks	status=$?	$(tail -n 1 "$HOME/gp.attacks.log")"
grep -a "^FAIL" "$HOME/gp.attacks.log" | head -n 12 | cut -c1-300
build/avra check packages/cli > "$HOME/gp.v1.log" 2>&1; echo "PROOF	check cli	status=$?"
build/avra check --verify-held packages/cli > "$HOME/gp.v2.log" 2>&1; echo "PROOF	verify-held cli	status=$?	$(grep -a 'verify-held:\|^avra:' "$HOME/gp.v2.log" | tail -n 1 | cut -c1-200)"
