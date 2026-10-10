#!/usr/bin/env python3
"""THE DETERMINISTIC WATCHER — no LLM, one pass every two minutes.

The merge queue and a PR's own check are two systems with a gap between
them, and every hour lost to that gap was a human noticing something a
script could have noticed. This watcher closes it, deterministically:

  (a) a PR whose required `test` FAILED — tell it the exact `job — line`,
      and re-run the failed jobs ONCE (a second rerun of the same head
      changes nothing, so it is refused by state, not by try-again);
  (b) a green, mergeable, unmerged PR not in the queue — enqueue it
      (auto-merge when it is not set, a direct enqueue when it is);
  (c) a queued entry with no `merge_group` run — dequeue and put it back,
      since an entry with no train starts nothing by waiting;
  (d) a failed train — name its failing `job — line` on the PR it carried.

The DECISION is a pure function (`plan`) over a world the gh CLI reads,
so it is proved against fixtures with NO network and NO LLM
(`--self-test`). Only `collect` and `execute` touch GitHub.

State (which heads were rerun, which failures were told) lives in a
small JSON file restored and saved by the workflow's cache: `--state`.
"""
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone

PR = "pull_request"
DEFAULT_REPO = "avra-lang/avra"
FULL = {"pull_request", "merge_group", "push", "workflow_dispatch", "schedule"}
RERUN = "rerun"
TOLD = "told"


# ---- the decision (pure; this is what the fixtures prove) --------------
def plan(prs, queue, trains, state):
    """The actions a pass owes. See the module docstring for the rules.

    `prs`: number, isDraft, state, mergeable, autoMerge, headRefOid,
           inQueue, test = None | {conclusion, runId, attempt, job, line}
    `queue`: pr, nodeId, stuck
    `trains`: pr, databaseId, job, line
    `state`: {"rerun": {key}, "told": {key}}
    """
    acts = []
    rerun, told = state["rerun"], state["told"]

    # (d) a failed train names its failing job on the PR it carried.
    for t in trains:
        key = f"train:{t['databaseId']}"
        if key in told:
            continue
        told[key] = True
        acts.append({"do": "comment", "pr": t["pr"],
                     "text": f"train failed: {t['job']} — {t['line']}\n\n"
                             f"Run `sh tools/work land` from the worktree once this is fixed."})

    for p in prs:
        n, head = p["number"], p["headRefOid"]
        t = p.get("test")
        failed = t is not None and t["conclusion"] == "FAILURE"
        # (a) the PR's own check failed: say why, and rerun the failed jobs once.
        if failed:
            want_rerun = t.get("attempt", 1) == 1 and f"rerun:{n}:{head}" not in rerun
            key = f"told:{n}:{head}"
            if want_rerun or key not in told:
                body = f"BLOCKED: {t['job']} — {t['line']}"
                if want_rerun:
                    body += "\n\nRe-running the failed jobs once."
                told[key] = True
                acts.append({"do": "comment", "pr": n, "text": body})
            if want_rerun:
                rerun[f"rerun:{n}:{head}"] = True
                acts.append({"do": "rerun", "run": t["runId"]})
            continue
        # (b) green, mergeable, unmerged, not queued — enqueue it.
        if (t is not None and t["conclusion"] == "SUCCESS"
                and p["state"] == "OPEN" and not p["isDraft"]
                and p["mergeable"] == "MERGEABLE" and not p["inQueue"]):
            acts.append({"do": "enqueue-auto" if not p["autoMerge"] else "enqueue",
                         "pr": n, "node": p.get("nodeId")})

    # (c) a queued entry with no train: take it out and put it back.
    for q in queue:
        if q.get("stuck"):
            acts.append({"do": "dequeue", "node": q["nodeId"], "pr": q["pr"]})
            acts.append({"do": "enqueue", "pr": q["pr"], "node": q["nodeId"]})
    return acts


