#!/usr/bin/env python3
"""THE AGGREGATE VERDICT: name the arithmetic, never a bare job name.

`test` is the one required check; every other job is a shard or a step.
This reads the run's `needs` JSON and answers whether every needed job is
GREEN — `success`, or `skipped` because the event or the plan did not owe
it — and refuses any other result, naming it. A skipped leg is BY DESIGN
and is not a failure; a `failure`, a `cancelled`, a `timed_out` or a
`startup_failure` is, and the refusal carries what it counted:

    test: PASSED — 9 success, 2 skipped, 0 failed (11 needed)
    test: FAILED — 1 of 11 not green (8 success, 2 skipped)
      suites: failure

A matrix job's aggregate is GitHub's own worst-of-its-legs, so a `suites`
refusal names a leg that failed; this tool judges the same truth and says
the count so the reader can see the arithmetic the old `FAILED — suites`
hid. An empty `needs` is refused: a verdict over no jobs judged nothing.

    ci_verdict.py --needs needs.json --workflow .github/workflows/checks.yml --job test
    ci_verdict.py --self-test

The expected set is the `test` job's own `needs:` list, read from the
workflow file, so the file is the ONE declaration of what the verdict
owes and no hand-kept copy can drift from it. A job the job needs but
the run did not report is refused, not passed.
"""
import json
import re
import sys

# A job is GREEN when it succeeded or was skipped BY DESIGN. Every other
# terminal result — failure, cancelled, timed_out, startup_failure,
# action_required, neutral, stale — is not green and is named.
GREEN = ("success", "skipped")


def needed_from_workflow(text, job):
    """The `needs:` list of `job`, read from the workflow text — the one
    declaration of what the `test` job owes, so no hand-kept copy can
    drift from it. Answers None when the job or its `needs:` is absent,
    which the caller refuses rather than judging nothing."""
    m = re.search(r"^  %s:\s*$" % re.escape(job), text, re.M)
    if not m:
        return None
    m2 = re.search(r"^    needs:\s*\[(.*?)\]", text[m.end():], re.M | re.S)
    if not m2:
        return None
    return [n.strip() for n in m2.group(1).split(",") if n.strip()]


def verdict(needs, expect=None):
    """(ok, text_lines). Every needed job is judged: a green result counts
    toward the total, any other result is not green and is listed. An
    empty `needs` is not a pass. `expect`, when given, names jobs the run
    OWED; one absent from `needs` is a refusal too, so a gate that never
    reported is not a gate that passed."""
    order = list(expect) if expect else list(needs)
    if not order:
        return False, ["test: FAILED — the run reported no jobs to judge"]
    counts = {}
    not_green = []
    for name in order:
        row = needs.get(name)
        if row is None:
            counts["missing"] = counts.get("missing", 0) + 1
            not_green.append((name, "missing"))
            continue
        result = row.get("result", "missing")
        counts[result] = counts.get(result, 0) + 1
        if result not in GREEN:
            not_green.append((name, result))
    total = len(order)
    summary = ", ".join("%d %s" % (counts[k], k) for k in sorted(counts))
    if not not_green:
        return True, ["test: PASSED — %s (%d needed)" % (summary, total)]
    lines = ["test: FAILED — %d of %d not green (%s)" % (len(not_green), total, summary)]
    for name, result in not_green:
        lines.append("test:   %s: %s" % (name, result))
    return False, lines


def _self_test():
    # every job green is a pass, and the arithmetic is stated
    ok, lines = verdict({"a": {"result": "success"}, "b": {"result": "skipped"}})
    assert ok and lines == ["test: PASSED — 1 skipped, 1 success (2 needed)"], (ok, lines)
    # a failure is refused and NAMED, with the count of what was not green
    ok, lines = verdict({
        "prepare": {"result": "success"},
        "suites": {"result": "failure"},
        "gate": {"result": "skipped"},
    })
    assert not ok, lines
    assert lines[0] == "test: FAILED — 1 of 3 not green (1 failure, 1 skipped, 1 success)", lines
    assert lines[1] == "test:   suites: failure", lines
    # every non-green terminal result is refused, not only `failure`
    for bad in ("cancelled", "timed_out", "startup_failure", "action_required"):
        ok, lines = verdict({"a": {"result": bad}})
        assert not ok and lines[1] == "test:   a: %s" % bad, (bad, lines)
    # a job the run OWED but never reported is refused and named
    ok, lines = verdict({"prepare": {"result": "success"}}, expect=["prepare", "suites"])
    assert not ok and any("suites: missing" in l for l in lines) and "1 of 2 not green" in lines[0], lines
    # the expected set is read from the workflow's own `needs:` line
    wf = """jobs:
  test:
    needs: [prepare, keepers-a, suites]
    if: always()
  other:
    needs: [x]
"""
    assert needed_from_workflow(wf, "test") == ["prepare", "keepers-a", "suites"]
    # a flow list YAML wrapped across lines still parses
    wf_wrapped = """jobs:
  test:
    needs: [prepare,
            keepers-a, suites]
    if: always()
"""
    assert needed_from_workflow(wf_wrapped, "test") == ["prepare", "keepers-a", "suites"]
    assert needed_from_workflow(wf, "missing") is None
    assert needed_from_workflow("jobs:\n  test:\n    runs-on: x\n", "test") is None
    # an unexpected extra job is not silently dropped from the count
    ok, lines = verdict({"a": {"result": "success"}, "b": {"result": "success"}},
                        expect=["a"])
    assert ok and "(1 needed)" in lines[0], lines
    # no jobs judged is not a pass
    ok, lines = verdict({})
    assert not ok and lines == ["test: FAILED — the run reported no jobs to judge"], lines
    print("ci_verdict: self-test clean")
    return 0


def main(argv):
    if "--self-test" in argv:
        return _self_test()
    needs_path, expect, workflow, job = None, None, None, None
    i = 0
    while i < len(argv):
        if argv[i] == "--needs":
            needs_path = argv[i + 1]
            i += 2
        elif argv[i] == "--workflow":
            workflow = argv[i + 1]
            i += 2
        elif argv[i] == "--job":
            job = argv[i + 1]
            i += 2
        elif argv[i] == "--expect":
            expect = argv[i + 1:]
            i = len(argv)
        else:
            print("ci-verdict: unknown argument %s" % argv[i], file=sys.stderr)
            return 2
    if workflow and job:
        with open(workflow) as f:
            expect = needed_from_workflow(f.read(), job)
        if not expect:
            print("ci-verdict: `%s` has no job `%s` or it names no `needs:`" % (workflow, job),
                  file=sys.stderr)
            return 2
    if not needs_path:
        print("ci-verdict: --needs <file> is required", file=sys.stderr)
        return 2
    with open(needs_path) as f:
        needs = json.load(f)
    print(json.dumps(needs, indent=2))
    ok, lines = verdict(needs, expect)
    for line in lines:
        print(line)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
