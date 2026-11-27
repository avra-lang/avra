# WISP INVENTORY — every internal entry point, classed

**Base:** `origin/program` at `94c02115` (train49). Re-measured from the tree: Make targets parsed from the Makefile, `tools/` top-level entries, `AVRA_*` tokens over Makefile, `.github/`, `tools/`, `packages/`, `runtime/`, `backend/`, the shims and CLAUDE/README/DOGFOODING, and `packages/cli/src/commands`. First measured at `d7cd84d9`; a row standing since then keeps its class and action, its callers re-read (Make, tools). A row marked *new since d7cd84d9* is classed by its shape, and the lead confirms it.

**Since train52** the nine `KEEPERS_*` sets are rows of `./wisp keepers` (packages/wisp/src/commands/keepers.av); a caller below named `KEEPERS_X` reads as that set.

**Class:** `user` a person building or using Avra reaches it; `internal` the repo's machinery; `not config` an `AVRA_` token that is no setting (a C macro, guard, enum or fixture name). **Action:** `keep`; `merge: <verb>` becomes that wisp verb and the old path dies in the same change; `delete`.

## Counts

| Surface | Total | Was (d7cd84d9) | By class | By action |
|---|---|---|---|---|
| Make targets | 143 | 160 | internal 138, user 5 | merge 121, keep 14, delete 5, delete, with work 2, delete (S1) 1 |
| tools/ entries | 270 | 299 | internal 270 | merge 256, delete 5, delete, with work 5, keep 4 |
| `AVRA_*` names | 285 | 270 | internal 161, not config 80, user 44 | merge 157, — 80, keep 44, delete 4 |
| cli command files | 42 | 42 | user 25, internal 17 | keep 24, merge 18 |

Not counted: the 100 `AVRA_SET_*` macros, which `wisp tree_settings` generates into `runtime/avra_settings.h` from the one declaration (packages/wisp/src/settings/declared.av). They are projections, never names a person sets.

### Where the merges land

| Verb | Rows |
|---|---|
| oracle | 138 |
| keepers | 112 |
| a flag of its verb | 86 |
| settings.debug | 68 |
| cost | 45 |
| census | 30 |
| gate | 21 |
| tree | 14 |
| seed | 8 |
| fixtures | 7 |
| shim flag | 7 |
| idioms | 6 |
| voices | 5 |
| work | 3 |
| dies with its callers | 1 |
| avra | 1 |

## Deleted as obsolete

A running list: each entry is gone from the tree, named with the train that removed it.

- **train41 (f43cefa0): dead Python and its gates:** `tools/cost_ratchet.py`, `tools/digest_diff.py`, `tools/parse_diff.py`, `tools/program_findings.py`, `tools/program_findings_gate.sh`, `tools/term_width.py`, `AVRA_LEAVES`.
- **train44 (f6ec64b8): keepers pruned, the PR flow retired:** `make cited`, `make http-cites`, `make families-left`, `make speed-note`, `make hooks-released`, `make whole-reads`, `make whole-reads-accept`, `make ci-verdict`, `make pr-watcher`, `make pipeline-doc`, `make tail-status`, `make pipeline-status`, `make codecs`, `make workflows-yaml`, `tools/batch.sh`, `tools/batch_test.sh`, `tools/cited.allow`, `tools/cited.py`, `tools/families.ceiling`, `tools/footprint.baseline`, `tools/http_cites.py`, `tools/pipeline_doc.allow`, `tools/pipeline_doc.py`, `tools/pipeline_status.py`, `tools/pr_watcher.py`, `tools/ratchet_rows.py`, `tools/speed.budget`, `tools/speed_ratchet.py`, `tools/tail_status.sh`, `tools/wasm-size.baseline`, `tools/whole_reads.baseline`, `tools/whole_reads.py`, `tools/witness_work_wait.sh`, `tools/work.budget`, `tools/work_ratchet.py`, `tools/workflows_yaml.py`, `AVRA_QUEUE_TOKEN`, `AVRA_WAIT_POLL`, `AVRA_WAIT_SECONDS`, `AVRA_WATCHER_STATE`.
- **train46 (7214a623): the store attacks became cli specs:** `make ahead-edit-attack`, `make held-store-attack`, `make heir-save-attack`, `make share-merge-attack`, `make beside-attack`, `make wave-share-attack`, `tools/ahead_edit_attack.sh`, `tools/beside_attack.sh`, `tools/heir_save_attack.sh`, `tools/held_store_attack.sh`, `tools/share_merge_attack.sh`, `tools/wave_share_attack.sh`.
- **train48 (d29c9ed2): moved to packages/wisp, ./wisp:** `make tools-suite`, `tools/avra.toml`, `tools/avra_tools.sh`, `tools/src/`, `tools/tools_key.sh`.
- **wisp defects (ported):** `tools/defects.py`, `tools/defects_previous.py`, `AVRA_DEFECT_STALL`, `AVRA_DEFECT_TIMEOUT`, `AVRA_DEFECT_WARM`, `AVRA_DEFECT_WARM_CLOCK`, `AVRA_DEFECT_WORKERS` (now flags).
- **wisp release (ported):** `tools/compiler_release.py` — publish is the binary's, the reads are the shim's.
- **Earlier (S1 corrections, d7cd84d9):** `make check/run/ir/emit/build-native` still stand, owed by S1's "dead" half, which was split out of the rename.

## Findings now

- **The rename is done** (train48): `packages/wisp`, `./wisp --compiler <avra>`, asset `wisp-<key>`. Its commands: `pr_mode`, `ci_path_gate`, `host_events`, `suites`, `tree_settings`, `cost`.
- **Nine keeper sets still stand** (`KEEPERS`, `_ALONE`, `_A`, `_A1`, `_A2`, `_B`, `_WASM`, `_STATIC`, `_PR`): the S4 registry is still to port.
- **`-accept` targets:** 11 remain; each becomes `--accept` on its `wisp cost` ratchet.
- **Sprites:** `tools/work` still sources the `sprite-*` scripts; they die with `wisp work`.

## Make targets

