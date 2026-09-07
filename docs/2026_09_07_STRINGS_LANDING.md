# Typed string patterns and grammar values — the landing

> **Status:** design, 2026-09-07, for `lane/strings` under the HTTP lead.
> **Ruled** by the HTTP lead and agreed by lane C — §10 records each
> ruling and what it changed. The pure core (format parser, reference
> matcher, `print`, the domain check) is built and red-teamed; the
> compiler feature is not. Every claim about *today's compiler* was
> probed with `./avra check` / `./avra run` at base
> `9fe5597` in `../avra-lane-strings`, bootstrapped from that tree
> (`sh tools/watch.sh 4000 make bootstrap`, peak 606 MB, status 0). A
> probe result names the base that answered it; the confidence ledger at
> the end lists every one.
>
> **What it answers:** Part III's crown jewel and Part V's Moves 1, 4, 5 of
> `../forge-crafting-intepreters/docs/2026_06_30_STRINGS_FROM_THE_FUTURE.md`,
> against the ROADMAP's HTTP-campaign ask "TYPED STRING CAPTURES / NAMED
> FORMATS … WANTING SITE: `@std.http`'s router."
>
> **The oracle** is `packages/std-http/src/frame.av` — a hand-written
> HTTP/1.1 framer over `Bytes` with 45 attack-table cases. The compiled
> scan is measured against it, not against an opinion.

---

## 0. The shape of the answer, in one page

A format is a **string literal with holes**. In pattern position it
parses; as a declaration it is a value that parses *and* prints.

```avra
match line {
    "{method} {path} HTTP/{major: int}.{minor: int}" -> serve(method, path, major, minor)
    _ -> bad_request()
}

grammar RequestLine = "{method} {path} HTTP/{major: int}.{minor: int}"

let fields = RequestLine.parse(line)          // RequestLine?
let text   = RequestLine.print(fields!)       // string?, refused off-domain
```

The whole feature rests on **one scan law**, stated once and obeyed
everywhere:

> **THE SCAN LAW.** A format matches a subject by one anchored,
> left-to-right pass. The **first** piece is a prefix and the **last** is
> a suffix; every piece **between** them is found at the **first**
> position at or after the cursor, and the capture before each piece is
> the span up to it. The pattern accepts when the pieces are found in
> order and the last capture's span is not negative. There is no
> backtracking, so the scan is linear in the subject and its cost is the
> sum of its literal searches.

*(This law is the second draft. The first said "every piece is found at
the first position at or after the cursor, and the cursor must land
exactly at the end" — uniform and wrong: an empty last piece is found
immediately at the cursor, so the last capture came back empty and the
flagship pattern failed on its own example. Building the reference
matcher found it in the first run; anchoring the last piece at the end
removes the case rather than adding one, because an empty suffix sits at
the subject's end by definition. Recorded because the paper is a design
artefact and a law that had to be corrected by running it is worth more
than one that reads as if it were obvious.)*

Everything else in this paper is a consequence of that sentence, a
refusal that keeps it true, or a measurement that proves it.

**The five slices.** S1 this paper. S2 patterns over `string`. S3
patterns over `Bytes`. S4 `grammar` declarations that parse. S5 `print`
and the round-trip law. §10 asks the lead for one ruling before S2 can
start; §11 says what S2 can begin regardless.

---

## 1. (a) The surface: typed string patterns

### 1.1 What a format literal is

A string literal **in pattern position** is read by a format parser that
runs in this feature's builder. The lexer is untouched.

| written | means |
|---|---|
| `{name}` | a capture binding `name: string` — the span up to the next literal |
| `{name: T}` | a capture parsed through `T`'s text protocol; the arm fails if it does not parse |
| `{_}` | an anonymous capture — consumes, binds nothing |
| `{{` / `}}` | one literal `{` / `}` |
| anything else | literal text |

Probed at `9fe5597`: `{b}` inside a string literal is already plain text
(`"a {b} c"` runs to `a {b} c`), and `\{` is **not** an escape — the lexer
keeps an unknown escape as its two characters, so `"a \{b\} c"` runs to
`a \{b\} c`. So the escape for a literal brace **must** be the doubling
convention, and it belongs to the format parser rather than the lexer.
That is the right home anyway: the lexer is lane A's, and doubling is what
printf, .NET and Rust already teach.

Interpolation and formats never collide, and the lexer already keeps them
apart for free: `"${x}"` in pattern position does not parse at all today
(F0100, "expected `}` to close the `match`"), because an interpolated
string lexes as `ISTR_BEGIN … ISTR_END` and the `pattern` rule captures a
bare `STRING`. Pattern captures are bindings; interpolation holes are
expressions; the two contexts are separated by the token kind, not by a
rule anyone has to remember.

### 1.2 The scan, worked

For `"{m} {p} HTTP/{maj: int}.{min: int}"` the parser yields

```
pieces   = ["", " ", " HTTP/", ".", ""]        // pieces.length == captures.length + 1
captures = [m: string, p: string, maj: int, min: int]
```

and the scan is:

1. `pieces[0]` must be a **prefix**; the cursor moves past it.
2. `pieces[4]`, the last, must be a **suffix**; call its position `stop`.
3. For each capture but the last: find its following piece at the first
   position at or after the cursor. Absent → the arm fails. The capture
   is the span from the cursor to that position; the cursor moves past
   the piece.
4. The last capture is the span from the cursor to `stop`. Negative →
   the arm fails.
5. A typed capture parses its span. Failure → the arm fails.

An empty last piece needs no case: an empty suffix sits at the subject's
end, so `stop` is the length and the last capture runs to it. A format
with **no** captures is a plain literal and is compared for equality —
which is the node it is built as anyway.

### 1.3 The consequence that must be tested, not hidden

No backtracking has a visible edge, and it is the price of the linear
guarantee. It lives on the **interior** captures:

```avra
match "w.x.y" { "{a}.{b}" -> "${a}|${b}", _ -> "no" }   // "w|x.y", NOT "w.x|y"
```

`a` stops at the **first** `.`, never the last. A backtracking matcher
could prefer the other split; this one cannot reach it, by construction.
That is not a defect to paper over — it is the guarantee — and it gets a
named test (`then "an interior capture stops at the FIRST next literal, never the last"`)
so nobody later "fixes" it into a backtracker.

The last capture is the mirror image and is worth its own test, because
the two rules differ and a reader will expect them not to:

```avra
match "x.txt.txt" { "{a}.txt" -> a, _ -> "no" }   // "x.txt" — the suffix anchor
```

Both are verified — §11's ledger records the reference matcher's output
for each.

### 1.4 What the format refuses

- **Two captures with nothing between them** — `"{a}{b}"` — cannot be
  split by any scan, and the vision's `"{head}{tail}"` needs a `char`
  type Avra does not have. Refused with a voice that says so.
- A `{` that does not open a capture, and a bare `}`. Refused, naming
  `{{` as the escape.
- An empty capture *name* (`"{}"`) — write `{_}`.
- A capture name written twice in one pattern.
- A typed capture whose type has no text protocol.

An **empty match** for a capture is allowed: `"{a} {b}"` against `" x"`
binds `a = ""`, `b = "x"`. A format states a shape, not a validator; a
non-empty method is the arm's business or the typed capture's. The oracle
agrees — `frame.av` refuses a zero-length verb in `request_line`, in its
own words, which is exactly where that law belongs.

### 1.5 The typed capture protocol

`int` lands first, and its domain is stated rather than assumed: an
optional `-` followed by **1 to 18** ASCII digits. Eighteen digits is
under 2^63, so the accumulate needs no overflow check — the same bound
`frame.av`'s `decimal` already uses, for the same reason. Nineteen digits
fails the arm; it is not a trap and not a wrong answer.

