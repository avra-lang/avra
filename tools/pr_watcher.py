#!/usr/bin/env python3
"""THE DETERMINISTIC WATCHER — no LLM, one pass every two minutes.

The merge queue and a PR's own check are two systems with a gap between
them, and every hour lost to that gap was a human noticing something a
script could have noticed. This watcher closes it, deterministically:

  (a) a PR whose required `test` FAILED — tell it the exact `job — line`,
      and re-run the failed jobs ONCE (a second rerun of the same head
      changes nothing, so it is refused by attempt, not by try-again);
  (b) a green, mergeable, unmerged PR not in the queue — enqueue it
      (auto-merge when it is not set, a direct enqueue when it is), but
      ONLY while the queue holds fewer than `AVRA_QUEUE_MAX` entries
      (default 6, tuned to the train's cost — see `QUEUE_MAX`): a full
      train occupies the shared runner pool for its whole duration, so
      N entries in flight saturate it and every extra entry makes the
      queue land SLOWER, not more. A green PR over the cap is held and
      named (`queue at 6 — holding #537`), never dropped; a later pass
      enqueues it once a slot frees. A green DRAFT never rides a train,
      so it is named, and taken ready where landing is wanted;
  (c) a queued entry that NOTHING is moving — dequeue and put it back. A
      train needs ~30–45 min, so an entry whose newest `merge_group` run
      is `in_progress`/`queued`, or started less than `STUCK_MINUTES`
      ago, is WORKING and is never churned (churning it cancels the live
      train and restarts the clock forever);
  (d) a failed train — name its failing `job — line` on the PR it carried;
  (e) a DRAFT — name it `#N is a DRAFT — unlandable` so it is never
      invisible, and take a green, otherwise-landable, wanted one ready
      (`DO NOT MERGE` in the title is the deliberate exception);
  (f) a CONFLICT — name it once with the rebase the owner owes
      (`git rebase --onto origin/main main <branch>`), sharing its words
      with `tools/queue_keeper.sh` so the two never drift;
  (g) BLOCKED — name the check it waits on, once.

EVERY open PR gets an action or a loud name: a state the watcher cannot
move is still a state it says out loud, never one it skips. Every comment
is deduped by `(pr, head, reason)`, so a pass over an unchanged head
repeats nothing.

The DECISION is a pure function (`plan`) over a world the gh CLI reads,
so it is proved against fixtures with NO network and NO LLM
(`--self-test`). Only `collect` and `execute` touch GitHub.

Every comment carries its own dedup key in an HTML marker, and
`do_action` refuses a body whose marker already stands on the PR — so a
lost state file can never re-post a comment, and two watchers (this one
and the machine's) never double-comment. State (which heads were rerun,
which failures were told) lives in a small JSON file restored and saved
by the workflow's cache: `--state`.
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
# THE QUEUE CAP IS TUNED TO THE TRAIN'S COST, NEVER CHOSEN ONCE. N full
# trains in flight saturate the shared runner pool, so too many entries make
# the queue land SLOWER, not more. The cap was 3 when every train paid a
# COLD COMPILER REBUILD in `prepare` (~7-16 minutes) and three saturated the
# pool; `prepare` now fetches a release compiler and costs ~76 s, so that
# rationale is gone. This repo's merge-queue ruleset allows
# `max_entries_to_build: 10` concurrent `merge_group` runs (GitHub's setting
# ranges 1-100; `max_entries_to_merge: 5`), so 6 doubles throughput while
# staying under the build concurrency and leaving room for entries an owner
# or the queue keeper adds. RE-TUNE FROM DATA: read a train's `prepare` time
# and its total duration when the pool saturates, and move this number with
# the cost; override with AVRA_QUEUE_MAX to measure a different value.
QUEUE_MAX = 6
FULL = {"pull_request", "merge_group", "push", "workflow_dispatch", "schedule"}
RERUN = "rerun"
TOLD = "told"
# A PR whose title says DO NOT MERGE is a deliberate draft: named, never
# readied. The phrase is a claim the owner wrote, not a state we infer.
DO_NOT_MERGE = re.compile(r"DO\s+NOT\s+MERGE", re.IGNORECASE)
# THE CONFLICT WORDS ARE ONE DEFINITION: `tools/queue_keeper.sh` speaks the
# same sentence, and the self-test refuses the two drifting apart.
CONFLICT_PHRASE = "this conflicts with main and cannot ride a train. Rebase onto origin/main"


# ---- the decision (pure; this is what the fixtures prove) --------------
def _waiting_on(p):
    """What a non-conflicting, non-draft, non-failing PR is waiting on.

    A missing `test` names itself; a pending one names its state; a green
    one whose merge state is not CLEAN names that. None means the PR is
    simply not required yet (a state a fixture may leave unmodelled).
    """
    t = p.get("test")
    if t is None:
        return "the required `test` check (not run yet)"
    c = (t.get("conclusion") or "").upper()
    if c == "SUCCESS":
        mss = (p.get("mergeStateStatus") or "CLEAN").upper()
        return None if mss == "CLEAN" else f"the merge state ({mss})"
    if c == "FAILURE":
        return None  # rule (a) owns it
    return f"the required `test` check ({c.lower() or 'pending'})"


def plan(prs, queue, trains, state, limit=QUEUE_MAX):
    """The actions a pass owes. See the module docstring for the rules.

    `prs`: number, isDraft, state, mergeable, mergeStateStatus, title,
           headRefName, autoMerge, headRefOid, inQueue,
           test = None | {conclusion, runId, attempt, job, line}
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
        acts.append({"do": "comment", "pr": t["pr"], "key": key, "mark": ("told", key),
                     "text": f"train failed: {t['job']} — {t['line']}\n\n"
                             f"Run `sh tools/work land` from the worktree once this is fixed."})

    # The cap governs NEW enqueues: room is the queue's whole depth budget.
    # Entries with a train RUNNING count against it and are never touched,
    # so a new enqueue can never displace a train already in flight.
    # Candidates are taken in the order the list arrives in — never
    # re-sorted or shuffled — so whatever priority the pass put on it is the
    # order the cap spends.
    room = max(0, limit - len(queue))
    for p in prs:
        n, head = p["number"], p["headRefOid"]
        t = p.get("test")
        failed = t is not None and t["conclusion"] == "FAILURE"
        conflicted = p.get("mergeable") == "CONFLICTING"
        draft = bool(p.get("isDraft"))
        green = t is not None and t["conclusion"] == "SUCCESS"
        open_ = p["state"] == "OPEN"
        # `mergeStateStatus` is CLEAN only when every requirement — checks,
        # reviews, no conflict — is met; a fixture omitting it means CLEAN.
        landable = (p.get("mergeable") == "MERGEABLE"
                    and (p.get("mergeStateStatus") or "CLEAN").upper() == "CLEAN")

        # (a) a failing check is the cause behind every other state: name the
        # job — line, and rerun the failed jobs once.
        if failed:
            want_rerun = t.get("attempt", 1) == 1 and f"rerun:{n}:{head}" not in rerun
            key = f"told:{n}:{head}"
            if want_rerun or key not in told:
                body = f"BLOCKED: {t['job']} — {t['line']}"
                if want_rerun:
                    body += "\n\nRe-running the failed jobs once."
                acts.append({"do": "comment", "pr": n, "key": key, "text": body,
                             "mark": ("told", key)})
            else:
                acts.append({"do": "note", "pr": n,
                             "text": f"#{n} still FAILING: {t['job']} — {t['line']} (told)"})
            if want_rerun:
                acts.append({"do": "rerun", "run": t["runId"],
                             "mark": ("rerun", f"rerun:{n}:{head}")})

        # (f) a conflict is named, so its owner is told rather than guessing;
        # its words are `tools/queue_keeper.sh`'s own.
        if conflicted:
            key = f"conflict:{n}:{head}"
            if key in told:
                acts.append({"do": "note", "pr": n,
                             "text": f"#{n} still conflicts with main (told)"})
            else:
                acts.append({"do": "comment", "pr": n, "key": key, "mark": ("told", key),
                             "also": CONFLICT_PHRASE,
                             "text": f"CONFLICT: {CONFLICT_PHRASE} — "
                                     f"`git rebase --onto origin/main main "
                                     f"{p.get('headRefName') or '<branch>'}`, "
                                     f"then `sh tools/work land`."})

        # (e) a draft is named — never silently skipped — and a green,
        # otherwise-landable, wanted one is taken ready.
        if draft:
            key = f"draft:{n}:{head}"
            if key in told:
                acts.append({"do": "note", "pr": n,
                             "text": f"#{n} is still a DRAFT (told)"})
            else:
                acts.append({"do": "comment", "pr": n, "key": key, "mark": ("told", key),
                             "text": f"#{n} is a DRAFT — unlandable. "
                                     f"`gh pr ready {n}` when it should land."})
            if (green and landable and open_ and not conflicted and not p["inQueue"]
                    and not DO_NOT_MERGE.search(p.get("title") or "")):
                acts.append({"do": "ready", "pr": n,
                             "text": f"#{n} is a green DRAFT — marking it ready"})

        # A failed, conflicting or draft PR is fully named above and cannot
        # ride a train; an in-queue one is named and left to its own train.
        if failed or conflicted or draft or p["inQueue"]:
            if p["inQueue"]:
                acts.append({"do": "note", "pr": n,
                             "text": f"#{n} is in the queue — its train decides"})
            continue

        # (b) green, mergeable, unconflicted, not queued — arm auto-merge (or
        # enqueue when it is already armed) while the cap has room.
        if green and landable and open_:
            if room > 0:
                acts.append({"do": "enqueue-auto" if not p["autoMerge"] else "enqueue",
                             "pr": n, "node": p.get("nodeId"), "why": "new"})
                room -= 1
            else:
                acts.append({"do": "hold", "pr": n,
                             "text": f"queue at {limit} — holding #{n}"})
            continue

        # (g) blocked — name the check it is waiting on, once.
        why = _waiting_on(p)
        key = f"blocked:{n}:{head}"
        if why and key not in told:
            acts.append({"do": "comment", "pr": n, "key": key, "mark": ("told", key),
                         "text": f"BLOCKED: waiting on {why}"})
        elif why:
            acts.append({"do": "note", "pr": n,
                         "text": f"#{n} still BLOCKED on {why} (told)"})
        else:
            acts.append({"do": "note", "pr": n,
                         "text": f"#{n} {p.get('mergeStateStatus') or 'unknown'} — no action owed"})

    # (c) a queued entry with no live train: take it out and put it back. Only
    # a `stuck` entry is touched, so one whose train is running is left where
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
                     "--json", "number,id,isDraft,state,mergeable,mergeStateStatus,"
                               "title,headRefName,autoMergeRequest,"
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
                     "--json", "databaseId,conclusion,status,headBranch,headSha,createdAt"])


