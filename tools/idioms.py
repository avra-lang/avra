#!/usr/bin/env python3
"""THE IDIOM BAR.

Three laws make backsliding structurally impossible:

  1. THE BASELINE IS A LIST OF SITES, NEVER A COUNT. A new violation
     fails even when an old one was fixed in the same commit — the
     old tool compared totals, so a net-zero swap was invisible.
  2. THIS TOOL CANNOT ADD TO THE BASELINE. `--accept` only PRUNES
     sites that are gone. There is no path that grows the debt list,
     so the number can only fall. The old tool's licensed-exception
     path was "edit the pinned number", which is how a ratchet
     becomes theatre.
  3. A LICENSE LIVES AT THE SITE. Genuinely-idiomatic-impossible
     code carries `// LICENSED I3: a stack, not a map` on or just
     above the line. Reviewers see the reason where the code is,
     forever — not as an integer in a file nobody reads.

So a new violation has exactly two honest exits: write the
idiomatic form, or annotate it with a reason.

A FOURTH law keeps the rules from rotting: every I-code in
DOGFOODING.md must have a matcher here or an entry in UNRATCHETED
with its reason. The registry can never again outrun the ratchet.
"""
import collections, os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = ["packages/std-avrac/src", "packages/cli/src"]
BASELINE = os.path.join(ROOT, "tools", "idioms.baseline")
SKIP = ("spec_test",)

# ── Matchers. Each yields (line_index, matched_text). Multi-line
# matchers exist because the COMMON formatting of a smell spans
# lines — the old single-line greps caught the rare shape and
# reported success. ──

def line_rx(pattern):
    p = re.compile(pattern)
    def f(lines):
        for i, l in enumerate(lines):
            if p.search(l):
                yield i, l.strip()
    return f

def block_end(lines, start):
    """Index of the `}` closing the block opened on `start`."""
    indent = len(lines[start]) - len(lines[start].lstrip())
    for j in range(start + 1, min(len(lines), start + 60)):
        s = lines[j]
        if s.strip() == "}" and len(s) - len(s.lstrip()) == indent:
            return j
    return -1

def push_loop(lines):
    """A `for` whose whole body is one `push` — that loop is a MAP.
    BOTH forms: the body on its own lines, and the whole loop on one.
    The multi-line matcher that replaced the old line-grep dropped
    the one-line form and hid 14 sites for as long as it stood."""
    for i, l in enumerate(lines):
        if re.match(r"\s*for .+ in .+\{\s*[a-z_]+\.push\(.*\}\s*$", l):
            yield i, l.strip()
            continue
        if not re.match(r"\s*for .+ in .+\{\s*$", l):
            continue
        end = block_end(lines, i)
        body = [b.strip() for b in lines[i + 1:end] if b.strip()] if end > 0 else []
        if len(body) == 1 and re.match(r"[a-z_]+\.push\(", body[0]):
            yield i, l.strip()

def emit_then_error(lines):
    """emit-then-intern(Error) — the `spoken` tail, spelled out."""
    for i, l in enumerate(lines):
        if re.search(r"\.emit\(", l):
            for j in range(i + 1, min(len(lines), i + 8)):
                if re.search(r"intern\(Type\.Error\)", lines[j]):
                    yield i, l.strip()
                    break
                if re.match(r"\s*(fn |})", lines[j]):
                    break

def bracket_ritual(lines):
    """push … work … pop on ONE name: that is a bracket fn (I15)."""
    for i, l in enumerate(lines):
        m = re.match(r"\s*([a-z_]+)\.push\(", l)
        if not m:
            continue
        name = m.group(1)
        for j in range(i + 1, min(len(lines), i + 14)):
            if re.search(rf"\b{name}\.pop\(\)", lines[j]):
                yield i, l.strip()
                break

def seen_accumulator(lines):
    """`mut seen` + contains + push: duplicate detection that is a
    POSITION law when the list is already in hand (I16)."""
    for i, l in enumerate(lines):
        if re.match(r"\s*mut seen\b", l):
            window = "\n".join(lines[i:i + 14])
            if ".contains(" in window and ".push(" in window:
                yield i, l.strip()