**It parses through a SHARED ROW, not an inline digit loop** — the HTTP
lead's ruling, and it is the right one. This paper proposed emitting the
accumulate inline, on the argument that it would then do the oracle's
exact arithmetic with no runtime dependency. That argument was about
*this* feature's convenience. The doctrine's argument is about the tree:
`frame.av`'s `decimal`, this capture, and a user's `"42"` conversion are
**three copies of one law**, and the third copy names the concept. One
row, one C body, three callers. Until the row lands, the capture may
call the framer's exact arithmetic — but as an interim, not as the
design.

A user type joins by **method row**, not by trait. Probed at `9fe5597`:
a trait method returning `Self?` is refused — `impl FromText for Port`
with `fn from_text(s: string) -> Port?` gives F2032, "`Port.from_text`
does not wear `FromText.from_text`'s signature", so `Self` does not
resolve to the impl type. A `CaptureRow` registry
(`{ name, builds: Type, reads: fn(...) -> ... }`) is the tree's own seam
for this — data, one place, queried by five consumers, exactly as
`rt_sigs()` and `MethodRow` already are. S2 ships the row type with one
row in it (`int`); the second row is what proves the seam, and it is not
in this arc.

---

## 2. (d) Typing: the laws, and what each refuses

**The subject.** A format pattern reads text: `string` (S2) or `Bytes`
(S3). Anything else refuses in the shape the tree already uses — today
`match 5 { "a" -> 1, _ -> 0 }` answers F2038, "a `string` never matches
`int`", and a format's refusal reads alike with its own code.

**The binds.** A capture is an arm binding, in pattern order, exactly as
a variant's payloads are. `{name}` binds `string`; `{name: T}` binds `T`;
`{_}` binds nothing.

**Three laws the tree already enforces, which formats inherits for free
and must therefore not re-implement:**

1. *An `or` arm binds nothing* (F2039). `arm_checks` refuses any arm
   whose alternatives bind, so a capture-bearing format inside an `or`
   run is refused today, in today's words. A capture-*free* format is not
   a format — it is a literal. Nothing to add.
2. *Coverage.* A format pattern is refutable, so a `match` over a
   `string` still needs its catch-all; `needs_catch_all` already fires
   for a subject with no variants. Nothing to add.
3. *The registry-hole lint* (F2040) counts arms that test a **variant**.
   A format tests no variant, so it neither triggers nor silences the
   lint. Nothing to add.

That is the argument for putting the format in the pattern ladder at all
rather than beside it: three of the laws it needs are already written,
and a parallel surface would have to grow its own copies of each.

**The refusals formats owns** are §8.

---

## 3. (c) How the format is read out of the PEG ladder — and the one seam

### 3.1 The grammar does not change

Lane C's advice, adopted: the `match` pattern grammar is scar tissue and
must not move. It does not. `enums` today contributes

```
pattern = "." vn:NAME (…)? -> variant_pat(…) | "_" -> wild_pat() | "true" -> true_pat()
        | "false" -> false_pat() | s:STRING -> str_pat(s) | v:NUMBER -> num_pat(v)
        | n:NAME -> bind_pat(n)
```

and the only change proposed is that the **`s:STRING` alternative and its
`build_str_pat` builder move to `features/formats/`**, unchanged in
shape. "The gram decides ownership of PARSE"; a string in pattern
position is now formats' to parse. `enums` keeps ownership of the
MEANING of `Pat.Lit`, which formats still builds for a capture-free
literal. Alternatives are ordered choices merged by rule name, and a
`STRING`-headed branch shares a first token with none of the other six,
so feature order does not matter here.

The builder is **total**. It reads the text, and on a malformation it
still produces a node carrying what it read plus the recorded fault —
"DECLARE THE WRECKAGE" — so the law speaks once at check time with an
F-code and a span, rather than as a fatal `Cause.Builder` parse error at
the whole branch's span that would cascade through the rest of the file.

A capture-free format builds `Pat.Lit(Expr.StrLit(unescaped))` —
byte-identical to today's behaviour except that `{{` becomes `{`.

### 3.2 The meaning change, and its measured blast radius

This is not a purely additive change, and the paper should say so
plainly. Today, at `9fe5597`, the flagship program **checks clean and
runs**:

```avra
let line = "GET /x HTTP/1.1"
match line {
    "{method} {path} HTTP/{major: int}.{minor: int}" -> "fmt",
    "GET /x HTTP/1.1" -> "literal",
    _ -> "miss",
}
```

`./avra check` exits 0; `./avra run` prints `literal`. The format arm is
a literal that can never match, and it silently takes a later arm. So the
change is not "a refusal becomes an acceptance" — it is **a silently
wrong acceptance becoming the right meaning**, which is the better
direction but still a change to accepted programs.

Measured blast radius in this tree: **37** string literals in arm-head
position across `packages/` and `corpus/`, of which **0** contain a brace.
(Scope: single-line arm heads matched by `^\s*"[^"]*"( or "[^"]*")* ->`
over `--include='*.av'`; a multi-line or unusually-spelled arm would not
be counted, and 3856 brace-bearing string literals tree-wide are almost
all ordinary expressions, not patterns.) So the meaning change is real in
principle and affects nothing here.

### 3.3 THE SEAM — the one thing this paper cannot decide alone

A format pattern needs a node. `Pat` is core's:

```avra
export enum Pat { Wild  Rest  Bind(name: string)  Variant(name: string, args: List<PatId>)  Lit(value: ExprId) }
```

It has **11 exhaustive matches** plus one catch-all projection: 3 in
`core/nodes.av` (`pattern_binds`, `irrefutable`, the fingerprint), 4 in
`features/enums/check.av`, 4 in `features/enums/lower.av`, and
`hole_binds`. Growing it is cheap in lines and expensive in doctrine,
because **enums is a feature**, and "a feature never matches another
feature's variants."

Proposed node, carrying its data in core so that most consumers answer
from the data and not from format knowledge:

```avra
/// One capture in a format: the name it binds (`_` binds nothing) and
/// the type it parses through (absent for a text span).
export type Capture = { name: string, ty: TypeRef? }
/// A format pattern: the literal pieces and the captures between them.
/// pieces.length == captures.length + 1
Format(pieces: List<string>, captures: List<Capture>)
```

This is **lane C's shape, and it is better than the one this paper first
proposed** (`{ name: string?, ty: string? }`) on both fields, for reasons
worth writing down:

- `name: string` with `"_"` for an anonymous capture is **not** a
  sentinel — `_` is the language's own word for "binds nothing", which
  `Pat.Wild` already spells. A `string?` would have invented a second
  way to say what the language already says. The repeat law skips `_`,
  exactly as it must.
- `ty: TypeRef?` beats a bare name because `TypeRef` is a plain record
  (`core/nodes.av:332`) that a builder **can** construct for a name —
  the objection this paper raised, that a builder cannot re-enter the
  type grammar, was true and irrelevant. And it leaves room for
  `{n: int?}` or `{xs: List<int>}` without a second representation.

**One ask that follows, for whoever writes the variant** (§12.3): core
should export a single `named_ref(name) -> TypeRef` first. The shape is
hand-spelled at seven fields in five places already — `named_ref` in
`features/decls.av:786` (private), `void_ref` in
`features/builder.av:154` (exported, the same thing with `"void"` in
it), a `ty(name, optional)` helper in `core/tests/nodes_test.av:8`, and
four more literals in that same test file. The doc on `plain`
(`core/nodes.av:343`) already warns why: "A RECONSTRUCTION NAMES WHAT
CHANGES, never the rest — spelling the others out drops the NEXT field
silently, and a field with a DEFAULT drops without even a compile
error. `muts` was lost here exactly so." The format builder would be the
sixth hand-spelling.

With the data in core, the 12 sites split as follows — this is the
measurement, not an estimate:

