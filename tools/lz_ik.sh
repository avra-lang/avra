CACHE_ATTACKS=lz VERBOSE=1 sh tools/cache_attacks.sh 2>&1 | grep -av "^awk" | tail -8
