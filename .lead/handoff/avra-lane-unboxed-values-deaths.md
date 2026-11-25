# avra-lane-unboxed-values, part 4 — what dies in a cold build, and the one cut

Every count comes from one census run: a cold `tapes $PWD/packages/cli --built`, work-ahead off. The
tree is next-base a683ac99, which carries the slabs, plus this lane's census commits. The new
instrument is commit 4c804e56, gated by `AVRA_CENSUS_DEATHS=1` and present only in census builds.
The timings come from the slab perf profile at -O1 (part 3; same tree with next-base a752d694): 56.4 s
user, 28958 samples.

Totals for the run: 436.5 M boxes made, **422.8 M boxes died**, 1259 M releases, 842 M retains.

## 1. What dies, by kind

Records and enums are list boxes in this runtime, so "list" covers them.

| kind | deaths | share | bytes |
|---|---|---|---|
| list (incl. records, crossings, cells) | 381.1 M | 90.1 % | 26.1 GB |
| text | 30.2 M | 7.1 % | 1.1 GB |
| bytes | 9.5 M | 2.3 % | 2.0 GB |
| map | 2.0 M | 0.5 % | 0.09 GB |

By size: 99.9 % of deaths are slab blocks of 1 KB or less. The list deaths fall in these classes:

| size class | deaths |
|---|---|
| 64 B | 124.1 M |
| 80 B | 148.4 M |
| 96 B | 69.7 M |
| 112 B | 26.5 M |
| 128 B | 6.8 M |
| 144–1024 B | 5.6 M |
| over 1 KB | 3.0 k |

## 2. How deep releases cascade

A cascade is one release reaching zero together with every box it frees.

| boxes in the cascade | cascades | boxes |
|---|---|---|
| 1 | 203.0 M | 203.0 M (48 %) |
| 2–3 | 31.3 M | 67.6 M |
| 4–63 | 5.4 M | 49.3 M |
| 64–1023 | 0.18 M | 33.5 M |
| 1024–524 287 | 7 359 | 27.2 M |
| **2–4 M** | **12** | **40.5 M (9.6 %)** |

## 3. How long boxes live

Life is measured in allocations made between a box's birth and its death.

- **45 %** of slab boxes die within 3 allocations: 104.3 M within 1 and 87.4 M within 2–3.
- 70 % die within 1000 allocations.
- A long-lived tail of 38 M boxes lives 2–33 M allocations; those are the boxes the big cascades drop.

## 4. The three groups asked about

