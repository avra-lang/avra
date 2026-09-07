#!/usr/bin/env python3
"""A fingerprint tag NAMES a node kind: inside one fold space no two
kinds may wear one number, or their fingerprints are equal by
construction and every consumer reads two things as one.

A space is a file: core/nodes.av's patterns, expressions and
statements are ONE space because the folds mix them (`arm_fps`
flattens pattern and expression fingerprints into one list, a
statement folds its expression's, and `restamp` wraps a statement's).
The memo tags in workspace.av and receivers.av are their own spaces.
"""
import re, sys, os, glob, collections

TAG = re.compile(r"\bfp\(\s*(\d+)\s*,")
MARK = re.compile(r"\brestamp\(\s*\w+\s*,\s*(\d+)")
# `fp(if c { 55 } else { 61 }, ...)` — a tag chosen by a condition.
PICK = re.compile(r"\bfp\(\s*if\b[^,]*?\{\s*(\d+)\s*\}\s*else\s*\{\s*(\d+)\s*\}")

def tags_in(text):
    """Every tag a file claims, as (number, line)."""
    out = []
    for n, line in enumerate(text.split("\n"), 1):
        for m in PICK.finditer(line):
            out += [(int(m.group(1)), n), (int(m.group(2)), n)]
        stripped = PICK.sub("", line)
        out += [(int(m.group(1)), n) for m in TAG.finditer(stripped)]
        out += [(int(m.group(1)), n) for m in MARK.finditer(line)]
    return out

CASES = [
    ("fp(50, [])", [50]),
    ("fp( 7 ,[a])", [7]),
    ("self.restamp(s, 61)", [61]),
    ("fp(if hi == null { 55 } else { 61 }, [x])", [55, 61]),
    ("fp(tag, [x])", []),          # a variable tag is not a claim
    ("fp_str(name)", []),          # fp_str is not fp
    ("// fp(99, [])", [99]),       # a commented tag still reserves
]

def selftest():
    for text, want in CASES:
        got = [n for n, _ in tags_in(text)]
        if sorted(got) != sorted(want):
            sys.exit(f"fingerprints: self-test failed on {text!r}: {got} != {want}")


def free_report():
    """The next free tag in each file that claims any."""
    out = []
    for path in sorted(glob.glob("packages/std-avrac/src/**/*.av", recursive=True)):
        if "/tests/" in path:
            continue
        claimed = {t for t, _ in tags_in(open(path).read())}
        if claimed:
            out.append(f"{os.path.basename(path)} next free {max(claimed) + 1}")
    return " — " + ", ".join(out) if out else ""

def main():
    selftest()
    bad = 0
    for path in sorted(glob.glob("packages/std-avrac/src/**/*.av", recursive=True)):
        if "/tests/" in path:
            continue
        seen = collections.defaultdict(list)
        for tag, line in tags_in(open(path).read()):
            seen[tag].append(line)
        for tag in sorted(seen):
            if len(seen[tag]) > 1:
                bad += 1
                where = ", ".join(f"{path}:{l}" for l in seen[tag])
                print(f"fingerprints: tag {tag} claimed {len(seen[tag])} times — {where}")
    if bad:
        print(f"fingerprints: {bad} REPEATED tags — two node kinds wearing one number "
              f"fingerprint alike, so a consumer reads them as one")
        return 1
    # THE KEEPER ANSWERS "WHAT IS FREE", so nobody has to grep for it.
    # A grep cannot see a COMPUTED tag — `fp(if … { 106 } else { 107 },
    # …)` contains no `fp(106` anywhere — so `grep -oE "fp\([0-9]+"`
    # reported 106 and 107 free while both were taken, and two lanes
    # picking a free number the same night is how tag 105 collided.
    # This reader already resolves the conditional spelling; asking it
    # is the only honest way to ask.
    print("fingerprints: every tag names one kind" + free_report())
    return 0

sys.exit(main())
