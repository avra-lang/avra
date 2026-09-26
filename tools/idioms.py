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
     code carries `// LICENSED style.push_loop: a stack, not a map`
     on or just above the line. Reviewers see the reason where the
     code is, forever — not as an integer in a file nobody reads.

So a new violation has exactly two honest exits: write the
idiomatic form, or annotate it with a reason.

A FOURTH law keeps the rules from rotting: every idiom named in
DOGFOODING.md must have a matcher here or an entry in UNRATCHETED
with its reason. The registry can never again outrun the ratchet.

FIFTH: an idiom the LANGUAGE can now state is a `rule` declaration
(the formatter, docs/2026_09_21_FORMATTER_DESIGN.md), never a regex
racing it — `avra check` finds it, this tool reads the finding, not
the source (`native_findings()`). Its regex is ported and its RULES
entry moves to UNRATCHETED, saying so. What stays HERE is what the
language cannot yet say on its own: whole-file/cross-declaration
reasoning (Bucket C — style.duplicated_message,
style.duplicated_literal, style.repeated_projection,
style.refusal_uncounted_contains, style.unmutated_mut,
style.dead_parameter, style.unused_import, style.repeated_unwrap,
grammar.comma_list_open), and rules still needing a language gap
(Bucket B — avra-8sb5.25.16's own catalog). The same baseline
ratchets both kinds of finding. A NATIVE finding reads no license of
its own — every idiom is named by its rule now, so there is no
predecessor identity for a native finding to inherit a site's
license through; what a human already reviewed under the tree's old
numbering was folded into the baseline directly the day the numbers
went (avra-8sb5.25.49), and any new native debt joins it the same
way, reviewed at adoption and every time after.
"""
import collections, glob, json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# EVERY PACKAGE'S SOURCE, never a list: a listed root forgets the next
# package, and three had joined the tree unread (std-sqlite, std-meta,
# std-derive) while this tool reported success.
SRC = sorted(os.path.relpath(p, ROOT) for p in glob.glob(os.path.join(ROOT, "packages", "*", "src")))
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
    """push … work … pop on ONE name: that is a bracket fn (compiler.bracket_ritual)."""
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
    POSITION law when the list is already in hand (compiler.seen_accumulator)."""
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

# A REAL count pins a number: `== n`, or the testing verbs that pin
# it for you. `>= 1` is not a count — it is style.uncounted_refusal's smell.
#
# EVERY VERB THE TESTING MODULE EXPORTS BELONGS HERE. `refused_in` pins
# the count at one (it IS `refused_n(p, phrase, 1)`) and was missing
# from this list for its whole life — a keeper's ACCEPT surface is as
# much a claim as its refuse surface, and only a test that uses the
# missing spelling inside a `then` block ever finds the gap.
COUNTED = re.compile(r"diagnostics\.length ==|voices\.length ==|refusals\(.*\) ==|refused_with\(|refused_n\(|refused_in\(")

# The spellings COUNTED must ACCEPT, each proved below — a matcher
# with N accepted alternatives needs N positive fixtures, or a dead
# alternative widens what the keeper permits and no failing fixture
# can see it.
COUNTS = ["a.diagnostics.length == 1", "p.voices.length == 2", "refusals(src) == 3",
          "refused_with(src, \"nope\")", "refused_n(p, \"nope\", 2)", "refused_in(p, \"nope\")"]

def uncounted_refusal(lines):
    """A refusal test asserting only `contains` — the shape that lets
    a CASCADE hide behind a message that happens to appear."""
    for i, l in enumerate(lines):
        if not re.search(r'then "', l):
            continue
        block = "\n".join(lines[i + 1:i + 10]).split('        then ')[0]
        if ".report().contains(" in block and not COUNTED.search(block):
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
            if re.match(r"(export )?(mut )?fn ", lines[j]):
                break
            rest.append(lines[j])
        body = "\n".join(rest)
        # a `mut` handed to a call may fill a `mut` seat, and one
        # receiving a method may be a writing method's place — the
        # compiler refuses a `let` at both, which a grep cannot see
        # and a PATH is a place: `pr.s.turn(...)` writes through `pr`
        # exactly as `pr.turn(...)` does, and `pr.buf = x` writes to
        # it — a rule that reads one segment refuses the `mut` the
        # compiler demands
        seg = r"\.[a-z_][a-z_0-9]*"
        if not (re.search(rf"\b{name}({seg})* *=[^=]", body)
                or re.search(rf"\b{name}({seg})+\(", body)
                or re.search(rf"[(,] *{name} *[,)]", body)):
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

def balanced(text, at):
    """What sits between the paren at `at` and the one that closes
    it, or None when the line does not close it."""
    depth = 0
    for j in range(at, len(text)):
        if text[j] == "(":
            depth = depth + 1
        elif text[j] == ")":
            depth = depth - 1
            if depth == 0:
                return text[at + 1:j]
    return None

def split_seats(seats):
    """`seats` cut at its TOP-LEVEL commas — a seat's own type may
    hold one (`fn(A, B) -> C`). AN ARROW'S `>` CLOSES NOTHING: a fn
    type answering a generic (`fn(A) -> Result<B, C>`) closes its
    OWN parens at depth 0, and the arrow right after read as a
    generic-close too, sending depth negative — so the comma inside
    `Result<B, C>` then read as TOP-LEVEL and split a seat in two.
    Never witnessed until a seat's fn type started answering a
    two-argument generic and another seat followed it."""
    out, depth, start, j = [], 0, 0, 0
    while j < len(seats):
        c = seats[j]
        if seats[j:j + 2] == "->":
            j += 2
            continue
        if c in "(<":
            depth = depth + 1
        elif c in ")>":
            depth = depth - 1
        elif c == "," and depth == 0:
            out.append(seats[start:j])
            start = j + 1
        j += 1
    return out + [seats[start:]]

def opening_bracket(text, at):
    """Where the `[` that `text[at]` closes was opened, or None."""
    depth = 0
    for j in range(at, -1, -1):
        if text[j] == "]":
            depth = depth + 1
        elif text[j] == "[":
            depth = depth - 1
            if depth == 0:
                return j
    return None



# A `let x = E` immediately guarded by `if x == null { return … }` (or
# `fail …`) IS THE ABSENCE-EARLY-EXIT LAW — `let x? = E else { … }`
# says the same thing once, and every later `x!` in the same block
# reads `x`. Restricted to an IMMUTABLE `let` (never a `mut`, a
# parameter, or a field/path) guarded on the VERY NEXT line at the
# SAME indent, whose body is a single `return`/`fail`; the matcher
# then requires EVERY bare mention of `x` for the rest of the
# enclosing block to be an unwrap (`x!`) — one that is not is `x`
# still read as nullable, which the rewrite would break — and refuses
# where the name could be SHADOWED there (a lambda or `for` binding,
# or a nested `let`/`mut` of the same name), since a text scan cannot
# then tell which binding a later `x!` names.
LET_GUARD = re.compile(r"^(\s*)let ([a-z_][a-zA-Z0-9_]*)(?::\s*([^=]+))?\s*=\s*(.+)$")

def let_scope_end(lines, indent, from_idx):
    """First line at LESS than `indent` (blank lines skipped) — the
    close of the block the `let` was scoped to."""
    for j in range(from_idx, len(lines)):
        s = lines[j]
        if not s.strip():
            continue
        if len(s) - len(s.lstrip()) < indent:
            return j
    return len(lines)

def let_shadowed(scope_text, name):
    n = re.escape(name)
    pats = [
        rf"\(\s*{n}\s*[:)]", rf"\(\s*{n}\s*,", rf",\s*{n}\s*[:)]",
        rf"\bfor\s*\(?\s*{n}\s*,", rf",\s*{n}\s*\)?\s*in\b", rf"\bfor\s+{n}\s+in\b",
        rf"\blet\s+{n}\b", rf"\bmut\s+{n}\b",
    ]
    return any(re.search(p, scope_text) for p in pats)

def let_else_guard(lines):
    """`let x = E` then an immediate absence-exit — `let x? = E else
    { … }` (nullable.let_else_guard)."""
    for i in range(len(lines) - 1):
        m = LET_GUARD.match(lines[i])
        if not m:
            continue
        indent_s, name, ann, rhs = m.groups()
        if ann is not None and not ann.strip().endswith("?"):
            continue
        indent = len(indent_s)
        guard = re.compile(
            r"^" + re.escape(indent_s) + r"if " + re.escape(name)
            + r" == null \{ (return\b[^{}]*|fail\b[^{}]*) \}\s*$")
        if not guard.match(lines[i + 1]):
            continue
        end = let_scope_end(lines, indent, i + 2)
        scope = "\n".join(lines[i + 2:end])
        if let_shadowed(scope, name):
            continue
        occ = list(re.finditer(r"(?<![.\w])" + re.escape(name) + r"(?!\w)", scope))
        if not occ or any(scope[o.end():o.end() + 1] != "!" for o in occ):
            continue
        yield i, lines[i].strip()

def bool_comprehension(lines):
    """A comprehension over a LIST, built only to be folded to a
    bool, is a SCAN. `xs.all(pred)` stops at the first answer and
    allocates nothing; the comprehension builds every element first
    and then measures what it built. Over a RANGE it is the only form
    the language has — a range takes no methods — and a PAIRED head
    needs an index the native scan does not hand over, so both are
    licensed by the matcher rather than by an annotation."""
    tail = re.compile(r"\]\.(any|all)\(it\)")
    for i, l in enumerate(lines):
        for m in tail.finditer(l):
            at = opening_bracket(l, m.start())
            if at is None:
                continue
            head = re.search(r" for [a-z_][a-z_0-9]* in (.+)$", l[at + 1:m.start()])
            if not head or ".." in head.group(1) or " if " in head.group(1):
                continue
            yield i, l[at:m.end()][-58:]

def dead_parameter(lines):
    """A parameter nothing reads — the signature lies about what the
    fn needs, and every call site carries the lie. Methods count,
    except under `impl Trait for T` and inside `trait T { }` itself,
    where the TRAIT owns the signature: a `nothing()` body — an
    impl's or a default's — cannot drop a parameter."""
    contract, in_text = False, False
    for i, l in enumerate(lines):
        # Template text is prose; its fn heads are not fns.
        if l.count('\"\"\"') % 2 == 1:
            in_text = not in_text
            continue
        if in_text:
            continue
        if re.match(r"(?:export )?(?:impl .+ for \w|trait \w+ \{)", l):
            contract = True
        if l == "}":
            contract = False
        if contract:
            continue
        # A head with no `{` is a trait's signature: nothing reads
        # its params by design. String contents are not a head.
        bare = re.sub(r'"(\\.|[^"\\])*"', '""', l)
        m = re.match(r"\s*(?:export )?(?:mut )?fn ([a-z_]+)\(", bare)
        if not m or "{" not in bare:
            continue
        # THE LIST ENDS AT ITS MATCHING PAREN, never at the line's
        # last one: a one-line body holding a lambda (`f(x, (q: T) ->
        # ...)`) put that lambda's seat in the fn's own parameter list
        # and the rule accused a parameter the fn never declared.
        seats = balanced(bare, m.end() - 1)
        if seats is None:
            continue
        # a `mut` seat is still a parameter: the mark is not its name
        params = [p.strip().split(":")[0].strip().removeprefix("mut ")
                  for p in split_seats(seats) if ":" in p]
        body = "\n".join(fn_body(lines, i)[1:]) or l[l.index(")") + 1:]
        for p in params:
            if p == "self" or p.startswith("_"):
                continue
            if not re.search(rf"\b{re.escape(p)}\b", body):
                yield i, f"{l.strip()[:60]} [{p}]"

# A module's files share one namespace, so an import is judged
# against its whole MODULE (the directory), never one file — lenient
# by design. scan() fills this before each file.
MODULE_BODY = {"text": ""}

# The file under scan, for the one rule whose exemption is a FILE: the
# emission vocabulary's own body may emit what everyone else speaks.
CURRENT = {"path": ""}

# A `grammar { … }` block EXPANDS into the grammar's own
# constructors, so a module that writes one uses these names without
# ever spelling them. A text scan cannot see an expansion.
GRAMMAR_BLOCK_NAMES = {
    "Grammar", "Rule", "Alt", "Seq", "Item", "Prim", "Rep", "Build",
    "Expect", "Recover",
}

def unused_import(lines):
    """A name imported and never used ANYWHERE in its module. The
    compiler refuses a MISSING import (F3000) and one a module does not
    export (F3012); an unused one is silent, so this rule keeps that
    direction."""
    expands = "grammar {" in MODULE_BODY["text"]
    for i, l in enumerate(lines):
        m = re.match(r"^use [a-z@][\w.@]*\.\{(.+)\}$", l.strip())
        if not m:
            continue
        for item in (n.strip() for n in m.group(1).split(",")):
            if not item:
                continue
            # `use a.{X as Y}` binds Y: the LOCAL name is what must be read.
            name = item.split(" as ")[-1].strip()
            if expands and name in GRAMMAR_BLOCK_NAMES:
                continue
            if not re.search(rf"\b{re.escape(name)}\b", MODULE_BODY["text"]):
                yield i, f"{l.strip()[:50]} [{name}]"

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
        if re.match(r"\s*(export )?(mut )?fn ", l):
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

COMMA_LIST = re.compile(r'\(\s*","[^()]*\)\*')

def comma_list_open(lines):
    """A repeated comma list in a GRAMMAR rule that does not offer the
    trailing comma. CLAUDE.md's grammar law: `( "," x )*` ends `","?`
    before its closer, in every rule. A list that refuses the comma is
    a defect, not a style — and a rule copied from a sibling and then
    diverging is invisible without this, which is how two of three
    `fn`-shaped rules came to differ."""
    for i, l in enumerate(lines):
        if not re.search(r'^\s*(stmt|primary|type|expression|postfix)\s*=', l):
            continue
        for m in COMMA_LIST.finditer(l):
            if not l[m.end():].lstrip().startswith('","?'):
                yield i, l.strip()[:60] + " … " + m.group(0)[:40]

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
    "style.duplicated_message": "a repeated fixture in a test is not a message that can drift",
    "style.duplicated_literal": "a fixture built twice in a test is the test being explicit",
}
TESTS_ONLY = {"style.refusal_uncounted_contains": "it is a law about how a REFUSAL is asserted"}

