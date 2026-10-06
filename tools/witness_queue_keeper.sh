#!/bin/sh
# WITNESS — `tools/queue_keeper.sh` NEVER ENQUEUES: it runs as a workflow's
# token, and an entry that token adds starts no train. Hermetic: a stub `gh`
# that serves one open, clean, unqueued PR and records every mutation and
# comment. Run: sh tools/witness_queue_keeper.sh
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/avra-queue-keeper.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
log="$tmp/gh.log"

# $GH_FAILED is how many trains carrying the PR have failed since its head.
cat > "$tmp/bin/gh" <<'SH'
#!/bin/sh
case "$*" in
    *enqueuePullRequest*) echo ENQUEUE >> "$GH_LOG" ;;
    *dequeuePullRequest*) echo DEQUEUE >> "$GH_LOG" ;;
    "pr comment"*) echo COMMENT >> "$GH_LOG" ;;
    "pr ready"*) echo DRAFT >> "$GH_LOG" ;;
    "pr list"*) echo "7 MERGEABLE abc123" ;;
    "pr view"*) echo abc123 ;;
    *"/commits/"*) echo "2026-01-01T00:00:00Z" ;;
    "run list"*length*) echo "${GH_FAILED:-0}" ;;
esac
exit 0
SH
chmod +x "$tmp/bin/gh"

keep() {
    : > "$log"
    PATH="$tmp/bin:$PATH" GH_LOG="$log" GH_FAILED="$1" AVRA_KEEPER_STATE="$tmp/state-$1" sh "$repo/tools/queue_keeper.sh" >/dev/null 2>&1
}
fail=0
say() { echo "witness_queue_keeper: $1"; fail=1; }

# (a) a green, unqueued PR: nothing is enqueued and nothing is said.
keep 0 || say "(a) the pass failed"
[ ! -s "$log" ] || say "(a) an unqueued PR drew: $(tr '\n' ' ' < "$log")"

# (b) dropped by one failed train: its owner is told, and it is NOT put back.
keep 1 || say "(b) the pass failed"
[ "$(tr '\n' ' ' < "$log")" = "COMMENT " ] || say "(b) a dropped PR drew: $(tr '\n' ' ' < "$log")"

# (c) three failed trains: held as a draft, told, never enqueued.
keep 3 || say "(c) the pass failed"
grep -q DRAFT "$log" || say "(c) a thrice-failed PR was not held as a draft"
! grep -q ENQUEUE "$log" || say "(c) the keeper enqueued"

[ "$fail" -eq 0 ] && echo "witness_queue_keeper: 3 proved — the keeper tells and holds, and never enqueues"
exit "$fail"
