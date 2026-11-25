#!/usr/bin/env python3
"""The program layer's findings held to the old path's `check`, over the kinds the program layer holds.

  program_findings.py compare NEW OLD KINDS [--except FRAGMENT ...]

NEW is `tapes <pkg> --findings`'s stdout, OLD is `check <pkg>`'s stdout, KINDS is `tapes <pkg> --kinds`'s.
A finding is a rendered block, from its `error[kind]`/`warning[kind]` line to the next. OLD keeps only
the kinds in KINDS; a block whose location line names a FRAGMENT is dropped from both. Answers 0 when
the two are the same multiset of blocks, else 1 with each side's extra blocks.
"""
import re
import sys
from collections import Counter

HEADER = re.compile(r"^(?:warning|error)\[([a-z_.]+)\]")


def blocks(text):
    """Each rendered finding in `text`, as (kind, block)."""
    out, kind, lines = [], None, []
    for line in text.split("\n"):
        m = HEADER.match(line)
        if m:
            if kind is not None:
                out.append((kind, "\n".join(lines).rstrip("\n")))
            kind, lines = m.group(1), [line]
        elif kind is not None:
            lines.append(line)
    if kind is not None:
        out.append((kind, "\n".join(lines).rstrip("\n")))
    return out


def located_in(block, fragments):
    """Whether the block's location line names one of `fragments`."""
    where = block.split("\n")[1] if "\n" in block else ""
    return any(f in where for f in fragments)


def kept(found, kinds, fragments):
    return Counter(b for k, b in found if (kinds is None or k in kinds) and not located_in(b, fragments))


def compare(new_path, old_path, kinds_path, fragments):
    kinds = {l.strip() for l in open(kinds_path) if l.strip()}
    new = kept(blocks(open(new_path).read()), None, fragments)
    old = kept(blocks(open(old_path).read()), kinds, fragments)
    only_new, only_old = new - old, old - new
    for title, side in (("only on the program layer", only_new), ("only on the old path", only_old)):
        for b, n in side.items():
            print(f"--- {title} (x{n}):\n{b}\n")
    print(f"findings: program {sum(new.values())}, old {sum(old.values())}, "
          f"only-program {sum(only_new.values())}, only-old {sum(only_old.values())}")
    return 0 if not only_new and not only_old else 1


def main(argv):
    if len(argv) < 4 or argv[0] != "compare":
        sys.stderr.write(__doc__)
        return 2
    rest = argv[4:]
    fragments = [rest[i + 1] for i in range(len(rest) - 1) if rest[i] == "--except"]
    return compare(argv[1], argv[2], argv[3], fragments)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
