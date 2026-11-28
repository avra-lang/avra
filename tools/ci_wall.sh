#!/bin/sh
# tool-witness: --self-test
# THE WALL-CLOCK MEASUREMENT.
#
# One PR check's wall time, per job and whole, read from the run's own jobs as GitHub reports
# them — the clock the owner's budget is about, which no step's own `date` arithmetic can see (a
# runner's queue, container init and artifact hand-downs are all wall time).
#
#   sh tools/ci_wall.sh collect                 # the metrics for $GITHUB_RUN_ID on stdout
#   sh tools/ci_wall.sh --api <base> --repo <o/r> --run <id> collect
#   sh tools/ci_wall.sh landed <sha>            # the wall record of the gate run that landed <sha>
#   sh tools/ci_wall.sh --self-test             # the arithmetic, over fixed jobs
#
# The stream is the one tools/ledger_rows.sh reads into `wall:` rows (WALL_HOST names the host, else
# ci-wall):
#
#   host ci-wall
#   wall prepare <ms>
#   wall gate <ms>
#   wall total <ms>
#   wall makespan <ms>
#
# `total` is the SUM of the jobs' own clocks — the run's work, which no queue between jobs can
# inflate; `makespan` is the first start to the last end, the wall a run is waited for, and carries
# the runner's queue too. A job the event skipped has no clock and is left out; the ledger judges
# what was measured. Plain shell, curl and jq.
#
# `landed` answers one word for the green gate run whose head is <sha>: `unread` when its verdict
# ran the `gate wall unread` step, `judged` when its `gate wall` step ran alone, `none` when no such
# run holds a wall record. It exits 1 when the API did not answer, which is no record either way.
set -u

HOST=${WALL_HOST:-ci-wall}

# lines <jobs json> <now, epoch seconds>: the metrics stream. A job with no start was not run; a
# skipped job carries a clock that did not (end <= start); a running job takes `now` as its end.
lines() {
    printf '%s' "$1" | jq -r --argjson now "$2" --arg host "$HOST" '
        def secs: if . == null then null else fromdateiso8601 end;
        [ .jobs[] | { name, start: (.started_at | secs), end: (.completed_at | secs) }
          | select(.start != null)
          | select(.end == null or .end > .start)
          | { name, start, end: (.end // $now) } ] as $runs
        | [ $runs[] | { name, ms: ((.end - .start) * 1000) } ] as $rows
        | "host \($host)",
          ($rows[] | "wall \(.name) \(.ms)"),
          (if ($rows | length) > 0 then "wall total \($rows | map(.ms) | add)" else empty end),
          (if ($runs | length) > 0 then "wall makespan \((($runs | map(.end) | max) - ($runs | map(.start) | min)) * 1000)" else empty end)'
}

# record <runs json> <jobs json of the newest green gate run>: that run's wall record
record() {
    [ "$(printf '%s' "$1" | jq '[.workflow_runs[] | select(.name == "gate" and .conclusion == "success")] | length')" -gt 0 ] || { echo none; return; }
    printf '%s' "$2" | jq -r '
        [ .jobs[] | select(.name == "verdict") | .steps[] ] as $steps
        | if any($steps[]; .name == "gate wall unread" and .conclusion == "success") then "unread"
          elif any($steps[]; .name == "gate wall" and .conclusion != "skipped") then "judged"
          else "none" end'
}

# newest <runs json>: the id of the newest green gate run among them
newest() {
    printf '%s' "$1" | jq -r '[.workflow_runs[] | select(.name == "gate" and .conclusion == "success") | .id] | max // empty'
}

if [ "${1:-}" = --self-test ]; then
    jobs='{"jobs":[
      {"name":"prepare","started_at":"2026-01-01T00:00:05Z","completed_at":"2026-01-01T00:01:05Z"},
      {"name":"gate","started_at":"2026-01-01T00:01:10Z","completed_at":"2026-01-01T00:02:40Z"},
      {"name":"running","started_at":"2026-01-01T00:02:50Z","completed_at":null},
      {"name":"skipped","started_at":null,"completed_at":null},
      {"name":"noclock","started_at":"2026-01-01T00:02:00Z","completed_at":"2026-01-01T00:02:00Z"}]}'
    now=$(printf '2026-01-01T00:03:00Z' | jq -R 'fromdateiso8601')
    got=$(lines "$jobs" "$now")
    want="host ci-wall
wall prepare 60000
wall gate 90000
wall running 10000
wall total 160000
wall makespan 175000"
    [ "$got" = "$want" ] || { echo "ci_wall: SELF-TEST FAILED — read:" >&2; echo "$got" >&2; exit 1; }
    [ "$(lines '{"jobs":[]}' "$now")" = "host ci-wall" ] || { echo "ci_wall: SELF-TEST FAILED — no jobs wrote a total" >&2; exit 1; }
    runs='{"workflow_runs":[{"id":7,"name":"gate","conclusion":"failure"},{"id":9,"name":"gate","conclusion":"success"},
      {"id":8,"name":"gate","conclusion":"success"},{"id":12,"name":"checks","conclusion":"success"}]}'
    [ "$(newest "$runs")" = 9 ] || { echo "ci_wall: SELF-TEST FAILED — the newest green gate run is not 9" >&2; exit 1; }
    verdict() { printf '{"jobs":[{"name":"slice (a)","steps":[{"name":"gate wall unread","conclusion":"success"}]},{"name":"verdict","steps":[%s]}]}' "$1"; }
    for case in 'unread|{"name":"gate wall","conclusion":"success"},{"name":"gate wall unread","conclusion":"success"}' \
        'unread|{"name":"gate wall","conclusion":"failure"},{"name":"gate wall unread","conclusion":"success"}' \
        'judged|{"name":"gate wall","conclusion":"success"},{"name":"gate wall unread","conclusion":"skipped"}' \
        'judged|{"name":"gate wall","conclusion":"failure"}' \
        'none|{"name":"gate wall","conclusion":"skipped"}' \
        'none|{"name":"table","conclusion":"success"}'; do
        got=$(record "$runs" "$(verdict "${case#*|}")")
        [ "$got" = "${case%%|*}" ] || { echo "ci_wall: SELF-TEST FAILED — read $got where ${case%%|*} was written: ${case#*|}" >&2; exit 1; }
    done
    [ "$(record '{"workflow_runs":[{"id":7,"name":"gate","conclusion":"failure"}]}' "$(verdict '{"name":"gate wall unread","conclusion":"success"}')")" = none ] \
        || { echo "ci_wall: SELF-TEST FAILED — a red run's record was read as a landing's" >&2; exit 1; }
    echo "ci_wall: self-test clean"
    exit 0
fi

base=${AVRA_WALL_API:-} repo=${GITHUB_REPOSITORY:-} run_id=${GITHUB_RUN_ID:-} verb=collect sha=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --api) base=$2; shift 2 ;;
        --repo) repo=$2; shift 2 ;;
        --run) run_id=$2; shift 2 ;;
        collect) shift ;;
        landed) verb=landed sha=${2:?ci_wall: landed names a commit}; shift 2 ;;
        *) echo "ci_wall: unknown argument $1" >&2; exit 2 ;;
    esac
