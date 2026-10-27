"""Gate 1: how much of an answerable question the declared space answers with no model call.

usage: python3 bench_enum.py [--worlds dev,2 dev,1 ...] [--depth 1]

The engine is correct given the right query (35/36 on the fixtures with gold plans), so the
open question is whether the *declared* space contains that query often enough to enumerate.
For each question this walks declarations only — no model, no gold:

  anchor   an entity whose declared label field the question names, found by string match
           over the world's own records (perfect linking; linking is measured separately)
  paths    the anchor itself, then one declared step: a reference property's edge, or a
           declared relation's own label word, either direction
  answers  every property of the model the path lands on, as its own field in one query

Then it executes them all and asks what the survivors look like against the question's own
gold: is the answer among them at all (coverage), does exactly one candidate carry it (a
zero-call answer), do several (a tie-break call is owed), or none (a decline).
"""
import argparse
import collections
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
GRAPH = HERE.parent
sys.path.insert(0, str(HERE))

from engine import App  # noqa: E402


def is_enum(p):
    return any(rule.startswith("one_of(") for rule in p.get("rules") or [])


def label_field(model):
    """The property a model is named by: its declared label, else its first required text.
    An enum is a narrowing, never a name — a word from its values narrows records, it does
    not identify one."""
    declared = ((model.get("semantics") or {}).get("label") or [None])[0]
    if declared:
        return declared
    for p in model["properties"]:
        if isinstance(p["shape"], str) and p["shape"] == "string" and p.get("default_source") is None and not is_enum(p):
            return p["name"]
    return None


def reference_target(shape):
    """The model a reference shape points at, through optional and list."""
    if not isinstance(shape, dict):
        return None
    inner = shape.get("optional") or shape.get("list")
    if inner is not None:
        return reference_target(inner)
    return shape.get("reference")


def properties(model):
    """The properties a query may read, each named once."""
    return [p["name"] for p in model["properties"]]


def steps_from(name, models):
    """Every declared one-step path out of a model, named: (edge name, target model, form), both ways."""
    model, out = models[name], []
    for p in model["properties"]:
        target = reference_target(p["shape"])
        if target:
            out.append((p["name"], target, "out"))
    for holder, other in models.items():
        rel = (other.get("semantics") or {}).get("relation")
        if not rel:
            continue
        seat = {p["name"]: p for p in other["properties"]}
        ends = [reference_target(seat[rel[side][0]]["shape"]) if rel.get(side) and rel[side][0] in seat else None for side in ("from", "to")]
        if name in ends:
            for value in [v["value"] for v in rel.get("labels") or []]:
                out.append((value, ends[1] if name == ends[0] else ends[0], "out"))
    for other_name, other in models.items():
        if other_name == name:
            continue
        for p in other["properties"]:
            if reference_target(p["shape"]) == name:
                out.append((p["name"], other_name, "in"))
    return out


def projection(model, var="b"):
    """`<var>.<prop> AS <prop>` for every property of the model a path lands on."""
    return ", ".join(f"{var}.{name} AS {name}" for name in properties(model))


def anchor_queries(question, world, models):
    """Every (model, label property, value) the question names, by exact text match."""
    said, found = question.lower(), []
    for vid, instance in world["instances"].items():
        model = models.get(instance["model"])
        if not model:
            continue
        field = label_field(model)
        if not field:
            continue
        for version in instance["versions"][:1]:
            value = version.get(field)
            if isinstance(value, str) and len(value) > 2 and value.lower() in said:
                found.append((instance["model"], field, value))
    return [(m, f, v) for m, f, v in found if not any(m != o and v.lower() in w.lower() and v != w for o, _, w in found)]


