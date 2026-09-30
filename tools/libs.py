#!/usr/bin/env python3
"""What each linking package's shared library is made of — ONE answer,
read by `make` to build them and by `tools/stems.sh` to check them.

WHY A TOOL AND NOT A MAKE RULE. Make cannot parse TOML, and a
generated `.mk` adds a staleness hazard nothing reports: the fragment
is right until a manifest changes and wrong silently after. One tool
that reads the manifests every time cannot go stale.

WHY IT ANSWERS AS DATA. `--data` is the whole point of the shape: the
keeper CONSUMES this answer rather than re-deriving it from the same
manifests. Two parsers of one truth is how `keeps` and `inert` both
went wrong in one week, and a library's contents is exactly the kind
of truth two readers would drift on.

THE LIBRARY'S PATH IS DERIVED FROM THE PACKAGE'S MANIFEST NAME, never
from a path a manifest names. §2.3 of the package-C standard refuses a
manifest path the toolchain WRITES, because that is a write primitive
across a dependency boundary; a manifest path the toolchain OPENS is a
LOAD primitive and carries the same force. The name is data the
compiler already validates for uniqueness across a workspace, and it
cannot become a path.

ONE LIBRARY PER PACKAGE, NOT PER OBJECT. @std/sqlite names two objects
and its sentinel calls into its amalgamation; a library per object
would leave those references unresolved.

AND A PACKAGE THE COMPILER ALREADY CARRIES GETS NO LIBRARY. Three of
the six linking packages are inside `build/avra` — @std/avrac,
@std/io, @std/process, which is exactly WHY S2a could host their
externs at all. Building a library for one of those would not add
reach; it would add a SECOND COPY of state that is meant to be single,
and `ffi.o`'s staging area is the sharpest instance — the frame would
have one staging area in the image and another in the library, with
which one a call used decided by the lookup order. The roster is
therefore the linking packages MINUS the compiler's own image, and the
test is `nm build/avra`, the same instrument `tools/stems.sh` already
reads.

THE RUNTIME IS LEFT UNDEFINED ON PURPOSE, AND THAT IS THE DESIGN'S
LOAD-BEARING PART. A package's C references a few of the runtime's own
symbols; they are NOT linked into the library, which binds them to the
HOST at load instead.

THE REASON IS `g_once`, NOT THE FREE LISTS. Two copies of
`g_free[CLASSES]` PARTITION memory rather than corrupt it — a box
freed into one list is re-used from that list, on one shared malloc
heap — so that costs footprint and a footprint argument loses to "but
it links". `static OnceSlot g_once[AVRA_ONCE_MAX]` duplicated means a
`once fn` reachable from both copies settles TWICE with two different
answers, where "one value for the whole process" is the contract F2055
protects; and those answers are immortal, so neither ever dies. A
semantic break. `g_acc_live` is the second: `AVRA_MEM_STATS` would
report one copy's view and look complete.

AND THE HAZARD IS NOT LIVE TODAY, which is why it is a RULE rather
than a lucky default: these libraries are pure C from `[link]` rows,
with no Avra code, no `once` and no allocation. It fires the first
time a package's C calls back into Avra.

AND THE ROWS ARE THE MANIFEST'S, TYPED. `[link] search` and `[link]
libs` are the only options a package may ask for, and the `-L`/`-l`
is written HERE — the compiler's `link_words` writes the same two
letters for the native link, so one manifest row means one thing on
both paths. There is no `flags` path: `[link]` has no such key, and
`[link.raw]`, which carries an option verbatim, is the PROGRAM's own.

AND THE LINK RUNS AS AN ARGV, never a shell line. `--build` calls the
linker through a list, so no character in a path or a manifest's
`[link]` row means anything but itself. Emitting a command for a
caller to pipe into `sh` would hand a dependency's flag a parser,
which is the two-hats law this tree already paid for once.
"""

import glob
import os
import subprocess
import sys
import tomllib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = "build"

# The platform's shared-library suffix and the flag that makes one.
# Two entries, because those are the two this tree builds on; a third
# platform adds a row rather than an `if`.
PLATFORMS = {
    "darwin": (".dylib", ["-dynamiclib"]),
    "linux": (".so", ["-shared", "-fPIC"]),
}

