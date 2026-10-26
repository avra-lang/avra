#!/usr/bin/env python3
"""Freezes the items of built domains into a split file, and checks that a
train split and an eval split share nothing.

    python3 split.py freeze --family eval --seeds 1,2,3 --name eval-v1
    python3 split.py disjoint splits/train-v1.jsonl splits/eval-v1.jsonl
"""
import argparse
import json
import pathlib
import re

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "out"
SPLITS = HERE / "splits"


def freeze(family, seeds, name):
    rows, worlds = [], []
    for seed in seeds:
        d = OUT / family / str(seed)
        spec = json.loads((d / "spec.json").read_text())
        items = json.loads((d / "items.json").read_text())
        world = f"{family}-{seed}"
        worlds.append({"world": world, "domain": spec["domain"], "questions": len(items), "models": [m["name"] for m in spec["models"].values()]})
        for n, it in enumerate(items, 1):
            rows.append({"id": f"{world}:{n:02d}", "world": world, "world_dir": f"{family}/{seed}", "domain": spec["domain"], "kind": it["kind"], "tags": it["tags"],
                         "intent": it["intent"], "question": it["question"], "cypher": it["cypher"], "params": it["params"], "as_of": it["as_of"],
                         "speaker": it["speaker"], "made": it["made"], "gold": it["gold"], "steps": it["steps"], "hops": it["hops"]})
    SPLITS.mkdir(exist_ok=True)
    (SPLITS / f"{name}.jsonl").write_text("\n".join(json.dumps(r) for r in rows) + "\n")
    meta = {"name": name, "family": family, "questions": len(rows), "worlds": worlds,
            "by_kind": {k: sum(r["kind"] == k for r in rows) for k in sorted({r["kind"] for r in rows})},
            "by_tag": {t: sum(t in r["tags"] for r in rows) for t in sorted({t for r in rows for t in r["tags"]})}}
    (SPLITS / f"{name}.meta.json").write_text(json.dumps(meta, indent=1))
    print(json.dumps({k: meta[k] for k in ("name", "questions", "by_kind")}, indent=1), f"{len(worlds)} worlds")


def disjoint(a, b):
    """Shared domains, model names and question texts between two splits (all must be empty)."""
    def read(p):
        return [json.loads(l) for l in pathlib.Path(p).read_text().splitlines() if l.strip()]

    def vocab(rows):
        words = {}
        for r in rows:
            for n in re.findall(r"[A-Z][a-z]+[A-Za-z]*", r["question"]):
                words.setdefault(n, set()).add(r["world"])
        return words

    ra, rb = read(a), read(b)
    shared = {"domains": sorted({r["domain"] for r in ra} & {r["domain"] for r in rb}),
              "questions": sorted({r["question"] for r in ra} & {r["question"] for r in rb}),
              "capitalised_words": sorted(set(vocab(ra)) & set(vocab(rb)))}
    print(json.dumps({k: (v if k != "capitalised_words" else v[:40]) for k, v in shared.items()}, indent=1))
    return shared


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)
    f = sub.add_parser("freeze")
    f.add_argument("--family", required=True)
    f.add_argument("--seeds", required=True)
    f.add_argument("--name", required=True)
    d = sub.add_parser("disjoint")
    d.add_argument("a")
    d.add_argument("b")
    args = p.parse_args()
    if args.cmd == "freeze":
        freeze(args.family, args.seeds.split(","), args.name)
    else:
        disjoint(args.a, args.b)


if __name__ == "__main__":
    main()
