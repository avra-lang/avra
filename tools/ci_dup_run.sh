#!/bin/sh
# A `labeled` run never doubles a gate another run on its head is already giving.
#
# The label and the open of one draft start two checks runs on one head. Both read the PR's mode
# at run time, so both give the full gate: twice the runners, for one verdict. A labeled run waits
# for the other runs on its head, and then mirrors the verdict of the one that did the work, so
# the head's required check states exactly one result. A run that did no full work (a light run)
# is not a verdict: the labeled run does the work.
#
# Plain shell, curl and jq: it runs in `prepare`'s plan step, before any compiler or built
# instrument exists.
#
#   sh tools/ci_dup_run.sh --repo <owner/repo> --sha <head> --run <own run id>
#   sh tools/ci_dup_run.sh --self-test
#
# Prints `work`, or `mirror <conclusion> <run id>`.
set -u

WORKFLOW=checks
FULL_JOB=keepers-a   # a full run runs this job; a light run does not
WAIT_S=${CI_DUP_WAIT_S:-30}
GIVE_UP_S=${CI_DUP_GIVE_UP_S:-2700}

# decide <others json>: `wait` while a run on the head is live, `work` when no run carries the
# verdict, else `mirror <conclusion> <id>` of the newest full run that reached success or failure.
# A cancelled (or skipped, or never-concluded) run carries no verdict.
decide() {
    printf '%s' "$1" | jq -r '
        if any(.[]; .status != "completed") then "wait"
        else
            ([.[] | select(.full and (.conclusion == "success" or .conclusion == "failure"))] | sort_by(.id) | reverse) as $done
            | if ($done | length) == 0 then "work" else "mirror \($done[0].conclusion) \($done[0].id)" end
        end'
}

api() { curl -fsS -H "Authorization: Bearer ${GH_TOKEN:-}" -H "Accept: application/vnd.github+json" "$1"; }

# others_on <repo> <sha> <own run id>: the other `checks` runs on the head, each with whether it ran
# the full gate.
others_on() {
    runs=$(api "https://api.github.com/repos/$1/actions/runs?head_sha=$2&event=pull_request&per_page=100") || return 1
    printf '%s' "$runs" | jq -c --argjson own "$3" --arg wf "$WORKFLOW" \
        '.workflow_runs // [] | map(select(.id != $own and .name == $wf)) | .[] | {id, status, conclusion: (.conclusion // "")}' |
    while IFS= read -r row; do
        id=$(printf '%s' "$row" | jq -r .id)
        jobs=$(api "https://api.github.com/repos/$1/actions/runs/$id/jobs?per_page=100") || jobs='{"jobs":[]}'
        full=$(printf '%s' "$jobs" | jq --arg j "$FULL_JOB" '[.jobs[]? | select(.name | startswith($j))] | length > 0')
        printf '%s' "$row" | jq -c --argjson full "$full" '. + {full: $full}'
    done | jq -s -c .
}

if [ "${1:-}" = --self-test ]; then
    check() { # check <name> <others json> <want>
        got=$(decide "$2")
        [ "$got" = "$3" ] || { echo "ci_dup_run: FAILED — $1: got '$got', wanted '$3'"; exit 1; }
    }
    check "no other run: this run works" '[]' work
    check "another run still live: wait for it" '[{"id":5,"status":"in_progress","conclusion":"","full":true}]' wait
    check "opened + labeled: the other full run's verdict is mirrored" '[{"id":5,"status":"completed","conclusion":"success","full":true}]' "mirror success 5"
    check "a failed full run is mirrored, not re-gated" '[{"id":5,"status":"completed","conclusion":"failure","full":true}]' "mirror failure 5"
    check "a light run is not a verdict: this run does the work" '[{"id":5,"status":"completed","conclusion":"failure","full":false}]' work
    check "a light run beside a full one: the full verdict stands" '[{"id":4,"status":"completed","conclusion":"failure","full":false},{"id":5,"status":"completed","conclusion":"success","full":true}]' "mirror success 5"
    check "a cancelled full run carries nothing: this run does the work" '[{"id":5,"status":"completed","conclusion":"cancelled","full":true}]' work
    check "a cancelled run beside a finished one: the finished verdict stands" '[{"id":4,"status":"completed","conclusion":"success","full":true},{"id":5,"status":"completed","conclusion":"cancelled","full":true}]' "mirror success 4"
    echo "ci_dup_run: self-test clean — 8 case(s)"
    exit 0
fi

repo= sha= own=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo) repo=$2; shift 2 ;;
        --sha) sha=$2; shift 2 ;;
        --run) own=$2; shift 2 ;;
        *) echo "ci_dup_run: unknown argument $1" >&2; exit 2 ;;
    esac
done
[ -n "$repo" ] && [ -n "$sha" ] && [ -n "$own" ] || { echo "ci_dup_run: --repo, --sha and --run are required" >&2; exit 2; }
waited=0
while :; do
    verdict=$(decide "$(others_on "$repo" "$sha" "$own")")
    if [ "$verdict" != wait ] || [ "$waited" -ge "$GIVE_UP_S" ]; then
        if [ "$verdict" = wait ]; then echo work; else echo "$verdict"; fi
        exit 0
    fi
    sleep "$WAIT_S"
    waited=$((waited + WAIT_S))
done
