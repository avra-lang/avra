"""Shortlist the record kinds a sentence may state, and fit how many to offer.

usage: python fit_shortlist.py recall         rank the offered kinds per sentence by `link` (needs the encoder's python)
       python fit_shortlist.py score          score every variant through the service (choice over the top k, yes/no on the top k)
       python fit_shortlist.py fit [--write PARAMS.json]    the table, and the winner into the parameters

The sentences are those of fit_records.py --mode choice (invented domains, one in three by hash), each
offered its own domain's kinds plus distractors up to the deployed width. A variant is judged on the
sentence's real gold: the kind taken (the leader at or above the threshold) is right when it is a stated
kind, nothing taken is right when none is stated. Thresholds are fitted on the fitting domains; every
fourth domain is held out. Scores are kept in bench/shortlist.scores.jsonl.
"""
import hashlib
import json
import os
import socket
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fit_records as fr  # noqa: E402

ROWS = os.path.join(HERE, "bench", "shortlist.invented.jsonl")
SCORES = os.path.join(HERE, "bench", "shortlist.scores.jsonl")
KS = (2, 3, 5, 8)
YESNO_KS = (3, 5)
WIDTH = 17


SOCKET = os.environ.get("AVRA_GRAPH_SOCKET") or os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")


def service(body):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKET)
        s.sendall((json.dumps(body) + "\n").encode())
        data = b""
        while not data.endswith(b"\n"):
            data += s.recv(65536)
    return json.loads(data)


def sampled(every=3):
    import cascade

    corpus = fr.tune_module("corpus")
    base = list(fr.rows(corpus))
    pool = fr.pooled_kinds(corpus, cascade.RECORD_FRAMING)
    return [r for r in fr.choice_rows(fr.sentence_rows(base), pool, WIDTH) if int(fr.ranked(r["sentence"])[:8], 16) % every == 0]


def ranked_kinds(sentence, wording, ask):
    """Offered kind indexes, best first, by `link` over the kinds' wording."""
    schema = [{"name": f"k{i}", "description": w} for i, w in enumerate(wording)]
    links = ask({"op": "link", "schema": schema, "phrases": [sentence], "n": len(schema)})["links"][sentence]
    return [int(n[1:]) for n, _ in links]


def recall(rows, order, ks=KS):
    """Share of stated kinds within each row's top k."""
    pairs = [(o, g) for r, o in zip(rows, order) for g in r["gold"]]
    return {k: round(sum(o.index(g) < k for o, g in pairs) / len(pairs), 3) for k in ks}


def taken(scores, kinds, t):
    """The kind taken from per-kind scores (the leader at or above t), or None."""
    best = max(range(len(scores)), key=lambda i: scores[i])
    return kinds[best] if scores[best] >= t else None


def right(taken_kind, gold):
    return taken_kind in gold if gold else taken_kind is None


def variant_rows(r, k):
    """The kinds a variant offers: the top k in the order they were offered."""
    return sorted(r["order"][:k])


def shortlisted_choice(row, k):
    import cascade

    kinds = variant_rows(row, k)
    context, question, options, tail = cascade.kind_choice_ask(row["sentence"], [row["options"][i] for i in kinds])
    return kinds, context, question, options + tail


def asks_of(r):
    """Every closed question a row's variants put: (variant, kinds, context, question, options)."""
    import cascade

    asks = []
    for k in KS:
        kinds, context, question, options = shortlisted_choice(r, k)
        asks.append((f"choice{k}", kinds, context, question, options))
    for k in YESNO_KS:
        for i in variant_rows(r, k):
            context, question, options = cascade.yesno_ask(r["options"][i], r["sentence"])
            asks.append((f"yesno{k}:{i}", [i], context, question, options))
    return asks


def score(rows):
    kept = {json.loads(l)["key"] for l in open(SCORES)} if os.path.exists(SCORES) else set()
    with open(SCORES, "a") as f:
        for r in rows:
            for name, kinds, context, question, options in asks_of(r):
                key = hashlib.sha256(json.dumps([r["sid"], name]).encode()).hexdigest()
                if key not in kept:
                    p = fr.choose(SOCKET, f'Text: "{r["text"]}"\n\n{context}', question, options)
                    f.write(json.dumps({"key": key, "sid": r["sid"], "variant": name, "kinds": kinds, "p": p}) + "\n")
                    f.flush()


