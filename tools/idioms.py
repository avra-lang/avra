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

# I40: a shape a TYPE LITERAL spells — a word, or Opt/List/Map/Res
# over words and plain names — interned by hand. The fold that gives
# the literal its meaning (core/types.av's `interned`) is the one
# place that spells the shapes; everywhere else is the smell.
SPELLED_PART = r"(?:\w+|Type\.(?:Int|Float|Bool|Str|Ptr|Void))"
SPELLED_SHAPE = re.compile(
    r"\.intern\(Type\.(?:Int|Float|Bool|Str|Ptr|Void)\)"
    r"|\.intern\(Type\.(?:Opt|List)\(" + SPELLED_PART + r"\)\)"
    r"|\.intern\(Type\.(?:Map|Res)\(" + SPELLED_PART + r", " + SPELLED_PART + r"\)\)")

def spelled_shape(lines):
    """A structural shape interned by hand where `.type(T)` spells it (I40)."""
    if CURRENT["path"].endswith("core/types.av"):
        return
    for i, l in enumerate(lines):
        if SPELLED_SHAPE.search(l):
            yield i, l.strip()

# I43: a fact column sized from an arena's count, or an id read
# through a hand offset — the two halves of a hand-kept side table.
HAND_SIZED = re.compile(r"filled[<(][^;]*\.count\(\)|\.index - ")

def hand_sized_column(lines):
    """A column sized by an arena's count, or an id minus a window's
    base (I43). A COMMENT IS NOT A SITE: the loops suite quotes the
    old spelling to say what once trapped."""
    for i, l in enumerate(lines):
        s = l.strip()
        if s.startswith("//"):
            continue
        if HAND_SIZED.search(l):
            yield i, s

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

# A REAL count pins a number: `== n`, or the testing verbs that pin
# it for you. `>= 1` is not a count — it is I30's smell.
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

# The `>= 1` spelling of a refusal count, in every costume the tree
# has worn it: `refusals(src) >= 1`, `a.diagnostics.length >= 1`,
# `p.diagnostics >= 1`, `p.voices.list.length >= 1`.
AT_LEAST_ONE = re.compile(
    r"(refusals\(.*\)|diagnostics(\.length)?|voices\.list\.length) >= 1\b")

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
    hold one (`fn(A, B) -> C`)."""
    out, depth, start = [], 0, 0
    for j, c in enumerate(seats):
        if c in "(<":
            depth = depth + 1
        elif c in ")>":
            depth = depth - 1
        elif c == "," and depth == 0:
            out.append(seats[start:j])
            start = j + 1
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

REGION_EMIT = re.compile(r"cx\.emit\(Ins\.(IfStart|ArmEnd|RegionEnd|LoopStart|LoopCond|LoopEnd)\b")

def raw_region(lines):
    """A region or loop instruction emitted raw by a feature. The
    emission vocabulary (features/emit.av) speaks it: `open_region`,
    `arm_end`, `close_region`/`close_region_as`; `loop_start`,
    `loop_cond`, `loop_end` and the walk — one instruction stream for
    both engines by construction. The vocabulary's own body is exempt."""
    if CURRENT["path"].endswith("features/emit.av"):
        return
    for i, l in enumerate(lines):
        if REGION_EMIT.search(l):
            yield i, l.strip()

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

# THE PASS STATES: the structs whose impl IS their vocabulary. A verb
# over one is a method (`cx.open_region(c)`), never a free fn taking
# the state first (`open_region(cx, c)`) — the rule reaches the pass's
# own files (features/*.av, language/*.av), where the shared
# vocabularies live; a feature dir's rule bodies dispatch on the
# state and stay free. A new state struct joins here when its impl
# becomes its vocabulary.
STATES = r"TypeCx|LowerCx|ResolveCx|Survey|Workspace|Decls|Builder|Body|Scope"
STATE_VERB = re.compile(r"^(?:export )?fn \w+\((?:mut )?\w+: (?:" + STATES + r")\b")
PASS_FILES = re.compile(r"packages/std-avrac/src/(features|language)/[^/]+\.av$")

