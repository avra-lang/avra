# Reuse in place

A value that dies at an operation lends the operation its box. Tracker:
epic avra-8sb5.34.

## §0 Decisions

**D1. Text and octets are ONE representation.** A `string` box and a
`Bytes` box were already the same layout — length in the header, a
spare NUL after the content — and only the header's kind differed,
which nothing but the memory accounting reads. So `.bytes()` and a
valid `.text()` answer the SAME box with one more reference: no copy,
no liveness proof, sound because both values are immutable. The kind
records how the box was minted; `box_bytes` and every reader treat the
two alike. (P6: "share one representation" vs "copy for safety" was a
false choice — immutability made sharing safe all along.)

**D2. An empty side is the other side.** `a.concat(empty)`,
`empty.concat(b)`, `a + ""` and a whole-length `slice` answer the
non-empty operand shared. Immutable, so indistinguishable from a copy.

**D3. The mechanism is a registry column, not IR.** A row with
`has_reusing_twin` has a twin `<name>_reusing` whose FIRST SEAT IS
CONSUMED: the compiler hands it a reference it owns and never reads
again. No `Ins` variant was added — `CallRt` already says "call this
row"; the twin is a different row, and every pass reads the
instruction exactly as before (the IR growth protocol's rule 5).

**D4. The compiler decides WHEN a value may be handed over; the
runtime decides WHETHER its box may be written.** The twin writes in
place only when the box's count is 1 and it is not immortal; otherwise
it makes the fresh answer and releases what it was handed. So a
compiler proof covers the UNCOUNTED aliases (views, borrows) and the
count covers every counted one (a list, a record field, a capture, a
cell, a snapshot).

**D5. Two hand-overs.**
- `Owned` — the first seat is a register the INNERMOST open scope owns
  and that dies at the call. The scope drops its entry; the twin owns
  the reference.
- `Emptied(slot)` — the first seat is a BORROW of a `mut` cell (the
  accumulator `s = s + x`, `out = out.concat(ys)`). The pass emits
  `avra_cell_forget(slot)` before the call: the cell's own reference
  moves to the twin, and the store after refills the cell.

**D6. A store MOVES a dying value into its cell** instead of retaining
it and releasing it at scope exit. Without it back-to-back growth in
one scope (`s = s + a` then `s = s + b`) would find the box counted
twice (cell + scope) and copy.

**D7. `with` lowers to a whole-record slice plus slot writes**
(boxed records; a flat record still packs). The slice IS the copy, so
`avra_array_slice_reusing` serves `with` and list `slice` alike — one
twin, two sources (P17).

**D8. The evaluator keeps copying.** It ignores `Retain`/`Release`,
so each twin is hosted by its base row's arm; `avra_cell_forget` by
`CellRelease`'s no-op. Answers are identical by construction.

**D9. `style.quadratic_growth` now names only PLACES.** A local `mut`
grows in place, so the lint fires only when the grown thing is not a
bare name (`self.out = self.out + t`). 17 of its 19 baseline sites
were locals and retired; the 2 left are real (std-process).

## §1 The rule "r dies at `at`"

1. `r` is read at `at` exactly once (never in two seats), and never
   after `at` in the body's stream.
2. No VIEW of `r` — a register riding `r`'s reference, found by
   `view_of`, transitively — is read at or after `at`. A read that
   took its owned twin holds its own reference and is not a view.
3. `Owned` additionally: the innermost open scope owns `r`. That is
   what keeps a value defined outside a loop or branch from being
   consumed once per turn or on one path only.
4. `Emptied` additionally: `r` is a `Load` of a cell that did not earn
   its own retain (`borrow_outlives` false); every bracket opened
   between the load and `at` has closed (`level_with`); after `at` the
   cell's next touch is a store into it, in a straight line
   (`refilled`); and no OTHER load of that cell is read at or after
   `at` (`borrowed_past`).

## §2 Red team — every guard witnessed failing

Attacks: `features/tests/reuse_in_place` (eval == native == expected,
clean under `AVRA_RC_GUARD=1`). Each attack keeps a second hold on a
box, grows or cuts the first, and reads the second back.

| guard removed | result under AVRA_RC_GUARD=1 |
|---|---|
| runtime `rc == 1` (`sole_sized`, `sole_array`) | trap: released an already-dead box |
| no read after `at` | wrong answers: `e1!/e1!`, `j1x/j1x` |
| innermost scope owns `r` | trap: released an already-dead box |
| no other borrow of the cell (`borrowed_past`) | wrong answer: `h1xh1x` |
| one seat (pass) + `a == b` (runtime) together | garbage: `fffffffff9����`, `?` |

The pass's one-seat check and the runtime's `a == b` are two layers:
either alone holds `s + s`. The guard now POISONS a moved-from text
box (as `array_poison` does a list), or a stale read under the guard
would still find the old bytes and pass.

## §3 Deadlines — guards no program reaches today

A green test of an unreachable branch is theatre; these are traced.
- **Views of `r`** (rule 2): every lending row with a managed answer
  has an owned twin, and `read_outlives` gives the twin to any child
  used past a read of its subject — so today no managed view outlives
  a consuming call. Fires the day a lending row without a twin, or a
  managed `Extract`, reaches a consumed subject.
- **`level_with`**: lowering loads a cell at its use, and a load used
  inside a loop that stores to the cell retains (`borrow_outlives`
  scans the whole loop). Fires the day a load is hoisted out of a
  region its use sits in.
- **`refilled`'s straight line**: `s = s + x` stores immediately. Fires
  the day an assignment's store is separated from its value by a
  bracket.

## §4 As built — R1

- runtime/avra_runtime.c: `shared`, `sole_sized`, `sole_array`,
  `sized_capacity` (size class, else `malloc_size`/
  `malloc_usable_size`), `sized_grown`/`sized_moved` (in place when
  the block has room, else a doubling move — `realloc` past the
  classes), twins `avra_{bytes,str}_concat_reusing`,
  `avra_bytes_slice_reusing`, `avra_bytes_of_str_reusing`,
  `avra_str_of_bytes_reusing`, `avra_array_{concat,slice}_reusing`,
  `avra_cell_forget`. Census gains `alloc:` (boxes by kind, buffers).
- core: `RtSig.has_reusing_twin`, `rt_reusing_twin`.
- compiler/memory/memory.av: `Lives` (last read and def site per
  register), `Handover`, the store move.
- features/structs/lower.av: `with` as slice + slot writes.
- Accounting follows the LENGTH, as `box_free` does, so a grown box's
  slack (at most its length) is not in `AVRA_MEM_STATS`.

## §5 Numbers — R1, against main 0e8a63c

**The request, Linux Sprite `avra-reuse`** (x86-64; the Mac's timings
are load noise, and a comparison is only ever interleaved):

| | before | after |
|---|---|---|
| tools/bench/request | 5.40 µs | 5.15 µs (−5%) |
| wrk pipelined16 c=200 | 146k req/s, 6.85 µs CPU | 158k req/s, 6.35 µs CPU |
| wrk keep-alive c=50 | 44.3k req/s | 46.1k req/s |
| C floor, pipelined16 | 1.13M req/s, 0.88 µs CPU | — |

Mac, interleaved (base built by `0e8a63c` against its own runtime):
2.43 µs -> 2.20 µs (−9%). A first reading of 2.84 -> 2.0 compared runs
at different loads and is RETRACTED.

**Request census, per request** (`-DAVRA_CENSUS`):

| | before | after |
|---|---|---|
| boxes allocated | 60 | 46 |
| — of them Bytes | 15 | 1 |
| — strings | 5 | 6 |
| — lists and records | 40 | 39 |
| retains | 76 | 52 |
| releases | 136 | 97 |

**`check packages/cli` census:** retains 422.0M -> 372.9M (−11.6%),
releases 551.4M -> 493.3M (−10.5%), boxes 133.2M -> 124.2M (−6.7%),
list buffers 129.7M -> 121.4M; peak 414 -> 415 MB. Cold wall, three
interleaved pairs: user 7.91 s -> 7.56 s; resident set 328–413 MB on
both sides.

**Growth by append**, 100,000 appends through a local `mut`: text
385 ms -> 4 ms, Bytes 391 ms -> 1 ms, list 13.7 s -> 1 ms.

**Why the request moved only 5–9%.** Every Bytes copy is gone, but a
box from the size-class free lists is cheap (ALLOCATION HERE IS
CHEAP), and what remains per request is 39 small records and lists —
each a box AND a buffer — none of them a value dying at an update.
Reuse has nothing to hand over there; §6 names what does.

## §6 What reuse cannot reach — the next slices

After R1 the request's allocations are records and lists: 39 per
request, each a box AND a separate buffer. None is dying-and-rebuilt;
they are small scalar records (`Span`, `Field`) and enum payloads.
- **R2 records as one block** (avra-8sb5.34.3): cells and marks laid
  in the box's own allocation, as static data already is. Halves them.
- **R3 consuming params** (avra-8sb5.34.4): params are borrowed, so a
  `with` on a param (`with_host(…, f)`) can never reuse. Perceus owns
  params; a seat that consumes would let the caller hand over.
- Interpolation builds a parts list then joins it; a sized builder
  row would skip the list.

## §7 As built — R2, records as one block

A box asked for a SIZE (`avra_array_sized`: records, literals, slices,
clones) is one allocation — its cells and marks laid right after the
AvraArray, the layout static data already had. `laid_out` now means
"cells inside the box", static or not, and the grow and reclaim paths
it already guarded serve both: a grow moves the cells out and leaves
the laid-out ones in the box; a reclaim frees only a buffer that is not
laid out. A builder (`avra_array_new`) keeps its own buffer, since it
grows. Nothing else in the runtime owns a list buffer.

Mac, four interleaved pairs over the R1 runtime: request 2.27 µs ->
2.08 µs (−8.5%). `check packages/cli`, five interleaved pairs: user
8.00 s -> 7.98 s — no regression.

## §8 As built — R4, value records

**D10. A record of `int` fields is a VALUE RECORD.** `flatten` marks
any non-generic record whose fields are all `int` flat (it took ONE
before); more than one field makes it WIDE (`is_wide`): an LLVM struct
in registers, passed and answered by value. A record a writing impl or
a `mut` seat seals stays boxed, as a one-field record always did.

**D11. A value record crosses every runtime row BOXED — at ONE door.**
Every slot write and read is a runtime call, and every runtime call
goes through `call`/`call_at`/`call_void` (features/emit.av; I58 and
I60 keep it so). There a wide seat is packed into a sized `List<int>`
box (`crossing`) and a wide answer read back and packed (`unboxed`).
`List<int>` is already managed, owned-twinned and released, so the
box needed no new ownership rule. A list cell, an enum payload, a map
value, a `Cell`, a capture, a task's answer: all one door.

**D12. `machine_type` is the question "what does this travel as".**
A name over a value record (`type Spanned = Span`) is a flat record of
ONE field that travels as the wide one. Every seam asks
`travels_wide`/`machine_type`, never `is_wide` of the type in hand:
the LLVM type, `rides_pointer`, the door, the hollow, const crossing,
and the `once` cache — which caches a value record in the one-cell
list a nullable answer already rides.

**D13. A `dyn` over a value record calls through a shim.** The dyn
box's slot holds the record boxed, while the method takes the
aggregate, and the dispatch site knows only the trait. The vtable
entry is `<method>$v` (`dyn_entry`, a `Wrap` that `unboxes`): it reads
the receiver back and calls the method.

**Red team** (features/tests/value_records, eval == native == expected
under AVRA_RC_GUARD=1; the answers equal main's). Three defects were
found by attack and fixed, each witnessed failing:

| defect | symptom without the fix |
|---|---|
| a departed arm's hollow was a word | LLVM: PHI operand types differ |
| a name over a value record | LLVM: call parameter type mismatch |
| `dyn` over a value record | native printed `3350411681624338536704` for `123` |

A named type over a RECORD reading `.of` is F0900 on main already
(avra-8sb5.34.11) — the attack reads the name without it.

**Numbers.** Request bench: no change beyond noise (Mac, four pairs) —
list boxes 39 -> 40 per request, list reads 138 -> 111, retains 52 ->
46. http's `Span`s are STORED — in `Field`, in `FieldLine`, in
`List<Field>` — and every one-word seat re-boxes them. `check
packages/cli`: user 7.71 s -> 7.10 s (−8%, three pairs): the
compiler's own int records stay in registers. Inline embedding
(R4b, avra-8sb5.34.10) is what reaches the stored ones.

## §9 As built — R6, the request path

**D14. A head's fields are OFFSETS, four ints each, in one list** —
`frame.Fields`, a name over `List<int>` with `count`, `name_at`,
`value_at`, `field` and `named`. A head costs one allocation however
many fields it carries, where each field was four boxes (`FieldLine`,
`Field`, two `Span`s). `field(i)` builds a `Field` only for a reader
who asks; the framer and `Request.header` never do. `field_lines`
writes into the caller's list and answers `Refusal?` — null on the
happy path, so no result enum is built either.

**D15. `Line` is gone; `Framing` is written in place.** The request
line's parts go straight to `settled` (its `Span`s are value records,
free in registers), and the framing fold writes through a `mut` seat
(`noted`, `took_*`, `broke`) instead of copying the record per field.

**D16. The response is ONE buffer grown in place** (`written`): a
local accumulator that R1 appends to without copying.

**D17. An interpolation lowers as its pieces**: empty literal parts
drop, one piece is itself, two are one `str_concat`, only three or
more build the parts list and join. `"${n}"` is `int_text(n)`.

**Loops where a lambda would be a box per call** (`fields_writable`,
`names_one_of`, `Fields.named`), licensed I4 at each site; R9 makes a
capture-free lambda static data and retires two of the three.

**Numbers** (Linux Sprite, the side tree = this lane plus the link
stopgap, since main's bench does not link — avra-8sb5.34, COMPONENTS
tracing):

| | campaign start | after R1 | after R6 |
|---|---|---|---|
| tools/bench/request | 5.40 µs | 5.15 µs | **3.28 µs** |
| wrk pipelined16 c=200 | 146k req/s, 6.85 µs CPU | 158k, 6.35 µs | **205k, 4.86 µs** |
| wrk keep-alive c=50 | 44.3k req/s | 46.1k | **50.4k** |
| list/record boxes per request | 40 | 39 | **14** |

The 14 left: `Head`, its two `Span`s (R4b), `Body`/`Framed`/`Method`/
`TargetForm` enums (R8 takes the payload-free ones), the handler's
`Response`, header list and `Header`, `Framing`, the fields list, and
the bench's own `Request`.

## §10 As built — R8, an enum that carries nothing is its tag

**D18. A non-generic enum whose variants carry nothing is FLAT over
one `int`** (`Decls.flatten_enum`): its value is its tag, a word, as C
spells an enum. `.Get`, `.None`, `.Origin` build nothing and count
nothing. The two enum verbs carry it: `tagged_value` packs the tag
(identity) and `tag_of` extracts it (identity), so every match, `is`
and `==` reads the word. `is_managed` asks flatness for an `Enum`.

**D19. It crosses as its tag.** A literal variant of one settles as
`MetaVal.Int(tag)` and lays out as `Slot.Int` — one word in a const
list, a record field, a table row — the shape a flat record already
crosses in. A `once` answer that is no pointer (a word enum, a value
record) rides the one-cell cache; the law's own help always listed
"an enum" as keepable.

**Ladder lesson.** Refreshing `avra.pre` from a gen-1 binary that
lacked a crossing fix let that binary compile the compiler, and every
const holding an enum trapped while settling (`width_words`,
`program_rows`). The standing binary for a gen-1 build is one that
predates the whole change; when none is at hand, `make bootstrap`
from the committed seed is.

**Attacks:** features/enums/tests/word_enums — match, `is`, `==`, a
list, a map, a record field, a payload beside a word variant, a
nullable (`let … else`, `??`), a const, a const list, `once`, `dyn`
with a method, a generic, a capture, a Cell — eval == native == the
pre-R8 answer, under AVRA_RC_GUARD=1.

**Numbers.** Request boxes 14 -> 11 (`Method`, `TargetForm` twice).
`check packages/cli` user 7.83 s -> 7.24 s (−7.5%, three interleaved
pairs); resident set overlapping.

**The pass's own cost is measured in INSTRUCTIONS RETIRED** (`time -l`),
since wall and user time at load 35 are noise. The first cut cost
+1.6% instructions on `check packages/cli`: `views` walked the body
for every candidate store. A precompute that also asked `takes_twin`
cost +9.6% — `takes_twin` scans forward for a lending row, so asking
it per instruction is quadratic. `viewed_regs` is a SUPERSET (any
register a managed view reads) and `views` keeps the exact filter;
the pass is then at parity (158.1B vs 158.3B instructions). Request
census: retains 20 -> 14, releases 36 -> 30 per request.

## §12 As built — the three narrow leaves

The R5a profile named three costs that were neither counts nor boxes:
- **`avra_int_text` formatted through `snprintf`** (`__vfprintf`, ~2%
  of the request): digits now written backwards into a scratch buffer,
  the magnitude unsigned so `INT64_MIN` has one too — checked against
  `snprintf` on thirteen edge cases.
- **`avra_str_char_code` carried its trap inline** — an 80-byte buffer
  and a `snprintf` in a hot leaf (A COLD PATH IN A HOT LEAF); it calls
  the out-of-line `trap_bounds` now, same words.
- **std-http's `byte(":")` read a literal at run time**, 41 sites. A
  LITERAL's byte at a literal index folds in lowering
  (`literal_code`, features/str_lit/lower.av) — the byte the runtime
  would read, or the runtime call when the index is outside the text —
  and the sites spell `":".char_code()`. The request path now calls
  `char_code` zero times. Pinned by str_lit/tests/char_code_fold
  (an escape, a later byte, a multi-byte lead and continuation, a
  computed index beside a written one; eval == native).

Still open from that profile: `avra_once_get` (~7%, 42 reads a request)
wants a `Bytes` const to cross as static data (R9).

## §13 As built — R9a, a `Bytes` const is static data

**D21. `Bytes` has a compile-time value form.** The crossing carries
octets as `MetaVal.Octets(List<int>)` (the evaluator's `Val.Y` crossed
as it holds them — it used to become `Text`), the settlement wire as a
number list (`o`, refused whole when a field is not a number, so the
record is rebuilt), the fingerprint as one folded part (tag 125). The
static layout gives a `Bytes` value a box of its own,
`StaticBox.Octets(b)`, which the backend lays out with the text
constant's writer — KIND_STATIC, immortal, the layout text and octets
share (D1) — and the evaluator reads back as `Val.Y`. So a `Bytes`
anywhere in a const — whole, in a list, in a record field — is an
address in the binary: no evaluation, no count.

**std-http's request-path tables are consts** (`frame.av`, `http.av`,
`client.av`: 34 `once fn`s — class tables, header names, the verbs):
`tchar` is an address where it was a cache lookup, a retain and a
release per read, 42 reads a request. The cold modules (`query.av`,
`route.av`, `server.av`) keep theirs: a `let amp = … amp()` there
would have been shadowed by the rewrite. A const is a NAME a binding
can shadow; a `once fn` call cannot be.