| site | answers | needs format knowledge |
|---|---|---|
| `core` `pattern_binds` | the capture names | no — reads the data |
| `core` `irrefutable` | `false` | no |
| `core` fingerprint | a new code | no |
| `enums` `names_variant` | `false` | no |
| `enums` `variant_args` | `null` | no |
| `enums` `whole_variant` | `null` | no |
| `enums` `whole_test` | `null` | no |
| `enums` `looks_inside` | `false` | no |
| `enums` `hole_binds` | already a catch-all projection | no |
| `enums` `pat_types` | the capture types | **yes** |
| `enums` `pat_reg` | emit the scan | **yes** |
| `enums` `bind_regs` | the captured registers | **yes** |

Nine sites answer in one word. **Three do not**, and two of those three
are the scan itself.

There is a second, sharper reason the three cannot simply be written in
enums, and it is structural rather than doctrinal: enums' pattern
protocol is **test, then bind** — `accepts_reg` emits the test outside
the arm's region, `bind_regs` emits the reads inside it. A format's test
*is* its bind. Splitting them either runs the scan twice per arm, which
forfeits the performance obligation outright, or requires the scan's
capture registers to survive from one call to the other — which is a new
general idea about patterns, not a line of enums.

**ROUTE A — mint the pattern-semantics seam. RULED, and agreed.**
`PatSemantics` with three methods (`pat_types`, `pat_accepts`,
`pat_binds`), and a `pat_semantics_of` map beside its two twins in
**`features/dispatch.av`** — `semantics_of` at :54, `stmt_semantics_of`
at :79 — not in `language/program.av`, which is where this paper first
put it. Each twin carries a doc line saying a new variant breaks *there*
at compile time and that the impl it names owes every pass; the third
carries the same. Enums' three bodies move behind `EnumPatSemantics`;
formats' three land in `features/formats/`. Roughly 40 new lines of seam
and ~120 lines of movement inside enums, with no behaviour change to
either.

**Who writes what** (settled with lane C): **lane C** writes the seam,
the enums movement, and the `Pat.Format` variant with its nine one-word
arms, gated in their own lane, and hands over a tree where
`PatSemantics` exists with enums behind it and nothing else changed.
**This lane** writes only formats' three bodies. That is the smallest
possible footprint in another lane's files, and it was lane C's offer,
not this lane's request.

**The argument is OWNERSHIP, not the rule of three** — lane C's, and it
is stronger than the one this paper first made. `Pat` is core's, but
`pat_types`, `pat_reg` and `bind_regs` are **enums'**, and they match it
exhaustively. The moment `formats` owns a sixth variant, those three
would have to grow an arm for a variant **enums does not own** — which
"a feature never matches another feature's variants" forbids outright.
The seam is not owed when a third pattern feature makes it convenient;
it is owed the moment a **second** feature owns a `Pat` variant, and
formats is that moment. (The paper's first argument was the ladder count
plus the two pattern features "The subset today" still wants — struct
destructuring and list patterns. That argument is true and it is weaker,
because it invites "two copies may wait" as a reply. Ownership admits no
such reply.)

**ROUTE B — teach enums about formats.** Rejected. It puts a feature's
rule in another feature's file and makes the scan enums' code forever.

**ROUTE C — no pattern at all in this arc.** Land S4/S5 first: the
`grammar` declaration and the scan engine need **no** `Pat` change, and
the match form is then pure sugar over a value that already works. This
is the fallback if the seam is refused or deferred, and it is not a
workaround — it is the same engine, one surface later. Its cost is that
the flagship spelling does not land in this arc.

**ROUTE D — the scan in the features root**, beside `checks.av`,
`emit.av` and `values.av`, with `features/formats/` reduced to a builder.
Cheapest to write and dishonest to read: a format scan is one feature's
rule, not shared infrastructure, and the root would acquire a resident
that does not belong to it.

**Recommendation: A, with C as the fallback.** Either way S2 touches
lane C's territory — `language/mod.av`, `core/nodes.av`,
`features/enums/`, and under A `language/program.av` — so the lead's
ruling and lane C's agreement are wanted before S2 opens. §11 says what
proceeds meanwhile.

---

## 4. (e) Lowering: the emission plan

Everything goes through the emission vocabulary (I33) — `open_region`,
`arm_end`, `close_region_as`, `const_int`, `const_bool`, the walk verbs
— and every register is minted in emission order (I29). No new IR
variant: the scan is regions, constants, `Bin`, and `CallRt` rows that
already exist. The IR's eight-consumer protocol is not opened.

**Over `Bytes` (S3, and the performance target).** The rows are already
there: `avra_bytes_index_of(b, needle, from)`, `avra_bytes_slice`,
`avra_bytes_eq_at`, `avra_bytes_len`, `avra_bytes_at`. The scan is a
straight-line sequence of guarded steps, one `index_of` per literal
piece, zero copies until a capture is materialised. This is
instruction-for-instruction what `frame.av`'s `request_line` does by
hand, which is why parity is the obligation and not an aspiration.

**Over `string` (S2) — and a real asymmetry found while probing.**
`Bytes.index_of` takes a `from` offset; `string.index_of` does not.
Probed at `9fe5597`: `"abcabc".index_of("b", 2)` is F2000, "`index_of`
takes 1 arguments, found 2", while `"abcabc".bytes().index_of("b".bytes(), 2)`
answers `4`. **Any left-to-right scan over text in this language is
therefore either quadratic or copying** — that is a language gap, not a
formats problem, and it is worth reporting on its own.

Two ways forward, and S2 does not have to block on either:

- *The ask.* One runtime row, `avra_str_index_of_from(s, needle, from)` —
  a one-line C body beside `avra_str_index_of`, one `rt_sigs()` row, one
  `RtHost` arm, one `tools/externs.py` entry. It closes the asymmetry for
  everyone and makes the string scan zero-copy. `runtime/` and
  `core/runtime_api.av` are lane A's; this is an ask to route through the
  lead, not something this lane writes.
- *The fallback S2 ships without waiting.* Convert the subject to `Bytes`
  **once** (`avra_bytes_of_str`), search with the Bytes rows, and cut each
  capture from the **original string** with `avra_str_substring` — which
  does not re-validate. Every capture's boundaries are exact positions of
  whole literal matches, so each capture is a whole substring of a valid
  UTF-8 string and is itself valid UTF-8; no validation is needed and none
  is paid. Cost: exactly one extra copy of the subject per evaluated
  format arm, and nothing else. For a request line that is one ~50-byte
  allocation.

The typed `int` capture lowers to a **shared runtime row** (§1.5). Its
owner is the SQLITE campaign, not lane A: decimal is CORE by that
campaign's scope decision, and lane A has nothing in flight on it. A
misrouted dependency is how a lane comes to block on another that does
not know it is blocking, so the row is named by its owner here. Until it lands, the capture
emits the framer's exact arithmetic through the walk vocabulary, so the
compiled scan and the hand-written one agree on the answer from the
first day and swap implementation later.

**AND EVERY MINTING CALL IS A ROW BY NAME, NEVER AN EXTERN** — the HTTP
lead's measurement, and it is a rule this lowering must obey rather than
a caution. A `Bytes` row that answers a managed value is a core row
carrying `owns_result: true`; an `extern fn` that is not a row **leaks
what it mints**, measured in the HTTP lane today. So every capture this
scan materialises — `avra_str_substring`, `avra_bytes_slice` — is
emitted as `Ins.CallRt` naming the row, and an extern is never a
shortcut to the same C function. The registry is what carries the
ownership fact; a declaration that bypasses it bypasses the fact.

Ownership: a `string` capture is a fresh managed box from
`avra_str_substring` (`owns_result: true`); a `Bytes` capture likewise
from `avra_bytes_slice`. Both are ordinary managed values bound in the
arm's region, settled by the memory pass exactly as a variant payload is.
A capture that binds nothing (`{_}`) is never materialised — only its
span is computed.

---

### 4.1 The three bodies, and the one thing the seam must carry

`PatSemantics` is three methods, and formats' three are written against
this shape:

