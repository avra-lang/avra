#!/usr/bin/env python3
"""The defects keeper's timings from the last green run of `checks` on main, fetched
into a file the keeper reads as `--previous`. Best effort: with no token, no run or no
artifact it writes nothing, and a timeout then says its last green seconds are not known.

    GH_TOKEN=... defects_previous.py --repo <owner/repo> --out build/defects-timings.prev.tsv
    defects_previous.py --self-test
"""
import io
import json
import os
import sys
import urllib.request
import zipfile

ARTIFACT = "defects-timings"
MEMBER = "defects-timings.tsv"


def newest_artifact(artifacts):
    """The newest unexpired artifact of that name, or None."""
    live = [a for a in artifacts if a.get("name") == ARTIFACT and not a.get("expired")]
    return max(live, key=lambda a: a["id"], default=None)


def get(url, token):
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read()


def main(argv):
    if "--self-test" in argv:
        return self_test()
    args = dict(zip(argv[::2], argv[1::2]))
    token = os.environ.get("GH_TOKEN", "")
    if not token:
        print("defects_previous: no token — no earlier timings")
        return 0
    try:
        base = "https://api.github.com/repos/%s" % args["--repo"]
        runs = json.loads(get(base + "/actions/workflows/checks.yml/runs?branch=main&status=success&per_page=1", token))["workflow_runs"]
        if not runs:
            print("defects_previous: no green run of checks on main")
            return 0
        found = newest_artifact(json.loads(get("%s/actions/runs/%d/artifacts" % (base, runs[0]["id"]), token))["artifacts"])
        if found is None:
            print("defects_previous: run %d left no %s" % (runs[0]["id"], ARTIFACT))
            return 0
        zf = zipfile.ZipFile(io.BytesIO(get("%s/actions/artifacts/%d/zip" % (base, found["id"]), token)))
        with open(args["--out"], "wb") as f:
            f.write(zf.read(MEMBER))
        print("defects_previous: timings of run %d in %s" % (runs[0]["id"], args["--out"]))
    except Exception as e:
        print("defects_previous: no earlier timings (%s)" % e)
    return 0


def self_test():
    cases = [
        ([], None),
        ([{"id": 1, "name": "avra-store"}], None),
        ([{"id": 4, "name": ARTIFACT, "expired": True}], None),
        ([{"id": 4, "name": ARTIFACT}, {"id": 9, "name": ARTIFACT}, {"id": 12, "name": "other"}], 9),
    ]
    bad = [(a, want) for a, want in cases if (lambda r: r and r["id"])(newest_artifact(a)) != want]
    for a, want in bad:
        print("defects_previous: FAILED — %r should pick %r" % (a, want))
    if bad:
        return 1
    print("defects_previous: self-test clean — %d case(s)" % len(cases))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
