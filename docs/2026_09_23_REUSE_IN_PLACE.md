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

**D9. `compiler.str_grown_quadratically` now names only PLACES.** A local `mut`
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

## §25 As built — R12, cold paths compiled for size

**D34. A body reachable from a `once fn` alone is cold by
construction.** `Body.memoized` names a `once fn`'s own (set at
`lower_fn` from the store's `is_once` fact, the same one that already
picks `once_body`'s guard); `cold_bodies` (compiler/lower/lower.av)
closes it over the whole program's call graph — a body joins the cold
set once EVERY caller into it is cold too, propagated by worklist from
the `memoized` roots. `body_symbol` names a call's target and an
address taken alike, so a hot reference either way keeps a body hot —
the set is self-correcting, never a hand-kept list, and a body with no
recorded caller (dead code, or reached only from the entry, which the
graph excludes on purpose) simply never joins it. `Lowered.cold` carries
the set once per program, computed in `union`/`settlement`, never
per emitted module — a split build would otherwise redo the closure
once per file.

**D35. The mark is two LLVM function attributes, not a new IR
shape.** `avra_llvm_set_cold` (backend/llvm_wrapper.c) adds `cold` and
`minsize` at the function the emitter already has in hand
(`llvm.av`'s `emit_mode`, beside the existing `weak_odr` mark) —
`cold` tells the optimizer the function is rarely reached, `minsize`
tells it to spend bytes for cycles inside it. Neither attribute
changes what a function computes, only how LLVM lays it out: the risk
of marking a hot body cold by mistake is a PERFORMANCE question, not a
correctness one, and `cold_bodies`'s "every caller must be cold" rule
means a wrong mark can only ever be a missed win, never a regression —
confirmed by the request bench (below) reading identical instruction
counts before and after, since that program's call graph has no
`once fn` in it at all. Considered and refused: per-instruction branch
weights on `?`/`catch`'s failure arm (the ticket's other candidate) —
it would need a new fact threaded through `Ins.IfStart` down from
lowering, which is IR-vocabulary growth (protocol: justify, pay every
consumer) for a payload that gates a HINT, not a value; the measured
growth was squarely in registration tables, not error branches, so the
whole-fn attribute on the fact the backend already computes
(`body_symbol`, `is_once`) was the cheaper, sufficient lever.

**Size ledger** (`tools/symsize.py`, `nm -n --defined-only`, size =
next symbol's address minus this one; Mac arm64, build/avra.pre =
tree at 10f8a9b, build/avra = this change, two-generation build
ladder, gen2 == gen3 byte-identical):

| | before | after |
|---|---|---|
| whole binary | 8,573,056 B | 7,341,152 B (−14.4%) |
| `__TEXT` sum (nm) | 6.60 MB | 5.14 MB (−22.2%) |

Per-module `__TEXT` deltas: `avrac.features` 2,779,388 → 1,392,312 B
(−1,387,076, roughly halved), `avrac.core` 792,480 → 712,552 B
(−79,928), `avrac.compiler` 2,196,024 → 2,137,720 B (−58,304),
`avrac.grammar` 306,604 → 302,624 B (−3,980). Biggest single-symbol
shrinks: `impls.impls` −48,720 B, `expr_spine.expr_spine` −44,240 B,
`fns.fns` −37,880 B, `core.rt_sigs` −23,108 B (a table-building fn
R12's own closure caught that R10/R11's report never named),
`enums.enums` −19,484 B, the grammar payload tables −18.6 KB/−18.1 KB,
`closures.closures` −17,584 B, `structs.structs` −16,644 B,
`components.components` −11,820 B. `minsize` also invites LLVM's
machine outliner: ~186 new `_OUTLINED_FUNCTION_N` symbols share code
the individual registration fns used to carry each on their own,
+44 KB — already netted into the totals above, not a separate cost.

**Compiler cost, `check packages/cli`** (`/usr/bin/time -l`,
interleaved old/new twice, `.avra-cache` moved aside each run):

| | old (avg of 2) | new (avg of 2) | delta |
|---|---|---|---|
| instructions retired | 162.77 B | 165.03 B | **+1.39%** |
| cycles elapsed | 43.64 B | 40.70 B | −6.7% |
| wall (`real`) | 17.08 s / 20.25 s | 15.23 s / 13.88 s | lower both pairs |