def state_verb(lines):
    """A vocabulary verb written as a free fn taking a pass state
    first — the state's impl is where it belongs (I39)."""
    if CURRENT["path"] and not PASS_FILES.search(CURRENT["path"]):
        return
    for i, l in enumerate(lines):
        if STATE_VERB.match(l):
            yield i, l.strip()

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
TESTS_ONLY = {"I20": "it is a law about how a REFUSAL is asserted",
              "I30": "it is a law about how a REFUSAL is asserted"}

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
    "I48": (bool_comprehension,
            "a comprehension over a LIST folded to a bool — that is a scan: "
            "`xs.all(pred)` stops at the first answer and builds nothing"),
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
            "a name imported and never used in its MODULE — the compiler "
            "refuses a missing one, never an unused one"),
    "I23": (dead_parameter,
            "a parameter nothing reads — the signature lies, and every call site "
            "carries the lie"),
    "I22": (registry_catchall,
            "2+ variants answer, so this is a REGISTRY — a catch-all here forgets "
            "the NEXT variant; spell the arms (or-runs keep it affordable), or "
            "write `rest ->` to say the remainder is deliberate"),
    "I19": (index_walk,
            "an index walk over a list — `for (j, x) in xs.enumerate()` hands over both"),
    "I20": (uncounted_refusal,
            "a refusal test with no diagnostics COUNT — a cascade can hide behind it"),
    "I30": (line_rx(AT_LEAST_ONE.pattern),
            "a refusal asserted as `>= 1` — a cascade of five passes it; pin the "
            "count (`refused_with`, `refused_n`, or `== n`)"),
    "I21": (unmutated_mut,
            "a `mut` nothing mutates — say `let`"),
    "I38": (comma_list_open,
            "a grammar comma list with no trailing-comma option — `( \",\" x )*` ends `\",\"?`"),
    "I33": (raw_region,
            "a region instruction emitted raw in a feature — speak emit.av's verb "
            "(open_region / arm_end / close_region)"),
    "I28": (line_rx(r"pointed\(error_at\("),
            "a refusal assembled by hand — the one shape is "
            "`refusal(kind, at, message, label, help)`"),
    "I26": (repeated_unwrap,
            "one nullable local forced open 3+ times — guard once, bind once, "
            "and read the name"),
    "I16": (seen_accumulator,
            "a seen-accumulator — a dup is `xs.index_of(x) < j` over enumerate"),
    "I35": (line_rx(r"cx\.emit\(Ins\.Scope(Enter|Exit)\(|\.out\.give\(Ins\.Scope(Enter|Exit)\("),
            "a raw scope bracket through a lowering context — the frame verbs "
            "(`scope_enter`/`scope_exit`, `seats_enter`/`seats_exit`, `arm_stmts`) "
            "are the spelling; a raw bracket is invisible to the `defer` frames"),
    "I36": (line_rx(r"^\s*(\w+) = \1 \+ (\"|\(|\w+\.substring\()"),
            "text grown by `s = s + piece` — quadratic; a `@std/text` builder "
            "(`builder()`, `push`, `built`) or `repeat`/`pad_*` says it in linear time"),
    "I39": (state_verb,
            "a vocabulary verb as a free fn taking a pass state first — the state's "
            "impl is its vocabulary: write `mut fn verb(…)` there and call `cx.verb(…)`"),
    "I40": (spelled_shape,
            "a structural type interned by hand — `intern(Type.Opt(intern(Type.Str)))` — "
            "where a type literal spells it: `cx.type(string?)`, `types.type(List<elem>)`"),
    "I43": (hand_sized_column,
            "a fact column sized by hand, or an id read through an offset — "
            "`SideTable<V>` states the window, the growth and the out-of-window "
            "defect once: `side_table(name, lo, hi, seed)`, `get(id)`, `grow_to(n)`"),
}

