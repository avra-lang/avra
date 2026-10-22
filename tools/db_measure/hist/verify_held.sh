#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
build/avra check packages/cli > /dev/null 2>&1; echo "cold check status=$?"
AVRA_QTRACE=1 build/avra check --verify-held packages/cli > "$HOME/vh.out" 2> "$HOME/vh.err"; echo "verify-held status=$?"
grep -a "^avra:\|moved the whole\|a producer runs" "$HOME/vh.err" "$HOME/vh.out" | cut -c1-400 | head -n 4
n=$(grep -ao "reader [0-9]*" "$HOME/vh.err" "$HOME/vh.out" | tail -n 1 | grep -o "[0-9]*$")
echo "reader=$n"
echo "its BEGIN line(s):"; grep -a "^BEGIN	$n	" "$HOME/vh.err" | head -n 4
echo "BEGIN records: $(grep -ac '^BEGIN' "$HOME/vh.err"), lines with BEGIN anywhere: $(grep -ac 'BEGIN' "$HOME/vh.err")"
echo "the 12 trace lines before the trap:"; grep -an "moved the whole\|a producer runs" "$HOME/vh.err" | head -n 1 | cut -d: -f1 | while read -r at; do sed -n "$((at - 12)),$((at))p" "$HOME/vh.err" | cut -c1-220; done
echo "families, by number:"; grep -n "^type [A-Z][A-Za-z]* = {}" packages/std-avrac/src/compiler/families/families.av | head -n 60 | awk -F'[: ]' '{ printf "%d=%s ", NR - 1, $3 }'; echo