def index_walk(lines):
    """`for j in 0..xs.length` that then indexes `xs[j]` — that walk
    is `for (j, x) in xs.enumerate()`, which hands over both."""
    for i, l in enumerate(lines):
        m = re.search(r"for ([a-z_]+) in 0\.\.([a-z_.]+)\.length", l)
        if not m:
            continue
        j, coll = m.group(1), m.group(2)
        end = block_end(lines, i)
        body = "\n".join(lines[i + 1:end if end > 0 else i + 8])
        if re.search(rf"{re.escape(coll)}\[{j}\]", body):
            yield i, l.strip()

def uncounted_refusal(lines):
    """A refusal test asserting only `contains` — the shape that lets
    a CASCADE hide behind a message that happens to appear."""
    for i, l in enumerate(lines):
        if not re.search(r'then "', l):
            continue
        block = "\n".join(lines[i + 1:i + 10]).split('        then ')[0]
        if ".report().contains(" in block and "diagnostics.length" not in block:
            yield i, l.strip()

def unmutated_mut(lines):
    """`mut` that nothing ever mutates — the reader is told to expect
    a change that never comes."""
    for i, l in enumerate(lines):
        m = re.match(r"\s*mut ([a-z_][a-z_0-9]*)(: [^=]+)? = ", l)
        if not m:
            continue
        name = m.group(1)
        rest = []
        for j in range(i + 1, len(lines)):
            if re.match(r"(export )?fn ", lines[j]):
                break
            rest.append(lines[j])
        body = "\n".join(rest)
        if not (re.search(rf"\b{name} *=[^=]", body)
                or re.search(rf"\b{name}\.(push|pop|set|insert|clear|sort|reverse)\(", body)):
            yield i, l.strip()

def registry_catchall(lines):
    """A match where TWO OR MORE variants answer is a REGISTRY, and a
    registry ending in `_ ->` silently forgets the NEXT variant —
    exactly how `let_name` dropped For's counter. One answering arm is
    a PROJECTION: its contract pins the answer for variants that do
    not exist yet, and the catch-all is honest there."""
    for i, l in enumerate(lines):
        if not re.search(r"match .+\{\s*$", l):
            continue
        depth = len(l) - len(l.lstrip())
        arms, catch = 0, False
        for j in range(i + 1, min(len(lines), i + 40)):
            s = lines[j]
            if s.strip() == "}" and len(s) - len(s.lstrip()) == depth:
                break
            # Only THIS match's arms count: a nested `when`'s own
            # catch-all sits deeper and is not this match's business.
            if len(s) - len(s.lstrip()) != depth + 4:
                continue
            if re.match(r"\.[A-Za-z]", s.strip()):
                arms += 1
            if s.strip().startswith("_ ->"):
                catch = True
        if catch and arms >= 2:
            yield i, l.strip()

def fn_body(lines, start):
    """The lines of the fn opened at `start`, triple-quoted regions
    dropped (a template's braces are text, not structure)."""
    head = lines[start]
    if head.rstrip().endswith("}"):
        return [head]
    # Triple-quoted text is kept for USAGE (a template reads its
    # params through `${name}`) but never counted for DEPTH, since
    # its braces are prose.
    out, depth, in_text = [], 0, False
    for j in range(start, len(lines)):
        l = lines[j]
        out.append(l)
        if l.count('\"\"\"') % 2 == 1:
            in_text = not in_text
            continue
        if in_text:
            continue
        # Braces inside string literals AND comments are prose, not
        # structure: the lexer compares against "{" as data, and a
        # doc line may quote a `}`.
        bare = re.sub(r'"(\\.|[^"\\])*"', '""', l)
        bare = re.sub(r"//.*$", "", bare)
        depth += bare.count("{") - bare.count("}")
        if j > start and depth <= 0:
            break
    return out

def dead_parameter(lines):
    """A parameter nothing reads — the signature lies about what the
    fn needs, and every call site carries the lie."""
    for i, l in enumerate(lines):
        m = re.match(r"(?:export )?fn ([a-z_]+)\((.*)\)", l)
        if not m or "(" not in l:
            continue
        params = [p.strip().split(":")[0].strip()
                  for p in m.group(2).split(",") if ":" in p]
        body = "\n".join(fn_body(lines, i)[1:]) or l[l.index(")") + 1:]
        for p in params:
            if p == "self" or p.startswith("_"):
                continue
            if not re.search(rf"\b{re.escape(p)}\b", body):
                yield i, f"{l.strip()[:60]} [{p}]"

