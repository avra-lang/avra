# ITEM × PHASE ENGINE — design (warm lane, for ARCHITECTURE FOR BOTH #1, #3, #4)

Principle: COMPUTE COARSE, INVALIDATE FINE; never trade warm for cold. A question exists only where an
edit can be cut off — an item in a phase. Inside one, plain fns, no bookkeeping.

## 1. What is measured today (tree 964cf5c7 = batch52 + grain)

Queries in std-avrac: 211 (164 `@query`, 31 `@cut_query`, 3+3 parted, 3 folded, 7 `@lasting`). By key
(of the 190 a signature scan classifies): item (file, at) 33 · name (file, name, …) 35 · file 43 ·
package/module 38 · other ~41 (DeclId 12, FileId 13, ImplAt, CalledFn, …).

Cold cli `tapes --findings`: 815,478 answers worked; per item ~25 law queries (21,924 items each).

Warm re-runs per edit kind, laws phase (`tapes --findings packages/cli`, one edit to
cli/src/commands/cache.av, 14 items; tool /work/meas/ip/count.py):

| edit | worked | what dominates |
|---|---|---|
| no-op | 0 | — |
| inline (module doc line) | 81 | item_under 14, item_start 14, law_findings 14 |
| literal in a body | 69 | item_under 14, item_start 14, the edited item's ~25 laws, ~12 file-level |
| comment in a body | 69 | same as literal |
| body (a statement added) | 70 | same, + typed_fn, written_typed |
| signature (a defaulted seat) | 103 | + law_findings 15, file_declares_named 8, readers' typed_fn/item_misses/receivers ×2, module_* and entry_* |
| declaration added before an item | 303 | every later item's ~25 laws again (items are keyed by POSITION), item_held 15, seats_written 12 |
| declaration added after an item | 148 | the items after it, again by position |

Three causes, in order of weight:
1. **Positional identity.** An item is (file, at). Any item added or removed renumbers every later item,
   and all of its ~25 law questions, its typing and its signature reads re-run (303 vs 70).
2. **Absolute places.** `item_start` and every finding's span are file offsets, so every item's start
   moves on any edit above it: item_under 14 + item_start 14 on every kind (28 of 69).
3. **Fine-grained law questions.** One edited item re-asks ~25 law queries plus their shared reads
   (~35 answers) where one item-phase answer would do; and a dependent reads another item's facts
   piecemeal (seats_written, written_fields, …), the decl_grain leftovers.

## 2. The query table after

