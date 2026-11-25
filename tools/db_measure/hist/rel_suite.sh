#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
build/avra fmt --check packages/std-relation/src/rows.av packages/std-relation/src/tests/refile_test.av | tail -n 1
s=$(date +%s); build/avra test packages/std-relation > "$HOME/suite.rel.log" 2>&1; st=$?
echo "PROOF	std-relation-suite	status=$st	$(( $(date +%s) - s ))s	$(grep -aE 'tests passed|programs? proved|refusals proved' "$HOME/suite.rel.log" | tr '\n' ';')"
[ "$st" = 0 ] || grep -aE "✗|^error|STOPPED" -A7 "$HOME/suite.rel.log" | head -n 60 | cut -c1-240
