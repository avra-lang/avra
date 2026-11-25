#!/usr/bin/env python3
# tool-witness: --self-test
"""THE ONE-LINE BLOCKER: why nothing is landing, in a handful of lines.

Many different causes read as one symptom — "nothing lands" — and each
took real time to find, one at a time. This prints the current one
without being asked twice:

  - `main`'s SHA and when it last moved;
  - the last runs' failures, COUNTED BY JOB (`keepers-a failed 9 of the
    last 15 runs`), which is the single most useful line that existed
    all night and nobody was printing;
  - each open PR's blocker in one word;
  - whether the local watchdog driver is loaded AND has run in the last
    five minutes — a paused driver must be the loudest line, because it
    was silently off for hours;
  - a one-line VERDICT naming the single most likely blocker.

There is NO merge queue: `main` requires the `test` check and that a
branch be up to date, and auto-merge lands a green, current PR by itself.
So the pipeline is the open PRs, the runs that prove them and the
watcher that keeps them moving.

It is READ-ONLY: it reads GitHub through the collectors `pr_watcher.py`
already has and writes nothing. `verdict` is a pure function over a
state, proved against synthetic fixtures with no network and no LLM
(`--self-test`), so the diagnosis is the same answer every run.

It must not lie: a signal it cannot read prints `unknown` and is skipped
by the verdict, never given a plausible default.

WAITING ON A HUMAN/LEAD is the section for what the watcher will never move
by itself: a green draft (it is a hold, and only a landing takes it), a
red non-draft PR, a PR BEHIND main, and a PR nobody has pushed to. A green
draft older than six hours fails the report (exit status 1), so a heartbeat
can alarm on it. The cap line says how many PRs are open and how old the
oldest is, so a pile-up is visible at a glance.
"""
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pr_watcher

REPO_DEFAULT = pr_watcher.DEFAULT_REPO
RUN_WINDOW = 15
DRIVER_LABEL = "lang.avra.watchdog"
DRIVER_LOG = os.path.expanduser("~/.avra-pr-watcher/watchdog.log")
DRIVER_FRESH_S = 300
FAIL_CONCLUSIONS = ("failure", "timed_out", "startup_failure", "action_required")
RUNNING_STATUS = ("in_progress", "running")
QUEUED_STATUS = ("queued", "requested", "waiting", "pending")
# THE WAITING THRESHOLDS: how long a state may stand before a human or the
# lead is told. A green draft past WAIT_GREEN_DRAFT_EXIT_S fails the report.
WAIT_RED_S = 2 * 3600
WAIT_BEHIND_S = 3600
WAIT_IDLE_S = 24 * 3600
WAIT_GREEN_DRAFT_EXIT_S = 6 * 3600


# ---- the decision (pure; this is what the fixtures prove) --------------
def verdict(s):
    """The one line that names the most likely reason nothing is landing.

    Signals it cannot read (None) are skipped, never guessed at. Order is
    by how directly a signal blocks a landing: a dead driver sweeps
    nothing, a red gate drops every PR that rides it, and an all-conflict
    tree has nothing landable.
    """
    prs = s.get("prs")
    runs = s.get("runs") or {}
    counts = runs.get("counts") or {}
    failed = runs.get("failed_jobs") or {}
    driver = s.get("driver") or {}
    window = runs.get("window") or RUN_WINDOW

    if prs and driver.get("loaded") is False:
        return (f"the local watchdog driver is NOT loaded ({DRIVER_LABEL} absent "
                f"from launchctl) — GitHub's cron is best-effort, so nothing sweeps")
    if prs and driver.get("loaded") is True and driver.get("fresh") is False:
        return (f"the local watchdog driver is loaded but has NOT run in "
                f"{human_age(driver.get('age_s'))} — GitHub's cron is best-effort, "
                f"so nothing is sweeping PRs")

    if failed:
        top_job, top_n = sorted(failed.items(), key=lambda kv: (-kv[1], kv[0]))[0]
        return (f"{top_job} failed {top_n} of the last {window} runs "
                f"({counts.get('failed', top_n)} failed) — that gate is red; "
                f"nothing behind it lands")
    if runs.get("unread"):
        return (f"{runs['unread']} run(s) failed but the failing job could not "
                f"be read (unknown) — open the run's log")

    if prs:
        words = [p["blocker"] for p in prs]
        if words and all(w == "conflict" for w in words):
            return (f"every open PR is in conflict with main ({len(prs)}) — "
                    f"rebase onto origin/main")
        if words and all(w == "draft" for w in words):
            return (f"every open PR is a draft ({len(prs)}) — mark one "
                    f"ready_for_review to land it")

    if counts.get("running"):
        return (f"{counts['running']} run(s) running, {counts.get('queued', 0)} queued — "
                f"the pipeline is moving; wait for it")
    if counts.get("queued"):
        return (f"{counts['queued']} run(s) queued and none running — the runner "
                f"pool may be saturated; wait for a runner")

    if prs:
        unarmed = [p["number"] for p in prs if p["blocker"] == "unarmed"]
        if unarmed:
            nums = " ".join(f"#{n}" for n in sorted(unarmed))
            return (f"{len(unarmed)} PR(s) are unarmed (green but not armed): {nums} — "
                    f"auto-merge is unset and the watcher has not picked them up")

    if prs is not None and not prs:
        return "nothing to land — no open PRs"
    if prs is None:
        return "cannot determine — the open PRs could not be read (unknown)"
    return "no single blocker found — see the per-PR table above"


