# `Bytes` — THE SHAPE, for lane A's review

> **Status:** a shape, not a patch. Written for lane A, who owns
> `runtime/` and `core/`, against the three kind-aware sites they named.
> Nothing here has been implemented and no file of theirs has been
> touched. Every runtime claim below was re-read in
> `runtime/avra_runtime.c` under this lane's own hand before writing.
>
> **The problem it solves:** SQLite's BLOB has no home. `string` holds
> arbitrary bytes — the header carries the length — but `==`,
> `contains`, `index_of`, `replace` and `split` are C string calls, so a
> blob compares EQUAL to its own truncation at the first NUL.

---

## 1. WHY `Bytes` NEVER REACHES `box_clone` — STRUCTURAL, NOT MORAL

`box_clone` (`runtime/avra_runtime.c:988`) is a two-arm dispatch whose
`else` assumes ARRAY —

```c
return (h && h->kind == KIND_MAP) ? map_clone((AvraMap*)p) : array_clone((AvraArray*)p);
```

— so a `Bytes` box reaching it is read as an `AvraArray`: `cap`, `len`,
`data`, `owned` decoded from raw payload bytes, then a walk over a wild
pointer.

**THE FIRST DRAFT OF THIS SECTION ARGUED FROM IMMUTABILITY. THAT WAS THE
WEAKER ARGUMENT AND IT IS WITHDRAWN.** The real reason is structural, and
lane A MEASURED it rather than reasoning about it: a probe placing
strings everywhere the copy-on-write path could plausibly find them — a
string in a `mut` cell reassigned, a string element written by index, a
string field, a string field nested two levels down, a map of strings
written through — emits **seven `cell_unique`/`slot_unique` calls, and
every one takes a LIST, a STRUCT or a MAP. Not one takes a string.**
Corroborated across the corpus: `corpus/places.av` produces 15 uniques,
`corpus/strs.av` produces zero. Even `r.tag = "u"`, which writes a string
INTO a slot, uses `slot_set_owned` — retain the new, release the old,
never clone. And `mut s = "abc"; s = "def"` emits no unique at all; it is
a plain `Store`.

**THE MECHANISM.** `box_clone` has exactly two callers,
`avra_cell_unique:827` and `avra_slot_unique:840`, and both are emitted
only for a place step that CONTINUES — `cell_unique` opens a root about
to be indexed or field-accessed, `slot_unique` opens an intermediate slot
for the same reason. **The FINAL step of every place is a SET**
(`slot_set`, `slot_set_owned`, `map_set`, or a `Store`) — never a unique.

Therefore: **a value with NO PATH SYNTAX can never be an intermediate
step, and so can never be an argument to either unique.** That is why
strings are safe, it has nothing to do with immutability, and it holds
for `Bytes` for exactly the same reason.

### The proof obligation — and the one this document first wrote was wrong

The first draft asked for *"a test that a `Bytes` in a `mut` cell cannot
be written through."* **That test proves nothing.** A `Bytes` in a `mut`
cell being written through is `b = other`, which lowers to a `Store`,
which is safe now and always will be. It never approaches `box_clone`.

**THE REAL OBLIGATION, checkable at the moment the feature is written:**
*does any grammar rule admit `Bytes` on the left of an INDEXED or FIELD
assignment* — `b[i] = x`, `b.f = x`? If no rule produces that,
`box_clone` is unreachable BY CONSTRUCTION, and the property is asserted
against the feature's own gram fragment rather than against a runtime
behaviour. It fails loudly the day someone adds indexing, which is
precisely the day it should.

**THE TRIGGER, reworded.** Not *"the day a mutable blob is wanted"* —
those are not the same day. A blob builder that answers a FRESH `Bytes`
each time is mutable in spirit and still never touches `box_clone`. The
trigger is **the day `Bytes` gains ASSIGNABLE PATH SYNTAX**. On that day
`box_clone` grows a `KIND_BYTES` arm BEFORE the first such write lands,
because the failure mode is heap corruption with no diagnostic,
discovered on whichever allocation next reuses the class.

