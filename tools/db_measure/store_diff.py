#!/usr/bin/env python3
"""Two stores written over one source by processes that met files in different orders:
which keys exist on one side only, and which common keys hold different bytes."""
import os, re, sys
from collections import defaultdict

def load(root):
    out = {}
    for d, _, fs in os.walk(root):
        for f in fs:
            p = os.path.join(d, f)
            rel = os.path.relpath(p, root).split(os.sep)
            if rel[0] == "compilers" or f == ".users": continue
            key = "/".join(rel[1:])  # drop the compiler's own directory
            out[key] = open(p, "rb").read()
    return out

A, B = load(sys.argv[1]), load(sys.argv[2])
kind = lambda k: k.split("/")[0]
only_a, only_b, differ = defaultdict(list), defaultdict(list), defaultdict(list)
for k in A:
    (differ if k in B and A[k] != B[k] else only_a if k not in B else defaultdict(list))[kind(k)].append(k)
for k in B:
    if k not in A: only_b[kind(k)].append(k)
kinds = sorted(set(map(kind, A)) | set(map(kind, B)))
print("%-6s %7s %7s %8s %8s %8s" % ("kind", "in A", "in B", "only A", "only B", "differ"))
for kd in kinds:
    print("%-6s %7d %7d %8d %8d %8d" % (kd, sum(1 for k in A if kind(k) == kd), sum(1 for k in B if kind(k) == kd), len(only_a[kd]), len(only_b[kd]), len(differ[kd])))
ids = re.compile(rb"(const|expr|seat)\$\d+\$[\w.]+")
for label, side in (("A", A), ("B", B)):
    hits = defaultdict(int)
    for k, v in side.items():
        if ids.search(k.encode()): hits[kind(k) + " KEY"] += 1
        n = len(ids.findall(v))
        if n: hits[kind(k) + " value"] += n
    print("names carrying a process-local index in", label, dict(hits))
def text(b):
    try: return b.decode()
    except UnicodeDecodeError: return None
shown = 0
for kd in kinds:
    for k in sorted(differ[kd])[:400]:
        a, b = text(A[k]), text(B[k])
        if a is None or b is None:
            if shown < 40: print("DIFF %s binary %d vs %d bytes" % (k[:70], len(A[k]), len(B[k]))); shown += 1
            continue
        la, lb = a.split("\n"), b.split("\n")
        sa, sb = set(la), set(lb)
        gone, came = [l for l in la if l not in sb], [l for l in lb if l not in sa]
        note = "same lines, another order" if not gone and not came else "%d lines only in A, %d only in B" % (len(gone), len(came))
        if shown < 60:
            print("DIFF %s: %s" % (k[:70], note))
            for l in gone[:2]: print("   A| " + l[:230])
            for l in came[:2]: print("   B| " + l[:230])
            shown += 1
for kd in kinds:
    for side, d in (("A", only_a), ("B", only_b)):
        for k in sorted(d[kd])[:3]: print("ONLY %s %s (%d bytes) %s" % (side, k[:80], len((A if side == "A" else B)[k]), (text((A if side == "A" else B)[k]) or "")[:120].replace("\n", " | ")))