Pinned by consts/tests/bytes_consts (literal, empty, non-UTF-8, list,
record field, a fn-computed class table, a thousand reads of an
immortal). The request bench on the Mac: 1.30 µs -> 0.99 µs, with the
literal-byte fold of §12.

## §14 As built — R10, the hot runtime leaves inline

**D22. The hottest runtime fns are ONE C source, compiled twice.**
`runtime/avra_hot.c` holds the count, the release, the slot read, the
owned read and the length; it builds into `libavra_runtime.a` like
every runtime file AND to bitcode (`build/avra_hot.bc`, by the clang of
the LLVM the compiler links) that `backend/llvm_wrapper.c` carries as
bytes (`build/avra_hot.inc`). Before a module's passes the worker links
that bitcode in with every definition AVAILABLE EXTERNALLY and the
module's own target, so `-O1` inlines the leaves and emits no copy; a
call it keeps resolves to the library's. The contract is
`runtime/avra_hot.h`: the header test inline, the guard flag and the
cold paths exported by `avra_runtime.c`. **The hot file owns no state**
— a static free list copied into a module would be a second one.

**D23. The compiler carries the bitcode, so its digest covers it.**
Every store is keyed by the compiler's own bytes; a changed leaf is a
changed compiler and retires every cached object that inlined the old
one. A path to a file beside the library would have left objects keyed
only by the library's PATH (avra-8sb5.34.2's hole) holding stale code.