*And the driver never asks for it:* a column read mints a fresh box, a
bind hands one over, and incremental blob I/O writes through SQLite's own
`sqlite3_blob_write`, never through an Avra buffer.

## 2. THE REPRESENTATION: the string's box, a distinct kind

Same layout, same allocator, same refcount path, same reclaim arm.
**A distinct `KIND_BYTES` tag, and its own length accessor.**

What "shares the box" does NOT mean, since one sentence was doing two
jobs badly in an earlier exchange: it does not mean sharing
`str_len`'s LENGTH PATH. That path's fallback is `strlen` and `Bytes`
must never go near it.

**Allocation shape: `n + 1`, exactly as `str_box` does, with the byte at
`[n]` lying outside the recorded length.**

This reverses a position this lane sent lane B earlier — that allocating
a byte which is not part of the value is "a lie about the
representation". The reversal has a reason and the earlier argument was
answering a different question. That byte is not a terminator anyone
READS: `Bytes` length is the header's, authoritatively, always. It is
there so the size-class arithmetic in §3.1 is BYTE-IDENTICAL to a
string's, and so the empty case dissolves rather than becoming a fourth
special case. Writing a NUL into it costs one store and means a
`Bytes` that happens to hold text can be handed to a C function that
wants a terminator, which the wall will eventually want.

## 3. THE THREE KIND-AWARE SITES

### 3.1 `box_bytes` (`runtime:280`) — JOIN THE `+1` ARM

```c
static size_t box_bytes(Header* h) {
    return h->kind == KIND_STR ? (size_t)h->len + 1 : (size_t)h->len;
}
```

This recovers the ALLOCATION size so `box_free` can compute the size
class. **`KIND_BYTES` joins the `KIND_STR` arm.** Miss it and
`class_of` picks the wrong class, the buffer is filed on the wrong free
list, and the next allocation of that class gets a short buffer — heap
corruption, no diagnostic, not reproducible until the class is reused.

**WHY THE `n+1` SHAPE IS LOAD-BEARING HERE, and why the obvious
alternative is a trap.** `box_alloc:245` reads

```c
size_t bytes = size > 0 ? size : 1;
...
h->len = (uint32_t)bytes;
```

so `box_alloc(0, …)` ALLOCATES 1 AND RECORDS len = 1. A `Bytes` that
allocated exactly `n` and then corrected its own length to 0 would have
`len = 0` against an allocation of 1 — and `box_bytes`'s `else` arm
would answer 0 while `class_of` was given 1. **The empty blob would free
into the wrong class.** That is the empty case turning into a
heap bug, which is the fourth time in this campaign that an empty value
is where an encoding loses information. The `n+1` shape removes it:
`n = 0` allocates 1, records len = 0, and the `+1` arm answers 1 —
correct.

### 3.2 `str_len` (`runtime:274`) — THE FIX I HAD WRONG

Current, and correct today only by convention:

```c
return (h && h->len) ? h->len : strlen(s);
```

