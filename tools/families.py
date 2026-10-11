#!/usr/bin/env python3
"""THE HAND-WRITTEN FAMILIES MAY ONLY FALL.

Every `@family(` marker in non-test std-avrac source is a family not
yet a `@query`. The count may only fall; `tools/families.ceiling`
holds the most it may be. A family converted to a `@query` lowers the
ceiling in the same PR.

THE ORDER CONTRACT IS RETIRED (DB 01e). `Family` is a `collect enum`
over the `@family` markers, ordered `by it.name`, so a family is keyed
by its NAME and declaration order is free. The old keeper held the
markers' ranks against `tools/families.order` on the belief that a
family ordinal was a durable address; it is not — nothing saved keys
by an ordinal (kept answers key on the query's stable name and code
hash) and no family fingerprint folds one. `tools/families.order` is
gone.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CEILING_FILE = "tools/families.ceiling"
SOURCE_ROOT = "packages/std-avrac/src"
HAND_WRITTEN = re.compile(r'^\s*@family\(', re.M)


def read(path):
    return open(os.path.join(ROOT, path)).read()


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
        return (f"families-left: {count} family marker(s) still wear `@family`, above the "
                f"ceiling {ceil} in {CEILING_FILE} — a family is converted to `@query`, "
                f"never added as a `@family`. The count may only fall.")
    return None


# ── Fixtures: what the reader ACCEPTS and what it REFUSES ──

# (count, ceiling, refused?) — the hand-written count may not rise.
CEILING_CASES = [
    (37, 37, False),                                      # at the ceiling
    (36, 37, False),                                      # fallen
    (38, 37, True),                                       # rose
]


def selftest():
    for count, ceil, refused in CEILING_CASES:
        got = ceiling_check(count, ceil) is not None
        if got != refused:
            sys.exit(f"families-left: ceiling self-test failed on {count} / {ceil}: "
                     f"refused={got}, want={refused}")


def main():
    selftest()
    ceil = ceiling()
    if ceil is None:
        print(f"families-left: {CEILING_FILE} holds no integer — the keeper examined nothing")
        return 1
    count = hand_written_count(ROOT)
    bad = ceiling_check(count, ceil)
    if bad:
        print(bad)
        return 1
    print(f"families-left: {count} still hand-written (@family), falling to 0 (ceiling {ceil})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
