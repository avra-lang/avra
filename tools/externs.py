#!/usr/bin/env python3
"""THE EXTERN WALL'S WIDTH KEEPER.

Avra's `int` is 64 bits; C's `int` is 32. An `extern fn f() -> int`
is declared `i64` at the seam (language/llvm.av's `declare_externs`),
but a C body answering a narrow type writes only the low half — and
neither ABI promises the bits above it. Both compilers materialise a
32-bit result with a 32-bit write, which ZEROES the upper half, so a
negative C `int` reads as a large positive Avra `int`.

MEASURED (2026-09-05): a C `int` returning -1 reads as 4294967295,
INT_MIN reads as 2147483648, and `f() == 0 - 1` answers false. BOTH
ENGINES AGREE on the wrong answer, so `eval == native` cannot catch
it — that property is AGREEMENT, never correctness.

THE SIZED TYPES HAVE LANDED. A seat may now name the machine width
its C prototype uses (`i32`, `u32`, `i64`), and the value crossing is
still an Avra `int` — A WIDTH IS A PROPERTY OF A SEAT, NOT OF A
VALUE. So the rule is no longer "every C body must be wide": it is
that the DECLARATION and the BODY must agree.

  declared `int` / `i64`  ->  a C return that fills the register
  declared `i32`          ->  a 32-bit SIGNED C type
  declared `u32`          ->  a 32-bit UNSIGNED C type
  declared `ptr`/`string` ->  a pointer

AND THE SOURCE LIST IS THE MANIFEST'S, NOT THIS SCRIPT'S. The old
limit — "it cannot see a THIRD party's headers" — was never about
third parties; it was about C that lives OUTSIDE THE TREE. VENDORED
C is in the tree, so a package that vendors an amalgamation gets the
same declaration-level check its own runtime gets, and the keeper
covers a wall it did not write. The list follows the package that
owns the C.

IT IS DECLARATION-LEVEL AND CALLS NOTHING, on purpose. A behavioural
checker gives a FALSE GREEN here: this libc's `atoi` is
`(int)strtol(...)`, so it answers -1 correctly through a narrow
extern, while a hand-written `int f(void){return -1;}` at -O2 answers
4294967295 — same prototype, opposite answers. The defect is
callee-dependent and invisible to any test that runs the callee it
happens to have. Only the declaration can be held to account.
"""
import re, sys, glob, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# The compiler's own C — GLOBBED, not listed. A hand-written list is a
# registry that silently forgets its next member, and this one would
# have: the first new file under `runtime/` would have had every
# extern in it unchecked, with the keeper reporting green.
def tree_sources():
    found = []
    for d in ("runtime", "backend"):
        for path in sorted(glob.glob(os.path.join(ROOT, d, "*.c"))):
            found.append(os.path.relpath(path, ROOT))
    return found


# a C return whose value fills the whole 64-bit register
WIDE = re.compile(r"(\*|\b(int64_t|uint64_t|long|size_t|ssize_t|ptrdiff_t|intptr_t|uintptr_t|"
                  r"__int64|LLVM[A-Za-z]*Ref)\b)")

# `void` is NOT wide — it is a different defect. A C body that answers
# nothing, read as `int`, hands the program whatever the register held;
# that is an answer which does not exist rather than one of the wrong
# size, so it gets its own words.
VOID = re.compile(r"^void$")

# a C return that is 32 bits, by signedness — the two differ in
# nothing but how the answer is extended, which is the whole of it
I32 = re.compile(r"^(signed\s+)?(int|int32_t)$")
U32 = re.compile(r"^(unsigned(\s+int)?|uint32_t)$")
PTR = re.compile(r"(\*|\bLLVM[A-Za-z]*Ref\b)")

# what each DECLARED Avra answer demands of the C body it names
DEMANDS = {
    "int":    (lambda t: bool(WIDE.search(t)), "fills the 64-bit register",
               "declare the seat `i32` or `u32` — or answer `int64_t`"),
    "i64":    (lambda t: bool(WIDE.search(t)), "fills the 64-bit register",
               "answer `int64_t`, or declare the seat at the width the body uses"),
    "i32":    (lambda t: bool(I32.match(t)), "is a 32-bit signed type",
               "the seat says `i32`, so the body must answer `int` or `int32_t`"),
    "u32":    (lambda t: bool(U32.match(t)), "is a 32-bit unsigned type",
               "the seat says `u32`, so the body must answer `unsigned` or `uint32_t`"),
    "ptr":    (lambda t: bool(PTR.search(t)), "is a pointer",
               "the seat says `ptr`, so the body must answer one"),
    "string": (lambda t: bool(PTR.search(t)), "is a pointer",
               "the seat says `string`, so the body must answer a `char*`"),
}


# C THE TREE DID NOT WRITE names its widths through TYPEDEFS and
# prefixes its returns with a MACRO, and a keeper that reads the
# SPELLING sees neither. Both are resolved from the same sources it
# already reads — a LIST of known names would be right for SQLite and
# wrong for the next library, which is the defect this keeper exists
# to catch, one domain over.
TYPEDEF = re.compile(r"^\s*typedef\s+([A-Za-z_][A-Za-z_0-9 ]*?)\s+([A-Za-z_][A-Za-z_0-9]*)\s*;", re.M)

# A C macro is conventionally SHOUTED and no C base type is, so an
# all-caps word in a return type is noise. `LLVMValueRef` and friends
# carry lowercase and survive; `signed` is kept, since `signed int` is
# a spelling the 32-bit rule reads.
NOISE = re.compile(r"^(const|static|extern|inline|register|volatile|[A-Z][A-Z0-9_]*)$")

# A macro standing where a TYPE belongs, which is a different thing
# from one decorating a declaration. `SQLITE_API int` is an attribute
# and its `int` survives stripping; `unsigned SQLITE_INT64_TYPE` IS
# the type, and stripping leaves `unsigned` — a 32-bit reading of a
# 64-bit branch. Corruption, not abstention.
MACRO = re.compile(r"^[A-Z][A-Z0-9_]*$")


def typedefs(sources):
    """Each typedef name and EVERY spelling it may stand for.

    A vendored header defines one name in several preprocessor
    branches — `__int64` for one compiler, `long long int` for
    another — so the name keeps them all and a verdict is only given
    when they agree.
    """
    out = {}
    for rel in sources:
        typedefs_from(open(os.path.join(ROOT, rel)).read(), out)
    return out


def typedefs_from(text, out):
    """ONE collection, so the self-test below exercises the rule the
    tree runs and not a copy of it — a copy is how a test agrees with
    a bug."""
    for m in TYPEDEF.finditer(text):
            body, name = m.group(1).strip(), m.group(2)
            # A BRANCH WHOSE TYPE IS A MACRO TAUGHT NOTHING, and no
            # information is not DISAGREEMENT. A vendored header names
            # a width through a macro the USER may supply
            # (`typedef SQLITE_INT64_TYPE sqlite_int64;`), and there is
            # no reading of it here — counting it as a dissenting vote
            # refused every sibling branch that DID say something.
            # It abstains, and its siblings decide.
            # THE LIMIT, which cannot be closed from source: if the
            # user's macro names a NARROW type, the siblings are wrong
            # about it. A width nobody wrote down is not knowable.
            if any(MACRO.match(w) for w in body.split()):
                continue
            if name != body and body:
                out.setdefault(name, set()).add(body)
    return out


