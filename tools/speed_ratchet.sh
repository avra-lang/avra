#!/bin/sh
# THE HARD PER-PHASE SPEED RATCHET: each phase of `packages/cli`'s own build and check, the least of
# SPEED_ROUNDS warm one-edit rounds (tools/speed_measure.sh), held as `speed:<host>:` rows of the ledger
# (the record under cost/, judged by `wisp cost` through tools/ledger_rows.sh). It measures on the
# machine the keeper stands on; on macOS on the lane's Sprite (`tools/work run`), since a loaded Mac
# supplies no number — SPEED_LOCAL=1 measures here. A host the ledger holds no row of is measured and
# told, never gated; an accept seeds it, and lowers a row, never raises one.
#   sh tools/speed_ratchet.sh            measure and judge
#   sh tools/speed_ratchet.sh accept     measure and record
set -eu
. "$(dirname "$0")/lib/tree.sh"
verb=${1:-judge}
case $verb in judge | accept) ;; *) echo "speed: judge or accept, never $verb" >&2; exit 2 ;; esac
cd "$tree"
stream=$tree/build/ledger/speed.stream
mkdir -p "$tree/build/ledger"
if [ "$(uname -s)" = Darwin ] && [ "${SPEED_LOCAL:-}" != 1 ]; then
    sprite=$(cat "$(git rev-parse --absolute-git-dir)/avra-sprite" 2>/dev/null || :)
    [ -n "$sprite" ] || { echo "speed: no Sprite bound to this worktree — not measured here (make speed-ratchet on a lane)"; exit 0; }
    sh tools/work run "sh tools/speed_measure.sh" > "$stream" 2>&1 || { tail -20 "$stream"; echo "speed: the Sprite's measurement failed" >&2; exit 1; }
else
    sh tools/speed_measure.sh > "$stream"
fi
exec sh tools/ledger_rows.sh "$stream" speed clock "$verb" "${2:-}"
