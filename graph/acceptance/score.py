#!/usr/bin/env python3
"""Scores the graph end to end against the 50-question acceptance set.

Pipeline per checkpoint: fresh db, ingest sources 1..N (no other prefix is
accepted), publish facts (oracle or extracted), then ask each question
through a planner and the graph's `query` op. Missing hooks score `not-run`.
"""
import argparse
import hashlib
import datetime
import json
import os
import pathlib
import shlex
import subprocess
import sys
import tempfile
import time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
BINARY = HERE / "app/src/main"
ORACLE = HERE / "oracle"
FIXTURE = HERE
ZONE = json.loads((HERE / "manifest.json").read_text()).get("default_timezone")
RESULTS = HERE / "results"
HELDOUT_RESULTS = HERE / "heldout-results"
SPLIT = HERE / "split.json"
STATUSES = ("pass", "fail", "not-run", "error")
SET_KEYS = {"candidates", "excluded"}
VALUE = {"take": "value"}
SPOKEN = ("candidates", "conflicts", "clarify", "reason")
MEDIA = {"csv": "text/csv"}


class PrefixError(ValueError):
    pass


def read_lines(path):
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def configure(root):
    """Points the harness at a fixture directory: its sources, oracle, split and app."""
    global FIXTURE, BINARY, ORACLE, SPLIT, ZONE
    FIXTURE = root
    ZONE = json.loads((root / "manifest.json").read_text()).get("default_timezone")
    BINARY = root / "app/src/main"
    ORACLE = root / "oracle"
    SPLIT = root / "split.json"


def load_fixture(root=None):
    root = root or FIXTURE
    manifest = json.loads((root / "manifest.json").read_text())
    return (manifest, read_lines(root / "sources.jsonl"),
            read_lines(root / "entities.jsonl"), read_lines(root / "questions.jsonl"))


def utc_ms(text):
    stamp = text if "T" in text else text + "T00:00:00Z"
    return int(datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp() * 1000)


def envelope(source):
    ms = utc_ms(source["received_at"])
    return {
        "contract": 2,
        "source": {"observation": source["observation"], "revision": source["revision"]},
        "authored_at_ms": ms, "received_at_ms": ms, "author": source["author"],
        "participants": [], "conversation": source["thread"],
        "media_type": MEDIA.get(source["kind"], "text/plain"),
        "content": source["content"], "frames": [],
        **({"timezone": ZONE} if ZONE else {}),
    }


def prefix_of(sources, checkpoint, picked=None):
    """The sources 1..checkpoint; any other selection is refused."""
    chosen = picked if picked is not None else [s["id"] for s in sources[:checkpoint]]
    expected = [s["id"] for s in sources[:checkpoint]]
    if chosen != expected:
        raise PrefixError(f"checkpoint {checkpoint} needs exactly {expected[0]}..{expected[-1]} in order")
    return sources[:checkpoint]


class App:
    """The graph CLI over one db file; every call is a fresh process."""

    def __init__(self, binary, db, scratch):
        self.binary, self.db, self.scratch = binary, db, scratch
        self.calls = 0
        self.after = {}

    @property
    def argv(self):
        return [str(self.binary), "request", "--db", str(self.db)]

    def call(self, request):
        self.calls += 1
        path = self.scratch / f"req-{self.calls}.json"
        path.write_text(json.dumps(request))
        done = subprocess.run([str(self.binary), "request", "--db", str(self.db), str(path)],
                              text=True, capture_output=True, timeout=60)
        try:
            body = json.loads(done.stdout)
        except json.JSONDecodeError:
            body = {"error": (done.stderr or done.stdout).strip()[:400]}
        if done.returncode != 0 and "error" not in body:
            body = {"error": f"exit {done.returncode}"}
        return body


def run_hook(command, payload, timeout=None, log=None, env=None):
    """The hook's JSON answer; its stderr is appended to `log` when given."""
    done = subprocess.run(shlex.split(command), input=json.dumps(payload), text=True,
                          capture_output=True, timeout=timeout,
                          env={**os.environ, **env} if env else None)
    if log is not None:
        log.append(done.stderr[-4000:])
    if done.returncode != 0:
        raise RuntimeError(f"hook exit {done.returncode}: {done.stderr.strip()[:300]}")
    return json.loads(done.stdout)


def anchor_span(source, anchor):
    """Half-open UTF-8 byte span of the one occurrence of `anchor` in the source."""
    text = source["content"]
    if text.count(anchor) != 1:
        raise ValueError(f"{source['id']}: anchor {anchor!r} occurs {text.count(anchor)} times")
    start = text.index(anchor)
    return [len(text[:start].encode()), len((text[:start] + anchor).encode())]


def oracle_facts(source):
    """Publication bodies for one source, or None when the oracle has no facts file."""
    path = ORACLE / "facts.jsonl"
    if not path.exists():
        return None
    out = []
    for row in (r for r in read_lines(path) if r["source"] == source["id"]):
        records = []
        for rec in row["records"]:
            value = {k: utc_ms(v) if k.endswith("_ms") and isinstance(v, str) else v
                     for k, v in rec["value"].items()}
            records.append({"id": rec["id"], "model": rec["model"], "mode": rec["mode"], "value": value,
                            "identities": rec.get("identities", []),
                            "locator": {"source": source["id"], "span": anchor_span(source, rec["anchor"])}})
        out.append({"id": "oracle-" + source["id"], "producer": "oracle", "scope": source["id"],
                    "input": source["observation"], "input_revision": source["revision"], "records": records})
    return out


def sealed(rows, what):
    """Oracle data keyed to a held-out question is refused: the held-out set stays unseen."""
    if not SPLIT.exists():
        return rows
    held = set(json.loads(SPLIT.read_text())["heldout"])
    keyed = sorted({r["question"] for r in rows if r["question"] in held})
    if keyed:
        raise ValueError(f"oracle {what} keyed to held-out questions: {', '.join(keyed)}")
    return rows


def oracle_plans():
    path = ORACLE / "plans.jsonl"
    return {row["question"]: row for row in sealed(read_lines(path), "plans")} if path.exists() else {}


def oracle_gold():
    path = ORACLE / "gold.jsonl"
    return read_lines(path) if path.exists() else []


def oracle_blocked():
    path = ORACLE / "blocked.jsonl"
    return {r["question"]: r["reason"] for r in sealed(read_lines(path), "blockers")} if path.exists() else {}


