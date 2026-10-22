"""Fit the cascade's decision parameters on labelled dev decisions.

usage: python calibrate.py OUT_JSON --choices DECISIONS SCORES [...] --er DECISIONS SCORES
Writes every parameter with the date, the scorer, the method and a sha256 of
each input file, so a fitted value can be reproduced and never sits in code
as a literal. A parameter the data cannot fit is written with fitted: false
and the source of its prior.
"""
import hashlib
import json
import sys
import time

sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
from pins import ENCODER, SCORER  # noqa: E402

GRID = [round(0.05 * i, 2) for i in range(1, 20)]


def loaded(decisions, scores):
    rows = {json.loads(l)["id"]: json.loads(l) for l in open(decisions)}
    return [(rows[s["id"]], s["p"]) for s in map(json.loads, open(scores)) if s["id"] in rows]


def digest(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def accept_score(pairs, t):
    """Accuracy when a choice is taken only at probability >= t, else 'none'."""
    ok = 0
    for row, p in pairs:
        none = len(row["options"]) - 1
        best = max(range(len(p)), key=lambda i: p[i])
        taken = best if p[best] >= t else none
        ok += taken == row["gold"]
    return ok / len(pairs)


def er_outcome(row, p, margin, ceiling):
    n = row["candidates"]
    ranked = sorted(range(len(p)), key=lambda i: -p[i])
    if ranked[0] < n and p[ranked[0]] - p[ranked[1]] >= margin:
        return "wrong" if ranked[0] != row["gold"] else "right"
    if ranked[0] == n and max(p[:n]) <= ceiling:
        return "right" if row["gold"] == n else "duplicate" if row["gold"] < n else "abstain"
    return "abstain"


def main():
    args = sys.argv[1:]
    out = args[0]
    choices = args[args.index("--choices") + 1 : args.index("--choices") + 3]
    er = args[args.index("--er") + 1 : args.index("--er") + 3]
    rows = loaded(*choices)
    relation = [(r, p) for r, p in rows if r["kind"] == "relation" and r["options"][-1].startswith("none")]
    speaker = [(r, p) for r, p in rows if r["kind"] == "speaker"]
    accept = max(GRID, key=lambda t: (accept_score(relation, t), t))
    accept_speaker = max(GRID, key=lambda t: (accept_score(speaker, t), t))
    ers = loaded(*er)
    # A wrong merge is the worst error: none first, then the most right answers.
    fits = []
    for m in GRID:
        for c in GRID:
            o = [er_outcome(r, p, m, c) for r, p in ers]
            fits.append((o.count("wrong"), -o.count("right"), o.count("duplicate"), -m, (m, c)))
    wrong, right, _, _, (margin, ceiling) = min(fits)
    params = {
        "accept": {"value": accept, "fitted": True, "objective": "relation-choice accuracy", "dev_accuracy": round(accept_score(relation, accept), 3), "n": len(relation)},
        "margin": {"value": margin, "fitted": True, "objective": "no wrong merge, then most right, then fewest duplicates", "dev_wrong": wrong, "dev_right": -right, "n": len(ers)},
        "new_ceiling": {"value": ceiling, "fitted": True, "objective": "joint with margin", "n": len(ers)},
        "accept_speaker": {"value": accept_speaker, "fitted": True, "objective": "speaker-choice accuracy ('cannot tell' when below)", "dev_accuracy": round(accept_score(speaker, accept_speaker), 3), "n": len(speaker)},
        "accept_record": {"value": accept, "fitted": False, "prior": "borrowed from the relation fit; no labelled record-pass decisions yet"},
        "span_threshold": {"value": 0.5, "fitted": False, "prior": "GLiNER2 library default threshold; no labelled span data yet"},
    }
    json.dump({
        "fitted_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "scorer": SCORER,
        "encoder": ENCODER,
        "method": "grid search, step 0.05; ties go to the larger value",
        "data": {p: digest(p) for p in choices + er},
        "params": params,
    }, open(out, "w"), indent=2)
    print(json.dumps({k: v["value"] for k, v in params.items()}))


if __name__ == "__main__":
    main()
