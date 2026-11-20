#!/usr/bin/env python3
"""THE EXACT-COUNT GATE: what the compiler DOES on fixed workloads, counted by the census runtime.

    cost_ratchet.py --judge <dir>      judge a `tools/cost.sh` run against tools/cost.baseline
    cost_ratchet.py --accept <dir>     record a run: rows fall to what it measured; a run over another
                                       snapshot records that snapshot and every row as measured
    cost_ratchet.py --edit <file> <kind> <text> <becomes>
                                       make one edit of tools/cost.sh's set: the text, which stands in
                                       the file once, becomes what follows (`\\n` a line break); a
                                       `rename` renames the word through the file
    cost_ratchet.py --self-test

`tools/cost.sh` runs the census compiler of the tree cold over workloads whose sources are ONE pinned
commit (the baseline's `snapshot` row), so a count moves only when the compiler's work does; and warm
after each of a fixed set of edits, where the count is the queries worked out again (an `edit-<kind>`
row), so a change that trades warm work for cold is seen. Counts are exact and machine-independent:
the runtime counts operations, never time.

A COUNTER OVER ITS ROW BY MORE THAN THE TOLERANCE FAILS, naming the workload, the counter and both
numbers. A counter under its row stays until `make cost-accept` lowers it; an accept never raises a
row over the same snapshot. Moving the snapshot is an accept with `COST_SNAPSHOT=<sha>`, which records
the new commit and every count it measured. A run that printed no count for a row FAILS.
"""
import os
import re
import sys

import ratchet_rows as rows_lib

BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cost.baseline")
# THE CANDIDATES THE LAST ACCEPT SAW (`avra census --candidates`), so a run can name the new ones. A
# candidate is work, never a regression: a new one is said, never failed on.
CANDIDATES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cost.candidates")
CANDIDATES_HEAD = """\
# THE ZERO-COST CANDIDATES THE LAST `make cost-accept` SAW: each `<technique> <fn>` that stood in its
# technique's top sites (`avra census --candidates`, docs/ZERO_COST.md). `make cost` names every
# candidate this file lacks; a candidate is a registry row or a ticket at discovery.
"""
TOLERANCE_PPM = 500
HEAD = """\
# THE EXACT-COUNT BASELINE: what the census compiler does, cold, on each fixed workload of the pinned
# snapshot (`make cost`, tools/cost.sh, tools/cost_ratchet.py). Exact and machine-independent. A row
# more than 0.05% over FAILS the gate; a row only falls, through `make cost-accept`; a new snapshot is
# `COST_SNAPSHOT=<sha> make cost-accept`, which records the commit and every count.
"""
# Each census line the runtime prints at exit, and the counters it carries, in order.
PRINTED = (
    (r"rc: (\d+) retains, (\d+) releases, (\d+) reclaims", ("retains", "releases", "reclaims")),
    (r"rc: (\d+) empty lists made, (\d+) grown", ("empty_lists", "empty_grown")),
    (r"rc: (\d+) list reads, (\d+) list writes", ("list_reads", "list_writes")),
    (r"alloc: (\d+) boxes, (\d+) list buffers", ("boxes", "list_buffers")),
    (r"rc: (\d+) copies, (\d+) string compares", ("copies", "string_compares")),
    (r"rc: (\d+) opens of an empty literal", ("empty_opens",)),
)
# The queries a cold check worked out, its inputs aside, from the counts line `check --counts` prints;
# and the answers a warm run worked out again, from its `worked:` line.
QUERIES = re.compile(r"^counts: .*\bqueries_computed=(\d+)", re.M)
WORKED = re.compile(r"^worked: (\d+) answers here", re.M)
CENSUS = tuple(c for _, names in PRINTED for c in names)
COUNTERS = CENSUS + ("queries_computed", "worked")
# A fall this small is the build's own: a file it writes and reads back within the stamp window.
FALL_PPM = 50
ROW = re.compile(r"^(?P<w>[a-z][a-z0-9-]*) (?P<c>[a-z_]+) (?P<n>\d+)$")
SNAPSHOT = re.compile(r"^snapshot ([0-9a-f]{40})$", re.M)


def counts_of(text):
    """The census lines of one run -> {counter: n}."""
    got = {}
    for pattern, names in PRINTED:
        m = re.search("^" + pattern + "$", text, re.M)
        if m:
            got.update(zip(names, (int(g) for g in m.groups())))
    for counter, line in (("queries_computed", QUERIES), ("worked", WORKED)):
        m = line.search(text)
        if m:
            got[counter] = int(m[1])
    return got