```avra
fn pat_types(mut cx: TypeCx, p: PatId, expected: TypeId) -> List<TypeId>
fn pat_accepts(mut cx: LowerCx, p: PatId, v: Reg, vty: TypeId) -> Reg
fn pat_binds(mut cx: LowerCx, p: PatId, v: Reg, vty: TypeId) -> List<Reg>
```

`pat_types` is straightforward: the subject must be `string` or `Bytes`,
and each capture answers its written type resolved, or `Str`.

The lowering pair is not, and the reason is structural: **enums' pattern
protocol is test-then-bind, and a format's test IS its bind.** The
accept runs *outside* the arm's region (so an untaken arm reads nothing);
the binds run *inside* it. Emitting the scan in both places runs it twice
per arm and forfeits §5 outright.

**THE RESOLUTION IS THE ORACLE'S OWN RULE, and it costs nothing.**
`frame.av` keeps "names and values as (lo, hi) offsets, never a `slice`
until the application asks" — §2.5 rule 4 of the framing laws. So:

- `pat_accepts` emits the scan and records, per capture, either its
  **(lo, hi) offset pair** (an untyped capture) or its **parsed value**
  (a typed one). Every one of those is an `int`. **No managed value is
  minted outside the arm's region**, so an untaken format arm allocates
  nothing at all — it does its literal searches and stops.
- `pat_binds`, inside the region, emits one `avra_str_substring` or
  `avra_bytes_slice` per untyped capture from the offsets it was left,
  and hands a typed capture's value straight through.

**What the seam must carry for this to work** (the one ask on lane C's
shape, §12.5): a per-pattern slot on the lowering context — say
`cx.pinned_at(p, regs)` and `cx.pinned_of(p)` — holding the registers a
pattern's *test* produced for its *binds* to read. That is pass STATE,
not a feature's rule, so it belongs on the context by CLAUDE.md's own
line. It is general rather than format-shaped: a list pattern
(`[a, b, ...rest]`, which "The subset today" still wants) has exactly the
same property — its length test and its element reads share one walk.

If lane C would rather not add the slot, the alternative is to widen the
lowering side to one method answering both the verdict and the binds.
That is cleaner in isolation and it would change how **enums** emits its
arms, which is the one thing this arc is trying not to do — so the slot
is the recommendation.

---

## 5. (f) The performance obligation, and how it is measured

**The obligation.** The compiled scan for the HTTP request line runs
within measurement noise of `frame.av`'s hand-written scan. The
obligation is stated over **`Bytes` subjects (S3)**, because that is where
the oracle lives and where a fair comparison exists; S2's string path
carries the one documented extra copy above and is measured separately
rather than being excused.

**How.** A benchmark program parses the same request-line buffer N times
two ways — `frame.av`'s `request_line`, and a `match` with the format
pattern — timed with `@std/time`, run under
`sh tools/watch.sh 4000`, both engines, and reported as ns/parse with N
chosen so a run takes seconds rather than milliseconds. Both figures come
from the same binary in the same run, so the comparison survives a noisy
machine even when the absolute numbers do not.

**And the measurement that actually matters.** `make census CMD="…"` for
exact retain/release and list-write counts, per caller. Instruction count
is not the risk here; allocation is. A format scan that allocates once
per capture is correct and fast; one that allocates per literal search is
correct and ruinous, and only the census can tell them apart. CLAUDE.md's
rule holds in both directions: allocation here is cheap, so a measured
allocation is a fact to report, not automatically a thing to remove.

**THE BASELINE, measured at `9fe5597` before there is anything to
compare it to.** A package framing one head 200,000 times, the bounds
record hoisted out of the loop, three runs under
`sh tools/watch.sh 4000`:

| head | run 1 | run 2 | run 3 |
|---|---|---|---|
| minimal HTTP/1.0, 25 bytes, 0 fields | 972 ns | 813 ns | 879 ns |
| full HTTP/1.1, 112 bytes, 4 fields | 3201 ns | 3529 ns | 3217 ns |

So **the noise band is about ±10%**, which is what "within measurement
noise" has to mean when S3 compares. Hoisting the `Limits` record out of
the loop changed nothing measurable (971 ns before, 813–972 after) —
consistent with CLAUDE.md's "allocation here is cheap, so avoiding one is
a trade, not a win", and a reminder that the scan's cost is scanning.

**THE COMPILED SCAN, MEASURED.** `tools/bench/frame_scan` reads one
HTTP request line five ways in the same run: the framer over a whole
head, and then the line split BY HAND and by a FORMAT PATTERN, over
text and over octets. 200,000 runs each, the subject hoisted out of
every loop (a `once` read is not free, and inside the loop it inflates
both sides and compresses the ratio), three runs:

| way | run 1 | run 2 | run 3 |
|---|---|---|---|
| framer, whole head | 746 ns | 635 ns | 651 ns |
| text: by hand | 62 ns | 60 ns | 62 ns |
| text: by format pattern | 98 ns | 96 ns | 97 ns |
| octets: by hand | 74 ns | 73 ns | 73 ns |
| octets: by format pattern | 92 ns | 90 ns | 90 ns |

**OVER OCTETS — where the obligation lives, because that is where the
framer works and where nothing is converted — the compiled scan is
1.24x a hand-written scan.** Over text it is 1.58x, and the difference
between the two ratios is exactly the subject conversion the string
path pays and the octet path does not: about 7 ns.

**The remaining 24% is countable and it is one thing.** The hand
version hoists its separator into a `once fn`, as `frame.av` hoists
every literal it scans for; the compiled scan converts each of its four
literals to octets on every attempt, because the IR carries no `Bytes`
constant. Four conversions against zero, and the gap is 17 ns — about
four nanoseconds each, which is what a small box costs here. That is
ask 6, and this measurement is its firing condition rather than an
opinion about it.

**THE PARSE DOOR, MEASURED — AND THE TRIGGER IT FALSIFIES.** Six runs
after the machine quietened, 200,000 each:

| way | ns |
|---|---|
| framer, whole head | 625–652 |
| text: by hand | 62–63 |
| text: by format pattern | 97–100 |
| text: by pattern **plus the same record** | 121–125 |
| text: by `Name.parse` | 122–125 |

**`Name.parse` costs what the pattern costs plus the record it builds,
and nothing else.** The door and the pattern-plus-record control are
identical within noise — the door adds no cost of its own.

That **falsifies the trigger this paper wrote for Move 1's value
shape.** The trigger said: if `Name.parse` measures above the pattern's
scan, the value's once-converted literals are worth the 44 sites. It
does measure above — by 25 ns — and every one of those nanoseconds is
the RECORD, which the value shape would pay identically. The trigger
compared the door against a control that does strictly less work, so it
would have fired forever while naming a cause it could not fix. The
first draft of a firing condition can be wrong in exactly the way a
first draft of a law can, and only a control measurement says so.

**Restated, and this is the version that means something:** the trigger
fires if `Name.parse` measures above **the pattern plus an equivalent
record construction**. Today it does not — 122–125 against 121–125 — so
Route B is vindicated by measurement rather than by argument.

**And a finding about the oracle, not about this feature.**
`2026_09_06_HTTP_FRAMING_LAWS.md` §2.1 records picohttpparser at ≈366
ns for a *9-header, 430-byte* GET. `frame.av` takes ≈3.2 µs for a
*4-header, 112-byte* one — roughly an order of magnitude off the C
reference on a smaller input. That is worth reporting on its own, and it
also sets the honest reading of the obligation: **"within noise of
`frame.av`" is not a claim of C parity**, and this paper should not be
read as making one. Closing the gap to picohttpparser is a separate piece
of work with a separate owner.

**Recorded before the fact, so it can be wrong in public:** I expect the
`Bytes` scan to land within noise, because it emits the same calls in the
same order as the oracle, and I expect the `string` scan to be
measurably slower by one subject-sized copy per match. If the first is
wrong, the seam or the emission order is wrong, and that is the finding.

---

## 6. (b) `grammar` declarations as values — parse, print, and the proof

### 6.1 The spelling, and why this one

