#!/usr/bin/env python3
"""Where the old path and the program layer differ over the sources std-avrac's specs ask.

`AVRA_SPEC_DIFFERENTIAL=1 build/avra test packages/std-avrac/<dir> > log` prints one block per
source whose diagnostics or run differ. This reads those logs and says, over the DISTINCT sources:
each kind the old path says and the layer doesn't, each the layer says and the old path doesn't,
each kind both say in different words, each reason the layer gives for not making a program the
old path runs, and each program the two run to different answers.

    python3 tools/spec_differential.py LOG... [--examples N] [--json FILE]
"""
import collections
import json
import re
import sys

BLOCK = re.compile(
    r"=====DIFF\n--SRC\n(.*?)\n--OLDK\n(.*?)\n--NEWK\n(.*?)\n--OLDRUN\n(.*?)\n--NEWRUN\n(.*?)\n=====END",
    re.S,
)
NOT_MADE = re.compile(r"ERR:not made on the program layer: (.*?), at ")


def kinds(said):
    return collections.Counter(line.split(":")[0] for line in said.split("\n") if line)


def blocks(paths):
    """Each differing source once: (source, old said, new said, old run, new run)."""
    seen = {}
    for path in paths:
        with open(path, errors="replace") as log:
            for block in BLOCK.findall(log.read()):
                seen.setdefault(block[0], block)
    return list(seen.values())


def tallied(found):
    missing, extra, worded, unmade = (collections.defaultdict(list) for _ in range(4))
    ran_apart = []
    for src, old, new, old_run, new_run in found:
        was, now = kinds(old), kinds(new)
        for kind in was - now:
            missing[kind].append(src)
        for kind in now - was:
            extra[kind].append(src)
        if was != now:
            continue
        if old != new:
            for kind in was:
                worded[kind].append(src)
            continue
        reason = NOT_MADE.match(new_run)
        if reason:
            unmade[re.sub(r"`[^`]*`", "`…`", reason.group(1))].append(src)
        elif old_run != new_run:
            ran_apart.append((src, old_run, new_run))
    return missing, extra, worded, unmade, ran_apart


def table(title, rows, examples):
    print(f"\n## {title}")
    for key, sources in sorted(rows.items(), key=lambda row: (-len(row[1]), row[0])):
        print(f"{len(sources):5} {key}")
        for src in sources[:examples]:
            print(f"        {src!r}")


def main(argv):
    paths, examples, out = [], 1, None
    args = iter(argv)
    for arg in args:
        if arg == "--examples":
            examples = int(next(args))
        elif arg == "--json":
            out = next(args)
        else:
            paths.append(arg)
    if not paths:
        print(__doc__)
        return 2
    found = blocks(paths)
    missing, extra, worded, unmade, ran_apart = tallied(found)
    print(f"{len(found)} distinct differing sources")
    table("OLD SAYS, LAYER SILENT (kind, distinct sources)", missing, examples)
    table("LAYER SAYS, OLD SILENT", extra, examples)
    table("SAME KINDS, OTHER WORDS", worded, examples)
    table("OLD RUNS, LAYER DOES NOT MAKE (the layer's reason)", unmade, examples)
    print(f"\n## BOTH RUN, TO DIFFERENT ANSWERS: {len(ran_apart)}")
    for src, old_run, new_run in ran_apart:
        print(f"        {src!r}\n            old {old_run!r}\n            new {new_run!r}")
    if out:
        with open(out, "w") as kept:
            json.dump(
                {
                    "sources": len(found),
                    "missing": {k: len(v) for k, v in missing.items()},
                    "extra": {k: len(v) for k, v in extra.items()},
                    "worded": {k: len(v) for k, v in worded.items()},
                    "unmade": {k: len(v) for k, v in unmade.items()},
                    "ran_apart": len(ran_apart),
                },
                kept,
                indent=1,
                sort_keys=True,
            )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