# (c) fires for a STUCK entry ONLY. A train needs ~30–45 minutes; churning
# an entry whose train is STILL RUNNING cancels it and restarts the clock
# forever, which is how a queue sat on one PR for hours while main never
# moved. So the bar is a train's whole duration, not five minutes, and a
# live run is never touched however long the entry has waited.
STUCK_MINUTES = 45


def _parse_ts(raw):
    """An ISO timestamp as aware UTC, or None when unreadable."""
    try:
        return datetime.fromisoformat((raw or "").replace("Z", "+00:00"))
    except ValueError:
        return None


def _newest_run(runs, pr):
    """The newest merge_group run for `pr` as (created, run), or None."""
    latest = None
    for r in runs:
        m = re.search(r"/pr-(\d+)-", r.get("headBranch") or "")
        if not m or int(m.group(1)) != pr:
            continue
        ts = _parse_ts(r.get("createdAt"))
        if ts is not None and (latest is None or ts > latest[0]):
            latest = (ts, r)
    return latest


def _entry_stuck(e, runs, now):
    """A queued entry is stuck only when NOTHING is moving it.

    A run that is `in_progress`/`queued` is a live train — WORKING, never
    churned. Only an entry with NO run at all, or whose newest run began
    longer ago than a whole train takes, may be dequeued and put back.
    """
    enq = _parse_ts(e.get("enqueuedAt"))
    if enq is None or now - enq < timedelta(minutes=STUCK_MINUTES):
        return False  # too young to judge: leave it alone
    latest = _newest_run(runs, e["pr"])
    if latest is None:
        return True  # no train ever started for the entry
    ts, r = latest
    if r.get("status") in ("in_progress", "queued"):
        return False  # a live train is WORKING
    return now - ts >= timedelta(minutes=STUCK_MINUTES)


