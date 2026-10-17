#!/usr/bin/env python3
"""THE DETERMINISTIC WATCHER — no LLM, one pass every five minutes.

THERE IS NO MERGE QUEUE. `main`'s ruleset requires the `test` check AND
that a branch be up to date with `main` before merging, and every green PR
has auto-merge armed, so merges happen ONE AT A TIME, hands-off. The
watcher closes the gap between "green" and "landed", deterministically:

  (a) a PR whose required `test` FAILED — tell it the exact `job — line`,
      and re-run the failed jobs ONCE (a second rerun of the same head
      changes nothing, so it is refused by attempt, not by try-again);
  (b) the NEXT green, mergeable PR — ARM auto-merge (`gh pr merge
      --auto --squash`), which is the whole landing mechanism;
  (c) that same PR, when BEHIND `main` — REFRESH it (`gh pr update-branch`),
      so "up to date" is met without a human. The refresh is deduped per
      head: the update moves the head, so the next pass refreshes only if
      `main` moved again;
  (l) THE ORDER IS ONE PR AT A TIME, which is what "require up to date"
      already makes it: every merge puts every other PR BEHIND, so arming
      and refreshing them all re-ran every gate once per merge (N armed PRs
      cost N-1 wasted runs a landing). Only the FRONT PR is armed and
      refreshed: green, mergeable, not held, the `priority` label first,
      then the oldest number. While a PR is armed and awaiting its run (or
      armed and clean, about to land) nobody else is armed or refreshed —
      the rest are named `#N waits behind #F`. A PR's own run stays the
      gate. A `hold` label is respected like a DO NOT MERGE title: never
      armed, never refreshed, one already armed is disarmed;
  (d) a CONFLICT — name the rebase its owner owes, once;
  (e) a DRAFT — name it `#N is a DRAFT — unlandable` so it is never
      invisible. The watcher NEVER readies a draft: a draft is a hold, and
      a lane or the lead lands it with `sh tools/work land`;
  (j) A HELD TITLE — a non-draft PR whose title says DO NOT MERGE is never
      armed, and one already armed is disarmed. Either signal alone holds it;
  (k) A GREEN DRAFT held more than two hours is named — once, and once more
      each UTC day after — so a draft that is ready to land is never silent;
  (f) a DOOMED RUN — cancel a `pull_request` run whose PR is no longer
      open. A superseded run is already cancelled by `checks.yml`'s own
      concurrency; this covers the PR that closed while its run lived;
  (g) BLOCKED — name the check it waits on, once;
  (h) UNVALIDATED MAIN — a merge the GitHub Actions bot pushed fires no
      workflow (GITHUB_TOKEN pushes trigger none), so main's head can
      stand with no `checks` run at all. Once that head is older than
      MAIN_GRACE seconds with no `checks` run on it, dispatch `checks` on
      main — once per SHA, deduped by state;
  (i) A HELD RUN — a `checks` run the Actions bot's push left in
      `action_required` (a bot-pushed head fires a run that waits for an
      approver) on an open, same-repository PR's CURRENT head: approve it,
      once per run id. A fork's run is never approved here.

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
which failures and refreshes were told, which runs were cancelled) lives
in a small JSON file restored and saved by the workflow's cache:
`--state`.

WHEN THE QUEUE WAS DROPPED (2026-10-11): the queue's only real value was
testing the COMBINATION — `main` plus everything ahead — and "require
branches to be up to date before merging" gives that back for free, one
PR at a time. What the queue cost was trains that test eight PRs at once
(so one red suite kills all eight), HEADGREEN batching, and a rebase
treadmill where every landing re-conflicted everything behind it. The
enqueue path is kept below, corrected, for a repo that re-enables a
queue: a malformed mutation that failed silently is the bug this watcher
was born from.
"""
import datetime
import json
import os
import re
import subprocess
import sys
import tempfile

PR = "pull_request"
DEFAULT_REPO = "avra-lang/avra"
RERUN = "rerun"
TOLD = "told"
# A PR whose title says DO NOT MERGE is a deliberate draft: named, never
# readied. The phrase is a claim the owner wrote, not a state we infer.
DO_NOT_MERGE = re.compile(r"DO\s+NOT\s+MERGE", re.IGNORECASE)
# THE ORDER'S TWO LABELS: `hold` keeps a PR out of the landing order entirely (never armed,
# never refreshed, disarmed if armed), `priority` puts it first in line.
HOLD_LABEL = "hold"
PRIORITY_LABEL = "priority"
# THE CONFLICT WORDS ARE ONE DEFINITION, spoken here and quoted by the
# docs; the self-test refuses the two drifting apart.
# A green draft is named once it has been green this long, and again each day.
HELD_GREEN_S = 2 * 3600
# A bot merge's head gets a grace before the watcher asks for its run: a
# push run that is merely slow to appear is not a missing run.
MAIN_GRACE = 180
CONFLICT_PHRASE = ("this conflicts with main. Rebase onto origin/main, then "
                   "`sh tools/work land`")


# ---- the decision (pure; this is what the fixtures prove) --------------
def _when(stamp):
    """An ISO-8601 UTC stamp as an aware datetime, or None when unread."""
    if not stamp or stamp.startswith("0001-"):
        return None
    return datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00"))


