#!/bin/sh
# WITNESS — `tools/work wait`, whose oracle is the branch's PR state, asked of
# `gh`, and NEVER `main`. Hermetic: a stub `gh` fed a scripted state sequence,
# and a stub `git` that RECORDS any call, so a single `git` invocation is the
# failure. Run: sh tools/witness_work_wait.sh
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
work=$repo/tools/work
tmp=$(mktemp -d "${TMPDIR:-/tmp}/avra-work-wait.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
seqf="$tmp/gh.seq"
gitlog="$tmp/git.log"
ghlog="$tmp/gh.log"
: > "$gitlog"

# A `gh` that answers the next state in the sequence, then stays OPEN.
# A queue entry is whatever $GH_ENTRY says ("<position> <seconds> <enqueuer>",
# or nothing: not queued); no train ever runs; every mutation is RECORDED.
cat > "$tmp/bin/gh" <<'SH'
#!/bin/sh
case "$*" in
    *dequeuePullRequest*) echo DEQUEUE >> "$GH_LOG"; exit 0 ;;
    *enqueuePullRequest*) echo ENQUEUE >> "$GH_LOG"; exit 0 ;;
    *mergeQueueEntry*) [ -z "${GH_ENTRY:-}" ] || echo "$GH_ENTRY"; exit 0 ;;
    *"--json number,id"*) [ -z "${GH_ENTRY:-}" ] || echo "7 PR_node"; exit 0 ;;
    *"--json state"*) ;;
    *) exit 0 ;;
esac
if [ -s "$GH_SEQ" ]; then
    head -1 "$GH_SEQ"
    tail -n +2 "$GH_SEQ" > "$GH_SEQ.next"
    mv "$GH_SEQ.next" "$GH_SEQ"
else
    echo OPEN
fi
SH
chmod +x "$tmp/bin/gh"

# A `git` that records the call and fails — `wait` must never reach it.
cat > "$tmp/bin/git" <<'SH'
#!/bin/sh
echo "GIT $*" >> "$GIT_LOG"
exit 99
SH
chmod +x "$tmp/bin/git"

run_wait() {
    PATH="$tmp/bin:$PATH" GH_SEQ="$seqf" GIT_LOG="$gitlog" GH_LOG="$ghlog" GH_ENTRY="${entry:-}" \
        AVRA_WAIT_POLL=0 AVRA_WAIT_SECONDS="$1" sh "$work" wait feature
}

fail=0
say() { echo "witness_work_wait: $1"; fail=1; }

# (a) OPEN then MERGED: success, and `main` was never touched.
printf 'OPEN\nMERGED\n' > "$seqf"
run_wait 60 >/dev/null 2>&1 || say "(a) a merged PR did not answer success"
[ -s "$gitlog" ] && say "(a) wait called git — main may not be polled"

# (b) CLOSED without merging: failure, not a false success.
printf 'CLOSED\n' > "$seqf"
run_wait 60 >/dev/null 2>&1 && say "(b) a closed PR answered success"

# (c) never landed: the deadline fails it, and still no git.
: > "$seqf"
run_wait 0 >/dev/null 2>&1 && say "(c) an unlanded PR answered success"
[ -s "$gitlog" ] && say "(c) wait called git"

# (d) an entry a BOT queued starts no train: it is taken out and queued
# again as this user, at once, however young it is.
: > "$seqf"; : > "$ghlog"
entry="1 4 github-actions[bot]" run_wait 0 >/dev/null 2>&1 || :
[ "$(tr '\n' ' ' < "$ghlog")" = "DEQUEUE ENQUEUE " ] || say "(d) a bot-queued entry was not requeued: $(tr '\n' ' ' < "$ghlog")"

# (e) a user's young entry with no train yet is left alone …
: > "$seqf"; : > "$ghlog"
entry="1 4 somebody" run_wait 0 >/dev/null 2>&1 || :
[ ! -s "$ghlog" ] || say "(e) a user's 4-second-old entry was requeued"

# (f) … and requeued once it has waited past the stuck bound.
: > "$seqf"; : > "$ghlog"
entry="1 400 somebody" run_wait 0 >/dev/null 2>&1 || :
[ "$(tr '\n' ' ' < "$ghlog")" = "DEQUEUE ENQUEUE " ] || say "(f) a user's stuck entry was not requeued"

[ "$fail" -eq 0 ] && echo "witness_work_wait: 6 proved — the PR is the oracle, main is never polled; a bot's entry and a stuck one are requeued"
exit "$fail"
