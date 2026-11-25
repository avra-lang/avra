# avra-lane-unboxed-values, part 2 — where a cold cli build spends its TIME: runtime rows × callers, perf at -O0 and -O1

**Base for every number below: trunk db94aa87 + avra-lane-saved-answers-2 (the in-place BytesBuilder;
`write_octet`'s list pushes are gone) + this lane's census instruments.** The compilers were built by
the ladder chain standing build/avra → c3ee494 (rung 1, 59b0dfa rows) → fd71c56 (rung 2, 83fe167 arms)
→ 805682b (HEAD); each measured compiler is that product's `AVRA_PROGRAM=1` build of the cli. Measured
run: cold `tapes $PWD/packages/cli --built` (both the tree's and the package's stores cleared),
work-ahead OFF, 44839/44839 made. Machine: 4 cores, 15 GB, NO hardware counters in this VM, so perf
samples `cpu-clock` at 499 Hz with frame-pointer call graphs (runtime and emitted code built with frame
pointers). The machine is noisy: the same binary varied 70.9–88.9 s user across rounds.

## 0. Headline

| | -O0 | -O1 |
|---|---|---|
| user CPU, cold cli --built | 99.5 s | 76.3 s |
| row READS (array_get, slot_get, …) self | **25.7 %** | **3.9 %** (inlined hot leaves) |
| Avra code self (at -O1 incl. the inlined leaves) | 22.9 % | 36.1 % |
| rc: retain/release + release cascade + box_free self | 14.3 % | 14.9 % |
| row WRITES (push, slot_put/set, slot_unique, cell bytes) self | 12.2 % | 13.3 % |
| glibc malloc/free | 10.5 % | **14.0 %** |
| box / list making self (array_made, box_alloc, str_owned) | 4.5 % | 5.9 % |
| other runtime rows | 4.2 % | 5.1 % |
| memmove / memset / memcmp | 2.0 % | 2.5 % |
| kernel, libc rest | 3.0 % | 3.5 % |
| blake3 | 0.7 % | 0.9 % |

* The 7.59 G list reads are a **-O0** cost (≈ 25 s); at -O1 they inline and are ≈ 3 s. **Ranking by
  READS is the wrong ranking for the installed (-O1) compiler.** At -O1, MEMORY MANAGEMENT is the bill:
  freeing (rc + cascade 14.9 %) + glibc (14.0 %) + making (5.9 %) ≈ **35 % ≈ 26 s**, and the write rows
  that stay calls are another 13.3 % ≈ 10 s.
* Measured, no code change: the same -O1 binary under `LD_PRELOAD=libmimalloc.so.2` vs glibc, four
  alternating rounds: 69.1 / 74.8 / 78.5 / 60.0 s vs 78.8 / 88.9 / 79.8 / 70.9 s user — **−9.0 s mean
  (−11 %)**, peak RSS 2.64 → 2.53 GB. jemalloc: no gain (80.2 / 80.0 s).

## 1. The instrument (commit 8210c25)

A census build now counts EVERY runtime row a body calls — each `CallRt`/`CallRtVoid`, and each
`Retain`/`Release` the memory pass emitted — by the body's own call site (the backend emits
`avra_census_row(label)` before the call; 1 M-slot tables, sorted reports, `AVRA_CENSUS_ROWS_TOP`). Rows
called from inside other rows are not counted (they are what the row costs). The top 30 000 sites cover
13.41 G calls. Totals of the run: 877.9 M retains, 1275.2 M releases, 400.6 M reclaims, 7594.0 M list
reads, 1290.8 M list writes, 414.3 M boxes. Counts are the same at -O0 and -O1 (one IR); the TIME per
call is not.

## 2. Ranked tables

### 2a. Runtime rows: calls (census) and self time (perf)

