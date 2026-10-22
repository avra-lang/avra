"""Gold closed choices from the real extraction cascade.

The cascade runs unchanged over each authored message. Its encoder is
replaced by the message's gold spans and its scorer by an oracle that answers
every choice from the gold and records it; the choice's context, question and
options are whatever the cascade itself built. The oracle's answer steers the
run, so each later choice is asked in the state the gold implies. A choice
whose answer the gold does not settle is answered but not recorded.

usage: python extract_drive.py [domain …] > decisions.jsonl   (stderr: counts)
"""
import collections
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "extract"))
import cascade  # noqa: E402
from corpus import descriptor, domains, placed  # noqa: E402

SCORED = {"typed": "type", "antecedent": "antecedent", "choose_speaker": "speaker", "resolve": "reference",
          "relate": "relation", "record_pass": "record", "value_of": "field", "fill": "stated", "emit": "field",
          "qualifiers": None}
CONFIDENCE = 0.9


class Gold:
    """One message's gold, placed in its text."""

    def __init__(self, domain, message):
        self.domain, self.m, self.t = domain, message, message["text"]
        self.ents = domain["entities"]
        spans = placed(self.t, message.get("mentions", []))
        self.names = {(a, b): item for a, b, item in spans if "ref" not in item[2:]}
        self.refs = {(a, b): item for a, b, item in spans if "ref" in item[2:]}
        self.quotes = {q[0]: q[1] for q in message.get("quotes", [])}
        self.facts = []
        for f in message.get("facts", []):
            at = self.t.index(f["in"])
            self.facts.append(dict(f, _span=(at, at + len(f["in"]))))

    def entity_at(self, a, b):
        item = self.names.get((a, b)) or self.refs.get((a, b))
        return item[1] if item else None

    def unsure(self, a, b):
        item = self.names.get((a, b))
        return bool(item) and "?" in item[2:]

    def stated_in(self, a, b, model=None):
        """Facts whose cue starts inside [a, b), of a model when named."""
        return [f for f in self.facts if a <= f["_span"][0] < b and (model is None or f["model"] == model)]


class Encoder:
    """The message's gold spans, labelled as the cascade asks for them."""

    def __init__(self, gold, oracle):
        self.g, self.oracle = gold, oracle

    def mentions(self, text, labels):
        if text != self.g.t:
            return {}
        out = {}
        if cascade.STATEMENT in labels:
            out[cascade.STATEMENT] = [{"start": a, "end": b, "confidence": CONFIDENCE} for a, b in cascade.Text(text).units()]
        if cascade.REFERENCE in labels:
            out[cascade.REFERENCE] = [{"start": a, "end": b, "confidence": CONFIDENCE} for a, b in self.g.refs]
        for (a, b), item in self.g.names.items():
            label = self.g.ents[item[1]]["model"].lower()
            if label in labels:
                out.setdefault(label, []).append({"start": a, "end": b, "confidence": CONFIDENCE})
        return out

    def records(self, text, model, anchor, fields):
        """Each gold record of this model, its text fields placed in its own sentence."""
        if text != self.g.t:
            return []
        units = cascade.Text(text).units()
        out = []
        for f in self.g.facts:
            if f["model"] != model:
                continue
            lo, hi = next(((a, b) for a, b in units if a <= f["_span"][0] < b), (0, len(text)))
            found = {}
            for name in fields:
                v = f.get("fields", {}).get(name)
                at = text.find(v, lo, hi) if isinstance(v, str) and v not in self.g.ents else -1
                if at >= 0:
                    found[name] = {"text": v, "start": at, "end": at + len(v), "confidence": CONFIDENCE}
            if found:
                out.append(found)
        return out