# bs2 MERGES a module's files into one bundle, so an import in one
# file serves every sibling: unused-import analysis is per MODULE
# (directory), never per file. scan() fills this before each file.
MODULE_BODY = {"text": ""}

def unused_import(lines):
    """A name imported and never used ANYWHERE in its module. bs2
    checks neither direction, so imports are hand-kept truth."""
    for i, l in enumerate(lines):
        m = re.match(r"^use [a-z@][\w.@]*\.\{(.+)\}$", l.strip())
        if not m:
            continue
        for name in (n.strip() for n in m.group(1).split(",")):
            if name and not re.search(rf"\b{re.escape(name)}\b", MODULE_BODY["text"]):
                yield i, f"{l.strip()[:50]} [{name}]"

# bs2 does NOT check a pattern's payload ARITY: `.A(_, _)` compiles
# against a three-payload variant and silently binds the wrong
# things. Node facts grow, so this is the guarantee our doctrine
# assumes and the compiler never gives — enforced here instead.
VARIANT_ARITY = {}

def enum_arities(text):
    """variant -> payload count, for every enum declared in `text`."""
    out = {}
    for m in re.finditer(r"^(?:export )?enum \w+ \{(.*?)^\}", text, re.S | re.M):
        for v in re.finditer(r"^ {4}([A-Z]\w*)(\((.*?)\))?\s*$", m.group(1), re.M):
            args = v.group(3)
            out.setdefault(v.group(1), set()).add(
                0 if not args else len([a for a in args.split(",") if a.strip()]))
    return out

def written_arity(text, i):
    """How many payloads the group starting at text[i] == '(' writes."""
    depth, commas, seen = 0, 0, False
    while i < len(text):
        c = text[i]
        if c == '"':
            seen, i = True, i + 1
            while i < len(text) and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c in "([{":
            depth, seen = depth + 1, depth > 0
        elif c in ")]}":
            depth -= 1
            if depth == 0:
                return commas + 1 if seen else 0
        elif c == "," and depth == 1:
            commas += 1
        elif not c.isspace():
            seen = True
        i += 1
    return None

def stale_arity(lines):
    """A variant pattern or construction writing the WRONG number of
    payloads. Only names with ONE arity tree-wide are judged."""
    text = "\n".join(lines)
    known = {v: set(a) for v, a in VARIANT_ARITY.items()}
    for v, arities in enum_arities(text).items():
        known.setdefault(v, set()).update(arities)
    for m in re.finditer(r"\.([A-Z]\w*)\(", text):
        arities = known.get(m.group(1))
        if not arities or len(arities) != 1:
            continue
        wrote = written_arity(text, m.end() - 1)
        want = next(iter(arities))
        if wrote is not None and wrote != want:
            yield text[:m.start()].count("\n"), f".{m.group(1)}( wrote {wrote}, declares {want}"

# A nullable opened with `!` again and again is a value the code
# already knows it has. CLAUDE.md's style rule settles it: a `let`
# earns its place when the value is read more than once.
BARE_UNWRAP = re.compile(r"(?<![.\w])([a-z_][a-z0-9_]*)!")

def repeated_unwrap(lines):
    """One nullable LOCAL forced open 3+ times in a fn — guard once,
    bind once, and read the name. A `mut` accumulator is not this
    smell: it changes every turn, so there is no one value to bind."""
    hits = []

    def scan(start, body):
        if start is None or not body:
            return
        text = "\n".join(body)
        accumulators = set(re.findall(r"\bmut ([a-z_][a-z0-9_]*)", text))
        for name, n in collections.Counter(BARE_UNWRAP.findall(text)).items():
            if n >= 3 and name not in accumulators:
                hits.append((start, f"{lines[start].strip()[:46]} [{name}! x{n}]"))

    start, body = None, []
    for i, l in enumerate(lines):
        if re.match(r"\s*(export )?fn ", l):
            scan(start, body)
            start, body = i, []
        elif start is not None:
            body.append(l)
    scan(start, body)
    for h in hits:
        yield h

# A STRING's `.length` is `strlen` in the runtime — O(length), every
# time it is asked. Re-asking inside a loop makes the loop quadratic.
# A LIST's `.length` is a field read, so only string-shaped receivers
# are the smell; the rule looks for the names our scanners use.
STRING_LEN_LOOP = re.compile(
    r"while [^{]*\b(s|src|a|b|text|name|source)\.length\b")

