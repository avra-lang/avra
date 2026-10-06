#!/usr/bin/env python3
"""THE LAYERING IS ONE-WAY, and this reads every `use` to hold it.

    core -> grammar -> features -> compiler        (packages/std-avrac/src)

A file names its own layer and the ones below it, never one above. Below
them all stands `@std/relation`, whose `engine/` is the kernel a running
program asks too: nothing under packages/std-relation/src names the
compiler, and `engine/` names `@std/meta` and itself alone.

A test drives the layers above the one it stands in — that is what a
test of a feature is — so the compiler's `tests/` are not read.
std-relation's are, with one licence spelled here: they may read the
compiler's `core` (a side table's test needs the table).

    python3 tools/layers.py          # refuses, naming each `use` that climbs
"""
import glob
import re
import sys

ORDER = ["core", "grammar", "features", "compiler"]
USE = re.compile(r"^use\s+(@std\.[a-z_]+(?:\.[a-z_]+)?|[a-z_]+(?:\.[a-z_]+)*)", re.M)


def layer_named(target):
    """The compiler layer a `use` names, or None."""
    if target.startswith("@std."):
        parts = target.split(".")
        return parts[2] if parts[1] == "avrac" and len(parts) > 2 and parts[2] in ORDER else None
    head = target.split(".")[0]
    return head if head in ORDER else None


def climbing(own, text):
    """The layers above `own` that a compiler file's text names, with the `use`."""
    return [(named, target) for target in USE.findall(text)
            for named in [layer_named(target)]
            if named and ORDER.index(named) > ORDER.index(own)]


def outside(text, engine, tests):
    """What a std-relation file's text names that it may not."""
    out = []
    for target in USE.findall(text):
        if target.startswith("@std.avrac") and not (tests and target == "@std.avrac.core"):
            out.append(f"`@std/relation` names the compiler — `use {target}`")
        if engine and not tests and target.startswith("@std.") and target.split(".")[1] not in ("meta", "relation"):
            out.append(f"the engine names `{target}` — it reads `@std/meta` alone")
    return out


def climbs():
    found, read = [], 0
    for path in sorted(glob.glob("packages/std-avrac/src/**/*.av", recursive=True)):
        own = path.split("/")[3]
        if own not in ORDER or "/tests/" in path:
            continue
        read += 1
        for named, target in climbing(own, open(path, encoding="utf-8").read()):
            found.append(f"{path}: `{own}` names `{named}` — `use {target}`")
    for path in sorted(glob.glob("packages/std-relation/src/**/*.av", recursive=True)):
        read += 1
        text = open(path, encoding="utf-8").read()
        found.extend(f"{path}: {w}" for w in outside(text, "/src/engine/" in path, "/tests/" in path))
    return found, read


def selftest():
    assert layer_named("compiler.families") == "compiler"
    assert layer_named("@std.avrac.features") == "features"
    assert layer_named("@std.relation.engine") is None
    assert climbing("core", "use features.{x}\n") == [("features", "features")]
    assert climbing("features", "use @std.avrac.compiler.{y}\n") == [("compiler", "@std.avrac.compiler")]
    assert climbing("features", "use core.{x}\nuse grammar.{g}\nuse features.{f}\n") == []
    assert len(outside("use @std.avrac.core.{T}\n", False, False)) == 1
    assert outside("use @std.avrac.core.{T}\n", False, True) == []
    assert len(outside("use @std.io.{env}\n", True, False)) == 1
    assert outside("use @std.meta.{identity}\nuse engine.{Kernel}\n", True, False) == []


def main():
    selftest()
    found, read = climbs()
    for line in found:
        print(f"layers: {line}")
    if found:
        sys.exit(1)
    print(f"layers: no `use` climbs — {read} file(s) read")


main()
