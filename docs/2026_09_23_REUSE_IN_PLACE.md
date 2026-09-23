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
