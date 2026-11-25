# usage: m5b-cost.sh <compiler> <tree>: seconds for one cold check of <tree>/packages/cli
rm -rf "$2/.avra-cache" "$2/packages/cli/.avra-cache" "$2/packages/std-avrac/.avra-cache"
cd "$2" && TIMEFORMAT="%U user %R wall" && time ("$1" check --time packages/cli > /tmp/cost.out 2>&1); grep -o "held [0-9]*/[0-9]*" /tmp/cost.out | head -1
