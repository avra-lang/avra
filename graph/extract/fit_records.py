"""Fit the per-kind record threshold on invented domains, never on fixtures.

usage: python fit_records.py [--mode choice|yesno] [--kinds N] [--scores OUT.jsonl] [--write PARAMS.json]

choice (the default) fits the pass as built: one closed choice over every offered kind. Each
sentence is offered its own domain's kinds plus kinds of other invented domains, up to N in
all (the deployed schema's kind count, a number and nothing else), so the choice has the width
it has in service. yesno fits the per-kind question instead.

Reads authored invented domains (TUNE_DIR/corpus, default the sibling tune worktree). For each
message sentence and each record kind its domain declares, the kind's closed yes/no
(cascade.record_ask) is scored by the resident model service (AVRA_GRAPH_SOCKET), over the
same bytes the cascade sends. A sentence is positive for a kind when a gold fact of that
kind has its cue inside the sentence. The threshold is the grid value with the best F1 on
the fitting domains; every fourth domain is held out and its F1 reported. Scores are kept
in OUT.jsonl, so a refit costs no model call.
"""
import hashlib
import importlib.util
import json
import os
import socket
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
TUNE = os.environ.get("TUNE_DIR") or os.path.join(HERE, "..", "..", "..", "avra-graph-tune", "graph", "tune")
GRID = [round(0.05 * i, 2) for i in range(1, 20)]
HELD_OUT_EVERY = 4


def tune_module(name):
    spec = importlib.util.spec_from_file_location("tune_" + name, os.path.join(TUNE, name + ".py"))
    m = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = m
    spec.loader.exec_module(m)
    return m


def choose(path, context, question, options):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(path)
        s.sendall((json.dumps({"op": "choose", "context": context, "question": question, "options": options}) + "\n").encode())
        data = b""
        while not data.endswith(b"\n"):
            chunk = s.recv(65536)
            if not chunk:
                break
            data += chunk
    return json.loads(data)["p"]


def sentences(encoder, text):
    """The record pass's units of a message, as the cascade derives them from the encoder."""
    import cascade

    c = cascade.Cascade(cascade.Plan([]), {"statements": encoder.mentions(text, {cascade.STATEMENT: cascade.STATEMENT_GLOSS})}, None)
    c.t, c.frames, c._units = cascade.Text(text), [], None
    out = []
    for a, b in c.units():
        for x, y in c.sub_units(a, b):
            x, y = c.trimmed(x, y)
            if y > x:
                out.append((x, y))
    return out


def rows(corpus):
    """One row per (message sentence, record kind): the question as the cascade asks it, and the gold."""
    import cascade

    encoder = cascade.Encoder()
    try:
        for name, d in corpus.domains().items():
            plan = cascade.Plan(corpus.descriptor(d))
            for m in d["messages"]:
                text = m["text"]
                cues = {}
                for f in m.get("facts", []):
                    cues.setdefault(f["model"], []).append(text.index(f["in"]))
                for a, b in sentences(encoder, text):
                    for kind in plan.records:
                        context, question, options = cascade.record_ask(plan.models[kind], text[a:b])
                        yield {"domain": name, "message": m["id"], "kind": kind, "text": text, "sentence": text[a:b], "context": context,
                               "question": question, "options": options, "gold": any(a <= c < b for c in cues.get(kind, []))}
    finally:
        encoder.close()


def pooled_kinds(corpus):
    """Every (domain, kind, option text) the invented domains declare, as the cascade words an option."""
    import cascade

    out = []
    for name, d in corpus.domains().items():
        plan = cascade.Plan(corpus.descriptor(d))
        out += [(name, k, cascade.FRAMINGS[cascade.RECORD_FRAMING](plan.models[k])) for k in plan.records]
    return out


def ranked(*parts):
    return hashlib.sha256("|".join(parts).encode()).hexdigest()


def choice_rows(base, pool, width):
    """Offer each sentence its own kinds and distractors from other domains, in an order fixed by hash."""
    import cascade

    out = []
    for r in base:
        own = {k for (d, k, _) in pool if d == r["domain"]}
        mine = [(k, o) for (d, k, o) in pool if d == r["domain"]]
        others = sorted(((k, o) for (d, k, o) in pool if d != r["domain"] and k not in own), key=lambda x: ranked(r["domain"], r["message"], r["sentence"], x[1]))
        offered = sorted(mine + others[: max(width - len(mine), 0)], key=lambda x: ranked(r["sentence"], x[1]))
        context, question, options, tail = cascade.kind_choice_ask(r["sentence"], [o for _, o in offered])
        out.append({**r, "context": context, "question": question, "options": options + tail, "kinds": [k for k, _ in offered],
                    "gold": sorted(i for i, (k, _) in enumerate(offered) if k in r["states"])})
    return out


