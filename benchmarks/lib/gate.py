#!/usr/bin/env python3
"""THE REGRESSION SEAM: a fresh run's rows against an accepted baseline,
refusing past a margin — the idea `tools/flow_bench/gate.py` landed for
the scheduler's transition rows, at the suite's scale.

`run.sh --record` accepts this machine's rows into `benchmarks/baseline.json`;
`run.sh --gate` refuses a row past its margin. A row is ONE machine's, so
nothing is compared across machines; a machine with no accepted row prints
that and does not gate (`--require` refuses instead). The default floor is
the C twin alone, so the gate runs with no compiler and no other
toolchain.
"""
import json
import os
import sys

from bench import BENCH

BASELINE = os.path.join(BENCH, "baseline.json")
DEFAULT_MARGIN = 2.0


def key(machine, lang, bench, row):
    return f"{machine}|{lang}|{bench}|{row}"


def load(path=BASELINE):
    if not os.path.isfile(path):
        return {"schema": 1, "rows": {}}
    with open(path) as f:
        return json.load(f)


def save(data, path=BASELINE):
    with open(path, "w") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")


def margin_for(spec, row, default):
    """A spec may move the whole benchmark's margin or one row's."""
    gate = spec.get("gate", {})
    return float(gate.get("rows", {}).get(row, gate.get("margin", default)))


def accept(measured, machine, gates=None, default=DEFAULT_MARGIN, path=BASELINE):
    """Accept every fresh row this machine measured. `measured` is the
    list of stored JSON rows; `gates` maps `(benchmark, row)` to the gate
    the spec gives it — a margin for a cost, `exact` for a witness count
    that must not move at all."""
    gates = gates or {}
    data = load(path)
    wrote = 0
    for row in measured:
        if not row["rows"]:
            continue
        for rname, cell in row["rows"].items():
            g = gates.get((row["benchmark"], rname), {})
            data["rows"][key(machine, row["language"], row["benchmark"], rname)] = {
                "value": cell["value"],
                "unit": cell["unit"],
                "check": g.get("check", "ratio"),
                "margin": float(g.get("margin", default)),
            }
            wrote += 1
    save(data, path)
    return wrote


def check(measured, machine, default=DEFAULT_MARGIN, require=False, path=BASELINE):
    """Compare fresh rows to the baseline. Answers (refusals, gated). A
    row nobody measured is named; a missing baseline row is a word, and a
    refusal only when `require`."""
    data = load(path)
    refusals, gated, words = [], 0, []
    for row in measured:
        for rname, cell in row["rows"].items():
            where = key(machine, row["language"], row["benchmark"], rname)
            base = data["rows"].get(where)
            if base is None:
                words.append(f"NO BASELINE ROW for {row['language']} {row['benchmark']} {rname} — `--record` accepts it")
                if require:
                    refusals.append((where, "NO BASELINE ROW — refused"))
                continue
            was = base["value"]
            margin = base.get("margin", default)
            gated += 1
            if base.get("check") == "exact":
                ok = cell["value"] == was
                print(f"gate: {'PASS' if ok else 'FAIL'}: {row['language']} {row['benchmark']} {rname}: "
                      f"{cell['value']:.4g} {cell['unit']} vs baseline {was:.4g} {base['unit']} (exact)")
                if not ok:
                    refusals.append((where, f"FAIL: {cell['value']:.4g} != the exact baseline {was:.4g}"))
                continue
            if not was:
                refusals.append((where, "the baseline row is 0 — nothing to compare"))
                continue
            got = cell["value"] / was
            verdict = "PASS" if got <= margin else "FAIL"
            print(f"gate: {verdict}: {row['language']} {row['benchmark']} {rname}: "
                  f"{cell['value']:.4g} {cell['unit']} vs baseline {was:.4g} {base['unit']}, "
                  f"{got:.2f}x (gate {margin:.1f}x)")
            if got > margin:
                refusals.append((where, f"{verdict}: {got:.2f}x past the {margin:.1f}x gate"))
    return refusals, gated, words


def report(refusals, gated, words, margin, require):
    for why in words:
        print(f"gate: {why}")
    if refusals:
        print(f"gate: REFUSED — {len(refusals)} row(s) past {margin:.1f}x or unmeasured:")
        for where, why in refusals:
            print(f"gate:   {where}: {why}")
        return 1
    if gated == 0:
        print("gate: NOT GATED — no accepted row on this machine, so nothing was compared")
        return 1 if require else 0
    print(f"gate: clean — {gated} row(s) within {margin:.1f}x of the baseline")
    return 0


# ── the rules on fixtures, no toolchain ──────────────────────────────

def self_test():
    machine = "linux-x86_64: test"
    base = {"schema": 1, "rows": {
        key(machine, "c", "tasks/spawn", "spawn_one"): {"value": 100.0, "unit": "ns", "margin": 2.0},
        key(machine, "c", "tasks/drain", "drain_ns_per_op"): {"value": 50.0, "unit": "ns", "margin": 3.0},
    }}
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "baseline.json")
        save(base, path)
        same = [{"benchmark": "tasks/spawn", "language": "c", "rows": {"spawn_one": {"unit": "ns", "value": 100.0, "samples": 5}}},
                {"benchmark": "tasks/drain", "language": "c", "rows": {"drain_ns_per_op": {"unit": "ns", "value": 50.0, "samples": 5}}}]
        over = [{"benchmark": "tasks/spawn", "language": "c", "rows": {"spawn_one": {"unit": "ns", "value": 250.0, "samples": 5}}},
                {"benchmark": "tasks/drain", "language": "c", "rows": {"drain_ns_per_op": {"unit": "ns", "value": 50.0, "samples": 5}}}]
        at_margin = [{"benchmark": "tasks/spawn", "language": "c", "rows": {"spawn_one": {"unit": "ns", "value": 200.0, "samples": 5}}}]
        absent = [{"benchmark": "tasks/fanin", "language": "c", "rows": {"fanin_n": {"unit": "ns", "value": 1.0, "samples": 1}}}]
        for rows, want_fail, want_require, label in (
            (same, False, False, "identical rows pass"),
            (over, True, False, "a row past the margin refuses"),
            (at_margin, False, False, "a row AT the margin passes (`>` the ratio, never `>=`)"),
            (absent, True, True, "a row with no baseline refuses when `--require`"),
            (absent, False, False, "a row with no baseline is a word otherwise"),
        ):
            refusals, gated, words = check(rows, machine, require=want_require, path=path)
            if bool(refusals) != want_fail:
                raise AssertionError(f"gate self-test: {label}: refusals={refusals} gated={gated} words={words}")
        # the per-row margin was read, not the default
        if margin_for({"gate": {"rows": {"drain_ns_per_op": 3.0}}}, "drain_ns_per_op", 2.0) != 3.0:
            raise AssertionError("gate self-test: a per-row margin was not read")
        if margin_for({}, "anything", 2.0) != 2.0:
            raise AssertionError("gate self-test: the default margin was not read")
    return True


if __name__ == "__main__":
    sys.exit(0 if self_test() else 1)
