"""Executable plans over a compiled catalog, in the planner's own representation
(a Cypher-subset query, its parameters and the read's valid-time view), each
with the structured steps a question is rendered from. Operators are read from
the query grammar's declaration and tried against the engine; a plan keeps only
if the real engine answers it the way its kind intends, and that answer is the
label."""
import json
import pathlib
import re

import times
from cat import Cat
from skeleton_knobs import KNOBS

GRAPH = pathlib.Path(__file__).resolve().parent.parent
SCALAR = ("string", "integer", "number", "boolean")


def operators():
    """Comparison tokens the query grammar declares, plus its text-search and null tests."""
    text = (GRAPH / "src/query/cypher.av").read_text()
    body = text[text.index("fn comparison_word"):]
    body = body[: body.index("\n}\n")]
    ops = re.findall(r'"([<>=]+)" ->', body)
    if '"CONTAINS"' in text:
        ops.append("CONTAINS")
    if "IsNull" in text:
        ops.append("IS NULL")
    return ops


def lit(v):
    return str(v).lower() if isinstance(v, bool) else str(v) if isinstance(v, (int, float)) else "'" + str(v) + "'"


def token_of(value):
    """The longest alphanumeric run of a text value."""
    runs = re.findall(r"[^\W_]{3,}", str(value))
    return max(runs, key=len) if runs else None


class Chain:
    def __init__(self):
        self.nodes, self.edges, self.where, self.steps, self.anchors, self.literals = [], [], {}, [], [], []
        self.speaker = None
        self.cur = set()
        self.avoid = set()

    def pattern(self, cat):
        out = f"(n0:{self.nodes[0]})"
        for k, e in enumerate(self.edges, 1):
            node = f"(n{k}:{self.nodes[k]})"
            out += f"-[:{e['word']}]->{node}" if e["arrow"] == "out" else f"<-[:{e['word']}]-{node}"
        return out

    def cypher(self, cat, returns):
        w = [c for k in sorted(self.where) for c in self.where[k]]
        return f"MATCH {self.pattern(cat)}" + (" WHERE " + " AND ".join(w) if w else "") + f" RETURN {returns}"