| phase | question (dense key) | answer | reads |
|---|---|---|---|
| split | `items(file)` — PARTED by item id | per item: its text, kind, declared names; the file's index (name → item id) | source_text(file) |
| parse | `parse(item)` | the item's syntax, places item-relative | split part of item |
| signature | `summary(item)` | the INTERFACE: each declared name's signature, fields/variants, seats' `mut`, marks, extern/grammar/deprecation, impls it writes (target, methods, statics) — with its own hash | parse(item); summaries it names |
| types | `types(item)` | typed bodies, item-relative | parse(item); summaries of the names it uses |
| laws | `laws(item)` | every law finding of the item (laws-fusion's fold) | parse, types(item); summaries |
| lowering | `lowered(item)` | lowered bodies | types(item); summaries |
| file | `file_findings(file)`, `file_erring(file)` | the file's findings rendered, absolute places | laws parts of its items + split |
| module | `module_names(module)` — PARTED by name | declarations of a name across the module's files | split indexes of its files |
| program | walk / reached / keys (serial middle, #9) | unchanged here | lowered(item) hashes |

Survivors from today: `item_under`+`item_tape` → parse; `fn_signature`, `record_signature`,
`enum_signature`, `alias_target`, `named_shape`, `trait_method_signature`, `impl_signatures`, and my
per-name cuts (`file_declares_named`, `seats_written`, `written_fields`, `declares_extern`,
`grammar_declared`, `home_gives_named`) → PARTS of `summary(item)`; `typed_fn`, `written_typed`,
`method_body_typed` → types; `law_findings` + the ~25 `item_*` law queries → laws (laws-fusion);
`item_held`, `item_count`, `item_start`, `file_declares_at` → gone (identity is stable, places relative);
`file_declares`, `file_scope`, `module_declares` → the split index and module_names parts.
~211 queries → ~12 query kinds; everything else becomes plain fns.

## 3. Identity and keys (dense typed keys, #3)

- **Item id = (file id, declared signature key, occurrence)**, never position: a fn/type/const by its
  first declared name and kind; an impl by (target, trait); a run statement block by (kind, ordinal
  among unnamed items). Adding or removing an item renumbers nothing else.
- **A question is (phase, item id)**: two small ints. Answers live in per-phase column tables indexed by
  item id (answer hash, settled serial, value slot), so a reused ask is ONE array index plus a serial
  compare — this is engine steps 2/3/5: no argument folding, no hashed question lookup, no record box.
- Across processes the frontier keys questions by (phase, stable item key text) once per item, interned
  at load; in process everything is ints.

## 4. How reads are recorded

- Inside an item-phase: nothing is recorded; plain fns over the item's own syntax.
- At the boundary: an item-phase answer records the SUMMARY PARTS it read — (item id, name) → part
  hash — once per (reader, part), in the packed ReadTable (step 1, landed as 356be742). A read already
  recorded by this reader is skipped by a per-reader stamp on the part (step 3).
- Places inside answers are item-relative; absolute places are made only at rendering, from the
  split's item starts (not a recorded read of any later phase).

## 5. Cutoff points

1. `items(file)` part per item: an item whose text hash didn't move cuts here — its parse/summary/
   types/laws are not asked again.
2. `summary(item)`: a body, literal or comment edit leaves the summary hash standing, so no OTHER
   item re-runs (the INTERFACE FIREWALL, #4). decl_grain's leftovers (seats_written(one),
   written_fields(Box)) disappear: they are parts of a summary that didn't move.
3. `types(item)` / `laws(item)` / `lowered(item)`: each its own answer hash; file- and program-level
   gatherings re-run only over moved parts.
4. `module_names` part per name: a declaration added or renamed moves only that name's part; readers of
   other names stand.

## 6. Warm re-run counts, before → after (laws phase, same edits)

| edit | before | after (designed) | after's set |
|---|---|---|---|
| no-op | 0 | 0 | — |
| inline doc | 81 | 3 | split, parse(item 0), laws(item 0) — summary cuts |
| literal | 69 | 6 | split, parse, summary (cuts), types, laws, file_findings |
| comment | 69 | 4 | split, parse, summary (cuts), laws (types cuts on the syntax hash) |
| body | 70 | 6 | as literal |
| signature | 103 | ~10 | split, parse, summary (moves), module part, + types/laws of each reader (2 here), file_findings |
| added before an item | 303 | ~8 | split, the new item's parse/summary/types/laws, module part for its name, file_findings |
| added after an item | 148 | ~8 | as above |

The exact-count gate (doc §"warm is protected by gate") takes this table as its budget, per kind.

## 7. Order, and coordination

1. Laws first, WITH laws-fusion: their fold makes `laws(item)` one question; this lane gives it the
   stable item id and item-relative places (cause 1 and 2), measured with count.py per step.
2. `items(file)` parted + stable ids + relative places: removes item_under/item_start/item_held churn
   (−28 per edit, −~230 on an added item) — the biggest warm win and independent of the fold.
3. `summary(item)` as the one interface: the signature queries and the per-name cuts become its parts.
4. Engine: dense (phase, item) keys and column tables (steps 2/3/5 land here, not before — keying the
   old questions densely would be thrown away).
5. Types and lowering as item-phase answers.
Each step: witness (warm == cold), count.py before/after per edit kind, the cold census, the bodies-wave table.

Open questions for the lead:
- laws-fusion's fold: is its answer keyed (file, at) today? Stable ids should land under it, not beside it.
- The bodies-wave table instrumentation (parallel-main's patch) for the engine steps.
