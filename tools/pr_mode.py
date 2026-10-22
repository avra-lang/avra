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


def label_event(action, label):
    """What a label event owes: `ignore` for any label but `full-ci` (the run only restates the head's
    standing verdict), `dedupe` for `full-ci` added (it never doubles a gate another run gives),
    `plain` for everything else, `unlabeled` full-ci included: it replans from the label as it stands."""
    if action not in ("labeled", "unlabeled"):
        return "plain"
    if label != "full-ci":
        return "ignore"
    return "dedupe" if action == "labeled" else "plain"


def self_test():
    cases = [
        ('{"draft": true, "labels": []}', "light"),
        ('{"draft": true, "labels": [{"name": "full-ci"}]}', "full"),
        ('{"draft": false, "labels": []}', "full"),
        ('{"draft": false, "labels": [{"name": "full-ci"}]}', "full"),
        ("", "full"),
        ("   \n", "full"),
    ]
    label_cases = [
        (("opened", ""), "plain"), (("synchronize", ""), "plain"), (("ready_for_review", ""), "plain"),
        (("labeled", "full-ci"), "dedupe"), (("unlabeled", "full-ci"), "plain"),
        (("labeled", "bug"), "ignore"), (("unlabeled", "bug"), "ignore"), (("labeled", ""), "ignore"),
    ]
    bad_labels = [(args, want) for args, want in label_cases if label_event(*args) != want]
    for args, want in bad_labels:
        print("pr_mode: FAILED — label event %r should be %s" % (args, want))
    if bad_labels:
        return 1
    bad = [(t, want) for t, want in cases if mode(t) != want]
    for t, want in bad:
        print("pr_mode: FAILED — %r should be %s" % (t, want))
    if bad:
        return 1
    print("pr_mode: self-test clean — %d case(s)" % (len(cases) + len(label_cases)))
    return 0


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    if "--label-event" in sys.argv:
        i = sys.argv.index("--label-event")
        print(label_event(sys.argv[i + 1], sys.argv[i + 2] if len(sys.argv) > i + 2 else ""))
        sys.exit(0)
    print(mode(sys.stdin.read()))
