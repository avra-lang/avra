"""Which local embedding model routes a phrase to its declared model best.

usage: python bench_embed.py MODEL_ID CATALOG_JSON [probe.jsonl]
Each probe phrase has a gold model name; documents are the catalog's own
model descriptions. Prints top-1/top-3 accuracy, load and per-batch time,
peak RSS. One model per process.
"""
import json
import os
import resource
import sys
import time

os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))

# Qwen3-Embedding wants an instruction on the query side only.
QUERY_PROMPTS = {"Qwen/Qwen3-Embedding-0.6B": "Instruct: Given a phrase from a personal note, find the record type that stores it\nQuery: "}


def main():
    model_id, catalog = sys.argv[1], json.load(open(sys.argv[2]))
    probe = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(__file__), "bench", "embed_probe.jsonl")
    rows = [json.loads(l) for l in open(probe)]
    docs = [m for m in catalog["models"] if m["description"]]
    from sentence_transformers import SentenceTransformer

    t = time.time()
    model = SentenceTransformer(model_id, device="cpu")
    load_s = time.time() - t
    t = time.time()
    dv = model.encode([f"{m['name']}: {m['description']}" for m in docs], normalize_embeddings=True, batch_size=16)
    docs_s = time.time() - t
    prefix = QUERY_PROMPTS.get(model_id, "")
    t = time.time()
    qv = model.encode([prefix + r["phrase"] for r in rows], normalize_embeddings=True, batch_size=32)
    query_s = time.time() - t
    top1 = top3 = 0
    for r, q in zip(rows, qv):
        ranked = sorted(range(len(docs)), key=lambda i: -float(q @ dv[i]))
        names = [docs[i]["name"] for i in ranked]
        top1 += names[0] == r["model"]
        top3 += r["model"] in names[:3]
        if names[0] != r["model"]:
            print(f"  miss {r['phrase']!r}: gold {r['model']}, got {names[:3]}", file=sys.stderr)
    n = len(rows)
    print(json.dumps({
        "model": model_id, "dims": int(dv.shape[1]), "probes": n, "docs": len(docs),
        "top1": round(top1 / n, 3), "top3": round(top3 / n, 3),
        "load_s": round(load_s, 1), "docs_s": round(docs_s, 2), "query_ms_each": round(1000 * query_s / n, 1),
        "maxrss_mb": round(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1e6),
    }))


if __name__ == "__main__":
    main()
