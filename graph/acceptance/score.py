#!/usr/bin/env python3
"""Scores the graph end to end against the 50-question acceptance set.

Pipeline per checkpoint: fresh db, ingest sources 1..N (no other prefix is
accepted), publish facts (oracle or extracted), then ask each question
through a planner and the graph's `query` op. Missing hooks score `not-run`.
"""
import argparse
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
RESULTS = HERE / "results"
STATUSES = ("pass", "fail", "not-run", "error")
SET_KEYS = {"candidates", "excluded"}
MEDIA = {"csv": "text/csv"}


class PrefixError(ValueError):
    pass


def read_lines(path):
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def load_fixture(root=HERE):
    manifest = json.loads((root / "manifest.json").read_text())
    return (manifest, read_lines(root / "sources.jsonl"),
            read_lines(root / "entities.jsonl"), read_lines(root / "questions.jsonl"))


def utc_ms(text):
    stamp = text if "T" in text else text + "T00:00:00Z"
    return int(datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp() * 1000)


def envelope(source):
    ms = utc_ms(source["received_at"])
    return {
        "contract": 1,
        "source": {"observation": source["observation"], "revision": source["revision"]},
        "authored_at_ms": ms, "received_at_ms": ms, "author": source["author"],
        "participants": [], "conversation": source["thread"],
        "media_type": MEDIA.get(source["kind"], "text/plain"),
        "content": source["content"], "frames": [],
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


def run_hook(command, payload, timeout=120):
    done = subprocess.run(shlex.split(command), input=json.dumps(payload), text=True,
                          capture_output=True, timeout=timeout)
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


def oracle_plans():
    path = ORACLE / "plans.jsonl"
    return {row["question"]: row for row in read_lines(path)} if path.exists() else {}


def oracle_gold():
    path = ORACLE / "gold.jsonl"
    return read_lines(path) if path.exists() else []


def oracle_readings():
    path = ORACLE / "readings.jsonl"
    return read_lines(path) if path.exists() else []


def complete_plan(row, request, schema, context, view):
    return {"contract": 1, "request": request, "schema": schema["fingerprint"], "context": context,
            "source_view": view, "steps": row["steps"], "output": row["output"],
            "budget": {"steps": 32, "rows": 1000, "work": 100000, "depth": 4, "timeout_ms": 10000}}


# ---- projection and grading -------------------------------------------------

def nest(fields):
    tree = {}
    for field in fields:
        node = tree
        for token in field["path"][:-1]:
            node = node.setdefault(token, {})
        node[field["path"][-1]] = field["value"]
    return tree


def read_keys(answer, keys):
    """Grader-side reading of generic [entity, property] fields into manifest keys."""
    out = {}
    for key, spec in keys.items():
        for field in answer.get("fields", []):
            if field["path"][1:] == spec["suffix"]:
                out[key] = field["path"][0] if spec["take"] == "entity" else field["value"]
                break
    return out


def projection(answer, keys=None):
    """The actual answer as the same shape the manifest's expectations use."""
    tree = nest(answer.get("fields", []))
    tree.update(read_keys(answer, keys or {}))
    if answer.get("candidates"):
        tree["candidates"] = [c["entity"] for c in answer["candidates"]]
    if answer.get("clarify"):
        tree["clarify"] = answer["clarify"]
    if answer.get("problems") and "reason" not in tree:
        tree["reason"] = answer["problems"][0]["code"]
    return tree


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
    matched = abstained and contains(canonical(expect["answer"], ids), canonical(projection(answer, keys), ids))
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

    def by_anchor(value):
        fields = app.call({"op": "get", "id": value}).get("fields", {})
        for prop in fields:
            runs = app.call({"op": "explain", "id": value, "property": prop})
            for run in runs if isinstance(runs, list) else []:
                locator = run.get("locator") or {}
                source = by_ref.get((run.get("input"), run.get("input_revision")))
                span = locator.get("span") if isinstance(locator, dict) else None
                for name, where, wanted in anchors:
                    if span and source == where and span_overlap(span, wanted):
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
    if mode == "oracle-facts" and not (ORACLE / "facts.jsonl").exists():
        missing.append("oracle/facts.jsonl")
    if mode == "oracle-facts" and not hooks.get("planner") and question["id"] not in plans:
        return ["oracle plan"]
    if not hooks.get("planner") and question["id"] not in plans:
        missing.append("planner")
    return missing


def publish_source(app, mode, hooks, source, schema, revision):
    if mode == "oracle-facts":
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
        result = run_hook(hooks["extractor"].replace("{schema}", str(schema_file)), envelope(source))
    except (RuntimeError, ValueError, subprocess.SubprocessError) as error:
        return f"extractor: {error}"
    return app.call({"op": "admit", "source": envelope(source)["source"], "result": result}).get("error")


def score_checkpoint(binary, checkpoint, questions, fixture, mode, hooks, scratch):
    manifest, sources, entities, _ = fixture
    plans = oracle_plans()
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
        failure = publish_source(app, mode, hooks, s, schema, receipt.get("graph_revision", 0))
        if failure:
            failure = f"publish {s['id']}: {failure}"
            break
    if failure:
        return {**rows, **{q["id"]: {"status": "error", "reason": failure} for q in runnable}}
    revision = app.call({"op": "schema"}).get("revision", 0)
    ids = Ids(id_map(app, entities, prefix, by_ref))
    answers = {}
    for q in runnable:
        rows[q["id"]] = ask(app, q, manifest, hooks, plans, schema, revision, answers, ids, by_ref, superseded)
    return rows


def ask(app, q, manifest, hooks, plans, schema, revision, answers, ids, by_ref, superseded):
    previous = answers.get(q.get("context", {}).get("previous_question"))
    context = question_context(q, manifest, revision, previous)
    started = time.time()
    try:
        if q["id"] in plans and not hooks.get("planner"):
            plan = complete_plan(plans[q["id"]], "score-" + q["id"], schema, context,
                                 q.get("source_view", "current"))
        else:
            plan = run_hook(hooks["planner"], {
                "contract": 1, "request": "score-" + q["id"], "question": q["question"],
                "context": context, "source_view": q.get("source_view", "current"),
                "schema": schema})
        answer = app.call({"op": "query", "plan": plan})
    except Exception as error:
        return {"status": "error", "reason": f"{type(error).__name__}: {error}"}
    if "error" in answer or "status" not in answer:
        return {"status": "error", "reason": str(answer.get("error", "no answer"))[:300]}
    answers[q["id"]] = answer.get("request")
    reading = {r["question"]: r["keys"] for r in oracle_readings()}.get(q["id"])
    verdict = grade(q, answer, ids, by_ref, superseded, reading)
    return {"status": "pass" if all(verdict.values()) else "fail", **verdict,
            "ms": int((time.time() - started) * 1000), "got": answer["status"]}


def score(binary, fixture, mode, hooks, scratch, only=None):
    _, _, _, questions = fixture
    grouped = {}
    for q in questions:
        if not only or q["id"] in only:
            grouped.setdefault(q["checkpoint"], []).append(q)
    results = {}
    for checkpoint in sorted(grouped):
        results.update(score_checkpoint(binary, checkpoint, grouped[checkpoint], fixture, mode, hooks, scratch))
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


def self_test():
    fixture = load_fixture()
    q01 = fixture[3][0]
    by_ref = {("profile:rowan", 1): "s01"}
    right = grade(q01, answer_for("person:elena"), {}, by_ref, set())
    assert all(right.values()), right
    wrong = grade(q01, answer_for("person:sora"), {}, by_ref, set())
    assert not wrong["answer"], wrong
    assert not grade(q01, answer_for("person:elena", ("other", 1)), {}, by_ref, set())["provenance"]
    assert not grade(q01, answer_for("person:elena"), {}, by_ref, {"s01"})["provenance"]
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
    print("score self-test passed: wrong fails, missing hooks not-run, cherry-picked prefix refused")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("oracle-facts", "e2e"), default="e2e")
    parser.add_argument("--extractor", help="command: source envelope JSON in, C01 extraction result JSON out")
    parser.add_argument("--planner", help="command: question + context JSON in, C01 ReadPlan JSON out")
    parser.add_argument("--only", help="comma-separated question ids")
    parser.add_argument("--binary", default=str(BINARY))
    parser.add_argument("--build", action="store_true", help="build the fixture app first")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if args.build or not pathlib.Path(args.binary).exists():
        built = subprocess.run(["sh", "tools/watch.sh", "3500", "./build/avra", "build", "graph/acceptance/app"], cwd=ROOT)
        if built.returncode != 0:
            sys.exit("fixture app build failed")
    fixture = load_fixture()
    hooks = {"extractor": args.extractor, "planner": args.planner}
    with tempfile.TemporaryDirectory(prefix="graph-score-") as directory:
        results = score(pathlib.Path(args.binary), fixture, args.mode, hooks, pathlib.Path(directory),
                        set(args.only.split(",")) if args.only else None)
    text, counts = table(results)
    print(text)
    RESULTS.mkdir(exist_ok=True)
    stamp = time.strftime("%Y%m%dT%H%M%S")
    out = RESULTS / f"score-{args.mode}-{stamp}.json"
    out.write_text(json.dumps({"mode": args.mode, "hooks": hooks, "counts": counts, "questions": results}, indent=2))
    print("results:", out.relative_to(ROOT))
    sys.exit(0 if counts["pass"] == len(results) else 1)


if __name__ == "__main__":
    main()
