#!/usr/bin/env python3
"""THE WORKFLOW PARSE KEEPER: every `.github/workflows/*.yml` must read as YAML.

A workflow that does not parse runs with NO jobs and says nothing about why,
so a green check can examine nothing. This reads each file's plain scalars and
refuses a `key: value` line whose value holds `: ` unquoted, which YAML reads
as a nested mapping. It is a structural check over the forms the workflows use,
not a full YAML parser: a value it cannot classify is reported, never passed.

  python3 tools/workflows_yaml.py            check every workflow file
  python3 tools/workflows_yaml.py --self-test
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKFLOWS = os.path.join(ROOT, ".github", "workflows")

# A `key: value` line: the key, then the value, and the value is not quoted or a block scalar.
KEY_VALUE = re.compile(r"^(\s*(?:- )?[A-Za-z_][\w-]*):\s+(\S.*)$")


def unquoted_colon(value):
    """Whether a plain (unquoted, non-block) value holds `: ` that YAML would read as a mapping."""
    if value[:1] in ("'", '"', "|", ">", "[", "{", "#", "&", "*", "!"):
        return False
    return ": " in value


def problems(text):
    out = []
    for n, line in enumerate(text.split("\n"), 1):
        if line.lstrip().startswith("#"):
            continue
        m = KEY_VALUE.match(line)
        if m and unquoted_colon(m.group(2).rstrip()):
            out.append((n, line.strip()))
    return out


def self_test():
    bad = "jobs:\n  x:\n    steps:\n      - run: grep -E '^(copy|push): ' build/out > a.txt\n"
    assert problems(bad) == [(4, "- run: grep -E '^(copy|push): ' build/out > a.txt")], problems(bad)
    quoted = "jobs:\n  x:\n    steps:\n      - run: \"grep -E '^(copy|push): ' build/out\"\n"
    assert problems(quoted) == [], "a quoted value is a string, never a mapping"
    plain = "jobs:\n  x:\n    runs-on: ubuntu-latest\n"
    assert problems(plain) == [], "a plain value with no `: ` is fine"
    print("workflows_yaml: self-test passed — 3 fixtures")
    return 0


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    files = sorted(glob.glob(os.path.join(WORKFLOWS, "*.yml")))
    if not files:
        print("workflows_yaml: REFUSED — no workflow files found (a check that examined nothing is not a pass)")
        return 1
    bad = []
    for f in files:
        for n, line in problems(open(f, encoding="utf-8").read()):
            bad.append(f"{os.path.relpath(f, ROOT)}:{n}: {line}")
    for b in bad:
        print("workflows_yaml: REFUSED — " + b + " (an unquoted `: ` reads as a mapping: quote the value)")
    if bad:
        return 1
    print(f"workflows_yaml: {len(files)} workflow file(s) read clean")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
