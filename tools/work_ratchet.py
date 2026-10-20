#!/usr/bin/env python3
"""THE WORK-COUNT RATCHET: what a warm check does, counted, never clocked.

    work_ratchet.py --raw <file> [--accept]   judge the counts the bench measured
    work_ratchet.py --self-test

`tools/warm_edit_bench.sh` runs `check --counts` on `packages/cli`, unchanged
and after one body edit, and writes `counts <scenario> <counter> <n>` rows.
The compiler counts its own work exactly (compiler/work.av), so a count is the
same on every machine and needs no slack: a counter past its row in
`tools/work.budget` REFUSES, a counter with no row refuses (record it with
`--accept`), and a row no run measured refuses.

WORK THAT GROWS WITH THE TREE IS HELD AS A RATIO to the program's size (`_ppm`:
per million of the program's files, modules or declarations), because the
gate measures the compiler checking its OWN tree and a PR that adds source
raises the raw counts legitimately (CLAUDE.md: a gate floor is relative, never
an absolute count). The raw counts and `program_*` sizes are REPORTED, never
judged (INFORMATIONAL). The unchanged scenario stays absolute: nothing at all.

A ceiling MAY ONLY FALL. `--accept` lowers each row to what was measured,
seeds a counter that has no row yet, and never raises one; a raise is a human
edit of the budget and the diff is the review. A run under its ceiling says so
and names the command that lowers it (`make work-accept`).
"""
import os
import re
import sys

BUDGET = os.path.join(os.path.dirname(os.path.abspath(__file__)), "work.budget")
ROW = re.compile(r"^counts (?P<scenario>[a-z]+) (?P<counter>[a-z_]+) (?P<n>[0-9]+)$")
BUDGET_ROW = re.compile(r"^(?P<scenario>[a-z]+) (?P<counter>[a-z_]+) (?P<n>[0-9]+)$")
# Reported beside the gated rows, never judged: the program's size and the raw counts
# whose ratios are gated.
INFORMATIONAL = {
    "rule_ms",
    "program_files", "program_modules", "program_decls",
    "files_minted", "modules_minted", "queries_computed", "typed_computed", "store_rows_written",
}
# A ratio near 1 moves a little when the tree grows by a few files (a constant few files
# are never minted): 517/519 is not 515/517. The slack is that, and no more.
PPM_SLACK = 2000
HEAD = """\
# THE WORK-COUNT RATCHET'S CEILINGS: the most work a warm `check packages/cli`
# may do, counted by the compiler itself (`check --counts`, compiler/work.av) —
# <scenario> <counter> <n>. Counts are exact and machine-independent, so a row
# carries no host and the gate allows no slack. Read by `tools/work_ratchet.py`
# (`make warm-edit`, `tools/warm_edit_bench.sh`).
#
# A ceiling MAY ONLY FALL: `make work-accept` lowers each row to what a run
# measured and never raises one. A raise is a human edit of this file, and the
# diff is the review. `unchanged` is a check of a tree the store already holds;
# `edit` is the check after one string literal in one body moved. A `_ppm` row is per
# million of the program's own files, modules or declarations (work that grows with
# the tree is a ratio, so a PR that adds source is not refused for it), judged with
# PPM_SLACK for a tree that grew by a few files.
"""


def measured_rows(text):
    """`counts <scenario> <counter> <n>` -> {(scenario, counter): n}, the
    least of a repeated row. Any other line is read past."""
    rows = {}
    for line in text.splitlines():
        m = ROW.match(line.strip())
        if m:
            key = (m.group("scenario"), m.group("counter"))
            n = int(m.group("n"))
            rows[key] = min(n, rows.get(key, n))
    return rows


def gated(rows):
    return {k: v for k, v in rows.items() if k[1] not in INFORMATIONAL}


def budget_rows(text):
    rows = {}
    for line in text.splitlines():
        m = BUDGET_ROW.match(line.strip())
        if m:
            rows[(m.group("scenario"), m.group("counter"))] = int(m.group("n"))
    return rows


def budget_text(rows):
    return HEAD + "".join("%s %s %d\n" % (s, c, rows[(s, c)]) for (s, c) in sorted(rows))