| # | row | calls | self at -O0 | self at -O1 |
|---|---|---|---|---|
| 1 | avra_slot_get | 4330.4 M | 7.1% | <0.4% / inlined |
| 2 | avra_array_get | 2123.7 M | 9.8% | 1.4% |
| 3 | release | 979.2 M | 6.3% | 5.5% |
| 4 | avra_array_push | 786.4 M | 3.2% | 2.8% |
| 5 | avra_array_len | 740.9 M | 1.9% | <0.4% / inlined |
| 6 | avra_slot_unique | 432.2 M | 2.0% | 2.1% |
| 7 | retain | 402.7 M | 2.3% | 1.7% |
| 8 | avra_array_sized | 357.4 M | 0.4% | 0.5% |
| 9 | avra_slot_put | 353.1 M | 1.0% | 0.9% |
| 10 | avra_cell_release | 317.6 M | <0.3% | 0.4% |
| 11 | avra_bytes_at | 284.9 M | <0.3% | <0.4% / inlined |
| 12 | avra_array_push_owned | 249.1 M | 1.3% | 1.5% |
| 13 | avra_seat_opened | 232.6 M | <0.3% | <0.4% / inlined |
| 14 | avra_array_get_owned | 231.2 M | 3.7% | <0.4% / inlined |
| 15 | avra_str_char_code | 203.1 M | 0.5% | 0.6% |
| 16 | avra_slot_set | 196.9 M | 0.5% | 0.7% |
| 17 | avra_slot_get_owned | 193.9 M | 1.4% | <0.4% / inlined |
| 18 | avra_array_push_moved | 189.3 M | 1.0% | 1.1% |
| 19 | avra_cell_bytes_word | 155.3 M | 0.8% | 0.9% |
| 20 | avra_streq | 135.7 M | 1.0% | 1.2% |
| 21 | avra_str_word_at | 99.8 M | <0.3% | 0.5% |
| 22 | avra_bytes_len | 54.6 M | <0.3% | <0.4% / inlined |
| 23 | avra_str_len | 43.3 M | <0.3% | <0.4% / inlined |
| 24 | avra_cell_unique | 39.5 M | <0.3% | <0.4% / inlined |
| 25 | avra_unwrap | 31.6 M | <0.3% | <0.4% / inlined |
| 26 | avra_slot_set_owned | 31.1 M | <0.3% | <0.4% / inlined |
| 27 | avra_map_slot | 24.3 M | 0.8% | 1.0% |
| 28 | avra_mmap_word_at | 14.2 M | <0.3% | <0.4% / inlined |
| 29 | avra_str_join | 12.5 M | 0.4% | 0.5% |
| 30 | avra_slot_put_moved | 12.2 M | <0.3% | <0.4% / inlined |

### 2b. List READS by row × calling fn (top 30)

| # | fn | row | calls |
|---|---|---|---|
| 1 | program:saved_layout.av.SavedLayoutWriter.word_pushed | avra_slot_get | 939.3 M |
| 2 | program:saved_layout.av.held_slot_value | avra_array_get | 246.6 M |
| 3 | program:saved_layout.av.word_in | avra_bytes_at | 197.7 M |
| 4 | avrac:compiler/backend/interp.av.Machine.run_body | avra_slot_get | 179.2 M |
| 5 | program:saved_layout.av.SavedLayoutWriter.word_pushed | avra_array_len | 156.5 M |
| 6 | avrac:grammar/lexer.av.Lexing.step | avra_slot_get | 122.8 M |
| 7 | avrac:compiler/backend/interp.av.Machine.run_body | avra_array_get | 115.8 M |
| 8 | program:syntax_tape.av.TapeReader.count | avra_slot_get | 110.8 M |
| 9 | program:saved_layout.av.SavedLayoutWriter.write_big_endian | avra_slot_get | 97.0 M |
| 10 | text:text.av.BytesBuilder.word | avra_slot_get | 97.0 M |
| 11 | text:text.av.BytesBuilder.length | avra_slot_get | 76.7 M |
| 12 | program:syntax_tape.av.number_from | avra_bytes_at | 73.0 M |
| 13 | program:saved_layout.av.SavedLayoutWriter.record_closed | avra_slot_get | 72.2 M |
| 14 | avrac:core/fp.av.fp_str | avra_str_word_at | 71.7 M |
| 15 | program:saved_layout.av.SavedSource.word_at | avra_array_get | 71.7 M |
| 16 | avrac:core/store.av.Stamped.unsettled | avra_slot_get | 68.8 M |
| 17 | avrac:compiler/backend/interp.av.Machine.step | avra_array_get | 67.9 M |
| 18 | avrac:core/store.av.SyntaxArena.alloc_expr | avra_slot_get | 66.0 M |
| 19 | avrac:core/arena.av.Arena.node_at$box enum/box enum/1 | avra_slot_get | 66.0 M |
| 20 | program:syntax_tape.av.number_from | avra_slot_get | 65.3 M |
| 21 | program:hash_keyed_table.av.HashKeyedTable.position_at$box record/box record/1 | avra_slot_get | 64.8 M |
| 22 | avrac:core/signed_types.av.SignedType.same_type | avra_slot_get | 63.4 M |
| 23 | program:saved_layout.av.SavedLayoutWriter.list_closed | avra_slot_get | 62.1 M |
| 24 | program:saved_layout.av.SavedLayoutWriter.write_octet | avra_slot_get | 58.3 M |
| 25 | text:text.av.BytesBuilder.octet | avra_slot_get | 58.3 M |
| 26 | avrac:compiler/item_writes.av.same_method | avra_slot_get | 54.6 M |
| 27 | program:hash_keyed_table.av.HashKeyedTable.position_at$box record/box record/1 | avra_array_get | 53.7 M |
| 28 | program:disk_store.av.Segment.saved_in | avra_array_get_owned | 50.9 M |
| 29 | program:disk_store.av.Segment.saved_in.lambda145 | avra_slot_get | 50.9 M |
| 30 | program:disk_store.av.Segment.saved_in.lambda145 | avra_array_get | 50.9 M |

