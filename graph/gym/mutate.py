"""Minimal edits of a plan's structured steps: the rivals a question must beat.
Every edit is generic over step fields: a literal swapped for another value
of the same property, a step dropped, a time moved, the asked property changed."""
import copy
import json

import times

LITERAL_KEYS = ("equals", "value")


def values_of(cat, world, model, prop):
    out = []
    for x in world["instances"].values():
        if x["model"] == model and prop in x["versions"][-1]:
            out.append(x["versions"][-1][prop])
    return out


def shown(cat, model, prop, v):
    enc = cat.time_paths(model).get((prop,))
    return times.day(v, enc) if enc else v


def literal_edits(plan, cat, world, rng):
    out = []
    for i, step in enumerate(plan["steps"]):
        body = next(iter(step.values()))
        if not isinstance(body, dict):
            continue
        key = next((k for k in LITERAL_KEYS if k in body), None)
        prop = body.get("property")
        if key is None or prop is None or "model" not in body:
            continue
        pool = [shown(cat, body["model"], prop, v) for v in values_of(cat, world, body["model"], prop)]
        pool = [v for v in dict.fromkeys(pool) if v != body[key] and isinstance(v, type(body[key]))]
        if not pool:
            continue
        new = copy.deepcopy(plan["steps"])
        next(iter(new[i].values()))[key] = rng.choice(pool)
        out.append(("literal", new))
    return out


def drop_edits(plan):
    out = []
    for i, step in enumerate(plan["steps"]):
        kind = next(iter(step))
        if kind in ("filter", "hop", "time") and len(plan["steps"]) > 2:
            out.append(("drop_" + kind, plan["steps"][:i] + plan["steps"][i + 1:]))
    return out


def time_edits(plan, rng):
    out = []
    for i, step in enumerate(plan["steps"]):
        if "time" in step:
            day = step["time"].rsplit(" ", 1)[-1]
            moved = times.shift(times.encode(day + "T00:00:00Z", "unix_millis"), "unix_millis", rng.choice([-120, -45, 45, 120]))
            new = copy.deepcopy(plan["steps"])
            new[i]["time"] = "as it stood on " + times.day(moved, "unix_millis")
            out.append(("time", new))
    return out


def ask_edits(plan, cat):
    out = []
    for i, step in enumerate(plan["steps"]):
        body = step.get("ask")
        if body and "property" in body and "model" in body:
            others = [p for p in cat.props(body["model"]) if p["name"] != body["property"] and not cat.target(p["shape"])]
            for p in others[:1]:
                new = copy.deepcopy(plan["steps"])
                new[i]["ask"]["property"] = p["name"]
                new[i]["ask"]["means"] = p.get("description", "")
                out.append(("ask", new))
    return out


def rivals(plan, cat, world, rng, want=3):
    """Up to `want` distinct minimal edits of the plan, each a different kind where possible; (kind, steps) pairs."""
    gold = json.dumps(plan["steps"])
    pool = literal_edits(plan, cat, world, rng) + drop_edits(plan) + time_edits(plan, rng) + ask_edits(plan, cat)
    rng.shuffle(pool)
    out, seen = [], {gold}
    for kind in dict.fromkeys(k for k, _ in pool):
        for k, steps in pool:
            s = json.dumps(steps)
            if k == kind and s not in seen:
                seen.add(s)
                out.append((k, steps))
                break
    return out[:want]
