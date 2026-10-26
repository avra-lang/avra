"""Fit the span threshold: the score separating a run of words that names an
entity from one that does not, on the invented questions.

usage: python fit_spans.py DATA.json params.json
Fit on the first ceil(2/3) of domains, checked on the rest. A question's span
is its mention, written as is or with a one-character edit; any other run of
up to span_words words, and any run linking to a different entity, is a miss."""
import json
import random
import sys

import numpy as np

from embedders import Embedder, VectorStore
from invent import typo
from link import EntityLinker
from spans import kept_spans, word_runs


def cases(domains, linker_for, longest, rng):
    """Per question: its scored runs and every known entity form it contains, as extents.
    The primary mention is also tried with a one-character edit."""
    out = []
    for d in domains:
        linker = linker_for(d)
        for q in d["questions"]:
            for form in (q["mention"], typo(q["mention"], rng)):
                text = q["question"].replace(q["mention"], form, 1)
                gold = [(text.find(f), text.find(f) + len(f), e["id"]) for e in d["entities"] for f in (e["name"], e["alias"]) if f in text and (f != q["mention"] or form == q["mention"])]
                gold += [(text.find(form), text.find(form) + len(form), q["entity"])] if form != q["mention"] else []
                runs = word_runs(text, longest)
                scored = [(a, b, e, s) for (a, b), (e, s) in zip(runs, linker.best_many([text[a:b] for a, b in runs]))]
                out.append((scored, gold))
    return out


def f1_at(rows, t):
    """A gold form is found when a kept span overlaps it and names its entity; a kept
    span that finds no gold form is a false one."""
    found = gold_n = kept_n = true_n = 0
    for scored, gold in rows:
        kept = kept_spans(scored, t)
        kept_n += len(kept)
        gold_n += len(gold)
        found += sum(any(e == ge and not (b <= lo or a >= hi) for a, b, e, _ in kept) for lo, hi, ge in gold)
        true_n += sum(any(e == ge and not (b <= lo or a >= hi) for lo, hi, ge in gold) for a, b, e, _ in kept)
    p, r = true_n / max(kept_n, 1), found / max(gold_n, 1)
    return 2 * p * r / max(p + r, 1e-9), p, r


def main():
    data, params_path = sys.argv[1:3]
    doc = json.load(open(data))
    domains = doc["domains"]
    cut = -(-2 * len(domains) // 3)
    params = json.load(open(params_path))
    store, emb = VectorStore("data/vectors.db"), Embedder(params["embedder"])
    longest = params.get("span_words", 4)

    def linker_for(d):
        return EntityLinker([{"id": e["id"], "name": e["name"], "aliases": [e["alias"]], "kind": e["kind"]} for e in d["entities"]], emb, store, params["entity_blend_dense"])

    rng = random.Random(11)
    fit, check = cases(domains[:cut], linker_for, longest, rng), cases(domains[cut:], linker_for, longest, rng)
    grid = [round(t, 3) for t in np.linspace(0.3, 1.0, 71)]
    best = max(grid, key=lambda t: (f1_at(fit, t)[0], t))
    params["span_words"] = longest
    params["span_threshold"] = best
    params["span_fit"] = {"data": data, "seed": doc["seed"], "fit_f1": round(f1_at(fit, best)[0], 3), "check_f1_pr": [round(x, 3) for x in f1_at(check, best)], "rule": "max F1 over runs, ties to the higher threshold"}
    json.dump(params, open(params_path, "w"), indent=1)
    print(json.dumps(params["span_fit"]), "threshold", best)


if __name__ == "__main__":
    main()
