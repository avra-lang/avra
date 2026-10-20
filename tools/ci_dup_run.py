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
FULL_JOB = "keepers-a"  # a full run runs this job; a light run lists it, skipped
WAIT_S = 30
GIVE_UP_S = 45 * 60


def decide(own, others, any_run=False):
    """`others`: the other runs on the head, each {id, status, conclusion, full}.
    `work` when no run carries the verdict, `wait` while one is live, else the mirror."""
    if any(o["status"] != "completed" for o in others):
        return "wait"
    # a cancelled (or skipped, or never-concluded) run carries no verdict: only a run that reached
    # success or failure does, so a run that finds only cancelled siblings does the work itself
    done = sorted((o for o in others if (o["full"] or any_run) and o["conclusion"] in ("success", "failure")),
                  key=lambda o: o["id"], reverse=True)
    if not done:
        return "work"
    newest = done[0]
    return "mirror %s %s" % (newest["conclusion"], newest["id"])


def ran_full(jobs):
    """A run gave the full gate when its `keepers-a` job RAN: a light run lists the job too, as
    skipped, and a skipped job is no verdict."""
    return any(j["name"].startswith(FULL_JOB) and j.get("conclusion") != "skipped" for j in jobs)


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
                     "full": ran_full(jobs)})
    return rows


def main(argv):
    if "--self-test" in argv:
        return self_test()
    any_run = "--any" in argv
    args = dict(zip([a for a in argv if a != "--any"][::2], [a for a in argv if a != "--any"][1::2]))
    repo, sha, own = args["--repo"], args["--sha"], int(args["--run"])
    token = os.environ.get("GH_TOKEN", "")
    waited = 0
    while True:
        verdict = decide({"id": own}, others_on(repo, sha, own, token), any_run)
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
    restated = [
        ("another label restates a light run's verdict too",
         [{"id": 5, "status": "completed", "conclusion": "success", "full": False}], "mirror success 5"),
        ("another label with no finished run does the work",
         [{"id": 5, "status": "completed", "conclusion": "cancelled", "full": False}], "work"),
    ]
    jobs_cases = [
        ("a light run lists keepers-a skipped: not a full run",
         [{"name": "prepare", "conclusion": "success"}, {"name": "keepers-a", "conclusion": "skipped"}], False),
        ("a sharded full run ran keepers-a",
         [{"name": "keepers-a (1)", "conclusion": "success"}, {"name": "keepers-a (2)", "conclusion": "failure"}], True),
        ("a keepers-a still running counts as the full run's",
         [{"name": "keepers-a", "conclusion": None}], True),
        ("no keepers-a at all: not a full run",
         [{"name": "prepare", "conclusion": "success"}], False),
    ]
    bad = [(name, got, want) for name, jobs, want in jobs_cases for got in [ran_full(jobs)] if got != want]
    bad += [(name, got, want) for name, rows, want in restated for got in [decide({"id": 9}, rows, True)] if got != want]
    bad += [(name, got, want) for name, rows, want in cases for got in [decide({"id": 9}, rows)] if got != want]
    for name, got, want in bad:
        print("ci_dup_run: FAILED — %s: got %r, wanted %r" % (name, got, want))
    if bad:
        return 1
    print("ci_dup_run: self-test clean — %d case(s)" % (len(cases) + len(jobs_cases) + len(restated)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
