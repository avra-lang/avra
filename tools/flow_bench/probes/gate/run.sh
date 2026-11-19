#!/bin/sh
# The gate probe, run OUTSIDE the tree in both engines, clones logged.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
dir=${TMPDIR:-/tmp}/flow-probe-gate
mkdir -p "$dir/src"
cp "$here/avra.toml" "$dir/avra.toml"
cp "$here/src/main.av" "$dir/src/main.av"
echo "== $(uname -srm), $(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo 'tree synced, no git')"
echo "-- evaluated"
"$root/build/avra" run "$dir" 2>&1 | grep -v "^$" | head -40
echo "-- native, AVRA_ALIAS_LOG=1"
"$root/build/avra" build "$dir" 2>&1 | grep -E "^error|^warning" | head -10
AVRA_ALIAS_LOG=1 "$dir/src/main" 2> "$dir/clones"
echo "clone lines: $(wc -l < "$dir/clones")"
head -5 "$dir/clones"
