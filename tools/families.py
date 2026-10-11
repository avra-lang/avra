#!/usr/bin/env python3
"""THE FAMILY ORDINALS ARE APPEND-ONLY.

A `Family` ordinal is a DURABLE address: kernel rows, kept caches and
witnesses are keyed by `ordinal`, and a family's fingerprint folds
that number. So the enum's declared order is a contract, not a
layout choice — the same law as "A NODE VARIANT IS APPENDED, NEVER
INSERTED" (CLAUDE.md), one ordinal space over.

THE MECHANISM MOVED TO THE COLLECT (.148): `Family` is a `collect
enum` over the `@family(rank, …)` markers, so a MISSING variant or a
rank gap is refused by the compiler itself (`dense` demands exactly
0..N, and every match over `Family` must spell the new variant). This
keeper still holds the order against `tools/families.order`: the
markers' RANK order must be that list plus appends at the end, so a
rank EDIT that shifts every later ordinal is refused before it
compiles — the move the old hand matches stayed consistent with, and
only kept-cache records noticed.

This keeper holds the order against `tools/families.order`: the live
enum must be exactly that list, plus appends at the end. An inserted,
moved, removed or renamed variant breaks the prefix and is refused
BEFORE it compiles.

THE LIVE ORDER IS THE MARKERS' RANKS. `Family` is a `collect enum`
over the `@family(rank, …)` markers in compiler/families/families.av
(.148 landed); the collect orders by each marker's rank, so sorting
the markers by rank IS the enum's order.

THE HAND-WRITTEN COUNT falls to 0 (.181): every `@family(` marker in
non-test std-avrac source is a family not yet a `@query`. The count
may only fall; `tools/families.ceiling` holds the most it may be.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAMILIES = "packages/std-avrac/src/compiler/families/families.av"
ORDER_FILE = "tools/families.order"
CEILING_FILE = "tools/families.ceiling"
SOURCE_ROOT = "packages/std-avrac/src"
HAND_WRITTEN = re.compile(r'^\s*@family\(', re.M)

def read(path):
    return open(os.path.join(ROOT, path)).read()


MARKER = re.compile(
    r'@family\(\s*(\d+)\s*,\s*"[^"]*"\s*,\s*"[^"]*"\s*\)\s*\n\s*type\s+([A-Za-z_][A-Za-z0-9_]*)'
)


def marker_order(text):
    """The `@family(rank, …)` markers' names, in RANK order.

    `Family` is the collect over these markers by `it.mark.args[0]`,
    so sorting the markers by their rank IS the collected enum's
    order. Answers None when no marker is found — a reader that
    examined nothing must say so, never pass vacuously.
    """
    found = [(int(rank), name) for rank, name in MARKER.findall(text)]
    if not found:
        return None
    return [name for _, name in sorted(found)]


def live_family_order():
    """The live `Family` order — the markers' rank order."""
    return marker_order(read(FAMILIES))


def committed_order():
    """`tools/families.order` — one name per line, `#` and blanks
    ignored. An empty file is a keeper that examined nothing, refused
    below rather than passed."""
    out = []
    for line in read(ORDER_FILE).split("\n"):
        name = line.split("#")[0].strip()
        if name:
            out.append(name)
    return out


def check(committed, live):
    """None when `live` is `committed` plus appends at the end, else
    the refusal naming what moved and why ordinals are durable."""
    if len(live) < len(committed):
        gone = ", ".join(committed[len(live):])
        return (f"families: the enum holds {len(live)} variant(s) but {ORDER_FILE} names "
                f"{len(committed)} — {gone} was REMOVED. A family ordinal is durable; a "
                f"removal shifts every later one.")
    for i, want in enumerate(committed):
        if live[i] != want:
            return (f"families: Family's order changed at ordinal {i} — {ORDER_FILE} names "
                    f"`{want}`, the enum names `{live[i]}`. A family variant is APPENDED, "
                    f"never inserted or moved: every later ordinal shifts, and records keyed "
                    f"by ordinal read the wrong family.")
    return None