`grammar` is **already a keyword** — probed at `9fe5597`, `let grammar = 1`
is F3002, "`grammar` is a keyword". So the declaration needs no new
reserved word and breaks no existing name. The declaration form is free:
`grammar RequestLine = "{method} {path}"` is F0100, "expected BREAK while
parsing `stmt`", pointing at the name.

The existing `grammar { … }` expression (the compiler's own grammar DSL,
`features/grammar_lit/`) is anchored on `"grammar" "{"`, so a `grammar`
followed by a NAME cannot collide with it.

```avra
grammar RequestLine = "{method} {path} HTTP/{major: int}.{minor: int}"
```

declares two things: a **record type** `RequestLine` whose fields are the
captures in order with their types, and the two operations.

### 6.2 `print` takes the record, not named arguments

The vision spells `RequestLine.print(method: "GET", path: "/x", …)`.
Named call arguments do not parse — probed at `9fe5597`: `f(a: 1, b: 2)`
is F0100, "expected `)` to close the arguments", with a cascade.

That refusal is a gift, because the better design was on the other side
of it. **`print` takes the record `parse` answers.** The two operations
are then literal inverses of one another over one type, the round-trip
law reads without machinery, and the named-argument ask disappears
entirely rather than being filed.

```avra
let f = RequestLine.parse(line)          // RequestLine?
let t = RequestLine.print(f!)            // string?
```

### 6.3 The round-trip law, its domain, and why it is provable

```text
parse(print(v)) == v          for every v in the admitted domain
print(parse(w)) == canonical(w)   for accepted wire input
```

The second is not byte identity — `007` parses to 7 and prints as `7` —
which is exactly the caution `2026_09_06_STD_HTTP_TYPED_ROUTES.md`
records, honoured rather than restated.

**THIS CONDITION WAS WRONG IN ITS FIRST DRAFT, and building `print`
found it.** The draft said:

> ~~For each capture *i* except the last, its text does not contain
> piece *i+1*.~~

It is NECESSARY and it is NOT SUFFICIENT, and the counterexample is
small. Take `grammar G = "{a}--{b}"` with `a = "x-"` and `b = "b"`.
Printed, that is `x-` + `--` + `b` = `x---b`. `"x-"` does not contain
`"--"`, so the draft admits it. Parsed, the first `--` in `x---b` sits
at index 1, not 2, so the scan answers `a = "x"`, `b = "-b"`. Run at
this base, both engines: `[x][-b]`. The split moved and the draft
condition never saw it, because **a capture that ENDS WITH A PROPER
PREFIX of the following piece overlaps it**, and `contains` cannot see
an overlap that only exists once the piece is appended.

**THE CORRECTED CONDITION**, which is exact rather than approximate:

> For each capture *i* except the last, appending its following piece
> must place that piece at the boundary and nowhere earlier:
> `(c_i + p_{i+1}).index_of(p_{i+1}) == |c_i|`.

It is the same question the scan itself asks, asked of the smallest
text that can answer it. On the counterexample:
`("x-" + "--").index_of("--")` is 1 and `|"x-"|` is 2, so it is refused.
On the safe case `("x" + "--").index_of("--")` is 1 and `|"x"|` is 1,
so it is admitted.

*Sufficiency.* The printed text is `p0 c0 p1 c1 … p_{n-1} c_{n-1} pn`.
`p0` matches as the prefix, so the cursor sits at `|p0|`; `pn` matches as
the suffix, so `stop` is the start of the trailing `pn`. The first
occurrence of `p1` at or after the cursor is at `|p0| + |c0|` — not
earlier, because the condition says `p1` does not occur inside
`c0 + p1` before `|c0|`, and the text from the cursor begins with
exactly that. So `c0` is recovered exactly and the cursor advances past
`p1`. Induction recovers every capture up to `c_{n-2}`, leaving the
cursor at the start of `c_{n-1}`, which the scan takes as the span to
`stop`. ∎

The lesson is the one this paper keeps relearning: a condition stated
in terms a reader finds natural (`contains`) is not the same as the
condition the machine actually imposes (where the scan STOPS), and only
writing the code that must obey it finds the gap.

The **last capture carries no condition**, and that falls out of the
suffix anchor rather than being granted: its end is positional, so a
value that contains — or even ends with — the final piece still
round-trips. `"{a}!"` prints `x!` as `x!!` and parses it back to `x!`.
Verified, not argued: §11's ledger records it.

So **`print` answers `string?` and refuses off-domain**: an interior
capture that would move its own delimiter cannot round-trip, and
printing it would produce text that parses back as something else.
Refusing is what makes the law true rather than hoped-for. `print` is
total over the domain it admits, and it says so by its type.

The law is **tested**, not asserted: a `then` case per grammar over a
generated value set including the boundary cases — a capture containing
its delimiter (refused), a capture that is empty, an `int` at 1 and at 18
digits and at 19 (the last refused), and a leading-zero input proving the
second law is canonicalisation and not identity. `#assert
RequestLine.round_trips` at compile time is Move 5 territory and is a
recorded trigger, not this arc.

### 6.4 The door `parse` reaches through — and what each route costs

**THIS SECTION WAS WRONG, and the correction is the point.** It said the
value shape needed "zero new doors and no other feature touched", and the
HTTP lead ruled on that sentence. The probe behind it was of USER-WRITTEN
Avra — `type Fmt<T>` with an `impl` — generalised to a BUILTIN row
without checking, which is CLAUDE.md's measurement-generalised-past-its-
scope trap committed inside a design paper. Both routes cost something,
and the counts below are what reversed the ruling.

**The starting fact, unchanged.** A type name as a receiver means variant
construction and nothing else. Probed at `9fe5597`: with
`type Port = { n: int }` and `impl Port { fn parse(s: string) -> Port? }`,
the call `Port.parse("80")` is F2003, "`Port` is a record, not an enum".
`callee_of` maps every `.TypeName` receiver to `Callee.Variant`, and
**there is no type-qualified call anywhere in this language** — CLAUDE.md
says so in as many words.

**ROUTE A — the grammar name is a VALUE of a generic `Format<R>`, with
`parse`/`print` as method rows.** Cost, counted: every builtin generic
type row in the tree maps to a DEDICATED `Type` variant — `List` to
`Type.List`, `Map` to `Type.Map`, `Result` to `Type.Res`, and those three
are all of them — so `Format<R>` needs `Type.Format(R)`. That breaks **44
exhaustive `Type` matches across 19 files**, spanning core, features and
the language driver. (`make vocab` reports "Type has 2 exhaustive
consumers"; the tree has forty-four. A keeper claiming a scope wider than
its coverage, reported separately.) What it buys: a format is a real
value, so `handle(RequestLine)` works, and its literals are converted to
octets ONCE at construction rather than per attempt — which would erase
the pattern's whole 24% gap (§5) with no IR constant at all.

**ROUTE B — `Name.parse(text)` EXPANDS at compile time** into the same
scan the pattern lowers, plus a record construction. Cost: one new
`Callee` variant with its admission rule, in `features/impls/`. `Callee`
has **four consumers** — its definition in `impls/callee.av`,
`impls/check.av`, `impls/lower.av` and `features/contexts.av` — one
directory, and its own doc says a new receiver kind breaks both passes at
compile time. (Grep the FILE, not the name: `language/receivers.av` has a
different enum also called `Callee`.) What it costs: no format exists at
run time, so a grammar cannot be PASSED as a value — Move 1's
`handle(RequestLine)` does not compile. What it buys: parsing costs
exactly what the pattern costs, and four sites against forty-four.

**RULED: ROUTE B.** Three-and-a-bit sites in one directory against 44 in
three lanes is not close, and the run-time argument agrees. The admission
rule is what makes it a capability rather than a special case, and it is
deliberately the NARROW one:

> **RULE A.** A type-name receiver means a call when the type's
> declaration is a `grammar` AND that grammar declares a door of that
> name. Anything else is variant construction, unchanged.