# ---- reading the world (gh) --------------------------------------------
def _gh(args, check=True):
    p = subprocess.run(["gh", *args], capture_output=True, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(f"gh {' '.join(args)}: {p.stderr.strip()}")
    return p.stdout


def _gh_json(args):
    return json.loads(_gh(args))


ANSI = re.compile(r"\x1b\[[0-9;]*m")


def first_cause(text):
    """The line of a log that names the failure, in the watcher's own words.

    A `##[error]` annotation is the runner's own verdict and wins; a
    keeper's `refused`, a suite's `!= expected`, a compiler `error[` and
    a test-count mismatch are next. A shell line echoed by the step's own
    script is never the cause, so `[ ... ]` and `echo ...` are skipped."""
    errs, bads = [], []
    for l in text.splitlines():
        body = ANSI.sub("", l.split("Z ", 1)[-1]).rstrip()
        if not body or body.startswith("##["):
            if body.startswith("##[error]"):
                errs.append(body[len("##[error]"):].strip())
            continue
        s = body.lstrip()
        if s.startswith("[") or s.startswith("echo ") or s.startswith("if "):
            continue
        if ("✗" in body or "!= expected" in body or "eval != " in body
                or s.startswith("error[") or " refused" in body
                or (re.search(r"\d+/\d+ tests passed", body)
                    and not re.search(r"(\d+)/\1 tests passed", body))):
            bads.append(body)
    pick = (errs or bads)
    return pick[0][:240] if pick else "(no failing line read — open the job log)"


def failing_job(repo, run_id):
    jobs = _gh_json(["run", "view", str(run_id), "-R", repo, "--json",
                     "jobs,attempt"]).get("jobs", [])
    bad = [j for j in jobs if j.get("conclusion") in
           ("failure", "timed_out", "startup_failure", "action_required")]
    if not bad:
        return None
    # the aggregate `test` says only that something failed; prefer the real job.
    j = next((x for x in bad if x["name"] != "test"), bad[0])
    log = _gh(["run", "view", str(run_id), "-R", repo, "--job",
               str(j["databaseId"]), "--log-failed"], check=False)
    return {"job": j["name"], "line": first_cause(log)}


def open_prs(repo):
    return _gh_json(["pr", "list", "-R", repo, "--state", "open", "--limit", "100",
                     "--json", "number,id,isDraft,state,mergeable,autoMergeRequest,"
                               "headRefOid,statusCheckRollup"])


def merge_queue(repo):
    owner, name = repo.split("/", 1)
    q = ("{repository(owner:\"%s\",name:\"%s\"){mergeQueue(branch:\"main\")"
         "{entries(first:100){nodes{state pullRequest{number id headRefOid}}}}}}" % (owner, name))
    out = _gh(["api", "graphql", "-f", f"query={q}", "--jq",
               ".data.repository.mergeQueue.entries.nodes[] | "
               "[.state, (.pullRequest.number|tostring), .pullRequest.id, .pullRequest.headRefOid] | @tsv"],
              check=False)
    entries = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) == 4:
            entries.append({"state": parts[0], "pr": int(parts[1]), "nodeId": parts[2],
                            "headSha": parts[3]})
    return entries


def _merge_group_runs(repo):
    return _gh_json(["run", "list", "-R", repo, "-e", "merge_group", "-L", "100",
                     "--json", "databaseId,conclusion,headBranch,headSha,createdAt"])


def _recent_run_prs(runs, minutes):
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=minutes)
    n = set()
    for r in runs:
        m = re.search(r"/pr-(\d+)-", r.get("headBranch") or "")
        try:
            ts = datetime.fromisoformat((r.get("createdAt") or "").replace("Z", "+00:00"))
        except ValueError:
            continue
        if m and ts >= cutoff:
            n.add(int(m.group(1)))
    return n


def test_of(repo, pr):
    for c in pr.get("statusCheckRollup") or []:
        name = c.get("name") or c.get("context")
        if name != "test":
            continue
        concl = c.get("conclusion") or c.get("state")
        run_id = None
        url = c.get("detailsUrl") or c.get("targetUrl") or ""
        m = re.search(r"/runs/(\d+)", url)
        if m:
            run_id = int(m.group(1))
        info = {"conclusion": (concl or "").upper(), "runId": run_id, "attempt": 1,
                "job": "test", "line": "(the failed job was not read)"}
        if info["conclusion"] == "FAILURE" and run_id:
            attempt = _gh(["api", f"repos/{repo}/actions/runs/{run_id}",
                           "--jq", ".run_attempt"], check=False).strip()
            info["attempt"] = int(attempt) if attempt.isdigit() else 1
        return info
    return None