def oracle_readings():
    path = ORACLE / "readings.jsonl"
    return sealed(read_lines(path), "readings") if path.exists() else []


def cypher_params(context):
    """The request context as Cypher parameters: asker, now, and what is set."""
    names = {"asker": "principal", "now": "question_at_ms", "speaker": "speaker", "valid_at": "valid_at_ms",
             "known_revision": "known_revision", "conversation": "conversation", "previous_answer": "previous_answer"}
    return {param: context[key] for param, key in names.items() if context.get(key) is not None}


def complete_plan(row, request, schema, context, view):
    if "cypher" in row:
        return {"cypher": row["cypher"], "params": {**row.get("params", {}), **cypher_params(context)}}
    return {"contract": 1, "request": request, "schema": schema["fingerprint"], "context": context,
            "source_view": view, "steps": row["steps"], "output": row["output"],
            **({"joined": row["joined"]} if row.get("joined") else {}),
            "budget": {"steps": 32, "rows": 1000, "work": 100000, "depth": 4, "timeout_ms": 10000}}


# ---- projection and grading -------------------------------------------------

def reshaped(value, spec):
    """Generic projections of a structured value: one element, one member, or a list of records as a map."""
    if "index" in spec and isinstance(value, list):
        value = value[spec["index"]]
    if "pick" in spec and isinstance(value, dict):
        value = value[spec["pick"]]
    if "map_by" in spec and isinstance(value, list):
        key, member = spec["map_by"]["key"], spec["map_by"]["value"]
        value = {item[key]: item[member] for item in value}
    return value


def terms(answer, spec):
    """What each field of the answer binds for one expected key, by the kind of
    binding the reading names (the entity, the value or the revision it rests
    on) and never by the spelling of the field's output name."""
    cited = {c["id"]: c["source"]["revision"] for c in answer.get("citations", [])}
    takes = {
        "entity": lambda f: f["path"][0],
        "value": lambda f: f["value"],
        "revision": lambda f: max(cited.get(c, 0) for c in f["citations"]),
    }
    return [reshaped(takes[spec["take"]](f), spec) for f in answer.get("fields", [])]


def extras(answer):
    """The answer's engine-spoken members: candidates, conflicts, a clarification, a reason."""
    tree = {}
    if answer.get("candidates"):
        tree["candidates"] = [c["entity"] for c in answer["candidates"]]
    if answer.get("conflicts"):
        tree["conflicts"] = [{"path": c["path"], "values": sorted((r["value"] for r in c["rivals"]), key=json.dumps)}
                             for c in answer["conflicts"]]
    if answer.get("clarify"):
        tree["clarify"] = answer["clarify"]
    if answer.get("absent"):
        tree["reason"] = answer["absent"][0]["code"]
    if answer.get("problems") and "reason" not in tree:
        tree["reason"] = answer["problems"][0]["code"]
    return tree


def bound(wanted, answer, ids, keys):
    """Whether every expected member is bound by the answer. An engine-spoken
    member is read by its name; any other by what a field binds: the keys'
    reading says whether it is the entity, the value or the revision, and one
    field binds at most one expected value. Scalars, units, booleans and
    absence compare exactly."""
    spoken = canonical(extras(answer), ids)
    rest = {}
    for key, want in wanted.items():
        if key in spoken:
            if not contains(canonical(want, ids), spoken[key]):
                return False
        elif key in SPOKEN and not keys.get(key):
            return False
        else:
            rest[key] = canonical(want, ids)
    options = {}
    for key, want in rest.items():
        spec = keys.get(key, VALUE)
        options[key] = [i for i, t in enumerate(canonical(terms(answer, spec), ids)) if contains(want, t)]
        if not options[key]:
            return False
    return distinct(list(options.items()), keys, set())


def distinct(pending, keys, used):
    """An assignment of fields to the expected values they bind in which no value-bound field serves two."""
    if not pending:
        return True
    (key, hits), rest = pending[0], pending[1:]
    if keys.get(key, VALUE)["take"] != "value":
        return distinct(rest, keys, used)
    return any(distinct(rest, keys, used | {i}) for i in hits if i not in used)


def canonical(value, ids, key=None):
    if isinstance(value, dict):
        return {k: canonical(v, ids, k) for k, v in value.items()}
    if isinstance(value, list):
        items = [canonical(v, ids, key) for v in value]
        return sorted(items, key=json.dumps) if key in SET_KEYS else items
    if isinstance(value, str):
        value = ids.get(value, value)
        if len(value) >= 10 and value[:4].isdigit() and value[4] == "-":
            try:
                return utc_ms(value)
            except ValueError:
                return value
    return value


def contains(expected, actual):
    """Objects match on every expected field; everything else matches exactly."""
    if isinstance(expected, dict):
        return isinstance(actual, dict) and all(k in actual and contains(v, actual[k]) for k, v in expected.items())
    return expected == actual and isinstance(expected, bool) == isinstance(actual, bool)


def cited_sources(answer, by_ref):
    refs = [(c["source"]["observation"], c["source"]["revision"]) for c in answer.get("citations", [])]
    return {by_ref[r] for r in refs if r in by_ref}, [r for r in refs if r not in by_ref]


def grade(question, answer, ids, by_ref, superseded, keys=None):
    """Three independent verdicts for one structured answer."""
    expect = question["expect"]
    abstained = answer["status"] == expect["status"]
    wanted = {k: v for k, v in expect["answer"].items()
              if k not in expect.get("optional", []) or bound({k: v}, answer, ids, keys or {})}
    matched = abstained and bound(wanted, answer, ids, keys or {})
    for wanted_absence in expect.get("absent", []):
        found = any(
            a["code"] == wanted_absence["code"]
            and (wanted_absence.get("entity") is None or ids.get(a["path"][0], a["path"][0]) == wanted_absence["entity"])
            for a in answer.get("absent", [])
        )
        matched = matched and found
    cited, unknown = cited_sources(answer, by_ref)
    need = set(expect.get("evidence_all", []))
    any_of = set(expect.get("evidence_any", []))
    stale = set() if question.get("source_view") == "history" else cited & superseded
    provenance = (need <= cited and (not any_of or bool(any_of & cited)) and not unknown and not stale
                  and set(expect.get("policy_all", [])) <= set(answer.get("policies", [])))
    return {"answer": matched, "provenance": provenance, "abstention": abstained}


