#!/usr/bin/env python3
"""THE COLD-COMPILE WORK RATCHET: what a cold `check packages/cli` DOES, counted exactly.

    census_ratchet.py --raw <file> [--accept]   judge a `make census-gate` output
    census_ratchet.py --self-test

`tools/census.sh check --counts packages/cli` builds a census compiler and runs the check
cold under it: exact retain / release / list-read / list-write counts and the bytes the run
left in its store (a row count alone misses rows that got larger), the same on every
machine (the runtime counts operations, never time). A linear scan over a list shows up as
list reads, so an algorithmic slowdown that moves no query or row count is still seen —
what a wall clock on a shared runner cannot promise.

WORK THAT GROWS WITH THE TREE IS A RATIO to the program's size (declarations), since the gate
checks the compiler's OWN tree and a PR that adds source raises raw counts legitimately
(CLAUDE.md: a gate floor is relative, never an absolute count). Ceilings are per declaration,
in `tools/census.budget`, with SLACK_PPM of room (the tree's shape moves a little).

A counter over its ceiling REFUSES, unless `SPEED_ACCEPT` names a reason (the workflow passes
the PR body's `SPEED_ACCEPT: <reason>` line): the pass is then loud, and the reason rides the
squash commit, so `git log` shows every accepted slowdown. A ceiling may only FALL: `--accept`
lowers each row and never raises one (`make census-accept`). A run with no counts REFUSES.

THE CEILING TIGHTENS BY ITSELF: `--main <file>` is main's last gated run (its per-declaration
counts, which the workflow keeps beside the speed baseline), and a PR is held to the LESS of the
committed ceiling and that, so a regression cannot creep back to the old level between commits
of the file. `SPEED_ACCEPT` passes a PR over main's number only while the committed ceiling
still holds it: a PR that must cost more RAISES `tools/census.budget` in its own diff, where
the review is, and says why in its body. Every run writes `build/census-now.txt` for main to keep.
"""
import os
import re
import sys

BUDGET = os.path.join(os.path.dirname(os.path.abspath(__file__)), "census.budget")
SLACK_PPM = 15000
COUNTERS = ("retains", "releases", "reclaims", "list_reads", "list_writes", "store_bytes")
HEAD = """\
# THE COLD-COMPILE CEILINGS: the most work a cold `check packages/cli` may do, per declaration
# of the program, counted by the runtime (`make census-gate`, tools/census_ratchet.py). Exact,
# machine-independent. A ceiling MAY ONLY FALL: `make census-accept` lowers each row to what a
# run measured. A raise is a human edit and the diff is the review; a PR that must grow one
# says `SPEED_ACCEPT: <reason>` in its body instead.
"""


def read_counts(text):
    """The census's `rc:` lines and the `counts:` line -> ({counter: n}, program_decls)."""
    got = {}
    for line in text.splitlines():
        m = re.match(r"rc: (\d+) retains, (\d+) releases, (\d+) reclaims", line)
        if m:
            got.update(retains=int(m[1]), releases=int(m[2]), reclaims=int(m[3]))
        m = re.match(r"rc: (\d+) list reads, (\d+) list writes", line)
        if m:
            got.update(list_reads=int(m[1]), list_writes=int(m[2]))
    m = re.search(r"^store: (\d+) bytes", text, re.M)
    if m:
        got["store_bytes"] = int(m[1])
    m = re.search(r"program_decls=(\d+)", text)
    return got, int(m[1]) if m else 0


