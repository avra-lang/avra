#!/bin/sh
# A BUILD LOG WITH NO CEILING IS A FULL DISK. `make avra` wrote its
# whole build into `build/avra-build.out` while only the last 200 KB
# was ever read; a looping build wrote 43 GB twice in one day and
# filled the volume, which killed every other session's work and cost
# a compiler binary. Each remaining redirect was small only because
# its producer was small — the same assumption, one file over.
#
# This runs a command with its output CAPPED and answers the
# command's own status, which a bare pipe would lose (the status
# would be `tail`'s). The marker rides the stream's end, where `tail`
# cannot cut it, and is stripped before a reader sees the file.
#
# A CAP BELONGS ON A LOG, NEVER ON DATA THAT IS COMPARED. A truncated
# log loses the head of an error and still says what failed; a
# truncated ARTIFACT can make two different outputs equal, which is
# exactly the agreement `witness` and `native-check` exist to test.
# Those redirects are justified at their sites and stay uncapped.
#
#   sh tools/capped.sh <file> <bytes> <command> [args...]
#   sh tools/capped.sh --self-test
set -e

if [ "$1" = "--self-test" ]; then
    # THE FIXTURES ARE THE THREE PROMISES: the output is kept whole
    # under the cap, the COMMAND'S OWN status survives a pipe that
    # would otherwise answer `tail`'s, and a runaway stops at the
    # ceiling. The second found a real defect on its first run — an
    # inherited `set -e` ended the capture's subshell before the
    # status marker was written, so every red command answered green.
    # THE FIXTURES RE-ENTER THIS SCRIPT, AND THAT IS SAFE HERE FOR A
    # REASON WORTH STATING: what they check is a PROCESS'S exit
    # status, which only a separate process has. The cycle that took
    # down the machine tonight was the other direction — a verb that
    # ran the fixtures, and fixtures that ran the verb. The capture
    # path below runs no fixtures, so the arrow points one way.
    t="$(mktemp -d)"
    trap 'rm -rf "$t"' EXIT
    self="$0"
    sh "$self" "$t/a.out" 1000 printf 'hello\n'
    [ "$(cat "$t/a.out")" = "hello" ] || { echo "capped: content lost"; exit 1; }
    st=0
    sh "$self" "$t/b.out" 1000 sh -c 'echo boom; exit 3' || st=$?
    [ "$st" = "3" ] || { echo "capped: a red command answered $st"; exit 1; }
    [ "$(cat "$t/b.out")" = "boom" ] || { echo "capped: a red command's words lost"; exit 1; }
    sh "$self" "$t/c.out" 4096 sh -c 'i=0; while [ $i -lt 20000 ]; do echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"; i=$((i+1)); done'
    size="$(wc -c < "$t/c.out" | tr -d " ")"
    [ "$size" -le 4096 ] || { echo "capped: no ceiling — $size bytes"; exit 1; }
    echo "capped: self-test passed — 3 fixtures (content, status, ceiling at $size bytes)"
    exit 0
fi

out="$1"; bytes="$2"; shift 2
mkdir -p "$(dirname "$out")"
# `set +e` INSIDE THE GROUP, or errexit is inherited by the subshell
# a pipeline element runs in: the command's own failure would end that
# subshell before the marker is written, the marker's absence would
# read as "no status", and every red command would answer green. The
# probe caught it; nothing in the tree would have.
{ set +e; "$@" 2>&1; echo "__capped_status=$?"; } | tail -c "$bytes" > "$out"
# A PIPE'S TAIL MAY ANSWER WHOLE CHUNKS PAST THE CAP (uutils' does, over
# many small writes); a file's seeks and is exact, so the cap is taken
# again from the file.
tail -c "$bytes" "$out" > "$out.tmp" && mv "$out.tmp" "$out"
line="$(tail -1 "$out")"
case "$line" in
    __capped_status=*)
        status="${line#__capped_status=}"
        # the file is at most `bytes`, so rewriting it is bounded too
        sed '$d' "$out" > "$out.tmp" && mv "$out.tmp" "$out"
        ;;
    *) status=0 ;;   # the marker itself was cut: a cap smaller than one line
esac
exit "$status"
