#!/bin/sh
# THE AGGREGATE VERDICT: name the arithmetic, never a bare job name.
#
# `test` is the one required check; every other job is a shard or a step. This reads the run's
# `needs` JSON and answers whether every needed job is GREEN — `success`, or `skipped` because the
# event or the plan did not owe it — and refuses any other result, naming it. A skipped leg is BY
# DESIGN; a `failure`, a `cancelled`, a `timed_out` or a `startup_failure` is not, and the refusal
# carries what it counted:
#
#     test: PASSED — 9 success, 2 skipped, 0 failed (11 needed)
#     test: FAILED — 1 of 11 not green (8 success, 2 skipped)
#     test:   suites: failure
#
# An empty `needs` is refused: a verdict over no jobs judged nothing. The expected set is the
# `test` job's own `needs:` list, read from the workflow file, so the file is the ONE declaration
# of what the verdict owes; a job the run did not report is refused, not passed.
#
# Plain shell and jq (a runner carries both): the one required check must still speak when the
# job that builds every other instrument failed, so it stands on nothing the run makes.
#
#   sh tools/ci_verdict.sh --needs needs.json --workflow .github/workflows/checks.yml --job test
#   sh tools/ci_verdict.sh --self-test
set -u

# needed <workflow text> <job>: the job's `needs:` list as a JSON array, or nothing.
needed() {
    printf '%s\n' "$1" | awk -v job="$2" '
        found == 0 && $0 ~ "^  " job ":[ \t]*$" { found = 1; next }
        found == 1 && collecting == 0 && /^    needs:[ \t]*\[/ { collecting = 1; line = $0; sub(/^    needs:[ \t]*\[/, "", line); text = line; if (index(line, "]")) { done = 1 } }
        found == 1 && collecting == 1 && done == 0 && !/^    needs:/ { text = text " " $0; if (index($0, "]")) done = 1 }
        done == 1 { sub(/\].*/, "", text); n = split(text, parts, ","); out = ""; for (i = 1; i <= n; i++) { gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", parts[i]); if (parts[i] != "") out = out (out == "" ? "" : "\n") parts[i] }; print out; exit }
    ' | jq -R -s -c 'split("\n") | map(select(. != "")) | if length == 0 then empty else . end'
}

# verdict <needs json> <expect json or null>: the lines, the first saying PASSED or FAILED.
verdict() {
    printf '%s' "$1" | jq -r --argjson expect "$2" '
        def green: . == "success" or . == "skipped";
        . as $needs
        | ($expect // ($needs | keys_unsorted)) as $order
        | if ($order | length) == 0 then "test: FAILED — the run reported no jobs to judge"
          else
            [ $order[] as $n | { n: $n, r: (if $needs[$n] == null then "missing" else ($needs[$n].result // "missing") end) } ] as $rows
            | ($rows | group_by(.r) | map("\(length) \(.[0].r)") | join(", ")) as $summary
            | ($rows | map(select(.r | green | not))) as $bad
            | if ($bad | length) == 0 then "test: PASSED — \($summary) (\($order | length) needed)"
              else ("test: FAILED — \($bad | length) of \($order | length) not green (\($summary))", ($bad[] | "test:   \(.n): \(.r)"))
              end
          end'
}

if [ "${1:-}" = --self-test ]; then
    fail() { echo "ci_verdict: self-test FAILED — $1"; exit 1; }
    out=$(verdict '{"a":{"result":"success"},"b":{"result":"skipped"}}' null)
    [ "$out" = "test: PASSED — 1 skipped, 1 success (2 needed)" ] || fail "every job green: $out"
    out=$(verdict '{"prepare":{"result":"success"},"suites":{"result":"failure"},"gate":{"result":"skipped"}}' null)
    [ "$(printf '%s\n' "$out" | sed -n 1p)" = "test: FAILED — 1 of 3 not green (1 failure, 1 skipped, 1 success)" ] || fail "a failure is counted: $out"
    [ "$(printf '%s\n' "$out" | sed -n 2p)" = "test:   suites: failure" ] || fail "a failure is named: $out"
    for bad in cancelled timed_out startup_failure action_required; do
        out=$(verdict "{\"a\":{\"result\":\"$bad\"}}" null)
        [ "$(printf '%s\n' "$out" | sed -n 2p)" = "test:   a: $bad" ] || fail "$bad is refused: $out"
    done
    out=$(verdict '{"prepare":{"result":"success"}}' '["prepare","suites"]')
    printf '%s\n' "$out" | grep -qx "test:   suites: missing" && printf '%s\n' "$out" | sed -n 1p | grep -q "1 of 2 not green" || fail "a job owed and not reported: $out"
    wf='jobs:
  test:
    needs: [prepare, keepers-a, suites]
    if: always()
  other:
    needs: [x]
'
    [ "$(needed "$wf" test)" = '["prepare","keepers-a","suites"]' ] || fail "needs read from the workflow: $(needed "$wf" test)"
    wrapped='jobs:
  test:
    needs: [prepare,
            keepers-a, suites]
    if: always()
'
    [ "$(needed "$wrapped" test)" = '["prepare","keepers-a","suites"]' ] || fail "a wrapped list: $(needed "$wrapped" test)"
    [ -z "$(needed "$wf" missing)" ] || fail "an absent job answered"
    [ -z "$(needed 'jobs:
  test:
    runs-on: x
' test)" ] || fail "a job with no needs answered"
    out=$(verdict '{"a":{"result":"success"},"b":{"result":"success"}}' '["a"]')
    case "$out" in "test: PASSED"*"(1 needed)") ;; *) fail "an extra job in the count: $out" ;; esac
    out=$(verdict '{}' null)
    [ "$out" = "test: FAILED — the run reported no jobs to judge" ] || fail "no jobs judged: $out"
    echo "ci_verdict: self-test clean"
    exit 0
fi

needs_path= workflow= job= expect=null
while [ "$#" -gt 0 ]; do
    case "$1" in
        --needs) needs_path=$2; shift 2 ;;
        --workflow) workflow=$2; shift 2 ;;
        --job) job=$2; shift 2 ;;
        --expect) shift; expect=$(printf '%s\n' "$@" | jq -R . | jq -s -c .); set -- ;;
        *) echo "ci-verdict: unknown argument $1" >&2; exit 2 ;;
    esac
done
if [ -n "$workflow" ] && [ -n "$job" ]; then
    expect=$(needed "$(cat "$workflow")" "$job")
    if [ -z "$expect" ]; then
        echo "ci-verdict: \`$workflow\` has no job \`$job\` or it names no \`needs:\`" >&2
        exit 2
    fi
fi
[ -n "$needs_path" ] || { echo "ci-verdict: --needs <file> is required" >&2; exit 2; }
jq . "$needs_path"
lines=$(verdict "$(cat "$needs_path")" "$expect")
printf '%s\n' "$lines"
case "$lines" in "test: PASSED"*) exit 0 ;; *) exit 1 ;; esac