done
if [ -z "$repo" ] || { [ "$verb" = collect ] && [ -z "$run_id" ]; }; then
    echo "ci_wall: collect needs GITHUB_REPOSITORY and GITHUB_RUN_ID (or --repo/--run)" >&2
    exit 1
fi
[ -n "$base" ] || base=https://api.github.com/repos/$repo
token=${GH_TOKEN:-${GITHUB_TOKEN:-}}
auth=
[ -z "$token" ] || auth="Authorization: Bearer $token"
# A RUN'S JOBS IN PAGES OF 30, each asked up to four times: the API answers a wide page of a large
# run with a 5xx that a narrow one never meets, and a hiccup is no measurement
asked() { # <path>: what the API answered there, or nothing after four tries
    for try in 1 2 3 4; do
        curl -fsS --max-time 60 -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: avra-ci-wall" \
            ${auth:+-H "$auth"} "$base/$1" && return 0
        sleep $((try * 3))
    done
    return 1
}
jobs_of() { # <run id>: every job of that run, one object
    pages=""
    page=1
    while :; do
        got=$(asked "actions/runs/$1/jobs?per_page=30&page=$page") || { echo "ci_wall: page $page of run $1's jobs did not answer in four tries" >&2; return 1; }
        pages="$pages$got"
        [ "$(printf '%s' "$got" | jq '.jobs | length')" -ge 30 ] || break
        page=$((page + 1))
    done
    printf '%s' "$pages" | jq -s '{jobs: (map(.jobs) | add)}'
}
if [ "$verb" = landed ]; then
    runs=$(asked "actions/runs?head_sha=$sha&event=push&status=completed&per_page=30") || { echo "ci_wall: the runs of $sha did not answer in four tries" >&2; exit 1; }
    id=$(newest "$runs")
    [ -n "$id" ] || { echo none; exit 0; }
    jobs=$(jobs_of "$id") || exit 1
    record "$runs" "$jobs"
    exit 0
fi
jobs=$(jobs_of "$run_id") || exit 1
lines "$jobs" "$(jq -n 'now | floor')"