What the hot read sites do:
* `SavedLayoutWriter.word_pushed` (939 M slot_get, 156 M array_len) — every field of the writer is a
  `Cell` inside a boxed record (`slot_words: Cell<List<int>>`, `slot_height: Cell<int>`): each use is
  record box → cell box → value, two `slot_get`s, and the list's length a third read. An identity record
  of cells: two loads per field.
* `held_slot_value` / `SavedSource.word_at` (array_get) — a bounds-checked index into a list of words, in
  a loop over a node's slots.
* `word_in` / `number_from` (bytes_at) — octet-at-a-time reads of a saved record, bounds-checked each.
* `Machine.run_body` / `step` / `at` (slot_get, array_get) — the evaluator reading its registers and
  instructions out of records and lists.
* `Lexing.step`, `TapeReader.count`, `Stamped.unsettled`, `Arena.node_at` — field reads of `self`
  through its box, in the per-character / per-node loop.

### 2c. List WRITES by row × calling fn (top 30)

| # | fn | row | calls |
|---|---|---|---|
| 1 | program:saved_layout.av.SavedLayoutWriter.word_pushed | avra_slot_put | 156.5 M |
| 2 | program:saved_layout.av.SavedLayoutWriter.word_pushed | avra_slot_unique | 156.5 M |
| 3 | program:saved_layout.av.SavedLayoutWriter.word_pushed | avra_slot_set | 156.1 M |
| 4 | text:text.av.BytesBuilder.word | avra_cell_bytes_word | 97.0 M |
| 5 | program:syntax_tape.av.number_from | avra_slot_put | 65.3 M |
| 6 | avrac:core/store.av.SyntaxArena.alloc_expr | avra_slot_unique | 61.9 M |
| 7 | text:text.av.BytesBuilder.octet | avra_cell_bytes_word | 58.3 M |
| 8 | avrac:core/store.av.SyntaxArena.alloc_expr | avra_array_push | 45.4 M |
| 9 | avrac:features/node_scaffold.av.node_builders.lambda67 | avra_array_push | 35.4 M |
| 10 | avrac:grammar/lexer.av.skip | avra_array_push | 28.8 M |
| 11 | avrac:grammar/lexer.av.Lexing.push | avra_seat_opened | 28.6 M |
| 12 | program:syntax_tape.av.number_into | avra_seat_opened | 27.3 M |
| 13 | program:syntax_tape.av.number_into | avra_array_push | 27.3 M |
| 14 | avrac:core/checking.av.checking | avra_array_push | 25.6 M |
| 15 | avrac:grammar/lexer.av.token | avra_array_push | 23.6 M |
| 16 | avrac:core/lists.av.filled$box enum/maybe box enum/1 | avra_array_push_owned | 23.0 M |
| 17 | program:saved_layout.av.record_labelled | avra_array_push | 22.8 M |
| 18 | avrac:compiler/backend/interp.av.Machine.put | avra_slot_unique | 22.6 M |
| 19 | avrac:grammar/lexer.av.Lexing.push | avra_slot_put | 22.6 M |
| 20 | program:hash_keyed_table.av.slots_holding | avra_array_push | 22.4 M |
| 21 | grammar:util.av.filled$word/maybe word/0 | avra_array_push | 22.2 M |
| 22 | program:syntax_tape.av.TapeWriter.count | avra_seat_opened | 22.2 M |
| 23 | program:syntax_tape.av.TapeWriter.count | avra_slot_unique | 22.2 M |
| 24 | avrac:core/store.av.Stamped.added | avra_slot_unique | 21.1 M |
| 25 | avrac:compiler/backend/interp.av.Machine.run_body | avra_seat_opened | 20.1 M |
| 26 | avrac:compiler/backend/interp.av.Machine.run_body | avra_slot_put | 19.3 M |
| 27 | grammar:untold.av.Untold.remember$box record/box record/1;box enum/box enum/1 | avra_seat_opened | 18.3 M |
| 28 | program:saved_layout.av.SavedLayoutWriter.record_closed | avra_slot_put | 18.0 M |
| 29 | program:saved_layout.av.SavedLayoutWriter.list_closed | avra_slot_put | 17.7 M |
| 30 | program:syntax_tape.av.TapeReader.place | avra_array_push | 17.1 M |