RULES = {
    "style.duplicated_message": (duplicated(r'"[a-z][^"]{20,}"'),
            "a long string duplicated in one file — shared messages are fns"),
    "style.repeated_projection": (line_rx(r"([a-z_]+\.[a-z_]+\(([a-z_]+)\)).*\1"),
            "the same projection computed twice on one line — bind it"),
    "style.duplicated_literal": (duplicated(r"[A-Z][a-zA-Z]+ \{ [a-z_]+: [^{}]* \}"),
            "an identical struct literal written twice — name its constructor"),
    "style.unused_import": (unused_import,
            "a name imported and never used in its MODULE — the compiler "
            "refuses a missing one, never an unused one"),
    "style.dead_parameter": (dead_parameter,
            "a parameter nothing reads — the signature lies, and every call site "
            "carries the lie"),
    "style.refusal_uncounted_contains": (uncounted_refusal,
            "a refusal test with no diagnostics COUNT — a cascade can hide behind it"),
    "style.unmutated_mut": (unmutated_mut,
            "a `mut` nothing mutates — say `let`"),
    "grammar.comma_list_open": (comma_list_open,
            "a grammar comma list with no trailing-comma option — `( \",\" x )*` ends `\",\"?`"),
    "style.repeated_unwrap": (repeated_unwrap,
            "one nullable local forced open 3+ times — guard once, bind once, "
            "and read the name"),
}

