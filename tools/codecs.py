#!/usr/bin/env python3
"""THE CODEC KEEPER'S OTHER SURFACE: what it refuses.

compiler/codecs.av holds the registry — every wire's encode fn paired
with its decode fn, checked field by field against synthetic samples
(`make codecs` runs that suite). That registry only proves the pairs
it NAMES agree; it says nothing about a pair nobody registered. This
reader is the other half: it scans the tree for encoder/decoder-SHAPED
fn pairs by name, and refuses any it finds that the registry does not
mention — so a new codec cannot skip the keeper by never being asked.

A CANDIDATE PAIR is two fn NAMES, both found as real declarations in
the tree, related by one of the SUFFIX RULES below (the shapes this
codebase's own wire fns already wear) or listed as an IRREGULAR pair
(a name relation no suffix rule reaches). Every candidate must appear
in compiler/codecs.av — as one of `codec_pairs()`'s registered labels,
or as an ACKNOWLEDGED GAP, named with the reason it is not exercised.
Both are read FROM THE SOURCE, never hand-copied here, so neither list
can drift from what the file actually says.
"""
import re, sys, os, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "packages", "std-avrac", "src")
REGISTRY = os.path.join(SRC, "compiler", "codecs.av")

# The registry file itself is not scanned for CANDIDATES — it is the
# thing candidates are checked AGAINST, and it is full of harness fns
# (`derived`, `codec_one`, …) that wear no wire fn's shape but would
# otherwise false-match a suffix rule (`derived_total` ends `_total`,
# not a rule here, but `codec_disagreements`/`total_disagreements`
# share a stem by accident of this file's own vocabulary).
SKIP_DIRS = (os.sep + "tests" + os.sep,)


def av_files():
    for path in sorted(glob.glob(os.path.join(SRC, "**", "*.av"), recursive=True)):
        rel = os.path.relpath(path, ROOT)
        if any(s in path for s in SKIP_DIRS):
            continue
        if os.path.abspath(path) == os.path.abspath(REGISTRY):
            continue
        yield rel


FN_DEF = re.compile(r"^\s*(?:export\s+)?(?:static\s+)?(?:mut\s+)?fn\s+([a-z_][a-zA-Z0-9_]*)\s*\(", re.M)


def defined_names():
    """Every free-standing fn NAME the tree declares (methods included —
    a method's own name is what a suffix rule or an irregular pair
    names, and `T.method()` call syntax is not part of the name), path
    by first definition. A name defined twice keeps its first path;
    this reader asks "does X exist", never "how many".
    """
    out = {}
    for rel in av_files():
        text = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        for m in FN_DEF.finditer(text):
            name = m.group(1)
            if name not in out:
                line = text.count("\n", 0, m.start()) + 1
                out[name] = (rel, line)
    return out


# ── SUFFIX RULES — an ENCODER name's shape, and the DECODER name shape
# it pairs with. Every rule fires only when BOTH names are real
# declarations; a rule that fires on the encoder alone is not a pair,
# it is a fn with no partner (nothing to refuse). ──
def suffix_candidates(name):
    if name.endswith("_word"):
        yield name[: -len("_word")] + "_of_word"
    if name.endswith("_wire"):
        stem = name[: -len("_wire")]
        yield stem + "_of_wire"
        yield stem + "_from_wire"
        yield "read_" + name
    if name.endswith("_block"):
        yield name[: -len("_block")] + "_unblocked"
    if name.startswith("encoded"):
        yield "decoded" + name[len("encoded"):]


# Name relations no suffix rule reaches — read by hand once, each with
# the site that made it plain. A bare `X`/`unX` rule was tried and
# dropped: over the whole tree it matched 29 unrelated predicate pairs
# (`answered`/`unanswered`, `held`/`unheld`, …) for the one real hit,
# `packed`/`unpacked` — a rule this noisy trains the reader to ignore
# its output (CLAUDE.md, "a lint counts what its doctrine counts").
IRREGULAR_PAIRS = [
    ("packed", "unpacked"),  # record.av: the one real `X`/`unX` codec
    ("list_field", "read_list"),  # record.av: no shared stem at all
    ("decl_wire", "wire_decl"),  # interface.av: `Decls.decl_wire`/`Decls.wire_decl`
    ("type_wire", "interface_type"),  # interface.av: the record's own reader, not a `_wire`-suffixed name
    ("type_wire", "read_type_wire"),  # interface.av: the lower-level primitive both readers wrap
]


