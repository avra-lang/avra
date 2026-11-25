#!/bin/sh
sh tools/cache_attacks.sh > "$HOME/ao.log" 2>&1; echo "PROOF	cache_attacks	status=$?	$(tail -n 1 "$HOME/ao.log")"
grep -a "^FAIL" "$HOME/ao.log" | head -n 12 | cut -c1-330
