"""Does the model write queries that answer the questions it was trained on the *kind* of?

    AVRA_GRAPH_SOCKET=<socket> python3 graph/planner/bench/in_domain.py [--worlds train/101 ...]

The gym's own question/query/gold items, on worlds held out of training, in the same run's
own bindings. A schema from the same generator is the in-domain test; the acceptance fixture
is the transfer test, and the two answer different questions.

Counts are legal (the engine accepts the query) and correct (its rows are the item's gold).
"""
import argparse, collections, json, pathlib, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent
GRAPH = HERE.parent.parent
sys.path.insert(0, str(HERE.parent))
import cypher_prompt, cypher_reply  # noqa: E402

HELD = ["train/101", "train/107", "train/122"]


def app(world, body):
    base = GRAPH / "gym" / "out" / world
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(body, f)
        path = f.name
    out = subprocess.run([str(base / "app/src/main"), "request", "--db", str(base / "graph.db"), path],
                         capture_output=True, text=True, timeout=120)
    pathlib.Path(path).unlink()
    try:
        return json.loads(out.stdout)
    except json.JSONDecodeError:
        return {"error": (out.stderr or out.stdout)[:200]}


def values(answer):
    return sorted({json.dumps(f["value"], sort_keys=True) for f in answer.get("fields", []) if "terms" not in f.get("path", [])})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worlds", nargs="*", default=HELD)
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()

    tally, reasons = collections.Counter(), collections.Counter()
    for world in args.worlds:
        base = GRAPH / "gym" / "out" / world
        catalog = json.loads((base / "catalog.json").read_text()).get("catalog") or {}
        schema = {"models": catalog.get("models", []), "derivations": catalog.get("derivations", [])}
        items = [i for i in json.loads((base / "items.json").read_text()) if i.get("cypher")]
        if args.limit:
            items = items[: args.limit]
        for item in items:
            params, as_of = item.get("params") or {}, item.get("as_of")
            view = {"as_of": as_of} if as_of else {}
            gold = sorted(item["gold"].get("values") or [])
            reply = cypher_reply.ask(cypher_prompt.ask(item["question"], schema))
            query = cypher_reply.desugar(cypher_reply.clean(reply))
            check = app(world, {"op": "check", "cypher": query, "params": params})
            legal = check.get("ok") is True
            correct = False
            if legal:
                got = values(app(world, {"op": "query", "cypher": query, "params": params, **view}))
                correct = bool(gold) and got == gold
            else:
                reasons[check.get("code")] += 1
            tally["legal" if legal else "illegal"] += 1
            tally["correct" if correct else ("legal-wrong" if legal else "no-query")] += 1
            print(f"  {world:10s} {'LEGAL ' if legal else 'illegal'} {'CORRECT' if correct else '':8s} {item['question'][:58]}")
    print("\n", dict(tally))
    print(" refusal codes:", dict(reasons))


if __name__ == "__main__":
    main()