What they do: a write into a `Cell`'s list goes `slot_unique` (open the cell's box unique) then
`slot_put`/`slot_set` or `array_push`; a `mut` seat write rides `avra_seat_opened`. `word_pushed` is
three write rows per pushed word; `alloc_expr` opens the arena's table and pushes per node.

### 2d. Count traffic (retain / release / owned reads) by row × calling fn (top 30)

| # | fn | row | calls |
|---|---|---|---|
| 1 | program:disk_store.av.Segment.saved_in | release | 56.9 M |
| 2 | program:disk_store.av.Segment.saved_in | avra_array_get_owned | 50.9 M |
| 3 | avrac:compiler/backend/interp.av.Machine.run_body | retain | 42.6 M |
| 4 | avrac:compiler/backend/interp.av.Machine.run_body | avra_cell_release | 41.0 M |
| 5 | avrac:core/arena.av.Arena.node_at$box enum/box enum/1 | avra_array_get_owned | 33.0 M |
| 6 | avrac:compiler/backend/interp.av.Machine.run_body | release | 28.9 M |
| 7 | avrac:compiler/item_writes.av.receiver_use$body | release | 27.3 M |
| 8 | avrac:compiler/item_writes.av.receiver_use$body | retain | 26.9 M |
| 9 | avrac:grammar/lexer.av.Lexing.in_raw_body | retain | 26.3 M |
| 10 | avrac:grammar/lexer.av.Lexing.in_raw_body | avra_cell_release | 26.3 M |
| 11 | avrac:grammar/lexer.av.Lexing.routed | avra_cell_release | 26.3 M |
| 12 | avrac:core/store.av.SyntaxArena.untape_expr_tables | release | 26.2 M |
| 13 | avrac:grammar/lexer.av.Lexing.step | release | 26.0 M |
| 14 | avrac:grammar/lexer.av.Lexing.routed | retain | 25.9 M |
| 15 | avrac:compiler/backend/interp.av.Machine.at | avra_array_get_owned | 23.7 M |
| 16 | avrac:grammar/lexer.av.scan_step | release | 23.2 M |
| 17 | avrac:compiler/backend/interp.av.Machine.value | retain | 21.6 M |
| 18 | avrac:compiler/backend/interp.av.Machine.value | release | 21.6 M |
| 19 | avrac:core/signed_types.av.SignedType.word | release | 19.7 M |
| 20 | program:saved_layout.av.SavedLayoutWriter.record_closed | avra_slot_get_owned | 18.0 M |
| 21 | program:saved_layout.av.SavedLayoutWriter.record_closed | release | 18.0 M |
| 22 | avrac:compiler/untold_parser.av.avra_r76_0 | avra_cell_release | 17.4 M |
| 23 | avrac:compiler/backend/interp.av.Machine.step | release | 15.7 M |
| 24 | avrac:compiler/untold_parser.av.avra_r76_0 | retain | 15.6 M |
| 25 | avrac:core/signed_types.av.SignedType.word | retain | 14.4 M |
| 26 | program:query_engine.av.QueryEngine.record_read | retain | 13.7 M |
| 27 | program:query_engine.av.QueryEngine.record_read | avra_cell_release | 13.7 M |
| 28 | program:hash_keyed_table.av.HashKeyedTable.position_at$box record/box record/1 | avra_slot_get_owned | 13.4 M |
| 29 | program:hash_keyed_table.av.HashKeyedTable.position_at$box record/box record/1 | release | 13.4 M |
| 30 | program:query_engine.av.QueryEngine.settled_answer | release | 13.4 M |

### 2e. Retains by the Avra fn that asked (all retains, rows included; top 30)

