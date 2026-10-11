#!/usr/bin/env python3
"""THE PIPELINE DOCUMENT'S COMMANDS RESOLVE.

`docs/2026_10_11_THE_PIPELINE.md` is the one place the landing path,
Sprites, the watcher and the gates are written down for a reader who has
never seen this repo. A document is read as current long after the tree
has moved, so every command it names is held here:

  * `make <target>` inside a code span or fenced block must be a target
    the Makefile declares (a bare word in prose is not a command and is
    not read);
  * a `tools/<path>` anywhere in the document must be a path the tree
    holds.

A name that is deliberately recorded as ABSENT — an old design's script,
kept in the text so nobody repeats it — stands in `tools/pipeline_doc.allow`
with its reason, the way `tools/cited.allow` holds a historical path.

    python3 tools/pipeline_doc.py            # refuses, naming each miss
    python3 tools/pipeline_doc.py --self-test # the rules on fixtures

The document is the subject, so a missing document is a REFUSAL, not a
pass: a keeper that examined nothing has not passed.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join("docs", "2026_10_11_THE_PIPELINE.md")
ALLOW = os.path.join("tools", "pipeline_doc.allow")

# A make target: `target:` or `target: prereq`, never an assignment.
TARGET = re.compile(r"^([A-Za-z0-9_.\-/]+)\s*:(?!=)")
# The `.PHONY` list, joined across its backslash continuations first.
PHONY = re.compile(r"^\.PHONY:\s*(.*)$", re.M)
# A `make` command inside a code region: `make keepers`, `make census CMD=…`.
MAKE = re.compile(r"\bmake\s+([A-Za-z0-9_.\-/]+)")
# A tools path: `tools/work`, `tools/gate_changed.sh`.
TOOL = re.compile(r"tools/[A-Za-z0-9_.\-/]+")


def targets_in(makefile):
    """Every target the Makefile declares, `.PHONY` names included."""
    out = set()
    for line in makefile.splitlines():
        m = TARGET.match(line)
        if m:
            out.add(m.group(1))
    joined = re.sub(r"\\\n", " ", makefile)
    for m in PHONY.finditer(joined):
        out.update(m.group(1).split())
    return out


def code_regions(text):
    """The fenced blocks and inline spans — where a command can stand."""
    out = []
    for m in re.finditer(r"```[^\n]*\n(.*?)```", text, re.S):
        out.append(m.group(1))
    for m in re.finditer(r"`([^`\n]+)`", text):
        out.append(m.group(1))
    return out


def allowed():
    """Names the document may cite without the tree holding them."""
    out = {}
    path = os.path.join(ROOT, ALLOW)
    if not os.path.exists(path):
        return out
    for line in open(path):
        line = line.split("#")[0].strip()
        if line:
            name, _, reason = line.partition(":")
            out[name.strip()] = reason.strip()
    return out


def problems(doc, makefile, exempt, exists):
    """The commands in `doc` the tree does not hold.

    `doc` and `makefile` are text; `exempt` maps a name to its reason;
    `exists` answers whether a `tools/` path is held."""
    known = targets_in(makefile)
    bad = []
    for region in code_regions(doc):
        for name in MAKE.findall(region):
            if name not in known and name not in exempt:
                bad.append(f"`make {name}` is no target in the Makefile")
    seen = set()
    for name in TOOL.findall(doc):
        if name in seen or name in exempt:
            continue
        seen.add(name)
        if not exists(name):
            bad.append(f"`{name}` is not in the tree")
    return bad, len(known), len(seen)


def self_test():
    """Fixtures on the pure rule, no tree."""
    makefile = "gate:\n\t@true\n.PHONY: keepers gate\n"
    held = {"tools/work", "tools/gate_changed.sh"}
    exists = lambda p: p in held
    good = "Run `make gate` then `sh tools/work run make keepers`.\n"
    bad, _, _ = problems(good, makefile, {}, exists)
    assert not bad, f"fixture refused a good line: {bad}"
    bad, _, _ = problems("Run `make nope`.\n", makefile, {}, exists)
    assert any("nope" in b for b in bad), "a missing target passed"
    bad, _, _ = problems("See `tools/ghost.sh`.\n", makefile, {}, exists)
    assert any("ghost" in b for b in bad), "a missing tools path passed"
    bad, _, _ = problems("See `tools/ghost.sh`.\n", makefile, {"tools/ghost.sh": "historical"}, exists)
    assert not bad, "an exempt name was refused"
    bad, _, _ = problems("make a PR green.\n", makefile, {}, exists)
    assert not bad, "prose `make` was read as a command"
    print("pipeline-doc: self-test passed — 5 fixtures")


def main():
    if "--self-test" in sys.argv:
        self_test()
        return 0
    doc_path = os.path.join(ROOT, DOC)
    if not os.path.exists(doc_path):
        print(f"pipeline-doc: {DOC} is gone — the document is the subject", file=sys.stderr)
        return 1
    makepath = os.path.join(ROOT, "Makefile")
    bad, ntargets, npaths = problems(
        open(doc_path).read(),
        open(makepath).read(),
        allowed(),
        lambda p: os.path.exists(os.path.join(ROOT, p)),
    )
    if bad:
        print(f"pipeline-doc: {DOC} names commands the tree does not hold:", file=sys.stderr)
        for b in bad:
            print(f"    {b}", file=sys.stderr)
        return 1
    print(
        f"pipeline-doc: {DOC} — every command resolves "
        f"({ntargets} target(s) declared, {npaths} tools/ path(s) named)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