# ---- the run -----------------------------------------------------------------

def question_context(question, manifest, known_revision, previous):
    base = {**manifest["default_context"], **question.get("context", {})}
    return {
        "principal": base["principal"], "speaker": base.get("speaker"), "conversation": None,
        "question_at_ms": utc_ms(manifest["evaluation_time"]),
        "valid_at_ms": utc_ms(question["valid_at"]) if "valid_at" in question else None,
        "known_revision": known_revision, "previous_answer": previous,
    }


def locator(app, entities):
    """Gold person id -> the graph's entity for that email identity (the caller's own handle)."""
    gold = {e["id"]: e["identity"] for e in entities if e["identity"]}

    def locate(value):
        identity = gold.get(value)
        found = app.call({"op": "resolve", **identity}) if identity else {}
        return found.get("entity", value) if isinstance(found, dict) else value
    return locate


def span_overlap(a, b):
    return a[0] < b[1] and b[0] < a[1]


def id_map(app, entities, sources, by_ref):
    """Production entity id -> gold id, joined grader-side.

    People carry a gold external identity (read through `aliases`); the rest
    join on the source span that introduced them (read through `explain`
    locators) against the grader's gold anchors."""
    cache = {}
    gold = {(e["identity"]["namespace"], e["identity"]["key"]): e["id"] for e in entities if e["identity"]}
    by_source = {s["id"]: s for s in sources}
    anchors = [(g["gold"], g["source"], anchor_span(by_source[g["source"]], g["anchor"]))
               for g in oracle_gold() if g["source"] in by_source]

    def by_alias(value):
        aliases = app.call({"op": "aliases", "id": value})
        for alias in aliases if isinstance(aliases, list) else aliases.get("aliases", []):
            hit = gold.get((alias.get("namespace"), alias.get("key")))
            if hit:
                return hit
        return None

    def spans_of(run):
        """Byte spans a claim run is anchored at: the published locator, or each
        anchor's position selector (code points of the source text) as bytes."""
        locator = run.get("locator") or {}
        if isinstance(locator, dict) and locator.get("span"):
            return [(by_ref.get((run.get("input"), run.get("input_revision"))), locator["span"])]
        out = []
        for a in run.get("anchors") or []:
            origin = by_ref.get((a["source"]["observation"], a["source"]["revision"]))
            text = by_source[origin]["content"] if origin in by_source else None
            for sel in a.get("selectors", []):
                if sel.get("kind") == "TextPositionSelector" and text is not None:
                    out.append((origin, [len(text[:sel["start"]].encode()), len(text[:sel["end"]].encode())]))
        return out

    def by_anchor(value):
        fields = app.call({"op": "get", "id": value}).get("fields", {})
        for prop in fields:
            runs = app.call({"op": "explain", "id": value, "property": prop})
            for run in runs if isinstance(runs, list) else []:
                for source, span in spans_of(run):
                    for name, where, wanted in anchors:
                        if source == where and span_overlap(span, wanted):
                            return name
        return None

    def lookup(value):
        if value not in cache:
            cache[value] = by_alias(value) or by_anchor(value)
        return cache[value]
    return lookup


class Ids(dict):
    def __init__(self, lookup):
        super().__init__()
        self.lookup = lookup

    def get(self, value, default=None):
        return (self.lookup(value) if ":" in value else None) or default


def ready(mode, hooks, question, plans):
    missing = []
    if mode == "e2e" and not hooks.get("extractor"):
        missing.append("extractor")
    if mode in ORACLE_FACTS and not (ORACLE / "facts.jsonl").exists():
        missing.append("oracle/facts.jsonl")
    if mode in ORACLE_FACTS and question["id"] in oracle_blocked():
        return ["(blocked: " + oracle_blocked()[question["id"]] + ")"]
    if mode == "oracle-facts" and not hooks.get("planner") and question["id"] not in plans:
        return ["oracle plan"]
    if not hooks.get("planner") and question["id"] not in plans:
        missing.append("planner")
    return missing


class Cache:
    """Results a cut run already paid for, outside the repository, keyed by
    everything they depend on: an extraction by source revision, catalog
    fingerprint, extractor command and the extractor's code; a graded
    question by mode, question, checkpoint, app binary, catalog, the planner
    command and code, and the evidence it was asked over (the checkpoint's
    extraction keys, or the oracle's files). Held-out runs never use it.
    Failures are never kept, so a resumed run retries them.

    An extraction is keyed by `extraction_key`: the whole source envelope,
    the catalog fingerprint, the extractor command and the extractor's own
    identity (models, fitted parameters, bounds, environment, code), so an
    entry is served only to the extractor that would produce it."""

    def __init__(self, fixture):
        self.root = pathlib.Path.home() / ".cache/avra-graph-score" / fixture
        self.root.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def key(*parts):
        return hashlib.sha256(json.dumps(parts, sort_keys=True).encode()).hexdigest()

    @staticmethod
    def code(command):
        """A digest of the program files a hook command names."""
        files = [ROOT / w for w in shlex.split(command or "") if w.endswith(".py") and (ROOT / w).exists()]
        texts = [p.read_bytes() for f in files for p in sorted(f.parent.glob("*.py"))]
        return hashlib.sha256(b"".join(texts)).hexdigest()

    @staticmethod
    def identity(command):
        """What the extractor says decides its results (`--identity`), or, for
        a hook that cannot say, a digest of the programs beside it."""
        if command not in IDENTITIES:
            argv = shlex.split(command.replace("{schema}", os.devnull)) + ["--identity"]
            try:
                done = subprocess.run(argv, capture_output=True, text=True, cwd=ROOT)
                said = json.loads(done.stdout) if done.returncode == 0 else None
            except (OSError, ValueError):
                said = None
            IDENTITIES[command] = said if isinstance(said, dict) else {"unreported": Cache.code(command)}
        return IDENTITIES[command]

    def get(self, kind, key):
        path = self.root / kind / f"{key}.json"
        return json.loads(path.read_text()) if path.exists() else None

    def put(self, kind, key, value):
        (self.root / kind).mkdir(exist_ok=True)
        (self.root / kind / f"{key}.json").write_text(json.dumps(value))


CACHE = None
REPLAY = {}
IDENTITIES = {}
TIMINGS = HERE / "timings.json"


