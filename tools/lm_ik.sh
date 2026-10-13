sh tools/cache_attacks.sh 2>&1 | grep -av "^awk" | tail -3
build/avra test packages/std-avrac > /tmp/t.out 2>&1; echo TEST_EXIT=$?; grep -a "tests passed\|programs proved" /tmp/t.out | tail -2; grep -a "✗" /tmp/t.out | head -5 | cut -c1-300
sh tools/db_measure/warm_edit.sh 3 packages/cli cli packages/cli/src/commands/shared.av "· memo" 2>&1 | grep -a "edit"
