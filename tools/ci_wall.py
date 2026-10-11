#!/usr/bin/env python3
"""THE WALL-CLOCK MEASUREMENT.

One PR check's wall time, per job and whole, read from the run's own jobs
as GitHub reports them — the clock the owner's budget is about, which no
step's own `date` arithmetic can see (a runner's queue, container init and
artifact hand-downs are all wall time).

    ci_wall.py collect                # the metrics for $GITHUB_RUN_ID on stdout
    ci_wall.py --api <base> --repo <o/r> --run <id> collect
    ci_wall.py --self-test            # the parse, against a local fake

The stream is the one `tools/speed_ratchet.py --wall` reads:

    host ci-wall
    wall prepare <ms>
    wall gate <ms>
    wall total <ms>

`total` is the run's start to now, so it is the whole check including the
queue and the aggregate job's own bookkeeping. A job the event skipped has
no clock and is left out; the ratchet judges what was measured.
"""
import datetime
import json
import os
import sys
import urllib.request

HOST = "ci-wall"


def _api(base, path):
    h = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "avra-ci-wall",
    }
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if token:
        h["Authorization"] = f"Bearer {token}"
    return urllib.request.urlopen(urllib.request.Request(base + path, headers=h), timeout=60)


def _stamp(text):
    """An ISO-8601 instant from the API, or None."""
    if not text:
        return None
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    return datetime.datetime.fromisoformat(text)


def _ms(start, end):
    return int((end - start).total_seconds() * 1000)


def measure(base, run_id, now=None):
    """The metrics stream, from the run and its jobs. `now` is the instant
    the whole-check total is read to, defaulting to this moment — the job
    reading it is itself nearly done."""
    now = now or datetime.datetime.now(datetime.timezone.utc)
    with _api(base, f"/actions/runs/{run_id}") as r:
        run = json.load(r)
    with _api(base, f"/actions/runs/{run_id}/jobs?per_page=100") as r:
        jobs = json.load(r)["jobs"]
    lines = ["host %s" % HOST]
    ends = []
    running = False
    for job in jobs:
        start = _stamp(job.get("started_at"))
        end = _stamp(job.get("completed_at"))
        if end is None:
            running = True
        else:
            ends.append(end)
        # A skipped job carries a clock that did not run (end <= start); it
        # was not measured and the ratchet judges only what was.
        if start is None or start >= (end or now):
            continue
        lines.append("wall %s %d" % (job["name"], _ms(start, end or now)))
    begun = _stamp(run.get("run_started_at")) or _stamp(run.get("created_at"))
    if begun is not None:
        # The whole check ends when its last job does; while one is still
        # running (the aggregate reading this) the end is now.
        last = now if running else max(ends)
        lines.append("wall total %d" % _ms(begun, last))
    return "\n".join(lines) + "\n"


def _self_test():
    import http.server
    import threading

    state = {
        "run": {"run_started_at": "2026-01-01T00:00:00Z", "created_at": "2026-01-01T00:00:00Z"},
        "jobs": [
            {"name": "prepare", "started_at": "2026-01-01T00:00:05Z", "completed_at": "2026-01-01T00:01:05Z"},
            {"name": "gate", "started_at": "2026-01-01T00:01:10Z", "completed_at": "2026-01-01T00:02:40Z"},
            {"name": "skipped", "started_at": None, "completed_at": None},
        ],
    }

    class Fake(http.server.BaseHTTPRequestHandler):
        def log_message(self, *a):
            pass

        def do_GET(self):
            body = None
            if self.path.startswith("/repos/o/r/actions/runs/1/jobs"):
                body = {"jobs": state["jobs"]}
            elif self.path.startswith("/repos/o/r/actions/runs/1"):
                body = state["run"]
            if body is None:
                self.send_response(404)
                self.end_headers()
                return
            blob = json.dumps(body).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(blob)))
            self.end_headers()
            self.wfile.write(blob)

    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Fake)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base = f"http://127.0.0.1:{server.server_address[1]}/repos/o/r"
    now = datetime.datetime(2026, 1, 1, 0, 3, 0, tzinfo=datetime.timezone.utc)
    try:
        out = measure(base, 1, now=now)
    finally:
        server.shutdown()
    rows = {}
    for line in out.splitlines():
        parts = line.split()
        if parts[0] == "wall" and len(parts) == 3:
            rows[parts[1]] = int(parts[2])
    want = {"prepare": 60000, "gate": 90000, "total": 180000}
    if rows != want:
        print(f"ci_wall: SELF-TEST FAILED — read {rows}, want {want}", file=sys.stderr)
        return 1
    if "skipped" in rows:
        print("ci_wall: SELF-TEST FAILED — a skipped job was measured", file=sys.stderr)
        return 1
    print("ci_wall: self-test clean")
    return 0


def main(argv):
    if "--self-test" in argv:
        return _self_test()
    base = os.environ.get("AVRA_WALL_API", "")
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    i = 0
    while i < len(argv):
        if argv[i] == "--api":
            base = argv[i + 1]
            i += 2
        elif argv[i] == "--repo":
            repo = argv[i + 1]
            i += 2
        elif argv[i] == "--run":
            run_id = argv[i + 1]
            i += 2
        elif argv[i] == "collect":
            i += 1
        else:
            print(f"ci_wall: unknown argument {argv[i]}", file=sys.stderr)
            return 2
    if not repo or not run_id:
        print("ci_wall: collect needs GITHUB_REPOSITORY and GITHUB_RUN_ID (or --repo/--run)", file=sys.stderr)
        return 1
    if not base:
        base = f"https://api.github.com/repos/{repo}"
    sys.stdout.write(measure(base, run_id))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
