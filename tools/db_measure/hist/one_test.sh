#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
for t in "$@"; do
    build/avra test "$t" > "$HOME/ot.log" 2>&1; echo "PROOF	$(basename "$t")	status=$?	$(grep -a 'tests passed' "$HOME/ot.log")"
    grep -a "✗\|^error\|^avra:" -A8 "$HOME/ot.log" | head -n 30 | cut -c1-260
done
