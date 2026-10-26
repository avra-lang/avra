"""Fit the cascade's remaining decision parameters on invented-domain decisions.

usage: python fit_decisions.py [--write PARAMS.json] [--every kind=N ...]

Reads the closed choices the real cascade asks over authored invented domains with gold answers
(TUNE_DIR/out/extract.jsonl: relation, speaker, antecedent, field), samples each kind by hash of
the decision, scores it with the resident model service (AVRA_GRAPH_SOCKET) over the bytes the
cascade sends, and fits on the fitting domains (every fourth held out):
  accept          relation choice accuracy      accept_speaker  speaker choice accuracy
  accept_field    field choice accuracy         margin, new_ceiling  no wrong merge, then most right, then fewest duplicates
Scores are kept in bench/decisions.invented.scores.jsonl, so a refit costs no model call.
"""
import hashlib
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from fit_records import GRID, HELD_OUT_EVERY, TUNE, choose, ranked  # noqa: E402

SCORES = os.path.join(HERE, "bench", "decisions.invented.scores.jsonl")
KINDS = ("relation", "speaker", "antecedent", "field")


def sampled(every):
    for line in open(os.path.join(TUNE, "out", "extract.jsonl")):
        r = json.loads(line)
        if r["kind"] in KINDS and int(ranked(r["context"], r["question"])[:8], 16) % every.get(r["kind"], 1) == 0:
            yield r


def scored(rows, sock):
    kept = {}
    if os.path.exists(SCORES):
        kept = {json.loads(l)["key"]: json.loads(l) for l in open(SCORES)}
    with open(SCORES, "a") as f:
        for r in rows:
            key = hashlib.sha256(json.dumps([r["source"], r["context"], r["question"], r["options"]]).encode()).hexdigest()
            if key not in kept:
                p = choose(sock, f'Text: "{r["source"]}"\n\n{r["context"]}', r["question"], r["options"])
                kept[key] = {"key": key, "domain": r["domain"], "kind": r["kind"], "options": len(r["options"]), "tail": r["tail"], "gold": r["gold"], "p": p}
                f.write(json.dumps(kept[key]) + "\n")
                f.flush()
            yield kept[key]


def accepted(rs, t):
    """Accuracy when a choice is taken only at probability >= t, else the last option (none)."""
    ok = 0
    for r in rs:
        p = r["p"]
        best = max(range(len(p)), key=lambda i: p[i])
        ok += (best if p[best] >= t else len(p) - 1) == r["gold"]
    return ok / len(rs) if rs else 0.0


def outcome(r, margin, ceiling):
    p, n = r["p"], r["options"] - r["tail"]
    order = sorted(range(len(p)), key=lambda i: -p[i])
    if order[0] < n and p[order[0]] - p[order[1]] >= margin:
        return "wrong" if order[0] != r["gold"] else "right"
    if order[0] == n and max(p[:n]) <= ceiling:
        return "right" if r["gold"] == n else "duplicate" if r["gold"] < n else "abstain"
    return "abstain"


def merge_cost(rs, mc):
    o = [outcome(r, *mc) for r in rs]
    return (o.count("wrong"), -o.count("right"), o.count("duplicate"), -mc[0])


def main():
    args = sys.argv[1:]
    every = {k: int(v) for k, v in (a.split("=") for a in args[args.index("--every") + 1 :] if "=" in a)} if "--every" in args else {}
    sock = os.environ.get("AVRA_GRAPH_SOCKET") or os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")
    rs = list(scored(sampled(every), sock))
    held = {d for i, d in enumerate(sorted({r["domain"] for r in rs})) if i % HELD_OUT_EVERY == HELD_OUT_EVERY - 1}
    split = lambda kind, keep=lambda r: True: ([r for r in rs if r["kind"] == kind and keep(r) and r["domain"] not in held], [r for r in rs if r["kind"] == kind and keep(r) and r["domain"] in held])
    out = {}
    for name, kind in (("accept", "relation"), ("accept_speaker", "speaker"), ("accept_field", "field")):
        train, test = split(kind)
        t = max(GRID, key=lambda g: (accepted(train, g), g))
        out[name] = {"value": t, "objective": f"{kind}-choice accuracy (the last option when below)", "train_accuracy": round(accepted(train, t), 3),
                     "held_out_accuracy": round(accepted(test, t), 3), "n_train": len(train), "n_held_out": len(test)}
    train, test = split("antecedent")
    mc = min(((m, c) for m in GRID for c in GRID), key=lambda mc: merge_cost(train, mc))
    for name, i in (("margin", 0), ("new_ceiling", 1)):
        cost = lambda rows: [outcome(r, *mc) for r in rows]
        out[name] = {"value": mc[i], "objective": "antecedent choice: no wrong link, then most right, then fewest duplicates (joint margin and ceiling)",
                     "train_wrong": cost(train).count("wrong"), "train_right": cost(train).count("right"),
                     "held_out_wrong": cost(test).count("wrong"), "held_out_right": cost(test).count("right"), "n_train": len(train), "n_held_out": len(test)}
    print(json.dumps({k: {x: y for x, y in v.items()} for k, v in out.items()}, indent=1))
    if "--write" in args:
        path = args[args.index("--write") + 1]
        params = json.load(open(path))
        names = sorted(os.listdir(os.path.join(TUNE, "corpus")))
        digest = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
        data = {"scores": digest(SCORES), "decisions": digest(os.path.join(TUNE, "out", "extract.jsonl")),
                "corpus": hashlib.sha256("".join(digest(os.path.join(TUNE, "corpus", n)) for n in names).encode()).hexdigest(), "domains": len(names)}
        for name, v in out.items():
            params["params"][name] = {**v, "fitted": True, "granularity": "pooled", "sample": f"one in {every.get(next(k for k, n in (('relation', 'accept'), ('speaker', 'accept_speaker'), ('field', 'accept_field'), ('antecedent', name)) if n == name), 1)}, by hash", "data": data}
        json.dump(params, open(path, "w"), indent=2)


if __name__ == "__main__":
    main()
