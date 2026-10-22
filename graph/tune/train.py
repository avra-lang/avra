"""LoRA on the pinned scorer, through mlx-lm's own trainer.

The loss is on the answer letter alone, at exactly the position the scorer
reads it: the prompt is the scorer's render of the user message (chat template
with the generation prompt), and the target is the letter's first token.
mlx-lm's completions format cannot say this — its template writes an empty
think block before an assistant answer — so the dataset is built here.

Validation is the held-out domains; every evaluation's loss is logged, an
adapter is saved at each evaluation, and `best.json` names the checkpoint
with the lowest held-out loss (early stopping, decided after the run).
Refuses to start without the free disk `params.json` asks for; logs the
process's peak memory with each report.

usage: python train.py --run <name> [--iters N] [--rank R] [--lr X] [--layers L] [--batch B]
"""
import argparse
import json
import os
import pathlib
import resource
import shutil
import sys
import time
import types

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "extract"))
os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")
from pins import SCORER  # noqa: E402

PARAMS = {k: v["value"] for k, v in json.loads((HERE / "params.json").read_text()).items()}


class Letters:
    """(tokens, offset) per example: the scorer's prompt ids, then the gold letter's token."""

    def __init__(self, path, tok):
        self.rows = [json.loads(l) for l in open(path) if l.strip()]
        self.tok = tok

    def __getitem__(self, i):
        return self.rows[i]

    def __len__(self):
        return len(self.rows)

    def process(self, d):
        prompt = self.tok.apply_chat_template([{"role": "user", "content": d["prompt"]}], add_generation_prompt=True)
        return prompt + [self.tok.encode(d["completion"], add_special_tokens=False)[0]], len(prompt)


def footprint():
    import mlx.core as mx

    return {"rss_gb": round(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 2**30, 2),
            "mlx_peak_gb": round(mx.get_peak_memory() / 2**30, 2)}


class Log:
    """Training and held-out losses, with footprint, one JSON line each."""

    def __init__(self, path):
        self.path, self.val = path, []

    def write(self, row):
        row = {**row, **footprint(), "t": round(time.time())}
        with open(self.path, "a") as f:
            f.write(json.dumps(row) + "\n")
        print(json.dumps(row), flush=True)

    def on_train_loss_report(self, info):
        self.write({"train": {k: float(v) for k, v in info.items()}})

    def on_val_loss_report(self, info):
        self.val.append((info["iteration"], float(info["val_loss"])))
        self.write({"val": {k: float(v) for k, v in info.items()}})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", required=True)
    parser.add_argument("--data", default=str(HERE / "data"))
    parser.add_argument("--iters", type=int, default=PARAMS["iters"])
    parser.add_argument("--rank", type=int, default=PARAMS["lora_rank"])
    parser.add_argument("--lr", type=float, default=PARAMS["learning_rate"])
    parser.add_argument("--layers", type=int, default=PARAMS["lora_layers"])
    parser.add_argument("--batch", type=int, default=PARAMS["batch_size"])
    a = parser.parse_args()
    free = shutil.disk_usage(HERE).free / 2**30
    if free < PARAMS["min_free_disk_gb"]:
        raise SystemExit(f"train: {free:.1f} GB free, under the {PARAMS['min_free_disk_gb']} GB floor")

    from mlx_lm import load
    from mlx_lm.lora import CONFIG_DEFAULTS, train_model

    out = HERE / "adapters" / a.run
    out.mkdir(parents=True, exist_ok=True)
    model, tok = load(SCORER.split("@")[0])
    train, valid = Letters(pathlib.Path(a.data) / "train.jsonl", tok), Letters(pathlib.Path(a.data) / "valid.jsonl", tok)
    every = PARAMS["steps_per_eval"]
    args = types.SimpleNamespace(**{**CONFIG_DEFAULTS, "model": SCORER, "train": True, "seed": PARAMS["seed"],
                                    "num_layers": a.layers, "batch_size": a.batch, "iters": a.iters,
                                    "val_batches": -1, "learning_rate": a.lr, "steps_per_report": PARAMS["steps_per_report"],
                                    "steps_per_eval": every, "save_every": every, "adapter_path": str(out),
                                    "max_seq_length": PARAMS["max_seq_length"], "grad_checkpoint": True,
                                    "lora_parameters": {"rank": a.rank, "dropout": 0.0, "scale": PARAMS["lora_scale"]}})
    log = Log(out / "log.jsonl")
    log.write({"start": {"run": a.run, "train": len(train), "valid": len(valid), "free_disk_gb": round(free, 1),
                         **{k: getattr(args, k) for k in ("num_layers", "batch_size", "iters", "learning_rate", "lora_parameters")}}})
    train_model(args, model, train, valid, log)
    saved = [(it, loss) for it, loss in log.val if (out / f"{it:07d}_adapters.safetensors").exists()]
    it, loss = min(saved, key=lambda x: x[1])
    best = {"iteration": it, "val_loss": loss, "adapter": f"{it:07d}_adapters.safetensors", "val": log.val,
            "base_val_loss": log.val[0][1] if log.val and log.val[0][0] == 1 else None}
    (out / "best.json").write_text(json.dumps(best, indent=1))
    (out / "best").mkdir(exist_ok=True)
    shutil.copy(out / best["adapter"], out / "best" / "adapters.safetensors")
    shutil.copy(out / "adapter_config.json", out / "best" / "adapter_config.json")
    log.write({"best": {"iteration": it, "val_loss": loss}})


if __name__ == "__main__":
    main()
