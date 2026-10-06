#!/bin/sh
# Keeps the merge queue moving, and tells a PR's owner when the PR cannot.
#
#   sh tools/queue_keeper.sh          one pass
#   sh tools/queue_keeper.sh --loop   a pass every 2 minutes, until stopped
#
# GitHub runs it every 5 minutes (.github/workflows/queue-keeper.yml); a
# pass by hand is never needed.
#
# IT NEVER ENQUEUES. It runs as the workflow's token, and GitHub starts no
# workflow for an event that token causes: an entry it adds sits in the
# queue with no train until someone takes it out and puts it back. A PR
# enters the queue from its lane, as its user (`sh tools/work land`).
#
# What it does: an entry GitHub marked UNMERGEABLE leaves the queue. A PR
# that conflicts with main gets ONE comment saying "rebase onto
# origin/main". A PR a failed train dropped is told once per failure to
# land again — a train fails every PR it carries, so most drops are
# someone else's — and one whose head has failed three trains is held as a
# DRAFT, with its failing lines on the PR, since every PR behind it rides
# its failure. Each is left for its owner.
set -eu

repo=avra-lang/avra
state="${AVRA_KEEPER_STATE:-$HOME/.avra-queue-keeper}"
mkdir -p "$state"

# Each queued PR as "<number> <state> <id>".
entries() {
    gh api graphql -f query='{repository(owner:"avra-lang",name:"avra"){mergeQueue(branch:"main"){entries(first:100){nodes{state pullRequest{number id}}}}}}' \
        --jq '.data.repository.mergeQueue.entries.nodes[] | "\(.pullRequest.number) \(.state) \(.pullRequest.id)"'
}

# An entry GitHub marked UNMERGEABLE stalls every train behind it, so it
# leaves the queue; the pass below treats it like any dropped PR.
unstick() {
    entries | while read -r n st id; do
        [ "$st" = UNMERGEABLE ] || continue
        gh api graphql -f query="mutation{dequeuePullRequest(input:{id:\"$id\"}){clientMutationId}}" >/dev/null 2>&1 \
            && echo "queue-keeper: #$n stalled the queue as UNMERGEABLE — taken out"
    done
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

# How many trains carrying PR $1 have failed since its head commit $2 was
# made: a new head starts from nothing.
failed_trains() {
    since=$(gh api "repos/$repo/commits/$2" --jq .commit.committer.date 2>/dev/null) || since=
    [ -n "$since" ] || { echo 0; return 0; }
    gh run list -R "$repo" -e merge_group -L 100 --json headBranch,conclusion,createdAt \
        --jq "[.[] | select(.headBranch | test(\"/pr-$1-\")) | select(.conclusion == \"failure\") | select(.createdAt > \"$since\")] | length"
}

pass() {
    unstick
    inq=" $(entries | cut -d' ' -f1 | tr '\n' ' ') "
    gh pr list -R "$repo" --state open --json number,mergeable,isDraft,headRefOid \
        --jq '.[] | select(.isDraft | not) | "\(.number) \(.mergeable) \(.headRefOid)"' |
    while read -r n mergeable head; do
        case "$inq" in *" $n "*) continue ;; esac
        if [ "$mergeable" = CONFLICTING ]; then
            say_once "$n" "queue keeper: this conflicts with main and cannot ride a train. Rebase onto origin/main, then \`sh tools/work land\`." conflict
            echo "queue-keeper: #$n conflicts with main — owner told"
            continue
        fi
        t=$(failed_trains "$n" "$head")
        [ "${t:-0}" -gt 0 ] || continue
        if [ "$t" -ge 3 ]; then
            say_once "$n" "$(printf 'queue keeper: three trains have failed with this PR in them, so it is held as a DRAFT — every PR behind it rode its failure. Its newest failure:\n\n```\n%s\n```\nFix it, then `gh pr ready %s` and `sh tools/work land`.' "$(train_failure "$n")" "$n")" failed
            gh pr ready "$n" -R "$repo" --undo >/dev/null 2>&1 || :
            echo "queue-keeper: #$n failed three trains — held as a draft, owner told"
            continue
        fi
        say_once "$n" "queue keeper: a train carrying this PR failed and dropped it from the queue (failure $t of 3 before it is held). If the failure is not this PR's, run \`sh tools/work land\` from its worktree to queue it again." "dropped-$t"
        echo "queue-keeper: #$n was dropped by a failed train ($t of 3) — owner told"
    done
}

if [ "${1:-}" = --loop ]; then
    while :; do pass; sleep 120; done
else
    pass
fi
