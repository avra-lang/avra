#!/usr/bin/env python3
"""Splits sampled rows into train and held-out sets for early stopping.

    python3 graph/planner/train/prepare.py rows.jsonl --out data/

Whole worlds are held out when there are several; with one world, whole
questions are (a row's question is the line of its prompt that names it), so a
question's rows never straddle the split. The held-out share is declared.
"""
import argparse
import hashlib
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
TRAINING = {k: v["value"] for k, v in json.loads((HERE / "params.json").read_text()).items()}


def unit_of(row, several):
    if several:
        return row["world"]
    return next((l for l in row["prompt"].splitlines() if l.startswith("Question:")), row["prompt"][:80])


def held_out(unit):
    """A unit's place in 0..99, stable across runs."""
    return int(hashlib.sha256(unit.encode()).hexdigest(), 16) % 100 < TRAINING["heldout_percent"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rows")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    rows = [json.loads(l) for l in pathlib.Path(args.rows).read_text().splitlines() if l.strip()]
    several = len({r["world"] for r in rows}) > 1
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    train = [r for r in rows if not held_out(unit_of(r, several))]
    valid = [r for r in rows if held_out(unit_of(r, several))]
    for name, part in (("train", train), ("valid", valid)):
        (out / f"{name}.jsonl").write_text("\n".join(json.dumps({"prompt": r["prompt"], "completion": r["completion"]}) for r in part) + "\n")
    print(f"{len(train)} train, {len(valid)} held out ({'worlds' if several else 'questions'})")


if __name__ == "__main__":
    main()
