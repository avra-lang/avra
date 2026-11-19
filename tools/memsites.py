#!/usr/bin/env python3
"""Names the allocation sites an AVRA_MEM_STATS report prints.

    python3 tools/memsites.py build/avra report.txt

Each `mem:   site 0x…` line gains the fn that holds the address, read
from the binary's own symbol table, so a Linux run needs no `atos`.
"""
import bisect
import re
import subprocess
import sys


def symbols(binary):
    out = subprocess.run(["nm", binary], capture_output=True, text=True, check=True).stdout
    rows = sorted(
        (int(p[0], 16), p[2])
        for p in (line.split() for line in out.splitlines())
        if len(p) == 3 and p[1] in "tTwW"
    )
    return [r[0] for r in rows], [r[1] for r in rows]


def plain(name):
    name = re.sub(r"\$([0-9A-F]{2})", lambda m: chr(int(m.group(1), 16)), name)
    name = re.sub(r"~/[^~]*/src/", "", name)
    return name.removeprefix("av_")[:150]


def main(binary, report):
    starts, names = symbols(binary)
    for line in open(report):
        m = re.search(r"site (0x[0-9a-f]+)", line)
        if not m:
            continue
        at = int(m.group(1), 16)
        i = bisect.bisect_right(starts, at) - 1
        print(f"{line.rstrip()[5:]}  {plain(names[i])}+{at - starts[i]}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