| # | fn | retains |
|---|---|---|
| 1 | avrac:compiler/item_writes.av.receiver_use$body | 27.2 M |
| 2 | array_append | 26.5 M |
| 3 | avrac:compiler/backend/interp.av.Machine.value | 21.6 M |
| 4 | avra_slot_set_owned | 19.4 M |
| 5 | avrac:compiler/untold_parser.av.avra_r76_0 | 16.0 M |
| 6 | avrac:grammar/lexer.av.Lexing.routed | 13.0 M |
| 7 | avrac:features/compose.av.build_row | 11.9 M |
| 8 | avrac:core/arena.av.Arena.add$box enum/box enum/1 | 9.9 M |
| 9 | avrac:core/signed_types.av.SignedType.word | 9.7 M |
| 10 | avra_map_value_at_owned | 9.4 M |
| 11 | program:query_engine.av.QueryEngine.record_read | 9.0 M |
| 12 | avra_bytes_of_str | 8.7 M |
| 13 | avrac:core/nodes.av.Expr.identity | 8.5 M |
| 14 | avrac:compiler/backend/interp.av.Machine.rt_dispatch | 7.4 M |
| 15 | avrac:grammar/lexer.av.collapse_breaks | 6.6 M |
| 16 | program:query_engine.av.QueryEngine.settled_answer | 6.1 M |
| 17 | avrac:grammar/lexer.av.Lexing.push | 5.9 M |
| 18 | avrac:grammar/lexer.av.emit | 5.6 M |
| 19 | avrac:compiler/backend/interp.av.Machine.run_body | 5.6 M |
| 20 | avra_slot_put_owned | 5.6 M |
| 21 | avrac:core/parts.av.SyntaxArena.fn_parts | 5.1 M |
| 22 | avra_unwrap_owned | 5.1 M |
| 23 | avrac:grammar/lexer.av.token | 4.9 M |
| 24 | program:saved_layout.av.record_labelled | 4.6 M |
| 25 | avra_str_of_bytes | 4.5 M |
| 26 | avrac:grammar/lexer.av.opened | 4.4 M |
| 27 | program:saved_layout.av.list_starting_at | 4.2 M |
| 28 | program:syntax_tape.av.TapeWriter.number_of | 4.2 M |
| 29 | avrac:compiler/backend/interp.av.reaches_out | 4.1 M |
| 30 | program:syntax_tape.av.TapeWriter.wrote | 4.0 M |

### 2f. TIME by Avra fn — its own code and the runtime it calls directly (perf, -O1, top 30)

| # | fn | share |
|---|---|---|
| 1 | avrac:compiler/item_signatures.av.held_read | 9.0% |
| 2 | avrac:core/store.av.SyntaxArena.alloc_expr | 3.3% |
| 3 | text:text.av.BytesBuilder.word | 2.1% |
| 4 | program:saved_layout.av.SavedLayoutWriter.word_pushed | 2.1% |
| 5 | program:hash_keyed_table.av.HashKeyedTable.position_at$box record/box record/1 | 1.8% |
| 6 | avrac:grammar/lexer.av.scan_step | 1.2% |
| 7 | avrac:core/arena.av.Arena.node_at$box enum/box enum/1 | 1.1% |
| 8 | avrac:core/fp.av.fp_str | 1.1% |
| 9 | avrac:compiler/backend/interp.av.Machine.run_body | 1.0% |
| 10 | program:syntax_tape.av.TapeReader.place | 1.0% |
| 11 | text:text.av.BytesBuilder.octet | 1.0% |
| 12 | avrac:core/taped_leaves.av.SyntaxArena.placed_span | 0.9% |
| 13 | program:interned.av.KeyLane.text | 0.8% |
| 14 | text:text.av.BytesBuilder.run | 0.7% |
| 15 | avrac:grammar/lexer.av.collapse_breaks | 0.6% |
| 16 | avrac:compiler/item_lowered.av.signed_lowered | 0.6% |
| 17 | avrac:grammar/lexer.av.Lexing.step | 0.6% |
| 18 | relation:engine/table.av.list_cell$box bytes/box bytes/1 | 0.6% |
| 19 | program:hash_keyed_table.av.HashKeyedTable.added$box record/box record/1 | 0.6% |
| 20 | avrac:core/nodes.av.Expr.identity | 0.5% |
| 21 | program:hash_keyed_table.av.HashKeyedTable.position_at$box enum/box enum/1 | 0.5% |
| 22 | program:query_engine.av.QueryEngine.worked_out | 0.5% |
| 23 | avrac:core/store.av.SyntaxArena.alloc_stmt | 0.5% |
| 24 | avrac:compiler/item_tapes.av.avra_item_tape | 0.5% |
| 25 | avrac:core/fp.av.fp_mix | 0.5% |
| 26 | avrac:core/store.av.SyntaxArena.untape_expr_tables | 0.5% |
| 27 | program:saved_layout.av.SavedLayoutWriter.record_closed | 0.5% |
| 28 | program:key_fold.av.KeyLane.tagged_text | 0.5% |
| 29 | avrac:compiler/backend/interp.av.Machine.step | 0.5% |
| 30 | program:saved_layout.av.held_slot_value | 0.4% |

