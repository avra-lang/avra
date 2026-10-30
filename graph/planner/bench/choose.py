"""Answer a question by running the declared candidates and choosing between the results.

    python3 graph/planner/bench/choose.py [--asker ID] [--depth N] [--no-choose]

The graph is built from the oracle facts, so extraction is held perfect: this measures the
question side alone. Every candidate is a walk over declared edges out of an entity the
question names, narrowed by the declared values it speaks, and projected on each property its
landing type declares. All of them run; the empty ones go; identical answers are one
behaviour. What is left is answered when there is one, chosen between when there are more,
and declined when there are none.

    answered-correct  the answer is the gold answer
    answered-wrong    a different answer, stated confidently
    declined-correct  gold says there is no answer, and none was produced
    declined-wrong    an answer exists and the run did not find it
"""
import argparse, collections, json, os, pathlib, sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
import cypher_reply  # noqa: E402
import enumerate as bench  # noqa: E402   the graph, the walk and the anchors, once

app, build, ref, iso_ms, values = bench.app, bench.build, bench.ref, bench.iso_ms, bench.values


def row_queries(seed_model, seed_where, edges, models, question):
    """One query per declared walk, answering with the whole record it lands on: a question
    may ask for several fields of one record, and a row is what the gold plans return."""
    out, seen = [], set()
    for steps, landing in [([], seed_model)] + bench.walk(edges, seed_model, bench.DEPTH):
        pattern = f"(a:{seed_model})" + "".join(steps)
        var = f"b{len(steps) - 1}" if steps else "a"
        picks = [p["name"] for p in models[landing]["properties"]]
        ret = ", ".join(f"{var}.{p} AS {p}" for p in picks)
        for prop, value in [(None, None)] + bench.declared_filters(question, models[landing]):
            conds = seed_where if prop is None else f"{seed_where} AND {var}.{prop} = {json.dumps(value)}"
            cy = f"MATCH {pattern} WHERE {conds} RETURN {ret}"
            if cy not in seen:
                seen.add(cy); out.append((cy, landing))
    return out


def options_for(distinct, models):
    """One sentence per distinct ANSWER — a whole result set, because a question may ask for
    several records — worded from the declarations that produced it."""
    out = []
    for answer, (landing, prop) in distinct.items():
        said = ", ".join(str(json.loads(v)) if v[:1] in '[{"' else v for v in answer)
        out.append(f"{said} — the {prop} of a {landing}")
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--asker", default="oracle:rowan")
    parser.add_argument("--depth", type=int, default=3)
    parser.add_argument("--no-choose", action="store_true")
    parser.add_argument("--cache", default=str(HERE / "choose.cache.json"),
                        help="the candidates a question produced, kept so the choice can be iterated")
    args = parser.parse_args()
    bench.DEPTH = args.depth

    schema = app({"op": "schema"})
    bench.CATALOG = schema
    build(schema)
    models = {m["name"]: m for m in schema["models"]}
    edges = bench.graph_of(models)
    manifest = json.load(open(bench.HERE / "acceptance/manifest.json"))
    questions = [json.loads(l) for l in open(bench.HERE / "acceptance/questions.jsonl")]
    plans = {r["question"]: r["cypher"] for r in (json.loads(l) for l in open(bench.ORM / "plans.jsonl")) if "cypher" in r}
    split = set(json.load(open(bench.HERE / "acceptance/split.json"))["heldout"])

    cache = json.loads(pathlib.Path(args.cache).read_text()) if pathlib.Path(args.cache).exists() else {}
    tally, asked = collections.Counter(), []
    for q in questions:
        if q["id"] in split or q["id"] not in plans:
            continue
        ctx = {**manifest["default_context"], **q.get("context", {})}
        bench.PARAMS = {"asker": args.asker, "now": iso_ms(manifest["evaluation_time"]),
                        "speaker": args.asker, "valid_at": iso_ms(q["valid_at"]) if "valid_at" in q else None}
        view = {"as_of": {"valid_at": bench.PARAMS["valid_at"]}} if bench.PARAMS.get("valid_at") else {}
        want = values(app({"op": "query", "cypher": plans[q["id"]], "params": bench.PARAMS, **view}))

        seeds = [(m, f"a.{lab} = $anchor", {"anchor": v}) for m, lab, v in bench.anchors(q["question"], models)]
        holder = app({"op": "get", "id": args.asker})
        if holder.get("model"):
            seeds.append((holder["model"], "id(a) = $asker", {}))

        pool, ran = [], 0
        for model, where, extra in seeds:
            for cy, landing in row_queries(model, where, edges, models, q["question"]):
                pool.append((cy, landing, "row", extra))
        if q["id"] in cache:
            distinct = {tuple(k): tuple(v) for k, v in cache[q["id"]]["distinct"].items()}
            want = cache[q["id"]]["want"]
        else:
            distinct = {}
            for cy, landing, prop, extra in pool:
                ran += 1
                got = tuple(values(app({"op": "query", "cypher": cy, "params": {**bench.PARAMS, **extra}, **view})))
                if got:
                    distinct.setdefault(got, (landing, prop))
            cache[q["id"]] = {"distinct": {json.dumps(list(k)): list(v) for k, v in distinct.items()}, "want": want}
        asked.append((len(pool), ran, len(distinct)))

        covers = [a for a in distinct if want and set(want) <= set(a)]
        if not want:
            outcome = "declined-correct" if not distinct else "answered-wrong"
        elif not covers:
            outcome = "declined-wrong" if not distinct else "answered-wrong"
        elif len(covers) == 1:
            outcome = "answered-correct"
        elif args.no_choose:
            outcome = "answered-wrong"
        else:
            picked = choose(q["question"], options_for({a: distinct[a] for a in covers}, models))
            outcome = "answered-correct" if picked is not None and picked < len(covers) else "answered-wrong"
        tally[outcome] += 1
        print(f"  {q['id']:4s} {outcome:17s} candidates={len(pool):4d} distinct={len(distinct):3d} gold={len(want)}")

    pathlib.Path(args.cache).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(args.cache).write_text(json.dumps(cache))
    n = sum(tally.values())
    print("\n", dict(tally), f"of {n}")
    print(" candidates per question: median", sorted(a[0] for a in asked)[len(asked) // 2],
          "max", max(a[0] for a in asked))
    print(" distinct answers:        median", sorted(a[2] for a in asked)[len(asked) // 2],
          "max", max(a[2] for a in asked))


def choose(question, options):
    """The model's pick among the executed answers, or None when it cannot tell."""
    import socket
    body = {"op": "choose", "context": f'Question: "{question}"',
            "question": "Which of these answers the question?", "options": options}
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(300)
    s.connect(cypher_reply.SOCKET)
    s.sendall((json.dumps(body) + "\n").encode())
    d = b""
    while not d.endswith(b"\n"):
        c = s.recv(65536)
        if not c:
            break
        d += c
    p = json.loads(d).get("p")
    return max(range(len(p)), key=lambda i: p[i]) if p else None


if __name__ == "__main__":
    main()