def test_of(repo, pr):
    for c in pr.get("statusCheckRollup") or []:
        name = c.get("name") or c.get("context")
        if name != "test":
            continue
        concl = c.get("conclusion") or c.get("state") or c.get("status")
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
        body, key = a["text"], a.get("key")
        if key:
            # THE COMMENT CARRIES ITS OWN DEDUP KEY, so a lost state file
            # cannot re-post it and a second watcher cannot double it. A
            # conflict also yields to a standing `queue_keeper.sh` comment,
            # which speaks `CONFLICT_PHRASE`: the two share the words, so
            # one phrase both names the conflict and proves it was named.
            # An unreadable answer refuses nothing, so a query that fails
            # does not silence the comment.
            needles = [f"<!-- pr-watcher:{key} -->"]
            if a.get("also"):
                needles.append(a["also"])
            sel = " or ".join(f"contains({json.dumps(nd)})" for nd in needles)
            seen = run(["pr", "view", str(a["pr"]), "-R", repo, "--json", "comments",
                        "--jq", f"[.comments[].body | select({sel})] | length"])
            if (seen or "").strip() not in ("", "0"):
                return
            body += f"\n\n<!-- pr-watcher:{key} -->"
        run(["pr", "comment", str(a["pr"]), "-R", repo, "--body", body])
    elif a["do"] == "rerun":
        run(["run", "rerun", str(a["run"]), "--failed", "-R", repo])
    elif a["do"] == "enqueue":
        # `gh api graphql` reads the operation from the `query` field (a
        # mutation too) — a `mutation` field is no field at all and the
        # whole call refuses with "A query attribute must be specified".
        run(["api", "graphql", "-f",
             f'query=mutation{{enqueuePullRequest(input:{{pullRequestId:"{a["node"]}"}}){{clientMutationId}}}}'])
    elif a["do"] == "enqueue-auto":
        run(["pr", "merge", str(a["pr"]), "-R", repo, "--auto", "--squash"])
    elif a["do"] == "dequeue":
        run(["api", "graphql", "-f",
             f'query=mutation{{dequeuePullRequest(input:{{id:"{a["node"]}"}}){{clientMutationId}}}}'])
    elif a["do"] == "ready":
        run(["pr", "ready", str(a["pr"]), "-R", repo])
    elif a["do"] in ("hold", "note"):
        pass  # a decision, not a mutation: the log says what the cap held or
              # what state the PR was already named in.
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
            "mergeStateStatus": "CLEAN", "title": "", "headRefName": f"lane/{n}"}
    if concl is not None:
        base["test"] = {"conclusion": concl, "runId": 900 + n, "attempt": 1,
                        "job": "gate", "line": "gate_changed: idioms refused packages/cli"}
    base.update(kw)
    return base


