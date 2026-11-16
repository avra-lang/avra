# THE FLOOR OF AN ATTACK, sourced after `set -u` (`. "$(dirname "$0")/lib/attack.sh"`): stands in the
# tree's root, runs under the lock its caller holds (no second watchdog) and takes no compile slot.
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
# A cold run clears the tree's `.avra-cache`; the machine store lives there too, or "cold" would read the machine's rows.
export AVRA_CACHE_DIR="$PWD/.avra-cache"
export AVRA_MAX_COMPILES=0
fails=0
steps=0

# Marks a fixture directory as a checkout whose store is its own, cold, never the tree's.
own_store() {
    : > "$1/.git"
    export AVRA_CACHE_DIR="$PWD/$1/.avra-cache"
}

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
