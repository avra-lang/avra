#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
sh tools/db_measure/hist/kg_probe.sh
sh tools/cache_attacks.sh > "$HOME/ko.attacks.log" 2>&1; echo "PROOF	cache_attacks	status=$?	$(tail -n 1 "$HOME/ko.attacks.log")"
grep -a "^FAIL" "$HOME/ko.attacks.log" | head -n 16 | cut -c1-300