**This lane previously proposed `h ? (size_t)h->len : strlen(s)` and
that is WRONG.** It would trust `h->len` for ANY box — and a
`KIND_ARRAY` or `KIND_MAP` box's `len` is its PAYLOAD BYTE SIZE
(`sizeof(AvraArray)`, `sizeof(AvraMap)` — tens of bytes), not a text
length. The unconditional form removes a safety property instead of
adding one. The predicate must be the KIND (lane A's form):

```c
return (h && (h->kind == KIND_STR || h->kind == KIND_STATIC)) ? h->len : strlen(s);
```

That trusts a zero length for a real string — which is the empty-string
fix, measured behaviour-preserving eight ways on both engines — and
refuses to trust a byte-size for a box that never carried text.

**AND `Bytes` DOES NOT APPEAR IN IT.** It gets its own accessor, whose
answer is the header's length unconditionally, with no fallback at all:
a `Bytes` box always has an authoritative length, and a non-box is not a
`Bytes`.

### 3.3 `box_clone` (`runtime:988`) — NOT REACHED, BY CONSTRUCTION

Discharged in §1 by immutability, with the trigger recorded for the day
that changes.

## 4. THE STANDING ASYMMETRY, INHERITED AND NAMED

`KIND_STATIC` boxes allocate `n+1` and store `len = n`, so `box_bytes`
under-reports them by one. That is harmless **only because static boxes
are immortal**: `avra_rc_release:421` returns early on `kind < 0`, so
`box_free` never sees one. *Safe by immortality, not by arithmetic.*

**Consequence for this design:** if `Bytes` ever gets a STATIC or
BORROWED flavour — and the FFI will want one, for a blob the program must
never own — the same asymmetry is waiting, and that flavour must either
be immortal in the same way or carry its own arm. Recorded before it is
built. (Lane A's warning; kept in their words because the phrasing is
the finding.)

## 5. THE OPERATIONS

Slice one, and deliberately short:

| verb | shape | note |
|---|---|---|
| `.length` | header load | authoritative, no fallback, no `strlen` |
| `==` | `memcmp` over both lengths | lengths first, then bytes. **The whole point** — this is what `string` cannot do |
| index / slice | header-bounded | slice mints a new box |
| `+` | allocate, two memcpys | |
| `.text()` | `Result<string, TextError>` | FALLIBLE — validates UTF-8 |
| `.bytes()` on a string | total | a string is always valid bytes |
| hex / base64 | Avra-level | not runtime rows |

NOT in slice one: `split`, `replace`, `contains`, `index_of`. They are
the NUL-lossy five, and a blob wants byte-search semantics that differ
from text's. They arrive with a measured need, not speculatively.

## 6. THE SQLITE BOUNDARY

**Reading.** `sqlite3_column_blob` returns a pointer valid only until the
next `step`/`reset`/`finalize`, so the driver COPIES at the boundary into
an owned box. And it never tests that pointer to decide what it found:
NULL means SQL NULL, a zero-length blob, OR an out-of-memory
(`sqlite3.h:5411`, `:5519-25`), so `sqlite3_column_type` is asked FIRST
and the class decides.

**Binding — AND THE LANGUAGE CURRENTLY MAKES THE UNSAFE CALL EASY AND
THE SAFE CALL IMPOSSIBLE.** `sqlite3_bind_blob(stmt, i, ptr, n, dtor)`
takes an explicit length, so a blob never needs a terminator. The
destructor seat is where the danger is, and the two constants are
verified in the vendored header:

```c
#define SQLITE_STATIC      ((sqlite3_destructor_type)0)     /* sqlite3.h:6429 */
#define SQLITE_TRANSIENT   ((sqlite3_destructor_type)-1)    /* sqlite3.h:6430 */
```

`SQLITE_STATIC` **is the null pointer.** And a `ptr?` extern seat takes
`null` today, emitting `ptr null` — no capability needed, nothing to
land. So the moment out-params exist, every `sqlite3_bind_*` is callable
**with the STATIC destructor and nothing else.**

That is not a free win. The header states the contract
(`sqlite3.h:4946-4950`): under `SQLITE_STATIC` *"the application remains
responsible for disposing of the object … the object and the provided
pointer to it must remain valid until either the prepared statement is
finalized or the same SQL parameter is bound to something else."* An
Avra box bound that way and released before `step` is a **use-after-free
inside SQLite**, at a site with no relationship to the bind.

`SQLITE_TRANSIENT` — which COPIES, and is therefore the safe default —
is `(void*)-1`.

> **DISCHARGED 2026-09-06 at `f7a8bba`.** This section said the safe
> sentinel was **unspellable**, on three clauses: "`ptr` is
> receive-only", "there is no int->ptr mint", and "`let p: ptr = 0` is
> F2024". **The first two are now FALSE.** `avra_ptr_at(address: int)`
> landed on the owner's word and works at both `-> ptr` and `-> ptr?`;
> probed at `91b6b61`, binary 2026-09-06 00:17, `./avra check` exit 0
> on `fn transient() -> ptr { avra_ptr_at(0 - 1) }`. Only the third
> clause still holds, which is why the page still READ as current.

**So the finding this section is built on — THE EASY CALL IS THE
DANGEROUS ONE AND THE SAFE CALL CANNOT BE WRITTEN — is half
discharged.** The `SQLITE_STATIC` use-after-free hazard is unchanged
and real: a pointer lent to SQLite that Avra frees first is a read of
freed memory inside SQLite, invisible to our refcounter because the
pointer is not ours to count. What has changed is that the SAFE side is
now expressible, so the INVERSION is gone.

**Consequences, restated on current facts:**
1. The named mint was indeed a prerequisite of binding a single value,
   and it has landed. The lowering guard remains the interlock that
   stops a pointer constant being silently discarded.
2. ~~Until then the driver must not offer a bind at all~~ — **LIFTED.**
   The driver ships binds with **TRANSIENT as the default** and STATIC
   as a named hatch carrying its contract at the site (P8 requires the
   hatch; it is never what you get by omitting an argument). The
   reasoning survives the lift: the refusal existed because the only
   REACHABLE mode was the unsafe one, not because binding is unsafe.
   *A hazard documented at a verb the caller can reach is a hazard
   shipped* still stands — which is why STATIC is spelled, not defaulted.*
3. `SQLITE_STATIC` becomes legitimate later — with `@borrows`, which
   makes "the box outlives the statement" a claim the compiler checks
   rather than a comment, and which is what lets a 10 MB blob stop
   costing a 10 MB copy.

## 6b. A FOURTH KIND-AWARE SITE, not in lane A's three — and it lies quietly

```c
static int acc_kind_of(int32_t kind) {
    return kind == KIND_ARRAY ? ACC_LIST : kind == KIND_MAP ? ACC_MAP
         : kind == KIND_STR ? ACC_STR : ACC_RECORD;      // runtime:234-236
}
```

A chain whose CATCH-ALL is `ACC_RECORD`. A `KIND_BYTES` box would be
silently filed as a RECORD in `AVRA_MEM_STATS` — the instrument this tree
reaches for when it asks where memory went, and the one that found the
first refcount leak no reading had caught.

Nothing crashes. The accounting just answers the wrong category, for the
one value category whose whole job is carrying LARGE payloads. A driver
moving a hundred megabytes of blobs would report it under records, and
the person debugging that would be reading a lie from the tool of record.
**It needs `ACC_BYTES`**, not a reuse of `ACC_STR` — text and blobs are
exactly the two things you would want told apart when a database is the
thing under memory pressure.

*This is the same shape as `box_bytes`: a kind-keyed chain whose default
was correct for every kind that existed when it was written.*

### And one catch-all that is RIGHT, which must be said rather than assumed

`avra_rc_release`'s reclaim dispatch (`runtime:426-433`) is
`KIND_ARRAY → array_reclaim`, `KIND_MAP → map_reclaim`, `else →
box_free`. A `Bytes` box has no children to release, so **the catch-all
is the correct arm and no edit is needed.** CLAUDE.md's registry doctrine
says a catch-all over our own enums silently forgets the next variant —
here it does not, because the arm is "a box with nothing inside it",
which is a real category and not an oversight. **Stating that is the
point:** the difference between this site and `acc_kind_of` is that one
catch-all means *"nothing further to do"* and the other means *"and
everything else is a record"*. Only the second is a bug, and only a
reader who checked both can tell you which is which.

## 7. LANDING CHECKLIST

File by file, in dependency order, for line-by-line review. **Every
runtime line number below was read in this worktree.** Lane A owns items
1–2, lane C owns items 3–4, and the rest routes as marked.

### 1 — `runtime/avra_runtime.c` (lane A)

| # | site | edit |
|---|---|---|
| 1.1 | `:48` the kind enum | add `KIND_BYTES = 4`. **Appends** — nothing serialises the ordinal today, but appending costs nothing and insertion could |
| 1.2 | beside `str_box:264` | `bytes_box(n)` — `box_alloc(n + 1, KIND_BYTES)`, then set `len = n`. The `n+1` is NOT a terminator, it is what makes 1.3 correct (§3.1) |
| 1.3 | `box_bytes:280` | `h->kind == KIND_STR \|\| h->kind == KIND_BYTES ? len + 1 : len`. **The size-class witness. Miss it and an empty blob frees into the wrong class** |
| 1.4 | `str_len:274` | kind-predicated (§3.2). Fixes the zero-length wart for text at the same time; premise measured eight ways, both engines |
| 1.5 | `acc_kind_of:234` | add `ACC_BYTES` (§6b) — **without it every blob is accounted as a record** |
| 1.6 | `avra_rc_release:426` | **NO EDIT.** The `else → box_free` arm is correct: a `Bytes` box has no children. Recorded so a reviewer does not "fix" it |
| 1.7 | new rows | `avra_bytes_len`, `avra_bytes_eq` (`memcmp` over both lengths, lengths compared first), `avra_bytes_at`, `avra_bytes_slice`, `avra_bytes_concat`, `avra_bytes_of_str`, `avra_str_of_bytes` |

**1.7's fallible row — ANSWERED (lane A).** The pattern exists but is a
CONVENTION rather than a mechanism, which is why it did not turn up as
one: `avra_str_index_of` answers `-1` on a miss, `avra_proc_run` a
NEGATED ERRNO, `avra_map_get_owned` the null pointer, and when a REASON
is wanted it is a SECOND ROW (`avra_errno_text` turns the code into
words). **Integer rows answer a negative; pointer rows answer null; a
reason is another row.**

**And there is no `Result`-answering row anywhere, nor should there be.**
A `Result` is a tagged box — tag at slot 0, value at slot 1 — so a C body
constructing one would have to know Avra's enum layout. *That is exactly
the coupling the boundary exists to prevent.*

So: **`avra_str_of_bytes` answers `Ptr`, null meaning "not valid UTF-8",
and the AVRA side turns null into `.Err(…)`.** C stays ignorant of the
enum; Avra builds its own `Result`. If a caller needs WHERE it failed,
that is a second TOTAL row — `avra_utf8_bad_at(bytes) -> int`, the byte
offset or `-1` — following `errno_text`'s precedent exactly. **Never
answer the value and the reason in one row**; nothing in the tree does,
and the two options this document first listed collapse into this one.

*Preferred over validating in Avra above a total row, and not for speed:*
Avra-side validation needs a byte-accessor row anyway, so a row is added
either way — and the C version keeps the scan where the bytes already
are.

### 2 — `core/runtime_api.av` + `core/ir.av` (lane A)

- 2.1 an `rt_sigs` row per 1.7 verb, `owns_result` set honestly — `len`,
  `eq` and `at` own nothing; `slice`, `concat` and the two conversions
  own their answer.
- 2.2 an `RtHost` variant per row.
- 2.3 **`RtKind` is untouched.** A `Bytes` crosses as `Ptr`.

### 3 — `language/interp.av` (lane C)

- 3.1 one `rt_dispatch` arm per `RtHost` variant. Mechanical, and the
  dispatch is exhaustive so the compiler names every one it is owed.
- 3.2 **no `Val` variant.** A `Bytes` is a managed pointer like a string.

### 4 — `core/types.av` + typing (lane C)

- 4.1 the `Bytes` type; `rides_pointer` TRUE (so `Bytes?` is
  niche-encoded and costs what `Bytes` costs); `is_managed` joins.
  **CHECKED, and the hazard is already discharged:** lane A asked
  whether `opt_ll_type` and `opt_rides_pointer` could disagree — a
  nullable that thinks it rides a pointer while its inner type does not
  takes the two-field `{ i1, T }` shape, and the two engines would then
  encode absence differently. They cannot disagree. There is ONE
  definition, `TypeRegistry.opt_rides_pointer` (`core/types.av:192`,
  `self.rides_pointer(inner) || self.is_flat(inner)`), and
  `opt_ll_type` (`language/llvm.av:222-223`) ASKS IT rather than
  re-deriving it. So telling the single predicate about `Bytes` — which
  is what `rides_pointer` TRUE does — is inherited by both readers at
  once. *One predicate, two readers, no second copy: the shape that did
  NOT bite us, worth recording beside the ones that did.*
- 4.2 **no implicit conversion in either direction.** A `string` is not
  a `Bytes` and a `Bytes` is not a `string`; the two verbs in §5 are the
  only crossings, and one of them is fallible.
- 4.3 F2001's help grows `Bytes`.
- 4.4 **the grammar assertion from §1** — no rule admits `Bytes` on the
  left of an indexed or field assignment, which is what keeps
  `box_clone` unreachable by construction.

### 5 — the value protocol (core event)

`bytes_of`, added AT THE SECOND READER and never at the first — CLAUDE.md's
rule, and the reason `Int` has no projection today.

### 6 — tests, in this order

1. **THE EMPTY BLOB FIRST.** It is where the encodings collide, four
   times over in this campaign. `.length` is 0, it is not `null`, it
   round-trips, and it frees without corrupting the class.
2. A NUL in the middle — `==` must not truncate. **This is the whole
   reason the type exists.**
3. A blob holding the fixture file's own bytes, read through the io seam.
4. `Bytes` vs `string` inequality, both directions, no coercion.
5. Under `AVRA_RC_GUARD=1`, small programs only.

**The instrument is a FIXTURE FILE holding NULs**, read through io —
`from_codepoint(0)` refuses (`ROADMAP:5987`), and a fixture tests the
path that actually matters: bytes crossing from OUTSIDE. A zero-length
file gives test 1 for free. (Lane A's suggestion.)

### 7 — downstream

- `@std/io` grows `read_bytes`/`write_bytes` — lane B has offered and is
  waiting on this shape.
- The driver's `SqlValue.Blob` and `Cells.blob_at`.

### The two prerequisites this checklist does NOT contain

- **The lowering guard** for a non-zero pointer constant — LANDED by the
  FFI lane, gated, and proven to fire. It is a prerequisite of *binding*
  a blob (`SQLITE_TRANSIENT`), not of the type existing.
- **A mintable `ptr`** — same dependency, same reason.

**THE TEST INSTRUMENT, since `from_codepoint(0)` refuses
(`ROADMAP:5987`):** a FIXTURE FILE holding NULs, checked into the test
tree and read through the io seam. It needs no new minting primitive, it
exercises the path that actually matters — bytes crossing the boundary
from OUTSIDE — and a zero-length file gives the empty case for free.
(Lane A's suggestion.)

---

## Confidence ledger

| claim | how verified |
|---|---|
| `box_bytes` is the size-class witness, `+1` for `KIND_STR` | read at `runtime/avra_runtime.c:280` |
| `box_alloc(0,…)` allocates 1 and records len 1 | read at `:245-247` — this is what forces the `n+1` shape |
| `str_len` trusts a non-zero header length only | read at `:274` |
| an array/map box's `len` is its payload byte size | `box_alloc` sets `len` from the allocation size; `avra_array_new` allocates `sizeof(AvraArray)` |
| `box_clone`'s `else` assumes ARRAY | read at `:988` |
| its only callers are the copy-on-write path | `:827` `avra_cell_unique`, `:840` `avra_slot_unique` — both read |
| a static box is never freed | `avra_rc_release:421` returns early on `kind < 0` |
| an empty string answers 0 eight ways | run, both engines, this worktree |
| `sqlite3_column_blob` returns NULL for three distinct conditions | `sqlite3.h:5411` and `:5519-25`, quoted |
| `Bytes` never reaches `box_clone` | **MEASURED, and no longer the weak claim it was.** Lane A's probe put strings in every shape the copy-on-write path could find — a `mut` cell reassigned, an element by index, a field, a field nested twice, a map written through — and read the IR: seven `cell_unique`/`slot_unique` calls, every one taking a LIST, STRUCT or MAP, none a string. `corpus/places.av` 15 uniques, `corpus/strs.av` zero. The mechanism: both callers are emitted only for a place step that CONTINUES, and every place's FINAL step is a set, so a value with no path syntax cannot be an intermediate step. HIGH. |
| the proof obligation | REWRITTEN — the first draft's test (a `Bytes` in a `mut` cell written through) proves nothing, because that is a `Store`. The real one is a grammar question: does any rule admit `Bytes` on the left of an indexed or field assignment? Assertable against the gram fragment. |
