# Per-query regions for the compiler: design

Status: design only, no code. Source facts are cited by file and line (tree at lent-59 / base57).
Trigger: wrong-answers' measurement on a cold `check packages/cli`. 90.3% of its 816 M boxes (89% of
bytes) die inside the query that made them, and 58% of all retains and releases fall on those boxes.
The escapes are answers, tapes, store segments and table cells. Top escape sites: `array_clone`
(4.66 M), `SyntaxArena.placed_span`, `SavedLayoutWriter.finished`, `texts_of`, `Segment.keep`.

## 0. What the runtime and the engine give us today

- **The header.** A box carries a 16-byte header `{ tag, kind_word, rc, len }` (runtime/avra_box.h:40).
  Its kind is a signed byte: 0 plain, 1 array, 2 map, 3 string, 4 octets. A negative kind is
  uncounted. `KIND_STATIC` = −1 and `KIND_DEAD` = −2. `KIND_IMMORTAL(k)` = −(k+4) keeps the shape:
  −4..−8 are the five shapes, immortal. The kind byte's eight negative values are all spoken for
  except −3.
- **The hot leaves.** `avra_rc_retain` returns on `avra_kind(h) < 0` before it touches `rc`
  (avra_hot.c:12), and `avra_rc_release` returns there too, after its null and guard checks. An
  uncounted box costs one compare.
- **Uniqueness drives writes.** In-place writes and appends are licensed by `h->rc == 1`
  (avra_runtime.c:1612, 3936). A write through a shared value clones it (avra_box.h:20–26).
  **Counts here are not only about freeing. They are how the runtime knows a write may happen in
  place.** This is the crux of the design.
- **A query's answer is bytes.** `QueryDefinition.compute: fn(QueryEngine, Bytes) -> Bytes`
  (std-program query_engine.av:47). `computed_answer`, via `worked_out`, hashes those bytes and
  records them (query_engine.av:835–857). A reader decodes an answer into values of its own. So
  **nothing a query made is reachable from another query except through those bytes, or through
  state that outlives the query** (engine tables, the store's pending segments, `Cell`s, arenas
  and memo tables a query grows, `once` cells).

## 1. How a box knows it is region-held

Recommended: a REGION BIT in the header's flags byte, plus the region's DEPTH in the header's
16-bit stamp field. The kind stays the box's shape, unchanged.

- `kind_word` is low byte kind, then flags, then a 16-bit stamp (avra_box.h:47). The flags byte has
  room: bit 0 is OBSERVED, and 0xFF marks static data. A region box sets `REGION` (bit 1). Its
  stamp holds the region's depth: 1 for the outermost query a process computes, +1 for each query
  asked inside it. The stamp field is currently the write-observation turn number; that use moves
  to a side table for region boxes, or region boxes are left unobserved. That's a decision for
  stage 1, whose cost is measured there.
- Not an address range. Region pages would come from one reserved virtual range, so "is region"
  would be one compare on the pointer with no header load. But the DEPTH, which section 3 needs,
  would then need per-depth ranges or a page table lookup, and a promoted-in-place box (section 2)
  would sit in a region page while being heap. The header bit handles both. The range test stays
  available as a debug cross-check (section 4).
- Not a new negative kind. Retain and release would get the no-op for free, but section 0's crux
  says a region box must still answer "am I unique?" until the compiler can prove it (stage 2).
  The negative-kind trick is the stage-2 end state, for boxes the compiler licenses (section 5).

Retain and release in stage 1: a region box is COUNTED as now (`rc++` / `rc--`), so `rc == 1`
still licenses in-place writes. What changes is that **a region box reaching 0 is not freed and does
not cascade**: its memory goes back when the region ends. Freeing is where the expensive work is.
`reclaims` is 832 M on the cost lane's cold check-cli (snapshot a6d0d0a0); each reclaim walks its
slots, releasing children, and pushes onto a free list. All of that work leaves. The increments stay until stage 2.

The new fast-path cost: release reads the flags byte when `rc` reaches 0, which is the rare,
out-of-line path. Retain is unchanged.

