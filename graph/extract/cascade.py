"""Local extraction cascade: an encoder proposes spans, a small LLM only
scores closed choices, and every proposal is an exact source anchor.

usage: python cascade.py [--catalog SCHEMA_JSON] [--local] [--no-prefix] [--units M] < in.json > out.json
       python cascade.py --serve   # keep both models resident behind a Unix socket

Without a listening service it exits 1 ("service unavailable"); --local
loads the models in this process instead.

stdin is one request, or a JSON array of them for a batch (one encoder
load and one scorer load for the whole batch; the answer is then an array).
A request is a C01 ExtractionRequest, or a bare I01 SourceEnvelope with
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

import string

from pins import ENCODER, MODEL_ID, SCORER, parameter

PARAMS_FILE = os.environ.get("CASCADE_PARAMS", os.path.join(os.path.dirname(os.path.abspath(__file__)), "params.json"))


def fitted(name):
    """A decision parameter from the calibration file calibrate.py writes."""
    return json.load(open(PARAMS_FILE))["params"][name]["value"]


SPAN_THRESHOLD = fitted("span_threshold")
ACCEPT = fitted("accept")
ACCEPT_SPEAKER = fitted("accept_speaker")
ACCEPT_RECORD = fitted("accept_record")
MARGIN = fitted("margin")
NEW_CEILING = fitted("new_ceiling")
MAX_OPTIONS = len(string.ascii_uppercase)
GENERATE_BUDGET = parameter("generate_budget")
ABSTAIN = object()
SOCKET = os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")
STATEMENT = "statement"
STATEMENT_GLOSS = "one complete statement, request or question, as a whole sentence"
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
QUOTE_CONTEXT = parameter("quote_context")

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

    def anchor(self, model):
        """The text field an entity record is named by."""
        texts = self.entities[model]
        return next((p["name"] for p in texts if required(p)), texts[0]["name"])

    def entity_labels(self):
        """Encoder labels for entity mentions, references and free relation labels."""
        labels = {m.lower(): gloss(self.models[m]) for m in self.entities}
        for name in self.relations:
            label = self.free_labels(name)
            if label:
                labels[label] = f"{label} of a {name}: {gloss(self.models[name])}"
        return labels

    def texts(self, model):
        return [p["name"] for p in self.models[model]["properties"] if route(p) == "text"]

    def encoder_queries(self, text):
        """Every encoder pass an extraction of this text can use. None depends
        on a choice, so all of them run before any choice is made."""
        q = {"entities": ("mentions", text, self.entity_labels()), "statements": ("mentions", text, {STATEMENT: STATEMENT_GLOSS})}
        for model, texts in self.entities.items():
            extra = [p["name"] for p in texts if p["name"] != self.anchor(model)]
            if extra:
                q[f"attributes:{model}"] = ("records", text, model, self.anchor(model), [self.anchor(model)] + extra)
        fields = {}
        for model in self.records:
            texts = self.texts(model)
            if texts:
                q[f"record:{model}"] = ("records", text, model, texts[0], texts)
            for p in self.models[model]["properties"]:
                if route(p) == "text" and required(p):
                    fields[f"{model}.{p['name']}"] = f"the {p['name']} of a {model}: {gloss(self.models[model])}"
        if fields:
            q["fields"] = ("mentions", text, fields)
        return q

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
    """The span encoder, run in a child process that ends with close()."""

    def __init__(self):
        import subprocess

        self.p = subprocess.Popen(
            [sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "encoder_worker.py")],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
        )
        hello = json.loads(self.p.stdout.readline() or "{}")
        if not hello.get("ready"):
            raise RuntimeError("the encoder process did not start")
        log(f"encoder_footprint_loaded={hello['footprint']}")

    def ask(self, **q):
        self.p.stdin.write(json.dumps(q) + "\n")
        self.p.stdin.flush()
        return json.loads(self.p.stdout.readline())

    def mentions(self, text, labels):
        return self.ask(op="mentions", text=text, labels=labels, threshold=SPAN_THRESHOLD)["value"] if labels else {}

    def records(self, text, model, anchor, fields):
        return self.ask(op="records", text=text, model=model, anchor=anchor, fields=fields, threshold=SPAN_THRESHOLD)["value"]

    def close(self):
        print(f"encoder_footprint_end={self.ask(op='footprint')['footprint']}", file=sys.stderr, flush=True)
        self.p.stdin.close()
        self.p.wait()


def choice_prompt(context, question, options, source=""):
    """The user message of one closed choice, exactly as the scorer sends it:
    the source text (when given), the context, the question and the lettered
    options. Importable without mlx, so tuning data matches runtime bytes."""
    letters = string.ascii_uppercase[: len(options)]
    text = f'Text: "{source}"\n\n' if source else ""
    return text + f"{context}\n\n{question}\n" + "\n".join(f"{l}) {o}" for l, o in zip(letters, options)) + "\nAnswer with the letter only."


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

    def generate(self, messages, max_tokens, stop=()):
        """Greedy text for a chat, ended before the first stop string; the
        extraction prefix cache is untouched."""
        from mlx_lm import stream_generate

        prompt = self.tok.apply_chat_template(messages, add_generation_prompt=True, tokenize=False)
        text = ""
        for part in stream_generate(self.model, self.tok, prompt, max_tokens=max(1, min(max_tokens, GENERATE_BUDGET))):
            text += part.text
            cut = min((text.find(s) for s in stop if s and s in text), default=-1)
            if cut >= 0:
                return text[:cut]
        return text

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
        letters = list(string.ascii_uppercase[: len(options)])
        text = f'Text: "{self.source}"\n\n' if self.source else ""
        prompt = self.render(choice_prompt(context, question, options, self.source))
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
        mx.clear_cache()
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
    """Phase two of an extraction: every choice, over spans phase one found."""

    def __init__(self, plan, spans, scorer):
        self.plan, self.spans, self.llm = plan, spans, scorer

    def run(self, source):
        self.t = Text(source["content"])
        self.records, self.mentions, self.minted, self.resolved, self._units = [], [], 0, {}, None
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
        labels = self.plan.entity_labels()
        found = self.spans["entities"]
        log("spans " + " ".join(f"{l}:{[self.t.s[x['start']:x['end']] for x in xs]}" for l, xs in found.items() if xs))
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
        anchor = self.plan.anchor(model)
        rec = {"local_id": self.mint(), "model": model, "fields": [self.field(anchor, self.t.s[a:b], [(a, b)], score=conf)], "identities": [], "resolution": {"kind": "new"}}
        rec["_anchor"] = (a, b)
        self.records.append(rec)
        return rec

    def units(self):
        """The spans choices are asked about, by CASCADE_UNITS:
        statements — the encoder's statement spans (gaps between them kept);
        windows — each frame, and the text outside frames, whole;
        sentences — punctuation splitting, kept only as a measured baseline."""
        if self._units is not None:
            return self._units
        mode = os.environ.get("CASCADE_UNITS", "statements")
        if mode == "sentences":
            self._units = self.t.units()
        elif mode == "windows":
            self._units = self.covering([f["_range"] for f in self.frames])
        else:
            found = self.spans["statements"].get(STATEMENT, [])
            self._units = self.covering([(s["start"], s["end"]) for s in found])
        return self._units

    def covering(self, ranges):
        """Non-overlapping ranges in order, longest kept on overlap, with the
        uncovered stretches between them as ranges of their own."""
        kept = []
        for a, b in sorted(ranges, key=lambda r: r[0] - r[1]):
            if all(b <= x or a >= y for x, y in kept):
                kept.append((a, b))
        kept.sort()
        out, at = [], 0
        for a, b in kept + [(len(self.t.s), len(self.t.s))]:
            if self.t.s[at:a].strip():
                out.append((at, a))
            if b > a:
                out.append((a, b))
            at = max(at, b)
        return [(a, b) for a, b in out if self.t.s[a:b].strip()]

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
        if ranked[0] == len(prior) and max(p[: len(prior)]) <= NEW_CEILING:
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
            got = self.spans.get(f"attributes:{model}", [])
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
        return ids[best] if best < len(ids) and p[best] >= ACCEPT_SPEAKER else None

    def model_of(self, rid):
        return next(r["model"] for r in self.records if r["local_id"] == rid)

    def referents(self, a, b):
        """People a passage may speak of without naming them here: its
        speaker, anchored on the passage, and the people the passage before
        it names. They are candidates only; the choices decide."""
        out = []
        speaker = self.speaker(a, b)
        if speaker:
            out.append((speaker, (a, b)))
        before = [u for u in self.units() if u[1] <= a]
        if before:
            x, y = before[-1]
            for m in self.mentions:
                if m["record"] and m["kind"] in self.person_models() and x <= m["start"] and m["end"] <= y:
                    if all(rid != m["record"] for rid, _ in out):
                        out.append((m["record"], (m["start"], m["end"])))
        return out

    def speaker(self, a, b):
        """Who speaks a passage: its frame's speaker, else the text's own."""
        frame = self.innermost(a, b)
        if frame is not None and frame["speaker"]:
            return frame["speaker"]
        if "text" not in self.resolved:
            self.resolved["text"] = self.choose_speaker(0, len(self.t.s))
        return self.resolved["text"]

    def person_models(self):
        return {self.plan.relations[n]["from"] and target(self.prop(n, self.plan.relations[n]["from"][0])["shape"]) for n in self.plan.relations}

    def prop(self, model, name):
        return next(p for p in self.plan.models[model]["properties"] if p["name"] == name)

    def name(self, rid):
        """A record's readable label: its first text value that is no reference."""
        ids = {r["local_id"] for r in self.records}
        r = next(r for r in self.records if r["local_id"] == rid)
        return next((f["value"] for f in r["fields"] if isinstance(f["value"], str) and f["value"] not in ids), rid)

    # Relations: the LLM scores every labelled reading of a candidate pair.

    def relation_pass(self):
        for name, rel in self.plan.relations.items():
            frm, to, label = rel["from"][0], rel["to"][0], rel["label"][0]
            ft, tt = target(self.prop(name, frm)["shape"]), target(self.prop(name, to)["shape"])
            free = self.plan.free_labels(name)
            for a, b in self.units():
                for sub in self.sub_units(a, b):
                    self.relate(name, frm, to, label, ft, tt, free, *sub)

    def sub_units(self, a, b):
        """A unit split at frame boundaries, so no anchor crosses a frame."""
        cuts = sorted({a, b} | {x for f in self.frames for x in f["_range"] if a < x < b})
        return [(x, y) for x, y in zip(cuts, cuts[1:]) if self.t.s[x:y].strip(" '\"“”‘’,.:")]

    def relate(self, name, frm, to, label, ft, tt, free, a, b):
        local = [m for m in self.mentions if m["record"] and a <= m["start"] and m["end"] <= b]
        referred = self.referents(a, b)

        def holders(model, anywhere):
            pool = self.mentions if anywhere else local
            ids = {m["record"]: (m["start"], m["end"]) for m in pool if m["kind"] == model and m["record"]}
            for rid, span in referred:
                if self.model_of(rid) == model:
                    ids.setdefault(rid, span)
            return ids

        froms, tos = holders(ft, False), holders(tt, False) or (holders(tt, True) if free else {})
        speaker = self.speaker(a, b)
        ctx = f'Sentence: "{self.t.s[a:b]}"' + (f"\nThis sentence is spoken by {self.name(speaker)}." if speaker else "")
        question = f"{self.plan.models[name]['description']}\n\nWhich of these does the sentence itself explicitly state? Do not infer from other sentences or world knowledge."
        rel = self.plan.relations[name]
        if free:
            labels = [m for m in self.mentions if m["kind"] == free and a <= m["start"] and m["end"] <= b]
            pairs = [(x, y) for x in froms for y in tos if x != y]
            for x, y in pairs:
                if not labels:
                    break
                opts = [self.phrased(rel, self.name(x), self.name(y), self.t.s[l["start"] : l["end"]]) for l in labels]
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
                opts = [self.phrased(rel, self.name(s), self.name(o), self.worded(w)) for s, o, v, w in readings]
                p = self.llm.pick(ctx, question, opts, ["none of these is explicitly stated"])
                best = max(range(len(p)), key=lambda k: p[k])
                if best < len(readings) and p[best] >= ACCEPT:
                    s, o, v, _ = readings[best]
                    cue = self.cue(rel, v, a, b)
                    self.emit(name, frm, to, label, (s, {**froms, **tos}[s]), (o, {**froms, **tos}[o]), v, cue, p[best], a, b, opts[best])

    def phrased(self, rel, frm, to, label):
        """A reading in the binding's declared phrasing."""
        return rel["phrasing"].replace("{from}", frm).replace("{to}", to).replace("{label}", label)

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
        for a, b in self.units():
            for x, y in self.sub_units(a, b):
                x, y = self.trimmed(x, y)
                if y <= x:
                    continue
                p = self.llm.pick(f'Sentence: "{self.t.s[x:y]}"', "Which kind of record does this sentence itself state, if any?", opts, ["none of these"])
                best = max(range(len(p)), key=lambda i: p[i])
                if best < len(kinds) and p[best] >= ACCEPT_RECORD:
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
        found = next((r for r in self.spans.get(f"record:{model}", []) if self.within(r, a, b)), {})
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
        optional = ["not stated"]
        if kind == "text":
            v = found.get(name)
            if v and self.named(v["start"], v["end"]):
                log(f"skip {model}.{name}: {v['text']!r} names an entity, not text")
                v = None
            if v and v.get("confidence", 0) >= SPAN_THRESHOLD:
                return self.field(name, v["text"], [(v["start"], v["end"])], score=v["confidence"])
            if not required(p):
                return None
            found_spans = self.spans.get("fields", {}).get(f"{model}.{name}", [])
            cands = [(s["start"], s["end"]) for s in found_spans if a <= s["start"] and s["end"] <= b and not self.named(s["start"], s["end"])]
            if not cands:
                return None
            pr = self.llm.pick(ctx, f"In a {model}, which part of the sentence is the {name}?", [self.t.s[x:y] for x, y in cands], ["not stated"])
            k = max(range(len(pr)), key=lambda i: pr[i])
            if k == len(cands) or pr[k] < ACCEPT_RECORD:
                return None
            x, y = cands[k]
            return self.field(name, self.t.s[x:y], [(x, y)], score=pr[k])
        if kind == "ref":
            ids, where = self.offered(target(p["shape"]), a, b)
            if not ids:
                return None
            pr = self.llm.pick(ctx, f"In this {model}, who or what is the {name}?", [self.name(i) for i in ids], optional)
            k = max(range(len(pr)), key=lambda i: pr[i])
            if k >= len(ids) or pr[k] < ACCEPT_RECORD:
                return None
            return self.field(name, ids[k], [where[ids[k]]], score=pr[k])
        if kind == "enum":
            vals = p["enum"]
            pr = self.llm.pick(ctx, f"For this {model}, which {name} does the sentence state?", vals, optional)
            k = max(range(len(pr)), key=lambda i: pr[i])
            return self.field(name, vals[k], [(a, b)], score=pr[k]) if k < len(vals) and pr[k] >= ACCEPT_RECORD else None
        if kind == "bool":
            pr = self.llm.choose(ctx, f"For this {model}, is {name} true or false according to the sentence?", ["true", "false"] + optional)
            k = max(range(len(pr)), key=lambda i: pr[i])
            return self.field(name, k == 0, [(a, b)], score=pr[k]) if k < 2 and pr[k] >= ACCEPT_RECORD else None
        if kind == "number" and not self.declared_time(model, name):
            nums = [(x.start(), x.end()) for x in re.finditer(r"\d[\d,]*", self.t.s[a:b])]
            nums = [(a + x, a + y) for x, y in nums]
            if not nums:
                return None
            pr = self.llm.pick(ctx, f"In this {model}, which number is the {name}?", [self.t.s[x:y] for x, y in nums], ["not stated"])
            k = max(range(len(pr)), key=lambda i: pr[i])
            if k == len(nums) or pr[k] < ACCEPT_RECORD:
                return None
            x, y = nums[k]
            return self.field(name, int(self.t.s[x:y].replace(",", "")), [(x, y)], score=pr[k])
        return None

    def within(self, record, a, b):
        """Whether every span a structure record found lies in [a, b)."""
        spans = [v for v in record.values() if isinstance(v, dict) and "start" in v]
        return bool(spans) and all(a <= v["start"] and v["end"] <= b for v in spans)

    def named(self, x, y):
        """Whether a span is exactly an entity mention the cascade kept."""
        return any(m["record"] and m["start"] == x and m["end"] == y for m in self.mentions)

    def declared_time(self, model, name):
        """Whether the model declares this property as an encoded time, which
        needs normalization, not a number read off the text."""
        v = self.plan.models[model]["semantics"].get("validity") or {}
        return any(p and p[-1] == name for p in (v.get("from"), v.get("until")))

    def offered(self, model, a, b):
        """Records of a model this sentence can refer to, with where each is evidenced."""
        where = {}
        for m in self.mentions:
            if m["record"] and m["kind"] == model:
                inside = a <= m["start"] and m["end"] <= b
                if inside or m["record"] not in where:
                    where[m["record"]] = (m["start"], m["end"]) if inside else None
        for rid, span in self.referents(a, b):
            if self.model_of(rid) == model:
                where[rid] = span
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
    """At most one model is held at a time: the encoder for phase one, the
    scorer for phase two and for choose/generate requests."""

    def __init__(self):
        self._llm, self.load_s = None, 0.0

    @property
    def llm(self):
        if self._llm is None:
            t = time.time()
            self._llm = Scorer()
            self.load_s = time.time() - t
        return self._llm

    def drop_llm(self):
        """Release the scorer's weights before the encoder loads."""
        if self._llm is not None:
            import gc

            import mlx.core as mx

            self._llm = None
            gc.collect()
            mx.clear_cache()

    def encoder(self):
        return Encoder()


