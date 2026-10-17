#!/usr/bin/env python3
"""Every kind a voice speaks by literal is a REGISTERED kind.

`refusal`, `warning` and `error_at` take the kind as their first
argument; a literal there that docs/DIAGNOSTICS.md (generated from the
assembled registry by `make witnesses`) has no entry for is a voice that
speaks a kind nothing registered — no row, no summary, no witness, no
help for `avra docs` to find. Reports what it examined."""
import glob, re, sys

CALL = re.compile(r'\b(?:refusal|warning|error_at)\(\s*"([a-z_]+\.[a-z_]+)"')
# The CLI's own failure wrapper is a kind of the program `avra`, never of
# the language the registry describes.
OUTSIDE = {"build.command_failed"}
registered = set(re.findall(r'^## (\S+)$', open('docs/DIAGNOSTICS.md').read(), re.M))
if not registered:
    print("voices-spoken: docs/DIAGNOSTICS.md names no kind — nothing to compare against")
    sys.exit(1)
spoken = {}
files = [f for f in glob.glob('packages/*/src/**/*.av', recursive=True) if '/tests/' not in f]
for f in files:
    text = open(f).read()
    for m in CALL.finditer(text):
        spoken.setdefault(m.group(1), (f, text[:m.start()].count('\n') + 1))
missing = sorted(k for k in spoken if k not in registered and k not in OUTSIDE)
for k in missing:
    f, line = spoken[k]
    print(f"voices-spoken: `{k}` is spoken at {f}:{line} and no registry row names it")
print(f"voices-spoken: {len(spoken)} spoken kind(s) in {len(files)} file(s) held against {len(registered)} registered")
sys.exit(1 if missing else 0)