def per_decl(got, decls):
    return {k: got[k] // decls for k in COUNTERS if k in got}


def read_budget(text):
    out = {}
    for line in text.splitlines():
        m = re.match(r"^([a-z_]+) (\d+)$", line.strip())
        if m:
            out[m[1]] = int(m[2])
    return out


def over(n, ceiling):
    return n * 1000000 > ceiling * (1000000 + SLACK_PPM)


def judge(now, budget, accept, main=None):
    """(refusals, notes). `now`, `budget`, `main`: counter -> per-declaration count."""
    main = main or {}
    bad, notes = [], []
    for k in COUNTERS:
        if k not in budget:
            bad.append(f"{k} has no ceiling — record it with `make census-accept`")
        elif k not in now:
            bad.append(f"{k} was not counted")
        elif over(now[k], min(budget[k], main.get(k, budget[k]))):
            ceiling = min(budget[k], main.get(k, budget[k]))
            from_main = k in main and main[k] < budget[k]
            msg = (f"{k}: {now[k]} per declaration, ceiling {ceiling}"
                   f"{' (main last ran ' + str(main[k]) + ')' if from_main else ''}"
                   f" (+{(now[k] - ceiling) * 100 // max(ceiling, 1)}%)")
            if not accept:
                bad.append(msg)
            elif over(now[k], budget[k]):
                bad.append(msg + f" — SPEED_ACCEPT also needs `{k} {now[k]}` in tools/census.budget, raised in this PR's diff")
            else:
                notes.append(msg)
        elif now[k] < min(budget[k], main.get(k, budget[k])):
            notes.append(f"{k} is under its ceiling ({now[k]} < {min(budget[k], main.get(k, budget[k]))}) — `make census-accept` lowers the file")
    return bad, notes


def render(budget):
    return HEAD + "".join(f"{k} {budget[k]}\n" for k in COUNTERS if k in budget)


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    if "--raw" not in argv:
        print("census_ratchet: --raw <file> names the census output", file=sys.stderr)
        return 2
    got, decls = read_counts(open(argv[argv.index("--raw") + 1], errors="replace").read())
    if not got or not decls:
        print("census_ratchet: REFUSED — the census printed no counts (a check that examined nothing is not a pass)")
        return 1
    now = per_decl(got, decls)
    budget = read_budget(open(BUDGET).read()) if os.path.exists(BUDGET) else {}
    if "--accept" in argv:
        new = {k: min(now[k], budget.get(k, now[k])) for k in COUNTERS if k in now}
        open(BUDGET, "w").write(render(new))
        print("census_ratchet: --accept — %d row(s) written, none raised" % len(new))
        return 0
    open(os.path.join(os.path.dirname(os.path.abspath(argv[argv.index("--raw") + 1])), "census-now.txt"), "w").write(
        "".join(f"{k} {now[k]}\n" for k in COUNTERS if k in now))
    main = read_budget(open(argv[argv.index("--main") + 1]).read()) if "--main" in argv and os.path.exists(argv[argv.index("--main") + 1]) else {}
    if "--main" in argv and not main:
        print("census_ratchet: no main counts kept yet — held to the committed ceilings alone")
    accept = os.environ.get("SPEED_ACCEPT", "").strip()
    bad, notes = judge(now, budget, bool(accept), main)
    for n in notes:
        print("census_ratchet: " + n)
    if accept and any("ceiling" in n and "per declaration" in n for n in notes):
        print(f"census_ratchet: ACCEPTED by SPEED_ACCEPT — {accept}")
    if bad:
        for b in bad:
            print("census_ratchet: REFUSED — " + b)
        print("census_ratchet: a PR that must cost more says `SPEED_ACCEPT: <reason>` in its body")
        return 1
    print("census_ratchet: held — %d counters within their ceilings (%d decls)" % (len(now), decls))
    return 0


def self_test():
    raw = "rc: 1000 retains, 2000 releases, 30 reclaims\nrc: 5000 list reads, 400 list writes\nstore: 70000 bytes\ncounts: x program_decls=10 y\n"
    got, decls = read_counts(raw)
    assert got == dict(retains=1000, releases=2000, reclaims=30, list_reads=5000, list_writes=400, store_bytes=70000) and decls == 10, (got, decls)
    now = per_decl(got, decls)
    assert now["retains"] == 100 and now["list_reads"] == 500
    ok = dict(now)
    assert judge(now, ok, False) == ([], [])
    low = {k: v + 50 for k, v in now.items()}
    bad, notes = judge(now, low, False)
    assert bad == [] and len(notes) == 6, "under every ceiling says so, never refuses"
    tight = dict(now, list_reads=100)
    bad, _ = judge(now, tight, False)
    assert len(bad) == 1 and bad[0].startswith("list_reads: 500"), bad
    bad, notes = judge(now, tight, True)
    assert len(bad) == 1 and "census.budget" in bad[0], "a waiver over the committed ceiling must raise the file"
    slack = dict(now, retains=99)
    assert judge(now, slack, False)[0] == [], "1% slack is not a refusal"
    assert judge(now, {}, False)[0], "a counter with no ceiling refuses"
    assert read_counts("nothing")[0] == {}
    # main ran lower than the committed ceiling: the PR is held to main's number
    kept = dict(now, list_reads=400)
    bad, _ = judge(now, ok, False, kept)
    assert len(bad) == 1 and "main last ran 400" in bad[0], bad
    # a waiver does not pass over the committed ceiling: the raise must be in the diff
    both = dict(now, list_reads=400)
    bad, notes = judge(now, both, True, both)
    assert len(bad) == 1 and "census.budget" in bad[0], bad
    # a waiver passes a PR over main's number while the committed ceiling holds it
    bad, notes = judge(now, ok, True, kept)
    assert bad == [] and any("list_reads" in n for n in notes), (bad, notes)
    # a store that tripled with every operation count flat is refused: bytes are their own counter
    fat = dict(now, store_bytes=now["store_bytes"] * 3)
    bad, _ = judge(fat, ok, False)
    assert len(bad) == 1 and bad[0].startswith("store_bytes:"), bad
    # a census that printed no counts FAILS: nothing examined is not a pass
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        empty = os.path.join(d, "out")
        open(empty, "w").write("census: nothing here\n")
        assert main(["--raw", empty]) == 1, "no counts must refuse"
        open(empty, "w").write("rc: 1 retains, 2 releases, 3 reclaims\nrc: 4 list reads, 5 list writes\nstore: 6 bytes\n")
        assert main(["--raw", empty]) == 1, "counts with no program size must refuse"
    print("census_ratchet: self-test passed — 14 fixtures")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