def restrlen(lines):
    """A loop condition that re-measures a STRING's length. Hoist it:
    `let n = s.length` before the loop, then test `i < n`."""
    for i, l in enumerate(lines):
        if STRING_LEN_LOOP.search(l):
            yield i, l.strip()

def duplicated(pattern, minimum=2):
    """Text repeated within one file — a name waiting to be given.
    Comment lines are skipped: a doc quoting the message it documents
    is documentation, not a second copy."""
    p = re.compile(pattern)
    def f(lines):
        seen = {}
        for i, l in enumerate(lines):
            if l.lstrip().startswith("//"):
                continue
            for m in p.findall(l):
                seen.setdefault(m, []).append((i, l.strip()))
        for text, hits in seen.items():
            if len(hits) >= minimum:
                for i, l in hits:
                    yield i, l
    return f

# Rules restricted to product code, with the reason. A test may
# violate any OTHER rule as freely as product code can.
PRODUCT_ONLY = {
    "I11": "a repeated fixture in a test is not a message that can drift",
    "I12": "a fixture built twice in a test is the test being explicit",
}
TESTS_ONLY = {"I20": "it is a law about how a REFUSAL is asserted"}

RULES = {
    "I3":  (push_loop,
            "a for-loop whose body is one push — that is a comprehension (or concat)"),
    "I4":  (line_rx(r"mut [a-z_]+: *[A-Za-z][A-Za-z<>, ]*\? *= *null"),
            "a nullable flag local — is this scan a find/index_of?"),
    "I7":  (line_rx(r"\[[a-z_][\w.]*\.length - 1\]"),
            "last-element index arithmetic — `xs.last()!`"),
    "I9":  (line_rx(r"\.index != |\.index == "),
            "a hand-rolled type-id comparison — the agreement law is `types_disagree`"),
    "I11": (duplicated(r'"[a-z][^"]{20,}"'),
            "a long string duplicated in one file — shared messages are fns"),
    "I13": (line_rx(r"([a-z_]+\.[a-z_]+\(([a-z_]+)\)).*\1"),
            "the same projection computed twice on one line — bind it"),
    "I14": (emit_then_error,
            "emit-then-intern(Error) — that pair is `spoken(cx, d)`"),
    "I15": (bracket_ritual,
            "a push/…/pop ritual — that is a bracket fn taking a thunk"),
    "I18": (line_rx(r"[a-z_]+_of\(.*\) *\?\?"),
            "a payload the dispatch GUARANTEES, papered over with a default — "
            "absence here is a DEFECT: `lower_defect(cx, e, ...)`"),
    "I12": (duplicated(r"[A-Z][a-zA-Z]+ \{ [a-z_]+: [^{}]* \}"),
            "an identical struct literal written twice — name its constructor"),
    "I24": (unused_import,
            "a name imported and never used in its MODULE — bs2 checks neither "
            "direction, so imports are hand-kept truth"),
    "I23": (dead_parameter,
            "a parameter nothing reads — the signature lies, and every call site "
            "carries the lie"),
    "I22": (registry_catchall,
            "2+ variants answer, so this is a REGISTRY — a catch-all here forgets "
            "the NEXT variant; spell the arms (or-runs keep it affordable)"),
    "I19": (index_walk,
            "an index walk over a list — `for (j, x) in xs.enumerate()` hands over both"),
    "I20": (uncounted_refusal,
            "a refusal test with no diagnostics COUNT — a cascade can hide behind it"),
    "I21": (unmutated_mut,
            "a `mut` nothing mutates — say `let`"),
    "I25": (stale_arity,
            "a variant pattern with the WRONG payload count — bs2 accepts it "
            "silently and binds the wrong things"),
    "I27": (restrlen,
            "a STRING's `.length` re-measured in a loop condition — "
            "that is `strlen` per iteration; hoist it"),
    "I26": (repeated_unwrap,
            "one nullable local forced open 3+ times — guard once, bind once, "
            "and read the name"),
    "I16": (seen_accumulator,
            "a seen-accumulator — a dup is `xs.index_of(x) < j` over enumerate"),
}