The wider **Rule B** — any type name with an inherent fn of that name —
is STATIC METHODS. **The owner granted them after this was written**, so
Rule B lands in lane C's slice and a grammar's `parse` becomes one case
of a general type-qualified call; nothing here is thrown away, because
Rule A's test is a narrowing of Rule B's and not a different question. The
difference matters at the test, not at the wording: Rule A asks the
DECLARATION's KIND, never "does it have a fn called that", because the
second question IS Rule B wearing Rule A's clothes. If static methods are
later granted, Rule A's test widens by one line and nothing here is
thrown away.

**RECORDED TRIGGER — Move 1's value-passing, and the number that brings
it back.** Route B forfeits passing a grammar as a value. It returns if
either fires: a consumer needs `handle(RequestLine)` — a router taking a
route as data is the obvious one — or `Name.parse` measures above **the
pattern plus an equivalent record construction**. The second half is the
CORRECTED form: the first draft compared the door against the bare
pattern, which does strictly less work, so it fired on the record's cost
and named a cause the value shape could not fix (§5). Measured today the
door is at parity with that control, so this half does not fire.

`{_}` is legal in a match pattern and **refused in a `grammar`
declaration** — an anonymous capture has no field to record and nothing
to print.

---

## 7. (g) Move 4 — a recorded trigger, not a build

Part V Move 4 is one grammar running on a literal *or* a live stream, the
matcher suspending when it needs more bytes. It is **not built in this
arc**.

> **RECORDED TRIGGER — resumable formats.** Fires when `@std.http`'s
> server must frame a request across reads without re-scanning from
> offset 0. The firing condition is measurable, not editorial: when the
> server's read loop shows the head being re-scanned per read and that
> re-scan appears in a `make census` or a benchmark as a cost, the format
> value must answer a third outcome — `Partial(resume_at)` — beside a
> match and a refusal.
>
> Until it fires, the stateless shape is correct and is what the fast
> parsers do: picohttpparser re-parses the whole head each call and
> guards it with `is_complete` scanning only the new bytes
> (`2026_09_06_HTTP_FRAMING_LAWS.md` §2.1), and `frame.av` already takes
> a `scanned` argument for exactly that. A resumable matcher that nothing
> has measured a need for is machinery built ahead of a decision, and
> CLAUDE.md records what that does to the decision.

---

## 8. (h) The diagnostics

Codes claimed from the first free typing slot at `9fe5597`, where F2057
is the highest in use. **F2058–F2062 are claimed by announcement**: the
HTTP lead confirms F2057 is the highest on `main` and lane C has
reserved nothing past it. Re-checked against `main` immediately before
S2 commits; if the build refuses a collision, the codes move and nothing
else does.

| code | kind | message | help |
|---|---|---|---|
| F2058 | `type.format` | ``a format pattern reads text, found `int` `` | "a format matches a `string` or a `Bytes`" |
| F2059 | `type.format_capture` | ``a capture named `id` twice — one name, one span`` | "rename one, or write `{_}` for a span you do not need" |
| F2060 | `type.format_parse` | ```{n: Port}` parses through `Port`, which does not read text`` | "`int` reads text today; a type joins by registering a capture row" |
| F2061 | `type.format_shape` | "two captures with nothing between them cannot be split" | "put a literal between them — a scan needs something to stop at" |
| F2062 | `type.format_brace` | ``a `{` opens a capture — this one does not close`` | "write `{{` for a literal brace" |

Every one is a **named voice** (I28) in `features/formats/`'s voices
section, its whole body the one `spoken`/`emit`, and every one gets a
golden rendering test. F2062 also covers a bare `}` and an empty capture
name, each with its own wording inside the one voice's family — a law
states the rule, and the rule here is that braces in a format mean
captures.

The span for a fault inside a literal points at the **literal**, and the
message names the offending text and its character index within the
format. Pointing at the exact byte would need the token's escape map,
which the lexer does not hand out; claiming a precision the span does not
have would be worse than naming the index.

---

## 9. The slices, and what each has to prove

Each slice: `make idioms`, `make vocab`, `make externs` green; the
red-team run to the letter with survivors as
`formats_adversarial_test.av`; the review round to the letter;
`make gate` green once at the end; a Conventional Commits message; then a
report with the branch, sha, what landed, what was refused in the
compiler's words, and every probe with the base that answered it.

**S2 — patterns over `string`.** `features/formats/` (mod, builders,
check, lower, tests), the `Pat.Format` node, the seam per §3.3, the
`CaptureRow` registry with `int` in it. Tests are `then` cases carrying
claim + program, host-independent. `corpus/formats.av` + `.expected`
proving eval == native. Goldens for all five refusals. The first accepted
test is the request line. The scan law's edge (§1.3) is a named test.

**S3 — patterns over `Bytes`.** Captures bind `Bytes` slices; the same
scan, the Bytes rows directly, no copy. The performance measurement of §5
lands here, against `frame.av`.

**S4 — `grammar` declarations that parse.** The declaration, the record
type, `parse`. Opens with the namespace probe of §6.4.

**S5 — `print` and the round-trip law.** LANDED. `print` answers
`string?` and refuses off-domain; the domain is §6.3's CORRECTED
condition, asked in octets so the check and the scan read the same
bytes. The law is a corpus program on both engines, not a proof in
prose.

---

## 10. The rulings, and what each one changed

This section was "what I could not decide". Every item is now decided,
and three of the five decisions changed the design rather than ratifying
it — which is the point of asking.

1. **The pattern seam: ROUTE A.** Ruled by the HTTP lead, agreed by lane
   C, who write the seam, the enums movement and the `Pat.Format`
   variant themselves. *What changed:* the argument. Lane C replaced the
   ladder-count case with **ownership** (§3.3), which admits no "two
   copies may wait" reply. And the seam's home is
   `features/dispatch.av` beside its two twins, not
   `language/program.av`. Both corrections are in §3.3.
2. **`avra_str_index_of_from`:** asked of lane A with this lane's
   wanting site. S2 ships the one-copy fallback and swaps when the row
   lands. *Unchanged.*
3. **F2058–F2062:** free and unreserved; claimed by announcement,
   re-checked before S2 commits. *Unchanged.*
4. **The meaning change:** ruled right — a pattern that compiles and can
   never match is a silent trap, zero sites in the tree, and `{{`/`}}`
   keeps literal braces spellable. *Added obligation:* the blast-radius
   measurement goes into the ROADMAP entry when S2 lands, not just here.
5. **The `int` capture: A SHARED ROW, not an inline digit loop.** *What
   changed, and this paper was wrong:* it argued for inlining because
   that needs no runtime dependency and does the oracle's exact
   arithmetic. But `frame.av`'s `decimal`, this capture and a user's
   `"42"` conversion are three copies of one law, and the third copy
   names the concept. The interim is the inline arithmetic; the design
   is one row (§1.5, §4).

Two further facts arrived with the rulings and are folded in: a `Bytes`
row that answers a managed value carries `owns_result: true` and an
`extern fn` that is not a row **leaks what it mints** (§4), and the
oracle's distance from picohttpparser is the HTTP lead's to close, not
this lane's — this lane's obligation stays "within noise of `frame.av`
as it stands the day it is measured", which is why the harness is built
to be rerun against a faster oracle (§5).

---

## 11. What is already built, and what it proved

None of this depends on the ruling — it is the same code under every
route — so it was written and run rather than promised. It lives in
scratch until §10.1 is answered and the feature has a home.

**Built and running at `9fe5597`:** the format parser (text to
`pieces` + `captures`, the `{{`/`}}` unescape, the five faults), the
reference matcher (the scan law, in Avra), the round-trip domain check,
and `print`. Roughly 120 lines. Two things came out of running it that
reading it would not have given:

1. **The scan law was wrong in its first draft** (§0). The reference
   matcher failed the flagship pattern on its own example, because an
   empty last piece is found immediately at the cursor. Anchoring the
   last piece at the end fixed it and *removed* a case rather than
   adding one.
