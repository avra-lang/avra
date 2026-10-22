#!/usr/bin/env python3
"""Fits the planner's parameters on scored bench decisions; writes params.json.

    python3 graph/planner/bench/calibrate.py graph/planner/bench/results/bench-<time>.json

property_yes: a property is returned when its debiased probability of "yes"
is at least this value. Fitted as the cut that makes the most property
decisions right on the development bench (ties: the lowest such cut), and
recorded with the results file, its date and both accuracies, so the
parameter's provenance is the file that fitted it.
"""
import datetime
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent


def property_yes(decisions, scored):
    """(cut, right at cut, right at argmax, n) over yes/no property decisions."""
    points = []
    for d, s in zip(decisions, scored):
        if s["kind"] != "property":
            continue
        yes = d["options"].index("yes")
        p_yes = s["p"][yes] if "p" in s else (s["p_gold"] if d["gold"] == yes else 1 - s["p_gold"])
        points.append((p_yes, d["gold"] == yes))
    cuts = sorted({p for p, _ in points} | {1.01})
    right = {c: sum((p >= c) == gold for p, gold in points) for c in cuts}
    best = max(cuts, key=lambda c: (right[c], -c))
    argmax = sum((p > 0.5) == gold for p, gold in points)
    return best, right[best], argmax, len(points)


def main():
    results = pathlib.Path(sys.argv[1])
    scored = json.loads(results.read_text())["scored"]
    decisions = [json.loads(l) for l in (HERE / "decisions.each.jsonl").read_text().splitlines() if l.strip()][1:]
    cut, right, argmax, n = property_yes(decisions[:len(scored)], scored)
    params = {"property_yes": cut,
              "fitted": {"on": str(results.name), "at": datetime.datetime.now().isoformat(timespec="seconds"),
                         "decisions": n, "right_at_cut": right, "right_at_argmax": argmax}}
    (HERE.parent / "params.json").write_text(json.dumps(params, indent=1) + "\n")
    print(f"property_yes = {cut:.3f}: {right}/{n} right (argmax {argmax}/{n}) -> graph/planner/params.json")


if __name__ == "__main__":
    main()