### 2g. Runtime leaf × the Avra fn that reached it (perf, -O1, top 30)

| # | leaf | Avra caller | share |
|---|---|---|---|
| 1 | malloc_consolidate | avrac:compiler/item_signatures.av.held_read | 3.6% |
| 2 | avra_rc_release | avrac:compiler/item_signatures.av.held_read | 1.9% |
| 3 | avra_release_dead | avrac:compiler/item_signatures.av.held_read | 1.5% |
| 4 | unlink_chunk.isra.0 | avrac:compiler/item_signatures.av.held_read | 1.0% |
| 5 | _int_malloc | avrac:core/store.av.SyntaxArena.alloc_expr | 0.9% |
| 6 | avra_cell_bytes_word | text:text.av.BytesBuilder.word | 0.5% |
| 7 | avra_slot_unique | avrac:core/store.av.SyntaxArena.alloc_expr | 0.5% |
| 8 | _int_malloc | avrac:core/taped_leaves.av.SyntaxArena.placed_span | 0.4% |
| 9 | cell_bytes_grown | text:text.av.BytesBuilder.word | 0.4% |
| 10 | avra_array_get | program:saved_layout.av.SavedLayoutWriter.word_pushed | 0.4% |
| 11 | str_owned | avrac:grammar/lexer.av.scan_step | 0.4% |
| 12 | _int_free | avrac:compiler/item_signatures.av.held_read | 0.4% |
| 13 | _int_malloc | text:text.av.BytesBuilder.word | 0.4% |
| 14 | _int_malloc | text:text.av.BytesBuilder.run | 0.3% |
| 15 | _int_malloc | program:syntax_tape.av.TapeReader.place | 0.3% |
| 16 | avra_slot_set | program:saved_layout.av.SavedLayoutWriter.word_pushed | 0.3% |
| 17 | sized_grown | text:text.av.BytesBuilder.word | 0.3% |
| 18 | avra_slot_unique | program:saved_layout.av.SavedLayoutWriter.word_pushed | 0.3% |
| 19 | cfree@GLIBC_2.2.5 | avrac:compiler/item_signatures.av.held_read | 0.3% |
| 20 | avra_slot_put | program:saved_layout.av.SavedLayoutWriter.word_pushed | 0.3% |
| 21 | array_made | avrac:core/store.av.SyntaxArena.alloc_expr | 0.3% |
| 22 | cell_bytes_grown | text:text.av.BytesBuilder.octet | 0.3% |
| 23 | blake3_compress_in_place_avx512 | program:answer_record.av.content_hash | 0.3% |
| 24 | blake3_compress_in_place_avx512 | - | 0.3% |
| 25 | array_made | avrac:grammar/lexer.av.scan_step | 0.2% |
| 26 | avra_str_word_at | avrac:core/fp.av.fp_str | 0.2% |
| 27 | avra_cell_bytes_word | text:text.av.BytesBuilder.octet | 0.2% |
| 28 | avra_rc_release | avrac:compiler/item_tapes.av.avra_item_tape | 0.2% |
| 29 | avra_bytes_of_str | program:saved_layout.av.SavedLayoutWriter.write_text | 0.2% |
| 30 | avra_array_push | avrac:core/store.av.SyntaxArena.alloc_expr | 0.2% |

### 2h. Self time by symbol (perf; -O0 and -O1, top 40 each)

-O0:

