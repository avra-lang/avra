#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
build/avra check packages/cli > /dev/null 2>&1; echo "cold check status=$?"
AVRA_QTRACE=1 build/avra check --verify-held packages/cli > "$HOME/vh.out" 2> "$HOME/vh.err"; echo "verify-held status=$?"
grep -a "^avra:" "$HOME/vh.err" | cut -c1-300 | head -n 3
echo "records=$(grep -ao 'VHS	\|MINT	' "$HOME/vh.err" | wc -l) lines=$(grep -ac '^VHS	\|^MINT	' "$HOME/vh.err")"
echo "settlements asked: $(grep -ac '^VHS	' "$HOME/vh.err"); files minted in the whole run: $(grep -ac '^MINT	' "$HOME/vh.err")"
echo "the last settlement asked and every mint after the FIRST settlement:"
first=$(grep -an '^VHS	' "$HOME/vh.err" | head -n 1 | cut -d: -f1)
grep -a '^VHS	' "$HOME/vh.err" | tail -n 2 | cut -c1-220
[ -n "$first" ] && tail -n +"$first" "$HOME/vh.err" | grep -a '^MINT	' | head -n 8 | cut -c1-220
echo "the 8 trace lines before the trap:"; at=$(grep -an '^avra:' "$HOME/vh.err" | head -n 1 | cut -d: -f1); sed -n "$((at - 8)),$((at))p" "$HOME/vh.err" | cut -c1-220
