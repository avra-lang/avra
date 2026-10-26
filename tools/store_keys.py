#!/usr/bin/env python3
"""A STORE KEY NAMES NO PLACE. Every key a row about a file or a program is filed under
goes through one derivation (`Workspace.file_key`, `Workspace.root_key`, packages.av),
which spells the file by its stored name, `package:relative/path`. A `node_key(` whose
parts list a path, a root, an entry or a directory as an element is a hand
list that folds where the checkout stands, and is refused. Counts what it read."""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DERIVATION = os.path.join("packages", "std-avrac", "src", "compiler", "packages.av")
PLACE = re.compile(r"[\[,]\s*(self\.root|[a-z_.]*\b(?:path|root|entry|dir))\s*[,\]]")
STRING = re.compile(r'"(?:[^"\\]|\\.)*"')


def refused(line):
    """Whether a source line builds a key from a place."""
    if "node_key(" not in line:
        return False
    parts = STRING.sub('""', line[line.index("node_key("):])
    return PLACE.search(parts) is not None


def sources():
    for base, dirs, files in os.walk(os.path.join(ROOT, "packages")):
        dirs[:] = [d for d in dirs if d not in ("tests", "build", "vendor") and not d.startswith(".")]
        for f in files:
            if f.endswith(".av"):
                yield os.path.join(base, f)


def self_test():
    assert refused('fn k(path: string) -> string { node_key(Stored.Unit, ["parts", path]) }')
    assert refused('node_key(Stored.Sig, [self.root, m.text()])')
    assert not refused('node_key(Stored.Unit, ["asks", okey])')
    assert not refused('node_key(Stored.Obj, ["entry", digest, tools.opt])')
    assert not refused('let x = path')
    assert not refused('node_key(Stored.Unit, ["const", obj_key_cached(self, store, m, path), name])')
    assert refused('node_key(Stored.Fp, ["manifest", self.root, under.named])')
    assert refused('node_key(Stored.Unit, ["kept", r.path, name])')


def main():
    self_test()
    bad = []
    read = 0
    for p in sources():
        rel = os.path.relpath(p, ROOT)
        if rel == DERIVATION:
            continue
        read += 1
        with open(p, encoding="utf-8") as fh:
            for n, line in enumerate(fh, 1):
                if refused(line):
                    bad.append(f"{rel}:{n}: {line.strip()}")
    if bad:
        print("store-keys: a key folds a place — derive it with `file_key`/`root_key` (packages.av):", file=sys.stderr)
        for b in bad:
            print("  " + b, file=sys.stderr)
        sys.exit(1)
    print(f"store-keys: {read} source(s), every node_key names no place")


if __name__ == "__main__":
    main()
