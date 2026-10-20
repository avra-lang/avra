#!/bin/sh
# A PACKAGE IS A REAL DIRECTORY: a symlinked one would run its suite under two names. The suites
# command (tools/src/commands/suites.av) cannot see a link — std-io's stat follows them — so this
# is the one question it leaves to the shell.
#
#   sh tools/suites_links.sh
set -eu
cd "$(dirname "$0")/.."
n=0
for d in packages/*; do
    if [ -L "$d" ]; then
        echo "suites: $d is a symlink — a package is a real directory, or its suite runs under two names" >&2
        n=$((n + 1))
    fi
done
[ "$n" = 0 ]