def blocker_of(pr, job=None):
    """One word for what stops this PR landing.

    `draft`/`conflict`/`failed:<job>`/`stale`/`unarmed`/`ready` are the
    named blockers; `pending` is checks not finished and `unknown` is a
    state none of them describes. A failure whose job could not be read
    is `failed:unknown`, never a guessed name.
    """
    if pr.get("isDraft"):
        return "draft"
    if pr.get("mergeable") == "CONFLICTING" or pr.get("mergeStateStatus") == "DIRTY":
        return "conflict"
    check = _test_check(pr)
    if check is None:
        return "pending"
    concl = (check.get("conclusion") or "").upper()
    status = (check.get("status") or "").upper()
    if concl in ("FAILURE", "TIMED_OUT", "STARTUP_FAILURE", "ACTION_REQUIRED", "CANCELLED"):
        return f"failed:{job}" if job else "failed:unknown"
    if concl == "SUCCESS":
        if pr.get("mergeStateStatus") == "BEHIND":
            return "stale"
        return "ready" if pr.get("autoMerge") else "unarmed"
    if status in ("IN_PROGRESS", "QUEUED", "PENDING", "WAITING", "REQUESTED") \
            or concl in ("", "NEUTRAL", "SKIPPED"):
        return "pending"
    return "unknown"


# ---- reading the world (gh) --------------------------------------------
def _safe(fn, *args):
    """A collector that cannot be read answers None, never a default."""
    try:
        return fn(*args)
    except Exception:
        return None


def main_head(repo):
    c = pr_watcher._gh_json(["api", f"repos/{repo}/commits/main"])
    return {"sha": c["sha"], "date": c["commit"]["committer"]["date"]}


def run_failed_jobs(repo, run_id):
    """The real jobs a run failed, excluding the aggregate `test` when a
    concrete job failed — `test` fails whenever anything does."""
    jobs = pr_watcher._gh_json(["run", "view", str(run_id), "-R", repo,
                                "--json", "jobs"]).get("jobs", [])
    bad = [j["name"] for j in jobs if (j.get("conclusion") or "") in FAIL_CONCLUSIONS]
    real = [n for n in bad if n != "test"]
    return real or bad


def _test_check(pr):
    for c in pr.get("statusCheckRollup") or []:
        if (c.get("name") or c.get("context")) == "test":
            return c
    return None


def _run_id(check):
    url = check.get("detailsUrl") or check.get("targetUrl") or ""
    m = re.search(r"/runs/(\d+)", url)
    return int(m.group(1)) if m else None


def driver_state():
    """The local launchd driver: loaded, and when it last ran.

    `loaded` is None where launchctl cannot be read (not macOS, absent);
    `fresh`/`age_s` are None where the log cannot be read. None is a
    question unanswered, never a healthy default.
    """
    loaded = None
    try:
        out = subprocess.run(["launchctl", "list"], capture_output=True,
                             text=True, timeout=10).stdout
        loaded = any(DRIVER_LABEL in line for line in out.splitlines())
    except Exception:
        loaded = None
    age = None
    try:
        age = int(time.time() - os.path.getmtime(DRIVER_LOG))
    except OSError:
        age = None
    return {"loaded": loaded, "fresh": None if age is None else age <= DRIVER_FRESH_S,
            "age_s": age, "log": DRIVER_LOG}


