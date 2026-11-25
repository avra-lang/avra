# Harvest — NODES / DERIVE (2026-10-30)

Base measured: `origin/main` 5f65f027 (hd-clean 3bdb4dbb contains it; `packages/std-avrac/src/features` is identical on both).
Method: read-only. Per ref, `git diff -U0 origin/main...<ref>`: share of its added lines (≥25 chars) present anywhere on main, share of its deleted lines gone from main, and the definitions (`fn/type/enum/trait/const`) it adds that no identifier on main carries. "Landed" means the key symbols are on main, since main squashes. 192 nodes-family refs scanned; raw data in the session scratchpad (`harvest.jsonl`).

## 0. Headline

- **Hand builders on main: 49 production `build_*`.** 48 are in `features/**/builders.av`, plus `build_type_link` in `expr_spine/type_lit.av`. Test fixtures don't count, and neither does `grammar_lit`'s `build_expr` helper. Goal: ≤1 (`build_sublang`, the registry lookup).
- **The step-6 door exists on main.** `Meaning.means(cx: MeanCx) -> Rewrite?` and `minted(cx) -> Minting` (features/contract.av:522). Users: Bitnot (`means`, a template); Pipe, ChainCall/Apply/Type, Table, If (payload), LetPattern, Component, ArmsBody and InstanceFn (`minted`). So "sugar is means()" is half built. What remains is moving the remaining desugar builders onto it.
- **The step-5 mechanisms are on main:** `@facet`, `@anchor`, `Field.default`, `Slot.Nested`, NParam/NVariant carriers, `Record.TypeRef`, `@operators`, `@fold`, generic record derives (`payload_of`), and the printer reading rule wordings.
- **Only 5 nodes refs hold real unlanded value:** `nodes-for`, `nodes-typelit`, `land-catch4`/`nodes-catch` (CatchArm), `nodes-arms` (ArmsMatch, stale) and `capture-inline` (crashes). Everything else is landed (squashed) or superseded.

## 1. Harvest table

