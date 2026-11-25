#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
build/avra check packages/cli > /dev/null 2>&1; echo "cold check status=$?"
AVRA_QTRACE=1 build/avra check --verify-held packages/cli > "$HOME/vh.out" 2> "$HOME/vh.err"; echo "verify-held status=$?"
grep -a "^avra:" "$HOME/vh.err" | cut -c1-300 | head -n 3
echo "VH records=$(grep -ao 'VH	' "$HOME/vh.err" | wc -l) lines=$(grep -ac '^VH	' "$HOME/vh.err")"
echo "by side and known:"; grep -a '^VH	' "$HOME/vh.err" | cut -f2,4 | sort | uniq -c
echo "unknown paths (first 8):"; grep -a '^VH	' "$HOME/vh.err" | grep "known=false" | head -n 8 | cut -c1-200
echo "last three VH lines before the trap:"; grep -a '^VH	' "$HOME/vh.err" | tail -n 3 | cut -c1-200
