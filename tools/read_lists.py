#!/usr/bin/env python3
"""NO ANSWER STANDS ON A LONG READ LIST, and the lists that do only shorten.

A saved answer is valid while every read it made still holds, so its read list is the
cost of asking whether it stands: an answer over 3,000 reads is a whole-program pass
wearing one cell, and an edit anywhere re-verifies it. `avra explain <package> --stats`
prints, for a cold derivation, each family's longest read list; this keeper runs it over
the compiler's own cli and holds each family under LIMIT.

A family still over LIMIT is DEBT, listed in tools/read_lists.ceiling as `Family ceiling`,
one per line. The file only shrinks: a listed family may not read more than its line says,
a family not listed may not pass LIMIT, and a line whose family fell under LIMIT is stale
and refused until pruned. A ceiling stands a tenth above the count it was set from, since a
list's length follows the sources it reads and a new file moves it a little; a pass that
cut the list moves the ceiling down with `--accept`.

    python3 tools/read_lists.py            # run the derivation and check
    python3 tools/read_lists.py --accept   # lower the ceilings, drop the paid ones
    python3 tools/read_lists.py --self-test
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CEILING = os.path.join(ROOT, "tools", "read_lists.ceiling")
PACKAGE = "packages/cli"
LIMIT = 3000
ROW = re.compile(r"^(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$")


def longest_by_family(text):
    """The `longest` column of a `--stats` table, by family."""
    found = {}
    for line in text.splitlines():
        m = ROW.match(line)
        if m:
            found[m.group(1)] = int(m.group(8))
    return found


def read_ceiling(text):
    """`Family longest` lines; comments and blanks aside."""
    ceil = {}
    for line in text.splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            name, value = line.split()
            ceil[name] = int(value)
    return ceil


def judged(longest, ceil):
    """Every refusal, in family order."""
    out = []
    for name in sorted(longest):
        at = longest[name]
        if name in ceil:
            if at > ceil[name]:
                out.append(f"{name}: its longest read list is {at}, over its ceiling {ceil[name]}")
            elif at <= LIMIT:
                out.append(f"{name}: {at} reads is under {LIMIT} — drop its line from tools/read_lists.ceiling (--accept)")
        elif at > LIMIT:
            out.append(f"{name}: its longest read list is {at}, over {LIMIT} — split the answer, never list it")
    for name in sorted(ceil):
        if name not in longest:
            out.append(f"{name}: listed in tools/read_lists.ceiling but no family answers it")
    return out


def margin(count):
    """A ceiling's room over the count it is set from."""
    return count + count // 10


def accepted(longest, ceil):
    """The ceiling file lowered: each debt at its current length with room, the paid ones gone."""
    return {n: min(margin(longest[n]), ceil[n]) for n in sorted(ceil) if n in longest and longest[n] > LIMIT}


def stats():
    """`explain --stats` over a cold store, the tree's own store set aside meanwhile."""
    store = os.path.join(ROOT, ".avra-cache")
    aside = store + ".read-lists"
    moved = os.path.isdir(store)
    if os.path.isdir(aside):
        sys.exit("read_lists: .avra-cache.read-lists stands from a run that did not finish — move it back first")
    if moved:
        os.rename(store, aside)
    try:
        run = subprocess.run(
            ["./avra", "explain", PACKAGE, "--stats"], cwd=ROOT, capture_output=True, text=True
        )
    finally:
        if os.path.isdir(store):
            shutil.rmtree(store)
        if moved:
            os.rename(aside, store)
    return run.stdout + run.stderr


def self_test():
    table = (
        "family          cells   served  computed    edges    p50    p99  longest\n"
        "Analysis          542    19003       542    36136     31    435      859\n"
        "Receivers           1    13616         1    55710  55710  55710    55710\n"
        "total           193830  6093490    177988  9586337\n"
    )
    got = longest_by_family(table)
    assert got == {"Analysis": 859, "Receivers": 55710}, got
    assert read_ceiling("# debt\nReceivers 55710  # whole pass\n\n") == {"Receivers": 55710}
    assert judged(got, {"Receivers": 55710}) == []
    assert judged(got, {"Receivers": 50000}) == ["Receivers: its longest read list is 55710, over its ceiling 50000"]
    assert judged(got, {}) == ["Receivers: its longest read list is 55710, over 3000 — split the answer, never list it"]
    assert "drop its line" in judged(got, {"Receivers": 55710, "Analysis": 900})[0]
    assert "no family answers it" in judged(got, {"Receivers": 55710, "Ghost": 4000})[0]
    assert accepted(got, {"Receivers": 70000, "Analysis": 900}) == {"Receivers": 61281}
    assert accepted(got, {"Receivers": 58000}) == {"Receivers": 58000}
    print("read_lists: self-test passed")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    text = stats()
    longest = longest_by_family(text)
    if not longest:
        print(text[-600:])
        sys.exit("read_lists: the derivation printed no read lists — nothing was examined")
    ceil = read_ceiling(open(CEILING).read()) if os.path.exists(CEILING) else {}
    if "--accept" in sys.argv:
        kept = accepted(longest, ceil)
        head = "".join(l for l in open(CEILING).read().splitlines(True) if l.startswith("#")) if os.path.exists(CEILING) else ""
        open(CEILING, "w").write(head + "".join(f"{n} {v}\n" for n, v in kept.items()))
        print(f"read_lists: {len(kept)} famil(ies) still over {LIMIT}")
        return
    refusals = judged(longest, ceil)
    debt = sum(1 for n, v in longest.items() if v > LIMIT)
    print(f"read_lists: {len(longest)} families examined over {PACKAGE}, {debt} over {LIMIT} (debt), {len(refusals)} refused")
    for r in refusals:
        print(f"  {r}")
    sys.exit(1 if refusals else 0)


if __name__ == "__main__":
    main()
