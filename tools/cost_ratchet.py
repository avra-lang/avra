#!/usr/bin/env python3
"""THE EXACT-COUNT GATE: what the compiler DOES on fixed workloads, counted by the census runtime.

    cost_ratchet.py --judge <dir>      judge a `tools/cost.sh` run against tools/cost.baseline
    cost_ratchet.py --accept <dir>     record a run: rows fall to what it measured; a run over another
                                       snapshot records that snapshot and every row as measured; a
                                       part's run, over the pinned snapshot, records its own rows alone
    cost_ratchet.py --rows <dir>       a run's rows, as tools/cost.baseline writes them
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
# THE STD PACKAGES THE SNAPSHOT'S ANSWERS SHIP A VERDICT FOR, as the baseline's run found them: a run
# whose list lacks one fails, naming it, since a package that loses its verdict is one today's
# compiler refuses over the snapshot, and the laid row then measures laws the user's never asks.
VERDICTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cost.verdicts")


def verdicts_lost(run_dir):
    """The packages the baseline's verdicts name that this run's don't, where the run made answers."""
    path = os.path.join(run_dir, "verdicts")
    if not os.path.exists(path) or not os.path.exists(VERDICTS):
        return []
    now = set(open(path).read().split())
    then = set(l for l in open(VERDICTS).read().split("\n") if l and not l.startswith("#"))
    return sorted(then - now)


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
    # the runtime's accounted high-water mark: what the run held at once, in its own boxes
    (r"mem: peak (\d+) MB in all", ("peak_mb",)),
)
# The queries a cold check worked out, its inputs aside, from the counts line `check --counts` prints;
# and the answers a warm run worked out again, from its `worked:` line.
QUERIES = re.compile(r"^counts: .*\bqueries_computed=(\d+)", re.M)
WORKED = re.compile(r"^worked: (\d+) answers here", re.M)
# THE PASS LEDGER's deterministic columns (`--passes --passes-rows`, std-program/src/pass_ledger.av):
# each pass's asks, its asks per unit and per item an edit moved, in thousandths, then its re-checks
# (answers checked against a kept record and kept) and re-checks per item moved — a pass whose work
# per unit rises is over its row as any counter is. Its times are shown, never rows. Six fields: a
# field added here is added to ledger_rows (std-program/src/pass_ledger.av) and the self-test together.
PASS_ROW = re.compile(r"^pass-row\t([a-z-]+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)$", re.M)
CENSUS = tuple(c for _, names in PRINTED for c in names)
COUNTERS = CENSUS + ("queries_computed", "worked")
# A fall this small is the build's own: a file it writes and reads back within the stamp window.
FALL_PPM = 50
# a workload's name may hold an underscore, as an edit's kind does (`edit-added_after`)
ROW = re.compile(r"^(?P<w>[a-z][a-z0-9_-]*) (?P<c>[a-z_]+) (?P<n>\d+)$")
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
    for p, asks, per_unit, per_moved, rechecks, rechecks_per_moved in PASS_ROW.findall(text):
        name = "pass_" + p.replace("-", "_")
        got[name + "_asks"] = int(asks)
        got[name + "_per_unit"] = int(per_unit)
        got[name + "_per_moved"] = int(per_moved)
        got[name + "_rechecks"] = int(rechecks)
        got[name + "_rechecks_per_moved"] = int(rechecks_per_moved)
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


# THE WORK A WARM EDIT DOES, not only the answers it works out again: each edit's run keeps its whole
# census (`edit-<kind>.census`), and these of its counters are its rows beside `worked` — a warm edit
# that does more per answer, with no more answers, is no longer under the gate.
WARM_COUNTERS = ("boxes", "retains", "releases", "list_writes", "peak_mb")


def measured(run_dir):
    """Every workload a run kept (`<name>.out`, and each edit's `edit-<kind>.census`) -> {(workload,
    counter): n}."""
    rows = {}
    for f in sorted(os.listdir(run_dir)):
        text = None
        if f.endswith(".out"):
            name = f[: -len(".out")]
            got = counts_of(open(os.path.join(run_dir, f), errors="replace").read())
            rows.update({(name, c): n for c, n in got.items()})
        elif f.startswith("edit-") and f.endswith(".census"):
            name = f[: -len(".census")]
            got = counts_of(open(os.path.join(run_dir, f), errors="replace").read())
            rows.update({(name, c): got[c] for c in got if c in WARM_COUNTERS or c.startswith("pass_")})
    return rows


