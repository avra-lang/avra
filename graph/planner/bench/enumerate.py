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
DEPTH = 3   # overridden by --depth; a bound on the walk, not a fact about any model

SOCK = os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")

def CHOOSE(context, options):
    """The service's closed choice over the declared shapes."""
    import socket as _s
    body = {"op": "choose", "context": f'Question: "{context}"', "question": "What kind of answer does the question ask for?", "options": options}
    sk = _s.socket(_s.AF_UNIX, _s.SOCK_STREAM); sk.settimeout(300); sk.connect(SOCK)
    sk.sendall((json.dumps(body) + "\n").encode())
    d = b""
    while not d.endswith(b"\n"):
        c = sk.recv(65536)
        if not c: break
        d += c
    return json.loads(d).get("p") or [0.0] * len(options)

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

def declared_filters(question, model):
    """The enum values a question speaks that this model declares, as (property, value):
    a narrowing the schema itself names, so no word list is involved."""
    said = question.lower()
    return [(p['name'], v) for p in model['properties'] for v in (p.get('enum') or []) if v.lower() in said]

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

SHAPE_SAID = {
    "text": "a word, a name or a piece of text",
    "number": "a number",
    "time": "a date or a point in time",
    "bool": "a yes or a no",
    "enum": "one of the values that type declares",
    "entity": "another record it points at",
    "count": "how many of something",
}

def shape_of_property(p):
    """The declared shape of a property's value, read from its own declaration."""
    sh = p['shape']
    inner = (sh.get('optional') or sh.get('list') or sh) if isinstance(sh, dict) else sh
    if isinstance(inner, dict) and 'reference' in inner: return 'entity'
    if isinstance(inner, dict) and 'embedded' in inner: return 'embedded'
    if p.get('time'): return 'time'
    if p.get('enum'): return 'enum'
    return {'string': 'text', 'integer': 'number', 'number': 'number', 'boolean': 'bool'}.get(str(inner), 'other')

def shape_options(models, cat, question):
    """The shapes this question might want, each worded from the declarations that hold it."""
    seen = {}
    for name, m in models.items():
        for p in m['properties']:
            k = shape_of_property(p)
            seen.setdefault(k, []).append(p['name'].replace('_', ' '))
    for q in (m.get('semantics') or {}).get('quantities') or []:
        seen.setdefault('count', []).append('units')
    for d in cat.get('derivations', []):
        seen.setdefault("derived:" + d['name'], []).append((d.get('description') or d['name']).split('.')[0])
    rendered = []
    for k, names in seen.items():
        if k.startswith('derived:'):
            rendered.append((k, names[0] if names else k))
        else:
            said = SHAPE_SAID.get(k, k)
            rendered.append((k, f"{said}: {', '.join(sorted(set(names))[:6])}"))
    return rendered

def derivation_queries(seed_model, seed_where, models, cat, edges, literals=()):
    """Every declared derivation the seed can feed: each `one` seat takes a node of its
    declared type (the seed itself, or a scan), each `all` seat a collection of its type, and
    a seat declared as a bare scalar takes a value the caller offers — the graph's own, never
    an invented one. A derivation with a scalar seat and no value offered is reported instead
    of guessed."""
    out, skipped = [], []
    for d in cat.get('derivations', []):
        seats = [(p['name'], p['input']) for p in d['parameters']]
        if any(not isinstance(i, dict) for _, i in seats) and not literals:
            skipped.append(d['name'])
            continue
        if not any(isinstance(i, dict) and i.get('one') == seed_model for _, i in seats):
            continue
        args, matchers, ok, took_seed = [], [], True, False
        for k, (name, inp) in enumerate(seats):
            if not isinstance(inp, dict):
                args.append(json.dumps(literals[0]))
                continue
            var = f"d{k}"
            model = inp.get('one') or inp.get('all')
            if model not in models:
                ok = False
                break
            if inp.get('all'):
                args.append(f"collect({var})")
                matchers.append(f"MATCH ({var}:{model})")
            elif inp.get('one') == seed_model and not took_seed:
                args.append("a")
                took_seed = True
            else:
                args.append(var)
                matchers.append(f"MATCH ({var}:{model})")
        if not ok:
            continue
        cy = (f"MATCH (a:{seed_model}) WHERE {seed_where} " + " ".join(matchers)
              + f" RETURN {d['name']}({', '.join(args)}) AS value")
        out.append((cy, d['output'], d['name']))
    return out, skipped


def derivation_scans(models, cat, literals=()):
    """Every declared derivation computed over the records themselves, with no anchor: a
    question may ask about "the invoice" without naming one, and then the derivation is the
    answer's shape. Each seat scans its declared type; a scalar seat takes a value offered."""
    out, skipped = [], []
    for d in cat.get('derivations', []):
        seats = [(p['name'], p['input']) for p in d['parameters']]
        if any(not isinstance(i, dict) for _, i in seats) and not literals:
            skipped.append(d['name'])
            continue
        args, matchers, ok = [], [], True
        for k, (name, inp) in enumerate(seats):
            if not isinstance(inp, dict):
                args.append(json.dumps(literals[0]))
                continue
            var = f"e{k}"
            model = inp.get('one') or inp.get('all')
            if model not in models:
                ok = False
                break
            args.append(f"collect({var})" if inp.get('all') else var)
            matchers.append(f"MATCH ({var}:{model})")
        if not ok:
            continue
        out.append((" ".join(matchers) + f" RETURN {d['name']}({', '.join(args)}) AS value", d['output'], d['name']))
    return out, skipped