UNRATCHETED = {
    "I47": "no grep tells a COMPLETE anchor list from a partial one — the anchors\n"
           "           are whatever the grammar can put in the range, so a helper taking\n"
           "           `List<Token>` of names reads identically whether or not the span\n"
           "           between them holds members of another kind. The keeper is the\n"
           "           attack: write the optional piece on the LAST member of one group\n"
           "           with another group following, and read it back through the\n"
           "           printer (annotations_adversarial_test.av, \"payload marks —\n"
           "           alignment\")",
    "I46": "no grep tells a question about a STATEMENT from a question about the\n"
           "           DECLARATION in hand — both read `decl(d).stmt`, and which one a\n"
           "           law is asking is semantic. The keeper is a test that pins the\n"
           "           COUNT over a member carrying a declaration of its own: a record\n"
           "           field with a DEFAULT is minted on its owner's statement, so a\n"
           "           per-decl walk asks its owner's question a second time",
    "I45": "no grep tells \"declares a derive and nothing else\" from an ordinary\n"
           "           file with a trait in it — the shape that breaks it is whatever\n"
           "           ELSE the file holds. The keeper is the law in CLAUDE.md and the\n"
           "           first build that tries: the annotated file loses its methods and\n"
           "           every caller is blamed",
    "I44": "no grep tells a BOUNDARY registry from any other list of rows, and a\n"
           "           reader that spells slot names or a writer that spells literal tags\n"
           "           reads as ordinary code. The keeper is the boundary check itself:\n"
           "           crossing_test.av moves each crossed shape and demands the refusal\n"
           "           name the one that moved",
    "I49": "no grep links two fns as INVERSES, so nothing textual sees a pack\n"
           "           learning a category its unpack has not. The keeper is `make\n"
           "           vocab`: both directions are named as consumers of the SAME\n"
           "           registry enum, and a catch-all or an `is` test inside either\n"
           "           fails the gate whichever direction grew the hole",
    "I42": "no grep tells a READ site from a SEAT site — `shape_at` is correct at\n"
           "           one and a defect at the other, and both spellings live beside each\n"
           "           other in the same file. The keeper is the adversarial suite:\n"
           "           named_adversarial_test.av reaches every vocabulary a name can\n"
           "           stand over, and a row reading the wrong door fails there",
    "I41": "an unwritable spelling as a key is a NAMING choice — the smell is\n"
           "           an in-band tag a program could write, which no grep tells from\n"
           "           an honest name; the review round hunts it",
    "I27": "RETIRED: a string's `.length` is a load — the header carries the\n"
           "           length — so a re-measure in a loop condition costs nothing and\n"
           "           the hoists that stand are harmless",
    "I25": "RETIRED: the compiler refuses a wrong payload count (F2015) on\n"
           "           patterns and constructions, one-line enums included — a\n"
           "           law now, and a matcher would only repeat it",
    "I32": "a whole-table scan for a keyed subset and a legitimate one-shot walk\n"
           "           over the same table are the same text; what makes the scan a smell\n"
           "           is being asked per query, which only a profile can see. `sample`\n"
           "           hunts it — it found the two that named the rule",
    "I31": "a stolen doc and a legitimate multi-paragraph header are the SAME\n"
           "           shape: a sentence ends, the next line opens with `A`/`The`. The\n"
           "           difference is whether the second paragraph ELABORATES the one\n"
           "           definition or DEFINES another — semantic, not syntactic. A first\n"
           "           matcher printed 78 hits; the two inspected split one real\n"
           "           (workspace's `shown`) and one legitimate (`full_type`). The\n"
           "           review round hunts it, as it did the five that named the rule",
    "I1":  "the accumulator DECLARATION is a weak proxy: stacks, folds, range\n"
           "           fills and enumerate walks all declare one. I3 matches the real\n"
           "           smell — a loop whose whole body is one push — and catches every\n"
           "           map I1 did, without 42 false positives",
    "I2":  "the evaluated-payload chain died with the eval collapse; no sites can exist",
    "I8":  "the spelled ritual and the only legitimate way to USE stmt_value are\n"
           "           textually identical — every hit was the verb's own body or a\n"
           "           site needing the id afterward. The review round hunts it",
    "I5":  "the remaining folds are duplicate DETECTION (they emit on the dup)",
    "I37": "a matcher cannot see whether a predicate has EFFECTS — `all` would\n"
           "           short-circuit past a binding the fold must perform, and only a\n"
           "           human can tell that from a pure test",
    "I6":  "head-plus-tail builds are subsumed by I1 and I3",
    "I10": "name->value if-ladders are too varied to grep — the review round hunts them",
    "I17": "a name serving two masters is semantic — no text pattern can see it",
    "I29": "mint order is STRUCTURE, not a greppable string: whether a\n"
    "        verb's answer register mints before or after its scratch\n"
    "        registers needs the emission sequence, not a pattern",
    "I34": "the matcher needs the enclosing fn's scope (a read of the\n"
           "           field BEFORE the write) — the read-then-write scan lives\n"
           "           in lane C's S4c-2 landing; liveness (S3) retires the idiom",
}