## 2. Escape points, and how each moves a value out

Stores of a pointer are the only way a region box can outlive its region. Two directions:
- **Heap (or an older region) → this region's box.** This is an ESCAPE, and must not leave a
  pointer into the region.
- **This region's box → heap.** This is a REMEMBERED pointer: the heap box's count was raised when
  it was stored, and must be released when the region ends, because a region box that dies does
  not cascade.

The escape points, in the order wrong-answers ranked them:

| Escape | Where | How it moves out | Cost given the top sites |
|---|---|---|---|
| The answer | `compute` returns `Bytes` (query_engine.av:47) | **Allocate in the target**: the answer writer (`SavedLayoutWriter`, whose `finished` is a top site) allocates its output buffer in the counted heap from the start, so the returned box is never region-held. No copy. | Zero copy. One flag on the writer's allocation. |
| Store segments | `Segment.keep`, the store's pending writes | Allocate in the target: the store's own buffers are heap. Bytes written into them are copied by value already (octets). | Zero beyond today's memcpy. |
| Tapes, arenas, memo tables a query grows | `SyntaxArena.placed_span`, `texts_of`, per-file tapes kept past the query | A **write barrier on slot and list stores**: storing a region pointer into a box of a lower depth (or into the heap) **promotes** it. Small boxes are deep-copied into the target's depth. Large boxes, and any subgraph past a size bound, are **promoted in place**: their REGION bit is cleared, their pages pinned, and the region keeps those pages at its end. | Copy cost proportional to escaped bytes. wrong-answers' 9.7% of boxes, 11% of bytes, are the ceiling, and most of those are answers and segments, which cost nothing above. The barrier itself costs a flags-byte compare on every pointer store. |
| `array_clone` (4.66 M) | Clones of shared values written | A clone made inside a region is a region box, unless its target slot is lower-depth, in which case the barrier promotes it. | Mostly stays in-region. |
| Engine tables (`settled_answers`, read sets, `lent`, frontier learned) | QueryEngine fields, `Cell`s and `HashKeyedTable`s | Their values are ContentHashes and bytes: scalars and heap octets. The barrier covers any boxed value. | Small. |
| `once` cells | `once fn` answers | Written once, live for the process. A `once` body computes under depth 0 (the heap), not in any region. | None. |

Promotion is deep: a promoted box's children that are region boxes are promoted too, by the same
copy-or-pin rule. Pin-in-place keeps addresses stable, so no pointer fix-up is ever needed. That
is why it is preferred for anything past the copy bound.

## 3. Nesting, and work-ahead forks

- **Regions form a stack per process**, keyed by depth. `computed_answer` pushes a region before
  `worked_out` and pops it after. A query asked while another computes gets depth d+1.
- **The rule is "point down, never up"**: a box may hold pointers to boxes of the same or lower
  depth (lower means older, including the heap at 0). The barrier compares the stored value's
  depth with the target's and promotes on a store that would point up. An outer query's values
  handed down as arguments are read freely by the inner query, since they outlive it. An inner
  query storing into an outer value, for example through a `Cell` it was handed, promotes to the
  outer depth.
- **Inner answers cross as bytes** (section 0). An outer query never holds an inner region's box,
  so popping a region frees it whole, with no scan.
- **Popping a region:**
  1. Release the remembered pointers (this region → heap or older region).
  2. Return every page that holds no pinned box.
  3. Fold pinned pages into the depth they were promoted to.
  The remembered set is appended to by the barrier, so its cost is proportional to the stores that
  made it.
- **Work-ahead forks:** `fork` copies the region stack along with memory. A worker computes its own
  queries under fresh regions, pushed above whatever the parent held at the fork, and hands
  results back through the store as bytes. A fork already gives a child its own memory and releases
  the parent's pool slots in it (`avra_pool_forked`, runtime/avra_pool.c:71). The child does the
  same for the region stack: it marks the inherited depths as its own floor and pushes above them.
  No region spans processes, and a forked child never pops a region it inherited. It exits.

## 4. What proves no region box survives its region

Layered, each catching what the one before can miss:

