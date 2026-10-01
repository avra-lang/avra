#!/bin/sh
# THE CHANGED-FILE FMT CHECK — ONE definition, called by the train's own fmt
# step (.github/workflows/checks.yml) and by `tools/work land`'s local
# preflight, so the two can never drift into two instruments.
#
#   sh tools/fmt_changed.sh <base> <head>     # the caller has refs (the train)
#   sh tools/fmt_changed.sh --files <files…>  # the caller already diffed
#
# Every named `.av` file is run through `fmt --check`. The compiler is
# `${AVRA:-build/avra}` — the tree under test's OWN build. THE BRANCH'S
# COMPILER, NEVER A STALE STANDING ONE: a binary that predates the syntax a
# branch added REFUSES that branch's files and cannot report the canonical
# diff, so it would certify a file the train then refuses. The train has its
# own build; `tools/work land` gets a branch build through `tools/sp` (whose
# synced tree carries no `.git`, which is why it passes `--files`). Nothing
# here polls `main`: the refs are named, never watched.
set -eu
[ "$#" -ge 1 ] || { echo "fmt_changed: usage: sh tools/fmt_changed.sh <base> <head> | --files <files…>" >&2; exit 2; }
avra=${AVRA:-build/avra}
[ -x "$avra" ] || { echo "fmt_changed: no compiler at $avra" >&2; exit 2; }
if [ "$1" = --files ]; then
    shift
    changed=$*
else
    [ "$#" -eq 2 ] || { echo "fmt_changed: usage: sh tools/fmt_changed.sh <base> <head>" >&2; exit 2; }
    changed=$(git diff --name-only --diff-filter=d "$1" "$2" -- '*.av')
fi
[ -n "$changed" ] || { echo "fmt_changed: no changed .av to check"; exit 0; }
"$avra" fmt --check $changed
