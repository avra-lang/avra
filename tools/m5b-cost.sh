# usage: cost.sh <compiler> <tree>: instructions for one cold check of <tree>/packages/cli
rm -rf "$2/.avra-cache" "$2/packages/cli/.avra-cache"
cd "$2" && perf stat -x, -e instructions "$1" check packages/cli > /dev/null 2> /tmp/perf.out; tail -1 /tmp/perf.out
