#!/usr/bin/env python3
"""A fingerprint tag NAMES a node kind: inside one fold space no two
kinds may wear one number, or their fingerprints are equal by
construction and every consumer reads two things as one.

AND A PARTS LIST IS FIXED ARITY. A flat concatenation of two
sequences has a boundary that MOVES: `f<A>(B)` and `f<A, B?>()`
spliced to one list and wore one fingerprint. Every variable-length
run folds through `fp_list` first, which is what this reader checks —
a `.concat` or a `flatten` standing in a parts list, with the nested
folds removed, is a run that never became one value.

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

SHARED = re.compile(r"(?<![A-Za-z0-9_])fp_list\(")

def tags_in(text, shared=True):
    """Every tag a file claims, as (number, line). `fp_list` is the
    SHARED fold: calling it mixes tag 105 into this file's space, so a
    caller claims it once — otherwise a local `fp(105, …)` and the
    shared fold would name two kinds with one number."""
    out = []
    for n, line in enumerate(text.split("\n"), 1):
        for m in PICK.finditer(line):
            out += [(int(m.group(1)), n), (int(m.group(2)), n)]
        without = PICK.sub("", line)
        out += [(int(m.group(1)), n) for m in TAG.finditer(without)]
        out += [(int(m.group(1)), n) for m in MARK.finditer(line)]
    if shared and "fn fp_list(" not in text:
        borrowed = SHARED.search(text)
        if borrowed:
            out.append((105, text.count("\n", 0, borrowed.start()) + 1))
    return out

def parts_of(text, at):
    """The text of the `fp(` call starting at `at`, to its balanced
    close — a run is not where the layout suggests, so count."""
    depth, j = 0, at
    while j < len(text):
        if text[j] == "(":
            depth += 1
        elif text[j] == ")":
            depth -= 1
            if depth == 0:
                return text[at:j + 1]
        j += 1
    return text[at:]

CALL = re.compile(r"(?<![A-Za-z0-9_])(fp|fp_list)\(")

def stripped(call):
    """The call's OWN parts — every nested fold removed, so a run
    inside `fp_list(...)` is not read as a run inside this list."""
    out, j = "", call.index("(") + 1
    while j < len(call):
        m = CALL.match(call, j)
        if m:
            j += len(parts_of(call, m.start()))
            continue
        out += call[j]
        j += 1
    return out

def splices_in(text):
    """Every `fp(` call whose own parts list splices a run, as
    (line, snippet) — and how many calls were read."""
    bad, seen = [], 0
    for m in re.finditer(r"(?<![A-Za-z0-9_])fp\(", text):
        call = parts_of(text, m.start())
        seen += 1
        own = stripped(call)
        if ".concat(" in own or "flatten(" in own:
            bad.append((text.count("\n", 0, m.start()) + 1, " ".join(call.split())[:90]))
    return bad, seen

SPLICE_CASES = [
    ("fp(1, [a, b])", 0),
    ("fp(1, [a].concat(bs))", 1),                      # a run spliced flat
    ("fp(1, [a, fp_list(bs.concat(cs))])", 0),         # the run folded first
    ("fp(1, flatten([[a], bs]))", 1),
    ("fp(1, [fp_list(xs), fp_list(ys.concat(zs))])", 0),
    ("fp_str(name).concat(x)", 0),                     # fp_str is not fp
    ("fp(1,\n  [a]\n    .concat(bs))", 1),             # a run over three lines
]

CASES = [
    ("fp(50, [])", [50]),
    ("fp( 7 ,[a])", [7]),
    ("self.restamp(s, 61)", [61]),
    ("fp(if hi == null { 55 } else { 61 }, [x])", [55, 61]),
    ("fp(tag, [x])", []),          # a variable tag is not a claim
    ("fp_str(name)", []),          # fp_str is not fp
    ("// fp(99, [])", [99]),       # a commented tag still reserves
    ("x = fp_list(xs)", [105]),    # the shared fold claims its tag here
    ("fn fp_list(p: List<int>) -> int { fp(105, p) }", [105]),
]

def selftest():
    for text, want in CASES:
        got = [n for n, _ in tags_in(text)]
        if sorted(got) != sorted(want):
            sys.exit(f"fingerprints: self-test failed on {text!r}: {got} != {want}")
    # BOTH SURFACES: what the reader refuses AND what it accepts.
    for text, want in SPLICE_CASES:
        got, _ = splices_in(text)
        if len(got) != want:
            sys.exit(f"fingerprints: splice self-test failed on {text!r}: {len(got)} != {want}")


def sources():
    """The compiler's files and the engine's: where a fingerprint is folded."""
    return [p for root in ("packages/std-avrac/src", "packages/std-relation/src/engine")
            for p in glob.glob(f"{root}/**/*.av", recursive=True)]


def free_report():
    """The next free tag in each file that claims any."""
    out = []
    for path in sorted(sources()):
        if "/tests/" in path:
            continue
        # a BORROWED tag is not this file's numbering, so it never
        # decides what is free here
        claimed = {t for t, _ in tags_in(open(path).read(), shared=False)}
        if claimed:
            out.append(f"{os.path.basename(path)} next free {max(claimed) + 1}")
    return " — " + ", ".join(out) if out else ""

def main():
    selftest()
    bad = 0
    folds = 0
    for path in sorted(sources()):
        if "/tests/" in path:
            continue
        text = open(path).read()
        spliced, read = splices_in(text)
        folds += read
        for line, snippet in spliced:
            bad += 1
            print(f"fingerprints: a run spliced into a parts list — {path}:{line}: {snippet}")
        seen = collections.defaultdict(list)
        for tag, line in tags_in(text):
            seen[tag].append(line)
        for tag in sorted(seen):
            if len(seen[tag]) > 1:
                bad += 1
                where = ", ".join(f"{path}:{l}" for l in seen[tag])
                print(f"fingerprints: tag {tag} claimed {len(seen[tag])} times — {where}")
    if bad:
        print(f"fingerprints: {bad} DEFECT(S) — a repeated tag makes two node kinds "
              f"fingerprint alike; a spliced run makes a payload's boundary move")
        return 1
    # THE KEEPER ANSWERS "WHAT IS FREE", so nobody has to grep for it.
    # A grep cannot see a COMPUTED tag — `fp(if … { 106 } else { 107 },
    # …)` contains no `fp(106` anywhere — so `grep -oE "fp\([0-9]+"`
    # reported 106 and 107 free while both were taken, and two lanes
    # picking a free number the same night is how tag 105 collided.
    # This reader already resolves the conditional spelling; asking it
    # is the only honest way to ask.
    print(f"fingerprints: every tag names one kind, and {folds} parts list(s) "
          f"are fixed arity" + free_report())
    return 0

sys.exit(main())
