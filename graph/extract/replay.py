"""An extractor hook that answers from recorded extractions.

usage: REPLAY_FROM=<results file>[:<more>] [REPLAY_RECONCILE=1] python replay.py < source envelope > extraction result

REPLAY_RECONCILE=1 passes each recorded extraction through the cascade's end-of-extraction reconciliation.

The result file's `extractions` hold each source's extraction as it was admitted. Replaying them
holds extraction fixed, so a change downstream (resolution, planning) is measured alone.
"""
import json
import os
import sys


def recorded(paths):
    found = {}
    for path in paths.split(":"):
        for e in json.load(open(path))["extractions"]:
            result = e.get("result") or {}
            if result.get("status") == "complete":
                found[(result["source"]["observation"], result["source"]["revision"])] = result
    return found


def main():
    envelope = json.load(sys.stdin)
    key = (envelope["source"]["observation"], envelope["source"]["revision"])
    got = recorded(os.environ["REPLAY_FROM"]).get(key)
    if got is None:
        sys.exit(f"no recorded extraction for {key}")
    if os.environ.get("REPLAY_RECONCILE"):
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import cascade

        got = {**got, "records": cascade.reconciled(got["records"])}
    json.dump(got, sys.stdout)


if __name__ == "__main__":
    main()
