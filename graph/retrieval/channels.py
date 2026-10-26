"""Retrieval channels over passages, each answering a best-first list of
passage indexes, and the fusion that joins them."""
import math
import re
import sqlite3

import numpy as np


def rrf(rankings, k, weights=None):
    """Reciprocal Rank Fusion: each ranking contributes 1/(k+rank) per item."""
    score = {}
    for i, ranking in enumerate(rankings):
        for rank, item in enumerate(ranking, 1):
            score[item] = score.get(item, 0.0) + (weights[i] if weights else 1.0) / (k + rank)
    return sorted(score, key=lambda x: (-score[x], x))


def terms(query):
    """FTS5 match expression: every word of the query, any of them."""
    return " OR ".join('"' + w + '"' for w in re.findall(r"\w+", query))


class Lexical:
    """BM25 over passages with the store's own FTS5 tokenizer."""

    def __init__(self, texts):
        self.db = sqlite3.connect(":memory:")
        self.db.execute("CREATE VIRTUAL TABLE p USING fts5(text, tokenize = 'porter unicode61 remove_diacritics 2')")
        self.db.executemany("INSERT INTO p(rowid, text) VALUES (?, ?)", list(enumerate(texts)))

    def rank(self, query, n):
        m = terms(query)
        if not m:
            return []
        return [r[0] for r in self.db.execute("SELECT rowid FROM p WHERE p MATCH ? ORDER BY bm25(p), rowid LIMIT ?", (m, n))]


class Dense:
    def __init__(self, vectors):
        self.vectors = vectors

    def rank(self, qvec, n):
        s = self.vectors @ qvec
        return [int(i) for i in np.argsort(-s, kind="stable")[:n]]


def walk(seeds, links, size, iterations=20, damping=0.85):
    """Personalized PageRank from `seeds` over undirected `links` between
    node indexes 0..size-1; the scores of every node, mass at a dead end
    returning to the seeds."""
    if not seeds:
        return np.zeros(size)
    adj = np.zeros((size, size))
    for a, b in links:
        adj[a, b] = adj[b, a] = 1.0
    deg = adj.sum(1)
    restart = np.zeros(size)
    restart[list(seeds)] = 1.0 / len(set(seeds))
    s = restart.copy()
    for _ in range(iterations):
        flow = (adj / np.where(deg == 0, 1, deg)[:, None]).T @ s
        stranded = s[deg == 0].sum()
        s = (1 - damping) * restart + damping * (flow + stranded * restart)
    return s


class Reranker:
    def __init__(self, model_id):
        from sentence_transformers import CrossEncoder

        self.model_id, self.model = model_id, CrossEncoder(model_id, device="cpu")

    def rerank(self, query, texts, order):
        scores = self.model.predict([(query, texts[i]) for i in order], batch_size=16)
        return [order[i] for i in np.argsort(-scores, kind="stable")]
