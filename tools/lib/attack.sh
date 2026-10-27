# THE FLOOR OF AN ATTACK, sourced after `set -u` (`. "$(dirname "$0")/lib/attack.sh"`): stands in the
# tree's root, runs under the lock its caller holds (no second watchdog) and takes no compile slot.
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
