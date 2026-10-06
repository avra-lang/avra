#!/usr/bin/env python3
"""WHO ASKED FOR EACH PARSE. Reads an AVRA_QTRACE trace and, for every file
parsed (`Q parse <path>`), prints the queries open when it happened — the
chain of computes that reached it, outermost first.

    python3 tools/db_measure/parse_why.py <trace file> <families.av>

Only families asked through `Relation.ask` appear in the trace, so a chain
shows those frames alone. A file id is named by the path its own parse
printed, where one did.
"""
import sys
from collections import defaultdict
from graph import family_table, label_of


def main():
    table = family_table(sys.argv[2])
    stack, parses, path_of = [], [], {}
    with open(sys.argv[1], encoding="utf-8", errors="replace") as lines:
        for line in lines:
            part = line.rstrip("\n").split("\t")
            if part[0] != "Q" or len(part) < 3:
                continue
            if part[1] == "ask" and len(part) >= 5 and part[4] == "compute":
                stack.append((int(part[2]), int(part[3])))
            elif part[1] == "settle" and stack:
                stack.pop()
            elif part[1] == "parse":
                parses.append((part[2], list(stack)))
                if stack and label_of(table, stack[-1][0]) in ("Plain", "Parsed"):
                    path_of[stack[-1][1]] = part[2]

    def named(frame):
        f, a = frame
        name = label_of(table, f)
        file_keyed = table.get(f, ("", ""))[1] == "FileId"
        return "%s(%s)" % (name, path_of[a].rsplit("/packages/", 1)[-1] if file_keyed and a in path_of else a)

    times = defaultdict(int)
    for path, _ in parses:
        times[path] += 1
    print("parses: %d over %d files" % (len(parses), len(times)))
    for path, frames in parses:
        print("%s\n    <- %s" % (path.rsplit("/packages/", 1)[-1], " <- ".join(named(f) for f in reversed(frames)) or "(no query open)"))


if __name__ == "__main__":
    main()
