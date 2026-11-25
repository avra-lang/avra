# avra-lane-parity-resolve-2: handback 3

Branch `avra-lane-parity-resolve-2`. Bundle range: `1cdefa1d..HEAD`, on top of what batch 41 fetched.

## New since 1cdefa1d
1. **type.variant_arity** (r392, `enum E { all, B }` then `E.all()`): an enum's variant named `all` is the name `E.all` reads. The built-in "list the variants" static stands aside, as on the old path. The one other row (r27) is no longer variant_arity on either side: it's a `Cell.new` argument, type.mismatch vs type.binding.
2. **type.defer_inert** 8 → 0: all 8 were the old path saying "only names `<error>`" over a name already refused. Per the ruling, the layer stays silent. The old path now stays silent too, so no voice names `<error>`.
3. **type.catch r588 and the no-prelude family** (ruled: the layer learns them):
   - **What changed:** whether a file stands in a package (`rooted`: its package lists an avra.toml) is now one fact, `sees_prelude` (item_scope.av). The laws below key on it.
   - **Tried and backed out:** withholding the prelude's lent names from a lone file altogether. That made `println` refuse, as on the old path, but the layer could no longer lower lone-file programs whose generated code reads lent names (a grammar's parse door: "a seat refuses a value here, in a body no law reads yet"; ~40 formats/fns suite cases). So a lone file still gets the prelude's lent names on the layer. **`println(…)` in a lone file builds on the layer and is "not defined" on the old path.** That is left open for a ruling: give the generated code its own prelude reach, or accept lone files seeing the prelude.
   - **The prelude's own types a lone file can't name are refused** where a typed verb call or a caught `await` would hand them out, in the old voices (one named fn each). The empty map's and arity's laws still speak first:
     - `Entry`: type.map_entry, `entry_unseen`, for `entries`/`filter`/`any`/`map`… on a map;
     - `ToInt`: type.to_int, `to_int_unseen`, for `floor`/`ceil`/`round`/`trunc`;
     - `Cancelled`: type.catch, `CatchFault.CancelledUnseen`, through a `prelude_seen` fact on the program interface.
4. **`[].bytes()`**: the empty-list verb law (b9e90b6e) refused it, and the old path accepts it. It was 5 false refusals in std-avrac's own sources, found by the new `check packages/std-avrac` receipt. `bytes` reads `[]` whole and is left be.

## Lone files: what still routes to the old path (switch list)
- build/run/check/test, lone file included, take the program layer (the door law in cli/src/commands/shared.av). But **the net** (`AVRA_PROGRAM_NET`, on by default) runs the old path's check before every one of them: `net_refused` in shared.av.
- `avra fix`: `program_at` → `root_program` / `file_workspace` (shared.av:303). Old path, no door.
- `avra refuses` (the `.refuses` tests): `one_refuses` → `file_workspace` → `ws.linked_program` (refuses.av:102). Old path, no door.
- `phased`/`on_program` (phase.av) is the old path, reached only from `run` with `AVRA_PROGRAM=0`.
- `emit`/`ir` (`on_lowered` → `program_aimed` → `lone_disk_at`) and `fmt` (`lone_disk_at`) already use the layer.
- **Harness gap:** a lone-file law can't be pinned yet. `tapes --law-witnesses` writes every law's witness as a package (tapes.av `witness_written`, WITNESS_MANIFEST), and tools/program-refusals cases are packages too. So the three no-prelude laws' witnesses don't fire as written. Their behaviour is shown on lone files only (both paths agree: entries, filter, any, map, floor, `await` catch).

## Found, not done
- **A component's state default isn't typed by the layer.** `component Card(a: int) { b: int = zz }` and `{ b: int = "s" }` both build on the layer. The old path refuses them (resolve.unresolved, type.struct_fields). That's a false accept. (The old path also says "`a` is not defined" for a seat read in a default, which may itself be a defect.)
- r114 / r520: pinned as follow-ons, per the agreement.

## Receipts (HEAD 025a98f7)
- Layer `check packages/std-avrac` (NET=0): exit 0. At d9add281 it had 5 `[].bytes()` false refusals (item 4), now fixed.
- std-avrac suite, `tools/gate.sh` slices at 025a98f7:
  - avrac-a, avrac-b, avrac-d, avrac-e, avrac-f, avrac-g: PASS;
  - avrac-c: FAIL on 1 unpinned case. "features/fns / a `const` seat / a settled seat accepts a callee that settles nothing": `let good: fn(const int) -> int = plain` is refused (type.binding) on the layer. **It fails identically at batch40 (d750dfa7) and at 1cdefa1d, with compilers built at each, so it's not from this branch.** It's unpinned in tools/gate/std-avrac.names.
- On the way, the gate caught a regression of mine, now fixed. Withholding the prelude from lone files broke ~40 formats/fns cases and 2 scope tests; that change was backed out (item 3).
- NET=0 cli build: exit 0.
- Witness: 791 of 802 hold, 11 known to differ, 0 failing, 4 untooled.
- Idioms (AVRA_MEM_POOL_MB=12000): 0 NEW of mine. 1 NEW in item_entry.av, identical to batch40's.

# Handback 4: batch41 merged (83655c24), bundle `batch41..HEAD`
- Merge: one definition per law. batch41's `join_reads_text`, `fold_seed_typed` and `fold_takes_seed_and_fn` own join and fold; my list-verb law dropped those parts and keeps `[]`, by-value scans and `enumerate`. Laws are the union (375), no duplicates. The 3 `{}` maps pins are removed from tools/gate/std-avrac.names.
- Since 025a98f7: component field defaults read as bodies (may overlap wrong-answers' 7424b58f, which isn't in my tree); the naming law reads field defaults; `x.type(T)` with T a type parameter (type.type_value).
- Receipts at 83655c24:
  - layer check packages/std-avrac exit 0;
  - gate slices avrac-a..g all PASS;
  - NET=0 cli build exit 0;
  - witness 840 of 852 hold, 12 known to differ, 0 failing, 4 untooled;
  - idioms 3 NEW, all batch41's, reported not fixed: item_members has the same `ChainCalled {…}` literal twice (chain_called / chain_uncalled, both in batch41), and item_view.av is identical to batch41.
