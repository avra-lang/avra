"""Local extraction cascade: an encoder proposes spans, a small LLM only
scores closed choices, and every proposal is an exact source anchor.

usage: python cascade.py [--catalog SCHEMA_JSON] [--local] [--no-prefix] < request_or_envelope.json > result.json
       python cascade.py --serve   # keep both models resident behind a Unix socket

stdin is a C01 ExtractionRequest, or a bare I01 SourceEnvelope with
--catalog naming the app's `{"op":"schema"}` answer. stdout is one C01
ExtractionResult (contract 2: selectors, FactBank factuality, speech act,
resolution). Timings, peak RSS and skipped models go to stderr.
The ontology comes only from the catalog descriptor.
"""
import json
import os
import re
import resource
import sys
import time

ENCODER = "fastino/gliner2-large-v1@d7aa8a2850d175a9227ff80358ea380723d03ad2"
SCORER = "mlx-community/Qwen3-4B-Instruct-2507-4bit@50d427756c6b1b2fe0c0a10f67fbda1fc8e82c1b"
MODEL_ID = f"{ENCODER}+{SCORER}"
SPAN_THRESHOLD = 0.4
ACCEPT = 0.5
MARGIN = 0.5
MAX_OPTIONS = 26
ABSTAIN = object()
SOCKET = os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")
THIRD_PERSON = re.compile(r"\b(she|She|he|He|her|Her|him|Him|they|They|them|Them)\b")
FIRST_PERSON = re.compile(r"\b(I|I'm|I'll|I've|me|my|My|mine|we|We|our|Our|us)\b")
SPEECH_ACTS = {
    "assert": "stated as a current fact by the speaker",
    "report": "reported as what someone else said",
    "plan": "a plan or intention for the future",
    "request": "a request asked of someone",
    "condition": "holds only under a stated condition",
    "draft": "a draft or tentative value",
}
# FactBank value of an affirmed claim by speech act; a denied one is CT-.
FACTUALITY = {"assert": "CT+", "report": "CT+", "plan": "Uu", "request": "Uu", "condition": "PS+", "draft": "PS+"}
QUOTE_CONTEXT = 32

os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")


LOG = []


def log(*parts):
    LOG.append(" ".join(str(p) for p in parts))


# ---------------------------------------------------------------- catalog


def target(shape):
    """The referenced model of a reference shape, through optional/list."""
    if isinstance(shape, dict):
        if "reference" in shape:
            return shape["reference"]
        inner = shape.get("optional") or shape.get("list")
        return target(inner) if inner is not None else None
    return None


def required(p):
    return not (isinstance(p["shape"], dict) and ("optional" in p["shape"] or "list" in p["shape"])) and p[
        "default_source"
    ] is None


def gloss(model):
    return model["description"].split("\n")[0].strip() or model["name"]


def is_enum(p):
    return any(r.startswith("one_of(") for r in p["rules"])


def route(p):
    """How a property's value can be evidenced, or None when it cannot."""
    shape = p["shape"]
    inner = shape.get("optional") if isinstance(shape, dict) and "optional" in shape else shape
    if is_enum(p):
        return "enum" if p.get("enum") else None
    if inner == "string":
        return "text"
    if inner == "boolean":
        return "bool"
    if inner == "integer":
        return "number"
    if target(inner):
        return "ref"
    return None


class Plan:
    """What the descriptor lets this adapter propose, and what it cannot."""

    def __init__(self, descriptor):
        self.models = {m["name"]: m for m in descriptor}
        refs = {target(p["shape"]) for m in descriptor for p in m["properties"]} - {None}
        embedded = {p["shape"]["embedded"] for m in descriptor for p in m["properties"] if isinstance(p["shape"], dict) and "embedded" in p["shape"]}
        self.entities, self.relations, self.records, self.blocked = {}, {}, {}, {}
        for m in descriptor:
            rel = m["semantics"].get("relation")
            if rel:
                why = self.relation_gap(m, rel)
                (self.blocked.__setitem__(m["name"], why) if why else self.relations.__setitem__(m["name"], rel))
            elif m["name"] in refs and self.nameable(m):
                self.entities[m["name"]] = [p for p in m["properties"] if route(p) == "text"]
            elif m["name"] not in embedded:
                gaps = self.gaps(m, ())
                if gaps:
                    self.blocked[m["name"]] = f"required fields without an evidence route: {gaps}"
                else:
                    self.records[m["name"]] = m

    def nameable(self, m):
        """A referenced model a span names: a required text anchor, and every
        other required field text too."""
        req = [p for p in m["properties"] if required(p)]
        return bool(req) and route(req[0]) == "text" and all(route(p) == "text" for p in req)

    def gaps(self, m, handled):
        return [
            p["name"] for p in m["properties"]
            if required(p) and p["name"] not in handled and route(p) is None and not self.embeddable(p["shape"])
        ]

    def relation_gap(self, m, rel):
        props = {p["name"]: p for p in m["properties"]}
        if len(rel["from"]) != 1 or len(rel["to"]) != 1 or len(rel["label"]) != 1:
            return "relation paths deeper than one property"
        if is_enum(props[rel["label"][0]]) and not rel["labels"]:
            return "label one_of values are not in the descriptor"
        gaps = self.gaps(m, (rel["from"][0], rel["to"][0], rel["label"][0]))
        return f"required fields without an evidence route: {gaps}" if gaps else None

    def embeddable(self, shape):
        """An embedded value whose every field may be absent."""
        if not (isinstance(shape, dict) and "embedded" in shape):
            return False
        return not any(required(p) for p in self.models[shape["embedded"]]["properties"])

    def free_labels(self, name):
        rel = self.relations[name]
        return None if rel["labels"] else rel["label"][0]