def edited(text, kind, old, new):
    """`text` with one edit made: `old`, which stands in it once, becomes `new`; a `rename` renames the
    word `old` wherever it stands. Raises where the edit does not stand as written."""
    new = new.replace("\\n", "\n")
    if kind == "rename":
        word = re.compile(r"\b%s\b" % re.escape(old))
        if not word.search(text):
            raise ValueError("no `%s` to rename" % old)
        return word.sub(new, text)
    if text.count(old) != 1:
        raise ValueError("`%s` stands %d times, not once" % (old, text.count(old)))
    return text.replace(old, new, 1)


def measured(run_dir):
    """Every workload a run kept (`<name>.out`) -> {(workload, counter): n}."""
    rows = {}
    for f in sorted(os.listdir(run_dir)):
        if f.endswith(".out"):
            name = f[: -len(".out")]
            got = counts_of(open(os.path.join(run_dir, f), errors="replace").read())
            rows.update({(name, c): n for c, n in got.items()})
    return rows


def unprinted(now):
    """Each counter a run owed and printed no count for: every census counter of a cold workload, and
    the answers an edit's warm run worked out again."""
    owed = {}
    for workload, _ in now:
        owed[workload] = ("worked",) if workload.startswith("edit-") else CENSUS
    return ["cost: %s printed no %s" % (w, c) for w in sorted(owed) for c in owed[w] if (w, c) not in now]


def snapshot_of(text):
    m = SNAPSHOT.search(text)
    return m[1] if m else None


def read_baseline(text):
    return snapshot_of(text), rows_lib.read(text, ROW, ["w", "c"], "n")


def render(snapshot, rows):
    return HEAD + "snapshot %s\n" % snapshot + rows_lib.lines(rows)


def percent(old, new):
    return "%+.3f%%" % (100.0 * (new - old) / old) if old else "new"


def judge(now, base):
    """-> (failures, lowered) lines: each baseline row a run printed no count for, or measured past
    the tolerance; and each row a run measured under."""
    failed, fell = [], []
    for key in sorted(base):
        old = base[key]
        if key not in now:
            failed.append("cost: %s %s: the run printed no count (row %d)" % (key[0], key[1], old))
            continue
        new = now[key]
        if (new - old) * 1_000_000 > old * TOLERANCE_PPM:
            failed.append("cost: %s %s: %d -> %d (%s, over the %g%% tolerance)"
                          % (key[0], key[1], old, new, percent(old, new), TOLERANCE_PPM / 10000))
        elif (old - new) * 1_000_000 > old * FALL_PPM:
            fell.append("cost: %s %s fell: %d -> %d (%s) — `make cost-accept` records it"
                        % (key[0], key[1], old, new, percent(old, new)))
    return failed, fell


def accepted(now, base, same_snapshot):
    """The rows an accept writes: over the same snapshot each row falls to what was measured and none
    rises; over another, every row is what was measured."""
    return rows_lib.lowered(now, base) if same_snapshot else dict(now)


def candidates_of(text):
    """`candidate: <technique> <count> <fn> <where>` lines -> {(technique, fn): line}."""
    found = {}
    for line in text.splitlines():
        w = line.split(" ")
        if len(w) >= 4 and w[0] == "candidate:":
            found[(w[1], w[3])] = line[len("candidate: "):]
    return found


def recorded(text):
    """The record's `<technique> <fn>` lines -> their keys."""
    return {tuple(line.split(" ")[:2]) for line in text.splitlines() if line and not line.startswith("#") and len(line.split(" ")) >= 2}


def new_candidates(found, known):
    return ["cost: new candidate: %s" % found[k] for k in sorted(found) if k not in known]


def candidates_said(run_dir, accept):
    """The run's new candidates said; under an accept, the record rewritten to what it saw."""
    path = os.path.join(run_dir, "candidates.txt")
    if not os.path.exists(path):
        return
    found = candidates_of(open(path).read())
    known = recorded(open(CANDIDATES).read()) if os.path.exists(CANDIDATES) else set()
    for line in new_candidates(found, known):
        print(line)
    print("cost: %d candidates, %d new" % (len(found), len([k for k in found if k not in known])))
    if accept:
        open(CANDIDATES, "w").write(CANDIDATES_HEAD + "".join("%s %s\n" % k for k in sorted(found)))


