"""A fact world for one compiled schema, built by walking its catalog: values
come from the declared rules and enums or from pools the generator invents per
property; relations and validity come from the declared bindings."""
import copy
import json
import random

import contam
import times
from cat import Cat, rule_args
from jsonutil import first_json
from skeleton_knobs import KNOBS

JSON_KIND = {"string": str, "integer": int, "number": (int, float), "boolean": bool}


def safe_text(v):
    return isinstance(v, str) and 1 <= len(v) <= 60 and contam.clean(v) and not any(c in v for c in "'\"\\")


def leaf_spec(cat, model, path, shape, optional, prop):
    enc = cat.time_paths(model).get(path)
    quantity = next((q for q in cat.sem(model).get("quantities", []) if tuple(q["amount"]) == path), None)
    return {"path": ".".join(path), "type": shape, "optional": optional, "rules": prop.get("rules", []), "description": prop.get("description", ""),
            **({"time_encoding": enc, "give": "ISO-8601 instants spread over at least two years"} if enc else {}),
            **({"quantity": {"unit": q_unit(quantity), "decimal_places": quantity["decimal_places"]}} if quantity else {})}


def q_unit(q):
    return q["unit"]


def valid_item(spec, v):
    if "time_encoding" in spec:
        return (isinstance(v, str) and _iso(v)) or (spec["time_encoding"] == "unix_millis" and isinstance(v, int) and not isinstance(v, bool) and v > 0)
    if spec["type"] != "boolean" and isinstance(v, bool):
        return False
    if not isinstance(v, JSON_KIND[spec["type"]]):
        return False
    return safe_text(v) if spec["type"] == "string" else True


def _iso(v):
    try:
        times.parse(v)
        return True
    except (ValueError, TypeError):
        return False


def pools(llm, cat, domain, done=None, keep=lambda out: None):
    """{model: {leaf path: [values in the property's own representation]}} invented per model."""
    out = dict(done or {})
    size = KNOBS["pool_size"]
    for model in cat.publishable():
        if model in out:
            continue
        leaves = [(path, shape, opt, prop) for path, shape, opt, prop in cat.leaves(model) if shape != "boolean"]
        specs = [leaf_spec(cat, model, *l) for l in leaves]
        label = cat.label(model)
        if not specs:
            out[model] = {}
            continue
        descriptor = {"model": model, "description": cat.models[model]["description"], "leaves": specs}
        note = ""
        for _ in range(5):
            reply = llm.generate(f"Domain: {domain}\nInvent realistic values for the properties of one kind of record, as one JSON object mapping each leaf path to a list of {size + 4 if label else size} "
                                 f"distinct values of its declared type that satisfy its rules (a label property gets distinct names of individual things; text values are short; "
                                 f"time leaves get ISO-8601 strings).{note}\n{json.dumps(descriptor)}", 3000)
            got = first_json(reply)
            bad = None
            built = {}
            if not isinstance(got, dict):
                bad = "the reply held no JSON object"
            else:
                for spec in specs:
                    items = [v for v in got.get(spec["path"], []) if valid_item(spec, v)]
                    items = list(dict.fromkeys(items))
                    need = 8 if spec["path"] == label else 4
                    if len(items) < need:
                        bad = f"{spec['path']} needs at least {need} valid distinct values"
                        break
                    if "time_encoding" in spec:
                        items = sorted(v if isinstance(v, int) else times.encode(v, spec["time_encoding"]) for v in items)
                    built[spec["path"]] = items
            if not bad:
                out[model] = built
                keep(out)
                break
            note = f"\nYour previous reply was refused: {bad}."
        else:
            raise SystemExit(f"gym: no usable value pools for {model}: {bad}")
    return out


def get_path(value, path):
    for k in path:
        if not isinstance(value, dict) or k not in value:
            return None
        value = value[k]
    return value


def del_path(value, path):
    for k in path[:-1]:
        value = value.get(k, {})
    value.pop(path[-1], None)


def set_path(value, path, v):
    for k in path[:-1]:
        value = value.setdefault(k, {})
    value[path[-1]] = v