# ---------------------------------------------------------------- text


class Text:
    """Character text with UTF-8 byte coordinates, units and frames."""

    def __init__(self, content):
        self.s = content
        self.byte = [0]
        for ch in content:
            self.byte.append(self.byte[-1] + len(ch.encode()))

    def span(self, start, end):
        return {"start": self.byte[start], "end": self.byte[end], "text": self.s[start:end]}

    def units(self):
        """Sentence/line units; a quotation is its own nested unit."""
        out = []
        for m in re.finditer(r"[^\n.!?]+(?:[.!?]+|$)", self.s):
            a, b = m.start(), m.end()
            while a < b and self.s[a] in " \t'\"":
                a += 1
            while b > a and self.s[b - 1] in " \t":
                b -= 1
            if b > a:
                out.append((a, b))
        return out

    def quotes(self):
        return [(m.start(1), m.end(1)) for m in re.finditer(r"(?<=[\s,:])['\"“‘](.+?)['\"”’](?=[\s.,;]|$)", self.s)]


# ---------------------------------------------------------------- models


class Encoder:
    def __init__(self):
        from gliner2 import GLiNER2

        self.m = GLiNER2.from_pretrained(ENCODER.split("@")[0])

    def mentions(self, text, labels):
        if not labels:
            return {}
        r = self.m.extract(text, self.m.create_schema().entities(labels), threshold=SPAN_THRESHOLD, include_confidence=True, include_spans=True)
        return r["entities"]

    def records(self, text, model, anchor, fields):
        s = self.m.create_schema()
        b = s.structure(model, mode="natural", anchor=anchor)
        for f in fields:
            b = b.field(f, dtype="str")
        r = self.m.extract(text, s, threshold=SPAN_THRESHOLD, include_confidence=True, include_spans=True)
        return r.get(model) or []


class Scorer:
    """Closed-choice scorer: next-token probabilities over option letters."""

    def __init__(self):
        from mlx_lm import load

        self.model, self.tok = load(SCORER.split("@")[0])
        self.calls, self.source, self.cache, self.prefix = 0, "", None, True

    def begin(self, source):
        """Every choice about one source shares its text as a cached prefix."""
        import mlx.core as mx
        from mlx_lm.models.cache import make_prompt_cache

        self.source, self.cache = source, None
        if not self.prefix or os.environ.get("CASCADE_PREFIX") == "0":
            return
        head = self.render(f'Text: "{source}"\n\n\x00').split("\x00")[0]
        self.cache = make_prompt_cache(self.model)
        mx.eval(self.forward(self.tok.encode(head)))

    def pick(self, context, question, options, tail=()):
        """Probabilities over options + tail. Past MAX_OPTIONS the options run
        in heats, each with the tail, and the heat winners meet in a final;
        an option that lost its heat scores 0."""
        options, tail = list(options), list(tail)
        room = MAX_OPTIONS - len(tail)
        if len(options) <= room:
            return self.choose(context, question, options + tail)
        winners = []
        for i in range(0, len(options), room):
            heat = options[i : i + room]
            p = self.choose(context, question, heat + tail) if len(heat) + len(tail) >= 2 else [1.0]
            winners.append(i + max(range(len(heat)), key=lambda k: p[k]))
        final = self.pick(context, question, [options[w] for w in winners], tail)
        out = [0.0] * (len(options) + len(tail))
        for j, w in enumerate(winners):
            out[w] = final[j]
        for j in range(len(tail)):
            out[len(options) + j] = final[len(winners) + j]
        return out

    def generate(self, messages, max_tokens):
        """Greedy text for a chat; the extraction prefix cache is untouched."""
        from mlx_lm import generate

        prompt = self.tok.apply_chat_template(messages, add_generation_prompt=True, tokenize=False)
        return generate(self.model, self.tok, prompt, max_tokens=max(1, min(max_tokens, 4096)), verbose=False)

    def render(self, body):
        return self.tok.apply_chat_template([{"role": "user", "content": body}], add_generation_prompt=True, tokenize=False)

    def forward(self, ids):
        import mlx.core as mx

        return self.model(mx.array(ids)[None], cache=self.cache)[0, -1]

    def choose(self, context, question, options):
        import mlx.core as mx
        from mlx_lm.models.cache import trim_prompt_cache

        if not 2 <= len(options) <= MAX_OPTIONS:
            raise ValueError(f"a choice takes 2 to {MAX_OPTIONS} options, got {len(options)}; split it into heats")
        letters = [chr(65 + i) for i in range(len(options))]
        body = f"{context}\n\n{question}\n" + "\n".join(f"{l}) {o}" for l, o in zip(letters, options)) + "\nAnswer with the letter only."
        text = f'Text: "{self.source}"\n\n' if self.source else ""
        prompt = self.render(text + body)
        ids = mx.array([self.tok.encode(l, add_special_tokens=False)[0] for l in letters])
        if self.cache is None:
            logits = self.model(mx.array(self.tok.encode(prompt))[None])[0, -1]
            p = mx.softmax(logits[ids].astype(mx.float32)).tolist()
        else:
            head = self.render(text + "\x00").split("\x00")[0]
            tail = self.tok.encode(prompt[len(head) :], add_special_tokens=False)
            p = mx.softmax(self.forward(tail)[ids].astype(mx.float32)).tolist()
            trim_prompt_cache(self.cache, len(tail))
        self.calls += 1
        if os.environ.get("CASCADE_DECISIONS"):
            with open(os.environ["CASCADE_DECISIONS"], "a") as out:
                out.write(json.dumps({"context": context, "question": question, "options": options, "p": p}) + "\n")
        if os.environ.get("CASCADE_TRACE"):
            log(f"? {question.splitlines()[-1]} | {context.splitlines()[-1][:100]}")
            for o, x in sorted(zip(options, p), key=lambda z: -z[1])[:3]:
                log(f"    {x:.3f} {o}")
        return p


