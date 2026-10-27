#!/usr/bin/env python3
"""Runs a planner over a frozen gym split and reports it with intervals.

    python3 evalrun.py snapshot                         # pin the committed planner for a run
    python3 evalrun.py run --split splits/eval-v1.jsonl --name base [--set beam_k=3] [--limit 20]
    python3 evalrun.py compare results/a.json results/b.json
    python3 evalrun.py report results/a.json [--at 0.5,0.8]

Oracle mode: each world's database holds the oracle's facts and the planner's
query is executed against it. A question is right when the planner's query
reads the gold values; an unanswerable question is right when the planner
abstains or its query itself answers unknown or ambiguous. Intervals resample
whole worlds; A/B uses the exact mid-p McNemar test on the same items.
"""
import argparse
import json
import pathlib
import subprocess
import sys
import tarfile
import io
import time

import stats

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUT = HERE / "out"
RESULTS = HERE / "results"
CACHE = pathlib.Path.home() / ".cache/avra-graph-ml"


def snapshot(rev="HEAD"):
    """The committed planner at `rev`, unpacked once under out/planner@<sha>; returns (dir, sha)."""
    sha = subprocess.run(["git", "rev-parse", "--short", rev], cwd=ROOT, text=True, capture_output=True, check=True).stdout.strip()
    target = OUT / f"planner@{sha}"
    if not (target / "graph/extract/timex.py").exists():
        data = subprocess.run(["git", "archive", rev, "graph/planner", "graph/retrieval", ":(glob)graph/extract/*.py"], cwd=ROOT, capture_output=True, check=True).stdout
        with tarfile.open(fileobj=io.BytesIO(data)) as tar:
            tar.extractall(target)
    return target / "graph/planner", sha


def load_split(path):
    return [json.loads(l) for l in pathlib.Path(path).read_text().splitlines() if l.strip()]


def modules(planner_dir):
    sys.path.insert(0, str(planner_dir))
    import beam, catalog, plan, prompt, structured  # noqa: E401
    return plan, beam, structured, catalog, prompt


def correct_of(item, planned, got):
    if item["intent"] == "answer":
        return bool(planned) and got["status"] == "answered" and got["values"] == item["gold"]["values"]
    return not planned or got["status"] != "answered"


