#!/usr/bin/env python3
"""EVERY WHOLE-PROGRAM READ IS A COUNTED SITE, and the count only falls.

A whole read asks a relation for ALL its rows (`decls.all_files()`,
`decls.all_decls()`, `Decl.all(db)`, `File.all(db)`, `.all_in(db)`): the
query that asks depends on every row, so one file's edit re-verifies it. They
reach one door, `Rows.seen_whole` (std-relation/src/rows.av), which the
compiler tallies exactly (`whole_reads`, `check --counts`, the warm-edit
ratchet). THIS keeper holds the other half: the SITES.

A site is a call of a whole verb in non-test compiler or CLI source. Each is
either LICENSED at its site, `// LICENSED whole.cold: <why>` on the line above
or the same line (a command or phase no warm check runs — the reason says
which), or listed in tools/whole_reads.baseline, one TAB-separated site per
line (file, source line trimmed; never a line number, so a move is no new
site). A site in neither fails. A license over no whole verb is stale, and one
with no reason is refused. The baseline only falls:

    python3 tools/whole_reads.py            # refuses a new site
    python3 tools/whole_reads.py --accept   # prunes what a fix made gone

A new whole verb is added to VERBS here, so the door cannot grow a side entry.
`Family.all()` (a collect enum, no argument) and the filesystem walk
`ws.all_files(dir)` (an argument) are not these verbs.
"""
import glob
import os
import re
import sys

import licence_families

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCOPE = ["packages/std-avrac/src", "packages/cli/src"]
BASELINE = "tools/whole_reads.baseline"
# A call of a verb that reads every row; a definition (`fn all_files(`) is no call.
VERBS = re.compile(r"\.all_files\(\)|\.all_decls\(\)|\.all_in\(|\b[A-Z][A-Za-z]*\.all\([^)\s]")
DEFINITION = re.compile(r"\bfn\s+all_(files|decls|in)\b|\bstatic\s+fn\s+all\b")
# The door's own bodies: the verbs `all_files()` and `all_decls()` wrap `File.all` and `Decl.all`.
# Their CALLERS are the sites, so the wrapping line is no second site.
DOOR = {("packages/std-avrac/src/features/decls_mint.av", "[file_info(r) for r in File.all(self.rows_db.get())]")}
LICENSE = re.compile(r"//\s*LICENSED\s+" + licence_families.id_pattern("whole.") + r"(:\s*(?P<why>.*\S))?")


def source_files(root):
    for scope in SCOPE:
        for path in sorted(glob.glob(os.path.join(root, scope, "**", "*.av"), recursive=True)):
            rel = os.path.relpath(path, root)
            if "/tests/" not in rel:
                yield rel


def sites(rel, text):
    """[(source line trimmed, licensed, why, line number)] for one file."""
    lines = text.splitlines()
    out = []
    for i, line in enumerate(lines):
        code = line.split("//")[0]
        if DEFINITION.search(code) or not VERBS.search(code) or (rel, line.strip()) in DOOR:
            continue
        near = [line] + ([lines[i - 1]] if i > 0 else [])
        lic = next((m for m in map(LICENSE.search, near) if m), None)
        out.append((line.strip(), lic is not None, (lic.group("why") or "") if lic else "", i + 1))
    return out


def stale_licenses(text):
    """Line numbers of a `whole.cold` license no whole verb sits under."""
    lines = text.splitlines()
    gone = []
    for i, line in enumerate(lines):
        if not LICENSE.search(line):
            continue
        here = [line.split("//")[0], lines[i + 1].split("//")[0] if i + 1 < len(lines) else ""]
        if not any(VERBS.search(c) and not DEFINITION.search(c) for c in here):
            gone.append(i + 1)
    return gone


def read_baseline(root):
    path = os.path.join(root, BASELINE)
    if not os.path.exists(path):
        return []
    rows = []
    for line in open(path):
        if line.strip() and not line.startswith("#"):
            f, _, src = line.rstrip("\n").partition("\t")
            rows.append((f, src))
    return rows