| Target | Called by | Class | Action | Note |
|---|---|---|---|---|
| apple-runtime | none | internal | merge: keepers | new since d7cd84d9 |
| attack | KEEPERS_B; KEEPERS_PR; recipe | internal | merge: oracle | an agreement or refusal case |
| avra | recipe | user | keep: Make | builds files; runs before any compiler exists |
| bash-parse | KEEPERS_STATIC; recipe | internal | merge: keepers | new since d7cd84d9 |
| bench | recipe | internal | merge: census | a report, never a verdict |
| bench-collections | recipe | internal | merge: census | a report, never a verdict |
| bootstrap | recipe | user | keep: Make | builds files; runs before any compiler exists |
| build-native | none | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| cache-attacks | recipe | internal | merge: oracle | an agreement or refusal case |
| cache-attacks-b | recipe | internal | merge: oracle | an agreement or refusal case |
| cache-attacks-b1 | recipe | internal | merge: oracle | an agreement or refusal case |
| cache-attacks-b2 | recipe | internal | merge: oracle | an agreement or refusal case |
| cache-attacks-w | recipe | internal | merge: oracle | an agreement or refusal case |
| census | recipe | internal | merge: census | a report, never a verdict |
| census-types | recipe | internal | merge: census | a report, never a verdict |
| check | recipe | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| ci-invariants | KEEPERS_STATIC; recipe | internal | merge: keepers |  |
| clean | recipe | user | keep: Make | builds files; runs before any compiler exists |
| clock-holds | KEEPERS | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| code-hash-attacks | recipe | internal | merge: oracle | an agreement or refusal case |
| codecs-static | KEEPERS_A2; KEEPERS_STATIC; recipe | internal | merge: keepers |  |
| compile-slots | KEEPERS_A2; recipe | internal | merge: oracle | an agreement or refusal case |
| compiler | recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| compiler-files | recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| compiler-key | recipe | internal | merge: keepers |  |
| cost | KEEPERS_A1; recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| cost-accept | recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| cost-snapshot | KEEPERS_A2; recipe | internal | merge: keepers | new since d7cd84d9 |
| cutoff-witness | KEEPERS_B | internal | merge: oracle | an agreement or refusal case |
| db-corpus | recipe | internal | merge: oracle | an agreement or refusal case |
| defects | keepers registry (b) | internal | merge: keepers | runs `wisp defects` |
| dev-server | recipe | internal | merge: keepers |  |
| dogfooding-rules | KEEPERS_B; KEEPERS_PR; recipe | internal | merge: idioms |  |
| edit-loop | recipe | internal | merge: cost warm-edit | no caller |
| emit | none | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| exact-patches | recipe | internal | merge: oracle | an agreement or refusal case |
| externs | KEEPERS_B; KEEPERS_STATIC; recipe | internal | merge: keepers |  |
| fingerprints | KEEPERS_B; KEEPERS_STATIC; recipe | internal | merge: keepers |  |
| flow-bench | recipe | internal | merge: census | a report, never a verdict |
| flow-g1 | recipe | internal | merge: census | a report, never a verdict |
| flow-gate | recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| flow-gate-accept | recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| flow-probes | recipe | internal | merge: census | a report, never a verdict |
| flow-trace | KEEPERS_A2; recipe | internal | merge: oracle | an agreement or refusal case |
| fmt-lossless | KEEPERS_A1; recipe | internal | merge: keepers |  |
| footprint | KEEPERS_PR; recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| footprint-accept | recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| fuzz | recipe | internal | merge: oracle | an agreement or refusal case |
| fuzz-http | recipe | internal | merge: oracle | an agreement or refusal case |
| gate | recipe | internal | merge: gate |  |
| h2spec | KEEPERS_B; recipe | internal | merge: keepers |  |
| hash-door | KEEPERS_A1; recipe | internal | merge: keepers |  |
| host-events | KEEPERS_STATIC; recipe | internal | merge: keepers |  |
| idioms | recipe | internal | merge: idioms |  |
| idioms-accept | recipe | internal | merge: idioms |  |
| inputs | KEEPERS_B; recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| inputs-accept | recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| install | none | user | keep: Make | builds files; runs before any compiler exists |
| ir | none | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| keepers | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-a | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-a1 | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-a2 | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-alone | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-b | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-pr | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-static | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-wasm | recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| layers | KEEPERS_B; KEEPERS_STATIC; recipe | internal | merge: keepers |  |
| layout-oracle | recipe | internal | merge: oracle | an agreement or refusal case |
| libs | recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| libs-self-test | KEEPERS_B; KEEPERS_STATIC; recipe | internal | merge: fixtures |  |
| libscope | KEEPERS_B; recipe | internal | merge: keepers |  |
| llvm-libs | recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| native-check | none | internal | merge: oracle | an eval==native case |
| no-threads | recipe | internal | merge: keepers |  |
| object-gone-attack | none | internal | delete (S1) | no caller; its script also runs in `cache-attacks-b2` |
| objects | recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| parser | KEEPERS_B; KEEPERS_PR; recipe | internal | merge: keepers |  |
| pool-check | KEEPERS_B; recipe | internal | merge: keepers |  |
| pre-commit-hook | KEEPERS_B; KEEPERS_STATIC; recipe | internal | merge: keepers | new since d7cd84d9 |
| read-cost | KEEPERS_A2; recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| read-lists | KEEPERS_A2; recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| ready | recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| recover | recipe | user | keep: Make | builds files; runs before any compiler exists |
| rt-header | KEEPERS_B; KEEPERS_PR; recipe | internal | merge: keepers |  |
| rt-ns | KEEPERS_B; KEEPERS_PR; recipe | internal | merge: keepers |  |
| rule-examples | KEEPERS_B; recipe | internal | merge: idioms |  |
| run | recipe | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| runtime-mutations | KEEPERS_ALONE; recipe | internal | merge: oracle | an agreement or refusal case |
| runtime-tests | KEEPERS_ALONE; recipe | internal | merge: keepers |  |
| scaffold-check | recipe | internal | merge: keepers |  |
| seed | recipe | internal | merge: seed |  |
| seed-check | recipe | internal | merge: seed |  |
| sizes | recipe | internal | merge: census | a report, never a verdict |
| soak-http | recipe | internal | merge: oracle | an agreement or refusal case |
| speed-accept | none | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| speed-ratchet | KEEPERS_A1; KEEPERS_PR | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| sprite | none | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite-check | none | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| stems | KEEPERS_A1; recipe | internal | merge: keepers |  |
| store-attacks | recipe | internal | merge: oracle | an agreement or refusal case |
| store-witnesses | recipe | internal | merge: oracle | an agreement or refusal case |
| suites | KEEPERS_B; KEEPERS_STATIC; recipe | internal | merge: gate --suites |  |
| sweep | recipe | internal | merge: tree sweep |  |
| test | recipe | internal | merge: gate --suites |  |
| tested | recipe | internal | merge: gate --suites |  |
| tick-object | recipe | internal | merge: keepers |  |
| tool-witnesses | recipe | internal | merge: fixtures |  |
| trap-marks | KEEPERS_B; recipe | internal | merge: keepers |  |
| traps | KEEPERS_A2; recipe | internal | merge: oracle | an agreement or refusal case |
| try | recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| ui-board | recipe | internal | merge: keepers |  |
| ui-browser | recipe | internal | merge: keepers |  |
| ui-browser-skip | KEEPERS_STATIC; recipe | internal | merge: keepers |  |
| ui-fuzz | recipe | internal | merge: oracle | an agreement or refusal case |
| ui-host | recipe | internal | merge: keepers |  |
| ui-host-test | recipe | internal | merge: keepers |  |
| vendored-fixture | KEEPERS_STATIC | internal | merge: keepers |  |
| vocab | KEEPERS_B; KEEPERS_STATIC; recipe | internal | merge: keepers |  |
| voices | KEEPERS_B | internal | merge: voices |  |
| voices-accept | none | internal | merge: voices |  |
| wall-accept | none | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wall-ratchet | none | internal | merge: cost | no caller; folds into the speed ratchet |
| warm-accept | none | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| warm-edit | KEEPERS_A2; KEEPERS_PR | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wasm-archive | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-body | none | internal | merge: keepers | "keeper owed" and run by nothing |
| wasm-cache | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-check | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-host-check | KEEPERS_WASM; recipe | internal | merge: keepers |  |
| wasm-packages | none | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| wasm-refuses | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-routes-size | KEEPERS_WASM | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wasm-runtime | none | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| wasm-seam | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-size | none | internal | merge: census | no caller |
| wasm-size-accept | none | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wasm-size-guard | KEEPERS_WASM | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wasm-tasks-mutations | KEEPERS_WASM; recipe | internal | merge: oracle | an agreement or refusal case |
| witness | KEEPERS_A2; recipe | internal | merge: oracle | an agreement or refusal case |
| witnesses | KEEPERS_B; KEEPERS_PR; recipe | internal | merge: keepers |  |
| work-accept | none | internal | merge: cost | a ratchet; `-accept` is its `--accept` |

## tools/

