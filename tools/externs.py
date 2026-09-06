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

Until the spec's sized integer types land (Axis 15.2: `i32`, `u32`
map to fixed-width C types), the rule is: a C body we own that an
`extern` reads as `int` MUST answer a 64-bit type or a pointer. This
keeper enforces it over our own C. It cannot see a THIRD party's
headers, so a binding to someone else's library still needs the
sized types — this closes our half.
"""
import re, sys, glob, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
C_SOURCES = ["runtime/avra_runtime.c", "backend/llvm_wrapper.c"]

# a return type whose value fills the whole 64-bit register
WIDE = re.compile(r"(\*|\b(int64_t|uint64_t|long|size_t|ssize_t|ptrdiff_t|intptr_t|uintptr_t|"
                  r"LLVM[A-Za-z]*Ref)\b)")

# `void` is NOT wide — it is a different defect. A C body that answers
# nothing, read as `int`, hands the program whatever the register held;
# that is an answer which does not exist rather than one of the wrong
# size, so it gets its own words.
VOID = re.compile(r"^void$")

def c_returns():
    """Every C function we define, by name, with its written return type."""
    out = {}
    for rel in C_SOURCES:
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

def main():
    bodies, wall = c_returns(), externs()
    ours = [(n, t, w) for n, t, w in wall if n in bodies]
    voids = [(n, t, w) for n, t, w in ours
             if t != "void" and VOID.match(bodies[n][0])]
    for name, avty, where in voids:
        ctype, crel, cline = bodies[name]
        print(f"externs: {name} answers C `void` at {crel}:{cline}, read as `{avty}` in {where}")
        print(f"externs:   there is no value to read — the program takes whatever the")
        print(f"externs:   register happened to hold. Declare it without an answer.")
    narrow = [(n, t, w) for n, t, w in ours
              if t == "int" and not WIDE.search(bodies[n][0]) and not VOID.match(bodies[n][0])]
    for name, _, where in narrow:
        ctype, crel, cline = bodies[name]
        print(f"externs: {name} answers C `{ctype}` at {crel}:{cline}, read as `int` in {where}")
        print(f"externs:   a narrow C return writes only the low 32 bits — a negative value")
        print(f"externs:   reads as a large positive `int`. Answer `int64_t`.")
    if narrow or voids:
        if narrow:
            print(f"externs: {len(narrow)} extern(s) narrower than the `int` they are read as")
        if voids:
            print(f"externs: {len(voids)} extern(s) read an answer their C body does not give")
        return 1
    unchecked = len(wall) - len(ours)
    note = f"; {unchecked} bind C we do not own (the sized types are their answer)" if unchecked else ""
    print(f"externs: {len(ours)} extern(s) match their C body's width{note}")
    return 0

sys.exit(main())