def encoded(reqs, models):
    """Phase one: every encoder pass for every request, in one encoder
    process, with no scorer loaded beside it."""
    models.drop_llm()
    t = time.time()
    enc = models.encoder()
    out = []
    try:
        for req in reqs:
            try:
                plan = Plan(req["catalog"]["descriptor"])
                spans = {}
                for key, (op, *args) in plan.encoder_queries(req["input"]["content"]).items():
                    spans[key] = enc.mentions(*args) if op == "mentions" else enc.records(*args)
                out.append(spans)
            except Exception as e:
                out.append(e)
    finally:
        enc.close()
    log(f"phase1_s={time.time() - t:.1f} sources={len(reqs)}")
    return out


def extract_batch(reqs, models=None):
    """C01 ExtractionResults for a batch: encoder pass for all, then every
    choice for all. A failure is a result, never an exception."""
    LOG.clear()
    models = models or Models()
    phase_one = encoded(reqs, models)
    head = list(LOG)
    answers = []
    for req, spans in zip(reqs, phase_one):
        LOG.clear()
        answers.append(extract(req, models, spans))
        answers[-1] = (answers[-1][0], head + answers[-1][1])
    return answers


def extract(req, models, spans):
    """Phase two for one request over its phase-one spans."""
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
        if isinstance(spans, Exception):
            raise spans
        plan = Plan(req["catalog"]["descriptor"])
        for m, why in plan.blocked.items():
            log(f"skip {m}: {why}")
        stage = "extractor.run"
        llm = models.llm
        started, calls = time.time(), llm.calls
        c = Cascade(plan, spans, llm)
        c.run(req["input"])
        reframe(c)
        records, frames = finish(c.records, c.frames)
        result.update(status="complete", records=records, proposed_frames=frames)
        log(f"scorer_load_s={models.load_s:.1f} phase2_s={time.time() - started:.1f} llm_calls={llm.calls - calls} records={len(records)} frames={len(frames)}")
    except Exception as e:
        result.update(status="failed", records=[], problems=[{"code": stage, "message": f"{type(e).__name__}: {e}"[:4096]}])
        log(f"failed: {type(e).__name__}: {e}")
    return result, list(LOG)