def _waiting_on(p):
    """What a non-conflicting, non-draft, non-failing PR is waiting on.

    A missing `test` names itself; a pending one names its state; a green
    one whose merge state is not CLEAN or BEHIND names that. BEHIND is
    rule (c)'s to refresh, never a block. None means the PR is simply not
    required yet (a state a fixture may leave unmodelled).
    """
    t = p.get("test")
    if t is None:
        return "the required `test` check (not run yet)"
    c = (t.get("conclusion") or "").upper()
    if c == "SUCCESS":
        mss = (p.get("mergeStateStatus") or "CLEAN").upper()
        return None if mss in ("CLEAN", "BEHIND") else f"the merge state ({mss})"
    if c == "FAILURE":
        return None  # rule (a) owns it
    return f"the required `test` check ({c.lower() or 'pending'})"


def _labels(p):
    return {str(x).lower() for x in p.get("labels") or []}


def _held(p):
    """A PR held out of the landing order: a DO NOT MERGE title or the `hold` label."""
    return bool(DO_NOT_MERGE.search(p.get("title") or "")) or HOLD_LABEL in _labels(p)


def _is_green(p):
    t = p.get("test")
    return t is not None and t["conclusion"] == "SUCCESS"


def _landing(p):
    """A PR that is armed and either awaiting its run or clean, about to land: the one PR in
    the order that nothing else may disturb by moving `main` or its own head."""
    if p["state"] != "OPEN" or p.get("isDraft") or _held(p) or not p["autoMerge"]:
        return False
    if p.get("mergeable") == "CONFLICTING":
        return False
    t = p.get("test")
    if t is not None and t["conclusion"] == "FAILURE":
        return False
    if not _is_green(p):
        return True
    return (p.get("mergeStateStatus") or "CLEAN").upper() == "CLEAN"


def next_in_order(prs):
    """The one PR to arm and refresh now, or None: nobody while one is landing, else the
    `priority` PRs first, then the oldest, among the green, mergeable, un-held."""
    if any(_landing(p) for p in prs):
        return None
    ready = [p for p in prs if p["state"] == "OPEN" and not p.get("isDraft") and not _held(p)
             and _is_green(p) and p.get("mergeable") == "MERGEABLE"]
    ready.sort(key=lambda p: (0 if PRIORITY_LABEL in _labels(p) else 1, p["number"]))
    return ready[0] if ready else None


def _ahead(prs, front):
    """Who a waiting PR is behind, in words: the front, or the PR that is landing."""
    if front is not None:
        return f"#{front['number']} (next in order)"
    landing = [p["number"] for p in prs if _landing(p)]
    return f"#{landing[0]} (landing)" if landing else "the order"