2. **The last capture needs no domain condition** (§6.3), which was not
   visible before the suffix anchor existed, and which makes `print`
   admit strictly more values than the first draft would have.

**Verified outputs**, reference matcher and `print`, at `9fe5597`:

| case | result |
|---|---|
| `"{m} {p} HTTP/{maj}.{min}"` over `GET /x HTTP/1.1` | `<GET,/x,1,1>` |
| the same, over `GET /x HTTP/1` | no match |
| `"{a}.{b}"` over `w.x.y` — the interior rule | `<w,x.y>`, never `<w.x,y>` |
| `"{a}.txt"` over `x.txt.txt` — the suffix anchor | `<x.txt>` |
| `"{a}"` over `""` and over `zz` | `<>` and `<zz>` — an empty capture is allowed |
| `"{a} {b}"` over `" x"` | `<,x>` |
| `"a{{b}}c"` over `a{b}c` | matches — the unescape |
| `"abc"` over `abd` | no match |
| print then parse of the flagship | `ok GET /x HTTP/1.1` |
| print of `{a}!` with `x!` giving `x!!`, then parse | `ok` — the last capture is unconstrained |
| print of `{a}!` with `x!y` giving `x!y!`, then parse | `ok` |
| print of `{a}.{b}` with `w.x` in the interior capture | `REFUSED` — the domain check |
| print of `{a}.{b}` with `w` and `x.y` | `ok w.x.y` |
| print then parse of `a{{{x}}}c` with `v` | `ok a{v}c` |
| parser faults: `{a}{b}`, `{a} {a}`, `a{b`, `a}b`, `{}`, `{a b}` | adjacent, repeated, unclosed@1, stray@1, malformed@0, malformed@0 |

**Red-teamed at `9fe5597`, before it lands.** 53 attack programs over
four of the eight classes — the four the pure code has a surface for:
degenerate format shapes (11), malformed surface position by position
(19), degenerate subjects (16), and the round trip (7). Results:

- **One wrong answer, found and fixed.** `matched` scanned a format that
  carries a fault and produced a match: `"{a}{b}"` against `"zz"`
  answered `<,zz>` for a format the adjacency law refuses. A faulted
  format now matches nothing and prints nothing.
- **One near-miss, same root, and it is the half worth keeping.**
  `print` already refused the faulted format — but by accident, because
  an empty interior piece makes the "does this capture contain the next
  piece" test true for every value. Right answer, wrong reason: a suite
  written that morning would have gone green and shipped the guard
  broken. It is recorded as a near-miss rather than counted as a pass.
- **The two engines agree** on all 57 lines of output, `./avra run`
  against `./avra build`'s binary.
- **Ownership is clean:** `AVRA_RC_GUARD=1` reports nothing, and
  `AVRA_MEM_STATS=1` reports 0 MB live in every category at exit.

Classes 2, 4, 5 (wrong types in every slot, crossing every other
feature, names against names) have no surface until the feature exists;
they run in S2 against the real thing.

**A CLAIM I MADE ABOUT FINGERPRINTS WAS WRONG, and lane A corrected
it.** Surveying the tree's duplicate `fp` tags, I reported that the
repeats were benign because they split between "genuinely separate
spaces" — the AST's and the query memo's. They do not split. `arm_fps`
folds pattern and expression fingerprints into ONE list, a statement
folds its expression's, and `restamp` wraps a statement's, so
`Pat.Rest` and `Expr.Receiver` were the same number and therefore the
same identity, always. The repeats I called benign were live.
The deeper correction is lane A's and it outranks tag choice entirely:
`fp` is LINEAR, so a tag is an additive offset and a payload is a flat
list — two spliced sequences share a boundary that can MOVE. The
defence is ARITY, not numbering. My grammar mark now folds each hole to
one value under its own tag so no boundary between holes can shift, and
`fp` itself folds the payload's length. The lesson for this paper: I
reached a structural conclusion from a `sort | uniq -c` and did not
check what the code does with the numbers, which is the same shape of
error as the round-trip proof two sections above.

**S5 LANDED, AND IT FALSIFIED §6.3's PROOF.** Writing `print` meant
implementing the domain condition, and implementing it meant asking
what the scan actually stops at rather than what a reader would call
natural. The first draft — "the capture does not contain the next
piece" — admits `{a}--{b}` with `a = "x-"`, which prints `x---b` and
parses back as `x` and `-b`. Verified at this base, both engines:
`[x][-b]`. §6.3 now carries the counterexample and the exact condition
(`(c + p).index_of(p) == |c|`), and `print` implements THAT.

`print` asks it in OCTETS, because that is the currency the scan uses:
a check built from `contains` or a C-string `index_of` would inspect
different bytes than the guard it protects, which is the law this tree
already learned the hard way. Verified outputs at this base:

| case | result |
|---|---|
| the flagship record printed | `GET /x HTTP/1.1` |
| print then parse, every field recovered | `ok` |
| all-empty values | `ok` — the literals alone |
| a space inside the PATH, whose delimiter is `" HTTP/"` | `ok` |
| a space inside the METHOD, whose delimiter IS a space | `refused` |
| the LAST hole holding its own delimiter | `ok` — the suffix anchor fixes its end |
| `{a}--{b}` with `a = "x-"` — the overlap | `refused` |
| the same one character shorter | `x--b` |

**Also built:** the benchmark harness of §5 against `frame.av` alone.
Its numbers and the noise band are in §5; the point of running it now is
that a baseline measured after the change is a number nobody can check.

**Two subset facts re-confirmed at `9fe5597`** while writing the above,
both already in CLAUDE.md and both hit on the first draft: `it` binds to
the **nearest** call, so `xs.find(names.index_of(names[it]) < it)` is
F2033 and wants the lambda written out; and an empty list does not adopt
a nullable aggregate want, so `return if c { [] } else { null }` under
`List<string>?` is F2025, and the empty must be bound at its own type
first.

---

## 13. S6 — the framer, and why it keeps its hand scans

The arc was built for `@std.http`'s framer, so the last question is
whether the framer should adopt it. **Measured, the answer is no**, and
the measurement is not the one that decides it.

**WHAT EACH ACCEPTS**, nine request lines drawn from the framing laws,
the framer against `grammar RequestLine = "{method} {path} HTTP/{major}.{minor}"`:

| line | verdict |
|---|---|
| `GET /x HTTP/1.1` | both take |
| `GET / HTTP/1.1` | both take |
| `GET  /x HTTP/1.1` (two spaces) | **pattern takes, framer refuses** |
| `GET /x HTTP/1.1extra` | **pattern takes, framer refuses** |
| `GET /x HTTP/11.1` | **pattern takes, framer refuses** |
| `GET /x HTTP/a.1` | **pattern takes, framer refuses** |
| ` GET /x HTTP/1.1` (leading space) | **pattern takes, framer refuses** |
| `GE<TAB>T /x HTTP/1.1` | **pattern takes, framer refuses** |
| `GET /x HTTP/1.1 ` (trailing space) | **pattern takes, framer refuses** |

Seven of nine. Every one is a law RFC 9112 gives a smuggling-shaped
reason for: §3 warns in the same paragraph that whitespace-delimited
parsing enables request smuggling, §2.3 fixes the version at one digit
each side, and the method is a `token` — an HTAB inside it is not a
method with a tab, it is two tokens a lenient parser might disagree
about.

**AND THE SPEED, which does not rescue it:** 146 ns for the pattern
against 1201 ns for a whole head. Not comparable — one line against a
head with a field — and it does not matter. **A faster scan that
accepts a smuggled request is not a win at any speed.**