UNRATCHETED = {
    "lists.last_index":  "PORTED NATIVELY (avra-8sb5.25.16): `lists.last_index`, a `rule`\n"
           "           in features/lists/idioms.av — `avra check`/`avra fix` enforce it,\n"
           "           ratcheted here by the native-findings phase below, not by a regex",
    "structs.index_compared":  "PORTED NATIVELY: `structs.index_compared` (features/structs/idioms.av)\n"
           "           — a `rule`, ratcheted by the native-findings phase below",
    "compiler.bool_of_defaulted": "PORTED NATIVELY: all six protocol projections as siblings\n"
           "           (`bool_of_defaulted` … `pairs_of_defaulted`, compiler/idioms.av) —\n"
           "           ratcheted by the native-findings phase below",
    "compiler.refusal_assembled": "PORTED NATIVELY: `refusal_assembled` (compiler/idioms.av) — ratcheted\n"
           "           by the native-findings phase below",
    "compiler.uncounted_refusal": "PORTED NATIVELY: all four receiver shapes as siblings\n"
           "           (`uncounted_refusal` … `voices_uncounted`, compiler/idioms.av) —\n"
           "           ratcheted by the native-findings phase below",
    "compiler.if_start_raw": "PORTED NATIVELY: all six `Ins` variants as siblings (`if_start_raw`\n"
           "           … `loop_end_raw`, compiler/idioms.av) — ratcheted by the\n"
           "           native-findings phase below",
    "compiler.scope_enter_raw": "PORTED NATIVELY: both scope brackets as siblings (`scope_enter_raw`,\n"
           "           `scope_exit_raw`, compiler/idioms.av) — ratcheted by the\n"
           "           native-findings phase below",
    "compiler.str_grown_quadratically": "PORTED NATIVELY: `str_grown_quadratically` (compiler/idioms.av) —\n"
           "           ratcheted by the native-findings phase below",
    "compiler.interned_opt": "PORTED NATIVELY: all six type-constructor shapes as siblings\n"
           "           (`interned_int` … `interned_res`, compiler/idioms.av) —\n"
           "           ratcheted by the native-findings phase below",
    "loops.push_loop":  "PORTED NATIVELY: `push_loop` (features/loops/idioms.av) — a NAME hole\n"
           "           (avra-8sb5.25.6) holds the loop's own binder open; ratcheted\n"
           "           by the native-findings phase below",
    "lists.bool_comprehension_list": "PORTED NATIVELY: `bool_comprehension_list`/`_range`\n"
           "           (features/lists/idioms.av) — a NAME hole holds the comprehension's\n"
           "           own element binder open; ratcheted by the native-findings phase\n"
           "           below. A comprehension with its own `if` filter is not yet\n"
           "           reached (the subset today)",
    "compiler.seen_accumulator": "PORTED NATIVELY: `seen_accumulator` (compiler/idioms.av) — a RUN hole\n"
           "           (avra-8sb5.25.10) holds the rest of the enclosing block open so the\n"
           "           accumulator's own `.contains`/`.push` calls are found wherever they\n"
           "           sit, not only in the first 14 lines; ratcheted by the native-\n"
           "           findings phase below",
    "compiler.hand_sized_index": "PORTED NATIVELY: `hand_sized_index` (compiler/idioms.av) — an id read\n"
           "           through a hand offset, `${e}.index - ${k}`; ratcheted by the\n"
           "           native-findings phase below. The sibling half of this idiom (a\n"
           "           fact column sized from an arena's count, `filled(...count())`)\n"
           "           is `compiler.filled_by_arena_count` now, also native (avra-8sb5.25.10)",
    "compiler.filled_by_arena_count": "PORTED NATIVELY (avra-8sb5.25.10): `filled_by_arena_count`\n"
           "           (compiler/idioms.av) — two `quote` arms, `filled(...)` and\n"
           "           `filled<T>(...)`, the pinned type argument a TYPE-seat hole\n"
           "           (`Shape.TypedNode`/`Open.Type`, core/shape.av) held open only so\n"
           "           the second arm's message can quote it back; ratcheted by the\n"
           "           native-findings phase below",
    "compiler.free_state_verb": "PORTED NATIVELY (avra-8sb5.25.10): `free_state_verb`\n"
           "           (compiler/idioms.av) — a bare-hole root guarded rule-side over a\n"
           "           new `Code.fn_params()`/`Code.decl_type()` (features/code.av,\n"
           "           the TYPE-seat door): a param list has no fixed arity a `quote`\n"
           "           pattern can spell, so the first param's own written type is read\n"
           "           structurally, never bound through the pattern; ratcheted by the\n"
           "           native-findings phase below. Narrower than the retired regex by\n"
           "           file reach (one path segment under `features/`/`compiler/`,\n"
           "           matching `PASS_FILES`) and by nesting (a trait's/an impl's own\n"
           "           method is excluded structurally, where the regex's column-zero\n"
           "           anchor excluded it by indentation) — 36 sites found tree-wide,\n"
           "           every one already `// LICENSED style.free_state_verb`'d by a\n"
           "           prior human review; the other 11 of 47 such comments name a site\n"
           "           the regex itself would never have matched either (a nested\n"
           "           feature file, or a first param that is not one of `state_types`)\n"
           "           — stale documentation, not a finding this rule missed",
    "compiler.stmt_index_walk": "PORTED NATIVELY (avra-8sb5.25.16): `stmt_index_walk`\n"
           "           (compiler/idioms.av) — reads `Code.for_range()`, the same\n"
           "           workaround `loops.index_walk` already reads its own range head\n"
           "           through; `core/store.av` is exempt structurally (its own\n"
           "           `stmt_ids()` IS this walk); ratcheted by the native-findings\n"
           "           phase below",
    "compiler.one_body_arms": "PORTED NATIVELY (avra-8sb5.25.16): `one_body_arms`\n"
           "           (compiler/idioms.av) — a bare-hole root guarded rule-side over a\n"
           "           new `Code.arms()` (features/code.av); ratcheted by the native-\n"
           "           findings phase below. WIDER than the regex (structural, not a\n"
           "           single-line text match); NO REWRITE (the alternatives-bind\n"
           "           question, F2039, is a typing fact this rule-side scan lacks)",
    "style.registry_catchall": "RETIRED (avra-8sb5.25.16): the regex found ZERO sites at\n"
           "           retirement (no baseline debt, no `// LICENSED style.registry_catchall`\n"
           "           comment anywhere) — the compiler's own typed diagnostic\n"
           "           (`registry_forgets`/`registry_forgets_bound`, features/enums/check.av,\n"
           "           F2040's successor) already counts answering arms against the\n"
           "           DECLARED ENUM's own variants, for every package `avra check` touches,\n"
           "           more precisely than a syntactic `_ ->` grep ever could. Not ported as\n"
           "           a `rule`: the enforcement was never idioms.py's to hand off",
    "compiler.raw_rt_call": "PORTED NATIVELY (avra-8sb5.25.16): `raw_rt_call`/`raw_rt_call_void`\n"
           "           (compiler/idioms.av) — a fixed-arity `quote` over `Ins.CallRt`/\n"
           "           `Ins.CallRtVoid`, guarded by the bound name hole's own TEXT\n"
           "           (`starts_with(\"\\\"avra_\")`); ratcheted by the native-findings\n"
           "           phase below",
    "compiler.raw_mint_emit": "PORTED NATIVELY (avra-8sb5.25.16): nine sibling rules, one per\n"
           "           covered `Ins` variant (`raw_mint_emit_bin` … `raw_mint_emit_load`,\n"
           "           compiler/idioms.av) — the let's own NAME hole and the emit's own\n"
           "           VALUE hole agreed by text; ratcheted by the native-findings phase\n"
           "           below. NARROWER than the regex: a pair inside an `if`/`while`/`for`\n"
           "           body is outside this pattern's reach (that body is a flat statement\n"
           "           list, never a nested `Block`) — `hollow_of`'s two sites (values.av)\n"
           "           stay licensed by comment for a human reader, unseen by the rule",
    "nullable.if_null_ternary": "PORTED NATIVELY: `nullable.default`, named `if_null_ternary`\n"
           "           (features/nullable/idioms.av) — ratcheted by the native-findings\n"
           "           phase below",
    "nullable.let_else_guard": "PORTED NATIVELY: `let_else_guard` (features/nullable/idioms.av) — a NAME\n"
           "           hole (avra-8sb5.25.6) and two run holes (avra-8sb5.25.10) hold the\n"
           "           `let`'s binder and the enclosing block's head/tail open; ratcheted\n"
           "           by the native-findings phase below. Narrower than the retired\n"
           "           regex: an annotated `let` never matches (no type-seat hole yet,\n"
           "           avra-8sb5.25.10), and shadowing is approximated by a text scan for\n"
           "           `name!` in the tail rather than a real binding check",
    "compiler.emit_then_error": "PORTED NATIVELY: `emit_then_error` (compiler/idioms.av) — two run holes\n"
           "           hold the enclosing block's head/tail open so the pair is found\n"
           "           adjacent anywhere in it, not only within a fixed line window;\n"
           "           ratcheted by the native-findings phase below",
    "compiler.bracket_ritual": "PORTED NATIVELY: `bracket_ritual` (compiler/idioms.av) — a run hole\n"
           "           holds the rest of the enclosing block open and a guard scans it by\n"
           "           TEXT for a matching `.pop()`, never the fixed 14-line window;\n"
           "           ratcheted by the native-findings phase below. Narrower than the\n"
           "           retired regex on purpose: the push and the pop must sit in the SAME\n"
           "           block (siblings), so a stack held open ACROSS match arms (the\n"
           "           `// LICENSED compiler.bracket_ritual: this IS the bracket` sites) never even reaches\n"
           "           the shape, let alone the license check",
    "loops.index_walk": "PORTED NATIVELY: `index_walk` (features/loops/idioms.av) — a run hole\n"
           "           holds the loop body open and a guard scans it by TEXT for\n"
           "           `xs[j]`; ratcheted by the native-findings phase below. Narrower\n"
           "           than the retired regex on purpose: the pattern roots at a\n"
           "           STATEMENT `for` loop, so a comprehension's own `for` clause\n"
           "           (`[… for j in 0..xs.length]`) never matches — a different shape,\n"
           "           not yet its own rule",
    "closures.pronoun_lambda": "PORTED NATIVELY: `pronoun_lambda` (features/closures/idioms.av) — a\n"
           "           NAME hole on the lambda's OWN param (avra-8sb5.25.10's Lambda\n"
           "           own-name-at case) plus a structural `call_args()` walk that\n"
           "           refuses a param handed to a nested call's own arguments;\n"
           "           ratcheted by the native-findings phase below",
    "nullable.nullable_flag_local": "PORTED NATIVELY: `nullable_flag_local` (features/nullable/idioms.av)\n"
           "           — no TYPE hole (a quote pattern has none in type position yet,\n"
           "           avra-8sb5.25.10): a bare-hole root guarded\n"
           "           `lit.is_nullable_flag_mut()` reads the `mut` declaration's own\n"
           "           `ty`/value fields structurally instead of binding them; ratcheted\n"
           "           by the native-findings phase below.\n"
           "           UNDER THE TREE'S OLD NUMBERING THIS IDIOM WAS FILED \"style.hand_rolled_scan\", a number\n"
           "           the RULES dict's own regex had ALREADY claimed for a DIFFERENT\n"
           "           idiom (\"hand-rolled scans that ARE find/index_of/any\",\n"
           "           `style.hand_rolled_scan` today) — a live collision: `decls_mint.av`'s\n"
           "           `// LICENSED style.hand_rolled_scan: a min-scan keeps the SMALLEST holder, not a\n"
           "           membership` was written for THAT idiom, and honouring it as this\n"
           "           one's predecessor would have SILENTLY suppressed a genuine\n"
           "           nullable-flag-local finding under someone else's review. This\n"
           "           idiom was renumbered to style.nullable_flag_local to break the collision — a\n"
           "           name chosen once, never mechanically incremented, so the same\n"
           "           accident could not recur the same way; every `// LICENSED style.hand_rolled_scan:`\n"
           "           comment the tree ever carried was written for the OTHER idiom, never\n"
           "           this one, and none of them was ever honoured as this idiom's\n"
           "           predecessor. SUPERSEDED AGAIN, by a stronger guarantee (avra-8sb5.25.51):\n"
           "           the name is `nullable.nullable_flag_local` now, `rule_id` itself —\n"
           "           collision-proof by CONSTRUCTION (one module, one name, the rules\n"
           "           table refuses a repeat) rather than by a human's care not to\n"
           "           mechanically increment a hand-picked one.",
    "if_expr.when_ladder": "PORTED NATIVELY: `when_ladder` (features/if_expr/idioms.av) — the\n"
           "           pattern's own three parts (`if`, `else if`, `else`) are the\n"
           "           floor a chain of any length recurses past, one nested match at a\n"
           "           time, rather than one pattern spanning every depth; ratcheted by\n"
           "           the native-findings phase below. Wider than the retired regex on\n"
           "           purpose: no per-arm shape check (no return/fail/break/continue/\n"
           "           assignment/one-line refusal) — `Expr.If` vs `Stmt.IfStmt` being\n"
           "           different node kinds BY POSITION (avra-8sb5.25.21) already does\n"
           "           the work the regex's body-text scan existed for, so a chain used\n"
           "           for its value structurally cannot be the statement form; a 4+-arm\n"
           "           chain is found once at each nesting level it appears at, a known\n"
           "           duplicate the Fix.Say tier does not need suppressed",
    "enums.bool_variant_match": "PORTED NATIVELY: `bool_variant_match`/`bool_variant_match_negated`\n"
           "           (features/enums/idioms.av) — no guard needed: the pattern's own\n"
           "           WILDCARD seat (a literal `_`, never an `or`-run) already refuses\n"
           "           a registry's remaining variants structurally, before any is\n"
           "           asked; ratcheted by the native-findings phase below",
    "compiler.modified_copy_literal": "PORTED NATIVELY: `modified_copy_literal` (compiler/idioms.av) — a bare\n"
           "           hole root (avra-8sb5.25.10's `At.Field`) matches ANY node, guarded\n"
           "           `lit.is_struct_lit()`, then reads `lit.kids()` field by field;\n"
           "           ratcheted by the native-findings phase below. Narrower than the\n"
           "           retired regex on purpose: no DECLARED-TYPE trace, so a\n"
           "           coincidental `x.field` name match is accused too, and the copy\n"
           "           test is STRUCTURAL (a `Prop` whose own name agrees), never a text\n"
           "           suffix guess",
    "style.arm_duplicates_sibling_answer": "telling \"this branch answers what a DIFFERENT arm already\n"
           "           answers\" needs reading every other arm's own answer and judging\n"
           "           whether they are the same computation — and, when the target is a\n"
           "           payload-blind or-run, whether widening it to the guarded variant's\n"
           "           own pattern is honest at that site. No grep links two arms as\n"
           "           answering the same thing",
    "style.named_type_representation_check": "no grep tells a representation-bearing named-type check from an\n"
           "           ordinary string comparison — the shape is identical either way,\n"
           "           and only the DOMAIN (a closed, named set of the tree's own free\n"
           "           wrappers) tells them apart. The keeper is the doc comment beside\n"
           "           `flat_named` and this entry: the next named type the check must\n"
           "           widen for is the trigger to give `Kind` a representation bit,\n"
           "           not to grow the list",
    "style.span_anchor_incomplete": "no grep tells a COMPLETE anchor list from a partial one — the anchors\n"
           "           are whatever the grammar can put in the range, so a helper taking\n"
           "           `List<Token>` of names reads identically whether or not the span\n"
           "           between them holds members of another kind. The keeper is the\n"
           "           attack: write the optional piece on the LAST member of one group\n"
           "           with another group following, and read it back through the\n"
           "           printer (annotations_adversarial_test.av, \"payload marks —\n"
           "           alignment\")",
    "style.per_decl_walk_asks_stmt": "no grep tells a question about a STATEMENT from a question about the\n"
           "           DECLARATION in hand — both read `decl(d).stmt`, and which one a\n"
           "           law is asking is semantic. The keeper is a test that pins the\n"
           "           COUNT over a member carrying a declaration of its own: a record\n"
           "           field with a DEFAULT is minted on its owner's statement, so a\n"
           "           per-decl walk asks its owner's question a second time",
    "style.mutable_slot_not_cell": "no grep tells a one-element list used as a slot from a list whose\n"
           "           first element is written; the keeper is the review round",
    "style.impl_method_equals_default": "needs body equality against the trait's default — a native rule\n"
           "           over the declaration's Code (the formatter's rule engine), not a\n"
           "           text matcher. `nothing()` (or whatever no-op form applies) is\n"
           "           transparent to the comparison: a body that wraps the default in\n"
           "           one still answers exactly what the default answers",
    "style.derive_file_not_alone": "no grep tells \"declares a derive and nothing else\" from an ordinary\n"
           "           file with a trait in it — the shape that breaks it is whatever\n"
           "           ELSE the file holds. The keeper is the law in CLAUDE.md and the\n"
           "           first build that tries: the annotated file loses its methods and\n"
           "           every caller is blamed",
    "style.positional_boundary_unspelled": "no grep tells a BOUNDARY registry from any other list of rows, and a\n"
           "           reader that spells slot names or a writer that spells literal tags\n"
           "           reads as ordinary code. The keeper is the boundary check itself:\n"
           "           crossing_test.av moves each crossed shape and demands the refusal\n"
           "           name the one that moved",
    "style.pack_unpack_one_table": "no grep links two fns as INVERSES, so nothing textual sees a pack\n"
           "           learning a category its unpack has not. The keeper is `make\n"
           "           vocab`: both directions are named as consumers of the SAME\n"
           "           registry enum, and a catch-all or an `is` test inside either\n"
           "           fails the gate whichever direction grew the hole",
    "style.seen_shape_vs_seat_shape": "no grep tells a READ site from a SEAT site — `shape_at` is correct at\n"
           "           one and a defect at the other, and both spellings live beside each\n"
           "           other in the same file. The keeper is the adversarial suite:\n"
           "           named_adversarial_test.av reaches every vocabulary a name can\n"
           "           stand over, and a row reading the wrong door fails there",
    "style.unwritable_spelling_key": "an unwritable spelling as a key is a NAMING choice — the smell is\n"
           "           an in-band tag a program could write, which no grep tells from\n"
           "           an honest name; the review round hunts it",
    "style.restrlen_loop": "RETIRED: a string's `.length` is a load — the header carries the\n"
           "           length — so a re-measure in a loop condition costs nothing and\n"
           "           the hoists that stand are harmless",
    "style.wrong_payload_count_pattern": "RETIRED: the compiler refuses a wrong payload count (F2015) on\n"
           "           patterns and constructions, one-line enums included — a\n"
           "           law now, and a matcher would only repeat it",
    "style.whole_table_scan": "a whole-table scan for a keyed subset and a legitimate one-shot walk\n"
           "           over the same table are the same text; what makes the scan a smell\n"
           "           is being asked per query, which only a profile can see. `sample`\n"
           "           hunts it — it found the two that named the rule",
    "style.doc_run_stolen": "a stolen doc and a legitimate multi-paragraph header are the SAME\n"
           "           shape: a sentence ends, the next line opens with `A`/`The`. The\n"
           "           difference is whether the second paragraph ELABORATES the one\n"
           "           definition or DEFINES another — semantic, not syntactic. A first\n"
           "           matcher printed 78 hits; the two inspected split one real\n"
           "           (workspace's `shown`) and one legitimate (`full_type`). The\n"
           "           review round hunts it, as it did the five that named the rule",
    "style.accumulator_declaration":  "the accumulator DECLARATION is a weak proxy: stacks, folds, range\n"
           "           fills and enumerate walks all declare one. rule.loops.push_loop matches the real\n"
           "           smell — a loop whose whole body is one push — and catches every\n"
           "           map style.accumulator_declaration did, without 42 false positives",
    "style.evaluated_payload_chain":  "the evaluated-payload chain died with the eval collapse; no sites can exist",
    "style.statement_value_ritual":  "the spelled ritual and the only legitimate way to USE stmt_value are\n"
           "           textually identical — every hit was the verb's own body or a\n"
           "           site needing the id afterward. The review round hunts it",
    "style.dedupe_union_fold":  "the remaining folds are duplicate DETECTION (they emit on the dup)",
    "style.hand_rolled_scan":  "SWEPT — every hand-rolled scan that is a bare find/index_of was\n"
           "           already converted; under the tree's old numbering this idiom's\n"
           "           number was found claimed live as tools/idioms.py's OWN regex key\n"
           "           for a DIFFERENT idiom (`style.nullable_flag_local`, filed under a\n"
           "           different number to break the collision) rather than this one,\n"
           "           which has had no matcher of its own since the sweep",
    "style.fold_as_flag": "a matcher cannot see whether a predicate has EFFECTS — `all` would\n"
           "           short-circuit past a binding the fold must perform, and only a\n"
           "           human can tell that from a pure test",
    "style.head_plus_tail_build":  "head-plus-tail builds are subsumed by style.accumulator_declaration and rule.loops.push_loop",
    "style.value_if_ladder": "name->value if-ladders are too varied to grep — the review round hunts them",
    "style.name_generalization": "a name serving two masters is semantic — no text pattern can see it",
    "style.early_answer_mint": "mint order is STRUCTURE, not a greppable string: whether a\n"
    "        verb's answer register mints before or after its scratch\n"
    "        registers needs the emission sequence, not a pattern",
    "style.same_scope_borrow": "the matcher needs the enclosing fn's scope (a read of the\n"
           "           field BEFORE the write) — the read-then-write scan lives\n"
           "           in lane C's S4c-2 landing; liveness (S3) retires the idiom",
}