def spellings(ctype, tds, depth=0):
    """A written return type with its macros dropped and its typedefs
    expanded: every way it can read. A chain deeper than four answers
    unresolved, which FAILS rather than guesses."""
    words = [w for w in ctype.replace("*", " * ").split() if not NOISE.match(w)]
    text = " ".join(words)
    named = [w for w in words if w in tds]
    if not named or depth > 4:
        # A BRANCH THAT STRIPS TO NOTHING TAUGHT THE KEEPER NOTHING,
        # and no information is not DISAGREEMENT. A vendored header
        # defines a width in a branch whose whole body is a macro the
        # user may supply (`typedef SQLITE_INT64_TYPE sqlite_int64;`),
        # and counting that silence as a dissenting vote refused every
        # typedef standing beside it. It abstains instead.
        # THE TEETH ARE IN `agrees`, NOT HERE: a type that resolves to
        # NOTHING AT ALL yields an empty set, which is not "every
        # reading agrees" — it fails, as an unreadable type must.
        # THE LIMIT, since it cannot be closed from source: if the
        # user's macro names a NARROW type, that branch is judged by
        # its siblings. A width nobody wrote down is not knowable here.
        return {text} if text else set()
    out = set()
    for w in named:
        for body in tds[w]:
            out |= spellings(" ".join(body if x == w else x for x in words), tds, depth + 1)
    return out or ({text} if text else set())


def agrees(declared, ctype, tds):
    """Whether the C body satisfies the seat under EVERY reading of
    its type. One branch disagreeing is a disagreement."""
    test = DEMANDS[declared][0]
    forms = spellings(ctype, tds)
    return bool(forms) and all(test(f) for f in forms)


def package_sources():
    """C the PACKAGES own — every `.c` under a package that declares a
    `[link]` section.

    THE OWNER IS THE DIRECTORY, not a manifest key. `[link]` names
    `objects`, and there is no registered key for SOURCES yet — the
    compiler warns "`sources` is not a key of `[link]`" at anything
    invented, and rightly, since a key nobody registered is a silent
    green waiting to happen. So the rule is the honest one available
    today: a package that links native code owns the C beside it, and
    a vendored amalgamation checked into that package is checked like
    any other body we can read. When a package can declare its own
    native build (ROADMAP: B7), prefer the key it registers and let
    this fall back.

    Returns the paths AND the packages walked, because a package that
    stops being scanned must show up as a number that fell rather than
    as silence.
    """
    found, seen = [], []
    for man in sorted(glob.glob(os.path.join(ROOT, "packages/**/avra.toml"), recursive=True)):
        if not re.search(r"^\[link\]", open(man).read(), re.M):
            continue
        pkg = os.path.dirname(man)
        seen.append(os.path.relpath(pkg, ROOT))
        for path in sorted(glob.glob(os.path.join(pkg, "**/*.c"), recursive=True)):
            found.append(os.path.relpath(path, ROOT))
    return found, seen


def c_returns(sources):
    """Every C function we define, by name, with its written return type."""
    out = {}
    for rel in sources:
        text = open(os.path.join(ROOT, rel)).read()
        for m in re.finditer(r"^([A-Za-z_][A-Za-z_0-9 ]*?[ *])\s*([A-Za-z_][A-Za-z_0-9]*)\s*\(", text, re.M):
            out[m.group(2)] = (m.group(1).strip(), rel, text.count("\n", 0, m.start()) + 1)
    return out

# WHERE AN EXTERN CAN BE DECLARED. `packages/` alone left the CORPUS
# unscanned, and corpus/native/externs.av is the file that
# DEMONSTRATES this seam — the one place a reader looks to learn what
# an extern may do. A keeper blind to its own subject's showcase is
# the untested-instrument shape: it had never been asked about the
# declarations most likely to be copied.
def declaring_sources():
    # AND THE GENERATORS. `tools/traps.sh` writes whole programs into
    # `build/traps/` from heredocs, and their `extern fn` lines are
    # declarations like any other — invisible to a glob over `.av`
    # because the file they live in has not been written yet. The
    # substrate lane found a missing host row inside one of those
    # programs, where no source grep could reach it. Reading the
    # GENERATOR is order-independent, where scanning its output would
    # depend on `make traps` having run first.
    return sorted(glob.glob(os.path.join(ROOT, "packages/**/*.av"), recursive=True)
                  + glob.glob(os.path.join(ROOT, "corpus/**/*.av"), recursive=True)
                  + glob.glob(os.path.join(ROOT, "tools/*.sh")))

def externs():
    """Every `extern fn NAME(...) -> TYPE` the tree declares."""
    out = []
    for path in declaring_sources():
        # `export extern fn` too: a PACKAGE's wall is exported by
        # definition, since the point of it is that callers reach it.
        # Matching only the bare spelling made the keeper structurally
        # blind to every binding package — it had only ever been asked
        # about the compiler's own walls, which are un-exported.
        for m in re.finditer(r"^(?:export )?extern fn ([A-Za-z_][A-Za-z_0-9]*)\s*\([^)]*\)\s*->\s*(\w+)",
                             open(path).read(), re.M):
            out.append((m.group(1), m.group(2), os.path.relpath(path, ROOT)))
    return out

def wall_seats():
    """Every `extern fn NAME(...)` the tree declares, with its seats.

    No `->` is required: an extern that answers nothing still FILLS
    seats, and those are exactly as wrong as any other when they
    disagree. The answer-side reader above is kept apart because it
    is keyed by the answer.
    """
    out = []
    for path in declaring_sources():
        for m in re.finditer(r"^(?:export )?extern fn ([A-Za-z_][A-Za-z_0-9]*)\s*\(([^)]*)\)",
                             open(path).read(), re.M):
            out.append((m.group(1), m.group(2), os.path.relpath(path, ROOT)))
    return out


# A C COMMENT STANDS WHERE A PARAMETER'S TYPE DOES. The amalgamation
# writes `sqlite3 **ppDb, /* OUT: SQLite db handle */ int flags`, and a
# split on commas hands the comment to the NEXT seat — which then reads
# as a pointer. The comment is dropped before anything is counted.
COMMENT = re.compile(r"/\*.*?\*/", re.S)

# The parameter's NAME, which C writes after its type and Avra writes
# before it. `int iCol` is an `int` seat; the name teaches nothing.
PARAM_NAME = re.compile(r"\b[A-Za-z_]\w*\s*$")


def c_signatures(sources, wanted):
    """The parameter list of every C function we DEFINE and also
    DECLARE, by name.

    The definition, never a prototype: a prototype may omit the seat
    names and the amalgamation carries both, so the body is the one
    spelling that must be true. It is looked up BY THE NAMES THE WALL
    ASKS ABOUT — a regex over nine megabytes of amalgamation costs
    more than the whole rest of this keeper, and every name it would
    find that no `extern fn` names is work nobody reads.
    """
    out = {}
    for rel in sources:
        text = open(os.path.join(ROOT, rel)).read()
        for name in wanted:
            if name in out:
                continue
            at = 0
            while True:
                at = text.find(name + "(", at)
                if at < 0:
                    break
                head = at + len(name)
                if at and (text[at - 1].isalnum() or text[at - 1] == "_"):
                    at = head
                    continue
                close, depth = head, 0
                while close < len(text):
                    if text[close] == "(":
                        depth += 1
                    elif text[close] == ")":
                        depth -= 1
                        if not depth:
                            break
                    elif text[close] == ";":
                        break
                    close += 1
                tail = text[close + 1:close + 40].lstrip()
                if close < len(text) and text[close] == ")" and tail[:1] == "{":
                    out[name] = (" ".join(COMMENT.sub(" ", text[head + 1:close]).split()),
                                 rel, text.count("\n", 0, at) + 1)
                    break
                at = head
    return out


