# `bytes` against STRINGS FROM THE FUTURE — the reconciliation

> The design vision for Avra's strings
> (`../forge-crafting-intepreters/docs/2026_06_30_STRINGS_FROM_THE_FUTURE.md`,
> 878 lines, 2026-06-30) read in full against the `bytes` design now on
> this branch
> (`docs/2026_09_05_STD_SQLITE_RESEARCH_bytes_blob.md`, 1054 lines),
> against the probe log (`…_probe_log.md`), and against THE SPEC
> (`…/2026_04_18_FULL_SPEC.md`), which is law wherever the three
> disagree.
>
> The owner's instruction: *"it's relevant to our bytes stuff. we may
> not want the whole thing but want to make sure it's aware."* So this
> file does not adopt the vision and does not ignore it. It says which
> parts BIND, which parts we TAKE, and which parts we DECLINE with the
> loss named.
>
> **The bytes design report EXISTS** and is reconciled against directly
> below, claim by claim. Where I agree with it I say so and stop; where
> I disagree the disagreement is in §4.
>
> Read-only session. Nothing here was run. Every claim carries a
> file:line, a spec sub-decision, or a marked inference.

---

## THE HEADLINE, BEFORE THE DETAIL

The vision is not a stranger to this campaign. **It already contains
`bytes`**, as a peer type of `string`, and it already decides the two
questions the campaign is asking:

> `bytes` = sequence of `u8`. Here `b[i: int] → u8` is honestly O(1),
> so integer indexing **is** allowed and pretty.
> — Part II, "The collapse"

> **A `string` is always valid UTF-8.** Enforced at the *only* entry
> point — the bytes→text boundary:
> `bytes.text()  // string?   validated (the safe default)`
> `bytes.text_lossy()  // string  U+FFFD-replaced, infallible`
> — Part III, "The invariants that make it sound", item 1

The `bytes` design report reached the same two answers independently —
a distinct type (§1.4), a fallible decode with a total twin (§3). **The
vision CORROBORATES the design's spine.** It diverges on exactly one
axis — whether `bytes` is a VIEW of a string's buffer or a BOX of its
own — and that divergence is where §3 and §4 do their work.

---

# 1. WHAT `STRINGS FROM THE FUTURE` ACTUALLY DECIDES

Faithful summary, its own terms. No editorial.

## 1.1 The presenting problem, and the paradox it names

Ticket `29f3`: the spec says `s[i]` returns `u8`, the old implementation
returned a 1-char string at a BYTE index — "invalid UTF-8 masquerading
as a string" (Part I). The document refuses to treat that as a
byte-vs-char argument:

> It's *not* "byte vs char." That's a symptom. The actual paradox is:
> `s[i]` is asked to be **O(1)** (Rust), **Unicode-correct** (chars, not
> bytes), and **obvious** (`s[i]` is "the i-th character"). On UTF-8,
> variable width makes O(1)-random-codepoint physically impossible — so
> all three can't hold *as long as `i` is an integer count*.
> — Part II, "Name the real paradox"

## 1.2 The collapse: `int` conflates position and count

`i: int` is forced to mean both a POSITION (wants O(1)) and a COUNT (is
O(n) on UTF-8). Split them:

- **Position → `Cursor`** — an opaque byte offset. O(1) to dereference,
  O(1) to advance. What iteration and search hand you.
- **Count → `s.char(n)`** — honestly O(n), and *named* like it.

Everything else is then O(1): `s.first`, `s.last`, `s[c]` for a Cursor
`c`, `s[c..]` for a slice, `s.find("x")?` answering a Cursor.

## 1.3 The intended representation

Three claims, and only the third is about layout:

1. **`string` = sequence of `char`** (Unicode scalar); `'a'` is a
   `char`. **`bytes` = sequence of `u8`**, integer-indexable. **`grapheme`
   is a distinct type** via `s.graphemes()`, "kept separate so you never
   pay Unicode-segmentation cost or carry the tables unless you ask."
2. **Lenses replace the bare value.** Part III, "there is no bare `s[i]`
   *or* bare `for c in s`":
   > `s.bytes` — Seq<u8> — O(1) index, O(1) length
   > `s.chars` — Seq<char> — codepoint cursors
   > `s.graphemes` — Seq<grapheme> — opt-in tables
   > … The three lenses share the *same* underlying buffer and
   > byte-offset cursor representation — one data structure, three
   > granularities, **zero copies**.
3. **Slicing is free, by leaning on SSO and refcounting.** Part II,
   "Two corollaries":
   > SSO (≤23 B inline) means a slice of a small string is a
   > sub-24-byte copy (free); a slice of a heap string is a
   > buffer-shared view (free). So one `string` type is *always* cheap
   > to slice — the user never sees owned-vs-borrowed.

   Escape analysis elides the refcount bump when a view does not escape;
   inside a manual-memory `scope` there is no refcount at all.

## 1.4 The intended API

- **No bare `s[i: int]`** — a compile error with a teaching F-code
  naming three intents (iterate, `s.first`/`s.last`, `s.char(n)` for the
  n-th codepoint, `s.bytes[i]` for a raw byte).
- **No bare `.length`.** Part II: "Bare `s.length` is its own little lie
  (LLM expects char count, spec returns bytes). Same fix: no bare
  `.length` on a string — `s.bytes.length` (O(1)) and
  `s.chars.count()` (O(n))."
- **One `Seq` protocol.** Part III, "The unification that ties it shut":
  > `list`, `s.bytes`, `s.chars`, `s.graphemes` all implement **one
  > `Seq` protocol** (cursor, slice, `find`, iterate, pattern-match). …
  > there is no separate "string API" to memorize.
- **Typed string patterns in `match`** — the "crown jewel", ticket
  `h78d`: `"GET {path} HTTP/1.{minor: int}"` as a pattern, captures
  binding to O(1) slices, typed captures parsing and validating, "a
  **single anchored left-to-right scan** … Linear time, by construction."

## 1.5 The intended text↔bytes relationship

One checkpoint, two verbs, asymmetric fallibility:

- `bytes.text() -> string?` — validated, the safe default.
- `bytes.text_lossy() -> string` — U+FFFD, infallible.
- `s.bytes` — free, no copy, no check, "because the invariant only ever
  narrows" (the phrasing is Rust's, restated in Part III's invariant 1).