# A rule that cannot fire is worse than no rule: it reports success
# forever. Every matcher must catch its own specimen, checked on every
# run — this caught style.protocol_defaulted shipping with a regex that could not span a
# nested call.
# WHAT A RULE MUST *NOT* FIRE ON — THE KEEPER'S OTHER SURFACE, in one
# table. Making a rule fail exercises only what it refuses; every
# spelling it ACCEPTS is a claim too, and the accepted shape nobody
# fixtured is exactly where a false positive lives unseen, because the
# rule is working and nobody looks. Two kinds of entry, one concept:
# an HONEST SPELLING a matcher must permit (a dead alternative widens
# the rule — `refused_n(` was one), and a CLEAN SHAPE it must not
# accuse (both style.unmutated_mut entries were live accusations against code the
# compiler requires).
#
# THEY WERE TWO TABLES, `ACCEPTED` and `CLEAN`, AND THE SECOND KILLED
# THE FIRST: two `CLEAN = {…}` bindings landed in one file a week
# apart, Python kept the later, and the style.unmutated_mut, style.dead_parameter and style.bool_comprehension fixtures of
# the earlier one stopped being checked with nothing to see. That is
# this file's own duplicate-number hazard one level up — the guard
# below now reads its own source for a table defined twice, as it
# already does for a number claimed twice.
CLEAN = {
    "style.refusal_uncounted_contains": [
        ['        then "k" {', '            a.report().contains("x") && a.diagnostics.length == 1'],
        ['        then "k" {', '            a.report().contains("x") && a.voices.length == 1'],
        ['        then "k" {', '            a.report().contains("x") && refusals(src) == 1'],
        ['        then "k" {', '            a.report().contains("x") && refused_with(src, "x")'],
        ['        then "k" {', '            a.report().contains("x") && refused_n(p, "x", 1)'],
    ],
    "style.unmutated_mut": [["    mut pr = attacked()?",
             "    pr.s.turn(ms(20))?"],
            ["    mut w = held()",
             "    w.c.buf = grown"]],
    "style.dead_parameter": [["fn tf_path(line: string) -> string { read(line, (q: Request) -> q.path()) }"],
            ["fn ro() -> int { flags_of(config_at(\"x\") with { mode: Mode.ReadOnly }) }"],
            ["fn f(a: int) -> int { g(a) with { b: 1 } }"],
            ["fn f(settle: fn(int) -> Result<int, string>, cross: fn(int) -> int) -> int {",
             "    settle(1)",
             "    cross(2)",
             "}"]],
    "style.bool_comprehension": [["    [covers_seg(x[j], y[j]) for j in 0..n].all(it)"],
            ["    [self.stage_seat(k, slots[i]) for i, k in sig.params].all(it)"],
            ["    [f(x) for x in xs if p(x)].any(it)"]],
}

