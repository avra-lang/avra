#!/bin/sh
# EXPANDED-ONCE ATTACK: no file's expansion settles more than a few times in a cold check of
# the compiler's own package. A file's expansion is demanded from inside each member's
# resolve, and every ask once re-ran the whole body (173 settles for the node enums' file).
# Usage: sh tools/expanded_attack.sh [avra] [package]
avra=${1:-build/avra}
package=${2:-packages/std-avrac}
# A re-entry nested inside the first re-entry reads what that one has minted, so a file
# settles twice at most: its run and that re-entry. The attack guards the per-member
# re-run (173) and every deeper nesting level.
limit=2
trace=$(mktemp "${TMPDIR:-/tmp}/avra-expanded.XXXXXX")
AVRA_QTRACE=1 "$avra" check "$package" 2>&1 | grep -a '^Q	settle	Expanded' > "$trace"
worst=$(cut -f4 "$trace" | sort | uniq -c | sort -rn | head -n 1)
count=$(echo "$worst" | awk '{print $1}')
echo "expanded-attack: $package, $(wc -l < "$trace" | tr -d ' ') Expanded settles, busiest file settled ${count:-0} times (limit $limit)"
if [ "${count:-0}" -gt "$limit" ]; then
    echo "expanded-attack: FAILED — a file's expansion settled more than $limit times"
    exit 1
fi
exit 0