def fitted(name):
    """Seconds a hook may take: fitted from measured runs (timings.json, written
    by --fit-timeout), or unbounded before any measurement."""
    return json.loads(TIMINGS.read_text()).get(name) if TIMINGS.exists() else None


def extract_timeout():
    return fitted("extract_timeout_s")


def plan_calls(question):
    """Milliseconds of each model call a planned question made, from the
    planner's own `call op=… ms=…` log lines."""
    lines = (l for chunk in question.get("planner_log", []) for l in chunk.splitlines())
    return [int(l.rsplit("ms=", 1)[1]) for l in lines if l.startswith("planner: call ") and "ms=" in l]


def evidence_keys(trace, prefix):
    """The extraction keys a checkpoint's prefix was admitted on; the trace
    also holds batch records, which name no single source."""
    ids = {s["id"] for s in prefix}
    return [r["key"] for r in trace or [] if r.get("kind") == "source" and r["source"] in ids]


def fit_timeout(paths):
    """Each hook's slowest measured run, doubled: a call may take as long again
    as the slowest one seen before it is called stuck."""
    runs = [json.loads(pathlib.Path(p).read_text()) for p in paths]
    extractions = [e["ms"] for r in runs for e in r.get("extractions", [])
                   if "ms" in e and (e.get("result") or {}).get("status") == "complete"]
    asked = [q for r in runs for q in r.get("questions", {}).values() if q.get("planned") and not q.get("cached")]
    questions = [q["ms"] for q in asked if "ms" in q]
    calls = [plan_calls(q) for q in asked]
    out = {"fitted": {"rule": "twice the slowest measured complete run of each hook",
                      "on": [pathlib.Path(p).name for p in paths], "at": time.strftime("%Y-%m-%dT%H:%M:%S"),
                      "extractions": len(extractions), "questions": len(questions)}}
    if extractions:
        out["extract_timeout_s"] = 2 * max(extractions) / 1000
    timed = [ms for c in calls for ms in c]
    if timed:
        out["plan_call_timeout_s"] = 2 * max(timed) / 1000
        out["plan_timeout_s"] = out["plan_call_timeout_s"] * max(len(c) for c in calls)
        out["fitted"]["plan_rule"] = ("a planner's model call: twice the slowest measured call; a question: that bound "
                                      "times the most calls any measured question made")
        out["fitted"]["plan_calls"] = len(timed)
    elif questions:
        out["plan_timeout_s"] = 2 * max(questions) / 1000
    if len(out) == 1:
        sys.exit("no measured hook run in those results")
    TIMINGS.write_text(json.dumps(out, indent=1) + "\n")
    print({k: v for k, v in out.items() if k != "fitted"}, "->", TIMINGS.relative_to(ROOT))


def extraction_key(source, schema, hooks):
    return Cache.key("extraction/2", envelope(source), schema["fingerprint"], hooks["extractor"],
                     Cache.identity(hooks["extractor"]))


def legacy_code(command, rev):
    """`Cache.code` of the extractor's programs as `rev` committed them."""
    files = [w for w in shlex.split(command) if w.endswith(".py")]
    names = sorted(subprocess.run(["git", "ls-tree", "--name-only", rev, f"{(ROOT / f).parent.relative_to(ROOT)}/"],
                                  capture_output=True, text=True, cwd=ROOT, check=True).stdout.split()
                   for f in files[:1])[0]
    texts = [subprocess.run(["git", "show", f"{rev}:{n}"], capture_output=True, cwd=ROOT, check=True).stdout
             for n in names if n.endswith(".py")]
    return hashlib.sha256(b"".join(texts)).hexdigest()


def legacy_key(source, schema, hooks, code=None):
    """The key extractions were kept under before `extraction_key`: it did not
    see the source text, the fitted parameters or the models."""
    return Cache.key(source["id"], source["observation"], source["revision"], schema["fingerprint"],
                     hooks["extractor"], code or Cache.code(hooks["extractor"]))


def adopt_legacy(fixture, hooks, binary, scratch, rev=None, was=None):
    """Copies the extractions kept under the legacy key to the current key,
    leaving the originals, and logs each in adopted.jsonl. The legacy key did
    not see the fitted parameters, so an adoption is the caller's word that
    they have not changed since those entries were made."""
    app = App(binary, scratch / "adopt.db", scratch)
    schema = app.call({"op": "schema"})
    adopted = []
    code = legacy_code(was or hooks["extractor"], rev) if rev else None
    for s in fixture[1]:
        old, new = legacy_key(s, schema, {**hooks, "extractor": was or hooks["extractor"]}, code), extraction_key(s, schema, hooks)
        kept = CACHE.get("extractions", old)
        if kept is not None and CACHE.get("extractions", new) is None:
            CACHE.put("extractions", new, kept)
            adopted.append({"source": s["id"], "legacy": old, "key": new})
    with (CACHE.root / "adopted.jsonl").open("a") as log:
        for row in adopted:
            log.write(json.dumps({**row, "at": time.strftime("%Y-%m-%dT%H:%M:%S"),
                                  "identity": Cache.identity(hooks["extractor"])}) + "\n")
    print(f"adopted {len(adopted)} of {len(fixture[1])} legacy extractions (originals kept)")


def file_digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def publish_source(app, mode, hooks, source, schema, revision, trace=None):
    if mode in ORACLE_FACTS:
        for body in oracle_facts(source) or []:
            current = app.call({"op": "schema"}).get("revision", revision)
            receipt = app.call({"op": "publish", "schema": schema["fingerprint"],
                                "expected_revision": current, **body})
            if "error" in receipt:
                return receipt["error"]
        return None
    try:
        schema_file = app.scratch / "schema.json"
        schema_file.write_text(json.dumps(schema))
        log = []
        record = {"kind": "source", "source": source["id"], "log": log}
        if trace is not None:
            trace.append(record)
        key = extraction_key(source, schema, hooks)
        record["key"] = key
        result = CACHE.get("extractions", key) if CACHE else None
        record["cached"] = result is not None
        if result is None:
            started = time.time()
            result = run_hook(hooks["extractor"].replace("{schema}", str(schema_file)), envelope(source),
                              timeout=extract_timeout(), log=log)
            record["ms"] = int((time.time() - started) * 1000)
            if CACHE and result.get("status") == "complete":
                CACHE.put("extractions", key, result)
                CACHE.put("logs", key, "".join(log).splitlines())
        record["result"] = result
    except (RuntimeError, ValueError, subprocess.SubprocessError) as error:
        return f"extractor: {error}"
    admitted = app.call({"op": "admit", "source": envelope(source)["source"], "result": result})
    record["admit"] = admitted
    if hooks.get("resolver") and "error" not in admitted:
        try:
            record["resolve"] = run_hook(hooks["resolver"], {"graph": app.argv, "source": envelope(source), "receipt": admitted},
                                         timeout=extract_timeout(), log=log)
        except (RuntimeError, ValueError, subprocess.SubprocessError) as error:
            return f"resolver: {error}"
    return admitted.get("error")