The payoff is stated explicitly: "Because the invariant holds, every
downstream `.chars` walk skips per-step validity checks — that's where
Rust-speed iteration comes from."

## 1.6 The other two invariants

2. **Cursors are valid forever** (immutability) and **aligned to their
   lens** (typed) — "Two whole error classes (invalidation,
   mid-codepoint slice) simply don't exist."
3. **Construction is always O(n)** — interpolation pre-sizes, `join` is
   one pass, `+=` in a loop lowers to amortized append. "The pretty
   syntax *is* the optimal builder — so the O(n²)-concat trap is
   unwritable."

## 1.7 What it escalates to (Parts V–VI)

A format becomes "a value the compiler can run in every direction":
bidirectional `grammar` values proving `print ∘ parse == id`;
`Tainted<string>` and `sql""`/`html""` making injection a type error;
refinement types (`type Email = string where it.matches(EMAIL)`);
zero-copy structured views with SIMD scanners; one grammar serving batch
and streaming; compile-time protocol-compatibility proofs; and `string`
as a **persistent rope** so edits are O(log n) with value semantics
(Part V, Move 6 — the answer to its own open question 2).

Part VI generalizes off strings entirely — invertible relations,
incremental/time-travelling state, one qualifier lattice for
effects/capabilities/units/taint/refinements, cost as part of the type,
and the language made of itself. Not this campaign's business, listed
for completeness.

## 1.8 What the document says about its own status

> **Aspirational syntax** — none of this compiles today. … Companion to
> the authoritative `docs/2026_04_18_FULL_SPEC.md`; where they disagree,
> this document is the *proposal* and the FULL_SPEC is *current law*.

It says so itself. That framing governs everything below.

---

# 2. HOW MUCH OF IT IS BUILT

| vision idea | status in this tree | evidence |
|---|---|---|
| `string` is a byte buffer, UTF-8 by intent | **BUILT, unenforced** | `str_box` `runtime/avra_runtime.c:264-268`; nothing validates |
| Strings are immutable | **BUILT** | every op mints a fresh box — `avra_str_substring` `:1136-1142`, `_trim` `:1197-1205`, `_concat` `:1253-1259`; no mutating string row in `rt_sigs()` `core/runtime_api.av:11-90` |
| Refcounted buffers | **BUILT** | `avra_rc_retain` `:383-390`, `avra_rc_release` `:415-434` |
| SSO (≤23 B inline, 24-byte value) | **NOT BUILT, and the tree went the other way** | a `string` is a pointer to a heap box with a 16-byte header `:56-61`; `ptr_shape` answers true for `.Str` (`core/types.av:118-124`) |
| A slice is a zero-copy view | **NOT BUILT, and structurally blocked** | `avra_str_substring` `:1136-1142` calls `str_owned` — a copy. The header `:56-61` has no offset field; all sixteen bytes are spoken for |
| Escape analysis elides the bump | **NOT BUILT** | the memory pass places retains/releases; no escape query exists (grep of `language/memory.av` shows no such rule) — MEDIUM, inferred from absence |
| `Cursor` type | **NOT BUILT**, and not in the spec either | no `Cursor` in `core/types.av:30-60` |
| `char` type, `'a'` literals | **NOT BUILT**; the SPEC commits to it | spec:5569, spec:6403. Today `char_code` answers `int` (`:1177-1187`) |
| Lenses `.bytes` / `.chars` / `.graphemes` | **NOT BUILT as lenses; the SHAPE exists as free fns** | `@std/text`'s `codepoints`, `chars`, `codepoint_count` (`packages/std-text/src/text.av:88-99`) — a library walk, not a type |
| No bare `s[i]` | **EFFECTIVELY TRUE, for the wrong reason** | F2000 "`[...]` indexes a `List`" (CLAUDE.md, the subset) — a SHAPE refusal, not the vision's teaching F-code naming three intents |
| No bare `.length` | **NOT DONE, and the SPEC REFUSES IT** | spec:1477 "`string.length` returns **byte count** by default"; the tree obeys (`avra_str_len` `:1189-1191`) |
| Valid-UTF-8 invariant enforced at one boundary | **NOT BUILT, and currently VIOLABLE from two directions** | (i) `avra_str_substring` `:1136-1142` clamps BYTE offsets, never aligns — `"αβγ".substring(0,1)` mints half a codepoint; (ii) probe log §6, a foreign `const char*` typed `string` |
| Construction is always O(n) | **BUILT for interpolation and join** | `interp_reg` (`features/str_lit/lower.av:8-21`) pre-sizes one array (`box_size`/`grown_box`) and emits ONE `avra_str_join`; `avra_str_join` `:997-1015` is one pass with a pre-computed total |
| Length-driven ops (the Seq spirit) | **HALF BUILT** | byte-exact: `.length` `:1189-1191`, `substring` `:1136-1142`, `char_code` `:1177-1187`, `trim` `:1197-1205`, `concat` `:1253-1259`, `ends_with` `:1152-1157` (memcmp), `join` `:997-1015`. NUL-lossy: `==` `:475-478` (strcmp), `contains` `:1144-1146` (strstr), `starts_with` `:1148-1150` (strncmp), `index_of` `:1159-1162` (strstr), `replace` `:1207-1230` (strlen+strstr+strcpy), `split` `:1232-1251` (strlen+strstr) |
| One `Seq` protocol across list/string/bytes | **NOT BUILT** | `length_word` (`features/values.av:428-437`) is the closest thing — a three-arm registry mapping a shape to its measure word |
| Typed string patterns in `match` | **NOT BUILT** | no capture-pattern syntax; `match` arms take literals |
| Persistent rope | **NOT BUILT, and contradicts the header model** | one box, one refcount, no structural sharing anywhere in `:244-434` |
| SIMD scanners | **NOT BUILT** | `strstr`/`memcmp`, `:1144-1162` |
| Comptime folding of `.chars.count()` | **NOT BUILT** | `@comptime` refuses at the `@` (CLAUDE.md, the subset) |
| `Tainted<T>`, grammars, `iso`, cost types | **NOT BUILT**, none in the spec | — |