def plan(prs, runs, state, trunk=None, held=None, now=None):
    """The actions a pass owes. See the module docstring for the rules.

    `prs`: number, isDraft, state, mergeable, mergeStateStatus, title,
           headRefName, autoMerge, headRefOid,
           test = None | {conclusion, runId, attempt, job, line}
    `runs`: databaseId, status, event, headBranch — the live `checks`
            runs, already filtered to the ones no PR is waiting on
    `state`: {"rerun": {key}, "told": {key}}
    `held`: the `checks` runs in `action_required`, unapproved
    `trunk`: None, or {sha, age, checked} — main's head SHA, its age in
            seconds, and whether any `checks` run stands on that SHA
    """
    acts = []
    rerun, told = state["rerun"], state["told"]
    now = now or datetime.datetime.now(datetime.timezone.utc)

    # (f) a run whose PR is no longer open is DOOMED: it can prove nothing
    # and only the runner pool pays for it. `checks.yml` cancels a
    # superseded run by its own concurrency; this covers the closed PR. A
    # run whose branch cannot be read is never cancelled — a verdict about
    # an unnamed thing is not one to act on.
    open_branches = {p.get("headRefName") for p in prs if p.get("headRefName")}
    for r in runs:
        if (r.get("event") or "") != PR:
            continue
        if (r.get("status") or "") not in ("in_progress", "queued"):
            continue
        branch = r.get("headBranch")
        if not branch or branch in open_branches:
            continue
        key = f"cancel:{r['databaseId']}"
        if key in told:
            continue
        acts.append({"do": "cancel", "run": r["databaseId"], "key": key,
                     "mark": ("told", key),
                     "text": f"cancelling run {r['databaseId']} on "
                             f"{branch} — its PR is no longer open"})

    front = next_in_order(prs)
    for p in prs:
        n, head = p["number"], p["headRefOid"]
        t = p.get("test")
        failed = t is not None and t["conclusion"] == "FAILURE"
        conflicted = p.get("mergeable") == "CONFLICTING"
        draft = bool(p.get("isDraft"))
        green = t is not None and t["conclusion"] == "SUCCESS"
        open_ = p["state"] == "OPEN"
        mergeable = p.get("mergeable") == "MERGEABLE"
        # `mergeStateStatus` is CLEAN only when every requirement — checks,
        # reviews, no conflict, up to date — is met; BEHIND is the one
        # requirement the watcher can clear itself.
        mss = (p.get("mergeStateStatus") or "CLEAN").upper()
        landable = mergeable and mss == "CLEAN"
        behind = mergeable and mss == "BEHIND"

        # (a) a failing check is the cause behind every other state: name the
        # job — line, and rerun the failed jobs once.
        if failed:
            want_rerun = (t.get("attempt", 1) == 1 and f"rerun:{n}:{head}" not in rerun
                          and not p.get("test_live"))
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

        # (d) a conflict is named, so its owner is told rather than guessing.
        if conflicted:
            key = f"conflict:{n}:{head}"
            if key in told:
                acts.append({"do": "note", "pr": n,
                             "text": f"#{n} still conflicts with main (told)"})
            else:
                acts.append({"do": "comment", "pr": n, "key": key, "mark": ("told", key),
                             "text": f"CONFLICT: {CONFLICT_PHRASE} — "
                                     f"`git rebase --onto origin/main main "
                                     f"{p.get('headRefName') or '<branch>'}`."})

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
            since = _when(t.get("greenSince")) if (t and green) else None
            if since and open_ and (now - since).total_seconds() > HELD_GREEN_S:
                day = now.date().isoformat()
                key = f"held-green:{n}:{day}"
                hours = int((now - since).total_seconds() // 3600)
                if key not in told:
                    acts.append({"do": "comment", "pr": n, "key": key, "mark": ("told", key),
                                 "text": f"#{n} green and held for {hours}h — "
                                         f"`sh tools/work land` lands it, or close it"})

        # (j) A HELD TITLE is a hold: a non-draft PR whose title says DO NOT
        # MERGE is never armed, and one that is armed is disarmed. Either
        # signal alone holds it; the workflow refuses to arm it too.
        if _held(p) and not draft:
            why = ("its title says DO NOT MERGE" if DO_NOT_MERGE.search(p.get("title") or "")
                   else f"it carries the `{HOLD_LABEL}` label")
            acts.append({"do": "note", "pr": n, "text": f"#{n} is HELD — {why}"})
            key = f"disarm:{n}:{head}"
            if p["autoMerge"] and key not in told:
                acts.append({"do": "disarm", "pr": n, "key": key, "mark": ("told", key),
                             "text": f"#{n} is held — disarming auto-merge"})
            continue

        # A failed, conflicting or draft PR is fully named above and cannot
        # merge yet.
        if failed or conflicted or draft:
            continue

        # (b)+(c) a green, mergeable PR is armed; once armed, one that is
        # behind is refreshed so "up to date" is met without a human.
        if green and mergeable and open_ and (front is None or front["number"] != n):
            # NOT THE FRONT: armed or refreshed now it would only be BEHIND again, and its
            # gate re-run, the moment the front lands.
            if p["autoMerge"] and landable:
                acts.append({"do": "note", "pr": n,
                             "text": f"#{n} is green and armed — auto-merge lands it"})
            else:
                acts.append({"do": "note", "pr": n,
                             "text": f"#{n} waits behind {_ahead(prs, front)}"})
            continue
        if green and mergeable and open_:
            if not p["autoMerge"]:
                acts.append({"do": "arm", "pr": n,
                             "text": f"#{n} is green — arming auto-merge"})
            if behind:
                key = f"refresh:{n}:{head}"
                if key in told:
                    acts.append({"do": "note", "pr": n,
                                 "text": f"#{n} is behind main (refresh asked)"})
                else:
                    acts.append({"do": "refresh", "pr": n, "key": key,
                                 "mark": ("told", key),
                                 "text": f"#{n} is behind main — updating the branch"})
            elif landable:
                if p["autoMerge"]:
                    acts.append({"do": "note", "pr": n,
                                 "text": f"#{n} is green and armed — auto-merge lands it"})
            else:
                acts.append({"do": "note", "pr": n,
                             "text": f"#{n} is green but the merge state is {mss}"})
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

    # (i) a held `checks` run on a same-repo PR's current head: approve it.
    heads = {p.get("headRefName"): p for p in prs
             if p.get("headRefName") and not p.get("isCrossRepository")}
    for r in held or []:
        p = heads.get(r.get("headBranch"))
        if not p or r.get("headSha") != p.get("headRefOid"):
            continue
        key = f"approve:{r['databaseId']}"
        if key in told:
            continue
        acts.append({"do": "approve", "run": r["databaseId"], "key": key,
                     "mark": ("told", key),
                     "text": f"approving held checks run {r['databaseId']} on "
                             f"#{p['number']} ({r['headBranch']})"})

    # (h) main with no `checks` run on its head: dispatch it, once per SHA.
    if trunk and not trunk["checked"] and trunk["age"] > MAIN_GRACE:
        key = f"dispatch:{trunk['sha']}"
        if key not in told:
            acts.append({"do": "dispatch", "key": key, "mark": ("told", key),
                         "text": f"main {trunk['sha'][:7]} has no `checks` run — dispatching one"})
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
                               "headRefOid,statusCheckRollup,isCrossRepository,createdAt,labels"])


def _runs(repo):
    return _gh_json(["run", "list", "-R", repo, "-L", "100",
                     "--json", "databaseId,status,conclusion,headBranch,event,"
                               "headSha,workflowName"])


def main_state(repo, runs):
    """main's head SHA, its age in seconds, and whether a `checks` run
    stands on it (any event: a push run is the usual one)."""
    head = _gh_json(["api", f"repos/{repo}/commits/main"])
    sha = head["sha"]
    when = head["commit"]["committer"]["date"]
    born = datetime.datetime.fromisoformat(when.replace("Z", "+00:00"))
    age = (datetime.datetime.now(datetime.timezone.utc) - born).total_seconds()
    checked = any(r.get("headSha") == sha and r.get("workflowName") == "checks"
                  for r in runs)
    return {"sha": sha, "age": age, "checked": checked}


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
                "job": "test", "line": "(the failed job was not read)",
                "greenSince": c.get("completedAt") if (concl or "").upper() == "SUCCESS" else None}
        if info["conclusion"] == "FAILURE" and run_id:
            attempt = _gh(["api", f"repos/{repo}/actions/runs/{run_id}",
                           "--jq", ".run_attempt"], check=False).strip()
            info["attempt"] = int(attempt) if attempt.isdigit() else 1
        return info
    return None


