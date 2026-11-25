#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
make read-cost > "$HOME/rc.log" 2>&1; echo "PROOF	read-cost	status=$?"; grep -a "^write\.\|read_cost" "$HOME/rc.log"
s=$(date +%s); build/avra test packages/std-relation > "$HOME/suite.rel.log" 2>&1; st=$?
echo "PROOF	std-relation-suite	status=$st	$(( $(date +%s) - s ))s	$(grep -aE 'tests passed|programs? proved|refusals proved' "$HOME/suite.rel.log" | tr '\n' ';')"
[ "$st" = 0 ] || grep -aE "✗|^error|STOPPED" -A6 "$HOME/suite.rel.log" | head -n 40 | cut -c1-240