Diagnostics are BYTE-IDENTICAL between old and new
(`diff` on stdout, four runs) — the mark changes layout, never
meaning. Instructions retired sit above the ±0.7% floor this doc's
own numbers treat as noise; `minsize` is the reason, read straight:
the ~40 marked fns each run exactly once per process (grammar
assembly, `once fn avra()`'s own memoized body), and a size-optimized
body can cost a few more instructions to execute in exchange for fewer
bytes and better locality for everything AROUND it — which is what the
cycles and wall numbers show moving instead. Recorded rather than
argued away: this is a real, small, one-time cost, not measurement
noise, and it buys a materially smaller, not-slower-in-cycles binary.

**Request bench** (`tools/bench/request`, built with each compiler,
run interleaved 4× each, instructions retired — the stable figure; the
program's own printed ns/request is noisier on a loaded Mac desktop):

| | old (avg of 4) | new (avg of 4) |
|---|---|---|
| instructions retired | 59.839 B | 59.778 B |

No measurable difference (~0.1%, inside noise) — expected: this
program's own call graph has no `once fn` in it, so `cold_bodies`
marks nothing and the compiled bench is untouched. This is the
confirmation that R12 is scoped to the COMPILER's own binary and
never reaches into an arbitrary compiled program's hot path.

**Red team.** (1) A wrongly-cold-marked hot fn regressing a real
program: unreachable by construction (the "every caller cold"
closure), and the request bench's null result is the empirical check.
(2) Behavior change under the mark: `cold`/`minsize` are LLVM
optimizer hints with no semantic effect by design; confirmed by
byte-identical `check packages/cli` diagnostics across old/new and by
the full `eval == native == expected` suites below. (3) The closure
itself wrong (marks something reachable from the entry): `entry`/
`program_main` are included as nodes in the graph fed to
`cold_bodies` specifically so anything they call keeps a permanent
non-cold caller — verified by reading the marked-cold set is exactly
the ~40 registration-table fns the size ledger names, nothing from the
request bench's or cli's own runtime logic. (4) Fixed-point
stability: gen2, gen3 and a gen4 built via `make libs` are
byte-identical (`cmp` clean) — the mark doesn't oscillate as the
compiler recompiles itself under its own new logic.

**Tests.** `packages/std-avrac`: 6672/6672 tests passed, 156 programs
proved (`eval == native == expected`), exit 0. `packages/std-http`:
468/468 tests passed, 4 programs proved, exit 0. `python3
tools/idioms.py`: no new violations. `python3 tools/externs.py`: clean
(the one new extern, `avra_llvm_set_cold`, matches its C body's arity
and width). `./build/avra fmt` unchanged on every touched file.

**Deferred:** branch-level cold hints on `?`/`catch`/trap failure arms
(the ticket's mechanism 2) — refused per D35's reasoning, not merely
postponed; the ROADMAP's sugar/IR backlog is where it belongs if a
future measurement finds the registration-table lever insufficient on
its own.
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

## §27 As built — R11e, a nullable word enum spends the spare tag

**D35. A nullable WORD ENUM (every variant carries nothing, so its
value IS its tag — R8) rides ONE register, the spare tag -1 its
absence** — D31's own trick (`Repr.Tagged`), generalized from
`is_valued` to `is_word_enum` rather than given a second mechanism
(the GENERALIZE-BEFORE-ADDING law). `TypeRegistry.word_carrier`
answers the tag's register for either type that names it — the enum
itself or its nullable — the way `valued_carrier` already does for a
value enum's Opt; `opt_rides_pointer` refuses the pointer only a flat
RECORD needs (a word enum's tag has its own spare value, unlike a
flat record's fields, so it never boxes). `inner_repr_of` files a
word enum's Opt under `Tagged` beside a value enum's; `absent_tagged`
splits the two payload widths apart (one register, the tag alone, for
a word enum — tag-and-word for a value enum, D31's original shape).
`Decls.scalar_field` widens to admit a WORD ENUM'S OWN NULLABLE
alongside D34's `int`/`bool`/word-enum trio, so a record carrying one
(`@std/http`'s `Framing`) is flat again, asked of the field's
declaration exactly as D34 requires.

**Every consumer D31 already taught to read a Tagged repr reads this
one the same way, because it IS the same repr**: `tag_of`/
`presence_of`/`carried_of`/`insisted_tagged` (values.av) already
switch on `repr_of`, not on `is_valued` directly, so word-enum
nullables fell through unaided the moment `inner_repr_of` answered
`Tagged` for them. Four consumers needed their OWN widening because
they read a register's SHAPE rather than asking `repr_of`: `memory.av`'s
`is_managed` (a word-enum Opt never boxes, so it is never counted, the
same law flat records already hold); `llvm.av`'s `opt_ll_type` (the
nullable's LLVM type is the WORD's, no wrapping aggregate); `llvm_emit.av`'s
`bare_value` (renamed from `flat_value` — a nullable word enum has no
LLVM aggregate either, so `extract_value`/`pack_value` treat it as
identity, a `cast_to_type` guarding the one case a flat record's
identity pack never needed: a present value ADOPTED into the
nullable, per `adopted`'s `.Tagged -> r` branch, arrives typed as the
BARE enum and is cast into the `Opt` register's own LLVM type at the
door rather than re-minted); and `interp.av`'s `bare_reg` (the
interpreter's mirror, no LLVM types to cast, just the same identity
question).

**Two companion fixes a Tagged nullable's OWN absence exposed, not
new to word enums but never exercised until this slice's tests wrote
a `match … { null -> …, v? -> … }` and an `x == null` over one**:
`pat_reg`'s bare `null` arm used to compare the subject against
`reg_of(the null literal)` by VALUE (`same_value`) — sound for a
NICHE nullable, where a null literal's register IS the pointer zero,
and wrong for a TAGGED one, where a null literal's register carries
no repr of its own until an adopting edge gives it one (the niche's
own law, `adopted`'s comment) — so the comparison read a Tagged
subject's spare tag against an unrelated raw zero. `literal_pat_reg`
asks the subject's own PRESENCE directly instead, never through
equality; `nullable_eq_reg` gets the same fix for `x == null` and
`null == x`. Both are `repr_of`-general, not word-enum-specific — no
regression test for `match v { null -> …, x? -> … }` existed over a
nullable VALUE enum before this slice, so whether D31 carried the
same latent gap is unconfirmed; worth a probe before the next Tagged
consumer is added.

**`@std/http`'s `Framing` restored to `why: Refusal?`** (D34 had
split it into `refused: bool` + `why: Refusal = .LineEnd`, a
placeholder default unread while `refused` was false, spelled by
hand at the one call site D34 declined to give nullable enums for
free). `noted`/`broke`/`settled`/`settled_reply` read `fr.why != null`
in place of `fr.refused`, matching the file's own established idiom
two lines below (`let broken: Refusal? = body_refusal(fr, limits); if
broken != null { return .Refused(broken!) }`) rather than a new one.

**Red team.** `features/enums/tests/nullable_word_enums` (`??`, `?.`,
`match` with `v?`/`null` arms, a record field, `List<E?>`, a `Map`
value, a `Cell`, a fn param/answer, a generic `T?` over a word-enum
`T`, and `E??` nested through a generic — the spare tag never
collapses a present-null into absent) plus
`nullable_word_enums_adversarial_test.av` (aliasing: a record field
copied then written through the copy, a `Cell` seat, `with`, a list
element by index; crossing: `dyn`, a generic seat, a `Box<T>`-shaped
field; static data: a top-level const and a const `List<E?>`; the tag
boundary at 64 variants; equality both directions and `!=`; a
single-variant word enum; a managed STRING field beside the nullable
word enum in the same flat record; `Result<E?, string>` through `?`
— stays boxed, correctly, since `payload_word`'s `.Opt` case still
asks for a pointer-riding nullable and a word-enum one is not one, so
this is left on the table rather than a defect; a `for` loop and
recursion over `List<E?>`; and a `match` arm that leaves the fn
merging beside both a present and an absent companion, `hollow_of`'s
fallback path) — eval == native under `AVRA_RC_GUARD=1` (two small
standalone probes built and run directly under the guard, per the
doctrine that the guard is for small programs, never a whole-package
compiler self-host: one exercising the enum feature's own aliasing/
dyn/generic/list/map/cell shapes across 2,000 loop turns, one calling
`@std/http`'s `framed()` 3,000 times across three request shapes
including two distinct `Refusal` reasons; `AVRA_MEM_STATS=1` read 0
MB live in every category at exit on both).

**A genuine finding along the way, not a defect in this slice**: the
red team's first pass wrote `if k < 0 { return "early" } else {
Dir.N }` as a merge attack and hit F2000 "an `if`'s branches
disagree: `string` vs `Dir`". Control-probed with a bare `int` in
place of the enum — identical refusal, so plain `if`/`else` has never
exempted a diverging arm from the branch-type join (`if_expr/
check.av`'s `branch_type` compares both arms directly and never calls
`checks.av`'s `stays()`, the filter `match` arms and other N-ary
joins already use). Orthogonal to this ticket's representation
change; filed as avra-8sb5.47. The attack was rewritten as a `match`
(whose join already exempts a leaving arm) to keep testing what it
meant to test — `hollow_of`'s fallback merging beside a present AND
an absent companion — and passes clean.

**Numbers** (tools/bench/request, Mac, 5,000,000 requests,
`/usr/bin/time -l`, interleaved, 4 rounds averaged, against the exact
pre-slice source and compiler — old `frame.av` built by the saved
pre-change binary, new `frame.av` built by the post-slice one):

| | before | after |
|---|---|---|
| instructions/request | 11,412 | 11,410 (−0.01%, noise) |
| boxes/request | 7 | 7 (unchanged) |
| bench binary | 379,448 B | 379,368 B (−80 B) |
| `build/avra` | 7,366,128 B | 7,348,688 B (−17,440 B, −0.24%) |

No measurable request-path win — expected: `Framing` was already a
flat value record after the tail slice (D34's `bool` workaround), so
this slice removes a field and a write far too small to clear the
±0.7% floor, not a new allocation site. What R11e buys is real
elsewhere: the honest `Refusal?` field back in `Framing` (D34's own
"stays out, on purpose" now paid), and — the larger claim — the
representation itself, generalized once at the type-registry level
rather than re-solved per call site, ready for the next record
anywhere in the tree that wants a nullable payload-free enum field
without boxing.

## §28 As built — R14, `sized_moved`'s block-size shortcut and `written()`'s own accumulator

**The capacity fix landed on the SLOW path, not the fast one.**
`sized_capacity`'s cheap check (a size class read from the LENGTH)
stays exactly as it was — the ticket's own candidate, reading the
block's real size on every append, was measured and refused: it cost
`tools/bench/request` ~3.6% instructions/request for a bug that only
truncation triggers, all of it `malloc_size`/`malloc_usable_size`
calls on appends that never needed one. `box_free`'s free-list filing
was measured the same way (misfiles a big block truncated small into
a class too small to be handed out again) and refused for the same
reason — its own `block_size` call landed on every SIZED box's death,
not only a truncated one, and cost the same bench the same order of
regression; reverted whole, left as `avra-8sb5.10.104`'s open half.
The fix instead sits where the move already happens: `sized_moved`
(entered only once the cheap check has already said "no room") asks
the block's real size ONCE, before moving anything, and answers the
same pointer when the block already fits — a box grown once and
truncated many times over pays for the allocator's opinion only on
the turn it might be wrong, never on the turns it is right by
construction. `appended`'s own disassembly is byte-identical before
and after (`objdump -d --disassemble-symbols=_appended`, both
`build/avra` and the saved `build/avra.pre`) — the fix adds nothing
to the hot fast path, because it never left `sized_moved`, which was
`noinline` already.

**`written()` lost its list, not its shape.** `packages/std-http/src/
http.av`'s `written` built a `List<Bytes>` of parts (pushed once per
header, four pieces each) and gathered it in one call at the end;
it now grows a single local `mut w: Bytes`, one `concat` per piece,
answering `w` at the tail. THE TAIL MATTERS: `w.concat(r.body)`
answered directly as the function's own last expression measured
WORSE than the list it replaced (12,845 instr/request against an
11,376 baseline) — reuse in place never reached that call at all,
confirmed with an isolated probe (`built(status, b, c) -> Bytes {
mut w = seed(status); w = w.concat(b); w.concat(c) }`, called in a
loop: 2 boxes per call, meaning NEITHER concat wrote in place).
Binding the result to `w` and answering `w` on its own line fixed it
in both the probe (1 box per call, matching the top-level pattern
`docs/2026_09_23_REUSE_IN_PLACE.md`'s own growth benchmarks already
rely on) and `written` itself. A value sitting directly in a function's
answer position is invisible to Handover; a value bound to a local
first, then answered, is not — the same fn, the same call, two
different costs, and nothing in the diagnostics said which.

**Measured and not landed — the connection's own buffer.** The
ticket's stated goal — `l.out` grown in place across many requests on
one connection, "zero allocations after the first" — is not reachable
by restructuring `@std/http`'s Avra source at all, for a reason that
has nothing to do with capacity: **Handover (Owned/Emptied) never
recognizes a STRUCT FIELD**, only a bare top-level `mut x: T` local's
own reassignment. Four isolated probes, each an `AVRA_MEM_STATS` box
count over 5,000,000 calls:

| accumulator shape | boxes/call |
|---|---|
| top-level `mut out: Bytes` local, reassigned in a loop | ~0 (steady state) |
| `mut h: Holder` LOCAL struct, `h.out = h.out.concat(x)` | 3 (every concat fresh) |
| `mut h: Holder` PARAMETER, same field write, inside the callee | 3 |
| `Cell<Bytes>`, `out.set(out.get().concat(x))` | 1 (never reused) |

`l.out` is a field of `Link` (`packages/std-http/src/server.av`) by
its whole design — every request's reply is answered through a
connection state machine passed as `mut l: Link` from `conversed`
down through `stepped`/`framing`/`bodied`/`answered` — so no
restructuring inside `@std/http` reaches the shape Handover actually
recognizes. `written`'s own rewrite is the reachable half: it grows
ITS OWN local, not the caller's field, and the caller still adopts
the finished `Bytes` by reference (D2, an empty `l.out` shares the
answer for free) exactly as it did before. Filed as
`avra-8sb5.10.107` (Handover never reaches a struct field), with the
tail-position finding above recorded on it too. `avra-8sb5.10.104`
(this campaign's own capacity ticket) is commented closed on its
capacity half and left open on its field-growth half, which is now
`.107`'s to answer.

**Red team.** `packages/std-avrac/src/features/tests/reuse_in_place/
reuse_in_place.av` gained four permanent cases (eval == native ==
expected, and — since the file is self-contained, no `use` at all —
built standalone and run under `AVRA_RC_GUARD=1` clean, no trap, no
leak under `AVRA_MEM_STATS=1`): a block truncated to empty and grown
back forty times over (the length a truncation resets read back as
the block's own room was the whole bug); a copy taken before the
truncation, proving the shortcut still only ever reaches a SOLE-owned
box (the caller chain's own `sole_sized` check, unchanged by this
slice); a literal `Bytes` truncated and grown, proving an immortal
box is still never written through; and a block truncated small then
grown well past the room its ORIGINAL allocation ever held, proving
the shortcut's absence — a genuine move — still lands on the right
bytes. `@std/http`'s own suite (468 unit tests, 4 programs, all of
`http_adversarial_test.av`'s CRLF-injection, NUL, empty-body and
status-line attacks among them) passed unchanged against the
rewritten `written` — the restructuring touched no law, only the
gather's shape.

**Numbers.** Isolated probe (`out = out.slice(0, 0); out =
out.concat(status_line); out = out.concat(content_len); out =
out.concat(body)`, a top-level `mut Bytes` local, 5,000,000
iterations, `/usr/bin/time -l`, `AVRA_CENSUS` for the box counts):

| | before | after |
|---|---|---|
| instructions/iteration | 1,086 | 790 (−27.3%) |
| `Bytes` boxes, whole run | 9,999,999 | 1 (steady state, one box) |

`tools/bench/request` (Mac, 5,000,000 requests, `/usr/bin/time -l`,
interleaved, several rounds averaged; the runtime fix alone measures
NEUTRAL here — a debug counter confirmed `sized_moved` is called
ZERO times in this bench's whole run, since nothing in the request
path truncates a buffer today — the numbers below are the runtime fix
plus `written`'s rewrite together):

| | before | after |
|---|---|---|
| instructions/request | 11,382 | 10,906 (−4.2%) |
| boxes/request | 10 | 9 |
| list buffers/request | 5 | 2 |
| bench binary | 379,272 B | 379,880 B (+608 B, +0.16%) |

What I wanted from the language while doing this: a way to say "this
value, reached through a field, dies here" that Handover can see —
today the only spelling that works is a bare local, and a struct
field (even one this function alone can reach, through its own `mut`
seat) silently falls back to a full copy with no diagnostic
distinguishing it from the reachable case. `avra-8sb5.10.107` is that
ask, filed.

## §29 As built — R15b, `defer`'s direct call reaches methods, managed captures, and non-void answers

**The gap.** `lower_defer`'s no-closure fast path (`direct_call`,
features/defers/lower.av) only ever matched ONE shape: a FREE call
answering VOID, every argument a SCALAR literal or capture.
Everything else — a METHOD call (`defer s.reset()`), a MANAGED
argument or receiver (`defer avra_puts(s)` where `s` is a captured
`string`), a non-void answer discarded (`defer s()` where `s() ->
string`) — minted the lambda's closure box (`avra_array_sized(2)` +
two owned pushes) and called it back through a pointer, on every
exit. The ORM session hit it squarely: `defer s.reset()` on a
managed `Stmt` receiver, inside `@model`'s generated `find()`, paid
a heap closure on every call.

**What widened, and what stayed narrow.** `direct_call` now tries
two shapes — `direct_free_call` (the original, generalized) and
`direct_method_call` (new) — sharing one predicate, `fixed_early`: an
argument is fixed at the `defer` when it is a CAPTURE (any type now,
not only a scalar) or a scalar literal. A method's receiver takes
the same test. Both bail to the boxed path when `TypeFacts` marked
the read `wants_alias_copy` or `wants_thaw` — the two special cases
`reg_of` itself branches on before an ordinary read; this path never
calls `reg_of`, so it asks the same two facts directly rather than
silently skip the copy a written-through alias needs. A method only
takes the fast path when it resolves through the impl table
(`callee_of`'s `.Declared` arm) with an EXACT seat match (self
included) — `declared_method` re-derives just that one arm's
precedence (a struct/enum/App receiver, no fn-typed field of the
same name shadowing it) locally, since `defers` cannot import
`impls`' `callee_of` (features never import features) and the
question is narrow enough not to earn a promotion to shared infra
yet — noted below as a follow-up. Every other receiver kind
(variant, static, contract/dyn, fn-field, row) still closes over the
box. `DirectCall` grew a `ret: TypeId` field; `run_direct` calls
through it instead of hardwiring `void` — a discarded managed answer
is owned once by the call and released once by the frame's ordinary
scope-close, the same path an unused `Load` or `Pack` destination
already takes, so nothing new was added to the memory pass for it.

**Correctness leans entirely on machinery already there.** No
`Ins.Retain`/`Release` is emitted from this file — the memory pass's
existing `borrow_outlives` scan (over a `.Load`, the SAME read
`capture_regs` performs for a `mut` local) already answers "does
this register need to survive a later cell store or bracket close",
which is exactly the shape a captured receiver read at the `defer`
and called at the exit takes. Proved rather than assumed: a
`mut`-reassignment test (`direct_methods.av`'s `reassigns`) shows the
deferred call sees the OLD receiver after the binding is
reassigned, on both engines; a red-team scratch aliasing probe
(`mut t = s; defer t.bump()`, `t.bump()`'s write escaping through the
returned `s`) reproduces byte-for-byte under `build/avra.pre` (the
pre-R15b compiler, boxed path) and the new compiler alike — a
pre-existing property of how `alias_copy_law`'s walk does not reach
into a lambda's own capture sources, unrelated to this slice, filed
as feedback rather than fixed here.

**Numbers.** `defer s.reset()` on a two-field managed struct, in a
tight loop, 2,000,000 iterations (`/usr/bin/time -l`, `build/avra.pre`
vs. the rebuilt compiler, same source, interleaved, 3 rounds, cache
cleared between binaries):

| | before (boxed) | after (direct) |
|---|---|---|
| instructions/run | 1,195,000,000 | 526,800,000 (−55.9%) |
| wall time | 0.06s | 0.03s |
| closure box per call | 1 (`avra_array_sized` + 2 pushes + `callptr`) | 0 |

`avra ir` on the same source confirms the shape directly: the OLD
compiler's `hot()` shows `avra_array_sized`, `avra_array_push_owned`
×2 and `callptr`; the NEW compiler's shows one `call Stmt.reset(...)`
and nothing else — the struct literal's own box (present in both,
unrelated to this change) is the only `avra_array_sized` left.

**Tests.** `features/defers/tests/direct_methods/` (program test,
eval == native == expected): a method defer on a managed receiver
reassigned after the `defer` (old value seen), several method defers
in one scope (last-registered first), fall-through/`return`/`fail`/`?`
exits, `errdefer` with a method call, a non-void answer discarded, a
managed free-call argument. Two new `then` blocks in
`defers_test.av` (receiver reassignment, non-void + ordering) and one
IR-shape assertion (no `avra_array_sized`/`avra_array_new`/`callptr`
for a method defer). The pre-existing `direct_shapes` (a callee
answering a value) and two `defers_adversarial_test.av` cases (a
managed capture, a `mut` string reassigned after the defer) now
exercise the widened path unchanged — both stayed green, which is
the regression proof for the generalization as much as the new tests
are the proof for methods.

What I wanted from the language while doing this: a promotable
narrow slice of `callee_of` — today "does this receiver's impl table
answer this name" is either the WHOLE dispatch precedence (import
`impls`, refused by layering) or a hand-copied re-derivation of one
arm (what `declared_method` is). A `pub(shared)`-shaped door — a
feature marking one fn as answerable by ANY feature, distinct from
both `export` (crosses packages) and package-private — would have
let `defers` ask the real `callee_of` instead of keeping a second,
narrower copy of its `.Declared` arm in sync by hand.

## §30 As built — R13, identical monomorphic copies merged

**The mechanism.** `object_written` (backend/llvm_wrapper.c) already
ran `default<O%d>` through `LLVMRunPasses` per emitted module; it now
calls `LLVMPassBuilderOptionsSetMergeFunctions(opts, 1)` first — the
same C-API knob clang's `-fmerge-functions` sets, folding a duplicate
body into a THUNK (a tail call/branch to the one it kept) rather than
a raw pass-string splice. One line, no new pipeline text.

**Why a thunk never merges an ADDRESS.** MergeFunctions has two
shapes: replace every USE of the duplicate with the canonical
function's value (legal only when the duplicate's address is not
itself observable — `unnamed_addr`), or leave the duplicate's own
symbol standing and rewrite its BODY to jump into the canonical one.
Avra's backend never marks a function `unnamed_addr` (grepped: the
only `LLVMSetUnnamedAddress` call in llvm_wrapper.c is on two STRING
globals, never a function), so every merge here takes the second
shape by construction — proved first in isolation
(`opt -passes='default<O2>,mergefunc'` on hand-written IR: an
external-linkage pair thunks with both addresses intact;
`unnamed_addr` on the same pair is what lets the optimizer
substitute one address for the other in a THIRD function that reads
`ptr @a`/`ptr @b` — confirming the property is exactly the mark's,
not a hope). Then proved on Avra itself: `pick_a`/`pick_b`, two
non-generic fns over different single-field managed structs
(`{v: string}`, `{v: List<int>}`), each passed as a VALUE into a
higher-order `via_a`/`via_b` (forcing `FnAddr` + an indirect call,
never a direct one) — `_av_pick_b` compiles to `b 0x…<_av_pick_a>`
(4 bytes, its OWN symbol, a live jump into the real body) while
`_av_pick_a` keeps its full ~208-byte implementation; both `via_a`
and `via_b` compute the right answer through the indirect call
(`eval == native`, `none/one|-1/2`), and `atos` on both addresses
still answers `av_pick_a`/`av_pick_b` by name. Avra also has no
channel that could notice a difference: `Type.Fn` is `false` under
`comparable()` (features/checks.av) — `==` on two fn values is F2000
before this ever reaches codegen — so the one operation that would
actually observe two merged fns sharing behavior is refused at the
type checker, independent of this change.

**The corpse that isn't reachable.** One pair — a private, non-generic,
single-call-site `first_of_a`/`first_of_b` (called directly, never
passed as a value) — merged into `b println+0x14`: a mid-function
OFFSET inside an unrelated fn. Alarming until traced: both call sites
get inlined by the ordinary O2 inliner, leaving the standalone bodies
with zero uses ANYWHERE in the module (confirmed: grepped the whole
binary's disassembly for their symbol names — no `bl`/`b` references
outside their own label), yet External linkage means LLVM cannot
delete them outright, so MergeFunctions is free to fold their
now-meaningless shells into whatever fits — the folded target's
CONTENT is irrelevant because nothing ever branches there. Avra's own
surface can't construct a caller for it either: no raw external
linkage crosses into an Avra program, and the only way to make a
private fn's address observable is the `$w`/`FnAddr` wrapper path,
which is exactly the path `pick_a`/`pick_b` proved safe above. Kept
as a finding, not a defect — it explains why a THUNK's target can
look nonsensical under `nm` without meaning anything is wrong.

**Numbers.** `build/avra.pre` (main 94619dd, unmodified) against the
rebuilt `build/avra`, fixed point proven (three successive
`make avra` byte-identical, `cmp` clean, confirmed twice after an
unrelated stale intermediate binary was caught and re-derived —
see the working-discipline note below):

| | before | after |
|---|---|---|
| `build/avra` (whole file) | 7,435,344 B | 7,256,160 B (−179,184, −2.41%) |
| `__text` | 5,205,556 B | 5,089,432 B (−116,124, −2.23%) |
| defined text symbols (`nm`) | 14,197 | 14,138 (−59) |

The symbol count barely moves because a thunk KEEPS its symbol —
almost every byte saved is a duplicate's BODY shrinking to 4 bytes,
not a symbol disappearing (`tools/symsize.py`'s per-symbol diff is
noisy here for the same reason: a merge into a fresh `private` shared
body, which `nm` never lists by name, misattributes its bytes to
whatever named symbol sorts next to it — read the TOTAL, not the
per-symbol rows, for this change).

Speed, `/usr/bin/time -l` "instructions retired", `.avra-cache`
cleared before every run compared (not only the first — the doctrine
line earns its keep here, see below), interleaved:

| | old | new | delta |
|---|---|---|---|
| `check packages/cli` ×3, avg | 173,389,501,232 | 173,484,953,394 | +0.055% (noise) |
| `build packages/cli` (full, incl. link) | 468,364,646,333 | 469,334,844,037 | +0.21% |

Speed is neutral within measurement noise for a check, and the one
real cost — running one more module pass at emit time — is 0.2% on
a full build of the compiler's own largest package, for a 2.4%
smaller binary. `make avra`'s WALL time swung 47s–70s across these
runs with other lanes' builds sharing the same 8 cores; instructions
retired is why that swing is not in this table.

**Cross-unit duplication, measured rather than guessed.** Per-file
splitting (`Owned.File`, `EMIT_WIDTH=4` workers) means MergeFunctions
only ever sees one file's own module — a `List<A>` and `List<B>`
walker homed to two different files never meet. Measured directly:
disassembled `build/avra.pre` and the rebuilt `build/avra` whole,
normalized every defined fn's instruction text (mnemonics + register
operands, immediates masked), hashed, and grouped the BASELINE's
duplicate-body clusters by declaring file (the mangled name's own
`~/path/to/file.av~N` suffix, or the declaring module when a
callsite-local fn carries none). 459 duplicate-body groups, 2048
participating symbols; of those, 146 are now thunks and 1425 are
still full duplicate bodies post-merge — most of the survivors sit in
groups this pass could never have reached (164 groups, an estimated
~21,500 duplicated instructions, ~86 KB, are cross-file). That is
real and roughly the same ORDER as what per-module merging already
captured (116 KB), not a multiple of it — a residual worth a future
ticket, not a reason to hold this one. `ld64` (this platform's
linker) has no identical-code-folding flag at all (`man ld`: nothing
answers to icf/fold/identical beyond `-dead_strip`, which is
unrelated); `lld` (which has `--icf=all`/`safe` for exactly this) is
not installed here and switching linkers is out of scope for this
slice per its own brief — reported, not applied.

**Red team.** `AVRA_RC_GUARD=1` and `AVRA_MEM_STATS=1` on small,
standalone programs only (never a guarded whole-package run):
`packages/std-avrac/src/compiler/tests/merge_functions` (two
per-file-homed generic instantiations over different pointer-shaped
managed structs, direct calls, empty-list case written first) and a
scratch probe pairing the same shape with indirect/address-taken
dispatch through a higher-order fn (`pick_a`/`pick_b`/`via_a`/`via_b`
above) — both 0 MB live in every category at exit, no trap, `eval ==
native == expected` on both. `atos` resolves every merged/thunked
symbol by its OWN name in both probes (a tail-call thunk never
touches `x30`, so a caller's return address still names the caller
correctly — traceability is unaffected for anything reachable, and
unreachable code, by definition, never traps to be misread). Attacks
covered: aliasing across the merge (two distinct callers of a shared
thunk seeing independently-owned data), a fn value stored and called
through a parameter (the address-taken case), a pointer-shaped
generic crossing two unrelated struct types, static/const list
literals as the argument, and the empty-input path first in both
probes. `python3 tools/idioms.py` (no new violations, debt unchanged
at 99), `make cited` (235/43 resolve, 10 licensed) both clean — no
`.av` source touched, so `avra fmt` does not apply.

**Critical checks.** `build/avra test packages/std-avrac`: every
program `eval == native == expected`, 113 examples proved as cases,
clean. `build/avra test packages/std-http`: 468/468 unit tests, 4
programs proved. `build/avra test packages/std-sqlite`: 505/505 unit
tests, 2 programs proved. `make runtime-tests`: box sizes, cores,
fibers, vtasks — 0 failed across all four. `avra ir` is unreachable
by this change by construction: nothing in core/compiler/typing or
lower.av moved, only the OBJECT-EMISSION pass list, so there is no
IR golden this ticket owns.

**A measurement lesson paid in this slice, not just cited.** The
first pass at the speed numbers used the pre-existing `build/avra`
this worktree started with as the "before" baseline and found `check
packages/cli` costing 60–170× MORE instructions after this change —
alarming, and wrong. That binary's own symbol table embedded a
DIFFERENT worktree's absolute path (`avra-reuse`, not `avra-r13`):
same commit in principle, but it failed outright on the CURRENT
source (`no fn verdict_of defined`, `no fn println defined` —
packages/cli/src/stage.av) on the very re-run that would have caught
it, then SUCCEEDED cleanly on a later, otherwise-identical re-run,
never reproducing the failure again across a dozen further
invocations. Read as "WHICH TREE" and "WHICH VERSION" (CLAUDE.md,
Working discipline): the saved `build/avra.pre` this worktree's own
AGENT_RULES already prescribes is the right baseline precisely
because it is a copy of THIS tree's own standing binary, not a
binary carried in from somewhere else — switching to it collapsed
the "60–170×" finding into the +0.055%/+0.21% table above. The one
non-reproducing failure is recorded, not explained; a transient
build failure on a shared 8-core machine running several other
lanes' compiles at once is exactly the shape CLAUDE.md's resource-
exhaustion entry describes, and it never recurred once isolated to
this worktree's own binaries.

What I wanted from the language while doing this: nothing new — this
slice never touched Avra source, only the C wrapper around one LLVM
pass-builder option, which is the whole point of a boundary that
lets a backend concern stay a backend concern.
## §30 As built — R15a, a Result side rides bool and float too — and a live landmine found, not disarmed

**D36. A Result side's word widens past int and a word enum to a bool
and a float.** Neither rides a pointer, so `side_word` (core/types.av)
answers `0` for both, exactly as it already did for `int`: `Result<bool,
E>`/`Result<float, E>` join `Result<int, E>` as value enums the moment
their OTHER side is one word too (`judge_result`, unchanged). The
LLVM backend's word slot was already an i64 whichever payload it
carries (`ll_type_of`'s `wide_ll_type([word, word])`, D28); packing a
bool into it used to go through the generic `avra_llvm_cast_to_type`,
which REFUSES to widen an integer without the caller naming a sign —
right for an ambiguous width, wrong for a bool, which has none. Routed
through `worded` instead (llvm_emit.av's `pack_value`), the SAME table
`rt_arg`'s I64 seats already use (`SlotForm.Widened` -> zext,
`.Reinterpreted` -> bitcast, `.Word` -> identity) — a THIRD caller of
an existing door, not a new one (GENERALIZE BEFORE ADDING). Extracting
the word back never needed a change: the aggregate slot is always i64,
so every direction out of it is a narrow or a same-width reinterpret,
which `avra_llvm_cast_to_type` already handled — the float
(int64<->double) branch there is real for the first time and no
longer "unreachable today" (backend/llvm_wrapper.c's own comment,
corrected). The rest of the machinery — `StaticBuild.slot_of`'s
`.Float`/`.Bool` arms, `slot_value`/`slot_mark` in llvm.av,
`slot_val` in interp.av, `is_managed`'s `counted_mask == 0` check —
was already generic over the payload's own shape and needed nothing:
built for `int` and never narrowed to it.

**Scoped to the Result side alone, on purpose — NOT the value-enum
payload law (`payload_word`, features/decls.av).** Widening
`payload_word` the same way (a DECLARED enum's own bool/float-carrying
variant becoming a word) reproduces cleanly and is provably the
narrower change: `side_word` alone (Result sides) rebuilds and
`avra test packages/std-avrac` runs clean end to end, twice, from a
saved pre-slice binary; `payload_word` alone (enum payloads, `side_word`
held back) traps `avra test packages/std-avrac` mid-suite with `index 0
is out of bounds (length 0)` inside `features/annotations` — declaration
generation, an annotation fn's `@traced` — and *with both widened
together* the same package instead SEGFAULTS inside the allocator's
free list (`array_made`, corrupted class bucket; `bt` bottoms out
through `avra_slot_unique`/`array_clone` from `spelled_static`, a
`once fn`'s own settlement). Isolated by A/B rebuild from
`build/avra.pre` each time (never mixed generations), not guessed.

**The implicated type, found by elimination, not proven to the
line:** `features/worklist.av`'s `MetaVal` — `Int(int) | Float(int) |
Text(string) | Bool(bool) | Absent | Gone | Node(int) | Map(int) |
Octets(List<int>)`, the ONE currency every compile-time value crosses
through (`literal_meta`, `Settled.answer`, annotation lift results) —
is the only enum among the compiler's own meta types with NO
disqualifying multi-field variant once `Bool` counts: `Kind` and
`Node` (`@std.meta`) both stay boxed regardless (a `Template`/`Interp`/
`Map`/`Result` variant already carries more than one field, and
`Kind`'s own `List(Kind)`/`Cell(Kind)`/`Opt(Kind)` self-reference is
refused by `same_decl`'s guard independently), so `MetaVal` is the
first enum in the tree this change makes eligible with no other
excuse. `MetaVal`'s own crossing code (`MetaHeap.slots`/`.node`/
`.adopt`, `val_of`/`meta_of` in interp.av, `StaticBuild.slot_of`'s
`.Enum`/`.Res` arms) reads as fully generic under inspection — ordinary
matches, no hand-rolled slot arithmetic found — so the defect was not
isolated to a line in the time this slice had. NAMED FOR THE NEXT
SESSION, not fixed: widen `payload_word` to admit `.Float or .Bool`
(mirroring this slice's `side_word` edit, comment already there at the
site), then chase the trap with `AVRA_QTRACE=1`/a debug build of
`array_reclaim`/`box_free` rather than blind bisection — this slice's
bisection (four A/B rebuilds, ~30 min each) found WHICH half breaks,
not WHERE.

**Red team.** A standalone probe (`Holder { r: Result<bool, string> }`,
no `use`) built and run under `AVRA_RC_GUARD=1`/`AVRA_MEM_STATS=1`:
a record field copied then written through the copy, `with`, a `Cell`
seat, a `dyn Shows` door, a generic `through<T>` door, a scalar `const`
Result and a `const List<Result<float, string>>`, 2000 loop turns —
eval == native, 0 MB live in every category at exit. The empty-value
law: `parse("f")` (an Ok `false`) and `Result<bool, E>?` both round-trip
present, never absent (`features/results/tests/scalar_results`, eval ==
native == expected — `avra test packages/std-avrac` end to end). The
program test pins float bit patterns directly, never through the
default print (`${x}` collapses `-0.0`, `0.0` and a subnormal alike):
`-0.0` via `0.0 * -1.0` checked by `1.0 / x < 0.0`, `NaN` via `x != x`,
`+inf`/`-inf` via `x == x / 2.0` at each sign, a subnormal via 1074
halvings of `1.0` compared against a FRESH independent call to the
same builder (a bit-exact equality, not a printed string). `@std/sqlite`'s
`Stmt.step() -> Result<bool, SqlError>` (the ticket's own motivating
site — `SqlError` is a multi-field record, one counted pointer word) —
`check packages/std-sqlite` clean; its native suite needs `make libs`
(a local `sqlite3`), not run this slice.

**Numbers** (Mac, `/usr/bin/time -l`, interleaved, 3 rounds, a
`-> Result<bool, string>` fn called 5,000,000 times in a loop, against
the exact pre-slice source and compiler):

| | before | after |
|---|---|---|
| instructions/call | 105.4 | 81.4 (−22.7%) |
| `build/avra` | 7,433,344 B | 7,431,904 B (−1,440 B) |

What I wanted from the language while doing this: a way to ask the
type registry "what does this declared enum's layout depend on" —
this slice spent real time manually re-deriving, per candidate type,
whether a multi-field variant or a self-reference already disqualified
it, exactly the kind of question `avra explain repr` answers for ONE
type but not for "which types does widening THIS rule move".

## §30 As built — R5, count elision at the call-crossing retain

**The target.** §6 named it: "R3 consuming params... params are
borrowed, so a `with` on a param can never reuse." R5's own slot
(avra-8sb5.34.7) narrowed further after two rounds of measurement —
static literals and value enums, not stack placement — to "no
retain/release on a box that never escapes the fn that made it."
Escape analysis for STACK PLACEMENT was already tried and shelved
(2026-09-24 comments on the ticket: only 1 of 10 request boxes never
escape its fn). This slice is a DIFFERENT elision at the same
doctrine: not "does the box ever leave," but "does THIS call ever
reach it."

**D15. A view crossing a user call is guarded only when the call is
ALSO handed its root.** `Call`/`CallPtr`'s defensive retain (memory.av
§ THE CALLER KEEPS ITS ARGUMENTS STANDING) protects a VIEW — a struct
field read, a lending row's answer — against "the callee may empty
the box it looks into." But a callee can only empty a box it holds a
SEAT on (THE ROOT OF A PATH DECIDES WHERE A WRITE LANDS, CLAUDE.md):
Avra has no ambient mutable state, so a call that never receives a
view's root — walked back through Extract and a lending row's own
view, `Lives.root_of` — cannot reach it, let alone write through it.
`root_handed` asks `lent_args(i).any(same_reg(it, life.root_of(ar)))`
per lent arg; the guard stays for every arg whose root the call
itself also receives, or that has no view behind it at all (`ar`
roots at `ar`, trivially among its own call's seats).

**D16. `root_of` answers ABSENT at a Load, on purpose.** A `mut`
binding's cell can be read by more than one `Load`, each its own
SSA register for the SAME box — register identity cannot say a later
argument is "the same" root when it arrived through a second load.
The first draft compared registers all the way down and broke
`features/fns/tests/borrowed_params`' `emptied` fn: `emptied(b,
b.rows[0])` reads `b` once (`avra_cell_thawed`, for the `mut` seat)
and again (`load`, to walk `.rows[0]`) — TWO DIFFERENT REGISTERS for
one box. `root_of(b.rows[0])` walked to the second load's register;
the call's own arg was the first; `same_reg` said no; the retain was
elided; `b.rows = []` inside `emptied` freed the list `row` still
pointed at; native answered `2` where eval and `.expected` both say
`s1`. `root_of` now returns absent the moment its walk meets ANY
`.Load`, and `root_handed` reads absence as "reachable" — conservative,
never wrong. `features/fns/tests/borrowed_params` caught this on the
FIRST run of the full suite, exactly as its own header promises
("each rule witnessed failing without it").

**Why the upstream owned-twin mostly already covers same-call
co-occurrence, and why that is not a proof.** For a LENDING CallRt
view (`avra_array_get`, `avra_map_get`), `read_outlives`/
`borrow_outlives` already walks forward from the read and — because
its "did the slot change" scan (`leaves_or_changes`) treats ANY later
instruction reading the SAME register as a possible change — upgrades
the read to its owned twin the moment the call ALSO reads that exact
register. Every hand-built same-call-co-occurrence case
(`viewed_seat_with_root`, §below) is intercepted there, before
`root_handed` ever runs. `emptied`'s witness is the case that
mechanism cannot see: the register the call receives (`b`, thawed for
the `mut` seat) and the register the view's chain passes through
(`b` reloaded) are DIFFERENT SSA names for the same box, and
`changes_cell`'s scan is register-identity, not box-identity. D16 is
what closes that gap; it is also why `root_handed`'s guard-still-owed
branch is a genuine SAFETY NET more than a frequently-taken one under
today's lowering — proven necessary by one real defect, not by a
dense trace of daily hits.

**Guards witnessed failing.** `python3` was not used; the guard was
removed literally, by reverting D16 to `Reg` (as first written), and
`build/avra test packages/std-avrac` was run: `borrowed_params`
failed exactly as described. Restoring D16 turned it back to
`s1`/green.

**Red team**, native under `AVRA_RC_GUARD=1`, matched against
eval and (where noise-free) against the baseline compiler's own
identical memory report:
| attack | shape | result |
|---|---|---|
| nested view chain, `mut` seat clears the parent | `type Inner`/`Outer`, `peek(mut o, o.inner.xs)` | `z0 cleared` both engines; unguarded mem stats byte-identical to baseline |
| same hazard through a `Cell`, not a seat | `Cell<Bag>`, `clear(c)` after `c.get().xs` | `c` both engines |
| loop-carried root, view read each turn, root never passed | `for i in 0..5 { total + width(r.cells) }` | `15` both |
| recursion, a view of a param passed down, never the param | `sum_from`/`peek`, param vs. view forms | `30` both |
| `defer` writing a `mut` seat after a view of its old value | `run(mut s)`, `defer { s.items = [...] }` | refused by the language itself (a capture is a copy) — not a shape this door reaches |
| `?` propagation crossing a call with a view alongside the record | `read(d: Doc)`, `first_line(d.lines)?` | `x/2` both |
| a view stored past its originating call, into a list, each loop turn | `saved.push(keep(r.xs))` | `9` both |
| two captured fns, the SAME lane read twice | `let a = () -> 1; let b = () -> a() + a()` | both `callptr` seats unretained, `avra_array_get` (not `_owned`) on both reads |

Every attack is also in `packages/std-avrac/src/compiler/tests/
lower_test.av`'s "the ownership roles read as behavior" / "calls
through boxes wear the callee's type" — `no_callptr_seat_retained`,
`viewed_seat` (elided) and `viewed_seat_with_root` (still guarded,
via the owned-twin) replace the three assertions this slice made
false by making the IR strictly BETTER than they expected.

**Numbers.** Fixed point: three successive `make avra` after the
final change gave byte-identical binaries (`cmp` on cache-forced
rebuilds, .avra-cache moved aside each time). Instructions retired,
`/usr/bin/time -l`, interleaved, 3 rounds, `.avra-cache` moved aside
before every `check` round:

| | before (main 94619dd) | after |
|---|---|---|
| tools/bench/request, 5,000,000 requests | 54.63B instr (avg) | 53.95B instr (avg) — −1.2% |
| `check packages/cli` | 173.8B instr (avg) | 166.6B instr (avg) — −4.1% |

Consistent in every round both ways (request: 54.51/54.73/54.64 →
54.01/53.93/53.92; cli: 173.09/173.76/174.53 → 166.47/166.90/166.46).
The compiler's own source is the better witness: `self`-and-a-field
crossing a method call is the common shape this door reaches (an
OOP-heavy tree), where the request bench's remaining allocations are
mostly records and lists that never cross a call as a view at all
(§6's own finding, unchanged). Diagnostics identical between old and
new (122 warnings, same lines) — behavior unchanged, only the count
lower. `make census` was not run: it drives `./avra` through
`tools/watch.sh`, which this campaign's standing order (AGENT_RULES)
forbids; instructions retired is this tree's own preferred proof for
exactly that reason.

What I wanted from the language while doing this: a way to assert
"these two SSA registers are loads of the same untouched cell"
directly, rather than by absence. `root_of` answering `Reg?` and
treating `null` as "conservative" reads right, but the same shape
(a value that MAY alias across more than one register, and a pass
that must answer soundly without knowing) will recur anywhere a `mut`
seat and a plain read of the same binding meet — a `same_box`
predicate over `Lives`, keyed on the CELL rather than the register,
would let a pass answer the sharper question instead of falling back
to "unknown, so guard."

## §31 R3 design — consuming params (not built)

**Why this is a design, not a slice.** avra-8sb5.34.4's ticket already
warns "Perceus owns params" is a calling-convention change; ROADMAP's
own ladder entry for R5 says "Consuming params (R3) fold in here,"
naming it as the same doctrine, not the same size. Every load-bearing
mechanism this needs is a TOUCH POINT in `SeatMark`, `fn_fits`,
`Body`, and BOTH sides of `.Call`/`.CallPtr` in memory.av — the same
shape as R1 itself (§4), which had its own red-team table and its own
landing. Attempting it inside R5's slice risks exactly what AGENT_RULES
warns against: "a wrong elision is a use-after-free that tests may
not see," compounded by a HALF-BUILT calling convention with no
red team of its own. R5 (§30) already found and fixed one real
use-after-free from a much narrower change; this is not the moment to
also carry an unfinished one. What follows is grounded in the actual
call sites (file:line), not a sketch.

**D17. Ownership is a SEAT MARK, not a per-call decision.** The ticket
offers two designs — "per seat from the callee's body" or "per call, a
dying argument at an owning seat" — and names the deciding constraint
itself: "keep ONE calling convention per fn symbol." A per-call choice
means the SAME callee compiles two ways depending on who calls it, or
carries a runtime branch; CLAUDE.md's fn-type-marks law exists
precisely to rule this out ("a `mut`-taking fn stored in a plain fn
seat wrote through an immutable `let` with no diagnostic, in both
engines," the defect a mark-on-the-TYPE closes). So: a FOURTH mark,
alongside `mutable`/`settled`/`unshared` — `SeatMark { mutable: bool,
settled: bool, unshared: bool = false, owned: bool = false }`
(core/types.av:792, appended — a GROWTH, not a move). The word is the
owner's to choose; `owned` is the working name below (Perceus calls
this the same thing; the runtime already says "owned twin" for the
analogous runtime-row contract).

**Grammar.** `features/fns/mod.av:40`'s `fn` rule already spells three
optional prefix words per parameter: `( ck:"const" )? ( mk:"mut" )?
( ik:"isolated" )? ps:NAME`. A fourth slot joins them (trailing comma
law unaffected — this is a prefix, not a list). The SAME rule serves
`extern fn` (line 39) and `once fn` (line 41); whether `owned` reaches
those too is a real question — an extern's inout seat already takes
the CALLER's cell address (`host_regs`, features/fns/lower.av:44), a
different crossing than an Avra-to-Avra `owned` transfer, and a `once
fn` takes no arguments at all (F2055) so the question does not reach
it.

**Type system.**
- `owned_mark(marks, j) -> bool` beside `mut_mark`/`settled_mark`/
  `isolated_mark` (core/types.av:817-829).
- `fn_fits` (features/checks.av:86-103) gains one more line in the
  per-seat loop, the SAME asymmetry direction as the other three:
  `if owned_mark(g.marks, j) && !owned_mark(w.marks, j) { fits = false
  }` — a value that consumes seat `j` cannot be smuggled into a seat
  type that never promised to consume it, or a caller through a
  DIFFERENT (unmarked) seat type would keep believing it still owns
  the argument after the call.
- `mark_word` (types.av:843-855) encodes the three existing marks as
  ONE letter each (`p/m/c/b/P/M/C/B` by `unshared`×`mutable`×
  `settled`); a fourth boolean doubles the space to sixteen. Folding
  it into the same letter is the wrong shape — spell it as a SECOND
  character per seat (`mark_word`'s existing letter, then `o` or
  nothing), so the interner's key stays one string and the doubling
  does not have to invent eight new letters nobody can read.
- `declared_marks`/`marks_of` (features/checks.av:1005,
  features/decls.av:971) read the parsed `owned` flag the same way
  they read `const`/`mut`/`isolated` today.
- A NEW REFUSAL: `owned` combined with `mut` on the same seat. The two
  are opposed by what they promise — `mut` is shared, caller-visible
  writing; `owned` is exclusive consumption, nothing left for the
  caller to see written back through. `fn f(owned mut x: T)` refuses,
  licensed at the seat, own F-code.
- Whether `owned self` is legal (a builder's `fn build(owned self) ->
  Output`) is a real, useful case (Rust's `self` consumption) and a
  real question for the receiver's own seat-mark plumbing — worth
  landing, not worth deciding here.

**Lowering, the callee's side — the smaller half.** `Body` (compiler/
lower/lower.av:71-89) gains `marks: List<SeatMark> = no_marks(...)`
— sized to `params.length`, a GROWTH at all seven construction sites
(lower.av:275, 511, 542, 566, 580, 608, 767, 789), most of which
already have `FnSig`/`Decls` in scope to read it from (`lower_fn` at
511 already threads a declared `Decl x`); the synthetic bodies
(`lower_lambda`, `lower_collect`, `lower_root`, `lower_main`,
`wrapped_body`, `unboxing_body`) take `no_marks` since none of them
declare a param a caller could mark `owned`. In `memory.av`,
`standing_regs` (line 73-80) currently marks EVERY param standing
unconditionally (`j < seats`); an `owned` seat must NOT be standing —
it is genuinely scope-owned, so the entry scope's `manages()` must
also SEED it at function start (right after the body's own
`ScopeEnter`, before the first instruction that could read a param):
`for j in 0..seats { if owned_mark(marks, j) { takes(open_scopes,
Reg{index: j}) } }`. THAT ALONE closes the loop: `Lives.handover`
already asks `owned_top(open_scopes, r)` (line 647) with no idea
WHERE a register's ownership came from, so `with`/`concat` on an
owned param takes the R1 reusing twin the moment it dies there, for
free — R3 does not touch R1's Handover logic at all, which is the
whole point of making ownership a SCOPE fact rather than a special
case. And `FnExit`/`ScopeExit`'s existing release-what-the-scope-owns
logic (`releases_for`, `exit_releases`) already frees an owned param
that nothing ever moved — an early `return` before touching it
releases correctly with NO new code, because it is now indistinguishable
from any other locally-owned value.

**Lowering, the caller's side — the real work.** At a `.Call`/
`.CallPtr` whose callee's `j`-th seat is `owned` (resolved for `.Call`
through a `name -> marks` map built once from `l.fns` in `memory()`;
for `.CallPtr` read directly off the callee register's OWN type,
`types.arrow_parts(reg_types[f.index]).marks` — no new plumbing there,
since `TypeRegistry` already carries it), the caller decides PER
ARGUMENT, Perceus-style, using the SAME `dies_at`/`owned_top` question
R1 already asks of a `CallRt`'s first seat (`Lives.moves`, line
664-667) — generalized from "the innermost scope owns it and it dies
here" to any owned-seat argument of a `.Call`/`.CallPtr`:
- DIES here, scope-owned: hand the existing reference over — no
  retain, and `disowns(open_scopes, ar)` instead of the scope's own
  eventual release (the reference moved to the callee, who now owes
  it).
- Does not die, or is not scope-owned (a param passed through, a cell
  load, an immortal): mint the callee its OWN reference — `Retain(ar)`
  before the call, the same shape `moved_out` already uses for a yield
  the closing scope does not own (memory.av:450-457).
This is genuinely NEW code in the `.Call`/`.CallPtr` arm (line 177 the
`lent` computation for standard seats stays exactly as R5 left it, for
every non-`owned` seat; an `owned` seat is excluded from THAT
treatment entirely and goes through this one instead) — nothing here
reuses `root_handed` (§30), because an `owned` seat's hazard is not
"can the callee reach the box," it is "who releases it," a different
question the R1 vocabulary already answers.

**Red team a landing owes (none of it run — this is the list, not the
proof).** Every attack in §30's own table, replayed with an `owned`
seat where §30 used a plain one; plus, specific to consumption: a
value passed to an owned seat and used AGAIN by the caller afterward
(must retain, must NOT double-free); the same call site inside a LOOP
(an owned argument minted fresh each turn dies each turn — the R1
loop-condition law, "the condition runs every turn," is the same
hazard one level up: an owned param settled ONCE after the loop
instead of once per call would leak or double-release exactly as an
unsettled `LoopCond` mint did); recursion passing the SAME owned
param down every level (each frame must own exactly one reference,
never the caller's); a `dyn`/`CallPtr` call through a stored closure
whose STATIC type disagrees with the concrete callee's marks (must be
refused by `fn_fits` at typing, before lowering ever sees it — the
adversarial case is proving that refusal fires, not that lowering
handles it); `defer`/`errdefer` capturing an owned param (does a
capture, itself a copy per CLAUDE.md's capture law, transfer or merely
alias the ownership the entry scope seeded?); an owned seat's value
ALSO handed to a `mut` seat of the SAME call (refused at the type
level once `owned mut` is refused, but a DIFFERENT owned seat plus a
DIFFERENT mut seat, same call, aliased argument, is not refused by
that rule and needs its own attack). A fixed-point build and
instructions-retired numbers on `with_host`-shaped code (the ticket's
own witness fn) close the slice, the same way §30's did.

What I wanted from the language while designing this (not while
building it, since I built none of it): the SeatMark growth is now
four independent booleans threaded through SEVEN construction sites
and re-encoded by hand in `mark_word`'s letter table each time one is
added — the THIRD time this exact shape has happened (`unshared` was
the last one). A declared-marks record that derives its own
interner-key encoding from its own field list, rather than a hand-kept
letter table one commit behind the type, would turn "did I remember
every site" from a code-review question into a compiler-enforced one.
## §30 As built — R9, a capture-free closure is static data

**The waste.** `xs.all(it > 3)`, a named fn passed as a value
(`xs.any(big)`), and a capture-free `defer` body all minted a fresh
`avra_array_sized(1)` + `Ins.FnAddr` + `push` box on EVERY read —
allocation and a header for one word (a code address) that never
varies. `fn_value_reg`'s box is ALWAYS captureless (the caller
supplies no captures for a bare name), so every named-fn-as-value
read paid this in full.

**D28. A box with no captures holds nothing a caller could vary, so
it is laid out once, as a `Static`** (the D26 mechanism — `Slot`
gains `Code(sym)`, a box's own code-address slot, alongside `Int`,
`Text`, `Box`). `values.av`'s `static_fn_box(sh, sym)` mints a
one-box `Static` (`StaticBox.Slots([Slot.Code(sym)])`) and emits
`Ins.StaticAddr` — the SAME array shape a dynamic closure box wears
(header, `AvraArray`, one cell), so `slot_read(box, 0, …)` and
`called_through` need not know which kind of box they hold. A
lambda WITH captures keeps `fn_box`'s dynamic path (its captures
differ per read); a capture-free lambda (`lambda_reg`, checked via
`caps.is_empty()`) and a named fn as a value (`fn_value_reg`,
`collect_fn_reg` — always captureless) take the static one, always.

**The backend's other half.** `slot_mark` answers `Code` as mark 0
(a plain word, never counted — matching `push_slot`'s own dynamic
code-address slot, which is `Type.Int` and never retained). LLVM's
`slot_value` answers the function's own `LLVMValueRef` — no cast
needed, since `avra_llvm_static_array`'s C side already `ptrtoint`s
any pointer-shaped cell. The evaluator's `slot_val` answers
`self.fn_addr_val(sym)`, the same body-index lookup `Ins.FnAddr`
already used.

**THE MODULE-SPLIT TRAP, found by the second build compiling
itself.** A split module's `declare_user` runs only for bodies
`refs_of` marks reachable, and `refs_of` scanned INSTRUCTIONS
(`body_symbol`) for a callee's name — never a `Static`'s own boxes.
A wrapper referenced ONLY through its `Slot.Code` (no `Ins.FnAddr`
anywhere once the box went static) was never declared in the module
that laid its static out, and `avra_llvm_get_named_function` answered
NULL — `avra_llvm_static_array`'s `LLVMTypeOf(NULL)` segfaulted
compiling `packages/cli` with itself, gen-2. THE LAW: a static that
names a code address is a body reference as real as an instruction's,
and `refs_of` must read both. Fixed by folding each module's OWN
statics' `Slot.Code` symbols into its reachable-bodies set
(`core.static_code_syms`, one definition `refs_of` and the tests
both call — the third-copy law paid before a second copy could
exist). Isolated by tracing: `avra ir` on the same source, twice,
byte-identical — proving lowering was never the culprit — before
`avra_llvm_static_array`'s frame named the actual NULL.

**Guards witnessed.** A capture-free lambda: called from a loop, a
list, a record field COPIED then written through (`mut copy = x`)
and `with`, crossing a `dyn` door, a named fn through a generic
call, recursion through a fn-typed parameter, an early `return`
reading the box after — `features/tests/static_fn_box`, eval ==
native == expected, the empty case (`() -> 0`) first. Native under
`AVRA_RC_GUARD=1` + `AVRA_MEM_STATS=1`: 0 MB live at exit, every
category. A 100 000-iteration loop through a named fn value: 0 MB
peak — the static box is read, never built.

**Numbers.** A 2 000 000-iteration loop building `[1, 2, 3, 4, 5]`
(already static, D26) and calling `.any(it > 3)`: 605M → 210M
instructions retired (~198/iteration), `avra_array_sized` in the
loop body 1 → 0. `check packages/std-avrac`: no new idiom debt (one
STALE baseline site pruned by the same run, unrelated to this
slice — `lists_test.av`, `make idioms-accept`). Fixed point: three
successive `make avra`, byte-identical, `.avra-cache` cleared before
each (a first, uncleared comparison chain read as unstable and was
not — the lesson is CLAUDE.md's own: clear the cache before any
before/after, always).

What I wanted from the language while doing this: `Slot`'s three
new consumers (`slot_mark`, `slot_value`, `slot_val`) are each a
five-line exhaustive match with one answering arm added — the
REGISTRY law working exactly as designed, catching every site at
compile time. What I wanted was for the FIRST of the three
(`llvm.av`'s `slot_mark`) to have told me the other two existed
before I found them one crash and one test failure at a time; a
`rule` that groups a NEW variant's every consumer into one
worklist (today: `make idioms`/`avra check` name them one at a
time, in whatever order the build happens to fail) would have
turned three discoveries into one.

## §32 As built — L3, sound-by-construction test runs

**The target** (avra-8sb5.34.30.3). Tonight's R5 use-after-free was
caught only because one existing program test happened to read the
freed value — luck, not a guarantee. The ask: every program test that
`avra test` already proves `eval == native == expected` for should
ALSO run its native binary once under `AVRA_RC_GUARD=1` (a stale read
answers garbage or traps instead of finding a plausible value) and
once under `AVRA_MEM_STATS=1` (0 live bytes at exit), systematically,
with `once fn` caches and static aggregates excluded on their own
terms rather than allow-listed.

**D1. The runtime's accounting has no EXACT signal, and a `once`
cache is not excluded from it.** `AVRA_MEM_STATS`'s existing report is
MB-rounded — a small program test's leak is bytes, and `>> 20` floors
it to zero — and its "peak/now" figures never come back down for a
`once` answer, because `avra_once_set` marks it `KIND_IMMORTAL`
(runtime/avra_box.h) and retain/release both no-op on a negative
kind: the bytes were added once at allocation and never subtracted,
by design, since the cache holds the answer for the process's life.
Measured on a scratch `once fn cached_dynamic() -> string`: 75 bytes
"still live" under the OLD report, forever, on every run.

**D2. `g_mortal_live`, a second always-on counter beside the
existing `g_live_bytes`, and a credit paid at the moment of
promotion, not read back from the header.** `acc_box`/`acc_add`
(runtime/avra_runtime.c) add to it exactly when `kind >= 0` — a
STATIC box (`str_static`, kind `-1` from birth: argv, env, keywords)
never enters it at all, matching "A SETTLED AGGREGATE IS STATIC
DATA." `avra_once_set` walks the value's OWN shape (`once_box_credit`
— box, buffer and every OWNED array/map slot, recursively, the same
walk `array_reclaim`/`map_reclaim` would make to free it) and
subtracts that whole footprint from the ledger in the SAME
call, BEFORE flipping the kind to immortal — while the kind still
names its true shape, which is what makes the walk unambiguous. A
report-time walk (the first draft) cannot tell a genuinely-promoted
box from one baked immortal by the backend at compile time (a
constant-foldable `once fn` body IS laid out as static data, kind
already negative the first time `avra_once_set` ever sees it) —
crediting that box's bytes on top of a ledger it never touched drove
`g_mortal_live` NEGATIVE. Promotion-time credit needs no such guess:
`vh->kind >= 0` is the exact question "did this box ever enter the
ledger," asked at the one moment the answer is certain. A KIND_PLAIN
box (a record, an enum) has no runtime-visible owned-field marks —
the compiler releases those by name, never by a mark the runtime
walks — so a `once fn` answering a record or enum with a managed
field is undercredited; no case in this tree exercises it, and it is
a recorded trigger for the day one does. `runtime/avra_runtime.c`
gained one new line under `AVRA_MEM_STATS`: `mem: live N bytes at
exit`, exact, which is the one line the soundness runner reads.

**D3. Two real, silent leaks, found by turning the instrument on the
compiler's own test-running code.** `suite_entry.av` hand-builds the
suite's `main` in raw `Ins` — outside the memory pass entirely, which
never sees hand-built IR — and TWO of its runtime calls minted an
owned string and never released it: `tally_line`'s `avra_int_text` +
`avra_str_concat` answer (the "N/M tests passed" line — leaked on
EVERY suite, spec-case count irrelevant, since it runs once per
suite) and `one_program`'s `avra_capture_end` answer (`got`, the
program's captured output — leaked on every PROGRAM test, sized to
its output). Neither touched any observable output; `eval == native
== expected` and every spec case stayed green through both, which is
exactly the class of bug a diff-the-answer check cannot see. Fixed
with one `Ins.Release` each, in place (suite_entry.av), mirroring
what a lowered body would have emitted for itself.

**D4. The soundness runs are gated on `AVRA_SOUNDNESS`, not
default.** Measured on `packages/std-avrac`'s own (large) suite
binary directly: a plain run is 21.6s wall; the SAME binary under
`AVRA_RC_GUARD=1` is 49.6s (2.3×) and, worse, EXITS RED — one spec
case, `features/crossing`'s "five thousand directives cross and
every one of them declares nothing," fails only under the guard.
That spec drives a NESTED compile of a generated 5000-directive
program through `real(...).check()`; the likeliest cause (not fully
traced to its root) is that guard mode never actually frees
anything, so `avra_mem_live()` — the always-on counter a
budget/settlement ceiling reads, per CLAUDE.md's BUDGET MEASUREMENT
entry — reports far more "still held" than the real occupancy the
budget was sized against, tripping a ceiling a plain run never
approaches. This is a genuine interaction between the guard and an
existing resource ceiling, not a UAF and not a defect in this
slice's own mechanism (the SAME binary passes `AVRA_MEM_STATS=1`
clean, and every other of std-avrac's 6805 cases and every program
test passes guarded); it is reported here, with its repro, rather
than allow-listed. Given that and the wall-time cost, the two extra
runs are opt-in (`AVRA_SOUNDNESS=1`, read once per suite in
`packages/cli/src/stage.av`'s `first_red`) — `avra test`'s default
behavior and cost are UNCHANGED. Wiring the flag into `make gate`'s
own invocation is left to whoever resolves the crossing budget
question; small and mid-sized packages (see numbers) pay only
milliseconds and could reasonably default it on sooner.

**Negative witnesses**, both a real bug reintroduced and reverted,
each shown failing then clean:
- The leak (D3), reverted by deleting its three `Ins.Release` lines:
  a fresh scratch package (`spec "trivial" { given "nothing" { then
  "true is true" { true } } }`) shows `1/1 tests passed` and
  `eval == native == expected` — every check that existed before
  tonight, GREEN — while `AVRA_SOUNDNESS=1` fails it: `AVRA_MEM_STATS=1:
  70 bytes still live at exit`, exit 1. Restored: exit 0, 0 bytes.
- R5's own first-draft bug (§30 above), reverted by deleting
  `root_of`'s `if self.ins[d] is .Load { return null }` line: the
  full suite's `borrowed_params` answers `2` for `s1` exactly as
  originally found — caught by the EXISTING `eval != native` check
  too, since the miscompile is native-only and this campaign already
  runs both engines, so it is not a "passes today, fails mine" case.
  Isolated to a ten-line scratch program (`emptied(mut b, row)`
  emptying `b.rows` while `row` still points at the same freed list),
  the UNGUARDED native run answers `0` (a stale read landing on
  reused memory, not a crash — the silent-wrong-value shape the
  guard exists for) while `AVRA_RC_GUARD=1` traps outright: `avra:
  array_get read a RELEASED box`. Restored: `s1 gone 0` both ways,
  guard clean.

**Critical checks.** `build/avra test packages/std-avrac`:
6805/6805 spec cases, every program test, green (repeated after
every change in this slice). `build/avra test packages/cli`: 77/77.
`build/avra test packages/std-process`: 118/118 + 2 programs (the
`Command`/`Env`/`outcome` surface this slice calls). `build/avra test
packages/std-text`: 113/113 + 2 programs (`parse_int`, the one this
slice calls to read the ledger's line). `python3 tools/idioms.py`:
no new violations (148 pre-existing debt sites, 648 files, 20
packages). `build/avra fmt` identical on both touched `.av` files.
`make cited` fails on `fn_params` (a stale licence in
`tools/cited.allow` naming `features/code.av`) — untouched by this
slice's three files (`packages/cli/src/stage.av`,
`packages/std-avrac/src/compiler/suite_entry.av`,
`runtime/avra_runtime.c`) and reproduces before any of them changed.

**Numbers.** Fixed point: three successive `make avra`,
`.avra-cache` moved aside before each, byte-identical
(`cmp build/avra.g1 build/avra.g2`, `cmp build/avra.g2
build/avra.g3`). Cost, `packages/std-avrac`'s own suite binary run
directly, `time`, warm: plain 21.6s / 15.0s user; `AVRA_RC_GUARD=1`
49.6s / 24.9s user (2.3×, and red — D4); `AVRA_MEM_STATS=1` 37.8s /
18.0s user (1.75×). `build/avra test packages/std-avrac` end to end,
`/usr/bin/time -l`, `.avra-cache` cleared: without the flag,
307.30s real / 1,219.0B instructions retired / 588 MB peak; with
`AVRA_SOUNDNESS=1`, 540.62s real (+76%) / 1,223.8B instructions
(+0.4%) / 595 MB peak. Instructions retired barely moves — the added
cost is almost entirely WALL TIME spent spawning and draining child
processes (`@std.process`'s default `drain_grace: secs(2)` per
`Command`), not CPU; on a small package (`std-path`, one suite, one
program test) the two extra runs cost under 50ms end to end,
noise-level against the package's own compile.

What I wanted from the language while doing this: a `once fn`'s
answer becoming immortal is a runtime FACT (`avra_box.h`'s
`KIND_IMMORTAL`) with no Avra-level name — `core/ir.av`'s vocabulary
has no way to ask "is this the process's one instance" from inside a
pass, so a future pass that wants to reason about `once`-cache
lifetime (this slice's runtime C code aside) has nothing to read.
And the deeper one: `avra_mem_live()`'s use as a budget ceiling and
`AVRA_RC_GUARD`'s use as a correctness net are two INSTRUMENTS built
to answer different questions, sharing one counter that only one of
them owns — D4 is that seam showing up as a false positive, and the
fix belongs to whichever of the two is willing to stop reading the
other's number.
## §32 As built — L1, a layout fact is write-once-after-read (SOUND BY CONSTRUCTION, avra-8sb5.34.30.1)

**The bug class.** R11c (avra-8sb5.34.21) computed a value enum's
counted mask from a payload record's FLATNESS, and a LATER `mut`
seat sealed that record — the mask went stale, silently, and a list
of those enums use-after-freed natively. CLAUDE.md already names the
law this breaks twice over ("WHETHER A VALUE RIDES A POINTER IS ITS
DECLARATION'S ANSWER", "A NAME … ITS MARK IS MADE AT ITS
DECLARATION"): a fact answered by declaration order is wrong the
moment something reads it before that order settles. The fix makes
the read side of that law a COMPILER DEFECT instead of a hope.

**D1. RepRow gains four read-tracking bits, one per fact bucket.**
`fields`/`boxed_flat` share ONE bucket (`Flat` — sealing moves both
in the same step), and `valued`/`counted` share another (`Valued`).
`Settled` and `Named` (`stands_for`) are their own. `LayoutFact` is
the registry (four variants, `note`/`was_read`/`fact_word` spell
every arm — no `_ ->`). Every PUBLIC read (`flat_fields`, `is_flat`,
`is_wide`, `boxed_flat`, `is_valued`, `counted_mask`, `is_settled`,
`stands_for`) routes through `note(id, fact)`, which marks the
bucket read ONCE — the guard every reader already pays (`if
!was_read`) is the SAME guard that makes the mark cheap: after the
first ask, every later one is a bit test. Reads a write method takes
of its OWN gate (`sealed`, in `mark_flat`/`mark_valued`; `stands_for`
as `unflatten`'s early-out) stay on the raw field — the registry's
own bookkeeping is not a consumer relying on the answer.

**D2. Every write is checked-and-refused, never checked-and-warned.**
`mark_flat`, `mark_valued`, `mark_settled`, `mark_named`, `unflatten`
each: read the current row, decide whether the write actually
CHANGES anything (a same-value write is always let through, matching
the ticket's "a write that doesn't change the answer is fine"), and
if the bucket was already read AND the value would move, call
`flag_stale(id, fact, cause)` and RETURN — the corrupting write never
lands, so the fact a caller already holds cannot go stale under it.
`flag_stale` appends a `LayoutStale { id, fact, cause }` to a new
`stale: Cell<List<LayoutStale>>` on `TypeRegistry` — plain data, no
diagnostic machinery, because `unflatten` fires from `intern()`,
which is CORE and cannot see a `Diagnostic` (layering: core -> query
-> grammar -> features -> compiler). `drain_stale()` turns the log
into worded strings (`\`Id\`'s flatness was read before a \`mut\`
seat sealed it`) — the ONE place a `TypeId` becomes prose in a file
that otherwise never prints one.

**D3. THE LAYERING WALL WAS THE REAL FIND.** The obvious write sites
(`decls.av`'s `flatten`/`laid_out`, `declare.av`'s `keep_boxed`,
`impls.av`'s receiver seal, `interface.av`'s held-record loading) are
all FEATURES or COMPILER layer, with `self.defect`-style diagnostics
in reach — but the READ that actually raced them, on main's own
source, was `side_word`'s `.Opt(inner)` arm asking
`opt_rides_pointer(inner)`, reached from `judge_result` INSIDE
`intern()` while comptime-settling `core.Fingerprint.derive`'s own
generated code for a declaration whose fields included `core.Reg` —
a CORE-layer read, with NO path to a `Decls`/`self.sig(...)` call at
all. `payload_word`'s own two-line guard (`match shape_of(t) {
.Struct(r,_) -> {let _ = self.sig(r)}, ...}`) is exactly the right
fix at every site THAT CAN SEE `Decls` — I generalized it into
`Decls.declared_first(t)` and used it at three (`payload_word` itself,
`literal_record`, `Emitter.mint_ty`) — but `judge_result`/`side_word`
cannot call it, and neither can any future core-layer reader. THE
FIX IS A HOOK: `TypeRegistry` gains `declare_hook: Cell<fn(TypeId) ->
void>`, defaulted to a no-op (`nothing_declared`) so a bare registry
(a unit test's `new_decls()`) behaves exactly as before this door
existed; `arm_declare` lets a HIGHER layer wire itself in without
core naming a type it cannot see. `new_decls()` arms it once,
closing over its OWN identity (`d.types.arm_declare((t) ->
d.declared_first(t))` — the same "NOT `mut`, hooks capture the
identity" shape `Decls.arm_marks`/`Workspace.anew` already use).
`note()` calls the hook on the FIRST ask of any bucket, before
marking it read — so `Reg`'s declaration is forced the moment
anything, anywhere, asks about its layout, whichever layer is
asking. This closes the gap `payload_word`'s three per-site copies
never could: a hook works from core, a per-site guard cannot.

**Guard witnessed failing, then fixed.** The negative witness is a
program, not a removed line — a 14-line source
(`type Small = {index:int}`, an enum carrying `Small` as one variant's
payload, and a SIBLING fn taking `mut s: Small`) reproduces R11c's
shape directly: the enum's layout reads `Small`'s flatness at
declare time, and the sibling's `mut` seat would seal it after.
Before D1–D3 this compiles silently (wrong mask, same as R11c).
With them: `error[language.defect]: \`Small\`'s flatness was read
before a \`mut\` seat sealed it` — pinned as a golden test in
`compiler/tests/language_test.av` (`lang.check(new_source_file(...))
==` the exact rendered line), CLAUDE.md's "a check whose failure has
never been witnessed is untested" paid literally: the case was run
red (no hook armed) before it was run green.

**A real bug found on the way, independent of D1–D3.** `unflatten`
rebuilt the RepRow from a bare literal (`RepRow { fields: [], sealed:
true, boxed_flat: … }`) instead of `r with { … }` — every OTHER field
a prior pass had set (`valued`, `counted`, `settled`) silently reset
to its declared default on every seal. The only types this could
touch are `Result<T,E>` sides (the one shape `mark_valued` marks
outside `flatten_enum`, which `unflatten` already excludes via its
own `.Enum` guard) sealed by a LATER `mut` seat — `fn f(mut r:
Result<int, string>)` after `Result<int,string>` was already judged
a value enum elsewhere. Fixed by the same `r with { … }` every other
write method already used; D1–D3's read-tracking would have caught
this too (a write moving an already-read `Valued` bucket) had the
race been reachable, but the write itself is wrong on its own terms
regardless.

**Proof.** `build/avra test packages/std-avrac`: 146 examples + 195
program tests, eval == native == expected, ZERO defects — including
one self-check that races EXACTLY this shape inside the compiler's
own comptime settlement of `@derive(Fingerprint)` over `core.Reg`, a
type this same test run touches thousands of times. `build/avra test
packages/cli`, `packages/std-testing`: clean. `python3
tools/idioms.py`: no new violations (one `style.dead_parameter` on
the hook's floor fn, fixed by naming the unread param `_t`, per I23).
`make cited`: pre-existing failure (`fn_params` licence, from
`e7a0f48`, untouched by this slice — a pure-Python check independent
of the compiler binary; verified unrelated). `build/avra fmt`
identical on all eight touched files. Fixed point: three successive
`make avra`, byte-identical, `.avra-cache` cleared before each.
Instructions retired on `build/avra check packages/cli`, old vs new,
interleaved: 208.16B -> 209.40B (+0.6%) — the cost of one bit-test
per (type, fact) pair's first ask, paid once per compile, against a
package check that does far more besides.

What I wanted from the language while doing this: the layering wall
(D3) is a real, load-bearing law (core cannot see a declaration), and
I paid it with a hand-armed callback because that is the idiom this
tree already uses for the same shape (`Decls.arm_marks`,
`Workspace.anew`'s hooks) — but there is no NAMED CONCEPT for "a
lower layer needs one upcall it cannot import," so the pattern gets
re-invented at its call site every time rather than declared once
where the doctrine already lives. A `hook<T>` primitive — a typed,
self-documenting one-shot upcall slot with its OWN entry in the
layering rule ("a hook is not an import") — would have turned this
from four lines of comment justifying the shape into a phrase.