# A pass runs every five minutes, so it must not read a log it already told.
# State gates the expensive fetches, and the whole pass is capped so a bad
# afternoon of failures can never turn the watcher itself into the outage.
DETAIL_CAP = 6


def collect(repo, state):
    told = state[TOLD]
    prs = []
    for raw in open_prs(repo):
        p = dict(raw)
        p["autoMerge"] = raw.get("autoMergeRequest") is not None
        p["nodeId"] = raw.get("id")
        p["labels"] = [l.get("name", "") for l in raw.get("labels") or []]
        p["test"] = test_of(repo, raw)
        # A `test` run still pending is a run live on this PR: a rerun now would
        # cancel it, the group being one per event.
        p["test_live"] = any(c.get("status", "COMPLETED") != "COMPLETED"
                             for c in raw.get("statusCheckRollup") or []
                             if (c.get("name") or c.get("context")) == "test")
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
    every = _runs(repo)
    runs = [r for r in every
            if (r.get("event") or "") == PR
            and (r.get("status") or "") in ("in_progress", "queued")]
    held = [r for r in every
            if (r.get("event") or "") == PR
            and (r.get("workflowName") or "") == "checks"
            and (r.get("conclusion") or "") == "action_required"]
    return {"prs": prs, "runs": runs, "held": held, "main": main_state(repo, every)}


# ---- doing the actions (gh) --------------------------------------------
def do_action(a, repo, run):
    if a["do"] == "comment":
        body, key = a["text"], a.get("key")
        if key:
            # THE COMMENT CARRIES ITS OWN DEDUP KEY, so a lost state file
            # cannot re-post it and a second watcher cannot double it. An
            # unreadable answer refuses nothing, so a query that fails does
            # not silence the comment.
            needle = f"<!-- pr-watcher:{key} -->"
            seen = run(["pr", "view", str(a["pr"]), "-R", repo, "--json", "comments",
                        "--jq",
                        "[.comments[].body | select(contains(" +
                        json.dumps(needle) + "))] | length"])
            if (seen or "").strip() not in ("", "0"):
                return
            body += f"\n\n<!-- pr-watcher:{key} -->"
        run(["pr", "comment", str(a["pr"]), "-R", repo, "--body", body])
    elif a["do"] == "rerun":
        run(["run", "rerun", str(a["run"]), "--failed", "-R", repo])
    elif a["do"] == "arm":
        run(["pr", "merge", str(a["pr"]), "-R", repo, "--auto", "--squash"])
    elif a["do"] == "refresh":
        run(["pr", "update-branch", str(a["pr"]), "-R", repo])
    elif a["do"] == "cancel":
        run(["run", "cancel", str(a["run"]), "-R", repo])
    elif a["do"] == "disarm":
        run(["pr", "merge", str(a["pr"]), "-R", repo, "--disable-auto"])
    elif a["do"] == "approve":
        run(["api", "-X", "POST", f"repos/{repo}/actions/runs/{a['run']}/approve"])
    elif a["do"] == "dispatch":
        run(["workflow", "run", "checks.yml", "-R", repo, "--ref", "main"])
    elif a["do"] == "enqueue":
        # THE QUEUE IS OFF; this spelling is kept, corrected, for a repo that
        # re-enables one. `gh api graphql` reads the operation from the
        # `query` field (a mutation too) — a `mutation` field is no field at
        # all and the whole call refuses with "A query attribute must be
        # specified and must be a string", SILENTLY from a pass's point of
        # view. The self-test renders this and refuses the malformed form.
        run(["api", "graphql", "-f",
             f'query=mutation{{enqueuePullRequest(input:{{pullRequestId:"{a["node"]}"}}){{clientMutationId}}}}'])
    elif a["do"] == "dequeue":
        run(["api", "graphql", "-f",
             f'query=mutation{{dequeuePullRequest(input:{{id:"{a["node"]}"}}){{clientMutationId}}}}'])
    elif a["do"] == "note":
        pass  # a decision, not a mutation: the log says what state it named.
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
            "autoMerge": False, "headRefOid": f"h{n}", "mergeStateStatus": "CLEAN",
            "title": "", "headRefName": f"lane/{n}"}
    if concl is not None:
        base["test"] = {"conclusion": concl, "runId": 900 + n, "attempt": 1,
                        "job": "gate", "line": "gate_changed: idioms refused packages/cli"}
    base.update(kw)
    return base


def _run(n, **kw):
    base = {"databaseId": n, "status": "in_progress", "event": PR,
            "headBranch": f"lane/gone-{n}"}
    base.update(kw)
    return base


def _empty_state():
    return {RERUN: {}, TOLD: {}}