SPECIMENS = {
    "rule.loops.push_loop":  [["for x in xs {", "    out.push(x)", "}"],
            ["    for x in xs { out.push(x) }"],
            ["    for (j, x) in xs.enumerate() { out.push(x) }"]],
    "style.duplicated_message": [['    let a = "a message long enough to be shared"',
             '    let b = "a message long enough to be shared"']],
    "style.duplicated_literal": [['    let a = Span { lo: lo, hi: hi }', '    let b = Span { lo: lo, hi: hi }']],
    "style.repeated_projection": [["    let ok = cx.shape_at(e) && cx.shape_at(e)"]],
    "style.bool_comprehension": [["    r.status <= 999 && [writable(h) for h in r.headers].all(it)"],
            ["    [b.ieq_at(0, b.length, w) for w in written_by].any(it)"],
            ["    ![names_one_of(h.name, reply_writes()) for h in r.headers].any(it)"]],
    "style.seen_accumulator": [["    mut seen: List<string> = []", "    if seen.contains(x) { }", "    seen.push(x)"]],
    "style.refusal_uncounted_contains": [['        then "it refuses" {', '            let a = analyze_source("x")',
             '            a.report().contains("nope")', "        }"],
            ['        then "it refuses" {', '            let a = analyze_source("x")',
             '            a.diagnostics.length >= 1 && a.report().contains("nope")', "        }"]],
    "style.uncounted_refusal": [['            refusals("x") >= 1'],
            ['            refusals(src) >= 1'],
            ['            a.diagnostics.length >= 1 && a.report().contains("nope")'],
            ["            p.diagnostics >= 1"],
            ["            p.voices.list.length >= 1 && lets.length == 2"]],
    "style.unmutated_mut": [["    mut registry = new_type_registry()", "    let n = registry.shapes.length"]],
    "style.dead_parameter": [["fn f(a: int, b: int) -> int {", "    a + a", "}"],
            ["    fn m(self, a: int, b: int) -> int {", "        a + a", "    }"],
            ["    fn m(self, a: int) -> int { 1 }"]],
    "style.unused_import": [["use core.{Span}"]],
    "grammar.comma_list_open": [['            stmt = "fn" n:NAME "(" ( ps:NAME ( "," ps:NAME )* )? ")" END -> fn_decl(n, ps)'],
             ['            primary = "[" ( a:expression ( "," a:expression )* )? "]" -> lit(a)']],
    "style.repeated_unwrap": [["fn f(x: int?) -> int {", "    if x == null { return 0 }",
             "    x! + x! + x!", "}"],
            ["    mut fn m(x: int?) -> int {", "        if x == null { return 0 }",
             "        x! + x! + x!", "    }"]],
}

