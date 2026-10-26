"""Linking by embedding plus string shape, over the graph's own declared
names, aliases and descriptions."""
import numpy as np

import json
import os

from bench import trigrams

PARAMS = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "params.json")))


def trigram_sim(mention, forms):
    q = trigrams(mention)
    return np.array([len(q & trigrams(f)) / len(q | trigrams(f)) for f in forms])


class EntityLinker:
    """entities: [{id, name, aliases?, kind?}]. Every name and alias is a form; a mention
    ranks entities by a blend of embedding cosine and character-trigram overlap."""

    def __init__(self, entities, embedder, store, blend=None):
        self.embedder, self.store = embedder, store
        self.blend = PARAMS["entity_blend_dense"] if blend is None else blend
        self.forms, self.owner = [], []
        for e in entities:
            for f in [e["name"], *e.get("aliases", [])]:
                self.forms.append(f"{f} ({e['kind']})" if e.get("kind") else f)
                self.owner.append(e["id"])
        self.vectors = store.encode(embedder, self.forms, "document")

    def link(self, mention, n=3):
        """Up to n (entity id, score) pairs, best first."""
        score = self.blend * (self.vectors @ self.store.encode(self.embedder, [mention], "query")[0]) + (1 - self.blend) * trigram_sim(mention, self.forms)
        out = {}
        for j in np.argsort(-score, kind="stable"):
            out.setdefault(self.owner[j], float(score[j]))
            if len(out) == n:
                break
        return list(out.items())


def candidate_pairs(mentions, entities, embedder, store, n=None):
    """Blocking for entity resolution: for each mention string, the ids of the
    n entities it may be, best first. Resolution decides among them."""
    linker = EntityLinker(entities, embedder, store)
    n = n or PARAMS["candidates_per_mention"]
    return {m: [i for i, _ in linker.link(m, n)] for m in mentions}


class SchemaLinker:
    """catalog: [{name, description}]. A phrase ranks record kinds by embedding
    similarity to the declared description."""

    def __init__(self, catalog, embedder, store):
        self.names = [c["name"] for c in catalog]
        self.embedder, self.store = embedder, store
        self.vectors = store.encode(embedder, [f"{c['name']}: {c['description']}" for c in catalog], "document")

    def link(self, phrase, n=3):
        s = self.vectors @ self.store.encode(self.embedder, [phrase], "query")[0]
        return [(self.names[i], float(s[i])) for i in np.argsort(-s, kind="stable")[:n]]
