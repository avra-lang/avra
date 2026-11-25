# Deletion map: what goes when the old path goes (tree at 9dd9f9dd; rows B, E and F corrected from the deletion rehearsal)

Each row gives a path, its line span or count, and **alive by** (what still reaches it today). A row marked † is a judgement made from a name-reference pass, not from a call graph. Rows marked ✓ were checked by deleting the code and building (the rehearsal: branches `rehearsal-delete` at dd1c60b9 for A–E, and `rehearsal-f1` at 08811be3 for F1; .lead/handoff/DELETION_REHEARSAL.md).

**Corrections in this revision**
- **B:** refuses.av is only partly dead. `hit_line` stays.
- **E:** E lands with B. shared_test is all `file_workspace`.
- **F:** F1 is not "named by nothing live": interface.av's `impl Decls` feeds lowering. F1 cannot go before F2. A deleted test file's helpers are borrowed by its siblings.
- **C and D**, for completeness: item_new_only is reached through modules.av `set_aside`, and tools/flow_trace_engines.sh belongs on D's tools row. Both are noted under their rows.

## A. The switches (each `program_door()` / `program_net()` and its old `else` branch)
| site | old branch | alive by |
|---|---|---|
| cli/src/commands/shared.av:386 `program_door`, :394 `program_net` | 2 fns, 9 lines with docs | every row below; `AVRA_PROGRAM=0`, `AVRA_PROGRAM_NET` |
| commands/check.av:19-26 | `checked_at(path)` then `said` | `avra check` under AVRA_PROGRAM=0 |
| commands/run.av:16-17 | `phased(args, "lower+run", ran)`; `ran` at :49-56 | `avra run` under AVRA_PROGRAM=0 |
| commands/test.av:22-35 | `proving_workspace` at :43-45, `ws.suites`, `proved` at :58-76 | `avra test` under AVRA_PROGRAM=0 |
| commands/fix.av:27-36 | `program_at`, `fixed` at :39-52, `applications` at :76-86 | `avra fix` under AVRA_PROGRAM=0 |
| commands/shared.av:720-760 `built_binary` | the else after the layer block: `build_workspace` and `toolchain(ws, …)`, plus `built_outcome` at :762-776 | `avra build` / `run` under AVRA_PROGRAM=0 |
| cli/src/stage.av:64-87 `refuse_eval` | after :65, `root_workspace` then `ws.from_sources` | the `@refuse-eval` leg under AVRA_PROGRAM=0 |

**Kept from fix.av (the layer `fix` reuses them):** `fixes_written`, `report`, `application_json`, `edit_json`, `opt_json`, `fight_report`, `application_line(s)`, `tier_word`, `edit_summary`, `diff_of`, and the command.

**Kept from check.av:** `joined_lines`, `refused_sites` (check_program.av calls both), and the flags and command.

