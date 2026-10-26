"""Choose how a record kind is worded as an option, on invented domains.

usage: python fit_framing.py [--write PARAMS.json]

Scores each wording of cascade.FRAMINGS over the same sampled sentences (fit_records.py --mode choice
--framing NAME writes each scores file) and picks the wording whose leading choice is right most often:
a stated kind leading, or none leading when no kind is stated. Wordings without scores are not eligible.
"""
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cascade  # noqa: E402
from fit_records import TUNE  # noqa: E402


def rows(path):
    return [json.loads(l) for l in open(path)]


def right(rs):
    ok = 0
    for r in rs:
        p = r["p"]
        k = max(range(len(p)), key=lambda i: p[i])
        ok += (k in r["gold"]) if r["gold"] else k == len(p) - 1
    return ok / len(rs)


def main():
    files = {}
    for name in cascade.FRAMINGS:
        path = os.path.join(HERE, "bench", f"records.invented.choice.{name}.scores.jsonl")
        if os.path.exists(path):
            files[name] = path
    scored = {n: {r["sid"]: r for r in rows(p)} for n, p in files.items()}
    common = set.intersection(*(set(r) for r in scored.values()))
    scored = {n: {k: r[k] for k in common} for n, r in scored.items()}
    accuracy = {}
    for n, rs in scored.items():
        accuracy[n] = round(right(list(rs.values())), 3)
    best = max(accuracy, key=lambda n: (accuracy[n], -list(accuracy).index(n)))
    print(json.dumps({"framing": best, "accuracy": accuracy, "n": {n: len(r) for n, r in scored.items()}}, indent=1))
    if "--write" in sys.argv:
        path = sys.argv[sys.argv.index("--write") + 1]
        params = json.load(open(path))
        names = sorted(os.listdir(os.path.join(TUNE, "corpus")))
        digest = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
        params["params"]["record_framing"] = {
            "value": best, "fitted": True, "objective": "share of sampled sentences whose leading record-kind choice is right (a stated kind, or none when none is stated)",
            "accuracy": accuracy, "n": {n: len(r) for n, r in scored.items()},
            "data": {"scores": {n: digest(p) for n, p in files.items()}, "corpus": hashlib.sha256("".join(digest(os.path.join(TUNE, "corpus", n)) for n in names).encode()).hexdigest(), "domains": len(names)}}
        json.dump(params, open(path, "w"), indent=2)


if __name__ == "__main__":
    main()