**The guard survives inlining** — the flag is read in the inlined body
and the guarded path is the runtime's. Witnessed: moves without the
dies-here test, built by the inlining compiler, trap `array_get read a
RELEASED box` under AVRA_RC_GUARD=1. (`moved_into` tests the last read
itself before asking `moves` — a witness removes both copies.) What
inlining costs a guarded run is precision: a leaf's return address
names its caller's caller. `AVRA_INLINE_RUNTIME=0` keeps the leaves
calls, and the census build sets it — its leaves count, the carried
bitcode's do not.

**Numbers.** Request bench (Mac, four pairs): 958 -> 898 ns; leaf call
sites in the binary: release 342 -> 36, array_get 492 -> 25, retain
94 -> 26; the binary +29%. `check packages/cli`: instructions 160.4B
-> 142.0B (−11.5%), cycles 40.9B -> 33.6B (−18%), wall 15.0 s ->
11.2 s.

## §15 Where the campaign stands (Linux Sprite, one core)

| | campaign start | now |
|---|---|---|
| tools/bench/request | 5.40 µs | 1.95 µs |
| wrk pipelined16 c=200 | 146k req/s, 6.85 µs CPU | 274k req/s, 3.65 µs CPU |
| wrk keep-alive c=50 | 44.3k req/s | 56.3k req/s |
| C floor (no parsing), pipelined | 1.14M req/s, 0.88 µs CPU | — |