| Entry | Called by | Class | Action | Note |
|---|---|---|---|---|
| affected_packages.sh | checks.yml, gate_changed.sh, work | internal | merge: gate |  |
| attack.baseline | Makefile, attack.av, attack.av +1 | internal | merge: oracle |  |
| attack.sh | checks.yml, Makefile, attack.av +44 | internal | merge: oracle |  |
| avsrc.py | Makefile | internal | merge: keepers |  |
| bash_parse.sh | checks.yml, Makefile | internal | merge: keepers | new since d7cd84d9 |
| bench.sh | Makefile, ci_invariants.py, digest_bench.sh +4 | internal | merge: census |  |
| bench/ | Makefile, README.md, bench.sh +48 | internal | merge: census |  |
| bounded.sh | checks.yml, Makefile, gate.sh | internal | merge: gate |  |
| calib.py | action.yml, speed_note.sh | internal | merge: cost |  |
| capped.sh | Makefile, db06_pkgc_witness.sh, dev_server_check.sh +5 | internal | merge: wisp runner | every child wisp spawns is capped and bounded; one definition |
| carried_store_attack.sh | gate.sh | internal | merge: oracle |  |
| case_leftover_attack.sh | gate.sh | internal | merge: oracle |  |
| census.sh | Makefile | internal | merge: census |  |
| census_compiler.sh | census.sh, cost.sh, cost_stable.sh +1 | internal | merge: census |  |
| census_types.sh | Makefile | internal | merge: census |  |
| chunk_owed_attack.sh | gate.sh | internal | merge: oracle |  |
| ci_dup_run.py | checks.yml, Makefile, ci_invariants.py | internal | merge: gate |  |
| ci_invariants.py | Makefile | internal | merge: keepers | PORTED — `wisp ci_invariants` |
| ci_verdict.sh | checks.yml | internal | merge: gate |  |
| ci_wall.sh | gate.yml, Makefile, ledger_rows.sh | internal | merge: gate |  |
| clock_holds.py | Makefile | internal | merge: cost |  |
| closure_fold_attack.sh | Makefile | internal | merge: oracle |  |
| closure_gather_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| code_hash_attacks.sh | Makefile | internal | merge: oracle |  |
| codecs.py | checks.yml, Makefile, codecs.av +1 | internal | merge: keepers |  |
| compile_slots.sh | Makefile | internal | merge: oracle |  |
| compiler_paths.sh | action.yml, checks.yml, lane-run.yml +6 | internal | merge: gate |  |
| corpus_ir.sh | none | internal | merge: census | NO CALLER |
| cost.baseline | gate.yml, Makefile, cost.av +10 | internal | merge: cost |  |
| cost.candidates | cost.av | internal | merge: cost |  |
| cost.sh | gate.yml, Makefile, census.av +8 | internal | merge: cost |  |
| cost.verdicts | cost.av, cost.sh | internal | merge: cost |  |
| cost_snapshot.sh | Makefile | internal | merge: keepers | new since d7cd84d9 |
| cost_stable.sh | cost.av | internal | merge: cost |  |
| cutoff.ceiling | Makefile, cutoff_witness.sh | internal | merge: cost |  |
| cutoff_witness.sh | Makefile, cutoff.ceiling | internal | merge: oracle |  |
| db06_pkgc_witness.sh | none | internal | delete | a finished campaign's probe |
| db06_step5_witness.sh | store_attacks.sh | internal | merge: oracle | run by store_attacks.sh |
| db06_step6_rebuild.sh | store_attacks.sh | internal | merge: oracle | cited by store_attacks.sh |
| db_corpus.sh | Makefile | internal | merge: oracle |  |
| db_measure/ | Makefile, census.sh, warm_edit_bench.sh | internal | merge: census |  |
| defects/ | Makefile, defects.av | internal | keep: wisp defects | the corpus `wisp defects` reads |
| dep_audit.sh | audit_switch_test.av, bypass.av | internal | merge: tree |  |
| dep_audit.tsv | dep_audit.sh | internal | merge: tree |  |
| dep_tests_listing_attack.sh | Makefile | internal | merge: oracle |  |
| derive_members_witness.sh | gate.sh | internal | merge: oracle |  |
| dev_server_check.sh | Makefile | internal | merge: keepers |  |
| docs_cache_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| dom_page.sh | none | internal | merge: keepers | NO CALLER |
| exact-patches/ | Makefile | internal | merge: oracle |  |
| externs.py | Makefile, llvm_emit.av, CENSUS.md | internal | merge: keepers |  |
| failed_tail_test.sh | none | internal | merge: fixtures |  |
| file_module_attack.sh | Makefile | internal | merge: oracle |  |
| fingerprints.py | Makefile | internal | merge: keepers |  |
| flow_bench/ | Makefile | internal | merge: census |  |
| flow_trace/ | Makefile, traced_answer.av, traced_generic.av +5 | internal | merge: oracle |  |
| flow_trace_engines.sh | Makefile, traced_answer.av, traced_generic.av +3 | internal | merge: oracle |  |
| flow_trace_swap_attack.sh | gate.sh | internal | merge: oracle |  |
| fmt_changed.sh | gate.sh, witness_fmt_changed.sh | internal | merge: keepers |  |
| fmt_lossless.sh | Makefile | internal | merge: keepers |  |
| fmt_roundtrip.sh | fmt_lossless.sh | internal | merge: keepers |  |
| footprint.py | Makefile | internal | merge: cost |  |
| footprint/ | checks.yml, Makefile, cost.baseline +8 | internal | merge: cost |  |
| footprint_bytes.sh | Makefile, footprint.py | internal | merge: keepers | new since d7cd84d9 |
| frame_place_attack.sh | gate.sh | internal | merge: oracle |  |
| fuzz.sh | Makefile | internal | merge: oracle |  |
| fuzz_http.sh | Makefile, main.av | internal | merge: oracle |  |
| gate.sh | compiler-macos.yml, gate.yml, lane-run.yml +5 | internal | merge: gate |  |
| gate/ | checks.yml, compiler-macos.yml, gate.yml +101 | internal | merge: keepers |  |
| gate_changed.sh | checks.yml, lane-run.yml, Makefile +1 | internal | merge: gate |  |
| gate_receipt.sh | Makefile | internal | merge: gate |  |
| gathered_cache_attack.sh | Makefile | internal | merge: oracle |  |
| h2spec.sh | Makefile | internal | merge: keepers |  |
| h2spec/ | Makefile, h2spec.sh | internal | merge: keepers |  |
| hand_down.sh | action.yml, checks.yml, orders.yml +1 | internal | merge: gate |  |
| hold_sweep.sh | hold_refusal_test.av | internal | delete | dies with the hold |
| hooks/ | Makefile, hooks_pre_commit_check.sh, store_attacks.sh +1 | internal | keep: data | git hooks; their bodies call wisp |
| hooks_pre_commit_check.sh | Makefile | internal | merge: keepers |  |
| host_fn_edit_attack.sh | Makefile | internal | merge: oracle |  |
| host_key.sh | ledger_rows.sh, speed_measure.sh, warm_edit_bench.sh +1 | internal | merge: cost |  |
| idioms.baseline | Makefile, explain_proof.sh, rules_proof.sh +4 | internal | keep: data of idioms |  |
| impl_held_attack.sh | Makefile | internal | merge: oracle |  |
| inputs.baseline | wisp inputs | internal | merge: cost |  |
| inputs.py | Makefile, licenses.av | internal | merge: cost | PORTED — `wisp inputs` |
| ios_sim_witness.sh | none | internal | merge: oracle | new since d7cd84d9 |
| jspi_node.sh | wasm-check.sh, wasm-host-check.sh, wasm-tasks-mutations.sh | internal | merge: keepers |  |
| keeper_planted.sh | gate.sh | internal | merge: keepers | new since d7cd84d9 |
| keepers_loop.sh | Makefile | internal | merge: gate |  |
| ladder.sh | action.yml, Makefile, ci_invariants.py +2 | internal | merge: seed |  |
| layer_sites_attack.sh | gate.sh | internal | merge: oracle |  |
| layers.py | Makefile | internal | merge: tree |  |
| layout-oracle/ | checks.yml, Makefile, solve.av +7 | internal | merge: oracle |  |
| layout_oracle.sh | checks.yml, orders.yml, Makefile +2 | internal | merge: oracle |  |
| layout_oracle_absent_test.sh | checks.yml, Makefile | internal | merge: oracle |  |
| layout_oracle_boundary_test.sh | checks.yml, Makefile | internal | merge: oracle |  |
| layout_oracle_own_term_test.sh | checks.yml, Makefile | internal | merge: oracle |  |
| ledger_rows.sh | gate.yml, Makefile, ci_invariants.py +5 | internal | merge: keepers | new since d7cd84d9 |
| lib/ | Makefile, manifest.av, avra.toml +214 | internal | merge: (dies with its callers) | shell helpers shared by scripts |
| libs.py | Makefile, manifest.av, avra.toml +3 | internal | merge: tree |  |
| libscope.sh | Makefile | internal | merge: tree |  |
| licence_families.py | none | internal | merge: keepers | PORTED — into `wisp inputs` |
| link_cache_attack.sh | Makefile | internal | merge: oracle |  |
| llvm_link.py | Makefile, avra.toml, llvm_link.sh | internal | merge: tree |  |
| llvm_link.sh | Makefile, llvm_link.py | internal | merge: tree |  |
| manifest_objects.sh | Makefile, db06_pkgc_witness.sh, libs.py +4 | internal | merge: tree objects | FIRST VERB; the compiler's manifest.av is the reader |
| memcap.sh | checks.yml, Makefile, ci_path_gate.av +9 | internal | merge: wisp runner | every child wisp spawns is capped and bounded; one definition |
| memsites.py | ab.sh, explain_cost.sh | internal | merge: census |  |
| moved_tree_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| names_attack.sh | Makefile | internal | merge: oracle |  |
| obj_gone_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| object_gone_attack.sh | Makefile | internal | merge: oracle | a different attack from obj_gone_attack.sh; run by cache-attacks-b2 |
| package_swap_attack.sh | Makefile | internal | merge: oracle |  |
| packages.sh | checks.yml, orders.yml, affected_packages.sh +2 | internal | merge: gate |  |
| page-closure/ | gate.sh, witness_page_closure.sh | internal | merge: oracle |  |
| path_leak_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| pool/ | Makefile, avra.toml, main.av +10 | internal | merge: keepers |  |
| pool_check.sh | Makefile | internal | merge: keepers |  |
| pr_body.sh | checks.yml, speed_note.sh | internal | merge: gate |  |
| pr_mode.py | checks.yml, Makefile | internal | merge: gate | PORTED — `wisp pr_mode` |
| print_mix_attack.sh | Makefile | internal | merge: oracle |  |
| profile.sh | Makefile | internal | merge: census |  |
| program-doors.expected/ | witness_program_doors.sh | internal | merge: oracle |  |
| program-doors/ | witness_program_doors.sh | internal | merge: oracle |  |
| program-fixes/ | witness_program_fixes.sh | internal | merge: oracle |  |
| program-ledger/ | witness_program_ledger.sh | internal | merge: oracle |  |
| program-refusals/ | witnesses.av, case_leftover_attack.sh, externs.py +3 | internal | merge: oracle |  |
| program-runs/ | witness_program_runs.sh | internal | merge: oracle |  |
| program-suites/ | root_listing_attack.sh, two_compilers_attack.sh, witness_program_suites.sh | internal | merge: oracle |  |
| program-warnings/ | gate.sh, witness_program_warnings.sh | internal | merge: oracle |  |
| program_refusals_sweep.sh | none | internal | delete | holds the program layer to the old path, deleted at b6dce5f |
| program_traps.baseline | tapes.av | internal | keep: data of keepers traps |  |
| queue-witness/ | gate.sh | internal | merge: oracle |  |
| read_lists.ceiling | read_lists.py | internal | merge: cost |  |
| read_lists.py | Makefile, read_lists.ceiling | internal | merge: cost |  |
| reclaim.sh | reclaim_test.sh | internal | merge: work reclaim |  |
| reclaim_test.sh | none | internal | merge: work reclaim |  |
| reformat_lane.sh | none | internal | delete | a one-time layout migration, done |
| root_listing_attack.sh | gate.sh | internal | merge: oracle |  |
| run_wasm.mjs | witness_program_refusal.sh | internal | merge: oracle |  |
| rungs.sh | action.yml, orders.yml, Makefile +2 | internal | merge: seed |  |
| seed_guard.sh | Makefile | internal | merge: seed |  |
| seed_is_tree.sh | Makefile | internal | merge: seed |  |
| shards.py | suite-cold.txt, suite-seconds.txt, suite-splits.txt +3 | internal | merge: gate |  |
| shim_guard_test.sh | none | internal | merge: fixtures |  |
| sig_restore_attack.sh | Makefile | internal | merge: oracle |  |
| soak_http.sh | Makefile | internal | merge: oracle |  |
| sources_hash.sh | Makefile, seed_guard.sh, sprite-provision.sh | internal | merge: tree |  |
| sp | action.yml, packages-dev.txt, packages.txt +448 | internal | delete | the old spelling of `work run` |
| speed.baseline | none | internal | merge: cost | NO CALLER |
| speed_measure.sh | Makefile, ledger_rows.sh, speed_ratchet.sh | internal | merge: cost |  |
| speed_note.sh | action.yml, calib.py, ci_invariants.py +2 | internal | merge: cost |  |
| speed_note_fixtures/ | speed_note_test.sh | internal | merge: cost |  |
| speed_note_test.sh | none | internal | merge: cost |  |
| speed_ratchet.sh | Makefile | internal | merge: keepers | new since d7cd84d9 |
| sprite-lib.sh | packages-dev.txt, packages.txt, sprite-remote.sh +2 | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite-provision.sh | Makefile, sprite-lib.sh, sprite-remote.sh +1 | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite-remote.sh | Makefile, ci_invariants.py, sprite-lib.sh +3 | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite-rsh.sh | work, work_test.sh | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite_remote_test.sh | work_test.sh | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| stale_imports_attack.sh | Makefile | internal | merge: oracle |  |
| stamps.sh | Makefile | internal | merge: tree |  |
| std_answers.sh | Makefile, std_answers.av, census.sh +3 | internal | merge: seed std-answers |  |
| std_answers_attack.sh | gate.sh | internal | merge: oracle |  |
| std_answers_checkout_witness.sh | gate.sh | internal | merge: oracle |  |
| stems.sh | Makefile, libs.py | internal | merge: tree |  |
| step_cpu.py | checks.yml | internal | merge: gate |  |
| steps_test.sh | none | internal | merge: fixtures |  |
| store_attacks.sh | Makefile | internal | merge: oracle |  |
| store_baseline.sh | store_attacks.sh | internal | merge: oracle |  |
| store_bound_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| store_clean_attack.sh | Makefile | internal | merge: oracle |  |
| store_quiet_attack.sh | Makefile | internal | merge: oracle |  |
| store_reads_attack.sh | Makefile, store_reads_process_test.av | internal | merge: oracle |  |
| storyboard/ | gate.sh, storyboard_browser.sh | internal | merge: keepers | new since d7cd84d9 |
| storyboard_browser.sh | gate.sh | internal | merge: keepers | new since d7cd84d9 |
| suites_links.sh | Makefile, suites.av | internal | merge: keepers |  |
| suspect_narrow_attack.sh | Makefile | internal | merge: oracle |  |
| symsize.py | Makefile | internal | merge: tree |  |
| terminated.allow | externs.py | internal | merge: keepers |  |
| tick.py | Makefile | internal | merge: keepers |  |
| tls_renegotiation.sh | h2spec.sh, main.av | internal | merge: keepers |  |
| tls_renegotiation/ | h2spec.sh, tls_renegotiation.sh | internal | merge: keepers | NO CALLER |
| tool_witnesses.sh | Makefile | internal | merge: fixtures |  |
| traps.py | Makefile, ir.av | internal | merge: oracle |  |
| traps.sh | Makefile, sqlite_adversarial_test.av, externs.py +1 | internal | merge: oracle |  |
| two_compilers_attack.sh | gate.sh | internal | merge: oracle |  |
| type_named_cache_attack.sh | type_named_test.av, gathered_cache_attack.sh | internal | merge: oracle |  |
| ui-bench/ | ui_bench.sh | internal | merge: census |  |
| ui-board/ | install_firefox.sh, checks.yml, gate.yml +18 | internal | merge: keepers |  |
| ui-observed/ | ui_board_browser.sh | internal | merge: keepers |  |
| ui-shown/ | ui_board_browser.sh | internal | merge: keepers |  |
| ui-warns/ | ui_board_browser.sh | internal | merge: keepers |  |
| ui_bench.sh | none | internal | merge: census | NO CALLER |
| ui_board.sh | Makefile, gate.sh, main.av | internal | merge: keepers |  |
| ui_board_browser.sh | packages-browser.txt, checks.yml, Makefile +6 | internal | merge: keepers |  |
| ui_fuzz.sh | Makefile | internal | merge: oracle |  |
| ui_host.sh | Makefile | internal | merge: keepers |  |
| ui_host_test.sh | Makefile | internal | merge: keepers |  |
| unicode_tables.py | unicode.av | internal | merge: tree |  |
| vendored_fixture.py | Makefile, std_sources.av | internal | merge: keepers |  |
| vocab.sh | Makefile | internal | merge: keepers |  |
| voices.baseline | Makefile, coverage.av | internal | merge: voices |  |
| voices_spoken.py | Makefile | internal | merge: voices |  |
| warm_edit_bench.sh | Makefile, work.av, ci_invariants.py +2 | internal | merge: cost |  |
| wasm-archive.sh | Makefile | internal | merge: keepers |  |
| wasm-body.sh | Makefile | internal | merge: keepers |  |
| wasm-cache-attacks.sh | Makefile | internal | merge: oracle |  |
| wasm-check.sh | Makefile | internal | merge: keepers |  |
| wasm-fixtures/ | task_stack_test.av, wasm-check.sh, wasm-tasks-mutations.sh | internal | merge: keepers |  |
| wasm-host-check.sh | Makefile, main.av | internal | merge: keepers |  |
| wasm-host-objects.sh | wasm-cache-attacks.sh, wasm-check.sh | internal | merge: keepers |  |
| wasm-host/ | Makefile, wasm-cache-attacks.sh, wasm-check.sh +2 | internal | merge: keepers | NO CALLER |
| wasm-min/ | wasm-size-guard.sh, wasm-size.sh | internal | merge: census |  |
| wasm-node.mjs | shared.av, wasm-check.sh, wasm-tasks-mutations.sh | internal | merge: keepers |  |
| wasm-refuses.sh | Makefile, keeper_planted.sh | internal | merge: keepers |  |
| wasm-refuses/ | Makefile, gate.sh, keeper_planted.sh +2 | internal | merge: keepers |  |
| wasm-routes-size.sh | Makefile, wasm-check.sh | internal | merge: cost |  |
| wasm-routes/ | Makefile, wasm-check.sh, wasm-routes-size.sh | internal | merge: keepers | NO CALLER |
| wasm-seam-check.sh | Makefile | internal | merge: keepers |  |
| wasm-seam/ | Makefile, wasm-seam-check.sh | internal | merge: keepers |  |
| wasm-size-guard.sh | Makefile, wasm-check.sh | internal | merge: cost |  |
| wasm-size.sh | Makefile | internal | merge: census |  |
| wasm-tasks-mutations.sh | Makefile | internal | merge: oracle |  |
| watch.sh | Makefile, avra, child_kept.sh +2 | internal | merge: wisp runner | every child wisp spawns is capped and bounded; one definition |
| witness-files/ | witness_program_differential.sh | internal | merge: oracle |  |
| witness_board_dev.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_board_native.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_body_consts.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_callee_edit.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_compiler_key.sh | Makefile, gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_compiler_release.sh | wisp | internal | merge: oracle | the shim's release reads, against local files; run by tool_witnesses (derived) |
| witness_disk_full.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_fmt_changed.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_frameless_writes.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_free_leaf.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_gate_changed.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_held_instance.sh | witness_settled_wire.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_layered_link.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_machine_store.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_page_closure.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_parallel_build.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_place_kill.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_differential.old | witness_program_differential.py, witness_program_differential.sh | internal | keep: data of its witness | the frozen golden witness_program_differential.py reads |
| witness_program_differential.py | witness_program_differential.sh | internal | merge: oracle |  |
| witness_program_differential.sh | gate.sh, main.av, witness_program_differential.py | internal | merge: oracle |  |
| witness_program_doors.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_edit.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_fixes.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_ledger.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_needs.sh | law_findings.av, gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_refusal.sh | case_leftover_attack.sh, externs.py, gate.sh +1 | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_runs.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_suites.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_waits.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_warnings.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_settled_wire.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_store_broken_edit.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_store_builders.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_store_prints.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_two_suites.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_validator_upstream_const.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_warm_edit.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_work_run.sh | none | internal | merge: oracle | run by tool_witnesses (derived) |
| work | checks.yml, compiler-macos.yml, lane-run.yml +149 | internal | merge: work | the seven lane commands; its `--sprite` half deletes |
| work_test.sh | sprite_remote_test.sh | internal | merge: fixtures |  |
| wrapper_marks_attack.sh | gate.sh | internal | merge: oracle |  |
| writes_attack.sh | Makefile | internal | merge: oracle |  |

