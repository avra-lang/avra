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


def target_for(reg, row, default=DEFAULT_MARGIN):
    """The G1 target against Go, as data in `bench.toml`'s
    `[gate.target]`: a row's own factor, or the table's default."""
    target = reg.get("gate", {}).get("target", {})
    return float(target.get("rows", {}).get(row, target.get("default", default)))


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


def check_against_go(measured, machine, reg, require=False, path=BASELINE):
    """Judge each Avra row against Go's row for the SAME machine, from
    THIS run when Go ran, else from the RECORDED baseline — never across
    machines, and never a fresh Avra against a stale Go baseline, which
    would charge Avra for the machine's own drift. Answers (refusals,
    judged, words). A witness count is not a cost and carries no target;
    a row Go never measures is a SKIP, while a row Go measures on some
    machine but not THIS one is a word, or a refusal when `require`."""
    rows = load(path).get("rows", {})
    fresh = {}
    for r in measured:
        for rname, cell in r["rows"].items():
            fresh[(r["benchmark"], r["language"], rname)] = cell
    go_ever = set()
    for k in rows:
        parts = k.split("|")
        if len(parts) == 4 and parts[1] == "go":
            go_ever.add((parts[2], parts[3]))
    refusals, judged, words = [], 0, []
    for row in measured:
        if row["language"] != "avra" or not row["rows"]:
            continue
        for rname, cell in row["rows"].items():
            where = key(machine, "avra", row["benchmark"], rname)
            abase = rows.get(where)
            gbase = rows.get(key(machine, "go", row["benchmark"], rname))
            # a witness count is checked by `check`; a cost has a target
            if (abase and abase.get("check") == "exact") or (gbase and gbase.get("check") == "exact"):
                continue
            gcell = fresh.get((row["benchmark"], "go", rname))
            if gcell is not None:
                go_value, go_unit, where_go = gcell["value"], gcell["unit"], "same run"
            elif gbase is not None:
                go_value, go_unit, where_go = gbase["value"], gbase["unit"], "baseline"
            elif (row["benchmark"], rname) in go_ever:
                words.append(f"NO GO ROW for avra {row['benchmark']} {rname} on this machine — `--record` go here to gate it")
                if require:
                    refusals.append((where, "NO GO ROW — refused"))
                continue
            else:
                words.append(f"no Go twin measures {row['benchmark']} {rname} — a SKIP, not a target")
                continue
            if not go_value:
                words.append(f"GO ROW IS 0 for {row['benchmark']} {rname} — nothing to compare")
                continue
            judged += 1
            target = target_for(reg, rname)
            ratio = cell["value"] / go_value
            verdict = "PASS" if ratio <= target else "FAIL"
            print(f"go: {verdict}: avra {row['benchmark']} {rname}: {cell['value']:.4g} {cell['unit']} "
                  f"vs Go {go_value:.4g} {go_unit} ({where_go}), {ratio:.2f}x (target {target:.1f}x)")
            if ratio > target:
                refusals.append((where, f"FAIL: {ratio:.2f}x past the {target:.1f}x target against Go"))
    return refusals, judged, words


def report_go(refusals, judged, words, require=False):
    for why in words:
        print(f"go: {why}")
    for where, why in refusals:
        print(f"go:   {where}: {why}")
    if refusals:
        print(f"go: REFUSED — {len(refusals)} row(s) past the target against Go or unmeasured")
        return 1
    if judged == 0:
        print("go: NOT JUDGED — nothing to check against Go on this machine")
        return 1 if require else 0
    print(f"go: clean — {judged} row(s) within their target against Go")
    return 0


def g1_table(measured, reg):
    """Print each Avra row beside Go's from the SAME run, with the ratio
    and the target verdict, then the ticket's rows with no Avra twin.
    Answers the number of rows past their target."""
    by = {}
    for row in measured:
        for rname, cell in row["rows"].items():
            by[(row["benchmark"], row["language"], rname)] = cell
    fails, seen = 0, set()
    print("## G1 — Avra beside Go on THIS machine (target: 2x time, 3x parked bytes)")
    print()
    print("| benchmark | row | Avra | Go | ratio | target | verdict |")
    print("|---|---|---|---|---|---|---|")
    for row in measured:
        if row["language"] != "avra":
            continue
        if row["benchmark"] in seen:
            continue
        seen.add(row["benchmark"])
        for rname, cell in row["rows"].items():
            base = load().get("rows", {}).get(key(row["machine"], "avra", row["benchmark"], rname))
            if base and base.get("check") == "exact":
                continue
            g = by.get((row["benchmark"], "go", rname))
            if g is None:
                print(f"| `{row['benchmark']}` | `{rname}` | {cell['value']:.4g} {cell['unit']} | SKIPPED | — | — | no Go twin |")
                continue
            target = target_for(reg, rname)
            ratio = cell["value"] / g["value"] if g["value"] else float("inf")
            verdict = "PASS" if ratio <= target else "FAIL"
            if verdict == "FAIL":
                fails += 1
            print(f"| `{row['benchmark']}` | `{rname}` | {cell['value']:.4g} {cell['unit']} "
                  f"| {g['value']:.4g} {g['unit']} | {ratio:.2f}x | {target:.1f}x | {verdict} |")
    missing = reg.get("gate", {}).get("missing", {})
    if missing:
        print()
        print("| ticket row with no Avra twin | blocker |")
        print("|---|---|")
        for label, why in missing.items():
            print(f"| {label} | {why} |")
    return fails


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


