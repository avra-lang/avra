build/avra test packages/std-avrac/src/features/cells 2>&1 | grep -E "set_at|passed|✗|cells" | head
sh tools/probe-cs/cli_census.sh $1

sh tools/probe-cs/time.sh $1