## AVRA_* names

| Name | Read in | Class | Action | Note |
|---|---|---|---|---|
| AVRA_A | projected_test.av | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_ADDCHDIR | avra_runtime.c, std_process.c | not config | — | a C macro, enum or guard |
| AVRA_AHEAD_EDIT | avra_settings.h, declared.av, named.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_AHEAD_UNPROVEN | avra_settings.h, declared.av, layer_check.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_ALIAS_EMIT | CLAUDE.md | internal | delete | named in CLAUDE.md only |
| AVRA_ALIAS_LOG | CLAUDE.md, avra_runtime.c, avra_settings.h +5 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_ATTACH_BOUND_S | work | internal | merge: wisp flag | read by tools alone |
| AVRA_ATTACH_S | sprite-remote.sh, sprite_remote_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_BENCH_PAYLOADS | main.av | internal | merge: wisp flag | read by tools alone |
| AVRA_BESIDE | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_BIN | ab.sh, avra, child_kept.sh +13 | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_BIN_MAX_BYTES | avra_settings.h, declared.av, named.av +2 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_BOOTSTRAPPING | avra | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_BOX_H | avra_box.h | not config | — | a C macro, enum or guard |
| AVRA_BUILDER_BACK | work | internal | merge: wisp flag | read by tools alone |
| AVRA_BUILD_CAP_MB | sprite-remote.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_BUILD_LOCK | fmt_light_test.av, watch.sh | not config | — | a test fixture's name |
| AVRA_BUILD_S | work | internal | merge: wisp flag | read by tools alone |
| AVRA_BUILD_SLOTS | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_CACHE_DIR | attack.sh, avra_settings.h, carried_store_attack.sh +57 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_CALLER | avra_hot.c, avra_platform.h, avra_runtime.c +1 | not config | — | a C macro, enum or guard |
| AVRA_CAP_MB | avra, compiler-macos.yml, lane-run.yml +1 | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_CASE | avra_runtime.c, child_kept.sh | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_CAS_DIR | avra_settings.h, declared.av, named.av +1 | not config | — | a test fixture's name |
| AVRA_CAS_MAX_AGE_DAYS | avra_settings.h, cas.av, declared.av +2 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_CAS_MAX_MB | avra_settings.h, cas.av, declared.av +4 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_CAS_PHASE | avra_settings.h, declared.av, named.av +1 | not config | — | a test fixture's name |
| AVRA_CENSUS | avra_hot.h, avra_runtime.c | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_DEATHS | avra_runtime.c, avra_settings.h, cost.sh +2 | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_ROWS_TOP | avra_settings.h, declared.av, named.av | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_SITES | avra_runtime.c, avra_settings.h, census.sh +3 | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_TOP | avra_settings.h, cost.sh, declared.av +1 | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_TYPES | avra_runtime.c, census_compiler.sh, census_types.sh +2 | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_TYPES_TOP | avra_settings.h, declared.av, named.av | internal | merge: settings.debug | runtime instrument |
| AVRA_CHILDREN | child_kept.sh, gate.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_CHILD_BIN | child_kept.sh, gate.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_CLOCK | avra_fiber.c, avra_fiber.h, avra_settings.h +4 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_CLOCK_ASKS | avra_runtime.c, avra_runtime.h, avra_settings.h +4 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_COMPILER_DEPOT | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_COMPILE_SLOT | avra_settings.h, compile_slots.sh, declared.av +3 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_CORES_H | avra_cores.h | not config | — | a C macro, enum or guard |
| AVRA_CORE_FROM_SURFACE | avra_settings.h, declared.av, item_elaborated.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_CWD | CLAUDE.md, avra, db_corpus.sh +3 | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_CXX_RUNTIME | Dockerfile, Makefile, avra +6 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_DB_FAST | avra_settings.h, declared.av, named.av +1 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_DB_GRAPH | ab.sh, avra_settings.h, declared.av +4 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_DB_VERIFY | avra_settings.h, debug.av, declared.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_DEBUG | avra_runtime.c, avra_settings.h, debug.av +4 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_DEPOT_KEEP | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_DEP_AUDIT | avra_settings.h, bypass.av, declared.av +4 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_DISK_FLOOR_MB | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_DOOR_H | avra_door.h | not config | — | a C macro, enum or guard |
| AVRA_E | inherit_env.av | not config | — | a test fixture's name |
| AVRA_EMIT_TIMES | llvm_wrapper.c | internal | merge: settings.debug | runtime instrument |
| AVRA_ENGINE_PARSE | avra_settings.h, declared.av, named.av +1 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_EPOLL | avra_fiber.c | not config | — | a C macro, enum or guard |
| AVRA_EVAL_JUMPS_CHECK | avra_settings.h, declared.av, interp.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_EXACT | Makefile, check_tests.sh, exact_comp.av +12 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_FFI_ARGS | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FFI_MAX_F | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FFI_MAX_I | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FFI_SEATS | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FFI_WORDS | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FIBER_GUARDS | avra_fiber.c, avra_settings.h, declared.av +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FIBER_H | avra_fiber.h | not config | — | a C macro, enum or guard |
| AVRA_FIBER_STACK | avra_settings.h, avra_task_stack_unoptimised.c, declared.av +4 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FLAGS_AT | avra_box.h, avra_hot.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_FLAGS_MASK | avra_box.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_FLOW_TRACE | avra_fiber.c, avra_settings.h, cores_test.c +6 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FLOW_TRACE_CAP | avra_settings.h, declared.av, named.av | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FOLD_CHECK | avra_settings.h, declared.av, named.av +4 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FOLD_OFF | avra_settings.h, declared.av, named.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FRAME_POINTERS | Makefile, census_compiler.sh, llvm_wrapper.c +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FRONTIER_WALK_CHECK | avra_settings.h, declared.av, frontier.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FROZEN_S | sprite-remote.sh, sprite_remote_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_GATE_BUILDER_ASKED | work, work_test.sh | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_GET_BUILD | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_GH | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_GUARDED_PACKAGE | CLAUDE.md, avra, shim_guard_test.sh | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_HASH_SEED | CLAUDE.md, avra_runtime.c, avra_settings.h +3 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_HEALTH_S | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_HEIR_LINGERS_MS | avra_cores.c, avra_settings.h, declared.av +2 | internal | merge: settings.debug | runtime instrument |
| AVRA_HELD_ANSWERS_OFF | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_BYTES | avra_settings.h, declared.av, item_signatures.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_ITEMS_OFF | avra_settings.h, declared.av, item_signatures.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_QUESTIONS_CHECK | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_QUESTIONS_OFF | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_ROUNDTRIP | avra_settings.h, declared.av, named.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_VALUES_BYTES | avra_settings.h, declared.av, held_values.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HOSTED | Makefile, avra_fiber.c, tasks.js +1 | not config | — | a C macro, enum or guard |
| AVRA_HOT_H | avra_hot.h | not config | — | a C macro, enum or guard |
| AVRA_INLINE_RUNTIME | census_compiler.sh, census_types.sh, link_cache_attack.sh +5 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_INSTRUMENTS | Makefile, avra_hot.h, avra_platform.h +1 | not config | — | a C macro, enum or guard |
| AVRA_IO_CORPUS_UNSET | io.av | not config | — | a test fixture's name |
| AVRA_IO_NO_SUCH_VARIABLE | io_test.av | not config | — | a test fixture's name |
| AVRA_IO_SURELY_UNSET |  | not config | — | a test fixture's name |
| AVRA_IR_OF | avra_settings.h, declared.av, item_program.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_KEEP | generated_types.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_KEY | config_adversarial_test.av | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_KILL_AFTER_PLACE | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_KQUEUE | avra_fiber.c | not config | — | a C macro, enum or guard |
| AVRA_LADDER_BASE | Makefile, ladder.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LADDER_DIR | Makefile, ladder.sh, sprite-remote.sh +1 | internal | merge: wisp flag | read by tools alone |
| AVRA_LADDER_REPO | ladder.sh, sprite-remote.sh, sprite_remote_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LADDER_S | Makefile, ladder.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LAND_BATCH_WT | reclaim.sh, reclaim_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LAND_LOCK | reclaim.sh, reclaim_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LAND_SPEED_OK | speed.baseline | internal | merge: wisp flag | read by tools alone |
| AVRA_LEG_PROBE | refuse_eval_test.av | not config | — | a test fixture's name |
| AVRA_LIGHT | avra, disk_host.av, stage.av | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_LINK_TRACE | avra_settings.h, declared.av, named.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_LLVM_MAJOR | sprite-provision.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LOG | witness_fmt_changed.sh, witness_gate_changed.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_MACHINE_STORE | avra_settings.h, cost.sh, declared.av +8 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_MACHINE_STORE_DIR | avra_settings.h, cost.sh, declared.av +7 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_MAC_COMPILER | work, work_test.sh | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_MAC_COMPILER_URL | work | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_MAINC_BUILD | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_MAINC_WAIT_S | work | internal | merge: wisp flag | read by tools alone |
| AVRA_MAIN_OVERRIDE | reference-transaction | internal | merge: wisp flag | read by tools alone |
| AVRA_MAIN_TREE | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_MAP_STATS | CLAUDE.md, avra_runtime.c, avra_settings.h +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MAX_COMPILES | Makefile, attack.sh, avra_settings.h +8 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_MEASURES_MEMORY | avra_platform.h, avra_pool.c, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_MEM_CEILING_MB | ab.sh, avra_runtime.c, avra_settings.h +12 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_DUMP_AT | avra_runtime.c, avra_settings.h, declared.av +1 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_FLOOR | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_MEM_POOL_DIR | avra_settings.h, cores_test.c, declared.av +3 | internal | merge: settings.debug | runtime instrument |
| AVRA_MEM_POOL_MB | avra_pool.c, avra_settings.h, compiler-macos.yml +5 | internal | merge: settings.debug | runtime instrument |
| AVRA_MEM_POOL_WAIT_MS | avra_pool.c, avra_settings.h, declared.av +3 | internal | merge: settings.debug | runtime instrument |
| AVRA_MEM_SITE | CLAUDE.md, avra_runtime.c, avra_settings.h +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_SITES | CLAUDE.md, avra_settings.h, declared.av +1 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_STATS | CLAUDE.md, FLAGS.md, ab.sh +22 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_WIDE | avra_runtime.c, avra_settings.h, declared.av +1 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MERGED_APART_FROM | avra_settings.h, declared.av, named.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_MERGED_HERE | avra_settings.h, declared.av, layer_check.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_N | inherit_env.av | not config | — | a test fixture's name |
| AVRA_NO_SUCH_TOOL_VAR | process_test.av | not config | — | a test fixture's name |
| AVRA_NO_SUCH_VAR |  | not config | — | a test fixture's name |
| AVRA_NO_SUCH_VARIABLE |  | not config | — | a test fixture's name |
| AVRA_NO_SUPERVISOR_TESTS | checks.yml, gate.sh, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_NULL_PAGE | avra_hot.h, link.av, wasm_data_base_test.av | not config | — | a C macro, enum or guard |
| AVRA_OBJ_MAX_BYTES | avra_settings.h, declared.av, named.av +4 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_OBSERVED | avra_box.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_ONCE_MAX | libs.py | internal | merge: wisp flag | read by tools alone |
| AVRA_P | inherit_env.av | not config | — | a test fixture's name |
| AVRA_PAGE |  | not config | — | a C macro, enum or guard; new since d7cd84d9 |
| AVRA_PAGE_FETCHED | dev.av, document.av | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_PAGE_HOST | dev.av, document.av | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_PAGE_MODULE | dev.av, document.av | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_PLANTED_READ | keeper_planted.sh | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_PLATFORM_H | avra_platform.h | not config | — | a C macro, enum or guard |
| AVRA_PREFIX | census.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_PRINTS_MAX_AGE_DAYS | avra_settings.h, declared.av, named.av +2 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_PROBE | process_adversarial_test.av, process_test.av | not config | — | a test fixture's name |
| AVRA_PROBE_BUILD | sprite-remote.sh, work | internal | merge: wisp flag | read by tools alone |
| AVRA_PROGRAM | README.md, build_report_test.av, check_program.av +18 | internal | delete | no reader since the old path died (b6dce5f); 23 tool sites still set it |
| AVRA_PROGRAM_MODE | Makefile, avra_settings.h, build_mode_test.av +18 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_PROGRAM_NET | build_report_test.av, build_tools_test.av, census.sh +21 | internal | delete | no reader; 24 tool sites still set it |
| AVRA_PRUNE_PCT | sprite-remote.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_QTRACE | CLAUDE.md, DOGFOODING.md, ab.sh +25 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_QUERY_FAMILIES | avra_settings.h, declared.av, named.av +1 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_QUERY_TIMES | avra_settings.h, cutoff_witness.sh, declared.av +10 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_RAMP_S | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RANDOM_H | avra_random.h | not config | — | a C macro, enum or guard |
| AVRA_RAN_TRAP | avra_settings.h, declared.av, named.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_RC_GUARD | CENSUS.md, CLAUDE.md, README.md +25 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_RC_LOG_BUDGET | avra_runtime.c, avra_settings.h, declared.av +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_RC_REASONS | avra_settings.h, declared.av, memory.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_READS_DIR | avra_settings.h, declared.av, named.av +2 | not config | — | a test fixture's name |
| AVRA_READS_PHASE | avra_settings.h, declared.av, named.av +2 | not config | — | a test fixture's name |
| AVRA_REATTACH_S | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RECLAIM_FREE_GB | reclaim.sh, reclaim_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RECLAIM_SCRIPT | reclaim_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RELEASE_API | wisp (shim) | internal | merge: wisp flag | the shim's reads; `wisp release publish --api` |
| AVRA_REMOTE_SCRIPT | sprite-lib.sh, sprite-remote.sh, sprite_remote_test.sh +2 | internal | merge: wisp flag | read by tools alone |
| AVRA_RT |  | not config | — | a C macro, enum or guard |
| AVRA_RT_F64 | avra_rt.h, runtime_header.av, runtime_header_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_H | avra_rt.h, runtime_header.av, runtime_header_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_HOST | avra_rt.h, ffi.c, runtime_header.av | not config | — | a C macro, enum or guard |
| AVRA_RT_I32 | avra_rt.h, runtime_header.av, runtime_header_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_I64 | avra_rt.h, runtime_header.av, runtime_header_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_LABEL | avra_rt.h, runtime_header.av | not config | — | a C macro, enum or guard |
| AVRA_RT_POINTER | avra_rt.h, runtime_header.av, runtime_header_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_PTR | avra_rt.h, runtime_header.av, runtime_header_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_SET | process_adversarial_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_SPELLED | avra_rt.h, runtime_header.av | not config | — | a C macro, enum or guard |
| AVRA_RT_TEXT | avra_rt.h, runtime_header.av | not config | — | a C macro, enum or guard |
| AVRA_RT_U32 | avra_rt.h, runtime_header.av, runtime_header_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_VOID_SEAT | avra_rt.h, runtime_header.av, runtime_header_test.av | not config | — | a C macro, enum or guard |
| AVRA_RUN | sprite-remote.sh, sprite_remote_test.sh, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RUNTIME_H | avra_runtime.h | not config | — | a C macro, enum or guard |
| AVRA_RUN_FLOOR_MB | sprite-remote.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SAMPLE | CLAUDE.md, watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SAMPLE_AFTER | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SAMPLE_FILE | CLAUDE.md, watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SCHED_PATH | avra_fiber.c, avra_settings.h, declared.av +3 | internal | merge: settings.debug | runtime instrument |
| AVRA_SCHED_RUNS | avra_fiber.c, avra_fiber.h, avra_settings.h +5 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_SCHED_SEED | DOGFOODING.md, avra_fiber.c, avra_fiber.h +7 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_SCOPE_IDS | avra_fiber.c, avra_runtime.c, avra_runtime.h +2 | not config | — | a C macro, enum or guard |
| AVRA_SEED_BEHIND | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SET |  | not config | — | a C macro, enum or guard; new since d7cd84d9 |
| AVRA_SETTINGS_H | projected.av, avra_settings.h | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_SETTINGS_TEST_SWITCH | settings_test.c | not config | — | a C macro, enum or guard; new since d7cd84d9 |
| AVRA_SHARED_KILL_AT | avra_cores.c, avra_settings.h, declared.av +2 | internal | merge: settings.debug | runtime instrument |
| AVRA_SHARED_TRAP_AT | avra_cores.c, avra_settings.h, declared.av +2 | internal | merge: settings.debug | runtime instrument |
| AVRA_SHARE_UNMERGED | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_SIGN_TABLES | sig_restore_attack.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SITES_ELF_SECTION | avra_box.h, flow_test.c, llvm_wrapper.c | not config | — | a C macro, enum or guard |
| AVRA_SITES_MACHO_SECTION | avra_box.h, avra_fiber.c, flow_test.c +1 | not config | — | a C macro, enum or guard |
| AVRA_SITES_MACHO_SEGMENT | avra_box.h, avra_fiber.c, flow_test.c +1 | not config | — | a C macro, enum or guard |
| AVRA_SLABS | avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_SLOTS_MAX | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SLOT_ASKER | avra_runtime.h | not config | — | a C macro, enum or guard |
| AVRA_SLOT_CTX | avra_fiber.c, avra_runtime.c, avra_runtime.h +2 | not config | — | a C macro, enum or guard |
| AVRA_SLOT_DIR | avra_settings.h, compile_slots.sh, declared.av +2 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_SLOT_FLOW | avra_runtime.h | not config | — | a C macro, enum or guard |
| AVRA_SLOT_HEARD | avra_runtime.c, avra_runtime.h, interp_tasks.av | not config | — | a C macro, enum or guard |
| AVRA_SLOT_KEYS | avra_runtime.c, avra_runtime.h | not config | — | a C macro, enum or guard; new since d7cd84d9 |
| AVRA_SLOT_LANDED | avra_runtime.c, avra_runtime.h | not config | — | a C macro, enum or guard; new since d7cd84d9 |
| AVRA_SLOT_MB | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SOUNDNESS | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_SOUND_CHECK | Makefile, avra_settings.h, check_program.av +7 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_SPEED_BIN | speed_measure.sh, warm_edit_bench.sh, witness_warm_edit.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SPRITES | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SPRITE_CLI | sprite-lib.sh, sprite-rsh.sh, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SPRITE_HOME | sprite-remote.sh, sprite_remote_test.sh, work +1 | internal | merge: wisp flag | read by tools alone |
| AVRA_SP_EXCLUDE | work | internal | merge: wisp flag | read by tools alone |
| AVRA_SP_TREE | sp | internal | merge: wisp flag | read by tools alone |
| AVRA_STAMP_AT | avra_box.h | not config | — | a C macro, enum or guard |
| AVRA_STAMP_MASK | avra_box.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_STAMP_ONE | avra_box.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_STD_ANSWERS | Makefile, gate.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_STORE_DIR | config_adversarial_test.av | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_STORE_HOLD_MS | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_STORE_KEPT_HERE | Makefile, ab.sh, attack.sh +51 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_STORE_KILL | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_STORE_MAX_AGE_S | avra_settings.h, declared.av, named.av +2 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_STORE_MAX_MB | action.yml, avra_settings.h, declared.av +3 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_STORE_REVISIONS | action.yml, avra_settings.h, declared.av +3 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_STORE_SEAL_FRAMES | avra_settings.h, declared.av, named.av +1 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_STREAM_PIECES | http_stream_download.av, http_stream_upload.av | not config | — | a test fixture's name |
| AVRA_STRICT_EXTERN_GUARD | llvm_wrapper.c | internal | merge: settings.debug | runtime instrument |
| AVRA_SUITE_ALL | avra_settings.h, declared.av, gate.sh +8 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_SURELY_UNSET_NAME | inherit_env.av | not config | — | a test fixture's name |
| AVRA_SYM | avra_fiber.c | not config | — | a C macro, enum or guard |
| AVRA_SYNC_S | work | internal | merge: wisp flag | read by tools alone |
| AVRA_SYNC_UNTRACKED_KB | work | internal | merge: wisp flag | read by tools alone |
| AVRA_SYS_SEARCH | Makefile, avra, avra.toml +2 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_TAG | avra_box.h, avra_hot.h, avra_runtime.c +3 | not config | — | a C macro, enum or guard |
| AVRA_TAPE_SCHEMA | tape_roots.av, taped_derive.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_TARGET_CACHE | llvm_wrapper.c | not config | — | a C macro, enum or guard |
| AVRA_TASKS_DIR | avra_fiber.c, avra_settings.h, declared.av +4 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_TASKS_DIR_NEXT | tasks_door_test.c | not config | — | a test fixture's name |
| AVRA_TASK_SLOTS | avra_fiber.c, avra_runtime.c, avra_runtime.h | not config | — | a C macro, enum or guard |
| AVRA_TICK_US | avra_fiber.c, avra_settings.h, declared.av +1 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_TIMER_TURNS | avra_fiber.c, avra_fiber.h, avra_settings.h +4 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_TOKEN | config_adversarial_test.av | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_TOKEN_FILE | config_adversarial_test.av | internal | merge: wisp flag | new since d7cd84d9 |
| AVRA_TOOLS_COMPILER | wisp | internal | delete | a deprecated alias `./wisp` reads; `--compiler` replaced it (train48) |
| AVRA_TRAP_TRACE | avra_runtime.c, avra_settings.h, declared.av +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_TYPE_MEMO_CHECK | avra_settings.h, declared.av, named.av +2 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_UNWIND_CAP | avra_fiber.c, avra_runtime.c, avra_unwind.h +1 | not config | — | a C macro, enum or guard |
| AVRA_UNWIND_H | avra_unwind.h | not config | — | a C macro, enum or guard |
| AVRA_VERDICT_DIR | avra_settings.h, declared.av, named.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_VERIFY_LLVM | avra_settings.h, declared.av, gate.sh +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_WAKE_S | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WALL_API | ci_wall.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WATCH_HELD | attack.sh, avra, defects.av +10 | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_WATCH_TRACE | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WAVE_ALONE | avra_settings.h, declared.av, layer_check.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_WITNESS_LOG | witness_warm_edit.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WITNESS_TIMES | witness_machine_store.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WORDS_NAMED | avra_platform.h | not config | — | a C macro, enum or guard; new since d7cd84d9 |
| AVRA_WORDS_SECTION | avra_platform.h | not config | — | a C macro, enum or guard; new since d7cd84d9 |
| AVRA_WORK_AHEAD_CORES | avra_settings.h, declared.av, named.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_WORK_AHEAD_OFF | avra_settings.h, cost.sh, cutoff_witness.sh +9 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_WORLD_LIB | world_test.av | not config | — | a test fixture's name |
| AVRA_X | hand_reads_test.av, inherit_env.av, inputs.py +2 | not config | — | a test fixture's name |
| AVRA_Y | inherit_env.av | not config | — | a test fixture's name |

