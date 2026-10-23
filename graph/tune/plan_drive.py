"""Gold closed choices from the real structured planner.

The planner composes each authored question over the domain's catalog, with
the graph's search answered from the domain's gold facts. An oracle chooser
takes, at every decision, the option the question's gold query implies, and
records the decision as the planner asked it. A question whose composed
query differs from its gold is reported and contributes nothing, so a label
is never written for a walk the planner cannot take.

usage: python plan_drive.py [domain …] > decisions.jsonl   (stderr: counts, misses)
"""
import collections
import hashlib
import json
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
SRC = pathlib.Path(os.environ.get("GRAPH_SRC", HERE.parent))
sys.path.insert(0, str(SRC / "planner"))
import structured  # noqa: E402
from corpus import domains, schema  # noqa: E402

KINDS = {"Is the question about": "speaker gate", "Who or what is the question about first?": "anchor", "Which kind of record is the person asking?": "speaker model",
         "Which kind of record holds the answer?": "kind", "Which relation does the question mean?": "relation",
         "Where next?": "hop", "What does the question ask for?": "mode", "What does the question want to know?": "recorded",
         "Which recorded status?": "status", "Which property does the question ask for?": "property",
         "Which other property does the answer also need?": "property more"}
PART = re.compile(r"(-\[(?:r\d+)?:\w+\]->|<-\[(?:r\d+)?:\w+\]-)\((n\d+):(\w+)\)")


class Walk:
    """A gold query in the planner's own dialect, read into its choices."""

    def __init__(self, cypher):
        m = re.fullmatch(r"MATCH \(n0:(\w+)\)(.*?)(?: WHERE (.*?))? RETURN (.*)", cypher)
        if not m:
            raise ValueError(f"not in the planner's dialect: {cypher}")
        self.label, body, where, returns = m.groups()
        self.hops = [(re.sub(r"\[r\d+:", "[:", a), v, t) for a, v, t in PART.findall(body)]
        if PART.sub("", body).strip():
            raise ValueError(f"unread pattern: {body}")
        self.conds = [c.strip() for c in where.split(" AND ")] if where else []
        self.count = returns.startswith("count(")
        status = re.match(r"coalesce\((n\d+|r\d+)\.(\w+), false\)", returns)
        self.status = status.groups() if status else None
        self.items = [] if self.count or self.status else re.findall(r"(n\d+|r\d+)\.(\w+) AS \w+", returns)

    def equal(self, var):
        return [(p, v) for x, p, v in equalities(self) if x == var]

    def contains(self, var):
        out = []
        for c in self.conds:
            m = re.fullmatch(r"(n\d+)\.(\w+) CONTAINS '(.*)'", c)
            if m and m.group(1) == var:
                out.append(m.group(2, 3))
        return out


def equalities(walk):
    out = []
    for c in walk.conds:
        m = re.fullmatch(r"(n\d+)\.(\w+) = '(.*)'", c)
        if m:
            out.append(m.groups())
    return out


class Oracle:
    """Answers each planner decision from the gold walk and records it.

    Each `on_<fn>` names the gold option's TEXT among the full option list of
    the decision (the outermost `best` call), so an option set the planner
    splits into heats still records the heat that holds the gold."""

    def __init__(self, domain, qid, walk):
        self.domain, self.qid, self.walk, self.decisions = domain, qid, walk, []

    def choose(self, context, question, options):
        frame = sys._getframe(1)
        while frame.f_code.co_name != "best":
            frame = frame.f_back
        forward = frame.f_locals["options"]
        while frame.f_back.f_code.co_name in ("best", "debiased"):
            frame = frame.f_back
        full, caller = frame.f_locals["options"], frame.f_back
        gold = getattr(self, "on_" + caller.f_code.co_name)(caller, question, full)
        if gold is None:
            raise Miss(f"no gold for {question!r} among {full}")
        if gold not in forward:
            return [0.0 for _ in options]
        record = {"domain": self.domain, "question_id": self.qid, "kind": kind(question), "source": "",
                  "context": context, "question": question, "options": forward, "gold": forward.index(gold), "tail": 0}
        if record not in self.decisions:
            self.decisions.append(record)
        return [1.0 if o == gold else 0.0 for o in options]

    def on_speaking(self, frame, question, options):
        return "yes" if "id(n0) = $speaker" in self.walk.conds else "no"

    def on_anchored(self, frame, question, options):
        local, w = frame.f_locals, self.walk
        if question.startswith("Who or what"):
            for var, prop, value in equalities(w):
                text = f"the {w.label} whose {prop} is {value!r}, named in the question"
                if var == "n0" and text in options:
                    return text
            if any(o.startswith(f"the {w.label} whose ") for o in options):
                raise Miss(f"a named {w.label} is offered; the gold should anchor on it")
            return options[-1]
        if question.startswith("Which kind of record is the person"):
            return w.label if w.label in options else None
        kinds = local["kinds"]
        return options[kinds.index(w.label)] if w.label in kinds else None

    def on_narrowed(self, frame, question, options):
        local = frame.f_locals
        var = local["var"]
        if "values" in local and question.startswith("Which ") and question.endswith(" does the question mean?"):
            wanted = dict(self.walk.equal(var)).get(local["label"][0])
            return options[local["values"].index(wanted)] if wanted in local["values"] else options[-1]
        shared = local["shared"]
        for prop, w in self.walk.contains(var):
            if (prop, w) in shared:
                return options[shared.index((prop, w))]
        return options[-1]

    def on_plan(self, frame, question, options):
        local = frame.f_locals
        h = len(local["out"].parts) - 1
        if question.startswith("Is the answer about this"):
            return options[0 if h == len(self.walk.hops) else 1]
        if h >= len(self.walk.hops):
            return None
        arrow, _, target = self.walk.hops[h]
        hops = local["options"]
        pool = local["said"] if question.startswith("Which relation") else local["ranked"]
        k = next((k for k, i in enumerate(pool) if hops[i][0] == arrow and hops[i][1] == target), None)
        return None if k is None else options[k]

    def on_returns(self, frame, question, options):
        local, w = frame.f_locals, self.walk
        if question.startswith("What does the question ask for"):
            return options[1 if w.count else 0]
        if question.startswith("What does the question want to know"):
            return options[1 if w.status else 0]
        flags = local["flags"]
        return options[flags.index(w.status)] if w.status in flags else None

    def on_compared(self, frame, question, options):
        local = frame.f_locals
        props = [(v, p["name"]) for v, _, p in frame.f_back.f_locals["props"]]
        items = [tuple(i) for i in self.walk.items]
        if question.startswith("Which property does"):
            return options[props.index(items[0])] if items and items[0] in props else None
        picked, rest = local["picked"], local["rest"]
        taken = {props[i] for i in picked}
        more = [i for i in items if i not in taken]
        if not more:
            return options[len(rest)]
        k = next((k for k, i in enumerate(rest) if props[i] == more[0]), None)
        return None if k is None else options[k]


