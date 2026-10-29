"""Does the 4B write Cypher that is legal AND answers the question?

    python3 graph/planner/bench/llm_cypher.py

Oracle facts (so extraction is perfect), development questions, the compact schema and
every declared link in the prompt, WITH desugared — a no-op in a subset that carries
every binding forward — and the engine's own refusal fed back once. Correctness is the
gold plan's values read from the same graph at the same view.

This is the measurement the "let the model write the query" route needs before it is
built: a legal query is not an answer, and only the engine can say which is which.
"""
import collections, json, os, pathlib, re, socket, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent.parent.parent
ORM = HERE/'acceptance/oracle'
SOCK = os.environ.get("AVRA_GRAPH_SOCKET") or os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")
DB = pathlib.Path(tempfile.mkdtemp())/'llm.db'

import importlib.util
_spec = importlib.util.spec_from_file_location("enum_bench", HERE/'planner/bench/enumerate.py')
enum = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(enum)
enum.DB = pathlib.Path(tempfile.mkdtemp())/'llm.db'
app, build, ref, iso_ms, values = enum.app, enum.build, enum.ref, enum.iso_ms, enum.values

def gen(prompt, messages=()):
    body = {"op": "generate", "messages": [{"role":"user","content":prompt}, *messages], "max_tokens": 260}
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.settimeout(600); s.connect(SOCK)
    s.sendall((json.dumps(body)+"\n").encode())
    d = b""
    while not d.endswith(b"\n"):
        c = s.recv(65536)
        if not c: break
        d += c
    return json.loads(d).get("text","")

def clean(t):
    """The query a reply carries: a reasoning block dropped, fences stripped, and the
    statement taken from where it starts — the model may think before it answers."""
    t = t.strip()
    t = re.sub(r"(?s)^\s*<think.*?<\/think>\s*", "", t)   # a closed reasoning block
    t = re.sub(r"(?s)^\s*<\/think>\s*", "", t)            # its tail, when the head was cut
    t = re.sub(r"(?s)^\s*<think\s*", "", t)
    for f in ("```cypher", "```Cypher", "```"):
        if t.startswith(f): t = t[len(f):]
    if "```" in t: t = t.split("```")[0]
    lines = [l for l in t.splitlines() if l.strip()]
    start = next((i for i, l in enumerate(lines) if l.lstrip().upper().startswith(("MATCH", "OPTIONAL"))), 0)
    return " ".join(" ".join(lines[start:]).split())


def desugar(t):
    return re.sub(r"\bWITH\s+[A-Za-z_]\w*(\s*,\s*[A-Za-z_]\w*)*\s+", "", t)

def compact(schema):
    out = []
    for m in schema["models"]:
        props = []
        for p in m["properties"]:
            sh = p["shape"]
            if isinstance(sh, dict):
                inner = sh.get("optional") or sh.get("list") or sh
                kind = ("ref:"+inner["reference"]) if isinstance(inner,dict) and "reference" in inner else \
                       ("embedded:"+inner["embedded"]) if isinstance(inner,dict) and "embedded" in inner else \
                       ("list" if "list" in sh else "opt" if "optional" in sh else json.dumps(inner)[:16])
            else: kind = str(sh)
            if p.get("time"): kind += "/"+p["time"]["encoding"]
            if p.get("enum"): kind += "="+"|".join(p["enum"])
            props.append(f"{p['name']}:{kind}")
        out.append(f"{m['name']}({', '.join(props)})")
    return "\n".join(out)

def main():
    schema = app({"op":"schema"}); build(schema)
    models = {m['name']: m for m in schema['models']}
    edges = []
    for name, m in models.items():
        for p in m['properties']:
            t = ref(p['shape'])
            if t: edges.append(f"({name})-[:{p['name']}]->({t})")
        rel = (m.get('semantics') or {}).get('relation')
        if rel:
            seat = {p['name']: p for p in m['properties']}
            ends = [ref(seat[rel[s][0]]['shape']) if rel.get(s) and rel[s][0] in seat else None for s in ('from','to')]
            if all(ends):
                for lab in [v['value'] for v in rel.get('labels') or []]:
                    edges.append(f"({ends[0]})-[:{lab}]->({ends[1]})")
    schema_text = compact(schema)
    manifest = json.load(open(HERE/'acceptance/manifest.json'))
    questions = [json.loads(l) for l in open(HERE/'acceptance/questions.jsonl')]
    plans = {r['question']: r['cypher'] for r in (json.loads(l) for l in open(ORM/'plans.jsonl')) if 'cypher' in r}
    split = set(json.load(open(HERE/'acceptance/split.json'))['heldout'])
    print(f"compact schema: {len(schema_text)} chars, {len(edges)} links")

    tally, reasons = collections.Counter(), collections.Counter()
    for q in questions:
        if q['id'] in split or q['id'] not in plans: continue
        ctx = {**manifest['default_context'], **q.get('context', {})}
        P = {"asker": "oracle:rowan", "now": iso_ms(manifest['evaluation_time']),
             "speaker": "oracle:rowan", "valid_at": iso_ms(q['valid_at']) if 'valid_at' in q else None}
        view = {"as_of": {"valid_at": P["valid_at"]}} if P.get("valid_at") else {}
        want = values(app({"op":"query","cypher":plans[q['id']],"params":P,**view}))
        prompt = (f"Write one Cypher query that answers the question.\n\n"
                  f"TYPES (name(property:shape); ref:X points at type X; opt/list are optional/many):\n{schema_text}\n\n"
                  f"LINKS (the only edges allowed, written (A)-[:name]->(B)):\n" + "\n".join(edges) + "\n\n"
                  "Rules: no WITH, no ORDER BY, no UNWIND; follow a reference with a LINK, never a.b.c; "
                  "every RETURN item needs its own AS name; use $asker, $now, $speaker.\n"
                  "Answer with the query only.\n\n"
                  f"QUESTION: {q['question']}\n\nCypher:")
        said, legal, correct = [], False, False
        for attempt in range(2):
            cy = desugar(clean(gen(prompt, said)))
            chk = app({"op":"check","cypher":cy,"params":P})
            if chk.get("ok") is True:
                legal = True
                got = values(app({"op":"query","cypher":cy,"params":P,**view}))
                correct = bool(want) and got == want
                break
            reasons[chk.get("code")] += 1
            said = [("assistant", cy), ("user", f"Refused: {chk.get('code')}: {chk.get('message')}. Give the corrected query only.")]
        tally['legal' if legal else 'illegal'] += 1
        tally['correct' if correct else ('legal-wrong' if legal else 'no-query')] += 1
        print(f"  {q['id']:4s} {'LEGAL ' if legal else 'illegal'} {'CORRECT' if correct else ''}")

    print("\n", dict(tally))
    print(" refusal codes:", dict(reasons))

if __name__ == '__main__':
    main()