# ---------------------------------------------------------------- cascade


class Cascade:
    def __init__(self, plan, encoder, scorer):
        self.plan, self.enc, self.llm = plan, encoder, scorer

    def run(self, source):
        self.t = Text(source["content"])
        self.records, self.mentions, self.minted = [], [], 0
        self.frames = [dict(f, _range=position(f["passage"]), _given=True) for f in source.get("frames", [])]
        clock = time.time()
        self.llm.begin(source["content"])
        prefix = time.time()
        self.entity_pass()
        spans = time.time()
        self.frame_pass(source)
        self.relation_pass()
        self.record_pass()
        log(f"prefix_s={prefix - clock:.2f} entities_s={spans - prefix:.2f} choices_s={time.time() - spans:.2f}")
        return self.records, self.frames

    # Entities: encoder spans, LLM picks the antecedent for partial names.

    def entity_pass(self):
        labels = {m.lower(): gloss(self.plan.models[m]) for m in self.plan.entities}
        for name in self.plan.relations:
            label = self.plan.free_labels(name)
            if label:
                labels[label] = f"{label} of a {name}: {gloss(self.plan.models[name])}"
        found = self.enc.mentions(self.t.s, labels)
        by_label = {m.lower(): m for m in self.plan.entities}
        typed = {}
        for l, xs in found.items():
            for x in xs:
                typed.setdefault((x["start"], x["end"]), []).append((l, x["confidence"]))
        spans = sorted((a, b, *self.typed(a, b, ls, labels)) for (a, b), ls in typed.items())
        spans.sort(key=lambda x: (-(x[1] - x[0]), x[0]))
        for a, b, label, conf in spans:
            if label not in by_label:
                self.mentions.append({"start": a, "end": b, "kind": label, "record": None, "score": conf})
                continue
            model = by_label[label]
            text = self.t.s[a:b]
            rec = self.antecedent(model, a, b) if any(r["model"] == model for r in self.records) else None
            if rec is ABSTAIN:
                log(f"abstain {model} {text!r}@{a}: no candidate with margin")
                self.new_entity(model, a, b, conf)["resolution"] = {"kind": "abstain"}
                continue
            if rec is None:
                rec = self.new_entity(model, a, b, conf)
            if rec is not None:
                self.mentions.append({"start": a, "end": b, "kind": model, "record": rec["local_id"], "score": conf})
        self.attributes()

    def typed(self, a, b, labels, glosses):
        """A span the encoder gave several types: the LLM picks one of them."""
        if len(labels) == 1:
            return labels[0]
        names = [l for l, _ in labels]
        p = self.llm.pick(f'Mention: "{self.t.s[a:b]}" at character {a}.', f'In the text, what is "{self.t.s[a:b]}"?', [f"{l}: {glosses[l]}" for l in names])
        k = max(range(len(names)), key=lambda i: p[i])
        return names[k], labels[k][1]

    def new_entity(self, model, a, b, conf):
        texts = self.plan.entities[model]
        anchor = next(p for p in texts if required(p))["name"] if any(required(p) for p in texts) else texts[0]["name"]
        rec = {"local_id": self.mint(), "model": model, "fields": [self.field(anchor, self.t.s[a:b], [(a, b)], score=conf)], "identities": [], "resolution": {"kind": "new"}}
        rec["_anchor"] = (a, b)
        self.records.append(rec)
        return rec

    def mint(self):
        self.minted += 1
        return f"r{self.minted}"

    def antecedent(self, model, a, b):
        text = self.t.s[a:b]
        words = set(text.lower().split())
        prior = [r for r in self.records if r["model"] == model and words & set(r["fields"][0]["value"].lower().split())]
        if not prior:
            return None
        if any(r["fields"][0]["value"] == text for r in prior):
            return next(r for r in prior if r["fields"][0]["value"] == text)
        options = [r["fields"][0]["value"] for r in prior] + ["someone new, not listed", "cannot tell"]
        p = self.llm.pick(f'Mention: "{text}" at character {a}.', f'In the text, who is "{text}" at character {a}?', options[: len(prior)], options[len(prior) :])
        ranked = sorted(range(len(options)), key=lambda i: -p[i])
        if ranked[0] < len(prior) and p[ranked[0]] - p[ranked[1]] >= MARGIN:
            return prior[ranked[0]]
        if ranked[0] == len(prior) and max(p[: len(prior)]) <= 1 - ACCEPT - MARGIN / 2:
            return None
        return ABSTAIN

    def attributes(self):
        """Other text fields and identity keys of entity records, by structure."""
        for model, texts in self.plan.entities.items():
            recs = [r for r in self.records if r["model"] == model]
            if not recs:
                continue
            anchor = recs[0]["fields"][0]["property"]
            extra = [p["name"] for p in texts if p["name"] != anchor]
            got = self.enc.records(self.t.s, model, anchor, [anchor] + extra) if extra else []
            for g in got:
                head = g.get(anchor)
                rec = head and next((r for r in recs if r["_anchor"][0] <= head["start"] < r["_anchor"][1] or self.points_to(r, head)), None)
                if not rec:
                    continue
                for f in extra:
                    v = g.get(f)
                    if v and v["confidence"] >= SPAN_THRESHOLD and not any(x["property"] == f for x in rec["fields"]):
                        rec["fields"].append(self.field(f, v["text"], [(v["start"], v["end"])], score=v["confidence"]))
            for rec in recs:
                missing = [p["name"] for p in texts if required(p) and not any(f["property"] == p["name"] for f in rec["fields"])]
                if missing:
                    log(f"drop {rec['local_id']} {model}: no evidence for {missing}")
                    self.records.remove(rec)
                    self.mentions = [m for m in self.mentions if m["record"] != rec["local_id"]]
                else:
                    self.identities(rec)

    def points_to(self, rec, span):
        return any(m["record"] == rec["local_id"] and m["start"] <= span["start"] < m["end"] for m in self.mentions)

    def identities(self, rec):
        for key in self.plan.models[rec["model"]]["semantics"]["identities"]:
            f = next((f for f in rec["fields"] if [f["property"]] == key["path"]), None)
            if f:
                rec["identities"].append({"identity": {"namespace": key["namespace"], "key": f["value"]}, "evidence": f["evidence"], "frame": f.get("frame")})

    # Frames: chat turns and quotations; the LLM picks a quote's speaker.

    def frame_pass(self, source):
        """Chat turns and quotations not already framed by the source."""
        people = [m for m in self.mentions if m["record"]]
        turns = []
        for m in people:
            line_start = self.t.s.rfind("\n", 0, m["start"]) + 1
            before = self.t.s[line_start : m["start"]].strip()
            if self.t.s[m["end"] : m["end"] + 1] == ":" and (not before or before[-1] in ".!?"):
                turns.append(m)
        turns.sort(key=lambda m: m["start"])
        for i, m in enumerate(turns):
            end = turns[i + 1]["start"] if i + 1 < len(turns) else len(self.t.s)
            while end > m["start"] and self.t.s[end - 1] in " \n":
                end -= 1
            self.add_frame(m["start"], end, None, m["record"])
        for a, b in self.t.quotes():
            parent = self.innermost(a, b)
            if any(f["_range"] == (a, b) for f in self.frames):
                continue
            speaker = self.choose_speaker(a, b, quoted=True)
            self.add_frame(a, b, parent["id"] if parent else None, speaker)

    def add_frame(self, a, b, parent, speaker):
        taken = {f["id"] for f in self.frames}
        fid = next(f"f{i}" for i in range(1, len(taken) + 2) if f"f{i}" not in taken)
        self.frames.append({"id": fid, "passage": self.evidence(a, b), "parent": parent, "speaker": speaker, "_range": (a, b)})

    def innermost(self, a, b):
        inside = [f for f in self.frames if f["_range"][0] <= a and b <= f["_range"][1]]
        return min(inside, key=lambda f: f["_range"][1] - f["_range"][0]) if inside else None

    def choose_speaker(self, a, b, quoted=False):
        """The person record that 'I'/'my' in this range refers to, or None."""
        people = {}
        for m in self.mentions:
            if m["record"] and m["kind"] in self.person_models():
                people.setdefault(m["record"], self.name(m["record"]))
        if not people:
            return None
        ids = list(people)
        options = [people[i] for i in ids] + ["the unnamed author of the text", "cannot tell"]
        what = "this quotation" if quoted else "this passage"
        p = self.llm.pick(f'Passage: "{self.t.s[a:b]}"', f'Who is speaking in {what} (who do "I", "my" and "we" refer to)?', options[: len(ids)], options[len(ids) :])
        best = max(range(len(options)), key=lambda i: p[i])
        return ids[best] if best < len(ids) and p[best] >= ACCEPT else None

    def model_of(self, rid):
        return next(r["model"] for r in self.records if r["local_id"] == rid)

    def referent(self, a, b):
        """Who a third-person pronoun in this sentence names: one of the people
        named in it or the two sentences before, or None (abstain)."""
        hit = THIRD_PERSON.search(self.t.s, a, b)
        if not hit:
            return None
        units = [u for u in self.t.units() if u[0] <= a]
        lo = units[-3][0] if len(units) >= 3 else 0
        near = [m for m in self.mentions if m["record"] and m["kind"] in self.person_models() and lo <= m["start"] < b and m["start"] < hit.start()]
        ids = list(dict.fromkeys(m["record"] for m in reversed(near)))
        if not ids:
            return None
        context = f'Passage: "{self.t.s[lo:b]}"'
        p = self.llm.pick(context, f'Who does "{hit.group()}" at character {hit.start()} refer to?', [self.name(i) for i in ids], ["someone not named here", "cannot tell"])
        ranked = sorted(range(len(p)), key=lambda i: -p[i])
        if ranked[0] < len(ids) and p[ranked[0]] - p[ranked[1]] >= MARGIN:
            return ids[ranked[0]], (hit.start(), hit.end())
        return None

    def person_models(self):
        return {self.plan.relations[n]["from"] and target(self.prop(n, self.plan.relations[n]["from"][0])["shape"]) for n in self.plan.relations}

    def prop(self, model, name):
        return next(p for p in self.plan.models[model]["properties"] if p["name"] == name)

    def name(self, rid):
        """A record's readable label: its first text value that is no reference."""
        ids = {r["local_id"] for r in self.records}
        r = next(r for r in self.records if r["local_id"] == rid)
        return next((f["value"] for f in r["fields"] if isinstance(f["value"], str) and f["value"] not in ids), rid)

    def speaker_of(self, a, b):
        f = self.innermost(a, b)
        if f is not None:
            return f["speaker"]
        if not hasattr(self, "_note_speaker"):
            self._note_speaker = self.choose_speaker(0, len(self.t.s))
        return self._note_speaker

    # Relations: the LLM scores every labelled reading of a candidate pair.

    def relation_pass(self):
        for name, rel in self.plan.relations.items():
            frm, to, label = rel["from"][0], rel["to"][0], rel["label"][0]
            ft, tt = target(self.prop(name, frm)["shape"]), target(self.prop(name, to)["shape"])
            free = self.plan.free_labels(name)
            for a, b in self.t.units():
                for sub in self.sub_units(a, b):
                    self.relate(name, frm, to, label, ft, tt, free, *sub)

    def sub_units(self, a, b):
        """A unit split at frame boundaries, so no anchor crosses a frame."""
        cuts = sorted({a, b} | {x for f in self.frames for x in f["_range"] if a < x < b})
        return [(x, y) for x, y in zip(cuts, cuts[1:]) if self.t.s[x:y].strip(" '\"“”‘’,.:")]

    def relate(self, name, frm, to, label, ft, tt, free, a, b):
        local = [m for m in self.mentions if m["record"] and a <= m["start"] and m["end"] <= b]
        speaker = self.speaker_of(a, b) if FIRST_PERSON.search(self.t.s[a:b]) else None
        pronoun = FIRST_PERSON.search(self.t.s, a, b) if speaker else None

        referent = self.referent(a, b)

        def holders(model, anywhere):
            pool = self.mentions if anywhere else local
            ids = {m["record"]: (m["start"], m["end"]) for m in pool if m["kind"] == model and m["record"]}
            if speaker and model in self.person_models() and pronoun:
                ids.setdefault(speaker, (pronoun.start(), pronoun.end()))
            if referent and self.model_of(referent[0]) == model:
                ids.setdefault(*referent)
            return ids

        froms, tos = holders(ft, False), holders(tt, free is not None)
        ctx = f'Sentence: "{self.t.s[a:b]}"' + (f'\nIn this sentence "I"/"my"/"our" refer to {self.name(speaker)}.' if speaker else "")
        question = (
            f"{self.plan.models[name]['description']}\n\nEach option reads {frm} → {label} → {to}. "
            "Which of these does the sentence itself explicitly state? Do not infer from other sentences or world knowledge."
        )
        rel = self.plan.relations[name]
        if free:
            labels = [m for m in self.mentions if m["kind"] == free and a <= m["start"] and m["end"] <= b]
            pairs = [(x, y) for x in froms for y in tos if x != y]
            for x, y in pairs:
                if not labels:
                    break
                opts = [f"{frm}={self.name(x)}, {to}={self.name(y)}, {label}={self.t.s[l['start']:l['end']]}" for l in labels]
                p = self.llm.pick(ctx, question, opts, ["none of these"])
                best = max(range(len(p)), key=lambda i: p[i])
                if best < len(labels) and p[best] >= ACCEPT:
                    l = labels[best]
                    self.emit(name, frm, to, label, (x, froms[x]), (y, tos[y]), self.t.s[l["start"] : l["end"]], (l["start"], l["end"]), p[best], a, b, opts[best])
            return
        ids = sorted(set(froms) | set(tos))
        for i, x in enumerate(ids):
            for y in ids[i + 1 :]:
                readings = [(s, o, v["value"], v["forward"] or [v["value"]]) for v in rel["labels"] for s, o in ((x, y), (y, x)) if s in froms and o in tos]
                if not readings:
                    continue
                opts = [f"{self.name(s)} → {self.worded(w)} → {self.name(o)}" for s, o, v, w in readings]
                p = self.llm.pick(ctx, question, opts, ["none of these is explicitly stated"])
                best = max(range(len(p)), key=lambda k: p[k])
                if best < len(readings) and p[best] >= ACCEPT:
                    s, o, v, _ = readings[best]
                    cue = self.cue(rel, v, a, b)
                    self.emit(name, frm, to, label, (s, {**froms, **tos}[s]), (o, {**froms, **tos}[o]), v, cue, p[best], a, b, opts[best])

    def worded(self, words):
        """A closed label as its first declared word, with the others as aliases."""
        return words[0] + (f" ({', '.join(words[1:])})" if len(words) > 1 else "")

    def cue(self, rel, value, a, b):
        """The declared linguistic label that evidences a closed label, else the sentence."""
        words = next(l["forward"] for l in rel["labels"] if l["value"] == value) or [value]
        for w in words:
            m = re.search(rf"\b{re.escape(w)}\b", self.t.s[a:b], re.I)
            if m:
                return (a + m.start(), a + m.end())
        return (a, b)

    # Records: the LLM names which declared record a sentence states, then
    # fills each field from spans, offered entities or declared values.

    def record_pass(self):
        kinds = list(self.plan.records)
        if not kinds:
            return
        opts = [f"{m}: {gloss(self.plan.models[m])}" for m in kinds]
        for a, b in self.t.units():
            for x, y in self.sub_units(a, b):
                x, y = self.trimmed(x, y)
                if y <= x:
                    continue
                p = self.llm.pick(f'Sentence: "{self.t.s[x:y]}"', "Which kind of record does this sentence itself state, if any?", opts, ["none of these"])
                best = max(range(len(p)), key=lambda i: p[i])
                if best < len(kinds) and p[best] >= ACCEPT:
                    self.fill(kinds[best], x, y, p[best])

    def trimmed(self, a, b):
        """A sentence without its chat-turn speaker prefix."""
        for f in self.frames:
            if f["_range"][0] == a and f["speaker"]:
                colon = self.t.s.find(":", a, b)
                if colon >= 0:
                    a = colon + 1
        while a < b and self.t.s[a] in " '\"“‘":
            a += 1
        return a, b

    def fill(self, model, a, b, chosen):
        m = self.plan.models[model]
        ctx = f'Sentence: "{self.t.s[a:b]}"'
        texts = [p["name"] for p in m["properties"] if route(p) == "text"]
        spans = self.enc.records(self.t.s[a:b], model, texts[0], texts) if texts else []
        found = spans[0] if spans else {}
        fields, missing = [], []
        for p in m["properties"]:
            value = self.value_of(model, p, found, ctx, a, b)
            if value is None:
                if required(p) and not self.plan.embeddable(p["shape"]):
                    missing.append(p["name"])
                continue
            fields.append(value)
        if missing:
            log(f"drop {model} at {a}: no evidence for {missing}")
            return
        kept = []
        for f in fields:
            if f["value"] == {}:
                kept.append(f)
                continue
            said = self.llm.pick(ctx, f"In a {model}, does the sentence itself state that {f['property']} is {self.shown(f['value'])}?", ["yes", "no"])
            if said[0] - said[1] >= MARGIN:
                kept.append(f)
            elif required(self.prop(model, f["property"])):
                log(f"reject {model} at {a}: {f['property']}={self.shown(f['value'])} is not stated")
                return
        fields = kept
        claim = f"{model} with " + ", ".join(f"{f['property']}={self.shown(f['value'])}" for f in fields)
        q = self.qualifiers(a, b, claim)
        for f in fields:
            f.update(q)
        self.records.append({"local_id": self.mint(), "model": model, "fields": fields, "identities": [], "resolution": {"kind": "new"}, "_score": chosen})

    def shown(self, v):
        return self.name(v) if isinstance(v, str) and any(r["local_id"] == v for r in self.records) else v

    def value_of(self, model, p, found, ctx, a, b):
        """One field proposal, or None when the sentence does not state it."""
        kind, name = route(p), p["name"]
        if self.plan.embeddable(p["shape"]):
            return self.field(name, {}, [(a, b)]) if required(p) else None
        optional = [] if required(p) else ["not stated"]
        if kind == "text":
            v = found.get(name)
            if v and self.named(a + v["start"], a + v["end"]):
                log(f"skip {model}.{name}: {v['text']!r} names an entity, not text")
                v = None
            if v and v.get("confidence", 0) >= SPAN_THRESHOLD:
                return self.field(name, v["text"], [(a + v["start"], a + v["end"])], score=v["confidence"])
            if not required(p):
                return None
            cands = self.clauses(a, b)
            pr = self.llm.pick(ctx, f"In a {model}, which part of the sentence is the {name}?", [self.t.s[x:y] for x, y in cands], ["not stated"])
            k = max(range(len(pr)), key=lambda i: pr[i])
            if k == len(cands) or pr[k] < ACCEPT:
                return None
            x, y = cands[k]
            return self.field(name, self.t.s[x:y], [(x, y)], score=pr[k])
        if kind == "ref":
            ids, where = self.offered(target(p["shape"]), a, b)
            if not ids:
                return None
            pr = self.llm.pick(ctx, f"In this {model}, who or what is the {name}?", [self.name(i) for i in ids], optional)
            k = max(range(len(pr)), key=lambda i: pr[i])
            if k >= len(ids) or pr[k] < ACCEPT:
                return None
            return self.field(name, ids[k], [where[ids[k]]], score=pr[k])
        if kind == "enum":
            vals = p["enum"]
            pr = self.llm.pick(ctx, f"For this {model}, which {name} does the sentence state?", vals, optional)
            k = max(range(len(pr)), key=lambda i: pr[i])
            return self.field(name, vals[k], [(a, b)], score=pr[k]) if k < len(vals) and pr[k] >= ACCEPT else None
        if kind == "bool":
            pr = self.llm.choose(ctx, f"For this {model}, is {name} true or false according to the sentence?", ["true", "false"] + optional)
            k = max(range(len(pr)), key=lambda i: pr[i])
            return self.field(name, k == 0, [(a, b)], score=pr[k]) if k < 2 and pr[k] >= ACCEPT else None
        if kind == "number" and not name.endswith("_ms"):
            nums = [(x.start(), x.end()) for x in re.finditer(r"\d[\d,]*", self.t.s[a:b])]
            nums = [(a + x, a + y) for x, y in nums]
            if not nums:
                return None
            pr = self.llm.pick(ctx, f"In this {model}, which number is the {name}?", [self.t.s[x:y] for x, y in nums], ["not stated"])
            k = max(range(len(pr)), key=lambda i: pr[i])
            if k == len(nums) or pr[k] < ACCEPT:
                return None
            x, y = nums[k]
            return self.field(name, int(self.t.s[x:y].replace(",", "")), [(x, y)], score=pr[k])
        return None

    def named(self, x, y):
        """Whether a span is exactly an entity mention the cascade kept."""
        return any(m["record"] and m["start"] == x and m["end"] == y for m in self.mentions)

    def clauses(self, a, b):
        """Candidate value spans: the sentence and its comma/conjunction parts."""
        s, out = self.t.s, {(a, b)}
        cuts = [a] + [a + m.end() for m in re.finditer(r",\s*|;\s*|\s+(?:and|but|until|so|then)\s+", s[a:b])] + [b]
        for x, y in zip(cuts, cuts[1:]):
            y2 = y
            while y2 > x and s[y2 - 1] in " ,;.?!":
                y2 -= 1
            if y2 > x:
                out.add((x, y2))
        return sorted(out)[:15]

    def offered(self, model, a, b):
        """Records of a model this sentence can refer to, with where each is evidenced."""
        where = {}
        for m in self.mentions:
            if m["record"] and m["kind"] == model:
                inside = a <= m["start"] and m["end"] <= b
                if inside or m["record"] not in where:
                    where[m["record"]] = (m["start"], m["end"]) if inside else None
        speaker = self.speaker_of(a, b) if FIRST_PERSON.search(self.t.s[a:b]) else None
        pronoun = FIRST_PERSON.search(self.t.s, a, b)
        if speaker and pronoun and any(r["local_id"] == speaker and r["model"] == model for r in self.records):
            where[speaker] = (pronoun.start(), pronoun.end())
        referent = self.referent(a, b)
        if referent and self.model_of(referent[0]) == model:
            where[referent[0]] = referent[1]
        for r in self.records:
            if r["model"] == model and r["local_id"] not in where:
                where[r["local_id"]] = None
        ids = [i for i in where if where[i] is not None] + [i for i in where if where[i] is None]
        return ids, {i: where[i] or self.evidence_range(i) for i in ids}

    def evidence_range(self, rid):
        """Where a record is named, for a reference made outside its own mention."""
        m = next((m for m in self.mentions if m["record"] == rid), None)
        if m:
            return (m["start"], m["end"])
        r = next(r for r in self.records if r["local_id"] == rid)
        return position(r["fields"][0]["evidence"][0])

    def emit(self, name, frm, to, label, subj, obj, value, cue, score, a, b, claim):
        if any(r["model"] == name and self.same(r, frm, subj[0], to, obj[0], label, value) for r in self.records):
            return
        q = self.qualifiers(a, b, claim)
        fields = [
            self.field(frm, subj[0], [subj[1]], **q),
            self.field(label, value, [cue], score=score, **q),
            self.field(to, obj[0], [obj[1]], **q),
        ]
        for p in self.plan.models[name]["properties"]:
            if not required(p) or p["name"] in (frm, to, label):
                continue
            if route(p) == "bool":
                said = self.llm.pick(f'Sentence: "{self.t.s[a:b]}"', f"Consider: {claim}. Is {p['name']} true or false according to the sentence?", ["true", "false"])
                value = said[0] >= said[1]
                if not value and q["factuality"] == "CT-":
                    q = dict(q, factuality="CT+")
                fields.append(self.field(p["name"], value, [cue], score=max(said)))
            else:
                fields.append(self.field(p["name"], {}, [cue]))
        for f in fields:
            f.update(q)
        self.records.append({"local_id": self.mint(), "model": name, "fields": fields, "identities": []})

    def same(self, r, frm, s, to, o, label, v):
        vals = {f["property"]: f["value"] for f in r["fields"]}
        return vals.get(frm) == s and vals.get(to) == o and vals.get(label) == v

    def qualifiers(self, a, b, claim):
        ctx = f'Sentence: "{self.t.s[a:b]}"'
        keys = list(SPEECH_ACTS)
        p = self.llm.choose(ctx, f"Consider only this claim: {claim}. How does the sentence present that claim itself (not other events in the sentence)?", [SPEECH_ACTS[k] for k in keys])
        act = keys[max(range(len(keys)), key=lambda i: p[i])]
        q = self.llm.choose(ctx, f"Consider only this claim: {claim}. Does the sentence affirm that claim, or deny that claim itself (a negated event elsewhere in the sentence does not count)?", ["affirms the claim", "denies the claim"])
        return {"speech_act": act, "factuality": FACTUALITY[act] if q[0] >= q[1] else "CT-"}

    def evidence(self, a, b):
        """One passage: its code-point position and its quote with context."""
        s = self.t.s
        return {"selector": [
            {"kind": "TextPositionSelector", "start": a, "end": b},
            {"kind": "TextQuoteSelector", "exact": s[a:b], "prefix": s[max(0, a - QUOTE_CONTEXT) : a], "suffix": s[b : b + QUOTE_CONTEXT]},
        ]}

    def field(self, prop, value, ranges, speech_act="assert", factuality="CT+", score=None):
        f = {"property": prop, "value": value, "evidence": [self.evidence(a, b) for a, b in ranges], "factuality": factuality, "speech_act": speech_act}
        frame = self.innermost(*ranges[0]) if hasattr(self, "frames") else None
        f["frame"] = frame["id"] if frame else None
        if score is not None:
            f["score"] = round(min(1.0, max(0.0, score)), 4)
        return f


