"""The structured planner arm: the model only makes closed choices, and the
query is composed from them, so it cannot invent a hop, drop the speaker or
loop. Each choice is scored by next-token probability over lettered options.

Nothing here names words of a language. Evidence comes from three places
only: the catalog's declarations (models, references, declared relation
phrases, enum values), the graph's own search over admitted facts, and the
model's closed choices. A choice the evidence settles alone (one declared
phrase spoken, one record the question names) is taken without the model.
"""
import json
import math
import re

import os
import sys

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "retrieval"))
import hooks as retrieval_hooks  # noqa: E402
from catalog import PARAMETERS, derivations_of, embedded_in, models_of, base_shape, reference_target, relation_ends, seat_of
from prompt import line
from sight import Sight


LETTERS = PARAMETERS["choice_letters"]
ENOUGH = "nothing else: the answer is complete"
RECORDED = ["the content of the records: values, words, dates, people (missing means unknown)",
            "only whether a yes/no status has been recorded (no record counts as no)"]


class Plan:
    """The composed query, built one choice at a time."""

    def __init__(self, vars=None):
        self.parts, self.where, self.vars = [], [], [] if vars is None else vars
        self.later = []

    def node(self, label):
        var = f"n{len(self.vars)}"
        self.vars.append((var, label))
        return var

    def seen(self, returns, tail="", where=(), limit=None, held=None):
        """A read-only query over the pattern so far, continued by `tail` and
        narrowed by `where`; `held` names the relation record the pattern passes."""
        parts = list(self.parts)
        if held:
            parts[held[2]] = parts[held[2]].replace("-[:", f"-[{held[0]}:", 1)
        conds = [*self.where, *where]
        text = "MATCH " + "".join(parts) + tail + (" WHERE " + " AND ".join(conds) if conds else "")
        return f"{text} RETURN {returns}" + (f" LIMIT {limit}" if limit else "")

    def cypher(self, returns):
        text = "MATCH " + "".join(self.parts)
        if self.where:
            text += " WHERE " + " AND ".join(self.where)
        return " ".join([text, *self.later, f"RETURN {returns}"])


