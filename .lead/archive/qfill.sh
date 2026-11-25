#!/bin/sh
# qfill.sh — keep the merge queue full.
# Re-queues EVERY open, non-draft, mergeable PR that is not already queued.
# Idempotent: a PR already in the queue is left alone (enqueue fails harmlessly).
# Run after any landing/drop: `sh .lead/scripts/qfill.sh`.
cd "$(git rev-parse --show-toplevel)" || exit 2
R=avra-lang/avra

# What is already queued?
gh api graphql -f query='{repository(owner:"avra-lang",name:"avra"){mergeQueue{entries(first:50){nodes{pullRequest{number}}}}}}' 2>/dev/null \
  | grep -o '"pullRequest":{"number":[0-9]*' | grep -o '[0-9]*' | sort -u > /tmp/qfill.queued

gh pr list -R "$R" --state open --limit 40 --json number,mergeable,isDraft \
  --jq '.[]|select(.isDraft==false)|select(.mergeable=="MERGEABLE")|.number' 2>/dev/null \
| while read n; do
    grep -qx "$n" /tmp/qfill.queued && continue
    (sh .lead/scripts/qwatch.sh "$n" > ".lead/qw$n.log" 2>&1 &)
    echo "queued #$n"
  done

echo "--- conflicting/draft open PRs (need a rebase or are deliberate drafts) ---"
gh pr list -R "$R" --state open --limit 40 --json number,mergeable,isDraft \
  --jq '.[]|select((.mergeable!="MERGEABLE") or .isDraft)|"#\(.number) \(.mergeable)\(if .isDraft then " DRAFT" else "" end)"' 2>/dev/null