## B. Helpers only the A branches reach ✓
| fn / file | lines | alive by |
|---|---|---|
| check.av `said`, `time_line`, `rendered_licenses`/`rendered_license`, `refused_licenses`, `accepted` | 73 | A's check branch. `accepted` is also reached by E's idiom_baseline_test. The layer's `refused_licenses`/`stale_citation` (4d873bb0) replace the licence pair. They match case for case: 13 cases SAME, warm included. |
| test.av `proving_workspace`, `proved`, `nothing_to_prove`, `scopes_of`, `names_no_test_under` | 42 | A's test branch. Kept: `no_tests_here` and `names_no_test`, which the layer's `program_tested` calls. `dir_root` and `path_root` stay. |
| commands/refuses.av, PART: `one_refuses`, `checked_refuses`, `refuses_binary` | 52 of 154 | `checked_refuses` ← test.av `proved`. **The rest STAYS:** `leg`, `leg_or_host`, `leg_wrong`, `ended_so`, `hang_bound`, `tested_env`, `compiler_env`, `owed`, `other_end`, `other_voice`. The layer's child legs (tapes.av `children_wrong`, around :2146) run through them. Deleting the whole file fails `make try` with `leg_or_host`, `tested_env` and `compiler_env` unresolved. |
| commands/phase.av | 24, whole file | `phased(args…)` ← run.av's old branch only. The other `phased` callers use the engine-phase verb, a different fn. |
| shared.av `program_arg`, `file_workspace`, `lone`, `root_workspace`, `root_program`, `program_at`, `on_program`, `warn`, `timings`, `build_workspace`, `build_entry`, `checked_at`, `toolchain(ws…)`, `ws_lookup` | 107 | Rows A, C, D and E. **`hit_line` STAYS:** the layer's tapes build calls it (tapes.av :570, :3395). `file_home` STAYS (check.av and fix use it on the layer). |
| shared.av `built_binary`'s old branch, `built_outcome` | 30 | A's build branch |
| run.av `ran` | 4 | A's run branch. `warn` has no other caller. |
| stage.av `refuse_eval`'s old branch; its imports `program_door`, `root_workspace` | 20 | the `@refuse-eval` leg under `AVRA_PROGRAM=0` |
| `program_door_refused`'s words | 1 clause | They said "with AVRA_PROGRAM=0 the old path does". The clause goes with the switch; no golden holds it. |
| what the deletion leaves unread | — | 6 `modules.unused_import` and 1 `fns.dead_parameter` (tapes `held`'s `root`). `avra fix --only modules.unused_import` removes the imports. idioms-cli is red until then. |

## C. The net and its step-aside list
| item | lines | alive by |
|---|---|---|
| shared.av `NetJudge`, `NetSaid`, `net_said`, `net_stops`, `net_vouches`, `said_refused`, `net_report`, `net_verdict`, `build_refusal`, `check_refusal`, `NET_REFUSED`, `NET_WITHIN_MS`, `false_refusal_header` :396-505 | ~110 | callers: check.av ×1, check_program.av ×3, db.av ×1, test.av ×1, tapes.av ×9 (each passes a `NetSaid` in or asks `net_stops`/`net_vouches`). Those parameters go with it |
| `.avra-cache/net-verdict{,.err}` that `net_report` writes | — | the net only |
| std-avrac/src/compiler/item_new_only.av (`NewOnly`, `parsed_new_only`, `program_new_only`, `new_only_fact_definitions`) | 220 | the step-aside list: shared.av `net_stops`/`net_vouches`, check_program.av ×3, tapes.av ×9 (including the `tapes --new_only` receipt at :1164 and :1190), item_tapes.av (its definitions registered), modules.av ×2 |
| gate rows that set AVRA_PROGRAM_NET=1 (tools/gate.sh: the build slice's net-on cli builds and the findings slices' "0 program-layer false refusal" rows) | — | the net |

**From the rehearsal:**
- **The step-aside list is also reached** through compiler/modules.av `Workspace.set_aside`. It is the old Workspace's own copy: it filters a layer-only test program out of `entry_files` with `parsed_new_only`. Cut that filter with C (−13 lines), or item_new_only cannot go before F.
- **The voice change:** a refusal the net said went to stdout; the layer's goes to stderr (see E, build_report).

## D. The tapes differentials (layer held to the old Workspace)
| item | lines | alive by |
|---|---|---|
| tapes.av `held` :1199-1216: workspace opened, `lowered_held`, `difference`, `typed_share` | 18 | `avra tapes <pkg>` with no flag, `--lowered`, `--signatures` |
| tapes.av :1348-1643: `difference`, `typed_share`, `typed_pairs`, `written_decl`, `type_difference`, `agrees`, `parameter_standing`, `names_no_type`, `headed`, `workspace_spelled`, `signature_difference`, `scope_difference`, and the namespace comparison :1566-1643 | ~295 | same |
| tapes.av :1996-2868: `lowered_held`, `wanted_held`, the `*_target`/`*_symbols`/`*_decl` family, `old_parameter`, `workspace_settled`, `flag_tests`/`tests_agreed`/`flag_tested`/`numbered`, the `lift*`/`lowered`/`statics_difference` family, `workspace_symbol`, `retag*`, `type_tags`, `callee_symbols`, `known_symbols`, `box_renamed`/`slot_renamed`, `leading`/`ins_text` | ~870 | `tapes --lowered` alone. `tallied` :2200 STAYS (`worked_by_query` uses it). `every_callee` :2401 needs one look |
| tapes.av `workspace_link_words` :3597-3604 and its comparison in `link_words_held` :3606-3622 | ~25 | `tapes --link_words` (manifests held to a workspace's link line) |
| tapes.av `unit_timed` :1170-1174 | 5 | old Workspace timing |
| tools: the gate rows that run `tapes` with no flag, `--lowered`, `--signatures` or `--link_words`; and every `old_row` (tools/gate.sh, GATE_OLD_PATH) together with each witness_program_*.sh "held to the old path" comparison (fixes, ledger, suites, doors, differential, warnings) | — | the differential receipts; per CLAUDE/gate they go "with one line each" |

**From the rehearsal:**
- **Also on D's tools row:** tools/flow_trace_engines.sh's evaluated leg, `AVRA_PROGRAM=0 avra run`. It is reached through `make flow-trace` (witness-b), not through a gate.sh row. Ported to `avra run --eval` (6afb7ad9).
- **Sweep every tool and Makefile recipe, not only gate.sh,** for `AVRA_PROGRAM=0` and `AVRA_PROGRAM_NET=1`: about 20 tools set them. With the switch gone, a tool that sets `AVRA_PROGRAM=0` silently runs the layer.
- **Slices left empty:** refusal-a/b/c and warnings-a/b/c held only `old_row` rows, and go with them.

## E. cli tests over the old path ✓ — they land WITH B
Without them, a cold `avra check packages/cli` refuses with 15 errors (rehearsal 81e706d7). Each file below is alive only through the B helpers it names.

| file | lines | old reach (what fails to resolve once B goes) | fate |
|---|---|---|---|
| commands/tests/check_reuse_test.av | 292 | `checked_at` ×18; whether a check was reused (`c.reused`) | delete, or port onto the layer's warm reuse |
| commands/tests/idiom_baseline_test.av | 92 | `checked_at`, `accepted` | port onto check_program's prune (`Baseline.pruned`) |
| commands/tests/findings_rows_test.av | 63 | `checked_at`, `root_workspace(..).opened_store()`; once they go, a lambda at :49 no longer types | delete: old Finding rows |
| commands/tests/check_test.av | 82 | `checked_at`; the root-shape routing of `build_workspace` | port: a src-less root on the layer. The live gap this showed is **FIXED in 33e48d74**: a directory with no `avra.toml` is refused in a new voice, `manifest.no_manifest` ("`<dir>` holds no `avra.toml`: nothing was checked"), naming the package it stands in; exit 1. A root with no `src/` checks each file directly in it, or refuses in `manifest.no_source`'s words. Witness: cli check_dir_test, 2/11 → 11/11. check_test's claims are covered there on the layer. |
| commands/tests/provider_words_test.av | 52 | `checked_at`; warm words | port, or check that the warm witness covers it |
| commands/tests/warm_component_form_test.av, warm_deleted_test.av, warm_order_test.av | 89, 58, 54 | `checked_at`, cold against warm | port: each claim is a layer warm claim too |
| commands/tests/shared_test.av | 122, **whole file** | `file_workspace` routing. All its cases are that; there are no `file_home` cases. | delete, or port its routing claims onto `checked_disk`/`file_home` |
| commands/tests/build_tools_test.av | 77 | `root_workspace`, `toolchain(ws…)` (tools fixed per workspace) | port onto the layer's toolchain stamp, or delete |
| commands/tests/rule_self_match_probe_test.av | 33 | `root_program("packages/std-avrac")` | port onto `held_on_disk`, or delete |

That is 11 files, 1,014 lines. Not old-path despite a name match: sibling_programs_test (its own `program_at`).

**The cli suite after B, C and E:** 9 cases fail. All are held up only by the net's words: ui_view ×4, generated_view ×2, sibling_programs ×2 and build_report ×1. On f794bbdc they are green with the net on; with it off, 8 fail the same way. build_report reads stdout, where the net put its refusal (`println`); the layer says the refusal on stderr. They must be closed on the layer, or pinned, before C goes.

## F. std-avrac: the old path itself

**F is one change, not three.** F1 cannot go before F2's old impls, nor F2 before F3. Each reaches the others, and a part deleted alone breaks the rest.

**F1. Whole files no LIVE code names, except interface.av ✓ (compiled, rehearsal-f1 08811be3).**
Measured by deleting these 16 files (and codecs_test.av) on the A–E rehearsal tree, then asking f794bbdc's old check what no longer resolves.

| file | lines | alive by, measured |
|---|---|---|
| compiler/interface.av | 784 | **LIVE: `impl Decls { type_symbol, wire_body, … }`.** The lowering calls `Decls.type_symbol` (lower/lower.av :1327 and :1703, lower/state.av :752), and the layer lowers through compiler/lower. `type_wire` and `decl_wire` feed features/decls.av's durable fold `ids()` / `decl_door` (:1396, :1407). Whether that fold is old-only needs one look. **Move `impl Decls` to a layer file first.** `impl Workspace` (:50-422) is old. |
| compiler/facts_scope.av | 147 | `Workspace.query_scope()`. **Every old-Workspace `@query`/`@relation` calls it in its generated body:** std-relation's generators write `ctx.query_scope()` (query.av :250, :746), giving 322 errors in query.av and 36 in relation.av. Old-only, but it goes with the last old query, not before. |
| compiler/codecs.av | 1351 | the old Checked/verdict wire. record.av, whole.av and verdict.av call its `wire_number`, `fields_wire`, `bit_word`, `FileFacts` and `RelLoc`. Old-only; it goes with F2. Its codecs_test.av goes with it. |
| compiler/modules.av, receivers.av, leaves.av, settlement_wire.av, rule_proof.av, decl_rows.av, dep_audit.av, filesaid.av, linked.av, rel_loc.av, uses_kept.av, sites.av, file_said.av | 614, 425, 520, 392, 198, 177, 158, 155, 116, 100, 86, 74, 66 | `impl Workspace` methods that only F2 files and F3 tests call (record.av ×50, workspace.av ×46, verdict.av ×22, whole.av ×21, workspace_analysis.av ×16, derive.av ×10, build.av, signed.av ×7, suite.av ×5, and so on). Old-only; they go with F2. modules.av's `set_aside` also kept C's `parsed_new_only` alive. That filter is cut in the rehearsal, so C can go first. |

**A layer defect this exposed.** With F1 gone, `make try` does not refuse the names that no longer resolve. It answers `package_impls` / `generated_names` "was asked while it was being answered" (`file_scope → generated_names → file_generated → generated → resolved`). A name that does not resolve sends the layer to ask the generators, and their runs resolve in turn, so the refusal is hidden behind a cycle. It is the same family as the derive-own-file cycle (6febccbe). **FIXED in 6645e46c:** generators stand in strata. `resolved` reads `written_file_scope`, where an import of a name its module doesn't write stays pending, bound only when that name itself is read. A missing name is therefore refused (`resolve.not_exported`) where it's written, never a cycle. Witness: compiler/tests/generator_strata_test; before, the run trapped on the cycle; after, 4/4. The rest of a generator's inputs followed in cb9919e3 and 91184de6:
  - the record it is handed (`record_signature_written`);
  - the sites and arguments it runs over (`stratum_resolved` in item_generators and item_generated);
  - what it lifts and marks (item_meta);
  - the impls its output files (item_methods `type_named`).

  **Measured on the F1 deletion over the lane** (scratch branch rehearsal-f1-lane at 1447c8f6), with the build's compiler containing the fix:
  - `make try`: 0 cycles, 425 errors said. Before: 5 cycles and 0 errors.
  - `check packages/std-avrac`, layer against old check, by distinct (message, file): every name error the old check says, the layer says too. That is `resolve.unresolved` 28/28, `type.unknown` 4/4 and `resolve.not_exported` 12/12.
  - The layer says 52 distinct errors in all, the old check 181. The rest are `type.method` errors in files the layer doesn't type while the package has resolution errors. That is its cascade policy, not a silence: the check exits 1.

**F0. The old path's machine pack, and the directories the deletion retires.**
- **The services P0 goes with F.** The old path's per-print machine pack (`~/.avra/cache/prints/<print>/store`) serves stale derive member lists (found by defects). The net-off flip removes the reader; the deletion removes the code.
- **Its witness is tools/derive_members_witness.sh** (defects, 0b689141). Cases (2), the default, and (3), `AVRA_PROGRAM=0`, go with the old path. Case (1) stays as a gate row.
- **Directories the deletion retires:** `~/.avra/cache/prints/` (the per-print packs) and `~/.avra/cache/cas/`. Nothing on the layer reads them once F lands. A user's existing ones are left behind as dead weight, so the landing should say so, or remove them on first run.

**F2. Mixed files: the old impls go, a shared export stays.** † (Not compiled apart. The F1 measurement shows which files hold the old callers: every one listed below, plus the three live sites under interface.av.)

| file | lines | what stays |
|---|---|---|
| workspace.av | 2446 | `Package`, `family_code_hash` (cli explain, family_hashes) |
| record.av | 2002 | `reads_of`, `Reads` (layer item_formats, item_context_reads, explain) |
| expand.av | 1636 | `Spelled` (interp, lowering, item_lowered) |
| workspace_analysis.av | 1281 | `trapped`, `lowered_unit_of` (interp, stage, tapes) |
| build.av | 1085 | the layer's link/emit verbs; needs a callers pass |
| voices.av | 1094 | ~16 voices the item_* laws speak |
| whole.av | 958 | `Program` itself; the type goes |
| derive.av | 720 | `Checked` goes; `BuildOutcome`/`Toolchain` stay (tapes, built_binary) |
| verdict.av | 711 | `Shaped` stays (layer, core) |
| failures.av | 691 | `Chain`, `Raised` stay |
| program.av | 612 | `parse_program`, `Parsed` stay |
| cache_walk.av | 555 | `Subject`, `Counted`, `Reached` stay |
| references.av | 502 | `Uses` stays |
| producers.av | 499 | `head_of`, `unmarked` stay |
| cancel_reach.av | 424 | `row_wait_said`, `spawn_wait_said` stay |
| suite.av | 405 | `RefusesCall`, `ChildEnd` (refuses.av's surviving runners), `SuiteProgram`, `in_scope`, `proofs_said`, `quarrel` stay |
| packages.av | 383 | `admission`, `entering`, `dep_chain`, `Admitting`, `unset_link_holes_of` stay |
| world.av | 312 | `Looked` stays |
| analysis.av | 307 | `Analysis`, `one_shot_let_go`. Each user needs a look (db.av, findings.av, idioms.av, licenses.av, lower.av, dev/witnesses.av); some are old-only too. `licenses.av`'s `file_stale_lines(a: Analysis …)` goes; `citations_naming_nothing` stays (the layer's `stale_citations`). |
| rule_examples.av | 264 | stays (`avra rules`, quote_pat, features/rule) |
| rule_fix.av | 256 | `Application`, `fix_applied`, `fighting_pair`, `rule_doc`, `fixable`/`repairable`/`errors_spoken`/`swallowed_break` stay. The old `Program.fix_applications` / `suggestion_applications` / `repair_applications` / `repair_clears` / `law_proved` / `ir_proved` / `edits_proved` door goes. |
| consumes.av | 245 | `kept_seats` stays (item_lowered) |
| rule_delete.av | 211 | `delete_edits`/`deleted` reach rule_pass and fmt; `decl_span`/`deletion_edit` stay (rule_pass now uses them) |
| signed.av | 125 | `Signed` stays |
| cleanup.av | 109 | `cleanup_unbounded` stays |
| answers.av | 97 | `file_text`: a name collision with std-relation; check |
| parse_said.av | 54 | `parse_said` stays (file_answers) |

**F3. The old test harness.**
- testing/old_path/mod.av (80 lines; `test_workspace`) and every test that imports it. Count them with `grep -rl 'testing.old_path' packages`. These are the harness lane's port list. rule_fix_test and rule_proof_test are off it now (324af538). Also every `@std.avrac.compiler.{Program, Workspace, Analysis}` import under `*/tests/`.
- **Measured: 14 tests call F1's `impl Workspace` directly.** They are rel_loc ×10, decl_name ×6, named_whole ×5, lifted_naming_adversarial ×4, fn_wire_marks ×4, warning_facts ×3, settle_name ×3, dense_names ×3, syntax_receivers ×2, queries_keyed ×2, held_facts ×2, typed_digest, producers and decl_wire (all in compiler/tests). Each is a port-or-delete row of the same kind as E.
- **Test files of one module share names, so deleting one can break its sibling.** compiler/tests/build_mode_test.av (8ae128b1, old-path, untagged) called `print_workspace` and `real_binary`, which only compiler_print_workspace_test.av defined. Before deleting any test file, grep its module's other test files for the names it defines. In the rehearsal the helpers moved into build_mode_test (17/17).
- `*_workspace_test` files: the 12 INTERNAL ones of the harness lane are deleted in the rehearsal. direct_test_workspace_test (lowering lane, 8ae128b1) stays until its owner tags it.

## G. Before deleting: a parity check
- **Stale `// LICENSED` ids: CONFIRMED gap.** A package whose file holds `// LICENSED style.no_such_rule: …` gets:
  - `AVRA_PROGRAM=0 avra check`: "licenses: 1 stale `// LICENSED` id(s) … names no rule `avra rules` lists", exit 1;
  - the layer check: nothing, exit 0.

  The law lives only in the old check (check.av `refused_licenses`, from `Checked.licenses` ← verdict.av `licenses()`). Deleting A loses it. It needs a layer form first.

  **CLOSED:** 4d873bb0 (defects; made cheap in 14aeb4eb) is the layer form. It was held case for case against the old check, with words, paths and exit compared. 13 cases, all SAME:
  - the package's own file; a file nothing imports; a test file; a path dependency's file;
  - a keeper-family id plus a rule id (not stale); a bare citation and one in a string (not stale);
  - order across files and within one; with an error (the error alone);
  - `--baseline` (the stale refusal first); `--baseline_accept` (prunes, exit 0);
  - a lone file; a file argument; warm (clean, again, add, again, drop).

  Not run: a raw block's body. The one difference found was not this law's: `avra check <dir that is not a package root>` checked 0 files on the layer. That is fixed in 33e48d74 (see E, check_test).
- `--counts` / `count_reads` on the old check branch (check.av:19) has a layer counterpart, `work_counts`, at :68; this needs a look.
- `fix` with only `Fixing` on the layer: impls.default_override now holds (324af538). No other `Fix.Delete` rule exists.
