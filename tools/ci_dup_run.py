#!/usr/bin/env python3
"""A `labeled` run never doubles a gate another run on its head is already giving.

The label and the open of one draft start two checks runs on one head. Both read the
PR's mode at run time, so both give the full gate: twice the runners, for one verdict.
A labeled run waits for the other runs on its head, and then mirrors the verdict of the
one that did the work, so the head's required check states exactly one result. A run
that did no full work (a light run) is not a verdict: the labeled run does the work.

    ci_dup_run.py --repo <owner/repo> --sha <head> --run <own run id> [--any]

`--any` counts a light run's verdict too: a label other than `full-ci` only restates it.
    ci_dup_run.py --self-test

Prints `work`, or `mirror <conclusion> <run id>`.
"""
import json
import os
import sys
import time
import urllib.request

WORKFLOW = "checks"
VERDICT_STEP = "verdict"  # `test` reaches this step only for a run that planned the full gate
WAIT_S = 30
GIVE_UP_S = 45 * 60


def accept_of(jobs):
    """The waiver key a run judged under: the `accepts <key>` step of its `test` job, or None for a run that
    predates the step."""
    for j in jobs:
        if j.get("name") == "test":
            for s in j.get("steps") or []:
                if (s.get("name") or "").startswith("accepts "):
                    return s["name"][len("accepts "):]
    return None


def decide(own, others, any_run=False, accept=None):
    """`others`: the other runs on the head, each {id, status, conclusion, full}.
    `work` when no run carries the verdict, `wait` while an EARLIER one is live, else the mirror."""
    # A RUN WAITS ONLY ON THE RUNS THAT STARTED BEFORE IT. A `labeled` and an `unlabeled` run sit in
    # different concurrency groups, so the two can be live together; a wait on a LATER sibling is a
    # wait on a run that is itself waiting on this one, and the pair stalls until both give up.
    # Ids are a total order, so the earliest run decides first and nothing cycles.
    if any(o["status"] != "completed" and o["id"] < own["id"] for o in others):
        return "wait"
    # a cancelled (or skipped, or never-concluded) run carries no verdict: only a run that reached
    # success or failure does, so a run that finds only cancelled siblings does the work itself
    # AND ONLY A VERDICT GIVEN UNDER THIS RUN'S WAIVER: the speed judge reads the PR body fresh, so a body edited
    # to add (or drop) a `SPEED_ACCEPT:` line must be re-judged, never handed the head's earlier verdict
    done = sorted((o for o in others if (o["full"] or any_run) and o["conclusion"] in ("success", "failure")
                   and (accept is None or o.get("accept") == accept)),
                  key=lambda o: o["id"], reverse=True)
    if not done:
        return "work"
    newest = done[0]
    return "mirror %s %s" % (newest["conclusion"], newest["id"])


def ran_full(jobs):
    """A run gave the full gate when its `test` job reached the `verdict` step: a light run's `test`
    refuses it in `light draft` instead, and a mirrored one never reaches it at all.

    NO HEAVY LEG CAN ANSWER THIS. A run whose diff owes no compiler plans full=1 and still skips
    `keepers-a` (it is gated on the build too), so a leg's skip says nothing about the mode. The
    question is asked of `test`, which is the one job that reads `full`. A renamed step leaves this
    answering False, which spends a gate rather than mirroring a light run's refusal."""
    return any(s.get("name") == VERDICT_STEP and s.get("conclusion") != "skipped"
               for j in jobs if j.get("name") == "test" for s in j.get("steps") or [])


def fetch(url, token):
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + token,
                                               "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def others_on(repo, sha, own, token):
    runs = fetch("https://api.github.com/repos/%s/actions/runs?head_sha=%s&event=pull_request&per_page=100"
                 % (repo, sha), token).get("workflow_runs", [])
    rows = []
    for r in runs:
        if r["id"] == own or r.get("name") != WORKFLOW:
            continue
        jobs = fetch("https://api.github.com/repos/%s/actions/runs/%d/jobs?per_page=100"
                     % (repo, r["id"]), token).get("jobs", [])
        rows.append({"id": r["id"], "status": r["status"], "conclusion": r.get("conclusion") or "",
                     "full": ran_full(jobs), "accept": accept_of(jobs)})
    return rows


def main(argv):
    if "--self-test" in argv:
        return self_test()
    any_run = "--any" in argv
    accept = None
    if "--accept" in argv:
        accept = argv[argv.index("--accept") + 1]
        del argv[argv.index("--accept"):argv.index("--accept") + 2]
    args = dict(zip([a for a in argv if a != "--any"][::2], [a for a in argv if a != "--any"][1::2]))
    repo, sha, own = args["--repo"], args["--sha"], int(args["--run"])
    token = os.environ.get("GH_TOKEN", "")
    waited = 0
    while True:
        verdict = decide({"id": own}, others_on(repo, sha, own, token), any_run, accept)
        if verdict != "wait" or waited >= GIVE_UP_S:
            print("work" if verdict == "wait" else verdict)
            return 0
        time.sleep(WAIT_S)
        waited += WAIT_S