- Reported, not fixed: `[].fold([], f)` (routed to parity-types).

# Handback 5: bundle `batch42..HEAD` (batch42 = 0caccf5d), HEAD f8051b19
- c5fa9f1f, resolve.import_clash: a `use` item binds its alias, so two lines clash only over the names they bind. `Type as MetaType` beside core's `Type` is no clash, as on the old path. This was 11 false refusals in std-avrac's own sources.
- 559c941b: two `export use` lines of one name are reexport_twice's alone (no import_clash beside it). One `module_at` builds the ModuleAt a path names. The unused empty-walk voice is gone, and `walk_unknowable` speaks for both paths.
- 88b920e8: `table<int>` is refused again (type.struct_fields, beside what the table means), as on the old path. 036c97ee had regressed it. Witness: w_table_owned_row.
- f8051b19: fmt for a test I reworded.

## Receipts (gates at 88b920e8; f8051b19 is fmt only)
- Layer `check packages/std-avrac` (NET=0): exit 0.
- Gate slices: avrac-c, d, e, f, g PASS.
- avrac-a FAIL: 3 item_tapes cases. avrac-b FAIL: 1 collect Self case. These are NOT mine: they come from batch42 and are reported, not fixed:
  - "an instance of a template, imported from another module";
  - "a word imported under an alias, and an item spelling only the alias";
  - "an item naming a word only inside another name";
  - "`collect enum E: T` / a method taking `Self` and answering another type than `bool` is refused at the trait".
- NET=0 cli build: exit 0.
- Witness: 864 of 878 hold, 13 known to differ, 1 failing (w_collect_enum_self, NOT mine: "a span reaches outside its own text — offset 307 of 306", exit 2), 4 untooled.
- Idioms: 0 NEW.
- fmt --check on touched .av: 0 differing.

# Handback 6: on batch45c, bundle `batch45c..HEAD` (batch45c = 9a2c69ff), HEAD 4dd06a53
Holds my whole family: everything through f8051b19, merged onto batch45 (bfd78472) and then batch45c (4040ed3c, clean).
- **Merge (one definition per law):**
  - Keyword dot-call: batch45's `keyword_call` law, `Miss.Keyword` and `keyword_called` voice stand. My `keyword_called` law, `KeywordCalled` miss and `keyword_formed` voice go.
  - checking.av: my `unrefused`/`elements_judged` beside batch45's comprehension/list-verb/trait-default seating; `prelude_seen` beside `default_seats`.
  - Seat lists: `StaticUnpinned` beside batch45's new seats.
  - `literal_param_miss` hands on the scope's generic fns.
- **Walk on `[]`: one law, `walk_knows_elements`.** It reads checking's unknowable walks, plus a written-`[]` walk at a place checking said nothing of. My list-verb law keeps scans and `enumerate`.
  - `[].fold` is fold's own law's (Walkless) alone.
  - Before this, `avra build` said `[].find_map`/`[].fold` twice (pw_find_map_unknowable, fold_get_adversarial).
- **Prelude-type laws** (entries/rounding) count only names the language or the prelude declares.
  - A program's own `type Entry` held in a map was refused as the prelude's. That reddened 5 evaluator-frees cases now asked of held packages.
- **Pins:** the 7 collect cases batch45 pins under its held-package harness are pinned again. The merge had kept my cfe52498 removal.

## Receipts at 4dd06a53
- Layer `check packages/std-avrac` (NET=0): exit 0.
- Gate slices avrac-a..g: all PASS.
- NET=0 cli build: exit 0.
- Witness: 907 of 932 hold, 25 known to differ, 0 failing, 4 untooled.
- Idioms: 0 NEW.
- fmt --check on touched .av: 0 differing.

## Found, not done
- `let xs = []` then `xs.map(it)`: the old path says type.list_element and the layer is silent. This predates the merge.

# Handback 7 (batch 52's first merge): bundle `batch51..HEAD` (batch51 = af47021e), HEAD 06eb3653
Holds my whole family (everything through 4dd06a53), merged onto batch51.
- item_uses.av:
  - One `UseFaultAt` carries both batch51's `unread` and my `Clash`.
  - `line_faults` reads the written line, alias and export included.
  - batch51's `line_refused` hands it one.
- item_typed.av: `prelude_seen` beside batch51's `kept`.
- No duplicate laws between batch51 and my side.
- Receipts at 06eb3653 (as asked: check, slices, idioms, fmt; no witness rerun):
  - layer `check packages/std-avrac` (NET=0): exit 0;
  - gate slices avrac-a..g: all PASS;
  - idioms: 0 NEW;
  - fmt --check: 0 differing.

# Handback 8 (batch 52, final): bundle `batch52..HEAD` (batch52 = 572c1d99), HEAD 7e717b29
- item_refused.av: the seat lists hold batch52's `.AnnotationSeat(_)` beside my `.StaticUnpinned(_, _)` (17 lists each). My Method arm keeps its `EMPTY_LIST` case.
- Receipts with the compiler built at 7e717b29:
  - layer `check packages/std-avrac` (NET=0): exit 0;
  - idioms: exit 0, 0 NEW;
  - fmt --check over every .av the bundle touches: 32 examined, 0 differing.
  - The formatting is this compiler's own `fmt`. A Mac fmt that disagrees would be a different fmt build, not unformatted files.