def score_checkpoint(binary, checkpoint, questions, fixture, mode, hooks, scratch, trace=None):
    manifest, sources, entities, _ = fixture
    plans = oracle_plans() if mode == "oracle-facts" else {}
    rows = {}
    runnable = []
    for q in questions:
        missing = ready(mode, hooks, q, plans)
        if missing:
            rows[q["id"]] = {"status": "not-run", "reason": "missing " + ", ".join(missing)}
        else:
            runnable.append(q)
    if not runnable:
        return rows
    prefix = prefix_of(sources, checkpoint)
    app = App(binary, scratch / f"checkpoint-{checkpoint}.db", scratch)
    schema = app.call({"op": "schema"})
    by_ref, revisions = {}, {}
    for s in prefix:
        by_ref[(s["observation"], s["revision"])] = s["id"]
        revisions[s["observation"]] = s["id"]
    superseded = {s["id"] for s in prefix if revisions[s["observation"]] != s["id"]}
    failure = None
    for s in prefix:
        receipt = app.call({"op": "ingest", "source": envelope(s)})
        if "error" in receipt:
            failure = f"ingest {s['id']}: {receipt['error']}"
            break
        failure = publish_source(app, mode, hooks, s, schema, receipt.get("graph_revision", 0), trace)
        if failure:
            failure = f"publish {s['id']}: {failure}"
            break
        app.after[s["id"]] = app.call({"op": "schema"}).get("revision", 0)
    if failure:
        return {**rows, **{q["id"]: {"status": "error", "reason": failure} for q in runnable}}
    revision = app.call({"op": "schema"}).get("revision", 0)
    ids = Ids(id_map(app, entities, prefix, by_ref))
    locate = locator(app, entities)
    answers = {}
    evidence = (evidence_keys(trace, prefix) if mode == "e2e"
                else [file_digest(ORACLE / "facts.jsonl"), file_digest(ORACLE / "plans.jsonl")])
    for q in runnable:
        key = Cache.key(mode, q["id"], checkpoint, file_digest(pathlib.Path(binary)), schema["fingerprint"],
                        hooks.get("planner"), Cache.code(hooks.get("planner")), hooks.get("resolver"), Cache.code(hooks.get("resolver")), evidence, file_digest(HERE / "score.py"))
        follows = q.get("context", {}).get("previous_question")
        kept = CACHE.get("questions", key) if CACHE and not follows else None
        if kept:
            rows[q["id"]] = {**kept, "cached": True}
            answers[q["id"]] = (kept.get("response") or {}).get("request")
            continue
        rows[q["id"]] = ask(app, q, manifest, hooks, plans, schema, revision, answers, ids, by_ref, superseded, locate)
        if CACHE and rows[q["id"]]["status"] in ("pass", "fail"):
            CACHE.put("questions", key, rows[q["id"]])
    return rows


