"""The catalog the compiler emits (the graph's `schema` op), read generically:
shapes, rules, bindings and edges come from the declarations, never from a
list of kinds."""
import re


class Cat:
    def __init__(self, schema):
        self.schema = schema
        self.models = {m["name"]: m for m in schema["models"]}
        self.embedded = {t for m in schema["models"] for p in m["properties"] for t in embedded_in(p["shape"])}

    # ---- shapes
    @staticmethod
    def core(shape):
        while isinstance(shape, dict) and "optional" in shape:
            shape = shape["optional"]
        return shape

    @staticmethod
    def optional(shape):
        return isinstance(shape, dict) and "optional" in shape

    def kind(self, shape):
        c = self.core(shape)
        return c if isinstance(c, str) else next(iter(c))

    def target(self, shape):
        """The model a reference points at, through optional and list wrappers."""
        c = self.core(shape)
        if isinstance(c, dict) and "list" in c:
            c = self.core(c["list"])
        return c.get("reference") if isinstance(c, dict) else None

    def props(self, model):
        return self.models[model]["properties"]

    def prop(self, model, name):
        return next(p for p in self.props(model) if p["name"] == name)

    # ---- semantics
    def sem(self, model):
        return self.models[model]["semantics"]

    def label(self, model):
        label = self.sem(model).get("label")
        return label[0] if label else None

    def relation(self, model):
        return self.sem(model).get("relation")

    def validity(self, model):
        return self.sem(model).get("validity")

    def quantities(self, model):
        """{top-level amount property: binding}."""
        return {q["amount"][0]: q for q in self.sem(model).get("quantities", []) if len(q["amount"]) == 1}

    def time_paths(self, model):
        """{path tuple: encoding}: time-bound properties and the validity bounds."""
        out = {(t["path"][0],): t["encoding"] for t in self.sem(model).get("times", [])}
        v = self.validity(model)
        if v:
            for end in ("from", "until"):
                if v.get(end):
                    out[tuple(v[end])] = v["encoding"]
        for p in self.props(model):
            if p.get("time"):
                out[(p["name"],)] = p["time"]["encoding"]
        return out

    def absences(self, model):
        return {a["path"][0]: a["code"] for a in self.sem(model).get("absences", []) if len(a["path"]) == 1}

    def publishable(self):
        return [n for n in self.models if n not in self.embedded]

    def named(self):
        return [n for n in self.publishable() if self.label(n)]

    def speakers(self):
        """Models that stand at the subject end of a relation binding."""
        out = []
        for n in self.publishable():
            r = self.relation(n)
            if r and len(r["from"]) == 1:
                t = self.target(self.prop(n, r["from"][0])["shape"])
                if t and t not in out:
                    out.append(t)
        return out

    def references(self, model):
        return [(p["name"], self.target(p["shape"])) for p in self.props(model) if self.target(p["shape"])]

    def order(self):
        """Publishable models, targets before the models that reference them."""
        done, out = set(), []

        def visit(n, trail=()):
            if n in done or n in trail:
                return
            for _, t in self.references(n):
                if t in self.models and t not in self.embedded:
                    visit(t, trail + (n,))
            done.add(n)
            out.append(n)

        for n in self.publishable():
            visit(n)
        return out

    def leaves(self, model):
        """Scalar leaves as (path tuple, shape core, optional?): enum and reference leaves excluded, embedded models entered."""
        out = []

        def walk(m, prefix):
            for p in self.props(m):
                c = self.core(p["shape"])
                path = prefix + (p["name"],)
                if isinstance(c, dict) and "embedded" in c:
                    walk(c["embedded"], path)
                elif isinstance(c, dict) and "list" in c:
                    inner = self.core(c["list"])
                    if isinstance(inner, str):
                        out.append((path, inner, self.optional(p["shape"]), p))
                elif isinstance(c, str) and not p.get("enum"):
                    out.append((path, c, self.optional(p["shape"]), p))
        walk(model, ())
        return out

    # ---- edges
    def edges(self, here):
        """Hops a node of this model can take, with the pattern word and its direction."""
        out = []
        for owner in self.publishable():
            for name, t in self.references(owner):
                if owner == here and t in self.models:
                    out.append({"to": t, "arrow": "out", "word": name, "via": "reference", "owner": owner})
                if t == here and not self.relation(owner):
                    out.append({"to": owner, "arrow": "in", "word": name, "via": "reference", "owner": owner})
            r = self.relation(owner)
            if r and len(r["from"]) == 1 and len(r["to"]) == 1:
                sub = self.target(self.prop(owner, r["from"][0])["shape"])
                obj = self.target(self.prop(owner, r["to"][0])["shape"])
                for l in r["labels"]:
                    for w in [l["value"], *l["forward"]]:
                        if here == sub:
                            out.append({"to": obj, "arrow": "out", "word": w, "via": "relation", "owner": owner, "label": l["value"], "reverse_word": False})
                        if here == obj:
                            out.append({"to": sub, "arrow": "in", "word": w, "via": "relation", "owner": owner, "label": l["value"], "reverse_word": False})
                    for w in l["reverse"]:
                        if here == obj:
                            out.append({"to": sub, "arrow": "out", "word": w, "via": "relation", "owner": owner, "label": l["value"], "reverse_word": True})
                        if here == sub:
                            out.append({"to": obj, "arrow": "in", "word": w, "via": "relation", "owner": owner, "label": l["value"], "reverse_word": True})
        seen, unique = set(), []
        for e in out:
            key = (e["to"], e["arrow"], e["word"], e["owner"])
            if key not in seen:
                seen.add(key)
                unique.append(e)
        return unique


def embedded_in(shape):
    if isinstance(shape, dict):
        if "embedded" in shape:
            yield shape["embedded"]
        for part in shape.values():
            yield from embedded_in(part)


def rule_args(rule):
    """('range', {'min': 1, 'max': 9}) from a rule's declared text, for rules written name(key: value, ...)."""
    m = re.match(r"(\w+)\((.*)\)$", rule.strip())
    if not m:
        return rule, {}
    args = {}
    for k, v in re.findall(r"(\w+):\s*(-?\d+)", m.group(2)):
        args[k] = int(v)
    return m.group(1), args