def judge(found, baseline):
    """(new, gone, refusals): found is [(file, line, licensed, why, n)]."""
    refusals = [
        "%s:%d: `// LICENSED whole.cold` names no reason" % (f, n) for f, _, lic, why, n in found if lic and not why
    ]
    counted = [(f, src) for f, src, lic, _, _ in found if not lic]
    pool = list(baseline)
    new = []
    for site in counted:
        if site in pool:
            pool.remove(site)
        else:
            new.append(site)
    return new, pool, refusals


HEADER = """\
# WHOLE-PROGRAM READS NOT YET LICENSED COLD, one TAB-separated site per line:
# its file and its own source line trimmed. This file only ever SHRINKS —
# `make whole-reads-accept` prunes what a fix made gone, and no path through it
# ADDS a line: a new whole read is narrowed to the rows it needs, or licensed
# `// LICENSED whole.cold: <why>` at its site (tools/whole_reads.py).
"""


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    found, stale = [], []
    for rel in source_files(ROOT):
        text = open(os.path.join(ROOT, rel)).read()
        found += [(rel, src, lic, why, n) for src, lic, why, n in sites(rel, text)]
        stale += ["%s:%d" % (rel, n) for n in stale_licenses(text)]
    new, gone, refusals = judge(found, read_baseline(ROOT))
    if "--accept" in argv:
        kept = [(f, s) for f, s in read_baseline(ROOT) if (f, s) not in gone]
        open(os.path.join(ROOT, BASELINE), "w").write(HEADER + "".join("%s\t%s\n" % row for row in sorted(kept)))
        print("whole_reads: --accept — %d site(s) kept, %d pruned, none added" % (len(kept), len(gone)))
        return 0
    bad = False
    for f, s in new:
        print("whole_reads: NEW SITE %s: %s" % (f, s))
        bad = True
    for r in refusals:
        print("whole_reads: %s" % r)
        bad = True
    for s in stale:
        print("whole_reads: STALE LICENSE %s: no whole verb under it" % s)
        bad = True
    if bad:
        print("whole_reads: REFUSED — narrow the read, or license it cold with its reason")
        return 1
    print("whole_reads: %d site(s) over %d file(s): %d licensed cold, %d counted (baseline %d, %d prunable)" % (
        len(found), len({f for f, *_ in found}), sum(1 for x in found if x[2]), sum(1 for x in found if not x[2]),
        len(read_baseline(ROOT)), len(gone)))
    return 0


def self_test():
    licence_families.selftest()
    def one(text):
        return sites("x.av", text)

    assert [s[0] for s in one("let a = self.decls.all_files()\n")] == ["let a = self.decls.all_files()"]
    assert one("fn all_files() -> List<FileInfo> {\n") == []  # a definition
    assert one("let f = Family.all()\n") == []  # a collect enum, no argument
    assert one("let f = ws.all_files(dir)\n") == []  # the filesystem walk
    assert len(one("[d for d in Decl.all(db)]\n")) == 1
    assert len(one("x.all_in(db)\n")) == 1
    assert one("// self.decls.all_files() in a comment\n") == []
    lic = one("// LICENSED whole.cold: the docs command\nlet a = Decl.all(db)\n")
    assert lic[0][1] and lic[0][2] == "the docs command"
    assert one("let a = Decl.all(db) // LICENSED whole.cold: docs\n")[0][1]
    bare = one("// LICENSED whole.cold\nlet a = Decl.all(db)\n")
    assert bare[0][1] and bare[0][2] == ""
    assert judge([("x", "s", True, "", 3)], [])[2], "a reasonless license is refused"
    assert stale_licenses("// LICENSED whole.cold: why\nlet a = 1\n") == [1]
    assert stale_licenses("// LICENSED whole.cold: why\nlet a = Decl.all(db)\n") == []
    new, gone, _ = judge([("x", "s", False, "", 1), ("x", "t", False, "", 2)], [("x", "s"), ("x", "u")])
    assert new == [("x", "t")] and gone == [("x", "u")]
    print("whole_reads: self-test passed — 13 fixtures")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