| # | symbol | self |
|---|---|---|
| 1 | avra_array_get | 9.8% |
| 2 | avra_slot_get | 7.1% |
| 3 | avra_rc_release | 6.3% |
| 4 | _int_malloc | 4.3% |
| 5 | avra_array_get_owned | 3.7% |
| 6 | array_made | 3.7% |
| 7 | avra_release_dead | 3.4% |
| 8 | avra_array_push | 3.2% |
| 9 | malloc_consolidate | 2.9% |
| 10 | avra_rc_retain | 2.3% |
| 11 | avra_slot_unique | 2.0% |
| 12 | avra_array_len | 1.9% |
| 13 | unlink_chunk.isra.0 | 1.8% |
| 14 | avrac:core/fp.av.fp_mix | 1.7% |
| 15 | box_free | 1.6% |
| 16 | avra_slot_get_owned | 1.4% |
| 17 | avra_array_push_owned | 1.3% |
| 18 | avra_array_push_moved | 1.0% |
| 19 | avra_streq | 1.0% |
| 20 | avra_slot_put | 1.0% |
| 21 | __memmove_avx512_unaligned_erms | 1.0% |
| 22 | avra_map_slot | 0.8% |
| 23 | avra_cell_bytes_word | 0.8% |
| 24 | array_grow | 0.8% |
| 25 | __memset_avx512_unaligned_erms | 0.7% |
| 26 | program:saved_layout.av.SavedLayoutWriter.word_pushed | 0.5% |
| 27 | avrac:grammar/lexer.av.two_char_of | 0.5% |
| 28 | avra_str_char_code | 0.5% |
| 29 | avra_slot_set | 0.5% |
| 30 | malloc | 0.5% |
| 31 | cell_bytes_grown | 0.5% |
| 32 | sized_grown | 0.4% |
| 33 | avra_str_join | 0.4% |
| 34 | avrac:compiler/backend/interp.av.Machine.run_body | 0.4% |
| 35 | blake3_compress_in_place_avx512 | 0.4% |
| 36 | program:saved_layout.av.width_holding | 0.4% |
| 37 | avra_array_sized | 0.4% |
| 38 | program:saved_layout.av.held_slot_value | 0.4% |
| 39 | str_owned | 0.3% |
| 40 | __memcmp_evex_movbe | 0.3% |

-O1:

| # | symbol | self |
|---|---|---|
| 1 | _int_malloc | 5.8% |
| 2 | avra_rc_release | 5.5% |
| 3 | array_made | 4.9% |
| 4 | avra_release_dead | 4.7% |
| 5 | malloc_consolidate | 3.9% |
| 6 | avra_array_push | 2.8% |
| 7 | unlink_chunk.isra.0 | 2.3% |
| 8 | avra_slot_unique | 2.1% |
| 9 | box_free | 2.0% |
| 10 | program:hash_keyed_table.av.HashKeyedTable.position_at$box record/box record/1 | 1.8% |
| 11 | avra_rc_retain | 1.7% |
| 12 | avra_array_push_owned | 1.5% |
| 13 | avra_array_get | 1.4% |
| 14 | __memmove_avx512_unaligned_erms | 1.3% |
| 15 | avra_streq | 1.2% |
| 16 | avrac:core/arena.av.Arena.node_at$box enum/box enum/1 | 1.1% |
| 17 | avra_array_push_moved | 1.1% |
| 18 | array_grow | 1.0% |
| 19 | avra_map_slot | 1.0% |
| 20 | avra_slot_put | 0.9% |
| 21 | avra_cell_bytes_word | 0.9% |
| 22 | program:saved_layout.av.SavedLayoutWriter.word_pushed | 0.8% |
| 23 | __memset_avx512_unaligned_erms | 0.7% |
| 24 | avrac:compiler/backend/interp.av.Machine.run_body | 0.7% |
| 25 | avra_slot_set | 0.7% |
| 26 | cell_bytes_grown | 0.7% |
| 27 | avrac:core/fp.av.fp_str | 0.7% |
| 28 | avra_str_char_code | 0.6% |
| 29 | malloc | 0.6% |
| 30 | sized_grown | 0.6% |
| 31 | program:hash_keyed_table.av.HashKeyedTable.position_at$box enum/box enum/1 | 0.5% |
| 32 | avrac:core/fp.av.fp_mix | 0.5% |
| 33 | blake3_compress_in_place_avx512 | 0.5% |
| 34 | avra_str_word_at | 0.5% |
| 35 | _int_free | 0.5% |
| 36 | avra_str_join | 0.5% |
| 37 | avra_array_sized | 0.5% |
| 38 | program:saved_layout.av.held_slot_value | 0.4% |
| 39 | __memcmp_evex_movbe | 0.4% |
| 40 | avra_cell_release | 0.4% |

Where glibc's 14.0 % at -O1 is asked from: avra_release_dead's frees 6.0 %, array_made 3.5 %, array_grow
(realloc) 2.4 %, sized_moved 0.8 %. The box free lists stop at LIST_LIMIT = 16 384 per size class (a
deliberate peak-memory bound, runtime/avra_runtime.c), so a cascade that frees millions of boxes hands
most of them to glibc and the next phase mallocs them back (`malloc_consolidate`, `unlink_chunk`).

## 3. The three changes with the largest expected TIME prize (at -O1, the installed level)