def sentence_rows(base):
    """One row per message sentence, with the kinds its gold facts state there."""
    seen, out = set(), []
    for r in base:
        key = (r["domain"], r["message"], r["sentence"])
        if key not in seen:
            seen.add(key)
            out.append({"domain": r["domain"], "message": r["message"], "text": r["text"], "sentence": r["sentence"],
                        "states": {x["kind"] for x in base if (x["domain"], x["message"], x["sentence"]) == key and x["gold"]}})
    return out


def scored(asked, socket_path, out, mode):
    """Each asked row with its scores; rows already in `out` cost no model call."""
    kept = {}
    if os.path.exists(out):
        kept = {json.loads(l)["key"]: json.loads(l) for l in open(out)}
    with open(out, "a") as f:
        for r in asked:
            key = hashlib.sha256(json.dumps([r["text"], r["context"], r["question"]] + (r["options"] if mode == "choice" else [])).encode()).hexdigest()
            if key not in kept:
                p = choose(socket_path, f'Text: "{r["text"]}"\n\n{r["context"]}', r["question"], r["options"])
                kept[key] = {"key": key, "domain": r["domain"], "kind": r.get("kind"), "gold": r["gold"], "p": p if mode == "choice" else p[0]}
                f.write(json.dumps(kept[key]) + "\n")
                f.flush()
            yield kept[key]


def f1(rs, t):
    tp = sum(r["gold"] and r["p"] >= t for r in rs)
    fp = sum(not r["gold"] and r["p"] >= t for r in rs)
    fn = sum(r["gold"] and r["p"] < t for r in rs)
    return 2 * tp / (2 * tp + fp + fn) if tp else 0.0


def accepted_right(r, t):
    """Taking the leading kind at t is right when it is a gold kind and wrong when it is not; none leading is right when no kind is stated."""
    p = r["p"]
    k = max(range(len(p)), key=lambda i: p[i])
    return not r["gold"] if k == len(p) - 1 else (k in r["gold"]) == (p[k] >= t)


def accuracy(rs, t):
    return sum(accepted_right(r, t) for r in rs) / len(rs)


def split(rs):
    held = {d for i, d in enumerate(sorted({r["domain"] for r in rs})) if i % HELD_OUT_EVERY == HELD_OUT_EVERY - 1}
    return [r for r in rs if r["domain"] not in held], [r for r in rs if r["domain"] in held], held


def fit(rs, mode):
    train, test, held = split(rs)
    score = f1 if mode == "yesno" else accuracy
    t = max(GRID, key=lambda g: (score(train, g), g))
    name = "f1" if mode == "yesno" else "accuracy"
    return t, {f"train_{name}": round(score(train, t), 3), f"held_out_{name}": round(score(test, t), 3), "n_train": len(train), "n_held_out": len(test),
               "positives": sum(bool(r["gold"]) for r in rs), "held_out_domains": sorted(held)}


OBJECTIVE = {"yesno": "F1 of the per-kind yes/no over message sentences, invented domains only (no fixture text)",
             "choice": "record-kind accept accuracy over sentences offered N kinds: the leading kind taken when it is a stated kind, left when it is not; invented domains only (no fixture text)"}
PARAM = {"yesno": "accept_kind_yes", "choice": "accept_record"}


def main():
    args = sys.argv[1:]
    flag = lambda name, default=None: args[args.index(name) + 1] if name in args else default
    mode = flag("--mode", "choice")
    width = int(flag("--kinds", "17"))
    out = flag("--scores", os.path.join(HERE, "bench", f"records.invented.choice.scores.jsonl" if mode == "choice" else "records.invented.scores.jsonl"))
    sock = os.environ.get("AVRA_GRAPH_SOCKET") or os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")
    corpus = tune_module("corpus")
    started = time.time()
    base = list(rows(corpus))
    asked = base if mode == "yesno" else choice_rows(sentence_rows(base), pooled_kinds(corpus), width)
    every = int(flag("--every", "1"))
    asked = [r for r in asked if int(ranked(r["sentence"])[:8], 16) % every == 0]
    rs = list(scored(asked, sock, out, mode))
    t, report = fit(rs, mode)
    print(json.dumps({"mode": mode, "threshold": t, **report, "scored": len(rs), "seconds": round(time.time() - started)}, indent=1))
    if "--write" in args:
        path = flag("--write")
        params = json.load(open(path))
        digest = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
        names = sorted(os.listdir(os.path.join(TUNE, "corpus")))
        entry = {"value": t, "fitted": True, "objective": OBJECTIVE[mode], "granularity": "pooled", **report,
                 "data": {"scores": digest(out), "corpus": hashlib.sha256("".join(digest(os.path.join(TUNE, "corpus", n)) for n in names).encode()).hexdigest(), "domains": len(names)}}
        if mode == "choice":
            entry["kinds_offered"] = width
            entry["sentence_sample"] = f"one in {every}, by hash of the sentence"
            entry["dev_accuracy"] = entry["held_out_accuracy"]
        params["params"][PARAM[mode]] = entry
        params["params"]["fitted_at_records"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
        json.dump(params, open(path, "w"), indent=2)


if __name__ == "__main__":
    main()
