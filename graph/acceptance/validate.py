#!/usr/bin/env python3
"""Fixture integrity only: not an NLP model, answer scorer or semantic audit."""
import copy
import csv
import io
import json
import re
import pathlib
import sys
from datetime import date, datetime


ROOT = pathlib.Path(__file__).resolve().parent
STATUSES = {"answered", "ambiguous", "unknown", "refused"}
ENTITY_PREFIXES = ("person:", "org:", "product:", "invoice:", "order:", "event:",
                   "trip:", "pet:", "appointment:", "task:")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def load_lines(path):
    rows = []
    for line_number, line in enumerate(path.read_text().splitlines(), 1):
        require(bool(line.strip()), f"{path.name}:{line_number}: blank JSONL row")
        try:
            row = json.loads(line)
        except json.JSONDecodeError as error:
            raise ValueError(f"{path.name}:{line_number}: {error}") from error
        require(isinstance(row, dict), f"{path.name}:{line_number}: expected object")
        rows.append(row)
    return rows


def unique(rows, label):
    found = {}
    for row in rows:
        key = row["id"]
        require(isinstance(key, str) and key, f"{label}: missing ID")
        require(key not in found, f"{label}: duplicate ID {key}")
        found[key] = row
    return found


def timestamp(value):
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    require(parsed.utcoffset() is not None, f"timestamp lacks timezone: {value}")
    return parsed


def walk(value):
    yield value
    if isinstance(value, dict):
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def validate(data):
    manifest, sources, entities, questions, tasks = data
    require(manifest["synthetic"] is True, "fixture must be explicitly synthetic")
    require(len(sources) == manifest["source_count"], "source count mismatch")
    require(len(questions) == manifest["question_count"], "question count mismatch")
    source_map = unique(sources, "sources")
    entity_map = unique(entities, "entities")
    question_map = unique(questions, "questions")
    task_map = unique(tasks, "tasks")
    identities = set()
    for entity in entities:
        identity = entity["identity"]
        if identity is not None:
            key = (identity["namespace"], identity["key"])
            require(key not in identities, f"duplicate gold external identity: {key}")
            identities.add(key)
    require(manifest["default_context"]["principal"] in entity_map, "unknown principal")
    require(manifest["default_context"]["speaker"] in entity_map, "unknown speaker")
    revisions, previous_time = {}, None
    for seq, source in enumerate(sources, 1):
        require(source["seq"] == seq, f"source {source['id']}: sequence gap")
        require(source["id"] == f"s{seq:02}", "source ID/sequence mismatch")
        require(source["author"] in entity_map, "source author is unknown")
        require(bool(source["content"].strip()), "empty source payload")
        at = timestamp(source["received_at"])
        require(previous_time is None or at >= previous_time, "source chronology moved backwards")
        previous_time = at
        observation = source["observation"]
        require(source["revision"] == revisions.get(observation, 0) + 1,
                f"source {source['id']}: non-contiguous observation revision")
        revisions[observation] = source["revision"]
        if source["kind"] == "csv":
            rows = list(csv.DictReader(io.StringIO(source["content"])))
            require(bool(rows) and all(None not in row and None not in row.values() for row in rows),
                    f"source {source['id']}: malformed CSV")
    require(timestamp(manifest["evaluation_time"]) >= previous_time, "evaluation precedes inputs")
    require(all(0 < value <= len(sources) for value in manifest["checkpoints"].values()),
            "invalid named checkpoint")
    for number, question in enumerate(questions, 1):
        label = question["id"]
        require(label == f"q{number:02}", "question ID/sequence mismatch")
        require(question["split"] == ("development" if number <= 35 else "reserved"),
                f"{label}: unexpected split")
        checkpoint = question["checkpoint"]
        require(type(checkpoint) is int and 1 <= checkpoint <= len(sources), "invalid checkpoint")
        require(bool(question["question"].strip()) and bool(question["tags"]), "empty question/tags")
        if "valid_at" in question:
            date.fromisoformat(question["valid_at"])
        context = dict(manifest["default_context"], **question.get("context", {}))
        require(context["principal"] in entity_map and context["speaker"] in entity_map,
                f"{label}: unknown context identity")
        prior = context.get("previous_question")
        if prior:
            require(prior in question_map and prior < label, f"{label}: invalid prior turn")
            require(question_map[prior]["checkpoint"] == checkpoint, "prior turn checkpoint differs")
            require(question_map[prior].get("context", manifest["default_context"]) ==
                    {key: context[key] for key in ("principal", "speaker")}, "prior turn speaker differs")
        expected = question["expect"]
        require(expected["status"] in STATUSES, f"{label}: invalid answer status")
        require(isinstance(expected["answer"], dict), f"{label}: answer must be a projection object")
        require(set(expected.get("optional", [])) <= set(expected["answer"]),
                f"{question['id']}: optional keys must be keys of the expected answer")
        evidence = expected.get("evidence_all", []) + expected.get("evidence_any", [])
        policies = expected.get("policy_all", [])
        require(all(policy in manifest["trusted_policies"] for policy in policies),
                f"{label}: unknown trusted policy")
        require(bool(evidence) or expected["status"] == "refused" and bool(policies),
                f"{label}: missing evidence requirements")
        require(not set(expected.get("evidence_all", [])) & set(expected.get("evidence_any", [])),
                f"{label}: redundant evidence alternatives")
        source_view = question.get("source_view", "current")
        require(source_view in {"current", "history"}, f"{label}: invalid source view")
        for source_id in evidence:
            require(source_id in source_map, f"{label}: unknown evidence {source_id}")
            require(source_map[source_id]["seq"] <= checkpoint, f"{label}: future evidence leak")
            if source_view == "current":
                source = source_map[source_id]
                latest = max(s["revision"] for s in sources[:checkpoint]
                             if s["observation"] == source["observation"])
                require(source["revision"] == latest, f"{label}: superseded source in current view")
        for value in walk(expected["answer"]):
            if isinstance(value, str) and value.startswith(ENTITY_PREFIXES):
                require(value in entity_map, f"{label}: unknown gold entity {value}")
            if isinstance(value, dict) and "minor" in value:
                require(type(value["minor"]) is int, f"{label}: money must use integer minor units")
                require(value.get("currency") in {"EUR", "GBP"}, f"{label}: missing/unknown currency")
        if expected["status"] == "ambiguous":
            require(len(set(expected["answer"].get("candidates", []))) >= 2, "ambiguity needs candidates")
        if expected["status"] in {"unknown", "refused"}:
            require(bool(expected["answer"].get("reason")), "abstention needs a reason")
    for task in tasks:
        require(task["state"] in {"done", "ready", "planned"}, "unknown task state")
        require(task["owns"] and task["deliverable"] and task["acceptance"], "incomplete task brief")
        for path in task["owns"]:
            require(path.startswith("graph/") and ".." not in pathlib.PurePosixPath(path).parts,
                    f"{task['id']}: invalid write boundary")
        for dependency in task["depends_on"]:
            require(dependency in task_map, f"{task['id']}: unknown dependency {dependency}")
            if task["state"] in {"ready", "done"}:
                require(task_map[dependency]["state"] == "done", "task marked ready before dependencies")
    active, visited = set(), set()

    def visit(key):
        require(key not in active, f"task dependency cycle at {key}")
        if key in visited:
            return
        active.add(key)
        for dependency in task_map[key]["depends_on"]:
            visit(dependency)
        active.remove(key)
        visited.add(key)

    for key in task_map:
        visit(key)


