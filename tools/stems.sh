#!/bin/sh
# THE STEM LAW'S KEEPER. The Makefile holds ONE definition of "a stem
# names its object, so a stem is unique tree-wide" (TREE_STEM_LAW);
# this drives that definition with synthetic inputs, so the law and its
# test can never be two rules disagreeing. TREE_C is overridden on
# make's command line — no file is created, nothing in packages/ moves.
#
# BOTH SURFACES, because a keeper that has only ever been watched
# refusing is half-tested: the ACCEPT rows prove it does not refuse a
# tree that is fine, and a dead alternative there would widen the law
# in silence.
#
# EVERY ROW CARRIES THE TREE'S OWN C. `test` wants RUNTIME_OBJS
# whatever TREE_C says, so a row omitting runtime/avra_runtime.c asks
# make for an object no source can build and fails for a reason that
# is not the law. The first draft did, and PASSED — the objects were
# on disk from an earlier build, and the rows only spoke when the
# tree was cold.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

fails=0
rows=0

# A row: the words `make -n test` must answer for these sources, and
# the verdict. `refuse` demands the law names every clashing file.
OWN="runtime/avra_runtime.c backend/llvm_wrapper.c"

row() {
    what="$1"; want_status="$2"; sources="$3"; want_words="$4"
    rows=$((rows + 1))
    out=$(make -n idioms TREE_C="$OWN $sources" 2>&1) && status=0 || status=$?
    if [ "$status" != "$want_status" ]; then
        echo "stems: $what — status $status, wanted $want_status"
        fails=$((fails + 1))
        return
    fi
    case "$out" in
        *"$want_words"*) ;;
        *) echo "stems: $what — the words are not there: $want_words"
           fails=$((fails + 1)) ;;
    esac
}

LAW="a stem is unique tree-wide"

row "two packages sharing a stem" 2 \
    "packages/std-io/src/c/util.c packages/std-path/src/c/util.c" \
    "rename one of: packages/std-io/src/c/util.c packages/std-path/src/c/util.c"
row "a vendored unit against a package's own" 2 \
    "packages/std-a/vendor/z.c packages/std-b/src/c/z.c" "$LAW"
row "three sharing one stem" 2 \
    "a/src/c/u.c b/src/c/u.c c/src/c/u.c" "rename one of: a/src/c/u.c b/src/c/u.c c/src/c/u.c"
row "two clashes at once" 2 "a/p.c b/p.c a/q.c b/q.c" "a/p.c b/p.c a/q.c b/q.c"
# A CASE-ONLY CLASH IS A CLASH. One flat `build/` sits on a volume
# that does not tell `util.o` from `Util.o` — proved on this tree:
# both sources compiled, `build/Casestem.o` was never a separate file,
# and `build/casestem.o` carried the OTHER package's symbol.
row "a case-only clash" 2 \
    "packages/std-io/src/c/util.c packages/std-path/src/c/Util.c" \
    "rename one of: packages/std-io/src/c/util.c packages/std-path/src/c/Util.c"
row "a clash of three spellings" 2 "a/u.c b/U.c c/uU.c" "a/u.c b/U.c"
row "distinct stems stand" 0 \
    "packages/std-net/src/c/std_net.c packages/width-witness/src/c/width_witness.c" ""
row "one package source stands" 0 "packages/std-net/src/c/std_net.c" ""
row "the tree's own C alone stands" 0 "" ""

# The tree itself, through the same law.
rows=$((rows + 1))
make -n test >/dev/null 2>&1 || { echo "stems: the tree's own stems clash"; fails=$((fails + 1)); }

# A TARGET DEPENDS ON WHAT IT LINKS. Two lists, two rules, and the
# rules read DIFFERENT sources from the Makefile so they cannot agree
# with it by construction: the manifests say what a package promises
# the link, and `build/avra` itself says what the compiler took.
#
# It went wrong twice in one campaign, in both directions. A
# hand-kept list let `make avra` link an object it had never built —
# the evaluator's trampoline, then @std/io's own C. Depending on every
# object instead cost a 9.5 MB vendored amalgamation compiled for a
# binary that never links it.
# A target's PREREQUISITES, which is the question — `make -n` prints
# only what it would DO, and an object already on disk produces no
# line at all, so a recipe scan answers "absent" about everything a
# warm tree already has. ITS RULE LINE, never a variable of it: make
# prints a target-specific variable as `target: VAR := value` — a
# `$(shell)` its recipe expands leaves `.SHELLSTATUS` there — and that
# line, read as the rule, names no prerequisite at all.
prereqs_of() { make -p -n "$1" 2>/dev/null | grep -m1 "^$1:[^=]*$" | sed "s/^$1://"; }

