#!/usr/bin/env python3
"""THE DETERMINISTIC WATCHER — no LLM, one pass every two minutes.

The merge queue and a PR's own check are two systems with a gap between
them, and every hour lost to that gap was a human noticing something a
script could have noticed. This watcher closes it, deterministically:

  (a) a PR whose required `test` FAILED — tell it the exact `job — line`,
      and re-run the failed jobs ONCE (a second rerun of the same head
      changes nothing, so it is refused by state, not by try-again);
  (b) a green, mergeable, unmerged PR not in the queue — enqueue it
      (auto-merge when it is not set, a direct enqueue when it is), but
      ONLY while the queue holds fewer than `AVRA_QUEUE_MAX` entries
      (default 3): a full train is ~40 min of the shared runner pool, so
      N entries in flight saturate it and every extra entry makes the
      queue land SLOWER, not more. A green PR over the cap is held and
      named (`queue at 3 — holding #537`), never dropped; a later pass
      enqueues it once a slot frees.
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
import tempfile
from datetime import datetime, timedelta, timezone

PR = "pull_request"
DEFAULT_REPO = "avra-lang/avra"
# N full trains in flight saturate the runners, so beyond a few entries the
# merge queue runs SLOWER (trains sit `queued` and nothing finishes). Three
# keeps slots moving without starving the pool; override with
# AVRA_QUEUE_MAX only to measure a different value.
QUEUE_MAX = 3
FULL = {"pull_request", "merge_group", "push", "workflow_dispatch", "schedule"}
RERUN = "rerun"
TOLD = "told"


# ---- the decision (pure; this is what the fixtures prove) --------------
def plan(prs, queue, trains, state, limit=QUEUE_MAX):
    """The actions a pass owes. See the module docstring for the rules.

    `prs`: number, isDraft, state, mergeable, autoMerge, headRefOid,
           inQueue, test = None | {conclusion, runId, attempt, job, line}
    `queue`: pr, nodeId, stuck
    `trains`: pr, databaseId, job, line
    `state`: {"rerun": {key}, "told": {key}}
    `limit`: the queue-depth cap for new enqueues (rule b).
    """
    acts = []
    rerun, told = state["rerun"], state["told"]

    # (d) a failed train names its failing job on the PR it carried.
    for t in trains:
        key = f"train:{t['databaseId']}"
        if key in told:
            continue
        acts.append({"do": "comment", "pr": t["pr"], "mark": ("told", key),
                     "text": f"train failed: {t['job']} — {t['line']}\n\n"
                             f"Run `sh tools/work land` from the worktree once this is fixed."})

    # (b) the cap: room is the queue's whole depth budget. Entries with a
    # train RUNNING count against it and are never touched, so a new enqueue
    # can never displace a train already in flight. Candidates are taken in
    # the order the list arrives in — never re-sorted or shuffled — so
    # whatever priority the pass put on it is the order the cap spends.
    room = max(0, limit - len(queue))
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
                acts.append({"do": "comment", "pr": n, "text": body,
                             "mark": ("told", key)})
            if want_rerun:
                acts.append({"do": "rerun", "run": t["runId"],
                             "mark": ("rerun", f"rerun:{n}:{head}")})
            continue
        # (b) green, mergeable, unmerged, not queued — enqueue it.
        if (t is not None and t["conclusion"] == "SUCCESS"
                and p["state"] == "OPEN" and not p["isDraft"]
                and p["mergeable"] == "MERGEABLE" and not p["inQueue"]):
            if room > 0:
                acts.append({"do": "enqueue-auto" if not p["autoMerge"] else "enqueue",
                             "pr": n, "node": p.get("nodeId"), "why": "new"})
                room -= 1
            else:
                acts.append({"do": "hold", "pr": n,
                             "text": f"queue at {limit} — holding #{n}"})

    # (c) a queued entry with no train: take it out and put it back. Only a
    # `stuck` entry is touched, so one whose train is running is left where
    # it stands; the cap above already counted it against the depth budget.
    for q in queue:
        if q.get("stuck"):
            acts.append({"do": "dequeue", "node": q["nodeId"], "pr": q["pr"]})
            acts.append({"do": "enqueue", "pr": q["pr"], "node": q["nodeId"],
                         "why": "kick"})
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
         "{entries(first:100){nodes{state pullRequest{number id headRefOid} enqueuedAt}}}}}" % (owner, name))
    out = _gh(["api", "graphql", "-f", f"query={q}", "--jq",
               ".data.repository.mergeQueue.entries.nodes[] | "
               "[.state, (.pullRequest.number|tostring), .pullRequest.id, .pullRequest.headRefOid, .enqueuedAt] | @tsv"],
              check=False)
    entries = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) == 5:
            entries.append({"state": parts[0], "pr": int(parts[1]), "nodeId": parts[2],
                            "headSha": parts[3], "enqueuedAt": parts[4]})
    return entries


def _merge_group_runs(repo):
    return _gh_json(["run", "list", "-R", repo, "-e", "merge_group", "-L", "100",
                     "--json", "databaseId,conclusion,headBranch,headSha,createdAt"])


# (c) fires for a STUCK entry ONLY. An entry is stuck when it has sat more
# than five minutes with NO merge_group run for it since it was enqueued: a
# fresh entry has not been picked up yet, and one whose train is running has
# a run created after it. Churning either cancels an in-flight train.
STUCK_MINUTES = 5


def _entry_stuck(e, runs, now):
    raw = e.get("enqueuedAt")
    if not raw:
        return False  # cannot judge an entry's age: leave it alone
    try:
        enq = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return False
    if now - enq < timedelta(minutes=STUCK_MINUTES):
        return False
    for r in runs:
        m = re.search(r"/pr-(\d+)-", r.get("headBranch") or "")
        if not m or int(m.group(1)) != e["pr"]:
            continue
        try:
            ts = datetime.fromisoformat((r.get("createdAt") or "").replace("Z", "+00:00"))
        except ValueError:
            continue
        if ts >= enq - timedelta(seconds=60):
            return False  # a train started for THIS entry
    return True


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
    now = datetime.now(timezone.utc)
    for e in q:
        e["stuck"] = _entry_stuck(e, runs, now)
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
def do_action(a, repo, run):
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
    elif a["do"] == "hold":
        pass  # a decision, not a mutation: the log says what the cap held.
    else:
        raise RuntimeError(f"unknown action {a['do']}")


def execute(actions, repo, run=_gh):
    """Take every action, each in its own try. ONE un-mergeable PR (a
    protected branch that refuses auto-merge, a race with a closed PR)
    must never abort the pass: the failure is named and the rest run.
    Answers the indices that failed, so their marks are not committed."""
    failed = []
    for i, a in enumerate(actions):
        try:
            do_action(a, repo, run)
        except Exception as e:
            failed.append(i)
            where = a.get("pr", a.get("run", ""))
            print(f"pr-watcher: {where} {a['do']} FAILED — {e}", file=sys.stderr)
    return failed


def commit_marks(actions, failed, state):
    """A SUCCEEDED action's mark is committed; a FAILED one's is not, so
    the next pass retries exactly it and repeats nothing that worked."""
    for i, a in enumerate(actions):
        if i in failed:
            continue
        m = a.get("mark")
        if m:
            state[m[0]][m[1]] = True


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
    # (b) THE CAP: a queue at the cap enqueues NOTHING and names what it held.
    ("queue-at-cap-holds",
     dict(prs=[_pr(7, "SUCCESS")],
          queue=[{"pr": 4, "nodeId": "N4", "stuck": False},
                 {"pr": 5, "nodeId": "N5", "stuck": False},
                 {"pr": 6, "nodeId": "N6", "stuck": False}],
          trains=[], state=_empty_state()),
     [("hold", 7)]),
    # a queue below the cap enqueues.
    ("room-below-cap-enqueues",
     dict(prs=[_pr(7, "SUCCESS")],
          queue=[{"pr": 4, "nodeId": "N4", "stuck": False},
                 {"pr": 5, "nodeId": "N5", "stuck": False}],
          trains=[], state=_empty_state()),
     [("enqueue-auto", 7)]),
    # the cap spends its room in list order and holds only the excess.
    ("cap-holds-the-excess",
     dict(prs=[_pr(7, "SUCCESS"), _pr(8, "SUCCESS")],
          queue=[{"pr": 4, "nodeId": "N4", "stuck": False},
                 {"pr": 5, "nodeId": "N5", "stuck": False}],
          trains=[], state=_empty_state()),
     [("enqueue-auto", 7), ("hold", 8)]),
    # a running entry is never dequeued even beside a stuck one.
    ("running-entry-untouched",
     dict(prs=[], queue=[{"pr": 7, "nodeId": "N7", "stuck": False},
                         {"pr": 8, "nodeId": "N8", "stuck": True}],
          trains=[], state=_empty_state()),
     [("dequeue", 8), ("enqueue", 8)]),
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
    commit_marks(first, [], st)
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

    # (2) THE STUCK PREDICATE IS REAL: a fresh entry and an entry whose train
    # started are never stuck; only an old entry with no run is.
    now = datetime(2026, 1, 1, 12, 0, 0, tzinfo=timezone.utc)
    run_after = {"headBranch": "gh-readonly-queue/main/pr-7-abc",
                 "createdAt": "2026-01-01T11:56:30Z"}
    old_with_run = {"pr": 7, "enqueuedAt": "2026-01-01T11:55:00Z"}
    fresh_no_run = {"pr": 8, "enqueuedAt": "2026-01-01T11:59:30Z"}
    old_no_run = {"pr": 9, "enqueuedAt": "2026-01-01T11:50:00Z"}
    if _entry_stuck(old_with_run, [run_after], now):
        sys.exit("pr-watcher: self-test — an entry with a train was called stuck")
    if _entry_stuck(fresh_no_run, [], now):
        sys.exit("pr-watcher: self-test — a fresh entry was called stuck")
    if not _entry_stuck(old_no_run, [], now):
        sys.exit("pr-watcher: self-test — an entry with no run for 10 minutes was not stuck")
    if plan([], [{"pr": 8, "nodeId": "N8", "stuck": False},
                 {"pr": 7, "nodeId": "N7", "stuck": False}], [], _empty_state()) != []:
        sys.exit("pr-watcher: self-test — a healthy queue produced actions")

    # THE CAP'S LOG NAMES THE LIMIT AND THE PR IT HELD, and the default is
    # three while AVRA_QUEUE_MAX moves it.
    held = plan([_pr(7, "SUCCESS")],
                [{"pr": 4, "nodeId": "N4", "stuck": False},
                 {"pr": 5, "nodeId": "N5", "stuck": False},
                 {"pr": 6, "nodeId": "N6", "stuck": False}],
                [], _empty_state())
    if [(a["do"], a["text"]) for a in held] != [("hold", "queue at 3 — holding #7")]:
        sys.exit(f"pr-watcher: self-test — the cap's hold line was {held}")
    os.environ["AVRA_QUEUE_MAX"] = "2"
    try:
        if queue_max() != 2:
            sys.exit("pr-watcher: self-test — AVRA_QUEUE_MAX was not read")
    finally:
        del os.environ["AVRA_QUEUE_MAX"]
    if queue_max() != QUEUE_MAX:
        sys.exit("pr-watcher: self-test — the cap did not fall back to its default")
    # The cap's new enqueues and rule (c)'s kicks wear distinct marks, so the
    # dry run can report what the cap did apart from the queue's own churn.
    if plan([_pr(7, "SUCCESS")], [], [], _empty_state())[0].get("why") != "new":
        sys.exit("pr-watcher: self-test — a cap enqueue was not marked new")
    kick = plan([], [{"pr": 8, "nodeId": "N8", "stuck": True}], [], _empty_state())
    if [a.get("why") for a in kick] != [None, "kick"]:
        sys.exit("pr-watcher: self-test — a stuck-entry kick was not marked")

    # (1)+(3) ONE FAILING ACTION MUST NOT ABORT THE PASS, AND STATE IS SAVED
    # WITH ONLY THE SUCCEEDED MARKS: the failed action is retried next pass.
    acts = plan([_pr(1, "FAILURE")], [],
                [{"pr": 5, "databaseId": 777, "job": "keepers-a", "line": "x"}],
                _empty_state())
    calls = []

    def flaky(args, _calls=calls):
        _calls.append(args)
        if args[0] == "run" and args[1] == "rerun":
            raise RuntimeError("GraphQL: Pull request Protected branch rules not configured")

    failed = execute(acts, "r", flaky)
    if len(calls) != len(acts) or len(failed) != 1:
        sys.exit("pr-watcher: self-test — a failed action stopped the pass")
    st = _empty_state()
    d = tempfile.mkdtemp(prefix="pr-watcher-selftest-")
    p = os.path.join(d, "state.json")
    world = {"prs": [_pr(1, "FAILURE")], "queue": [],
             "trains": [{"pr": 5, "databaseId": 777, "job": "keepers-a", "line": "x"}]}
    run_pass(world, st, p, "r", execute_fn=lambda a, r: execute(a, r, flaky))
    saved = load_state(p)
    if saved["rerun"] or not saved["told"]:
        sys.exit("pr-watcher: self-test — state saved a failed mark or lost a succeeded one")


def queue_max():
    """The cap from the environment, or the default. A blank or unreadable
    value falls back rather than crashing a pass the whole landing waits on."""
    raw = (os.environ.get("AVRA_QUEUE_MAX") or "").strip()
    return int(raw) if raw.isdigit() and int(raw) > 0 else QUEUE_MAX


def run_pass(world, state, state_path, repo, execute_fn=execute, limit=QUEUE_MAX):
    """One live pass. State is committed and SAVED in a `finally`:
    whatever an action or the pass itself does, the marks of what
    SUCCEEDED stand and the next pass retries only what failed."""
    acts = plan(world["prs"], world["queue"], world["trains"], state, limit)
    for a in acts:
        print("pr-watcher:", a["do"], a.get("pr", a.get("run", "")), a.get("text", ""))
    failed = []
    try:
        failed = execute_fn(acts, repo)
    finally:
        commit_marks(acts, failed, state)
        save_state(state_path, state)
    return acts


def main(argv):
    if "--self-test" in argv:
        selftest()
        print(f"pr-watcher: self-test — {len(SELFTEST)} plan scenario(s) and the "
              f"finder/runner cases hold")
        return 0
    repo = os.environ.get("GH_REPO", DEFAULT_REPO)
    state_path = os.environ.get("AVRA_WATCHER_STATE",
                                os.path.expanduser("~/.avra-pr-watcher/state.json"))
    state = load_state(state_path)
    world = collect(repo, state)
    limit = queue_max()
    if "--dry-run" in argv:
        acts = plan(world["prs"], world["queue"], world["trains"], state, limit)
        # New enqueues (rule b) are what the cap governs; kicks (rule c) are
        # re-enqueues of entries already counted against the depth.
        new = sum(1 for a in acts if a.get("why") == "new")
        kicks = sum(1 for a in acts if a.get("why") == "kick")
        held = sum(1 for a in acts if a["do"] == "hold")
        for a in acts:
            tag = f" [{a['why']}]" if a.get("why") else ""
            print("pr-watcher:", a["do"] + tag, a.get("pr", a.get("run", "")), a.get("text", ""))
        print(f"pr-watcher: dry run — queue at {len(world['queue'])}/{limit}: "
              f"{new} new enqueue(s), {held} held, {kicks} stuck-entry kick(s) — "
              f"not taken, state untouched")
        return 0
    acts = run_pass(world, state, state_path, repo, limit=limit)
    print(f"pr-watcher: {len(world['prs'])} open PR(s), {len(world['queue'])} queued, "
          f"{len(world['trains'])} failed train(s) — {len(acts)} action(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
