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
# The compiler's own C. Every other source comes from the manifest of
# the package that owns it.
TREE_SOURCES = ["runtime/avra_runtime.c", "backend/llvm_wrapper.c"]


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


def typedefs(sources):
    """Each typedef name and EVERY spelling it may stand for.

    A vendored header defines one name in several preprocessor
    branches — `__int64` for one compiler, `long long int` for
    another — so the name keeps them all and a verdict is only given
    when they agree.
    """
    out = {}
    for rel in sources:
        for m in TYPEDEF.finditer(open(os.path.join(ROOT, rel)).read()):
            body, name = m.group(1).strip(), m.group(2)
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
        return {text}
    out = set()
    for w in named:
        for body in tds[w]:
            out |= spellings(" ".join(body if x == w else x for x in words), tds, depth + 1)
    return out or {text}


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

def externs():
    """Every `extern fn NAME(...) -> TYPE` the tree declares."""
    out = []
    for path in glob.glob(os.path.join(ROOT, "packages/**/*.av"), recursive=True):
        # `export extern fn` too: a PACKAGE's wall is exported by
        # definition, since the point of it is that callers reach it.
        # Matching only the bare spelling made the keeper structurally
        # blind to every binding package — it had only ever been asked
        # about the compiler's own walls, which are un-exported.
        for m in re.finditer(r"^(?:export )?extern fn ([A-Za-z_][A-Za-z_0-9]*)\s*\([^)]*\)\s*->\s*(\w+)",
                             open(path).read(), re.M):
            out.append((m.group(1), m.group(2), os.path.relpath(path, ROOT)))
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
]
FIXTURE = """
#if defined(_MSC_VER)
  typedef __int64 sqlite_int64;
#else
  typedef long long int sqlite_int64;
#endif
typedef sqlite_int64 sqlite3_int64;
"""


def self_test():
    """The cases above, against the fixture's typedefs. A failure here
    means the keeper's model moved, and every verdict it gives is
    suspect until it is explained."""
    tds = {}
    for m in TYPEDEF.finditer(FIXTURE):
        body, name = m.group(1).strip(), m.group(2)
        if name != body and body:
            tds.setdefault(name, set()).add(body)
    bad = [(d, c, want) for d, c, want in CASES if agrees(d, c, tds) != want]
    for declared, ctype, want in bad:
        reads = " | ".join(sorted(spellings(ctype, tds)))
        print(f"externs: SELF-TEST — `{ctype}` under a `{declared}` seat should "
              f"{'satisfy' if want else 'fail'} it; it reads as {reads}")
    return len(bad)


def main():
    if self_test():
        print("externs: the keeper's own cases fail — its verdicts are not to be trusted")
        return 1
    vendored, packages = package_sources()
    sources = TREE_SOURCES + vendored
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
    if narrow or voids:
        if narrow:
            print(f"externs: {len(narrow)} extern(s) disagree with their C body's width")
        if voids:
            print(f"externs: {len(voids)} extern(s) read an answer their C body does not give")
        return 1
    unchecked = len(wall) - len(ours)
    note = f"; {unchecked} bind C we do not own (the sized types are their answer)" if unchecked else ""
    widths = sum(1 for _, t, _ in wall if t in ("i32", "u32", "i64"))
    scanned = f"{len(sources)} C source(s)"
    if packages:
        scanned += f", {len(vendored)} of them owned by {len(packages)} linking package(s)"
    extra = f"; {widths} name a width" if widths else ""
    print(f"externs: {len(ours)} extern(s) match their C body's width{note}{extra}")
    print(f"externs: read {scanned}; {len(CASES)} of the keeper's own cases hold")
    return 0

sys.exit(main())
