"""Local embedders behind one shape: `Embedder.encode(texts, role)` answers
unit-length float32 rows. A role is `query` or `document`; each model declares
its own prompt per role. `identity` names the model, revision and prompts, so
a stored vector is reusable exactly when the identity matches."""
import hashlib
import os
import sqlite3

import numpy as np

os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))

BGE_QUERY = "Represent this sentence for searching relevant passages: "
QWEN_TASK = "Instruct: Given a question, retrieve the passage that answers it\nQuery: "

# model id -> (query prompt, document prompt, backend)
MODELS = {
    "BAAI/bge-small-en-v1.5": (BGE_QUERY, "", "st"),
    "BAAI/bge-base-en-v1.5": (BGE_QUERY, "", "st"),
    "google/embeddinggemma-300m": ("task: search result | query: ", "title: none | text: ", "st"),
    "mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ": (QWEN_TASK, "", "mlx"),
}


class Embedder:
    def __init__(self, model_id):
        self.model_id = model_id
        self.query_prompt, self.document_prompt, self.backend = MODELS[model_id]
        self.identity = f"{model_id}|q={self.query_prompt}|d={self.document_prompt}"
        self._model = None

    def _load(self):
        if self._model is not None:
            return
        if self.backend == "st":
            from sentence_transformers import SentenceTransformer

            self._model = SentenceTransformer(self.model_id, device="cpu")
        else:
            os.environ.setdefault("HF_HUB_OFFLINE", "1")
            from mlx_lm import load

            self._model = load(self.model_id)

    def encode(self, texts, role="document"):
        self._load()
        prompt = self.query_prompt if role == "query" else self.document_prompt
        texts = [prompt + t for t in texts]
        if self.backend == "st":
            return np.asarray(self._model.encode(texts, normalize_embeddings=True, batch_size=16), dtype=np.float32)
        import mlx.core as mx

        model, tok = self._model
        rows = []
        for text in texts:
            state = model.model(mx.array(tok.encode(text))[None])[0, -1].astype(mx.float32)
            rows.append(np.asarray(state / mx.sqrt((state * state).sum())))
        mx.clear_cache()
        return np.asarray(rows, dtype=np.float32)


class VectorStore:
    """Vectors keyed by content hash and embedder identity, in a local SQLite
    file: embedding a text again is a lookup, and a changed text or embedder
    is a new key."""

    def __init__(self, path):
        self.db = sqlite3.connect(path)
        self.db.execute("CREATE TABLE IF NOT EXISTS vec (hash TEXT, embedder TEXT, role TEXT, dim INTEGER, v BLOB, PRIMARY KEY (hash, embedder, role))")

    @staticmethod
    def key(text):
        return hashlib.sha256(text.encode()).hexdigest()

    def encode(self, embedder, texts, role="document"):
        keys = [self.key(t) for t in texts]
        found = {}
        for k in set(keys):
            row = self.db.execute("SELECT dim, v FROM vec WHERE hash=? AND embedder=? AND role=?", (k, embedder.identity, role)).fetchone()
            if row:
                found[k] = np.frombuffer(row[1], dtype=np.float32)
        missing = list(dict.fromkeys(t for t, k in zip(texts, keys) if k not in found))
        if missing:
            for t, v in zip(missing, embedder.encode(missing, role)):
                found[self.key(t)] = v
                self.db.execute("INSERT OR REPLACE INTO vec VALUES (?,?,?,?,?)", (self.key(t), embedder.identity, role, len(v), v.tobytes()))
            self.db.commit()
        self.hits = len(texts) - len(missing)
        return np.stack([found[k] for k in keys]) if texts else np.zeros((0, 0), dtype=np.float32)