def paths(models, model, depth):
    """Every declared chain out of the anchor model, as one MATCH pattern from `(a)`: the
    engine reads a path inline and refuses a second MATCH that returns nothing, so a walk is
    one pattern, not a sequence of them. A model is never revisited on one chain."""
    out = [(f"(a:{model})", model, "a")]

    def walk(here, pattern, seen, left):
        if left == 0:
            return
        for edge, target, form in steps_from(here, models):
            if target in seen:
                continue
            var = f"b{len(seen)}"
            arrow = f"-[:{edge}]->" if form == "out" else f"<-[:{edge}]-"
            chain = f"{pattern}{arrow}({var}:{target})"
            out.append((chain, target, var))
            walk(target, chain, seen | {target}, left - 1)

    walk(model, out[0][0], {model}, depth)
    return out


def candidates(question, world, models, depth):
    """Every query the declarations admit for a question: [(cypher, where it lands, step, anchor)]."""
    out = []
    for model, field, value in anchor_queries(question, world, models):
        for pattern, landed, var in paths(models, model, depth):
            where = f" WHERE a.{field} = $anchor" if var != "a" or True else ""
            query = f"MATCH {pattern}{where} RETURN {projection(models[landed], var)}"
            out.append((query, landed, pattern[len(f'(a:{model})'):][:24] or "anchor", value))
    return out


def stated(answer, anchor):
    """The values a query answered with, one per property: empties and the anchor itself
    dropped, since the thing a question starts from is never its answer."""
    out = {}
    for f in answer.get("fields") or []:
        path = f.get("path") or []
        value = f.get("value")
        if len(path) == 2 and value is not None and value != anchor:
            out[path[1]] = value
    return out


def verdict(item, survivors, golds):
    """What the survivors add up to for one question."""
    hits = [(cypher, name, value) for cypher, name, values in survivors for name, value in values.items() if json.dumps(value, sort_keys=True) in golds]
    if item["gold"]["status"] == "unknown":
        return "declined" if not survivors else "answered-wrongly", hits
    if not survivors:
        return "empty", hits
    if hits and len(survivors) == 1:
        return "one-right", hits
    if hits:
        return "several", hits
    return "wrong", hits


def world_of(family, seed):
    base = GRAPH / "gym" / "out" / family / seed
    catalog = json.loads((base / "catalog.json").read_text())["catalog"]
    return {
        "base": base,
        "models": {m["name"]: m for m in catalog["models"]},
        "world": json.loads((base / "world.json").read_text()),
        "items": json.loads((base / "items.json").read_text()),
        "app": App(base / "app/src/main", base / "graph.db", base / "scratch"),
    }


def measure(selection, depth):
    tally, kinds, queries = collections.Counter(), collections.defaultdict(collections.Counter), 0
    for family, seed in selection:
        one = world_of(family, seed)
        for item in one["items"]:
            asked = candidates(item["question"], one["world"], one["models"], depth)
            survivors = []
            for cypher, landed, name, anchor in asked:
                queries += 1
                values = stated(one["app"].query(cypher, {**item["params"], "anchor": anchor}), anchor)
                if values:
                    survivors.append((cypher, name, values))
            outcome, _ = verdict(item, survivors, item["gold"].get("values") or [])
            tally[outcome] += 1
            kinds[item["kind"]][outcome] += 1
    return tally, kinds, queries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worlds", nargs="*", default=["dev,2", "dev,1"])
    parser.add_argument("--depth", type=int, default=1)
    args = parser.parse_args()
    tally, kinds, queries = measure([tuple(w.split(",")) for w in args.worlds], args.depth)
    total = sum(tally.values())
    covered = tally["one-right"] + tally["several"]
    print(f"{total} questions, {queries} queries, depth {args.depth}")
    print(f"  coverage (the answer is reachable)      {covered:4d}  {covered / total:5.1%}")
    print(f"  zero-call answer (one survivor, right)  {tally['one-right']:4d}  {tally['one-right'] / total:5.1%}")
    for outcome, n in tally.most_common():
        print(f"  {outcome:18s} {n:4d}  {n / total:5.1%}")
    print()
    for kind in sorted(kinds):
        row = kinds[kind]
        print(f"  {kind:12s} " + " ".join(f"{o}={row[o]}" for o in sorted(row)))


if __name__ == "__main__":
    main()