def candidate_pairs(names):
    """Every (encoder, decoder) both present in `names` — the suffix
    rules plus the irregular list, deduplicated.
    """
    seen = set()
    out = []
    for name in sorted(names):
        for other in suffix_candidates(name):
            if other in names and other != name and (name, other) not in seen:
                seen.add((name, other))
                out.append((name, other))
    for pair in IRREGULAR_PAIRS:
        if pair[0] in names and pair[1] in names and pair not in seen:
            seen.add(pair)
            out.append(pair)
    return out


# ── WHAT THE REGISTRY ALREADY CLAIMS — read from codecs.av itself,
# never hand-copied: `derived("a.b/c.d", …)`/`derived_total(…)`'s own
# label, and a bespoke row's `pair: "…"` field (`dbrow_check`'s). Both
# spell `<name1>` and (optionally `<module>.`)`<name2>`, `/`-joined, a
# trailing `" (…)"` annotation dropped. ──
LABEL_CALL = re.compile(r'\b(?:derived|derived_total)\(\s*\n?\s*"([^"]+)"')
LABEL_FIELD = re.compile(r'\bpair:\s*"([^"]+)"')


def registered_labels(text):
    return [m.group(1) for m in LABEL_CALL.finditer(text)] + [m.group(1) for m in LABEL_FIELD.finditer(text)]


def label_pair(label):
    label = re.sub(r"\s*\([^)]*\)\s*$", "", label)
    if "/" not in label:
        return None
    left, right = label.split("/", 1)
    return left.rsplit(".", 1)[-1], right.rsplit(".", 1)[-1]


# ── ACKNOWLEDGED GAPS — a candidate this reader finds real but the
# registry does not exercise, named with why, read here rather than
# left for the reader to wonder whether it was forgotten. ──
ACKNOWLEDGED_GAPS = {}


CASES = [
    ("fn mark_word(m: SeatMark) -> string { \"\" }\nfn mark_of_word(w: string) -> SeatMark { z }",
     [("mark_word", "mark_of_word")]),
    ("fn doc_wire(x: T) -> string { \"\" }\nfn doc_of_wire(w: string) -> T? { null }",
     [("doc_wire", "doc_of_wire")]),
    ("fn settled_wire(x: T) -> string { \"\" }\nfn settled_from_wire(w: string) -> T? { null }",
     [("settled_wire", "settled_from_wire")]),
    ("fn facts_block(x: T) -> string { \"\" }\nfn facts_unblocked(w: string) -> T? { null }",
     [("facts_block", "facts_unblocked")]),
    ("fn packed(xs: List<string>) -> string { \"\" }\nfn unpacked(w: string) -> List<string> { [] }",
     [("packed", "unpacked")]),
    ("fn encoded(x: T) -> string { \"\" }\nfn decoded(w: string) -> T? { null }",
     [("encoded", "decoded")]),
    ("fn encoded_docfacts(x: T) -> string { \"\" }\nfn decoded_docfacts(w: string) -> T? { null }",
     [("encoded_docfacts", "decoded_docfacts")]),
    ("fn type_wire(x: T) -> string { \"\" }\nfn read_type_wire(w: List<string>, at: int) -> T? { null }",
     [("type_wire", "read_type_wire")]),
    # a lone encoder, no partner defined anywhere: no pair to refuse
    ("fn lonely_wire(x: T) -> string { \"\" }",
     []),
    # `unpacked` alone, no `packed`: the `un`-rule needs both sides
    ("fn unpacked(w: string) -> List<string> { [] }",
     []),
]

SPLICE = "// LICENSED style.raw_thing: not a real site\n"


# ── A DECODER READS A JOINED RECORD THROUGH `wire_fields` ─────────────
# `split` drops a trailing empty segment, so a decoder that splits a
# joined line reads back one field short when its last field is empty.
# Every registered decoder's own body is scanned for a raw `.split(`.

RAW_SPLIT = re.compile(r"\.split\(")