SELFTEST = [
    # (a) a failed PR is told its exact job — line and rerun once.
    ("failed-pr-reruns-once",
     dict(prs=[_pr(1, "FAILURE")], runs=[], state=_empty_state()),
     [("comment", 1), ("rerun", 901)]),
    # a failed run with another test run live on the PR is told, never rerun: the
    # rerun would cancel the live one.
    ("failed-with-live-run-not-rerun",
     dict(prs=[_pr(3, "FAILURE", test_live=True)], runs=[], state=_empty_state()),
     [("comment", 3)]),
    # the same head a second time: named as already told, never rerun twice.
    ("rerun-not-twice",
     dict(prs=[_pr(1, "FAILURE", test={"conclusion": "FAILURE", "runId": 901,
                                       "attempt": 2, "job": "gate", "line": "x"})],
          runs=[], state={RERUN: {"rerun:1:h1": True}, TOLD: {"told:1:h1": True}}),
     [("note", 1)]),
    # (b) a green mergeable PR is armed (the landing mechanism).
    ("green-unarmed-arms",
     dict(prs=[_pr(2, "SUCCESS")], runs=[], state=_empty_state()),
     [("arm", 2)]),
    # a green PR already armed and up to date is named, not re-armed.
    ("green-armed-ready-notes",
     dict(prs=[_pr(2, "SUCCESS", autoMerge=True)], runs=[], state=_empty_state()),
     [("note", 2)]),
    # (c) a green, armed PR behind main is refreshed.
    ("green-armed-behind-refreshes",
     dict(prs=[_pr(2, "SUCCESS", autoMerge=True, mergeStateStatus="BEHIND")],
          runs=[], state=_empty_state()),
     [("refresh", 2)]),
    # a green, unarmed PR behind main is armed AND refreshed in one pass.
    ("green-unarmed-behind-arms-and-refreshes",
     dict(prs=[_pr(2, "SUCCESS", mergeStateStatus="BEHIND")],
          runs=[], state=_empty_state()),
     [("arm", 2), ("refresh", 2)]),
    # the refresh is deduped per head: a second pass over the same head only
    # notes it.
    ("refresh-not-twice",
     dict(prs=[_pr(2, "SUCCESS", autoMerge=True, mergeStateStatus="BEHIND")],
          runs=[], state={RERUN: {}, TOLD: {"refresh:2:h2": True}}),
     [("note", 2)]),
    # (l) ONE PR AT A TIME: of three green PRs behind main only the OLDEST is armed and
    # refreshed; the others wait, named, so a merge re-runs one gate, not three.
    ("order-front-is-oldest",
     dict(prs=[_pr(5, "SUCCESS", mergeStateStatus="BEHIND"),
               _pr(2, "SUCCESS", mergeStateStatus="BEHIND"),
               _pr(9, "SUCCESS", mergeStateStatus="BEHIND")],
          runs=[], state=_empty_state()),
     [("note", 5), ("arm", 2), ("refresh", 2), ("note", 9)]),
    # a `priority` PR goes first whatever its number.
    ("order-priority-first",
     dict(prs=[_pr(2, "SUCCESS", mergeStateStatus="BEHIND"),
               _pr(9, "SUCCESS", mergeStateStatus="BEHIND", labels=["priority"])],
          runs=[], state=_empty_state()),
     [("note", 2), ("arm", 9), ("refresh", 9)]),
    # a `hold` PR is never armed or refreshed, and the order passes over it.
    ("order-hold-skipped",
     dict(prs=[_pr(2, "SUCCESS", mergeStateStatus="BEHIND", labels=["hold"]),
               _pr(3, "SUCCESS", mergeStateStatus="BEHIND")],
          runs=[], state=_empty_state()),
     [("note", 2), ("arm", 3), ("refresh", 3)]),
    # a `hold` PR that is already armed is disarmed.
    ("order-hold-disarms",
     dict(prs=[_pr(2, "SUCCESS", autoMerge=True, labels=["hold"])],
          runs=[], state=_empty_state()),
     [("note", 2), ("disarm", 2)]),
    # a PR armed and awaiting its run is the one in flight: nobody else is armed or refreshed.
    ("order-inflight-blocks-others",
     dict(prs=[_pr(2, "", autoMerge=True, mergeStateStatus="BLOCKED"),
               _pr(3, "SUCCESS", mergeStateStatus="BEHIND")],
          runs=[], state=_empty_state()),
     [("comment", 2), ("note", 3)]),
    # an armed, clean PR is about to land: the PR behind main waits for it.
    ("order-landing-blocks-others",
     dict(prs=[_pr(2, "SUCCESS", autoMerge=True),
               _pr(3, "SUCCESS", mergeStateStatus="BEHIND")],
          runs=[], state=_empty_state()),
     [("note", 2), ("note", 3)]),
    # (d) a conflict is NAMED once, with the rebase its owner owes.
    ("conflict-named",
     dict(prs=[_pr(3, "SUCCESS", mergeable="CONFLICTING", headRefName="lane/x")],
          runs=[], state=_empty_state()),
     [("comment", 3)]),
    # (e) a green DRAFT is NAMED and never readied: a draft is a hold.
    ("draft-green-named-never-readied",
     dict(prs=[_pr(3, "SUCCESS", isDraft=True)], runs=[], state=_empty_state()),
     [("comment", 3)]),
    # a green DRAFT that is NOT otherwise landable is named, never readied.
    ("draft-blocked-named",
     dict(prs=[_pr(3, "SUCCESS", isDraft=True, mergeStateStatus="BLOCKED")],
          runs=[], state=_empty_state()),
     [("comment", 3)]),
    # a DO NOT MERGE draft is the deliberate exception: named, never readied.
    ("draft-do-not-merge-named",
     dict(prs=[_pr(3, "SUCCESS", isDraft=True, title="DO NOT MERGE — timing proof")],
          runs=[], state=_empty_state()),
     [("comment", 3)]),
    # a conflicting DRAFT is named twice — as a conflict and as a draft.
    ("draft-conflict-named",
     dict(prs=[_pr(3, "SUCCESS", isDraft=True, mergeable="CONFLICTING")],
          runs=[], state=_empty_state()),
     [("comment", 3), ("comment", 3)]),
    # (g) a BLOCKED PR names the check it waits on, once.
    ("blocked-names-its-check",
     dict(prs=[_pr(4, None, mergeStateStatus="BLOCKED")], runs=[], state=_empty_state()),
     [("comment", 4)]),
    # a green, armed PR in a merge state that is neither CLEAN nor BEHIND (a
    # state that should not occur here) is still NAMED, never silently skipped.
    ("green-armed-blocked-named",
     dict(prs=[_pr(6, "SUCCESS", autoMerge=True, mergeStateStatus="BLOCKED")],
          runs=[], state=_empty_state()),
     [("note", 6)]),
    ("pending-names-its-check",
     dict(prs=[_pr(5, "", mergeStateStatus="BLOCKED")], runs=[], state=_empty_state()),
     [("comment", 5)]),
    # (f) a run whose PR is no longer open is cancelled once.
    ("doomed-run-cancelled",
     dict(prs=[], runs=[_run(55)], state=_empty_state()),
     [("cancel", 55)]),
    ("cancelled-run-not-recancelled",
     dict(prs=[], runs=[_run(55)],
          state={RERUN: {}, TOLD: {"cancel:55": True}}),
     []),
]


