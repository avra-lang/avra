"""Measure retrieval channels, entity linking and schema linking on an
invented corpus (invent.py).

usage: python bench.py DATA.json EMBEDDER [--rerank MODEL] [--part retrieval|entity|schema|all]
One embedder (and at most one reranker) per process; prints one JSON line
per measurement, with latency and peak RSS.
"""
import argparse
import json
import resource
import sys
import time

import numpy as np

import channels
from embedders import Embedder, VectorStore


def rss_mb():
    return round(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1e6)


def metrics(ranks, ks=(1, 3, 5, 10)):
    """Recall@k and MRR over each question's rank of its first gold item (None = missed)."""
    n = len(ranks)
    out = {f"R@{k}": round(sum(1 for r in ranks if r is not None and r <= k) / n, 3) for k in ks}
    out["MRR"] = round(sum(1 / r for r in ranks if r) / n, 3)
    return out


def first_rank(order, gold):
    return next((i for i, p in enumerate(order, 1) if p in gold), None)


def trigrams(s):
    s = f"  {s.lower()} "
    return {s[i:i + 3] for i in range(len(s) - 2)}


def trigram_rank(mention, names, n):
    q = trigrams(mention)
    sim = [len(q & trigrams(x)) / len(q | trigrams(x)) for x in names]
    return [int(i) for i in np.argsort(-np.asarray(sim), kind="stable")[:n]]


def entity_part(domains, store, emb, rng_seed=7):
    """Mention -> entity. Mentions: the short form, a typo of the full name, a typo of the short form.
    Index regimes: names only, or names and short forms (the aliases the graph holds)."""
    import random

    from invent import typo

    rng = random.Random(rng_seed)
    results = {}
    for regime in ("names", "names+aliases"):
        for mention_kind in ("alias", "name_typo", "alias_typo"):
            tally = {m: [] for m in ("dense", "trigram", "dense+trigram")}
            for d in domains:
                ents = d["entities"]
                forms, owner = [], []
                for i, e in enumerate(ents):
                    for f in ([e["name"]] if regime == "names" else [e["name"], e["alias"]]):
                        forms.append(f"{f} ({e['kind']})")
                        owner.append(i)
                fv = store.encode(emb, forms, "document")
                mentions = [{"alias": e["alias"], "name_typo": typo(e["name"], rng), "alias_typo": typo(e["alias"], rng)}[mention_kind] for e in ents]
                qv = store.encode(emb, mentions, "query")
                for i, (m, q) in enumerate(zip(mentions, qv)):
                    dense = [owner[j] for j in np.argsort(-(fv @ q), kind="stable")]
                    tri = [owner[j] for j in trigram_rank(m, forms, len(forms))]
                    for name, order in (("dense", dense), ("trigram", tri), ("dense+trigram", channels.rrf([dedupe(dense), dedupe(tri)], 60))):
                        tally[name].append(first_rank(dedupe(order), {i}))
            for name, ranks in tally.items():
                results[f"{regime}/{mention_kind}/{name}"] = metrics(ranks, (1, 3))
    return results


def dedupe(order):
    return list(dict.fromkeys(order))


def schema_part(domains, store, emb):
    """Phrase -> record kind by the declared description."""
    out = {}
    ranks = []
    for d in domains:
        docs = [f"{s['name']}: {s['description']}" for s in d["schema"]]
        dv = store.encode(emb, docs, "document")
        phrases = [(p, i) for i, s in enumerate(d["schema"]) for p in s["phrases"]]
        qv = store.encode(emb, [p for p, _ in phrases], "query")
        for (p, gold), q in zip(phrases, qv):
            ranks.append(first_rank([int(i) for i in np.argsort(-(dv @ q), kind="stable")], {gold}))
    return metrics(ranks, (1, 3))