def fn_body(text, name):
    """The body of `fn name(...)` in text, braces counted from the
    signature's own `{` — a one-line body included — or None."""
    m = re.search(r"^\s*(?:export\s+)?(?:static\s+)?(?:mut\s+)?fn\s+" + re.escape(name) + r"\s*\(", text, re.M)
    if not m:
        return None
    i = text.find("{", m.end())
    if i < 0:
        return None
    depth = 0
    for j in range(i, len(text)):
        c = text[j]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return (text.count("\n", 0, m.start()) + 1, text[i:j + 1])
    return None


def raw_splits(text, decoders):
    """Each registered decoder in `text` whose own body splits raw."""
    out = []
    for name in decoders:
        got = fn_body(text, name)
        if got and RAW_SPLIT.search(got[1]):
            out.append((name, got[0]))
    return out


SPLIT_CASES = [
    ("fn read_it(s: string) -> List<string> { s.split(\",\") }\n", ["read_it"], [("read_it", 1)]),
    ("fn read_it(s: string) -> List<string> {\n    wire_fields(s, \",\")\n}\n", ["read_it"], []),
    ("fn other(s: string) -> List<string> { s.split(\",\") }\nfn read_it(s: string) -> List<string> { wire_fields(s, \",\") }\n", ["read_it"], []),
]


def selftest():
    for text, decoders, want in SPLIT_CASES:
        got = raw_splits(text, decoders)
        if got != want:
            sys.exit(f"codecs: raw-split self-test failed on {text!r}: {got} != {want}")
    for text, want in CASES:
        names = set()
        for m in FN_DEF.finditer(text):
            names.add(m.group(1))
        got = sorted(candidate_pairs(names))
        if got != sorted(want):
            sys.exit(f"codecs: self-test failed on {text!r}: {got} != {want}")
    # the irregular list's own members must round-trip through candidate_pairs
    names = set(n for pair in IRREGULAR_PAIRS for n in pair)
    got = set(candidate_pairs(names))
    for pair in IRREGULAR_PAIRS:
        if pair not in got:
            sys.exit(f"codecs: self-test failed — irregular pair {pair} not produced")
    # label_pair's own surface: what it accepts and what it splits
    LABEL_CASES = [
        ("record.mark_word/mark_of_word", ("mark_word", "mark_of_word")),
        ("db.encoded/decoded (DbRow)", ("encoded", "decoded")),
        ("interface.type_wire/settlement_wire.type_from_wire", ("type_wire", "type_from_wire")),
        ("no slash here", None),
    ]
    for label, want in LABEL_CASES:
        got = label_pair(label)
        if got != want:
            sys.exit(f"codecs: label_pair self-test failed on {label!r}: {got} != {want}")


def main():
    selftest()
    names = defined_names()
    candidates = candidate_pairs(set(names))

    registry_text = open(REGISTRY, encoding="utf-8").read()
    labels = registered_labels(registry_text)
    registered = set()
    bad = 0
    for label in labels:
        pair = label_pair(label)
        if pair is None:
            print(f"codecs: a registry label does not spell one pair — {label!r}")
            bad += 1
            continue
        registered.add(pair)
        for fn in pair:
            if fn not in names:
                print(f"codecs: registered pair {pair} names `{fn}`, which no fn in the tree defines")
                bad += 1

    decoders = sorted(set(pair[1] for pair in registered))
    for rel in av_files():
        text = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        for name, line in raw_splits(text, decoders):
            print(f"codecs: {rel}:{line}: `{name}` decodes a joined record with a raw `.split(` — "
                  f"read it through core's `wire_fields`, which keeps an empty last field")
            bad += 1

    uncovered = []
    for pair in candidates:
        if pair in registered or pair in ACKNOWLEDGED_GAPS:
            continue
        uncovered.append(pair)
    for pair in uncovered:
        where = names[pair[0]]
        print(f"codecs: {where[0]}:{where[1]}: `{pair[0]}`/`{pair[1]}` looks like a codec pair — "
              f"register it in compiler/codecs.av's codec_pairs(), or name it in "
              f"tools/codecs.py's ACKNOWLEDGED_GAPS with the reason")
        bad += 1

    if bad:
        print(f"codecs: {bad} DEFECT(S) — a codec the keeper cannot hold honest")
        return 1
    print(
        f"codecs: {len(candidates)} candidate pair(s) found in {len(list(av_files()))} file(s), "
        f"{len(registered)} registered, {len(ACKNOWLEDGED_GAPS)} acknowledged gap(s)"
    )
    return 0


sys.exit(main())
