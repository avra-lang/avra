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

MODELS_KEPT, PROPERTIES_KEPT = 4, 3


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
            if isinstance(value, str) and len(value) >= 2 and value.lower() in said:
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


def declared_values(model):
    """Every value a model's enum properties declare, with the property that holds it."""
    return [(p["name"], value) for p in model["properties"] for value in p.get("enum") or []]


def numbers_in(question):
    """The numbers a question writes, as integers."""
    out = []
    for word in question.replace(",", " ").split():
        digits = "".join(c for c in word if c.isdigit())
        if digits and len(digits) <= 9:
            out.append(int(digits))
    return out


def quantity_amount(model):
    """The property a model's declared quantity reads its amount from, for a sum."""
    for q in (model.get("semantics") or {}).get("quantities") or []:
        amount = q.get("amount") or []
        if len(amount) == 1:
            return amount[0]
    return None


def family_queries(question, models):
    """The query families that name no entity: the model itself, a declared enum value it holds
    (taken or refused), a count over it, a sum of its declared quantity, and a numeric bound the
    question writes on a declared number property."""
    out, said = [], question.lower()
    sums = numbers_in(question)
    for name, model in models.items():
        out.append((f"MATCH (a:{name}) RETURN {projection(model, 'a')}", name, "model", {}))
        out.append((f"MATCH (a:{name}) RETURN count(a) AS count", name, "count", {}))
        amount = quantity_amount(model)
        if amount:
            out.append((f"MATCH (a:{name}) RETURN sum(a.{amount}) AS total", name, f"sum {amount}", {}))
        for prop, value in declared_values(model):
            if value.lower() in said:
                for operator, form in (("=", "eq"), ("<>", "not")):
                    out.append((f"MATCH (a:{name}) WHERE a.{prop} {operator} $value RETURN {projection(model, 'a')}", name, f"{prop} {form} {value}", {"value": value}))
        for p in model["properties"]:
            if isinstance(p["shape"], str) and p["shape"] in ("integer", "number"):
                for n in sums:
                    for operator in (">", "<"):
                        out.append((f"MATCH (a:{name}) WHERE a.{p['name']} {operator} $number RETURN {projection(model, 'a')}", name, f"{p['name']} {operator} {n}", {"number": n}))
    return out


def candidates(question, world, models, depth):
    """Every query the declarations admit for a question: [(cypher, where it lands, step, anchor)]."""
    out = []
    for model, field, value in anchor_queries(question, world, models):
        for pattern, landed, var in paths(models, model, depth):
            where = f" WHERE a.{field} = $anchor" if var != "a" or True else ""
            query = f"MATCH {pattern}{where} RETURN {projection(models[landed], var)}"
            out.append((query, landed, pattern[len(f'(a:{model})'):][:24] or "anchor", {"anchor": value}))
    return out + family_queries(question, models)


def schema_ranks(models, question, retrieval):
    """The declared things a question's own wording ranks nearest, per kind: the pruner the
    enumerator leans on, since execution can only score what it was handed."""
    import link

    def top(kind, items, n):
        ranked = link.SchemaLinker(items, retrieval.embedder, retrieval.store).link(question, n)
        return {name.split("/", 1)[1] for name, _ in ranked}

    return (
        top("model", [{"name": f"model/{n}", "description": first_sentence(m.get("description"))} for n, m in models.items()], MODELS_KEPT),
        top("property", [{"name": f"property/{n}.{p['name']}", "description": p["name"].replace("_", " ") + ", a " + n} for n, m in models.items() for p in m["properties"]], PROPERTIES_KEPT),
    )


def first_sentence(description):
    """A declaration's first sentence, its wrapped lines joined."""
    import re

    text = " ".join((description or "").split())
    end = re.search(r"[.!?](\s|$)", text)
    return text[: end.end()].strip() if end else text


def stated(answer, anchor, label=None):
    """The values a query answered with, one per property, with whether the answer cites
    anything: empties and the anchor itself dropped, since the thing a question starts from
    is never its answer, and an uncited value is a hole rather than evidence."""
    out, records = {}, {f["path"][0] for f in answer.get("fields") or [] if f.get("path")}
    for f in answer.get("fields") or []:
        path = f.get("path") or []
        value = f.get("value")
        if len(path) != 2 or value is None:
            continue
        if path[1] == label and value == anchor:
            continue
        out[path[1]] = (value, bool(f.get("citations")))
    return out, max(1, len(records))


