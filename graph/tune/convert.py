"""Gold decisions -> mlx-lm completions data, rendered by the real scorer.

Each decision becomes the prompt the shared service's `choose` op would build
for it (graph/extract/cascade.py's Scorer.choose, run with a stand-in model
that only records what it is asked) and the gold letter as the completion.
Every decision is written in two option orders: as asked, and with its
listed options reversed (fixed trailing alternatives such as "none of these"
stay last, as the cascade lists them). Whole domains are held out for
validation, so early stopping measures transfer to unseen schemas.

usage: python convert.py extract.jsonl plan.jsonl … --out data/   (venv python)
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
from pins import SCORER  # noqa: E402

PARAMS = {k: v["value"] for k, v in json.loads((HERE / "params.json").read_text()).items()}


class Renderer(cascade.Scorer):
    """The real choose(), with a model that answers nothing and a render that keeps its prompt."""

    def __init__(self):
        import mlx.core as mx
        from mlx_lm.utils import load_tokenizer, hf_repo_to_path

        self.tok = load_tokenizer(hf_repo_to_path(SCORER.split("@")[0]))
        vocab = len(self.tok.get_vocab())
        self.model = lambda ids, cache=None: mx.zeros((1, ids.shape[1], vocab))
        self.calls, self.source, self.cache, self.prefix, self.body = 0, "", None, False, None

    def render(self, body):
        self.body = body
        return super().render(body)

    def prompt(self, source, context, question, options):
        self.source = source
        self.choose(context, question, options)
        return self.body


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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("decisions", nargs="+")
    parser.add_argument("--out", default=str(HERE / "data"))
    args = parser.parse_args()
    rows = [json.loads(l) for f in args.decisions for l in open(f) if l.strip()]
    rng = random.Random(PARAMS["seed"])
    rows = balanced(rows, rng)
    r = Renderer()
    split = {"train": [], "valid": []}
    counts = collections.Counter()
    for d in rows:
        part = "valid" if held_out(d["domain"]) else "train"
        for options, gold in orders(d):
            body = r.prompt(d.get("source", ""), d["context"], d["question"], options)
            split[part].append({"prompt": body, "completion": cascade.string.ascii_uppercase[gold],
                                "kind": d["kind"], "domain": d["domain"]})
            counts[(part, d["kind"])] += 1
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for part, xs in split.items():
        rng.shuffle(xs)
        (out / f"{part}.jsonl").write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in xs))
    manifest = {"decisions": args.decisions, "examples": {p: len(xs) for p, xs in split.items()},
                "domains": {p: sorted({x["domain"] for x in xs}) for p, xs in split.items()},
                "by_kind": {f"{p}/{k}": n for (p, k), n in sorted(counts.items())}}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1))
    print(json.dumps({"examples": manifest["examples"], "domains": {p: len(v) for p, v in manifest["domains"].items()}}))


if __name__ == "__main__":
    main()