UNRATCHETED = {
    "I1":  "the accumulator DECLARATION is a weak proxy: stacks, folds, range\n"
           "           fills and enumerate walks all declare one. I3 matches the real\n"
           "           smell — a loop whose whole body is one push — and catches every\n"
           "           map I1 did, without 42 false positives",
    "I2":  "the evaluated-payload chain died with the eval collapse; no sites can exist",
    "I8":  "the spelled ritual and the only legitimate way to USE stmt_value are\n"
           "           textually identical — every hit was the verb's own body or a\n"
           "           site needing the id afterward. The review round hunts it",
    "I5":  "the remaining folds are duplicate DETECTION (they emit on the dup)",
    "I6":  "head-plus-tail builds are subsumed by I1 and I3",
    "I10": "name->value if-ladders are too varied to grep — the review round hunts them",
    "I17": "a name serving two masters is semantic — no text pattern can see it",
}

# A rule that cannot fire is worse than no rule: it reports success
# forever. Every matcher must catch its own specimen, checked on every
# run — this caught I18 shipping with a regex that could not span a
# nested call.
SPECIMENS = {
    "I3":  [["for x in xs {", "    out.push(x)", "}"],
            ["    for x in xs { out.push(x) }"],
            ["    for (j, x) in xs.enumerate() { out.push(x) }"]],
    "I4":  [["    mut best: Thing? = null"],
            ["    mut hit: List<int>? = null"],
            ["    mut seen: Map<string, int>? = null"]],
    "I7":  [["    let v = xs[xs.length - 1]"],
            ["    let v = a.b[a.b.length - 1]"],
            ["    let v = self.items[self.items.length - 1]"]],
    "I9":  [["    if a.index != b.index { }"], ["    if a.index == b.index { }"]],
    "I11": [['    let a = "a message long enough to be shared"',
             '    let b = "a message long enough to be shared"']],
    "I12": [['    let a = Span { lo: lo, hi: hi }', '    let b = Span { lo: lo, hi: hi }']],
    "I13": [["    let ok = cx.shape_at(e) && cx.shape_at(e)"]],
    "I14": [["    cx.emit(d)", "    cx.intern(Type.Error)"]],
    "I15": [["    v.push(name)", "    let f = go()", "    let _ = v.pop()"]],
    "I16": [["    mut seen: List<string> = []", "    if seen.contains(x) { }", "    seen.push(x)"]],
    "I18": [["    cx.emit(Ins.ConstBool(dst, truth_of(cx.store.expr(e)) ?? false))"],
            ['    let v = text_of(node) ?? ""']],
    "I19": [["    for j in 0..args.length {", "        let a = args[j]", "    }"]],
    "I20": [['        then "it refuses" {', '            let a = analyze_source("x")',
             '            a.report().contains("nope")', "        }"]],
    "I21": [["    mut registry = new_type_registry()", "    registry.intern(t)"]],
    "I22": [["    match s {", "        .A(x) -> x,", "        .B(y) -> y,", "        _ -> null,", "    }"]],
    "I23": [["fn f(a: int, b: int) -> int {", "    a + a", "}"]],
    "I24": [["use core.{Span}"]],
    "I25": [["enum E {", "    A(x: int, y: int)", "}", "    match e {", "        .A(_) -> 1,", "    }"]],
    "I27": [["    while i < s.length {"], ["    while j <= b.length {"],
            ["    while i < src.length && p(i) {"]],
    "I26": [["fn f(x: int?) -> int {", "    if x == null { return 0 }",
             "    x! + x! + x!", "}"]],
}

def selftest():
    """Every rule catches EVERY specimen, or the tool refuses to run.

    One specimen proves a matcher is alive; it does not prove its
    REACH. Four rules shipped blind spots that a single specimen
    passed straight over — I7 could not see a dotted receiver, I3
    could not see a one-line loop, I4 could not see a generic with
    two parameters, and I26 counted field unwraps as locals. A rule
    claims a SHAPE, so every spelling of that shape belongs here."""
    dead = []
    for code, (matcher, _) in RULES.items():
        specimens = SPECIMENS.get(code)
        if specimens is None:
            dead.append(f"{code} has no specimen")
            continue
        for spec in specimens:
            if not list(matcher(spec)):
                dead.append(f"{code}'s matcher misses `{' / '.join(spec)[:52]}`")
    return dead

