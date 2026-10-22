#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
T=packages/std-avrac/src
build/avra fmt --check $T/features/decls_mint.av $T/features/tests/decl_facts_test.av $T/features/tests/doc_fact_test.av $T/compiler/tests/held_facts_test.av | tail -n 1
for t in $T/compiler/tests/held_facts_test.av $T/features/tests/decl_facts_test.av $T/features/tests/doc_fact_test.av; do
    build/avra test "$t" > "$HOME/fm.log" 2>&1; echo "PROOF	$(basename "$t")	status=$?	$(grep -a 'tests passed' "$HOME/fm.log")"
    grep -a "✗\|^error" -A8 "$HOME/fm.log" | head -n 40 | cut -c1-240
done
build/avra check packages/std-avrac --baseline tools/idioms.baseline > "$HOME/fm.idioms.log" 2>&1; echo "PROOF	idioms std-avrac	status=$?"; grep -a "^error" -A6 "$HOME/fm.idioms.log" | head -n 20 | cut -c1-220