def self_test_go():
    """THE GO-TARGET GATE'S OWN FAILURE, WITNESSED. A gate whose failure
    has never been seen is an untested instrument, so a row PAST its
    target must refuse and be named. Also held: a row inside its target
    passes, a witness count is not judged, and a row with no Go baseline
    is a word (or a refusal under `require`)."""
    machine = "linux-x86_64: test"
    now = "2026-01-01T00:00:00+00:00"
    base = {"schema": 1, "rows": {
        key(machine, "go", "tasks/pingpong", "pingpong_ns"): {"value": 300.0, "unit": "ns", "check": "ratio", "margin": 2.0},
        key(machine, "avra", "tasks/pingpong", "pingpong_ns"): {"value": 700.0, "unit": "ns", "check": "ratio", "margin": 2.0},
        key(machine, "go", "tasks/parked", "parked_bytes"): {"value": 1000.0, "unit": "bytes", "check": "ratio", "margin": 2.0},
        key(machine, "go", "tasks/pingpong", "pingpong_rounds"): {"value": 100.0, "unit": "ops", "check": "exact", "margin": 2.0},
        # Go measures this row on ANOTHER machine, so a machine missing it
        # is what `--require` refuses; `tasks/fanin`'s Go twin does not
        # measure `fanin_never` at all, so that one is a SKIP.
        key("other-machine", "go", "tasks/fanin", "fanin_ns_per_op"): {"value": 90.0, "unit": "ns", "check": "ratio", "margin": 2.0},
    }}
    reg = {"gate": {"target": {"default": 2.0, "rows": {"parked_bytes": 3.0}}}}
    measured = [
        {"benchmark": "tasks/pingpong", "language": "avra", "machine": machine, "when": now,
         "rows": {"pingpong_ns": {"unit": "ns", "value": 900.0, "samples": 5},
                  "pingpong_rounds": {"unit": "ops", "value": 100.0, "samples": 5}}},
        {"benchmark": "tasks/parked", "language": "avra", "machine": machine, "when": now,
         "rows": {"parked_bytes": {"unit": "bytes", "value": 3200.0, "samples": 5}}},
    ]
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "baseline.json")
        save(base, path)
        # 900/300 = 3.00x past the 2.0x target -> REFUSED, and
        # 3200/1000 = 3.20x past its own 3.0x -> REFUSED. Witness BOTH.
        refusals, judged, words = check_against_go(measured, machine, reg, path=path)
        if not refusals:
            raise AssertionError("gate self-test: a row past its Go target did NOT refuse")
        if judged != 2:
            raise AssertionError(f"gate self-test: judged {judged}, wanted 2 (the witness count is not judged)")
        print(f"self-test: go gate REFUSED {len(refusals)} row(s) past target, as designed")
        # fresh Go wins over the stale baseline: 900/500 = 1.80x passes,
        # though 900 against the 300 baseline is 3.00x and would refuse
        fresh_go = [{"benchmark": "tasks/pingpong", "language": "go", "machine": machine, "when": now,
                     "rows": {"pingpong_ns": {"unit": "ns", "value": 500.0, "samples": 5}}}]
        rf, jf, _ = check_against_go(measured + fresh_go, machine, reg, path=path)
        if any("pingpong_ns" in w for _, w in rf) or jf != 2:
            raise AssertionError(f"gate self-test: fresh Go did not win the comparison: {rf}")
        # inside the target: 600/300 = 2.00x passes at `>` the ratio
        inside = [{"benchmark": "tasks/pingpong", "language": "avra", "machine": machine, "when": now,
                   "rows": {"pingpong_ns": {"unit": "ns", "value": 600.0, "samples": 5}}}]
        refusals2, judged2, _ = check_against_go(inside, machine, reg, path=path)
        if refusals2 or judged2 != 1:
            raise AssertionError(f"gate self-test: a row AT the target did not pass: {refusals2}")
        # Go measures this row elsewhere, not on THIS machine: a word, and
        # a refusal only under `require`.
        unmeasured = [{"benchmark": "tasks/fanin", "language": "avra", "machine": machine, "when": now,
                       "rows": {"fanin_ns_per_op": {"unit": "ns", "value": 1.0, "samples": 1}}}]
        r3, j3, w3 = check_against_go(unmeasured, machine, reg, path=path)
        if r3 or j3 or not w3:
            raise AssertionError("gate self-test: a row with no Go row here was not a word")
        r4, _, _ = check_against_go(unmeasured, machine, reg, require=True, path=path)
        if not r4:
            raise AssertionError("gate self-test: `--require` did not refuse a machine missing a Go row")
        # a row Go never measures anywhere is a SKIP, never a refusal
        no_twin = [{"benchmark": "tasks/drain", "language": "avra", "machine": machine, "when": now,
                    "rows": {"drain_unbounded_1k_ns_per_op": {"unit": "ns", "value": 60.0, "samples": 1}}}]
        r5, _, w5 = check_against_go(no_twin, machine, reg, require=True, path=path)
        if r5 or not w5:
            raise AssertionError("gate self-test: a row with no Go twin anywhere was not a SKIP")
        if target_for(reg, "parked_bytes") != 3.0 or target_for(reg, "pingpong_ns") != 2.0:
            raise AssertionError("gate self-test: the per-row Go target was not read")
    return True


if __name__ == "__main__":
    sys.exit(0 if (self_test() and self_test_go()) else 1)