def split_params(text):
    """A C parameter list, one entry per seat. Nested parens belong to
    a function-pointer seat and never separate one."""
    if text.strip() in ("void", ""):
        return []
    out, depth, cur = [], 0, ""
    for ch in text:
        if ch in "([":
            depth += 1
        if ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def seat_fits(seat, ctype, tds):
    """Whether an Avra PARAMETER seat matches the C seat it fills.

    THE SEAT IS READ WHOLE — `mut db: ptr?`, not its type alone —
    because `mut` is written before the NAME and a split on the colon
    drops it. A `mut X` seat IS a C `X*`: the out-parameter convention
    writes through one level of pointer, so the star is spent by the
    `mut` and what remains must match X. That is why `mut a: i32` over
    `int *a` is right and not a width defect.
    """
    name, _, declared = seat.partition(":")
    declared = declared.strip().rstrip("?")
    if name.strip().startswith("mut "):
        star = ctype.rfind("*")
        if star < 0:
            return False
        ctype = (ctype[:star] + ctype[star + 1:]).strip()
    if declared not in DEMANDS:
        return True          # a seat this keeper has no reading for abstains
    return agrees(declared, ctype, tds)


# AN EXTERN WHOSE C BODY MINTS AN OWNED BOX MUST BE A ROW. `owns_result`
# lives on a row in `rt_sigs()` and NOWHERE ELSE, so an `extern fn`
# whose name is not one is hard-coded to own nothing and the memory
# pass plans no release for what it mints. That is a silent leak: the
# evaluator leaked every float it rendered exactly so, and the HTTP
# lane leaked every socket read.
#
# THE TEST IS "MINTS", NOT "ANSWERS A MANAGED TYPE". Most externs
# answering text are CORRECT without a row — argv, a library's rodata,
# anything `str_static` made immortal — and refusing those would be a
# lint counting a proxy. `str_static` is excluded from the seeds for
# that reason: it allocates, and what it allocates must never be
# released.
MINTS = re.compile(r"\b(str_owned|box_alloc|sized_box|bytes_owned)\s*\(")
IMMORTAL = {"str_static"}


def c_bodies(sources):
    """Every C fn we can read, name -> its body text."""
    out = {}
    for rel in sources:
        out.update(bodies_in(open(os.path.join(ROOT, rel), errors="ignore").read()))
    return out




def owned_mints(bodies):
    """The C fns that hand back a box the caller must release —
    directly, or by RETURNING one that does."""
    mints = {n for n, b in bodies.items() if MINTS.search(b)} - IMMORTAL
    for _ in range(5):
        grown = set(mints)
        for n, b in bodies.items():
            if n in IMMORTAL:
                continue
            for m in mints:
                if re.search(r"\breturn\s+" + re.escape(m) + r"\s*\(", b):
                    grown.add(n)
        if grown == mints:
            break
        mints = grown
    return mints


def rows():
    """The names `rt_sigs()` carries — the only place `owns_result` is
    written."""
    text = open(os.path.join(ROOT, "packages/std-avrac/src/core/runtime_api.av")).read()
    return set(re.findall(r'RtSig \{ name: "([a-z_0-9]+)"', text))


def leaking_externs(wall, bodies, known):
    """Every declaration facing a minting body that is not a row."""
    minting = owned_mints(bodies)
    out = []
    for name, declared, where in wall:
        if name in minting and name not in known:
            out.append((name, declared, where))
    return out


# THE MINT RULE'S OWN CASES. This check lands GREEN on today's tree —
# no declaration faces a minting body without a row — so these cases
# are the ONLY evidence it looks at the right thing. `one_liner` is
# not decoration: bodies were scanned to the next line-starting brace,
# which a one-line body does not have, so it swallowed the definitions
# after it and twelve float helpers read as minting because a minter
# sat two definitions below them.
MINT_FIXTURE = """
static const char* str_static(const char* s) { char* b = sized_box(1, 1); return b; }
static const char* str_owned(const char* s, size_t n) { char* b = sized_box(n, 1); return b; }
static const char* float_text(double d) { char buf[40]; return str_owned(buf, 3); }
const char* answers_minted(int64_t bits) { return float_text(1.0); }
int64_t one_liner(int64_t a, int64_t b) { return as_bits(as_double(a) + as_double(b)); }
const char* answers_immortal(void) { return str_static("x"); }
int64_t answers_a_number(int64_t x) { return x + 1; }
"""

MINT_CASES = [
    ("str_owned", True),
    ("float_text", True),
    ("answers_minted", True),
    ("one_liner", False),
    ("answers_immortal", False),
    ("answers_a_number", False),
]


def bodies_in(text):
    """C fn bodies, brace-counted so a one-line body ends at its own
    closing brace rather than the next line-starting one."""
    out = {}
    for m in re.finditer(r"^(?:static\s+)?(?:const\s+)?[A-Za-z_][A-Za-z_0-9 \*]*?\b([a-z_][a-z_0-9]*)\s*\([^)]*\)\s*\{", text, re.M):
        depth, i, n = 1, m.end(), len(text)
        while i < n and depth:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        out[m.group(1)] = text[m.end():i - 1]
    return out


def mint_self_test():
    bad = [(n, w) for n, w in MINT_CASES if (n in owned_mints(bodies_in(MINT_FIXTURE))) != w]
    for name, want in bad:
        print(f"externs: SELF-TEST — `{name}` should {'MINT' if want else 'not mint'} an owned box")
    return len(bad)


def wrong_seats(wall, sigs, tds):
    """Every parameter seat that disagrees with the C body it fills,
    and every arity that does.

    THE RETURN WAS ONLY EVER HALF THE DECLARATION. This keeper read
    answers for its whole life while a wall's PARAMETERS went
    unchecked — and a vendored library's are where the widths
    actually live: 36 of @std/sqlite's seats named a 64-bit `int`
    over a C `int`, and the truncation is silent in both directions.
    """
    out = []
    for name, params, where in wall:
        if name not in sigs:
            continue
        cargs, crel, cline = sigs[name]
        # A VARIADIC BODY IS THE VARIADIC RULE'S, not this one's. Its
        # arity always "disagrees" — the ellipsis counts as a seat —
        # and reporting that beside the real law is a cascade: one
        # mistake, one message, and the arity is the symptom.
        if is_variadic(cargs):
            continue
        cp, ap = split_params(cargs), split_params(params)
        if len(ap) != len(cp):
            out.append((name, where, crel, cline, None, len(ap), len(cp)))
            continue
        for a, c in zip(ap, cp):
            if not seat_fits(a, PARAM_NAME.sub("", c).strip() or c, tds):
                out.append((name, where, crel, cline, (a, c), 0, 0))
    return out


