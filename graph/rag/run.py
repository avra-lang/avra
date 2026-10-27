"""A plain-RAG baseline on the acceptance questions, graded by score.grade.

usage: python run.py [--k N | --fill] [--only q01,q02] [--out runs/NAME.json]
Per question: the sources up to its checkpoint (each with its observation,
revision and received time) are indexed with the hybrid retrieval (BM25 +
dense + rerank, no walk); the top passages go to the shared model with the
catalog's declared record kinds, and it answers records with source ids or
declines. No graph, no extraction, no per-kind prompt: one prompt for every
question. `--fill` keeps ranked passages while the model's declared context
holds them; `--k N` keeps N."""
import argparse
import json
import os
import pathlib
import re
import socket
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(ROOT / "acceptance"))
sys.path.insert(0, str(ROOT / "retrieval"))
sys.path.insert(0, str(ROOT / "planner"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")

import score  # noqa: E402
from prompt import declared_context, line  # noqa: E402

SOCKET = pathlib.Path(os.environ.get("RAG_SOCKET") or pathlib.Path.home() / ".cache/avra-graph-ml/cascade.sock")
MODEL = "mlx-community/Qwen3-4B-Instruct-2507-4bit"
HUB = pathlib.Path.home() / ".cache/avra-graph-ml/hf/hub"


def asked(body):
    with socket.socket(socket.AF_UNIX) as s:
        s.settimeout(900)
        s.connect(str(SOCKET))
        s.sendall((json.dumps(body) + "\n").encode())
        data = b""
        while not data.endswith(b"\n"):
            chunk = s.recv(65536)
            if not chunk:
                break
            data += chunk
    answer = json.loads(data)
    if "error" in answer:
        raise RuntimeError(answer["error"])
    return answer


def shape_words(shape):
    if isinstance(shape, str):
        return shape
    (kind, inner), = shape.items()
    return {"optional": f"{shape_words(inner)} or absent", "list": f"list of {shape_words(inner)}",
            "reference": f"the name of a {inner}", "embedded": f"a {inner} value"}.get(kind, f"{kind} {inner}") if kind in ("optional", "list", "reference", "embedded") else f"{kind} {inner}"


def catalog_text(schema):
    out = []
    for m in schema["models"]:
        fields = "; ".join(f"{p['name']} ({shape_words(p['shape'])})" + (f": {line(p['description'])}" if p.get("description") else "") for p in m["properties"])
        out.append(f"{m['name']}: {line(m.get('description', ''))}\n  fields: {fields}")
    return "\n".join(out)


def label_of(model):
    path = ((model.get("semantics") or {}).get("label")) or []
    if len(path) == 1:
        return path[0]
    return next((p["name"] for p in model["properties"] if p["shape"] == "string"), None)


def passage_text(s):
    return f"[{s['id']} | {s['observation']} revision {s['revision']} | received {s['received_at']} | author {s['author']}]\n{s['content']}"


def instructions(schema, labels, context):
    who = labels.get(context["principal"], context["principal"])
    speaker = labels.get(context.get("speaker") or context["principal"], context.get("speaker"))
    when = f" The question concerns {context['valid_at']}." if context.get("valid_at") else ""
    return (
        "Answer the question using only the passages. The record kinds below are the vocabulary of an answer.\n\n"
        f"{catalog_text(schema)}\n\n"
        f"The question is asked by {who} (speaking as {speaker}); the current time is {context['now']}.{when} "
        "'My' refers to the speaker.\n\n"
        'Reply with one JSON object and nothing else: {"status": "answered" | "unknown" | "ambiguous" | "refused", '
        '"records": [{"kind": <record kind>, "fields": {<field>: <value>}}], "sources": [<ids of the passages the answer rests on>], '
        '"reason": <why, when not answered>}. A reference field holds the name of the thing referred to; an embedded value is a JSON object of its fields; '
        "dates are ISO 8601; a count is a number; a truth is true or false. Answer \"unknown\" when the passages do not establish the answer; "
        '"ambiguous" when several readings fit; "refused" when the passages forbid answering. When a later revision of a passage replaces an earlier one, rely on the later.')


def parse(text):
    start = text.find("{")
    depth = 0
    for i in range(start, len(text)) if start >= 0 else []:
        depth += text[i] == "{"
        depth -= text[i] == "}"
        if depth == 0:
            try:
                return json.loads(text[start:i + 1])
            except json.JSONDecodeError:
                return None
    return None


def as_answer(reply, sources, models):
    """The grader's answer shape from the model's reply: one field per record field, rooted at the record's label."""
    by_id = {s["id"]: s for s in sources}
    cited = [by_id[i] for i in reply.get("sources", []) if i in by_id]
    citations = [{"id": f"c{n}", "source": {"observation": s["observation"], "revision": s["revision"]}} for n, s in enumerate(cited)]
    ids = [c["id"] for c in citations]
    fields = []
    for r in reply.get("records") or []:
        model = models.get(r.get("kind"), {})
        body = r.get("fields") or {}
        root = body.get(label_of(model)) if model else None
        root = root if isinstance(root, str) else json.dumps(body, sort_keys=True)
        for name, value in body.items():
            fields.append({"path": [root, name], "value": value, "citations": ids})
    status = reply.get("status") if reply.get("status") in ("answered", "unknown", "ambiguous", "refused") else "unknown"
    out = {"status": status, "fields": fields, "citations": citations, "candidates": [], "conflicts": [], "policies": [], "absent": []}
    if status != "answered" and reply.get("reason"):
        out["absent"] = [{"code": str(reply["reason"]), "path": [""]}]
    return out


class Names(dict):
    """The grader's identity join for text answers: a name that is one entity's label (or a word-subset of exactly one) is that gold id."""

    def __init__(self, entities):
        super().__init__()
        self.labels = {e["id"]: e["label"] for e in entities}

    def get(self, value, default=None):
        words = set(re.findall(r"\w+", str(value).lower()))
        if not words or ":" in str(value):
            return default
        hits = [i for i, l in self.labels.items() if words <= set(re.findall(r"\w+", l.lower()))]
        return hits[0] if len(hits) == 1 else default


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--k", type=int)
    ap.add_argument("--fill", action="store_true")
    ap.add_argument("--only")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    score.configure((ROOT / "acceptance").resolve())
    manifest, sources, entities, questions = score.load_fixture()
    schema = json.load(open(HERE / "runs" / "schema.json"))
    models = {m["name"]: m for m in schema["models"]}
    labels = {e["id"]: e["label"] for e in entities}
    readings = {r["question"]: r["keys"] for r in score.oracle_readings()}
    only = set(a.only.split(",")) if a.only else None
    questions = [q for q in questions if q["split"] == "development" and (not only or q["id"] in only)]

    from embedders import Embedder, VectorStore
    from channels import Reranker
    from hybrid import Index, Passage
    from link import PARAMS

    emb, store, reranker = Embedder(PARAMS["embedder"]), VectorStore(os.path.expanduser("~/.cache/avra-graph-ml/vectors.db")), Reranker(PARAMS["reranker"])
    budget = declared_context(MODEL, HUB)
    names = Names(entities)
    rows = {}
    for q in questions:
        started = time.time()
        prefix = score.prefix_of(sources, q["checkpoint"])
        by_ref = {(s["observation"], s["revision"]): s["id"] for s in prefix}
        latest = {}
        for s in prefix:
            latest[s["observation"]] = s["id"]
        superseded = {s["id"] for s in prefix if latest[s["observation"]] != s["id"]}
        base = {**manifest["default_context"], **q.get("context", {})}
        context = {"principal": base["principal"], "speaker": base.get("speaker"), "now": manifest["evaluation_time"], "valid_at": q.get("valid_at")}
        index = Index([Passage(s["id"], passage_text(s), s["id"]) for s in prefix], [], emb, store, reranker, {**PARAMS, "rerank_depth": len(prefix)})
        ranked = [h["passage"] for h in index.search(q["question"], [], len(prefix))]
        head = instructions(schema, labels, context)
        picked, used = [], len(head) + len(q["question"])
        for pid in ranked:
            text = passage_text(next(s for s in prefix if s["id"] == pid))
            if (a.k and len(picked) >= a.k) or (a.fill and budget and used + len(text) > budget - 4096):
                break
            picked.append(pid)
            used += len(text)
        shown = [s for s in prefix if s["id"] in picked]
        shown.sort(key=lambda s: picked.index(s["id"]))
        user = head + "\n\nPassages:\n\n" + "\n\n".join(passage_text(s) for s in shown) + f"\n\nQuestion: {q['question']}"
        try:
            reply_text = asked({"op": "generate", "messages": [{"role": "user", "content": user}]})["text"]
            reply = parse(reply_text) or {"status": "unknown", "reason": "unparseable"}
            answer = as_answer(reply, prefix, models)
            verdict = score.grade(q, answer, names, by_ref, superseded, readings.get(q["id"]))
            rows[q["id"]] = {"status": "pass" if all(verdict.values()) else "fail", **verdict, "got": answer["status"], "passages": picked,
                             "reply": reply_text, "ms": int((time.time() - started) * 1000)}
        except Exception as error:
            rows[q["id"]] = {"status": "error", "reason": f"{type(error).__name__}: {error}"}
        print(q["id"], rows[q["id"]]["status"], rows[q["id"]].get("answer"), rows[q["id"]].get("provenance"), rows[q["id"]].get("abstention"), flush=True)
        json.dump({"k": a.k, "fill": a.fill, "rows": rows}, open(a.out, "w"), indent=1)
    cats = json.load(open(ROOT / "acceptance" / "split.json"))["categories"]
    by = {}
    for qid, r in rows.items():
        by.setdefault(cats.get(qid, "?"), []).append(r["status"] == "pass")
    print("total", sum(r["status"] == "pass" for r in rows.values()), "of", len(rows))
    for c, v in sorted(by.items()):
        print(f"  {c}: {sum(v)}/{len(v)}")


if __name__ == "__main__":
    main()