def main(argv):
    if argv[1:] == ["--self-test"]:
        return self_test()
    if len(argv) == 6 and argv[1] == "--edit":
        path, kind, old, new = argv[2:]
        try:
            text = edited(open(path).read(), kind, old, new)
        except ValueError as e:
            print("cost: the %s edit of %s: %s" % (kind, path, e))
            return 1
        open(path, "w").write(text)
        return 0
    if len(argv) != 3 or argv[1] not in ("--judge", "--accept"):
        print(__doc__)
        return 2
    run_dir = argv[2]
    ran = open(os.path.join(run_dir, "snapshot")).read().strip()
    text = open(BASELINE).read() if os.path.exists(BASELINE) else ""
    pinned, base = read_baseline(text)
    now = measured(run_dir)
    if not now:
        print("cost: the run printed no counts — refusing to judge")
        return 1
    missing = unprinted(now)
    if missing:
        print("\n".join(missing))
        return 1
    if argv[1] == "--accept":
        same = ran == pinned
        if same:
            failed, _ = judge(now, base)
            if failed:
                print("\n".join(failed))
                print("cost: an accept never raises a row over the same snapshot")
                return 1
        open(BASELINE, "w").write(render(ran, accepted(now, base, same)))
        candidates_said(run_dir, True)
        print("cost: tools/cost.baseline recorded (snapshot %s)" % ran)
        return 0
    if ran != pinned:
        print("cost: the run measured snapshot %s, the baseline pins %s" % (ran, pinned))
        return 1
    failed, fell = judge(now, base)
    for line in fell + failed:
        print(line)
    print("cost: %d rows, %d over, %d fell" % (len(base), len(failed), len(fell)))
    candidates_said(run_dir, False)
    return 1 if failed else 0


def self_test():
    rows_lib.self_test()
    run = ("rc: 100 retains, 90 releases, 10 reclaims\nrc: 5 empty lists made, 1 grown\n"
           "rc: 1000 list reads, 200 list writes\nalloc: 50 boxes, 7 list buffers\n"
           "rc: 3 copies, 4 string compares\nrc: 2 opens of an empty literal\nmem: noise\n")
    got = counts_of(run)
    assert got == {"retains": 100, "releases": 90, "reclaims": 10, "empty_lists": 5, "empty_grown": 1,
                   "list_reads": 1000, "list_writes": 200, "boxes": 50, "list_buffers": 7,
                   "copies": 3, "string_compares": 4, "empty_opens": 2}, got
    assert set(got) == set(CENSUS)
    assert counts_of("counts: files_loaded=3 queries_computed=41 store_rows_written=41\n") == {"queries_computed": 41}
    assert counts_of("worked: 69 answers here; item_under 14\n") == {"worked": 69}
    # a noop's row of 0 fails at the first answer worked again
    assert judge({("edit-noop", "worked"): 1}, {("edit-noop", "worked"): 0})[0]
    # a fall inside the build's own jitter is not named
    assert judge({("w", "boxes"): 999_951}, {("w", "boxes"): 1_000_000}) == ([], [])
    # an edit stands once or is refused; a rename reaches every whole word and no part of one
    assert edited("a\nb\n", "body", "b", "c\\nd") == "a\nc\nd\n"
    for bad in ("x", "a"):
        try:
            edited("a a\n", "body", bad, "y")
            assert False, bad
        except ValueError:
            pass
    assert edited("f(x) f fg\n", "rename", "f", "g") == "g(x) g fg\n"
    sha = "a" * 40
    snap, rows = read_baseline(render(sha, {("w", "boxes"): 1000, ("w", "retains"): 10}))
    assert snap == sha and rows == {("w", "boxes"): 1000, ("w", "retains"): 10}
    # within the tolerance passes; one box past it fails, naming both numbers
    assert judge({("w", "boxes"): 100_050}, {("w", "boxes"): 100_000}) == ([], [])
    failed, _ = judge({("w", "boxes"): 100_051}, {("w", "boxes"): 100_000})
    assert failed == ["cost: w boxes: 100000 -> 100051 (+0.051%, over the 0.05% tolerance)"], failed
    # a fall passes and is named; a missing count fails
    failed, fell = judge({("w", "boxes"): 900}, {("w", "boxes"): 1000})
    assert failed == [] and "fell: 1000 -> 900" in fell[0]
    failed, _ = judge({}, {("w", "boxes"): 1000})
    assert "printed no count" in failed[0]
    # an accept over the same snapshot never raises; over another, it records what was measured
    assert accepted({("w", "boxes"): 1004}, {("w", "boxes"): 1000}, True) == {("w", "boxes"): 1000}
    assert accepted({("w", "boxes"): 900}, {("w", "boxes"): 1000}, True) == {("w", "boxes"): 900}
    assert accepted({("w", "boxes"): 1200}, {("w", "boxes"): 1000}, False) == {("w", "boxes"): 1200}
    assert unprinted({("edit-body", "worked"): 3}) == []
    assert unprinted({("check-cli", "queries_computed"): 3})[0] == "cost: check-cli printed no retains"
    # a candidate is keyed by its technique and fn; one the record lacks is said, by its line
    found = candidates_of("candidate: reuse-in-place 40 f packages/x.av:3\ncandidate: strided-list 9 g packages/y.av\n")
    assert set(found) == {("reuse-in-place", "f"), ("strided-list", "g")}
    assert recorded("# head\nreuse-in-place f\n") == {("reuse-in-place", "f")}
    assert new_candidates(found, {("reuse-in-place", "f")}) == ["cost: new candidate: strided-list 9 g packages/y.av"]
    print("cost_ratchet self-test: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
