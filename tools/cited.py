#!/usr/bin/env python3
"""THE NAMES THE DOCTRINE CITES RESOLVE — and that is ALL this asserts.

A law rots at its DECORATION, never at its sentence: an audit of 99
laws found 17 carrying something stale and 0 whose law was wrong. Of
the 17, FIVE were names a grep can find (`printed_value`, `bool_word`,
`balanced`, `tag_of(cx, v)`, "all in core/nodes.av") and TWELVE were
counts, line numbers and attributions no tool can see. So this keeper
reaches A THIRD of the rot, and its name says which third: it checks
CITATIONS, not doctrine. A keeper named for more than it asserts reads
as coverage the tree does not have.

SCOPE IS THE LIVE DOCTRINE, never the ledgers. CLAUDE.md and
DOGFOODING.md state what is true NOW, so a dead name there is a
defect. ROADMAP.md is dated receipts — an entry there is allowed to
describe the tree on the day it was written, and checking it would
demand edits that falsify the record.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCTRINE = ["CLAUDE.md", "DOGFOODING.md"]
SOURCES = ["packages", "tools", "runtime", "backend", "bootstrap", "Makefile", "avra"]
SKIP_DIR = {".git", "build", "node_modules", ".tasks", ".claude", ".pi"}
# THIS KEEPER DOES NOT READ ITSELF. A name counts as defined because
# the tree USES it, so a tool inside the scanned tree would whitelist
# every name it mentions — its own fixtures included, which is how the
# first draft passed a name it had invented.
SKIP_FILE = {"cited.py", "cited.allow"}
READ_EXT = {".av", ".c", ".h", ".py", ".sh", ".toml", ".ll", ".md", ""}

# A cited NAME: backticked, snake_case, at least one underscore — a
# single word (`int`, `match`) is a language word, not a citation.
NAME = re.compile(r"`([a-z][a-z0-9]*(?:_[a-z0-9]+)+)`")
# A cited PATH: backticked, with a known extension.
PATH = re.compile(r"`([a-z_][a-z0-9_./-]*\.(?:av|c|h|py|sh|ll|toml))`")
# A bare line citation, which decays on the next edit of that file.
LINE = re.compile(r"`?\b([a-z_][a-z0-9_./-]*\.(?:av|c|h|py|sh)):(\d+)")


def allowed():
    """Names OR PATHS the doctrine may cite without the tree defining
    or holding them, each with its reason. A NEGATIVE EXAMPLE names a
    shape the law refuses; a SHORTENING is prose naming half a symbol;
    a HISTORICAL PATH names a file since removed, whose incident the
    doctrine still teaches."""
    path = os.path.join(ROOT, "tools", "cited.allow")
    out = {}
    for line in open(path):
        line = line.split("#")[0].strip()
        if line:
            name, _, reason = line.partition(":")
            out[name.strip()] = reason.strip()
    return out


def tree_paths():
    """Every source path, relative to the root, read once."""
    out = []
    for base in SOURCES:
        p = os.path.join(ROOT, base)
        if os.path.isfile(p):
            out.append(base)
            continue
        for dirpath, dirnames, filenames in os.walk(p):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIR]
            for fn in filenames:
                out.append(os.path.relpath(os.path.join(dirpath, fn), ROOT))
    return out


def symbols():
    """Every lowercase word the tree defines or uses, read ONCE. A
    per-name grep over the tree costs minutes; one pass costs a second."""
    found, files = set(), 0
    word = re.compile(r"[a-z][a-z0-9_]*")
    for base in SOURCES:
        p = os.path.join(ROOT, base)
        if os.path.isfile(p):
            found.update(word.findall(open(p, errors="ignore").read()))
            files += 1
            continue
        for dirpath, dirnames, filenames in os.walk(p):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIR]
            for fn in filenames:
                if fn in SKIP_FILE:
                    continue
                if os.path.splitext(fn)[1] in READ_EXT:
                    found.update(word.findall(
                        open(os.path.join(dirpath, fn), errors="ignore").read()))
                    files += 1
    return found, files


def resolves(rel, tree):
    """A cited path, matched by its SEGMENTS IN ORDER — doctrine names a
    file by the parts a reader would search for (`std-sqlite/boundary.av`
    for `packages/std-sqlite/src/boundary.av`), skipping the middles
    that carry no meaning. Strict about the names, tolerant of the
    path. The first draft returned on the FIRST file of that basename
    and reported every `mod.av` but one as missing."""
    want = [seg for seg in rel.strip("./").split("/") if seg]
    for path in tree:
        have = path.split("/")
        i = 0
        for seg in have:
            if i < len(want) and seg == want[i]:
                i += 1
        if i == len(want) and have[-1] == want[-1]:
            return True
    return False


def cited(text):
    return set(NAME.findall(text)), set(PATH.findall(text))


def audit(defined, allow, tree):
    dead, files = [], 0
    for doc in DOCTRINE:
        text = open(os.path.join(ROOT, doc)).read()
        files += 1
        names, paths = cited(text)
        for n in sorted(names):
            if n not in defined and n not in allow:
                dead.append((doc, n, "names nothing in the tree"))
        for p in sorted(paths):
            if not resolves(p, tree) and p not in allow:
                dead.append((doc, p, "is not a file in the tree"))
        for m in LINE.finditer(text):
            dead.append((doc, m.group(0),
                         "cites a LINE, which the next edit of that file moves"))
    return dead, files


def selftest(defined, allow):
    """A KEEPER HAS TWO SURFACES. The refusal is tested by a dead name;
    the ACCEPTANCES need fixtures too, or a spelling nobody uses widens
    the keeper unseen (tools/idioms.py carried one for weeks)."""
    bad = []
    fake = "zz_no_such_symbol_anywhere"
    d, _ = cited(f"a law citing `{fake}` must be refused")
    if not d or fake not in d:
        bad.append("the matcher does not see a backticked snake_case name")
    if fake in defined:
        bad.append("the fixture name exists in the tree — pick another")
    # ACCEPTED 1: a name the tree defines.
    live = "type_stmt" if "type_stmt" in defined else None
    if live is None:
        bad.append("fixture `type_stmt` no longer exists — pick another live name")
    elif live in allow:
        bad.append("a live name sits in the allow file")
    # ACCEPTED 2: a name the allow file licenses.
    if not allow:
        bad.append("the allow file is empty — its spelling is untested")
    else:
        for name, reason in allow.items():
            if not reason:
                bad.append(f"`{name}` is allowed with no reason")
            if name in defined:
                bad.append(f"`{name}` is allowed AND defined — retire the licence")
    # A single word must NOT be read as a citation.
    plain, _ = cited("the word `int` is a type, not a citation")
    if plain:
        bad.append("a single word was read as a citation")
    return bad


def main():
    allow = allowed()
    defined, src_files = symbols()
    bad = selftest(defined, allow)
    if bad:
        print("cited: SELF-TEST FAILED — the keeper cannot be trusted:")
        for b in bad:
            print(f"  {b}")
        return 1
    dead, doc_files = audit(defined, allow, tree_paths())
    names, paths = set(), set()
    for doc in DOCTRINE:
        n, p = cited(open(os.path.join(ROOT, doc)).read())
        names |= n
        paths |= p
    if dead:
        print(f"cited: {len(dead)} citation(s) the tree cannot answer:")
        for doc, what, why in dead:
            print(f"  {doc}: `{what}` {why}")
        print("  fix the citation, or license it in tools/cited.allow with its reason.")
        return 1
    print(f"cited: {len(names)} name(s) and {len(paths)} path(s) resolve — "
          f"read {doc_files} doctrine file(s) against {src_files} source file(s); "
          f"{len(allow)} licensed.")
    print("cited: this checks CITATIONS, not doctrine — a count, a line number "
          "or an attribution is invisible to it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
