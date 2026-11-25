#!/bin/sh
# Each census binary's per-caller tables, resolved, over main's tree.
set -eu
for which in main branch; do
    rm -rf .avra-cache
    AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 "build/avra.census.$which" check packages/cli 2>&1 >/dev/null \
        | grep ': site 0x' > "build/sites-$which.txt" || true
    echo "== $which $(wc -l < "build/sites-$which.txt") site lines"
    while IFS= read -r line; do
        set -- $line
        name=$(addr2line -f -e "build/avra.census.$which" "$3" 2>/dev/null | head -1)
        echo "$1 $name $4"
    done < "build/sites-$which.txt" | awk '{k=$1" "$2; s[k]+=$3} END {for (k in s) print s[k], k}' | sort -rn > "build/sym-$which.txt"
done
join -1 2 -2 2 <(awk '{print $1, $2"|"$3}' build/sym-main.txt | sort -k2) <(awk '{print $1, $2"|"$3}' build/sym-branch.txt | sort -k2) -a 1 -a 2 -e 0 -o 0,1.1,2.1 \
    | awk '{d=$3-$2; if (d<0) d=-d; print d, $3-$2, $1, $2, $3}' | sort -rn | head -40