# EVERY OBJECT A MANIFEST NAMES IS A PACKAGE OBJECT.
rows=$((rows + 1))
package_objs=" $(prereqs_of test) "
for obj in $(sed -n 's/.*objects *= *\[\(.*\)\].*/\1/p' packages/*/avra.toml \
             | tr ',' '\n' | tr -d ' "' | sed 's|.*/||' | sort -u); do
    case "$package_objs" in
        *" build/$obj "*) ;;
        *) echo "stems: a manifest names build/$obj and no target that runs programs depends on it"
           fails=$((fails + 1)) ;;
    esac
done

# EVERY OBJECT THE COMPILER TOOK IS A COMPILER OBJECT — asked of the
# BINARY, not of a closure walked here. A second dependency resolver
# would be a copy of the one that decides the answer; `nm` reads what
# actually happened.
rows=$((rows + 1))
looked=0
seen=0
if [ -x build/avra ]; then
    compiler_objs=" $(prereqs_of avra) "
    for o in build/*.o; do
        [ -e "$o" ] || continue
        seen=$((seen + 1))
        # THE SYMBOL SPELLING IS THE PLATFORM'S: Mach-O prefixes `_`,
        # ELF does not — and the OPTIONAL underscore must be spelled
        # `_*`, not `\?`: `\?` is a GNU-sed extension, so on BSD/macOS
        # the substitution never matched and the reader returned NOTHING.
        sym=$(nm -gU "$o" 2>/dev/null | sed -n 's/.* T _*//p' | head -1)
        [ -n "$sym" ] || continue
        nm -gU build/avra 2>/dev/null | grep -q " T _*$sym\$" || continue
        looked=$((looked + 1))
        case "$compiler_objs" in
            *" $o "*) ;;
            *) echo "stems: build/avra carries $sym from $o, and \`make avra\` does not depend on it"
               fails=$((fails + 1)) ;;
        esac
    done
fi
# A CHECK THAT EXAMINED NOTHING IS NOT A CHECK THAT PASSED. It reads
# objects on disk, and on a cold tree there are none — so it says how
# many it looked at rather than reporting green over an empty set.
if [ "$looked" = 0 ]; then
    if [ "$seen" = 0 ]; then
        echo "stems: no object files on disk — that rule examined NOTHING (a cold tree builds first)"
    else
        echo "stems: $seen object file(s) on disk and NOT ONE named a symbol this reader found — the spelling is wrong for this platform, so that rule examined NOTHING"
        fails=$((fails + 1))
    fi
fi

# A MAKEFILE VARIABLE IS ASSIGNED ONCE. Make takes the LAST assignment
# and the earlier one is dead — but it does not LOOK dead, and a
# reader who edits it is editing nothing. `COMPILER_OBJS` was defined
# twice inside the very change that fixed the link-dependency class,
# and the cost was a FALSE NEGATIVE IN A REVIEW: lane A edited the
# dead copy to test this keeper's teeth, watched the keeper pass, and
# was drafting "the compiler-list check does not work" before the
# prerequisite order made them look again. A dead definition that
# reads as authoritative turns a working keeper into a broken one in
# the reviewer's notes.
#
# READ TEXTUALLY, and here that is right rather than a shortcut: the
# rule is about the FILE's own shape, and make's database shows only
# the surviving value — it cannot say a name was assigned twice.
rows=$((rows + 1))
twice=$(grep -E '^[A-Za-z_][A-Za-z0-9_]* *:?\??=' Makefile \
        | sed -E 's/^([A-Za-z_][A-Za-z0-9_]*).*/\1/' | sort | uniq -d)
for name in $twice; do
    where=$(grep -nE "^$name *:?\??=" Makefile | cut -d: -f1 | tr '\n' ' ')
    echo "stems: the Makefile assigns $name more than once (lines $where) — make takes the last and the rest are dead"
    fails=$((fails + 1))
done

