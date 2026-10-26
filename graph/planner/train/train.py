#!/usr/bin/env python3
"""LoRA on the planner's scorer from sampled planner rows.

    python3 graph/planner/train/train.py --run <name> --data data/ [--check]

The loss is on the answer letter alone, at the position the scorer reads it:
the prompt is the scorer's chat render of the user message with the generation
prompt, the target is the letter's first token. Rows are the exact messages
the service builds, so training text is runtime text byte for byte. The
held-out loss is logged at each evaluation; the adapter with the lowest one is
kept (`best/`). `--check` tokenizes the data with the tokenizer alone and
loads no model.
"""
import argparse
import json
import os
import pathlib
import shutil
import sys
import time
import types

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent / "extract"))
os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")
from pins import SCORER  # noqa: E402

PARAMS = {k: v["value"] for k, v in json.loads((HERE / "params.json").read_text()).items()}
RUNS = pathlib.Path.home() / ".cache/avra-graph-ml/runs"


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


def letter_loss(model, batch, lengths):
    """Cross-entropy on the tokens from each example's offset to its last token only."""
    import mlx.core as mx
    import mlx.nn as nn

    logits = model(batch[:, :-1])
    steps = mx.arange(1, batch.shape[1])
    mask = mx.logical_and(steps >= lengths[:, 0:1], steps < lengths[:, 1:])
    ce = nn.losses.cross_entropy(logits, batch[:, 1:]) * mask
    ntoks = mask.sum()
    return ce.astype(mx.float32).sum() / ntoks, ntoks


class Stop(Exception):
    """A planned end: held-out loss stopped improving, or the time cap passed."""


class Log:
    """One JSON line per report and evaluation; keeps only the best evaluated adapter on disk."""

    def __init__(self, path, out):
        self.path, self.out, self.val, self.started = path, out, [], time.time()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("")

    def write(self, phase, **row):
        with open(self.path, "a") as f:
            f.write(json.dumps({"t": round(time.time(), 1), "phase": phase, **row}) + "\n")

    def on_train_loss_report(self, info):
        self.write("train", step=int(info["iteration"]), loss=float(info["train_loss"]))
        if time.time() - self.started > PARAMS["max_hours"] * 3600:
            raise Stop(f"time cap of {PARAMS['max_hours']} h")

    def on_val_loss_report(self, info):
        step = int(info["iteration"]) + 1
        self.val.append((step, float(info["val_loss"])))
        best = min(self.val, key=lambda x: x[1])[0]
        for k, _ in self.val[:-1]:
            older = self.out / f"{k:07d}_adapters.safetensors"
            if k != best and older.exists():
                older.unlink()
        self.write("eval", step=step, val_loss=float(info["val_loss"]))
        if len(self.val) - 1 - [k for k, _ in self.val].index(best) >= PARAMS["patience_evals"]:
            raise Stop(f"held-out loss has not improved for {PARAMS['patience_evals']} evaluations")


def tokenizer():
    from mlx_lm.utils import _download, load_tokenizer

    return load_tokenizer(_download(SCORER.split("@")[0]))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", required=True)
    parser.add_argument("--data", required=True)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--iters", type=int, default=PARAMS["iters"])
    parser.add_argument("--rank", type=int, default=PARAMS["lora_rank"])
    parser.add_argument("--lr", type=float, default=PARAMS["learning_rate"])
    parser.add_argument("--layers", type=int, default=PARAMS["lora_layers"])
    parser.add_argument("--accumulate", type=int, default=PARAMS["grad_accumulation"])
    a = parser.parse_args()
    data = pathlib.Path(a.data)
    if a.check:
        tok = tokenizer()
        for name in ("train", "valid"):
            d = Letters(data / f"{name}.jsonl", tok)
            sizes = [len(d.process(d[i])[0]) for i in range(len(d))]
            print(f"{name}: {len(d)} rows, longest {max(sizes, default=0)} tokens, "
                  f"every completion one token: {all(len(tok.encode(r['completion'], add_special_tokens=False)) == 1 for r in d.rows)}")
        return
    out = RUNS / f"beam-adapter-{a.run}"
    out.mkdir(parents=True, exist_ok=True)
    log = Log(out / "metrics.jsonl", out)
    free = shutil.disk_usage(out).free / 2**30
    if free < PARAMS["min_free_disk_gb"]:
        raise SystemExit(f"train: {free:.1f} GB free, under the {PARAMS['min_free_disk_gb']} GB floor")

    import functools

    import mlx.core as mx
    import mlx_lm.lora as lora
    import mlx_lm.tuner.trainer as trainer
    from mlx_lm import load
    from mlx_lm.lora import CONFIG_DEFAULTS, train_model

    mx.set_memory_limit(int(PARAMS["mlx_memory_limit_gb"] * 2**30))
    mx.set_cache_limit(int(PARAMS["mlx_cache_limit_gb"] * 2**30))
    trainer.maybe_set_recommended_wired_limit = lambda: None
    lora.train = functools.partial(trainer.train, loss=letter_loss)
    try:
        model, tok = load(SCORER.split("@")[0])
        train, valid = Letters(data / "train.jsonl", tok), Letters(data / "valid.jsonl", tok)
        longest = max(len(d.process(d[i])[0]) for d in (train, valid) for i in range(len(d)))
        args = types.SimpleNamespace(**{**CONFIG_DEFAULTS, "model": SCORER, "train": True, "seed": 0,
                                        "num_layers": a.layers, "batch_size": 1, "grad_accumulation_steps": a.accumulate,
                                        "iters": a.iters, "val_batches": -1, "learning_rate": a.lr,
                                        "steps_per_report": 1, "steps_per_eval": PARAMS["steps_per_eval"],
                                        "save_every": PARAMS["steps_per_eval"], "adapter_path": str(out),
                                        "max_seq_length": longest, "grad_checkpoint": True, "clear_cache_threshold": 0,
                                        "lora_parameters": {"rank": a.rank, "dropout": 0.0, "scale": PARAMS["lora_scale"]}})
        log.write("start", run=a.run, train=len(train), valid=len(valid), longest_tokens=longest, rank=a.rank,
                  layers=a.layers, accumulate=a.accumulate, lr=a.lr)
        train_model(args, model, train, valid, log)
    except Stop as e:
        log.write("stopped", note=str(e))
    saved = [(it, loss) for it, loss in log.val if (out / f"{it:07d}_adapters.safetensors").exists()]
    if not saved:
        log.write("done", note="no evaluated adapter was saved")
        return
    it, loss = min(saved, key=lambda x: x[1])
    (out / "best").mkdir(exist_ok=True)
    shutil.copy(out / f"{it:07d}_adapters.safetensors", out / "best" / "adapters.safetensors")
    shutil.copy(out / "adapter_config.json", out / "best" / "adapter_config.json")
    (out / "best.json").write_text(json.dumps({"step": it, "val_loss": loss, "val": log.val}, indent=1))
    log.write("done", step=it, val_loss=loss)


if __name__ == "__main__":
    main()
