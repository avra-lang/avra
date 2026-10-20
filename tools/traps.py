#!/usr/bin/env python3
"""THE TRAPS COLUMN'S KEEPER.

`RtSig.traps` (packages/std-avrac/src/core/ir.av) says whether a runtime row
can raise a trap a guard catches. A row that cannot is declared `nounwind`,
so a call of it is given no unwind edge and the cleanups of the frame around
it are skipped when it traps. A WRONG `false` IS THEREFORE SILENT: the trap
is still caught, and the frame's deferred calls never run.

The column defaults to `false`, so a row says `traps: true` exactly when it
can trap, and this keeper holds the C to that in BOTH directions:

  - a row that reaches a trap and does not say `traps: true` is refused,
    with the chain that reaches it;
  - a row that says `traps: true` and reaches none is refused.

A row reaches a trap through any C fn its body calls (the runtime's own,
inlined leaves included) that calls `avra_trap` or a sibling, `abort` or
`exit`; or that calls a name the keeper cannot classify (a function pointer, a
hook, a host import), which may run Avra code and so may trap. A name is
classified safe in `SAFE` below.

A sink call that is fatal by design — a limit or a defect of the process,
never a trap the language raises — carries its decision where the call is:

    avra_trap("..."); // LICENSED traps.process_limit: <why>

(`traps.process_limit`: memory, a ceiling; `traps.defect`: the runtime's own
layout found corrupt.) A marker on a line with no sink is refused, so one
cannot outlive the call it excuses.
"""
import re, sys, glob, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SINKS = re.compile(r"^(avra_trap\w*|abort|exit|_exit)$")
LICENSE = re.compile(r"LICENSED\s+traps\.(process_limit|defect)\b")
KEYWORDS = {"if", "while", "for", "switch", "return", "sizeof", "defined", "__builtin_expect",
            "__builtin_unreachable", "__builtin_offsetof", "_Static_assert", "typeof", "__typeof__"}
# Callees that run no Avra code and raise no language trap: the C library, the
# compiler's builtins, the runtime's own macros, and the two C function-pointer
# params (`text`, `source`) that only ever name C fns. A callee not here and not
# defined in the runtime is a call out, which may trap.
SAFE = set("""
__atomic_add_fetch __atomic_load_n __atomic_store_n __builtin_memcpy __builtin_return_address
_dyld_get_image_header _dyld_get_image_vmaddr_slide atoi calloc clock_gettime close closedir
dirfd dl_iterate_phdr epoll_wait fclose fcntl fflush fopen fork fprintf fputc fputs fread free
fseek fstat ftell fwrite getenv getpid getsectiondata isfinite kevent longjmp mallinfo2 malloc
malloc_size malloc_usable_size malloc_zone_statistics memchr memcmp memcpy memmem memmove memset
mmap munmap open opendir pipe qsort raise read readdir realloc sched_getaffinity setjmp snprintf
strcmp strerror strlen strtod strtoll sysconf utimes va_arg va_end va_start waitpid write
AVRA_CALLER CENSUS CPU_COUNT IS_IMMORTAL KIND_IMMORTAL KIND_SHAPE MB S_ISREG WEXITSTATUS WIFEXITED
WIFSIGNALED WTERMSIG volatile
text source
""".split())


def declared_rows():
    """Each runtime row of runtime_api.av: name -> whether it says `traps: true`."""
    text = open(os.path.join(ROOT, "packages/std-avrac/src/core/runtime_api.av")).read()
    out = {}
    for m in re.finditer(r'name:\s*"(avra_\w+)",(.*?)\n\s{8}\},', text, re.S):
        out.setdefault(m.group(1), bool(re.search(r"\btraps:\s*true\b", m.group(2))))
    return out


def c_bodies():
    """fn name -> (file, body text), over the runtime's C and headers."""
    bodies = {}
    paths = sorted(glob.glob(os.path.join(ROOT, "runtime", "*.c")) + glob.glob(os.path.join(ROOT, "runtime", "*.h")))
    head = re.compile(r"^[A-Za-z_][\w\s\*]*?\b(\w+)\s*\([^;{}]*\)[^;{}]*\{", re.M)
    for path in paths:
        text = open(path).read()
        for m in head.finditer(text):
            name = m.group(1)
            if name in KEYWORDS:
                continue
            depth, i = 1, m.end()
            while i < len(text) and depth:
                depth += (text[i] == "{") - (text[i] == "}")
                i += 1
            bodies.setdefault(name, (os.path.relpath(path, ROOT), text[m.end():i]))
    return bodies