def duplicate_names():
    """A dotted name claimed twice in any table, read from this file's
    own text — the dict has already dropped the loser by the time it
    runs."""
    text = open(__file__).read()
    out = []
    # A TABLE DEFINED TWICE IS THE SAME HAZARD ONE LEVEL UP: the later
    # binding replaces the earlier whole, so every fixture in it stops
    # being checked and the tool still reports success. It happened to
    # `CLEAN`.
    for name in sorted(set(re.findall(r"^([A-Z_]+) = \{", text, re.M))):
        if len(re.findall(r"^" + name + r" = \{", text, re.M)) > 1:
            out.append(name + " is defined more than once — the later table silently replaces the earlier")
    for table in ("RULES", "SPECIMENS", "UNRATCHETED", "CLEAN"):
        start = text.find("\n" + table + " = {")
        if start < 0:
            continue
        body = text[start:text.index("\n}", start)]
        claimed = re.findall(r'^\s{4}"([a-z][a-z_]*(?:\.[a-z][a-z_]*)+)"\s*:', body, re.M)
        for code in sorted(set(claimed)):
            if claimed.count(code) > 1:
                out.append(code + " is claimed " + str(claimed.count(code)) + " times in " + table + " — the later one silently wins")
    # and the REGISTRY, which is the spec this tool implements: a
    # name claimed twice there sends every `LICENSED <name>` at those
    # sites to whichever rule the reader happens to scroll to first.
    entries = registry_entries()
    for code in sorted(set(entries)):
        if entries.count(code) > 1:
            out.append(code + " is claimed " + str(entries.count(code)) + " times in DOGFOODING.md's registry — a license naming it is ambiguous")
    return out

