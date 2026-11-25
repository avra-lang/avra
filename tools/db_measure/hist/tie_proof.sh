#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
F=packages/std-avrac/src/features/collects/tests
build/avra fmt --check packages/std-avrac/src/features/decls.av packages/std-avrac/src/compiler/lower/lower.av $F/collect_order_ties/collect_order_ties.av | tail -n 1
for t in $F/collect_order_ties/collect_order_ties.av $F/collects_test.av $F/collect_order_text/collect_order_text.av $F/collect_order_typed_asc/collect_order_typed_asc.av $F/collect_order_typed_desc/collect_order_typed_desc.av $F/gathered_package/src/main.av; do
    build/avra test "$t" > "$HOME/tp.log" 2>&1; echo "PROOF	$(basename "$t")	status=$?	$(grep -a 'tests passed\|examples proved\|passed' "$HOME/tp.log" | tail -n 1 | cut -c1-120)"
    grep -a "✗\|^error\|^avra:\|FAIL" -A6 "$HOME/tp.log" | head -n 16 | cut -c1-240
done
sh tools/cache_attacks.sh > "$HOME/tp.attacks.log" 2>&1; echo "PROOF	cache_attacks	status=$?	$(tail -n 1 "$HOME/tp.attacks.log")"
grep -a "^FAIL" "$HOME/tp.attacks.log" | head -n 12 | cut -c1-300
