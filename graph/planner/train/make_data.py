"""Turn the generated pairs into mlx_lm's training data, with the runtime's own bytes.

    python3 graph/planner/train/make_data.py [--pairs PATH] [--out DIR] [--hold 3]

A prompt is chat-templated exactly as the model service renders it for the query-writing
arm (one user message, generation prompt), so training text is runtime text byte for byte —
the failure the first two adapters here paid for. The split is by WORLD, so validation is on
schemas the training never saw.
"""
import argparse, json, os, pathlib, sys

HERE = pathlib.Path(__file__).resolve().parent
os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE.parent.parent / "extract"))
from pins import SCORER  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pairs", default=str(HERE.parent / "bench" / "cypher.pairs.jsonl"))
    parser.add_argument("--out", default=str(HERE / "data"))
    parser.add_argument("--hold", type=int, default=3, help="worlds kept for validation")
    args = parser.parse_args()

    from mlx_lm.utils import _download, load_tokenizer

    tok = load_tokenizer(_download(SCORER.split("@")[0]))
    rows = [json.loads(l) for l in open(args.pairs) if l.strip()]
    worlds = sorted({r["world"] for r in rows})
    held = set(worlds[:: max(1, len(worlds) // args.hold)][: args.hold]) if args.hold else set()

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    parts = {"train": [], "valid": []}
    for r in rows:
        prompt = tok.apply_chat_template([{"role": "user", "content": r["prompt"]}],
                                         add_generation_prompt=True, tokenize=False)
        parts["valid" if r["world"] in held else "train"].append({"prompt": prompt, "completion": r["completion"]})
    for name, made in parts.items():
        (out / f"{name}.jsonl").write_text("\n".join(json.dumps(p) for p in made) + "\n")
    print(json.dumps({"train": len(parts["train"]), "valid": len(parts["valid"]),
                      "held_worlds": sorted(held), "out": str(out)}, indent=1))


if __name__ == "__main__":
    main()
