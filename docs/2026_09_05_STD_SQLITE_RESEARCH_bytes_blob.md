# `bytes` — Avra's blob, designed

The BLOB is one of SQLite's five storage classes and Avra has no type
that can hold one honestly. This is the design for the type that can:
what it IS, what it COSTS, what it can DO, and the order it lands in.

A CORE EVENT, in the doctrine's exact sense — "The protocol grows with
value categories — a core event — never per feature" (CLAUDE.md, the
value-protocol rule). It is the first new value category since `Str`.

THE ANSWER IN ONE PARAGRAPH. `bytes` is a distinct built-in type whose
box IS a string box — the same sixteen-byte header, the same allocator,
the same size classes, the same refcount — wearing a different kind tag
and reached only through length-driven operators. The type system keeps
the two apart; the runtime keeps one allocation path. No IR variant is
added: every operation rides `CallRt`, the escape hatch that exists so
the instruction set stays closed (`core/ir.av:61-64`). The prerequisite
is smaller than the type: `string`'s own operators must stop lying about
NUL, which is a bug in `string` whether or not `bytes` ever lands.

---

## 0. THE SITUATION, CORRECTED

The campaign brief's premise holds, with one correction and one
sharpening.

**HOLDS.** A `string` is already a headered byte box that can carry any
byte including NUL. `.length` is a header load (`avra_str_len`,
`runtime/avra_runtime.c:1189-1191` over `str_len` `:272-275`);
`substring` `:1136-1142`, `char_code` `:1177-1187`, `trim` `:1197-1205`,
`concat` `:1253-1259`, `ends_with` `:1152-1157` and `join` `:997-1015`
are all length-driven and byte-exact.

**LOSSY, as the brief says.** `==` (`avra_streq` `:475-478`, `strcmp`),
`contains` (`:1144-1146`, `strstr`), `index_of` (`:1159-1162`,
`strstr`), `replace` (`:1207-1230`, `strlen`+`strstr`), `split`
(`:1232-1251`, `strlen`+`strstr`).

**CORRECTION — `starts_with` IS ALSO LOSSY, and the brief lists it as
safe.** `avra_str_starts_with` (`:1148-1150`) is
`strncmp(s, prefix, str_len(prefix)) == 0`. The length comes from the
header, but `strncmp` itself stops comparing at a NUL: C17 §7.24.4.4
specifies that characters following a null character are not compared.
So `"\0A".starts_with("\0B")` answers TRUE. `ends_with` is correct
because it uses `memcmp`; `starts_with` must too. **HIGH** — read in the
source, and the standard's wording is explicit.

**SHARPENING — the `len == 0` fallback is vestigial, not load-bearing.**
`str_len` is `return (h && h->len) ? h->len : strlen(s);`
(`runtime/avra_runtime.c:272-275`). Two fall-throughs: `h == NULL` (not
our box) and `h->len == 0`. The second exists for one historical reason,
recorded at `ROADMAP.md:465-467`: "a zero measures — which is what
carried the transition build, whose own constants had no length." That
transition is over. The seed's own constants carry lengths —
`bootstrap/seed.ll:6` is
`{ i32 1096176193, i32 -1, i32 0, i32 6, [7 x i8] c"--help\00" }`
(tag `0x41565241` = "AVRA", kind `-1` STATIC, rc `0`, **len 6**) — and
the backend writes the length into every constant it emits
(`backend/llvm_wrapper.c:466-472`). Every runtime producer sets it:
`str_box` `:264-268`, `read_whole` `:1357-1366`, `avra_int_text`
`:495-499`, `str_owned` `:1122-1127`.

So the empty-blob hazard is closed by DELETING a clause, not by adding a
sentinel. §2.3 states the one-line fix.

---

## 1. THE CENTRAL DESIGN QUESTION

Three candidates:

- **(a)** a distinct core value category with its own type
- **(b)** fix `string`'s NUL-lossy operators, so `string` IS the byte type
- **(c)** `List<u8>` with a `u8` scalar

### 1.1 (c) is refused first, because the tree already measured it

There is no `u8` at app level and the spec says there will not be:
sub-decision 31.1 gives app level `int` and `uint` and nothing else,
with `i8`/`u8`/`u16`… reserved for `systems { }` blocks
(spec:6236-6252). So (c) is really `List<int>`, and an Avra list is
`{ cap, len, int64_t* data, uint8_t* owned, void* site }`
(`runtime/avra_runtime.c:511-524`) over ONE buffer holding both the
cells and the owned marks. That is **nine bytes of storage per byte of
blob**, plus a box and a heap buffer — a 1 MB blob becomes 9 MB. P4
alone ends the argument.

It fails a second time, at the boundary that matters. `sqlite3_bind_blob`
wants a pointer to the bytes. A `List<int>`'s pointer is the `AvraArray`
struct, whose FIRST FIELD IS THE CAPACITY — so what C reads is not what
Avra wrote. The tree already recorded exactly this reasoning against the
one-element-list out-param workaround (`ROADMAP.md:1594-1599`): "a
one-element `List<int>` as the out-param seat hands C the `AvraArray`
pointer whose FIRST FIELD IS THE CAPACITY, so what C writes is not what
Avra reads." Rust's `Vec<u8>` works precisely because a Vec's data
pointer IS the bytes; Avra's list is not that shape.

Refused. **HIGH.**

### 1.2 The survey — who chose what, and what it cost them

**Rust — two types, one representation, and then a THIRD.** `String` is
a `Vec<u8>` carrying a UTF-8 invariant; `&str` is a view with the same
invariant. `Vec<u8>`/`&[u8]` are arbitrary bytes. `as_bytes()` is free —
no copy, no check, because the invariant only ever narrows. The decode
is where the design pays off: `String::from_utf8(v)` answers
`Result<String, FromUtf8Error>` and the error hands the bytes back;
`String::from_utf8_lossy` is total and substitutes U+FFFD. Rust then
needed a THIRD type — `OsString`/`OsStr` — because a Windows path is
neither valid UTF-8 nor merely bytes. **Lesson:** the fallible decode
belongs in the type system, and a third type appears at exactly the
boundary where an invariant cannot be maintained. Avra's third thing is
`ptr` plus a copy verb, already named by this campaign's prior-art
research (`docs/2026_09_05_STD_SQLITE_RESEARCH_prior_art.md`, B2).