# A `Bytes` SEAT IS THE CROSSING CHECK'S ONE EXEMPTION, and the
# PROTOTYPE EARNS IT — never the author's intention. A text seat the
# callee RESOLVES is scanned for an interior NUL and traps; a seat
# whose C prototype CARRIES ITS OWN LENGTH is `Bytes` and pays
# nothing. So the question is structural: can the body know where the
# bytes end?
#
# A prototype with NO integer seat after the pointer cannot know — it
# must scan for a NUL — so a `Bytes` there is the truncation the check
# exists to stop, wearing the exemption. `sqlite3_stricmp(const char*,
# const char*)` declared with `Bytes` seats answers EQUAL for "ab\0cd"
# and "ab\0ce"; `memcmp(a, b, n)` over the same five bytes does not.
#
# A PROTOTYPE IS NOT THE ONLY WAY A CALLEE KNOWS THE LENGTH, which
# this rule learned from the tree the hour it was written: three of
# our own seats carry no length and are RIGHT — `avra_str_len`,
# `avra_utf8_bad_at` and the frame's own `avra_ffi_set_bytes` read the
# Avra box's HEADER, which is core's C doing what §2.1 says only core
# may. So the exemption is earned by the callee KNOWING the length,
# from the prototype OR from the box; and a body this tree did not
# write knows only what its prototype says. The scope is vendored C.
#
# TWO LIMITS, STATED HERE RATHER THAN DISCOVERED LATER. An integer
# after the pointer may be a length or a flag and no spelling tells
# them apart, so `open(const char *, int)` passes. And a package's own
# C is trusted the way core's is, though nothing certifies it — the
# day a package writes a scanning body of its own, this abstains. The
# keeper refuses what PROVABLY scans and abstains where it cannot
# tell, which is the posture `seat_fits` takes one rule over.
def integer_seat(ctype):
    """Whether a C seat is an integer — a pointer never is."""
    if PTR.search(ctype):
        return False
    bare = ctype.strip()
    return bool(WIDE.search(bare) or I32.match(bare) or U32.match(bare))


def declared_of(seat):
    """The type an Avra seat names, without its `mut` or its `?`."""
    _, _, declared = seat.partition(":")
    return declared.strip().rstrip("?")


def foreign_body(crel):
    """Whether a C body is one this tree did not write — vendored
    under a package, by §3's own layout rule."""
    return "/vendor/" in crel.replace(os.sep, "/")


# THE KEEPER'S OTHER SURFACE, AND WHY IT IS A COUNT AND NOT A REFUSAL.
# The refusing half above is SOUND IN ONE DIRECTION ONLY: no integer
# after the pointer PROVES the body must scan, while an integer after
# it proves nothing — it may be a length or a flag, and
# `open(const char *, int)` declared `string` is correct and would be
# refused by the mirror rule. Measured on this tree: the mirror would
# fire ZERO times, because @std/sqlite's four length-carrying seats are
# already `Bytes`. A rule with no measurable true-positive rate and a
# known false-positive shape is F2040 again, so the other surface is
# WITNESSED rather than enforced — the count makes the migration
# visible and goes up when a seat earns its exemption.
def earned_octets(wall, sigs):
    out = []
    for name, params, where in wall:
        if name not in sigs:
            continue
        cargs, crel, cline = sigs[name]
        if is_variadic(cargs):
            continue
        cp, ap = split_params(cargs), split_params(params)
        if len(ap) != len(cp):
            continue
        for i, seat in enumerate(ap):
            if declared_of(seat) != "Bytes":
                continue
            after = [PARAM_NAME.sub("", c).strip() or c for c in cp[i + 1:]]
            if any(integer_seat(c) for c in after):
                out.append((name, seat))
    return out


def bytes_without_length(wall, sigs):
    out = []
    for name, params, where in wall:
        if name not in sigs:
            continue
        cargs, crel, cline = sigs[name]
        if not foreign_body(crel):
            continue
        if is_variadic(cargs):
            continue
        cp, ap = split_params(cargs), split_params(params)
        if len(ap) != len(cp):
            continue          # the arity rule speaks first
        for i, seat in enumerate(ap):
            if declared_of(seat) != "Bytes":
                continue
            after = [PARAM_NAME.sub("", c).strip() or c for c in cp[i + 1:]]
            if not any(integer_seat(c) for c in after):
                out.append((name, seat, where, crel, cline))
    return out


# A VARIADIC BODY CANNOT BE CALLED BY A FIXED DECLARATION, in either
# engine. Apple's arm64 ABI reads a variadic callee's arguments from
# the STACK while a fixed call puts them in REGISTERS, so the callee
# reads a slot nobody wrote — no link error, no trap, a wrong answer.
# The trailing `...` is the whole test: a `va_list` seat is an ordinary
# pointer and calls correctly, so it is NOT variadic here.
#
# THE NARROWING CONDITION, written where the keeper is rather than in a
# paper: this refuses for BOTH engines only while the grammar cannot
# spell a variadic seat. `declare` already takes LLVM's vararg flag and
# both call sites pass false, so today the native path is as wrong as
# the evaluator. The day an ellipsis seat exists and the backend passes
# that flag, this narrows to the interpreter alone and the wording
# above loses its last four words.
def is_variadic(cargs):
    """Whether a C parameter list ends in an ellipsis. Takes the list
    as written, newlines and all — a prototype spread over lines is
    the same list."""
    seats = split_params(" ".join(cargs.split()))
    return bool(seats) and seats[-1] == "..."


# (a C parameter list, variadic?) — both surfaces, because a keeper
# watched only refusing is half tested.
VARIADIC_CASES = [
    ("int op, ...", True),                          # sqlite3_test_control, the measured case
    ("sqlite3 *db, int op, ...", True),             # sqlite3_db_config
    ("...", True),                                  # the degenerate list
    ("const char *zFormat,\n  ...", True),          # spread over lines
    ("int op, va_list ap", False),                   # a va_list rides a pointer
    ("sqlite3 *db, int op, int a, int b", False),
    ("void", False),
    ("", False),
    ("void (*xFunc)(void*, int, char**)", False),   # parens are a fn-pointer seat
    ("const char *zDots", False),                    # a name is not an ellipsis
    ("struct dots ...x", False),                     # not a bare `...`
]


def variadic_self_test():
    """The readings above. A failure means the ellipsis model moved."""
    bad = [(c, want) for c, want in VARIADIC_CASES if is_variadic(c) != want]
    for cargs, want in bad:
        # THE MESSAGE COLLAPSES THE WHITESPACE THE CASE KEEPS. One case
        # spreads its list over lines to prove the newline does not
        # matter; printed as written, its failure is the one place it
        # looks like it does.
        print(f"externs: SELF-TEST — C `({' '.join(cargs.split())})` should read as "
              f"{'variadic' if want else 'fixed'}")
    return len(bad)


def variadic_walls(wall, sigs):
    """Every declaration whose C body is variadic — the fixed spelling
    that cannot call it."""
    return [(name, where, sigs[name][1], sigs[name][2], len(split_params(params)))
            for name, params, where in wall
            if name in sigs and is_variadic(sigs[name][0])]