def run(args):
    import plans as gymplans
    from engine import App

    planner_dir, sha = snapshot(args.rev)
    plan, beam, structured, catalog, prompt = modules(planner_dir)
    for kv in args.set or []:
        name, _, value = kv.partition("=")
        catalog.PARAMETERS[name] = json.loads(value)
    sock = pathlib.Path(args.sock) if args.sock else None
    if sock is None:
        from llm import socket_path
        sock = socket_path()
    shared = plan.Shared(sock)
    llm = shared if catalog.PARAMETERS["rank_use"] else plan.ChooseOnly(shared)
    llm.budget = prompt.Budget(prompt.declared_context(plan.MODEL, plan.HUB), catalog.PARAMETERS["answer_tokens"])
    items = load_split(args.split)
    if args.limit:
        items = items[: args.limit]
    RESULTS.mkdir(exist_ok=True)
    partial = RESULTS / f"{args.name}.rows.jsonl"
    done = {}
    if partial.exists():
        for l in partial.read_text().splitlines():
            r = json.loads(l)
            if not r["error"]:
                done[r["id"]] = r
        partial.write_text("".join(json.dumps(r) + "\n" for r in done.values()))
    rows, apps = [], {}
    for n, item in enumerate(items, 1):
        if item["id"] in done:
            rows.append(done[item["id"]])
            continue
        d = OUT / item["world_dir"]
        if item["world"] not in apps:
            app = App(d / "app/src/main", d / "graph.db", d / "scratch")
            apps[item["world"]] = (app, app.call({"op": "schema"}), plan.Graph(app.argv))
        app, schema, graph = apps[item["world"]]
        context = {"principal": item["params"]["asker"], "speaker": item["speaker"], "conversation": None, "question_at_ms": item["params"]["now"],
                   "valid_at_ms": None, "known_revision": schema.get("revision", 0), "previous_answer": None}
        params = plan.params_of(context)
        started, error, chosen = time.time(), None, None
        for attempt in range(3):
          error = None
          try:
            seek, read, probe = plan.remembered(graph.search), plan.remembered(graph.read), graph.prober(params)
            found = beam.candidates(llm, lambda w: structured.plan(w, item["question"], schema, context, seek, None, read, probe), probe)
            for path in found:
                try:
                    plan.gated(path.cypher, schema, params, graph)
                except catalog.Refusal:
                    continue
                chosen = {"cypher": path.cypher, "score": path.score(), "as_of": plan.viewed(llm, item["question"], context)}
                break
            break
          except (SystemExit, OSError, ValueError) as why:
            error = str(why)[:300]
            time.sleep(60)
        got = gymplans.read_answer(app.query(chosen["cypher"], params, chosen["as_of"])) if chosen else {"status": None, "values": [], "support": []}
        right = correct_of(item, chosen, got)
        rows.append({"id": item["id"], "world": item["world"], "kind": item["kind"], "intent": item["intent"], "tags": item["tags"],
                     "planned": bool(chosen), "cypher": chosen and chosen["cypher"], "as_of": chosen and chosen["as_of"], "status": got["status"],
                     "score": chosen and chosen["score"], "correct": bool(right), "plan_exact": bool(chosen and chosen["cypher"] == item["cypher"]),
                     "ms": int((time.time() - started) * 1000), "error": error})
        with partial.open("a") as out:
            out.write(json.dumps(rows[-1]) + "\n")
        print(f"{n}/{len(items)} {item['id']} {item['kind']:<12} {'+' if right else '-'} {rows[-1]['ms']} ms {error or ''}", flush=True)
    result = {"name": args.name, "split": str(args.split), "planner_commit": sha, "overrides": args.set or [], "socket": str(sock),
              "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "rows": rows}
    RESULTS.mkdir(exist_ok=True)
    path = RESULTS / f"{args.name}.json"
    path.write_text(json.dumps(result, indent=1))
    print("wrote", path)
    print(json.dumps(summary(rows, args.at), indent=1))


def summary(rows, at=None):
    clusters = [r["world"] for r in rows]
    hits = [r["correct"] for r in rows]
    acc, lo, hi = stats.accuracy_ci(clusters, hits)
    out = {"questions": len(rows), "worlds": len(set(clusters)), "accuracy": round(acc, 4), "ci95": [round(lo, 4), round(hi, 4)],
           "errors": sum(bool(r["error"]) for r in rows)}
    for key in ("kind", "intent"):
        part = {}
        for v in sorted({r[key] for r in rows}):
            sel = [r for r in rows if r[key] == v]
            a, l, h = stats.accuracy_ci([r["world"] for r in sel], [r["correct"] for r in sel], draws=4000)
            part[v] = {"n": len(sel), "accuracy": round(a, 4), "ci95": [round(l, 4), round(h, 4)]}
        out["by_" + key] = part
    answered = [r for r in rows if r["planned"] and r["status"] == "answered"]
    risk_rows = [((r["score"] if r in answered else None), r["intent"] == "answer" and r["correct"]) for r in rows]
    curve, area = stats.risk_coverage(risk_rows)
    out["abstention"] = {"coverage": round(len(answered) / len(rows), 4), "wrong_when_answered": round(1 - sum(r["intent"] == "answer" and r["correct"] for r in answered) / len(answered), 4) if answered else None,
                         "unanswerable_answered_confidently": sum(r["intent"] != "answer" and r in answered for r in rows),
                         "aurc": round(area, 4) if area == area else None}
    for c in [float(x) for x in (at or "").split(",") if x]:
        out["abstention"][f"risk_at_{c}"] = round(stats.risk_at(curve, c), 4)
    out["plan_exact_rate"] = round(sum(r["plan_exact"] for r in rows) / len(rows), 4)
    return out


def compare(args):
    a, b = (json.loads(pathlib.Path(p).read_text()) for p in (args.a, args.b))
    ra, rb = {r["id"]: r for r in a["rows"]}, {r["id"]: r for r in b["rows"]}
    ids = [i for i in ra if i in rb]
    got = stats.paired([ra[i]["world"] for i in ids], [ra[i]["correct"] for i in ids], [rb[i]["correct"] for i in ids])
    print(json.dumps({"a": a["name"], "b": b["name"], "paired_items": len(ids), **got}, indent=1))


def report(args):
    rows = json.loads(pathlib.Path(args.path).read_text())["rows"]
    print(json.dumps(summary(rows, args.at), indent=1))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("snapshot")
    r = sub.add_parser("run")
    r.add_argument("--split", required=True)
    r.add_argument("--name", required=True)
    r.add_argument("--rev", default="HEAD")
    r.add_argument("--set", action="append")
    r.add_argument("--limit", type=int)
    r.add_argument("--sock")
    r.add_argument("--at")
    c = sub.add_parser("compare")
    c.add_argument("a")
    c.add_argument("b")
    s = sub.add_parser("report")
    s.add_argument("path")
    s.add_argument("--at")
    args = p.parse_args()
    if args.cmd == "snapshot":
        print(snapshot())
    else:
        {"run": run, "compare": compare, "report": report}[args.cmd](args)


if __name__ == "__main__":
    main()
