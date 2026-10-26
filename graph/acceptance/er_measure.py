"""Entity resolution against the fixture's gold entities, after admission and the resolver.

usage: python er_measure.py --extractor CMD --resolver CMD [--through sNN]

Ingests, admits and resolves every source in order (the grader's own steps), then joins each
admitted entity's merge group to a gold entity by the grader's id map. Reports, per model:
admitted entities, merge groups, gold entities reached, groups holding two gold entities (wrong
merges) and gold entities spread over several groups (missed merges). Grader code is imported,
never changed. Run with a model service on AVRA_GRAPH_SOCKET when the resolver has new choices.
"""
import argparse
import collections
import json
import pathlib
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "extract"))
import score  # noqa: E402
import resolve  # noqa: E402


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--extractor", required=True)
    parser.add_argument("--resolver")
    parser.add_argument("--through")
    parser.add_argument("--show", action="store_true", help="list each merge group with the labels its members carry")
    args = parser.parse_args()
    score.configure(HERE)
    manifest, sources, entities, _ = score.load_fixture()
    hooks = {"extractor": args.extractor, "resolver": args.resolver, "planner": None}
    prefix = score.prefix_of(sources, len(sources) if not args.through else [x["id"] for x in sources].index(args.through) + 1)
    trace = []
    with tempfile.TemporaryDirectory(prefix="graph-er-") as scratch:
        scratch = pathlib.Path(scratch)
        app = score.App(score.BINARY, scratch / "er.db", scratch)
        schema = app.call({"op": "schema"})
        by_ref = {(s["observation"], s["revision"]): s["id"] for s in prefix}
        for s in prefix:
            receipt = app.call({"op": "ingest", "source": score.envelope(s)})
            failure = score.publish_source(app, "e2e", hooks, s, schema, receipt.get("graph_revision", 0), trace)
            if failure:
                sys.exit(f"{s['id']}: {failure}")
        lookup = score.id_map(app, entities, prefix, by_ref)
        find = resolve.Graph(app.call).groups()
        seen = {r["entity"]: app.call({"op": "get", "id": r["entity"]}).get("model")
                for rec in trace for r in (rec.get("admit") or {}).get("records", [])}
        out = {}
        for model in ("Person", "Organization"):
            members = [e for e, m in seen.items() if m == model]
            groups = collections.defaultdict(set)
            gold = collections.defaultdict(set)
            for e in members:
                g = find(e)
                who = lookup(e)
                groups[g].add(e)
                if who:
                    gold[who].add(g)
            owner = collections.defaultdict(set)
            for who, gs in gold.items():
                for g in gs:
                    owner[g].add(who)
            if args.show:
                graph = resolve.Graph(app.call)
                for g, es in groups.items():
                    names = sorted({str(v) for e in es for vs in graph.fields(e).values() for v in vs if isinstance(v, str)})
                    print(model, len(es), "gold", sorted(owner.get(g, [])), names[:6])
            out[model] = {"entities": len(members), "groups": len(groups), "gold_reached": len(gold),
                          "unjoined_groups": sum(1 for g in groups if g not in owner),
                          "wrong_merges": sum(len(w) > 1 for w in owner.values()),
                          "gold_in_several_groups": sum(len(g) > 1 for g in gold.values()),
                          "extra_groups_over_gold": sum(len(g) - 1 for g in gold.values())}
        print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
