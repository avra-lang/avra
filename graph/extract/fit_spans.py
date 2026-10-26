"""Fit the encoder's span threshold on invented domains, never on fixtures.

usage: python fit_spans.py [--write PARAMS.json]     (needs the encoder's python; no generative model)

For each authored message, the encoder is asked for the domain's entity labels at the grid's
lowest threshold, once; every higher threshold is then a filter on the returned confidences.
A gold mention is an entity name the authored message places in its text. The threshold is the
grid value with the best exact-span F1 over the fitting domains; every fourth domain is held out.
"""
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from fit_records import GRID, HELD_OUT_EVERY, TUNE, tune_module  # noqa: E402


def collected(corpus):
    """(domain, gold spans, predicted spans with confidence) per message."""
    import cascade

    encoder = cascade.Encoder()
    out = []
    try:
        for name, d in corpus.domains().items():
            plan = cascade.Plan(corpus.descriptor(d))
            labels = plan.entity_labels()
            models = {m.lower() for m in plan.entities}
            for m in d["messages"]:
                gold = set()
                for a, b, item in corpus.placed(m["text"], m.get("mentions", [])):
                    kind = d["entities"][item[1]]["model"].lower() if item[1] in d["entities"] else None
                    if "ref" not in item[2:] and kind in models:
                        gold.add((a, b, kind))
                found = encoder.ask(op="mentions", text=m["text"], labels=labels, threshold=GRID[0])["value"]
                out.append((name, gold, [(x["start"], x["end"], k, x["confidence"]) for k, xs in found.items() if k in models for x in xs]))
    finally:
        encoder.close()
    return out


def f1(rows, t):
    tp = fp = fn = 0
    for _, gold, pred in rows:
        kept = {(a, b, k) for a, b, k, c in pred if c >= t}
        tp, fp, fn = tp + len(kept & gold), fp + len(kept - gold), fn + len(gold - kept)
    return 2 * tp / (2 * tp + fp + fn) if tp else 0.0


def main():
    corpus = tune_module("corpus")
    rows = collected(corpus)
    held = {d for i, d in enumerate(sorted({r[0] for r in rows})) if i % HELD_OUT_EVERY == HELD_OUT_EVERY - 1}
    train, test = [r for r in rows if r[0] not in held], [r for r in rows if r[0] in held]
    t = max(GRID, key=lambda g: (f1(train, g), g))
    report = {"train_f1": round(f1(train, t), 3), "held_out_f1": round(f1(test, t), 3), "n_train": len(train), "n_held_out": len(test),
              "curve": {str(g): round(f1(rows, g), 3) for g in GRID}}
    print(json.dumps({"threshold": t, **report}, indent=1))
    if "--write" in sys.argv:
        path = sys.argv[sys.argv.index("--write") + 1]
        params = json.load(open(path))
        names = sorted(os.listdir(os.path.join(TUNE, "corpus")))
        digest = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
        params["params"]["span_threshold"] = {
            "value": t, "fitted": True, "objective": "exact-span F1 of entity mentions over message text, invented domains only (no fixture text)",
            "granularity": "pooled", **{k: v for k, v in report.items() if k != "curve"},
            "data": {"corpus": hashlib.sha256("".join(digest(os.path.join(TUNE, "corpus", n)) for n in names).encode()).hexdigest(), "domains": len(names)}}
        json.dump(params, open(path, "w"), indent=2)


if __name__ == "__main__":
    main()
