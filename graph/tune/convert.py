"""Gold decisions -> mlx-lm completions data, in the scorer's own bytes.

Each decision becomes the user message the shared service's `choose` op
sends (graph/extract/cascade.py's `choice_prompt`, the one definition the
scorer renders) and the gold letter as the completion; mlx-lm applies the
model's chat template to both, as the scorer does.
Every decision is written in two option orders: as asked, and with its
listed options reversed (fixed trailing alternatives such as "none of these"
stay last, as the cascade lists them). Whole domains are held out for
validation, so early stopping measures transfer to unseen schemas.

usage: python convert.py extract.jsonl plan.jsonl … --out data/
"""
import argparse
import collections
import hashlib
import json
import pathlib
import random
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "extract"))
import cascade  # noqa: E402

PARAMS = {k: v["value"] for k, v in json.loads((HERE / "params.json").read_text()).items()}


def orders(d):
    """(options, gold) as asked and with the listed options reversed."""
    n = len(d["options"]) - d.get("tail", 0)
    perm = list(range(n))[::-1] + list(range(n, len(d["options"])))
    yield d["options"], d["gold"]
    if perm != list(range(len(d["options"]))):
        yield [d["options"][i] for i in perm], perm.index(d["gold"])


def held_out(domain):
    """Whether a domain is held out: a stable hash of its name, never its content."""
    return int(hashlib.sha256(domain.encode()).hexdigest(), 16) % 100 < PARAMS["heldout_percent"]


def balanced(rows, rng):
    """Within a kind, a fixed trailing alternative (none, not stated, cannot tell)
    is gold at most as often as the listed options are, so declining is learned
    without becoming the default."""
    out, by = [], collections.defaultdict(lambda: ([], []))
    for d in rows:
        declined = d.get("tail", 0) and d["gold"] >= len(d["options"]) - d["tail"]
        by[d["kind"]][1 if declined else 0].append(d)
    for kind, (picked, declined) in by.items():
        rng.shuffle(declined)
        out += picked + declined[: max(len(picked), PARAMS["declined_floor"])]
    return out


def stratified(rows, n, rng):
    """A fixed sample balanced over (decision kind, domain): rounds take one
    example from each group in turn until n are taken."""
    groups = collections.defaultdict(list)
    for x in rows:
        groups[(x["kind"], x["domain"])].append(x)
    for g in groups.values():
        rng.shuffle(g)
    keys, out = sorted(groups), []
    while len(out) < n and any(groups.values()):
        for k in keys:
            if groups[k] and len(out) < n:
                out.append(groups[k].pop())
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("decisions", nargs="+")
    parser.add_argument("--out", default=str(HERE / "data"))
    args = parser.parse_args()
    rows = [json.loads(l) for f in args.decisions for l in open(f) if l.strip()]
    rng = random.Random(PARAMS["seed"])
    rows = balanced(rows, rng)
    split = {"train": [], "valid": []}
    counts = collections.Counter()
    for d in rows:
        part = "valid" if held_out(d["domain"]) else "train"
        for options, gold in orders(d):
            body = cascade.choice_prompt(d["context"], d["question"], options, d.get("source", ""))
            split[part].append({"prompt": body, "completion": cascade.string.ascii_uppercase[gold],
                                "kind": d["kind"], "domain": d["domain"], "source": d.get("source", ""),
                                "context": d["context"], "question": d["question"], "options": options, "gold": gold})
            counts[(part, d["kind"])] += 1
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for part, xs in split.items():
        rng.shuffle(xs)
        (out / f"{part}.jsonl").write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in xs))
    sample = stratified(split["valid"], PARAMS["val_sample"], rng)
    (out / "valid_sample.jsonl").write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in sample))
    manifest = {"valid_sample": len(sample), "decisions": args.decisions, "examples": {p: len(xs) for p, xs in split.items()},
                "domains": {p: sorted({x["domain"] for x in xs}) for p, xs in split.items()},
                "by_kind": {f"{p}/{k}": n for (p, k), n in sorted(counts.items())}}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1))
    print(json.dumps({"examples": manifest["examples"], "domains": {p: len(v) for p, v in manifest["domains"].items()}}))


if __name__ == "__main__":
    main()
