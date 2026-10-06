#!/usr/bin/env python3
"""THE KERNEL'S GRAPH, COUNTED — and the saved-answer rule tried on it.

Reads the lines a compiler writes under AVRA_DB_GRAPH=1 (query/kernel.av):

    F <kernel> <family>                      a family registered
    I <kernel> <family> <arg>                an input set
    G <kernel> <family> <arg> <n> <f:a ...>  a cell settled, with the keys it read
    A <kernel> <family> <arg> <n>            a frame abandoned (its reads moved up)
    E <kernel> <family>                      a family evicted
    C <kernel> <reads per family ...>        recorded reads so far, repeats included

    python3 tools/db_measure/graph.py <graph file> <families.av> [--top N]

M1 is the table per family. M2 simulates "a query keyed by a durable name is
saved; one keyed by a local id belongs to the saved answer that reads it": each
saved cell's list is its direct durable reads once every local cell's reads are
folded up into its readers. Three classifications are tried, each printed with
the families it calls durable. Nothing here decides which is right.
"""
import re
import sys
from array import array
from collections import defaultdict

SHIFT = 40
MASK = (1 << SHIFT) - 1


def family_table(path):
    """rank -> (name, key type) from the @family declarations."""
    text = open(path, encoding="utf-8").read()
    found = re.findall(r'@family\((\d+),\s*"([^"]*)",\s*"[^"]*"\)\s*\ntype\s+(\w+)', text)
    return {int(rank): (name, key) for rank, key, name in found}


class Kernel:
    def __init__(self):
        self.families = 0
        self.inputs = defaultdict(set)
        self.settles = defaultdict(int)
        self.pushed = defaultdict(int)
        self.abandons = defaultdict(int)
        self.evicted = []
        self.reads = []
        self.flat = array("q")
        self.at = {}

    def deps(self, key):
        start, n = self.at[key]
        return self.flat[start:start + n]


def read_graph(path):
    kernels = defaultdict(Kernel)
    with open(path, encoding="utf-8", errors="replace") as lines:
        for line in lines:
            part = line.rstrip("\n").split("\t")
            kind = part[0]
            if kind == "G" and len(part) >= 5:
                k = kernels[part[1]]
                f = int(part[2])
                key = (f << SHIFT) | int(part[3])
                start = len(k.flat)
                if len(part) > 5 and part[5]:
                    for tok in part[5].split(" "):
                        df, _, da = tok.partition(":")
                        k.flat.append((int(df) << SHIFT) | int(da))
                n = len(k.flat) - start
                k.at[key] = (start, n)
                k.settles[f] += 1
                k.pushed[f] += n
            elif kind == "C" and len(part) >= 3:
                kernels[part[1]].reads = [int(n) for n in part[2].split(" ") if n]
            elif kind == "I" and len(part) >= 4:
                kernels[part[1]].inputs[int(part[2])].add(int(part[3]))
            elif kind == "F" and len(part) >= 3:
                k = kernels[part[1]]
                k.families = max(k.families, int(part[2]) + 1)
            elif kind == "A" and len(part) >= 5:
                kernels[part[1]].abandons[int(part[2])] += 1
            elif kind == "E" and len(part) >= 3:
                kernels[part[1]].evicted.append(int(part[2]))
    return kernels


def quantile(sorted_values, q):
    if not sorted_values:
        return 0
    return sorted_values[min(len(sorted_values) - 1, int(q * len(sorted_values)))]


def label_of(table, f):
    return table[f][0] if f in table else "relation#%d" % f


def key_of(table, f):
    return table[f][1] if f in table else "cell"


def m1(k, table):
    cells = defaultdict(int)
    out = defaultdict(int)
    into = defaultdict(int)
    targets = defaultdict(set)
    for key, (start, n) in k.at.items():
        f = key >> SHIFT
        cells[f] += 1
        out[f] += n
        for d in k.flat[start:start + n]:
            into[d >> SHIFT] += 1
            targets[d >> SHIFT].add(d)
    fams = sorted(set(range(k.families)) | set(cells) | set(into) | set(k.inputs))
    print("%-4s %-14s %-11s %9s %9s %8s %11s %11s %11s %10s %12s" % (
        "fam", "name", "key", "cells", "settles", "inputs", "deps", "deps.cum", "read-by", "distinct", "reads"))
    total = defaultdict(int)
    for f in fams:
        reads = k.reads[f] if f < len(k.reads) else 0
        row = (cells[f], k.settles[f], len(k.inputs[f]), out[f], k.pushed[f], into[f], len(targets[f]), reads)
        for i, v in enumerate(row):
            total[i] += v
        print("%-4d %-14s %-11s %9d %9d %8d %11d %11d %11d %10d %12d" % ((f, label_of(table, f), key_of(table, f)) + row))
    print("%-4s %-14s %-11s %9d %9d %8d %11d %11d %11d %10d %12d" % (
        ("", "TOTAL", "") + tuple(total[i] for i in range(8))))
    if k.abandons:
        print("abandoned frames: %s" % ", ".join("%s %d" % (label_of(table, f), n) for f, n in sorted(k.abandons.items())))
    if k.evicted:
        print("evicted families: %s" % ", ".join(label_of(table, f) for f in k.evicted))
    return total