def collect_state(repo):
    with ThreadPoolExecutor(max_workers=4) as ex:
        f_main = ex.submit(_safe, main_head, repo)
        f_runs = ex.submit(_safe, pr_watcher._runs, repo)
        f_prs = ex.submit(_safe, pr_watcher.open_prs, repo)
        main, runs, prs = f_main.result(), f_runs.result(), f_prs.result()

    if prs is not None:
        for p in prs:
            p["autoMerge"] = p.get("autoMergeRequest") is not None

    window = [r for r in (runs or []) if (r.get("event") or "") != "merge_group"][:RUN_WINDOW]
    counts = {"running": 0, "queued": 0, "failed": 0, "passed": 0, "other": 0}
    failed_runs = []
    for r in window:
        c = (r.get("conclusion") or "").lower()
        st = (r.get("status") or "").lower()
        if c == "failure":
            counts["failed"] += 1
            failed_runs.append(r)
        elif c == "success":
            counts["passed"] += 1
        elif st in RUNNING_STATUS:
            counts["running"] += 1
        elif st in QUEUED_STATUS:
            counts["queued"] += 1
        else:
            counts["other"] += 1

    pr_run = {}
    if prs is not None:
        for p in prs:
            check = _test_check(p)
            if check and (check.get("conclusion") or "").upper() == "FAILURE":
                pr_run[p["number"]] = _run_id(check)

    run_ids = {r["databaseId"] for r in failed_runs}
    run_ids |= {rid for rid in pr_run.values() if rid}
    job_cache = {}
    if run_ids:
        with ThreadPoolExecutor(max_workers=8) as ex:
            futs = {ex.submit(_safe, run_failed_jobs, repo, rid): rid for rid in run_ids}
            for f, rid in futs.items():
                job_cache[rid] = f.result()

    failed_jobs, unread = {}, 0
    for r in failed_runs:
        names = job_cache.get(r["databaseId"])
        if names is None:
            unread += 1
            continue
        for n in names:
            failed_jobs[n] = failed_jobs.get(n, 0) + 1

    prs_out = None
    if prs is not None:
        prs_out = []
        for p in prs:
            rid = pr_run.get(p["number"])
            names = job_cache.get(rid) if rid else None
            job = names[0] if names else None
            prs_out.append({"number": p["number"], "blocker": blocker_of(p, job)})

    now = datetime.now(timezone.utc)
    recs = None
    if prs is not None:
        with ThreadPoolExecutor(max_workers=8) as ex:
            pushed = [ex.submit(_safe, head_pushed, repo, p["headRefOid"]) for p in prs]
            recs = [_wait_record(p, job_cache.get(pr_run.get(p["number"])), f.result())
                    for p, f in zip(prs, pushed)]
    waiting_out = None
    if recs is not None:
        lines, alarm = waiting(recs, now, _when_main(main))
        waiting_out = {"lines": lines, "alarm": alarm, "cap": cap_line(recs, now),
                       "landing": landing_effects(recs)}
    return {"repo": repo, "now": now.isoformat(), "main": main,
            "runs": {"counts": counts, "window": len(window),
                     "failed_jobs": failed_jobs, "unread": unread},
            "prs": prs_out, "driver": driver_state(), "waiting": waiting_out}


def _when_main(main):
    return pr_watcher._when(main["date"]) if main and main.get("date") else None


# ---- waiting on a human or the lead (pure; proved by the fixtures) -----
def waiting(recs, now, main_date):
    """The lines for WAITING ON A HUMAN/LEAD, and whether a green draft is
    old enough to fail the report. `recs`: one record per open PR (see
    `_wait_record`); `now` and `main_date` are aware datetimes."""
    lines, alarm = [], False
    for r in recs:
        n, t = r["number"], r["test"]
        if r["isDraft"]:
            green = _secs_before(now, t["greenSince"]) if t["conclusion"] == "SUCCESS" else None
            if green is not None:
                lines.append(f"  #{n} green draft, green {human_age(green)}: {r['title']}")
                alarm = alarm or green > WAIT_GREEN_DRAFT_EXIT_S
            continue
        red = _secs_before(now, t["doneAt"]) if t["conclusion"] == "FAILURE" else None
        if red is not None and red > WAIT_RED_S:
            lines.append(f"  #{n} red for {human_age(red)} — failing: "
                         f"{', '.join(r['failing']) or 'unknown'}")
        behind = _secs_before(now, main_date) if r["mss"] == "BEHIND" else None
        if behind is not None and behind > WAIT_BEHIND_S:
            lines.append(f"  #{n} BEHIND main; main moved {human_age(behind)} ago")
        idle = _secs_before(now, r["lastPush"])
        if idle is not None and idle > WAIT_IDLE_S:
            lines.append(f"  #{n} no push for {human_age(idle)}")
    return lines, alarm