class Evidence:
    """What the graph's own search says about the question.

    A record the question names is found by its whole value, whatever its
    words' frequency. Otherwise a word is evidence only where it is
    informative in this graph: its
    document frequency (passages the search returns for it alone) is at most
    the median over the question's words. Facts on enum properties are
    declared categories, matched by declarations, never by search; a
    reference's value is an entity id, never a word. A word a
    declaration, an anchor or a narrowing has explained stops counting."""

    def __init__(self, search, question, models):
        self.facts, self.every, self.words, self.spent = [], [], set(), set()
        self.used, self.near = set(), []
        if not search:
            return
        found = {w: search(w) for w in dict.fromkeys(tokens(question))}
        counts = sorted(len(v) for v in found.values() if v)
        if not counts:
            return
        median = counts[(len(counts) - 1) // 2]
        self.words = {w for w, hits in found.items() if hits and len(hits) <= median}
        for w, hits in found.items():
            for p in hits:
                fact = self.fact(p, models)
                if fact and fact not in self.every:
                    self.every.append(fact)
                if fact and w in self.words and fact not in self.facts:
                    self.facts.append(fact)

    @staticmethod
    def fact(passage, models):
        if passage.get("kind") != "fact":
            return None
        head, _, value = passage["text"].partition(": ")
        model, _, prop = head.partition(" ")
        declared = models.get(model, {}).get("properties", [])
        if not any(q["name"] == prop and not q.get("enum") and not reference_target(q["shape"]) for q in declared):
            return None
        return model, prop, value

    def explain(self, text):
        """Words some declaration or choice now accounts for."""
        self.words -= set(tokens(text))

    def named(self, question):
        """Facts whose whole value the question spells: records it names. A name
        is evidence however common its words are, since the whole value matches."""
        exact = [f for f in self.every if spoken(f[2], question.lower())]
        return exact + [f for f in self.near if f not in exact]

    def models(self):
        """Models whose facts hold a still unexplained informative word."""
        return {m for m, _, value in self.facts if self.words & set(tokens(value))} - self.spent

    def points_at(self, prop):
        """Whether unexplained informative words of the question name this property."""
        text = prop["name"].replace("_", " ") + " " + prop.get("description", "")
        return bool(self.words & set(tokens(text)))

    def shown(self, hop):
        """A hop's words, with the facts of its target that hold unexplained words."""
        held = [value for m, _, value in self.facts if m == hop[1] and self.words & set(tokens(value))]
        return hop[2] + ("; such records hold: " + "; ".join(repr(v) for v in held) if held else "")

    def about(self, model, question):
        """(property, words) for this model's facts sharing words with the question:
        every shared word is offered, and the model chooses which, if any, narrows."""
        words = set(tokens(question))
        return [(prop, [w for w in tokens(value) if w in words]) for m, prop, value in self.every
                if m == model and (m, prop, value) not in self.used and words & set(tokens(value))]


def quoted(text):
    return "'" + text.replace("'", "") + "'"


def tokens(text):
    return re.findall(r"\w+", text.lower())


def spoken(phrase, text):
    """Whether a phrase occurs in the text as whole words."""
    return re.search(rf"\b{re.escape(phrase.lower())}\b", text) is not None


def unsaid(phrases, text):
    """The text without the phrases a hop has answered for."""
    for p in phrases:
        text = re.sub(rf"\b{re.escape(p.lower())}\b", " ", text)
    return text


def best(chooser, context, question, options, keys=None):
    """The likeliest option; one option is no choice. A chooser that can rank
    answers is asked to, when the call names each option's short key: every
    option then competes in one distribution, whatever their number. A chooser
    that searches (`decide`) is handed each decision's log-probabilities and
    names the option taken."""
    budget = getattr(chooser, "budget", None)
    if budget:
        budget.holds(context, question, *options)
    if not options:
        raise ValueError(f"no options for: {question}")
    if len(options) == 1:
        return 0
    if keys and hasattr(chooser, "rank"):
        logp = odds(chooser, context, question, options, keys)
    elif len(options) > LETTERS:
        heats = [options[i:i + LETTERS - 1] for i in range(0, len(options), LETTERS - 1)]
        winners = [heat[best(chooser, context, question, heat)] for heat in heats]
        return options.index(winners[best(chooser, context, question, winners)])
    else:
        logp = [math.log(max(x, 1e-9)) for x in debiased(chooser, context, question, options)]
    pick = chooser.decide(logp) if hasattr(chooser, "decide") else max(range(len(logp)), key=logp.__getitem__)
    chooser.tally = getattr(chooser, "tally", 0.0) + logp[pick]
    if hasattr(chooser, "took"):
        chooser.took(options[pick])
    return pick


def odds(chooser, context, question, options, keys):
    """Each option's log-probability among the options: its answer's score
    averaged over the listed order and its reverse, normalised over the set."""
    forward = chooser.rank(context, question, options, keys)
    backward = chooser.rank(context, question, options[::-1], keys[::-1])[::-1]
    raw = [(a + b) / 2 for a, b in zip(forward, backward)]
    top = max(raw)
    total = top + math.log(sum(math.exp(r - top) for r in raw))
    return [r - total for r in raw]


def debiased(chooser, context, question, options):
    """Each option's probability averaged over the listed order and its reverse,
    so no option gains from where it is listed."""
    forward = chooser.choose(context, question, options)
    backward = chooser.choose(context, question, options[::-1])[::-1]
    return [(a + b) / 2 for a, b in zip(forward, backward)]


def unique(keys):
    """Keys that tell their options apart: a repeat takes its position."""
    return [k if keys.count(k) == 1 else f"{k} ({i + 1})" for i, k in enumerate(keys)]


def fitted(most, chooser, trail, question, build):
    """The options built with as many sample rows as the model's prompt budget
    holds, up to `most`."""
    tokens = getattr(getattr(chooser, "budget", None), "tokens", None)
    for rows in range(most, -1, -1):
        options = build(rows)
        if tokens is None or len(trail) + len(question) + sum(map(len, options)) <= tokens:
            return options
    return build(0)


def hop_key(hop):
    """A hop's short name: its declared word, else the reference followed and the record reached."""
    arrow, target, _, phrases, _, _ = hop
    name = arrow.strip("<>-[]:")
    return phrases[0] if phrases else f"{target} by {name}" if arrow.startswith("<-") else f"{name} to {target}"


def hops(models, label):
    """Each relationship a node of `label` really has, as (cypher, target, words,
    phrases, record, meaning): declared relation phrases first, whose record
    model is named and whose meaning is every phrase of the label, both ways;
    then reference properties both ways."""
    out = []
    for name, m in models.items():
        ends = relation_ends(m)
        relation = ((m.get("semantics") or {}).get("relation")) or {}
        for l in (relation.get("labels", []) if ends else []):
            meaning = [l["value"], *l.get("forward", []), *l.get("reverse", [])]
            if ends[0] == label:
                also = [w for w in l.get("forward", []) if w != l["value"]]
                said = f" ({', '.join(also)})" if also else ""
                out.append((f"-[:{l['value']}]->", ends[1], f"their {l['value']}{said}: a {ends[1]}",
                            [l["value"], *also], name, meaning))
            if ends[1] == label:
                for w in l.get("reverse", []):
                    out.append((f"-[:{w}]->", ends[0], f"their {w}: a {ends[0]}", [w], name, meaning))
    for p in models[label]["properties"]:
        target = reference_target(p["shape"])
        if target:
            out.append((f"-[:{p['name']}]->", target, f"follow its {p['name']} to a {target}", [], None, []))
    for owner, m in models.items():
        for p in m["properties"]:
            if reference_target(p["shape"]) == label:
                about = line(m.get("description", ""))
                out.append((f"<-[:{p['name']}]-", owner, f"{owner} records whose {p['name']} is this {label}: {about}", [], None, []))
    return out


def arrival(models, label, options):
    """Stay or go on, each side showing what it holds: this record's own
    properties, or the records reached from it."""
    held = ", ".join(p["name"].replace("_", " ") for p in models[label]["properties"])
    onward = ", ".join(dict.fromkeys(h[1] for h in options))
    return [f"yes: the answer is among this {label}'s own properties ({held})",
            f"no: the answer is on related records ({onward})"]


def plan(chooser, question, schema, context, search=None, depth=None, read=None, probe=None):
    """One query composed from closed choices; `depth` caps the hops (the
    request's budget), else the catalog's size bounds the walk."""
    derived = derivations_of(schema)
    declared = models_of(schema)
    held = {d["output"] for d in derived} | {e for m in declared.values() for p in m["properties"] for e in embedded_in(p["shape"])}
    models = {k: m for k, m in declared.items() if k not in held}
    head = f"Question: {question}"
    evidence = Evidence(search, question, models)
    if probe:
        evidence.near = retrieval_hooks.near_facts(chooser, question, labels_of(probe, models))
    out = Plan()
    if hasattr(chooser, "watch"):
        chooser.watch(out)
    look = Sight(probe, models, PARAMETERS["preview_rows"]) if probe and PARAMETERS["preview"] else None
    var, label = anchored(chooser, head, question, models, context, evidence, out, read, look, probe)
    came, held = None, None
    phrasing = question.lower()
    for hop in range(depth if depth is not None else len(models)):
        options = [h for h in hops(models, label) if not came or (h[0], h[1]) != came]
        trail = f"{head}\nSo far: {' '.join(out.parts)} — now at a {label}."
        evidence.explain(" ".join(p["name"].replace("_", " ") for p in models[label]["properties"]))
        if not options:
            break
        said = [i for i, h in enumerate(options) if any(spoken(p, phrasing) for p in h[3])]
        onward = [i for i, h in enumerate(options) if h[1] in evidence.models()]
        if said:
            ask = "Which relation does the question mean?"
            pick = said[0] if len(said) == 1 else said[best(
                chooser, trail, ask,
                fitted(look.rows if look else 0, chooser, trail, ask, lambda n: [options[i][2] + (look.reach(out, options[i], n) if look else "") for i in said]),
                unique([options[i][3][0] for i in said]))]
            evidence.explain(" ".join(options[pick][3]))
        else:
            if not onward and best(chooser, trail, f"Is the answer about this {label}?", arrival(models, label, options)) == 0:
                break
            ranked = onward or list(range(len(options)))
            ask = "Where next?"
            pick = ranked[best(
                chooser, trail, ask,
                fitted(look.rows if look else 0, chooser, trail, ask, lambda n: [evidence.shown(options[i]) + (look.reach(out, options[i], n) if look else "") for i in ranked]),
                unique([hop_key(options[i]) for i in ranked]))]
        arrow, target, _, _, record, meaning = options[pick]
        phrasing = unsaid(meaning, phrasing)
        back = ("<-" + arrow[1:-2] + "-" if arrow.endswith("->") else arrow[1:-1] + "->")
        var = out.node(target)
        held = (f"r{len(out.vars) - 1}", record, len(out.parts)) if record else None
        out.parts.append(f"{arrow}({var}:{target})")
        came, label = (back, label), target
        narrowed(chooser, trail, models[target], var, out, question, evidence, look)
        evidence.spent.add(target)
    trail = f"{head}\nSo far: {' '.join(out.parts)} — the answer is about these {label} records."
    offers = [d for d in derived if offered(d, label)]
    items = returns(chooser, trail, models[label], var, held and (held[0], models[held[1]]), evidence, offers,
                    lambda d: derivation_call(chooser, trail, d, out, var, label, models, evidence, question),
                    look and PARAMETERS["preview_values"] and (lambda v, name, n: look.value(out, v, name, n, held)), look)
    if held and f"{held[0]}." in items:
        out.parts[held[2]] = out.parts[held[2]].replace("-[:", f"-[{held[0]}:", 1)
    return out.cypher(items)


def labels_of(probe, models):
    """Every record's label as a fact (model, property, value), read from the graph."""
    sight, facts = Sight(probe, models, 0), []
    for name in models:
        prop = sight.label_of(name)
        if prop:
            out = Plan()
            var = out.node(name)
            out.parts.append(f"({var}:{name})")
            facts += [(name, prop, json.loads(v)) for v in sight.values(out.seen(f"{var}.{prop} AS v")) or []
                      if isinstance(json.loads(v), str)]
    return facts


def nearest(chooser, question, models, k):
    """The k declared models whose text lies nearest the question in the
    embedding model's space, in declared order; all of them when the chooser
    cannot embed or no k is declared."""
    if not k or k >= len(models) or not hasattr(chooser, "embed"):
        return list(models)
    docs = [f"{name}: {line(m.get('description', ''))} Fields: {', '.join(p['name'] for p in m['properties'])}"
            for name, m in models.items()]
    asked, vectors = chooser.embed([question], True)[0], chooser.embed(docs)
    near = sorted(range(len(docs)), key=lambda i: -sum(a * b for a, b in zip(asked, vectors[i])))[:k]
    return [name for i, name in enumerate(models) if i in near]


def speaking(chooser, head, models, context, read):
    """Whether the question is about the speaker or what is theirs: a closed
    yes/no, framed with the speaker's own declared label when the graph holds one."""
    entity = read(context["speaker"]) if read else {}
    path = (((models.get(entity.get("model")) or {}).get("semantics")) or {}).get("label") or []
    values = (entity.get("fields") or {}).get(path[0], []) if len(path) == 1 else []
    who = next((v["value"] for v in sorted(values, key=lambda v: not v.get("chosen"))), None)
    ask = f"Is the question about {who}, the one asking, or about what belongs to {who}?" if who \
        else "Is the question about the one asking, or about what belongs to them?"
    return best(chooser, f"{head}\nAsked by {who}." if who else head, ask, ["no", "yes"]) == 1


def anchored(chooser, head, question, models, context, evidence, out, read=None, look=None, probe=None):
    """The first node: the speaker, a record the question names, or every record of a kind."""
    named = distinct(evidence.named(question), probe, models)
    if context.get("speaker") and speaking(chooser, head, models, context, read):
        # The speaker is a graph entity: its model is a fact the graph holds.
        label = (read(context["speaker"]) if read else {}).get("model")
        if label not in models:
            keyed = identified(models)
            label = keyed[best(chooser, head, "Which kind of record is the person asking?", keyed)]
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
        out.where.append(f"id({var}) = $speaker")
        return var, label
    starts = [f"the {m} whose {p} is {v!r}, named in the question" for m, p, v in named] + ["every record of one kind"]
    pick = best(chooser, head, "Who or what is the question about first?", starts,
                unique([f"{m} {v}" for m, _, v in named] + ["any record"]))
    if pick < len(named):
        label, prop, value = named[pick]
        evidence.used.add((label, prop, value))
        evidence.explain(value)
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
        out.where.append(f"{var}.{prop} = {quoted(value)}")
        evidence.spent.add(label)
    else:
        kinds = nearest(chooser, question, models, PARAMETERS["kind_shortlist"])
        label = kinds[best(chooser, head, "Which kind of record holds the answer?",
                           [k + ": " + line(models[k].get("description", "")) for k in kinds], kinds)]
        var = out.node(label)
        out.parts.append(f"({var}:{label})")
        narrowed(chooser, head, models[label], var, out, question, evidence, look)
        evidence.spent.add(label)
    return var, label


def distinct(facts, probe, models):
    """The facts with one per record they name: spellings that resolve to the same records are one option.
    A fact the graph does not resolve stands for itself."""
    if not probe:
        return facts
    sight, seen, out = Sight(probe, models, 0), set(), []
    for fact in facts:
        found = sight.entities(*fact)
        key = (fact[0], found) if found else fact
        if key not in seen:
            seen.add(key)
            out.append(fact)
    return out


def identified(models):
    """Models whose records carry a declared identity: who a context id can name."""
    keyed = [k for k, m in models.items() if ((m.get("semantics") or {}).get("identities"))]
    return keyed or list(models)


def narrowed(chooser, trail, model, var, out, question, evidence, look=None):
    """A relationship record's declared label value, then a word its facts share with the question."""
    relation = ((model.get("semantics") or {}).get("relation")) or {}
    label = relation.get("label") or []
    props = {p["name"]: p for p in model["properties"]}
    if len(label) == 1 and props.get(label[0], {}).get("enum"):
        values = props[label[0]]["enum"]
        words = {l["value"]: l.get("forward", []) for l in relation.get("labels", [])}
        options = [f"{v} ({', '.join(words.get(v, [v]))})" for v in values] + ["any of them"]
        pick = best(chooser, trail, f"Which {label[0]} does the question mean?", options)
        if pick < len(values):
            out.where.append(f"{var}.{label[0]} = {quoted(values[pick])}")
    shared = [(prop, w) for prop, words in evidence.about(model["name"], question) for w in words
              if base_shape(props[prop]["shape"]) == "string" and not props[prop].get("enum")]
    shared = list(dict.fromkeys(shared))
    if not shared:
        return
    ask = f"Which of these narrows the {model['name']} records to the ones the question means?"
    options = [f"its {prop} contains {w!r}" + (look.kept(out, var, prop, w) if look else "") for prop, w in shared] + ["no narrowing"]
    pick = best(chooser, trail, ask, options, unique([f"its {prop} contains {w!r}" for prop, w in shared] + ["no narrowing"]))
    if pick < len(shared):
        prop, w = shared[pick]
        out.where.append(f"{var}.{prop} CONTAINS {quoted(w)}")
        evidence.explain(w)


def offered(derivation, label):
    """Whether a derivation reads only records and one of its seats is this model."""
    seats = [seat_of(p) for p in derivation["parameters"]]
    return None not in seats and any(model == label for _, model in seats)


def derivation_call(chooser, trail, d, out, var, label, models, evidence, question):
    """A declared derivation called on the walk's end, whose records fill a seat of
    their model (a single-row one first): each other seat is filled
    by a further MATCH from the previous seat's records, through a reference
    they share, else from a record of its model the question names, else from
    every record of it."""
    seats = [seat_of(p) for p in d["parameters"]]
    first = min((i for i, (_, model) in enumerate(seats) if model == label), key=lambda i: seats[i][0] == "all")
    bound, at = {first: var}, (var, label)
    for i, (how, model) in enumerate(seats):
        if i in bound:
            continue
        sub, v = Plan(out.vars), out.node(model)
        links = [h for h in hops(models, at[1]) if h[1] == model and h[4] is None]
        if links:
            link = links[best(chooser, trail, f"Which relation takes the {at[1]} records to the {model} records?",
                              [h[2] for h in links])]
            sub.parts.append(f"({at[0]}){link[0]}({v}:{model})")
        else:
            sub.parts.append(f"({v}:{model})")
            if how != "all":
                named = [f for f in evidence.named(question) if f[0] == model]
                options = [f"the {m} whose {p} is {val!r}, named in the question" for m, p, val in named] + ["any of them"]
                pick = best(chooser, trail, f"Which {model} record does the question mean?", options)
                if pick < len(named):
                    evidence.used.add(named[pick])
                    evidence.explain(named[pick][2])
                    sub.where.append(f"{v}.{named[pick][1]} = {quoted(named[pick][2])}")
        if how != "all":
            narrowed(chooser, trail, models[model], v, sub, question, evidence)
        out.later.append("MATCH " + "".join(sub.parts) + (" WHERE " + " AND ".join(sub.where) if sub.where else ""))
        bound[i], at = v, (v, model)
    args = ", ".join(f"collect({bound[i]})" if how == "all" else bound[i] for i, (how, _) in enumerate(seats))
    return f"{d['name']}({args}) AS {d['name']}"


def returns(chooser, trail, model, var, record=None, evidence=None, offers=(), compose=None, seen=None, look=None):
    """The RETURN items: a count, one recorded status, or chosen values. The
    final node's properties are candidates; a relation record passed on the
    way is a path, so its own fields are candidates only where unexplained
    informative words of the question point at them, except its yes/no status
    fields, which answer a question that asks for a status."""
    props = [(var, model["name"], p) for p in model["properties"]]
    if record:
        props += [(record[0], record[1]["name"], p) for p in record[1]["properties"]
                  if evidence and evidence.points_at(p)]
    asked = best(chooser, trail, "What does the question ask for?",
                 ["the value of one or more of their properties", "how many there are"]
                 + [f"the declared computation {d['name']}: {line(d['description'])}" for d in offers])
    if asked >= 2:
        return compose(offers[asked - 2])
    if asked == 1:
        return f"count({var}) AS count"
    flags = [(v, p["name"]) for v, _, p in props if base_shape(p["shape"]) == "boolean"]
    if record:
        flags += [(record[0], p["name"]) for p in record[1]["properties"]
                  if base_shape(p["shape"]) == "boolean" and (record[0], p["name"]) not in flags]
    if flags and best(chooser, trail, "What does the question want to know?", RECORDED) == 1:
        v, name = flags[best(chooser, trail, "Which recorded status?", [n for _, n in flags])]
        return f"coalesce({v}.{name}, false) AS {name}"
    def shown(rows):
        return [f"the {owner}'s {p['name']}" + (f" ({line(p['description'])})" if p.get("description") else "")
                + (seen(v, p["name"], rows) if seen else "") for v, owner, p in props]
    ask = "Which property does the question ask for?"
    picked = compared(chooser, trail, fitted(look.rows if look else 0, chooser, trail, ask, shown), unique([f"{owner}.{p['name']}" for _, owner, p in props]))
    names = [props[i][2]["name"] for i in picked]
    return ", ".join(f"{props[i][0]}.{props[i][2]['name']} AS {props[i][2]['name']}"
                     + ("" if names.count(props[i][2]["name"]) == 1 else f"_{props[i][0]}")
                     for i in picked)


def compared(chooser, trail, shown, keys):
    """One property chosen against the others, then more while the answer needs them."""
    picked = [best(chooser, trail, "Which property does the question ask for?", shown, keys)]
    while len(picked) < len(shown):
        rest = [i for i in range(len(shown)) if i not in picked]
        asked = trail + "\nAlready answering with: " + "; ".join(shown[i] for i in picked)
        at = best(chooser, asked, "Which other property does the answer also need?",
                  [shown[i] for i in rest] + [ENOUGH], [keys[i] for i in rest] + ["nothing else"])
        if at == len(rest):
            break
        picked.append(rest[at])
    return picked