**THE REASON, stated as a law rather than a result.** A FORMAT PATTERN
IS A SPLITTER; THE FRAMER'S SCAN IS A SPLITTER AND A VALIDATOR. Every
line of an HTTP head carries a byte-class law — the method is a
`token`, the target excludes CTL and SP, the field name is a `token`
that must touch its colon, the field value is `field-vchar` — and a
format's holes say only "up to the next literal". The header line is
worse than the request line in both directions at once: `OWS` is
`*( SP / HTAB )`, so a pattern with `": "` REFUSES the valid
`Host:example.com` while ACCEPTING the invalid `Host : example.com`
that §5.1 says a server MUST reject.

Applying the classes after the split costs strictly more than the hand
scan, which does both in one pass — so there is no fast path here
either.

**WHERE THE PATTERNS DO WIN** is where the typed-routes paper already
put them: the ROUTE, not the frame. A route's target has been framed
already, its shape is fixed, and its captures are values a handler
wants rather than spans a parser walks. That paper wrote "HTTP framing
stays byte-oriented … Converting the entire received buffer to UTF-8
and trimming lines loses the distinction between protocol syntax and
content" before any of this existed; this section is that sentence with
a number and an attack table behind it.

`tools/bench/frame_patterns` is the harness, kept so the claim can be
re-run rather than believed.

---

## 12. The asks still open, with their wanting sites

1. **`avra_str_index_of_from(s, needle, from)`** — lane A. `string`'s
   `index_of` takes no offset while `Bytes`'s does, so every
   left-to-right scan over text in this language is quadratic or
   copying. WANTING SITE: the string-subject format scan (§4). Not
   blocking; S2 ships the one-copy fallback.
2. **A decimal-parsing row** — the SQLITE campaign's, because decimal is
   CORE by that campaign's scope decision. NOT lane A's: an earlier
   draft of this paper said it was, and a dependency filed against the
   wrong owner is one nobody is carrying. WANTING SITES: `frame.av`'s
   `decimal`, this feature's `int` capture, and a user's `"42"`
   conversion (§1.5). Not blocking, and not scheduled: `{n: int}`
   refuses today and the handler converts, with the typing a later
   slice against a live consumer.
3. **`named_ref(name) -> TypeRef` exported from core** — whoever writes
   the `Pat.Format` variant, so its builder is not the sixth
   hand-spelling of a seven-field record whose own doc warns against
   exactly that (§3.3). Small, and it wants doing *before* the variant,
   not after.
4. **A capture-type registry row** (`CaptureRow`) — this lane, in S2,
   with `int` as its only row. The second row is what proves the seam,
   and it is not in this arc (§1.5).
5. **A per-pattern slot on the lowering context** — DELIVERED by lane
   C as `LowerCx.bind_test(p, regs)` / `test_regs_of(p)`, keyed by the
   pattern so a nested one finds its own registers. The scan is emitted
   once. Original ask: `cx.pinned_at(p, regs)` / `cx.pinned_of(p)`: the registers a
   pattern's test produced, for its binds to read. WANTING SITE:
   formats' `pat_accepts`/`pat_binds` pair, which would otherwise run
   the scan twice per arm (§4.1). General, not format-shaped — a list
   pattern needs the same thing.
6. **A `Bytes` constant in the IR**, so a scan's literals are converted
   once rather than per attempt. WANTING SITE: `literal()` in
   `features/formats/lower.av`. FIRING CONDITION, now measured rather
   than guessed: the 24% gap between the compiled octet scan and a
   hand-written one is four literal conversions at about four
   nanoseconds each (§5). Growing the IR is a vocabulary event with the
   eight-consumer protocol, so this is not a formats-lane change.

---

## Confidence ledger

Every row ran at base `9fe5597` in `../avra-lane-strings`, 2026-09-07,
with the compiler bootstrapped from that tree.

| claim | how verified |
|---|---|
| the flagship format arm checks clean and runs as a literal today | `./avra check` exit 0; `./avra run` prints `literal` |
| `{b}` in a string literal is plain text | `./avra run`: `a {b} c` |
| `\{` is not an escape | `./avra run`: `a \{b\} c` |
| `{{` is two characters today | `./avra run`: `a {{b}} c` |
| `grammar` is already a keyword | `let grammar = 1` → F3002, "`grammar` is a keyword" |
| `format` is not a keyword | `let format = 1` → exit 0 |
| `grammar Name = "…"` is free | F0100, "expected BREAK while parsing `stmt`", at the name |
| a trait method returning `Self?` does not resolve | F2032, "`Port.from_text` does not wear `FromText.from_text`'s signature" |
| there are no static methods on a type name | `Port.parse("80")` → F2003, "`Port` is a record, not an enum" |
| named call arguments do not parse | `f(a: 1, b: 2)` → F0100, "expected `)` to close the arguments" |
| `string.index_of` takes no offset | `"abcabc".index_of("b", 2)` → F2000, "`index_of` takes 1 arguments, found 2" |
| `Bytes.index_of` does | `"abcabc".bytes().index_of("b".bytes(), 2)` → `4` |
| a string pattern against a `Bytes` subject refuses | F2038, "a `string` never matches `Bytes`" |
| a string pattern against an `int` subject refuses | F2038, "a `string` never matches `int`" |
| `"${x}"` in pattern position does not parse | F0100, "expected `}` to close the `match`" |
| the nullable-record match is the natural desugaring | `match f() { r? -> …, null -> … }` over a `Fields?` runs, printing `GET /x 1.1` |
| a `once fn` cannot answer a one-scalar-field record | F2055, "`once fn r` answers `R`, which the runtime cannot keep" |
| a two-field record is fine | exit 0 |
| 37 arm-head string patterns tree-wide, 0 with a brace | `grep -rnE '^\s*"[^"]*"( or "[^"]*")* ->' --include='*.av' packages/ corpus/` and its brace-bearing variant |
| `Pat` has 11 exhaustive matches + 1 catch-all projection | `grep -rn '\.Wild' --include='*.av'`: 3 in `core/nodes.av`, 4 in `enums/check.av`, 4 in `enums/lower.av`, plus `hole_binds` |
| no feature imports another feature | `use features.<name>.` over `features/`: only self-imports (`enums`×2, `bytes`×1) |
| F2057 is the highest typing code in use | `grep -rhoE '"F[0-9]{4}"' --include='*.av'`, sorted |
| the builder channel carries the builder's own words | `grammar/executor.av:359-375`, `Cause.Builder`, fatal |
| the format parser, the reference matcher, `print` and the domain check all work | 14 parser cases and 14 scan/round-trip cases run in both engines; §11's table is their output |
| the scan law's first draft failed the flagship | the reference matcher returned an empty last capture; corrected in §0 |
| `frame.av` frames a minimal head in ≈810–970 ns, a full one in ≈3.2–3.5 µs | a package, 200,000 runs, three runs under `sh tools/watch.sh 4000` (§5) |
| hoisting the `Limits` record out of the loop changes nothing measurable | 971 ns before, 813–972 ns after |
| the red team found one wrong answer and one near-miss | `matched` scanned a faulted format; `print` refused one only by accident (§11) |
| both engines agree across the attack set | `./avra run` and `./avra build`'s binary, 57 identical output lines |
| the attack program leaks nothing | `AVRA_RC_GUARD=1` silent; `AVRA_MEM_STATS=1` reports 0 MB live in every category |
| one name can be a type and a value at once | `type Line` plus `let Line = Line { … }` runs, answering `GET` |
| a generic impl's answer can follow its type argument | `Fmt<T>` with `fn parse(…) -> T?` answers `Line?` under `Fmt<Line>` |
| a generic struct literal cannot pin its arguments | `Fmt<Line> { pieces: [] }` is F0100, "expected BREAK while parsing `stmt`" |
| the semantics twins live in `features/dispatch.av` | `semantics_of` at :54, `stmt_semantics_of` at :79 — not `language/program.av` |
| `TypeRef` is a plain record a builder can construct | `core/nodes.av:332`, seven fields, no arena |
| the `TypeRef`-for-a-name shape is hand-spelled five times | `decls.av:786` (private), `builder.av:154` (exported as `void_ref`), `nodes_test.av:8` plus four literals |