def code_of(line):
    """A line's code: string and char literals and the line comment are not calls."""
    line = re.sub(r'"(\\.|[^"\\])*"|\'(\\.|[^\'\\])*\'', '""', line)
    return line.split("//")[0]


def lines_of(body):
    """The body's lines with block comments blanked, newlines kept."""
    return re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), body, flags=re.S).split("\n")


def line_calls(body):
    """(callee, licensed) for every call in `body`, by line: a call on a line that carries
    a LICENSED traps marker is licensed."""
    out = []
    for line in lines_of(body):
        licensed = bool(LICENSE.search(line))
        for c in re.findall(r"\b([A-Za-z_]\w*)\s*\(", code_of(line)):
            if c not in KEYWORDS:
                out.append((c, licensed))
    return out


def reaches(row, bodies):
    """The first way `row` reaches a trap, as a chain, or None. A trap is a sink not
    licensed where it stands, or a callee that is neither defined here nor SAFE."""
    seen, stack = set(), [(row, [row])]
    while stack:
        fn, chain = stack.pop()
        if fn in seen or fn not in bodies:
            continue
        seen.add(fn)
        for callee, licensed in line_calls(bodies[fn][1]):
            if SINKS.match(callee):
                if not licensed:
                    return chain + [callee]
            elif callee in bodies:
                stack.append((callee, chain + [callee]))
            elif callee not in SAFE:
                return chain + [callee + " (a call out)"]
    return None


def stray_licenses(bodies):
    """A LICENSED traps marker on a line that calls no sink."""
    out = []
    for fn, (path, body) in bodies.items():
        for line in lines_of(body):
            if LICENSE.search(line) and not any(SINKS.match(c) for c in re.findall(r"\b([A-Za-z_]\w*)\s*\(", code_of(line))):
                out.append(f"traps: {path}: a LICENSED traps marker in `{fn}` sits on a line that calls no trap: {line.strip()[:80]}")
    return out


def judged(rows, bodies):
    """Every refusal for `rows` (name -> says `traps: true`) over `bodies`."""
    refused = []
    for row, says in sorted(rows.items()):
        if row not in bodies:
            refused.append(f"traps: {row} has no C body this keeper can read")
            continue
        chain = reaches(row, bodies)
        if chain and not says:
            refused.append(f"traps: {row} reaches a trap and does not say `traps: true`: " + " -> ".join(chain))
        if says and not chain:
            refused.append(f"traps: {row} says `traps: true` and reaches no trap")
    return refused


def selftest():
    """The keeper's own cases, on a synthetic C: a direct trap, a chain through a helper
    and a call out are found, a clean body is quiet, a licensed sink is excused, a `true`
    row with no trap and a trapping row without `true` are refused, a marker with no sink
    and a row with no body are refused."""
    synthetic = {
        "row_direct": ("x.c", "if (i < 0) avra_trap_bounds(i, n);"),
        "row_chain": ("x.c", "return helper(a);"),
        "helper": ("x.c", "if (!a) abort();"),
        "row_clean": ("x.c", "return a->len + strlen(s);"),
        "row_out": ("x.c", "hook(a);"),
        "row_licensed": ("x.c", "if (!p) avra_trap(\"oom\"); // LICENSED traps.process_limit: out of memory"),
        "stray": ("x.c", "int n = 1; // LICENSED traps.defect: nothing here"),
    }
    assert reaches("row_direct", synthetic) == ["row_direct", "avra_trap_bounds"]
    assert reaches("row_chain", synthetic) == ["row_chain", "helper", "abort"]
    assert reaches("row_clean", synthetic) is None
    assert reaches("row_out", synthetic) == ["row_out", "hook (a call out)"]
    assert reaches("row_licensed", synthetic) is None
    assert judged({"row_chain": True, "row_clean": False}, synthetic) == []
    assert len(judged({"row_chain": False}, synthetic)) == 1
    assert judged({"row_clean": True}, synthetic) == ["traps: row_clean says `traps: true` and reaches no trap"]
    assert judged({"row_gone": False}, synthetic) == ["traps: row_gone has no C body this keeper can read"]
    assert len(stray_licenses(synthetic)) == 1
    return 10


def main():
    cases = selftest()
    rows, bodies = declared_rows(), c_bodies()
    refused = judged(rows, bodies) + stray_licenses(bodies)
    if refused:
        print("\n".join(refused))
        print(f"traps: {len(refused)} refusal(s)")
        sys.exit(1)
    says = sum(rows.values())
    print(f"traps: {len(rows)} row(s) read, {says} say `traps: true` and reach a trap, {len(rows) - says} reach none ({len(bodies)} C fn(s) read, {cases} of the keeper's own cases hold)")


if __name__ == "__main__":
    main()