**Go — one type for both, and the distinction comes back as
convention.** A Go `string` is an immutable sequence of arbitrary bytes;
it is NOT guaranteed UTF-8. `[]byte` is the mutable twin, and
`[]byte(s)` / `string(b)` COPY. Go's compiler carries narrow peepholes
to avoid the copy — `m[string(b)]` in a map lookup is recognized and
uses `b`'s data directly (golang/go#3512), and defeating the peephole by
binding the conversion to a variable first reintroduces the allocation
(golang/go#71132 is a live issue about widening it). Because the type
carries no encoding claim, every library that cares re-imports the
question: `utf8.ValidString`, `for range` decoding to runes with U+FFFD
for invalid input, `unicode/utf8` scattered through the standard
library. **Lesson:** merging the types removes the encoding question
from the type system and puts it in every caller.

**Python 2 → 3 — the split, done as a migration, and the field's most
expensive lesson.** Python 2's `str` was bytes with an implicit
coercion to `unicode`; Python 3 made `str` text and `bytes` disjoint,
with no implicit coercion in either direction. THE COST: Python 3.0
shipped December 2008 and Python 2 reached end of life on 1 January
2020 — eleven years — and the bytes/str split was repeatedly named the
single largest source of porting work. The strictness had to be walked
back twice: PEP 461 restored `%`-formatting for `bytes` in Python 3.5
after binary-protocol code proved unwritable without it, and PEP 383's
`surrogateescape` handler (Python 3.1) exists so an undecodable filename
can be represented as `str` and round-tripped back to the same bytes.
THE PURCHASE: `UnicodeDecodeError` moved from "anywhere, at random" to
the I/O boundary, which is the one place the encoding is actually known.
**THE LESSON FOR AVRA, and it is double-edged:** take the split, and
take it NOW — Avra has no installed base, so Python's entire cost was
legacy code and Avra pays none of it. And take PEP 461's lesson
pre-emptively: ship `bytes` with real ergonomics on day one (slice,
concat, compare, hex, base64) so nobody reaches back for `string`.

**Zig — `[]const u8` for both.** A Zig string literal is
`*const [N:0]u8`; equality is `std.mem.eql(u8, a, b)`; UTF-8 is a
convention validated only where `std.unicode` is called. This works
because Zig has slices as a language primitive and no managed strings at
all — there is nothing for a type to protect. Avra has managed,
reference-counted text and no slice primitive. **The model does not
transfer**; citing it as prior art would be a category error.

**Swift — `String` vs `Data`.** `String` is Unicode-correct with UTF-8
backing (Swift 5); `Data` (and `[UInt8]`) are the byte types.
`String(data:encoding:)` is failable and answers `String?`; `s.utf8` is
a free view; `Data(s.utf8)` copies. Rust's answer with a heavier bytes
type. **Lesson: the same two-type conclusion, reached independently.**

**Erlang — binaries, and the closest thing in the field to Avra's
headered box.** The BEAM keeps *heap binaries* (up to 64 bytes, copied
into the process heap) and *refc binaries* (over 64 bytes, allocated in
a shared binary heap, reference-counted, reached through a per-process
`ProcBin`), plus *sub-binaries*: an offset+length VIEW into another
binary, created in O(1) by binary matching with no copy. Length is O(1)
(`byte_size/1`); search and slice are length-driven (`binary:match/3`,
`binary:part/3`). **Lesson one:** a length-carrying, reference-counted
byte box with O(1) size is a proven design at scale — which is what Avra
already has, one type short. **Lesson two, the warning, and the most
useful thing in this survey:** a small sub-binary keeps the entire refc
binary alive — the classic Erlang "binary leak", whose remedy is an
explicit `binary:copy/1`. The efficiency guide also documents that the
append optimization requires a *single* ProcBin reference, because the
binary object can be reallocated and only one pointer can be fixed up.
**So: Avra's slice COPIES, and a `BytesView` over another box is refused
until there is a measured reason** — and the header has nowhere to put
an offset anyway (§2.2).

**The tally.** Two types: Rust, Python 3, Swift, C# (`byte[]` vs
`string`), Java. One type: Go, Zig, Erlang, Python 2. Every one-type
language re-imports the distinction as a library convention, and the one
that migrated across the line spent eleven years doing it.

### 1.3 (b) is refused — but half of it must land anyway

Making `string` the byte type is the Go answer. It fails here for four
reasons, in order of force.

**The spec already decided, and the spec is LAW where anything
disagrees (CLAUDE.md).** Sub-decision 9.15 is explicit: "**Encoding:**
UTF-8 internally, always" (spec:1477), and 15.6 restates it as an
invariant the FFI relies on: "`string` is always valid UTF-8 (invariant
from 9.15). `CString.from` fails only if the string contains embedded
null bytes" (spec:3054). (b) is not a design choice available to this
lane; it is a spec amendment.

**The driver could not choose its bind verb.** SQLite's storage classes
are NULL, INTEGER, REAL, TEXT, BLOB, and a driver that round-trips must
call `sqlite3_bind_text` for one and `sqlite3_bind_blob` for the other.
If one Avra type carried both, the choice would need a runtime
discriminator riding on the value — which is exactly "the parallel Value
enum the doctrine refuses" (CLAUDE.md, the value-protocol rule). The
TYPE is the discriminator, computed at compile time, costing nothing.
That is P10: the compiler holds semantic knowledge no other tool has.

**P1, LLM-first.** A model asked for `hash(password)` in a language
where `string` is bytes will write a program that interpolates a hash
into a log line, and get mojibake or a truncated line, silently. Two
types make that a compile error at the one place a decision is owed.

**The Go outcome, re-created by hand.** If `string` held arbitrary
bytes, every `@std/text` verb would need a validity check or a
documented "undefined for non-UTF-8".

**BUT — the operators must be fixed regardless, and FIRST.** The
NUL-lossiness of `==`, `contains`, `index_of`, `replace`, `split` and
`starts_with` is a BUG IN `string`, independent of `bytes`:

- `@std/io`'s `write_text` already writes the HEADER's length, "never
  strlen: a text may hold NUL bytes, and a write that stopped at the
  first one would truncate in silence" (`runtime/avra_runtime.c:1388`,
  commit `3c622be`).