def cap_line(recs, now):
    """How many PRs are open, and how old the oldest one is."""
    opened = [t for t in (pr_watcher._when(r["createdAt"]) for r in recs) if t is not None]
    if not recs:
        return "cap      0 open PRs"
    if not opened:
        return f"cap      {len(recs)} open PRs; the oldest's age is unknown"
    old = min(opened)
    oldest = next(r["number"] for r in recs if pr_watcher._when(r["createdAt"]) == old)
    return f"cap      {len(recs)} open PRs; oldest #{oldest}, opened {human_age((now - old).total_seconds())} ago"


def head_pushed(repo, sha):
    """When a PR's head commit was committed — its last push, as far as
    the watcher can read it. None when gh cannot answer."""
    return pr_watcher._gh_json(["api", f"repos/{repo}/commits/{sha}",
                                "--jq", "{d: .commit.committer.date}"]).get("d")


def landing_effects(recs):
    """One line per open PR: what landing it NOW would restart. Landing moves
    `main`, so every other non-draft PR whose `test` check is still running
    goes BEHIND and restarts. A draft is not landable and says so."""
    lines = []
    for r in recs:
        n = r["number"]
        if r["isDraft"]:
            lines.append(f"  #{n} draft — not landable")
            continue
        others = [q["number"] for q in recs
                  if q["number"] != n and not q["isDraft"] and q["running"]]
        if others:
            lines.append(f"  #{n} lands now → restarts " + ", ".join(f"#{o}" for o in others)
                         + " (mid-CI)")
        else:
            lines.append(f"  #{n} lands now → restarts nothing")
    return lines


def _secs_before(now, stamp):
    """Seconds from `stamp` (an ISO string or a datetime) until `now`."""
    t = stamp if isinstance(stamp, datetime) else pr_watcher._when(stamp)
    return None if t is None else (now - t).total_seconds()


def _wait_record(p, names, pushed=None):
    check = _test_check(p) or {}
    concl = (check.get("conclusion") or "").upper()
    return {"number": p["number"], "title": p.get("title") or "",
            "isDraft": bool(p.get("isDraft")), "mss": (p.get("mergeStateStatus") or "").upper(),
            "test": {"conclusion": concl,
                     "greenSince": check.get("completedAt") if concl == "SUCCESS" else None,
                     "doneAt": check.get("completedAt")},
            "failing": names or [], "createdAt": p.get("createdAt"),
            "lastPush": pushed,
            "running": check.get("status") is not None
            and (check.get("status") or "").upper() != "COMPLETED"}


# ---- rendering ---------------------------------------------------------
def human_age(seconds):
    if seconds is None:
        return "unknown"
    seconds = int(seconds)
    if seconds < 90:
        return f"{seconds}s"
    minutes = seconds // 60
    if minutes < 90:
        return f"{minutes}m"
    hours = minutes // 60
    if hours < 48:
        return f"{hours}h"
    return f"{hours // 24}d"


def _age_since(now_iso, then_iso):
    try:
        now = datetime.fromisoformat(now_iso)
        then = datetime.fromisoformat((then_iso or "").replace("Z", "+00:00"))
        return human_age((now - then).total_seconds())
    except Exception:
        return "unknown"


def driver_line(driver):
    loaded, fresh, age = driver.get("loaded"), driver.get("fresh"), driver.get("age_s")
    if loaded is None:
        return "driver   unknown (launchctl could not be read)"
    if loaded is False:
        return f"driver   !!! NOT LOADED ({DRIVER_LABEL} is not a loaded launchd job)"
    if fresh is None:
        return f"driver   loaded, but last run unknown ({driver.get('log')} unreadable)"
    if fresh is False:
        return f"driver   !!! NOT RUNNING — last ran {human_age(age)} ago ({driver.get('log')})"
    return f"driver   loaded, last ran {human_age(age)} ago"


