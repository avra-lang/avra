#!/usr/bin/env python3
"""The fns whose source holds a `while`, as the names the emitter gives
them: `@<package>.<dirs under src>.[<Type>.]<fn>`. A `while` inside a
lambda is charged to the fn around it. One name a line.
usage: whiles.py <package dir>…"""
import pathlib, re, sys

FN = re.compile(r'^\s*(?:export\s+)?(?:mut\s+|once\s+|static\s+)*fn\s+([a-z_][a-z0-9_]*)')
IMPL = re.compile(r'^impl\s+(?:[A-Z]\w*\s+for\s+)?([A-Z]\w*)')
WHILE = re.compile(r'^\s*(?:[a-z_]+:\s*)?while\b')

for root in sys.argv[1:]:
    root = pathlib.Path(root)
    pkg = '@' + root.name.replace('-', '.', 1).replace('-', '_') if root.name.startswith('std-') else None
    for path in sorted((root / 'src').rglob('*.av')):
        if '/tests/' in str(path):
            continue
        dirs = '.'.join(path.relative_to(root / 'src').parts[:-1])
        text = re.sub(r'"(?:\\.|[^"\\])*"', '""', re.sub(r'//[^\n]*', '', path.read_text()))
        owner, fn, depth, fn_depth, impl_depth = None, None, 0, -1, -1
        for line in text.split('\n'):
            m = IMPL.match(line)
            if m and depth == 0:
                owner, impl_depth = m.group(1), 0
            m = FN.match(line)
            if m and fn is None:
                fn, fn_depth = m.group(1), depth
            if fn and WHILE.match(line):
                print('.'.join(p for p in (pkg, dirs, owner, fn) if p))
            depth += line.count('{') - line.count('}')
            if fn and depth <= fn_depth:
                fn = None
            if owner and depth <= impl_depth:
                owner = None
