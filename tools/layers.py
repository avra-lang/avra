#!/usr/bin/env python3
"""THE LAYERING IS ONE-WAY, and this reads every `use` to hold it.

    core -> grammar -> features -> compiler        (packages/std-avrac/src)

A file names its own layer and the ones below it, never one above. Below
them all stands `@std/relation`, whose `engine/` is the kernel a running
program asks too: nothing under packages/std-relation/src names the
compiler, and `engine/` names `@std/meta` and itself alone — never a
sibling module of its own package (`use db.{…}`), which stands above it.

A test drives the layers above the one it stands in — that is what a
test of a feature is — so the compiler's `tests/` are not read.
std-relation's are, with one licence spelled here: they may read the
compiler's `core` (a side table's test needs the table).

ROWS FILED BY ID HAVE ONE WRITER. `@std/relation` hands an owner's rows
over as a value (`Rel.replaced`); the three verbs under it — `owner_named`,
`put_owned`, `kept_of` — are the declaration table's alone, LICENSED to
the two files named in `BY_ID_WRITERS` until its rows are a value too
(avra-8sb5.57.214). Any other call outside packages/std-relation is
refused, in every package.

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
        if engine and not tests and (target == "@std.relation" or not target.startswith(("@std.", "engine"))) \
                and not target.startswith("@std.relation.engine"):
            out.append(f"the engine names `{target}`, its own package above it — it reads `@std/meta` and itself alone")
    return out


BY_ID = re.compile(r"\.(owner_named|put_owned|kept_of)\(")
BY_ID_WRITERS = ("packages/std-avrac/src/features/decls.av", "packages/std-avrac/src/features/decls_mint.av")


def by_id_calls(path, text):
    """The by-id writer's verbs `text` calls, where `path` is no licensed writer of them."""
    if path.startswith("packages/std-relation/") or path in BY_ID_WRITERS:
        return []
    return [f"`.{verb}(` files rows by id — the declaration table's alone; hand rows over with `Rel.replaced`"
            for verb in BY_ID.findall(text)]


def by_id_writers():
    found, read = [], 0
    for path in sorted(glob.glob("packages/*/src/**/*.av", recursive=True)):
        read += 1
        found.extend(f"{path}: {w}" for w in by_id_calls(path, open(path, encoding="utf-8").read()))
    return found, read


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
    assert outside("use @std.meta.{identity}\nuse engine.{Kernel}\nuse @std.relation.engine.{Key}\n", True, False) == []
    assert len(outside("use db.{Db}\n", True, False)) == 1
    assert len(outside("use @std.relation.{relation}\n", True, False)) == 1
    assert outside("use db.{Db}\n", False, False) == []
    stray = "rs.put_owned(db, \"F\", 0, r, h, ks, db.owner_named(\"x\"))\nrs.kept_of(db, o, [])\n"
    assert len(by_id_calls("packages/std-http/src/quota.av", stray)) == 3
    assert len(by_id_calls("packages/std-avrac/src/compiler/failures.av", stray)) == 3
    assert by_id_calls("packages/std-avrac/src/features/decls.av", stray) == []
    assert by_id_calls("packages/std-relation/src/tests/named_owner/named_owner.av", stray) == []
    assert by_id_calls("packages/std-http/src/quota.av", "self.kept(buckets, k, b)\nFact.replaced(db, \"o\", rows)\n") == []


def main():
    selftest()
    found, read = climbs()
    strays, scanned = by_id_writers()
    for line in found + strays:
        print(f"layers: {line}")
    if found or strays:
        sys.exit(1)
    if read == 0 or scanned == 0:
        sys.exit("layers: 0 files read — run from the tree's root; a check that read nothing passed nothing")
    print(f"layers: no `use` climbs — {read} file(s) read; rows are filed by id in the declaration table alone — {scanned} file(s) read")


main()