# SHAPES ONE UNIFORM FRAME CANNOT CARRY, refused at the declaration
# for the same reason a variadic body is: the evaluator calls through
# ONE fully applied prototype of int64 and double slots, so a seat that
# rides another class, another width, or memory is read from a place
# nobody wrote. Each is detected POSITIVELY and by name — never as
# "not a scalar I recognise", which would refuse every typedef the
# keeper has not met and make the rule's true-positive rate its
# author's imagination.
#
# WHAT IS NOT COVERED, said out loud: a struct passed by value behind
# a TYPEDEF (`sqlite3_value v`) reads as an ordinary name here and
# passes. Catching it needs the typedef's target resolved to a struct,
# which `typedefs()` does not record. RECORDED TRIGGER: the first
# declaration that faces one — which cannot happen while an Avra seat
# can only be `int`, `ptr`, a width word or `float`, since none of
# those can name a struct.
UNFRAMEABLE = [
    # (a regex over one C seat or return, the words that name the law)
    (re.compile(r"\blong\s+double\b"),
     "a `long double` rides its own class, which the frame has no slot for"),
    (re.compile(r"\b__int128\b"),
     "an `__int128` rides a register PAIR, which the frame passes as one"),
    (re.compile(r"__attribute__\s*\(\s*\(\s*vector_size|\b__m(64|128|256|512)\b|\bfloat(32|64)x\d+_t\b"),
     "a vector rides its own file, which the frame does not fill"),
    (re.compile(r"^(const\s+|volatile\s+)*(struct|union)\s+[A-Za-z_]\w*\s*$"),
     "a struct or union BY VALUE classifies by field — it may split registers or ride memory"),
]

# An f32 SEAT is half of a `v` register and a double written there is
# read as a different number. An f32 RETURN is fine: the answer is read
# back through the declared width, not through a slot the caller filled.
F32_SEAT = re.compile(r"^(const\s+|volatile\s+)*float\s*$")


def unframeable(seat):
    """The law a C seat breaks, or None. Takes the seat with its name
    already stripped, as the width rules take it."""
    bare = " ".join(seat.split())
    if F32_SEAT.match(bare):
        return "an `f32` seat is half of a `v` register — a double written there reads as another number"
    for pattern, law in UNFRAMEABLE:
        if pattern.search(bare):
            return law
    return None


# (a C seat, the law it breaks or None) — both surfaces, as the
# variadic cases are.
FRAME_CASES = [
    ("long double", "long double"),
    ("const long double", "long double"),
    ("__int128", "__int128"),
    ("unsigned __int128", "__int128"),
    ("float", "f32"),
    ("const float", "f32"),
    ("struct sqlite3_index_info", "by value"),
    ("union u_tag", "by value"),
    ("double", None),                    # the class the frame DOES carry
    ("float *", None),                   # a pointer to f32 is a pointer
    ("struct sqlite3_index_info *", None),  # by reference is a pointer
    ("int", None),
    ("const char *", None),
    ("sqlite3_int64", None),             # a typedef to a word
    ("long", None),
]


def frame_self_test():
    """The readings above. A failure means the frame's model moved."""
    bad = []
    for seat, want in FRAME_CASES:
        got = unframeable(seat)
        hit = got is not None
        if hit != (want is not None) or (want and want not in got and want != "by value" and want != "f32"):
            bad.append((seat, want, got))
    for seat, want, got in bad:
        print(f"externs: SELF-TEST — C seat `{seat}` should "
              f"{'break the frame (' + want + ')' if want else 'ride the frame'}"
              f"; it reads as {got!r}")
    return len(bad)


def unframeable_walls(wall, sigs):
    """Every declaration whose C body has a seat the frame cannot
    carry."""
    out = []
    for name, params, where in wall:
        if name not in sigs:
            continue
        cargs, crel, cline = sigs[name]
        for c in split_params(cargs):
            law = unframeable(PARAM_NAME.sub("", c).strip() or c)
            if law:
                out.append((name, where, crel, cline, c.strip(), law))
                break
    return out


# A SYMBOL WITH NO READABLE SOURCE MAY NOT TAKE A DEFAULTED WIDTH.
# Every rule above reads the C BODY — the return's width, each seat's
# width, the ellipsis, the shapes one frame cannot carry. For a symbol
# this tree has no source for (libc, a system library, anything the
# manifest links but does not carry), all of them abstain, and the
# declaration is the only thing standing. So a bare `int` there is a
# 64-bit GUESS about a body nobody here compiled — and the guess is
# silent in both directions, since a C `int` answer of -1 read as a
# 64-bit `int` is 4294967295 and a 64-bit argument in an `int` seat
# arrives truncated. Naming the width converts an unverifiable default
# into a deliberate statement, which is the most the seam allows.
#
# ONLY `int` IS REFUSED. `ptr`, `string`, `float` and `bool` name no
# integer width, and `i32`/`u32`/`i64` name one already.
DEFAULTED = re.compile(r"^int$")

# The type a seat declares, with `mut` and the name stripped — a seat
# is written `name: type` and an inout `mut name: type`.
SEAT_TYPE = re.compile(r":\s*([^:]+)$")


def seat_type(seat):
    m = SEAT_TYPE.search(seat.strip())
    return m.group(1).strip() if m else seat.strip()


# (a declared Avra type, is it a defaulted width?) — both surfaces.
WIDTH_CASES = [
    ("int", True),
    ("i32", False), ("u32", False), ("i64", False),
    ("ptr", False), ("ptr?", False),
    ("string", False), ("string?", False),
    ("float", False), ("bool", False),
    ("List<string>", False),
]

# (a written seat, its type) — the stripping the rule depends on.
SEAT_TYPE_CASES = [
    ("a: int", "int"),
    ("mut out: i64", "i64"),
    ("vfs: string?", "string?"),
    ("mut db: ptr?", "ptr?"),
]


def width_self_test():
    """The readings above. A failure means the default's model moved."""
    bad = [(t, want) for t, want in WIDTH_CASES if bool(DEFAULTED.match(t)) != want]
    for t, want in bad:
        print(f"externs: SELF-TEST — a declared `{t}` should "
              f"{'be' if want else 'not be'} a defaulted width")
    stripped = [(w, want) for w, want in SEAT_TYPE_CASES if seat_type(w) != want]
    for written, want in stripped:
        print(f"externs: SELF-TEST — seat `{written}` should read its type as `{want}`, "
              f"read `{seat_type(written)}`")
    return len(bad) + len(stripped)


def defaulted_walls(wall, walls, bodies, sigs):
    """Every declaration over a symbol with NO readable source that
    leaves a width to the default."""
    out = []
    for name, declared, where in wall:
        if name not in bodies and DEFAULTED.match(declared):
            out.append((name, where, "its answer", declared))
    for name, params, where in walls:
        if name in sigs:
            continue
        for seat in split_params(params):
            t = seat_type(seat)
            if DEFAULTED.match(t):
                out.append((name, where, f"seat `{seat.strip()}`", t))
    return out