class Builder:
    def __init__(self, cat, pool, rng):
        self.cat, self.pool, self.rng = cat, pool, rng
        self.instances = {}
        self.counter = 0
        self.by_model = {}
        self.reserve = {}

    def mint(self):
        self.counter += 1
        return f"i{self.counter}"

    def draw(self, model, prefix, spec_type):
        p = self.pool[model].get(".".join(prefix))
        if p:
            return self.rng.choice(p)
        return {"string": "x", "integer": 1, "number": 1.0, "boolean": self.rng.random() < 0.5}[spec_type]

    def value(self, model, owner_props, prefix, taken):
        """The engine value of a model's properties (an embedded model's, when entered), by declared shape."""
        cat, rng = self.cat, self.rng
        out = {}
        label = cat.label(model) if not prefix else None
        for p in owner_props:
            shape, name = p["shape"], p["name"]
            c = cat.core(shape)
            if cat.optional(shape) and name != label and rng.random() < KNOBS["null_rate"]:
                continue
            if p.get("enum"):
                out[name] = rng.choice(p["enum"])
            elif cat.target(shape):
                target = cat.target(shape)
                options = [i for i in self.by_model.get(target, []) if i not in taken.setdefault(target, set())] or self.by_model.get(target, [])
                if not options:
                    continue
                pick = rng.choice(options)
                taken[target].add(pick)
                out[name] = [pick] if isinstance(c, dict) and "list" in c else pick
            elif isinstance(c, dict) and "embedded" in c:
                out[name] = self.value(model, cat.props(c["embedded"]), prefix + (name,), {})
            elif isinstance(c, dict) and "list" in c:
                inner = cat.core(c["list"])
                out[name] = [self.draw(model, prefix + (name,), inner) for _ in range(rng.randint(1, 3))]
            elif c == "boolean":
                out[name] = rng.random() < 0.5
            else:
                out[name] = self.draw(model, prefix + (name,), c)
        return out

    def populate(self, model):
        cat, rng = self.cat, self.rng
        named = cat.label(model)
        count = rng.randint(*(KNOBS["entities_per_model"] if named else KNOBS["records_per_model"]))
        ids = []
        names = list(self.pool[model].get(named, [])) if named else []
        for k in range(count):
            vid = self.mint()
            value = self.value(model, cat.props(model), (), {})
            if named:
                value[named] = names[k] if k < len(names) else self.draw(model, (named,), "string")
            self.apply_validity(model, value)
            self.instances[vid] = {"model": model, "versions": [value], "changed": None}
            ids.append(vid)
        if named:
            self.reserve[model] = names[count:]
            if model in cat.speakers() and len(ids) >= 3 and rng.random() < KNOBS["same_name_rate"]:
                self.instances[ids[-1]]["versions"][0][named] = self.instances[ids[0]]["versions"][0][named]
        self.by_model[model] = ids

    def apply_validity(self, model, value):
        v = self.cat.validity(model)
        if not v:
            return
        pool_from = self.pool[model].get(".".join(v["from"])) if v.get("from") else None
        pool_until = self.pool[model].get(".".join(v["until"])) if v.get("until") else None
        if not pool_from:
            return
        start = self.rng.choice(pool_from[: max(1, len(pool_from) // 2)])
        set_path(value, v["from"], start)
        if v.get("until"):
            later = [x for x in (pool_until or pool_from) if x > start]
            ended = later and self.rng.random() < 0.3
            if ended:
                set_path(value, v["until"], self.rng.choice(later))
            else:
                del_path(value, v["until"])

    def supersede(self):
        cat, rng = self.cat, self.rng
        for vid, inst in self.instances.items():
            model = inst["model"]
            v = cat.validity(model)
            if not v or not v.get("from") or rng.random() >= KNOBS["supersede_rate"]:
                continue
            first = inst["versions"][0]
            if v.get("until") and get_path(first, v["until"]) is not None:
                continue
            pool_from = self.pool[model].get(".".join(v["from"]), [])
            start = get_path(first, v["from"])
            later = [x for x in pool_from if x > start]
            if not later:
                continue
            new = copy.deepcopy(first)
            options = [p for p in cat.props(model) if p["name"] != v["from"][0] and (v.get("until") is None or p["name"] != v["until"][0]) and p["name"] != cat.label(model) and not p.get("enum")]
            r = cat.relation(model)
            if r:
                options = [p for p in cat.props(model) if p["name"] == r["to"][0]]
            rng.shuffle(options)
            for p in options:
                fresh = self.value(model, [p], (), {})
                if p["name"] in fresh and fresh[p["name"]] != first.get(p["name"]):
                    new[p["name"]] = fresh[p["name"]]
                    inst["changed"] = p["name"]
                    break
            if inst["changed"] is None:
                continue
            set_path(new, v["from"], rng.choice(later))
            inst["versions"].append(new)


def refs_of(cat, model, value):
    out = []
    for name, t in cat.references(model):
        v = value.get(name)
        out += v if isinstance(v, list) else [v] if v else []
    return out


def sources_of(cat, instances, rng):
    """Ordered sources; an instance first appears no earlier than everything it references, and a restatement lands later than its original."""
    count = rng.randint(*KNOBS["sources_per_world"])
    slot = {}
    slots = [[] for _ in range(count)]
    for vid in sorted(instances, key=lambda i: cat.order().index(instances[i]["model"])):
        inst = instances[vid]

        def floor_of(version):
            return max([slot[r] for r in refs_of(cat, inst["model"], version) if r in slot] or [0])

        first = floor_of(inst["versions"][0])
        at = min(first, count - 1)
        at = rng.randint(at, max(at, count - 1 - (len(inst["versions"]) - 1)))
        slot[vid] = at
        slots[at].append((vid, 0))
        keep = 1
        for i in range(1, len(inst["versions"])):
            lo = max(at + 1, floor_of(inst["versions"][i]))
            if lo > count - 1:
                break
            at = rng.randint(lo, count - 1)
            slots[at].append((vid, i))
            keep += 1
        del inst["versions"][keep:]
        if keep == 1:
            inst["changed"] = None
    return [{"id": f"src{k + 1}", "statements": items} for k, items in enumerate(slots) if items]


def make(cat, pool, rng):
    b = Builder(cat, pool, rng)
    for model in cat.order():
        b.populate(model)
    b.supersede()
    world = {"instances": b.instances, "by_model": b.by_model, "reserve": b.reserve}
    world["sources"] = sources_of(cat, b.instances, rng)
    eligible = [i for i, x in b.instances.items() if len(x["versions"]) == 1 and not any(i in refs_of(cat, y["model"], v) for y in b.instances.values() for v in y["versions"])]
    world["tombstones"] = sorted(rng.sample(eligible, min(len(eligible), int(len(b.instances) * KNOBS["tombstone_rate"]))))
    return world