def self_test():
    cases = [
        ("no other run: this run works",
         [], "work"),
        ("another run still live: wait for it",
         [{"id": 5, "status": "in_progress", "conclusion": "", "full": True}], "wait"),
        ("opened + labeled: the other full run's verdict is mirrored",
         [{"id": 5, "status": "completed", "conclusion": "success", "full": True}], "mirror success 5"),
        ("a failed full run is mirrored, not re-gated",
         [{"id": 5, "status": "completed", "conclusion": "failure", "full": True}], "mirror failure 5"),
        ("a light run is not a verdict: this run does the work",
         [{"id": 5, "status": "completed", "conclusion": "failure", "full": False}], "work"),
        ("a light run beside a full one: the full verdict stands",
         [{"id": 4, "status": "completed", "conclusion": "failure", "full": False},
          {"id": 5, "status": "completed", "conclusion": "success", "full": True}], "mirror success 5"),
        ("a cancelled full run carries nothing: this run does the work",
         [{"id": 5, "status": "completed", "conclusion": "cancelled", "full": True}], "work"),
        ("a cancelled run beside a finished one: the finished verdict stands",
         [{"id": 4, "status": "completed", "conclusion": "success", "full": True},
          {"id": 5, "status": "completed", "conclusion": "cancelled", "full": True}], "mirror success 4"),
    ]
    waived = [
        ("a failure under another waiver is not mirrored: the edited body is judged again",
         [{"id": 5, "status": "completed", "conclusion": "failure", "full": True, "accept": "aaa"}], "work"),
        ("a verdict under the same waiver is mirrored",
         [{"id": 5, "status": "completed", "conclusion": "failure", "full": True, "accept": "bbb"}], "mirror failure 5"),
        ("a run that predates the key carries no verdict under a waiver",
         [{"id": 5, "status": "completed", "conclusion": "success", "full": True}], "work"),
    ]
    restated = [
        ("another label restates a light run's verdict too",
         [{"id": 5, "status": "completed", "conclusion": "success", "full": False}], "mirror success 5"),
        ("another label with no finished run does the work",
         [{"id": 5, "status": "completed", "conclusion": "cancelled", "full": False}], "work"),
    ]
    late = [
        ("two label runs live together: the later one is not waited for, so the pair cannot stall",
         [{"id": 12, "status": "in_progress", "conclusion": "", "full": False}], "work"),
        ("an earlier live run is waited for and a later one is not",
         [{"id": 4, "status": "in_progress", "conclusion": "", "full": False},
          {"id": 12, "status": "in_progress", "conclusion": "", "full": False}], "wait"),
    ]
    jobs_cases = [
        ("a light run's test refuses it in `light draft`: not a full run",
         [{"name": "test", "conclusion": "failure", "steps": [
             {"name": "mirror", "conclusion": "skipped"},
             {"name": "light draft", "conclusion": "failure"},
             {"name": "verdict", "conclusion": "skipped"}]}], False),
        ("a run that owed no compiler gave the full gate anyway: keepers-a skipped, verdict ran",
         [{"name": "prepare", "conclusion": "success"},
          {"name": "keepers-a", "conclusion": "skipped"},
          {"name": "test", "conclusion": "success", "steps": [
              {"name": "light draft", "conclusion": "skipped"},
              {"name": "verdict", "conclusion": "success"}]}], True),
        ("a mirrored run carries a verdict but gave no gate: not a full run",
         [{"name": "test", "conclusion": "failure", "steps": [
             {"name": "mirror", "conclusion": "failure"},
             {"name": "verdict", "conclusion": "skipped"}]}], False),
        ("a verdict still running counts as the full run's",
         [{"name": "test", "conclusion": None, "steps": [{"name": "verdict", "conclusion": None}]}], True),
        ("no test job at all: not a full run",
         [{"name": "prepare", "conclusion": "success"}], False),
    ]
    bad = [(name, got, want) for name, jobs, want in jobs_cases for got in [ran_full(jobs)] if got != want]
    bad += [(name, got, want) for name, rows, want in restated for got in [decide({"id": 9}, rows, True)] if got != want]
    bad += [(name, got, want) for name, rows, want in late for got in [decide({"id": 9}, rows)] if got != want]
    bad += [(name, got, want) for name, rows, want in waived for got in [decide({"id": 9}, rows, False, "bbb")] if got != want]
    bad += [(name, got, want) for name, rows, want in cases for got in [decide({"id": 9}, rows)] if got != want]
    for name, got, want in bad:
        print("ci_dup_run: FAILED — %s: got %r, wanted %r" % (name, got, want))
    got = accept_of([{"name": "test", "steps": [{"name": "mirror"}, {"name": "accepts abc123"}]}, {"name": "x"}])
    if got != "abc123" or accept_of([{"name": "test", "steps": [{"name": "verdict"}]}]) is not None:
        print("ci_dup_run: FAILED — the waiver key is not read from the test job's `accepts` step: %r" % (got,))
        return 1
    if bad:
        return 1
    print("ci_dup_run: self-test clean — %d case(s)"
          % (len(cases) + len(jobs_cases) + len(restated) + len(late) + len(waived) + 1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