def selftest():
    """Every rule catches EVERY specimen, or the tool refuses to run.

    One specimen proves a matcher is alive; it does not prove its
    REACH. Four rules shipped blind spots that a single specimen
    passed straight over — `rule.lists.last_index` could not see a
    dotted receiver, `rule.loops.push_loop` could not see a one-line
    loop, `style.hand_rolled_scan` could not see a generic with two
    parameters, and `style.repeated_unwrap` counted field unwraps as
    locals. A rule claims a SHAPE, so every spelling of that shape
    belongs here.

    It also refuses a REPEATED NAME. Under the tree's old numbering,
    two lanes numbered a new idiom the same day and both landed style.raw_region:
    a duplicate key in a dict literal is legal Python, the later one
    wins, and the earlier rule vanishes — the emission law went
    unenforced for a whole window while this tool reported success.
    A NAME does not remove that hazard by itself — two lanes can
    still coin the same descriptive name for two different smells the
    same day — so the check still reads the SOURCE rather than the
    collapsed dict, which cannot see its own duplicates."""
    dead = duplicate_names()
    # WARN_RE's own reach: a real header (matched) and a fixture that
    # merely QUOTES the same words inside a string, never at column 0
    # (not matched — the adversarial test's own trap, restated here).
    real = 'warning[style.x]: a thing\n   ╭─[/a/b.av:12:3]\n'
    quoted = '            p.report().starts_with("warning[style.x]: a thing")\n'
    if not WARN_RE.search(real):
        dead.append("WARN_RE misses a real diagnostic header")
    if WARN_RE.search(quoted):
        dead.append("WARN_RE fires inside a fixture's own quoted string")
    for code, (matcher, _) in RULES.items():
        specimens = SPECIMENS.get(code)
        if specimens is None:
            dead.append(f"{code} has no specimen")
            continue
        for spec in specimens:
            if not list(matcher(spec)):
                dead.append(f"{code}'s matcher misses `{' / '.join(spec)[:52]}`")
        for spec in CLEAN.get(code, []):
            if list(matcher(spec)):
                dead.append(f"{code}'s matcher accuses the clean `{' / '.join(spec)[:52]}`")
    return dead


def sources():
    for base in SRC:
        for path in glob.glob(os.path.join(ROOT, base, "**", "*.av"), recursive=True):
            if not any(s in path for s in SKIP) and not is_program(path):
                yield path


def is_program(path):
    """A PROGRAM TEST IS A PROOF, NOT COMPILER CODE: the text it must
    print sits beside it, and the shape it proves is often the very
    one the bar forbids — `mut.av`'s subject IS a `mut`, `lists.av`'s
    IS an index walk. The bar reads what the compiler is written in."""
    return os.path.exists(path[: -len(".av")] + ".expected")

def licensed(lines, i, code):
    """A license lives AT the site: on the line or just above it."""
    for j in range(max(0, i - 2), i + 1):
        if re.search(rf"LICENSED {code}\b", lines[j]):
            return True
    return False

# A rule finding's rendered header, at the true start of its line —
# never inside a fixture's own quoted string, which reads the same
# text without starting a line (avra-8sb5.25.16's own attack: an
# adversarial test's report() assertion QUOTES this exact shape).
WARN_RE = re.compile(r"^warning\[([^\]]+)\]:[^\n]*\n\s*╭─\[([^:]+):(\d+):\d+\]", re.M)

def collected_rule_ids(binary):
    """Every rule the compiler carries, by identity — `avra rules
    --json` over the cli, whose closure links every rule. An empty
    answer is a failure, never an empty set: a filter that examined
    nothing would count nothing."""
    env = dict(os.environ, AVRA_WATCH_HELD="1", AVRA_CWD=os.path.join(ROOT, "packages", "cli"))
    out = subprocess.run([binary, "rules", "--json"], cwd=os.path.join(ROOT, "packages", "cli"),
                         env=env, capture_output=True, text=True, timeout=300).stdout
    ids = {r["id"] for r in json.loads(out or "[]")}
    if not ids:
        sys.exit("idioms: `avra rules --json` answered no rules — refusing to count native findings blind")
    return ids

