#!/usr/bin/env python3
"""THE RUNTIME CHANGE GATE: the scheduler's transition rows against a
recorded baseline, refusing past a ratio.

A change to `runtime/*.c` can cost the transition hot path without
touching a test, so a regression there reaches `main` silently. This
gate runs the C rows the scheduler owns and compares them to
`tools/flow_bench/gate.baseline`, one row per machine and toolchain like
`footprint.baseline`, so a Sprite and a Mac are never compared.

  gate.py --baseline tools/flow_bench/gate.baseline <raw>
      rows measured by `run.sh --gate` -> `<engine> <row> <total> <count>`
  gate.py --baseline … --require <raw>
      a machine with no baseline row is a REFUSAL, not a note (the
      runtime-PR job, which must not silently gate nothing)
  gate.py --record --baseline … <raw>
      accept this machine's rows into the baseline, deliberately
  gate.py --self-test
      the rules on fixtures, no runtime

The margin defaults to 2.0x (FLOW_GATE_RATIO), the G1 time gate: far
above the few-percent spread the bench's rounds show, far below what a
syscall on the transition costs. The gate holds the C rows alone — a
compiler change does not fail a runtime gate — and the compiled Avra
twins stay published beside Go by the G1 view (`table.py --gates`).
"""
import os
import platform
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASELINE = os.path.join(ROOT, "tools", "flow_bench", "gate.baseline")
DEFAULT_RATIO = 2.0

# The rows the gate holds, in the order they are printed. Each is a
# transition edge the scheduler can tax; the round trip is the row that
# regressed, spawn+join carries the same edge two times a task, and the
# parked row crosses it cold.
ROWS = [
    "c_gate_round_trip",
    "c_spawn_one",
    "c_spawn_parked_cold",
]


def rows_of(text):
    """`<engine> <row> <total> <count>` lines -> {row: (least total, count)}
    over the rounds the file holds; a count is fixed per row, so the
    least total is the least per-unit."""
    rows = {}
    for line in text.splitlines():
        parts = line.split()
        if len(parts) == 4 and parts[2].isdigit() and parts[3].isdigit():
            total, count = int(parts[2]), int(parts[3])
            if parts[1] not in rows or total < rows[parts[1]][0]:
                rows[parts[1]] = (total, count)
    return rows


def baseline_rows(text):
    """`<platform> <row> <total> <count> <toolchain>` -> {(platform, toolchain, row): (total, count)}."""
    rows = {}
    for line in text.splitlines():
        parts = line.split(None, 4)
        if len(parts) == 5 and not line.startswith("#"):
            rows[(parts[0], parts[4].strip(), parts[1])] = (int(parts[2]), int(parts[3]))
    return rows


def host():
    return f"{platform.system().lower()}-{platform.machine().lower()}"


def toolchain():
    out = subprocess.run(["cc", "--version"], capture_output=True, text=True)
    return (out.stdout.splitlines() or ["absent"])[0].strip() if out.returncode == 0 else "absent"


def per_unit(cell):
    total, count = cell
    return total / count if count else 0.0


def check(measured, accepted, where, ratio, require):
    """What the gate holds — every row, judged against this machine's
    accepted row. Answers (refusals, gated, words): the refusals are the
    rows past the margin (or a row nobody measured, which would be a
    verdict over nothing); `gated` is how many rows had a baseline here,
    which is the coverage the gate must state. A machine with no accepted
    row REFUSES only when the caller asks (`--require`): otherwise the
    rows are printed and the absence is the words."""
    refusals, gated, words = [], 0, []
    for row in ROWS:
        found = measured.get(row)
        base = accepted.get((where[0], where[1], row))
        if found is None:
            refusals.append((row, "NOT MEASURED — the gate examined nothing for it"))
            continue
        if base is None:
            machine = "%s / %s" % where
            words.append("NO BASELINE ROW for %s — `run.sh --record` accepts it" % machine)
            if require:
                refusals.append((row, "NO BASELINE ROW for %s — refused" % machine))
            continue
        now, was = per_unit(found), per_unit(base)
        if not was:
            refusals.append((row, "the baseline row is 0 — nothing to compare"))
            continue
        gated += 1
        got = now / was
        line = "%s — %.1f ns/unit vs baseline %.1f ns/unit, %.2fx (gate %.1fx)" % (
            "PASS" if got <= ratio else "FAIL",
            now,
            was,
            got,
            ratio,
        )
        print("gate: %s: %s" % (row, line))
        if got > ratio:
            refusals.append((row, line))
    return refusals, gated, words


def record(raw_path, base_path):
    """Write this machine/toolchain's rows into the baseline, keeping
    every other machine's. The rows are the raw totals over their counts,
    so the file holds what was measured."""
    measured = rows_of(open(raw_path).read())
    here = (host(), toolchain())
    lines = open(base_path).read().splitlines() if os.path.isfile(base_path) else []
    head = [line for line in lines if line.startswith("#")]
    body = [line for line in lines if not line.startswith("#")]
    kept = []
    for line in body:
        parts = line.split(None, 4)
        if len(parts) == 5 and not (parts[0] == here[0] and parts[4].strip() == here[1] and parts[1] in ROWS):
            kept.append(line)
    wrote = 0
    for row in ROWS:
        if row not in measured:
            print("gate: %s was not measured — nothing recorded for it" % row)
            continue
        total, count = measured[row]
        kept.append("%s %s %d %d %s" % (here[0], row, total, count, here[1]))
        wrote += 1
    if not head:
        head = [
            "# THE LAST ACCEPTED FLOW G1 BASELINE: the scheduler's transition rows,",
            "# <platform> <row> <total ns> <count> <toolchain>, written by",
            "# `sh tools/flow_bench/run.sh --record` and held by `make flow-gate`.",
            "# One row is ONE machine's; the gate compares like with like. No row,",
            "# no gate on that machine.",
        ]
    open(base_path, "w").write("\n".join(head + kept) + "\n")
    print("gate: recorded %d row(s) for %s / %s in %s" % (wrote, here[0], here[1], base_path))
    return 0 if wrote == len(ROWS) else 1


