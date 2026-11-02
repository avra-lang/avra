# THE FLOOR OF AN ATTACK, sourced after `set -u` (`. "$(dirname "$0")/lib/attack.sh"`): stands in the
# tree's root, runs under the lock its caller holds (no second watchdog) and takes no compile slot.
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
fails=0
steps=0

# One failed check, counted and named.
fail() {
    fails=$((fails + 1))
    echo "FAIL  $*"
}

# The attack's last line — what it ran, then how much failed — and its status.
verdict() {
    echo "$1: $2, $fails failed"
    [ "$fails" -eq 0 ]
}
