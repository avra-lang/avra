#!/usr/bin/env python3
"""A template copy carries every fact its source node wore. Each table of
`SyntaxArena` (core/store.av) says in the comment above it how a copy
treats it: `copied by `verb`` (a verb core/rebuild.av calls on the
destination store) or `not copied: reason`. A table with neither is a
fact the copier forgets, and a forgotten fact leaves no mark at any site.
"""
import re, sys

STORE = "packages/std-avrac/src/core/store.av"
REBUILD = "packages/std-avrac/src/core/rebuild.av"
COPIED = re.compile(r"//\s*copied by `([a-z_]+)`")
NOT_COPIED = re.compile(r"//\s*not copied: \S")
TABLE = re.compile(r"^    ([a-z_]+): Cell<")


def arena_body(text):
    start = text.index("export type SyntaxArena = {")
    return text[start:text.index("\n}\n", start)].split("\n")


def tables(lines):
    """(name, the comment lines directly above it) for every Cell table."""
    out = []
    for i, line in enumerate(lines):
        m = TABLE.match(line)
        if not m:
            continue
        above = []
        j = i - 1
        while j >= 0 and lines[j].lstrip().startswith("//"):
            above.append(lines[j])
            j -= 1
        out.append((m.group(1), above))
    return out


def main():
    lines = arena_body(open(STORE).read())
    rebuild = open(REBUILD).read()
    bad = []
    seen = 0
    for name, above in tables(lines):
        seen += 1
        text = "\n".join(above)
        verbs = COPIED.findall(text)
        if not verbs and not NOT_COPIED.search(text):
            bad.append(f"{name}: no `copied by` or `not copied:` line above it")
            continue
        for v in verbs:
            if not re.search(r"\bdst\." + v + r"\(", rebuild):
                bad.append(f"{name}: `{v}` is not called on the destination in {REBUILD}")
    if bad:
        print("copy-tables: the copier's table law is broken:", file=sys.stderr)
        for b in bad:
            print("  " + b, file=sys.stderr)
        sys.exit(1)
    print(f"copy-tables: {seen} tables of SyntaxArena, each classified")


main()