## cli commands (packages/cli/src/commands)

| Command / file | Class | Action | Note |
|---|---|---|---|
| attack | internal | merge: oracle attack |  |
| build | user | keep |  |
| cache | user | keep | `clean` is user; `families` moves to census |
| census | internal | merge: census |  |
| check | user | keep |  |
| check_program.av | user | keep | support of check |
| db | user | keep | LEAD LISTED IT TO MOVE: `db diff` is the ORM's migration plan, a user verb |
| dev | user | keep |  |
| dev_backend.av | user | keep | support of dev |
| diagnostics | user | merge: avra docs | the error index; `docs <code>` already looks one up |
| disk_host.av | user | keep | support |
| docs | user | keep |  |
| emit | user | keep | P7; ask lead: or `explain --llvm` |
| expand | user | keep | P7: generated declarations |
| explain | user | keep | P7: the layer's answers, inspectable |
| fix | user | keep |  |
| fix_program.av | user | keep | support of fix |
| fmt | user | keep |  |
| grammar | internal | merge: census grammar | prints the assembled grammar; was `language` |
| idiom_baseline.av | internal | merge: idioms | `check --baseline` moves to `wisp idioms` |
| ir | user | keep | P7; ask lead: or `explain --ir` |
| licences | internal | merge: keepers licences |  |
| lowered.av | internal | merge: census lowered | support file of ir/emit/explain |
| mod.av | user | keep | support |
| new | internal | merge: wisp new | scaffolds a compiler feature / IR instruction |
| parsers | internal | merge: keepers parser |  |
| process | user | keep | a package's declared tools |
| refuses.av | user | keep | support file of test |
| repr | internal | merge: census repr |  |
| rules | internal | merge: idioms rules | the gate reads its JSON |
| run | user | keep |  |
| runtime_header | internal | merge: keepers rt-header |  |
| runtime_namespace | internal | merge: keepers rt-ns |  |
| settled | internal | merge: census settled |  |
| shared.av | user | keep | support |
| std_answers.av | internal | merge: seed std-answers | support file |
| tapes | internal | merge: census tapes |  |
| tasks | user | keep | a running process's tasks |
| test | user | keep |  |
| trace | user | keep | reads a flow trace a user program wrote |
| voices | internal | merge: voices |  |
| writes | internal | merge: census writes |  |