def sources():
    for base in SRC:
        for path in glob.glob(os.path.join(ROOT, base, "**", "*.av"), recursive=True):
            if not any(s in path for s in SKIP):
                yield path

def licensed(lines, i, code):
    """A license lives AT the site: on the line or just above it."""
    for j in range(max(0, i - 2), i + 1):
        if re.search(rf"LICENSED {code}\b", lines[j]):
            return True
    return False

def scan():
    """Every unlicensed site, as stable fingerprints."""
    # Module bodies, built once: every sibling's non-import lines.
    bodies = {}
    for path in sources():
        d = os.path.dirname(path)
        if d not in bodies:
            bodies[d] = "\n".join(
                "\n".join(l for l in open(s).read().split("\n")
                          if not l.strip().startswith("use "))
                for s in glob.glob(os.path.join(d, "*.av")))

    for path in sources():
        for v, arities in enum_arities(open(path).read()).items():
            VARIANT_ARITY.setdefault(v, set()).update(arities)

    found = {}
    for path in sources():
        rel = os.path.relpath(path, ROOT)
        MODULE_BODY["text"] = bodies[os.path.dirname(path)]
        lines = open(path).read().split("\n")
        for code, (matcher, _) in RULES.items():
            if code in PRODUCT_ONLY and "/tests/" in rel:
                continue
            if code in TESTS_ONLY and "/tests/" not in rel:
                continue
            seen = {}
            for i, text in matcher(lines):
                if licensed(lines, i, code):
                    continue
                # Fingerprint by TEXT, not line number: edits above a
                # site must not churn the debt list.
                n = seen.get(text, 0)
                seen[text] = n + 1
                found[f"{code}\t{rel}\t{text}#{n}"] = (path, i + 1, code)
    return found

def load():
    if not os.path.exists(BASELINE):
        return set()
    return {l.rstrip("\n") for l in open(BASELINE)
            if l.strip() and not l.startswith("#")}

def save(fps):
    with open(BASELINE, "w") as f:
        f.write("# KNOWN idiom debt, one site per line. This file only ever\n")
        f.write("# SHRINKS: no tool path adds to it. A new violation is fixed\n")
        f.write("# in the code or annotated `// LICENSED I<n>: reason` at the\n")
        f.write("# site. `make idioms-accept` prunes what is gone. Burn it down.\n")
        for fp in sorted(fps):
            f.write(fp + "\n")

def registry_codes():
    doc = os.path.join(ROOT, "DOGFOODING.md")
    return {m for m in re.findall(r"^- (I\d+)", open(doc).read(), re.M)}

def main():
    accept = "--accept" in sys.argv
    # LAW 4: the registry may never outrun the ratchet.
    missing = registry_codes() - set(RULES) - set(UNRATCHETED)
    if missing:
        print(f"idioms: {', '.join(sorted(missing))} in DOGFOODING.md have no matcher")
        print("  add one to tools/idioms.py, or list it in UNRATCHETED with its reason.")
        return 1

    dead = selftest()
    if dead:
        print("idioms: DEAD RULE(S) — a rule that cannot fire reports success forever:")
        for d in dead:
            print(f"  {d}")
        return 1

    found = scan()
    base = load()
    new = sorted(set(found) - base)
    gone = sorted(base - set(found))

    if accept:
        # LAW 2: pruning only. New sites are NEVER banked.
        save(base - set(gone))
        print(f"idioms: pruned {len(gone)} fixed site(s); {len(base) - len(gone)} debt remain")
        return 0

    if new:
        print(f"idioms: {len(new)} NEW violation(s) — the baseline never grows:")
        for fp in new:
            path, line, code = found[fp]
            print(f"  {os.path.relpath(path, ROOT)}:{line}  [{code}] {RULES[code][1]}")
            print(f"      write the idiomatic form, or annotate: // LICENSED {code}: <reason>")
        return 1

    by_code = {}
    for fp in base & set(found):
        by_code[fp.split("\t")[0]] = by_code.get(fp.split("\t")[0], 0) + 1
    tally = " ".join(f"{c}={n}" for c, n in sorted(by_code.items()))
    note = f"; {len(gone)} fixed — `make idioms-accept` banks it" if gone else ""
    print(f"idioms: no new violations. debt {len(base) - len(gone)} ({tally}){note}")
    return 0

sys.exit(main())