# A rule that cannot fire is worse than no rule: it reports success
# forever. Every matcher must catch its own specimen, checked on every
# run — this caught I18 shipping with a regex that could not span a
# nested call.
# WHAT A RULE MUST *NOT* FIRE ON — THE KEEPER'S OTHER SURFACE, in one
# table. Making a rule fail exercises only what it refuses; every
# spelling it ACCEPTS is a claim too, and the accepted shape nobody
# fixtured is exactly where a false positive lives unseen, because the
# rule is working and nobody looks. Two kinds of entry, one concept:
# an HONEST SPELLING a matcher must permit (a dead alternative widens
# the rule — `refused_n(` was one), and a CLEAN SHAPE it must not
# accuse (both I21 entries were live accusations against code the
# compiler requires).
#
# THEY WERE TWO TABLES, `ACCEPTED` and `CLEAN`, AND THE SECOND KILLED
# THE FIRST: two `CLEAN = {…}` bindings landed in one file a week
# apart, Python kept the later, and the I21, I23 and I48 fixtures of
# the earlier one stopped being checked with nothing to see. That is
# this file's own duplicate-number hazard one level up — the guard
# below now reads its own source for a table defined twice, as it
# already does for a number claimed twice.
CLEAN = {
    "I20": [
        ['        then "k" {', '            a.report().contains("x") && a.diagnostics.length == 1'],
        ['        then "k" {', '            a.report().contains("x") && a.voices.length == 1'],
        ['        then "k" {', '            a.report().contains("x") && refusals(src) == 1'],
        ['        then "k" {', '            a.report().contains("x") && refused_with(src, "x")'],
        ['        then "k" {', '            a.report().contains("x") && refused_n(p, "x", 1)'],
    ],
    "I21": [["    mut pr = attacked()?",
             "    pr.s.turn(ms(20))?"],
            ["    mut w = held()",
             "    w.c.buf = grown"]],
    "I23": [["fn tf_path(line: string) -> string { read(line, (q: Request) -> q.path()) }"],
            ["fn ro() -> int { flags_of(config_at(\"x\") with { mode: Mode.ReadOnly }) }"],
            ["fn f(a: int) -> int { g(a) with { b: 1 } }"]],
    "I48": [["    [covers_seg(x[j], y[j]) for j in 0..n].all(it)"],
            ["    [self.stage_seat(k, slots[i]) for i, k in sig.params].all(it)"],
            ["    [f(x) for x in xs if p(x)].any(it)"]],
}

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
    "I48": [["    r.status <= 999 && [writable(h) for h in r.headers].all(it)"],
            ["    [b.ieq_at(0, b.length, w) for w in written_by].any(it)"],
            ["    ![names_one_of(h.name, reply_writes()) for h in r.headers].any(it)"]],
    "I14": [["    cx.emit(d)", "    cx.intern(Type.Error)"]],
    "I15": [["    v.push(name)", "    let f = go()", "    let _ = v.pop()"]],
    "I16": [["    mut seen: List<string> = []", "    if seen.contains(x) { }", "    seen.push(x)"]],
    "I18": [["    cx.emit(Ins.ConstBool(dst, truth_of(cx.store.expr(e)) ?? false))"],
            ['    let v = text_of(node) ?? ""']],
    "I19": [["    for j in 0..args.length {", "        let a = args[j]", "    }"]],
    "I20": [['        then "it refuses" {', '            let a = analyze_source("x")',
             '            a.report().contains("nope")', "        }"],
            ['        then "it refuses" {', '            let a = analyze_source("x")',
             '            a.diagnostics.length >= 1 && a.report().contains("nope")', "        }"]],
    "I30": [['            refusals("x") >= 1'],
            ['            refusals(src) >= 1'],
            ['            a.diagnostics.length >= 1 && a.report().contains("nope")'],
            ["            p.diagnostics >= 1"],
            ["            p.voices.list.length >= 1 && lets.length == 2"]],
    "I21": [["    mut registry = new_type_registry()", "    let n = registry.shapes.length"]],
    "I22": [["    match s {", "        .A(x) -> x,", "        .B(y) -> y,", "        _ -> null,", "    }"]],
    "I23": [["fn f(a: int, b: int) -> int {", "    a + a", "}"],
            ["    fn m(self, a: int, b: int) -> int {", "        a + a", "    }"],
            ["    fn m(self, a: int) -> int { 1 }"]],
    "I24": [["use core.{Span}"]],
    "I38": [['            stmt = "fn" n:NAME "(" ( ps:NAME ( "," ps:NAME )* )? ")" END -> fn_decl(n, ps)'],
             ['            primary = "[" ( a:expression ( "," a:expression )* )? "]" -> lit(a)']],
    "I33": [["    cx.emit(Ins.IfStart(c))"], ["        cx.emit(Ins.ArmEnd(v))"], ["    cx.emit(Ins.RegionEnd(dst, last))"], ["    cx.emit(Ins.LoopStart)"], ["    cx.emit(Ins.LoopCond(more))"], ["    cx.emit(Ins.LoopEnd)"]],
    "I28": [['    cx.emit(pointed(error_at("k", at, "m"), "l"))']],
    "I26": [["fn f(x: int?) -> int {", "    if x == null { return 0 }",
             "    x! + x! + x!", "}"],
            ["    mut fn m(x: int?) -> int {", "        if x == null { return 0 }",
             "        x! + x! + x!", "    }"]],
    "I35": [["    cx.emit(Ins.ScopeEnter(Level.Application))"],
            ["    cx.emit(Ins.ScopeExit(null))"],
            ["    lo.out.give(Ins.ScopeExit(r))"]],
    "I36": [['        out = out + " "'],
            ["            text = text + src.substring(j, j + 1)"],
            ["            out = out + (unescaped(text.char_code(j + 1)) ?? text.substring(j, j + 2))"]],
    "I39": [["export fn open_region(mut cx: LowerCx, cond: Reg) {"],
            ["fn sig(ws: Workspace, d: DeclId) -> FnSig? {"],
            ["fn fields_zipped(b: Builder, fs: List<Token>) -> Result<List<Param>, string> {"]],
    "I43": [["    mut walked: List<bool> = filled(view.store.exprs.count(), false)"],
            ["        of_expr: filled<TypeId>(store.exprs.count(), hole),"],
            ["    fn type_at(e: ExprId) -> TypeId { self.of_expr[e.index - self.lo] }"]],
    "I40": [["    let str = cx.view.types.intern(Type.Str)"],
            ["    cx.view.types.intern(Type.Opt(held))"],
            ["    self.types.intern(Type.Map(cx.view.types.intern(Type.Str), want))"]],
}

