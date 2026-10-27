"""Fit the retrieval parameters on the gym's train worlds and check them on the
frozen eval split.

usage: python fit_gym.py params.json
Train worlds: every gym/out/train/<n> holding items.json and texts.json; their
answerable questions target their gold sources. Fitted: RRF k, the BM25 weight
(dense is 1) and the rerank depth, by MRR of the first gold source. The walk
weight is not fitted here (no graph walk runs over a gym world) and stays as it
was. Provenance of both splits is written into the params."""
import collections
import glob
import itertools
import json
import os
import sys

import numpy as np

import channels
from bench import first_rank
from embedders import Embedder, VectorStore

GYM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "gym")


def worlds(split_jsonl=None):
    """[(texts, [(question, gold source ids)])] per world."""
    out = []
    if split_jsonl:
        by = collections.defaultdict(list)
        for l in open(split_jsonl):
            q = json.loads(l)
            if q["intent"] == "answer" and q["gold"]["sources"]:
                by[q["world_dir"]].append((q["question"], q["gold"]["sources"]))
        return [(json.load(open(os.path.join(GYM, "out", *w.split("/"), "texts.json"))), qs) for w, qs in by.items()]
    for d in sorted(glob.glob(os.path.join(GYM, "out", "train", "*"))):
        if os.path.exists(d + "/items.json") and os.path.exists(d + "/texts.json"):
            qs = [(x["question"], x["gold"]["sources"]) for x in json.load(open(d + "/items.json")) if x.get("question") and x.get("intent") == "answer" and x["gold"]["sources"]]
            if qs:
                out.append((json.load(open(d + "/texts.json")), qs))
    return out


def runs_of(split, emb, store, reranker, depths):
    """Per question: the dense and bm25 rankings, the texts and gold, and the reranked
    order of the fusion at each (k, weight, depth) is computed by the caller from these."""
    rows = []
    for texts, qs in split:
        ids = list(texts)
        docs = [texts[i]["text"] for i in ids]
        lex, dense = channels.Lexical(docs), channels.Dense(store.encode(emb, docs, "document"))
        qv = store.encode(emb, [q for q, _ in qs], "query")
        for (q, gold), v in zip(qs, qv):
            g = {ids.index(s) for s in gold if s in ids}
            if g:
                rows.append({"q": q, "docs": docs, "gold": g, "dense": dense.rank(v, len(ids)), "bm25": lex.rank(q, len(ids))})
    return rows


def mrr(rows, order_of):
    return round(float(np.mean([1 / r if (r := first_rank(order_of(x), x["gold"])) else 0 for x in rows])), 4)


def main():
    path = sys.argv[1]
    params = json.load(open(path))
    emb, store = Embedder(params["embedder"]), VectorStore("data/vectors-gym.db")
    reranker = channels.Reranker(params["reranker"])
    train, check = worlds(), worlds(os.path.join(GYM, "splits", "eval-v1.jsonl"))
    fit_rows, check_rows = runs_of(train, emb, store, reranker, None), runs_of(check, emb, store, reranker, None)

    def fused(x, k, wb):
        return channels.rrf([x["dense"], x["bm25"]], k, [1.0, wb])

    best, best_m = None, -1
    for k, wb in itertools.product((10, 30, 60), (0.25, 0.5, 1.0, 2.0, 4.0)):
        m = mrr(fit_rows, lambda x: fused(x, k, wb))
        if m > best_m:
            best, best_m = (k, wb), m
    k, wb = best
    depth_mrr = {}
    for d in (3, 5, 8):
        depth_mrr[d] = mrr(fit_rows, lambda x: reranker.rerank(x["q"], x["docs"], fused(x, k, wb)[:d]) + fused(x, k, wb)[d:])
    top = max(depth_mrr.values())
    depth = min(d for d, m in depth_mrr.items() if m == top)

    def final(x):
        o = fused(x, k, wb)
        return reranker.rerank(x["q"], x["docs"], o[:depth]) + o[depth:]

    report = {"fit": {"questions": len(fit_rows), "worlds": len(train), "fused_MRR": best_m, "rerank_depth_MRR": depth_mrr},
              "eval": {"questions": len(check_rows), "worlds": len(check),
                       "invented_params": mrr(check_rows, lambda x: channels.rrf([x["dense"], x["bm25"]], params["rrf_k"], [params["weights"]["dense"], params["weights"]["bm25"]])),
                       "gym_params_fused": mrr(check_rows, lambda x: fused(x, k, wb)), "gym_params_reranked": mrr(check_rows, final),
                       "dense": mrr(check_rows, lambda x: x["dense"]), "bm25": mrr(check_rows, lambda x: x["bm25"])}}
    params["invented_params"] = {key: params[key] for key in ("rrf_k", "weights", "rerank_depth")}
    params["rrf_k"], params["weights"], params["rerank_depth"] = k, {**params["weights"], "dense": 1.0, "bm25": wb}, depth
    params["gym_fit"] = {"train_worlds": len(train), "train_questions": len(fit_rows), "report": report,
                         "rule": "grid max first-gold MRR on gym train worlds; smallest rerank depth reaching the best; walk weight kept from the invented fit"}
    json.dump(params, open(path, "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
