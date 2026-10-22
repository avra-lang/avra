"""Fit the cascade's decision parameters on labelled dev decisions.

usage: python calibrate.py OUT_JSON --choices DECISIONS SCORES [...] --er DECISIONS SCORES [--records DECISIONS FRAMING=SCORES [...]]
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


def leader(row, p):
    """The record kind a decision's scores favour, or None when 'none' leads."""
    best = max(range(len(p)), key=lambda i: p[i])
    return best if best < len(row["options"]) else None


def accepted_right(row, p, t):
    """Whether taking the leading kind at threshold t is the right call: taken
    when it is among the sentence's records, left when it is not."""
    k = leader(row, p)
    return (k in row["gold"]) == (p[k] >= t)


def fit_threshold(pairs):
    """The tightest grid threshold with the best accuracy on one kind's leads."""
    return max(GRID, key=lambda t: (sum(accepted_right(r, p, t) for r, p in pairs), t))


def record_fit(pairs, per_kind):
    """{kind index or None: threshold}: one threshold for every kind, or one per
    kind that leads at least once (the others take the pooled one)."""
    led = [(r, p) for r, p in pairs if leader(r, p) is not None]
    pooled = fit_threshold(led)
    if not per_kind:
        return {None: pooled}
    kinds = {leader(r, p) for r, p in led}
    return {None: pooled, **{k: fit_threshold([(r, p) for r, p in led if leader(r, p) == k]) for k in kinds}}


def record_accuracy(pairs, fit):
    led = [(r, p) for r, p in pairs if leader(r, p) is not None]
    return sum(accepted_right(r, p, fit.get(leader(r, p), fit[None])) for r, p in led) / len(led) if led else 0.0


def held_out_accuracy(pairs, per_kind):
    """Leave-one-source-out accuracy of a fit, so the granularity is chosen by
    decisions it never saw."""
    sources = sorted({r["source"] for r, _ in pairs})
    ok = n = 0
    for s in sources:
        rest = [(r, p) for r, p in pairs if r["source"] != s]
        mine = [(r, p) for r, p in pairs if r["source"] == s and leader(r, p) is not None]
        fit = record_fit(rest, per_kind)
        ok += sum(accepted_right(r, p, fit.get(leader(r, p), fit[None])) for r, p in mine)
        n += len(mine)
    return ok / n if n else 0.0


def record_params(decisions, framed):
    """accept_record and record_framing from record-kind decisions scored under
    each framing: the framing whose leading kind is right most often, then the
    threshold granularity that generalises best across sources."""
    rows = {json.loads(l)["id"]: json.loads(l) for l in open(decisions)}
    scored = {}
    for name, path in framed:
        scored[name] = [(rows[s["id"]], s["p"]) for s in map(json.loads, open(path)) if s["id"] in rows]

    def right(pairs):
        return sum((max(range(len(p)), key=lambda i: p[i]) in r["gold"]) if r["gold"] else leader(r, p) is None for r, p in pairs) / len(pairs)

    accuracy = {name: right(pairs) for name, pairs in scored.items()}
    framing = max(accuracy, key=lambda n: (accuracy[n], -list(accuracy).index(n)))
    pairs = scored[framing]
    per_kind = held_out_accuracy(pairs, True) > held_out_accuracy(pairs, False)
    fit = record_fit(pairs, per_kind)
    names = {}
    for r, _ in pairs:
        names = r["options"]
        break
    record = {
        "value": fit[None],
        "fitted": True,
        "objective": "record-kind accept accuracy: the leading kind taken when it is among the sentence's records, left when it is not",
        "granularity": "per kind" if per_kind else "pooled",
        "held_out_accuracy": {"pooled": round(held_out_accuracy(pairs, False), 3), "per kind": round(held_out_accuracy(pairs, True), 3)},
        "dev_accuracy": round(record_accuracy(pairs, fit), 3),
        "n": sum(1 for r, p in pairs if leader(r, p) is not None),
    }
    if per_kind:
        record["per_kind"] = {names[k]: v for k, v in sorted(fit.items(), key=lambda kv: -1 if kv[0] is None else kv[0]) if k is not None}
    return record, {"value": framing, "fitted": True, "objective": "share of record-kind decisions whose leading choice is right (a record kind in the gold set, or none)", "accuracy": {n: round(a, 3) for n, a in accuracy.items()}, "n": len(pairs)}


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
    records = None
    if "--records" in args:
        given = args[args.index("--records") + 1 :]
        records = (given[0], [tuple(g.split("=", 1)) for g in given[1:]])
    # A wrong merge is the worst error: none first, then the most right answers.
    fits = []
    for m in GRID:
        for c in GRID:
            o = [er_outcome(r, p, m, c) for r, p in ers]
            fits.append((o.count("wrong"), -o.count("right"), o.count("duplicate"), -m, (m, c)))
    wrong, right, _, _, (margin, ceiling) = min(fits)
    fitted_records = record_params(*records) if records else None
    params = {
        "accept": {"value": accept, "fitted": True, "objective": "relation-choice accuracy", "dev_accuracy": round(accept_score(relation, accept), 3), "n": len(relation)},
        "margin": {"value": margin, "fitted": True, "objective": "no wrong merge, then most right, then fewest duplicates", "dev_wrong": wrong, "dev_right": -right, "n": len(ers)},
        "new_ceiling": {"value": ceiling, "fitted": True, "objective": "joint with margin", "n": len(ers)},
        "accept_speaker": {"value": accept_speaker, "fitted": True, "objective": "speaker-choice accuracy ('cannot tell' when below)", "dev_accuracy": round(accept_score(speaker, accept_speaker), 3), "n": len(speaker)},
        "accept_record": {"value": accept, "fitted": False, "prior": "borrowed from the relation fit; no labelled record-pass decisions yet"},
        "accept_field": {"value": fitted_records[0]["value"] if records else accept, "fitted": False, "prior": "borrowed from accept_record's pooled value; no labelled field-level decisions yet"},
        "record_framing": {"value": "line", "fitted": False, "prior": "the first physical line of the model description"},
        **({"accept_record": fitted_records[0], "record_framing": fitted_records[1]} if records else {}),
        "span_threshold": {"value": 0.5, "fitted": False, "prior": "GLiNER2 library default threshold; no labelled span data yet"},
    }
    json.dump({
        "fitted_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "scorer": SCORER,
        "encoder": ENCODER,
        "method": "grid search, step 0.05; ties go to the larger value",
        "data": {p: digest(p) for p in choices + er + ([records[0]] + [path for _, path in records[1]] if records else [])},
        "params": params,
    }, open(out, "w"), indent=2)
    print(json.dumps({k: v["value"] for k, v in params.items()}))


if __name__ == "__main__":
    main()