def judge(measured, ceilings):
    """(refusals, words): refusals are counters past a row, with no row, or
    rows nothing measured."""
    refusals, words = [], []
    for key in sorted(measured):
        name = "%s %s" % key
        if key not in ceilings:
            refusals.append((name, "measured %d with no ceiling row — record it with `make work-accept`" % measured[key]))
            continue
        now, was = measured[key], ceilings[key]
        limit = was + (PPM_SLACK if key[0] == "edit" and key[1].endswith("_ppm") else 0)
        if now > limit:
            refusals.append((name, "%d against a ceiling of %d (over by %d)" % (now, was, now - limit)))
        elif now < was:
            words.append("%s: %d under a ceiling of %d — `make work-accept` lowers it" % (name, now, was))
        elif now > was:
            words.append("%s: %d, %d over its ceiling and inside the growth slack" % (name, now, now - was))
        else:
            words.append("%s: %d, at its ceiling" % (name, now))
    for key in sorted(set(ceilings) - set(measured)):
        refusals.append(("%s %s" % key, "a ceiling row no run measured"))
    return refusals, words


def accepted(measured, ceilings):
    """The ceilings after `--accept`: lowered to what was measured, a new
    counter seeded, never one raised."""
    out = dict(ceilings)
    for key, now in measured.items():
        out[key] = min(now, ceilings.get(key, now))
    return out


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    raw = argv[argv.index("--raw") + 1] if "--raw" in argv else None
    if raw is None:
        print("work_ratchet: --raw <file> names the measurement", file=sys.stderr)
        return 2
    reported = measured_rows(open(raw).read())
    measured = gated(reported)
    if not measured:
        print("work_ratchet: REFUSED — the measurement carries no `counts` row (did `check --counts` print one?)")
        return 1
    ceilings = budget_rows(open(BUDGET).read()) if os.path.exists(BUDGET) else {}
    if "--accept" in argv:
        new = accepted(measured, ceilings)
        open(BUDGET, "w").write(budget_text(new))
        print("work_ratchet: --accept — %d row(s) written, none raised" % len(new))
        return 0
    refusals, words = judge(measured, ceilings)
    for (scenario, name), n in sorted(reported.items()):
        if name in INFORMATIONAL:
            print("work: %s %s: %d (reported)" % (scenario, name, n))
    for w in words:
        print("work: %s" % w)
    if refusals:
        print("work: REFUSED — %d counter(s) past the ceiling or unjudged:" % len(refusals))
        for name, why in refusals:
            print("work:   %s: %s" % (name, why))
        return 1
    print("work: %d counter(s) held" % len(measured))
    return 0


def self_test():
    raw = "host x\nwarm edit 50\ncounts edit files_parsed 3\ncounts edit files_parsed 2\ncounts unchanged files_parsed 0\n"
    m = measured_rows(raw)
    assert m == {("edit", "files_parsed"): 2, ("unchanged", "files_parsed"): 0}, m
    held = {("edit", "files_parsed"): 2, ("unchanged", "files_parsed"): 0}
    assert judge(m, held)[0] == []
    over = judge({("edit", "files_parsed"): 3, ("unchanged", "files_parsed"): 0}, held)[0]
    assert len(over) == 1 and "over by 1" in over[0][1], over
    assert len(judge(m, {("edit", "files_parsed"): 2})[0]) == 1  # no row for unchanged
    assert len(judge(m, {**held, ("edit", "files_minted"): 1})[0]) == 1  # row nothing measured
    under = judge({("edit", "files_parsed"): 1, ("unchanged", "files_parsed"): 0}, held)
    assert under[0] == [] and "make work-accept" in under[1][0]
    ppm = {("edit", "files_minted_ppm"): 996131, ("unchanged", "files_minted_ppm"): 0}
    assert judge({("edit", "files_minted_ppm"): 996146, ("unchanged", "files_minted_ppm"): 0}, ppm)[0] == [], "growth slack"
    assert len(judge({("edit", "files_minted_ppm"): 999000, ("unchanged", "files_minted_ppm"): 0}, ppm)[0]) == 1
    assert len(judge({("edit", "files_minted_ppm"): 996131, ("unchanged", "files_minted_ppm"): 1}, ppm)[0]) == 1, "unchanged is absolute"
    assert accepted({("edit", "files_parsed"): 1, ("unchanged", "files_parsed"): 5}, held) == {
        ("edit", "files_parsed"): 1,
        ("unchanged", "files_parsed"): 0,
    }
    assert accepted({("edit", "files_minted"): 4}, held)[("edit", "files_minted")] == 4
    assert budget_rows(budget_text(held)) == held
    assert gated({("edit", "program_files"): 9, ("edit", "files_minted_ppm"): 3}) == {("edit", "files_minted_ppm"): 3}
    print("work_ratchet: self-test passed — 12 fixtures")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
