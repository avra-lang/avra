#!/bin/sh
# Keeps every open, non-draft PR moving through the merge queue. A PR its
# owner is holding back is a DRAFT (`gh pr ready --undo <n>`).
#
#   sh tools/queue_keeper.sh          one pass
#   sh tools/queue_keeper.sh --loop   a pass every 2 minutes, until stopped
#
# GitHub runs it after every train and every 5 minutes (.github/workflows/
# queue-keeper.yml); a pass by hand is never needed.
#
# A PR GitHub dropped from the queue is put back, at most twice per head
# commit: a train fails every PR it carries, so most drops are someone
# else's failure. A PR that conflicts with main gets ONE comment saying
# "rebase onto origin/main"; one that failed its third train is held as a
# DRAFT, since every PR behind it rides its failure, with its failing
# lines on the PR. Either is left for its owner.
set -eu

repo=avra-lang/avra
state="${AVRA_KEEPER_STATE:-$HOME/.avra-queue-keeper}"
mkdir -p "$state"

queued() {
    gh api graphql -f query='{repository(owner:"avra-lang",name:"avra"){mergeQueue(branch:"main"){entries(first:100){nodes{pullRequest{number}}}}}}' \
        --jq '.data.repository.mergeQueue.entries.nodes[].pullRequest.number'
}

# The failing lines of PR $1's newest train, or nothing.
train_failure() {
    run=$(gh run list -R "$repo" -e merge_group -L 40 --json databaseId,headBranch,conclusion \
        --jq ".[] | select(.headBranch | test(\"/pr-$1-\")) | select(.conclusion == \"failure\") | .databaseId" | head -1)
    [ -n "$run" ] || return 0
    gh run view "$run" -R "$repo" --log 2>/dev/null | python3 -c '
import re, sys
for l in sys.stdin:
    m = re.search(r"(\d+)/(\d+) tests passed", l)
    if (m and m.group(1) != m.group(2)) or "✗" in l or " != expected" in l or "eval != " in l or re.search(r"^error\[", l.split("Z ", 1)[-1]):
        print(l.split("Z ", 1)[-1].rstrip()[:240])' | head -12
}

# Says $2 on PR $1 once per head commit, under the key $3.
say_once() {
    mark="$state/$1-$(gh pr view "$1" -R "$repo" --json headRefOid --jq .headRefOid)-$3"
    [ -e "$mark" ] && return 0
    gh pr comment "$1" -R "$repo" --body "$2" >/dev/null && : > "$mark"
}

# Puts PR $1 in the queue. A PR whose own check is missing or stale gets
# it run again first (closing and reopening re-runs it), then is queued.
enqueue() {
    id=$(gh pr view "$1" -R "$repo" --json id --jq .id)
    q="mutation{enqueuePullRequest(input:{pullRequestId:\"$id\"}){mergeQueueEntry{position}}}"
    gh api graphql -f query="$q" >/dev/null 2>&1 && return 0
    gh pr close "$1" -R "$repo" >/dev/null 2>&1 && gh pr reopen "$1" -R "$repo" >/dev/null 2>&1
    gh pr merge "$1" -R "$repo" --auto >/dev/null 2>&1
}

pass() {
    inq=" $(queued | tr '\n' ' ') "
    gh pr list -R "$repo" --state open --json number,mergeable,isDraft,headRefOid \
        --jq '.[] | select(.isDraft | not) | "\(.number) \(.mergeable) \(.headRefOid)"' |
    while read -r n mergeable head; do
        case "$inq" in *" $n "*) continue ;; esac
        if [ "$mergeable" = CONFLICTING ]; then
            say_once "$n" "queue keeper: this conflicts with main and cannot ride a train. Rebase onto origin/main, then \`sh tools/work land\`." conflict
            echo "queue-keeper: #$n conflicts with main — owner told"
            continue
        fi
        tries="$state/$n-$head.tries"
        t=$(cat "$tries" 2>/dev/null || echo 0)
        if [ "$t" -ge 2 ]; then
            say_once "$n" "$(printf 'queue keeper: three trains have failed with this PR in them, so it is held as a DRAFT — every PR behind it rode its failure. Its newest failure:\n\n```\n%s\n```\nFix it, then `gh pr ready %s` and `sh tools/work land`.' "$(train_failure "$n")" "$n")" failed
            gh pr ready "$n" -R "$repo" --undo >/dev/null 2>&1 || :
            echo "queue-keeper: #$n failed three trains — held as a draft, owner told"
            continue
        fi
        if enqueue "$n"; then
            echo $((t + 1)) > "$tries"
            echo "queue-keeper: #$n back in the queue (retry $((t + 1)) of 2)"
        fi
    done
}

if [ "${1:-}" = --loop ]; then
    while :; do pass; sleep 120; done
else
    pass
fi