Open, in the ROADMAP's C-level ladder: inline embedding (R4b), a
capture-free closure as static data (R9), count elision past moves
(R5), one server per core (R7).

## §16 As built — R4b (records), a value record laid inline

**D24. A value-record field is laid INLINE in the boxed record holding
it**, as C lays a struct member: its fields are slots of the parent,
and every field after it sits past its width (`TypeRegistry.slot_width`,
`slot_offset`; `LowerCx.field_offset`). One verb per direction:
`packed_struct` lays a record's parts as their `leaves` (a value
record's fields, a name over one opened first); `boxed_field` reads at
the offset (`unboxed_at` rebuilds a wide field from its slots);
`field_written` writes at the offset — a place's field write and a
`with`'s rewrite both go through it, and `with` slices the record's
full width. The runtime door (`crossing`) shares `leaves`, so a value
record in a list cell, a map, a Cell or a payload is still one box.

**D25. A boxed record CROSSES AS ITS SLOTS.** The evaluator's array for
a record holds exactly what `packed_struct` pushed, so a literal's
crossing node splices a wide field's own node in (`inline_slots`) and
the static layout expands a wide field's type into its fields'
(`slot_types`) — one convention for the evaluator, the literal and the
binary. No `@std/meta` shape holds a value-record field, so the meta
crossing's slot readers are unmoved.