def run_part(run_dir):
    """-> (the part a run measured, the workloads it measured): every row of those, and only those, is
    judged; a run that names none is the whole run of an older tools/cost.sh."""
    try:
        part = open(os.path.join(run_dir, "part")).read().strip()
        names = {line.strip() for line in open(os.path.join(run_dir, "workloads")) if line.strip()}
    except OSError:
        return "all", {k[0] for k in measured(run_dir)} | {k[0] for k in read_baseline(open(BASELINE).read())[1]}
    return part, names


def unprinted(now):
    """Each counter a run owed and printed no count for: every census counter of a cold workload, and
    the answers an edit's warm run worked out again; a ledger's run (`ledger-<workload>`) is counted by
    no census, and owes only the pass rows it printed."""
    owed = {}
    for workload, _ in now:
        if workload.startswith("ledger-"):
            owed[workload] = ()
        else:
            owed[workload] = ("worked",) + WARM_COUNTERS if workload.startswith("edit-") else CENSUS
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


def rows_said(run_dir):
    """A run's rows, as tools/cost.baseline writes them, over the snapshot it measured: what a gate's
    verdict carries, so a row is read off the run that measured it. -> 0."""
    print(render(open(os.path.join(run_dir, "snapshot")).read().strip(), measured(run_dir)), end="")
    return 0


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
    if len(argv) == 4 and argv[1] == "--same":
        return same_warm(argv[2], argv[3])
    if len(argv) == 3 and argv[1] == "--rows":
        return rows_said(argv[2])
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
    part, ran_workloads = run_part(run_dir)
    # A PART IS ACCEPTED OVER THE PINNED SNAPSHOT ALONE: its workloads' rows are recorded and every
    # other row stands as it was; a new snapshot records every row, so only the whole run moves it
    if argv[1] == "--accept" and part != "all" and ran != pinned:
        print("cost: an accept over another snapshot records every row, and this run measured the %s part alone" % part)
        return 1
    others = {k: n for k, n in base.items() if k[0] not in ran_workloads}
    base = {k: n for k, n in base.items() if k[0] in ran_workloads}
    missing = unprinted(now) + ["cost: %s printed no counts" % w for w in sorted(ran_workloads) if not any(k[0] == w for k in now)]
    if missing:
        print("\n".join(missing))
        return 1
    lost = verdicts_lost(run_dir)
    if lost and not (argv[1] == "--accept" and ran != pinned):
        for name in lost:
            print("cost: the snapshot's %s ships no verdict, as it did when the baseline was recorded: "
                  "today's compiler refuses it over the snapshot — move the snapshot" % name)
        return 1
    if argv[1] == "--accept":
        same = ran == pinned
        if same:
            failed, _ = judge(now, base)
            if failed:
                print("\n".join(failed))
                print("cost: an accept never raises a row over the same snapshot")
                return 1
        open(BASELINE, "w").write(render(ran, {**others, **accepted(now, base, same)}))
        made = os.path.join(run_dir, "verdicts")
        if os.path.exists(made):
            open(VERDICTS, "w").write("# the std packages the snapshot's answers ship a verdict for (tools/cost_ratchet.py)\n" + open(made).read())
        # a part's run classifies only its own sites, and a ledger's none: the record is the whole run's
        candidates_said(run_dir, part == "all")
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


# A WARM ROW HOLDS when two compilers that differ in nothing the work reads move it by no more than a
# tenth of the tolerance: text of another length hashes to other buckets, a few hundred operations in
# tens of millions, never a margin the gate's own tolerance would lose; an answer ordered by hash (an
# owner flipped, a count doubled) moves it by far more, and fails.
STABLE_PPM = TOLERANCE_PPM // 10


def same_warm(a_dir, b_dir):
    """Two warm runs of compilers that differ in nothing the work reads (tools/cost_stable.sh): every
    edit's row within STABLE_PPM of the other, the answers worked out again exactly; each row that
    moved said, by how much. -> 0 when every row holds."""
    a = {k: n for k, n in measured(a_dir).items() if k[0].startswith("edit-")}
    b = {k: n for k, n in measured(b_dir).items() if k[0].startswith("edit-")}
    keys = sorted(set(a) | set(b))
    unheld = []
    for k in keys:
        old, new = a.get(k), b.get(k)
        if old == new:
            continue
        ppm = abs(new - old) * 1_000_000 / old if old and new is not None else None
        held = ppm is not None and k[1] != "worked" and ppm <= STABLE_PPM
        print("cost: %s %s: %s -> %s (%s)%s" % (k[0], k[1], old if old is not None else "-", new if new is not None else "-",
                                               "%.1f ppm" % ppm if ppm is not None else "absent", "" if held else " — NOT HELD"))
        if not held:
            unheld.append(k)
    print("cost: %d warm rows, %d moved, %d past %d ppm or an answer moved" % (len(keys), len([k for k in keys if a.get(k) != b.get(k)]), len(unheld), STABLE_PPM))
    return 1 if unheld or not a else 0