- `read_text` already reads it back full-length (`read_whole`
  `:1357-1366` sets the header from `fread`'s count).
- And `==` says those two texts are equal to their own truncations.

`write_text` and `==` disagree about what a text IS. Fixing the
operators makes them agree. It is a small, self-contained slice with its
own value, and it must land first because **`bytes`' operators are the
same C** — writing them twice would be the third copy the doctrine
names ("The third copy of a shape names the concept").

### 1.4 RECOMMENDATION — (a), collapsed

**A distinct type `bytes`, sharing `string`'s box exactly.**

This is P6, and the paradox is real: (a) buys type safety and appears to
cost a second representation, a second allocator and a conversion; (b)
buys one representation and costs the safety. The collapse is that the
representation and the type are independent axes. **Two types, one
layout, one allocator, one refcount, one free list.** (a)'s safety at
(b)'s cost.

The spelling is **`bytes`**, lowercase — the tree's built-in type names
are lowercase (`language/typing.av:317-322`: `"int"`, `"string"`,
`"bool"`, `"void"`, `"ptr"`), it is the name Python uses so P1's model
reaches for it first, and it reads right beside `string`. The ROADMAP's
probe wrote `Bytes` and got F2001 "`Bytes` names no type"
(`ROADMAP.md:1558`); the landing gives F2001's help the spelling, so
that probe's exact wording becomes a signpost rather than a dead end.
(`remedy_for`, `features/facts.av:14-16`, is keyword-only — reached from
`resolve.av:302`'s `refuse_keyword` — so the remedy rides the type-name
diagnostic's help, not the remedies table.)

---

## 2. THE REPRESENTATION

### 2.1 A `bytes` box IS a string box

The header, verbatim (`runtime/avra_runtime.c:56-61`):

```c
typedef struct {
    uint32_t tag;    // 0x41565241 "AVRA" — this header is ours
    int32_t  kind;   // -2 DEAD, -1 STATIC, 0 PLAIN, 1 ARRAY, 2 MAP, 3 STR
    int32_t  rc;     // the reference count
    uint32_t len;    // a string's text length; a record's payload bytes
} Header;
```

Sixteen bytes, immediately before the payload, sixteen-aligned — `hdr`
refuses an unaligned or sub-image address before reading anything
(`:68-73`).

A `bytes` box is minted by the SAME verb strings use:

```c
char* buf = str_box(n, KIND_BYTES);   // box_alloc(n + 1, KIND_BYTES); h->len = n
```

`str_box` (`:264-268`) allocates `n + 1` payload bytes through
`box_alloc` (`:244-262`) and overwrites `h->len` with `n`. The extra
byte holds a NUL terminator. Identical layout, identical allocation
path, identical accounting hook, `rc = 1`.

### 2.2 What sharing buys, and what it costs

**BUYS.**

- **One allocator.** `box_alloc` `:244-262` with its size classes
  (`CLASS_BYTES 16`, `CLASS_MAX 256`, `LIST_LIMIT 16384`, `:83-88`) and
  its per-class free lists. No second allocator to get wrong, and a blob
  under 256 bytes recycles through the same list a small string does.
- **Zero change to refcounting.** `avra_rc_retain` `:383-390` and
  `avra_rc_release` `:415-434` read the header and dispatch on kind only
  for RECLAIM: `KIND_ARRAY` releases owned slots, `KIND_MAP` releases the
  map, everything else is `box_free`. A `bytes` box holds no slots, so
  it takes the `box_free` path with no new arm.
- **Zero change to the memory pass.** `bytes` rides a pointer, so
  `ptr_shape` (`core/types.av:118-124`) answers true, `rides_pointer`
  (`:248-259`) answers true, and every managed rule — retain at a call
  argument, release at scope exit, the cell protocol, the owned-slot
  marks — applies unchanged.
- **Zero-cost conversion, later.** `bytes_of(s)` and `text_of(b)` are
  length-driven copies today. Because the layouts are IDENTICAL, a
  future optimization can make the conversion a KIND FLIP on a
  uniquely-referenced box (`rc == 1`, which `avra_array_shared`
  `:816-818` already knows how to ask). Record it; do not build it —
  P4 is measured, never assumed.
- **One text projection.** `${b}` is refused (§3), so there is no second
  printing path to keep in sync.

**COSTS, both small and both nameable.**

- **Two types with one machine layout.** The TYPE SYSTEM keeps them
  apart and that is sufficient: `Type.Bytes` and `Type.Str` intern to
  distinct ids (`canon`, `core/types.av:130-152`, gives each its own
  key), `unify` never agrees them, and method rows are gated by their
  `takes` predicate (`on_str`, `features/str_lit/check.av:59-61`; a
  parallel `on_bytes`). No expression can read one as the other.
- **The RUNTIME does not need to tell them apart for correctness** — it
  never dispatches text-vs-bytes; the compiler picks the row. It needs
  the distinct kind for exactly two things:
  1. `box_bytes` (`:280-282`) is
     `h->kind == KIND_STR ? h->len + 1 : h->len` — the size a box
     occupies. A `bytes` box also allocates `len + 1`, so `KIND_BYTES`
     must join that arm or `box_free` computes the wrong size class and
     the box returns to the wrong free list. **One line.**
  2. `acc_kind_of` (`:234-236`) decides which accounting bucket a box
     charges. Without a `KIND_BYTES` arm, a driver reading 100 MB of
     blobs sees "strings" in `AVRA_MEM_STATS=1`. That is a blinded
     instrument in the one campaign whose memory question is blobs — P7
     says the magic stays visible. **One arm, plus `ACC_BYTES` in the
     enum at `:98` and its name at `:99`.**

So: **`KIND_BYTES = 4`** at `:48`, two one-line changes, and nothing
else in the runtime's memory machinery moves.

**The header has no room for an offset**, which is why a slice copies:
all sixteen bytes are spoken for, and widening the header would cost
every string and every record in the tree. That happens to agree with
the Erlang sub-binary lesson (§1.2), so the constraint and the design
want the same thing.

### 2.3 The empty-blob hazard, resolved concretely

`str_len` today (`runtime/avra_runtime.c:272-275`):

```c
static size_t str_len(const char* s) {
    Header* h = hdr((void*)s);
    return (h && h->len) ? h->len : strlen(s);
}
```

THE FIX — one clause deleted:

```c
static size_t str_len(const char* s) {
    Header* h = hdr((void*)s);
    return h ? (size_t)h->len : strlen(s);
}
```

**Why this is a no-op for strings.** The `h->len == 0` branch is
reachable only for a tagged box whose length was never recorded. No such
box exists: the backend's constants carry it (`llvm_wrapper.c:466-472`),
the seed's carry it (`bootstrap/seed.ll:6`, len 6 for `"--help"`), and
every runtime producer sets it (`str_box` `:264-268`, `read_whole`
`:1357-1366`, `avra_int_text` `:495-499`, `str_owned` `:1122-1127`,
`str_static` `:302-308`). For an empty string the fallback and the
header agree at 0 anyway, because `str_box` always allocates the
terminator. `ROADMAP.md:465-467` records the branch as transition
scaffolding.

**Why it matters for `bytes`.** An empty `bytes` box must answer 0 from
the HEADER, never by measuring a payload. With the clause gone that is
guaranteed by construction, and the "empty blob is indistinguishable
from no length recorded" hazard cannot be expressed.

**Belt.** Keep the terminator (`str_box`'s `n + 1`). It costs one byte
and buys two things: `str_len`'s foreign-pointer fallback can never read
past a `bytes` payload even if reached by defect, and a `bytes` value
whose content happens to be NUL-free text can be handed to a C API
expecting `const char*` with no copy.

**The residual, named.** `hdr` answering NULL for a FOREIGN pointer
keeps the `strlen` fallback alive, and that is the seam the campaign's
other research already condemns (`ROADMAP.md:1617-1640`): an `extern fn`
may never declare `string` or `bytes` as its answer. §4 states the law.

### 2.4 The length ceiling, ratified

`len` is `uint32_t` (`:60`), so a box caps at 4,294,967,295 bytes.
SQLite's own ceiling is lower: `SQLITE_MAX_LENGTH` defaults to
1,000,000,000 and the implementation supports at most 2^31−3 =
2,147,483,645 bytes for a string or BLOB (sqlite.org/limits.html). **No
SQLite blob can overflow the header.** A `bytes` box built from another
source can, so the minting verbs trap past `0xFFFFFFFF` rather than
truncating the length — worded like the index trap
(`avra_str_char_code` `:1177-1187`), because a silently wrong length is
the one failure this whole design exists to prevent.

---

## 3. THE OPERATIONS

Legend: **row** = a `rt_sigs()` registry row plus a C body plus an
interpreter host arm. **avra** = written in Avra, in `@std/text`.

| operation | spelling | where | complexity | note |
|---|---|---|---|---|
| length | `b.length` | row `avra_bytes_len` | O(1) | a header load; joins `length_word` (`features/values.av:428-437`) |
| emptiness | `b.is_empty()` | **free** | O(1) | `lower_is_empty` (`str_lit/lower.av:59-68`) already asks `length_word` |
| index | `b.at(i)` | row `avra_bytes_at` | O(1) | answers `int` 0..255; traps out of bounds, worded like `avra_str_char_code` |
| slice | `b.slice(lo, hi)` | row `avra_bytes_slice` | O(n) **copy** | clamped, ends exclusive, like `avra_str_substring` `:1136-1142` |
| concat | `a + b`, `a.concat(b)` | row `avra_bytes_concat` | O(n+m) | `str_len` on both sides, one `str_box` |
| equality | `a == b` | row `avra_bytes_eq` | O(n), early-out on length | lengths, then `memcmp`; wired at `same_value` (`features/values.av:55-64`) |
| ordering | `a.compare(b)` | row `avra_bytes_cmp` | O(n) | `memcmp` then shorter-is-less — exactly SQLite's BLOB collation |
| search | `b.index_of(n)`, `b.contains(n)` | row `avra_bytes_index_of` | O(n·m) | `contains` is `index_of >= 0`, lowered in Avra — no second row |
| prefix/suffix | `b.starts_with(p)`, `b.ends_with(p)` | rows | O(m) | `memcmp`, never `strncmp` (§0) |
| hex out | `to_hex(b) -> string` | **avra** | O(n) | a comprehension over a 16-character table |
| hex in | `from_hex(s) -> Result<bytes, TextError>` | **avra** | O(n) | fallible: an odd length or a non-hex digit |
| base64 out | `to_base64(b) -> string` | **avra** | O(n) | RFC 4648 standard alphabet, padded |
| base64 in | `from_base64(s) -> Result<bytes, TextError>` | **avra** | O(n) | fallible: alphabet, padding, length |
| decode | `text_of(b) -> Result<string, TextError>` | avra validator + row `avra_bytes_as_text` | O(n) | **fallible** — see below |
| decode, total | `text_lossy(b) -> string` | **avra** | O(n) | ill-formed sequences become U+FFFD |
| encode | `bytes_of(s) -> bytes` | row `avra_bytes_of_text` | O(n) | **total** — a `string` is already a byte box |
| iteration | `for x in b` | `elem_word` beside `length_word` | O(n) | last slice; see below |
| map key | — | **refused** | — | maps are string-keyed (`core/types.av:47-50`); `b.to_hex()` is the key |
| `${b}` | — | **refused** | — | F2007's arm; help names `to_hex()` |
| `join` over `List<bytes>` | — | **refused** | — | `join` reads text (CLAUDE.md, the subset); fold with `concat` |

### 3.1 The decisions inside that table

**The decode answers a `Result`, and the error names the offset.**
`text_of(b) -> Result<string, TextError>` where `TextError` carries the
byte offset and what was wrong — the shape `@std/json` already uses,
`Unexpected(at, found)` (`ROADMAP.md:1036`). The VALIDATOR is written in
Avra over `@std/text`'s existing lead-byte decoder (`codepoints`,
`codepoint_count`, `packages/std-text/src/text.av:88-97`) — one more
consumer of an algorithm the tree already has, not a new one. The row
`avra_bytes_as_text` mints a `KIND_STR` box from the payload and is
called ONLY after the validator has said yes, so the UTF-8 invariant on
`string` is never broken by construction.

**The encode is total** because a `string` is already a byte box. That
asymmetry — total one way, fallible the other — is Rust's `as_bytes` /
`from_utf8` exactly, and it is the shape that makes the invariant pay.

**Hex and base64 are Avra, not C.** Three reasons: they are not hot
enough to earn a row (a blob is read once and encoded once, and the
`memcpy`-shaped work is elsewhere); writing them in Avra dogfoods the
language and will surface real sugar wants; and P17 prefers composition
to a wider C surface. If a profile ever disagrees, each becomes one row.

**They live in `@std/text`, not a new `@std/bytes`.** Every one of them
is a text↔bytes PROJECTION, `@std/text` already owns the UTF-8 decoder
and `from_codepoint` (`text.av:103-106`), and hex and base64 are text
encodings of bytes. P17: composability over more packages.

**Iteration is the last slice and it is small.** The walk's `turn_elem`
(`features/emit.av:129-135`) hardcodes `avra_array_get`. Give it an
`elem_word(shape)` twin beside `length_word` — the same registry shape,
which I22 already blesses — and `for x in b`, `[f(x) for x in b]` and
`b.map(f)` all land through ONE stream, because the walk vocabulary is
already shared (I33). That is what makes `to_hex` a one-line
comprehension rather than a while loop, so it is worth landing even
though nothing in the driver strictly needs it.

**`b[i]` waits.** Index syntax on a non-`List` is refused today — F2000
"`[...]` indexes a `List`" (CLAUDE.md, the subset). `b.at(i)` is the v1
spelling and `b[i]` is a sugar-backlog item naming this site.

**`<` waits.** Avra has no ordering operator on non-scalars
(`features/expr_spine/check.av:124,165` governs comparability), so
ordering is the method `compare(b) -> int`. That is enough for a driver:
SQLite's own BLOB comparison is `memcmp` then length, which is exactly
what the method answers.

### 3.2 The row count, and why it is a REGISTRY

Twelve rows: `avra_bytes_len`, `_at`, `_slice`, `_concat`, `_eq`,
`_cmp`, `_index_of`, `_starts_with`, `_ends_with`, `_of_text`,
`_as_text`, `_from_host` (§4). Plus `avra_bytes_ptr` (§4) makes
thirteen.

THE VOCABULARY SEAM RULE decides the shape (CLAUDE.md): a runtime fn is
DATA — a name, parameter kinds, ownership — so it is a REGISTRY ROW.
`rt_sigs()` (`core/runtime_api.av:11-90`) is one table and five
consumers QUERY it; adding is one row plus one C body plus one host arm,
and nothing dispatches. **No instruction is added**, so the IR's eight
consumers are not paid at all — `CallRt` is documented as exactly this
escape hatch: "THE escape hatch that keeps this instruction set closed:
features lower value-producing runtime needs here, never as new
variants" (`core/ir.av:61-64`).

The one enum that DOES grow is `RtHost` (`core/ir.av:222-290`), and that
is the guarantee working: `rt_dispatch` (`language/interp.av:500-570`)
is exhaustive, so a row with a new host cannot ship without its
interpreter arm.

### 3.3 eval == native, by construction

The interpreter's string arms call the compiler's OWN Avra string
methods — `.Streq -> self.streq_val(vals)`,
`.StrContains -> verdict(self.text_val(vals[0]).contains(...))`
(`language/interp.av:509,533-541`) — which lower to the same runtime
rows the native program calls. So **the NUL-safety fix in §1.3 fixes
both engines at once**, and the bytes arms inherit the same property:
each is a thin call over a `Val.By(v: bytes)` whose methods are the rows
being hosted. The divergence registry has nothing to record.

The cost is a two-stage build (§6, S6): `Val` gaining a `By` variant
means the compiler's own source uses `bytes`, which the standing binary
must already understand.

---

## 4. THE SQLITE ANGLE

### 4.1 Reading a blob — the copy, specified exactly

The rules, from <https://www.sqlite.org/c3ref/column_blob.html>:

1. **Lifetime.** "The pointers returned are valid until a type
   conversion occurs as described above, or until sqlite3_step() or
   sqlite3_reset() or sqlite3_finalize() is called." → the driver MUST
   copy before the row is returned to Avra.
2. **The empty blob is a NULL pointer.** "The return value from
   sqlite3_column_blob() for a zero-length BLOB is a NULL pointer." →
   a NULL is not an error and not SQL NULL. Ask
   `sqlite3_column_type(stmt, i)` FIRST; only `SQLITE_NULL` means SQL
   NULL.
3. **Call order.** "you should call sqlite3_column_text(),
   sqlite3_column_blob(), or sqlite3_column_text16() first to force the
   result into the desired format, then invoke sqlite3_column_bytes()"
   → blob first, length second. Never the reverse.
4. **OOM.** "If an out-of-memory error occurs, then the return value
   from these routines is the same as if the column had contained an SQL
   NULL value… distinguished by invoking the sqlite3_errcode()
   immediately after the suspect return value is obtained and before any
   other SQLite interface is called on the same database connection."

THE EXTERN WALL. The externs answer `ptr` and `int`. Never `bytes`,
never `string`:

```avra
extern fn sqlite3_column_type(stmt: ptr, col: int) -> int
extern fn sqlite3_column_blob(stmt: ptr, col: int) -> ptr
extern fn sqlite3_column_bytes(stmt: ptr, col: int) -> int
```

THE COPY. One core row — language infrastructure, not a shim; the
general FFI answer for every C library, and the precedent is exact
(`avra_str_from_codepoint` is a row minted for `@std/text`,
`core/runtime_api.av:88`):

```c
// A FOREIGN region copied into a headered box. The caller owns the
// answer; an empty region is a valid empty box, never NULL.
const char* avra_bytes_from_host(const void* p, int64_t n) {
    if (n < 0) n = 0;
    if (n > 0xFFFFFFFFll) avra_trap("a byte region longer than a box can measure");
    char* buf = str_box((size_t)n, KIND_BYTES);
    if (n > 0 && p) memcpy(buf, p, (size_t)n);
    buf[n] = '\0';
    return buf;
}
```

- **WHICH ALLOCATOR.** `str_box` → `box_alloc` (`:244-262`): the size
  classes, the free lists, the accounting, the header. Never a bare
  `malloc` — CLAUDE.md: "A new C fn that answers TEXT to a program
  allocates it with `box_alloc`/`str_owned`… never a bare `malloc` or a
  C literal."
- **WHO OWNS IT.** The CALLER. The row is declared `owns_result: true`,
  so the memory pass gives the `CallRt` result an owner and the enclosing
  scope releases it (`managed_dst`, `language/memory.av:316-327`).
- **WHAT THE REFCOUNT STARTS AT.** `1` — `box_alloc` sets `h->rc = 1`
  (`:256`). That one reference belongs to the register the call defines.
  Pushing the value into a row list retains it to 2 at the pack; the
  scope's release takes it back to 1, now owned by the list. Answering
  it from a fn moves the reference under callee-cleans.
- **A NULL `p` WITH `n == 0` MINTS A VALID EMPTY BOX** — non-NULL,
  length 0. This is precisely why §2.3 must land first: the box's length
  has to be BELIEVED, not measured, or an empty blob reads whatever
  follows the payload.
- **A ROW BORROWS ITS ARGUMENTS.** `p` is a `ptr` and unmanaged, so no
  retain and no release — CLAUDE.md's "A RUNTIME ROW BORROWS ITS
  ARGUMENTS" is satisfied trivially here, and `owns_result: true` is the
  only ownership claim the row makes.

THE LAW THIS CARRIES, and it should be a named voice, not a convention:
**an `extern fn` may never declare `string` or `bytes` as its answer.**
Today a foreign `const char*` typed as `string` "works" by accident —
`hdr` refuses the untagged pointer so retain/release no-op, and
`str_len` falls back to `strlen` (`ROADMAP.md:1617-1640`) — and
`AVRA_RC_GUARD=1` is blind to it because an untagged pointer raises no
events. For a BLOB it is not even accidentally right: a blob's length is
not `strlen`. Refuse it in the compiler.

### 4.2 Writing a blob — STATIC vs TRANSIENT

The rules, from <https://www.sqlite.org/c3ref/bind_blob.html>:

- **SQLITE_STATIC** — "the application remains responsible for disposing
  of the object. In this case, the object and the provided pointer to it
  must remain valid until either the prepared statement is finalized or
  the same SQL parameter is bound to something else, whichever occurs
  sooner."
- **SQLITE_TRANSIENT** — "the object is to be copied prior to the return
  from sqlite3_bind_*(). The object and pointer to it must remain valid
  until then. SQLite will then manage the lifetime of its private copy."
- **NULL** — "If the third parameter… is a NULL pointer then the fourth
  parameter is ignored and the end result is the same as
  sqlite3_bind_null()."
- **Negative length** — for `sqlite3_bind_text`, "the length of the
  string is the number of bytes up to the first zero terminator."

**CAN AVRA SAFELY HAND SQLITE A POINTER INTO ITS OWN BOX? YES — under a
stated rule.** A `bytes` register IS a `char*` to the payload; the
header sits behind it, so the address handed over is the payload
address, valid and stable for as long as the box lives. One row exposes
it:

```
avra_bytes_ptr(b: bytes) -> ptr     // owns_result: false — it BORROWS
```

**THE RULE, stated once:**

> A pointer into an Avra box may cross to C for exactly as long as Avra
> can NAME a live reference to that box. Reference counting places the
> release at the end of the owning scope; a `bind` is not a retain. So
> `SQLITE_STATIC` is legal only when a live Avra value holds the box
> until the statement is finalized or the parameter is rebound.

Consequences, in order:

1. **v1 binds with `SQLITE_TRANSIENT`, always.** SQLite copies before
   returning; the box may die the instant after. One extra copy per
   bind, correctness with zero lifetime machinery, and it is what every
   safe binding in the field does by default.
2. **`SQLITE_STATIC` becomes legal the day the statement handle is an
   `opaque type` (spec 15.5) holding its bound `bytes` values in a
   field** until `finalize` or a rebind. Then the retain is the FIELD's
   and the language's own counting discharges SQLite's clause — the type
   system proving the lifetime instead of a comment. Record it as the
   optimization it is; do not ship it before opaque types.
3. **NEVER bind a NULL pointer for an empty blob.** An Avra `bytes` box
   is always non-NULL — `box_alloc` allocates at least one byte
   (`:245`) — so `avra_bytes_ptr` on an empty box answers a valid
   address, and `n = 0` binds a zero-length BLOB rather than SQL NULL.
   The headered box hands us this for free, and it is exactly the
   asymmetry the READ side has to work around by hand (§4.1, rule 2).
4. **The negative-length shortcut is forbidden.** Always pass
   `b.length` (a header load), never `-1`. Same law as `write_whole`
   (`runtime/avra_runtime.c:1388`).
5. **`avra_bytes_ptr`'s answer is never stored.** It is a borrow with no
   lifetime the compiler can see; it is handed straight to the `bind`
   call in the same expression. When spec 15.4's `@borrows` lands, this
   row is its first customer.
6. `sqlite3_bind_zeroblob(stmt, i, n)` stays the spelling for a large
   placeholder — it costs an integer, not `n` bytes.

### 4.3 Incremental BLOB I/O needs a WRITABLE box

`sqlite3_blob_read(blob, void* Z, int N, int iOffset)` fills a
caller-provided region (api_surface §1.9). A `bytes` value born
immutable cannot be filled. The shape that works, and it is small:

```
bytes.zeroed(n) -> bytes        // one row: str_box + memset, rc 1
avra_bytes_ptr(b) -> ptr        // the row §4.2 already needs
```

Mint a zero-filled box, hand SQLite its payload address, let SQLite
fill it. **Sound only while the box is uniquely referenced**, which it
is at the moment of minting and which the language cannot yet PROVE.
Named as a blocker (B5) with that caveat, because a `bytes` value
written after birth is the one place this design's immutability is
bent.

---

## 5. THE MIGRATION

### 5.1 What breaks in the tree, and it is all by design

**`Type` gains a variant, so every exhaustive match over `Type` stops
compiling.** That is the guarantee, not the cost — the same one the IR's
eight consumers give. The compiler names all of them; here is the list,
so the work can be sized before it starts (found by grepping the
`.EmptyMap` arm, which every exhaustive `Type` match spells):

| file | sites |
|---|---|
| `core/types.av` | `ptr_shape` :118-124, `canon` :130-152, `substituted` :263-281, `name_of` :284-307, `args_of` :311-321 |
| `features/unify.av` | :44, :88, :98, :114, :141, :155, :179 |
| `features/values.av` | `length_word` :428-437 (registry — one arm), `same_value` :55-64 (the wiring site) |
| `features/contexts.av` | :17, :30, :149 |
| `features/expr_spine/check.av` | :124, :165 |
| `features/impls/callee.av` | :40, :63 |
| `features/variants.av` | :77 |
| `features/enums/mod.av` | :69 |
| `features/str_lit/lower.av` | :41 |
| `language/lower_walk.av` | :93, :144, :155 |
| `language/receivers.av` | :192, :250 |
| `language/memory.av` | :37 |
| `language/llvm.av` | :207 |

Twenty-six arms across thirteen files. Twenty-five are a two-word
addition to an `or`-run. **`llvm.av:207` is the only one with a machine
consequence**: `bytes` joins the pointer-typed arm, which is what makes
it a managed value everywhere else.

**`RtHost` gains twelve variants**, so `rt_dispatch`
(`language/interp.av:500-570`) demands twelve arms. Also the guarantee.

**Nothing in the memory pass changes.** `rides_pointer` answers true, so
retains, releases, cell settling, owned slots and the callee-cleans ABI
all apply with no new rule.

**NO IR VARIANT.** Stated again because it is the design's largest
single win: `dst_of`, `step`, `memory_ins`, `body_lines`, `emit_ins` and
`give` are untouched, and `make vocab` has nothing new to keep.

**The NUL-safety fix changes `string` semantics** — two strings that
differ only after a NUL stop comparing equal. Nothing in the tree can
observe the change today: the compiler's own strings come from source
text and from its own construction, and `write_text` already treats a
NUL-bearing text as full-length (`:1388`), so the fix makes `==` AGREE
with `write_text` instead of contradicting it. The gate and the 161-file
corpus are the proof; a corpus pair over a NUL-bearing text pins it
forever.

**No literal syntax in v1.** Deliberate. Spec 28.3 offers `b"..."` typed
`List<u8>` (spec:5570) — which is the representation §1.1 refuses — and
a byte literal holding a NUL could not survive the constant path anyway:
`avra_llvm_build_global_string_ptr` measures with `strlen`
(`backend/llvm_wrapper.c:466`), and the wrapper's seat is `string`
(`language/llvm_api.av:29`), so the length is lost crossing the extern.
Byte values in v1 arrive from `bytes_of(s)`, `from_hex`, `from_base64`,
`read_bytes` and `avra_bytes_from_host`. `b"..."` (with `\x` escapes,
and a length-carrying constant emitter) is a sugar-backlog item naming
this paragraph.

### 5.2 `@std/io` — two functions, and ZERO new C

Lane B owns `@std/io` and has offered to grow it. The offer costs less
than it looks:

- **`write_bytes(path, b) -> Result<string, IoError>`** — `write_whole`
  ALREADY writes `str_len(content)` bytes, header-driven, with the
  comment stating the law (`runtime/avra_runtime.c:1388-1390`). The C is
  correct as written. Only the Avra signature's seat type changes.
  (It answers the PATH, as `write_text` does, because `Result<void, E>`
  is refused — CLAUDE.md, the subset.)
- **`read_bytes(path) -> Result<bytes, IoError>`** — `read_whole`
  ALREADY sets the header from `fread`'s count (`:1357-1366`), so the
  stash holds a full-length box today; `avra_io_read` stashes it and
  `avra_io_taken` hands the reference over (`:1417-1422`). The only new
  C is a second taker:

```c
// The stash taken as BYTES. The stash holds the only reference, so the
// kind may be restamped in place; the reference moves to the caller.
const char* avra_io_taken_bytes(void) {
    const char* p = avra_io_taken();
    Header* h = hdr((void*)p);
    if (h && h->kind == KIND_STR) h->kind = KIND_BYTES;
    return p;
}
```

  Zero-copy, and sound because the stash's reference is unique by
  construction (`io_stash` releases the previous one, `:1409-1412`).
  `box_bytes` treats both kinds as `len + 1`, so the restamp does not
  disturb reclaim. **MEDIUM** confidence on the restamp being accepted
  as idiomatic rather than clever — the alternative is a plain copy, one
  extra `memcpy` per file read, and the lane owner decides.
- `read_text` and `write_text` are unchanged. A text holding a NUL keeps
  working and starts comparing correctly.

### 5.3 `@std/text` — the projections live here

Gains `to_hex`, `from_hex`, `to_base64`, `from_base64`, `text_of`,
`text_lossy`, `bytes_of`, with `spec`/`given`/`then` tests beside them.
All Avra except the two conversion rows. Its existing UTF-8 lead-byte
decoder (`text.av:88-97`) becomes the validator's body — one more
consumer, no new algorithm.

`text_lossy` needs U+FFFD, and `"�"` is not a lexer escape
(CLAUDE.md, the subset: the lexer keeps an unknown escape as its two
characters). The spelling is `from_codepoint(65533)`, which `@std/text`
already exports (`text.av:103-106`).

### 5.4 `@std/process` — a latent instance of the same bug, named not fixed

`avra_proc_take` answers `string` (`core/runtime_api.av:71`) and a
child's stdout is arbitrary bytes. Today that truncates at the first NUL
for every operator but `.length`. Once `bytes` lands, `@std/process`'s
`out`/`err` should become `bytes` with a `text()` projection. **Record
it in the ROADMAP as a lane-B follow-on; do not do it inside this
campaign** — it is a real API change with its own tests and its own
review, and bundling it would hide it.

`@std/json` is unaffected: JSON is text by definition.

### 5.5 The bootstrap order

The compiler's own source uses `bytes` in exactly one place —
`Val.By(v: bytes)` in `language/interp.av:16-28` — and that means the
STANDING binary must already understand `bytes` before that source can
be compiled. CLAUDE.md's rule ("A SYNTAX CHANGE TO THE COMPILER'S OWN
SOURCE runs in one order") applies verbatim:

1. `cp build/avra build/avra.pre` — the way back.
2. Build 1: the compiler KNOWS `bytes` (type, rows, feature, backend)
   but its own source does not USE it; the bytes host arms answer a
   defect.
3. Refresh `bootstrap/seed.ll` from build 1 (the tree does this
   routinely — see commit `c1541dd`, "chore(seed): refreshed after lane
   d merged").
4. Build 2: `Val.By` and the twelve host arms land, compiled by build 1.
5. Build a third time to prove the fixed point, per the CODEGEN FIX rule
   — this touches no pass, so one confirming build is enough.

---

## 6. THE LANDING CHECKLIST

Dependency order. Every step ends with
`sh tools/watch.sh 4000 make gate` — one heavy process, foreground,
under the watchdog.

**S0 — NUL SAFETY IN `string`.** Independent of everything below and
valuable alone.
- `runtime/avra_runtime.c`: `str_len` `:272-275` drops the `&& h->len`
  clause; `avra_streq` `:475-478` becomes length-then-`memcmp`;
  `avra_str_starts_with` `:1148-1150` becomes `memcmp`;
  `avra_str_contains` `:1144`, `avra_str_index_of` `:1159`,
  `avra_str_replace` `:1207`, `avra_str_split` `:1232` move to a shared
  length-driven `find_bytes(hay, n, needle, m)` helper — ONE search, not
  four (the third-copy rule).
- `memmem` is glibc-only; the runtime writes the loop itself, as it
  already guards `posix_spawn_file_actions_addchdir` by platform
  (`:1290-1300`).
- Tests beside `packages/std-avrac/src/core/tests/text_test.av`;
  `corpus/nul_text.av` + `.expected` proving eval == native.

**S1 — THE TYPE.**
- `core/types.av`: `Type.Bytes` in the enum `:12-90`; the five
  exhaustive fns (`ptr_shape` `:118`, `canon` `:130` — a fresh key,
  `"19"` is free — `substituted` `:263`, `name_of` `:284` answering
  `"bytes"`, `args_of` `:311`).
- `language/typing.av:317-322`: `"bytes" -> Type.Bytes`; F2001's help
  names the spelling for a source that wrote `Bytes`.
- `features/unify.av` (7 sites): `bytes` agrees only with `bytes`. **No
  widening to or from `string`, in either direction.**
- The remaining exhaustive arms in §5.1's table.
- `language/llvm.av:207`: `bytes` joins the pointer-type arm.

**S2 — THE RUNTIME BOX.**
- `runtime/avra_runtime.c`: `KIND_BYTES = 4` at `:48`; `box_bytes`
  `:280-282` treats it like `KIND_STR`; `ACC_BYTES` in the accounting
  enum `:98` with its name at `:99`, and the arm in `acc_kind_of`
  `:234-236`.
- The C bodies for the nine operation rows plus `avra_bytes_of_text` and
  `avra_bytes_as_text`, each allocating through `str_box`, each trapping
  past `0xFFFFFFFF`.

**S3 — THE ROWS.**
- `core/ir.av:222-290`: the `RtHost` variants.
- `core/runtime_api.av:11-90`: the `rt_sigs()` rows, `owns_result` set
  per body (`_slice`, `_concat`, `_of_text`, `_as_text`, `_from_host`,
  `zeroed` own; the rest borrow).
- `language/interp.av:500-570`: the host arms answer a defect for now —
  the exhaustive match is satisfied, the meaning arrives in S6.

**S4 — THE FEATURE.**
- `avra new feature bytes` →
  `packages/std-avrac/src/features/bytes/{mod.av,check.av,lower.av,tests/}`.
  `mod.av` mirrors `features/str_lit/mod.av:10-52`: an `on_bytes`
  predicate, the method rows, the `length` property row through
  `measured_reg`. **No gram fragment** — `gram: Grammar = no_grammar()`
  is the component's own default (`features/mod.av:111-123`), so a
  feature that contributes only method and property rows is a supported
  shape, not a workaround.
- `features/values.av`: `length_word` `:428-437` gains
  `.Bytes -> "avra_bytes_len"` (which gives `is_empty` for free);
  `same_value` `:55-64` gains the `.Bytes` arm beside `.Str`.
- `language/mod.av:100`: the feature joins the assembly. It contributes
  no grammar, so its position is free — put it beside `str_lit`.
- `corpus/bytes.av` + `.expected`.

**S5 — THE LIBRARY.**
- `packages/std-text/src/text.av`: `to_hex`, `from_hex`, `to_base64`,
  `from_base64`, `text_of`, `text_lossy`, `bytes_of`; tests beside.
- `packages/std-io/src/io.av`: `read_bytes`, `write_bytes` (lane B).
  `avra_io_taken_bytes` is the only new C.

**S6 — THE INTERPRETER (build 2).** Per §5.5's order.
- `language/interp.av:16-28`: `Val.By(v: bytes)`; `bytes_val` beside
  `text_val`; the twelve host arms become real.
- The corpus pair now proves eval == native for every bytes operation.

**S7 — ITERATION (optional, last).**
- `features/emit.av`: `elem_word(shape)` beside `length_word`;
  `turn_elem` `:129-135` asks it. The loops and lists typing answer
  `int` for a `bytes` subject. `for`, comprehensions and `map` all land
  together because the walk is one vocabulary (I33).
- Rewrite `to_hex` as a comprehension; delete the while loop.

**S8 — THE DRIVER'S SEAT.**
- `avra_bytes_from_host`, `avra_bytes_ptr`, `bytes.zeroed(n)`.
- The compiler refusal: an `extern fn` may never declare `string` or
  `bytes` as its answer, as a NAMED VOICE (I28) with its own F-code —
  the next free F2 id today is **F2056**, claimed at landing.
- `packages/std-sqlite/`: the blob column read and the blob bind, with
  the `SQLITE_TRANSIENT` law written at the site.

**DOGFOODING.** No new idiom is proposed here. Two existing ones are
load-bearing and must be honoured at every site: **I22** (`length_word`
and `elem_word` are REGISTRIES — every arm spelled, no catch-all) and
**I28** (the extern-answer refusal is a named voice fn, not assembled
prose). Any pattern the implementation discovers lands in DOGFOODING's
registry AT DISCOVERY with its matcher, under the next free number, per
the tool's duplicate-number refusal.

---

## BLOCKERS

Ordered by what stops the driver soonest.

### B1 — `str_len`'s zero fallback makes an empty box unmeasurable
`runtime/avra_runtime.c:272-275`. An empty `bytes` box would be measured
by `strlen` over its payload. **FIX:** delete the `&& h->len` clause
(§2.3). Proved a no-op for `string` by `bootstrap/seed.ll:6`,
`backend/llvm_wrapper.c:466-472`, and every runtime producer. **SMALL.**
Must land in S0, before any `bytes` box exists.

### B2 — `starts_with` is NUL-lossy, and the brief lists it as safe
`avra_str_starts_with` `:1148-1150` uses `strncmp`, which stops at a NUL
in either operand (C17 §7.24.4.4). **FIX:** `memcmp` after a length
guard, exactly as `ends_with` `:1152-1157` already does. **SMALL**, S0.

### B3 — `sqlite3_blob_read` needs a WRITABLE box, and `bytes` is immutable
Incremental BLOB I/O fills a caller-provided region (api_surface §1.9).
**FIX:** `bytes.zeroed(n)` (one row: `str_box` + `memset`) plus
`avra_bytes_ptr`, handing SQLite the payload address of a
freshly-minted, uniquely-referenced box. Sound at the moment of minting;
**the language cannot PROVE the uniqueness**, so the rule lives in the
row's doc and in a review. This is the one place the design's
immutability is bent, and it should be bent deliberately or the whole
incremental-BLOB family is deferred. **SMALL** to build, **MEDIUM** to
decide.

### B4 — an `extern fn` may declare `string` (and would be able to declare `bytes`)
`extern_row` hard-codes `owns_result: false`
(`core/runtime_api.av:103`), and nothing refuses `-> string` on an
extern, so a foreign `const char*` becomes an Avra `string` that reads
sixteen bytes of foreign memory on every `.length`
(`ROADMAP.md:1617-1640`). For a blob it is worse: a blob's length is not
`strlen`. **FIX:** a compiler refusal, named voice, F2056; the extern
wall answers `ptr` and `int`, and `avra_bytes_from_host` /
`avra_str_from_host` mint the box. Shared with the campaign's prior-art
and FFI research; restated here because `bytes` doubles its blast
radius. **SMALL-MEDIUM.**

### B5 — `SQLITE_STATIC` has no lifetime the language can express
A bind is not a retain, and reference counting places the release at the
owning scope's end. **FIX:** bind `SQLITE_TRANSIENT` in v1 (one copy per
bind, correct with no machinery); `SQLITE_STATIC` becomes legal once the
statement is an `opaque type` (spec 15.5) holding its bound `bytes` in a
field until finalize or rebind. Depends on the opaque-type blocker the
FFI research already owns. **DEFERRED, by design.**

### B6 — no index operator and no ordering operator on a non-`List`
`b[i]` is F2000 "`[...]` indexes a `List`"; `<` is F2000 "`==` compares
scalars for now" territory (`features/expr_spine/check.av:124,165`).
**FIX for v1:** `b.at(i)` and `b.compare(other) -> int`. Both operators
are sugar-backlog items naming §3.1. **NOT BLOCKING** — the driver never
needs either.

### B7 — no byte literal, and the constant path could not carry one
`avra_llvm_build_global_string_ptr` measures with `strlen`
(`backend/llvm_wrapper.c:466`) and its seat is `string`
(`language/llvm_api.av:29`), so a constant holding a NUL loses its tail
crossing the extern. **FIX, deferred:** `b"..."` with `\x` escapes plus
a length-carrying constant emitter (`avra_llvm_build_global_bytes(b, s,
len, name)`) — a backend-wrapper change, still no IR variant, since
`Ins.ConstStr`'s payload is itself a length-carrying box. Sugar backlog.
**NOT BLOCKING** — v1's bytes come from conversions and I/O.

### B8 — `Result<void, E>` is refused, so `write_bytes` answers the path
Standing item (CLAUDE.md, the subset; F2019). `write_bytes` answers the
path exactly as `write_text` does. **NOT BLOCKING.**

### B9 — the two-stage build plus a seed refresh
`Val.By` makes the compiler's own source use `bytes`, so the standing
binary must know `bytes` first (§5.5). Process, not language. **NOT
BLOCKING**, but it is the step most likely to be skipped and it leaves
no compiler if it is — `cp build/avra build/avra.pre` FIRST.

---

## CONFIDENCE LEDGER

| # | Claim | How verified | Confidence |
|---|---|---|---|
| 1 | The header is `{u32 tag, i32 kind, i32 rc, u32 len}`, 16 bytes, 16-aligned, tag `0x41565241` | read `runtime/avra_runtime.c:48-73` | HIGH |
| 2 | `==`, `contains`, `index_of`, `replace`, `split` truncate at NUL | read `:475-478, 1144-1146, 1159-1162, 1207-1230, 1232-1251` | HIGH |
| 3 | `starts_with` ALSO truncates (`strncmp` stops at a NUL) — corrects the brief | read `:1148-1150`; C17 §7.24.4.4 wording | HIGH |
| 4 | `.length`, `substring`, `char_code`, `trim`, `concat`, `ends_with`, `join` are byte-exact | read `:997-1015, 1136-1142, 1152-1157, 1177-1187, 1189-1205, 1253-1259` | HIGH |
| 5 | The `h->len == 0` fallback is vestigial; every producer sets the length | `bootstrap/seed.ll:6` shows len 6 for `"--help"`; `backend/llvm_wrapper.c:466-472`; `ROADMAP.md:465-467` | HIGH |
| 6 | `str_box`/`box_alloc` give `rc = 1` and a size-class free list | read `:244-268` | HIGH |
| 7 | `box_bytes` and `acc_kind_of` are the ONLY two runtime sites needing a `KIND_BYTES` arm | read `:234-236, 280-289`; `rc_release` `:415-434` dispatches kind only for ARRAY/MAP reclaim | HIGH |
| 8 | No IR variant is needed — every op rides `CallRt` | `core/ir.av:26-64`; the ops are all value-producing runtime calls | HIGH |
| 9 | A feature may contribute rows with NO grammar | `features/mod.av:111-123`, `gram: Grammar = no_grammar()` is the config default | HIGH |
| 10 | 26 exhaustive `Type` arms across 13 files must gain a case | grepped the `.EmptyMap` arm across `packages/std-avrac/src` | HIGH |
| 11 | `length_word` is a registry with three answering arms; adding `.Bytes` gives `is_empty` for free | read `features/values.av:428-437`, `features/str_lit/lower.av:59-68` | HIGH |
| 12 | The interpreter hosts string rows via the compiler's own Avra string methods, so one C fix serves both engines | read `language/interp.av:509, 529-541` | HIGH |
| 13 | `sqlite3_column_blob` returns NULL for a zero-length BLOB; pointers die at the next step/reset/finalize; blob-then-bytes call order; OOM is indistinguishable without `sqlite3_errcode` | fetched sqlite.org/c3ref/column_blob.html, quoted | HIGH |
| 14 | `SQLITE_STATIC` requires validity until finalize or rebind; `SQLITE_TRANSIENT` copies before return; a NULL third parameter binds SQL NULL; a negative text length measures to the first NUL | fetched sqlite.org/c3ref/bind_blob.html, quoted | HIGH |
| 15 | `SQLITE_MAX_LENGTH` defaults to 1e9 and cannot exceed 2^31−3, so no SQLite blob overflows a `uint32` header length | fetched sqlite.org/limits.html | HIGH |
| 16 | `write_whole` already writes the header length; `read_whole` already sets it from `fread` — so `@std/io` needs zero new C for `write_bytes` and one taker for `read_bytes` | read `:1357-1366, 1379-1398, 1409-1422` | HIGH |
| 17 | The spec commits `string` to UTF-8-always, which refuses option (b) | spec:1477 (9.15 Encoding), spec:3054 (15.6) | HIGH |
| 18 | The spec has no app-level `u8`; sized ints are systems-level | spec:6236-6252 (31.1) | HIGH |
| 19 | A `List<int>` costs ~9 bytes per blob byte and its pointer is the struct, not the data | read `runtime/avra_runtime.c:511-524`; `ROADMAP.md:1594-1599` states the same for out-params | HIGH |
| 20 | Erlang: heap binaries ≤64 bytes, refc binaries above, sub-binaries are O(1) views, and a sub-binary retains the whole binary | erlang.org efficiency guide, "Constructing and Matching Binaries" | HIGH |
| 21 | Go: `string` is arbitrary bytes; conversions copy except narrow compiler peepholes (`m[string(b)]`) | golang/go#3512, golang/go#71132 | HIGH |
| 22 | Python: 3.0 Dec 2008, Py2 EOL 2020-01-01; PEP 461 restored `%` for bytes in 3.5; PEP 383 `surrogateescape` from 3.1 | peps.python.org/pep-0461, peps.python.org/pep-0383 | HIGH |
| 23 | Rust: `String::from_utf8` is fallible, `from_utf8_lossy` total, `as_bytes` free; `OsString` exists for the third case | standard-library knowledge, not re-verified this session | MEDIUM |
| 24 | Swift: `String(data:encoding:)` is failable, `s.utf8` is a free view | standard-library knowledge, not re-verified this session | MEDIUM |
| 25 | Restamping the io stash's kind in place is sound because the stash reference is unique | read `io_stash` `:1409-1412`, `avra_io_taken` `:1417-1422`; NOT probed | MEDIUM |
| 26 | `elem_word` beside `length_word` is all iteration costs | read `features/emit.av:99-146`; the typing side (loops/lists element answer) was NOT read | MEDIUM |
| 27 | F2056 is the next free F2 code | grepped `F2[0-9]{3}` across `packages/std-avrac/src`; highest is F2055; other lanes may claim first | MEDIUM |
| 28 | Nothing in the tree observes the `==` semantics change | reasoned from `write_text`'s existing header-length law; NOT proved by running the gate (this session is read-only) | MEDIUM |
| 29 | A future `bytes ↔ string` conversion could be a kind flip on a unique box | reasoned from identical layouts + `avra_array_shared` `:816-818`; NOT designed or probed | LOW |

**No claim in this report was verified by running anything.** This
session was read-only by instruction: no build, no `./avra`, no gate.
Every "read" above is a source read; every "fetched" is a named external
document. The probes this design implies — a NUL-bearing text through
`==`, an empty `bytes` box's length, a blob round-trip — are listed as
the first three tests in S0 and S4.