# EVERY SYMBOL A PACKAGE LIBRARY LEAVES OPEN IS ACCOUNTED FOR, and
# the accounting is PRINTED — a keeper counts what it looked at and
# says so, or a new open symbol arrives invisibly.
#
# A library is linked with the runtime DELIBERATELY unresolved; a
# second copy would duplicate state the language promises is single
# (`g_once` above all: a `once fn` reachable from two copies settles
# TWICE, and since those answers are immortal, neither ever dies).
# Mach-O permits that only symbol by symbol (`-U`, tools/libs.py), so
# a TYPO there fails the link; ELF permits every open symbol, where
# `avra_traap` links clean and fails at first call. So the amnesty is
# bounded, in THREE bands:
#
#   OURS      an `avra_*` the host exports — bound at load, correct.
#   MISSING   an `avra_*` the host does NOT export — the typo band,
#             and a refusal.
#   FOREIGN   everything else. Almost all of it is the platform's,
#             which the loader answers. But a symbol another PACKAGE's
#             library defines is a CROSS-PACKAGE C reference, and
#             under RTLD_LOCAL it will not resolve AT ALL — the other
#             library's symbols are not in any namespace this one can
#             see. That is a defect the keeper names rather than a
#             band it tolerates.
#
# THE ROSTER IS CONSUMED, NOT RE-DERIVED: `tools/libs.py --undefined`
# answers what each built library left open. Parsing the manifests a
# second time here is how `keeps` and `inert` both went wrong.
if [ -x build/avra ]; then
    rows=$((rows + 1))
    python3 - "$fails" <<'PYEOF' || fails=$((fails + 1))
import glob, os, subprocess, sys, tomllib

def syms(argv):
    out = subprocess.run(argv, capture_output=True, text=True)
    return {l.split()[-1].lstrip("_") for l in out.stdout.splitlines() if l.strip()}


# TWO PACKAGES MAY NOT DEFINE ONE SYMBOL, and it is the stem law one
# level up: a stem names an OBJECT, a symbol names a BODY, and the
# evaluator resolves a body BY NAME across the whole closure. It walks
# the program's libraries and takes the first handle that carries the
# name, then MEMOIZES that address under the name alone — no package
# rides the key — so the second package's own calls reach the first
# package's body.
#
# MEASURED, with two throwaway linking packages defining `probe_dup`
# as 111 and 222 and one program depending on both: `./avra check`
# said nothing, `./avra run` answered `alpha=111 beta=111` — beta's
# own verb running alpha's C — and `./avra build` refused with `ld: 1
# duplicate symbols`. So the evaluator RUNS, wrongly and silently, a
# program the native path cannot link, and which body wins is decided
# by the order the closure was walked.
#
# TREE-WIDE RATHER THAN PER-CLOSURE, the same posture the stem law
# takes: a duplicate only bites a program that depends on both, and
# working out which programs those are is a second dependency
# resolver. The names are a package's own C and nothing forces them to
# collide.
def duplicated(defined):
    owners = {}
    for lib in sorted(defined):
        for s in defined[lib]:
            owners.setdefault(s, []).append(lib)
    return sorted((s, libs) for s, libs in owners.items() if len(libs) > 1)


DUP_CASES = [
    # (what each library defines, the clashes)
    ({"a": {"one", "shared"}, "b": {"two", "shared"}}, [("shared", ["a", "b"])]),
    ({"a": {"one"}, "b": {"two"}}, []),
    ({"a": {"s"}, "b": {"s"}, "c": {"s"}}, [("s", ["a", "b", "c"])]),
    ({"a": set()}, []),
    ({}, []),
]

bad = sum(1 for given, want in DUP_CASES if duplicated(given) != want)
for given, want in DUP_CASES:
    if duplicated(given) != want:
        print(f"stems: SELF-TEST — {given} should clash as {want}, reads as {duplicated(given)}")
if bad:
    sys.exit(1)

