#!/bin/sh
# THE SHARED FAILURE TAIL, held by a forced failure: a command that refuses
# on stdout and traps on stderr, with more than 20 lines between, must show
# both words, only the last 20 lines, nothing of the tool's bookkeeping, and
# nothing past 300 characters a line. Read both ways: the old one-stream,
# first-lines reading (`head -2` of stderr) would miss the refusal.
set -u
cd "$(dirname "$0")/.."
. tools/lib/failed_tail.sh
R=build/failed-tail-test; mkdir -p $R
{
    echo "refusal on stdout: the cold build refused its source"
    i=0; while [ $i -lt 40 ]; do echo "filler $i"; i=$((i + 1)); done
    echo "watch: peak 10 MB"
    echo "long $(printf 'x%.0s' $(seq 1 400))"
} > $R/out
echo "trap on stderr" > $R/err
got=$(failed_tail $R/out $R/err)
bad() { echo "failed-tail self-test: $1"; exit 1; }
case "$got" in *"trap on stderr"*) ;; *) bad "the stderr trap is missing" ;; esac
case "$got" in *"filler 39"*) ;; *) bad "the tail of stdout is missing" ;; esac
case "$got" in *"refusal on stdout"*) bad "more than 20 lines were carried" ;; esac
case "$got" in *"filler 19"*) bad "more than 20 lines were carried" ;; esac
case "$got" in *"watch:"*) bad "the watchdog's line rode along" ;; esac
[ "$(printf '%s\n' "$got" | wc -l | tr -d ' ')" = 20 ] || bad "not exactly 20 lines"
[ "$(printf '%s\n' "$got" | awk '{ if (length($0) > m) m = length($0) } END { print m }')" -le 308 ] || bad "a line was not cut at 300 characters"
words=$(printf 'refusal here\n' | failed_words)
case "$words" in *"refusal here"*) ;; *) bad "failed_words dropped a line of standard input" ;; esac
echo "failed-tail self-test: both streams, the last 20 lines, each cut at 300, no bookkeeping"