def received(conn):
    """One request: bytes up to the first newline, or to end of stream."""
    data = b""
    while b"\n" not in data:
        chunk = conn.recv(parameter("socket_read_bytes"))
        if not chunk:
            break
        data += chunk
    return data.split(b"\n", 1)[0]


def answered(body, models):
    """A generate op's text, or an extraction's result and log."""
    if body.get("op") == "generate":
        return {"text": models.llm.generate(body["messages"], int(body.get("max_tokens", GENERATE_BUDGET)), [str(s) for s in body.get("stop", [])])}
    if body.get("op") == "choose":
        models.llm.source, models.llm.cache = "", None
        return {"p": models.llm.choose(body["context"], body["question"], body["options"])}
    models.llm.prefix = body.get("prefix", True)
    os.environ["CASCADE_UNITS"] = body.get("units") or "statements"
    os.environ["CASCADE_TRACE"] = "1" if body.get("trace") else ""
    if "requests" in body:
        return {"results": [{"result": r, "log": l} for r, l in extract_batch(body["requests"], models)]}
    result, logs = extract_batch([body["request"]], models)[0]
    return {"result": result, "log": logs}


def settled():
    """Return MLX's freed buffers to the system after a request, and say how
    much it holds: buffers it keeps cached otherwise grow into swap."""
    import mlx.core as mx

    peak = mx.get_peak_memory() // 2**20
    mx.clear_cache()
    mx.reset_peak_memory()
    return f"mlx_active_mb={mx.get_active_memory() // 2**20} mlx_peak_mb={peak}"