# EVERY DECLARED `[link]` ROW REACHES THE LINK LINE. A `[link]` row is
# the manifest's promise about what a package's C needs; the library
# is where that promise is kept, and nothing else in the tree checks
# that it was. The DECLARATION is read from the manifests here and the
# TOOL's answer is held to it — the keeper does not re-derive the
# answer, which is what `keeps` and `inert` were.
#
# WITNESSED FAILING: `tools/libs.py` read `link.flags`, a key the
# manifest law has no place for (`[link]` takes `objects`/`search`/
# `libs`, `[link.raw]` takes `flags`), so its expansion was
# unreachable and every library was linked with an EMPTY word list.
# `@std/sqlite`'s `libs = ["m", "pthread"]` and `@std/avrac`'s
# `search`/`libs` had never reached a link line.
#
# AND DARWIN HID IT, which is why it needed a keeper and not a reader:
# libSystem is linked implicitly and re-exports libm and libpthread,
# so libstd-sqlite links CLEAN with both rows missing and `nm -m`
# shows every one of those symbols already bound. Measured: the
# library links with neither `-lm` nor any amnesty.
# ELF is where a dropped row bites, and no local run would ever say so.
#
# BY WORD WHERE A ROW IS LITERAL, BY COUNT WHERE IT CARRIES A `${}`
# HOLE: filling a hole here would be a THIRD expander beside the
# compiler's `filled_words` and the tool's `expanded`, and a hole that
# fills to nothing is dropped by both. So a literal row must be on the
# line by name, and no `-L`/`-l` word may exist beyond the rows
# declared — which bounds the holed ones from above and catches a word
# no manifest asked for.
def link_gaps(link, objects, words):
    """Where a library's link line and its package's `[link]` rows
    disagree — a declared row missing, or a word nobody declared."""
    gaps = []
    if len(objects) != len(link.get("objects", [])):
        gaps.append(f"links {len(objects)} object(s) against "
                    f"{len(link.get('objects', []))} declared")
    for key, letter in (("search", "-L"), ("libs", "-l")):
        declared = link.get(key, [])
        gaps += [f"declares `{key}` row `{r}` and the line carries no `{letter}{r}`"
                 for r in declared if "${" not in r and letter + r not in words]
        on_line = [w for w in words if w.startswith(letter)]
        if len(on_line) > len(declared):
            gaps.append(f"carries {len(on_line)} `{letter}` word(s) against "
                        f"{len(declared)} declared `{key}` row(s)")
    return gaps


# BOTH SURFACES, and the EMPTY CASE FIRST: a keeper's accept side is
# where a dead alternative widens the law in silence.
GAP_CASES = [
    # (the `[link]` table, the objects linked, the words linked, the gaps)
    ({}, [], [], []),
    ({"objects": ["../../build/a.o"], "libs": ["m", "pthread"]},
     ["build/a.o"], ["-lm", "-lpthread"], []),
    ({"objects": ["../../build/a.o"], "libs": ["m", "pthread"]},
     ["build/a.o"], [],
     ["declares `libs` row `m` and the line carries no `-lm`",
      "declares `libs` row `pthread` and the line carries no `-lpthread`"]),
    ({}, [], ["-lz"], ["carries 1 `-l` word(s) against 0 declared `libs` row(s)"]),
    ({"objects": ["a", "b"]}, ["build/a.o"], [], ["links 1 object(s) against 2 declared"]),
    # a `${}` hole, filled and dropped: held by count, never by word
    ({"search": ["${P}/lib"]}, [], ["-L/opt/lib"], []),
    ({"search": ["${P}/lib"]}, [], [], []),
]

bad = sum(1 for link, objs, words, want in GAP_CASES
          if link_gaps(link, objs, words) != want)
for link, objs, words, want in GAP_CASES:
    if link_gaps(link, objs, words) != want:
        print(f"stems: SELF-TEST — {link} linked as {objs} {words} should read "
              f"{want}, reads {link_gaps(link, objs, words)}")
if bad:
    sys.exit(1)


def declared_link():
    """Each package's `[link]` table, keyed by its MANIFEST NAME — the
    same key `tools/libs.py` prints, so no stem rule is spelled a
    third time here."""
    out = {}
    for path in sorted(glob.glob("packages/*/avra.toml")):
        with open(path, "rb") as f:
            m = tomllib.load(f)
        name = m.get("package", {}).get("name")
        if name:
            out[name] = m.get("link", {})
    return out