def retrieval_part(domains, store, emb, reranker, depth=50, k=60):
    """Per-domain passage retrieval with each channel alone and fused."""
    runs = {}
    t_dense = t_rerank = 0.0
    nq = 0
    for d in domains:
        texts = [p["text"] for p in d["passages"]]
        pidx = {p["id"]: i for i, p in enumerate(d["passages"])}
        pv = store.encode(emb, texts, "document")
        lex, dense = channels.Lexical(texts), channels.Dense(pv)
        # entity graph: node i < E are entities, E + j are passages
        E = len(d["entities"])
        eidx = {e["id"]: i for i, e in enumerate(d["entities"])}
        forms = [f"{e['name']} ({e['kind']})" for e in d["entities"]]
        fv = store.encode(emb, forms, "document")
        links = [(eidx[m], E + pidx[p["id"]]) for p in d["passages"] for m in p["mentions"]]
        # a note naming another entity also ties to it
        for p in d["passages"]:
            for e in d["entities"]:
                if e["name"].lower() in p["text"].lower() and e["id"] not in p["mentions"]:
                    links.append((eidx[e["id"]], E + pidx[p["id"]]))
        qs = d["questions"]
        qv = store.encode(emb, [q["question"] for q in qs], "query")
        for q, v in zip(qs, qv):
            nq += 1
            gold = {pidx[g] for g in q["gold"]}
            t = time.time()
            dn = dense.rank(v, depth)
            t_dense += time.time() - t
            lx = lex.rank(q["question"], depth)
            link = int(np.argmax(fv @ v)) if False else None
            mention_v = store.encode(emb, [q["mention"]], "query")[0]
            seed = int(np.argmax(fv @ mention_v))
            pr = walk_scores(seed, links, E, len(texts))
            wk = [int(i) for i in np.argsort(-pr, kind="stable")[:depth] if pr[i] > 0]
            variants = {"dense": dn, "bm25": lx, "walk": wk}
            for combo in (("bm25", "dense"), ("bm25", "walk"), ("dense", "walk"), ("bm25", "dense", "walk")):
                variants["+".join(combo)] = channels.rrf([variants[c] for c in combo], k)
            if reranker:
                for base in ("dense", "bm25+dense+walk"):
                    t = time.time()
                    variants[f"{base}>rerank"] = reranker.rerank(q["question"], texts, variants[base][:depth]) + variants[base][depth:]
                    t_rerank += time.time() - t
            for name, order in variants.items():
                runs.setdefault(name, []).append(first_rank(order, gold))
    out = {name: metrics(r) for name, r in runs.items()}
    out["_latency_ms"] = {"dense_scan_per_query": round(1000 * t_dense / nq, 2), "rerank_per_query": round(1000 * t_rerank / nq, 1) if reranker else None, "queries": nq}
    return out


def walk_scores(seed, links, E, P):
    s = channels.walk([seed], links, E + P)
    return s[E:]


def pooled(domains):
    """All domains as one: ids prefixed per domain, so entities and passages of different
    settings compete in one index."""
    out = {"theme": "pool", "entities": [], "passages": [], "questions": [], "schema": []}
    for n, d in enumerate(domains):
        for e in d["entities"]:
            out["entities"].append({**e, "id": f"{n}{e['id']}"})
        for p in d["passages"]:
            out["passages"].append({**p, "id": f"{n}{p['id']}", "mentions": [f"{n}{m}" for m in p["mentions"]]})
        for q in d["questions"]:
            out["questions"].append({**q, "gold": [f"{n}{g}" for g in q["gold"]], "entity": f"{n}{q['entity']}"})
        out["schema"] += d["schema"]
    return [out]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("data")
    ap.add_argument("embedder")
    ap.add_argument("--rerank")
    ap.add_argument("--pool", action="store_true")
    ap.add_argument("--part", default="all")
    ap.add_argument("--vectors", default="data/vectors.db")
    a = ap.parse_args()
    domains = json.load(open(a.data))["domains"]
    if a.pool:
        domains = pooled(domains)
    store, emb = VectorStore(a.vectors), Embedder(a.embedder)
    t = time.time()
    emb._load()
    load_s = round(time.time() - t, 1)
    reranker = channels.Reranker(a.rerank) if a.rerank else None
    for part, fn in (("entity", lambda: entity_part(domains, store, emb)), ("schema", lambda: schema_part(domains, store, emb)), ("retrieval", lambda: retrieval_part(domains, store, emb, reranker))):
        if a.part in (part, "all"):
            t = time.time()
            res = fn()
            print(json.dumps({"embedder": a.embedder, "reranker": a.rerank, "part": part, "load_s": load_s, "wall_s": round(time.time() - t, 1), "rss_mb": rss_mb(), "result": res}))


if __name__ == "__main__":
    main()
