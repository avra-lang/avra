#!/usr/bin/env python3
"""EVERY HOOK A `Decls` HOLDS IS RELEASED WHEN THE TABLE IS LET GO.

A hook is a `Cell<fn(…) -> …>` field of `Decls`; it captures the workspace that
holds the table, so one `disarm` or `let_go` does not reset leaves a cycle
counting never frees, and every discarded attempt then stands beside the next.
This reads the struct's hook fields and the two fns that reset them, and
refuses a field neither sets.

    python3 tools/hooks_released.py
"""
import re
import sys

PATH = "packages/std-avrac/src/features/decls.av"


def block(text, head):
    """The text from `head` to its matching close brace."""
    start = text.index(head)
    open_at = text.index("{", start)
    depth = 0
    for i in range(open_at, len(text)):
        depth += {"{": 1, "}": -1}.get(text[i], 0)
        if depth == 0:
            return text[open_at:i]
    raise SystemExit(f"hooks-released: no closing brace after `{head}`")


def main():
    text = open(PATH).read()
    fields = re.findall(r"^\s+(\w+): Cell<fn\(", block(text, "type Decls = "), re.M)
    released = block(text, "fn disarm()") + block(text, "fn let_go(")
    missed = [f for f in fields if f"self.{f}.set(" not in released]
    for f in missed:
        print(f"hooks-released: `{f}` is a hook of Decls that neither `disarm` nor `let_go` resets")
    print(f"hooks-released: {len(fields)} hooks read, {len(missed)} never released")
    sys.exit(1 if missed or not fields else 0)


main()