# WHAT NOTHING ON THE LINK LINE ANSWERS. The per-symbol `-U` is the
# amnesty that lets the RUNTIME bind to the host at load, and
# `nm -u` cannot tell that band from a symbol the loader will answer:
# it lists a symbol bound to a named library too. `nm -m` splits them,
# so "the platform's" stops being a claim and becomes a count. A
# FOREIGN symbol left for dynamic lookup is one no `-l` row covered —
# which is the shape a dropped `libs` row takes on a platform that
# does not link libSystem implicitly.
#
# ELF HAS NO SUCH COLUMN, so off darwin this answers None and the
# keeper says it did not ask. A check that examined nothing is not a
# check that passed.
def unbound(path):
    """The symbols a Mach-O library leaves for DYNAMIC LOOKUP, or None
    where the question cannot be asked."""
    if sys.platform != "darwin":
        return None
    out = subprocess.run(["nm", "-m", path], capture_output=True, text=True)
    return {l.split()[-4].lstrip("_") for l in out.stdout.splitlines()
            if l.strip().endswith("(dynamically looked up)")}


host = syms(["nm", "build/avra"])
rows = subprocess.run(["python3", "tools/libs.py", "--undefined"],
                      capture_output=True, text=True).stdout
# what each OTHER library defines, so a cross-package reference is nameable
data = [line.split("\t") for line in
        subprocess.run(["python3", "tools/libs.py", "--data"],
                       capture_output=True, text=True).stdout.splitlines()]
defined = {row[0]: syms(["nm", "-g", "--defined-only", row[1]])
           for row in data if os.path.exists(row[1])}
outputs = {row[0]: row[1] for row in data if os.path.exists(row[1])}

bad = 0
declared = declared_link()
rows_seen = held = holed = 0
for name, out, objects, words, pkg in data:
    link, line = declared.get(pkg, {}), words.split()
    for gap in link_gaps(link, objects.split(), line):
        print(f"stems: lib{name} {gap} — {pkg}'s `[link]` is the promise and the "
              f"library is where it is kept")
        bad += 1
    for key, letter in (("search", "-L"), ("libs", "-l")):
        for r in link.get(key, []):
            rows_seen += 1
            if "${" in r:
                holed += 1
            elif letter + r in line:
                held += 1
print(f"stems:   {rows_seen} declared `[link]` search/libs row(s) across {len(data)} "
      f"package librar{'y' if len(data) == 1 else 'ies'} — {held} found by name on a "
      f"link line, {holed} carrying a `${{}}` hole and held by count")
for line in rows.splitlines():
    parts = line.split("\t")
    lib, open_syms = parts[0], (parts[1].split() if len(parts) > 1 else [])
    ours = [x for x in open_syms if x.startswith("avra_") and x in host]
    missing = [x for x in open_syms if x.startswith("avra_") and x not in host]
    foreign = [x for x in open_syms if not x.startswith("avra_")]
    crossed = sorted({x for x in foreign
                      for other, defs in defined.items()
                      if other != lib and x in defs})
    for x in missing:
        print(f"stems: lib{lib} leaves {x} for the host and build/avra does not export it")
        bad += 1
    for x in crossed:
        print(f"stems: lib{lib} leaves {x}, which lib{[o for o, d in defined.items() if o != lib and x in d][0]} defines "
              f"— a cross-package reference cannot resolve under RTLD_LOCAL")
        bad += 1
    loose = unbound(outputs[lib])
    stray = sorted(x for x in (loose or set()) if not x.startswith("avra_"))
    for x in stray:
        print(f"stems: lib{lib} leaves {x} for dynamic lookup and nothing on its link "
              f"line answers it — a `[link] libs` row is missing")
        bad += 1
    note = ("binding not asked here" if loose is None
            else f"{len(foreign) - len(stray)} bound to a named library")
    print(f"stems:   lib{lib} leaves {len(open_syms)} symbol(s) open — "
          f"{len(ours)} ours ({' '.join(ours) or 'none'}), "
          f"{len(foreign)} the platform's ({note})")
for sym, libs in duplicated(defined):
    print(f"stems: {' and '.join('lib' + l for l in libs)} each define {sym} "
          f"— the evaluator takes the FIRST and memoizes it under the name alone, "
          f"so one package's calls reach the other's body; the native link refuses outright")
    bad += 1
print(f"stems:   {sum(len(d) for d in defined.values())} defined symbol(s) across "
      f"{len(defined)} package librar{'y' if len(defined) == 1 else 'ies'}, each owned once")
sys.exit(1 if bad else 0)
PYEOF
fi

if [ "$fails" != 0 ]; then
    echo "stems: $fails of $rows rows failed"
    exit 1
fi
echo "stems: $rows rows — the stem law holds, every manifest object has a target, and $looked of the compiler's own were read from the binary"