# THE KEEPER'S OWN CASES. This check spent its whole life reading C
# THIS TREE WROTE, which spells `int64_t` plainly — so its width set
# never met a typedef or a macro prefix, and it passed every day while
# structurally unable to see the case it was about to be asked to
# guard. The first vendored amalgamation produced 8 false positives on
# arrival. A keeper that has only ever guarded one domain is untested,
# so its readings are pinned here rather than left to the next
# vendored header to discover.
CASES = [
    # (declared, written C return, satisfied?)
    ("int",  "SQLITE_API sqlite3_int64", True),   # a typedef chain, through a macro
    ("int",  "sqlite_int64", True),               # the older spelling
    ("int",  "SQLITE_API int", False),            # genuinely narrow, macro or not
    ("i32",  "SQLITE_API int", True),             # the seat names the width
    ("i32",  "SQLITE_API sqlite3_int64", False),  # a wide body under a narrow seat
    ("u32",  "unsigned int", True),
    ("int",  "int64_t", True),
    ("int",  "const char *", True),               # a pointer fills the register
    ("ptr",  "SQLITE_API void *", True),
    # a branch whose whole body is a macro ABSTAINS: its siblings decide
    ("int",  "SQLITE_API sqlite3_uint64", True),
    # and a return type that is ONLY a macro resolves to nothing, which
    # is not agreement — the teeth the abstention must not file down
    ("int",  "SQLITE_API SOME_WIDTH", False),
]
# THE SEAT CASES, pinned for the same reason the answer cases are: the
# parameter side arrived with a vendored wall and its two hard readings
# — a comment standing where a type does, and a `mut` seat spending the
# C star — are exactly the ones a later edit would quietly lose.
SEAT_CASES = [
    # (declared seat, written C seat, fits?)
    ("col: i32",      "int iCol",                True),
    ("col: int",      "int iCol",                False),  # 64 over 32
    ("n: i64",        "int N",                   False),
    ("value: int",    "sqlite3_int64 iValue",    True),   # through the typedef
    ("escape: u32",   "unsigned int esc",        True),
    ("escape: i32",   "unsigned int esc",        False),  # signedness is a width
    ("db: ptr",       "sqlite3 *db",             True),
    ("vfs: string?",  "const char *zVfs",        True),
    ("mut db: ptr?",  "sqlite3 **ppDb",          True),   # the `mut` spends one star
    ("mut a: i32",    "int *a",                  True),
    ("mut a: i32",    "int a",                   False),  # nothing to write through
    ("ms: i32",       "int ms",                  True),
]


OCTET_CASES = [
    # (Avra seats, the C seats they fill, refused?)
    # Both surfaces: what the rule REFUSES and what it must ACCEPT.
    # An accepting path with no fixture is a dead alternative that
    # widens the keeper silently.
    ("a: Bytes, b: Bytes",         "const char *a, const char *b",           True),
    ("s: Bytes",                   "const char *s",                          True),
    ("b: Bytes, f: ptr",           "const void *b, FILE *f",                 True),
    ("a: Bytes, b: Bytes, n: i64", "const void *a, const void *b, size_t n", False),
    ("t: Bytes, n: i32",           "const char *t, int n",                   False),
    ("s: string, t: string",       "const char *s, const char *t",           False),
    ("d: ptr, t: Bytes, n: i32",   "sqlite3 *d, const char *t, int n",       False),
]

# The abstaining path needs its own fixture, or it is a dead
# alternative: a `Bytes` seat with no length over C THIS TREE WROTE
# passes, because the body may read the box's header.
OWN_OCTET_CASE = ("b: Bytes", "const char *s", "runtime/avra_runtime.c")


def octet_self_test():
    """The `Bytes` rule against whole prototypes, through the SAME
    function the tree runs — a fixture built from a copy of the rule
    would test the copy."""
    bad = []
    for params, cargs, want in OCTET_CASES:
        found = bytes_without_length([("f", params, "fixture.av:1")],
                                     {"f": (cargs, "packages/p/vendor/lib.c", 1)})
        if bool(found) != want:
            bad.append((params, cargs, want))
    params, cargs, crel = OWN_OCTET_CASE
    if bytes_without_length([("f", params, "fixture.av:1")], {"f": (cargs, crel, 1)}):
        bad.append((params, cargs, False))
    for params, cargs, want in bad:
        print(f"externs: SELF-TEST — `{params}` over C `{cargs}` should "
              f"{'be refused' if want else 'pass'}")
    return len(bad)


def seat_self_test():
    """The seat readings above, against the same typedefs. A failure
    means the parameter model moved."""
    tds = typedefs_from(FIXTURE, {})
    bad = [(d, c, want) for d, c, want in SEAT_CASES if seat_fits(d, PARAM_NAME.sub("", c).strip() or c, tds) != want]
    for declared, ctype, want in bad:
        print(f"externs: SELF-TEST — a `{declared}` seat over C `{ctype}` should "
              f"{'fit' if want else 'not fit'}")
    return len(bad)


FIXTURE = """
#ifdef SQLITE_INT64_TYPE
  typedef SQLITE_INT64_TYPE sqlite_int64;
  typedef unsigned SQLITE_INT64_TYPE sqlite_uint64;
#elif defined(_MSC_VER)
  typedef __int64 sqlite_int64;
  typedef unsigned __int64 sqlite_uint64;
#else
  typedef long long int sqlite_int64;
  typedef unsigned long long int sqlite_uint64;
#endif
typedef sqlite_int64 sqlite3_int64;
typedef sqlite_uint64 sqlite3_uint64;
"""


def self_test():
    """The cases above, against the fixture's typedefs. A failure here
    means the keeper's model moved, and every verdict it gives is
    suspect until it is explained."""
    tds = typedefs_from(FIXTURE, {})
    bad = [(d, c, want) for d, c, want in CASES if agrees(d, c, tds) != want]
    for declared, ctype, want in bad:
        reads = " | ".join(sorted(spellings(ctype, tds)))
        print(f"externs: SELF-TEST — `{ctype}` under a `{declared}` seat should "
              f"{'satisfy' if want else 'fail'} it; it reads as {reads}")
    return len(bad)


# A POINTER IS A CAPABILITY, so a `ptr`-answering extern must be READ
# and never abstained. This keeper reads C in the tree; a symbol whose
# prototype it cannot find is one it can hold to nothing, and for a
# pointer answer that abstention MINTS — `extern fn atoi(s: string) ->
# ptr?` reinterprets a C `int` as an address and checks clean, so
# deleting any one named minting door leaves the seam itself open.
# Abstention stays permission for every other answer and is refusal
# here.
def unread_pointers(wall, bodies):
    return [(n, t, w) for n, t, w in wall if t == "ptr" and n not in bodies]

PTR_CASES = [
    # (wall row, is the prototype readable, refused?)
    (("atoi", "ptr", "x.av"), False, True),      # libc: unreadable, minting
    (("avra_ptr_at", "ptr", "x.av"), True, False),  # ours: read, held to its C
    (("atoi", "int", "x.av"), False, False),     # unreadable but answers a width
    (("avra_now_ns", "int", "x.av"), True, False),
]

def ptr_self_test():
    for row, readable, want in PTR_CASES:
        bodies = {row[0]: ("void*", "r.c", 1)} if readable else {}
        got = bool(unread_pointers([row], bodies))
        if got != want:
            print(f"externs: ptr self-test failed on {row} readable={readable}: {got} != {want}")
            return 1
    return 0

# A ROW THAT RETAINS A SEAT MUST SAY WHICH WAY. Two bodies both call
# `avra_rc_retain` on a parameter and they mean opposite things:
# `avra_insist` retains and ANSWERS it, handing the reference to the
# caller (`owns_result`), while `avra_array_push_owned` retains and
# STORES it, so the value outlives the call (`keeps`). Nothing but the
# body tells them apart, so the registry's claim is checked against it
# here — an unmarked retainer would make its seat read as borrowed by
# anything that asks, and a wrongly-marked one makes every `!` unwrap
# look like an escape.
def seat_names(params):
    out = []
    for p in params.split(","):
        p = p.strip()
        if p and p != "void":
            out.append(p.split()[-1].lstrip("*"))
    return out