def corpus_of(base):
    """The world's own sources, one passage each, as the retrieval layer reads them."""
    texts = json.loads((base / "texts.json").read_text())
    return [{"id": each, "text": body["text"]} for each, body in texts.items() if body.get("text")]


def grounded(value, passages):
    """Whether a value's own words appear in the passages a question retrieves: an answer the
    text never says is a wrong join, however well it cites the record it was read from."""
    said = json.dumps(value, sort_keys=True).strip('"') if not isinstance(value, str) else value
    if isinstance(value, (dict, list)):
        said = " ".join(str(v) for v in (value.values() if isinstance(value, dict) else value))
    said = str(said).strip().strip('"')
    return bool(said) and len(said) > 2 and any(said.lower() in p.lower() for p in passages)


def asked_property(item):
    """The property the gold plan asks for, read from its steps. Used to bound a measurement
    (what the space reaches once the property is chosen), never to answer a question."""
    for step in item.get("steps") or []:
        ask = step.get("ask")
        if ask and ask.get("property"):
            return f"{ask.get('model')}.{ask.get('property')}"
    return None


def verdict(item, survivors, golds, passages=()):
    """What the survivors add up to for one question. A value votes once per path that reaches
    it, weighted by how narrowly that path was drawn — a scan of a whole model votes for
    everything and so votes for nothing — and only when the retrieved text says it."""
    votes = collections.Counter()
    for cypher, _, values, records in survivors:
        for value, is_cited in values.values():
            if is_cited and (not passages or grounded(value, passages)):
                votes[json.dumps(value, sort_keys=True)] += 1 / records
    reached = {json.dumps(value, sort_keys=True) for _, _, values, _ in survivors for value, _ in values.values()}
    hits = [name for _, name, values, _ in survivors for value, _ in values.values() if json.dumps(value, sort_keys=True) in golds]
    if item["gold"]["status"] == "unknown":
        return "declined" if not votes else "answered-wrongly", hits
    if not survivors:
        return "empty", hits
    if not votes:
        return "uncited", hits
    best = votes.most_common()
    agreed = len(best) == 1 or best[0][1] > best[1][1]
    if agreed and best[0][0] in golds:
        return "one-right", hits
    return ("several" if reached & set(golds) else "wrong"), hits


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


def measure(selection, depth, retrieval=None, oracle_property=False):
    tally, kinds, queries = collections.Counter(), collections.defaultdict(collections.Counter), 0
    for family, seed in selection:
        one = world_of(family, seed)
        for item in one["items"]:
            asked = candidates(item["question"], one["world"], one["models"], depth)
            kept_models, kept_properties = schema_ranks(one["models"], item["question"], retrieval) if retrieval else (set(one["models"]), set())
            if oracle_property:
                wanted = asked_property(item)
                kept_properties = {wanted} if wanted else set()
            survivors = []
            for cypher, landed, name, extra in asked:
                if landed not in kept_models:
                    continue
                queries += 1
                values, records = stated(
                    one["app"].query(cypher, {**item["params"], **extra}),
                    extra.get("anchor", ""),
                    label_field(one["models"][landed]),
                )
                values = {k: v for k, v in values.items() if f"{landed}.{k}" in kept_properties} if kept_properties else values
                if values:
                    survivors.append((cypher, name, values, records))
            first = corpus_of(one["base"])
            passages = [p["text"] for p in first] if not retrieval else [p for p in (first and [x["text"] for x in retrieval.retrieve({"passages": first, "question": item["question"], "n": 5})["hits"]])]
            outcome, _ = verdict(item, survivors, item["gold"].get("values") or [], passages)
            tally[outcome] += 1
            kinds[item["kind"]][outcome] += 1
    return tally, kinds, queries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worlds", nargs="*", default=["dev,2", "dev,1"])
    parser.add_argument("--depth", type=int, default=1)
    parser.add_argument("--prune", action="store_true", help="keep only what the schema link ranks nearest")
    parser.add_argument("--oracle-property", action="store_true", help="bound the measurement: keep only the property the gold plan asks for")
    args = parser.parse_args()
    retrieval = None
    if args.prune:
        sys.path.insert(0, str(GRAPH / "retrieval"))
        import service

        retrieval = service.Retrieval()
        retrieval.ready()
    tally, kinds, queries = measure([tuple(w.split(",")) for w in args.worlds], args.depth, retrieval if args.prune else None, args.oracle_property)
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
