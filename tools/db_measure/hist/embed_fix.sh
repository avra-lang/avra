#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
T=packages/std-avrac/src/compiler
build/avra fmt --check $T/workspace_analysis.av $T/record.av $T/tests/run_reads_test.av $T/tests/references_refused_test.av | tail -n 1
for t in $T/tests/run_reads_test.av $T/tests/references_refused_test.av; do
    build/avra test "$t" > "$HOME/ef.log" 2>&1; echo "PROOF	$(basename "$t")	status=$?	$(grep -a 'tests passed' "$HOME/ef.log")"
    grep -a "✗\|^error\|^avra:" -A8 "$HOME/ef.log" | head -n 30 | cut -c1-260
done
sh tools/cache_attacks.sh > "$HOME/ef.attacks.log" 2>&1; echo "PROOF	cache_attacks	status=$?	$(tail -n 1 "$HOME/ef.attacks.log")"
grep -a "^FAIL" "$HOME/ef.attacks.log" | head -n 12 | cut -c1-300
build/avra check packages/std-avrac --baseline tools/idioms.baseline > "$HOME/ef.idioms.log" 2>&1; echo "PROOF	idioms std-avrac	status=$?"; grep -a "NEW violation" -A6 "$HOME/ef.idioms.log" | head -n 12 | cut -c1-220
sh tools/db_measure/stale_embed_ctl.sh