# THE RUNTIME IS BOUND TO THE HOST AT LOAD. Mach-O refuses an
# undefined symbol at link time unless told; ELF permits it by
# default. THE AMNESTY IS THE RUNTIME BAND AND NOTHING ELSE: an
# `avra_*` left open is held to `nm build/avra`, and a FOREIGN symbol
# left for dynamic lookup is a `[link] libs` row nobody declared —
# both are refusals in `tools/stems.sh`, which reads `--undefined`.
#
# AND THE FLAG IS NOT WHAT MAKES A PLATFORM LIBRARY RESOLVE. Darwin
# links libSystem implicitly and libSystem re-exports libm and
# libpthread, so those bind with or without their `[link]` rows and
# with or without this flag. Only ELF reads a manifest's promise as
# written, which is why the promise is kept by a keeper here.
HOST_BOUND = ["-Wl,-undefined,dynamic_lookup"] if sys.platform == "darwin" else []


def platform():
    key = "darwin" if sys.platform == "darwin" else "linux"
    return PLATFORMS[key]


# AN ARCHIVE IS LINKED WHOLE INTO A LIBRARY. A program's link pulls only
# the members it references, which is why a package archives its C; a
# library has no references of its own to pull by, so without this a
# library of an archive holds nothing and the evaluator finds no row.
def linked_whole(obj):
    if not obj.endswith(".a"):
        return [obj]
    if sys.platform == "darwin":
        return ["-Wl,-force_load," + obj]
    return ["-Wl,--whole-archive", obj, "-Wl,--no-whole-archive"]


def libname(pkg_name):
    """The library stem a package's MANIFEST NAME derives.

    `@std/sqlite` -> `std-sqlite`. ONE leading `@` is dropped and `/`
    becomes `-`.

    THE RULE IS SPELLED TWICE — here and in the compiler's
    `library_stem` — so it is written to be COPYABLE EXACTLY: strip
    one leading `@`, replace every `/`. `lstrip("@")` was wrong for
    that reason and not for its own: it strips EVERY leading `@`,
    which no substring-based twin will do.

    AND IT IS NOT INJECTIVE, which the first draft claimed it was.
    `@std/a-b` and `@std/a/b` both derive `std-a-b` — two different
    package names, one library path, the second build overwriting the
    first and the evaluator opening whichever is on disk. That is
    SILENT, unlike a disagreement between the two spellings, which is
    loud. So `libraries()` refuses a collision rather than the stem
    escaping its way out of one: an escape would rename every existing
    library to buy injectivity nobody has needed yet.
    """
    stripped = pkg_name[1:] if pkg_name.startswith("@") else pkg_name
    return stripped.replace("/", "-")


def host_symbols():
    """What `build/avra` exports. A KEEPER THAT EXAMINED NOTHING IS NOT
    A KEEPER THAT PASSED, so an absent compiler is an error and never
    an empty set — an empty set would silently give every package a
    library, including the three the host already carries."""
    path = os.path.join(ROOT, "build", "avra")
    if not os.path.exists(path):
        print("libs: build/avra is not built, and the roster is derived from what it "
              "carries — build the compiler first", file=sys.stderr)
        sys.exit(1)
    out = subprocess.run(["nm", path], cwd=ROOT, capture_output=True, text=True)
    return {line.split()[-1].lstrip("_")
            for line in out.stdout.splitlines() if line.strip()}


def defines(obj):
    """The symbols an object DEFINES — what a library of it would add."""
    out = subprocess.run(["nm", "-g", obj], cwd=ROOT, capture_output=True, text=True)
    return {parts[-1].lstrip("_") for parts in
            (line.split() for line in out.stdout.splitlines())
            if len(parts) >= 3 and parts[-2] in ("T", "D", "S", "B")}


def in_the_image(objects, host):
    """Whether the compiler already carries these objects — all of them,
    none of them, or a MIXTURE, which is spelled rather than folded into
    one of the other two. A package split across the seam would get a
    library holding half of itself and resolving the other half to the
    host by luck of lookup order."""
    verdicts = [bool(defines(o) & host) for o in objects]
    if all(verdicts):
        return "carried"
    if not any(verdicts):
        return "absent"
    return "split"