def seated_bodies(sources):
    """Every C fn we can read, name -> (its seat list, its body text).

    `c_bodies` answers the body alone; a keep is about WHICH SEAT, so
    this reads the parameter list beside it, brace-counted the same way.
    """
    out = {}
    for rel in sources:
        text = open(os.path.join(ROOT, rel), errors="ignore").read()
        for m in re.finditer(r"^(?:static\s+)?(?:const\s+)?[A-Za-z_][A-Za-z_0-9 \*]*?\b([a-z_][a-z_0-9]*)\s*\(([^)]*)\)\s*\{", text, re.M):
            depth, i, n = 1, m.end(), len(text)
            while i < n and depth:
                if text[i] == "{":
                    depth += 1
                elif text[i] == "}":
                    depth -= 1
                i += 1
            out[m.group(1)] = (m.group(2), text[m.end():i - 1])
    return out

def retaining_seats(bodies):
    """Every row body that takes its own reference to a seat."""
    out = {}
    for name, (params, body) in bodies.items():
        held = [i for i, p in enumerate(seat_names(params))
                if re.search(r"avra_rc_retain\(\s*" + re.escape(p) + r"\s*[,)]", body)]
        if held:
            out[name] = held
    return out

def sig_rows():
    """Each `rt_sigs()` row's name, `keeps` seats, and `owns_result`."""
    text = open(os.path.join(ROOT, "packages/std-avrac/src/core/runtime_api.av")).read()
    out = {}
    for m in re.finditer(r'RtSig \{ name: "([a-z_0-9]+)"(.*?) \},', text, re.S):
        keeps = re.search(r"keeps: \[([^\]]*)\]", m.group(2))
        marked = [i for i, v in enumerate(keeps.group(1).split(",")) if v.strip() == "true"] if keeps else []
        out[m.group(1)] = (marked, "owns_result: true" in m.group(2))
    return out

def unsaid_keeps(bodies, sigs):
    """Rows whose body retains a seat the row does not account for."""
    out = []
    for name, held in sorted(retaining_seats(bodies).items()):
        if name not in sigs:
            continue
        marked, owns = sigs[name]
        if marked == held or owns:
            continue
        out.append((name, held, marked, owns))
    return out

KEEP_CASES = [
    # (body params, body text, marked seats, owns_result, refused?)
    (("void* a, void* v", "avra_rc_retain(v);", [1], False), False),   # marked, stored
    (("void* a, void* v", "avra_rc_retain(v);", [], False), True),     # retains, says nothing
    (("void* p", "avra_rc_retain(p); return p;", [], True), False),    # answers it
    (("void* a, void* v", "return a;", [], False), False),             # retains nothing
]

def keep_self_test():
    for (params, body, marked, owns), want in KEEP_CASES:
        got = bool(unsaid_keeps({"r": (params, body)}, {"r": (marked, owns)}))
        if got != want:
            print(f"externs: keeps self-test failed on {body!r} marked={marked}: {got} != {want}")
            return 1
    return 0

# A ROW THAT RESOLVES ITS TEXT OUTSIDE THE PROGRAM IS NOT INERT.
# `inert: true` claims the row RESOLVES NOTHING — a NUL is data to it —
# and that claim is what exempts a seat from the crossing check. Where
# the body hands a text seat to the filesystem, the environment, or a
# spawn, a NUL is TWO NAMES and there is no correct answer, so the
# claim is false and the exemption is a hole waiting for the day
# someone reads the registry instead of the C.
# HAND-MARKING 81 ROWS IS WHAT THIS GUARDS. `avra_host_env` and
# `avra_io_env` have the same body — `getenv(name)` — and were marked
# oppositely by the pass that introduced the column; that is not a
# judgement anyone lost, it is what a hand sweep does at that size.
# WRITING, NOT RESOLVING: `puts`/`fputs` truncate output at a NUL,
# which is data loss rather than name ambiguity. They are left to
# judgement, so this refuses nothing a reasonable marking allows.
RESOLVING = re.compile(
    r"\b(getenv|setenv|fopen|freopen|open|open64|openat|creat|stat|lstat|fstatat"
    r"|access|faccessat|opendir|unlink|unlinkat|rmdir|mkdir|mkdirat|rename|renameat"
    r"|link|symlink|readlink|chdir|chmod|chown|truncate|utimes"
    r"|execv|execve|execvp|execl|execlp|execle|posix_spawn|posix_spawnp"
    r"|system|popen|dlopen|connect|bind|getaddrinfo|gethostbyname)\s*\(")

def inert_rows(text):
    """The rows the registry marks `inert: true`."""
    out = set()
    for m in re.finditer(r'RtSig \{ name: "([a-z_0-9]+)"(.*?) \},', text, re.S):
        if re.search(r"inert:\s*true", m.group(2)):
            out.add(m.group(1))
    return out

def resolving_inerts(bodies, inert):
    """Every row claiming `inert` whose C body resolves a text seat."""
    out = []
    for name in sorted(inert):
        if name not in bodies:
            continue
        params, body = bodies[name]
        if "char*" not in params and "char *" not in params:
            continue
        calls = sorted({m.group(1) for m in RESOLVING.finditer(body)})
        if calls:
            out.append((name, calls))
    return out

INERT_CASES = [
    # (params, body, marked inert, refused?)
    (("const char* n", "getenv(n);", True), True),    # io_env / host_env
    (("const char* p", "fopen(p, \"r\");", True), True),
    (("const char* p", "opendir(p);", True), True),
    (("const char* n", "getenv(n);", False), False),  # marked CHECKED: fine
    (("void* a, int64_t i", "return a;", True), False),   # no text seat
    (("const char* s", "fputs(s, stderr);", True), False),  # writes, not resolves
    (("const char* s", "return str_len(s);", True), False), # reads its own bytes
]

def inert_self_test():
    for (params, body, marked), want in INERT_CASES:
        rows = {"r"} if marked else set()
        got = bool(resolving_inerts({"r": (params, body)}, rows))
        if got != want:
            print(f"externs: inert self-test failed on {body!r} inert={marked}: {got} != {want}")
            return 1
    return 0

