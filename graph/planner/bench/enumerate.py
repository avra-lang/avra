"""R1: enumerate the declared paths a question could take, execute them, and ask whether
the gold answer is reachable — and whether "keep the non-empty" alone picks it.

    python3 graph/planner/bench/enumerate.py

No model is asked anything and no extraction runs: the graph is built from the oracle
facts, so this measures the query side alone. Every candidate is a declared edge walk
out of an anchor the question names, rendered with the same query language the planner
uses; a survivor is a candidate that returned at least one value.
"""
import collections, datetime, json, os, pathlib, subprocess, sys, tempfile

HERE = pathlib.Path(__file__).resolve().parent.parent.parent
APP, ORM = HERE / 'acceptance/app/src/main', HERE / 'acceptance/oracle'
DB = pathlib.Path(tempfile.mkdtemp()) / 'r1.db'
DEPTH = 3

def app(body):
    with tempfile.NamedTemporaryFile('w', suffix='.json', delete=False) as f:
        json.dump(body, f); p = f.name
    out = subprocess.run([str(APP), 'request', '--db', str(DB), p], capture_output=True, text=True, timeout=120)
    os.unlink(p)
    try: return json.loads(out.stdout)
    except json.JSONDecodeError: return {"error": (out.stderr or out.stdout)[:300]}

def iso_ms(t):
    d = datetime.datetime.fromisoformat(t.replace('Z', '+00:00'))
    return int((d if d.tzinfo else d.replace(tzinfo=datetime.timezone.utc)).timestamp() * 1000)

def envelope(row):
    return {"contract": 2, "source": {"observation": row["observation"], "revision": row["revision"]},
            "authored_at_ms": None, "received_at_ms": iso_ms(row["received_at"]), "author": row.get("author"),
            "participants": [], "conversation": row.get("thread"), "media_type": "text/plain",
            "content": row["content"], "frames": []}

def bodies(source):
    for row in (json.loads(l) for l in open(ORM / 'facts.jsonl')):
        if row['source'] != source['id']: continue
        recs = [{"id": r["id"], "model": r["model"], "mode": r["mode"],
                 "value": {k: (iso_ms(v) if k.endswith('_ms') and isinstance(v, str) else v) for k, v in r["value"].items()},
                 "identities": r.get("identities", []), "locator": {"source": source["id"], "span": [0, 0]}}
                for r in row['records']]
        yield {"id": "oracle-" + source["id"], "producer": "oracle", "scope": source["id"],
               "input": source["observation"], "input_revision": source["revision"], "records": recs}

def build(schema):
    for line in open(HERE / 'acceptance/sources.jsonl'):
        src = json.loads(line)
        app({"op": "ingest", "source": envelope(src)})
        for b in bodies(src):
            cur = app({"op": "schema"}).get("revision", 0)
            app({"op": "publish", "schema": schema["fingerprint"], "expected_revision": cur, **b})

def ref(shape):
    if not isinstance(shape, dict): return None
    inner = shape.get('optional') or shape.get('list')
    return ref(inner) if inner is not None else shape.get('reference')

def graph_of(models):
    """Every declared edge, both ways: a reference property, or a relation's label value."""
    out = collections.defaultdict(set)
    for name, m in models.items():
        for p in m['properties']:
            t = ref(p['shape'])
            if t: out[name].add((t, p['name'])); out[t].add((name, p['name']))
        rel = (m.get('semantics') or {}).get('relation')
        if rel:
            seat = {p['name']: p for p in m['properties']}
            ends = [ref(seat[rel[s][0]]['shape']) if rel.get(s) and rel[s][0] in seat else None for s in ('from', 'to')]
            if all(ends):
                for lab in [v['value'] for v in rel.get('labels') or []]:
                    out[ends[0]].add((ends[1], lab)); out[ends[1]].add((ends[0], lab))
    return out

def walk(edges, start, depth):
    """[(steps, landing)] — every simple path of at most `depth` declared edges."""
    out, frontier = [], [([], start, (start,))]
    for _ in range(depth):
        nxt = []
        for steps, here, seen in frontier:
            for target, edge in sorted(edges[here]):
                if target in seen: continue
                step = ([f"-[:{edge}]->(b{len(steps)}:{target})"] if not steps else [f"-[:{edge}]->(b{len(steps)}:{target})"])
                frame = (steps[-1] if steps else "(a)") + step[0]
                out.append((steps + step, target))
                nxt.append((steps + step, target, seen + (target,)))
        frontier = nxt
    return out

