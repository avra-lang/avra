#!/bin/sh
# THE CHANGED-FILE FMT CHECK — ONE definition, called by the gate's own fmt
# step (.github/workflows/checks.yml) and by `tools/work land`'s local
# preflight, so the two can never drift into two instruments.
#
#   sh tools/fmt_changed.sh <base> <head>     # the caller has refs (the gate)
#   sh tools/fmt_changed.sh --files <files…>  # the caller already diffed
#
# Every named `.av` file is run through `fmt --check`. The compiler is
# `${AVRA:-build/avra}` — the tree under test's OWN build. THE BRANCH'S
# COMPILER, NEVER A STALE STANDING ONE: a binary that predates the syntax a
# branch added REFUSES that branch's files and cannot report the canonical
# diff, so it would certify a file the gate then refuses. The gate has its
# own build; a lane's Sprite holds a branch build (`tools/work run`), and its
# synced tree carries no `.git`, which is why `--files` exists. Nothing
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
# A FIXTURE MALFORMED ON PURPOSE IS NOT FORMATTING'S TO JUDGE. A file whose
# case (the nearest directory above it holding a `refuses.expected`) expects
# a parse or lex refusal — that file names a `parse.`/`lex.` kind — cannot be
# printed by fmt, by design: it is skipped, with one line naming it. Every
# other refusal is still a failure, a case expecting any other kind included.
expects_parse_refusal() {
    d=$(dirname "$1")
    while :; do
        if [ -f "$d/refuses.expected" ]; then
            grep -Eq '^error\[(parse|lex)\.' "$d/refuses.expected"
            return
        fi
        case "$d" in .|/) return 1 ;; esac
        d=$(dirname "$d")
    done
}
judged=
for f in $changed; do
    if expects_parse_refusal "$f"; then
        echo "fmt_changed: skipped $f — its case expects a parse/lex refusal, which fmt cannot print"
    else
        judged="$judged $f"
    fi
done
[ -n "$judged" ] || { echo "fmt_changed: no changed .av left to check"; exit 0; }
"$avra" fmt --check $judged
