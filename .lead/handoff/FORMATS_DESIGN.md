# FORMATS — design note (B, then A, then C)

What exists today: `grammar R = "…"` is a record whose fields are its holes. On the layer its doors are
STATICS that item_formats.av generates as an `impl R { … }` from the record's `GrammarSpec { head, parts:
List<FormatPart { hole: Hole { name, ty: TypeRef?, greedy }, piece } }`. The four statics are `pattern`,
`parse`, `parse_octets` and `print`; the scan itself is the prelude's `format_spans`. On the old path the
same four are MethodRows (features/formats/mod.av). A pattern `"…"` in a `match` is `Pat.Format`,
read by the same reader (format.av `read_format`).

## B. `R.parts()` — a format's shape as a value

- **@std/meta declares the shape, once:** `FormatShape { head: string, holes: List<FormatHole> }` and
  `FormatHole { name: string, ty: string, greedy: bool, piece: string }`. `ty` is the type the hole
  binds, spelled as it is written: "string" where untyped.
- **The door is a fifth generated static,** `static fn parts() -> FormatShape`, beside `pattern()`.
  Its body is a record literal that item_formats writes from the same `GrammarSpec` it reads for
  `pattern()`. So it is read off the reader's parts, never re-parsed from the spelling, and no
  `crossing.av` row is needed: the value is static data the binary lays out like any const.
  `FORMAT_STATICS` gains "parts".
- **One definition:** the compiler converts `GrammarSpec → FormatShape` in exactly one verb,
  `format_shape(spec)`. B's door, C's library function and C's match law all read through it.
- **Old path:** the doors there are MethodRows. I'd give `parts` only to the layer and mark the gap
  (`tapes --new-only`), since the old path is being switched off. Say if you want the row as well.
- **Witness:** the README's wanted_door prints `3`, and `usage` drawn from `Copy.parts()` prints
  `<src:string> <dst:string...> <mode:int>`.

## A. A hole of any type that crosses as text

- **Today:** `reads_of(h)` matches `ty.name` against "string"/"int", the name-as-text dispatch
  CLAUDE.md forbids.
- **The decision moves to where the hole's type is RESOLVED.** Typing resolves the hole's `TypeRef`
  to a type and records a `HoleReading` fact per hole: `Text | Int | Form(ty)`.
  - `Text` and `Int` are told by the resolved type's identity (the owned `str`/`int`), not its spelling.
  - `Form(ty)` holds where `ty` implements `@std/text`'s `TextForm`. The trait is asked by DECLARED
    IDENTITY: on the layer the bound is the `SignedType` of the declaration `@std/text` exports
    (file + name), asked through `implements(engine, reader, ty, bound)` (item_methods.av, written
    impls first). On the old path it is the `DeclId` of that declaration through the impls table.
    No name is compared as text.
  - Anything else is refused once at the hole: "`T` crosses no text — implement `@std/text`'s
    `TextForm`" (type.format_parse, its voice re-worded to the law).
- **The readers take the fact, not the name:**
  - item_formats' `parse`: a `Form` hole is `T.from_text_form(span)?`, and absence fails the parse.
  - `print`: writes `r.f.text_form()`, and the round-trip guard (`survives`) runs on that same text.
  - A pattern arm (lower.av): binds through `T.from_text_form(span)`, and absence moves to the next arm.
  - `int` keeps its inline `format_int` path, and `string` its span.
- **One protocol a type:** parse and print both go through that type's `TextForm` impl; there is no
  registry and no second mechanism. `Time` works at once.
- **Witness:** the README's program prints `matched 7 miss 7 /items/i7`. A refusal case covers a hole
  typed by a type with no `TextForm`.

## C. `subsumes(A, B)` — "A accepts every text B accepts"

- **One definition, in @std/meta:** `export fn subsumes(a: FormatShape, b: FormatShape) -> Subsumed`,
  where `Subsumed { Covers, Misses, Unknown }`. It is pure Avra over B's value.
  - The compiler's match law calls it on `format_shape(spec)` of two arms.
  - `A.subsumes(B)` is a door that folds at compile time to `subsumes(A.parts(), B.parts()) ==
    .Covers`, so the compiler and every library ask the very same function.
- **Semantics, exactly the scan's:** a text matches F iff it begins with F's head and the scan
  succeeds. Hole k ends at its piece's FIRST occurrence (or its LAST where greedy), and a last piece
  "" means the hole takes the rest. Each span must also read as its type: `int` is `-?[0-9]+`,
  `string` is any text (empty included, as `format_spans` allows), and `Form(T)` is opaque.
- **The algorithm, where neither format holds a `Form` hole, is exact and decidable:**
  - Each such format denotes a REGULAR language.
    - A lazy hole followed by piece p is "a span holding no p, then p".
    - A greedy hole is "a span, then p, then a remainder holding no p".
    - Both are KMP automata over p.
  - The alphabet is partitioned into classes: each byte that occurs in either format's head or pieces,
    the digits, `-`, and "every other byte". The DFAs therefore stay small.
    - States per format are at most Σ|pieces| + |head| + (number of holes) × (KMP states of its piece).
  - "A covers B" is decided by emptiness of L(B) ∩ ¬L(A) on the product DFA, at most
    |DFA_A| × |DFA_B| states.
  - **The bound:** a cap of 4096 product states (the longest real route pattern gives well under 200).
    Past the cap it answers `Unknown`, and the walk itself is linear in the product.
- **A `Form(T)` hole is not regular.** Such a pair is decided only by STRUCTURAL ALIGNMENT:
  - Equal heads and equal pieces at each position.
  - Each of A's holes accepts at least what B's does at that position: `string` ⊇ everything,
    `int` ⊇ `int`, `Form(T)` ⊇ only `Form(T)`, the same type by identity.
  - Equal greed.
  - Alignment that holds is `Covers`; anything else is `Unknown`, never `Misses`. A `Form` hole can
    make no claim of missing.
- **Match reachability:**
  - In the layer's item_unreached, for each unguarded arm whose pattern is a format or a hole-free
    literal over a `string` subject, an earlier unguarded format arm `i` with
    `subsumes(i, j) == .Covers` warns `type.unreachable_arm` at arm j, naming arm i's pattern.
  - `Unknown` warns nothing.
  - A hole-free literal B needs no automaton: run A's scan on B's text, which is exact.
  - The README's three dead arms are each named. `{n: int}` over `{k: int}` is `Covers`: names don't
    matter, readings do.
- **std-http's `covers`/`shadows`** in route.av stay its own until it moves onto `subsumes`. Then there
  is no second copy; that is its owner's step, and I'd note it in the ROADMAP.
- **Old path:** it warns no format arm today. The new warnings are the layer's own (`tapes --new-only`
  doesn't apply to warnings), recorded as a known difference with its reason. Say if you'd rather the
  old path got the law too.

## Order and landing

- **B** comes first: it adds `FormatShape` and `format_shape`, which C's library function takes.
- **A** next: it adds `HoleReading`, and C reads the hole's reading through B's `ty`, plus the
  reading fact the match law needs.
- **C** last.
- Each is its own commit with its witnesses (prints cases, a refusal case for A, a warns case for C),
  and C's match law is witnessed in the README's three arms.
- **Questions for you:**
  1. The old-path doors for B and the old-path law for C, or layer-only?
  2. Is `@std/meta` the right home for `subsumes`, or a new `@std/formats`?
