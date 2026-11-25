#!/bin/sh
# The proof lines that need one tree and one compiler, each named, none stopping the next.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
line() { name=$1; shift; s=$(date +%s); "$@" > "$HOME/proof.$name.log" 2>&1; st=$?; echo "PROOF	$name	status=$st	$(( $(date +%s) - s ))s	$(grep -E 'tests passed|programs? proved|refusals proved|no new violations|examined|IDENTICAL|keepers:|seed-check|attack' "$HOME/proof.$name.log" | tail -n 4 | tr '\n' ';' | cut -c1-300)"; [ "$st" = 0 ] || tail -n 12 "$HOME/proof.$name.log" | cut -c1-240; }
line fmt build/avra fmt --check $(git diff --name-only origin/main...HEAD 2>/dev/null | grep '\.av$' || cat tools/db_measure/hist/touched.txt)
line idioms-relation build/avra check packages/std-relation --baseline tools/idioms.baseline
line idioms-avrac build/avra check packages/std-avrac --baseline tools/idioms.baseline
line relation-suite build/avra test packages/std-relation
line read-cost make read-cost
line seed-check make seed-check
line keepers make keepers
line cache-attacks sh tools/cache_attacks.sh
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
line cold-check-cli build/avra check --time packages/cli
grep '^time:' "$HOME/proof.cold-check-cli.log" | tail -n 1 | cut -c1-300
grep -h "^write\.\|^row\.\|^kernel\.\|^ask\." "$HOME/proof.read-cost.log"