# A pass runs every two minutes, so it must not read a log it already told.
# State gates the expensive fetches, and the whole pass is capped so a bad
# afternoon of failures can never turn the watcher itself into the outage.
DETAIL_CAP = 6


def collect(repo, state):
    told = state[TOLD]
    q = merge_queue(repo)
    inq = {e["pr"] for e in q}
    runs = _merge_group_runs(repo)
    # A queued entry is stuck when no train has started on it lately: an
    # UNMERGEABLE entry stalls the whole queue, and one with no run for ten
    # minutes was made and never picked up. A run in progress is recent.
    recent = _recent_run_prs(runs, minutes=10)
    for e in q:
        e["stuck"] = e["state"] == "UNMERGEABLE" or e["pr"] not in recent
    prs = []
    for raw in open_prs(repo):
        p = dict(raw)
        p["autoMerge"] = raw.get("autoMergeRequest") is not None
        p["nodeId"] = raw.get("id")
        p["inQueue"] = raw["number"] in inq
        p["test"] = test_of(repo, raw)
        prs.append(p)
    # Enrich only a failing PR that will be acted on (untold, or attempt 1).
    detail = 0
    for p in prs:
        t = p.get("test")
        if not t or t["conclusion"] != "FAILURE" or not t["runId"]:
            continue
        key = f"told:{p['number']}:{p['headRefOid']}"
        if key in told and t["attempt"] != 1:
            continue
        if detail >= DETAIL_CAP:
            break
        detail += 1
        fj = failing_job(repo, t["runId"])
        if fj:
            t["job"], t["line"] = fj["job"], fj["line"]
    trains = []
    seen, new = set(), 0
    for r in runs:
        if r["conclusion"] != "failure":
            continue
        m = re.search(r"/pr-(\d+)-", r["headBranch"] or "")
        if not m:
            continue
        key = f"train:{r['databaseId']}"
        pr = int(m.group(1))
        if key in told or pr in seen:
            continue
        if new >= DETAIL_CAP:
            break
        seen.add(pr)
        new += 1
        fj = failing_job(repo, r["databaseId"])
        if fj:
            trains.append({"databaseId": r["databaseId"], "pr": pr,
                           "job": fj["job"], "line": fj["line"]})
    return {"prs": prs, "queue": q, "trains": trains}


# ---- doing the actions (gh) --------------------------------------------
def execute(actions, repo, run=_gh):
    for a in actions:
        if a["do"] == "comment":
            run(["pr", "comment", str(a["pr"]), "-R", repo, "--body", a["text"]])
        elif a["do"] == "rerun":
            run(["run", "rerun", str(a["run"]), "--failed", "-R", repo])
        elif a["do"] == "enqueue":
            run(["api", "graphql", "-f",
                 f'mutation={{enqueuePullRequest(input:{{pullRequestId:"{a["node"]}"}}){{clientMutationId}}}}'])
        elif a["do"] == "enqueue-auto":
            run(["pr", "merge", str(a["pr"]), "-R", repo, "--auto", "--squash"])
        elif a["do"] == "dequeue":
            run(["api", "graphql", "-f",
                 f'mutation={{dequeuePullRequest(input:{{id:"{a["node"]}"}}){{clientMutationId}}}}'])
        else:
            raise RuntimeError(f"unknown action {a['do']}")


def load_state(path):
    try:
        with open(path) as f:
            s = json.load(f)
    except (OSError, ValueError):
        s = {}
    s.setdefault(RERUN, {})
    s.setdefault(TOLD, {})
    return s


def save_state(path, state):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w") as f:
        json.dump(state, f, indent=1, sort_keys=True)


# ---- the proof (no network, no LLM) ------------------------------------
def _pr(n, concl, **kw):
    base = {"number": n, "isDraft": False, "state": "OPEN", "mergeable": "MERGEABLE",
            "autoMerge": False, "headRefOid": f"h{n}", "inQueue": False,
            "test": {"conclusion": concl, "runId": 900 + n, "attempt": 1,
                     "job": "gate", "line": "gate_changed: idioms refused packages/cli"}}
    base.update(kw)
    return base


def _empty_state():
    return {RERUN: {}, TOLD: {}}


