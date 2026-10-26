"""Hybrid retrieval over passages: BM25, dense and a graph walk fused by
weighted RRF, then a cross-encoder over the top of the fusion.

Every hit carries the channels that placed it (an independent agreement
signal for abstention), and the ids of its passage, facts and source."""
import json
import os

import numpy as np

import channels
from embedders import Embedder, VectorStore
from link import EntityLinker, PARAMS


class Passage:
    def __init__(self, id, text, source=None, facts=(), entities=()):
        self.id, self.text, self.source, self.facts, self.entities = id, text, source, list(facts), list(entities)


class Index:
    """passages: [Passage]; entities: [{id, name, aliases?, kind?}] the graph knows.
    A passage ties to the entities it lists; a walk from the question's linked
    entities scores passages through those ties."""

    def __init__(self, passages, entities, embedder, store, reranker=None, params=PARAMS):
        self.passages, self.entities, self.params = passages, entities, params
        self.embedder, self.store, self.reranker = embedder, store, reranker
        texts = [p.text for p in passages]
        self.lex = channels.Lexical(texts)
        self.dense = channels.Dense(store.encode(embedder, texts, "document"))
        self.linker = EntityLinker(entities, embedder, store, params["entity_blend_dense"])
        self.eidx = {e["id"]: i for i, e in enumerate(entities)}
        E = len(entities)
        self.links = [(self.eidx[m], E + j) for j, p in enumerate(passages) for m in p.entities if m in self.eidx]

    def search(self, question, mentions=(), n=10):
        pa, depth = self.params, len(self.passages)
        qv = self.store.encode(self.embedder, [question], "query")[0]
        seeds = [self.eidx[self.linker.link(m, 1)[0][0]] for m in mentions]
        E = len(self.entities)
        scores = channels.walk(seeds, self.links, E + len(self.passages))[E:]
        ranked = {
            "dense": self.dense.rank(qv, depth),
            "bm25": self.lex.rank(question, depth),
            "walk": [int(i) for i in np.argsort(-scores, kind="stable")[:depth] if scores[i] > 0],
        }
        w = pa["weights"]
        order = channels.rrf([ranked[c] for c in ("dense", "bm25", "walk")], pa["rrf_k"], [w[c] for c in ("dense", "bm25", "walk")])
        top = pa["rerank_depth"]
        if self.reranker and order:
            order = self.reranker.rerank(question, [p.text for p in self.passages], order[:top]) + order[top:]
        out = []
        for i in order[:n]:
            p = self.passages[i]
            out.append({"passage": p.id, "source": p.source, "facts": p.facts, "text": p.text,
                        "channels": {c: r.index(i) + 1 for c, r in ranked.items() if i in r}})
        return out
