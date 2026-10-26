"""The retrieval ops of the model service, answered by small non-generative
models held in this process.

`link`:     {entities:[{id,name,aliases?,kind?}], mentions:[str]}       -> {links:{mention:[[id,score]]}}
            {entities, text}        -> {spans:[{start,stop,text,entity,score}]}  (spans of `text` naming an entity)
            {schema:[{name,description}], phrases:[str]}                 -> {links:{phrase:[[name,score]]}}
`retrieve`: {passages:[{id,text,source?,facts?,entities?}], entities, question, mentions?, n?} -> {hits:[...]}
`block`:    {entities, mentions, n?}                                     -> {candidates:{mention:[id]}}
Vectors persist in the local store, keyed by content hash and embedder identity."""
import os
import threading

from channels import Reranker
from embedders import Embedder, VectorStore
from hybrid import Index, Passage
from link import EntityLinker, PARAMS, SchemaLinker, candidate_pairs
from spans import linked_spans

HERE = os.path.dirname(os.path.abspath(__file__))
VECTORS = os.environ.get("RETRIEVAL_VECTORS") or os.path.expanduser("~/.cache/avra-graph-ml/vectors.db")

OPS = ("link", "retrieve", "block")


class Retrieval:
    def __init__(self):
        self.embedder, self.reranker, self.store = Embedder(PARAMS["embedder"]), None, None
        self.lock = threading.Lock()

    def ready(self):
        if self.store is None:
            os.environ.setdefault("HF_HUB_OFFLINE", "1")
            self.store = VectorStore(VECTORS)
            self.reranker = Reranker(PARAMS["reranker"])

    def answer(self, body):
        with self.lock:
            self.ready()
            return getattr(self, body["op"])(body)

    def link(self, body):
        if "schema" in body:
            linker = SchemaLinker(body["schema"], self.embedder, self.store)
            return {"links": {p: linker.link(p, int(body.get("n", 3))) for p in body["phrases"]}}
        linker = EntityLinker(body["entities"], self.embedder, self.store)
        if "text" in body:
            return {"spans": linked_spans(linker, body["text"])}
        return {"links": {m: linker.link(m, int(body.get("n", 3))) for m in body["mentions"]}}

    def retrieve(self, body):
        passages = [Passage(p["id"], p["text"], p.get("source"), p.get("facts", ()), p.get("entities", ())) for p in body["passages"]]
        index = Index(passages, body.get("entities", []), self.embedder, self.store, self.reranker)
        return {"hits": index.search(body["question"], body.get("mentions", []), int(body.get("n", 10)))}

    def block(self, body):
        return {"candidates": candidate_pairs(body["mentions"], body["entities"], self.embedder, self.store, body.get("n"))}


_held = None


def answered(body):
    """The answer to a `link`, `retrieve` or `block` op; the models load on first use."""
    global _held
    _held = _held or Retrieval()
    return _held.answer(body)
