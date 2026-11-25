# Harvest — the hold-deletion cluster (2026-10-30)

Read-only survey. Base: `hd-clean` @ `3bdb4dbb` (on `origin/main` 5f65f027 via 76504d55).
Source of truth for the deletion: `origin/hd-sigfix` @ `475aa67e` (contains the cut #1371 @ cb3ea83d
and every `hold-delete*`/`hd-*` branch except the 1-commit siblings listed in §4).
`git cherry hd-clean origin/hd-sigfix`: **0 patch-equivalent commits** — nothing of sigfix's 103
non-merge commits is on hd-clean by patch; equivalents below were checked by symbol/line.

| tree | `held\|hold` mentions in `compiler/` | `is_held`/`hold_only` words | `@family` lines |
|---|---|---|---|
| origin/main | 2395 | 68 | 52 |
| **hd-clean** | **2413** | **69** (+`held_by_rule`) | 52 |
| hd-nohold2 / hd-consts | 2067 / 2074 | 59 / 60 | 54 |
| hd-sigfix | 1735 | **0** | 55 |

Symbol locations below are `file:line` on **hd-clean** (verified with `git grep hd-clean`);
paths relative to `packages/std-avrac/src/`. "branch-born" = introduced and removed inside the
chain, not on hd-clean (nothing to delete there).

---

## 1. THE DELETION LIST (by the hold's job)

### 1a. The derivation's hold decision / turns — `fc5b24ef` (derive.av −974; 21 files, −2169)
Deleted (all present on hd-clean):
- derive.av: `Attempt` :52, `built_entry` :56, `Turn` :70, `reading` :77, `having_read` :80, `unheld` :86,
  `gave_way` :96, `adrift` :107, `Tried` :122, `turn_said` :130, `read_words` :140, `read_label` :148,
  `left_line` :158, `Stood` :170, `verdict_owed` :177, `or_refused` :182, `owing` :249, `derived_reading` :445,
  `derived_owing` :453, `stood_first` :474, `under_hold` :493, `refusal_noted` :517, `from_sources` :540,
  `unruled` :608, `again` :629, `tried_anew` :634, `holding` :687, `edit_print` :759, `moved_in` :767,
  `lead_reads` :775, `guessed_reads` :786, `homes_were_read` :795, `guess_kept` :800, `verdict_reads_first` :825,
  `const_reads` :832, `cheap_reads` :840, `known_as` :1021, `known_homes` :1024, `reads_ahead` :1028,
  `flat_moved` :1038, `unsealed` :1047, `layouts_judged` :1058, `sealed_by_held` :1071, `seals_in` :1076,
  `row_seals` :1082, `presealed` :1095, `seal_key` :1103, `sealed_record` :1105, `kept_boxed` :1115,
  `names_record` :1122, `bodies_asked` :1140, `home_moved` :1144, `resolve_pending_reads` :1156,
  `read_unkept` :1195, `force_read` :1214, `read_runs` :1226, `met_unread` :1243, `read_counted` :1246,
  `hold_refusal`/`hold_refusal_unkept` :1394/:1399, `refusal_cause` :1404, `nothing_held` :1408,
  `records_adrift` :1412, `sealed_layout_moved` :1432, `guessable` :1444.