def next_free_code():
    """The next free I-number, from this file's own text and from
    DOGFOODING's registry — the sources `duplicate_numbers` reads.

    NOBODY SHOULD HAVE TO GREP FOR THIS. A registry that refuses a
    repeat while staying silent about what is FREE makes every author
    work the answer out alone, and two lanes working it out the same
    day is exactly how I33 landed twice. The keeper knows; it says so.
    AND IT TAKES THE EXTREME, NEVER A GAP: highest-plus-one is robust
    to an instrument that under-reports the middle of a list, which a
    literal search over a computed spelling always is.
    """
    seen = set(_CODE.findall(open(__file__).read()))
    reg = os.path.join(ROOT, "DOGFOODING.md")
    if os.path.exists(reg):
        seen |= set(_CODE.findall(open(reg).read()))
    return max((int(n) for n in seen), default=0) + 1

_CODE = re.compile(r"\bI(\d+)\b")

def duplicate_numbers():
    """A number claimed twice in any table, read from this file's own
    text — the dict has already dropped the loser by the time it runs."""
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
        claimed = re.findall(r'^\s{4}"(I\d+)"\s*:', body, re.M)
        for code in sorted(set(claimed)):
            if claimed.count(code) > 1:
                out.append(code + " is claimed " + str(claimed.count(code)) + " times in " + table + " — the later one silently wins")
    # and the REGISTRY, which is the spec this tool implements: a
    # number claimed twice there sends every `LICENSED I<n>` at those
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
    passed straight over — I7 could not see a dotted receiver, I3
    could not see a one-line loop, I4 could not see a generic with
    two parameters, and I26 counted field unwraps as locals. A rule
    claims a SHAPE, so every spelling of that shape belongs here.

    It also refuses a REPEATED NUMBER. Two lanes numbered a new idiom
    the same day and both landed I33: a duplicate key in a dict
    literal is legal Python, the later one wins, and the earlier rule
    vanishes — the emission law went unenforced for a whole window
    while this tool reported success. A collapsed dict cannot see its
    own duplicates, so the check reads the SOURCE."""
    dead = duplicate_numbers()
    for spelling in COUNTS:
        if not COUNTED.search(spelling):
            dead.append(f"I20 does not accept the count `{spelling}`")
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

def registry_entries():
    """Every number the registry CLAIMS, in order, duplicates kept. The
    number must be followed by space or `(` — prose about a rule
    ("- I7's matcher was BLIND to…") is commentary, not an entry."""
    doc = os.path.join(ROOT, "DOGFOODING.md")
    return re.findall(r"^- (I\d+)(?=[\s(])", open(doc).read(), re.M)

def registry_codes():
    return set(registry_entries())

def numbered(codes):
    """Idiom codes in numeric order."""
    return sorted(codes, key=lambda c: int(c[1:]))

def main():
    accept = "--accept" in sys.argv
    if "--rules" in sys.argv:
        print("ratcheted:", " ".join(numbered(RULES)))
        print("unratcheted:", " ".join(numbered(UNRATCHETED)))
        return 0
    # LAW 4: the registry may never outrun the ratchet.
    missing = registry_codes() - set(RULES) - set(UNRATCHETED)
    if missing:
        print(f"idioms: {', '.join(sorted(missing))} in DOGFOODING.md have no matcher")
        print("  add one to tools/idioms.py, or list it in UNRATCHETED with its reason.")
        return 1

    # LAW 4, THE OTHER DIRECTION: a rule the tool enforces but the
    # rulebook never states. I3 was ratcheted and licensed at 53 sites
    # with no registry entry at all, so every one of those licenses
    # pointed at nothing.
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
          f" — {len(files)} file(s) in {len(SRC)} package(s), next free I{next_free_code()}")
    return 0

sys.exit(main())
