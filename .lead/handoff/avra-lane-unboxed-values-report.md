# avra-lane-unboxed-values — where the compiler's boxes come from, and the first layout rule

Branch `avra-lane-unboxed-values` (merged with trunk 5e7ff03b). Everything below is measured on a COLD
`tapes $PWD/packages/cli --built`, work-ahead OFF (a forked child's census is lost), Linux, 4 cores.

## 0. Headline

* A cold cli build mints **523.3 M boxes** (new-path-built compiler; 511.2 M old-path-built), 68.2 M
  list buffers, 812 M retains, 1320 M releases, 6.63 G list reads, 1.87 G list writes. Peak 2.3 GB RSS.
* Every boxed record, boxed enum and crossing box is an `AvraArray`: 16 B header + 40 B struct + 8 B
  per slot + 1 mark byte per slot. A `Span?` (16 B of payload) costs ~65 B in TWO boxes.
* **Rule picked and prototyped: a value enum in a one-word cell (list element, map value, `Cell`) is its
  word, its tag in the cell's mark byte.** Removes **70.28 M boxes (−13.4 %)**, 70.3 M releases and
  reclaims, 140.6 M list writes; retains unchanged. eval == native on every program test
  (`std-avrac --ran`: 0 failing); the rule-built compiler rebuilds the cli byte-identically.
* **Honest result on time: −13.4 % of boxes bought ≤ 2 % CPU, inside the noise** (user 96.7 / 94.6 s →
  93.6 / 94.4 s). A box costs ≲ 30 ns all-in (free-list alloc). Unboxing alone cannot reach the 5 s
  target; a stage pays only where it also removes READS and RC traffic (stages 2 and 5 below).

## 1. Instruments (commits 01c244c, 1dd2989)

* `tools/census.sh` on Linux: runtime and emitted code keep frame pointers (`-fno-omit-frame-pointer`,
  `AVRA_FRAME_POINTERS=1`), so `made:` names the Avra fn that asked for the box (two frames up).
* NEW: the `type:` table carries BYTES; a `typed:` table charges each box to its minting site WITH its
  label (`AVRA_CENSUS_TOP` rows); census site tables are 256 K slots (the compiler has > 32 K minting
  sites); `CENSUS_BUILDER=` names the compiler that builds the census compiler (a layout rule belongs
  to the BUILDING compiler).
* BUG FIXED: `tapes <pkg>` keeps its store in `<pkg>/.avra-cache`, which census.sh never stood aside — a
  second census of a package ran WARM ("worked: 0 answers here", 45 M boxes instead of 511 M). A
  package named on the command now stands aside too and comes back on exit.
* BUG FIXED: site resolution ran one `addr2line` per row (hours for 4 000 rows) → one pass (1.5 s).
* Label caveat: an old-path-built compiler labels a box by its IR register type (`List<int>` and `[]`
  hide crossing boxes); a new-path-built one by layout KIND (`box record`, `box slot`). Table 2a uses the
  former for language types, 2b–2d the latter.

## 2. Ranked tables

### 2a. Boxes by TYPE (old-path-built census compiler, 511.2 M boxes; label = IR type, minting row)

| # | type by row | boxes | bytes |
|---|---|---|---|
| 1 | List<int> by avra_enum_boxed | 70.23 M | 5197 MB |
| 2 | [] by avra_array_sized | 50.81 M | 2845 MB |
| 3 | List<int> by avra_array_sized | 44.19 M | 3154 MB |
| 4 | List<SavedSlot> by avra_array_sized | 26.31 M | 1928 MB |
| 5 | string by avra_str_join | 16.78 M | 804 MB |
| 6 | ScanStep by avra_array_sized | 12.85 M | 1182 MB |
| 7 | Bytes by avra_bytes_of_str_reusing | 11.91 M | 1016 MB |
| 8 | string by avra_int_text | 11.30 M | 218 MB |
| 9 | Val by avra_array_sized | 11.30 M | 827 MB |
| 10 | List<string> by avra_array_sized | 10.29 M | 617 MB |
| 11 | string by avra_array_sized | 10.12 M | 1089 MB |
| 12 | ContentHash? by avra_array_sized | 8.11 M | 527 MB |
| 13 | string by avra_str_substring | 7.20 M | 187 MB |
| 14 | List<ExprId> by avra_array_sized | 6.98 M | 410 MB |
| 15 | Loc by avra_array_sized | 6.60 M | 547 MB |
| 16 | TapePlace? by avra_array_sized | 6.44 M | 418 MB |
| 17 | Token by avra_array_sized | 6.05 M | 611 MB |
| 18 | Captured<Token, LangNode> by avra_array_sized | 5.67 M | 419 MB |
| 19 | SavedBytes by avra_array_sized | 5.47 M | 454 MB |
| 20 | Span? by avra_array_sized | 5.42 M | 352 MB |
| 21 | Bytes by avra_bytes_slice | 5.30 M | 177 MB |
| 22 | fn(HeldEntry) -> bool by avra_array_sized | 4.78 M | 354 MB |
| 23 | List<Val> by avra_array_sized | 4.57 M | 256 MB |
| 24 | SavedRecord by avra_array_sized | 4.55 M | 501 MB |
| 25 | string? by avra_str_of_bytes | 4.31 M | 159 MB |
| 26 | SavedList by avra_array_sized | 4.18 M | 422 MB |
| 27 | string by avra_str_concat_reusing | 3.92 M | 75 MB |
| 28 | List<bool> by avra_array_sized | 3.85 M | 301 MB |
| 29 | Cell<List<int>> by avra_array_sized | 3.49 M | 227 MB |
| 30 | Ins by avra_array_sized | 3.46 M | 286 MB |

`List<int> by avra_enum_boxed` = value enums crossing a one-word cell; `List<int>`/`[]` by
`avra_array_sized` = list literals AND flat records crossing (`crossed(.Fields)`) AND the inner box of a
flat record's nullable.

### 2b. Boxes by layout KIND (new-path-built census compiler — the prototype's baseline, 523.3 M)

| kind by row | boxes | bytes |
|---|---|---|
| box list by avra_array_sized | 180.95 M | 11656 MB |
| box record by avra_array_sized | 83.97 M | 7786 MB |
| **box list by avra_enum_boxed** (a value enum crossing a cell) | **70.27 M** | **5200 MB** |
| box enum by avra_array_sized | 36.24 M | 2730 MB |
| box slot by avra_array_sized (a flat record's nullable) | 24.90 M | 1618 MB |
| box closure by avra_array_sized | 24.83 M | 1972 MB |
| box text by avra_str_join | 16.80 M | 805 MB |
| box range by avra_array_sized | 13.57 M | 1004 MB |
| box cell by avra_array_sized | 13.26 M | 862 MB |
| box text by avra_int_text | 11.33 M | 218 MB |
| box bytes by avra_bytes_of_str | 11.23 M | 802 MB |
| box text by avra_array_sized | 10.13 M | 1090 MB |

### 2c. Boxes by ALLOCATING FN (top 30; new-path-built baseline)

| # | fn | boxes | bytes |
|---|---|---|---|
| 1 | avrac:core/signed_types.av.SignedType.written_into | 16.28 M | 1192 MB |
| 2 | avrac:core/store.av.SyntaxArena.alloc_expr | 12.98 M | 844 MB |
| 3 | avrac:compiler/item_typed.av.TypedBody.written_into | 12.55 M | 928 MB |
| 4 | program:saved_layout.av.saved_layout_writer | 9.97 M | 648 MB |
| 5 | program:frontier.av.FrontierChange.question_at | 9.54 M | 663 MB |
| 6 | avrac:core/lowering.av.CalledFn.written_into | 8.88 M | 678 MB |
| 7 | avrac:core/ir.av.Ins.written_into | 7.40 M | 538 MB |
| 8 | avrac:core/signed_types.av.SignedType.spelled | 7.33 M | 268 MB |
| 9 | avrac:grammar/lexer.av.skip | 7.13 M | 656 MB |
| 10 | program:query_engine.av.held_file | 6.78 M | 381 MB |
| 11 | program:saved_layout.av.SavedLayoutWriter.finish_pending_run | 6.51 M | 653 MB |
| 12 | avrac:core/store.av.SyntaxArena.untape_expr_tables | 6.26 M | 350 MB |
| 13 | avrac:core/taped_leaves.av.SyntaxArena.placed_span | 6.15 M | 427 MB |
| 14 | program:syntax_tape.av.TapeReader.place | 6.15 M | 455 MB |
| 15 | program:address.av.SourceFileAddress.written_into | 6.09 M | 451 MB |
| 16 | avrac:core/ir.av.Reg.written_into | 5.90 M | 410 MB |
| 17 | avrac:core/nodes.av.Expr.identity | 5.85 M | 436 MB |
| 18 | avrac:grammar/lexer.av.token | 5.79 M | 585 MB |
| 19 | program:query_engine.av.QueryEngine.settled_answer | 5.54 M | 385 MB |
| 20 | avrac:grammar/lexer.av.emit | 5.53 M | 509 MB |
| 21 | avrac:grammar/bridge.av.token_loc | 5.28 M | 438 MB |
| 22 | program:saved_layout.av.SavedSource.octets_at | 4.81 M | 287 MB |
| 23 | program:frontier.av.fresh_place | 4.79 M | 397 MB |
| 24 | program:answer_record.av.ContentHash.written_into | 4.74 M | 351 MB |
| 25 | program:saved_layout.av.record_labelled | 4.58 M | 503 MB |
| 26 | avrac:grammar/lexer.av.scan_step | 4.56 M | 90 MB |
| 27 | program:answer_record.av.question | 4.54 M | 366 MB |
| 28 | program:query_engine.av.held_text | 4.53 M | 208 MB |
| 29 | program:saved_layout.av.list_starting_at | 4.21 M | 425 MB |
| 30 | avrac:compiler/backend/interp.av.alloca_reg | 4.06 M | 228 MB |

### 2d. Allocating fn × kind (top 40)

| # | fn | kind / row | boxes | bytes |
|---|---|---|---|---|
| 1 | avrac:core/store.av.SyntaxArena.alloc_expr | box list / avra_array_sized | 12.98 M | 844 MB |
| 2 | avrac:compiler/item_typed.av.TypedBody.written_into | box list / avra_enum_boxed | 12.47 M | 923 MB |
| 3 | avrac:core/signed_types.av.SignedType.written_into | box list / avra_enum_boxed | 10.46 M | 774 MB |
| 4 | program:saved_layout.av.SavedLayoutWriter.write_text | box bytes / avra_bytes_of_str | 10.19 M | 730 MB |
| 5 | avrac:grammar/lexer.av.skip | box record / avra_array_sized | 7.13 M | 656 MB |
| 6 | avrac:core/lowering.av.CalledFn.written_into | box list / avra_enum_boxed | 6.88 M | 509 MB |
| 7 | avrac:core/store.av.SyntaxArena.untape_expr_tables | box list / avra_array_sized | 6.25 M | 350 MB |
| 8 | avrac:core/nodes.av.Expr.identity | box record / avra_array_sized | 5.85 M | 436 MB |
| 9 | avrac:core/signed_types.av.SignedType.written_into | box list / avra_array_sized | 5.82 M | 418 MB |
| 10 | avrac:grammar/lexer.av.token | box record / avra_array_sized | 5.79 M | 585 MB |
| 11 | avrac:grammar/lexer.av.emit | box record / avra_array_sized | 5.53 M | 509 MB |
| 12 | avrac:grammar/bridge.av.token_loc | box record / avra_array_sized | 5.28 M | 438 MB |
| 13 | program:saved_layout.av.saved_layout_writer | box cell / avra_array_sized | 4.98 M | 324 MB |
| 14 | avrac:core/ir.av.Ins.written_into | box list / avra_enum_boxed | 4.81 M | 356 MB |
| 15 | program:frontier.av.fresh_place | box closure / avra_array_sized | 4.79 M | 397 MB |
| 16 | program:frontier.av.FrontierChange.question_at | box list / avra_array_sized | 4.77 M | 353 MB |
| 17 | program:frontier.av.FrontierChange.question_at | box slot / avra_array_sized | 4.77 M | 310 MB |
| 18 | program:saved_layout.av.record_labelled | box record / avra_array_sized | 4.58 M | 503 MB |
| 19 | avrac:grammar/lexer.av.scan_step | box text / avra_str_substring | 4.56 M | 90 MB |
| 20 | program:saved_layout.av.SavedSource.octets_at | box bytes / avra_bytes_slice | 4.33 M | 147 MB |
| 21 | program:saved_layout.av.list_starting_at | box record / avra_array_sized | 4.21 M | 425 MB |
| 22 | program:address.av.SourceFileAddress.written_into | box list / avra_enum_boxed | 4.06 M | 300 MB |
| 23 | avrac:compiler/backend/interp.av.alloca_reg | box list / avra_array_sized | 4.06 M | 228 MB |
| 24 | avrac:core/signed_types.av.SignedType.spelled | box list / avra_array_sized | 3.66 M | 205 MB |
| 25 | avrac:core/signed_types.av.SignedType.spelled | box text / avra_str_join | 3.66 M | 62 MB |
| 26 | avrac:core/signed_types.av.SignedType.spelled | box text / avra_str_concat_reusing | 3.62 M | 63 MB |
| 27 | program:query_engine.av.held_file | box text / avra_int_text | 3.39 M | 64 MB |
| 28 | program:saved_layout.av.saved_layout_writer | box list / avra_array_sized | 3.32 M | 186 MB |
| 29 | avrac:compiler/backend/interp.av.Machine.const_int_val | box enum / avra_array_sized | 3.30 M | 243 MB |
| 30 | program:saved_layout.av.SavedLayoutWriter.finish_pending_run | box bytes / avra_bytes_of_list | 3.25 M | 471 MB |
| 31 | program:saved_layout.av.SavedLayoutWriter.finish_pending_run | box list / avra_array_sized | 3.25 M | 182 MB |
| 32 | program:answer_record.av.ContentHash.written_into | box list / avra_enum_boxed | 3.16 M | 234 MB |
| 33 | avrac:core/taped_leaves.av.SyntaxArena.placed_span | box list / avra_array_sized | 3.08 M | 228 MB |
| 34 | avrac:core/taped_leaves.av.SyntaxArena.placed_span | box slot / avra_array_sized | 3.08 M | 200 MB |
| 35 | program:syntax_tape.av.TapeReader.place | box list / avra_array_sized | 3.08 M | 255 MB |
| 36 | program:syntax_tape.av.TapeReader.place | box slot / avra_array_sized | 3.08 M | 200 MB |
| 37 | avrac:compiler/item_lowered.av.LoweredFn.written_into | box list / avra_enum_boxed | 3.02 M | 224 MB |
| 38 | avrac:core/ir.av.Reg.written_into | box list / avra_array_sized | 2.95 M | 192 MB |
| 39 | avrac:core/ir.av.Reg.written_into | box list / avra_enum_boxed | 2.95 M | 218 MB |
| 40 | program:query_engine.av.QueryEngine.hash_of_answer_to | box record / avra_array_sized | 2.79 M | 282 MB |

## 3. What each top type would be unboxed, and what the law already flattens

The law today (core/layout.av `declared`; features/decls.av `flatten` — the two paths agree): a record
with no type parameters whose fields are ALL scalar (int, bool, a payload-free enum or its nullable) is
FLAT — one field travels as the field (typed ids `ExprId`, `StmtId`, `Reg` are words), several as
`Fields` in registers. A payload-free enum is a `Word`. An enum of ≤ 62 variants each carrying ≤ 1 word
(int, pointer, payload-free enum — NOT bool/float) is `Tagged`; its `T?` spends the spare tag. `T?` of a
pointer is the pointer. `int?`/`bool?` is `Maybe` (a pair; in a cell, the word + `MARK_ABSENT`).
Everything else is a box.

| top type(s) | boxes | today | unboxed form | law has it? |
|---|---|---|---|---|
| value enums in list/map/Cell cells (`SavedSlot`, `Open`, `Result<int, …>`) | 70.3 M | Tagged in registers, but a ONE-WORD CELL forces a crossing box `[tag, word]` | word in the cell, tag in the mark byte | **MISSED → prototyped** |
| `ContentHash?` `TapePlace?` `Span?` (several-field flat record's nullable) | 24.9 M slot + ~18 M inner boxes | `Boxed(Slot)` holding a crossing box: TWO boxes per present value | `Maybe(Fields)` in registers; a crossing only where stored in a cell | MISSED |
| `ExprId?` `StmtId?` `Reg?` (one-field flat record's nullable) | ~4 M | `Boxed(Slot)` | exactly the field's own nullable — what `int?` already is | MISSED (inconsistent with `int?`) |
| `Val` (interp) and any enum with a bool payload | 11.3 M (old) / ~7 M (new) | boxed: a bool payload is refused (decls.av `payload_word` names an unexplained `MetaVal` trap) | `Tagged`, the bool as a word | MISSED (blocked on that trap) |
| `Token`, `Loc`, `ScanStep`, `SavedBytes`, `SavedList`, `SavedRecord`, `Ident` | of 84 M record boxes | boxed: any pointer field | `Fields` with counted leaves (`Layout.Fields.counted()` already models it), ≤ 3–4 words | MISSED — the memory pass and backend must retain/release each counted leaf |
| `Range` | 13.6 M | `Boxed(Range)` | `Fields(lo, hi)` | MISSED |
| `List<SavedSlot>` (Saved derive `write_record(v, [..slots])`) | 26.3 M | a real list per saved record | not layout: the derive writes slots into the writer | n/a |
| typed ids, flat records (`Span`, `ContentHash`, `TapePlace`, `ExprMarks`) in registers | 0 | `Word` / `Fields` | — | HAS IT |
| a flat record as a list element | inside the 181 M "box list" | each element a crossing box of its fields | k cells per element (1 for a one-word record) | MISSED (split not measured) |

## 4. The rule (prototyped): a value enum in a cell

**Statement.** A value of layout `Tagged(counted)` in a ONE-WORD CELL — a list element, a map value, a
`Cell`'s slot — is its WORD in the cell, owned (`MARK_OWNED`) exactly when bit `tag` of `counted` says
its variant carries a pointer, and its TAG in the cell's mark byte above the owned and absent bits
(`mark = tag << 2 | owned`); the spare tag (an absent `T?`) is `MARK_ABSENT` with a zero word. It is the
nullable-scalar-in-a-cell law (`int?` = word + `MARK_ABSENT`) one step wider.

**Where it lives** (new path only; the old path keeps its crossing boxes — a different compiler, which
never shares a list with the new one):
* runtime: avra_box.h `MARK_TAG_SHIFT`; rows `avra_array_push_enum`, `avra_slot_set_enum`,
  `avra_slot_enum_tag`, `avra_slot_enum_word` (lends), `avra_array_last_enum_tag`, `avra_array_drop_last`,
  `avra_map_set_enum`, `avra_map_enum_tag_at`, `avra_map_enum_word_at` — their RtSig rows, their claim in
  the generated avra_rt.h, and their evaluator hosts (a cell holds `P([tag, word])` or `Gone`).
* lowering: core/boxed.av `slot_read` / `proven_read` / `element_at` and core/own_verbs.av `popped` /
  `map_value` / `map_written` / `slot_written` / `push_slot` gain a `.Tagged` arm beside their `.Maybe` arm.
* data laid before the run: `Slot.Tagged(tag, word)` — the const crossing (compiler/item_consts.av
  `cell`) and quote shapes (core/quote_match.av `open_slot`) lay it; the backend's `slot_mark` /
  `slot_value`, the evaluator, ir_text, code_hash and tapes' renaming read it.

**Soundness conditions** (each checked on this branch):
1. EVERY reader and EVERY writer of a one-word cell holding a `Tagged` value takes these arms — a writer
   left on the crossing box is a wrong answer, not a slow one. The census caught exactly that: quote
   shapes' static `Open` cells were still crossing boxes, so the rule-built compiler read a pointer as a
   hole index and ran to the 12 GB ceiling. Fixed at the cause (69dde69). The crossing writers left
   (records' inline two-slot leaves, closure captures, dyn boxes, `once` answers) are read by crossing
   readers and untouched.
2. Every runtime read of a mark tests bits (`& MARK_OWNED`, `& MARK_ABSENT`) — all 33 audited. The one
   copy that rebuilt a mark from OWNED alone (`array_append`'s owned arm: slice and concat lost tags) now
   copies the mark whole.
3. ≤ 62 variants (6 tag bits) — the `MOST_VALUED_VARIANTS` bound the layout already enforces.
4. No runtime row compares, hashes, sorts or prints list elements by word (that is lowered Avra code over
   `element_at`) — checked over every `avra_array_*` / `avra_map_*` row.
5. Static data: `data_slot` still declines `Tagged`; the const crossing and quote shapes lay
   `Slot.Tagged` (mark = tag·4 | the word's own mark, or `MARK_ABSENT`).
6. The memory pass needs nothing new: the word rows lend like `avra_enum_word`, the write rows take their
   word by `Takes.Counted` like `avra_slot_set_tagged`.

## 5. Prototype receipts

Census, cold `tapes cli --built`, work-ahead off, ONE source tree, the census compiler built by trunk
`build/avra` (before) vs the rule-bearing `avra-try` (after), both `AVRA_PROGRAM=1` (base e8760228):

| | before | after | Δ |
|---|---|---|---|
| boxes | 523,269,986 | 452,987,985 | −70,282,001 (−13.4 %) |
| `avra_enum_boxed` boxes | 70,274,489 | 0 | −70.27 M (−5.20 GB allocated) |
| retains | 812,061,693 | 812,062,464 | +771 |
| releases | 1,320,447,182 | 1,250,171,026 | −70.28 M |
| reclaims | 511,501,072 | 441,224,182 | −70.28 M |
| list writes | 1,871,753,623 | 1,731,202,730 | −140.6 M |
| list reads | 6,634,605,055 | 6,778,902,898 | +144.3 M (a tag row and a word row per read) |
| peak RSS | 2285 MB | 2283 MB | — |

* Shipping compilers, no census, same source: `avra-try` (built by trunk; the rule NOT in its own code)
  vs `avra-rule` (built by avra-try; the rule in its own code). Cold `tapes cli --built`, work-ahead off,
  two alternating rounds: user CPU **96.71 / 94.60 s vs 93.63 / 94.38 s**; identical tapes output
  (43267 of 43271 made on that base). Inside the noise.
* Fixed point: `avra-rule` rebuilding the cli gives a binary `cmp`-identical to `avra-rule` itself.
* eval == native: `avra-try tapes std-avrac --ran` (base e8760228) — 490 program tests, 423 made, 421 in
  the evaluator, 423 natively, **0 failing**. New program test `features/enums/tests/enum_in_cell`:
  list push / index write / slice / concat / pop, `List<T?>` with absences, a map's write over, a `Cell`,
  a counted payload and a word payload — both engines.

## 6. Staged plan (prize = measured boxes on a cold cli build unless marked est.)

| stage | rule | prize | cost / risk |
|---|---|---|---|
| 1 (this branch) | a value enum in a cell: word + tag in the mark | −70.3 M boxes, −70.3 M releases; CPU ≤ 2 % | small; ready for review |
| 2 | a flat record's nullable: one field → the field's own nullable (`ExprId?` laid as `int?`); several → `Maybe(Fields)` in registers, a crossing only into a cell | −24.9 M slot boxes + est. ~18 M inner boxes (question_at 4.77, placed_span 3.08, TapePlace.place 3.08, settled_answer 2.77, span_place 1.71, place_in 1.47, loc_span 1.30) ≈ −40 M, and two reads fewer per access | one field: tiny (every `Maybe(Word)` arm exists); several: the `.Maybe` arms learn a carried value wider than a word |
| 3 | bool payloads in value enums (find the `MetaVal` trap decls.av names first) | `Val`: 11.3 M (old) / est. ~7 M new (`Machine.const_int_val` 3.3 M, `bin_val` 1.5 M, `pushed` 1.1 M) | needs that trap's cause |
| 4 | `Range` as `Fields(lo, hi)` | −13.6 M | small; ranges cross `avra_range_*` rows |
| 5 | small records with pointer fields as `Fields` with counted leaves (≤ 3–4 words, no state field) | up to −84 M record boxes and the row reads through them (Token / Loc / ScanStep alone ~37 M) | large: the memory pass and backend retain/release each counted leaf; a copy costs k retains for 1 — measure per type |
| 6 | a flat record in a list cell as k cells (1 for a one-word record) | inside the 181 M "box list" — split not measured (needs a crossing label) | medium |
| — (derive, not layout) | Saved derive writes slots into the writer instead of `write_record(v, [..slots])` | −26.3 M list boxes | trivial |
| — (representation) | a record box without the 40 B `AvraArray` struct (header + words + marks) | ~−35 % of record/slot bytes, no count change | runtime-wide |

What the measurement says about the 5 s target: the box COUNT is not the dominant cost (13 % of boxes ≈
0–2 % CPU). The heavy counters are 6.7 G list reads and 1.3 G releases; a stage earns its keep by
removing READS and RC traffic — every access to a boxed field is a row call — not by removing boxes.
The next instrument I would build: a per-row CALL census (row × calling fn), to rank read traffic the way
this one ranks boxes.

## 7. Receipts after merging trunk 5e7ff03b (branch head b74887b)

* old-path `make try` exit 0 (installed as build/avra); `AVRA_PROGRAM=1 make try` exit 0.
* `avra-try runtime-header` == runtime/avra_rt.h (the 9 new rows claim their C bodies).
* `avra-try tapes std-avrac --ran`: 501 program tests, **449 made, 447 in the evaluator, 449 natively,
  0 failing** (trunk: 448 made; +1 is enum_in_cell).
* cold `avra-try tapes cli --built`: **43962 / 43962 made** (trunk 43942; the +20 bodies are this
  branch's own code).
* `check packages/cli --baseline tools/idioms.baseline`: exit 0. `check packages/std-avrac --baseline`:
  only the 4 known trunk findings (code_hash_test ×2, reach_test, typed_member); this branch's own
  findings (a when-ladder and a push loop in the new test, one message said three times) are fixed.
* The census counts and timing in §5 were taken on base e8760228; the rule's code is unchanged since,
  except the quote-shape fix (69dde69, in the "after" census) and the voice/fmt commits.

## 8. Unproven

* A CPU effect beyond noise (needs more rounds on a quiet machine).
* `AVRA_RC_GUARD=1` over the new program test in both engines — not run.
* tools/witness_program_edit.sh — not run (no query, memo or build-driver code touched).
* The old path is unchanged: an old-path-built compiler keeps every crossing box.