def aggregate_queries(models, cat):
    """A count over every declared type, and a sum over every declared quantity: the shapes
    the catalog itself names, so nothing here is a guess about the domain."""
    out = []
    for name, m in models.items():
        out.append((f"MATCH (a:{name}) RETURN count(a) AS count", name, "count"))
        for q in (m.get('semantics') or {}).get('quantities') or []:
            amount = q.get('amount') or []
            if len(amount) == 1 and any(p['name'] == amount[0] for p in m['properties']):
                out.append((f"MATCH (a:{name}) RETURN sum(a.{amount[0]}) AS total", name, f"sum {amount[0]}"))
    return out

def queries_for(seed_model, seed_where, edges, models, question):
    """(cypher, landing, property) for every declared path out of one anchor, each in the
    plain form and narrowed by the enum values the question speaks at the landing."""
    out, seen = [], set()
    for steps, landing in [( [], seed_model)] + walk(edges, seed_model, DEPTH):
        pattern = f"(a:{seed_model})" + "".join(steps)
        var = f"b{len(steps) - 1}" if steps else "a"
        narrowings = [[]] + [[f"{var}.{prop} = {json.dumps(v)}"] for prop, v in declared_filters(question, models[landing])]
        narrowings += [[f"{var}.{prop} <> {json.dumps(v)}"] for prop, v in declared_filters(question, models[landing])]
        for extra in narrowings:
            for prop in candidate_props(models[landing]):
                conds = " AND ".join([seed_where] + extra)
                cy = f"MATCH {pattern} WHERE {conds} RETURN {var}.{prop} AS value"
                if cy in seen: continue
                seen.add(cy); out.append((cy, landing, prop))
    return out

def values(ans):
    return sorted({json.dumps(f['value'], sort_keys=True) for f in ans.get('fields', []) if 'terms' not in f.get('path', [])})

def main():
    global PARAMS, DEPTH, asker, CATALOG
    args = sys.argv[1:]
    if "--depth" in args: DEPTH = int(args[args.index("--depth") + 1])
    asker = args[args.index("--asker") + 1] if "--asker" in args else None
    schema = app({"op": "schema"})
    CATALOG = schema
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
        PARAMS = {"asker": asker or ctx['principal'], "now": iso_ms(manifest['evaluation_time']),
                  "speaker": asker or ctx.get('speaker') or ctx['principal'],
                  "valid_at": iso_ms(q['valid_at']) if 'valid_at' in q else None}
        gold = plans.get(q['id'])
        goldview = {"as_of": {"valid_at": PARAMS["valid_at"]}} if PARAMS.get("valid_at") else {}
        want = values(app({"op": "query", "cypher": gold, "params": PARAMS, **goldview})) if gold else []
        seeds = [(m, lab, f"a.{lab} = $anchor", {"anchor": v}) for m, lab, v in anchors(q['question'], models)]
        # the party asking is whatever type the graph files that id under; nothing is assumed
        holder = app({"op": "get", "id": PARAMS["asker"]})
        if holder.get("model"):
            seeds.append((holder["model"], None, "id(a) = $asker", {}))
        elif q is questions[0]:
            print(f"  (the asker {PARAMS['asker']!r} is not in the graph; pass --asker with an id it holds)",
                  file=sys.stderr)
        ungenerated = []
        # every candidate carries the declared shape of the value it would answer with
        pool = [(cy, 'count', {}) for cy, _, _ in aggregate_queries(models, CATALOG)]
        for model, lab, where, extra in seeds:
            derivations, skipped = derivation_queries(model, where, models, CATALOG, edges)
            ungenerated += skipped
            pool += [(cy, "derived:" + name, extra) for cy, _, name in derivations]
            for cy, landing, prop in queries_for(model, where, edges, models, q['question']):
                decl = next(p for p in models[landing]['properties'] if p['name'] == prop)
                pool.append((cy, shape_of_property(decl), extra))
        # one closed choice over the shapes the declarations name, then run only those
        options = shape_options(models, CATALOG, q['question'])
        keys = [k for k, _ in options]
        want_shape = None
        if len(options) > 1:
            p_ = CHOOSE(q['question'], [text for _, text in options])
            best = max(range(len(p_)), key=lambda i: p_[i])
            want_shape = keys[best] if p_[best] > 0 else None
        # the declared shape is a TIER, not a filter: its candidates are tried first, and the
        # rest are tried only when it yields nothing, so a wrong shape costs ordering, not recall
        first = [c for c in pool if want_shape is not None and c[1] == want_shape]
        rest = [c for c in pool if want_shape is None or c[1] != want_shape]
        got, asked, empties = set(), 0, 0
        view = {"as_of": {"valid_at": PARAMS["valid_at"]}} if PARAMS.get("valid_at") else {}
        for tier in (first, rest):
            for cy, shape, extra in tier:
                asked += 1
                vs = values(app({"op": "query", "cypher": cy, "params": {**PARAMS, **extra}, **view}))
                if not vs: empties += 1
                got |= set(vs)
            if got:
                break
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

PARAMS, asker, CATALOG = {}, None, {}
if __name__ == '__main__':
    main()
