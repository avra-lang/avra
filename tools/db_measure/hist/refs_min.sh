#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
T=packages/std-avrac/src
build/avra fmt --check $T/features/decls.av $T/compiler/workspace.av $T/compiler/references.av $T/features/tests/refs_stand_test.av $T/compiler/tests/references_refused_test.av $T/compiler/tests/held_facts_test.av $T/compiler/record.av $T/features/decls_mint.av $T/features/tests/doc_fact_test.av $T/features/tests/decl_facts_test.av | tail -n 1
for t in $T/features/tests/refs_stand_test.av $T/compiler/tests/references_refused_test.av $T/compiler/tests/references_test.av $T/compiler/tests/held_facts_test.av $T/features/tests/decl_facts_test.av $T/features/tests/doc_fact_test.av; do
    build/avra test "$t" > "$HOME/rm.log" 2>&1; echo "PROOF	$(basename "$t")	status=$?	$(grep -a 'tests passed' "$HOME/rm.log")"
    grep -a "✗\|^error\|^avra:" -A8 "$HOME/rm.log" | head -n 40 | cut -c1-240
done
build/avra check packages/std-avrac --baseline tools/idioms.baseline > "$HOME/rm.idioms.log" 2>&1; echo "PROOF	idioms std-avrac	status=$?"; grep -a "NEW violation" -A6 "$HOME/rm.idioms.log" | head -n 12 | cut -c1-220