**1. The allocator under boxes and buffers — expected −9 s (−11 %), measured as an upper bound.**
Replace glibc beneath `fresh()` / `realloc` / `free` with a page allocator that reuses freed pages across
size classes: a vendored mimalloc, or runtime-own slabs (64 KB pages per class, free lists per page, an
empty page returned to a pool any class can take, which keeps the peak-memory bound LIST_LIMIT exists for).
*Measured before building:* `LD_PRELOAD` mimalloc on the unchanged -O1 binary: −9.0 s mean over 4
alternating rounds, −110 MB peak RSS. *How to accept the build:* the same paired protocol (≥ 4
alternating rounds, same binary otherwise), the runtime's own accounting (`AVRA_MEM_STATS` peak, `mem:
live 0 bytes at exit`), the sound check and RC_GUARD, and it must reach at least the preload's number.

**2. Freeing in bulk: the read-back item cache and the release cascade — expected up to −7 s (≤ 9 %).**
`item_signatures.held_read` alone is 9.0 % of -O1 time, almost all of it FREEING: on passing
HELD_BYTES = 320 MB it drops the whole `Map<string, ReadItem>` (`held_items().set({})`), and the release
recursion walks every node of every held store (`malloc_consolidate` 3.6 %, rc_release 1.9 %,
release_dead 1.5 %, unlink_chunk 1.0 % under it). Two shapes, either general: (a) evict by halves or
least-recently-read instead of all at once, so each eviction frees a bounded part and keeps the hot
items; (b) a store read back is one ARENA — its boxes come from its own pages and dying frees the pages,
not each box (needs the memory pass to know no box escapes the store, or a copy-out at escape).
*Measure before building:* count evictions and boxes freed per eviction (a counter beside
`held_bytes`), the re-read rate after an eviction (how many keys come back), and a run with HELD_BYTES
raised to 640 MB / 1.2 GB: time vs peak RSS. If doubling the cap removes most of the 9 % at an acceptable
peak, (a) is the change; if re-reads are rare, the cost is pure freeing and (b) is.

**3. The write rows as hot leaves — expected −4 to −7 s (of the 13.3 %).**
At -O1 the READ rows inline (3.9 % left) but every WRITE row stays a call: `avra_array_push` 786 M,
`slot_unique` 432 M, `slot_put` 353 M, `push_owned` 249 M, `slot_set` 197 M, `push_moved` 189 M,
`cell_bytes_word` 155 M ≈ 2.4 G calls ≈ 10 s, ~4 ns each. Their fast paths are a few instructions (unique
box, `len < cap`: store the word and the mark, bump `len`); put the fast path in the hot bitcode
(runtime/avra_hot.c, the file -O1 inlines) and keep the slow path (grow, clone-on-share, release of the
old owned word) a call. *Measure before building:* `perf annotate` of each write row on this run to get
the fast-path share of its samples (the prize is fast-path samples × (1 − inlined cost)), and a micro
program pushing 10⁸ words into a unique list at -O1 with the row inlined by hand vs not.

Not in the three, measured: row READS (25.7 % at -O0, 3.9 % at -O1) — the -O1 default already took that
prize (−23 s); a representation change that removes reads (flattening `Cell`s out of identity records,
fields by value) pays at -O0, not at the installed level. Box COUNT alone (part 1 of this lane: −13 %
boxes, ≤ 2 % CPU) agrees: making is 5.9 % + 3.5 % malloc at -O1.

## 4. Receipts on the merged branch (head 268f701f = trunk aaa040c3 + next-base 70c41adc)

The measurements above are on the db94aa87 + saved-answers-2 base; the branch now carries trunk and
next-base. Builder: the ladder's HEAD product (805682b, which already carries the armed cell-bytes rows),
so no separate ladder run was needed for aaa040c3; stores cleared after each compiler swap.
* old-path `make try` exit 0, installed as build/avra; `AVRA_PROGRAM=1 make try` exit 0.
* cold `avra-try tapes cli --built`: **44980 / 44980 made**.
* `AVRA_SOUND_CHECK=1 avra-try check packages/cli`: **sound check: 0** (`defect: in` lines: 0).
* `check packages/cli --baseline tools/idioms.baseline`: exit 0.
* `check packages/std-avrac --baseline`: one finding, in a trunk test this branch does not touch
  (features/mutation/tests/state_unannotated.av, `let_stmt.unmutated_mut`). The first attempt ran out of
  the memory pool with stores left by an earlier compiler; with the stores cleared it ran.
* What this branch changes: tools/census.sh (CENSUS_BUILDER, package stores stood aside, one-pass
  symbols), runtime census tables (bytes, labelled sites, row calls, 1 M sorted slots — census builds
  only), and `avra_census_row` emitted before each runtime call ONLY when AVRA_CENSUS_TYPES is set. A
  shipping build emits nothing new. The enum-in-cell rule stays on branch
  avra-lane-unboxed-values-enum-cell (b74887b), not in this bundle.
