#!/usr/bin/env python3
"""THE FAMILY ORDINALS ARE APPEND-ONLY.

A `Family` ordinal is a DURABLE address: kernel rows, kept caches and
witnesses are keyed by `ordinal`, and a family's fingerprint folds
that number. So the enum's declared order is a contract, not a
layout choice — the same law as "A NODE VARIANT IS APPENDED, NEVER
INSERTED" (CLAUDE.md), one ordinal space over.

`family_gap_voice` (compiler/workspace.av) catches a variant that was
ADDED without extending `family_at`/`family_count` — a MISSING
registration. It does NOT catch one that was MOVED: insert a variant
mid-enum and every later ordinal shifts, while `family_at` and
`ordinal` are hand matches that move together and stay consistent
with each other. The runtime self-check therefore passes, and only
records written under the OLD ordinals read the wrong family.

This keeper holds the order against `tools/families.order`: the live
enum must be exactly that list, plus appends at the end. An inserted,
moved, removed or renamed variant breaks the prefix and is refused
BEFORE it compiles.

THE SEAM FOR .148: when `Family` becomes a derived `@query` enum,
`live_family_order` reads the derived order instead — one function
body, and every check below is unchanged.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKSPACE = "packages/std-avrac/src/compiler/workspace.av"
ORDER_FILE = "tools/families.order"

def read(path):
    return open(os.path.join(ROOT, path)).read()


def enum_variants(text, name):
    """A `enum <name> { … }` block's variant names, in declared order.

    Comment content is dropped before reading, so a `}` inside a doc
    line cannot end the block early. A variant is the leading
    `UpperCamel` word of a line, so a payload variant keeps its
    position. Answers None when the enum is absent — a reader that
    found nothing must say so, never pass vacuously.
    """
    m = re.search(rf"\benum\s+{re.escape(name)}\s*\{{", text)
    if not m:
        return None
    depth = 1
    body = []
    i = m.end()
    while i < len(text) and depth > 0:
        if text[i] == "/" and i + 1 < len(text) and text[i + 1] == "/":
            j = text.find("\n", i)
            i = len(text) if j < 0 else j
            continue
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                break
        body.append(text[i])
        i += 1
    out = []
    for line in "".join(body).split("\n"):
        vm = re.match(r"\s*([A-Z][A-Za-z0-9_]*)", line)
        if vm:
            out.append(vm.group(1))
    return out


def live_family_order():
    """The live `Family` order — THE ONE SEAM .148 moves.

    Today the enum is hand-written in workspace.av. Once .148 derives
    `Family` as a `@query` enum, read that declaration's order here
    instead; `check` and `main` need no change.
    """
    return enum_variants(read(WORKSPACE), "Family")


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


# ── Fixtures: what the reader REFUSES and what it ACCEPTS ──

ENUM_CASE = """enum Family {
    Alpha
    /// a doc line with a } brace
    Beta
    Gamma
}"""

PARSE_CASES = [
    (ENUM_CASE, ["Alpha", "Beta", "Gamma"]),
    ("enum Other {\n    X\n}", None),               # absent enum -> None
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

def selftest():
    for text, want in PARSE_CASES:
        got = enum_variants(text, "Family")
        if got != want:
            sys.exit(f"families: parse self-test failed: {got!r} != {want!r}")
    for committed, live, refused in CHECK_CASES:
        got = check(committed, live) is not None
        if got != refused:
            sys.exit(f"families: check self-test failed on {committed} / {live}: "
                     f"refused={got}, want={refused}")


def main():
    selftest()
    live = live_family_order()
    if live is None:
        print(f"families: no `enum Family` in {WORKSPACE} — the reader examined nothing. "
              f"If .148 moved it to a derived @query enum, point live_family_order at that.")
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
    return 0


if __name__ == "__main__":
    sys.exit(main())
