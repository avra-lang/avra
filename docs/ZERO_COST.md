# Zero cost — the registry

The law (CLAUDE.md, "PERFORMANT BY DEFAULT"): idiomatic code IS the fast code. A writer never
hand-tunes a representation; the compiler chooses it, and the cost of what was written is visible
and gated. This file is the registry the law is held to: one row per technique, each with the
DETECTOR that finds its candidates. A technique without a detector is a wish, not a row.

## Detectors — how candidates are found

Four instruments, each reading what the compiler or the runtime already knows (P10). None is a
human reading code.

| detector | reads | finds | where |
|---|---|---|---|
| **census sites** | the runtime's exact per-site counters (boxes, retains, releases, clones, opens of an empty literal, string compares, list writes) over the fixed workloads | the hottest sites, each CLASSIFIED to the technique that would remove its cost (below) | `avra census --candidates` |
| **missed-optimization remarks** | the compiler at the moment a technique declines to fire | WHY a site paid, as a TYPED reason per technique (`Declined`: `DeferDecline`, `ProbeDecline`, `SettleDecline`, `ConsumeDecline`, `DynDecline`, `PackDecline`), its words rendered by one voice fn | `avra explain --cost @fn`, grouped by reason and counted; `cost_remarks` is a query, so the remarks are facts in the DB. A build never notes them: zero cost unless asked |
| **shape rules** | the source, as `rule` declarations `avra check` finds | the patterns that cost by construction | `avra check`, ratcheted like idioms |
| **exact-count gate** | the census totals per cold workload, and the answers a warm run works out again after each fixed edit, over one pinned snapshot, against `tools/cost.baseline` | regressions: any counter that rose past tolerance, cold or warm | a gate slice (`make cost`); lowering a counter needs `make cost-accept` |

**The classifier** is what makes candidates automatic. A census site's SHAPE names its technique:

| site shape (from the census) | technique |
|---|---|
| a box freed in the fn that made it | stack records (escape analysis) |
| a free at rc 1 followed by an alloc of the same size | reuse in place |
| a retain whose release is the binding's last use | move at last use |
| an owned twin read (`avra_slot_get_owned`, `avra_array_get_owned`) and its release, in a fn whose borrow is read across a call handed nothing that can run code (`AVRA_RC_REASONS`: `candidate: a borrow a call makes owned`) | borrows across quiet calls |
| `avra_streq`/name compare callers | interned names |
| an open of the binary's empty literal (`[]`, `{}`) by a first write | fresh empties |
| a box of flat scalar fields pushed into a list | strided list |
| a slot box over a crossed box (`F?`) | nullable flat record |
| a list made and only walked once | deforestation |
| an indirect call whose target set is one fn | devirtualization |
| a `dyn` box laid with N code pointers | static method tables |
| a number's text minted in an Avra fn (`box text by avra_int_text`) | content keys |

`avra census --candidates` prints the top sites per technique with their counts and the source
line, so a ranked work list is one command. Run per batch on the gate's workloads, its output
diffed against the last run is how a NEW candidate appears without anyone looking.

`make cost` runs every compiler workload with the site tables on (`cold-with-store-fill` measures the store, not the compiler, and takes none), resolves each site to its symbol and
writes `build/cost/candidates.txt` (`avra census --candidates [--root <tree>] <report>…`, the top
ten per technique). A `(technique, fn)` that `tools/cost.candidates` lacks is NAMED, never failed;
`make cost-accept` rewrites that record. Deforestation and devirtualization have no census hook
yet, and borrows across quiet calls are found by the memory pass's own tally (`AVRA_RC_REASONS`), so
the classifier reads the other nine shapes.

## How work is assessed

- **Every PR**: the exact-count gate holds; a new shape-rule finding fails like an idiom.
- **Every new feature**: its design post names its cost (boxes, calls, copies per use) and which
  registry rows it relies on or adds. A feature that makes idiomatic code slower needs a row that
  removes the cost, or it is not ready.
- **Maintenance**: a finding from any detector is a row or a ticket at discovery, never a comment.
- **New techniques** join this table with their detector in the same change.

## Techniques

| technique | status | removes |
|---|---|---|
| packed lists of scalars | landed (batch 48) | a mark byte a cell, boxes per element |
| strided lists of flat records | in progress (alloc) | a box per element |
| nullable flat record as presence + words | designed (alloc (2), after the aggregate rewrite) | 2 boxes per `F?` |
| static method tables | done (lowering-quality, to land) | N code-pointer pushes per `dyn` box: one table per type and trait, laid once as data; a box is its value and its table |
| aggregates as leaf scalars, unfilled parts zeroed | in progress (parallel-main) | SelectionDAG fallbacks, undef words |
| release rows | landed (batch 48) | release call sites |
| interned names | proposed | string compares in lookups |
| interpolation in one buffer: a string's runs and holes appended to the thread's scratch between `avra_text_begin` and `avra_text_end`, builds nesting, the text minted once | landed (str_lit's `text_lowered`) | a box per number's spelling, the pieces' list and the join — one box per interpolation instead (`box text by avra_text_end` in the census) |
| content keys: a table keyed by a value folds it to a `ContentHash` over both lanes and probes a `HashKeyedTable` (or interns it), never a text built per lookup | landed for the cancel survey (`BodyAt.print`); the general form waits on maps keyed by any hashable value, and `compiler.text_keyed_probe` (lane/replay-defects/text-keyed-rule) turns on with it | a text, and a box per number in it, on every probe — `BodyAt.key()` minted 2.32 M of them on a cold build-cli |
| reuse in place (Perceus/FBIP) | proposed | free + alloc pairs |
| fresh empties: a first write into `[]` makes its buffer, never a clone of the static | proposed | the open of the empty literal (`empty_opens`) |
| move at last use (borrow inference) | partial (params' consumes) | retain/release pairs |
| borrows across quiet calls: a borrowed read stands across a call whose callee writes no cell (`writes_no_cell`, read once of its own instructions) and is handed nothing that can run code | done (lowering-quality, to land) | a retain and release per borrowed cell read across an out-of-line scalar fn (`HashKeyedTable.position_at` with its slot arithmetic as a fn: 3 owned reads and 2 release runs a search); the callee's bit rides `BodySeen`, so a callee that comes to write a cell remakes its callers |
| devirtualization | proposed | indirect calls with one target |
| deforestation | partial (walk chains) | intermediate lists |
| scalar replacement / stack records | proposed | boxes that never escape |
| arenas per query | proposed | per-temporary frees |
| set/switch lowering of `x in [literals]` | proposed | linear scans over constants |
| column layout for List<Record> read by field | proposed | strided reads of one field |