GRAPH = ROOT.parent
GENERIC = {"Store", "Works", "Jacket"}
PRIVATE_KINDS = {"Person", "Organization", "Product", "Pet", "Resident", "Merchant"}
SCANNED = ("acceptance/app/src/models", "acceptance/portability/app/src/models", "extract", "planner", "cypher", "src")
SKIPPED = {"bench", "recorded", "__pycache__", "build"}
SUFFIXES = {".av", ".py", ".md", ".toml", ".json"}


def leak_pattern(entities, sources):
    """Fixture names, document identifiers and mail domains as one regex."""
    return leak_union([(entities, sources)])


def leak_union(fixtures):
    entities = [e for ents, _ in fixtures for e in ents]
    sources = [s for _, srcs in fixtures for s in srcs]
    words = {w for e in entities if e["kind"] in PRIVATE_KINDS for w in re.findall(r"[A-Z][a-z]+", e["label"])}
    domains = {d for s in sources for d in re.findall(r"@([\w-]+\.example)", s["content"])}
    parts = [r"\b(?:" + "|".join(sorted(words - GENERIC)) + r")\b", r"\b(?:INV|PO|R)-\d+\b", r"\bNJ-\d+\b"]
    parts += [re.escape(d) for d in sorted(domains)]
    return re.compile("|".join(parts))


def leaks(root, pattern):
    """Every fixture token the engine, extractor, planner and app declarations carry."""
    found = []
    for rel in SCANNED:
        base = root / rel
        for path in sorted(base.rglob("*")) if base.exists() else []:
            if path.is_file() and path.suffix in SUFFIXES and not SKIPPED & set(path.parts):
                for number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
                    hit = pattern.search(line)
                    if hit:
                        found.append(f"{path.relative_to(root)}:{number}: {hit.group(0)}")
    return found


