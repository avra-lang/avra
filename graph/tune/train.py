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

usage: python train.py --run <name> [--iters N] [--rank R] [--lr X] [--layers L] [--accumulate K]
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


class Footprint:
    """The process's physical footprint as macOS accounts it (unified memory included)."""

    def __init__(self):
        import ctypes

        self.lib = ctypes.CDLL("/usr/lib/libproc.dylib")
        self.buf = (ctypes.c_uint64 * 32)()
        self.pid = os.getpid()

    def gb(self):
        self.lib.proc_pid_rusage(self.pid, 0, self.buf)
        return self.buf[2 + 7] / 2**30  # rusage_info_v0: 16-byte uuid, then ri_phys_footprint is the 8th counter


class MemoryCap(Exception):
    pass


class Metrics:
    """One JSON line per step and per evaluation, for the live dashboard; the run's
    own log keeps the same lines. Aborts the run past the footprint cap."""

    def __init__(self, paths, total, out):
        self.paths, self.total, self.val, self.fp, self.out = paths, total, [], Footprint(), out
        for p in paths:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("")

    def write(self, phase, step=None, loss=None, val_loss=None, lr=None, tps=None, note=""):
        import mlx.core as mx

        row = {"t": round(time.time(), 1), "step": step, "total_steps": self.total, "loss": loss, "val_loss": val_loss,
               "lr": lr, "tokens_per_s": tps, "mlx_active_gb": round(mx.get_active_memory() / 2**30, 3),
               "mlx_peak_gb": round(mx.get_peak_memory() / 2**30, 3), "footprint_gb": round(self.fp.gb(), 3),
               "phase": phase, "note": note}
        line = json.dumps(row) + "\n"
        for p in self.paths:
            with open(p, "a") as f:
                f.write(line)
        if row["footprint_gb"] > PARAMS["footprint_abort_gb"]:
            raise MemoryCap(f"footprint {row['footprint_gb']} GB over the {PARAMS['footprint_abort_gb']} GB cap")

    def failed(self, note):
        """The error line, written without measuring, so a broken runtime still reports."""
        line = json.dumps({"t": round(time.time(), 1), "step": None, "total_steps": self.total, "loss": None, "val_loss": None,
                           "lr": None, "tokens_per_s": None, "mlx_active_gb": None, "mlx_peak_gb": None,
                           "footprint_gb": None, "phase": "error", "note": note}) + "\n"
        for p in self.paths:
            with open(p, "a") as f:
                f.write(line)

    def on_train_loss_report(self, info):
        self.write("train", int(info["iteration"]), float(info["train_loss"]), lr=float(info["learning_rate"]),
                   tps=round(float(info["tokens_per_second"]), 1))

    def on_val_loss_report(self, info):
        # mlx-lm reports the evaluation before step k as k-1; the adapter saved at step k is the one evaluated.
        step = int(info["iteration"]) + 1
        self.val.append((step, float(info["val_loss"])))
        best = min(self.val, key=lambda x: x[1])[0]
        for k, _ in self.val[:-1]:
            older = self.out / f"{k:07d}_adapters.safetensors"
            if k != best and older.exists():
                older.unlink()  # only the best evaluated adapter is kept, so disk use stays two adapters
        self.write("eval", step, val_loss=float(info["val_loss"]), note=f"val_time_s={info['val_time']:.0f}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", required=True)
    parser.add_argument("--data", default=str(HERE / "data"))
    parser.add_argument("--iters", type=int, default=PARAMS["iters"])
    parser.add_argument("--rank", type=int, default=PARAMS["lora_rank"])
    parser.add_argument("--lr", type=float, default=PARAMS["learning_rate"])
    parser.add_argument("--layers", type=int, default=PARAMS["lora_layers"])
    parser.add_argument("--accumulate", type=int, default=PARAMS["grad_accumulation"])
    a = parser.parse_args()
    out = HERE / "adapters" / a.run
    out.mkdir(parents=True, exist_ok=True)
    metrics = Metrics([pathlib.Path(os.path.expanduser(PARAMS["metrics_file"])), out / "metrics.jsonl"], a.iters, out)
    free = shutil.disk_usage(HERE).free / 2**30
    if free < PARAMS["min_free_disk_gb"]:
        metrics.failed(f"{free:.1f} GB free disk, under the {PARAMS['min_free_disk_gb']} GB floor")
        raise SystemExit(f"train: {free:.1f} GB free, under the {PARAMS['min_free_disk_gb']} GB floor")

    import mlx.core as mx
    import mlx_lm.tuner.trainer as trainer
    from mlx_lm import load
    from mlx_lm.lora import CONFIG_DEFAULTS, train_model

    mx.set_memory_limit(int(PARAMS["mlx_memory_limit_gb"] * 2**30))
    mx.set_cache_limit(int(PARAMS["mlx_cache_limit_gb"] * 2**30))
    trainer.maybe_set_recommended_wired_limit = lambda: None  # wiring memory would take it from the other work
    every = PARAMS["steps_per_eval"]
    try:
        model, tok = load(SCORER.split("@")[0])
        train, valid = Letters(pathlib.Path(a.data) / "train.jsonl", tok), Letters(pathlib.Path(a.data) / "valid.jsonl", tok)
        longest = max(len(d.process(d[i])[0]) for d in (train, valid) for i in range(len(d)))
        args = types.SimpleNamespace(**{**CONFIG_DEFAULTS, "model": SCORER, "train": True, "seed": PARAMS["seed"],
                                        "num_layers": a.layers, "batch_size": 1, "grad_accumulation_steps": a.accumulate,
                                        "iters": a.iters, "val_batches": PARAMS["val_examples"], "learning_rate": a.lr,
                                        "steps_per_report": 1, "steps_per_eval": every, "save_every": every,
                                        "adapter_path": str(out), "max_seq_length": longest, "grad_checkpoint": True,
                                        "clear_cache_threshold": 0,
                                        "lora_parameters": {"rank": a.rank, "dropout": 0.0, "scale": PARAMS["lora_scale"]}})
        metrics.write("train", 0, note=json.dumps({"run": a.run, "train": len(train), "valid": len(valid), "longest_tokens": longest,
                                                   "rank": a.rank, "layers": a.layers, "accumulate": a.accumulate, "lr": a.lr,
                                                   "free_disk_gb": round(free, 1)}))
        train_model(args, model, train, valid, metrics)
    except Exception as e:
        metrics.failed(f"{type(e).__name__}: {e}"[:500])
        raise SystemExit(f"train: {type(e).__name__}: {e}")
    saved = [(it, loss) for it, loss in metrics.val if (out / f"{it:07d}_adapters.safetensors").exists()]
    it, loss = min(saved, key=lambda x: x[1])
    best = {"step": it, "val_loss": loss, "adapter": f"{it:07d}_adapters.safetensors", "val": metrics.val,
            "base_val_loss": metrics.val[0][1] if metrics.val and metrics.val[0][0] == 1 else None}
    (out / "best.json").write_text(json.dumps(best, indent=1))
    (out / "best").mkdir(exist_ok=True)
    shutil.copy(out / best["adapter"], out / "best" / "adapters.safetensors")
    shutil.copy(out / "adapter_config.json", out / "best" / "adapter_config.json")
    metrics.write("done", a.iters, val_loss=loss, note=f"best step {it}")


if __name__ == "__main__":
    main()