def decisions(rows, scored):
    """{variant: [(domain, gold, scores per offered kind, kinds)]} with a choice's scores cut to its kinds (none dropped)."""
    by = {}
    for line in scored:
        by.setdefault(line["sid"], {})[line["variant"]] = line
    out = {}
    for r in rows:
        mine = by.get(r["sid"], {})
        for k in KS:
            v = mine.get(f"choice{k}")
            if v:
                out.setdefault(f"choice over top {k}", []).append((r["domain"], r["gold"], v["p"], v["kinds"] + [None]))
        for k in YESNO_KS:
            ps = [(i, mine[f"yesno{k}:{i}"]["p"][0]) for i in variant_rows(r, k) if f"yesno{k}:{i}" in mine]
            if len(ps) == k:
                out.setdefault(f"yes/no over top {k}", []).append((r["domain"], r["gold"], [p for _, p in ps], [i for i, _ in ps]))
    return out


def accuracy(items, t):
    return sum(right(taken(scores, kinds, t), gold) for _, gold, scores, kinds in items) / len(items)


def fit_table(rows):
    scored = [json.loads(l) for l in open(SCORES)]
    table = []
    for name, items in decisions(rows, scored).items():
        held = {d for i, d in enumerate(sorted({x[0] for x in items})) if i % fr.HELD_OUT_EVERY == fr.HELD_OUT_EVERY - 1}
        train, test = [x for x in items if x[0] not in held], [x for x in items if x[0] in held]
        t = max(fr.GRID, key=lambda g: (accuracy(train, g), g))
        calls = 1 if name.startswith("choice") else int(name.split()[-1])
        table.append({"variant": name, "threshold": t, "train": round(accuracy(train, t), 3), "held_out": round(accuracy(test, t), 3), "n": len(items), "calls_per_sentence": calls})
    return table


def winner(table):
    """Best held-out accuracy; fewer calls per sentence on a tie."""
    return max(table, key=lambda x: (x["held_out"], -x["calls_per_sentence"]))


def main():
    mode = sys.argv[1]
    if mode == "recall":
        rows = sampled()
        with open(ROWS, "w") as f:
            for r in rows:
                order = ranked_kinds(r["sentence"], r["options"][:-1], service)
                f.write(json.dumps({"sid": fr.ranked(r["domain"], r["message"], r["sentence"]), "domain": r["domain"], "text": r["text"], "sentence": r["sentence"],
                                    "options": r["options"][:-1], "order": order, "gold": r["gold"]}) + "\n")
        done = [json.loads(l) for l in open(ROWS)]
        print(json.dumps({"stated_kinds": sum(len(r["gold"]) for r in done), "sentences": len(done), "recall_at": recall(done, [r["order"] for r in done], KS + (WIDTH,))}))
        return
    rows = [json.loads(l) for l in open(ROWS)]
    if mode == "score":
        score(rows)
        return
    table = fit_table(rows)
    best = winner(table)
    print(json.dumps({"table": table, "winner": best}, indent=1))
    if "--write" in sys.argv:
        path = sys.argv[sys.argv.index("--write") + 1]
        params = json.load(open(path))
        digest = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
        data = {"rows": digest(ROWS), "scores": digest(SCORES)}
        k = int(best["variant"].split()[-1])
        yesno = best["variant"].startswith("yes/no")
        params["params"]["record_shortlist_k"] = {"value": k, "fitted": True, "objective": "held-out accuracy of the kind taken per sentence (a stated kind right, nothing taken right when none is stated); fewer calls on a tie",
                                                  "table": table, "recall_at": recall(rows, [r["order"] for r in rows], KS + (WIDTH,)), "data": data}
        params["params"]["record_mode"] = {"value": "yesno" if yesno else "choice", "fitted": True, "objective": "same table", "data": data}
        key = "accept_kind_yes" if yesno else "accept_record"
        params["params"][key] = {**params["params"][key], "value": best["threshold"], "fitted": True, "objective": "same table", "held_out_accuracy": best["held_out"], "granularity": "pooled",
                                 "data": {**params["params"][key].get("data", {}), **data, "corpus": params["params"]["accept_record"]["data"]["corpus"]}}
        json.dump(params, open(path, "w"), indent=2)


if __name__ == "__main__":
    main()