class Sampler:
    def __init__(self, cat, world, app, rng, now, principal=None):
        self.cat, self.world, self.app, self.rng, self.now = cat, world, app, rng, now
        self.ops = operators()
        speakers = [i for i, x in world["instances"].items() if x["model"] in cat.speakers()]
        self.principal = principal or (speakers[0] if speakers else next(iter(world["instances"])))

    # ---- reading the world
    def current(self, model):
        return [x["versions"][-1] for x in self.world["instances"].values() if x["model"] == model]

    def values(self, model, name):
        return [v[name] for v in self.current(model) if name in v and v[name] is not None]

    def count(self, cypher, params=None):
        got = self.app.query(cypher, {"asker": self.principal, "now": self.now, **(params or {})})
        if got.get("status") != "answered" or not got.get("fields"):
            return None
        return got["fields"][0]["value"]

    def scalar_props(self, model):
        return [p for p in self.cat.props(model) if self.cat.kind(p["shape"]) in SCALAR and not self.cat.target(p["shape"])]

    def means(self, model, prop):
        enc = self.cat.time_paths(model).get((prop["name"],))
        return {"property": prop["name"], "means": prop.get("description", ""), **({"time_encoding": enc} if enc else {}),
                **({"allowed": prop["enum"]} if prop.get("enum") else {})}

    def shown(self, model, name, v):
        enc = self.cat.time_paths(model).get((name,))
        return times.day(v, enc) if enc else v

    def literal_for(self, model, name, v):
        enc = self.cat.time_paths(model).get((name,))
        if enc:
            return {"date": times.day(v, enc)}
        return {"number": v} if isinstance(v, (int, float)) and not isinstance(v, bool) else {"text": str(v)}

    # ---- pieces
    def start(self, ch, model=None, speaker=False):
        cat, rng = self.cat, self.rng
        model = model or rng.choice(cat.named())
        ch.nodes.append(model)
        if speaker and model in cat.speakers():
            ch.where.setdefault(0, []).append("id(n0) = $speaker")
            ch.speaker = self.principal if self.world["instances"][self.principal]["model"] == model else next(
                i for i, x in self.world["instances"].items() if x["model"] == model)
            ch.cur = {ch.speaker}
            ch.steps.append({"start": {"model": model, "means": cat.models[model]["description"], "the_asker": True}})
            return
        ident = rng.choice(self.world["by_model"][model])
        name = self.world["instances"][ident]["versions"][0][cat.label(model)]
        ch.where.setdefault(0, []).append(f"n0.{cat.label(model)} = {lit(name)}")
        ch.steps.append({"start": {"model": model, "means": cat.models[model]["description"], "property": cat.label(model), "equals": name}})
        ch.anchors.append(name)
        ch.cur = {i for i in self.world["by_model"][model] if self.world["instances"][i]["versions"][-1].get(cat.label(model)) == name}

    def neighbors(self, vids, e):
        """Instances one hop reaches from the given instances, read off the world."""
        cat, inst = self.cat, self.world["instances"]
        out = set()
        for vid in vids:
            if e["via"] == "reference" and e["arrow"] == "out":
                v = inst[vid]["versions"][-1].get(e["word"])
                out |= set(v if isinstance(v, list) else [v] if v else [])
            elif e["via"] == "reference":
                for oid, x in inst.items():
                    if x["model"] == e["owner"]:
                        v = x["versions"][-1].get(e["word"])
                        if vid in (v if isinstance(v, list) else [v]):
                            out.add(oid)
            else:
                r = cat.relation(e["owner"])
                near_prop, far_prop = (r["from"][0], r["to"][0]) if (e["arrow"] == "out") != e["reverse_word"] else (r["to"][0], r["from"][0])
                for x in inst.values():
                    if x["model"] == e["owner"]:
                        v = x["versions"][-1]
                        if v.get(near_prop) == vid and v.get(r["label"][0]) == e["label"] and v.get(far_prop):
                            out.add(v[far_prop])
        return {i for i in out if i in inst}

    def hop_step(self, e, here):
        cat = self.cat
        base = {"from_model": here, "to_model": e["to"]}
        if e["via"] == "reference":
            return {"hop": {**base, "through_property": e["word"], "property_owner": e["owner"],
                            "direction": "the property holds the reference" if e["arrow"] == "out" else "walk back to the records holding the reference"}}
        r = cat.relation(e["owner"])
        return {"hop": {**base, "relation_record": e["owner"], "sentence_form": r["phrasing"], "label": e["label"], "word_used": e["word"],
                        "word_is_reverse_form": e["reverse_word"], "known_side": "subject" if e["arrow"] == ("out" if not e["reverse_word"] else "in") else "object"}}

    def walk(self, ch, hops):
        cat = self.cat
        for _ in range(hops):
            here = ch.nodes[-1]
            options = [e for e in cat.edges(here) if e["to"] in cat.models and not cat.relation(e["to"]) and
                       not (ch.edges and e["word"] == ch.edges[-1]["word"] and e["to"] == ch.nodes[-2])]
            if ch.cur:
                options = [e for e in options if self.neighbors(ch.cur, e)]
            if not options:
                return
            e = self.rng.choice(options)
            if ch.cur:
                ch.cur = self.neighbors(ch.cur, e)
            ch.steps.append(self.hop_step(e, here))
            ch.edges.append(e)
            ch.nodes.append(e["to"])

    def ask_column(self, ch, prop=None):
        cat = self.cat
        model = ch.nodes[-1]
        props = [p for p in cat.props(model) if not cat.target(p["shape"]) and p["name"] not in ch.avoid]
        if len(ch.nodes) == 1 and cat.label(model):
            props = [p for p in props if p["name"] != cat.label(model)]
        prop = prop or self.rng.choice(props or [p for p in cat.props(model) if not cat.target(p["shape"])])
        ch.steps.append({"ask": {"model": model, **self.means(model, prop)}})
        return prop

    def filter_on(self, ch, k):
        model = ch.nodes[k]
        cands = self.scalar_props(model)
        self.rng.shuffle(cands)
        total = len(self.current(model))
        for prop in cands[: KNOBS["relations_probe_limit"]]:
            pool = self.values(model, prop["name"])
            if not pool:
                continue
            v = self.rng.choice(pool)
            op = self.rng.choice(self.ops)
            if op == "IS NULL":
                cond, shown, literal = f"n{k}.{prop['name']} IS NULL", None, None
            elif op == "CONTAINS":
                tok = token_of(v) if isinstance(v, str) and not prop.get("enum") else None
                if not tok:
                    continue
                cond, shown, literal = f"n{k}.{prop['name']} CONTAINS {lit(tok.lower())}", tok.lower(), {"text": tok.lower()}
            else:
                cond, shown, literal = f"n{k}.{prop['name']} {op} {lit(v)}", self.shown(model, prop["name"], v), self.literal_for(model, prop["name"], v)
            hit = self.count(f"MATCH (n0:{model}) WHERE {cond.replace(f'n{k}', 'n0')} RETURN count(n0) AS c")
            if not hit or hit >= total + 1 and op != "IS NULL":
                continue
            ch.where.setdefault(k, []).append(cond)
            ch.avoid.add(prop["name"])
            ch.steps.append({"filter": {"model": model, **self.means(model, prop), "operator": op, **({"value": shown} if shown is not None else {})}})
            if literal:
                ch.literals.append(literal)
            return True
        return False

    # ---- plan kinds
    def finish(self, ch, kind, returns, tags, valid_at=None, intent="answer"):
        steps = list(ch.steps)
        params = {"asker": ch.speaker or self.principal, "now": self.now}
        if ch.speaker:
            params["speaker"] = ch.speaker
        as_of = None
        if valid_at is not None:
            as_of = {"valid_at": times.ENCODE["iso_instant"](times.decode(valid_at, "unix_millis"))}
            steps.append({"time": "as it stood on " + times.day(valid_at, "unix_millis")})
        return {"kind": kind, "intent": intent, "cypher": ch.cypher(self.cat, returns), "params": params, "as_of": as_of, "speaker": ch.speaker,
                "steps": steps, "anchors": list(ch.anchors), "literals": list(ch.literals), "hops": len(ch.edges), "tags": tags}

    def lookup(self):
        ch = Chain()
        self.start(ch)
        prop = self.ask_column(ch)
        return self.finish(ch, "lookup", f"n0.{prop['name']} AS value", ["lookup"])

    def hop(self):
        ch = Chain()
        self.start(ch, speaker=self.rng.random() < 0.25)
        self.walk(ch, self.rng.randint(1, KNOBS["max_hops"]))
        if not ch.edges:
            return None
        prop = self.ask_column(ch)
        return self.finish(ch, "hop", f"n{len(ch.edges)}.{prop['name']} AS value", ["hop"])

    def anchored_or_open(self, ch):
        if self.rng.random() < 0.5:
            self.start(ch)
            self.walk(ch, self.rng.randint(1, 2))
            return bool(ch.edges)
        ch.nodes.append(self.rng.choice([m for m in self.cat.publishable() if not self.cat.label(m)] or self.cat.publishable()))
        return True

    def filtered(self):
        ch = Chain()
        if not self.anchored_or_open(ch):
            return None
        k = len(ch.edges)
        if not self.filter_on(ch, k):
            return None
        prop = self.ask_column(ch)
        return self.finish(ch, "filter", f"n{k}.{prop['name']} AS value", ["filter"])

    def aggregate(self):
        ch = Chain()
        if not self.anchored_or_open(ch):
            return None
        k = len(ch.edges)
        model = ch.nodes[k]
        if self.rng.random() < 0.5:
            self.filter_on(ch, k)
        sums = list(self.cat.quantities(model))
        if sums and self.rng.random() < 0.6:
            prop = self.cat.prop(model, self.rng.choice(sums))
            ch.steps.append({"ask": {"model": model, "total_of": prop["name"], "means": prop.get("description", ""), "over": "all matching records"}})
            return self.finish(ch, "aggregate", f"sum(n{k}.{prop['name']}) AS total", ["aggregate", "sum"])
        ch.steps.append({"ask": {"model": model, "count_of": "matching records"}})
        return self.finish(ch, "aggregate", f"count(n{k}) AS count", ["aggregate", "count"])

    def temporal(self):
        cat, rng = self.cat, self.rng
        cand = []
        for vid, x in self.world["instances"].items():
            v = cat.validity(x["model"])
            if not v or not v.get("from") or not cat.relation(x["model"]):
                continue
            from_ = lambda ver: ver
            if len(x["versions"]) > 1:
                a, b = (self.get(x["versions"][i], v["from"]) for i in (0, 1))
                cand.append((vid, [a + (b - a) // 2, b + 5 * 86_400_000]))
        if not cand:
            return None
        vid, moments = rng.choice(cand)
        x = self.world["instances"][vid]
        r = cat.relation(x["model"])
        known = x["versions"][0][r["from"][0]]
        model = self.world["instances"][known]["model"]
        ch = Chain()
        ch.nodes.append(model)
        name = self.world["instances"][known]["versions"][0][cat.label(model)]
        ch.where.setdefault(0, []).append(f"n0.{cat.label(model)} = {lit(name)}")
        ch.steps.append({"start": {"model": model, "means": cat.models[model]["description"], "property": cat.label(model), "equals": name}})
        ch.anchors.append(name)
        options = [e for e in cat.edges(model) if e["via"] == "relation" and e["owner"] == x["model"] and e["label"] == x["versions"][0][r["label"][0]]]
        if not options:
            return None
        e = rng.choice(options)
        ch.steps.append(self.hop_step(e, model))
        ch.edges.append(e)
        ch.nodes.append(e["to"])
        prop = self.ask_column(ch, cat.prop(e["to"], cat.label(e["to"])) if cat.label(e["to"]) else None)
        return self.finish(ch, "temporal", f"n1.{prop['name']} AS value", ["temporal", "valid_time"], valid_at=rng.choice(moments))

    @staticmethod
    def get(value, path):
        for k in path:
            value = value[k]
        return value

    def unanswerable(self):
        cat, rng = self.cat, self.rng
        why = rng.choice(["missing", "unrecorded", "ambiguous"])
        dup = {}
        for vid, x in self.world["instances"].items():
            if cat.label(x["model"]):
                dup.setdefault((x["model"], x["versions"][0][cat.label(x["model"])]), []).append(vid)
        same = [k for k, v in dup.items() if len(v) > 1]
        if why == "ambiguous" and not same:
            why = "missing"
        ch = Chain()
        if why == "ambiguous":
            model, name = rng.choice(same)
            ch.nodes.append(model)
            ch.where.setdefault(0, []).append(f"n0.{cat.label(model)} = {lit(name)}")
            ch.steps.append({"start": {"model": model, "means": cat.models[model]["description"], "property": cat.label(model), "equals": name}})
            ch.anchors.append(name)
            self.walk(ch, rng.randint(0, 1))
            prop = self.ask_column(ch)
            return self.finish(ch, "unanswerable", f"n{len(ch.edges)}.{prop['name']} AS value", ["unanswerable", "ambiguous_name"], intent="abstain")
        if why == "missing":
            pools = {m: r for m, r in self.world["reserve"].items() if r}
            if not pools:
                return None
            model = rng.choice(list(pools))
            name = rng.choice(pools[model])
            ch.nodes.append(model)
            ch.where.setdefault(0, []).append(f"n0.{cat.label(model)} = {lit(name)}")
            ch.steps.append({"start": {"model": model, "means": cat.models[model]["description"], "property": cat.label(model), "equals": name}})
            ch.anchors.append(name)
            self.walk(ch, rng.randint(0, 2))
            prop = self.ask_column(ch)
            return self.finish(ch, "unanswerable", f"n{len(ch.edges)}.{prop['name']} AS value", ["unanswerable", "missing_entity"], intent="abstain")
        self.start(ch)
        model = ch.nodes[0]
        vid = next(i for i in self.world["by_model"][model] if self.world["instances"][i]["versions"][0][cat.label(model)] == ch.anchors[0])
        blanks = [p for p in cat.props(model) if cat.optional(p["shape"]) and not cat.target(p["shape"]) and p["name"] not in self.world["instances"][vid]["versions"][-1]]
        if not blanks:
            return None
        prop = rng.choice(blanks)
        ch.steps.append({"ask": {"model": model, **self.means(model, prop)}})
        return self.finish(ch, "unanswerable", f"n0.{prop['name']} AS value", ["unanswerable", "unrecorded"], intent="abstain")

    KINDS = {"lookup": "lookup", "hop": "hop", "filter": "filtered", "aggregate": "aggregate", "temporal": "temporal", "unanswerable": "unanswerable"}

    def sample(self, kind):
        return getattr(self, self.KINDS[kind])()


def read_answer(answer):
    fields = answer.get("fields", [])
    values = sorted(json.dumps(f["value"], sort_keys=True) for f in fields if "terms" not in f["path"])
    support = sorted({f["path"][0] for f in fields if len(f["path"]) == 2 and f["path"][1] != "terms" and f["path"][0] not in ("total", "count", "value")} |
                     {f["path"][2] for f in fields if len(f["path"]) > 2 and f["path"][1] == "terms"})
    return {"status": answer.get("status"), "values": values, "support": support,
            "sources": sorted({c["source"]["observation"] for c in answer.get("citations", [])}), "problems": [p["code"] for p in answer.get("problems", [])]}


def outcome(app, plan):
    return read_answer(app.query(plan["cypher"], plan["params"], plan["as_of"]))