def selftest():
    for name, world, want in SELFTEST:
        acts = plan(world["prs"], world["runs"], world["state"])
        got = [(a["do"], a.get("pr", a.get("run"))) for a in acts]
        if got != want:
            sys.exit(f"pr-watcher: self-test failed on `{name}`: got {got}, want {want}")
    # THE TREADMILL: five green PRs all behind main cost ONE refresh a pass, never five.
    five = [_pr(n, "SUCCESS", mergeStateStatus="BEHIND", autoMerge=True) for n in (4, 6, 7, 8, 9)]
    refreshed = [a["pr"] for a in plan(five, [], _empty_state()) if a["do"] == "refresh"]
    if refreshed != [4]:
        sys.exit(f"pr-watcher: self-test — five armed PRs behind main refreshed {refreshed}, want [4]")
    # and once the front merges, the next in order is the one refreshed.
    refreshed = [a["pr"] for a in plan(five[1:], [], _empty_state()) if a["do"] == "refresh"]
    if refreshed != [6]:
        sys.exit(f"pr-watcher: self-test — after the front merged {refreshed} was refreshed, want [6]")
    # a failed PR told once, not every pass.
    st = _empty_state()
    first = plan([_pr(1, "FAILURE")], [], st)
    commit_marks(first, [], st)
    second = plan([_pr(1, "FAILURE", test={"conclusion": "FAILURE", "runId": 901,
                                           "attempt": 2, "job": "gate", "line": "x"})],
                  [], st)
    if (not any(a["do"] == "comment" for a in first)
            or any(a["do"] == "comment" for a in second)
            or any(a["do"] == "rerun" for a in second)):
        sys.exit("pr-watcher: self-test — a failure was not told exactly once")

    # DEDUP BY (PR, HEAD, REASON): a conflict, a draft and a blocked PR
    # are each commented ONCE for one head, and a second pass over an
    # unchanged head repeats nothing. This is the proof the state file is
    # keyed by reason, not merely by PR.
    for reason, pr in (("conflict", _pr(11, "SUCCESS", mergeable="CONFLICTING")),
                       ("draft", _pr(12, "SUCCESS", isDraft=True, mergeStateStatus="BLOCKED")),
                       ("blocked", _pr(13, None, mergeStateStatus="BLOCKED"))):
        st = _empty_state()
        pass1 = plan([pr], [], st)
        commit_marks(pass1, [], st)
        pass2 = plan([pr], [], st)
        if not [a for a in pass1 if a["do"] == "comment"]:
            sys.exit(f"pr-watcher: self-test — the {reason} state was never named")
        if any(a["do"] == "comment" for a in pass2):
            sys.exit(f"pr-watcher: self-test — the {reason} comment repeated on an unchanged head")

    # (h) an unvalidated main is dispatched once per SHA, never twice, and
    # a main that has a checks run, or is inside the grace, is left alone.
    def trunk(age, checked, sha="m1"):
        return {"sha": sha, "age": age, "checked": checked}
    if plan([], [], _empty_state(), trunk(600, True)):
        sys.exit("pr-watcher: self-test — main with a checks run was dispatched")
    if plan([], [], _empty_state(), trunk(60, False)):
        sys.exit("pr-watcher: self-test — main inside the grace was dispatched")
    st = _empty_state()
    first = plan([], [], st, trunk(600, False))
    if [a["do"] for a in first] != ["dispatch"]:
        sys.exit(f"pr-watcher: self-test — an unvalidated main was not dispatched: {first}")
    commit_marks(first, [], st)
    if plan([], [], st, trunk(600, False)):
        sys.exit("pr-watcher: self-test — main was dispatched twice for one SHA")
    if [a["do"] for a in plan([], [], st, trunk(600, False, sha="m2"))] != ["dispatch"]:
        sys.exit("pr-watcher: self-test — a new main SHA was not dispatched")
    sent = []
    execute(first, "avra-lang/avra", run=lambda args: sent.append(args) or "")
    if sent != [["workflow", "run", "checks.yml", "-R", "avra-lang/avra", "--ref", "main"]]:
        sys.exit(f"pr-watcher: self-test — the dispatch was sent as {sent}")

    # (i) a held checks run on a same-repo current head is approved once per
    # run id; a fork's, a stale head's and an approved one's are left alone.
    def pr_on(branch, sha, fork=False):
        return {"number": 90, "state": "OPEN", "isDraft": False, "mergeable": "MERGEABLE",
                "mergeStateStatus": "CLEAN", "autoMerge": False, "title": "",
                "headRefName": branch, "headRefOid": sha, "isCrossRepository": fork,
                "test": None}
    def held_run(rid, branch, sha):
        return {"databaseId": rid, "headBranch": branch, "headSha": sha,
                "event": PR, "workflowName": "checks", "conclusion": "action_required"}
    st = _empty_state()
    owed = plan([pr_on("lane/x", "s1")], [], st, None, [held_run(7, "lane/x", "s1")])
    if [(a["do"], a.get("run")) for a in owed if a["do"] == "approve"] != [("approve", 7)]:
        sys.exit(f"pr-watcher: self-test — a held run on a current head was not approved: {owed}")
    commit_marks(owed, [], st)
    if any(a["do"] == "approve" for a in
           plan([pr_on("lane/x", "s1")], [], st, None, [held_run(7, "lane/x", "s1")])):
        sys.exit("pr-watcher: self-test — a held run was approved twice")
    if any(a["do"] == "approve" for a in plan([pr_on("lane/x", "s2")], [], _empty_state(), None, [held_run(8, "lane/x", "s1")])):
        sys.exit("pr-watcher: self-test — a run on a superseded head was approved")
    if any(a["do"] == "approve" for a in plan([pr_on("fork/x", "s1", fork=True)], [], _empty_state(), None,
            [held_run(9, "fork/x", "s1")])):
        sys.exit("pr-watcher: self-test — a fork's held run was approved")
    sent = []
    execute([a for a in owed if a["do"] == "approve"], "avra-lang/avra",
            run=lambda args: sent.append(args) or "")
    if sent != [["api", "-X", "POST", "repos/avra-lang/avra/actions/runs/7/approve"]]:
        sys.exit(f"pr-watcher: self-test — the approval was sent as {sent}")

    # (k) a green DRAFT held more than two hours is named — once, then once
    # more on each UTC day — and a draft is never readied on the way.
    now = datetime.datetime(2026, 10, 12, 12, 0, tzinfo=datetime.timezone.utc)

    def green_draft(n, hours_green, title=""):
        since = now - datetime.timedelta(hours=hours_green)
        p = _pr(n, "SUCCESS", isDraft=True, title=title)
        p["test"]["greenSince"] = since.strftime("%Y-%m-%dT%H:%M:%SZ")
        return p

    def held_named(acts):
        return [a for a in acts if a["do"] == "comment" and "held for" in a.get("text", "")]

    if held_named(plan([green_draft(31, 1)], [], _empty_state(), now=now)):
        sys.exit("pr-watcher: self-test — a draft green for an hour was named as held")
    st = _empty_state()
    first = plan([green_draft(31, 3)], [], st, now=now)
    if len(held_named(first)) != 1:
        sys.exit(f"pr-watcher: self-test — a draft green 3h was not named once: {first}")
    commit_marks(first, [], st)
    if held_named(plan([green_draft(31, 3)], [], st, now=now)):
        sys.exit("pr-watcher: self-test — a held draft was named twice the same day")
    tomorrow = now + datetime.timedelta(days=1)
    if len(held_named(plan([green_draft(31, 27)], [], st, now=tomorrow))) != 1:
        sys.exit("pr-watcher: self-test — a held draft was not named again the next day")
    if any(a["do"] == "ready" for a in plan([green_draft(31, 3)], [], _empty_state(), now=now)):
        sys.exit("pr-watcher: self-test — a green draft was readied")

    # (j) a held title is a hold: a non-draft PR is never armed, and an armed
    # one is disarmed once per head, with the exact argv.
    held_pr = _pr(5, "SUCCESS", title="DO NOT MERGE — timing proof")
    if any(a["do"] == "arm" for a in plan([held_pr], [], _empty_state(), now=now)):
        sys.exit("pr-watcher: self-test — a held PR was armed")
    armed = _pr(5, "SUCCESS", autoMerge=True, title="DO NOT MERGE: wait")
    st = _empty_state()
    owed = plan([armed], [], st, now=now)
    if [a["do"] for a in owed if a["do"] == "disarm"] != ["disarm"]:
        sys.exit(f"pr-watcher: self-test — an armed held PR was not disarmed: {owed}")
    commit_marks(owed, [], st)
    if any(a["do"] == "disarm" for a in plan([armed], [], st, now=now)):
        sys.exit("pr-watcher: self-test — a held PR was disarmed twice for one head")
    sent = []
    execute([a for a in owed if a["do"] == "disarm"], "avra-lang/avra",
            run=lambda args: sent.append(args) or "")
    if sent != [["pr", "merge", "5", "-R", "avra-lang/avra", "--disable-auto"]]:
        sys.exit(f"pr-watcher: self-test — the disarm was sent as {sent}")

    # NEVER SILENT: every state a PR can be in draws an action or a name.
    for p in (_pr(21, "SUCCESS"),
              _pr(22, "SUCCESS", isDraft=True),
              _pr(23, "SUCCESS", mergeable="CONFLICTING"),
              _pr(24, None, mergeStateStatus="BLOCKED"),
              _pr(25, "FAILURE"),
              _pr(26, "SUCCESS", mergeStateStatus="BEHIND"),
              _pr(27, "SUCCESS", isDraft=True, mergeable="CONFLICTING")):
        if not plan([p], [], _empty_state()):
            sys.exit(f"pr-watcher: self-test — PR #{p['number']} was silently skipped")

    # (f) A LIVE RUN IS NEVER CANCELLED, AND ONLY A `pull_request` RUN IS A
    # CANDIDATE: a run a still-open PR names is WORKING; a push run and a
    # completed run are never touched however stale they look.
    open_pr = _pr(31, "SUCCESS", autoMerge=True, headRefName="lane/live")
    if [a["do"] for a in plan([open_pr], [_run(1, headBranch="lane/live")],
                              _empty_state())] != ["note"]:
        sys.exit("pr-watcher: self-test — a run an open PR names was cancelled")
    live = [_run(2, headBranch="lane/elsewhere")]
    if plan([], [dict(live[0], event="push")], _empty_state()):
        sys.exit("pr-watcher: self-test — a push run was treated as doomed")
    if plan([], [dict(live[0], status="completed")], _empty_state()):
        sys.exit("pr-watcher: self-test — a completed run was treated as doomed")
    if plan([], [dict(live[0], headBranch=None)], _empty_state()):
        sys.exit("pr-watcher: self-test — a run with no branch was cancelled")
    # first_cause names a keeper refusal and a test mismatch.
    if "refused" not in first_cause("... keepers: gate refused ..."):
        sys.exit("pr-watcher: self-test — first_cause missed a keeper refusal")
    if "tests passed" not in first_cause("1/2 tests passed"):
        sys.exit("pr-watcher: self-test — first_cause missed a test mismatch")

    # (1)+(3) ONE FAILING ACTION MUST NOT ABORT THE PASS, AND STATE IS SAVED
    # WITH ONLY THE SUCCEEDED MARKS: the failed action is retried next pass.
    acts = plan([_pr(1, "FAILURE")], [], _empty_state())
    calls = []

    def flaky(args, _calls=calls):
        _calls.append(args)
        if args[0] == "run" and args[1] == "rerun":
            raise RuntimeError("SELF-TEST: Pull request Protected branch rules not configured")

    failed = execute(acts, "r", flaky)
    if len(failed) != 1:
        sys.exit("pr-watcher: self-test — a failed action stopped the pass")

    # THE ENQUEUE MUTATION IS WELL-FORMED even though no queue is on: gh
    # reads the operation from the `query` field, and a bare `mutation`
    # field has no query attribute at all.
    rendered = []

    def render(args, _r=rendered):
        _r.append(args)

    do_action({"do": "enqueue", "pr": 1, "node": "N1"}, "r", render)
    do_action({"do": "dequeue", "pr": 1, "node": "N1"}, "r", render)
    if not rendered or not all(
            any(str(x).startswith("query=mutation") for x in c) for c in rendered):
        sys.exit(f"pr-watcher: self-test — a queue mutation is malformed: {rendered}")

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

    st = _empty_state()
    d = tempfile.mkdtemp(prefix="pr-watcher-selftest-")
    p = os.path.join(d, "state.json")
    world = {"prs": [_pr(1, "FAILURE")],
             "runs": [_run(55)]}
    run_pass(world, st, p, "r", execute_fn=lambda a, r: execute(a, r, flaky),
             label="pr-watcher:self-test:")
    saved = load_state(p)
    if saved["rerun"] or not saved["told"]:
        sys.exit("pr-watcher: self-test — state saved a failed mark or lost a succeeded one")


def run_pass(world, state, state_path, repo, execute_fn=execute, label="pr-watcher:"):
    """One live pass. State is committed and SAVED in a `finally`:
    whatever an action or the pass itself does, the marks of what
    SUCCEEDED stand and the next pass retries only what failed."""
    acts = plan(world["prs"], world["runs"], state, world.get("main"), world.get("held"))
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
    if "--dry-run" in argv:
        acts = plan(world["prs"], world["runs"], state, world.get("main"), world.get("held"))
        armed = sum(1 for a in acts if a["do"] == "arm")
        refreshed = sum(1 for a in acts if a["do"] == "refresh")
        cancelled = sum(1 for a in acts if a["do"] == "cancel")
        for a in acts:
            print("pr-watcher:", a["do"], a.get("pr", a.get("run", "")), a.get("text", ""))
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
        print(f"pr-watcher: dry run — no queue: {armed} arm(s), {refreshed} refresh(es), "
              f"{cancelled} cancel(s) — not taken, state untouched")
        return 0
    acts = run_pass(world, state, state_path, repo)
    print(f"pr-watcher: {len(world['prs'])} open PR(s), {len(world['runs'])} doomed run(s) "
          f"— {len(acts)} action(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
