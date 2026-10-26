"""Fit the agreement threshold: the share of a plan's supporting passages the
independent retrieval must hold in its top `rerank_depth` for the plan's
answer to stand.

usage: python fit_agreement.py DATA.json params.json
Over the invented questions, pooled: a right answer is supported by the
question's gold passage, a wrong one by another entity's passage (the
question's passages excluded). The threshold maximises balanced accuracy on
the first ceil(2/3) of domains; the rest check it."""
import json
import random
import sys

import numpy as np

import channels
from bench import pooled
from embedders import Embedder, VectorStore
from hybrid import Index, Passage


def scored(pool, params, emb, store, reranker, rng):
    ps = [Passage(p["id"], p["text"], p["id"], [p["id"]], p["mentions"]) for p in pool["passages"]]
    ents = [{"id": e["id"], "name": e["name"], "aliases": [e["alias"]], "kind": e["kind"]} for e in pool["entities"]]
    index = Index(ps, ents, emb, store, reranker, params)
    right, wrong = [], []
    for q in pool["questions"]:
        held = {h["passage"] for h in index.search(q["question"], [q["mention"]], params["rerank_depth"])}
        gold = set(q["gold"])
        other = rng.choice([p["id"] for p in pool["passages"] if p["id"] not in gold and q["entity"] not in next(x for x in pool["passages"] if x["id"] == p["id"])["mentions"]])
        right.append(len(gold & held) / len(gold))
        wrong.append(len({other} & held))
    return right, wrong


def balanced(right, wrong, t):
    return (sum(r >= t for r in right) / len(right) + sum(w < t for w in wrong) / len(wrong)) / 2


def main():
    data, path = sys.argv[1:3]
    doc = json.load(open(data))
    domains = doc["domains"]
    cut = -(-2 * len(domains) // 3)
    params = json.load(open(path))
    emb, store = Embedder(params["embedder"]), VectorStore("data/vectors.db")
    reranker = channels.Reranker(params["reranker"])
    rng = random.Random(5)
    fit = scored(pooled(domains[:cut])[0], params, emb, store, reranker, rng)
    check = scored(pooled(domains[cut:])[0], params, emb, store, reranker, rng)
    grid = [round(t, 2) for t in np.linspace(0.05, 1.0, 20)]
    best = max(grid, key=lambda t: (balanced(*fit, t), -t))
    params["agreement_threshold"] = best
    params["agreement_fit"] = {"data": data, "seed": doc["seed"], "fit_balanced_accuracy": round(balanced(*fit, best), 3),
                               "check_balanced_accuracy": round(balanced(*check, best), 3),
                               "check_right_held": round(float(np.mean([r >= best for r in check[0]])), 3),
                               "check_wrong_rejected": round(float(np.mean([w < best for w in check[1]])), 3),
                               "rule": "max balanced accuracy over a 0.05 grid, ties to the lower threshold"}
    json.dump(params, open(path, "w"), indent=1)
    print(json.dumps(params["agreement_fit"]), best)


if __name__ == "__main__":
    main()