def hand_written_count(root):
    """`@family(` markers in non-test std-avrac source: the families not
    yet `@query`. Test trees hold fixtures, not families, and are skipped."""
    total = 0
    for dirpath, dirnames, filenames in os.walk(os.path.join(root, SOURCE_ROOT)):
        dirnames[:] = [d for d in dirnames if d != "tests"]
        for name in filenames:
            if name.endswith(".av"):
                total += len(HAND_WRITTEN.findall(read(os.path.join(dirpath, name))))
    return total


def ceiling():
    """`tools/families.ceiling` — one integer, the most markers may remain."""
    text = read(CEILING_FILE).strip()
    return int(text) if text.isdigit() else None


def ceiling_check(count, ceil):
    """None when `count` does not rise above `ceil`, else the refusal."""
    if count > ceil:
        return (f"families: {count} family marker(s) still wear `@family`, above the "
                f"ceiling {ceil} in {CEILING_FILE} — a family is converted to `@query`, "
                f"never added as a `@family`. The count may only fall.")
    return None


# ── Fixtures: what the reader REFUSES and what it ACCEPTS ──

MARKER_CASE = """@family(2, "FileId", "Parsed")
type Parsed = {}

/// a doc line with a } brace
@family(0, "FileId", "SourceFile")
type Source = {}

@family(1, "int", "Manifest")
type Manifest = {}
"""

PARSE_CASES = [
    (MARKER_CASE, ["Source", "Manifest", "Parsed"]),
    ("type Other = {}\n", None),               # no marker -> None
]

# (committed, live, refused?) — both surfaces of the same rule.
CHECK_CASES = [
    (["A", "B", "C"], ["A", "B", "C"], False),            # unchanged
    (["A", "B", "C"], ["A", "B", "C", "D"], False),       # append at the end
    (["A", "B", "C"], ["A", "X", "B", "C"], True),        # INSERTED mid-enum
    (["A", "B", "C"], ["A", "C", "B"], True),             # MOVED
    (["A", "B", "C"], ["A", "B"], True),                  # REMOVED
    (["A", "B", "C"], ["X", "B", "C"], True),             # RENAMED
]

# (count, ceiling, refused?) — the hand-written count may not rise.
CEILING_CASES = [
    (37, 37, False),                                      # at the ceiling
    (36, 37, False),                                      # fallen
    (38, 37, True),                                       # rose
]

def selftest():
    for text, want in PARSE_CASES:
        got = marker_order(text)
        if got != want:
            sys.exit(f"families: parse self-test failed: {got!r} != {want!r}")
    for committed, live, refused in CHECK_CASES:
        got = check(committed, live) is not None
        if got != refused:
            sys.exit(f"families: check self-test failed on {committed} / {live}: "
                     f"refused={got}, want={refused}")
    for count, ceil, refused in CEILING_CASES:
        got = ceiling_check(count, ceil) is not None
        if got != refused:
            sys.exit(f"families: ceiling self-test failed on {count} / {ceil}: "
                     f"refused={got}, want={refused}")


def main():
    selftest()
    live = live_family_order()
    if live is None:
        print(f"families: no `@family` marker in {FAMILIES} — the reader examined nothing.")
        return 1
    committed = committed_order()
    if not committed:
        print(f"families: {ORDER_FILE} names no family — the keeper examined nothing")
        return 1
    bad = check(committed, live)
    if bad:
        print(bad)
        return 1
    extra = len(live) - len(committed)
    print(f"families: {len(committed)} committed ordinal(s) in order, "
          f"{len(live)} variant(s) read" + (f", {extra} appended" if extra else ""))
    ceil = ceiling()
    if ceil is None:
        print(f"families: {CEILING_FILE} holds no integer — the keeper examined nothing")
        return 1
    count = hand_written_count(ROOT)
    bad = ceiling_check(count, ceil)
    if bad:
        print(bad)
        return 1
    print(f"families: {count} still hand-written (@family), falling to 0 (ceiling {ceil})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