| group | deaths | how it was found |
|---|---|---|
| (a) never-written empty lists (hot-writes', not touched) | **79.5 M** (18.8 % of deaths) | a list box dying with no cell |
| (b) made and dropped in ONE fn | **151.5 M** (35.9 %) | the minting Avra fn equals the fn whose release opened the box's cascade (resolved by symbol). This is an upper bound on "never escaped": a box can be stored and still be dropped by its own fn. |
| (c) whole graphs dropped at once (held-items', not touched) | **40.8 M** in 12 cascades, 67.7 M in all cascades of ≥ 1024 boxes | root release site. 40.8 M of the big-cascade boxes are rooted at `avra_slot_put_moved` called from `held_read` (the `held_items().set({})` eviction). The other roots: `avra_item_tape` 5.5 M, `avra_cell_release` 5.0 M, `avra_columns` 4.7 M, `items_spliced` 2.2 M, `parsed_as` 1.6 M. |

The rest are boxes made in one fn and dropped by another: 269.4 M deaths. A handful of large pairs
lead that list:

| minted in | dropped from | deaths |
|---|---|---|
| `alloc_expr` | `slot_put_moved` | 11.9 M |
| `placed_span` | `slot_put_moved` | 8.4 M |
| `lexer.skip` / `emit` | `Lexing.step` | 13.0 M |
| `TapeReader.place` | `Expr.untaped_id` | 6.3 M |

## 5. Time

Samples whose leaf is in the free path (`avra_rc_release`, `release_dead`, `box_free`, `slab_free`,
`array_reclaim`, …) are 13.1 % of the cold build.

| released from | share of the build |
|---|---|
| `held_read` (group c) | **2.9 %** (40.8 M boxes, ≈ 40 ns each, cold memory) |
| `avra_item_tape` | 0.4 % |
| `worked_out` | 0.3 % |
| `signed_lowered` | 0.3 % |
| a tail of thousands of fns | ≤ 0.2 % each |

The cost per death splits by temperature:
- **cold deaths ≈ 40 ns each**: a big graph dropped long after it was made;
- **warm deaths ≈ 15 ns each**: the 382 M other deaths, 10.2 % of the time.

Allocating at the other end costs about 13.5 ns per box: `slab_alloc` 8.0 % plus `array_made` 2.5 %,
spread over 436 M boxes.

## 6. The one cut, by size

**(b): a temporary whose life the memory pass can PROVE ends in its own frame lives in the frame.**
The prize upper bound is 151.5 M boxes. Each saves an allocation (~13.5 ns) and a death (~15 ns), so
the bound is ≈ 4.3 s ≈ 7.6 % of the cold build.

It beats the alternatives:
- (c) is about 1.6 s, and the held-items lane owns it.
- (a) is about 2 s, and the hot-writes lane owns it.

The pattern behind (b), read from the top fns:
- **A list literal handed to a seat that only reads it.**
  - `derived([fp_str("ExprId"), self.index])` in `ExprId.fingerprint` / `TypeRef.fingerprint`: 3.4 M.
  - `Expr.identity`: a record literal folded and dropped, 8.0 M.
  - `words_of`: 2.5 M.
  - `TapeWriter.flags`: 2.4 M.
- **A comprehension consumed by a lent row.** `SignedType.spelled`'s `["?" for _i in 0..n].join("")`,
  7.8 M: a list plus two texts.
- **A list made, read in a loop and dropped.** `untape_expr_tables` 9.5 M, `every_expr` 3.7 M,
  `settled_answer` 6.6 M (a list plus a slot box).

**The rule.** A box made in fn F lives in F's frame when the memory pass proves all of these:
1. Every use in F is a read, or a hand-over to a LENT seat. Lent means the callee never retains,
   stores, returns, captures, yields or sends it, nor any alias of it, transitively. That needs the
   seat facts the memory pass already keeps (`lends`, `keeps`, and rc-elision's lent analysis). A seat
   without the fact is not lent.
2. It is never stored into a box, cell, map, `once`, closure, task or channel, never returned, never
   the answer of a region that outlives F, and never in an `Unwind` payload.
3. Its size is known where it is made: a literal of n elements, or a record of known fields. A
   comprehension of unknown length is not covered.
4. A write that would clone it (copy-on-write) makes a heap copy; the frame box itself is never resized
   or freed by a row. Pushing onto a frame list is refused, which excludes builders.
5. On EVERY exit of F (normal end, `return`, a failure, an unwind) the box's owned cells are released
   and the box is not freed. The memory pass already places releases on all exits.
6. Its header carries a kind the counting rows treat as uncounted, as `KIND_STATIC` is. So a stray
   retain or release is a no-op, never a free. The `AVRA_RC_GUARD` replay must see it as a frame box,
   not a leak.
7. Fibers: F's frame must outlive every read of the box. A suspend inside F keeps the frame (fibers
   have their own stacks), so a frame box handed across a suspend is safe only if condition 2 holds.

**Measure before building.** This census cannot yet separate "proven lent" from "happened to die
here". The next instrument is a compiler-side label, census-only like `census_box`: each minting site
the memory pass judges frame-eligible under conditions 1–3 gets the label "frame-eligible". The `made:`
and death tables then give the exact eligible count, and the prize is that count × ~28 ns. If it is
under ~1.5 s, the cut does not pay for its soundness surface, and the next candidate is the 382 M warm
deaths' own path cost: a death walk that skips cell scans for lists with no owned marks, and
`array_reclaim` + `box_free` fused into one slab free.

## Files

- Instrument: commit 4c804e56 (runtime/avra_runtime.c, census-only).
- Raw census on this box: `build/census-raw-deaths.out`. Lines `death:`, `cascade:`, `life:`,
  `bigcascade:`, and 18 577 `pair:` lines (minting site, dropping site, count, bytes); resolve with
  `addr2line` against `build/avra.census-deaths`.