def self_test():
    rows_lib.self_test()
    run = ("rc: 100 retains, 90 releases, 10 reclaims\nrc: 5 empty lists made, 1 grown\n"
           "rc: 1000 list reads, 200 list writes\nalloc: 50 boxes, 7 list buffers\n"
           "rc: 3 copies, 4 string compares\nrc: 2 opens of an empty literal\nmem: peak 12 MB in all\n"
           "mem:   list boxes    peak      9 MB, now      0 MB\nmem: noise\n")
    got = counts_of(run)
    assert got == {"retains": 100, "releases": 90, "reclaims": 10, "empty_lists": 5, "empty_grown": 1,
                   "list_reads": 1000, "list_writes": 200, "boxes": 50, "list_buffers": 7,
                   "copies": 3, "string_compares": 4, "empty_opens": 2, "peak_mb": 12}, got
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
    # every row a run measures reads back, an edit's kind with an underscore among them
    every = {("edit-added_after", "worked"): 42, ("ledger-edit-added_after", "pass_tape_asks"): 7}
    assert read_baseline(render(sha, every))[1] == every
    # a peak one MB over a row of a thousand fails: a held list is caught at the first MB it adds
    failed, _ = judge({("w", "peak_mb"): 1001}, {("w", "peak_mb"): 1000})
    assert failed == ["cost: w peak_mb: 1000 -> 1001 (+0.100%, over the 0.05% tolerance)"], failed
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
    # an edit owes the answers it worked out again and the work its census counted
    whole = {("edit-body", "worked"): 3}
    whole.update({("edit-body", c): 1 for c in WARM_COUNTERS})
    assert unprinted(whole) == []
    assert unprinted({("edit-body", "worked"): 3}) == ["cost: edit-body printed no %s" % c for c in WARM_COUNTERS]
    # an edit's census is read for its warm rows; a back-edit's and the settle's are not rows
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        census = "rc: 7 retains, 6 releases, 1 reclaims\nrc: 1000 list reads, 200 list writes\nalloc: 50 boxes, 4 list buffers\nmem: peak 30 MB in all\n"
        for f, text in (("edit-body.out", "worked: 3 answers here; x 3\n"), ("edit-body.census", census), ("back-body.census", census), ("settle.census", census)):
            open(os.path.join(d, f), "w").write(text)
        got = measured(d)
        assert got == {("edit-body", "worked"): 3, ("edit-body", "boxes"): 50, ("edit-body", "retains"): 7,
                       ("edit-body", "releases"): 6, ("edit-body", "list_writes"): 200, ("edit-body", "peak_mb"): 30}, got
        assert same_warm(d, d) == 0
    assert unprinted({("check-cli", "queries_computed"): 3})[0] == "cost: check-cli printed no retains"
    # a ledger's run owes no census counter; its pass rows are its rows
    assert unprinted({("ledger-edit-body", "pass_tape_asks"): 4}) == []
    assert counts_of("pass-row\ttape\t12\t3000\t0\t5\t2500\n") == {"pass_tape_asks": 12, "pass_tape_per_unit": 3000, "pass_tape_per_moved": 0,
                                                              "pass_tape_rechecks": 5, "pass_tape_rechecks_per_moved": 2500}
    # a row of the old four fields binds nothing: a ledger and its ratchet move together
    assert counts_of("pass-row\ttape\t12\t3000\t0\n") == {}
    # a candidate is keyed by its technique and fn; one the record lacks is said, by its line
    found = candidates_of("candidate: reuse-in-place 40 f packages/x.av:3\ncandidate: strided-list 9 g packages/y.av\n")
    assert set(found) == {("reuse-in-place", "f"), ("strided-list", "g")}
    assert recorded("# head\nreuse-in-place f\n") == {("reuse-in-place", "f")}
    assert new_candidates(found, {("reuse-in-place", "f")}) == ["cost: new candidate: strided-list 9 g packages/y.av"]
    print("cost_ratchet self-test: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
