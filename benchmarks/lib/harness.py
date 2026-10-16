#!/usr/bin/env python3
"""THE RUNNER. One `run.sh` interface over the registry: run benchmarks,
record them, project a report, gate a baseline.

    run.sh [--lang LANG,...] [--bench FAMILY/NAME,...]
           [--record] [--report] [--gate] [--require]
           [--list] [--self-test] [--quiet]

A run prints one JSON row per (benchmark, language) — the fixed schema in
`benchmarks/README.md`. `--record` also appends it to
`benchmarks/results/runs.jsonl` (one row per benchmark/language/machine,
latest wins) and accepts its numbers into `benchmarks/baseline.json`.
`--gate` compares a fresh run to that baseline, past a margin.
"""
import argparse
import json
import os
import sys
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import gate as gatemod
import report as reportmod
from bench import (BENCH, Fail, Skip, bench_dirs, machine_id, registry,
                   row_of, run_language, skipped_row, spec_of)

RESULTS = os.path.join(BENCH, "results", "runs.jsonl")


def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def csv(text):
    return [part.strip() for part in text.split(",") if part.strip()] if text else None


def load_store(path=RESULTS):
    """(benchmark, language, machine) -> the latest stored JSON row."""
    out = {}
    if os.path.isfile(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    row = json.loads(line)
                    out[(row["benchmark"], row["language"], row["machine"])] = row
    return out


def save_store(store, path=RESULTS):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        for where in sorted(store):
            f.write(json.dumps(store[where], sort_keys=True, separators=(",", ":")) + "\n")


def spec_gates(reg, benches):
    """(benchmark, row) -> the gate its spec asks for: a margin for a
    cost, `exact` for a witness count that must not move."""
    default = float(reg["gate"].get("margin", gatemod.DEFAULT_MARGIN))
    out = {}
    for key, bdir in benches:
        spec = spec_of(bdir)
        gate = spec.get("gate", {})
        for rname, rspec in spec.get("rows", {}).items():
            if rspec.get("check") == "exact":
                out[(key, rname)] = {"check": "exact"}
            else:
                out[(key, rname)] = {
                    "check": "ratio",
                    "margin": float(gate.get("rows", {}).get(rname, gate.get("margin", default))),
                }
    return out


def run_suite(reg, benches, requested, when):
    """Run every selected (benchmark, language). Answers (rows, failures):
    a Skip is a row that says SKIPPED and why; a Fail is a loud defect."""
    machine = machine_id()
    rows, failures = [], []
    for key, bdir in benches:
        spec = spec_of(bdir)
        listed = spec.get("languages") or list(reg["languages"])
        want = requested or listed
        for lang in want:
            if lang not in reg["languages"]:
                failures.append(f"{key}: no language `{lang}` in bench.toml")
                continue
            if lang not in listed:
                rows.append(skipped_row(key, lang, machine, when, "not listed in this benchmark's spec"))
                continue
            try:
                version, cells, notes = run_language(key, bdir, lang, reg["languages"][lang], spec.get("workload"))
                rows.append(row_of(key, lang, version, machine, when, cells, notes))
            except Skip as e:
                rows.append(skipped_row(key, lang, machine, when, str(e)))
            except Fail as e:
                failures.append(f"{key} {lang}: {e}")
    return rows, failures


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--lang", default=None)
    ap.add_argument("--bench", default=None)
    ap.add_argument("--record", action="store_true")
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--gate", action="store_true")
    ap.add_argument("--g1", action="store_true")
    ap.add_argument("--require", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        import selftest
        return 0 if selftest.main() else 1
    if args.report:
        reportmod.write()
        if not args.quiet:
            print("report: wrote benchmarks/report/results.md and index.html")
        return 0

    reg = registry()
    benches = bench_dirs(set(csv(args.bench)) if args.bench else None)
    if args.list:
        print("benchmarks:")
        for key, bdir in benches:
            spec = spec_of(bdir)
            listed = spec.get("languages") or list(reg["languages"])
            print(f"  {key:24s} {spec['benchmark'].get('title', '')}")
            print(f"    languages: {', '.join(listed)}")
        print("languages:")
        for name, cfg in reg["languages"].items():
            print(f"  {name:10s} {cfg.get('title', name)}")
        return 0

    requested = csv(args.lang)
    if not requested and (args.gate or args.g1):
        # The C floor stays. Avra and Go run too, so a row's own target
        # against Go is judged from the SAME run — a fresh Avra against
        # a stale Go baseline would charge Avra for the machine's drift.
        # A language the machine lacks is SKIPPED and the recorded Go row
        # is the fallback; `--lang` narrows this for a lighter gate.
        requested = [reg["gate"].get("floor", "c"), "avra", "go"]
    if requested:
        requested = list(dict.fromkeys(requested))
    when = now()
    rows, failures = run_suite(reg, benches, requested, when)

    if not args.quiet:
        for row in rows:
            print(json.dumps(row, sort_keys=True))
    for why in failures:
        print(f"bench: FAIL {why}", file=sys.stderr)

    code = 0
    if args.record:
        store = load_store()
        for row in rows:
            store[(row["benchmark"], row["language"], row["machine"])] = row
        save_store(store)
        wrote = gatemod.accept(
            rows, machine_id(), spec_gates(reg, benches),
            reg["gate"].get("margin", gatemod.DEFAULT_MARGIN),
        )
        reportmod.write()
        if not args.quiet:
            print(f"record: {len(rows)} row(s) stored, {wrote} accepted into baseline.json, report regenerated")
    if args.g1:
        print()
        gatemod.g1_table(rows, reg)
        print()
    if args.gate:
        refusals, gated, words = gatemod.check(
            [r for r in rows if r["rows"]], machine_id(),
            reg["gate"].get("margin", gatemod.DEFAULT_MARGIN), args.require,
        )
        code = gatemod.report(refusals, gated, words, reg["gate"].get("margin", gatemod.DEFAULT_MARGIN), args.require)
        gref, gjudged, gwords = gatemod.check_against_go(rows, machine_id(), reg, args.require)
        code = gatemod.report_go(gref, gjudged, gwords, args.require) or code
    if failures:
        code = code or 1
    return code


if __name__ == "__main__":
    sys.exit(main())
