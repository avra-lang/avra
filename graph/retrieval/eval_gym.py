"""Retrieval on the gym's frozen eval split: per world, the rendered sources
are the passages and each answerable question's gold sources are its targets.

usage: python eval_gym.py EMBEDDER [--rerank MODEL] [--split PATH] [--out PATH]
Reports, per channel set, R@k over `any` and `all` gold sources and MRR of the
first gold source; the fused weights, k and rerank depth are params.json's."""
import argparse
import collections
import json
import os
import resource
import sys
import time

import numpy as np

import channels
from bench import first_rank
from embedders import Embedder, VectorStore

GYM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "gym")


def score(runs, ks=(1, 3, 5)):
    out = {}
    for k in ks:
        out[f"any@{k}"] = round(sum(1 for order, gold in runs if set(order[:k]) & gold) / len(runs), 3)
        out[f"all@{k}"] = round(sum(1 for order, gold in runs if gold <= set(order[:k])) / len(runs), 3)
    out["MRR"] = round(sum(1 / r for r in (first_rank(order, gold) for order, gold in runs) if r) / len(runs), 3)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("embedder")
    ap.add_argument("--rerank")
    ap.add_argument("--split", default=os.path.join(GYM, "splits", "eval-v1.jsonl"))
    ap.add_argument("--out")
    a = ap.parse_args()
    params = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "params.json")))
    questions = [json.loads(l) for l in open(a.split)]
    by_world = collections.defaultdict(list)
    for q in questions:
        if q["intent"] == "answer" and q["gold"]["sources"]:
            by_world[q["world_dir"]].append(q)
    emb, store = Embedder(a.embedder), VectorStore("data/vectors-gym.db")
    reranker = channels.Reranker(a.rerank) if a.rerank else None
    runs = collections.defaultdict(list)
    t_rerank, n = 0.0, 0
    for world, qs in by_world.items():
        texts = json.load(open(os.path.join(GYM, "out", *world.split("/"), "texts.json")))
        ids = list(texts)
        docs = [texts[i]["text"] for i in ids]
        dv = store.encode(emb, docs, "document")
        lex, dense = channels.Lexical(docs), channels.Dense(dv)
        qv = store.encode(emb, [q["question"] for q in qs], "query")
        for q, v in zip(qs, qv):
            gold = {ids.index(s) for s in q["gold"]["sources"] if s in ids}
            if not gold:
                continue
            n += 1
            ch = {"dense": dense.rank(v, len(ids)), "bm25": lex.rank(q["question"], len(ids))}
            ch["bm25+dense"] = channels.rrf([ch["dense"], ch["bm25"]], params["rrf_k"], [params["weights"]["dense"], params["weights"]["bm25"]])
            ch["bm25+dense(equal,k60)"] = channels.rrf([ch["dense"], ch["bm25"]], 60)
            if reranker:
                t = time.time()
                top = params["rerank_depth"]
                base = ch["bm25+dense"]
                ch["bm25+dense>rerank(depth)"] = reranker.rerank(q["question"], docs, base[:top]) + base[top:]
                ch["bm25+dense>rerank(all)"] = reranker.rerank(q["question"], docs, base)
                t_rerank += time.time() - t
            for name, order in ch.items():
                runs[name].append((order, gold))
    out = {"embedder": a.embedder, "reranker": a.rerank, "questions": n, "worlds": len(by_world),
           "result": {k: score(v) for k, v in runs.items()}, "rerank_ms_per_query": round(1000 * t_rerank / n, 1) if reranker else None,
           "rss_mb": round(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1e6)}
    print(json.dumps(out, indent=1))
    if a.out:
        json.dump(out, open(a.out, "w"), indent=1)


if __name__ == "__main__":
    main()
