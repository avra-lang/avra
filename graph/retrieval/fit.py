"""Fit the retrieval parameters on invented domains and check them on others.

usage: python fit.py DATA.json EMBEDDER RERANKER OUT.json [PARAMS.json to update]
Domains split by position: the first ceil(2/3) fit (pooled), the rest check
(pooled). Fitted: RRF k, per-channel weights, the entity-link blend of
dense and trigram similarity, and the rerank depth. The output records the
data file, its seed, the models and both scores as provenance.
"""
import itertools
import json
import sys

import numpy as np

import channels
from bench import first_rank, metrics, pooled
from channels import trigrams
from embedders import Embedder, VectorStore


def trigram_sim(mention, forms):
    q = trigrams(mention)
    return np.array([len(q & trigrams(f)) / len(q | trigrams(f)) for f in forms])


def blend_rank(dense, tri, alpha):
    return list(np.argsort(-(alpha * dense + (1 - alpha) * tri), kind="stable"))


def entity_cases(pool, store, emb, regime):
    """(dense sims, trigram sims, owner of each form, gold entity) per mention."""
    import random

    from invent import typo

    rng = random.Random(7)
    ents = pool["entities"]
    forms, plain, owner = [], [], []
    for i, e in enumerate(ents):
        for f in ([e["name"], e["alias"]] if regime else [e["name"]]):
            forms.append(f"{f} ({e['kind']})")
            plain.append(f)
            owner.append(i)
    fv = store.encode(emb, forms, "document")
    cases = []
    for i, e in enumerate(ents):
        for m in (e["alias"], typo(e["name"], rng), typo(e["alias"], rng)):
            q = store.encode(emb, [m], "query")[0]
            cases.append((fv @ q, trigram_sim(m, plain), owner, i))
    return cases


def entity_score(cases, alpha):
    ranks = []
    for dense, tri, owner, gold in cases:
        order = list(dict.fromkeys(owner[j] for j in blend_rank(dense, tri, alpha)))
        ranks.append(first_rank(order, {gold}))
    return metrics(ranks, (1, 3))


def elbow(cases, alpha):
    """The smallest n whose recall equals recall at n + 1: the candidates a blocker must keep."""
    ranks = [first_rank(list(dict.fromkeys(owner[j] for j in blend_rank(d, t, alpha))), {g}) for d, t, owner, g in cases]
    recall = lambda n: sum(1 for r in ranks if r is not None and r <= n)
    n = 1
    while recall(n) < recall(n + 1):
        n += 1
    return n


def retrieval_runs(pool, store, emb, reranker):
    texts = [p["text"] for p in pool["passages"]]
    depth = len(texts)
    pidx = {p["id"]: i for i, p in enumerate(pool["passages"])}
    lex, dense = channels.Lexical(texts), channels.Dense(store.encode(emb, texts, "document"))
    E = len(pool["entities"])
    eidx = {e["id"]: i for i, e in enumerate(pool["entities"])}
    fv = store.encode(emb, [f"{e['name']} ({e['kind']})" for e in pool["entities"]], "document")
    links = [(eidx[m], E + pidx[p["id"]]) for p in pool["passages"] for m in p["mentions"]]
    runs = []
    for q in pool["questions"]:
        v = store.encode(emb, [q["question"]], "query")[0]
        seed = int(np.argmax(fv @ store.encode(emb, [q["mention"]], "query")[0]))
        pr = channels.walk([seed], links, E + len(texts))[E:]
        ch = {"dense": dense.rank(v, depth), "bm25": lex.rank(q["question"], depth), "walk": [int(i) for i in np.argsort(-pr, kind="stable")[:depth] if pr[i] > 0]}
        runs.append((q, {pidx[g] for g in q["gold"]}, ch))
    return texts, runs


def fused(ch, k, w):
    return channels.rrf([ch["dense"], ch["bm25"], ch["walk"]], k, [w["dense"], w["bm25"], w["walk"]])