def _empty_state():
    return {RERUN: {}, TOLD: {}}


SELFTEST = [
    # (a) a failed PR is told its exact job — line and rerun once.
    ("failed-pr-reruns-once", dict(prs=[_pr(1, "FAILURE")], queue=[], trains=[],
                              state=_empty_state()),
     [("comment", 1), ("rerun", 901)]),
    # the same head a second time: named as already told, never rerun twice.
    ("rerun-not-twice",
     dict(prs=[_pr(1, "FAILURE", test={"conclusion": "FAILURE", "runId": 901,
                                       "attempt": 2, "job": "gate", "line": "x"})],
          queue=[], trains=[],
          state={RERUN: {"rerun:1:h1": True}, TOLD: {"told:1:h1": True}}),
     [("note", 1)]),
    # (b) a green mergeable PR is enqueued (auto-merge armed when unset).
    ("green-enqueues", dict(prs=[_pr(2, "SUCCESS")], queue=[], trains=[], state=_empty_state()),
     [("enqueue-auto", 2)]),
    ("green-already-auto",
     dict(prs=[_pr(2, "SUCCESS", autoMerge=True)], queue=[], trains=[], state=_empty_state()),
     [("enqueue", 2)]),
    # a green PR already in the queue: named, left to its own train.
    ("green-in-queue",
     dict(prs=[_pr(2, "SUCCESS", inQueue=True)], queue=[], trains=[], state=_empty_state()),
     [("note", 2)]),
    # (b) THE CAP: a queue at the cap enqueues NOTHING and names what it held.
    ("queue-at-cap-holds",
     dict(prs=[_pr(7, "SUCCESS")],
          queue=[{"pr": 4, "nodeId": "N4", "stuck": False},
                 {"pr": 5, "nodeId": "N5", "stuck": False},
                 {"pr": 6, "nodeId": "N6", "stuck": False},
                 {"pr": 8, "nodeId": "N8", "stuck": False},
                 {"pr": 9, "nodeId": "N9", "stuck": False},
                 {"pr": 10, "nodeId": "N10", "stuck": False}],
          trains=[], state=_empty_state()),
     [("hold", 7)]),
    # a queue below the cap enqueues.
    ("room-below-cap-enqueues",
     dict(prs=[_pr(7, "SUCCESS")],
          queue=[{"pr": 4, "nodeId": "N4", "stuck": False},
                 {"pr": 5, "nodeId": "N5", "stuck": False},
                 {"pr": 6, "nodeId": "N6", "stuck": False},
                 {"pr": 8, "nodeId": "N8", "stuck": False},
                 {"pr": 9, "nodeId": "N9", "stuck": False}],
          trains=[], state=_empty_state()),
     [("enqueue-auto", 7)]),
    # the cap spends its room in list order and holds only the excess.
    ("cap-holds-the-excess",
     dict(prs=[_pr(7, "SUCCESS"), _pr(8, "SUCCESS")],
          queue=[{"pr": 4, "nodeId": "N4", "stuck": False},
                 {"pr": 5, "nodeId": "N5", "stuck": False},
                 {"pr": 6, "nodeId": "N6", "stuck": False},
                 {"pr": 9, "nodeId": "N9", "stuck": False},
                 {"pr": 10, "nodeId": "N10", "stuck": False}],
          trains=[], state=_empty_state()),
     [("enqueue-auto", 7), ("hold", 8)]),
    # a running entry is never dequeued even beside a stuck one.
    ("running-entry-untouched",
     dict(prs=[], queue=[{"pr": 7, "nodeId": "N7", "stuck": False},
                         {"pr": 8, "nodeId": "N8", "stuck": True}],
          trains=[], state=_empty_state()),
     [("dequeue", 8), ("enqueue", 8)]),
    # (f) a conflict is NAMED once, with the rebase its owner owes.
    ("conflict-named",
     dict(prs=[_pr(3, "SUCCESS", mergeable="CONFLICTING", headRefName="lane/x")],
          queue=[], trains=[], state=_empty_state()),
     [("comment", 3)]),
    # (e) a green, otherwise-landable DRAFT is NAMED and taken ready.
    ("draft-green-readied",
     dict(prs=[_pr(3, "SUCCESS", isDraft=True)],
          queue=[], trains=[], state=_empty_state()),
     [("comment", 3), ("ready", 3)]),
    # a green DRAFT that is NOT otherwise landable is named, never readied.
    ("draft-blocked-named",
     dict(prs=[_pr(3, "SUCCESS", isDraft=True, mergeStateStatus="BLOCKED")],
          queue=[], trains=[], state=_empty_state()),
     [("comment", 3)]),
    # a DO NOT MERGE draft is the deliberate exception: named, never readied.
    ("draft-do-not-merge-named",
     dict(prs=[_pr(3, "SUCCESS", isDraft=True, title="DO NOT MERGE — timing proof")],
          queue=[], trains=[], state=_empty_state()),
     [("comment", 3)]),
    # a conflicting DRAFT is named twice — as a conflict and as a draft.
    ("draft-conflict-named",
     dict(prs=[_pr(3, "SUCCESS", isDraft=True, mergeable="CONFLICTING")],
          queue=[], trains=[], state=_empty_state()),
     [("comment", 3), ("comment", 3)]),
    # (g) a BLOCKED PR names the check it waits on, once.
    ("blocked-names-its-check",
     dict(prs=[_pr(4, None, mergeStateStatus="BLOCKED")],
          queue=[], trains=[], state=_empty_state()),
     [("comment", 4)]),
    ("pending-names-its-check",
     dict(prs=[_pr(5, "", mergeStateStatus="BLOCKED")],
          queue=[], trains=[], state=_empty_state()),
     [("comment", 5)]),
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
    if (not any(a["do"] == "comment" for a in first)
            or any(a["do"] == "comment" for a in second)
            or any(a["do"] == "rerun" for a in second)):
        sys.exit("pr-watcher: self-test — a failure was not told exactly once")

    # (5) DEDUP BY (PR, HEAD, REASON): a conflict, a draft and a blocked PR
    # are each commented ONCE for one head, and a second pass over an
    # unchanged head repeats nothing. This is the proof the state file is
    # keyed by reason, not merely by PR.
    for reason, pr in (("conflict", _pr(11, "SUCCESS", mergeable="CONFLICTING")),
                       ("draft", _pr(12, "SUCCESS", isDraft=True, mergeStateStatus="BLOCKED")),
                       ("blocked", _pr(13, None, mergeStateStatus="BLOCKED"))):
        st = _empty_state()
        pass1 = plan([pr], [], [], st)
        commit_marks(pass1, [], st)
        pass2 = plan([pr], [], [], st)
        comments1 = [a for a in pass1 if a["do"] == "comment"]
        if not comments1:
            sys.exit(f"pr-watcher: self-test — the {reason} state was never named")
        if any(a["do"] == "comment" for a in pass2):
            sys.exit(f"pr-watcher: self-test — the {reason} comment repeated on an unchanged head")

    # NEVER SILENT: every state a PR can be in draws an action or a name.
    for p in (_pr(21, "SUCCESS"),
              _pr(22, "SUCCESS", isDraft=True),
              _pr(23, "SUCCESS", mergeable="CONFLICTING"),
              _pr(24, None, mergeStateStatus="BLOCKED"),
              _pr(25, "FAILURE"),
              _pr(26, "SUCCESS", inQueue=True),
              _pr(27, "SUCCESS", isDraft=True, mergeable="CONFLICTING")):
        if not plan([p], [], [], _empty_state()):
            sys.exit(f"pr-watcher: self-test — PR #{p['number']} was silently skipped")

    # (f) THE CONFLICT WORDS ARE ONE DEFINITION: `tools/queue_keeper.sh`
    # speaks the same sentence, so the watcher and the keeper cannot drift.
    keeper = os.path.join(os.path.dirname(os.path.abspath(__file__)), "queue_keeper.sh")
    try:
        with open(keeper) as f:
            keeper_text = f.read()
    except OSError as e:
        sys.exit(f"pr-watcher: self-test — cannot read {keeper}: {e}")
    if CONFLICT_PHRASE not in keeper_text:
        sys.exit("pr-watcher: self-test — the conflict words drifted from queue_keeper.sh")
    # first_cause names a keeper refusal and a test mismatch.
    if "refused" not in first_cause("... keepers: gate refused ..."):
        sys.exit("pr-watcher: self-test — first_cause missed a keeper refusal")
    if "tests passed" not in first_cause("1/2 tests passed"):
        sys.exit("pr-watcher: self-test — first_cause missed a test mismatch")

    # (2) THE STUCK PREDICATE IS REAL, AND A LIVE TRAIN IS NEVER CHURNED: a
    # fresh entry, an entry whose train is running, and one whose run began
    # inside a whole train's duration are never stuck; only an entry with NO
    # run, or whose newest run began longer ago than a train takes, is.
    now = datetime(2026, 1, 1, 12, 0, 0, tzinfo=timezone.utc)
    branch = "gh-readonly-queue/main/pr-7-abc"
    running = {"headBranch": branch, "status": "in_progress",
               "createdAt": "2026-01-01T11:20:00Z"}
    fresh = {"headBranch": branch, "status": "completed", "conclusion": "cancelled",
             "createdAt": "2026-01-01T11:58:00Z"}
    aged = {"headBranch": branch, "status": "completed", "conclusion": "cancelled",
            "createdAt": "2026-01-01T11:00:00Z"}
    old_live = {"pr": 7, "enqueuedAt": "2026-01-01T11:00:00Z"}
    fresh_no_run = {"pr": 8, "enqueuedAt": "2026-01-01T11:59:30Z"}
    old_no_run = {"pr": 9, "enqueuedAt": "2026-01-01T11:00:00Z"}
    if _entry_stuck(old_live, [running], now):
        sys.exit("pr-watcher: self-test — an entry with a RUNNING train was churned")
    if _entry_stuck(fresh_no_run, [], now):
        sys.exit("pr-watcher: self-test — a fresh entry was called stuck")
    if _entry_stuck(old_live, [fresh], now):
        sys.exit("pr-watcher: self-test — a run from 5 minutes ago was churned")
    if not _entry_stuck(old_live, [aged], now):
        sys.exit("pr-watcher: self-test — an entry whose run began 60 minutes ago was not stuck")
    if not _entry_stuck(old_no_run, [], now):
        sys.exit("pr-watcher: self-test — an entry with no run for 60 minutes was not stuck")
    if plan([], [{"pr": 8, "nodeId": "N8", "stuck": False},
                 {"pr": 7, "nodeId": "N7", "stuck": False}], [], _empty_state()) != []:
        sys.exit("pr-watcher: self-test — a healthy queue produced actions")

    # THE CAP'S LOG NAMES THE LIMIT AND THE PR IT HELD, and the default is
    # six while AVRA_QUEUE_MAX moves it.
    held = plan([_pr(7, "SUCCESS")],
                [{"pr": 4, "nodeId": "N4", "stuck": False},
                 {"pr": 5, "nodeId": "N5", "stuck": False},
                 {"pr": 6, "nodeId": "N6", "stuck": False},
                 {"pr": 8, "nodeId": "N8", "stuck": False},
                 {"pr": 9, "nodeId": "N9", "stuck": False},
                 {"pr": 10, "nodeId": "N10", "stuck": False}],
                [], _empty_state())
    if [(a["do"], a["text"]) for a in held] != [("hold", "queue at 6 — holding #7")]:
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
            raise RuntimeError("SELF-TEST: Pull request Protected branch rules not configured")

    failed = execute(acts, "r", flaky)
    if len(failed) != 1:
        sys.exit("pr-watcher: self-test — a failed action stopped the pass")
    # A COMMENT'S OWN MARKER IS THE DEDUP: even with state lost, a body whose
    # key already stands on the PR is not posted again, and one that does not
    # is.
    posted = []

    def standing(args, _p=posted):
        if args[0] == "pr" and args[1] == "view":
            return "1"
        _p.append(args)
        return ""

    def absent(args, _p=posted):
        if args[0] == "pr" and args[1] == "view":
            return "0"
        _p.append(args)
        return ""

    act = {"do": "comment", "pr": 1, "key": "told:1:h1", "text": "BLOCKED"}
    do_action(act, "r", standing)
    if posted:
        sys.exit("pr-watcher: self-test — a comment with its marker already standing was re-posted")
    posted.clear()
    do_action(act, "r", absent)
    if len(posted) != 1:
        sys.exit("pr-watcher: self-test — a comment without its marker was not posted")

    # A CONFLICT ALSO YIELDS TO THE KEEPER'S WORDS: when a standing comment
    # carries `CONFLICT_PHRASE` (as `queue_keeper.sh`'s does) the watcher does
    # not add a second conflict comment, though it posts when the phrase is
    # absent.
    posted.clear()

    def phrase_stands(args, _p=posted):
        if args[0] == "pr" and args[1] == "view":
            return "1" if CONFLICT_PHRASE in " ".join(args) else "0"
        _p.append(args)
        return ""

    conflict_act = {"do": "comment", "pr": 1, "key": "conflict:1:h1",
                    "also": CONFLICT_PHRASE, "text": f"CONFLICT: {CONFLICT_PHRASE}."}
    do_action(conflict_act, "r", phrase_stands)
    if posted:
        sys.exit("pr-watcher: self-test — a conflict comment repeated over queue_keeper's")
    posted.clear()
    do_action({"do": "comment", "pr": 1, "key": "conflict:2:h2",
               "also": CONFLICT_PHRASE, "text": "CONFLICT elsewhere."}, "r", absent)
    if len(posted) != 1:
        sys.exit("pr-watcher: self-test — a conflict was not named when no phrase stood")
    st = _empty_state()
    d = tempfile.mkdtemp(prefix="pr-watcher-selftest-")
    p = os.path.join(d, "state.json")
    world = {"prs": [_pr(1, "FAILURE")], "queue": [],
             "trains": [{"pr": 5, "databaseId": 777, "job": "keepers-a", "line": "x"}]}
    run_pass(world, st, p, "r", execute_fn=lambda a, r: execute(a, r, flaky),
             label="pr-watcher:self-test:")
    saved = load_state(p)
    if saved["rerun"] or not saved["told"]:
        sys.exit("pr-watcher: self-test — state saved a failed mark or lost a succeeded one")


def queue_max():
    """The cap from the environment, or the default. A blank or unreadable
    value falls back rather than crashing a pass the whole landing waits on."""
    raw = (os.environ.get("AVRA_QUEUE_MAX") or "").strip()
    return int(raw) if raw.isdigit() and int(raw) > 0 else QUEUE_MAX


def run_pass(world, state, state_path, repo, execute_fn=execute, limit=QUEUE_MAX,
             label="pr-watcher:"):
    """One live pass. State is committed and SAVED in a `finally`:
    whatever an action or the pass itself does, the marks of what
    SUCCEEDED stand and the next pass retries only what failed."""
    acts = plan(world["prs"], world["queue"], world["trains"], state, limit)
    for a in acts:
        print(label, a["do"], a.get("pr", a.get("run", "")), a.get("text", ""))
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
        # EVERY open PR, one line, straight off the actions the pass owes —
        # so a state with no action reads as one instead of vanishing.
        by_pr = {}
        for a in acts:
            by_pr.setdefault(a.get("pr"), []).append(a["do"])
        for p in world["prs"]:
            mine = by_pr.get(p["number"], [])
            what = ",".join(sorted(set(mine))) if mine else "NO ACTION"
            print(f"pr-watcher: #{p['number']:<4} {(p.get('mergeStateStatus') or '?'):<8} "
                  f"draft={'Y' if p.get('isDraft') else 'n'} "
                  f"mergeable={(p.get('mergeable') or '?'):<11} -> {what}")
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