SLICE_IDS = {"q01", "q06", "q07", "q16", "q46", "q47"}


def check_split(questions):
    split = json.loads((ROOT / "split.json").read_text())
    ids = {q["id"] for q in questions}
    held = set(split["heldout"])
    require(held <= ids, "split: unknown held-out question")
    require(set(split["categories"]) == ids, "split: every question has one category")
    require(not held & SLICE_IDS, "split: slice questions stay in development")
    categories = set(split["categories"].values())
    require({split["categories"][q] for q in held} == categories - {"injection"},
            "split: every multi-question category has a held-out member")


PORTABILITY = ROOT / "portability"
HARDCODE_BASELINE = ROOT / "hardcoding.baseline"
HARDCODE_ROOTS = ("extract", "planner", "src")
_STR = r"(?:\"[^\"\n]+\"|'[^'\n]+')"
WORD_LIST = re.compile(r"[\[{(]\s*" + _STR + r"(?:\s*,\s*" + _STR + r"){3,}")
THRESHOLD = re.compile(
    r"(?:<=|>=|<|>|==)\s*-?\d+\.\d+|(?:<=|>=|<|>)\s*\d{2,}\b|^\s*[A-Z][A-Z_0-9]*\s*=\s*-?\d+(?:\.\d+)?\s*$"
)


def hardcoded_sites(root):
    """Word lists and numeric thresholds in engine, extractor and planner code.

    A calibrated-parameters file (its name says `parameters`) is the one place
    such values may live; tests, benches and recordings are not code."""
    found = []
    for rel in HARDCODE_ROOTS:
        for path in sorted((root / rel).rglob("*")):
            parts = set(path.parts)
            if (path.is_file() and path.suffix in (".py", ".av") and not {"bench", "recorded", "__pycache__", "tests"} & parts
                    and not path.name.startswith("test_") and "parameters" not in path.name):
                for line in path.read_text(errors="ignore").splitlines():
                    if WORD_LIST.search(line) or THRESHOLD.search(line):
                        found.append(f"{path.relative_to(root)} :: {line.strip()}")
    return sorted(set(found))


def check_hardcoding(root):
    baseline = set(HARDCODE_BASELINE.read_text().splitlines()) if HARDCODE_BASELINE.exists() else set()
    sites = hardcoded_sites(root)
    new = [site for site in sites if site not in baseline]
    require(not new, "hardcoded word lists or thresholds outside a parameters file (baseline only shrinks):\n  "
            + "\n  ".join(new[:20]))
    gone = len(baseline - set(sites))
    return len(sites), gone


def init_hardcoding_baseline(root):
    require(not HARDCODE_BASELINE.exists(), "the hardcoding baseline exists; it only shrinks")
    HARDCODE_BASELINE.write_text("".join(site + "\n" for site in hardcoded_sites(root)))


def prune_hardcoding_baseline(root):
    keep = set(hardcoded_sites(root))
    old = HARDCODE_BASELINE.read_text().splitlines()
    HARDCODE_BASELINE.write_text("".join(line + "\n" for line in old if line in keep))


def check_portability(entities, sources):
    """The second fixture is well formed and shares no names or domains with the first."""
    manifest = json.loads((PORTABILITY / "manifest.json").read_text())
    p_sources = load_lines(PORTABILITY / "sources.jsonl")
    p_entities = load_lines(PORTABILITY / "entities.jsonl")
    p_questions = load_lines(PORTABILITY / "questions.jsonl")
    require(len(p_sources) == manifest["source_count"], "portability: source count")
    require(len(p_questions) == manifest["question_count"], "portability: question count")
    seqs = {s["id"]: s["seq"] for s in p_sources}
    gold = {e["id"] for e in p_entities}
    for q in p_questions:
        require(q["checkpoint"] <= len(p_sources), f"portability {q['id']}: checkpoint past the sources")
        for ev in q["expect"].get("evidence_all", []):
            require(ev in seqs and seqs[ev] <= q["checkpoint"], f"portability {q['id']}: evidence {ev} is not known at its checkpoint")
        for token in json.dumps(q["expect"]["answer"]).replace('"', " ").split():
            if token.startswith(("resident:", "tool:", "plant:", "order:", "repair:", "merchant:", "loan:")):
                require(token.strip(",:}]") in gold, f"portability {q['id']}: unknown gold {token}")
    first = leak_union([(entities, sources)])
    texts = [e["label"] for e in p_entities] + [s["content"] for s in p_sources]
    shared = sorted({m.group(0) for t in texts for m in first.finditer(t)})
    require(not shared, "portability shares fixture tokens with the first fixture: " + ", ".join(shared))


