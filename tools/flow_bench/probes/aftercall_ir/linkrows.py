#!/usr/bin/env python3
"""The objects and libraries a package's dependency closure links: every
`[link]` row reached through `path` dependencies, objects as paths from
the tree's root. usage: linkrows.py <tree root> <package dir>"""
import os, re, sys

root, start = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
seen, objects, libs, todo = set(), [], [], [start]
while todo:
    pkg = todo.pop()
    if pkg in seen or not os.path.exists(os.path.join(pkg, 'avra.toml')):
        continue
    seen.add(pkg)
    text = open(os.path.join(pkg, 'avra.toml')).read()
    todo += [os.path.normpath(os.path.join(pkg, p)) for p in re.findall(r'path\s*=\s*"([^"]+)"', text)]
    link = text.split('[link]', 1)[1].split('\n[', 1)[0] if '[link]' in text else ''
    for key, into in (('objects', objects), ('libs', libs)):
        m = re.search(key + r'\s*=\s*\[([^\]]*)\]', link)
        for item in re.findall(r'"([^"]+)"', m.group(1)) if m else []:
            item = os.path.relpath(os.path.normpath(os.path.join(pkg, item)), root) if key == 'objects' else '-l' + item
            if item not in into:
                into.append(item)
print(' '.join(objects + ['build/libavra_runtime.a'] + libs + ['-lm']))