1. **Construction.** Answers and segments are allocated in their target (section 2), so the main
   escapes never create a region pointer to begin with.
2. **The write barrier**, in every build: every pointer store compares depths, then promotes. This
   is the runtime's soundness rule; nothing else is relied on.
3. **The debug region guard** (`AVRA_REGION_GUARD=1`): popping a region poisons its returned pages
   (`mprotect PROT_NONE`) instead of reusing them, so any surviving pointer traps on its first use.
   That's the same discipline as `AVRA_RC_GUARD`'s quarantine, applied to whole pages. A
   whole-heap scan for pointers into the popped address range, a debug-only and expensive pass, is
   a second check at region pop on a sample of queries.
4. **The memory pass**, statically: it already proves which values a body owns, lends or hands back
   (the lent and consumed marks). It learns one more fact per store: the depth of the target, which
   the program layer knows (a field of a value made in this query, against one handed in, a `Cell`,
   an engine table). Then a store the barrier would have to promote is flagged at compile time, as
   cost, and as a cue to allocate in the target.
5. **The RC guard and the soundness check** keep running unchanged over all of it. A region box
   still has a real count in stage 1, so their invariants still hold.

## 5. Expected census delta, and a staged plan where each stage is measurable alone

Base: cold `check packages/cli` (816 M boxes; 2.09 G retains, 2.92 G releases, 832 M reclaims on
the cost snapshot a6d0d0a0).

| Stage | What lands | Measured by | Expected |
|---|---|---|---|
| **0. Count it** | Census only. Every box records the depth it was made at, and its death whether it died at that depth. This is wrong-answers' measurement, made a permanent census row: `region: died-home N / escaped M by site`. | The census itself | Today's 90.3% / 9.7%, as a row. |
| **1. Regions own memory, counts stay** | The depth stack in `computed_answer`, the region bump allocator (page-sized arenas), the flags bit and depth stamp, the write barrier with promote (copy or pin), the remembered set, pop. A region box reaching 0 doesn't free. | `reclaims`, the free-list and cascade time, cold check-cli wall time and peak RSS, plus two new rows: `promoted boxes / bytes` and `barrier promotions by site`. | Reclaims −85..−90% (832 M → ~100 M). Retains and releases unchanged. Allocation goes from free-list to bump. Peak may rise, since a region frees at its end, not as boxes die. That is bounded by the largest query's working set and must be measured. |
| **2. Allocate in the target** | `SavedLayoutWriter` and the store's segment buffers allocate in the heap. The barrier's top promotion sites from stage 1 are each made to allocate in their target. | `promoted bytes` falls; wall time | Most of the stage-1 promotion bytes gone. Only the tapes and arenas that genuinely outlive their query still promote. |
| **3. Licensed uncounted** | The memory pass marks values proven unique, region-local and never stored down. Their boxes are made with the region's immortal-shape kind (−(k+4) with the REGION bit), so retain and release are the existing one-compare no-op. A write through one is in place by license, not by `rc == 1`. | `retains` and `releases` | Up to −58% of retains and releases (wrong-answers' share on boxes that die home), less whatever the pass can't prove unique. Each license is a row, so the census names what it proved. |
| **4. Retire per-read lending** | If stage 3 removes what lent/Grown targets, lent-59's per-read lending is kept only where a view crosses region boundaries. | The census, against lent-59 parked | Decided by the numbers, not ahead of them. |

Each stage lands alone, with its own census before and after and the existing soundness receipts:
sound check 0, RC guard clean, eval == native, the edit gate. Stage 1 also needs the region guard
(section 4.3) clean over the full suite before it lands.

## Open questions, for whoever builds it

- Do OBSERVED and stamp-based write logging matter for region boxes, which no other query can see?
  If not, a region box simply isn't observed and the stamp is free for the depth.
- The pin threshold, copy versus pin-in-place: to set from stage 1's promotion-size histogram.
- Peak memory under stage 1, for the largest queries (whole-package walks). If one query's working
  set is the problem, a query may sub-region its own loops: the memory pass knows loop-local values
  as well. That's a later step, not part of this design.