def render(s):
    lines = [f"PIPELINE {s.get('repo')}   {s.get('now')}"]
    main = s.get("main")
    if main:
        lines.append(f"main     {main['sha'][:8]}  moved {_age_since(s['now'], main['date'])} ago "
                     f"({main['date']})")
    else:
        lines.append("main     unknown (gh could not read the main commit)")

    runs = s.get("runs")
    if runs and runs.get("window"):
        c = runs["counts"]
        lines.append(f"runs     last {runs['window']}: {c['running']} running, {c['queued']} queued, "
                     f"{c['failed']} failed, {c['passed']} passed")
        if runs.get("failed_jobs"):
            ranked = sorted(runs["failed_jobs"].items(), key=lambda kv: (-kv[1], kv[0]))
            lines.append("         failing: " + ", ".join(f"{j} {n}" for j, n in ranked))
        elif c["failed"]:
            lines.append("         failing: unknown (the failing jobs could not be read)")
    else:
        lines.append("runs     unknown (gh could not read recent runs)")

    lines.append(driver_line(s.get("driver") or {}))

    prs = s.get("prs")
    if prs is None:
        lines.append("prs      unknown (gh could not read open PRs)")
    else:
        buckets = {}
        for p in prs:
            buckets.setdefault(p["blocker"], []).append(p["number"])
        ranked = sorted(buckets.items(), key=lambda kv: (-len(kv[1]), kv[0]))
        lines.append(f"prs      {len(prs)} open: "
                     + ", ".join(f"{b} {len(n)}" for b, n in ranked))
        for b, nums in ranked:
            lines.append(f"         {b}: " + " ".join(f"#{n}" for n in sorted(nums)))

    waiting_out = s.get("waiting")
    if waiting_out is None:
        lines.append("waiting  unknown (gh could not read open PRs)")
    else:
        lines.append("")
        lines.append("WAITING ON A HUMAN/LEAD")
        lines.extend(waiting_out["lines"] or ["  none"])
        lines.append(waiting_out["cap"])
        lines.append("")
        lines.append("LANDING NOW WOULD")
        lines.extend(waiting_out["landing"] or ["  no open PRs"])

    lines.append("")
    lines.append(f"VERDICT  {verdict(s)}")
    return lines


def main(argv):
    if "--self-test" in argv:
        return selftest()
    if "--witness" in argv:
        return witness()
    repo = os.environ.get("GH_REPO", REPO_DEFAULT)
    state = collect_state(repo)
    if "--json" in argv:
        print(json.dumps(state, indent=2, sort_keys=True, default=str))
        return 0
    print("\n".join(render(state)))
    return 1 if (state.get("waiting") or {}).get("alarm") else 0


# ---- the proof (no network, no LLM) ------------------------------------
def _cpr(**kw):
    base = {"number": 1, "isDraft": False, "mergeable": "MERGEABLE",
            "mergeStateStatus": "CLEAN", "autoMerge": False,
            "statusCheckRollup": []}
    base.update(kw)
    return base


def _check(concl="", status="COMPLETED"):
    return {"name": "test", "conclusion": concl, "status": status,
            "detailsUrl": "https://github.com/avra-lang/avra/actions/runs/123/job/1"}


BLOCKER_CASES = [
    ("draft", _cpr(isDraft=True), None, "draft"),
    ("conflict-by-mergeable", _cpr(mergeable="CONFLICTING"), None, "conflict"),
    ("conflict-by-dirty", _cpr(mergeStateStatus="DIRTY"), None, "conflict"),
    ("failed-names-job", _cpr(statusCheckRollup=[_check("FAILURE")]), "keepers-a", "failed:keepers-a"),
    ("failed-no-job-is-unknown", _cpr(statusCheckRollup=[_check("FAILURE")]), None, "failed:unknown"),
    ("stale", _cpr(mergeStateStatus="BEHIND", statusCheckRollup=[_check("SUCCESS")]), None, "stale"),
    ("unarmed", _cpr(statusCheckRollup=[_check("SUCCESS")]), None, "unarmed"),
    ("ready", _cpr(autoMerge=True, statusCheckRollup=[_check("SUCCESS")]), None, "ready"),
    ("pending-no-check", _cpr(), None, "pending"),
    ("pending-in-progress", _cpr(statusCheckRollup=[_check("", "IN_PROGRESS")]), None, "pending"),
    ("unknown-conclusion", _cpr(statusCheckRollup=[_check("EXPECTED")]), None, "unknown"),
]


