#!/usr/bin/env python3
"""THE PR'S RUN MODE, read from the PR as the API answers it at run time.

    curl <the PR's API JSON> | pr_mode.py

Prints `light` for a draft without the `full-ci` label, `full` otherwise. An
empty or unreadable answer is `full`, so a run whose PR state did not come back
runs the whole gate.

    pr_mode.py --self-test
"""
import json
import sys


def mode(text):
    if not text.strip():
        return "full"
    pr = json.loads(text)
    labels = [label["name"] for label in pr.get("labels", [])]
    return "light" if pr.get("draft") and "full-ci" not in labels else "full"


def self_test():
    cases = [
        ('{"draft": true, "labels": []}', "light"),
        ('{"draft": true, "labels": [{"name": "full-ci"}]}', "full"),
        ('{"draft": false, "labels": []}', "full"),
        ('{"draft": false, "labels": [{"name": "full-ci"}]}', "full"),
        ("", "full"),
        ("   \n", "full"),
    ]
    bad = [(t, want) for t, want in cases if mode(t) != want]
    for t, want in bad:
        print("pr_mode: FAILED — %r should be %s" % (t, want))
    if bad:
        return 1
    print("pr_mode: self-test clean — %d case(s)" % len(cases))
    return 0


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    print(mode(sys.stdin.read()))
