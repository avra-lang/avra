#!/bin/sh
# WITNESS — the two command forms `tools/sp` assembles (and so `tools/work
# run`). A single quoted multi-word command is ONE command STRING, run as
# written; a many-word argv is one command's words, each quoted. They must
# agree, and the single form must NOT become one shell word. Hermetic:
# `tools/sp --command` prints the assembly and never touches a Sprite.
# Run: sh tools/witness_work_run.sh
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
sp=$repo/tools/sp

one=$(sh "$sp" --command "build/avra test packages/cli")
many=$(sh "$sp" --command build/avra test packages/cli)
simple=$(sh "$sp" --command build/avra)

fail=0
say() { echo "witness_work_run: $1"; fail=1; }

# (a) the single string stays a command, never a quoted filename.
[ "$one" = "build/avra test packages/cli" ] || say "(a) the single command string was rewritten: '$one'"
[ "$one" = "'build/avra test packages/cli'" ] && say "(a) the single command string is one quoted word"

# (b) a single word passes through.
[ "$simple" = "build/avra" ] || say "(b) a single word was rewritten: '$simple'"

# (c) both forms run the same three words.
eval "set -- $one"
[ "$1 $2 $3" = "build/avra test packages/cli" ] || say "(c) the single form does not run as three words"
eval "set -- $many"
[ "$1 $2 $3" = "build/avra test packages/cli" ] || say "(c) the many-word form does not run as three words"

[ "$fail" -eq 0 ] && echo "witness_work_run: 3 proved — one command string or an argv, never one shell word"
exit "$fail"