DURABLE_KEYS = {"FileId", "ModuleId", "DeclId", "unit"}


def classes(table, k, variant):
    """family -> True when its cells are saved under `variant`."""
    durable = {}
    fams = set(range(k.families)) | {key >> SHIFT for key in k.at} | {d >> SHIFT for d in set(k.flat)}
    for f in fams:
        name, key = label_of(table, f), key_of(table, f)
        named = f not in table or name == "Named"
        if variant == "A":
            durable[f] = key in DURABLE_KEYS or name == "Manifest"
        elif variant == "A+":
            durable[f] = key in DURABLE_KEYS or name == "Manifest" or named
        elif variant == "file":
            durable[f] = key in {"FileId", "ModuleId", "unit"} or name == "Manifest" or named
    return durable


def m2(k, table, variant, top):
    durable = classes(table, k, variant)
    print("\n-- rule under classification %s: saved = %s" % (
        variant, " ".join(sorted(label_of(table, f) for f, d in durable.items() if d))))
    print("   in memory = %s" % " ".join(sorted(label_of(table, f) for f, d in durable.items() if not d)))
    folded = {}
    longest = (0, None)
    lost = defaultdict(int)

    def fold(root):
        """The durable reads beneath one local cell, memoized; a cell on the path adds nothing."""
        nonlocal longest
        stack = [(root, iter(k.deps(root)) if root in k.at else iter(()), set())]
        open_keys = {root}
        while stack:
            key, it, acc = stack[-1]
            pushed = False
            for d in it:
                if durable.get(d >> SHIFT, False):
                    acc.add(d)
                elif d in folded:
                    acc |= folded[d]
                elif d not in k.at:
                    lost[d >> SHIFT] += 1
                elif d not in open_keys:
                    open_keys.add(d)
                    stack.append((d, iter(k.deps(d)), set()))
                    pushed = True
                    break
            if pushed:
                continue
            stack.pop()
            open_keys.discard(key)
            folded[key] = frozenset(acc)
            if len(acc) > longest[0]:
                longest = (len(acc), key)
        return folded[root]

    per = defaultdict(list)
    for key, (start, n) in k.at.items():
        f = key >> SHIFT
        if not durable.get(f, False):
            continue
        acc = set()
        for d in k.flat[start:start + n]:
            df = d >> SHIFT
            if durable.get(df, False):
                acc.add(d)
            elif d in k.at:
                acc |= folded[d] if d in folded else fold(d)
            else:
                lost[df] += 1
        acc.discard(key)
        per[f].append(len(acc))
    print("%-14s %9s %6s %8s %8s %9s %11s" % ("family", "saved", "min", "median", "p95", "max", "reads"))
    every = []
    for f in sorted(per):
        sizes = sorted(per[f])
        every.extend(sizes)
        print("%-14s %9d %6d %8d %8d %9d %11d" % (
            label_of(table, f), len(sizes), sizes[0], quantile(sizes, 0.5), quantile(sizes, 0.95), sizes[-1], sum(sizes)))
    every.sort()
    print("%-14s %9d %6d %8d %8d %9d %11d" % (
        "ALL SAVED", len(every), every[0] if every else 0, quantile(every, 0.5), quantile(every, 0.95),
        every[-1] if every else 0, sum(every)))
    local_cells = sum(1 for key in k.at if not durable.get(key >> SHIFT, False))
    sizes = sorted(len(s) for s in folded.values())
    print("in-memory cells settled: %d, read under a saved answer: %d; their folded lists: median %d, p95 %d, longest %d (%s:%d), summed %d" % (
        local_cells, len(folded), quantile(sizes, 0.5), quantile(sizes, 0.95), longest[0],
        label_of(table, longest[1] >> SHIFT) if longest[1] is not None else "-",
        (longest[1] & MASK) if longest[1] is not None else 0, sum(sizes)))
    if lost:
        print("reads, by a saved answer or a cell under one, of a cell neither saved nor ever settled (no name under this rule): %s" % ", ".join(
            "%s %d" % (label_of(table, f), n) for f, n in sorted(lost.items(), key=lambda p: -p[1])[:top]))


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    top = int(sys.argv[sys.argv.index("--top") + 1]) if "--top" in sys.argv else 12
    table = family_table(sys.argv[2])
    kernels = read_graph(sys.argv[1])
    print("kernels: %d (%s)" % (len(kernels), ", ".join(
        "#%s %d cells" % (i, len(k.at)) for i, k in sorted(kernels.items(), key=lambda p: -len(p[1].at)))))
    for i, k in sorted(kernels.items(), key=lambda p: -len(p[1].at))[:3]:
        if not k.at:
            continue
        print("\n==== kernel #%s: M1, the graph as settled ====" % i)
        m1(k, table)
        for variant in ("A", "A+", "file"):
            m2(k, table, variant, top)


if __name__ == "__main__":
    main()