def native_findings():
    """Every finding `avra check` reports on its own — a Bucket-A idiom
    ported as a `rule` (avra-8sb5.25.16) is enforced HERE, never by a
    second regex racing the compiler's own vocabulary.

    A finding counts when its kind IS a collected rule's id
    (`collected_rule_ids`): a rule's finding kind is its id by
    construction, so membership is the whole test and every other
    diagnostic is the compiler's own gate, never this ratchet's.

    A NATIVE finding reads no license at its site, ever — a rule
    carries no comment of its own, so a native finding either gets
    fixed or joins the baseline as accepted debt, reviewed once at
    adoption and every time after. There is no predecessor identity
    to honour a site comment under: every idiom is named by its rule,
    the same name for as long as the rule exists, so a `// LICENSED`
    comment beside a native finding is documentation for the reader,
    never a suppression the tool reads back.

    Fingerprinted the same way a matcher's finding is: by the site's
    own TEXT, never a line number, so an edit above a site does not
    churn the debt list."""
    binary = os.path.join(ROOT, "build", "avra")
    if not os.path.exists(binary):
        return {}, 0
    rule_ids = collected_rule_ids(binary)
    pkgs = sorted(set(os.path.dirname(p) for p in SRC))
    env = dict(os.environ, AVRA_WATCH_HELD="1")
    sites, checked = set(), 0
    for pkg in pkgs:
        try:
            out = subprocess.run([binary, "check", pkg], cwd=ROOT, env=env,
                                  capture_output=True, text=True, timeout=300).stdout
        except Exception:
            continue
        checked += 1
        for kind, path, line in WARN_RE.findall(out):
            if kind not in rule_ids:
                continue
            path = path if os.path.isabs(path) else os.path.join(ROOT, path)
            rel = os.path.relpath(path, ROOT)
            if any(s in rel for s in SKIP) or is_program(path):
                continue
            sites.add((kind, rel, int(line)))

    found = {}
    for kind, rel, line in sorted(sites):
        src_lines = open(os.path.join(ROOT, rel)).read().split("\n")
        code = "native:" + kind
        text = src_lines[line - 1].strip() if 0 < line <= len(src_lines) else ""
        n = 0
        key = f"{code}\t{rel}\t{text}#{n}"
        while key in found:
            n += 1
            key = f"{code}\t{rel}\t{text}#{n}"
        found[key] = (os.path.join(ROOT, rel), line, code)
    return found, checked

NATIVE = {"packages": 0}

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

    found = {}
    for path in sources():
        rel = os.path.relpath(path, ROOT)
        MODULE_BODY["text"] = bodies[os.path.dirname(path)]
        CURRENT["path"] = rel
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

    native, checked = native_findings()
    NATIVE["packages"] = checked
    found.update(native)
    return found

def load():
    if not os.path.exists(BASELINE):
        return set()
    return {l.rstrip("\n") for l in open(BASELINE)
            if l.strip() and not l.startswith("#")}

def save(fps):
    with open(BASELINE, "w") as f:
        f.write("# KNOWN idiom debt, one site per line. This file only ever\n")
        f.write("# SHRINKS: no tool path adds to it. A finding is fixed in the\n")
        f.write("# code, or annotated `// LICENSED <name>: reason` at the site —\n")
        f.write("# a `native:` finding reads no license of its own (a rule\n")
        f.write("# carries no comment of its own), so a `// LICENSED` comment\n")
        f.write("# beside one is the reader's documentation, never a\n")
        f.write("# suppression this tool honours: what sits below is either a\n")
        f.write("# RULE MATCHING ITS OWN QUOTE PATTERN (compiler/idioms.av's\n")
        f.write("# declarations — a structural artifact, since a pattern\n")
        f.write("# necessarily spells the shape it detects) or genuinely\n")
        f.write("# accepted debt, reviewed at adoption and every time after.\n")
        f.write("# `make idioms-accept` prunes what is gone. Burn it down.\n")
        for fp in sorted(fps):
            f.write(fp + "\n")

def registry_entries():
    """Every name the registry CLAIMS, in order, duplicates kept. The
    name must be followed by space or `(` — prose about a rule
    ("- lists.last_index's matcher was BLIND to…") is
    commentary, not an entry."""
    doc = os.path.join(ROOT, "DOGFOODING.md")
    return re.findall(r"^- ([a-z][a-z_]*(?:\.[a-z_]+)+)(?=[\s(])", open(doc).read(), re.M)

def registry_codes():
    return set(registry_entries())

def main():
    accept = "--accept" in sys.argv
    if "--rules" in sys.argv:
        print("ratcheted:", " ".join(sorted(RULES)))
        print("unratcheted:", " ".join(sorted(UNRATCHETED)))
        return 0
    # LAW 4: the registry may never outrun the ratchet.
    missing = registry_codes() - set(RULES) - set(UNRATCHETED)
    if missing:
        print(f"idioms: {', '.join(sorted(missing))} in DOGFOODING.md have no matcher")
        print("  add one to tools/idioms.py, or list it in UNRATCHETED with its reason.")
        return 1

    # LAW 4, THE OTHER DIRECTION: a rule the tool enforces but the
    # rulebook never states. `rule.loops.push_loop` was ratcheted and
    # licensed at 53 sites with no registry entry at all, so every one
    # of those licenses pointed at nothing.
    unstated = (set(RULES) | set(UNRATCHETED)) - registry_codes()
    if unstated:
        print(f"idioms: {', '.join(sorted(unstated))} enforced with no entry in DOGFOODING.md")
        print("  the registry IS the spec — write the rule where a reader will look for it.")
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
            if code.startswith("native:"):
                kind = code[len("native:"):]
                print(f"  {os.path.relpath(path, ROOT)}:{line}  [{kind}] a native rule finding")
                print(f"      `avra check` names the law in full; fix it, or accept it into the baseline")
            else:
                print(f"  {os.path.relpath(path, ROOT)}:{line}  [{code}] {RULES[code][1]}")
                print(f"      write the idiomatic form, or annotate: // LICENSED {code}: <reason>")
        return 1

    by_code = {}
    for fp in base & set(found):
        by_code[fp.split("\t")[0]] = by_code.get(fp.split("\t")[0], 0) + 1
    tally = " ".join(f"{c}={n}" for c, n in sorted(by_code.items()))
    note = f"; {len(gone)} fixed — `make idioms-accept` banks it" if gone else ""
    # A KEEPER COUNTS WHAT IT LOOKED AT AND SAYS SO. A check that
    # examined nothing is not a check that passed, and the only way a
    # reader can tell the two apart is the number.
    files = list(sources())
    print(f"idioms: no new violations. debt {len(base) - len(gone)} ({tally}){note}"
          f" — {len(files)} file(s) in {len(SRC)} package(s) scanned, "
          f"{NATIVE['packages']} native-checked")
    return 0

sys.exit(main())