**D26. A field of a value record is written by repacking it** (landed
first, 0c12c7a): `s.lo = 5` stored the int over the whole cell — right
natively by layout accident, a defect in the evaluator. The record is
read, packed with the field replaced, and written back where it lives
(`written_to`, one step up the path), which is how a nested
`h.at.lo = 9` reaches the inline slots.

Attacks: features/tests/inline_records — a wide field first, in the
middle, several with fields after them; built, read, written, `with`,
a const and a const list (static layout), a generic `Box<Span>`, a
method through `self`, a `dyn`, a named field, a nested path — eval ==
native == the pre-R4b answers under AVRA_RC_GUARD=1.

Numbers: request boxes 11 -> 10 (the head's spans); Mac request bench
1.28 -> 1.09 µs (three pairs); `check packages/cli` instructions at
parity (150.8B vs 150.5B). Enum payloads are R4b's second half.

**R4b's second half — payloads.** A value-record payload is laid inline
after the tag the same way: `tagged_value` lays the payloads' `leaves`
and sizes its own box (the six callers no longer precompute a size),
and `payload_at` takes the variant's carried types and reads past the
tag and the widths before it. A literal variant crosses as its slots,
the static layout expands a wide payload's type — the record rule, one
more place. An `.Err` box stays valid for every `Result<_, E>`: its
layout depends on E alone. Attacks: features/enums/tests/
inline_payloads (a wide payload alone, between others, two of them,
`Result<Span, E>` with a value-record error through `?`, a const and a
const list, inside a record and a list) — eval == native == pre-R4b.

**The miss the suite caught (412167f):** the fn-field call read its
field with a raw slot index — the one record read that bypassed
`field_read` — so `Server`'s `self.make()` read the wrong slot once its
listener and limits were laid inline, and the multi-core server
segfaulted. A layout change is only as sound as the claim that every
read goes through the one verb; the grep for raw slot reads is the
check (`slot_read(` over a record subject).

## §17 As built — R5a', a constant literal is static data

**Measured first.** Of the request's 10 remaining list/record boxes,
ONE never escaped its fn (the bench's own `Request`); four were
constant literals — `Header { … }`, the `[…]` holding it,
`Unrouted {}`, `Body.None`. Stack boxes would have bought one.

**D26. A literal the source alone spells is laid out once, as a
const is.** `spelled_static` (features/values.av) runs at the lowering
spine's one edge: a pointer-riding literal whose every part is spelled
(`literal_meta` — the fold `const` seats already use) and whose type
is closed becomes `StaticAddr` of an immortal box, named by its file
and expression. Maps stay run-time; a scalar is already a constant.

**D27. A write through a fresh `mut` local opens a STATIC box, and
only a static one.** The alias-copy law writes a local seeded by a
construction or a fn's answer in place — that is what keeps an identity
whose hooks capture it one (features/tests/borrow_identity) — so a
`mut`-seat call on `mut xs = [1]` wrote into the binary's `[1]`, and
every later turn read `[1, 7, 7]`. `avra_cell_thawed` copies a cell's
box when it is immortal and answers any counted box as it stands; the
evaluator notes the handles a static was built as. Opening every such
write unique instead (a count check) forked the identity the test pins.

The same channel still lets `mut c = inner(s); add(c)` grow `s.xs` when
`inner` answers a field of `s` — the identity mechanism, working as
designed, and a question for the language rather than this slice.

Pinned by features/tests/static_literals (fifteen write shapes over
three turns, then every literal read again; the `mut`-seat cases
witnessed failing without the thaw). Request boxes 10 -> 6;
`check packages/cli` 151.2B -> 150.0B instructions.

## §18 Measured and not landed — a cell's last read hands its box over

`written` ends `out.bytes().concat(r.body)`, and the cell still holds
`out`, so the Bytes twin copies the head. Handing the cell's reference
over at a read nothing follows (no later read, no loop around it) made
the twin fire — and the census stayed at 14 boxes a request (Bytes
2 -> 1, strings 6 -> 7): the head's box had no room for the body, so
growing it allocated and copied what the copy did. `check
packages/cli` at parity. Not landed; the patch is one predicate in
`refilled_cell` plus a per-instruction loop table.

## §19 Where the request stands (Mac, after R5 static literals)

~14 boxes a request (6 strings, 2 Bytes, 6 records/lists), each ~2%
of the request: time is ~30% boxes, ~26% the framer's own scans
(`bytes_run`, `index_of`, `memchr`), ~12% the response's appends.
No single lever above 5% remains in the compiler; the next are
std-http's shape (the `Framed`/`Head`/`Response` chain) or
per-core throughput.

## §20 As built — R11, value enums

**D28. An enum whose every variant carries at most one word is its tag
and that word, in registers** (`TypeRegistry.is_valued`, marked at the
enum's declaration by `Decls.flatten_enum`). A word is an int, a word
enum, or a counted pointer; a payload's answer is asked of ITS OWN
declaration first, and an enum payload counts only when it carries
nothing — so the verdict never depends on which was declared first
(`declared_type` asks an enum's declaration before handing out its id,
as it does a name's). Bools, floats, raw pointers, pairs and value
records disqualify.

**D29. The word is counted by the tag.** A per-type mask names the
variants whose word is a pointer; `Retain`/`Release` of a value enum
become `avra_rc_retain/release_tagged` (hot leaves, inlined), and a
cell holding one is settled by tag in the backend — a cell is two
words, never one pointer (the red team's first finding: the pointer
settle read the tag as an address and a later read met a freed box).

**D30. In a box it is two slots; at a one-word seat, its tagged box.**
A record field or an enum payload lays tag then word (`push_leaf`,
`leaf_write`; the word's mark follows the tag through
`avra_array_push_tagged`/`avra_slot_set_tagged`). A list cell, a map
value or a Cell holds today's tagged box, made and read at the door
(`avra_enum_boxed`/`_tag`/`_word`). A static record lays the same two
slots.

**D31. A nullable value enum spends the spare tag -1** (`Repr.Tagged`):
still two registers, so every lift that assumed a nullable's widen is
identity — `Code` into `Fix?` in every rule — stays true. A one-slot
box was tried first and broke exactly those lifts.

Pinned by features/enums/tests/value_enums (records inline, `with`,
field writes, list/map/Cell/payload seats, a const, nullables, a
return from inside a loop, recursive enums; eval == native under
AVRA_RC_GUARD, 0 of 64 boxes live at exit).

**Numbers.** Server under load: 15 -> 13 boxes a request (`Framed`,
`Body`). `check packages/cli` at parity (162.4B instructions both).
Stage 1 alone — boxed at every slot — measured +1% and 15 -> 15: the
inline layout is what paid.

**Not done: `Result<T, E>`.** Its sides are laid out by THEIR
declarations, and a `Result` is interned wherever it is spelled, so
marking it at intern would judge a record before it is signed — two
bodies could disagree on the calling convention. It needs the sides'
declarations asked first, at a door every spelling passes.

## §21 As built — R11b, a Result is a value enum

**D32. A `Result<T, E>` of two one-word sides rides registers**, Ok tag
0, Err tag 1. It is judged ONCE, where the type is first interned
(`TypeRegistry.judge_result`), from layouts that can no longer move: a
side's declaration must have SETTLED (`mark_settled`, made at every
record's and enum's declaration), a flat record stays out (a `mut` seat
may still box it), and an enum is never sealed at all — it has no path a
`mut` seat writes through. `applied` asks a spelled Result's record
sides first, so `Result<int, NetError>` is judged with `NetError` known.

**D33. A failure leaves in the fn's own layout** (`propagated`): `?` and
a selective `catch` pass the subject on as it stands when both Results
are laid alike — a box by its pointer, a value's Err tag and word — and
wrap its error again when one is a value and the other a box.

Pinned by features/results/tests/value_results (both repack directions,
a selective catch, list/field/map/nullable/Cell seats; eval == native
under AVRA_RC_GUARD, 0 of 46 boxes live at exit). A static list of
value Results lays each as its tagged box; only fields and payloads
split into tag and word (`fields_of`).

**Numbers.** Server under ab -k: 13 -> 10 boxes a request (6 under a
load that sends no `Connection` field); @std/net's `write`/`try_write`
no longer box. `try_read` answers `Result<Read, NetError>` and `Read`
is itself two words, so it stays boxed. `check packages/cli` -0.4%
instructions; the compiler binary +3.4% (8.29 -> 8.57 MB).

## §22 Where the campaign stands (Linux Sprite, one core, e3d55d2)

| | start | §15 | now | C floor |
|---|---|---|---|---|
| tools/bench/request | 5.40 µs | 1.95 µs | 1.70 µs | — |
| wrk pipelined16 c=200 | 146k req/s, 6.85 µs CPU | 274k, 3.65 µs | 330k, 3.05 µs | 1.14M, 0.88 µs |
| wrk keep-alive c=50 | 44.3k | 56.3k | 56.6k (17.8 µs CPU) | 72.7k |

Keep-alive is syscall-bound: a read and a write per request dominate
the 17.8 µs, so the allocation levers show in the pipelined column.
The next levers are the response written into the connection's own
buffer (R14) and fewer syscalls per request (batched writes).

## §23 As built — the profile, and three cuts from it

**The first Linux profile was the instrument's.** callgrind under
valgrind maps a PIE image and its heap below 4 GB, and `avra_hdr`
refuses every address below 4 GB, so every box read as foreign:
no count, no free, every constant copied — `malloc` at 30%. Real runs
are unaffected (PIE at 0x56…, 0 boxes live at exit); the premise is a
deadline all the same (avra-8sb5.34.24). The true profile came from a
profiling-only copy with the floor at 0x10000: 12.5k instructions a
request — memory work 31%, the framer's scans 23%, http logic 20%,
the response's header checks 10%, building the response 11%.

**Three cuts** (request bench, 5M requests, instructions retired):
1. The live-byte count stays on every allocation (a settlement's
   budget reads it); the report's category is computed only when
   `AVRA_MEM_STATS` is set (`acc_box`, `acc_note` out of line):
   64.57B -> 64.04B.
2. The server judged every response twice (`as_sent`, then `wire`
   again). It calls `wire` once; only a `HEAD` asks `as_sent` again to
   measure the body it withholds. No unjudged writer is exported — a
   response no peer could read stays refused at the one crossing.
3. The reply is ONE gathered allocation (`List<Bytes>.bytes()`): the
   status line read from `reply_lines`, a const of every three-digit
   status laid out in the binary; header text shared, not copied.
   Together: 64.0B -> 59.9B (-6.4%). A header's four pieces are
   pushed, not concatenated as a literal: the literal is a box per
   header, and measured 3.5% slower.

## §24 Keep-alive: the gap is our CPU, not the kernel

Counted with an LD_PRELOAD shim over libc's wrappers (the Sprite
refuses ptrace and perf), one core, wrk -c50, 5 s:

| per request | Avra | C floor |
|---|---|---|
| read | 1.00 | 1.00 |
| write | 1.00 | 1.00 |
| epoll_wait | 0.03 | 0.02 |
| clock_gettime | 4.03 | 0 |

The same syscalls as C. The four clock reads are the idle and write
deadlines' (`within`), 27 ns each on this TSC clock — ~0.1 µs of the
~2.9 µs gap (63k vs 77k req/s). The rest is the request's own work,
so the pipelined profile's levers (§23) move keep-alive too.

## §26 As built — tail, Framing as a value record

**D34. A FLAT record's field list widens past `int`: a `bool`, and a
WORD ENUM (one whose own declaration carries no payload anywhere, so
its tag is its whole value) are scalar fields too** — asked of a
field's own declaration through `carries_nothing`, never of the type
registry's marks, so the answer never depends on which of the two was
declared first (the law `payload_word` already keeps for an enum
payload). `Decls.scalar_field` is the one predicate; `flatten`
(decls.av) calls it in place of the old `is .Int` check. Nothing else
moved: `slot_width`, `ll_type_of`, `packed_struct`, `leaves`/
`unboxed_at` and the crossing's `inline_slots` were already generic
over a field's OWN shape (built for R4b's nested value records and
R11's enum payloads) — a bool lands as an i1 register, a word enum's
tag as an int64, exactly as `ll_type_of`/`machine_shape` already
answered them standalone.

**A nullable enum stays OUT, on purpose.** `Opt(WordEnum)` still
rides a pointer (`opt_rides_pointer`'s "a flat record has no spare
value" law, unchanged) — giving a nullable enum its own spare-tag
register (mirroring D31's valued-enum niche) is a real generalization
and a wider one: it would move EVERY `<Enum>?` in the tree, not one
record's field, and `is_managed`'s `flat_managed` (memory.av) has
never been exercised for a record carrying a MANAGED field — the
backend's `retained`/`released` pass a `.Struct` register straight to
`avra_rc_retain`, sound only because every flat record today is
unmanaged. Left as the next scalar-field width; a record that wants a
`T?` field avoids the box by carrying a `bool` + `T` pair instead
(`@std/http`'s own fix, below).

**§26a `@std/http`'s `Framing` (frame.av), applied.** `why: Refusal?`
was the one field blocking `flatten`: a nullable enum. Split into
`refused: bool` and `why: Refusal` (the `.LineEnd` default is a
placeholder, unread while `refused` is false) — the {bool, value}
pair D34 declined to give nullable enums for free, spelled by hand at
the one call site that needed it.

Fixed by the SAME move: a `mut` seat keeps its box (types.av's
`unflatten`), so `noted`/`broke`/`took_length`/`took_codings`/
`took_host`/`took_connection`/`took_expectation` had to stop taking
`mut fr: Framing` and start taking `fr: Framing`, answering the next
`Framing` — `with` in place of a field write. A record threaded
through a `mut` HELPER PARAMETER can never be a value record
regardless of its fields: the write needs an address, and a value
record's whole point is that it has none. `framing_of`'s own `mut fr`
stays a `mut` LOCAL (a local is opened, not sealed), so the fold reads
exactly as before, one field at a time.

Attacks: `features/tests/scalar_fields` (a bool and a word-enum field
through a `Cell`, a `mut` seat, a `match` on the field itself, a
capture taken before a later write, `Result`, `dyn`, a `Map`, a fold
through `with` across a loop — `Framing`'s own shape — a nested wide
field, a generic `Box<T>`, a static list, `is`, `pop`) — eval ==
native under `AVRA_RC_GUARD=1`, 0 boxes live at exit. `@std/http`'s
own suite (468 unit tests, 4 programs, every named `Refusal` already
pinned by `frame_test.av`) passed unchanged — the restructuring
touched no LAW, only the fold's shape.

**Numbers** (tools/bench/request, Mac, 5,000,000 requests,
`/usr/bin/time -l`, interleaved, several rounds averaged):

| | before | after |
|---|---|---|
| instructions/request | 11,966 | 11,385 (-4.9%) |
| boxes/request | 8 | 7 |

`framing_of`'s own allocation site is gone; the other seven (the
field list, `Head`, `Request`, three inside `written`, `Response`)
are unmoved — R14 (the response written into the connection's own
buffer) and net's last box (R11d, below) are what is left.
`check packages/cli`: 162.3B -> 162.0B instructions (-0.2%, inside
the documented ±0.7% noise floor), binary 8.573 -> 8.572 MB.

**Measured and not landed — R11d, `Result<Read, NetError>`.**
`judge_result`/`side_word` require BOTH sides at most one word;
`Read` (`@std/net`) is itself a value enum (`Data(Bytes) | Eof |
Pending`, tag+word, TWO words already), so `side_word(Read)` is null
by its OWN rule (`is_valued(t) -> null`) and the Result stays boxed.
Fitting it would widen a Result carrying a valued-enum side to THREE
registers (the Result's own tag, the side's tag, the side's word) — a
real change to `judge_result`'s "one word per side" invariant, on the
type every body in the compiler and every std package spells.
Reconnaissance only this slice, deliberately: Framing's fix stayed
inside one record's own field list and one `mut`-seat law; this one
moves a load-bearing assumption under `Result<T, E>` itself. Left for
its own ticket (avra-8sb5.34.22), with a red team sized to match.

**Measured and not landed — the framer's own scans (candidate 3).**
`crlf_only` and `request_line`/`field_lines` each re-scan the same
head bytes (a blank-line search, a CRLF-well-formedness pass, then a
class-table pass per token) — real waste, named "23% the framer's own
scans" at §23's profile. Every one of those three passes is a LAW
against request smuggling (frame.av's own opening comment), so
merging them needs the SAME red-team weight as the framer's original
landing, not an afternoon's. Not attempted this slice.