def main():
    data, emb_id, rr_id, out = sys.argv[1:5]
    domains = json.load(open(data))
    seed = domains["seed"]
    domains = domains["domains"]
    cut = -(-2 * len(domains) // 3)
    fit_pool, check_pool = pooled(domains[:cut])[0], pooled(domains[cut:])[0]
    store, emb = VectorStore("data/vectors.db"), Embedder(emb_id)
    reranker = channels.Reranker(rr_id)

    best = {}
    grid = [round(a, 2) for a in np.linspace(0, 1, 11)]
    for regime in (False, True):
        cases = entity_cases(fit_pool, store, emb, regime)
        score = {a: entity_score(cases, a)["MRR"] for a in grid}
        best[regime] = max(grid, key=lambda a: (score[a], -abs(a - 0.5)))
    check = {str(r): entity_score(entity_cases(check_pool, store, emb, r), best[r]) for r in (False, True)}
    check_fixed = {str(r): {str(a): entity_score(entity_cases(check_pool, store, emb, r), a)["MRR"] for a in (0, 0.5, 1.0)} for r in (False, True)}
    blend = best[True]
    candidates = max(elbow(entity_cases(fit_pool, store, emb, r), best[r]) for r in (False, True))

    texts, fit_runs = retrieval_runs(fit_pool, store, emb, reranker)
    _, check_runs = retrieval_runs(check_pool, store, emb, reranker)
    best_cfg, best_mrr = None, -1
    for k, wb, ww in itertools.product((10, 30, 60), (0.25, 0.5, 1.0), (0.0, 0.1, 0.25, 0.5)):
        w = {"dense": 1.0, "bm25": wb, "walk": ww}
        mrr = metrics([first_rank(fused(ch, k, w), g) for _, g, ch in fit_runs])["MRR"]
        if mrr > best_mrr:
            best_cfg, best_mrr = (k, w), mrr
    k, w = best_cfg
    depths = {}
    for n in (3, 5, 10, 20):  # candidate depths; the smallest reaching the best MRR is kept
        ranks = []
        for q, g, ch in fit_runs:
            order = fused(ch, k, w)
            ranks.append(first_rank(reranker.rerank(q["question"], texts, order[:n]) + order[n:], g))
        depths[n] = metrics(ranks, (1, 3))
    check_texts = _
    result = {
        "provenance": {"data": data, "seed": seed, "fit_domains": cut, "check_domains": len(domains) - cut, "embedder": emb.identity, "reranker": rr_id, "fit_questions": len(fit_runs)},
        "rerank_depth_fit": depths,
        "fit": {"fused_MRR": best_mrr},
        "check": {
            "entity_blend_by_regime": check,
            "entity_fixed_alpha_mrr": check_fixed,
            "fused": metrics([first_rank(fused(ch, k, w), g) for _, g, ch in check_runs]),
            "dense": metrics([first_rank(ch["dense"], g) for _, g, ch in check_runs]),
            "equal_weights_k60": metrics([first_rank(fused(ch, 60, {"dense": 1, "bm25": 1, "walk": 1}), g) for _, g, ch in check_runs]),
        },
    }
    top = max(v["MRR"] for v in depths.values())
    result["params"] = {"rrf_k": k, "weights": w, "entity_blend_dense": blend, "rerank_depth": min(n for n, v in depths.items() if v["MRR"] == top), "candidates_per_mention": candidates}
    json.dump(result, open(out, "w"), indent=1)
    print(json.dumps(result["params"]))
    if len(sys.argv) > 5:
        params = json.load(open(sys.argv[5]))
        params.update(result["params"], embedder=emb_id, reranker=rr_id, provenance={**result["provenance"], "fit_file": out, "rule": "grid max fused MRR on fit domains; smallest depth reaching the best rerank MRR; candidates at the recall elbow"})
        json.dump(params, open(sys.argv[5], "w"), indent=1)


if __name__ == "__main__":
    main()
