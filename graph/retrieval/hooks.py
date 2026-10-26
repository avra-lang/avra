"""What the planner asks of the retrieval ops, through the model service its
chooser already holds. Each function answers nothing when the chooser reaches
no service, so a planner without one behaves as before."""
import json
import os

PARAMS = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "params.json")))


def service(chooser):
    """The object under `chooser` that speaks to the socket (`asked`), or None."""
    seen = 0
    while chooser is not None and not hasattr(chooser, "asked") and seen < 8:
        chooser, seen = getattr(chooser, "base", None), seen + 1
    return chooser


SOCKET = os.path.expanduser("~/.cache/avra-graph-ml/retrieval.sock")


def asked(chooser, body):
    """The op's answer from the retrieval socket when something answers there, else from the
    service the chooser holds (a service that predates the op refuses it: no answer); None when neither answers."""
    import socket

    if os.path.exists(SOCKET):
        with socket.socket(socket.AF_UNIX) as s:
            try:
                s.connect(SOCKET)
            except OSError:
                s = None
            if s:
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
    svc = service(chooser)
    if svc is None:
        return None
    try:
        return svc.asked(body)
    except SystemExit:
        return None


def near_facts(chooser, question, facts):
    """Facts (model, property, value) whose value the question names without spelling
    it exactly: a nickname, a misspelling, a short form. Values link as entities of
    their model; a span of the question over the fitted threshold names one."""
    if not facts:
        return []
    values = list(dict.fromkeys((m, v) for m, _, v in facts))
    entities = [{"id": str(i), "name": v, "kind": m} for i, (m, v) in enumerate(values)]
    answer = asked(chooser, {"op": "link", "entities": entities, "text": question})
    if answer is None:
        return []
    spans = answer["spans"]
    named = {values[int(s["entity"])] for s in spans}
    return [f for f in facts if (f[0], f[2]) in named]


def agreement(chooser, question, support, passages, entities=(), mentions=()):
    """The independent evidence check: retrieve over `passages` and report which of
    the plan's `support` ids (passage, fact or source ids) the hybrid ranking holds
    in its top `rerank_depth`. Answers {"agree": share held, "held": [...], "hits": [...]},
    or None when no service answers."""
    answer = asked(chooser, {"op": "retrieve", "passages": passages, "entities": list(entities), "question": question,
                             "mentions": list(mentions), "n": PARAMS["rerank_depth"]}) if support else None
    if answer is None:
        return None
    hits = answer["hits"]
    seen = {h["passage"] for h in hits} | {f for h in hits for f in h["facts"]} | {h["source"] for h in hits if h["source"]}
    held = [s for s in support if s in seen]
    return {"agree": len(held) / len(support), "held": held, "hits": hits}