class Miss(Exception):
    pass


def kind(question):
    for prefix, name in KINDS.items():
        if question.startswith(prefix):
            return name
    if question.startswith("Is the answer about this"):
        return "arrival"
    if question.startswith("Which of these narrows"):
        return "narrowing"
    if question.endswith("does the question mean?"):
        return "label"
    return "other"


class Search:
    """The graph's search over a domain's gold: fact passages ('Model prop: value'
    for text values) and every message as a source passage, matched by word."""

    def __init__(self, domain, desc):
        self.passages = [{"kind": "source", "text": m["text"]} for m in domain["messages"]]
        texts = {m["name"]: {p["name"] for p in m["properties"] if structured.base_shape(p["shape"]) == "string" and not p.get("enum")}
                 for m in desc}
        facts = set()
        for e in domain["entities"].values():
            first = next(p for p in desc if p["name"] == e["model"])["properties"][0]["name"]
            facts.add((e["model"], first, e["name"]))
            for k, v in e.get("fields", {}).items():
                facts.add((e["model"], k, v))
        for m in domain["messages"]:
            for f in m.get("facts", []):
                for k, v in f.get("fields", {}).items():
                    if k in texts[f["model"]] and isinstance(v, str) and v not in domain["entities"]:
                        facts.add((f["model"], k, v))
        self.passages += [{"kind": "fact", "text": f"{m} {p}: {v}"} for m, p, v in sorted(facts)]

    def __call__(self, word):
        return [p for p in self.passages if word in structured.tokens(p["text"].partition(": ")[2] if p["kind"] == "fact" else p["text"])]


def speaker_view(domain, desc):
    """The graph's `get` answer for an entity: its model and its label field."""
    first = {m["name"]: m["properties"][0]["name"] for m in desc}

    def read(entity):
        e = domain["entities"].get(entity)
        if not e:
            return {}
        return {"model": e["model"], "fields": {first[e["model"]]: [{"value": e["name"], "chosen": True}]}}
    return read


def asker(domain, desc, qid):
    """Who asks a question the gold leaves unattributed: a record of a model
    with a declared identity, picked by a stable hash of the question's id, so
    the speaker gate also sees questions that are not about the asker."""
    keyed = {m["name"] for m in desc if m["semantics"]["identities"]}
    people = sorted(k for k, e in domain["entities"].items() if e["model"] in keyed)
    return people[int(hashlib.sha256(qid.encode()).hexdigest(), 16) % len(people)] if people else None


def drive(domain, out, misses):
    s = schema(domain)
    for m in s["models"]:
        m["semantics"]["label"] = [m["properties"][0]["name"]]
    search = Search(domain, s["models"])
    for i, q in enumerate(domain.get("questions", [])):
        qid = f"{domain['domain']}:q{i:02d}"
        try:
            walk = Walk(q["cypher"])
            oracle = Oracle(domain["domain"], qid, walk)
            model_of = speaker_view(domain, s["models"])
            asked = [q.get("speaker")] if q.get("speaker") else [None, asker(domain, s["models"], qid)]
            for speaker in asked:
                composed = structured.plan(oracle, q["q"], s, {"speaker": speaker}, search, None, model_of)
                if composed != q["cypher"]:
                    break
        except (Miss, ValueError) as e:
            misses.append(f"{qid} {q['q']!r}: {e}")
            continue
        if composed != q["cypher"]:
            misses.append(f"{qid} {q['q']!r}: composed\n      {composed}\n    gold\n      {q['cypher']}")
            continue
        out += oracle.decisions


def main():
    out, misses = [], []
    for name, d in domains(set(sys.argv[1:]) or None).items():
        before, missed = len(out), len(misses)
        drive(d, out, misses)
        counts = collections.Counter(x["kind"] for x in out[before:])
        print(f"{name}: {len(d.get('questions', [])) - (len(misses) - missed)} walks, {len(out) - before} decisions {dict(counts)}", file=sys.stderr)
    for m in misses:
        print("  miss " + m, file=sys.stderr)
    for x in out:
        print(json.dumps(x, ensure_ascii=False))


if __name__ == "__main__":
    main()