**The two lines that matter most.** The header/length work landed AFTER
the vision was written (2026-06-30), and it OVERTOOK the vision on one
point and CONTRADICTED it on another:

- **Overtook:** `.length` is now an O(1) header load for strings
  (`str_len` `:272-275`), which is the vision's `s.bytes.length` cost
  without the lens. The vision's complaint about `.length` was about its
  MEANING, not its cost, and the meaning question is settled by
  spec:1477 against the vision.
- **Contradicted:** the vision's slicing corollary rests on SSO, which
  the tree does not have and which the header model actively displaces.
  See §4, T1.

---

# 3. THE RECONCILIATION

Six decisions. For each: what the vision implies, then
**ADOPT / ADAPT / DECLINE** with the loss named.

## D1 — Is `bytes` a distinct type, a fix to `string`'s lossy operators, or `List<u8>`?

**The vision implies a DISTINCT TYPE, and refuses the other two by
construction.** `bytes` is named as a peer of `string` in the collapse
("`bytes` = sequence of `u8`… integer indexing **is** allowed"), and the
whole model is built on `string` carrying a UTF-8 invariant that
arbitrary bytes would destroy — Part III's invariant 1 is the reason
`.chars` can skip per-step validity checks. A `string` that held blobs
would delete the invariant and with it the performance story. `List<u8>`
never appears; the vision's byte sequence is a LENS over one buffer, the
opposite of a boxed cell array.

**ADOPT.** This is bytes_blob §1.4's recommendation, independently
reached, and the vision supplies a reason §1.4 does not: the two-type
split is what BUYS the iteration speed, not merely what buys the type
safety. The design's own reasons stand — spec:1477 and spec:3054 make
(b) a spec amendment rather than a lane decision (bytes_blob §1.3); a
`List<int>` is nine bytes per blob byte and its pointer is the
`AvraArray` struct, not the data (bytes_blob §1.1, `runtime/avra_runtime.c:511-524`).

**Agreed with bytes_blob:** §1.1, §1.3, §1.4 in full.

## D2 — Does `bytes` share the string box, or get its own?

**The vision implies SHARING, and goes further than the design does:**
one buffer, three granularities, **zero copies**. `s.bytes` is a VIEW,
not a conversion; `b.text()` reads the same memory back.

**ADAPT.** Take "one layout, one allocator, one refcount, one free
list"; **decline the zero-copy view.**

- **Adopted:** bytes_blob §2.1's `KIND_BYTES` sharing `str_box`
  (`:264-268`) / `box_alloc` (`:244-262`), with the two runtime arms
  §2.2 identifies (`box_bytes` `:280-282`, `acc_kind_of` `:234-236`).
  Correct as written, and the vision's "one data structure" is the same
  instinct at a different altitude.
- **Declined:** the view. The header (`:56-61`) has no offset field —
  all sixteen bytes are tag/kind/rc/len — and widening it costs every
  string and every record in the tree. bytes_blob §2.2 states this and
  is right.
- **What we lose:** `s.bytes` is not free. A 1 MB text bound as a blob
  costs a 1 MB copy; `bytes_of(s)` and `text_of(b)` are O(n) forever
  unless the kind-flip optimization lands.
