"""Corpus: one (prompt, completion) pair per gym item, generated from the plan that made it.

    python3 graph/planner/train/pairs.py [--out PATH] [--families train]

The gym already samples a plan over an invented schema, executes it for the gold rows and
renders the question from the plan — so a pair is a projection of the plan, never a written
example. The prompt comes from `planner/cypher_prompt.py`, the same bytes the measurement in
`planner/bench/llm_cypher.py` sends, so an adapter is trained on what it is judged by.

The gold rows travel beside each pair: a query that does not re-execute to them is a gap in
the language, not training data, and the refusal it makes is what says which gap.
"""
import argparse, glob, json, pathlib, sys

HERE = pathlib.Path(__file__).resolve().parent.parent
GRAPH = HERE.parent
sys.path.insert(0, str(HERE))
import cypher_prompt  # noqa: E402


def world(path):
    return json.loads(pathlib.Path(path).read_text())


def pairs(families):
    """(world, seed, item, prompt) for every item that has a query, in a stable order."""
    out = []
    for path in sorted(glob.glob(str(GRAPH / "gym" / "out" / "*" / "*" / "items.json"))):
        family, seed = pathlib.PurePath(path).parts[-3], pathlib.PurePath(path).parts[-2]
        if family not in families:
            continue
        catalog = world(pathlib.Path(path).parent / "catalog.json").get("catalog") or {}
        schema = {"models": catalog.get("models", []), "derivations": catalog.get("derivations", [])}
        for item in world(path):
            if not item.get("cypher"):
                continue
            out.append({"world": f"{family}/{seed}", "family": family, "id": item.get("id") or item["question"][:40],
                        "prompt": cypher_prompt.ask(item["question"], schema),
                        "completion": item["cypher"],
                        "gold": item["gold"].get("values") or [], "kind": item.get("kind"),
                        "intent": item.get("intent"), "steps": item.get("steps"),
                        # the run's own bindings, so a pair can be re-executed and judged
                        "params": item.get("params") or {}, "as_of": item.get("as_of")})
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default=str(HERE / "bench" / "cypher.pairs.jsonl"))
    parser.add_argument("--families", nargs="*", default=["train"])
    args = parser.parse_args()
    made = pairs(set(args.families))
    out = pathlib.Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(json.dumps(p) for p in made) + "\n")
    by = {}
    for p in made:
        by[p["family"]] = by.get(p["family"], 0) + 1
    print(json.dumps({"pairs": len(made), "by_family": by, "worlds": len({p['world'] for p in made}),
                      "out": str(out), "bytes": out.stat().st_size}, indent=1))


if __name__ == "__main__":
    main()