def libraries():
    """Every package that needs a library: name, output path, objects, words.

    A package with no `[link]` objects has no library, and neither has
    one the compiler already carries — the roster is the manifests and
    `nm build/avra`, never a list kept beside them.
    """
    host = host_symbols()
    rows = []
    for path in sorted(glob.glob(os.path.join(ROOT, "packages", "*", "avra.toml"))):
        with open(path, "rb") as f:
            manifest = tomllib.load(f)
        link = manifest.get("link", {})
        objects = link.get("objects", [])
        if not objects:
            continue
        pkg = manifest.get("package", {}).get("name")
        if not pkg:
            continue
        root = os.path.dirname(path)
        paths = [os.path.relpath(os.path.join(root, o), ROOT) for o in objects]
        if any(not os.path.exists(os.path.join(ROOT, o)) for o in paths):
            continue          # not built yet; make's prerequisites decide when
        seen = in_the_image(paths, host)
        if seen == "carried":
            continue
        if seen == "split":
            print(f"libs: {pkg} is half inside `build/avra` and half outside — a library "
                  f"of it would hold one half and resolve the other by lookup order",
                  file=sys.stderr)
            sys.exit(1)
        stem = libname(pkg)
        suffix, _ = platform()
        clash = [r for r in rows if r["name"] == stem]
        if clash:
            print(f"libs: {pkg} and {clash[0]['package']} both derive `{stem}` — one library "
                  f"path for two packages, and the second build would overwrite the first",
                  file=sys.stderr)
            sys.exit(1)
        rows.append({
            "package": pkg,
            "name": stem,
            "output": os.path.join(OUT, "lib" + stem + suffix),
            "objects": paths,
            "words": link_words(link),
        })
    return rows


def link_words(link):
    """A `[link]` table's rows as linker words, in the compiler's own
    order: the directories it searches, then the libraries it needs.

    THE ROWS ARE TYPED AND THE OPTION LETTER IS OURS, which is
    `link_words` in the compiler spelled for the library build: a
    manifest names a DIRECTORY or a LIBRARY and never an option, so no
    word a package writes can become one. `[link]` has no `flags` key
    for the same reason, and `[link.raw]` — which does carry an option
    verbatim — is the PROGRAM's own: a library built here is opened by
    a package's DEPENDENTS, where F4016 refuses raw options outright.
    So there is no flags path at all rather than a dead one.

    A row filling to nothing asks for NO WORD: an empty one is an
    argument the linker still counts, and a bare `-L` eats the word
    after it.
    """
    return [letter + w
            for key, letter in (("search", "-L"), ("libs", "-l"))
            for w in (expanded(r) for r in link.get(key, [])) if w]


def expanded(flag):
    """A `${NAME}` hole filled from the environment, as the compiler's
    own `link_words` fills it: a machine's paths belong to the machine
    and not to a checked-in manifest."""
    out, i = [], 0
    while i < len(flag):
        if flag.startswith("${", i):
            close = flag.find("}", i)
            if close < 0:
                out.append(flag[i:])
                break
            out.append(os.environ.get(flag[i + 2:close], ""))
            i = close + 1
        else:
            out.append(flag[i])
            i += 1
    return "".join(out)


def row_named(name):
    for row in libraries():
        if row["name"] == name:
            return row
    return None


def build(name):
    row = row_named(name)
    if row is None:
        print(f"libs: no linking package derives `{name}`", file=sys.stderr)
        return 1
    missing = [o for o in row["objects"] if not os.path.exists(os.path.join(ROOT, o))]
    if missing:
        print(f"libs: {row['package']} names objects that are not built: "
              f"{' '.join(missing)}", file=sys.stderr)
        return 1
    _, mode = platform()
    argv = (["cc"] + mode + HOST_BOUND + ["-o", row["output"]]
            + [w for o in row["objects"] for w in linked_whole(o)] + row["words"])
    return subprocess.call(argv, cwd=ROOT)


def main(argv):
    if len(argv) >= 2 and argv[1] == "--data":
        # name \t output \t objects(space) \t words(space) \t package
        # THE PACKAGE IS A COLUMN so a keeper can reach the manifest that
        # declared these rows. The tool answers what it will link; the
        # declaration is the manifest's, and holding one to the other
        # needs both to be nameable from one line.
        for row in libraries():
            print("\t".join([row["name"], row["output"],
                             " ".join(row["objects"]), " ".join(row["words"]),
                             row["package"]]))
        return 0
    if len(argv) >= 2 and argv[1] == "--outputs":
        print(" ".join(row["output"] for row in libraries()))
        return 0
    if len(argv) >= 2 and argv[1] == "--names":
        print(" ".join(row["name"] for row in libraries()))
        return 0
    if len(argv) >= 2 and argv[1] == "--undefined":
        # every symbol a built library leaves for the host to answer
        for row in libraries():
            out = os.path.join(ROOT, row["output"])
            if not os.path.exists(out):
                continue
            got = subprocess.run(["nm", "-u", out], cwd=ROOT,
                                 capture_output=True, text=True)
            names = sorted({l.split()[-1].lstrip("_")
                            for l in got.stdout.splitlines() if l.strip()})
            print("\t".join([row["name"], " ".join(names)]))
        return 0
    if len(argv) >= 3 and argv[1] == "--build":
        return build(argv[2])
    print("usage: libs.py --data | --outputs | --names | --undefined | --build <name>",
          file=sys.stderr)
    return 2


sys.exit(main(sys.argv))