def main():
    if self_test() + seat_self_test() + octet_self_test() + variadic_self_test() + frame_self_test() + width_self_test() + mint_self_test() + ptr_self_test() + keep_self_test() + inert_self_test():
        print("externs: the keeper's own cases fail — its verdicts are not to be trusted")
        return 1
    vendored, packages = package_sources()
    sources = tree_sources() + vendored
    bodies, wall = c_returns(sources), externs()
    tds = typedefs(sources)
    ours = [(n, t, w) for n, t, w in wall if n in bodies]
    voids = [(n, t, w) for n, t, w in ours
             if t != "void" and all(VOID.match(f) for f in spellings(bodies[n][0], tds))]
    for name, avty, where in voids:
        ctype, crel, cline = bodies[name]
        print(f"externs: {name} answers C `void` at {crel}:{cline}, read as `{avty}` in {where}")
        print(f"externs:   there is no value to read — the program takes whatever the")
        print(f"externs:   register happened to hold. Declare it without an answer.")
    narrow = [(n, t, w) for n, t, w in ours
              if t in DEMANDS and not all(VOID.match(f) for f in spellings(bodies[n][0], tds))
              and not agrees(t, bodies[n][0], tds)]
    for name, declared, where in narrow:
        ctype, crel, cline = bodies[name]
        _, wanted, remedy = DEMANDS[declared]
        print(f"externs: {name} answers C `{ctype}` at {crel}:{cline}, declared `{declared}` in {where}")
        print(f"externs:   a declared `{declared}` needs a C return that {wanted}")
        print(f"externs:   {remedy}")
    walls = wall_seats()
    sigs = c_signatures(sources, {n for n, _, _ in walls})
    varargs = variadic_walls(walls, sigs)
    for name, where, crel, cline, an in varargs:
        print(f"externs: {name} declares {an} fixed seat(s) in {where}, "
              f"its C body is VARIADIC at {crel}:{cline}")
        print(f"externs:   a variadic callee reads its arguments from the stack and a")
        print(f"externs:   fixed call passes them in registers, so no fixed declaration")
        print(f"externs:   calls this body correctly — in either engine.")
        print(f"externs:   One fixed extern per argument shape is NOT the way out: it")
        print(f"externs:   was measured reading 12345 back as -298729216.")
    guessed = defaulted_walls(wall, walls, bodies, sigs)
    for name, where, at, declared in guessed:
        print(f"externs: {name} in {where} leaves {at} as `{declared}`, "
              f"and this tree has no C source for it")
        print(f"externs:   nothing checks a width the keeper cannot read, so a bare `int`")
        print(f"externs:   is a 64-bit guess about a body nobody here compiled — a C `int`")
        print(f"externs:   answer of -1 reads as 4294967295, and a 64-bit argument in an")
        print(f"externs:   `int` seat arrives truncated. Name it: `i64` where the C says")
        print(f"externs:   `long` or `int64_t`, `i32`/`u32` where it says `int`/`unsigned`.")
    unframed = unframeable_walls(walls, sigs)
    for name, where, crel, cline, seat, law in unframed:
        print(f"externs: {name} in {where} faces C seat `{seat}` at {crel}:{cline}, "
              f"which one frame cannot carry")
        print(f"externs:   {law} — so the evaluator would read a slot nobody wrote.")
        print(f"externs:   Pass it by pointer, or leave the symbol to the native path.")
    seats = wrong_seats(walls, sigs, tds)
    for name, where, crel, cline, pair, an, cn in seats:
        if pair is None:
            print(f"externs: {name} declares {an} seat(s) in {where}, "
                  f"its C body takes {cn} at {crel}:{cline}")
            print(f"externs:   a call fills seats the body never reads, or leaves its own unfilled")
            continue
        a, c = pair
        print(f"externs: {name} seats `{a}` in {where} over C `{c}` at {crel}:{cline}")
        print(f"externs:   the seat and the body must name the same width — a C `int` is 32 bits")
    earned = earned_octets(walls, sigs)
    octets = bytes_without_length(walls, sigs)
    for name, seat, where, crel, cline in octets:
        print(f"externs: {name} seats `{seat}` in {where} over C at {crel}:{cline}")
        print(f"externs:   its C carries no length after that pointer, so the body must scan")
        print(f"externs:   to a NUL — a `Bytes` seat there wears the crossing check's exemption")
        print(f"externs:   without earning it. Declare the seat `string` and let it be checked.")
    minting = unread_pointers(wall, bodies)
    for name, declared, where in minting:
        print(f"externs: {name} answers `ptr` in {where} and no C in the tree declares it")
        print(f"externs:   a pointer from a body this keeper cannot read is an address minted")
        print(f"externs:   from whatever the register held — the width check abstains and the")
        print(f"externs:   abstention is what grants it. Name it in tree C, or answer its width.")
    if narrow or voids or seats or varargs or unframed or guessed or minting or octets:
        if octets:
            print(f"externs: {len(octets)} `Bytes` seat(s) face a C body that carries no length")
        if minting:
            print(f"externs: {len(minting)} extern(s) answer a pointer no C body here declares")
        if guessed:
            print(f"externs: {len(guessed)} declaration(s) guess a width over a symbol this tree cannot read")
        if unframed:
            print(f"externs: {len(unframed)} extern(s) face a C seat one frame cannot carry")
        if varargs:
            print(f"externs: {len(varargs)} extern(s) face a variadic C body with a fixed spelling")
        if seats:
            print(f"externs: {len(seats)} parameter seat(s) disagree with their C body")
        if narrow:
            print(f"externs: {len(narrow)} extern(s) disagree with their C body's width")
        if voids:
            print(f"externs: {len(voids)} extern(s) read an answer their C body does not give")
        return 1
    api = open(os.path.join(ROOT, "packages/std-avrac/src/core/runtime_api.av")).read()
    loud = resolving_inerts(seated_bodies(sources), inert_rows(api))
    for name, calls in loud:
        print(f"externs: {name} is marked `inert` and its C body calls {', '.join(calls)}")
        print(f"externs:   `inert` claims the row RESOLVES NOTHING, which is what exempts its")
        print(f"externs:   seat from the crossing check. A NUL in a name it resolves is TWO")
        print(f"externs:   names and no correct answer — the row is not inert.")
    if loud:
        print(f"externs: {len(loud)} row(s) claim `inert` over a body that resolves")
        return 1

    if earned:
        print(f"externs: {len(earned)} `Bytes` seat(s) earn the exemption from a length in the prototype")
    unsaid = unsaid_keeps(seated_bodies(sources), sig_rows())
    for name, held, marked, _ in unsaid:
        print(f"externs: {name} retains seat(s) {held} in C, its row marks {marked or 'none'}")
        print(f"externs:   a body that RETAINS a seat either KEEPS it — stored past the call,")
        print(f"externs:   `keeps` — or ANSWERS it, `owns_result`. Unsaid, the seat reads as")
        print(f"externs:   borrowed and whatever asks about escape is told the wrong thing.")
    if unsaid:
        print(f"externs: {len(unsaid)} row(s) retain a seat their row does not account for")
        return 1

    leaks = leaking_externs(wall, c_bodies(sources), rows())
    for name, declared, where in leaks:
        print(f"externs: {name} is declared in {where} and its C body MINTS an owned box")
        print(f"externs:   `owns_result` lives on a row in `rt_sigs()` and nowhere else, so")
        print(f"externs:   this declaration owns nothing and the memory pass plans no release")
        print(f"externs:   for what it makes. Give it a row, or answer text it does not own.")
    if leaks:
        print(f"externs: {len(leaks)} extern(s) mint a box no row accounts for")
        return 1

    unchecked = len(wall) - len(ours)
    note = f"; {unchecked} bind C we do not own, every width named" if unchecked else ""
    widths = sum(1 for _, t, _ in wall if t in ("i32", "u32", "i64"))
    scanned = f"{len(sources)} C source(s)"
    if packages:
        scanned += f", {len(vendored)} of them owned by {len(packages)} linking package(s)"
    extra = f"; {widths} name a width" if widths else ""
    print(f"externs: {len(ours)} extern(s) match their C body's width{note}{extra}")
    checked = sum(len(split_params(p)) for n, p, _ in walls if n in sigs)
    print(f"externs: {checked} parameter seat(s) match the C seat they fill")
    print(f"externs: no declaration faces a variadic C body, nor a seat the frame cannot carry")
    print(f"externs: read {scanned}; "
          f"{len(CASES) + len(SEAT_CASES) + len(OCTET_CASES) + len(VARIADIC_CASES) + len(FRAME_CASES) + len(WIDTH_CASES) + len(SEAT_TYPE_CASES) + len(MINT_CASES) + len(PTR_CASES) + len(KEEP_CASES) + len(INERT_CASES)} of the keeper's own cases hold")
    return 0

sys.exit(main())
