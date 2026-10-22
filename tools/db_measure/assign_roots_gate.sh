#!/bin/sh
# avra-8sb5.57.195/198: the gate for the assign-roots map change,
# with this commit as the diff base (its parent is origin/main).
cd "$(dirname "$0")/../.." || exit 1
echo "== gate_changed --refs HEAD~1 HEAD --no-keepers =="
sh tools/gate_changed.sh --refs HEAD~1 HEAD --no-keepers 2>&1 | tail -25
echo "gate exit $?"
echo "== keepers-pr =="
make keepers-pr 2>&1 | tail -12
echo "keepers-pr exit $?"
