#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
T=packages/std-relation/src
build/avra fmt --check $T/rows.av $T/tests/refile_test.av $T/tests/refile_lists/refile_lists.av | tail -n 1
build/avra test $T/tests/refile_test.av > "$HOME/rl.log" 2>&1; echo "PROOF	refile_test.av	status=$?	$(grep -a 'tests passed' "$HOME/rl.log")"
grep -a "✗\|^error\|^avra:" -A8 "$HOME/rl.log" | head -n 40 | cut -c1-260
build/avra test packages/std-relation > "$HOME/rl.suite.log" 2>&1; echo "PROOF	std-relation suite	status=$?	$(grep -aE 'tests passed|programs? proved|refusals proved' "$HOME/rl.suite.log" | tr '\n' ';')"
grep -a "✗\|^error\|STOPPED\|refile_lists" -A6 "$HOME/rl.suite.log" | head -n 30 | cut -c1-260
build/avra check packages/std-relation --baseline tools/idioms.baseline > "$HOME/rl.idioms.log" 2>&1; echo "PROOF	idioms std-relation	status=$?"; grep -a "NEW violation" -A6 "$HOME/rl.idioms.log" | head -n 12 | cut -c1-220
