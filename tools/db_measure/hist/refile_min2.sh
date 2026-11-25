#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
T=packages/std-relation/src
build/avra test packages/std-relation > "$HOME/rl.suite.log" 2>&1; echo "PROOF	std-relation suite	status=$?	$(grep -aE 'tests passed|programs? proved|refusals proved' "$HOME/rl.suite.log" | tr '\n' ';')"
grep -a "✗\|^error\|STOPPED" -A6 "$HOME/rl.suite.log" | head -n 20 | cut -c1-260
AVRA_ALIAS_LOG=1 build/avra test $T/tests/refile_test.av > "$HOME/rl.alias.out" 2> "$HOME/rl.alias.err"; echo "PROOF	refile_test under the clone log	status=$?	clones logged: $(grep -ac . "$HOME/rl.alias.err")"
head -n 4 "$HOME/rl.alias.err" | cut -c1-200
