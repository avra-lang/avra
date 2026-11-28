#!/bin/bash
# A CHILD COMPILER, KEPT: `AVRA_BIN` for a suite whose cases run `<tree>/avra`. Each child runs
# `AVRA_CHILD_BIN` as it would have, its words passed through as they come, and leaves under
# `$AVRA_CHILDREN/<case>/` (the case the suite's runner names in `AVRA_CASE`) its arguments, what it
# said on each stream and how it ended, a file each, named by its pid. A child is stopped by its
# group, as std-process and tools/watch.sh stop one, so a signal reaches the compiler beside this script.
set -u
real=${AVRA_CHILD_BIN:?AVRA_CHILD_BIN names the compiler a child runs}
case=${AVRA_CASE:-no case}
dir=${AVRA_CHILDREN:?AVRA_CHILDREN names where children are kept}/$(printf '%s' "$case" | cksum | cut -d' ' -f1)
mkdir -p "$dir"
[ -f "$dir/case" ] || printf '%s\n' "$case" >"$dir/case"
at=$dir/$$
printf '%s\n' "$@" >"$at.args"
"$real" "$@" > >(tee "$at.out") 2> >(tee "$at.err" >&2) &
child=$!
# a signal to the child's group reaches the compiler once, as it would unwrapped; this script's own
# copy is absorbed, and its wait, interrupted, is waited again, so the status is the compiler's own
# LICENSED scratch_law: a fixture child that must outlive the signals its parent's kill sends
trap ':' TERM INT HUP
while kill -0 "$child" 2>/dev/null; do wait "$child"; done
wait "$child"
status=$?
wait
printf '%s\n' "$status" >"$at.exit"
exit "$status"