| ref / PR | what | proved / measured | why failed / stalled | PORT (sha) | close? | goal step 6 use |
|---|---|---|---|---|---|---|
| `nodes-for` (wt `avra-nodes-d`, clean) · no PR | `for i in lo..hi` becomes a ForEach over the range, read once. Deletes `Stmt.For`, its cond/step nodes, `check_for`, `lower_for` and **`build_for`**. 13 files, +76/−180. | Builds (HOLD_HANDOFF 10-27). Loops IR golden and suites **not run**. | Parked when the nodes-finish lane idled. Rung 1 (Range bridge #1340) landed in batch BB #1349. This is rung 2. | **bf1ddfea**. Base 9f75dfe8 = BB, 15 behind; none of its files have moved on main since. | after port | yes: kills `build_for` (89.23) |
| `exp-for-once` · PR #1338 (draft) | measurement-only version of the above | CI 20 ok / 3 FAILURE (the suites whose output changes, as intended) | never meant to land | none (nodes-for supersedes) | **close #1338** | — |
| `nodes-typelit` · no PR (`nodes-door2` = same commit) | `v.type(T)` stays a TypeLiteral node meaning the minted call. Deletes the `type_lits` side table, its fingerprint restamp and the printer's reverse-spelling (`type_lit_tail` + 4 fns). +67/−79. | builds; suites unreported | parked with nodes-finish | **6d3068d2**. 19 behind; `format/source_text.av` and `core/store.av` have moved since, so expect small conflicts. `build_type_link` stays; the commit removes its side table, not the fn. | after port | half of 89.20; `build_type_link` → `minted` after |
| `capture-inline` (wt `avra-07f`, clean) · no PR | walk verbs inline lambdas that capture (`lower/state.av`, `lists/chain.av`, `pipeline.av`). +30/−16. | **gen2 crashes on features/tasks** (its own subject line) | gen2 crash never diagnosed. The capture-free half landed (#1290, batch AP). | 274f122d **only after the crash is found**. It is a perf change, not nodes. | keep as source; no nodes value | no |
| `land-catch4` · PR #964 OPEN (conflict) | `catch` arms become `CatchArm` records built by their own rules; **`build_catch` dies**; `@fold` group may be optional (std-grammar `fold_once`); a regression pin over every written form. 6 commits, 23 files. | CI green at c78b9292 before main moved. Watcher: one conflict in `expr_spine/mod.av`; `seed-check` never run (engine change). | 68 behind; the spine was reshaped under it. Waited on generic record derives (89.15), which have since landed, so CatchArm now costs zero core rows. | 8c31509c (fold optional), 47053936, fc777346, 85c8476a, c78b9292. `2df2dc58` is fmt. | after port | kills `build_catch` |
| `nodes-catch`, `land-catch`/2/3, `nodes-catch2`, `catch-main`, `catch-rebase` | earlier spins of the same | — | superseded by land-catch4 | none | close all | — |
| `nodes-arms` (wt `avra-nodes-arms` is now on `db04d-link-env`, dirty with **DB** link-env work, not nodes) · #978 closed | trailing arms `{ p -> … }` become an `ArmsMatch` sugar with a minted meaning. Retires `mark_sugar_match`. +1703/−269, 41 files. | built 10-18 (89.18 note) | 141 behind; main reworked expand/store/builder/contract since (40 files touched). The components half went another way: ArmsBody node, #1322. | Redo, don't rebase. Read `arms_match_nodes`/`arms_means` from c. bd6b4df4^ / origin/nodes-arms. | close after redo | kills `build_trailing_arms` (89.18) |
| `nodes-batch5`, `nodesg`, `nodesg2`, `nodes-g3`, `nodes-homes-e` | batch carriers of nodes-arms + a TypeWord/TypeApplied typelit and rewrite holes. g3/homes-e carry 220 commits of DB derive/held work. | — | #978/#1004 closed; the parts landed elsewhere or live in nodes-arms/typelit | none beyond nodes-arms | close | — |
| `nodes-generic-records` / `land-generic-records` / `land-generic-shape*` | derives read payload records off their declarations (`payload_of`); 29 rows → 0 for Children/Exact/Rebuild; Shape slice | doc §6: suites identical to baseline; gen2==gen3 fixed point | **LANDED**: #933 batch-nodes-4 + the batches before it. `comp_clauses`/`exact_variant` are gone on main. | — | close branches. Epic **89.15**: close, or narrow to the stated hand residue (Param, Arm, FormatPart, Mark, BodyView, TypeRef). | enables CatchArm |
| `block-word-template` · PR #1215 OPEN draft | a template's names are judged in the file that wrote it | 100% of its lines on main | **LANDED** via #1247 template-hygiene-2 | — | **close #1215** (superseded by #1247) | — |
| `subset-gate` · PR #989 OPEN | "the subset today" made executable (`compiler/tests/subset/*`) | — | **LANDED**: `refusals_test.av` and `runtime_test.av` are on main | — | **close #989** | — |
| `builder-slots` (wt `avra-builders`, clean except `tools/.suites_tmp.sh`) · #981 closed | grammar constructor productions: nested builds, lists, facets and stated terms in a payload | 97% on main | **LANDED** in batchE #1031 (`Term.Node`, `fixed_expr` term on main) | — | close branch; **close ticket 89.25** | — |
| `marks1` | ExprMarks record | `ExprMarks` on main (7 refs) | **LANDED**. Its `pipe_means`/`table_means` were superseded by `minted`. | — | close; **close 89.26** | — |
| `tables`, `tables-pr`, `nodes-tables-keyed-marks` | `table<Row>{…}` as a minted sugar | `Table` `impl Meaning … minted` on main; `mark_table` gone | **LANDED** (#1031) | — | close; **close 89.21** | — |
| `nodes-means2/3/3-wip/4/4a`, `land-means-1`, `nodes-facts`, `nodes-iflet`, `nodes-is`, `nodes-chain` | `means()` door, NodeFacts, Bitnot/Pipe templates, `?.` chains as sugars, `Is` keeps its pattern | NodeFacts, ChainCall/ChainApply and Bitnot `means` are on main | **LANDED** in another shape: `minted` replaced the `*_means` template fns, and #1321/#1343 replaced the `Is`/IfLet path (if-payload means the match). | — | close all; **close 89.19**; 89.17 is mostly covered by #1343, so re-check `build_if_stmt` | — |
| `nodes-j`, `nodes-j-tidy`, `nodes-j-body`, `nodes-j-carriers`, `pr1244`, `nodes-j-door` | components: Expr.Component, InstanceFn, ArmsBody, Setting rule; the sugar door's refusal voice (`MeaningVoice`) | all on main except j-door's `MeaningVoice`/`refuse_meaning` | **LANDED** (batch AX #1322 and others). j-door's voice was superseded: main's contract says "an Err its own refusal, spoken where it stands". | — | close | — |
| `nodes-anchor`, `nodes-typeref`, `nodes-5-*`, `nodes-step5*`, `nodes-enum-decl`, `nfield-*`/`land-nfield-*`, `nodes-use`, `nodes-d`, `nodes-d2`, `nodes-map`, `nodes-struct`, `nodes-if`, `nodes-range-bridge`, `nodes-records-*`, `nodes-makers`, `nodes-derives`, `nodes-carriers`, `nodes-facet`, `nodes-field-default(-seed)`, `land-default-2`/`nodes-default2`, `land-extern`, `nodes-type`/`nodes-facets` | step-5 slices: rules name their node, carriers, @facet/@anchor/Field.default, refusals moved to checks | ≥85% on main, no missing definitions | **LANDED** (batches P/Q/U/AD/AE/AT/BA/BB…) | — | close all | — |
| `nodes-operators`, `nodes-fold-b(2)`, `nodes-fold-turns`, `nodes-fold-design`, `nodes-suffix-build(2)`, `nodes-layout`/`syntax`/`5b/5c/5d` | `@operators`, `@fold` postfix, printer wordings | missing names are old `build_*` fns main has already deleted | **LANDED** (#828, #834, #1092 family) | — | close | — |
| `land-fold-opt` | std-grammar: a `@fold` group may be optional (`fold_once`) | not on main | rides land-catch4 (8c31509c) | via land-catch4 | close after catch port | yes (catch) |
| `dedupe-bind` | one `bound_pat` for a bare-name pattern seat | not on main | superseded by `nodes-d2` "one bind_pat" (#1278, batch AI) | — | close | — |
| `record-run` | `record_of` as one `${t}{..${inits}}` template; deletes RECORD_WIDTH and the 12-arm match | `RECORD_WIDTH` is gone on main | **LANDED** (`collect-fold` carried it). Its `std-json/tests/wide_record` witness was **not** carried. | port the wide_record test only | close | derive any width |
| `collect-fold`, `collect-*`, `nodes-derive-closure`, `nodes-self*`, `nodes-shape-2`, `local-marks`/`marks-652`/`marks-pr` | collect fold per root, derive closure, @local, Identity on leaf records | ≥85% | **LANDED** | — | close | — |
| `nodes-self-exact`, `nodes-shape`, `nodes-1b-c(-wip)`, `nodes-expr`, `nodes-stmt`, `nodes-stmt-s`, `nodes-2d/2e/2f*`, `nodes-1b*`, `nodes-delegate`, `nodes-trait`, `nodes-spawn`, `nodes-pat`, `nodes-slot` | steps 1–3 WIP (Exact trait, per-member Identity, Expr/Stmt gathered) | the low % is because main moved on (If/Is/IfStmt names gone or renamed) | WIP superseded by landed steps 1–3 (#435, #439, #534, #813, #822). 1b-c's `derived_members` was never landed; step 3's per-record kids is still blocked (89.3). | none (`derived_members` idea → 89.3) | close | — |
| `spread-*`, `lane/spread`, `nodes-spread` | spread `..` everywhere | `spread-calls` merged #971, `spread-1` #901; nodes-spread is the design doc (now docs/2026_10_17_SPREAD.md) | **LANDED** | — | close; **89.24**: close or narrow to patterns | — |
| `lower-attempt0`, `fold-out` | DB: remember run reads; BLAKE3 the text in keys | `runs_key`/`listed_here` not on main | DB, not nodes → DB harvest | — | DB harvest | no |
| `nodes-held-*`, `nodes-homes`, `nodes-reporting`, `nodesg-fix`, `nodes-place` | DB held/kept-view work under a nodes name | 33–57% | hold-era; A16 deletes the hold | lesson only | close (DB harvest) | no |
| worktree `avra-nodes-default2` (now on `db09`, dirty) | staged `kept_marks_test.av` + seat_row attack | — | DB work, not nodes | → DB harvest | ask before removing | no |
| worktree `avra-nodes-self` (on `reentrant-once`, dirty `soundness.av`, `core/ir.av`) | not nodes | — | — | → DB/perf harvest | ask | no |

Worktrees found clean with nothing to harvest: `avra-nodes-d` (nodes-for), `avra-07f` (capture-inline), `avra-carriers` (nodes-j-body, landed), `avra-nodes-map` / `avra-nodes-finish` (0450e639, landed), `avra-nodes-r` (nodes-if, landed), `avra-cfold` (landed). They can be removed once their branches are closed (needs the owner's say-so).

## 2. Builder inventory on origin/main (49)

Classes are NODES.md's: **def** default · **side** side table/@facet · **nest** nested group record · **choice** grammar branches `-> Variant` · **desugar** → `means()`/`minted` · **fold** · **refusal** → check.av · **anchor** span anchor/interleave.

| # | builder | file | class (primary first) | addressed by |
|---|---|---|---|---|
| 1 | build_annotated | annotations/builders.av | side (annotate_before), desugar (`applied` quote) | none; Annotation as a facet + the template `means` |
| 2 | build_mark | annotations | nest (Mark record), desugar (`applied`) | none |
| 3 | build_asset | asset | desugar (const + `provided<K>` call + `bundled`), refusal | none; a clean `minted` candidate |
| 4 | build_block | block | def / block law (`block_of`) | 89.14 / 89.16 (Block.value derived) |
| 5 | build_fn_type | closures | nest (seats → TypeRef args/marks) | 89.5.5 (TypeRef defaults) |
| 6 | build_trailing_arms | closures | desugar (`it -> match`), side (mark_sugar_match) | **nodes-arms** (redo), 89.18 |
| 7 | build_collect_decl | collects | refusal (it/by/dense), anchor (aligned_binds windows), side (dense), choice (kind/scope) | 89.5.6, 89.5.2 |
| 8 | build_collect_enum_decl | collects | same as 7 | same |
| 9 | build_component_decl | components | refusal, side (spread_fields), nest (sorted members), desugar (`with_body` quote) | none |
| 10 | build_component_event | components | desugar (event → nullable fn Param, null default) | none; Param defaults |
| 11 | build_component_keyed | components | refusal (by/it/binder), desugar (key Prop) | 89.22 closed, but the refusals remain → 89.5.6 |
| 12 | build_component_braced_head | components | refusal (pure) | 89.5.6 (`@expect` or a check) |
| 13 | build_component_named | components | choice (record vs template word, by import) + desugar (`let n =`) | none |
| 14 | build_component_named_bare | components | same as 13 | none |
| 15 | build_on_handler | components | desugar (lambda), side (mark_on_handler) | nodes-j-carriers landed the Setting rule; the handler itself remains |
| 16 | build_hole_arm | enums | desugar (a hole as an arm) | none |
| 17 | build_int_lit | expr_spine | choice (fraction vs int from one token) | none; lexer token kinds |
| 18 | build_unmixed_bitwise | expr_spine | refusal (the climb's agreement callback) | 89.5.7 (`@operators` Unmixed) |
| 19 | build_bind_pat | expr_spine | choice (`rest` → Rest, `null` → Lit) | nodes-d2 landed one bind_pat; the choice remains |
| 20 | build_neg | expr_spine | fold (literal constant-fold) + desugar (`0 - v`) | FOLD_AND_MEANS: "-literal stays hand", so the **2nd escape-hatch candidate** unless folding moves to consts |
| 21 | build_method_link | expr_spine | desugar (pronoun args) | FOLD_AND_MEANS `@pronoun` (not built) |
| 22 | build_trailed_link | expr_spine | refusal ×2, desugar (blocks as args) | 89.5.6 + `@pronoun` |
| 23 | build_trailing | expr_spine | desugar (pronoun seat when the body reads `it`) | `@pronoun` |
| 24 | build_catch | expr_spine | choice ×6 forms, anchor (aligned_binds), refusal | **land-catch4 #964** (CatchArm) |
| 25 | build_expr_stmt | expr_stmt | choice (ExprStmt vs Assign) | none; two branches `-> Variant` |
| 26 | build_format_pat | formats | refusal (text faults), choice (Lit vs Format) | 89.5.6 |
| 27 | build_grammar_decl | formats | desugar (`declared_format` → StructDecl + mark_grammar), refusal | none; `minted` stmt door missing |
| 28 | build_grammar_lit | grammar_lit | desugar (comptime DSL parse → struct literal) | none; **escape-hatch candidate** (it runs a parser) |
| 29 | build_if_stmt | if_expr | side (mark_statement_if), desugar (else-if chain value) | 89.16 / 89.14 |
| 30 | build_impl | impls | refusal (fn-only), side (impl_tparams, trait_args), choice (for / no for) | 89.5.4 / 89.5.6 |
| 31 | build_trait_member | impls | side (static/mutating), anchor (name..body span), def (hollow body) | `@facet` + `@anchor` (both landed) — mechanical |
| 32 | build_let_else | let_stmt | desugar (`trailed`) | `@pronoun`/trailed rule |
| 33 | build_let_pattern | let_stmt | fold (folded_lets: later statements fold into the node) | LetPattern `minted` landed; the builder half remains |
| 34 | build_list_pat | lists | refusal (one `..`), anchor (split by `..` position) | 89.5.3 nested group (before/rest/after) |
| 35 | build_for | loops | desugar (cond/step nodes) | **nodes-for bf1ddfea** |
| 36 | build_export | modules | side (@facet exported), refusal (twice) | 89.5.4: an `@facet exported` field |
| 37 | build_quote | quote | refusal, anchor (runs between holes), side (mark_quote_at) | none; core to templates |
| 38 | build_quote_pat | quote | choice (wraps build_quote) | none |
| 39 | build_run_hole | quote | side (mark_run_hole) | `@facet` |
| 40 | build_given | specs | nest (stamps group on child cases) | 89.5.3 |
| 41 | build_str_lit | str_lit | side (mark_raw_string) | `@facet` (mechanical) |
| 42 | build_type_decl | structs | choice (NamedType vs StructDecl), refusal ×5 (spread voices), side (spread_fields) | 89.5.6 + choice branches |
| 43 | build_struct_lit | structs | anchor (written order), def (pun), side (struct_targs) | 89.5.3 |
| 44 | build_fields_pat | structs | refusal ×2, anchor (pattern by position), def (punned binder) | 89.5.3 |
| 45 | build_sublang | sublang | registry lookup + expansion | **THE escape hatch** (NODES.md) |
| 46 | build_type_ref | type_expr | pure (reads labels by name) | nodes-typeref landed it as one fn; make it the `Record.TypeRef` row (89.5.5) |
| 47 | build_union_type | type_expr | choice/def (alternatives) | 89.5.5 |
| 48 | build_type_link | expr_spine/type_lit.av | desugar (`v.type(T)`), side (type_lits) | **nodes-typelit 6d3068d2**, then `minted` |
| — | build_expr | grammar_lit | helper, not a builder | — |

Tally (primary class): desugar 15 · refusal 9 · side 7 · choice 7 · nest/anchor 7 · def 2 · fold 1 · escape 1. Branches in hand kill 3 (for, catch, type_link half).

## 3. recover/* and archive/* sweep (779 refs)

779 refs. **246 are flagged**: the subject, or a file the ref's own commits touch, names store, record, hold/held, codec, kernel, relation, families, query, derive.av, workspace.av, builders, Expr/Stmt or grammar. Every recover ref has ≥1 commit off main by construction (a stash or WIP snapshot), so "not on main" is always true. The judgement below is about value. Raw list: `ra_out.txt` in the session scratchpad.

**September (160 flagged): superseded.** Stashes of lane/b, comptime/*, cache/cas, fix/held-settle, fix/consumed-record and fix/imported-package-lowering, all from before DB 01–09 and the GitHub move. The hold-era ones (cache-cas "whole-hold laws", held-settle) are on the A16 delete list. **Lesson only; no port.**

**October, nodes-relevant:**
- `recover/kids-derived` (10-08) — the Children derive also writes an Expr's own kids. Superseded: step 3 landed its walk law (#822). The per-record kids idea is still open as 89.3, so read it there.
- `recover/wt/avra-builders-wip` (10-22, 6 commits) — uncommitted builder-slots state: `node_grammar_fold_test.av`, `node_grammar.av` and std-grammar `ast.av`/`builders.av`. builder-slots itself landed (#1031). **Check the fold test** (`node_grammar_fold_test`) against main before closing; it may be an unlanded `@fold` witness.
- `recover/lane/grammar-expected-wip` (10-22) — an uncommitted `fb_diags` fix across std-grammar executor/first/operators/diagnostics. **Unverified on main → check** (grammar diagnostics, nodes-adjacent).
- `recover/hole-lands`, `-2` (10-08) — spliced TypeRefs resolve where they land (partial). Superseded by template-hygiene-2 (#1247).
- `archive/ui/lane-ui-h-wip` (10-17) — touches `verify_held.av`, `nodes.av`, `store.av`, `builders.av`. UI lane WIP; hold-era. Superseded.
- `archive/ui/origin-closeout-avra-ui-findis` / `-bisect` (10-01/02) — `find_map` + payload-binding `is` under `if`. Landed (`find_map` and `if … is` are on main).

**October, DB-relevant** (hand to the DB harvest; one line each):
- `recover/db-s4bc-wip` (10-16) — FileSaid observation rows (said_row/rules_row/findings_row); traps at index 129. Superseded by the said family and saved rows. **Learn** the trap.
- `recover/wt/avra-07a-gather-wip` (10-22, 8 commits) — facts_codec, query and derive gather. In the `@codec` cluster (db-07b-typed). **PORT candidate** for the step-2 typed rows.
- `recover/wt/avra-codec-base-wip` (10-22) — facts_codec, relation, stable. Same `@codec` cluster. **PORT candidate.**
- `recover/wt/avra-codecs-fix(-wip)` (10-09/22, 187 files) — family ordinals keyed by name, codecs. Mostly landed (01e); the WIP is noise. Superseded.
- `recover/wt/avra-arm-rows-wip`, `-arm-nobump`, `-arm-noloop`, `-arm47-dbg`, `-bisA…E` (10-22) — kernel/db/rows/accessors bisect states. Superseded (debug snapshots); `@family` → `@query` (DB 12) deletes them.
- `recover/wt/avra-db-07a-wip` (80 commits), `-db06(-wip)`, `-db06-step3`, `-db06-stats` (538 files), `-db-125`, `-db-a3(-wip)`, `-db-said`, `-db08-verdict`, `-db01e`, `-db-09`, `-cs2`, `-cn2`, `-attr(-wip)`, `-collect-wip` (kept_settle.av) — DB 06–09 lane snapshots, mostly landed as batches. `-db-said` (108 files) and `-db-125` (55) are **unverified, so check them for unlanded saved-row code**. `-collect-wip` touches `kept_settle.av`, which the goal deletes, so learn only.
- `recover/wt/avra-perf-load` (10-22) — "a warm check asks only the holds a moved input reaches". Hold-era. **Lesson** for step 1 (warm path).
- `recover/prekey`, `recover/record-reads`, `recover/query-two-annotations`, `recover/stash-docfact-side-*`, `recover/stash-fix-embed-literal-admit-*` (10-01/08) — early DB probes ("correct, measured no load gain" etc.). Superseded; learn only.
- `recover/wt/avra-8sb5-57-191-wip`, `recover/wt/avra-batchs`, `-batcher(-q)` — query over_export / producer_cross tests, plus batch carriers. Batches landed; **check `producer_cross` exists on main**.
- `recover/wt/main-checkout-wip` (10-22) — notes `db-07e-hold.md`, `host-fn-held.md`. Docs only; **read for hold lessons**.
- `recover/wt/graph-evidence`, `gw-wip`, `m02wt*`, `old-mcp` (200+ commits each) — the GRAPH product's `query.av`/`cypher.av`, not the compiler DB. Out of scope.
- `recover/lane/avra-1106-lane`, `wt/avra-1106*` — std-db codec/derive (time-stored), not the compiler DB. Landed via the batches.

## 4. Recommended nodes lane order (on hd-clean)

1. **Port `nodes-for` bf1ddfea.** Clean base (BB), no moved files. Run the loops IR golden and suites. −1 builder (`build_for`) and −`Stmt.For`. Close #1338.
2. **Port `nodes-typelit` 6d3068d2.** Resolve source_text/store; then make `build_type_link` a `minted` TypeLiteral rule. −1 builder.
3. **Re-cut catch from `land-catch4`.** Take 8c31509c (@fold optional) first with `seed-check`, then the CatchArm commits on today's spine. Generic derives landed, so CatchArm needs no core rows. −1 builder. Close #964 and the catch branches.
4. **Mechanical `@facet`/`@anchor` conversions** (mechanisms already on main): str_lit, run_hole, export, trait_member, then impl's marks. About −5.
5. **Choice → branches `-> Variant`:** expr_stmt, bind_pat, int_lit, union_type/type_ref (`Record.TypeRef`), quote_pat, format_pat. About −6.
6. **`@pronoun` (FOLD_AND_MEANS rec. 7, not built):** method_link, trailing, trailed_link, let_else. −4.
7. **Trailing arms redo (89.18)** from nodes-arms' `arms_match_nodes`, as `minted`. −1.
8. **Refusals → check.av (89.5.6)**, per feature: collects ×2, components (braced_head, keyed, decl), type_decl, list_pat, fields_pat.
9. **Nested groups (89.5.3):** struct_lit, fields_pat, list_pat, given, component_decl members.
10. **Statement-door `minted`** (the Stmt analogue of `store.mean`; HOLD_HANDOFF says the epic doc still owes the trigger note): asset, grammar_decl, if_stmt (with 89.16), let_pattern, annotated/mark, component_named, on_handler, component_event, hole_arm.
11. **Escape-hatch decision for the owner:** sublang (agreed), plus grammar_lit and neg (FOLD_AND_MEANS says "-literal stays hand"). The goal says ≤1, so either fold `-lit` in consts or license it.

**Close now (landed or superseded):** PRs #989, #1215, #1338 (after the nodes-for port); tickets 89.19, 89.21, 89.25, 89.26 and 89.15 (or narrow it); every branch marked "close" in §1. `capture-inline` is perf-only with a gen2 crash: hand it to the perf harvest.