def self_test(data):
    def cyclic(altered):
        for task in altered[4]:
            task["state"] = "planned"
        altered[4][0]["depends_on"] = ["A01"]

    mutations = [
        ("non-contiguous", lambda d: d[1][0].update(revision=2)),
        ("chronology", lambda d: d[1][1].update(received_at="2020-01-01T00:00:00Z")),
        ("duplicate gold", lambda d: d[2][1].update(identity=d[2][0]["identity"])),
        ("unknown evidence", lambda d: d[3][0]["expect"].update(evidence_all=["missing"])),
        ("future evidence", lambda d: d[3][0].update(checkpoint=1, expect={"status":"answered", "answer":{}, "evidence_all":["s30"]})),
        ("unknown gold", lambda d: d[3][0]["expect"].update(answer={"person":"person:missing"})),
        ("integer minor", lambda d: d[3][0]["expect"].update(answer={"money":{"minor":1.2,"currency":"EUR"}})),
        ("unknown dependency", lambda d: d[4][0].update(depends_on=["missing"])),
        ("dependency cycle", cyclic),
        ("superseded source", lambda d: d[3][47]["expect"].update(evidence_all=["s02"])),
        ("missing evidence", lambda d: d[3][0]["expect"].update(evidence_all=[])),
        ("unknown trusted policy", lambda d: d[3][48]["expect"].update(policy_all=["untrusted-document"])),
        ("invalid source view", lambda d: d[3][0].update(source_view="future")),
    ]
    for number, (expected_error, mutate) in enumerate(mutations, 1):
        altered = copy.deepcopy(data)
        mutate(altered)
        try:
            validate(altered)
        except ValueError as error:
            require(expected_error in str(error), f"negative witness {number} failed for the wrong reason: {error}")
            continue
        raise ValueError(f"negative witness {number} was incorrectly accepted")
    pattern = leak_pattern(data[2], data[1])
    for text in ("Rowan's wife Elena", "mail alex@velluto-works.example", "see INV-204", "NJ-01 jacket"):
        require(pattern.search(text), f"leak witness missed: {text}")
    both = leak_union([(data[2], data[1]), (load_lines(PORTABILITY / "entities.jsonl"), load_lines(PORTABILITY / "sources.jsonl"))])
    for text in ("Teodor lent the auger", "mail odalys@larkspur.example", "Greenholt Nursery"):
        require(both.search(text), f"second-fixture leak witness missed: {text}")
    for text in ("a founder's spouse", "Dana Ferris", "mail dana@example.test"):
        require(not pattern.search(text), f"leak witness refused innocent text: {text}")
    for text in ('words = ["a", "b", "c", "d"]', "if score >= 0.65:", "LIMIT = 40", "if n > 30 {"):
        require(WORD_LIST.search(text) or THRESHOLD.search(text), f"hardcoding witness missed: {text}")
    for text in ('names = ["a", "b"]', "if n > 3:", "x = items[0]"):
        require(not (WORD_LIST.search(text) or THRESHOLD.search(text)), f"hardcoding refused innocent text: {text}")
    print(f"integrity self-test: {len(mutations)} invalid fixtures refused, leak pattern witnessed")


def main():
    require(sys.argv[1:] in ([], ["--self-test"], ["--hardcoding-init"], ["--hardcoding-prune"]),
            "usage: validate.py [--self-test | --hardcoding-init | --hardcoding-prune]")
    if sys.argv[1:] == ["--hardcoding-init"]:
        return init_hardcoding_baseline(GRAPH)
    if sys.argv[1:] == ["--hardcoding-prune"]:
        return prune_hardcoding_baseline(GRAPH)
    manifest = json.loads((ROOT / "manifest.json").read_text())
    data = (manifest, *(load_lines(ROOT / manifest[key])
                        for key in ("sources", "entities", "questions", "tasks")))
    validate(data)
    check_split(data[3])
    p_entities = load_lines(PORTABILITY / "entities.jsonl")
    p_sources = load_lines(PORTABILITY / "sources.jsonl")
    check_portability(data[2], data[1])
    leaked = leaks(GRAPH, leak_union([(data[2], data[1]), (p_entities, p_sources)]))
    require(not leaked, "fixture tokens outside the fixture:\n  " + "\n  ".join(leaked[:20]))
    sites, gone = check_hardcoding(GRAPH)
    if sys.argv[1:]:
        self_test(data)
    print(f"fixture integrity: {len(data[1])} sources, {len(data[2])} gold entities, "
          f"{len(data[3])} questions, {len(data[4])} acyclic task briefs; NOT an NLP pass")
    print(f"hardcoding audit: {sites} baseline sites, {gone} prunable")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError, OSError) as error:
        print(f"fixture integrity failed: {error}", file=sys.stderr)
        sys.exit(1)