def candidate_props(model):
    return [p['name'] for p in model['properties']]

def label_of(model):
    """The property a model is named by: its declared label, else its first required text."""
    declared = ((model.get('semantics') or {}).get('label') or [None])[0]
    if declared: return declared
    for p in model['properties']:
        sh = p['shape']
        if isinstance(sh, str) and sh == 'string' and p.get('default_source') is None and not p.get('enum'):
            return p['name']
    return None

def anchors(question, models):
    """The entities the question names: label values found in its own words."""
    said, out = question.lower(), []
    for name, m in models.items():
        lab = label_of(m)
        if not lab: continue
        r = app({"op": "query", "cypher": f"MATCH (a:{name}) RETURN a.{lab} AS v", "params": PARAMS})
        for f in r.get('fields', []):
            v = f.get('value')
            if isinstance(v, str) and len(v) > 2 and v.lower() in said:
                out.append((name, lab, v))
    return out

def queries_for(seed_model, seed_where, edges, models):
    """(cypher, landing, property) for every declared path out of one anchor."""
    out, seen = [], set()
    for steps, landing in [( [], seed_model)] + walk(edges, seed_model, DEPTH):
        body = "".join(steps)
        for prop in candidate_props(models[landing]):
            var = f"b{len(steps) - 1}" if steps else "a"
            cy = f"MATCH (a:{seed_model}) WHERE {seed_where} {body} RETURN {var}.{prop} AS value"
            if cy in seen: continue
            seen.add(cy); out.append((cy, landing, prop))
    return out

def values(ans):
    return sorted({json.dumps(f['value'], sort_keys=True) for f in ans.get('fields', []) if 'terms' not in f.get('path', [])})

def main():
    global PARAMS
    schema = app({"op": "schema"})
    build(schema)
    models = {m['name']: m for m in schema['models']}
    edges = graph_of(models)
    manifest = json.load(open(HERE / 'acceptance/manifest.json'))
    questions = [json.loads(l) for l in open(HERE / 'acceptance/questions.jsonl')]
    plans = {r['question']: r['cypher'] for r in (json.loads(l) for l in open(ORM / 'plans.jsonl')) if 'cypher' in r}
    split = set(json.load(open(HERE / 'acceptance/split.json'))['heldout'])

    tally = collections.Counter(); rows = []
    for q in questions:
        if q['id'] in split: continue
        ctx = {**manifest['default_context'], **q.get('context', {})}
        # the oracle publishes its records under `oracle:` ids
        as_oracle = lambda v: v.replace("person:", "oracle:") if isinstance(v, str) else v
        PARAMS = {"asker": as_oracle(ctx['principal']), "now": iso_ms(manifest['evaluation_time']),
                  "speaker": as_oracle(ctx.get('speaker') or ctx['principal']),
                  "valid_at": iso_ms(q['valid_at']) if 'valid_at' in q else None}
        gold = plans.get(q['id'])
        want = values(app({"op": "query", "cypher": gold, "params": PARAMS})) if gold else []
        seeds = [(m, lab, f"a.{lab} = $anchor", {"anchor": v}) for m, lab, v in anchors(q['question'], models)]
        seeds.append(("Person", None, "id(a) = $asker", {}))
        got, asked, empties = set(), 0, 0
        for model, lab, where, extra in seeds:
            for cy, landing, prop in queries_for(model, where, edges, models):
                asked += 1
                ans = app({"op": "query", "cypher": cy, "params": {**PARAMS, **extra}})
                vs = values(ans)
                if not vs: empties += 1
                got |= set(vs)
        hit = [w for w in want if w in got]
        stage = ('no gold plan' if not gold else 'reachable' if hit else 'unreachable')
        tally[stage] += 1
        if stage == 'reachable':
            distinct = len(got)
            tally['unique' if distinct <= len(want) else 'many'] += 1
        rows.append((q['id'], stage, asked, empties, len(got), len(want)))
        print(f"  {q['id']:4s} {stage:12s} asked={asked:4d} empty={empties:4d} distinct={len(got):4d} gold={len(want)}")

    print()
    print("of the development questions:", dict(tally))
    print("mean queries asked:", round(sum(r[2] for r in rows) / len(rows), 1),
          "| mean empties:", round(sum(r[3] for r in rows) / len(rows), 1))

PARAMS = {}
if __name__ == '__main__':
    main()