def iso_instant(ms):
    return datetime.datetime.fromtimestamp(ms / 1000, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def as_of_for(spec, context, after):
    """The read's view: valid time of the question, transaction time after a named source."""
    view = {}
    if spec.get("valid") == "question":
        view["valid_at"] = iso_instant(context.get("valid_at_ms") or context["question_at_ms"])
    if spec.get("after_source"):
        view["revision"] = after[spec["after_source"]]
    return view


def query_request(planned):
    """A planner answers {cypher, params}; an oracle or legacy hook answers a ReadPlan."""
    seen = {"as_of": planned["as_of"]} if planned.get("as_of") else {}
    if "cypher" in planned:
        return {"op": "query", "cypher": planned["cypher"], "params": planned.get("params", {}), **seen}
    return {"op": "query", "plan": planned, **seen}


def ask(app, q, manifest, hooks, plans, schema, revision, answers, ids, by_ref, superseded, locate):
    previous = answers.get(q.get("context", {}).get("previous_question"))
    context = question_context(q, manifest, revision, previous)
    context = {**context, **{k: locate(context[k]) for k in ("principal", "speaker") if context[k]}}
    started = time.time()
    record = {}
    try:
        if q["id"] in plans:
            plan = complete_plan(plans[q["id"]], "score-" + q["id"], schema, context,
                                 q.get("source_view", "current"))
            if plans[q["id"]].get("as_of"):
                plan = {**plan, "as_of": as_of_for(plans[q["id"]]["as_of"], context, app.after)}
        elif q["id"] in REPLAY:
            plan = REPLAY[q["id"]]
        else:
            log = []
            record["planner_log"] = log
            plan = run_hook(hooks["planner"], {
                "contract": 1, "request": "score-" + q["id"], "question": q["question"],
                "context": context, "source_view": q.get("source_view", "current"),
                "schema": schema, "graph": [str(app.binary), "request", "--db", str(app.db)]},
                timeout=fitted("plan_timeout_s"), log=log,
                env={"PLANNER_CALL_TIMEOUT_S": str(fitted("plan_call_timeout_s"))} if fitted("plan_call_timeout_s") else None)
        record["planned"] = plan
        answer = app.call(query_request(plan))
        record["response"] = answer
    except Exception as error:
        return {"status": "error", "reason": f"{type(error).__name__}: {error}", **record}
    if "error" in answer or "status" not in answer:
        return {"status": "error", "reason": str(answer.get("error", "no answer"))[:300], **record}
    answers[q["id"]] = answer.get("request")
    reading = {r["question"]: r["keys"] for r in oracle_readings()}.get(q["id"])
    verdict = grade(q, answer, ids, by_ref, superseded, reading)
    return {"status": "pass" if all(verdict.values()) else "fail", **verdict,
            "ms": int((time.time() - started) * 1000), "got": answer["status"], **record}


def streamed(command, payloads, timeout=None, log=None):
    """Runs a batch hook (`--stream`: a JSON array in, one JSON line
    {"index", "result"} out per payload as it completes) and yields each
    (index, result, log lines) as it arrives, so a cut run keeps what finished."""
    process = subprocess.Popen(shlex.split(command) + ["--stream"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True)
    process.stdin.write(json.dumps(payloads))
    process.stdin.close()
    deadline = time.time() + timeout if timeout else None
    try:
        for line in process.stdout:
            if line.strip():
                answer = json.loads(line)
                yield answer["index"], answer["result"], answer.get("log", [])
            if deadline and time.time() > deadline:
                raise subprocess.TimeoutExpired(command, timeout)
        stderr = process.stderr.read()
        if log is not None:
            log.append(stderr[-4000:])
        if process.wait() != 0:
            raise RuntimeError(f"hook exit {process.returncode}: {stderr.strip()[:300]}")
    finally:
        if process.poll() is None:
            process.kill()


def prefill(binary, fixture, mode, hooks, scratch, checkpoint, trace=None):
    """Extracts every source the checkpoints read that the cache lacks, in one
    streamed call of the extractor, so a resumed run pays its model loads once;
    each complete result is cached, under the key scoring asks, as it arrives."""
    if mode in ORACLE_FACTS or not CACHE or not hooks.get("extractor"):
        return
    app = App(binary, scratch / "prefill.db", scratch)
    schema = app.call({"op": "schema"})
    schema_file = scratch / "prefill-schema.json"
    schema_file.write_text(json.dumps(schema))
    keyed = [(extraction_key(s, schema, hooks), s) for s in fixture[1][:checkpoint]]
    missing = [(k, s) for k, s in keyed if CACHE.get("extractions", k) is None]
    if not missing:
        return
    per_source = extract_timeout()
    log, started, complete = [], time.time(), 0
    record = {"kind": "batch", "batch": [s["id"] for _, s in missing], "log": log}
    if trace is not None:
        trace.append(record)
    for index, result, lines in streamed(hooks["extractor"].replace("{schema}", str(schema_file)),
                                  [envelope(s) for _, s in missing],
                                  timeout=per_source * len(missing) if per_source else None, log=log):
        if result.get("status") == "complete":
            CACHE.put("extractions", missing[index][0], result)
            CACHE.put("logs", missing[index][0], lines)
            complete += 1
        record.update(batch_ms=int((time.time() - started) * 1000), complete=complete)


def score(binary, fixture, mode, hooks, scratch, only=None, trace=None):
    _, _, _, questions = fixture
    grouped = {}
    for q in questions:
        if not only or q["id"] in only:
            grouped.setdefault(q["checkpoint"], []).append(q)
    if grouped:
        prefill(binary, fixture, mode, hooks, scratch, max(grouped), trace)
    results = {}
    for checkpoint in sorted(grouped):
        results.update(score_checkpoint(binary, checkpoint, grouped[checkpoint], fixture, mode, hooks, scratch, trace))
    return {q["id"]: results[q["id"]] for q in questions if q["id"] in results}


def table(results):
    mark = {True: "ok", False: "NO", None: "-"}
    lines = [f"{'q':<4} {'status':<8} {'answer':<6} {'prov':<5} {'abst':<5} note"]
    for qid, r in results.items():
        lines.append(f"{qid:<4} {r['status']:<8} {mark[r.get('answer')]:<6} {mark[r.get('provenance')]:<5} "
                     f"{mark[r.get('abstention')]:<5} {r.get('reason', '')[:70]}")
    counts = {s: sum(r["status"] == s for r in results.values()) for s in STATUSES}
    lines.append("total " + " ".join(f"{s}={n}" for s, n in counts.items()) + f" of {len(results)}")
    return "\n".join(lines), counts


# ---- self test ---------------------------------------------------------------

FAKE_APP = '''#!/usr/bin/env python3
import json, sys
request = json.load(open(sys.argv[-1]))
op = request["op"]
if op == "schema":
    out = {"fingerprint": "f", "revision": 3, "models": []}
elif op == "ingest":
    out = {"graph_revision": 3}
elif op == "publish":
    out = {"revision": 4}
elif op == "aliases":
    out = {"aliases": []}
elif op == "query":
    out = json.load(open(sys.argv[0] + ".answer"))
else:
    out = {"error": "unknown op"}
print(json.dumps(out))
'''


def answer_for(person, source=("profile:rowan", 1)):
    return {"contract": 1, "request": "score-q01", "status": "answered", "read_revision": 3,
            "fields": [{"path": ["person"], "value": person, "basis": "observed", "citations": ["c1"]}],
            "citations": [{"id": "c1", "source": {"observation": source[0], "revision": source[1]}}],
            "policies": [], "problems": [], "candidates": []}


def bound_cases():
    """Plausible wrong answers still fail; right ones pass whatever their output names."""
    def field(name, value, entity="e:1"):
        return {"path": [entity, name], "value": value, "citations": []}

    reading = {"who": {"take": "entity"}, "age": {"take": "value"}, "kind": {"take": "value"}}
    want = {"who": "person:a", "age": 7, "kind": "x"}
    ids = {"e:1": "person:a", "e:2": "person:b"}

    class Ids(dict):
        get = lambda self, v, default=None: ids.get(v, default)

    def ok(fields, wanted=want, answer=None):
        return bound(wanted, {"fields": fields, **(answer or {})}, Ids(), reading)

    good = [field("a", 7), field("b", "x")]
    assert ok(good), "right values pass under any output name"
    assert not ok([field("a", 8), field("b", "x")]), "a wrong value fails"
    assert not ok([field("a", 7), field("b", "y")]), "a wrong second value fails"
    assert not ok([field("a", 7, "e:2"), field("b", "x", "e:2")]), "a wrong entity fails"
    assert not ok(good[:1]), "a missing member fails"
    assert not ok([field("a", 7)] * 2), "one field serves one value member"
    assert not ok([field("a", True), field("b", "x")], {**want, "age": 1}), "a bool is not an int"
    assert bound({"reason": "contains_silk"}, {"fields": [field("reason", "contains_silk")]}, Ids(), {"reason": {"take": "value"}})
    assert not bound({"reason": "contains_silk"}, {"fields": [field("reason", "other")]}, Ids(), {"reason": {"take": "value"}})
    assert not bound({"reason": "no_such"}, {"fields": [], "absent": [{"code": "other"}]}, Ids(), {})


def self_test():
    fixture = load_fixture()
    q01 = fixture[3][0]
    by_ref = {("profile:rowan", 1): "s01"}
    right = grade(q01, answer_for("person:elena"), {}, by_ref, set())
    assert all(right.values()), right
    wrong = grade(q01, answer_for("person:sora"), {}, by_ref, set())
    assert not wrong["answer"], wrong
    renamed = answer_for("person:elena")
    renamed["fields"][0]["path"] = ["any_alias_at_all"]
    assert grade(q01, renamed, {}, by_ref, set())["answer"], "an output name is not part of the answer"
    assert not grade(q01, {**renamed, "fields": []}, {}, by_ref, set())["answer"], "no field binds the value"
    assert not grade(q01, answer_for("person:elena", ("other", 1)), {}, by_ref, set())["provenance"]
    assert not grade(q01, answer_for("person:elena"), {}, by_ref, {"s01"})["provenance"]
    bound_cases()
    try:
        prefix_of(fixture[1], 5, picked=["s01", "s03", "s04", "s05", "s06"])
        raise AssertionError("cherry-picked prefix was accepted")
    except PrefixError:
        pass
    assert [s["id"] for s in prefix_of(fixture[1], 3)] == ["s01", "s02", "s03"]
    with tempfile.TemporaryDirectory(prefix="score-selftest-") as directory:
        scratch = pathlib.Path(directory)
        fake = scratch / "fake-app"
        fake.write_text(FAKE_APP)
        fake.chmod(0o755)
        silent = score(fake, fixture, "e2e", {}, scratch, only={"q01", "q08"})
        assert {r["status"] for r in silent.values()} == {"not-run"}, silent
        planner = f"{sys.executable} -c \"import json; print(json.dumps({{'steps': []}}))\""
        extractor = "echo {}"
        blocked = score(fake, fixture, "e2e", {"planner": planner, "extractor": extractor}, scratch, only={"q01"})
        assert blocked["q01"]["status"] == "error" and "unknown op" in blocked["q01"]["reason"], blocked
        facts = scratch / "oracle"
        facts.mkdir()
        (facts / "facts.jsonl").write_text(json.dumps({"source": "s01", "records": []}) + "\n")
        global ORACLE
        saved, ORACLE = ORACLE, facts
        try:
            for person, status in (("person:sora", "fail"), ("person:elena", "pass")):
                pathlib.Path(str(fake) + ".answer").write_text(json.dumps(answer_for(person)))
                got = score(fake, fixture, "oracle-facts", {"planner": planner}, scratch, only={"q01"})
                assert got["q01"]["status"] == status, got
        finally:
            ORACLE = saved
    held = json.loads(SPLIT.read_text())["heldout"][0]
    try:
        sealed([{"question": held}], "plans")
        raise AssertionError("oracle data keyed to a held-out question was accepted")
    except ValueError:
        pass
    assert sealed([{"question": "q01"}], "plans")
    src = read_lines(FIXTURE / "sources.jsonl")[0]
    schema, hooks = {"fingerprint": "f"}, {"extractor": "x"}
    IDENTITIES["x"] = {"params": "a"}
    base = extraction_key(src, schema, hooks)
    assert base == extraction_key(dict(src), schema, hooks)
    assert base != extraction_key({**src, "content": src["content"] + " "}, schema, hooks), "text unseen"
    assert base != extraction_key(src, {"fingerprint": "g"}, hooks), "catalog unseen"
    IDENTITIES["x"] = {"params": "b"}
    assert base != extraction_key(src, schema, hooks), "extractor identity unseen"
    IDENTITIES.clear()
    shown = [{"kind": "batch", "batch": ["s01"], "log": []}, {"kind": "source", "source": "s01", "key": "k1", "log": []},
             {"kind": "source", "source": "s99", "key": "k9", "log": []}]
    assert evidence_keys(shown, [{"id": "s01"}]) == ["k1"], "a batch record broke the evidence read"
    assert plan_calls({"planner_log": ["planner: call op=generate ms=900\nnoise\nplanner: call op=choose ms=12"]}) == [900, 12]
    print("score self-test passed: wrong fails, missing hooks not-run, cherry-picked prefix refused, extraction key sees text, catalog and extractor")


SLICE = "q01,q06,q07,q16,q46,q47"
SLICES = HERE / "slices.json"
# Modes publishing the oracle's facts: with the oracle's plans, or with the planner hook.
ORACLE_FACTS = ("oracle-facts", "planner")
SLICE_HOOKS = {
    "extractor": ("graph/extract/cascade.py", "python3 graph/extract/cascade.py --catalog {schema}"),
    "planner": ("graph/planner/plan.py", "python3 graph/planner/plan.py"),
    "resolver": ("graph/extract/resolve.py", "python3 graph/extract/resolve.py"),
}


def slice_ids(name):
    """A slice's question ids; a named slice is refused once the fixture it was
    derived from has moved."""
    if name == "demo":
        return SLICE
    recorded = json.loads(SLICES.read_text()) if SLICES.exists() else {}
    if name not in recorded or name == "provenance":
        sys.exit(f"no slice {name!r}: " + ", ".join(["demo"] + [k for k in recorded if k != "provenance"]))
    moved = [n for n, d in recorded["provenance"]["inputs"].items() if file_digest(FIXTURE / n) != d]
    if moved:
        sys.exit(f"slice {name!r} is stale ({', '.join(moved)} changed): run select_slice.py")
    return ",".join(recorded[name])


def slice_hooks(args):
    """Explicit flags win; otherwise a hook is on when its program exists."""
    found = {k: cmd for k, (path, cmd) in SLICE_HOOKS.items() if (ROOT / path).exists()}
    return {"extractor": args.extractor or found.get("extractor"), "planner": args.planner or found.get("planner"),
            "resolver": args.resolver or found.get("resolver")}


def load_split(questions):
    if SPLIT.exists():
        return json.loads(SPLIT.read_text())
    return {"heldout": [], "categories": {q["id"]: "development" for q in questions}}


def heldout_report(mode, hooks, results, extractions, categories):
    """Held-out questions print as an aggregate; details go to a private file."""
    counts = {s: sum(r["status"] == s for r in results.values()) for s in STATUSES}
    by = {}
    for qid, r in results.items():
        got = by.setdefault(categories[qid], [0, 0])
        got[0] += r["status"] == "pass"
        got[1] += 1
    print(f"== {mode} HELD-OUT  extractor={hooks['extractor']}  planner={hooks['planner']}")
    print("held-out: " + " ".join(f"{s}={n}" for s, n in counts.items()) + f" of {len(results)}")
    print("by category: " + ", ".join(f"{c} {p}/{n}" for c, (p, n) in sorted(by.items())))
    HELDOUT_RESULTS.mkdir(mode=0o700, exist_ok=True)
    out = HELDOUT_RESULTS / f"heldout-{mode}-{time.strftime('%Y%m%dT%H%M%S')}.json"
    body = json.dumps({"mode": mode, "hooks": hooks, "counts": counts, "questions": results,
                       "extractions": list(extractions)}, indent=2)
    descriptor = os.open(out, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w") as handle:
        handle.write(body)
    print("details: private file in heldout-results/ (mode 0600, ignored by git)")
    return counts


def report(mode, hooks, results, extractions=()):
    text, counts = table(results)
    print(f"== {mode}  extractor={hooks['extractor']}  planner={hooks['planner']}")
    print(text)
    RESULTS.mkdir(exist_ok=True)
    out = RESULTS / f"score-{mode}-{time.strftime('%Y%m%dT%H%M%S')}.json"
    out.write_text(json.dumps({"mode": mode, "hooks": hooks, "counts": counts, "questions": results,
                               "extractions": list(extractions)}, indent=2))
    print("results:", out.relative_to(ROOT))
    return counts


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("oracle-facts", "planner", "e2e"), default="e2e",
                        help="planner: the oracle's facts with the planner hook instead of the oracle's plans")
    parser.add_argument("--slice", nargs="?", const="demo", metavar="NAME",
                        help=f"demo ({SLICE}) or a slice named in slices.json (fast: derived by select_slice.py), "
                             "in every mode, default hooks when present")
    parser.add_argument("--extractor", help="command: source envelope JSON in, C01 extraction result JSON out")
    parser.add_argument("--planner", help="command: question + context JSON in, C01 ReadPlan JSON out")
    parser.add_argument("--resolver", help="command: after each admission, {graph, source, receipt} in; links entities across sources by `merge`")
    parser.add_argument("--regrade", metavar="RESULTS",
                        help="grade a results file's recorded plans again with this grader (no planner runs; "
                             "extractions come from the cache); writes a new results file and prints what flipped")
    parser.add_argument("--only", help="comma-separated development question ids")
    parser.add_argument("--heldout", action="store_true",
                        help="run the held-out questions; prints an aggregate only")
    parser.add_argument("--fixture", default=".", help="fixture directory under graph/acceptance (portability)")
    parser.add_argument("--binary", default=None)
    parser.add_argument("--build", action="store_true", help="build the fixture app first")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--fit-timeout", nargs="+", metavar="RESULTS",
                        help="fit the extraction timeout from e2e results files, then exit")
    parser.add_argument("--adopt-legacy", nargs="?", const="", metavar="REV",
                        help="copy extractions kept under the legacy key to the current key (originals stay), then exit; "
                             "REV is the commit whose extractor code made them")
    parser.add_argument("--legacy-extractor", help="with --adopt-legacy: the extractor command the entries were made under")
    parser.add_argument("--resume", action="store_true",
                        help="reuse extractions and graded questions a cut run already paid for (never held-out)")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if args.fit_timeout:
        return fit_timeout(args.fit_timeout)
    configure((HERE / args.fixture).resolve())
    global CACHE
    CACHE = Cache(FIXTURE.name if args.fixture != "." else "acceptance") if args.resume and not args.heldout else None
    args.binary = args.binary or str(BINARY)
    if args.build or not pathlib.Path(args.binary).exists():
        built = subprocess.run(["sh", "tools/watch.sh", "3500", "./build/avra", "build", str(FIXTURE.relative_to(ROOT) / "app")], cwd=ROOT)
        if built.returncode != 0:
            sys.exit("fixture app build failed")
    fixture = load_fixture()
    if args.adopt_legacy is not None:
        if not CACHE:
            sys.exit("--adopt-legacy needs --resume")
        with tempfile.TemporaryDirectory(prefix="graph-score-") as directory:
            return adopt_legacy(fixture, slice_hooks(args), pathlib.Path(args.binary), pathlib.Path(directory),
                                 args.adopt_legacy or None, args.legacy_extractor)
    split = load_split(fixture[3])
    held = set(split["heldout"])
    named = set((slice_ids(args.slice) if args.slice else args.only or "").split(",")) - {""}
    if named & held:
        sys.exit("held-out questions run only through --heldout: " + ", ".join(sorted(named & held)))
    if args.heldout:
        only = held
    else:
        only = named or {q["id"] for q in fixture[3]} - held
    runs = ("oracle-facts", "planner", "e2e") if args.slice else (args.mode,)
    hooks = slice_hooks(args) if args.slice else {"extractor": args.extractor, "planner": args.planner, "resolver": args.resolver}
    before = {}
    if args.regrade:
        if args.heldout:
            sys.exit("--regrade reads a development results file")
        old = json.loads(pathlib.Path(args.regrade).read_text())
        before = old["questions"]
        REPLAY.update({q: r["planned"] for q, r in before.items() if r.get("planned")})
        runs = (old["mode"],)
        hooks = {**old["hooks"], **{k: getattr(args, k) for k in ("extractor", "resolver") if getattr(args, k)},
                 "planner": "replay " + pathlib.Path(args.regrade).name}
        only = only & set(REPLAY)
    failed = False
    for mode in runs:
        with tempfile.TemporaryDirectory(prefix="graph-score-") as directory:
            extractions = []
            results = score(pathlib.Path(args.binary), fixture, mode, hooks, pathlib.Path(directory), only, extractions)
        counts = (heldout_report(mode, hooks, results, extractions, split["categories"]) if args.heldout
                  else report(mode, hooks, results, extractions))
        failed = failed or counts["pass"] != len(results)
        for q, r in results.items():
            if before and before[q]["status"] != r["status"]:
                print(f"flipped {q}: {before[q]['status']} -> {r['status']}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