def _wrec(n, draft=False, concl="", done=None, green=None, mss="CLEAN",
          pushed="2026-10-12T11:00:00Z", failing=(), title="t",
          created="2026-10-12T00:00:00Z"):
    return {"number": n, "title": title, "isDraft": draft, "mss": mss,
            "test": {"conclusion": concl, "greenSince": green, "doneAt": done},
            "failing": list(failing), "createdAt": created, "lastPush": pushed}


NOW = "2026-10-12T12:00:00+00:00"
# (name, records, now, main's date, lines wanted, alarm wanted)
WAITING_CASES = [
    ("green-draft-is-listed-with-its-age", [_wrec(1, draft=True, concl="SUCCESS",
        green="2026-10-12T11:00:00Z")], NOW, None, 1, False),
    ("green-draft-named-past-two-hours", [_wrec(1, draft=True, concl="SUCCESS",
        green="2026-10-12T09:00:00Z")], NOW, None, 1, False),
    ("green-draft-over-six-hours-alarms", [_wrec(1, draft=True, concl="SUCCESS",
        green="2026-10-12T05:00:00Z")], NOW, None, 1, True),
    ("red-under-two-hours-is-quiet", [_wrec(2, concl="FAILURE",
        done="2026-10-12T11:00:00Z", failing=["gate"])], NOW, None, 0, False),
    ("red-past-two-hours-names-the-job", [_wrec(2, concl="FAILURE",
        done="2026-10-12T09:00:00Z", failing=["gate", "keepers-a"])], NOW, None, 1, False),
    ("behind-under-an-hour-is-quiet", [_wrec(3, mss="BEHIND")], NOW,
        "2026-10-12T11:30:00+00:00", 0, False),
    ("behind-past-an-hour-is-named", [_wrec(3, mss="BEHIND")], NOW,
        "2026-10-12T10:30:00+00:00", 1, False),
    ("no-push-under-a-day-is-quiet", [_wrec(4, pushed="2026-10-11T13:00:00Z")], NOW, None, 0, False),
    ("no-push-over-a-day-is-named", [_wrec(4, pushed="2026-10-11T11:00:00Z")], NOW, None, 1, False),
    ("a-clean-open-pr-is-quiet", [_wrec(5, concl="SUCCESS", green="2026-10-12T11:59:00Z")],
        NOW, None, 0, False),
]


def _lrec(n, draft=False, running=False):
    return {"number": n, "isDraft": draft, "running": running}


LANDING_CASES = [
    ("nothing-in-flight", [_lrec(1), _lrec(2)],
     ["  #1 lands now → restarts nothing", "  #2 lands now → restarts nothing"]),
    ("a-mid-ci-pr-is-restarted", [_lrec(1), _lrec(2, running=True)],
     ["  #1 lands now → restarts #2 (mid-CI)", "  #2 lands now → restarts nothing"]),
    ("a-draft-is-named-not-counted", [_lrec(1), _lrec(3, draft=True, running=True)],
     ["  #1 lands now → restarts nothing", "  #3 draft — not landable"]),
    ("two-in-flight-are-both-named", [_lrec(1, running=True), _lrec(2, running=True), _lrec(3)],
     ["  #1 lands now → restarts #2 (mid-CI)", "  #2 lands now → restarts #1 (mid-CI)",
      "  #3 lands now → restarts #1, #2 (mid-CI)"]),
]


def _vstate(prs=(), failed_jobs=None, tfail=0, trun=0, tpass=0,
            tqueue=0, driver=None, window=RUN_WINDOW, unread=0):
    return {"repo": "r", "now": "2026-01-01T00:00:00+00:00", "main": None,
            "prs": None if prs is None else [{"number": n, "blocker": b} for n, b in prs],
            "driver": driver if driver is not None else {"loaded": True, "fresh": True, "age_s": 10},
            "runs": {"counts": {"running": trun, "queued": tqueue, "failed": tfail,
                                "passed": tpass, "other": 0},
                     "window": window, "failed_jobs": dict(failed_jobs or {}),
                     "unread": unread}}


