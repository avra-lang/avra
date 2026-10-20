#!/bin/sh
# THE PR'S BODY, READ FRESH. `github.event.pull_request.body` is the payload frozen when the run
# started, so a waiver line (`SPEED_ACCEPT: <reason>`) added afterwards is invisible even to a
# re-run of the job. This asks the API for the PR as it is now (PR_NUMBER and GH_TOKEN), and
# answers $PR_BODY — the payload's — when it cannot (no PR, no token, no answer).
#
#   sh tools/pr_body.sh            the body, on stdout
#   sh tools/pr_body.sh --self-test
set -u

body() {
    if [ -n "${PR_NUMBER:-}" ] && [ -n "${GH_TOKEN:-}" ]; then
        api=${PR_BODY_API:-https://api.github.com/repos/${GITHUB_REPOSITORY:-avra-lang/avra}/pulls/$PR_NUMBER}
        if got=$(curl -fsS -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" "$api" 2>/dev/null) &&
            text=$(printf '%s' "$got" | python3 -c 'import json,sys; b=json.load(sys.stdin).get("body"); sys.stdout.write(b or "")' 2>/dev/null); then
            printf '%s\n' "$text"
            return 0
        fi
    fi
    printf '%s\n' "${PR_BODY:-}"
}

if [ "${1:-}" = --self-test ]; then
    d=$(mktemp -d)
    printf '{"body": "text\\nSPEED_ACCEPT: now"}' > "$d/pr.json"
    got=$(PR_NUMBER=7 GH_TOKEN=t PR_BODY_API="file://$d/pr.json" PR_BODY='SPEED_ACCEPT: stale' body)
    printf '%s\n' "$got" | grep -qx 'SPEED_ACCEPT: now' || { echo "pr_body: the fresh body was not read: $got"; exit 1; }
    got=$(PR_NUMBER=7 GH_TOKEN=t PR_BODY_API="file://$d/missing.json" PR_BODY='SPEED_ACCEPT: payload' body)
    printf '%s\n' "$got" | grep -qx 'SPEED_ACCEPT: payload' || { echo "pr_body: an unanswered API did not fall back to the payload: $got"; exit 1; }
    got=$(PR_BODY='SPEED_ACCEPT: payload' body)
    printf '%s\n' "$got" | grep -qx 'SPEED_ACCEPT: payload' || { echo "pr_body: no PR number did not fall back to the payload: $got"; exit 1; }
    echo "pr_body: self-test passed — the API's body wins, the payload answers when it cannot"
    exit 0
fi
body
