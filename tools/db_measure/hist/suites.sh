#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
for p in std-relation std-avrac; do
    s=$(date +%s); build/avra test packages/$p > "$HOME/suite.$p.log" 2>&1; st=$?
    echo "PROOF	$p-suite	status=$st	$(( $(date +%s) - s ))s	$(grep -aE 'tests passed|programs proved|refusals proved' "$HOME/suite.$p.log" | tr '\n' ';')	single programs: $(grep -ac '^1 program proved' "$HOME/suite.$p.log")"
    [ "$st" = 0 ] || grep -aE "✗|^error|STOPPED" -A6 "$HOME/suite.$p.log" | head -n 40 | cut -c1-240
done