SELFTEST = [
    # (a) a failed PR is told its exact job — line and rerun once.
    ("failed-pr-reruns-once", dict(prs=[_pr(1, "FAILURE")], queue=[], trains=[],
                              state=_empty_state()),
     [("comment", 1), ("rerun", 901)]),
    # the same head a second time: nothing (attempt is now 2).
    ("rerun-not-twice",
     dict(prs=[_pr(1, "FAILURE", test={"conclusion": "FAILURE", "runId": 901,
                                       "attempt": 2, "job": "gate", "line": "x"})],
          queue=[], trains=[],
          state={RERUN: {"rerun:1:h1": True}, TOLD: {"told:1:h1": True}}),
     []),
    # (b) a green mergeable PR is enqueued (auto-merge when unset).
    ("green-enqueues", dict(prs=[_pr(2, "SUCCESS")], queue=[], trains=[], state=_empty_state()),
     [("enqueue-auto", 2)]),
    ("green-already-auto",
     dict(prs=[_pr(2, "SUCCESS", autoMerge=True)], queue=[], trains=[], state=_empty_state()),
     [("enqueue", 2)]),
    # a green PR already in the queue: nothing.
    ("green-in-queue",
     dict(prs=[_pr(2, "SUCCESS", inQueue=True)], queue=[], trains=[], state=_empty_state()),
     []),
    # a conflicted or draft PR is left alone.
    ("conflicting-left", dict(prs=[_pr(3, "SUCCESS", mergeable="CONFLICTING")],
                              queue=[], trains=[], state=_empty_state()), []),
    ("draft-left", dict(prs=[_pr(3, "SUCCESS", isDraft=True)],
                        queue=[], trains=[], state=_empty_state()), []),
    # (c) a queued entry with no train is dequeued and re-enqueued.
    ("stuck-entry",
     dict(prs=[], queue=[{"pr": 4, "nodeId": "N4", "stuck": True}],
          trains=[], state=_empty_state()),
     [("dequeue", 4), ("enqueue", 4)]),
    # (d) a failed train names its job on the PR once.
    ("failed-train-told-once",
     dict(prs=[], queue=[], trains=[{"pr": 5, "databaseId": 777, "job": "keepers-a",
                                     "line": "compile-slots refused"}], state=_empty_state()),
     [("comment", 5)]),
]


def selftest():
    for name, world, want in SELFTEST:
        acts = plan(world["prs"], world["queue"], world["trains"], world["state"])
        got = [(a["do"], a.get("pr", a.get("run"))) for a in acts]
        if got != want:
            sys.exit(f"pr-watcher: self-test failed on `{name}`: got {got}, want {want}")
    # a failed PR told once, not every pass.
    st = _empty_state()
    first = plan([_pr(1, "FAILURE")], [], [], st)
    second = plan([_pr(1, "FAILURE", test={"conclusion": "FAILURE", "runId": 901,
                                           "attempt": 2, "job": "gate", "line": "x"})],
                  [], [], st)
    if first == [] or second != []:
        sys.exit("pr-watcher: self-test — a failure was not told exactly once")
    # first_cause names a keeper refusal and a test mismatch.
    if "refused" not in first_cause("... keepers: gate refused ..."):
        sys.exit("pr-watcher: self-test — first_cause missed a keeper refusal")
    if "tests passed" not in first_cause("1/2 tests passed"):
        sys.exit("pr-watcher: self-test — first_cause missed a test mismatch")


def main(argv):
    if "--self-test" in argv:
        selftest()
        print(f"pr-watcher: self-test — {len(SELFTEST)} scenario(s) hold")
        return 0
    repo = os.environ.get("GH_REPO", DEFAULT_REPO)
    state_path = os.environ.get("AVRA_WATCHER_STATE",
                                os.path.expanduser("~/.avra-pr-watcher/state.json"))
    state = load_state(state_path)
    world = collect(repo, state)
    acts = plan(world["prs"], world["queue"], world["trains"], state)
    for a in acts:
        print("pr-watcher:", a["do"], a.get("pr", a.get("run", "")), a.get("text", ""))
    if "--dry-run" in argv:
        print(f"pr-watcher: dry run — {len(acts)} action(s) not taken")
        return 0
    execute(acts, repo)
    save_state(state_path, state)
    print(f"pr-watcher: {len(world['prs'])} open PR(s), {len(world['queue'])} queued, "
          f"{len(world['trains'])} failed train(s) — {len(acts)} action(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
