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
#   sh tools/ci_wall.sh --self-test             # the arithmetic, over fixed jobs
#
# The stream is the one `tools/speed_ratchet.py --wall` reads:
#
#   host ci-wall
#   wall prepare <ms>
#   wall gate <ms>
#   wall total <ms>
#
# `total` is the SUM of the jobs' own clocks — the check's work, which no queue between jobs can
# inflate; a run's makespan also carries the runner's queue, and a crowded runner is not a
# regression the tree caused. A job the event skipped has no clock and is left out; the ratchet
# judges what was measured. Plain shell, curl and jq: the `test` job reads it with nothing built.
set -u

HOST=ci-wall

# lines <jobs json> <now, epoch seconds>: the metrics stream. A job with no start was not run; a
# skipped job carries a clock that did not (end <= start); a running job takes `now` as its end.
lines() {
    printf '%s' "$1" | jq -r --argjson now "$2" --arg host "$HOST" '
        def secs: if . == null then null else fromdateiso8601 end;
        [ .jobs[] | { name, start: (.started_at | secs), end: (.completed_at | secs) }
          | select(.start != null)
          | select(.end == null or .end > .start)
          | { name, ms: (((.end // $now) - .start) * 1000) } ] as $rows
        | "host \($host)",
          ($rows[] | "wall \(.name) \(.ms)"),
          (if ($rows | length) > 0 then "wall total \($rows | map(.ms) | add)" else empty end)'
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
wall total 160000"
    [ "$got" = "$want" ] || { echo "ci_wall: SELF-TEST FAILED — read:" >&2; echo "$got" >&2; exit 1; }
    [ "$(lines '{"jobs":[]}' "$now")" = "host ci-wall" ] || { echo "ci_wall: SELF-TEST FAILED — no jobs wrote a total" >&2; exit 1; }
    echo "ci_wall: self-test clean"
    exit 0
fi

base=${AVRA_WALL_API:-} repo=${GITHUB_REPOSITORY:-} run_id=${GITHUB_RUN_ID:-}
while [ "$#" -gt 0 ]; do
    case "$1" in
        --api) base=$2; shift 2 ;;
        --repo) repo=$2; shift 2 ;;
        --run) run_id=$2; shift 2 ;;
        collect) shift ;;
        *) echo "ci_wall: unknown argument $1" >&2; exit 2 ;;
    esac
done
if [ -z "$repo" ] || [ -z "$run_id" ]; then
    echo "ci_wall: collect needs GITHUB_REPOSITORY and GITHUB_RUN_ID (or --repo/--run)" >&2
    exit 1
fi
[ -n "$base" ] || base=https://api.github.com/repos/$repo
token=${GH_TOKEN:-${GITHUB_TOKEN:-}}
auth=
[ -z "$token" ] || auth="Authorization: Bearer $token"
jobs=$(curl -fsS --max-time 60 -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: avra-ci-wall" ${auth:+-H "$auth"} "$base/actions/runs/$run_id/jobs?per_page=100") || exit 1
lines "$jobs" "$(jq -n 'now | floor')"
