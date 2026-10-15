#!/usr/bin/env python3
"""THE SUITE'S SELF-TEST: the gate's rules on fixtures, the row contract,
and the reproducibility receipt — the committed report must equal a fresh
projection of the stored JSON, byte for byte. No toolchain and no
benchmark program runs here.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import bench
import gate
import report

SCHEMA_KEYS = {"benchmark", "language", "version", "machine", "when", "rows", "notes"}


def check(cond, label):
    if not cond:
        print(f"self-test: FAIL — {label}", file=sys.stderr)
    return cond


def contract():
    """The row contract a language program speaks."""
    ok = True
    rows, notes = bench.parse_rows("spawn_one\t186.6\tns\t5\n# least of 5\n")
    ok &= check(rows == {"spawn_one": {"unit": "ns", "value": 186.6, "samples": 5}}, "a well-formed row parses")
    ok &= check(notes == ["least of 5"], "a `#` line becomes a note")
    try:
        bench.parse_rows("spawn_one 186.6 ns\n")
        ok &= check(False, "a row with no tabs is refused")
    except bench.Fail:
        pass
    row = bench.row_of("tasks/spawn", "c", "cc 1", "linux-x86_64: test", "2026-01-01T00:00:00+00:00", rows, notes)
    ok &= check(set(row) == SCHEMA_KEYS, "the row carries exactly the fixed schema keys")
    ok &= check(set(row["rows"]["spawn_one"]) == {"unit", "value", "samples"}, "a row cell carries unit, value, samples")
    skip = bench.skipped_row("tasks/spawn", "rust", "linux-x86_64: test", "2026-01-01T00:00:00+00:00", "no rustc")
    ok &= check(skip["notes"].startswith("SKIPPED:") and skip["rows"] == {}, "a skip is a row that says so")
    return ok


def main():
    ok = contract()
    try:
        ok &= check(gate.self_test(), "the gate's rules hold on fixtures")
    except AssertionError as e:
        ok &= check(False, str(e))
    ok &= check(report.check(), "the committed report equals a fresh projection of the stored JSON")
    if ok:
        print("self-test: clean")
    return ok


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
