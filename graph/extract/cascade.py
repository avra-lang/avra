"""Local extraction cascade: an encoder proposes spans, a small LLM only
scores closed choices, and every proposal is an exact source anchor.

usage: python cascade.py [--catalog SCHEMA_JSON] < request_or_envelope.json > result.json

stdin is a C01 ExtractionRequest, or a bare I01 SourceEnvelope with
--catalog naming the app's `{"op":"schema"}` answer. stdout is one C01
ExtractionResult. Timings, peak RSS and skipped models go to stderr.
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
FIRST_PERSON = re.compile(r"\b(I|I'm|I'll|I've|me|my|My|mine|we|We|our|Our|us)\b")
MODALITIES = {
    "asserted": "stated as a current fact by the speaker",
    "reported": "reported as what someone else said",
    "planned": "a plan or intention for the future",
    "requested": "a request asked of someone",
    "conditional": "holds only under a stated condition",
    "draft": "a draft or tentative value",
}

os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")


def log(*parts):
    print(*parts, file=sys.stderr)


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


class Plan:
    """What the descriptor lets this adapter propose, and what it cannot."""

    def __init__(self, descriptor):
        self.models = {m["name"]: m for m in descriptor}
        refs = {target(p["shape"]) for m in descriptor for p in m["properties"]} - {None}
        embedded = {p["shape"]["embedded"] for m in descriptor for p in m["properties"] if isinstance(p["shape"], dict) and "embedded" in p["shape"]}
        self.entities, self.relations, self.blocked = {}, {}, {}
        for m in descriptor:
            rel = m["semantics"].get("relation")
            if rel:
                why = self.relation_gap(m, rel)
                (self.blocked.__setitem__(m["name"], why) if why else self.relations.__setitem__(m["name"], rel))
            elif m["name"] in refs:
                texts = [p for p in m["properties"] if p["shape"] in ("string", {"optional": "string"}) and "one_of(value)" not in p["rules"]]
                gaps = [p["name"] for p in m["properties"] if required(p) and p not in texts]
                if gaps or not texts:
                    self.blocked[m["name"]] = f"required non-text fields {gaps}"
                else:
                    self.entities[m["name"]] = texts
            elif m["name"] not in embedded:
                self.blocked[m["name"]] = "no relation binding and not a reference target"

    def relation_gap(self, m, rel):
        props = {p["name"]: p for p in m["properties"]}
        if len(rel["from"]) != 1 or len(rel["to"]) != 1 or len(rel["label"]) != 1:
            return "relation paths deeper than one property"
        label = props[rel["label"][0]]
        if "one_of(value)" in label["rules"] and not rel["labels"]:
            return "label one_of values are not in the descriptor"
        for p in m["properties"]:
            if p["name"] in (rel["from"][0], rel["to"][0], rel["label"][0]) or not required(p):
                continue
            if not self.embeddable(p["shape"]):
                return f"required field {p['name']} has no evidence route"
        return None

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
        self.calls = 0

    def choose(self, context, question, options):
        import mlx.core as mx

        letters = [chr(65 + i) for i in range(len(options))]
        body = f"{context}\n\n{question}\n" + "\n".join(f"{l}) {o}" for l, o in zip(letters, options)) + "\nAnswer with the letter only."
        prompt = self.tok.apply_chat_template([{"role": "user", "content": body}], add_generation_prompt=True, tokenize=False)
        logits = self.model(mx.array(self.tok.encode(prompt))[None])[0, -1]
        ids = mx.array([self.tok.encode(l, add_special_tokens=False)[0] for l in letters])
        self.calls += 1
        p = mx.softmax(logits[ids].astype(mx.float32)).tolist()
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
        self.records, self.frames, self.mentions, self.minted = [], [], [], 0
        self.entity_pass()
        self.frame_pass(source)
        self.relation_pass()
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
        spans = sorted(
            ((x["start"], x["end"], l, x["confidence"]) for l, xs in found.items() for x in xs),
            key=lambda x: (-(x[1] - x[0]), x[0]),
        )
        for a, b, label, conf in spans:
            if label not in by_label:
                self.mentions.append({"start": a, "end": b, "kind": label, "record": None, "score": conf})
                continue
            model = by_label[label]
            text = self.t.s[a:b]
            rec = self.antecedent(model, a, b) if any(r["model"] == model for r in self.records) else None
            if rec is None:
                rec = self.new_entity(model, a, b, conf)
            if rec is not None:
                self.mentions.append({"start": a, "end": b, "kind": model, "record": rec["local_id"], "score": conf})
        self.attributes()

    def new_entity(self, model, a, b, conf):
        texts = self.plan.entities[model]
        anchor = next(p for p in texts if required(p))["name"] if any(required(p) for p in texts) else texts[0]["name"]
        rec = {"local_id": self.mint(), "model": model, "fields": [self.field(anchor, self.t.s[a:b], [(a, b)], score=conf)], "identities": [], "candidates": []}
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
        options = [r["fields"][0]["value"] for r in prior] + ["someone else, not listed"]
        ctx = f'Text: "{self.t.s}"'
        p = self.llm.choose(ctx, f'In the text, who is "{text}" at character {a}?', options)
        best = max(range(len(options)), key=lambda i: p[i])
        return prior[best] if best < len(prior) and p[best] >= ACCEPT else None

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
                rec["identities"].append({"identity": {"namespace": key["namespace"], "key": f["value"]}, "spans": f["spans"], "frame": f.get("frame")})

    # Frames: chat turns and quotations; the LLM picks a quote's speaker.

    def frame_pass(self, source):
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
        f = {"id": f"f{len(self.frames) + 1}", "span": self.t.span(a, b), "parent": parent, "speaker": speaker, "_range": (a, b)}
        self.frames.append(f)

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
        p = self.llm.choose(f'Text: "{self.t.s}"\n\nPassage: "{self.t.s[a:b]}"', f'Who is speaking in {what} (who do "I", "my" and "we" refer to)?', options)
        best = max(range(len(options)), key=lambda i: p[i])
        return ids[best] if best < len(ids) and p[best] >= ACCEPT else None

    def person_models(self):
        return {self.plan.relations[n]["from"] and target(self.prop(n, self.plan.relations[n]["from"][0])["shape"]) for n in self.plan.relations}

    def prop(self, model, name):
        return next(p for p in self.plan.models[model]["properties"] if p["name"] == name)

    def name(self, rid):
        return next(r for r in self.records if r["local_id"] == rid)["fields"][0]["value"]

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

        def holders(model, anywhere):
            pool = self.mentions if anywhere else local
            ids = {m["record"]: (m["start"], m["end"]) for m in pool if m["kind"] == model and m["record"]}
            if speaker and model in self.person_models() and pronoun:
                ids.setdefault(speaker, (pronoun.start(), pronoun.end()))
            return ids

        froms, tos = holders(ft, False), holders(tt, free is not None)
        ctx = f'Text: "{self.t.s}"\n\nSentence: "{self.t.s[a:b]}"' + (f'\nIn this sentence "I"/"my"/"our" refer to {self.name(speaker)}.' if speaker else "")
        question = f"{self.plan.models[name]['description']}\n\nWhich of these does the sentence itself explicitly state? Do not infer from other sentences or world knowledge."
        rel = self.plan.relations[name]
        if free:
            labels = [m for m in self.mentions if m["kind"] == free and a <= m["start"] and m["end"] <= b]
            pairs = [(x, y) for x in froms for y in tos if x != y]
            for x, y in pairs:
                if not labels:
                    break
                opts = [f"{frm}={self.name(x)}, {to}={self.name(y)}, {label}={self.t.s[l['start']:l['end']]}" for l in labels]
                p = self.llm.choose(ctx, question, opts + ["none of these"])
                best = max(range(len(p)), key=lambda i: p[i])
                if best < len(labels) and p[best] >= ACCEPT:
                    l = labels[best]
                    self.emit(name, frm, to, label, (x, froms[x]), (y, tos[y]), self.t.s[l["start"] : l["end"]], (l["start"], l["end"]), p[best], a, b, opts[best])
            return
        ids = sorted(set(froms) | set(tos))
        for i, x in enumerate(ids):
            for y in ids[i + 1 :]:
                readings = [(s, o, v["value"], w) for v in rel["labels"] for w in v["forward"][:1] or [v["value"]] for s, o in ((x, y), (y, x)) if s in froms and o in tos]
                if not readings:
                    continue
                opts = [f"{self.name(s)}'s {w} is {self.name(o)}" for s, o, v, w in readings]
                p = self.llm.choose(ctx, question, opts + ["none of these is explicitly stated"])
                best = max(range(len(p)), key=lambda k: p[k])
                if best < len(readings) and p[best] >= ACCEPT:
                    s, o, v, _ = readings[best]
                    cue = self.cue(rel, v, a, b)
                    self.emit(name, frm, to, label, (s, {**froms, **tos}[s]), (o, {**froms, **tos}[o]), v, cue, p[best], a, b, opts[best])

    def cue(self, rel, value, a, b):
        """The declared linguistic label that evidences a closed label, else the sentence."""
        words = next(l["forward"] for l in rel["labels"] if l["value"] == value) or [value]
        for w in words:
            m = re.search(rf"\b{re.escape(w)}\b", self.t.s[a:b], re.I)
            if m:
                return (a + m.start(), a + m.end())
        return (a, b)

    def emit(self, name, frm, to, label, subj, obj, value, cue, score, a, b, claim):
        if any(r["model"] == name and self.same(r, frm, subj[0], to, obj[0], label, value) for r in self.records):
            return
        modality, polarity = self.qualifiers(a, b, claim)
        q = {"modality": modality, "polarity": polarity}
        fields = [
            self.field(frm, subj[0], [subj[1]], **q),
            self.field(label, value, [cue], score=score, **q),
            self.field(to, obj[0], [obj[1]], **q),
        ]
        for p in self.plan.models[name]["properties"]:
            if required(p) and p["name"] not in (frm, to, label):
                fields.append(self.field(p["name"], {}, [cue], **q))
        self.records.append({"local_id": self.mint(), "model": name, "fields": fields, "identities": [], "candidates": []})

    def same(self, r, frm, s, to, o, label, v):
        vals = {f["property"]: f["value"] for f in r["fields"]}
        return vals.get(frm) == s and vals.get(to) == o and vals.get(label) == v

    def qualifiers(self, a, b, claim):
        ctx = f'Sentence: "{self.t.s[a:b]}"'
        keys = list(MODALITIES)
        p = self.llm.choose(ctx, f"Consider only this claim: {claim}. How does the sentence present that claim itself (not other events in the sentence)?", [MODALITIES[k] for k in keys])
        modality = keys[max(range(len(keys)), key=lambda i: p[i])]
        q = self.llm.choose(ctx, f"Consider only this claim: {claim}. Does the sentence affirm that claim, or deny that claim itself (a negated event elsewhere in the sentence does not count)?", ["affirms the claim", "denies the claim"])
        return modality, ("affirmed" if q[0] >= q[1] else "denied")

    def field(self, prop, value, ranges, modality="asserted", polarity="affirmed", score=None):
        spans = [self.t.span(a, b) for a, b in ranges]
        f = {"property": prop, "value": value, "spans": spans, "polarity": polarity, "modality": modality}
        frame = self.innermost(*ranges[0]) if hasattr(self, "frames") else None
        f["frame"] = frame["id"] if frame else None
        if score is not None:
            f["score"] = round(min(1.0, max(0.0, score)), 4)
        return f


def finish(records, frames):
    """Frames are assigned once all frames exist; private keys are dropped."""
    return [{k: v for k, v in r.items() if not k.startswith("_")} for r in records], [
        {k: v for k, v in f.items() if not k.startswith("_")} for f in frames
    ]


def reframe(cascade):
    for r in cascade.records:
        for f in r["fields"]:
            fr = cascade.innermost(*char_range(cascade.t, f["spans"][0]))
            f["frame"] = fr["id"] if fr else None
        for i in r["identities"]:
            fr = cascade.innermost(*char_range(cascade.t, i["spans"][0]))
            i["frame"] = fr["id"] if fr else None


def char_range(t, span):
    return t.byte.index(span["start"]), t.byte.index(span["end"])


def main():
    args = sys.argv[1:]
    stdin = json.load(sys.stdin)
    if "input" in stdin:
        req = stdin
    else:
        catalog = json.load(open(args[args.index("--catalog") + 1]))
        sys.path.insert(0, os.path.dirname(__file__))
        from request import request

        req = request(stdin, catalog, MODEL_ID)
    result = {
        "contract": 1,
        "request": req["request"],
        "source": req["input"]["source"],
        "schema": req["catalog"]["fingerprint"],
        "extractor": req["extractor"],
    }
    started = time.time()
    try:
        plan = Plan(req["catalog"]["descriptor"])
        for m, why in plan.blocked.items():
            log(f"skip {m}: {why}")
        enc, llm = Encoder(), Scorer()
        loaded = time.time()
        c = Cascade(plan, enc, llm)
        c.run(req["input"])
        reframe(c)
        records, frames = finish(c.records, c.frames)
        result.update(status="complete", records=records, proposed_frames=frames)
        log(f"load_s={loaded - started:.1f} extract_s={time.time() - loaded:.1f} llm_calls={llm.calls} records={len(records)} frames={len(frames)}")
    except Exception as e:
        result.update(status="failed", records=[], problems=[{"code": "extractor.setup" if "loaded" not in dir() else "extractor.run", "message": f"{type(e).__name__}: {e}"[:4096]}])
        log(f"failed: {type(e).__name__}: {e}")
    log(f"maxrss_mb={resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1e6:.0f}")
    json.dump(result, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    main()