def finish(records, frames):
    """Private keys are dropped; frames the source already gave are not proposed."""
    return [{k: v for k, v in r.items() if not k.startswith("_")} for r in records], [
        {k: v for k, v in f.items() if not k.startswith("_")} for f in frames if not f.get("_given")
    ]


def reframe(cascade):
    for r in cascade.records:
        for f in r["fields"]:
            fr = cascade.innermost(*position(f["evidence"][0]))
            f["frame"] = fr["id"] if fr else None
        for i in r["identities"]:
            fr = cascade.innermost(*position(i["evidence"][0]))
            i["frame"] = fr["id"] if fr else None


def position(evidence):
    p = next(s for s in evidence["selector"] if s["kind"] == "TextPositionSelector")
    return p["start"], p["end"]


def requested(stdin, catalog_path):
    if "input" in stdin:
        return stdin
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from request import request

    return request(stdin, json.load(open(catalog_path)), MODEL_ID)


class Models:
    """Loaded once per process; a resident service keeps them warm."""

    def __init__(self):
        t = time.time()
        self.enc, self.llm = Encoder(), Scorer()
        self.load_s = time.time() - t


def extract(req, models=None):
    """One C01 ExtractionResult; a failure is a result, never an exception."""
    LOG.clear()
    result = {
        "contract": 2,
        "request": req["request"],
        "source": req["input"]["source"],
        "schema": req["catalog"]["fingerprint"],
        "extractor": req["extractor"],
    }
    stage = "extractor.setup"
    try:
        plan = Plan(req["catalog"]["descriptor"])
        for m, why in plan.blocked.items():
            log(f"skip {m}: {why}")
        models = models or Models()
        stage = "extractor.run"
        started, calls = time.time(), models.llm.calls
        c = Cascade(plan, models.enc, models.llm)
        c.run(req["input"])
        reframe(c)
        records, frames = finish(c.records, c.frames)
        result.update(status="complete", records=records, proposed_frames=frames)
        log(f"load_s={models.load_s:.1f} extract_s={time.time() - started:.1f} llm_calls={models.llm.calls - calls} records={len(records)} frames={len(frames)}")
    except Exception as e:
        result.update(status="failed", records=[], problems=[{"code": stage, "message": f"{type(e).__name__}: {e}"[:4096]}])
        log(f"failed: {type(e).__name__}: {e}")
    log(f"maxrss_mb={resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1e6:.0f}")
    return result, list(LOG)


