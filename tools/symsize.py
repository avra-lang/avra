"""Bytes of code per symbol, grouped by package, as markdown tables.

    python3 tools/symsize.py BINARY              one binary: packages and largest symbols
    python3 tools/symsize.py BINARY BEFORE       the same, with BEFORE's sizes and the delta

A symbol's size is the distance to the next text symbol's address
(`nm -n --defined-only`), which counts padding and outlined code with
the symbol before them. The binary's own file size heads the table.
"""
import collections
import os
import re
import subprocess
import sys

TOP = 15


def sizes(binary):
    """Every text symbol's size in bytes, by name."""
    out = subprocess.run(['nm', '-n', '--defined-only', binary], capture_output=True, text=True, check=True).stdout
    syms = [(int(p[0], 16), p[2]) for p in (l.split(' ') for l in out.splitlines()) if len(p) >= 3 and p[1] in ('T', 't')]
    return {n: b - a for (a, n), (b, _) in zip(syms, syms[1:])}


def module(name):
    """Where a symbol comes from: its `@std` package (the compiler's own by
    directory module), the runtime, or the program. A mangled name does not
    say whether a segment is a module or a type, so a package is the unit."""
    m = re.match(r'_?av_\$40std\$2E([^$]+)\$2E([^$]+)', name)
    if m:
        return f'avrac.{m.group(2)}' if m.group(1) == 'avrac' else m.group(1)
    if name.lstrip('_').startswith('avra_'):
        return 'runtime (C)'
    if name.lstrip('_').startswith('av_'):
        return 'program'
    return 'other (libc, sqlite, outlined)'


def by_module(syms):
    groups = collections.Counter()
    for n, s in syms.items():
        groups[module(n)] += s
    return groups


def shown(name):
    """A mangled name as the source spells it; a specialization's key is elided."""
    base, _, key = name.lstrip('_').partition('$24')
    base = re.sub(r'^av_', '', base).replace('$40', '@').replace('$2E', '.')
    return f'{base} (specialized)' if key else base


def kb(n):
    return f'{n / 1024:,.1f} KB'


def signed(n):
    return f'{n:+,} B'


def one(binary):
    syms = sizes(binary)
    groups = by_module(syms)
    print(f'`{binary}`: file {kb(os.path.getsize(binary))}, text symbols {kb(sum(syms.values()))}, {len(syms)} symbols\n')
    print('| package | bytes | share |\n|---|---|---|')
    total = sum(groups.values()) or 1
    for g, s in groups.most_common(TOP):
        print(f'| {g} | {s:,} | {100 * s / total:.1f}% |')
    print('\n| largest symbols | bytes |\n|---|---|')
    for n, s in sorted(syms.items(), key=lambda kv: -kv[1])[:TOP]:
        print(f'| `{shown(n)}` | {s:,} |')


def two(binary, before):
    a, b = sizes(before), sizes(binary)
    ga, gb = by_module(a), by_module(b)
    print(f'`{before}` -> `{binary}`: file {kb(os.path.getsize(before))} -> {kb(os.path.getsize(binary))}, '
          f'text symbols {kb(sum(a.values()))} -> {kb(sum(b.values()))} ({signed(sum(b.values()) - sum(a.values()))})\n')
    print('| package | before | after | delta |\n|---|---|---|---|')
    for g in sorted(set(ga) | set(gb), key=lambda g: -abs(gb[g] - ga[g]))[:TOP]:
        print(f'| {g} | {ga[g]:,} | {gb[g]:,} | {signed(gb[g] - ga[g])} |')
    print('\n| symbol | before | after | delta |\n|---|---|---|---|')
    moved = sorted(set(a) | set(b), key=lambda n: -abs(b.get(n, 0) - a.get(n, 0)))
    for n in moved[:TOP]:
        print(f'| `{shown(n)}` | {a.get(n, 0):,} | {b.get(n, 0):,} | {signed(b.get(n, 0) - a.get(n, 0))} |')


if __name__ == '__main__':
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    for b in sys.argv[1:]:
        if not os.path.isfile(b):
            sys.exit(f'symsize: no binary at {b}')
        if len(sizes(b)) < 2:
            sys.exit(f'symsize: {b} has no text symbols to size (stripped?)')
    if len(sys.argv) == 2:
        one(sys.argv[1])
    else:
        two(sys.argv[1], sys.argv[2])