- suite.av: `Hearing` :48, `heard_whole` :223 (+ `heard`/`read`/`left`/`workspace`/`attempt`/`paths` helpers).
- build.av: `link_owes` :1114 (the link's owed-homes restart). cache_walk.av, interface.av (−46), saved.av (branch).
- Tests deleted: `discarded_cost_test.av`, `guess_test.av`, `hold_refusal_test.av`, parts of `saved_test.av`.
- **Replaced with:** "one attempt per derivation; saved answers stand in" = the kernel revive/keeper hooks
  (`276792ca` Revival/`reads_stand`, `172175ec` ArgName/`saved_*`, `6ad2e874` `Saver`/`saves`/`flush_saved`).
  Commit body: *Items rows and their revive are NOT in the cut*. Later `9a80a6cb` deleted `stood_said` (branch-born).

### 1b. The module record's load chain — `fc5b24ef` (record.av −184)
- record.av: `load_interface` :752, `bare_interface` :760, `load_named` :769, `load_imports` :833,
  `load_gathered` :855, `meet_file` :1012, `read_why` :1077; interface.av `identity_*` (branch-born).
- **Side effect (root of the 3733 lead #1):** `note_producers` (producers.av:248) is called on hd-clean
  only from record.av:847 (end of the record-load walk). On cb3ea83d its only caller is
  `tests/cancel_reach_test.av:424` → held files' re-exports/gathers maps were EMPTY. Nothing replaced it until
  `8df2faaf` deleted the consumers too.

### 1c. verify-held and its tooling — `fc5b24ef`, `db085ade`, `2dbb4ef7`, `1eefec43`
- `compiler/verify_held.av` whole file (486 lines on hd-clean: `HeldMismatch` :21 … `mark_str` :484).
- cli: explain.av `compared_held` :368, `compared_lines` :380, `disagreement_line` :385, `mismatch_json` :488;
  shared.av `verify_held_said` :552, `reported_verify_held` :563, `verify_held_line` :571; test
  `commands/tests/explain_holds_test.av` (−150; probe helpers re-homed by `0eeb2807`).
- tools: `cache_attacks.sh` held/read claims + `--verify-held` (`db085ade`, −81); `tools/hold_sweep.sh`,
  `tools/turn_memory_attack.sh` deleted, `held_generated_attack.sh` → `generated_rows_attack.sh`, Makefile
  (`2dbb4ef7`); `tools/vocab.sh` verify_held row (`1eefec43`).
- **Replaced with:** `042bcd68` (hd-verify, NOT merged) `AVRA_VERIFY_REVIVE=1`: every revived answer recomputed
  and compared (std-relation answers.av +44). `#1303` re-states the attacks as cost claims (files parsed, consts settled).

### 1d. Held mint / producer doors — `98ee4f66` (10 files, −158)
- interface.av `mint_files` :332, `makers_in` :1006 (`makers_by_path` branch-born);
  workspace.av `held_named`/`held_worded`/`held_marked` :1289/:1291/:1293, `minted_modules` :1296,
  `minted_files` :1306, field `minted: Cell<Map<string,bool>>`;
  features/decls.av `no_holder` :883, `no_holders` :886;
  features/decls_mint.av `hold_named`/`hold_worded`/`hold_marked`/`hold_modules` :404–:410,
  `arm_named`/`arm_worded`/`arm_marked` :427–:431.
- **Replaced with:** name environments (`eab7f9f6` NameEnv, `5c305773` FileSaid/SiblingEnv) — "the env
  families are no fake savers"; mint_file answers its items (`41fbe203`).

### 1e. Held items / joins / row-fill flags — `0afa98f6` (= hd-nohold2 `15674131`, merged into sigfix)
- workspace.av `file_ensured` :1267, Hold fields `file_ready`, `row_filled` (used interface.av:315),
  `holds_settled` (already gone on hd-clean, `9d530aac`), `held_flat` (derive.av:1043, interface.av:200);
- features/decls.av `note_module_rows` :1398, field `held_items`;
  decls_mint.av `arm_file` :423, `held_items_of_file` :443, `held_joins` :450, `remember_held_item` :458.
- **Replaced with:** the Items revive — `4a4878a8`/`83dd8ef3` (`items_text`, `items_revived`, `attach_parse`),
  `bbc1598f`/`dbc48fd3` (attach parse before any body read; every body-range reader via `decl_with_body`).

### 1f. Signature fill from the record — `4fd23582` (hd-nohold, 12 files, −373) + `b2cddb9d` (hd-delete)
- families/families.av `HeldSig` :112; interface.av `fill_shape` :130, `fill_const` :146, `fill_aims` :163,
  `fill_named` :168, `fill_record` :176, `field_default` :207, `fill_enum` :212, `fill_opaque` :269,
  `fill_ensured` :314; workspace.av `held_sig_verified` :866, `target_ensured` :1261, `held_sig_dep` :2232,
  `held_module` :2244, `held_sig` :2251, `held_sig_asked` :2260, fields `file_module`, `sig_asked`;
  features/decls.av `held_value` :2117, `remember_held_value` :2119, `held_reach` :2121, `remember_held_reach` :2123,
  fields `held_values`, `held_reaches`; test `held_sig_test.av` (−79); one `tools/idioms.baseline` line.
- **Replaced with:** saved Sig rows — `cb9f0b16` (`sig_line`, `sig_revived`, `sig_standing`), `f7cf33c5`
  (only a free fn's sig is saved), `bab848bf` (`sig_stable`: hash by record shape, never interned ids);
  plus `bf13082b` sig reads its row after the parse stands.
- **WARNING for hd-clean:** `63d74a94` (sigs 2190 → 58 ms) made `Workspace.sig` call `fill_ensured`
  (workspace.av:2202–2209, held branch). Deleting 1f before a saved Sig/declaration row lands reverts that win.
  Session log: a sig row must restore the DECLARATION (`declare_one` also registers methods/namespace),
  not a `DeclSig`; two sig-row probes reverted (generic `Type.Var` scope; skipped registration).

### 1g. Const units — `1e229225` (hd-consts, NOT in sigfix; builds, no suites)
- interface.av `keep_const_units` :62, `const_rows_ready` :113, `const_unit_key` :122; derive.av call.
- features/decls.av `held_const_type` :2115 (`7a11ca86`).
- **Replaced with:** nothing — a const is typed and settled like any other (4fd23582 body).

### 1h. Unit rows (held lowering) — `aec6aa14` (unit_rows.av 222 → ~20 lines)
- unit_rows.av `UnitRow` :16, `unit_served` :22, `unit_kept` :37, `consts_read` :58, `consts_stand` :74,
  `keep_unit_rows` :93, `row_place` :110, `row_file` :128, `row_lives` :137, `unit_surface` :142,
  `surface_of` :153, `surface_fp` :163, `RowKey` :177, `RowPlace` :180.
- **Replaced with:** `Lowered` saved per declaration (`lowered_text`, `lowered_revived`, `unit_saved`,
  `symbol_spelled`), revive gated on `hold.serving` (workspace.av:316/421 on hd-clean) — which was
  **never set** until `a491f45f` set it for checks; `8da9bc6e` refuses a revived stub unit to a compile-time run.

### 1i. `is_held` / `hold_only` and every held branch — `8df2faaf` (25 files, −1006) + `7a11ca86`
- whole.av `is_held` :156, `hold_only` :168, `gathered_moved` :340, `gathered_away` :345, `gathering_read` :354
  (`producers_of` now producers.av:55); features/decls.av field `held: Cell<Map<string,bool>>` :589.
- build.av `homed_in_held` :818, `held_objects` :1088, `held_object` :1095.
- cancel_reach.av `held_link_scheduler` :164, `held_links` :171. kept_settle.av `held_path` :157, `held_names` :536.
- modules.av `reexports_in` :600, `held_reexport` :605. producers.av `note_producers` :248, `filed_under` :259.
- record.av `held_gather` :888, `held_modules` :2216, `held_paths` :2223, `held_stubs` :2243; `reached_modules`
  loses its store seat.
- references.av `restored_refs` :188, `read_target` :196, `refs_into` :199, `held_sources` :207,
  `refs_of_source` :212, `held_refs_to` :220, `held_target` :230, `kept_ref_rows` :237, `file_stands` :246,
  `resolved_ref` :252.
- workspace.av `HeldGather` :339, `held_methods` :2418, `held_trait` :2428; Hold fields `held_asks`, `asks_lost`,
  `named_by`, `worded_by`, `marked_by`, `externed_by`, `typed_by`, `refs_by_target`, `held_refs`, `kept_refs`,
  `linked_by`, `reexports`, `gathered`, `stood`.
- workspace_analysis.av `read_held_asks` :522, `ask_stands` :535, `ask_home` :540, `home_held` :543,
  `asked_want` :549, `held_wants` :557, `read_held_codes` :614.
- features/decls.av `no_externs` :888, `no_modules` :890, `no_held_refs` :920, `arm_held_refs` :2675;
  decls_mint.av `held_externs` :413, `held_files` :416, `file_held` :421, `arm_externs` :433,
  `held_opened` :809, `held_closed` :815, `unheld_files` :398 (`7a11ca86`).
- held branches in consumes.av, failures.av, lower/lower.av (6), memory/memory.av, receivers.av, program.av,
  features/contexts.av, leaves.av.
- Tests: `default_bit_test.av`, `record_held_runs_test.av` deleted; `cancel_reach_test.av` held cases
  (`held_from` :411 … `runs_after`). HOLD_HANDOFF says port these 3 tests, not drop them.
- **Replaced with: NOTHING.** Every file is read every run. This is the 506 s / 600 s (§3).

### 1j. Still on sigfix (never deleted by anyone) — the "still owed" list
`type Hold` (workspace.av:253) + `served`/`serving`; `held_okey` (workspace_analysis.av:625; 11 refs on sigfix);
`held_set`/`held_set_key`/`holds_asked`/`suspect_rows`/`file_judged`/`file_rows_stand` (filesaid.av:398/392/421/
348/215/197); `stands_in` (derive.av:543); `KeyParts` (record.av:1358, formats 1–2); `keep_interfaces` (record.av:701)
+ `insert_sig`; `mint_file` (interface.av:354); `stub_of` (interface.av:675); `kept_settle.av` (918 lines);
`Admitted` family (families.av:148); `keep_const_units` (only hd-consts). ROADMAP checklist `6c0c2a3c` (not on hd-clean)
lists the same set + the store relocation rewrite (`Anchor`, `filed`, `found`, `names_place`, `MARK`, `store_anchors`).

### 1k. Hold mechanisms ADDED on hd-clean after the chain (delete with the rest)
`held_by_rule` whole.av:172 (`94623955`, the one definition of held: rows stand ∧ not loaded this turn ∧ not
read ∧ not forced — 22 divergences witnessed before it matched), `fill_ensured` use in `sig()` (`63d74a94`),
held set by program (`7b71f6ce`/`df699f30`), `pack_readers`/`suspect_rows` index (`0857cbda`).

---

## 2. BUG FIXES worth porting regardless

| sha | one line | on hd-clean? |
|---|---|---|
| `475aa67e` (+`62f50f00`) | method table: one entry per DECLARATION (`any(same_decl)`), so `draw<Button>`/`draw<Link>` both stand and a re-run never double-registers | **No.** hd-clean decls.av:3551–3552 checks only the FIRST same-named entry (`held_method(target,name)` + `same_decl`) → a re-registered 2nd same-name generic is pushed twice. Port (4 lines). |
| `70e48898` / `4086c16a` | a stored name is never a path: `text_digest(path_named(StoredName(..)))` at the door | N/A today: hd-clean has no `StoredName`; kept_settle.av:353/:477 still `text_digest(r[1])`. Bug was born on the branch (`30d80f71` TextDigest). Port WITH any stored-name / package:path key work (`2a842b9c`). |
| `d5d67fe3` (hd-said) | an env probe with no digest is `absent`, never `0` | N/A (saved.av absent). Port with NameEnv. Owed: row codec 13-vs-14 fields, `?? 0` sweep (workspace.av 3 sites). |
| `2e32cf3c` | 13-field identity row = 14 with empty `maker` (split drops trailing empty) | N/A: hd-clean `read_row` (record.av:302) has no maker column; the maker column is `0780dac9`'s. Port together. |
| `bf13082b` | `sig` reads its row after the parse attaches (`decl_with_body`) — killed the 3733 cascade | **Yes** — `14cd5083` (workspace.av:2197 `early`). avra-nohold dirty diff == this; nothing else there. |
| `ab2994d3` + `63b0ff8b` | a method table settled early is short, never final; a standing impl names its members before any sig; an expansion in flight is not a table | **No** (workspace.av:2291 still returns `registered_methods` on non-Compute). Fixed the 29× `SyntaxArena has no method tag_stmt` (edit exit 0 at 10-27 10:05Z). Port only with revived/minted files; `62f50f00` later removed the `growing` guard. |
| `c63fe1ea` | kernel: a `.By` dep verified at this revision answers `changed_at` without its verifier (no reparse by a walker) | **No** (std-relation kernel.av:588). General kernel perf fix; port. |
| `31377ef9` | `reads_stand`/env probe restore a saved answer before verifying | No — needs `restored()` kernel API (`276792ca`). Port with revive. |
| `9b619be2` + `e91a9fcf` | `typing_open()` one predicate; whole-program verify under typing answers as it stands; consumed/read-found bits answer unread | **No** (consumes.av:80 still `|| comptime_active()`). Port; small. |
| `8da9bc6e` | a compile-time run never takes a revived stub unit (`Unit.is_stub`) | No; only matters once Lowered revives. Port with 1h. |
| `1cbcc007` | maker re-run: provisional lifts drop nothing; a wrapped fn crosses as the written one (`recursive_lift`) | No. Port with expansion work. |
| `e114603b` (hd-expanded) | a maker that could not run keeps its rows — `Ran`/`Directed`/`Unrun`, empty answer only ever an answer (encoding spends the empty value) | No (`Unrun` absent). Port. Did NOT change the 3733. |
| `25fcd389` | nameless-receiver defect names method + receiver type | **No** (features/impls/lower.av:22). Port (diagnostic). |
| `9a28e0ed` | a lowering defect names file + expression index | **No** (features/contract.av ~614). Port. |
| `6aabb734` | defects print the open frame stack (`Kernel.open_stack`) on cycle-read-of-missing-key and refs-after-typing | **No** (`open_stack` absent). Port (debuggability). |
| `91016f30` (db07e-step3) | `slots.last()!` for the least-recently-valid slot | No (`older_slots`/`VERSIONS_KEPT` absent on hd-clean). Only with #1236. |
| `2eb3161e`/`31c3d459`/`24a01003` | an unchanged saved answer is not filed again; `row_hash` is `int?` (absent ≠ 0) | No (saved.av). Port with savers. |
| `50e6feee`, `56c8f1a1` | gathers line scope read once; closure collect's set rides this program's row | No (`gathers_set`/`closure_set_key` absent). Port with store work. |
| `46b017e0`/`bfd11bf5` | `program_objects`/`opened` dead seats dropped | No. Trivial; port when touching build.av. |
| `9bd66df0` | cross_compiler_warm_attack via `tools/lib/steps.sh` + `compiler_release.py` | No (tool absent; #1272). Port with #1272. |
| `0780dac9` (hd-keys) | rows name a declaration by key (sibling, parent key, maker col 13), never an ordinal — A17 | No (`written_keys` etc absent). Port in step 2; it is DB 07a's naming. |

---

## 3. ROOT CAUSES

| breakage | cause | status / evidence |
|---|---|---|
| 3733 `language.defect` on the cli edit (first: generated `identity` over `Stmt` member `Defer`, receiver `<error>`) | a declaration row read BEFORE its file's parse attached: attaching reseats decls with the parse's ranges, so the earlier row named another arena's stmts → records arrived with no fields ("property … without a row"; all defects in core/expr/expr.av 334 + core/stmt/stmt.av 262) | **DIAGNOSED** — `bf13082b` alone: 3733 → 52 diagnostics, measured twice (cut; and hd-nohold2 + fix), session log 10-27 07:38Z/07:50Z |
| `note_producers` has no callers on the cut → held re-exports/gathers read EMPTY maps | `fc5b24ef` deleted `load_gathered`/record load chain, the only non-test caller | **DIAGNOSED by grep** (cb3ea83d: only cancel_reach_test.av:424); it was NOT the 3733 cause (sig fix was) |
| `SyntaxArena has no method tag_stmt` (29×) after the sig fix | method table settled while a generated impl was still being minted (short table read as final; expansion in flight treated as table) | **DIAGNOSED by fix** — `63b0ff8b`+`ab2994d3`, edit exit 0 (10-27 10:05Z). Caveat: same log admits many runs that day used a STALE `avra-try` |
| Edit 88.6 s already at cb3ea83d; 112–121 s / 194–201 s after 8df2faaf | hold deleted → every file parsed/typed/lowered; `keep` 110–124 s = `code_facts` + rule engine (`says`/`ruled_now`) over every file; `lower` 27–36 s whole program; `typed-settles` 19 903 | phase numbers MEASURED; attribution to keep's sub-parts **GUESSED** (KEEPPROBE results never read back — "every measurement since … ran an old binary", 10-27 10:13Z) |
| `Lowered` saved but never revived | revive gated on `hold.serving`, initialised false, never set | **DIAGNOSED by reading** (saved.av:609, workspace.av:394 on the cut); `a491f45f` set it for checks → "bought nothing measurable" |
| Typed rows OOM (7.9 GB `make try`, status 137) | `0272f17d` blamed the `@codec` generator; later analysis: registering a saver makes the family `stands_alone`, so every reader records ~10³ standalone rows (answers × read-set length) — row GRANULARITY, not codec emission | first: GUESSED in commit msg; second: **DIAGNOSED-ish** (saved.av:210 `big_reads` trace, read lists > 1500); not re-measured after `e6929af0` |
| `facts_kept` writes almost no rows on the edit | bails when any read lacks a durable name | **GUESSED** (instrumented, result never read; stale binary) |
| `check packages/std-avrac` dies at 11 s: `@std/relation:src/input.av does not exist` | branch's own `TextDigest` family (`30d80f71`) passed a STORED NAME to `text_digest`, which wants a path | **DIAGNOSED** — `Q ask TextDigest 2076 compute` just before failure; fixed at the door `70e48898`/`4086c16a`; `@std` then ran to completion (506 s) |
| sigfix cold `check packages/cli` killed at 600 s; std-avrac 506 s | the hold's one job — "this file's body is not needed this run", answered BEFORE work starts — has no replacement; Items revive was never wired (fc5b24ef body), no per-file Analysis row exists | **DIAGNOSED in principle** (506 s measured 10-28 23:45Z; "no commit anywhere has an analysis row" verified by search) |
| sigfix edit crash, exit 2, 55 s | not isolated. Last named blocker: `annotation.unsettled — derive a const trapped while settling` @ `@derive(Fingerprint)` features/contract.av:142/:148 | **UNDIAGNOSED** (QTRACE bisect planned, never run) |
| `Html.draw<Button>` declared twice | method registration not idempotent after `62f50f00` deduped by NAME (dropped generic siblings) | **DIAGNOSED** — fixed by id in `475aa67e` |
| whole-tree transplant onto hd-clean fails | deletion entangled with branch APIs (`TextDigest`, `StoredName`, 5-arg `store_stamped`, saved.av); 21/25 files copy clean, then `held_stubs`/`held_paths`/`is_held`/`parts_key`/`seen_key` undefined | **DIAGNOSED** (build error list, 10-28 23:08Z) |
| swapping `is_held` for a row judgement on hd-clean | `index 219 is out of bounds (length 40)`; ICE "what a held file said could not be read, and nothing was held"; store poisoned | **DIAGNOSED as: held is DATA** ("body absent this run"), not a cache |
| merging `stands_in` + `file_rows_stand` | `index -1 is out of bounds (length 0)` — present vs judged-and-ruled | **DIAGNOSED** (hd-clean, reverted). NB #1236 deleted `stands_in` on its base and was green there — re-check before trusting either |
| `manifest.no_target` on kr/kv fixtures (#1371 CI) | `entry_file()` null although src/main.av exists; main passes | symptom DIAGNOSED, cause **GUESSED** (a cut regression, likely the deleted `built_entry`/`Attempt.entry`) |
| `make try` fails on the cut's Sprite | released compiler cannot resolve the tree's `@std` layout (same stored-name bug); direct self-build OOM-killed at 212 s | DIAGNOSED (logs quoted in session) |
| poisoned `.avra-cache` after builder runs over a failing tree | mint-order + `<error>` defects until cache cleared | observed repeatedly; mechanism **GUESSED**; still unfixed |

---

## 4. HARVEST TABLE (one row per ref)

Goal step: 1 fast path · 2 saved per-decl analysis · 3 hold deletion · 4 DB08–09.

| ref / PR | what it did | proved / measured | why failed / stalled | PORT (shas) | close? | step |
|---|---|---|---|---|---|---|
| **hold-delete-cut** #1371 (cb3ea83d) | the cut: one attempt, verify_held gone, saved families, keys, NameEnv/FileSaid | cold/unchanged exit 0; edit exit 1 (3733), 88.6 s | stale-row cascade + no replacement for skip; CI: families ceiling 45/43, read-lists 11 408 > 3000, census +47–93 %, `no_target` | via hd-sigfix rows below | yes after port | 3 |
| **hd-sigfix** (475aa67e) | cut + hd-nohold(2) + 8df2faaf one-road + facts codec + TextDigest + keep skips + store-name door | 0 `is_held`; 3733 → 52 → 0; std-avrac 506 s; cli cold > 600 s; edit exit 2, 55 s | §3: every file read; `@derive(Fingerprint)` trap unresolved | deletion list §1 (fc5b24ef, 98ee4f66, 0afa98f6, 4fd23582, aec6aa14, 8df2faaf, 7a11ca86) as the CHECKLIST; fixes §2; infra 276792ca, 172175ec, 6ad2e874, 4a4878a8/83dd8ef3, cb9f0b16/f7cf33c5/bab848bf, e6929af0, 2913a0a2 | yes after port | 2,3 |
| hold-delete (15a1c709) | early chain: store seal-into-runs, kernel revive, Sig rows, checklist | — | superseded by cut | `6c0c2a3c` ROADMAP checklist; `2a842b9c`/`284ac586` (dup) stored names/package:path keys (64 new fns, 14 on hd-clean) | yes | 2,3 |
| hold-delete-flush (53da17d3) | one flush: keepers note keys, `flush_saved` writes exactly those | — | merged up | `6ad2e874`, `53da17d3` | yes | 2 |
| hold-delete-typed (f10f8b04) | Typed saved per decl, restored over its parse | — | reverted by 0272f17d (OOM) | `f10f8b04` guards (refuse revive over unparsed file / decl still expanding) | yes | 2 |
| hold-delete-lowered (0272f17d) | Lowered saved per decl; unit-row hold path deleted; TypeFacts codec dropped | 7.9 GB OOM with Typed saver | row granularity (`stands_alone`) | `aec6aa14` (Lowered saver), the `stands_alone`→"leaf files with its parent" law | yes | 2,3 |
| hold-delete-attach (cb5bf2e1, 1 unique) | Items: decls + use lines saved, minted from row, parse attached on body read | — | superseded by 83dd8ef3 in chain | none beyond 83dd8ef3 | yes | 2 |
| hold-delete-env (372ce72f) | NameEnv: outside reads grouped; trace by family | read lists | in chain | `eab7f9f6`, `372ce72f`, `9265bb2c`, `134b25f8` (env never probes env) | yes | 2 |
| hold-delete-said (5c305773) | FileSaid saved; Syntax saved by hash; two envs | stood files' said from FileSaid → tw edit parses 2 = main | in chain | `5c305773` (FileSaid ≈ hd-clean warning-facts goal; reconcile with `d1f91bc0`) | yes | 1,2 |
| hold-delete-tools (2dbb4ef7) | deletes hold keepers | — | in chain | `2dbb4ef7`, `db085ade` at hold deletion | yes | 3 |
| hold-delete-vocab (1eefec43) | vocab row for verify_held | — | in chain | `1eefec43` | yes | 3 |
| hold-delete-fixes2 (9bd66df0) | steps.sh / cross-compiler attack fix | — | in chain | `9bd66df0` with #1272 | yes | 3 |
| hd-keys (0780dac9) | rows name a decl by key, never ordinal | builds | in chain | `0780dac9` + `2e32cf3c` | yes | 2 |
| hd-expanded (e114603b) | Ran/Directed/Unrun for makers | `avra expand stmt.av` identical cold vs edit (1532 lines); 3733 unchanged | not the cause; step 2 (`Expanded` from pristine parse) unwritten | `e114603b`, `1cbcc007` | yes | 2 |
| hd-nohold (4fd23582) | held file is ordinary: sig/const/rows from saved answers | tw edit exit 0, 4/4 | no sig speed replacement | §1f list; replacement must precede (see WARNING) | yes | 3 |
| hd-nohold2 (15674131, 1 unique; worktree avra-nohold, dirty diff == bf13082b + tw_*.sh scripts) | items()/file_ensured/held_items/joins gone | make try passes; + sig fix → 52 diags | — | `15674131`; scripts `tw_verify.sh`/`tw_loop.sh`/`tw_bis.sh` as repro fixtures | yes (ask before worktree removal) | 3 |
| hd-consts (1e229225, 1 unique) | delete keep_const_units/const_rows_ready/const_unit_key | builds; no suites | not merged | `1e229225` | yes | 3 |
| hd-delete (b2cddb9d, 1 unique) | held sig fills from saved Sig row, not module record | — | superseded by 4fd23582 | none | yes | 3 |
| hd-said (d5d67fe3, 1 unique) | absent probe digest = `absent` | — | not merged | `d5d67fe3` with NameEnv | yes | 2 |
| hd-verify (042bcd68, 1 unique) | `AVRA_VERIFY_REVIVE=1`: revived answer recomputed + compared | ruled out revived values as 3733 cause | not merged | **`042bcd68`** — the replacement for verify_held | yes | 2,3 |
| consumed (ee86371c, 1 unique) | Consumed as its own saved family | **does not build** (error unread) | stalled | idea only; owed deletions: `o` flag, `fn_shape` consumed merge, held branch of `computed_consumed`, `typing_open` workaround | yes (learned) | 2 |
| names-memo (563675c7, 2 unique) | durable name spelled once per workspace, not per read per row | — | not merged | `9482083e`+`563675c7` | yes | 2 |
| cache-port #1303 (ab6ae263, 2 unique) | cache_attacks.sh → cost claims (files parsed, consts settled), `cas_bytes_read` | cut vs main tw: unused-fn edit 5 parsed/187 q vs 2/67; read-fn 5/189 vs 4/123 | targets cut; budget rows not added | `e3f66d8b`, `ab6ae263` — the GATE for step 3 | after port | 3 |
| dep-edit-kept #1272 (0c94783a) | dep_edit_kept + cross_compiler_warm attacks | main: edits parsed 3/42/3, others 114/195/248; `Q suspects … 78 suspect files` | expected red on main (hold witness) | `0c94783a` (+`9bd66df0`) | after port | 1,3 |
| db07e-step3 #1236 (b31b2af9, 5 unique) | FileRead.Words in a file's key; 4 versions behind `get_valid`; deletes `stands_in` | witness `cr` stale on main, cold-correct here | stalled; conflicts with pi's "stands_in merge unsound" | `bb1d35b9` Words read (component-word staleness is a REAL hole), `91016f30`, `b31b2af9`, `eacc14fb` | after port | 1,2 |
| refs-verify (e91a9fcf) | refs: typing_open; whole-program verify under typing | — | in chain | `9b619be2`, `e91a9fcf` | yes | 2 |
| time-stored-main #1220 CLOSED (1d8208b1, 14 unique) | std-time TextForm/JSON, std-db `@soft_delete`/`@auto` | — | not hold work; TextForm & soft_delete already on hd-clean (likely landed elsewhere) | none for this harvest; verify std lane landed `5bc657d4` (embed admits no package) | yes | — |
| hd-fam (local, 9265bb2c; worktree avra-fam clean) | = hold-delete chain tip at NameEnv | — | contained in sigfix | none | yes | — |
| hold-delete-keep (local, 13199b00; worktree avra-edit-speed, untracked ab*.sh) | typed rows on db-stored codec (`typed_rows.av`), `[lifted]` budget | — | WIP, needs named answers always on; codec OOM | `e116ba22`/`39024c2d` ideas; `13199b00` ≈ `cfe98a30`, `994e72b4` ≈ `00de0cf4` | yes | 2 |

### Infrastructure on the chain, absent from hd-clean (step-2 raw material)
`276792ca` kernel revive (`Revival`, `reads_stand`, `set_saved`; 11/20 fns missing) · `172175ec` durable key
names (`ArgName`, `saved_*`; 13/17 missing) · `8a938355` typed-let hook defaults · `63f39a57` ComponentNames
saved · `6ad2e874` `Saver`/`saves`/`flush_saved` · `00de0cf4`+`cfe98a30` @codec owner hoist (TypeFacts) ·
`e6929af0` facts as own row, one executor each way (89 new fns, `FactsScope`, `written_*`/`read_*` ids) ·
`2913a0a2` `store_wire` = fold of the wire table · `30d80f71` TextDigest family keyed by octets
(+ its door fix) · `f31e21f5` keep skips (`said_kept`) · `a491f45f` check reads saved units. Every one
lives in `compiler/saved.av`, which hd-clean/main never had — re-express on main's `compiler/store/*` seam
(session log: "main rewrote the store; cannot cherry-pick").

---

## 5. Port order this implies (smallest safe first)
1. Pure fixes, no dependencies: `475aa67e` (method entry by id), `c63fe1ea`, `25fcd389`, `9a28e0ed`, `6aabb734`, `9b619be2`+`e91a9fcf`.
2. Gates before deletion: `042bcd68` (verify-revive), `#1303` cost claims, `#1272` attacks.
3. Saved per-decl rows on main's store seam: key names (`0780dac9`, `172175ec`) → revive (`276792ca`, `31377ef9`)
   → Items (`83dd8ef3`, `bbc1598f`, `dbc48fd3`) → declaration row (NOT DeclSig) → Lowered (`aec6aa14`, `8da9bc6e`)
   → facts (`e6929af0`) filed as leaves, never `stands_alone`.
4. Then §1 groups in order 1g → 1e → 1d → 1f → 1h → 1i → 1a/1b/1c → 1j, gate after each (cold, edit, `--time`).