def gate(raw_path, base_path, ratio, require):
    measured = rows_of(open(raw_path).read())
    accepted = baseline_rows(open(base_path).read()) if os.path.isfile(base_path) else {}
    here = (host(), toolchain())
    print("gate: %s, cc: %s" % (here[0], here[1]))
    fail, gated, words = check(measured, accepted, here, ratio, require)
    print("gate: %d of %d row(s) examined, %d gated here" % (len(measured), len(ROWS), gated))
    for why in words:
        print("gate: %s" % why)
    if fail:
        print("gate: REFUSED — %d row(s) past %.1fx or unmeasured:" % (len(fail), ratio))
        for row, why in fail:
            print("gate:   %s: %s" % (row, why))
        return 1
    if gated == 0:
        print("gate: NOT GATED — no accepted row on this machine, so nothing was compared")
        return 1 if require else 0
    print("gate: clean — %d row(s) within %.1fx of the baseline" % (len(ROWS), ratio))
    return 0


# ── the rules on fixtures, no runtime ──

def self_test():
    base = (
        "linux-x86_64 c_gate_round_trip 19600000 200000 cc 1\n"
        "linux-x86_64 c_spawn_one 1210000 10000 cc 1\n"
        "linux-x86_64 c_spawn_parked_cold 8380000 10000 cc 1\n"
    )
    other = "darwin-arm64 c_gate_round_trip 16400000 200000 cc 2\n"
    # a comment and a line that is not a row are read past, never a row
    accepted = baseline_rows("# a comment\n" + base + "linux-x86_64 notarow cc 1\n")
    assert len(accepted) == 3, accepted
    where = ("linux-x86_64", "cc 1")
    same = "c c_gate_round_trip 19600000 200000\nc c_spawn_one 1210000 10000\nc c_spawn_parked_cold 8380000 10000\n"
    over = same.replace("19600000", "58800000")
    # each accepted spelling, and each refused one. A row at the margin
    # passes (the gate is `>` the ratio, never `>=`); a row past it fails
    # by name; a row nobody measured is a verdict over nothing; a machine
    # with no accepted row is GATED 0, accepted until asked.
    assert check(rows_of(same), accepted, where, 2.0, False)[0] == []
    assert check(rows_of(same.replace("19600000", "39200000")), accepted, where, 2.0, False)[0] == []
    fail, gated, _ = check(rows_of(over), accepted, where, 2.0, False)
    assert [r for r, _ in fail] == ["c_gate_round_trip"] and gated == 3, (fail, gated)
    fail, _, _ = check(rows_of("c c_gate_round_trip 19600000 200000\n"), accepted, where, 2.0, False)
    assert len(fail) == 2, fail
    elsewhere = baseline_rows(other)
    fail, gated, _ = check(rows_of(same), elsewhere, where, 2.0, False)
    assert fail == [] and gated == 0, (fail, gated)
    fail, _, _ = check(rows_of(same), elsewhere, where, 2.0, True)
    assert len(fail) == 3 and all("refused" in w for _, w in fail), fail
    # the least of the rounds is the row, never the first, and a line that
    # is not a 4-field row is read past
    twice = "c not a row\nc c_gate_round_trip 29400000 200000\n" + same
    assert rows_of(twice)["c_gate_round_trip"] == (19600000, 200000)
    # --record: THIS machine's stale row is replaced by the measured least,
    # another machine's rows are kept, and its header survives
    try:
        with tempfile.TemporaryDirectory() as work:
            raw = os.path.join(work, "raw")
            base_at = os.path.join(work, "base")
            open(raw, "w").write(same + same.replace("19600000", "49000000"))
            open(base_at, "w").write("# keep me\n" + base.replace("linux-x86_64", host()) + other)
            record(raw, base_at)
            kept = baseline_rows(open(base_at).read())
            assert ("darwin-arm64", "cc 2", "c_gate_round_trip") in kept, kept
            assert kept[(host(), toolchain(), "c_gate_round_trip")] == (19600000, 200000), kept
            assert open(base_at).read().startswith("# keep me\n"), "the header was lost"
    except Exception as why:
        print("gate self-test: --record fixture failed: %s" % why)
        return 1
    print("gate self-test: 10 fixture(s) held")
    return 0


def main(argv):
    ratio = float(os.environ.get("FLOW_GATE_RATIO", DEFAULT_RATIO))
    path = None
    base = BASELINE
    require = False
    recording = False
    i = 1
    while i < len(argv):
        if argv[i] == "--baseline":
            base = argv[i + 1]
            i += 2
        elif argv[i] == "--ratio":
            ratio = float(argv[i + 1])
            i += 2
        elif argv[i] == "--require":
            require = True
            i += 1
        elif argv[i] == "--self-test":
            return self_test()
        elif argv[i] == "--record":
            recording = True
            i += 1
        else:
            path = argv[i]
            i += 1
    if recording:
        return record(path, base) if path else 2
    if path is None:
        print("gate: no raw file — run `sh tools/flow_bench/run.sh --gate`", file=sys.stderr)
        return 2
    return gate(path, base, ratio, require)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