def received(conn):
    """One request: bytes up to the first newline, or to end of stream."""
    data = b""
    while b"\n" not in data:
        chunk = conn.recv(1 << 16)
        if not chunk:
            break
        data += chunk
    return data.split(b"\n", 1)[0]


def answered(body, models):
    """A generate op's text, or an extraction's result and log."""
    if body.get("op") == "generate":
        return {"text": models.llm.generate(body["messages"], int(body.get("max_tokens", 256)))}
    if body.get("op") == "choose":
        models.llm.source, models.llm.cache = "", None
        return {"p": models.llm.choose(body["context"], body["question"], body["options"])}
    models.llm.prefix = body.get("prefix", True)
    result, logs = extract(body["request"], models)
    return {"result": result, "log": logs}


def serve():
    """A local Unix-socket service, served in order: one JSON line in, one
    JSON line out, per connection. `{"op":"generate","messages":[…],
    "max_tokens":n}` answers `{"text":…}` (greedy); `{"op":"choose","context","question","options"}` answers `{"p":[…]}`;
    `{"request":…}` answers an extraction. A failure answers `{"error":…}`."""
    import socket

    models = Models()
    if os.path.exists(SOCKET):
        os.replace(SOCKET, SOCKET + ".stale")
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.bind(SOCKET)
    os.chmod(SOCKET, 0o600)
    s.listen(4)
    print(f"cascade serving on {SOCKET} (load_s={models.load_s:.1f})", file=sys.stderr, flush=True)
    while True:
        conn, _ = s.accept()
        with conn:
            data = received(conn)
            if not data.strip():
                continue
            started = time.time()
            try:
                body = json.loads(data)
                answer = answered(body, models)
            except Exception as e:
                body, answer = {}, {"error": f"{type(e).__name__}: {e}"}
            op = body.get("op", "extract")
            print(
                f"{time.strftime('%H:%M:%S')} {op} bytes={len(data)} options={len(body.get('options', []))} "
                f"s={time.time() - started:.2f} {answer.get('error', 'ok')}",
                file=sys.stderr,
                flush=True,
            )
            try:
                conn.sendall(json.dumps(answer, ensure_ascii=False).encode() + b"\n")
            except OSError as e:
                print(f"client gone: {e}", file=sys.stderr, flush=True)


def remote(req, prefix=True):
    """The resident service's answer, or None when no service is listening."""
    import socket

    if not os.path.exists(SOCKET):
        return None
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.connect(SOCKET)
    except OSError:
        return None
    with s:
        s.sendall(json.dumps({"request": req, "prefix": prefix}, ensure_ascii=False).encode() + b"\n")
        s.shutdown(socket.SHUT_WR)
        return json.loads(b"".join(iter(lambda: s.recv(1 << 16), b"")))


def main():
    args = sys.argv[1:]
    if "--serve" in args:
        return serve()
    stdin = json.load(sys.stdin)
    req = requested(stdin, args[args.index("--catalog") + 1] if "--catalog" in args else None)
    answer = None if "--local" in args else remote(req, "--no-prefix" not in args)
    if answer is None:
        result, logs = extract(req)
    elif "error" in answer:
        print(f"service: {answer['error']}", file=sys.stderr)
        return 1
    else:
        result, logs = answer["result"], ["served"] + answer["log"]
    print("\n".join(logs), file=sys.stderr)
    json.dump(result, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