VERDICT_CASES = [
    ("no-driver",
     _vstate(prs=[(1, "ready")], driver={"loaded": False, "fresh": None, "age_s": None}),
     ["driver", "NOT loaded"]),
    ("driver-stale",
     _vstate(prs=[(2, "ready")], driver={"loaded": True, "fresh": False, "age_s": 7200}),
     ["driver", "has NOT run"]),
    ("dominant-job",
     _vstate(prs=[(4, "ready")], failed_jobs={"keepers-a": 9}, tfail=9),
     ["keepers-a failed 9", "last 15 runs"]),
    ("all-conflict",
     _vstate(prs=[(5, "conflict"), (6, "conflict")]),
     ["conflict", "rebase"]),
    ("all-draft",
     _vstate(prs=[(7, "draft"), (8, "draft")]),
     ["draft"]),
    ("moving",
     _vstate(prs=[(9, "pending")], trun=2),
     ["running", "moving"]),
    ("queued-no-runner",
     _vstate(prs=[(9, "pending")], tqueue=4),
     ["queued", "runner"]),
    ("unarmed",
     _vstate(prs=[(10, "unarmed")]),
     ["unarmed", "auto-merge"]),
    ("unread-runs",
     _vstate(prs=[(11, "pending")], tfail=2, unread=2),
     ["could not be read"]),
    ("prs-unknown",
     _vstate(prs=None),
     ["unknown"]),
    ("nothing-to-land",
     _vstate(),
     ["nothing to land"]),
    ("fallback",
     _vstate(prs=[(12, "pending"), (13, "pending")]),
     ["no single blocker"]),
]


def witness():
    """Print each blocker and each verdict firing, so the branches are
    witnessed rather than only asserted."""
    for name, pr, job, _want in BLOCKER_CASES:
        print(f"blocker  {name:28s} -> {blocker_of(pr, job)}")
    for name, state, _wants in VERDICT_CASES:
        print(f"verdict  {name:28s} -> {verdict(state)}")
    return 0


def selftest():
    for name, pr, job, want in BLOCKER_CASES:
        got = blocker_of(pr, job)
        if got != want:
            sys.exit(f"pipeline-status: self-test — blocker `{name}`: got {got}, want {want}")
    for name, state, wants in VERDICT_CASES:
        got = verdict(state)
        missing = [w for w in wants if w not in got]
        if missing:
            sys.exit(f"pipeline-status: self-test — verdict `{name}`: {got!r} "
                     f"missing {missing}")
    # a signal that could not be read is skipped, never guessed at: a dead
    # driver with NO PRs does not become the verdict.
    if "driver" in verdict(_vstate(prs=[], driver={"loaded": False, "fresh": None, "age_s": None})):
        sys.exit("pipeline-status: self-test — a dead driver was blamed with no PRs to land")
    for name, recs, now_iso, main_iso, want_lines, want_alarm in WAITING_CASES:
        now = datetime.fromisoformat(now_iso)
        main_date = datetime.fromisoformat(main_iso) if main_iso else None
        lines, alarm = waiting(recs, now, main_date)
        if len(lines) != want_lines or alarm != want_alarm:
            sys.exit(f"pipeline-status: self-test — waiting `{name}`: got {lines} "
                     f"alarm={alarm}, want {want_lines} line(s) alarm={want_alarm}")
    if "oldest #7" not in cap_line(
            [_wait_record(_cpr(number=7, createdAt="2026-10-10T12:00:00Z"), None),
             _wait_record(_cpr(number=8, createdAt="2026-10-11T12:00:00Z"), None)],
            datetime.fromisoformat("2026-10-12T12:00:00+00:00")):
        sys.exit("pipeline-status: self-test — the cap line did not name the oldest PR")
    for name, recs, want in LANDING_CASES:
        got = landing_effects(recs)
        if got != want:
            sys.exit(f"pipeline-status: self-test — landing `{name}`: got {got}, want {want}")
    print(f"pipeline-status: self-test — {len(BLOCKER_CASES)} blocker case(s), "
          f"{len(VERDICT_CASES)} verdict scenario(s), {len(WAITING_CASES)} waiting "
          f"scenario(s) and {len(LANDING_CASES)} landing scenario(s) hold")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