def serve():
    """A local Unix-socket service, served in order: one JSON line in, one
    JSON line out, per connection. `{"op":"generate","messages":[…],
    "max_tokens":n,"stop":[…]}` answers `{"text":…}` (greedy, ended before
    the first stop string); `{"op":"choose","context","question","options"}` answers `{"p":[…]}`;
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
                f"s={time.time() - started:.2f} {settled()} {answer.get('error', 'ok')}",
                file=sys.stderr,
                flush=True,
            )
            try:
                conn.sendall(json.dumps(answer, ensure_ascii=False).encode() + b"\n")
            except OSError as e:
                print(f"client gone: {e}", file=sys.stderr, flush=True)


def remote(body):
    """The resident service's answer to one body, or None when nothing listens."""
    import socket

    if not os.path.exists(SOCKET):
        return None
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.connect(SOCKET)
    except OSError:
        return None
    with s:
        s.sendall(json.dumps(body, ensure_ascii=False).encode() + b"\n")
        s.shutdown(socket.SHUT_WR)
        return json.loads(b"".join(iter(lambda: s.recv(parameter("socket_read_bytes")), b"")))


def main():
    args = sys.argv[1:]
    if "--serve" in args:
        return serve()
    stdin = json.load(sys.stdin)
    catalog = args[args.index("--catalog") + 1] if "--catalog" in args else None
    batch = isinstance(stdin, list)
    reqs = [requested(s, catalog) for s in (stdin if batch else [stdin])]
    if "--local" in args:
        answers = extract_batch(reqs)
    else:
        units = args[args.index("--units") + 1] if "--units" in args else None
        answer = remote({"requests": reqs, "prefix": "--no-prefix" not in args, "units": units, "trace": "--trace" in args})
        if answer is None:
            print(f"service unavailable: nothing answers on {SOCKET}; start `cascade.py --serve`, or pass --local to load the models here", file=sys.stderr)
            return 1
        if "error" in answer:
            print(f"service: {answer['error']}", file=sys.stderr)
            return 1
        answers = [(a["result"], ["served"] + a["log"]) for a in answer["results"]]
    for _, logs in answers:
        print("\n".join(logs), file=sys.stderr)
    results = [r for r, _ in answers]
    json.dump(results if batch else results[0], sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
