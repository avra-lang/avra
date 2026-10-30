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
import anchor as anchors_of  # noqa: E402
import cypher_reply  # noqa: E402
import enumerate as bench  # noqa: E402   the graph, the walk and the anchors, once

app, build, ref, iso_ms, values = bench.app, bench.build, bench.ref, bench.iso_ms, bench.values


WORD = __import__("re").compile(r"[A-Za-z][A-Za-z'-]{3,}")


def content_words(question):
    """The words a question carries that could name a value: no list decides, the text does."""
    return [w for w in dict.fromkeys(WORD.findall(question))]


def text_props(models, model):
    """The declared text properties of a model: a value written in words."""
    out = []
    for p in models[model]["properties"]:
        shape = p["shape"]
        inner = (shape.get("optional") or shape.get("list") or shape) if isinstance(shape, dict) else shape
        if inner == "string" and not p.get("enum") and not p.get("time"):
            out.append(p["name"])
    return out


def row_queries(seed_model, seed_where, edges, models, question, budget, phase="all"):
    """Every declared walk answering with the whole record it lands on, then each walk's
    narrowings. A question may ask for several fields of one record, so a row is the unit.

    The walks come first because they are the axis a budget must not starve: every walk is
    tried plainly, and only then is any walk narrowed — by a declared enum value the question
    speaks, or by one of its words against a declared text field of the record the answer
    comes from or the record it hangs off. The order is fixed, so a question's cost is bounded
    and nothing about the corpus decides it."""
    words = content_words(question)
    walks, seen, out = [], set(), []
    for steps, landing in [([], seed_model)] + bench.walk(edges, seed_model, bench.DEPTH):
        pattern = f"(a:{seed_model})" + "".join(steps)
        var = f"b{len(steps) - 1}" if steps else "a"
        nodes = [(var, landing)]
        if steps:
            made = __import__("re").findall(r"\(b\d+:(\w+)\)", "".join(steps))
            nodes += [(f"b{len(steps) - 2}", made[-2])] if len(made) >= 2 else [("a", seed_model)]
        ret = ", ".join(f"{var}.{p['name']} AS {p['name']}" for p in models[landing]["properties"])
        walks.append((pattern, var, landing, nodes, ret))

    def emit(conds, landing):
        cy = f"MATCH {pattern} WHERE {' AND '.join(conds)} RETURN {ret}"
        if cy not in seen and len(out) < budget:
            seen.add(cy)
            out.append((cy, landing))
        return len(out) >= budget

    if phase in ("all", "plain"):
        for pattern, var, landing, nodes, ret in walks:        # every walk, plainly
            if emit([seed_where], landing):
                return out, True
    if phase == "plain":
        return out, False
    for pattern, var, landing, nodes, ret in walks:            # then its narrowings
        for prop, value in bench.declared_filters(question, models[landing]):
            if emit([seed_where, f"{var}.{prop} = {json.dumps(value)}"], landing):
                return out, True
        for node, model in nodes:
            for prop in text_props(models, model):
                for word in words:
                    if emit([seed_where, f"{node}.{prop} CONTAINS {json.dumps(word)}"], landing):
                        return out, True
    return out, False


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
    parser.add_argument("--coverage", type=float, default=0.6, help="share of a value's words a question must carry to name it")
    parser.add_argument("--budget", type=int, default=400, help="queries a question may run")
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
    # a read needs the bindings the graph requires; the index is one read per declared text property
    index_params = {"asker": args.asker, "now": iso_ms(manifest["evaluation_time"]), "speaker": args.asker}
    value_index = anchors_of.index(models, lambda cy: app({"op": "query", "cypher": cy, "params": index_params}))
    print(f"anchor index: {len(value_index)} declared text values")
    questions = [json.loads(l) for l in open(bench.HERE / "acceptance/questions.jsonl")]
    plans = {r["question"]: r["cypher"] for r in (json.loads(l) for l in open(bench.ORM / "plans.jsonl")) if "cypher" in r}
    split = set(json.load(open(bench.HERE / "acceptance/split.json"))["heldout"])

    cache = json.loads(pathlib.Path(args.cache).read_text()) if pathlib.Path(args.cache).exists() else {}
    tally, asked, reach = collections.Counter(), [], 0
    for q in questions:
        if q["id"] in split or q["id"] not in plans:
            continue
        ctx = {**manifest["default_context"], **q.get("context", {})}
        bench.PARAMS = {"asker": args.asker, "now": iso_ms(manifest["evaluation_time"]),
                        "speaker": args.asker, "valid_at": iso_ms(q["valid_at"]) if "valid_at" in q else None}
        view = {"as_of": {"valid_at": bench.PARAMS["valid_at"]}} if bench.PARAMS.get("valid_at") else {}
        want = values(app({"op": "query", "cypher": plans[q["id"]], "params": bench.PARAMS, **view}))

        seeds = [(m, f"a.{prop} = $anchor", {"anchor": value})
                 for m, prop, value in anchors_of.named(q["question"], value_index, args.coverage)]
        holder = app({"op": "get", "id": args.asker})
        if holder.get("model"):
            seeds.append((holder["model"], "id(a) = $asker", {}))

        pool, ran, caps = [], 0, 0
        # every anchor contributes its plain walks before any anchor narrows one, so a budget
        # cannot starve an anchor: the first phase is bounded by the schema, the second by it
        for model, where, extra in seeds:
            made, _ = row_queries(model, where, edges, models, q["question"], 10_000, phase="plain")
            pool += [(cy, landing, "row", extra) for cy, landing in made]
        room = max(0, args.budget - len(pool))
        share = max(1, room // max(1, len(seeds)))
        for model, where, extra in seeds:
            made, capped = row_queries(model, where, edges, models, q["question"], share, phase="narrow")
            pool += [(cy, landing, "row", extra) for cy, landing in made]
            caps += capped
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
        reach += 1 if covers else 0
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
        print(f"  {q['id']:4s} {outcome:17s} candidates={len(pool):4d} distinct={len(distinct):3d} covers={len(covers):2d} gold={len(want)}"
              + ("  (budget hit)" if caps else ""))

    pathlib.Path(args.cache).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(args.cache).write_text(json.dumps(cache))
    n = sum(tally.values())
    print("\n", dict(tally), f"of {n}", f"| reachable {reach}")
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