class Oracle(cascade.Scorer):
    """Answers each choice from the gold and records the ones the gold settles."""

    def __init__(self, gold, out):
        self.g, self.out, self.calls, self.source, self.cache, self.prefix = gold, out, 0, "", None, False
        self.current, self.c = None, None

    def begin(self, source):
        self.source = source

    def choose(self, context, question, options):
        frame = sys._getframe(1)
        while frame and not (frame.f_code.co_filename == cascade.__file__ and frame.f_code.co_name in SCORED):
            frame = frame.f_back
        name, local = frame.f_code.co_name, frame.f_locals
        self.c = local["self"]
        gold, kind = getattr(self, "on_" + name)(local, options)
        self.calls += 1
        if gold is not None:
            self.out.append({"domain": self.g.domain["domain"], "message": self.g.m["id"], "kind": kind or SCORED[name],
                             "source": self.source, "context": context, "question": question, "options": options,
                             "gold": gold, "tail": self.tail_of(local, options)})
        pick = gold if gold is not None else len(options) - 1
        return [1.0 if i == pick else 0.0 for i in range(len(options))]

    @staticmethod
    def tail_of(local, options):
        """How many trailing options are fixed alternatives (none, cannot tell), kept last in both orders."""
        for key in ("prior", "ids", "readings", "labels", "kinds", "vals", "nums", "cands"):
            if key in local and isinstance(local[key], list) and len(local[key]) < len(options):
                return len(options) - len(local[key])
        return 0

    # The record a cascade id stands for, by the gold of the span that made it.

    def entity(self, rid):
        r = next((r for r in self.c.records if r["local_id"] == rid), None)
        if r is None or "_anchor" not in r:
            return None
        return self.g.entity_at(*r["_anchor"])

    def index(self, ids, entity):
        return next((i for i, rid in enumerate(ids) if self.entity(rid) == entity), None)

    # One handler per cascade method that asks; each answers (gold index or None, kind).

    def on_typed(self, local, options):
        e = self.g.entity_at(local["a"], local["b"])
        model = e and self.g.ents.get(e, {}).get("model", "").lower()
        return next((i for i, n in enumerate(local["names"]) if n == model), None), None

    def on_antecedent(self, local, options):
        a, b, prior = local["a"], local["b"], local["prior"]
        if self.g.unsure(a, b):
            return len(prior) + 1, None
        k = self.index([r["local_id"] for r in prior], self.g.entity_at(a, b))
        return (k if k is not None else len(prior)), None

    def on_choose_speaker(self, local, options):
        who = self.g.quotes.get(self.c.t.s[local["a"]:local["b"]])
        ids = local["ids"]
        if who is None:
            return None, None
        if who == "author":
            return len(ids), None
        if who == "?":
            return len(ids) + 1, None
        k = self.index(ids, who)
        return k, None

    def on_resolve(self, local, options):
        ids, who = local["ids"], self.g.entity_at(local["x"], local["y"])
        if who in (None, "?"):
            return (len(ids) + 1 if who == "?" else None), None
        k = self.index(ids, who) if who != "none" else None
        if k is None and who != "none" and who in {item[1] for item in self.g.names.values()}:
            return None, None
        return (k if k is not None else len(ids)), None

    def on_relate(self, local, options):
        a, b, readings = local["a"], local["b"], local.get("readings")
        if readings is None:
            return None, None
        for f in self.g.stated_in(a, b, local["name"]):
            for i, (s, o, v, _) in enumerate(readings):
                if self.entity(s) == f["from"] and self.entity(o) == f["to"] and v == f["label"]:
                    self.current = f
                    return i, None
        self.current = None
        return len(readings), None

    def on_record_pass(self, local, options):
        kinds = local["kinds"]
        for f in self.g.stated_in(local["x"], local["y"]):
            if f["model"] in kinds:
                self.current = f
                return kinds.index(f["model"]), None
        self.current = None
        return len(kinds), None

    def on_value_of(self, local, options):
        f = self.current
        if not f or f["model"] != local["model"]:
            return None, None
        name, kind = local["name"], local["kind"]
        want = f.get("fields", {}).get(name)
        if kind == "ref":
            ids = local["ids"]
            k = self.index(ids, want) if want is not None else None
            return (k if k is not None else len(ids)), None
        if kind == "enum":
            vals = local["vals"]
            return (vals.index(want) if want in vals else len(vals)), None
        if kind == "bool":
            return (2 if want is None else 0 if want else 1), None
        if kind == "number":
            texts = [self.c.t.s[x:y].replace(",", "") for x, y in local["nums"]]
            return (texts.index(str(want)) if want is not None and str(want) in texts else len(texts)), None
        if kind == "text":
            texts = [self.c.t.s[x:y] for x, y in local["cands"]]
            return (texts.index(want) if want in texts else len(texts)), None
        return None, None

    def on_fill(self, local, options):
        f, field = self.current, local["f"]
        want = f.get("fields", {}).get(field["property"]) if f else None
        value = field["value"]
        got = self.entity(value) if isinstance(value, str) and any(r["local_id"] == value for r in self.c.records) else value
        return (0 if want is not None and got == want else 1), None

    def on_emit(self, local, options):
        f = self.current
        want = f.get("fields", {}).get(local["p"]["name"]) if f else None
        return (None if want is None else 0 if want else 1), None

    def on_qualifiers(self, local, options):
        f = self.current
        if not f:
            return None, None
        if options == list(cascade.SPEECH_ACTS.values()):
            return list(cascade.SPEECH_ACTS).index(f.get("act", "assert")), "modality"
        return (1 if f.get("deny") else 0), "polarity"


def drive(domain, out):
    plan = cascade.Plan(descriptor(domain))
    for m in domain["messages"]:
        gold = Gold(domain, m)
        oracle = Oracle(gold, out)
        enc = Encoder(gold, oracle)
        spans = {k: enc.mentions(*q) if op == "mentions" else enc.records(*q)
                 for k, (op, *q) in plan.encoder_queries(m["text"]).items()}
        c = cascade.Cascade(plan, spans, oracle)
        c.run({"content": m["text"], "frames": []})


def main():
    out = []
    for name, d in domains(set(sys.argv[1:]) or None).items():
        before = len(out)
        drive(d, out)
        counts = collections.Counter(x["kind"] for x in out[before:])
        print(f"{name}: {len(out) - before} decisions {dict(counts)}", file=sys.stderr)
    for x in out:
        print(json.dumps(x, ensure_ascii=False))


if __name__ == "__main__":
    main()