- **Why acceptable:** the vision's own survey material argues against
  views — Erlang's sub-binary retains the whole parent binary, the
  classic space leak (bytes_blob §1.2, ledger #20). A copy has a cost
  you can see; a view has a cost you cannot. And the driver's blob path
  MUST copy anyway: `sqlite3_column_blob`'s pointer dies at the next
  `step`/`reset`/`finalize` (bytes_blob §4.1, rule 1), so the one
  place the campaign touches blobs is a place the vision's view model
  could not have served either.

**Disagreed with bytes_blob:** the future kind-flip sketch (§2.2, ledger
#29) is unsound as worded. See §4, T3.

## D3 — What happens to `==`, `contains`, `index_of`, `replace`, `split` on a byte-carrying value?

**The vision implies they are length-driven by construction and never
NUL-terminated.** Every operation in the model consumes a Seq — a
(buffer, offset, length) — and `buf.bytes.find('\n')` is described as a
SIMD scan over a known extent. There is no terminator anywhere in the
model. In the vision's terms, `"\0A" == "\0B"` answering true is not a
design tension; it is a **bug**.

**ADOPT the fix, and take the vision's framing as the reason to write it
ONCE.** bytes_blob §1.3 is right that the NUL-lossiness is a standing
`string` bug that must land first and independently. The vision adds the
shape of the fix: under one Seq protocol these are ONE implementation
over (pointer, length), serving `string`, `bytes` and later `list`.
That is the doctrine's own rule — "The third copy of a shape names the
concept" (CLAUDE.md) — arriving from the other direction.

Concretely, for S0:

| op | today | fix |
|---|---|---|
| `==` `:475-478` | `strcmp` | length compare, then `memcmp` |
| `starts_with` `:1148-1150` | `strncmp` (stops at a NUL in EITHER operand, C17 §7.24.4.4) | length guard, then `memcmp` — as `ends_with` `:1152-1157` already does |
| `contains` `:1144-1146`, `index_of` `:1159-1162` | `strstr` | one internal `mem_find(h, hn, n, nn)` |
| `replace` `:1207-1230` | `strlen` + `strstr` + a terminating `strcpy` | `str_len` + `mem_find` + `memcpy` |
| `split` `:1232-1251` | `strlen` + `strstr`, and `*r != '\0'` IS the trailing-empty rule | `str_len` + `mem_find`, with the trailing-empty rule restated in terms of length |

**Agreed with bytes_blob:** §0's correction that `starts_with` is lossy
and the brief lists it as safe — verified at `:1148-1150`, HIGH.

**Disagreed with bytes_blob:** B2 sizes the whole thing as "SMALL, S0"
on the strength of `starts_with` alone. `replace` and `split` are not
one-liners. See §4, T6.

## D4 — How do text and bytes convert, and which direction is fallible?

**The vision answers this outright and completely.** `bytes.text()`
validated; `bytes.text_lossy()` infallible; `s.bytes` free and total.
"the ONE UTF-8 checkpoint. Nothing downstream re-checks" (Part IV,
`parse_http`).

**ADOPT the structure. ADAPT the answer type.**

- **Adopted:** two verbs, not one — a fallible decode WITH a total
  lossy twin. bytes_blob §3 has both (`text_of` and `text_lossy`), which
  matches. Adopted also: the asymmetry's reason — encode is total
  because the invariant only narrows.
- **Adapted:** the vision answers `string?`. bytes_blob answers
  `Result<string, TextError>` carrying the byte offset. **The design is
  right and the vision is wrong here, by the vision's own hand** — its
  decode example is `raw.text() ?? Err(raw.first_invalid_offset())`
  (Part IV), a second pass over the same bytes to recover what the first
  pass already knew. A `Result` collapses that. The probe log supplies
  the second reason: `string?` is a NICHE (`features/values.av:228-232`;
  probe log §2), and the campaign's own law is that a row answers "an
  EMPTY BOX for empty, and NULL only for ABSENT" (probe log §2b). Making
  "invalid UTF-8" a null spends the absence channel on an error.
- **Adapted, minor:** the vision's spelling is a METHOD (`b.text()`),
  bytes_blob's is a free fn in `@std/text` (`text_of(b)`). A method on a
  built-in type IS expressible — the `on_str` gate
  (`features/str_lit/check.av:59-61`, per bytes_blob §2.2) is the
  precedent. Recommend the method spelling for the two conversions and
  the free-fn spelling for hex/base64. Low stakes; state the choice.

**Agreed with bytes_blob:** §3.1's decode-is-Result, encode-is-total,
and its reuse of `@std/text`'s existing lead-byte walk
(`text.av:88-99`) as the validator body. That is the vision's "one
checkpoint" built out of an algorithm the tree already has.

## D5 — Does the vision's model make the empty-blob hazard better, worse, or irrelevant?

**IRRELEVANT BY CONSTRUCTION — and that is an argument FOR the fix, not
against it.** The vision's sequences carry an explicit length at every
level; a lens is a buffer plus an extent. There is no `strlen`, no
sentinel, and therefore nowhere for `str_len`'s `h->len == 0` fallback
(`:272-275`) to exist. The vision has no empty-blob hazard because it
has no measuring.

**ADOPT the fix (delete the `&& h->len` clause), and promote the
principle.** bytes_blob §2.3 and B1 are correct: the clause is
vestigial, every producer sets the length (`str_box` `:264-268`,
`read_whole` `:1357-1366`, `avra_int_text` `:495-499`, `str_owned`
`:1122-1127`, `str_static` `:302-308`, plus the backend's constants and
`bootstrap/seed.ll:6`), and for an empty `string` the header and the
fallback already agree at 0.

The vision names the LAW the fix is an instance of, and this tree has
now been bitten by it three times — `write_text` truncating on `strlen`
(commit `3c622be`), `str_len` distrusting a zero, and
`sqlite3_column_blob` answering NULL for empty (probe log §2a). The
probe log itself observes the pattern: "Empty is not a boring edge in
this tree; it is where the encodings collide."

**Steal it as a named law:** *A LENGTH IS CARRIED, NEVER MEASURED.*
See §5, S1.

**One sharpening the vision cannot give us:** it would make the hazard
WORSE if the views ever landed, because a view's payload pointer is
mid-box and `hdr` (`:68-73`) authenticates by alignment plus a four-byte
magic. See §4, T4.

## D6 — Does the vision already answer the "text with an embedded NUL" question?

**YES, decisively, and it agrees with the spec.** U+0000 is valid UTF-8.
A `string` in the vision is "always valid UTF-8", so a NUL-bearing
`string` is a perfectly legal `string`, and nothing in the model permits
an operator to stop at one. The question the campaign brief poses — "a
five-byte value reads EQUAL to its own two-byte prefix" — is, in the
vision's terms, a straightforward defect.

**ADOPT.** This settles a framing question in bytes_blob's favour and
strengthens it: the NUL-safety fix is NOT a prerequisite that `bytes`
pays for. It is a standing `string` bug that the vision, the spec
(spec:1475, "UTF-8 internally, always" — which admits U+0000), and the
tree's own `write_text` (`:1388-1390`, "a write reads the header's
length, never strlen") all already condemn. `bytes` merely makes it
urgent.

**The one thing the vision does NOT answer, and the SPEC DOES:** what a
NUL-bearing string does at the C boundary. Spec 15.6 (spec:3054): "*`CString.from` fails
only if the string contains embedded null bytes, in which case it
returns an error*", with `CStr` — pointer + length — as the infallible
alternative. **That is `avra_bytes_ptr` (bytes_blob §4.2) under a name
the spec already gave it.** See §5, S2 and §6.

---

# 4. CONFLICTS AND TRAPS

Adversarial. Each is a way one of the two designs breaks the other, or a
vision assumption the probe log has disproved.

## T1 — THE SSO CONFLICT. The spec mandates a layout that would void the design's central claim. **HIGH. This is the one that could sink it.**

Spec 9.15 (spec:1468-1474) decides:

> **(b) Heap + RC with small string optimization (SSO)** … A `string` is
> a 24-byte value on 64-bit systems. If ≤ 23 bytes, stored inline in
> those 24 bytes with a 1-bit discriminator.

**The tree did not build that.** A `string` is a pointer to a heap box
with a 16-byte header (`:56-61`), always, at every size; `ptr_shape`
answers true for `.Str` (`core/types.av:118-124`) and the whole memory
pass depends on it.

The vision leans on SSO for its slicing corollary ("a slice of a small
string is a sub-24-byte copy (free)"). The `bytes` design leans on the
POINTER model for its central claim — "a `bytes` box IS a string box"
(§2.1), `rides_pointer` answers true so "nothing in the memory pass
changes" (§5.1), and `avra_bytes_ptr` hands C the payload address
(§4.2). **If SSO ever lands to satisfy the spec, all three collapse
simultaneously:** a `string` would no longer be a pointer, `ptr_shape`
would answer differently for `.Str`, a small `bytes` could not hand C a
stable address, and "one layout" would be a claim about two different
machines.

**What to do:** the `bytes` design must name this and propose the
amendment, not route around it. The tree's header model is strictly
better for the campaign — an SSO string cannot cross to C without
materializing, which is the one thing every FFI row needs — and the
header model already delivers what SSO was chosen for (size classes and
free lists, `:83-88`, recycle a small box without malloc). File it: **9.15's
layout clause is superseded by the header model; SSO is deleted, not
deferred.** Until that is written down, `bytes` is built on a
representation the spec contradicts.

## T2 — THE `b"..."` TYPE CONFLICT, and an internal spec inconsistency. **HIGH.**

Spec 28.3 (spec:5570): "**Byte strings:** `b"..."` for byte literals
(type `List<u8>`)". That is exactly the representation bytes_blob §1.1
refuses on P4 grounds.

Worse, the spec disagrees with itself: 31.1 (spec:6236-6252) reserves
`i8`/`u8`/… for `systems { }` blocks, giving app level `int` and `uint`
only. So spec 28.3 offers an **app-level literal of a type app level
cannot name**. (Spec 6404 repeats it: `b'a'` typed `u8`.)

bytes_blob §5.1 notices the clash and defers the literal ("No literal
syntax in v1. Deliberate."), which sidesteps but does not resolve it.
**The spec is law; a silent divergence is not available.** File a spec
amendment with the campaign: `b"..."` types `bytes`, and 28.3 is
reconciled with 31.1. Otherwise the first person to write `b"\x00"` gets
a value the spec says is a `List<u8>`.

## T3 — THE KIND-FLIP FLIPS STATICS. A latent crash in a recorded optimization. **HIGH.**

bytes_blob §2.2 records a future zero-cost conversion: "a KIND FLIP on a
uniquely-referenced box (`rc == 1`, which `avra_array_shared` `:816-818`
already knows how to ask)". Ledger #29 marks it LOW and unbuilt. It is
also **unsound as worded**, and the reason is not obvious:

- `avra_array_shared` (`:816-818`) is
  `h != NULL && h->kind >= 0 && h->rc > 1` — it answers *shared*, so
  "not shared" is true for a STATIC box.
- A STATIC box's rc is **frozen at 1 forever**: `box_alloc` sets
  `h->rc = 1` (`:256`) and both retain and release return early on
  `h->kind < 0` (`:385`, `:402`, `:421`).
- So every string constant in the program — the backend's globals, the
  runtime's own words, argv, the environment (`str_static` `:302-308`) —
  passes an `rc == 1` uniqueness test.

Flipping a STATIC box to `KIND_BYTES` makes an immortal constant
refcounted and freeable, and the runtime's own header comment
(`:18-20`) says "A STATIC box is immortal: its header is read and never
written, so a constant may live in read-only memory" — so the flip may
also be a write to read-only memory.

**The guard must be `h->kind == KIND_STR && h->rc == 1`, never `rc`
alone.** bytes_blob's own `avra_io_taken_bytes` sketch (§5.2) gets this
right — it tests `h->kind == KIND_STR` — so the fix is to make §2.2
match §5.2. Write the kind test into the recorded optimization now,
while it is still prose.

## T4 — `hdr` IS A HEURISTIC, AND BLOBS ARE THE FIRST ATTACKER-CONTROLLED BYTES IN THE TREE. **MEDIUM-HIGH.**

`hdr` (`:68-73`) authenticates a box by three tests: 16-alignment, an
address above `0x100000000`, and the four bytes at `p-16` equalling
`0x41565241`. Until now every value in this tree had content the program
or the compiler authored, so a forged tag was not reachable.

**A blob is arbitrary foreign bytes.** A blob containing `41 56 52 41`
at the right alignment manufactures a valid-looking header for any
pointer sixteen bytes past it. Today nothing hands `hdr` a pointer INTO
a box — but `avra_bytes_ptr` (bytes_blob §4.2) exists precisely to
manufacture such a pointer and give it to C, and the probe log §6
establishes that a foreign pointer typed `string` **already reaches
`str_len`**, which calls `hdr`. Combine the two and a program can be
made to read a length out of database content.

**Consequence for the design:** B4 (refuse `-> string` / `-> bytes` on
an `extern fn`) is currently classified as hygiene — "SMALL-MEDIUM",
listed fourth. **It is the soundness gate on `avra_bytes_ptr` landing at
all.** Reclassify: `avra_bytes_ptr` does not ship before the extern-wall
refusal does. And `AVRA_RC_GUARD` cannot cover the gap — probe log §6:
"an untagged pointer raises none" — so there is no instrument behind the
rule.

## T5 — THE UTF-8 INVARIANT IS ALREADY VIOLABLE, so "never broken by construction" is false today. **HIGH.**

bytes_blob §3.1: "The row `avra_bytes_as_text` … is called ONLY after
the validator has said yes, so the UTF-8 invariant on `string` is never
broken by construction." **That is true of that door and false of the
house.** Two live paths produce an invalid `string` right now:

1. **`avra_str_substring` (`:1136-1142`)** clamps `lo`/`hi` to the byte
   length and never aligns to a codepoint boundary. `"αβγ".substring(0, 1)`
   mints a one-byte `string` holding half a codepoint. This is exactly
   the `29f3` bug the vision was written about (Part I: "can return
   **half a multibyte character** = invalid UTF-8 masquerading as a
   string"), surviving in a different verb.
2. **A foreign `const char*` typed `string`** — probe log §6, in the
   tree today as a permitted (if condemned) declaration.

So `text()`/`text_lossy()` cannot be advertised as "the ONE checkpoint"
without a decision:

- **(a)** state honestly that `string` is *UTF-8 by convention,
  unenforced*, and that the validator is a narrowing at one door — which
  costs the vision's iteration-speed payoff, a payoff nothing in this
  tree currently collects anyway; or
- **(b)** make `substring` codepoint-aligning, which is a
  corpus-visible semantics change and a separate slice.

The vision picks (b) by construction (typed cursors make the bad slice
unconstructable). The spec picks (a) implicitly (spec:1480, "`s[i]`
indexes by byte position and returns `u8`"). **The spec wins; say (a)
out loud** rather than claiming an invariant the tree does not hold.

## T6 — B2 mis-sizes the NUL fix. `replace` and `split` are not one-liners. **HIGH.**

B2 sizes the S0 slice from `starts_with` alone ("`memcmp` after a length
guard… **SMALL**"). But:

- `avra_str_replace` (`:1207-1230`) uses `strlen` on all three operands,
  `strstr` in two loops, and a terminating `strcpy(w, r)`. Every one is
  NUL-lossy.
- `avra_str_split` (`:1232-1251`) uses `strlen(sep)`, `strstr`, and
  `*r != '\0'` — and that last test **is** the documented
  trailing-empty-segment rule (CLAUDE.md, runtime facts: `"a."` splits
  to one element). A length-driven rewrite must restate that rule in
  terms of length or it changes observable behaviour.
- A length-driven search needs `memmem`, which is **not C-standard**
  (POSIX/glibc/macOS have it; the tree compiles its own runtime, so a
  small internal `mem_find` is the portable answer — and it is the ONE
  implementation D3 says should exist).

Size S0 as: one `mem_find` helper, six call sites, one behavioural
re-statement in `split`, plus corpus pairs. Not a one-liner.

## T7 — `avra_str_codepoint_count` is DEAD, NUL-LOSSY C waiting to be re-adopted. **HIGH.** (Not in the bytes report.)

`runtime/avra_runtime.c:1166-1173` walks `for (p = s; *p; p++)` — it
stops at the first NUL. It is in **no** `rt_sigs()` row
(`core/runtime_api.av:11-90`, read in full) and referenced nowhere else
in the tree; `@std/text`'s `codepoint_count` is a separate Avra walk
over `s.length` (`packages/std-text/src/text.av:97-99`) and is
NUL-safe.

Delete it in S0. Left standing, it is the obvious "fast path" for
someone to wire up later, re-importing precisely the bug the slice just
removed.

## T8 — THE LENS NAME IS A TRAP FOR THE COPY. **MEDIUM.**

If `bytes` lands as a distinct box (D2) and lenses are ever taken
seriously, `s.bytes` becomes sugar for `bytes_of(s)` — an **O(n) copy
wearing the vision's O(1) name**. `s.bytes.length` would then cost O(n)
where the vision promises O(1), which is the exact class of lie
("`.length` gets the same treatment… its own little lie") the vision
exists to kill.

**Reserve `s.bytes` and do not ship it.** bytes_blob's free-fn spelling
`bytes_of(s)` (§3) is right, and it is right *for this reason* — defend
it as deliberate rather than incidental, and record the reservation so a
later sugar slice cannot spend the name.

## T9 — "No bare `.length`" is dead on arrival, and should be declined loudly. **HIGH.**

Vision, Part II: "no bare `.length` on a string". Spec 9.15
(spec:1477): "`string.length` returns **byte count** by default (cheap,
O(1))." The tree implements the spec (`avra_str_len` `:1189-1191`), and
every std package reads it.

**THE SPEC WINS.** `bytes` giving `b.length` a header load (bytes_blob
§3, `avra_bytes_len`) is both spec-compatible and vision-compatible —
on `bytes`, "length" is unambiguous, which is the vision's whole
argument for why `s.bytes.length` was the acceptable spelling. Record
the decline so nobody re-litigates it in a later lane.

## T10 — The probe log has disproved the vision's nullable decode. **HIGH.**

The vision's `bytes.text() -> string?` spends the nullable channel on
"invalid UTF-8". The probe log establishes that a nullable pointer is a
**niche** — the null pointer IS absence
(`features/values.av:228-232`; probe log §2) — and derives the
campaign's own law from it: "a row answers an EMPTY BOX for empty, and
NULL only for ABSENT" (probe log §2b). An error is neither. bytes_blob's
`Result<string, TextError>` is the correct shape and the vision's is
not. Already handled in D4; listed here because it is a case where a
2026-06-30 assumption was measured false in 2026-09-05.

## T11 — The vision's persistent rope and the header model are mutually exclusive. **HIGH, and it is a DECLINE not a conflict.**

Part V, Move 6 proposes `string` as a persistent rope: "edits are
O(log n), value semantics, and old cursors/slices stay valid because
edits share structure." The tree's model is one contiguous box, one
refcount, no structural sharing (`:244-434`), and `avra_bytes_ptr`
(bytes_blob §4.2) hands C a **contiguous payload address** — which a
rope by definition cannot provide.

**DECLINE, permanently, for `bytes`.** What we lose: editor-grade text
with cheap edits. Why acceptable: nothing in this tree edits text (every
string op mints a fresh box today), and a rope would make FFI — the
campaign's entire subject — impossible without materializing. If a rope
ever lands it must be a *third* type, not `string` and not `bytes`.

---

# 5. WHAT SHOULD BE STOLEN REGARDLESS

Worth having even if `bytes` lands exactly as designed.

**S1 — "A LENGTH IS CARRIED, NEVER MEASURED."** Promote to a named law
in CLAUDE.md, beside the header law. It has three instances already:
`write_text` truncating on `strlen` (commit `3c622be`), `str_len`'s zero
fallback (`:272-275`, B1), and `sqlite3_column_blob` answering NULL for
a zero-length blob (probe log §2a). Three copies name the concept.
**Where:** CLAUDE.md's memory-law section.

**S2 — The `text()` / `text_lossy()` verb pair, and the spec's `CStr`
name.** Steal the vision's naming for the conversions (fallible verb +
total twin), and steal spec 15.6's `CString`/`CStr` split for the
boundary: `avra_bytes_ptr` IS `CStr` (pointer + length, borrows for the
call, infallible), and the fallible NUL-checking conversion IS
`CString.from`. The spec named these rows before the campaign invented
them. **Where:** `@std/text` for the first pair; the FFI research and
bytes_blob §4.2 for the second.

**S3 — One length-driven search, serving every sequence.** The vision's
`Seq` unification, narrowed to what this tree can hold: a single
internal `mem_find(hay, hn, needle, nn)` behind `contains`, `index_of`,
`replace`, `split` for `string` AND `bytes`. Not a protocol, not a
trait — one C helper and six call sites. **Where:** S0, and it is what
makes D3 a fix rather than a duplication.

**S4 — Typed string patterns (`h78d`, "the crown jewel").** The one
feature in the document that is pure sugar with a stated linear-time
guarantee and no representation dependency. Its wanting sites are
already in this campaign: a DSN/URI parse, `@std/json`'s scanner,
`@std/process`'s `which`. **Where:** ROADMAP sugar backlog
(`ROADMAP.md:3999`), naming those sites, per CLAUDE.md's dogfooding rule.

**S5 — `Tainted<T>` and `sql"…"` (Part V, Move 2).** A SQL driver is the
canonical customer for injection-as-a-type-error, and this campaign is
the cheapest moment in the project's life to STATE the ask — the wanting
site is being built right now. **Do not build it.** File it with the
site named. **Where:** ROADMAP, as a language ask against `@std/sqlite`.

**S6 — "Pay-for-what-you-use, never the default tax"** (the vision's
`IndexedString` escape hatch). This is the principle that justifies
`bytes` copying by default and recording the kind-flip as an
optimization rather than promising it. Steal the phrasing into
bytes_blob §2.2 — it converts a hedge into a stated design stance.

**S7 — `char` as a real type with `'a'` literals.** Not a vision ask —
**the SPEC already commits** (spec:5569, spec:6403-6404) and the tree has
none. It is what would make `b.at(i)` answering `int` (bytes_blob §3) a
temporary spelling rather than a permanent one, and what makes
`s.char_code() == 97` readable. **Where:** ROADMAP as a spec-backed gap,
sized independently of this campaign.

**S8 — Re-frame `bytes.zeroed(n)` as CONSTRUCTION, not mutation.** B3
concedes that "the design's immutability is bent". The vision's
invariant 3 — *construction is always O(n)*, the builder is a
first-class idea — gives the honest framing: `zeroed(n)` plus a
fill-through-`avra_bytes_ptr` is a **builder**, sound while the box is
uniquely referenced and never re-entered after it is published. That is
a rule a review can check and a comment can state. "Immutability bent"
is not. **Where:** bytes_blob B3 and §4.3.

---

# 6. THE POINTER-OPERATIONS DOC

`../forge-crafting-intepreters2/docs/spec_pointer_operations.md`, 463
lines, 14 TDD tests plus an implementation section.

**VERDICT: stale in form, PRE-EMPTIVE in exactly two rows,
CONTRADICTORY in its memory model, and SILENT on all three things the
campaign actually needs.** Cite it for the precedent; do not adopt it.

## 6.1 Stale in form

Its feature registration is a Rust macro —
`#[avra_feature(name = "Pointer Operations", … ast_nodes = [PtrIndex,
PtrIndexAssign, PtrOffset])` — so it is a **pre-clean-room artefact of
the old Rust compiler**. CLAUDE.md's rule applies at full strength:
"Follow the old tree's *documented designs*, never its code habits."
Its `avra run test_read.av` examples are also flatly contradicted by the
tree: `avra run` INTERPRETS and refuses any extern ("`<name>` is extern
— the evaluator cannot host it; build natively", probe log Part II).

## 6.2 It PRE-EMPTS two rows the campaign is inventing — and names them

| pointer-ops doc | campaign's row (bytes_blob) |
|---|---|
| `string.from_ptr(ptr, int) -> string` | `avra_bytes_from_host(p, n)` §4.1 |
| `ptr.from_string(string) -> ptr` | `avra_bytes_ptr(b)` §4.2 |

**This is corroboration, not conflict.** Two independent designs, years
apart, reached the same two boundary primitives — which is the strongest
available evidence that a foreign-region-to-box copy and a
box-payload-borrow are the irreducible FFI pair. Take the naming
precedent: **`bytes.from_ptr(p, n)`** and **`ptr.from_bytes(b)`**, which
inherit the old spelling while fixing its defect — the old rows answer
and consume `string`, which is exactly what probe log §6 and B4 condemn.

## 6.3 It CONTRADICTS the current memory model on three counts

1. **`ptr[i] = v` writes a byte through any pointer** (Tests 2, 3, 13;
   Implementation table). With the header model that is an unchecked
   write into a possibly-shared, possibly-STATIC box — it would let a
   program mutate a live `string` that other references hold, deleting
   the immutability every other part of this design rests on. Under T4
   it is also how a forged tag would get written.
2. **`ptr == ptr`, `ptr != ptr`, `ptr - ptr`** (Tests 9, 11) do not
   exist: a bare `ptr` has no equality today — probe log Part II,
   `F2000: '==' compares scalars for now`. Only `ptr?` has a null test.
3. **Test 13's `buffer_push` writes through `buf.data[buf.len]` on a
   non-`mut` `let`**, then returns `buf with { len: … }`. That is a
   mutation the current doctrine forbids on its face (CLAUDE.md's
   borrow/path-write law), and it is the shape that makes the immutable
   value a lie.

## 6.4 It is SILENT on all three campaign items

- **Out-params as `mut` seats:** absent. No `mut`, no `out`, no
  address-of anywhere in 463 lines. The campaign's first blocker (probe
  log, "THE OUT-PARAM IS A `mut` SEAT") is not addressed, not
  contradicted, not anticipated.
- **Opaque handles with a `free_with`:** absent. Its answer to lifetime
  is a hand-written `defer free(buf)` in every test — which is exactly
  what spec 15.5's compiler-managed opaque types exist to delete
  (spec:3025-3030: "wrapping a library like SQLite or libcurl normally
  requires careful `defer` pairings throughout user code").
- **Borrowed foreign buffers:** absent. `string.from_ptr` copies (that
  is its point) and `ptr.from_string` borrows with no lifetime story at
  all — the caller is trusted. Spec 15.4's `@borrows`/`@returns_borrowed`
  vocabulary post-dates it and supersedes it.

## 6.5 What to take, and the split it implies

- **Its null diagnostic (Test 10).** A `ptr` deref on null "should panic
  with a clear error, not segfault", rendered with a span and the words
  "buf is null". That is the right shape for `bytes.at(i)`'s trap and
  for a handle deref, and it matches the tree's existing trap wording
  discipline (`avra_str_char_code` `:1177-1187`).
- **Its trajectory.** "When `systems` blocks ship, pointer operations
  become restricted" agrees with spec 2.1 (soundness is a boundary
  property) and spec 31.1 (sized ints are systems-level). That gives the
  campaign the consistent split: **`bytes.at(i)` and `b.length` stay
  app-level and safe; raw `ptr[i]` and `ptr + n` are a systems-level
  future the campaign must NOT depend on.** `avra_bytes_ptr` is not
  pointer arithmetic — it is a single borrow handed straight into a
  `bind` call in the same expression (bytes_blob §4.2, consequence 5),
  and it should be defended as that, not as a first step toward this
  doc.

---

# CONFIDENCE LEDGER

| # | Claim | How verified | Confidence |
|---|---|---|---|
| 1 | The vision contains `bytes` as a peer type with honest O(1) integer indexing | read `2026_06_30_STRINGS_FROM_THE_FUTURE.md` Part II, "The collapse"; quoted | HIGH |
| 2 | The vision's text↔bytes boundary is `bytes.text() -> string?` / `bytes.text_lossy() -> string` | read Part III, invariant 1; Part IV, "The bytes→string boundary"; quoted | HIGH |
| 3 | The vision declares itself a proposal subordinate to the FULL_SPEC | read its status block, lines 1-10; quoted | HIGH |
| 4 | Spec 9.15 mandates SSO: a 24-byte string value, ≤23 bytes inline | spec:1468-1474, quoted | HIGH |
| 5 | The tree's `string` is a pointer to a 16-byte-headered heap box at every size | read `runtime/avra_runtime.c:56-73, 244-268`; `core/types.av:118-124` | HIGH |
| 6 | Spec 9.15 mandates `.length` = byte count and `s[i] -> u8`, contradicting the vision's "no bare `.length`" and "`s[i]` is an error" | spec:1477-1482, quoted | HIGH |
| 7 | Spec 28.3 types `b"..."` as `List<u8>` while 31.1 makes `u8` systems-level-only — an internal spec inconsistency | spec:5570; spec:6236-6252; spec:6404 | HIGH |
| 8 | Spec 15.6 already specifies the fallible NUL-checking string→C conversion and the infallible pointer+length one | spec:3034-3054, quoted | HIGH |
| 9 | `starts_with` is NUL-lossy (`strncmp`); `ends_with` is not (`memcmp`) | read `:1148-1157` | HIGH |
| 10 | `replace` and `split` use `strlen`+`strstr`+`strcpy`, so the S0 fix is larger than B2 states, and `split`'s trailing-empty rule IS its `*r != '\0'` test | read `:1207-1251`; behaviour cross-checked against CLAUDE.md's runtime facts | HIGH |
| 11 | `avra_str_codepoint_count` (`:1166-1173`) is NUL-lossy and in no `rt_sigs()` row and referenced nowhere else in the tree | read `:1166-1173`; read `core/runtime_api.av:11-90` in full; grepped the whole worktree for the symbol — one hit, its definition | HIGH |
| 12 | A STATIC box's rc is frozen at 1, so an `rc == 1` uniqueness test passes for every constant | read `box_alloc` `:256`; retain/release early returns at `:385, :402, :421`; `avra_array_shared` `:816-818` | HIGH |
| 13 | `hdr` authenticates by alignment + address floor + a four-byte magic only | read `:68-73` | HIGH |
| 14 | A blob is the first value category whose CONTENT is foreign/attacker-controlled, so a forged tag becomes reachable | inference from #13 plus `avra_bytes_ptr`'s existence (bytes_blob §4.2) and probe log §6's foreign-pointer-reaches-`str_len` path | MEDIUM — reasoned, not probed; the mechanism's parts are each HIGH |
| 15 | `avra_str_substring` clamps byte offsets and never aligns to a codepoint boundary, so an invalid `string` is constructible today | read `:1136-1142` | HIGH |
| 16 | Interpolation is pre-sized and lowers to ONE `avra_str_join` — the vision's "construction is always O(n)" is effectively built | read `features/str_lit/lower.av:8-21`; `avra_str_join` `:997-1015` | HIGH |
| 17 | Every string operation mints a fresh box; nothing mutates a string in place | read the string section `:1136-1259`; no mutating string row in `rt_sigs()` | HIGH |
| 18 | A slice copies, and the header has no room for an offset | read `avra_str_substring` `:1136-1142` (calls `str_owned`); header `:56-61` is fully allocated | HIGH |
| 19 | `@std/text`'s `codepoint_count` is a length-driven Avra walk and is NUL-safe | read `packages/std-text/src/text.av:88-99` | HIGH |
| 20 | A nullable pointer is a niche; the campaign's law is empty-box-for-empty, NULL-for-absent | `features/values.av:228-232`; probe log §2, §2a, §2b | HIGH |
| 21 | The pointer-ops doc registers a Rust feature macro and its `avra run` examples are refused by this tree | read `spec_pointer_operations.md` Implementation section; probe log Part II's `avra run` refusal | HIGH |
| 22 | The pointer-ops doc contains no out-param, no opaque handle, and no borrow-lifetime vocabulary | read all 463 lines; its only `mut` uses are local bindings (`mut i`, `mut total`), its only lifetime story a hand-written `defer free` | HIGH |
| 23 | The pointer-ops doc's two bridge functions are the campaign's two boundary rows under different names | read its Implementation "Bridge functions" table against bytes_blob §4.1-4.2 | HIGH |
| 24 | Escape analysis is not built in this tree | absence of any such query in the memory pass; not exhaustively searched | MEDIUM |
| 25 | bytes_blob's `avra_io_taken_bytes` restamp is safe where the §2.2 kind-flip is not, because it tests `KIND_STR` | read bytes_blob §5.2 against §2.2 and #12 | HIGH |
| 26 | Erlang sub-binaries retain the parent, the argument against views | bytes_blob ledger #20, not independently re-verified this session | MEDIUM |

**Nothing in this report was verified by running anything.** Read-only
by instruction: no `make`, no `./avra`, no build, no gate. Every "read"
is a source read; every spec citation is a line in
`2026_04_18_FULL_SPEC.md`; every vision quote is copied from
`2026_06_30_STRINGS_FROM_THE_FUTURE.md`.

The probes this reconciliation implies, in order: (1) a NUL-bearing text
through `==`, `contains`, `replace` and `split`, both engines; (2)
`"αβγ".substring(0, 1)` printed as bytes, to pin T5; (3) a `bytes` box
minted empty, its `.length`, to pin B1; (4) a STATIC box through
whatever uniqueness predicate the kind-flip eventually uses, to pin T3.
