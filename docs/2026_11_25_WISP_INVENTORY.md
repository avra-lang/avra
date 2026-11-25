# WISP INVENTORY — every internal entry point, classed

**Base:** `origin/program` at `d7cd84d9`. **Measured** by a token index over Makefile, `.github/`, `tools/`, `packages/`, `runtime/`, `backend/`, the shims and CLAUDE.md/README/DOGFOODING (docs/ excluded as callers). A caller is a Makefile recipe or prerequisite, a keeper set (`KEEPERS_*`), a workflow, another tool, a package source, or the shim. `witness_*.sh` and `*_test.sh` are called by `tool_witnesses.sh`, which derives them by glob.

**Class:** `user` = a person building or using Avra reaches it; `internal` = the repo's own machinery; `not config` = an `AVRA_` token that is no setting (a C macro, guard, enum or fixture name).

**Corrected at S1** (each delete was re-checked against its callers before it went): 4 delete rows were live and are re-classed below; the 7 Sprite rows wait for `work`, which still sources them; `tools-suite` died with the move. The counts above are the first measurement.

**Action:** `keep` stays where it is; `merge: <verb>` becomes that wisp verb (or a flag/setting) and the old path is deleted in the same change; `delete` is dead or superseded.

## Counts

| Surface | Total | By class | By action |
|---|---|---|---|
| Make targets | 160 | internal 155, user 5 | merge 138, keep 14, delete 8 |
| tools/ entries | 299 | internal 299 | merge 277, delete 17, keep 5 |
| `AVRA_*` names | 270 | internal 153, not config 73, user 44 | merge 150, — 73, keep 44, delete 3 |
| cli command files | 42 | user 25, internal 17 | keep 24, merge 18 |


The ticket's figures (154 / 267 / 247 / 43) were taken on an earlier tree; these are this tree's. `tools/` counts top-level entries (files and directories); 4603 files lie beneath them, fixtures mostly.


### Where the merges land (rows per wisp verb, all four surfaces)

| Verb | Rows |
|---|---|
| oracle | 149 |
| keepers | 118 |
| a flag of its verb | 75 |
| settings.debug | 68 |
| cost | 59 |
| census | 30 |
| gate | 23 |
| tree | 14 |
| fixtures | 9 |
| seed | 8 |
| shim | 8 |
| idioms | 6 |
| work | 5 |
| voices | 5 |
| the child runner (every spawn) | 3 |
| dies with its callers | 1 |
| avra docs (user) | 1 |
| new | 1 |


### Findings worth a decision

- **`avra-tools` already is wisp.** `tools/avra.toml` + `tools/src/` is an Avra program on `@std/cli` (six commands: `pr_mode`, `ci_path_gate`, `hooks_released`, `host_events`, `families`, `suites`), built by MAIN's compiler and published under `tools_key.sh`'s key (`tools/avra_tools.sh`). Wisp is that package renamed, not a second one.
- **Two dead env names still set everywhere:** `AVRA_PROGRAM` (23 tool sites) and `AVRA_PROGRAM_NET` (24) have no reader since the old path died at `b6dce5f`. `AVRA_ALIAS_EMIT` lives in CLAUDE.md only.
- **Three gates:** `make gate` (Makefile, 30 prerequisites), `tools/gate.sh` (slices, `gate.yml`) and `tools/gate_changed.sh` (`checks.yml`). One verb, three modes.
- **Nine keeper sets** (`KEEPERS`, `_ALONE`, `_A`, `_A1`, `_A2`, `_B`, `_WASM`, `_STATIC`, `_PR`) are Make variables that `keepers-static`/`keepers-pr` police with `filter-out`. They are a registry, so they become one table with a set column.
- **Sixteen `-accept` targets**, one per ratchet. They become one flag, `--accept`, on the ratchet's verb.
- **Sprites are retired** (owner 11-02), yet `tools/work` holds 112 `sprite` lines and five `sprite-*` scripts stand. They are deleted when `work` moves.
- **Dead wrappers:** `make check/run/ir/emit/build-native` wrap `./avra <cmd> $(FILE)` and nothing calls them. (`obj_gone_attack.sh` and `object_gone_attack.sh` read alike, but they are two different attacks, and both run.)
- **Self-test-only tools** (`digest_diff.py`, `parse_diff.py`): only their own fixtures run them. The lead decides whether each is an instrument or dead.
- **The `_OFF` / `_CHECK` switches** (`AVRA_HELD_ITEMS_OFF`, `AVRA_FOLD_CHECK`, `AVRA_HELD_QUESTIONS_CHECK`, … 68 rows of `settings.debug`) are the "gated" half of gated==ungated. Each becomes a reading in the oracle, not a variable a human sets.


## Make targets

| Target | Called by | Class | Action | Note |
|---|---|---|---|---|
| hash-door | KEEPERS_A1 | internal | merge: keepers |  |
| wasm-runtime | tools; recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| wasm-packages | tools; recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| wasm-check | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-seam | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-tasks-mutations | KEEPERS_WASM | internal | merge: oracle | an agreement or refusal case |
| wasm-host-check | ci; KEEPERS_WASM | internal | merge: keepers |  |
| wasm-refuses | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-cache | KEEPERS_WASM | internal | merge: keepers |  |
| wasm-size | none | internal | merge: census | no caller |
| wasm-body | none | internal | merge: keepers | "keeper owed" and run by nothing |
| wasm-size-guard | KEEPERS_WASM | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wasm-routes-size | KEEPERS_WASM | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wasm-size-accept | tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wasm-archive | KEEPERS_WASM | internal | merge: keepers |  |
| objects | ci; tools | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| seed | tools; recipe | internal | merge: seed |  |
| recover | dep of bootstrap; tools; recipe | user | keep: Make | builds files; runs before any compiler exists |
| bootstrap | tools; recipe | user | keep: Make | builds files; runs before any compiler exists |
| ready | recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| avra | ci; dep of install,libs; tools; recipe | user | keep: Make | builds files; runs before any compiler exists |
| compiler-files | tools | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| compiler | ci; tools | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| try | tools; recipe | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| edit-loop | none | internal | merge: cost warm-edit | no caller |
| install | tools; recipe | user | keep: Make | builds files; runs before any compiler exists |
| sprite | recipe | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite-check | tools | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sweep | none | internal | merge: tree sweep |  |
| test | tools; recipe | internal | merge: gate --suites |  |
| runtime-tests | dep of gate; KEEPERS_ALONE | internal | merge: keepers |  |
| runtime-mutations | KEEPERS_ALONE; tools | internal | merge: oracle | an agreement or refusal case |
| compiler-key | tools | internal | merge: keepers |  |
| flow-trace | KEEPERS_A2; tools | internal | merge: oracle | an agreement or refusal case |
| traps | dep of gate; KEEPERS_A2; tools | internal | merge: oracle | an agreement or refusal case |
| compile-slots | dep of gate; KEEPERS_A2 | internal | merge: oracle | an agreement or refusal case |
| llvm-libs | dep of gate | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| db-corpus | dep of cache-attacks-w | internal | merge: oracle | an agreement or refusal case |
| cache-attacks | dep of gate | internal | merge: oracle | an agreement or refusal case |
| store-attacks | none | internal | merge: oracle | an agreement or refusal case |
| cache-attacks-b | dep of cache-attacks | internal | merge: oracle | an agreement or refusal case |
| cache-attacks-b1 | dep of cache-attacks-b | internal | merge: oracle | an agreement or refusal case |
| cache-attacks-b2 | dep of cache-attacks-b | internal | merge: oracle | an agreement or refusal case |
| ahead-edit-attack | KEEPERS_B | internal | merge: oracle | an agreement or refusal case |
| held-store-attack | KEEPERS_B | internal | merge: oracle | an agreement or refusal case |
| cutoff-witness | KEEPERS_B | internal | merge: oracle | an agreement or refusal case |
| heir-save-attack | KEEPERS_B | internal | merge: oracle | an agreement or refusal case |
| share-merge-attack | KEEPERS_B | internal | merge: oracle | an agreement or refusal case |
| beside-attack | KEEPERS_B | internal | merge: oracle | an agreement or refusal case |
| wave-share-attack | KEEPERS_B | internal | merge: oracle | an agreement or refusal case |
| code-hash-attacks | ci | internal | merge: oracle | an agreement or refusal case |
| object-gone-attack | none | internal | delete (S1) | no caller; its script also runs in `cache-attacks-b2` |
| census | tools; recipe | internal | merge: census | a report, never a verdict |
| stems | dep of gate; KEEPERS_A1; tools | internal | merge: keepers |  |
| clean | tools; recipe | user | keep: Make | builds files; runs before any compiler exists |
| seed-check | ci; dep of gate; tools | internal | merge: seed |  |
| check | none | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| run | STORE_WITNESSES; tools | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| ir | none | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| emit | none | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| build-native | none | internal | delete | a wrapper over `./avra <cmd> $(FILE)`; nothing calls it |
| libscope | KEEPERS_B | internal | merge: keepers |  |
| libs | ci; dep of libscope,test; tools | internal | keep: Make | a file in build/; wisp asks Make for files, never the reverse |
| suites | ci; dep of test; KEEPERS_B,KEEPERS_STATIC | internal | merge: gate --suites |  |
| cited | dep of gate; KEEPERS_B,KEEPERS_STATIC | internal | merge: keepers |  |
| http-cites | KEEPERS_B,KEEPERS_STATIC | internal | merge: keepers |  |
| dogfooding-rules | dep of gate; KEEPERS_B,KEEPERS_PR | internal | merge: idioms |  |
| rule-examples | KEEPERS_B | internal | merge: idioms |  |
| families-left | dep of gate; KEEPERS_B,KEEPERS_STATIC | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| read-lists | KEEPERS_A2 | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| layers | dep of gate; KEEPERS_B,KEEPERS_STATIC | internal | merge: keepers |  |
| speed-note | KEEPERS_B,KEEPERS_STATIC | internal | merge: keepers |  |
| libs-self-test | KEEPERS_B,KEEPERS_STATIC | internal | merge: fixtures |  |
| hooks-released | dep of gate; KEEPERS_B,KEEPERS_STATIC | internal | merge: keepers |  |
| tools-suite | KEEPERS_B | internal | delete (S1) | `./avra test tools`; wisp joins the derived suites under packages/ |
| inputs | KEEPERS_B | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| clock-holds | KEEPERS | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| inputs-accept | tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| whole-reads | KEEPERS_B | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| whole-reads-accept | tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| read-cost | KEEPERS_A2 | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| speed-ratchet | KEEPERS_A1,KEEPERS_PR; tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| speed-accept | ci | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| wall-ratchet | none | internal | merge: cost | no caller; folds into the speed ratchet |
| wall-accept | recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| cost | KEEPERS_A1; tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| cost-accept | tools; recipe | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| warm-edit | KEEPERS_A2,KEEPERS_PR; tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| warm-accept | none | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| work-accept | tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| idioms | dep of gate; tools | internal | merge: idioms |  |
| idioms-accept | none | internal | merge: idioms |  |
| fmt-lossless | dep of gate; KEEPERS_A1; tools | internal | merge: keepers |  |
| attack | dep of gate; KEEPERS_B,KEEPERS_PR | internal | merge: oracle | an agreement or refusal case |
| defects | KEEPERS_B | internal | merge: keepers |  |
| vocab | dep of gate; KEEPERS_B,KEEPERS_STATIC | internal | merge: keepers |  |
| ui-host | dep of gate; tools | internal | merge: keepers |  |
| host-events | KEEPERS_STATIC; tools | internal | merge: keepers |  |
| ui-host-test | dep of gate; tools | internal | merge: keepers |  |
| ui-fuzz | none | internal | merge: oracle | an agreement or refusal case |
| exact-patches | none | internal | merge: oracle | an agreement or refusal case |
| ui-board | dep of gate; tools | internal | merge: keepers |  |
| dev-server | none | internal | merge: keepers |  |
| ui-browser | ci; dep of gate; tools | internal | merge: keepers |  |
| ui-browser-skip | KEEPERS_STATIC | internal | merge: keepers |  |
| layout-oracle | none | internal | merge: oracle | an agreement or refusal case |
| fingerprints | dep of gate; KEEPERS_B,KEEPERS_STATIC | internal | merge: keepers |  |
| footprint | KEEPERS_PR; tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| footprint-accept | tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| flow-gate | ci; tools | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| flow-gate-accept | none | internal | merge: cost | a ratchet; `-accept` is its `--accept` |
| tick-object | none | internal | merge: keepers |  |
| no-threads | none | internal | merge: keepers |  |
| keepers | tools; recipe | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-alone | ci | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-a | ci; tools | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-a1 | none | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-a2 | none | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-b | none | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-wasm | none | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| tool-witnesses | dep of gate; recipe | internal | merge: fixtures |  |
| cache-attacks-w | dep of cache-attacks | internal | merge: oracle | an agreement or refusal case |
| store-witnesses | dep of cache-attacks-w; tools; recipe | internal | merge: oracle | an agreement or refusal case |
| ci-invariants | KEEPERS_STATIC; tools | internal | merge: keepers |  |
| ci-verdict | KEEPERS_STATIC | internal | merge: keepers |  |
| pr-watcher | KEEPERS_STATIC | internal | merge: keepers |  |
| pipeline-doc | KEEPERS_STATIC | internal | merge: keepers |  |
| vendored-fixture | KEEPERS_STATIC | internal | merge: keepers |  |
| tail-status | KEEPERS_STATIC | internal | merge: keepers |  |
| pipeline-status | none | internal | merge: work status |  |
| keepers-static | ci; tools | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| keepers-pr | none | internal | merge: keepers --set <name> | a set is a row of the keeper registry |
| codecs | dep of gate; KEEPERS_A2; tools | internal | merge: keepers |  |
| codecs-static | ci; dep of codecs | internal | merge: keepers |  |
| rt-header | dep of gate; KEEPERS_B,KEEPERS_PR; tools | internal | merge: keepers |  |
| rt-ns | dep of gate; KEEPERS_B,KEEPERS_PR; tools | internal | merge: keepers |  |
| pool-check | KEEPERS_B | internal | merge: keepers |  |
| parser | dep of gate; KEEPERS_B,KEEPERS_PR | internal | merge: keepers |  |
| witnesses | dep of gate; KEEPERS_B,KEEPERS_PR; tools | internal | merge: keepers |  |
| voices | KEEPERS_B; tools | internal | merge: voices |  |
| voices-accept | recipe | internal | merge: voices |  |
| externs | dep of gate; KEEPERS_B,KEEPERS_STATIC; tools | internal | merge: keepers |  |
| workflows-yaml | KEEPERS_STATIC | internal | merge: keepers |  |
| trap-marks | KEEPERS_B | internal | merge: keepers |  |
| witness | dep of gate; KEEPERS_A2 | internal | merge: oracle | an agreement or refusal case |
| gate | ci; tools; recipe | internal | merge: gate |  |
| tested | dep of gate | internal | merge: gate --suites |  |
| native-check | none | internal | merge: oracle | an eval==native case |
| bench | none | internal | merge: census | a report, never a verdict |
| bench-collections | none | internal | merge: census | a report, never a verdict |
| flow-bench | tools | internal | merge: census | a report, never a verdict |
| flow-g1 | tools | internal | merge: census | a report, never a verdict |
| flow-probes | none | internal | merge: census | a report, never a verdict |
| h2spec | ci; KEEPERS_B; tools | internal | merge: keepers |  |
| census-types | recipe | internal | merge: census | a report, never a verdict |
| sizes | tools; recipe | internal | merge: census | a report, never a verdict |
| fuzz | none | internal | merge: oracle | an agreement or refusal case |
| fuzz-http | tools | internal | merge: oracle | an agreement or refusal case |
| soak-http | tools | internal | merge: oracle | an agreement or refusal case |
| scaffold-check | none | internal | merge: keepers |  |


## tools/

| Entry | Called by | Class | Action | Note |
|---|---|---|---|---|
| affected_packages.sh | checks.yml, gate_changed.sh, work | internal | merge: gate |  |
| ahead_edit_attack.sh | Makefile | internal | merge: oracle |  |
| attack.baseline | Makefile, attack.sh, attack.av | internal | merge: oracle |  |
| attack.sh | Makefile, checks.yml, ahead_edit_attack.sh +46 | internal | merge: oracle |  |
| avra.toml | Makefile, affected_packages.sh, ahead_edit_attack.sh +221 | internal | keep: wisp package | avra-tools IS wisp; renamed, moved to packages/wisp |
| avra_tools.sh | Makefile, checks.yml, ci_invariants.py +1 | internal | merge: ./wisp shim | its resolution (main's compiler, keyed) becomes the shim |
| avsrc.py | Makefile | internal | merge: keepers |  |
| batch.sh | batch_test.sh, work | internal | merge: work |  |
| batch_test.sh | Makefile | internal | merge: fixtures |  |
| bench/ | Makefile, checks.yml, census_types.sh +18 | internal | merge: census |  |
| bench.sh | Makefile, ci_invariants.py | internal | merge: census |  |
| beside_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| bounded.sh | Makefile, checks.yml, gate.sh +1 | internal | merge: gate |  |
| calib.py | Makefile, action.yml, speed_note.sh | internal | merge: cost |  |
| capped.sh | Makefile, db06_pkgc_witness.sh, dev_server_check.sh +6 | internal | merge: wisp runner | every child wisp spawns is capped and bounded; one definition |
| carried_store_attack.sh | gate.sh | internal | merge: oracle |  |
| case_leftover_attack.sh | gate.sh | internal | merge: oracle |  |
| census.sh | Makefile | internal | merge: census |  |
| census_compiler.sh | census.sh, cost.sh, cost_stable.sh +1 | internal | merge: census |  |
| census_types.sh | Makefile | internal | merge: census |  |
| chunk_owed_attack.sh | gate.sh | internal | merge: oracle |  |
| ci_dup_run.py | Makefile, checks.yml, ci_invariants.py | internal | merge: gate |  |
| ci_invariants.py | Makefile | internal | merge: keepers |  |
| ci_verdict.sh | Makefile, checks.yml | internal | merge: gate |  |
| ci_wall.sh | Makefile, checks.yml, speed.budget +1 | internal | merge: gate |  |
| cited.allow | cited.py, pipeline_doc.allow, pipeline_doc.py | internal | merge: keepers |  |
| cited.py | Makefile | internal | merge: keepers |  |
| clock_holds.py | Makefile | internal | merge: cost |  |
| closure_fold_attack.sh | Makefile | internal | merge: oracle |  |
| closure_gather_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| code_hash_attacks.sh | Makefile | internal | merge: oracle |  |
| codecs.py | Makefile, checks.yml, ci_invariants.py | internal | merge: keepers |  |
| compile_slots.sh | Makefile | internal | merge: oracle |  |
| compiler_paths.sh | action.yml, checks.yml, lane-run.yml +6 | internal | merge: gate |  |
| compiler_release.py | action.yml, checks.yml, avra_tools.sh +8 | internal | merge: gate |  |
| corpus_ir.sh | — | internal | merge: census | NO CALLER |
| cost.baseline | Makefile, gate.yml, cost.sh +2 | internal | merge: cost |  |
| cost.candidates | cost_ratchet.py | internal | merge: cost |  |
| cost.sh | Makefile, gate.yml, census_compiler.sh +5 | internal | merge: cost |  |
| cost.verdicts | cost.sh, cost_ratchet.py | internal | merge: cost |  |
| cost_ratchet.py | Makefile, gate.yml, cost.baseline +4 | internal | merge: cost |  |
| cost_stable.sh | cost_ratchet.py | internal | merge: cost |  |
| cutoff.ceiling | Makefile, cutoff_witness.sh | internal | merge: cost |  |
| cutoff_witness.sh | Makefile, cutoff.ceiling | internal | merge: oracle |  |
| db06_pkgc_witness.sh | — | internal | delete | a finished campaign's probe |
| db06_step5_witness.sh | store_attacks.sh | internal | merge: oracle | run by store_attacks.sh |
| db06_step6_rebuild.sh | store_attacks.sh | internal | merge: oracle | cited by store_attacks.sh |
| db_corpus.sh | Makefile | internal | merge: oracle |  |
| db_measure/ | Makefile, census.sh, warm_edit_bench.sh | internal | merge: census |  |
| defects/ | Makefile, checks.yml, gate.sh +23 | internal | merge: keepers |  |
| defects.py | Makefile | internal | merge: keepers |  |
| defects_previous.py | Makefile, checks.yml | internal | merge: keepers |  |
| dep_audit.sh | audit_switch_test.av, bypass.av | internal | merge: tree |  |
| dep_audit.tsv | dep_audit.sh | internal | merge: tree |  |
| dep_tests_listing_attack.sh | Makefile | internal | merge: oracle |  |
| derive_members_witness.sh | gate.sh | internal | merge: oracle |  |
| dev_server_check.sh | Makefile | internal | merge: keepers |  |
| digest_diff.py | — | internal | merge: oracle | NO CALLER |
| docs_cache_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| dom_page.sh | — | internal | merge: keepers | NO CALLER |
| exact-patches/ | Makefile | internal | merge: oracle |  |
| externs.py | Makefile, llvm_emit.av | internal | merge: keepers |  |
| failed_tail_test.sh | — | internal | merge: fixtures |  |
| families.ceiling | Makefile, families.av | internal | merge: cost |  |
| file_module_attack.sh | Makefile | internal | merge: oracle |  |
| fingerprints.py | Makefile | internal | merge: keepers |  |
| flow_bench/ | Makefile | internal | merge: census |  |
| flow_trace/ | layer_sites_attack.sh | internal | merge: oracle |  |
| flow_trace_engines.sh | Makefile, traced_fd.av, traced_answer.av +3 | internal | merge: oracle |  |
| flow_trace_swap_attack.sh | gate.sh | internal | merge: oracle |  |
| fmt_changed.sh | gate.sh, witness_fmt_changed.sh | internal | merge: keepers |  |
| fmt_lossless.sh | Makefile | internal | merge: keepers |  |
| fmt_roundtrip.sh | fmt_lossless.sh | internal | merge: keepers |  |
| footprint/ | Makefile, checks.yml, libs.py +7 | internal | merge: cost |  |
| footprint.baseline | gate.py, footprint.py | internal | merge: cost |  |
| footprint.py | Makefile | internal | merge: cost |  |
| frame_place_attack.sh | gate.sh | internal | merge: oracle |  |
| fuzz.sh | Makefile | internal | merge: oracle |  |
| fuzz_http.sh | Makefile, main.av | internal | merge: oracle |  |
| gate/ | Makefile, action.yml, checks.yml +133 | internal | merge: keepers |  |
| gate.sh | gate.yml | internal | merge: gate |  |
| gate_changed.sh | Makefile, checks.yml, pipeline_doc.py +1 | internal | merge: gate |  |
| gate_receipt.sh | Makefile | internal | merge: gate |  |
| gathered_cache_attack.sh | Makefile | internal | merge: oracle |  |
| h2spec/ | Makefile, Dockerfile, install_h2spec.sh | internal | merge: keepers |  |
| h2spec.sh | Makefile | internal | merge: keepers |  |
| hand_down.sh | action.yml, checks.yml, orders.yml +1 | internal | merge: gate |  |
| heir_save_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| held_store_attack.sh | Makefile | internal | merge: oracle |  |
| hold_sweep.sh | hold_refusal_test.av | internal | delete | dies with the hold |
| hooks/ | hooks_released.av, hooks_released_test.av, store_attacks.sh +14 | internal | keep: data | git hooks; their bodies call wisp |
| hooks_pre_commit_check.sh | Makefile | internal | merge: keepers |  |
| host_fn_edit_attack.sh | Makefile | internal | merge: oracle |  |
| host_key.sh | speed_measure.sh, speed_ratchet.py, warm_edit_bench.sh +1 | internal | merge: cost |  |
| http_cites.py | Makefile | internal | merge: keepers |  |
| idioms.baseline | Makefile, explain_proof.sh, rules_proof.sh +4 | internal | keep: data of idioms |  |
| impl_held_attack.sh | Makefile | internal | merge: oracle |  |
| inputs.baseline | inputs.py | internal | merge: cost |  |
| inputs.py | Makefile, licenses.av | internal | merge: cost |  |
| jspi_node.sh | wasm-check.sh, wasm-host-check.sh, wasm-tasks-mutations.sh | internal | merge: keepers |  |
| keepers_loop.sh | Makefile | internal | merge: gate |  |
| ladder.sh | Makefile, action.yml, ci_invariants.py +2 | internal | merge: seed |  |
| layer_sites_attack.sh | gate.sh | internal | merge: oracle |  |
| layers.py | Makefile | internal | merge: tree |  |
| layout-oracle/ | Makefile, checks.yml, ci_invariants.py +7 | internal | merge: oracle |  |
| layout_oracle.sh | Makefile, checks.yml, orders.yml +2 | internal | merge: oracle |  |
| layout_oracle_absent_test.sh | Makefile, checks.yml | internal | merge: oracle |  |
| layout_oracle_boundary_test.sh | Makefile, checks.yml | internal | merge: oracle |  |
| layout_oracle_own_term_test.sh | Makefile, checks.yml | internal | merge: oracle |  |
| lib/ | Makefile, Dockerfile, gate.yml +142 | internal | merge: (dies with its callers) | shell helpers shared by scripts |
| libs.py | Makefile, stems.sh, work +2 | internal | merge: tree |  |
| libscope.sh | Makefile | internal | merge: tree |  |
| licence_families.py | — | internal | merge: keepers | NO CALLER |
| link_cache_attack.sh | Makefile | internal | merge: oracle |  |
| llvm_link.py | Makefile, llvm_link.sh, avra.toml | internal | merge: tree |  |
| llvm_link.sh | Makefile, llvm_link.py | internal | merge: tree |  |
| manifest_objects.sh | Makefile, avra_tools.sh, db06_pkgc_witness.sh +4 | internal | merge: tree objects | FIRST VERB; the compiler's manifest.av is the reader |
| memcap.sh | Makefile, checks.yml, census.sh +8 | internal | merge: wisp runner | every child wisp spawns is capped and bounded; one definition |
| memsites.py | ab.sh, explain_cost.sh | internal | merge: census |  |
| moved_tree_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| names_attack.sh | Makefile | internal | merge: oracle |  |
| obj_gone_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| object_gone_attack.sh | Makefile | internal | merge: oracle | a different attack from obj_gone_attack.sh; run by cache-attacks-b2 |
| package_swap_attack.sh | Makefile | internal | merge: oracle |  |
| packages.sh | checks.yml, orders.yml | internal | merge: gate |  |
| page-closure/ | witness_page_closure.sh | internal | merge: oracle |  |
| parse_diff.py | — | internal | merge: oracle | NO CALLER |
| path_leak_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| pipeline_doc.allow | Makefile, pipeline_doc.py | internal | merge: keepers |  |
| pipeline_doc.py | Makefile | internal | merge: keepers |  |
| pipeline_status.py | Makefile | internal | merge: keepers |  |
| pool/ | Makefile, avra.toml, main.av +56 | internal | merge: keepers |  |
| pool_check.sh | Makefile | internal | merge: keepers |  |
| pr_body.sh | checks.yml, speed_note.sh | internal | merge: gate |  |
| pr_mode.py | Makefile, checks.yml | internal | merge: gate |  |
| pr_watcher.py | Makefile, pr-watcher.yml, ci_invariants.py +1 | internal | merge: keepers |  |
| print_mix_attack.sh | Makefile | internal | merge: oracle |  |
| profile.sh | Makefile | internal | merge: census |  |
| program-doors/ | witness_program_doors.sh | internal | merge: oracle |  |
| program-doors.expected/ | witness_program_doors.sh | internal | merge: oracle |  |
| program-fixes/ | witness_program_fixes.sh | internal | merge: oracle |  |
| program-ledger/ | witness_program_ledger.sh | internal | merge: oracle |  |
| program-refusals/ | case_leftover_attack.sh, externs.py, witness_program_needs.sh +3 | internal | merge: oracle |  |
| program-runs/ | witness_program_runs.sh | internal | merge: oracle |  |
| program-suites/ | root_listing_attack.sh, two_compilers_attack.sh, witness_program_suites.sh | internal | merge: oracle |  |
| program-warnings/ | gate.sh, witness_program_warnings.sh | internal | merge: oracle |  |
| program_findings.py | program_findings_gate.sh | internal | delete | holds the program layer to the old path, deleted at b6dce5f |
| program_findings_gate.sh | — | internal | delete | holds the program layer to the old path, deleted at b6dce5f |
| program_refusals_sweep.sh | — | internal | delete | holds the program layer to the old path, deleted at b6dce5f |
| program_traps.baseline | tapes.av | internal | keep: data of keepers traps |  |
| queue-witness/ | gate.sh | internal | merge: oracle |  |
| ratchet_rows.py | Makefile | internal | merge: cost |  |
| read_lists.ceiling | read_lists.py | internal | merge: cost |  |
| read_lists.py | Makefile, read_lists.ceiling | internal | merge: cost |  |
| reclaim.sh | reclaim_test.sh | internal | merge: work reclaim |  |
| reclaim_test.sh | — | internal | merge: work reclaim |  |
| reformat_lane.sh | — | internal | delete | a one-time layout migration, done |
| root_listing_attack.sh | gate.sh | internal | merge: oracle |  |
| run_wasm.mjs | witness_program_refusal.sh | internal | merge: oracle |  |
| rungs.sh | Makefile, action.yml, orders.yml +2 | internal | merge: seed |  |
| seed_guard.sh | Makefile | internal | merge: seed |  |
| seed_is_tree.sh | Makefile | internal | merge: seed |  |
| shards.py | Makefile, suite-cold.txt, suite-seconds.txt +3 | internal | merge: gate |  |
| share_merge_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| shim_guard_test.sh | — | internal | merge: fixtures |  |
| sig_restore_attack.sh | Makefile | internal | merge: oracle |  |
| soak_http.sh | Makefile | internal | merge: oracle |  |
| sources_hash.sh | Makefile, seed_guard.sh, sprite-provision.sh | internal | merge: tree |  |
| sp | yyjson.c, calls.c, wasm-tasks-mutations.sh +33 | internal | delete | the old spelling of `work run` |
| speed.baseline | — | internal | merge: cost | NO CALLER |
| speed.budget | Makefile, checks.yml, speed_ratchet.py +1 | internal | merge: cost |  |
| speed_measure.sh | Makefile, speed.budget, speed_ratchet.py | internal | merge: cost |  |
| speed_note.sh | Makefile, action.yml, calib.py +4 | internal | merge: cost |  |
| speed_note_fixtures/ | speed_note_test.sh | internal | merge: cost |  |
| speed_note_test.sh | — | internal | merge: cost |  |
| speed_ratchet.py | Makefile, checks.yml, ci_invariants.py +5 | internal | merge: cost |  |
| sprite-lib.sh | packages-dev.txt, packages.txt, sprite-remote.sh +2 | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite-provision.sh | Makefile, sprite-lib.sh, sprite-remote.sh +1 | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite-remote.sh | Makefile, ci_invariants.py, sprite-lib.sh +3 | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite-rsh.sh | work, work_test.sh | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| sprite_remote_test.sh | work_test.sh | internal | delete, with work | Sprites retired (owner 11-02); `tools/work` still sources these, so they go when `work` moves |
| src/ | Makefile, suite-seconds.txt, suite-splits.txt +611 | internal | keep: wisp package | avra-tools IS wisp; renamed, moved to packages/wisp |
| stale_imports_attack.sh | Makefile | internal | merge: oracle |  |
| stamps.sh | Makefile | internal | merge: tree |  |
| std_answers.sh | Makefile, census.sh, cost.sh +3 | internal | merge: seed std-answers |  |
| std_answers_attack.sh | gate.sh | internal | merge: oracle |  |
| std_answers_checkout_witness.sh | gate.sh | internal | merge: oracle |  |
| stems.sh | Makefile, libs.py | internal | merge: tree |  |
| step_cpu.py | Makefile, checks.yml, pr_watcher.py | internal | merge: gate |  |
| steps_test.sh | — | internal | merge: fixtures |  |
| store_attacks.sh | Makefile | internal | merge: oracle |  |
| store_baseline.sh | store_attacks.sh | internal | merge: oracle |  |
| store_bound_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| store_clean_attack.sh | Makefile | internal | merge: oracle |  |
| store_quiet_attack.sh | Makefile | internal | merge: oracle |  |
| store_reads_attack.sh | Makefile, store_reads_process_test.av | internal | merge: oracle |  |
| suites_links.sh | Makefile, suites.av | internal | merge: keepers |  |
| suspect_narrow_attack.sh | Makefile | internal | merge: oracle |  |
| symsize.py | Makefile | internal | merge: tree |  |
| tail_status.sh | Makefile | internal | merge: gate |  |
| term_width.py | — | internal | delete | a one-off probe; no caller |
| terminated.allow | externs.py | internal | merge: keepers |  |
| tick.py | Makefile | internal | merge: keepers |  |
| tls_renegotiation/ | — | internal | merge: keepers | NO CALLER |
| tls_renegotiation.sh | h2spec.sh, main.av | internal | merge: keepers |  |
| tool_witnesses.sh | Makefile | internal | merge: fixtures |  |
| tools_key.sh | checks.yml, avra_tools.sh | internal | merge: gate |  |
| traps.py | Makefile, ir.av | internal | merge: oracle |  |
| traps.sh | Makefile, externs.py, sqlite_adversarial_test.av | internal | merge: oracle |  |
| two_compilers_attack.sh | gate.sh | internal | merge: oracle |  |
| type_named_cache_attack.sh | gathered_cache_attack.sh, type_named_test.av | internal | merge: oracle |  |
| ui-bench/ | ui_bench.sh | internal | merge: census |  |
| ui-board/ | Makefile, Dockerfile, install_firefox.sh +19 | internal | merge: keepers |  |
| ui-observed/ | ui_board_browser.sh | internal | merge: keepers |  |
| ui-shown/ | ui_board_browser.sh | internal | merge: keepers |  |
| ui-warns/ | ui_board_browser.sh | internal | merge: keepers |  |
| ui_bench.sh | — | internal | merge: census | NO CALLER |
| ui_board.sh | Makefile, gate.sh, main.av | internal | merge: keepers |  |
| ui_board_browser.sh | Makefile, packages-browser.txt, checks.yml +4 | internal | merge: keepers |  |
| ui_fuzz.sh | Makefile | internal | merge: oracle |  |
| ui_host.sh | Makefile | internal | merge: keepers |  |
| ui_host_test.sh | Makefile | internal | merge: keepers |  |
| unicode_tables.py | unicode.av | internal | merge: tree |  |
| vendored_fixture.py | Makefile, std_sources.av | internal | merge: keepers |  |
| vocab.sh | Makefile | internal | merge: keepers |  |
| voices.baseline | Makefile, coverage.av | internal | merge: voices |  |
| voices_spoken.py | Makefile | internal | merge: voices |  |
| warm_edit_bench.sh | Makefile, ci_invariants.py, pipeline_doc.allow +6 | internal | merge: cost |  |
| wasm-archive.sh | Makefile | internal | merge: keepers |  |
| wasm-body.sh | Makefile | internal | merge: keepers |  |
| wasm-cache-attacks.sh | Makefile | internal | merge: oracle |  |
| wasm-check.sh | Makefile | internal | merge: keepers |  |
| wasm-fixtures/ | wasm-check.sh, wasm-tasks-mutations.sh, task_stack_test.av | internal | merge: keepers |  |
| wasm-host/ | tasks_test.js | internal | merge: keepers | NO CALLER |
| wasm-host-check.sh | Makefile, main.av, tasks_proxy_test.js +1 | internal | merge: keepers |  |
| wasm-host-objects.sh | wasm-cache-attacks.sh, wasm-check.sh | internal | merge: keepers |  |
| wasm-min/ | wasm-size-guard.sh, wasm-size.sh | internal | merge: census |  |
| wasm-node.mjs | wasm-check.sh, wasm-tasks-mutations.sh, shared.av | internal | merge: keepers |  |
| wasm-refuses/ | Makefile, README.md | internal | merge: keepers |  |
| wasm-refuses.sh | Makefile | internal | merge: keepers |  |
| wasm-routes/ | — | internal | merge: keepers | NO CALLER |
| wasm-routes-size.sh | Makefile, wasm-check.sh | internal | merge: cost |  |
| wasm-seam/ | Makefile | internal | merge: keepers |  |
| wasm-seam-check.sh | Makefile | internal | merge: keepers |  |
| wasm-size-guard.sh | Makefile, wasm-check.sh | internal | merge: cost |  |
| wasm-size.baseline | wasm-size-guard.sh | internal | merge: cost |  |
| wasm-size.sh | Makefile | internal | merge: census |  |
| wasm-tasks-mutations.sh | Makefile | internal | merge: oracle |  |
| watch.sh | Makefile, child_kept.sh, memcap.sh +2 | internal | merge: wisp runner | every child wisp spawns is capped and bounded; one definition |
| wave_share_attack.sh | Makefile, gate.sh | internal | merge: oracle |  |
| whole_reads.baseline | Makefile, whole_reads.py | internal | merge: cost |  |
| whole_reads.py | Makefile, whole_reads.baseline, licenses.av | internal | merge: cost |  |
| witness-files/ | witness_program_differential.sh | internal | merge: oracle |  |
| witness_board_dev.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_board_native.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_body_consts.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_callee_edit.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_compiler_key.sh | Makefile, gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_compiler_release.sh | compiler_release.py | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_disk_full.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_fmt_changed.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_frameless_writes.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_free_leaf.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_gate_changed.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_held_instance.sh | witness_settled_wire.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_layered_link.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_machine_store.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_page_closure.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_parallel_build.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_place_kill.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_differential.old | witness_program_differential.py, witness_program_differential.sh | internal | keep: data of its witness | the frozen golden witness_program_differential.py reads |
| witness_program_differential.py | witness_program_differential.sh | internal | merge: oracle |  |
| witness_program_differential.sh | gate.sh, main.av, witness_program_differential.py | internal | merge: oracle |  |
| witness_program_doors.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_edit.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_fixes.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_ledger.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_needs.sh | gate.sh, law_findings.av | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_refusal.sh | case_leftover_attack.sh, externs.py, gate.sh +1 | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_runs.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_suites.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_waits.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_program_warnings.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_settled_wire.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_store_broken_edit.sh | gate.sh | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_store_builders.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_store_prints.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_two_suites.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_validator_upstream_const.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_warm_edit.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_work_run.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| witness_work_wait.sh | — | internal | merge: oracle | run by tool_witnesses (derived) |
| work | Makefile, fetch_pinned.sh, packages-browser.txt +232 | internal | merge: work | the seven lane commands; its `--sprite` half deletes |
| work.budget | work_ratchet.py | internal | merge: cost |  |
| work_ratchet.py | Makefile, speed_ratchet.py, warm_edit_bench.sh +1 | internal | merge: cost |  |
| work_test.sh | sprite_remote_test.sh | internal | merge: fixtures |  |
| workflows_yaml.py | Makefile | internal | merge: keepers |  |
| wrapper_marks_attack.sh | gate.sh | internal | merge: oracle |  |
| writes_attack.sh | Makefile | internal | merge: oracle |  |


## AVRA_* names

`settings.debug` is a nested record of the compiler's one typed settings declaration (@std/config). Wisp sets those fields per reading, and nothing ambient does. `wisp flag` is a typed flag of the verb that reads it. `shim flag` is passed by argv between `./avra` and the binary.


| Name | Read in | Class | Action | Note |
|---|---|---|---|---|
| AVRA_ADDCHDIR | std_process.c, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_AHEAD_EDIT | worked_ahead.av, ahead_edit_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_AHEAD_UNPROVEN | worked_ahead.av, ahead_edit_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_ALIAS_EMIT | — | internal | delete | named in CLAUDE.md only |
| AVRA_ALIAS_LOG | avra_runtime.c, run.sh, main.av +1 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_ATTACH_BOUND_S | work | internal | merge: wisp flag | read by tools alone |
| AVRA_ATTACH_S | sprite-remote.sh, sprite_remote_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_BENCH_PAYLOADS | main.av | internal | merge: wisp flag | read by tools alone |
| AVRA_BESIDE | worked_ahead.av, beside_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_BIN | avra, avra-try, closure_fold_attack.sh +15 | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_BIN_MAX_BYTES | pack.av | user | keep: typed setting | compiler: one @std/config record |
| AVRA_BOOTSTRAPPING | avra | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_BOX_H | avra_box.h | not config | — | a C macro, enum or guard |
| AVRA_BUILDER_BACK | work | internal | merge: wisp flag | read by tools alone |
| AVRA_BUILD_CAP_MB | sprite-remote.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_BUILD_LOCK | fmt_light_test.av, watch.sh | not config | — | a test fixture's name |
| AVRA_BUILD_S | work | internal | merge: wisp flag | read by tools alone |
| AVRA_BUILD_SLOTS | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_CACHE_DIR | cas.av, cas_phase_test.av, carried_store_attack.sh +47 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_CALLER | avra_hot.c, avra_platform.h, avra_runtime.c +1 | not config | — | a C macro, enum or guard |
| AVRA_CAP_MB | avra, sprite-remote.sh, lane-run.yml | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_CASE | avra_runtime.c, child_kept.sh | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_CAS_DIR | cas_phase_test.av | not config | — | a test fixture's name |
| AVRA_CAS_MAX_AGE_DAYS | cas.av | user | keep: typed setting | compiler: one @std/config record |
| AVRA_CAS_MAX_MB | cas.av, pack.av, store_attacks.sh | user | keep: typed setting | compiler: one @std/config record |
| AVRA_CAS_PHASE | cas_phase_test.av | not config | — | a test fixture's name |
| AVRA_CENSUS | avra_hot.h, avra_runtime.c, census.sh +4 | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_DEATHS | avra_runtime.c, cost.sh | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_ROWS_TOP | avra_runtime.c | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_SITES | avra_runtime.c, census.sh, cost.sh | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_TOP | avra_runtime.c, cost.sh | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_TYPES | llvm.av, llvm_wrapper.c, avra_runtime.c +2 | internal | merge: settings.debug | runtime instrument |
| AVRA_CENSUS_TYPES_TOP | avra_runtime.c | internal | merge: settings.debug | runtime instrument |
| AVRA_CHILDREN | gate.sh, child_kept.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_CHILD_BIN | gate.sh, child_kept.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_CLOCK | avra_fiber.c, avra_fiber.h, verdict_test.c +1 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_CLOCK_ASKS | avra_runtime.c, avra_runtime.h, clock_test.c +1 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_COMPILER_DEPOT | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_COMPILE_SLOT | std_io.c, io.av, compile_slots.sh | user | keep: typed setting | compiler: one @std/config record |
| AVRA_CORES_H | avra_cores.h | not config | — | a C macro, enum or guard |
| AVRA_CORE_FROM_SURFACE | item_elaborated.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_CWD | shared.av, avra, db_corpus.sh +2 | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_CXX_RUNTIME | avra.toml, whole.av, avra +6 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_DB_FAST | debug.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_DB_GRAPH | debug.av, ab.sh, graph.py +1 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_DB_VERIFY | debug.av, suspect_narrow_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_DEBUG | interp.av, settle_named_test.av, debug.av +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_DEFECT_STALL | defects.py | internal | merge: wisp flag | read by tools alone |
| AVRA_DEFECT_TIMEOUT | defects.py | internal | merge: wisp flag | read by tools alone |
| AVRA_DEFECT_WARM | defects.py | internal | merge: wisp flag | read by tools alone |
| AVRA_DEFECT_WARM_CLOCK | defects.py | internal | merge: wisp flag | read by tools alone |
| AVRA_DEFECT_WORKERS | defects.py | internal | merge: wisp flag | read by tools alone |
| AVRA_DEPOT_KEEP | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_DEP_AUDIT | audit_switch_test.av, bypass.av, decls.av +1 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_DISK_FLOOR_MB | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_DOOR_H | avra_door.h | not config | — | a C macro, enum or guard |
| AVRA_E | inherit_env.av | not config | — | a test fixture's name |
| AVRA_EMIT_TIMES | llvm_wrapper.c | internal | merge: settings.debug | runtime instrument |
| AVRA_ENGINE_PARSE | debug.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_EPOLL | avra_fiber.c | not config | — | a C macro, enum or guard |
| AVRA_EVAL_JUMPS_CHECK | interp.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_EXACT | live.av, exact_comp.av, exact_empty.av +11 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_FFI_ARGS | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FFI_MAX_F | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FFI_MAX_I | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FFI_SEATS | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FFI_WORDS | ffi.c | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FIBER_GUARDS | avra_fiber.c, flow_test.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FIBER_H | avra_fiber.h | not config | — | a C macro, enum or guard |
| AVRA_FIBER_STACK | avra_fiber.c, avra_task_stack_unoptimised.c, fiber_adversarial_test.c +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FLAGS_AT | avra_box.h, avra_hot.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_FLAGS_MASK | avra_box.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_FLOW_TRACE | trace.av, avra_fiber.c, cores_test.c +3 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FLOW_TRACE_CAP | avra_fiber.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FOLD_CHECK | query_engine.av, witness_body_consts.sh, witness_program_edit.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FOLD_OFF | query_engine.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FRAME_POINTERS | llvm_wrapper.c, census_compiler.sh, read_cost.sh +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_FRONTIER_WALK_CHECK | frontier.av, gate.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_FROZEN_S | sprite-remote.sh, sprite_remote_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_GET_BUILD | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_GH | batch.sh, batch_test.sh, work +1 | internal | merge: wisp flag | read by tools alone |
| AVRA_GUARDED_PACKAGE | avra, shim_guard_test.sh | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_HASH_SEED | avra_runtime.c, wasm-archive.sh | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_HEALTH_S | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_HEIR_LINGERS_MS | avra_cores.c, heir_save_attack.sh | internal | merge: settings.debug | runtime instrument |
| AVRA_HELD_ANSWERS_OFF | query_engine.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_BYTES | item_signatures.av, held_store_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_ITEMS_OFF | item_signatures.av, held_store_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_QUESTIONS_CHECK | query_engine.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_QUESTIONS_OFF | query_engine.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_ROUNDTRIP | query_engine.av, saved_query.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HELD_VALUES_BYTES | held_values.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_HOSTED | avra_fiber.c, tasks.js, wasm-body.sh +1 | not config | — | a C macro, enum or guard |
| AVRA_HOT_H | avra_hot.h | not config | — | a C macro, enum or guard |
| AVRA_INLINE_RUNTIME | llvm.av, llvm_wrapper.c, census_compiler.sh +5 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_INSTRUMENTS | avra_hot.h, avra_platform.h, avra_runtime.c +2 | not config | — | a C macro, enum or guard |
| AVRA_IO_CORPUS_UNSET | io.av | not config | — | a test fixture's name |
| AVRA_IO_NO_SUCH_VARIABLE | io_test.av | not config | — | a test fixture's name |
| AVRA_IO_SURELY_UNSET | io_adversarial_test.av | not config | — | a test fixture's name |
| AVRA_IR_OF | item_program.av, witness_body_consts.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_KEEP | generated_types.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_KILL_AFTER_PLACE | tapes.av, witness_place_kill.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_KQUEUE | avra_fiber.c | not config | — | a C macro, enum or guard |
| AVRA_LADDER_BASE | ladder.sh, Makefile | internal | merge: wisp flag | read by tools alone |
| AVRA_LADDER_DIR | ladder.sh, sprite-remote.sh, sprite_remote_test.sh +1 | internal | merge: wisp flag | read by tools alone |
| AVRA_LADDER_REPO | ladder.sh, sprite-remote.sh, sprite_remote_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LADDER_S | ladder.sh, Makefile | internal | merge: wisp flag | read by tools alone |
| AVRA_LAND_BATCH_WT | reclaim.sh, reclaim_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LAND_LOCK | reclaim.sh, reclaim_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LAND_SPEED_OK | speed.baseline | internal | merge: wisp flag | read by tools alone |
| AVRA_LEAVES | digest_diff.py | internal | merge: wisp flag | read by tools alone |
| AVRA_LEG_PROBE | refuse_eval_test.av | not config | — | a test fixture's name |
| AVRA_LIGHT | disk_host.av, stage.av, avra | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_LINK_TRACE | tapes.av, witness_layered_link.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_LLVM_MAJOR | sprite-provision.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_LOG | witness_fmt_changed.sh, witness_gate_changed.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_MACHINE_STORE | tapes.av, cost.sh, std_answers_attack.sh +4 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_MACHINE_STORE_DIR | tapes.av, cost.sh, std_answers.sh +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_MAINC_BUILD | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_MAINC_WAIT_S | work | internal | merge: wisp flag | read by tools alone |
| AVRA_MAIN_OVERRIDE | reference-transaction | internal | merge: wisp flag | read by tools alone |
| AVRA_MAIN_TREE | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_MAP_STATS | avra_runtime.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MAX_COMPILES | std_io.c, io.av, compile_slots.sh +5 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_MEASURES_MEMORY | avra_platform.h, avra_pool.c, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_MEM_CEILING_MB | avra_runtime.c, mem_ceiling_test.c, ab.sh +10 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_DUMP_AT | avra_runtime.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_FLOOR | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_MEM_POOL_DIR | avra_pool.c, cores_test.c, pool_claim_test.c +1 | internal | merge: settings.debug | runtime instrument |
| AVRA_MEM_POOL_MB | avra_pool.c, avra_runtime.c, cores_test.c +2 | internal | merge: settings.debug | runtime instrument |
| AVRA_MEM_POOL_WAIT_MS | avra_pool.c, avra_runtime.c, pool_claim_test.c +1 | internal | merge: settings.debug | runtime instrument |
| AVRA_MEM_SITE | avra_runtime.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_SITES | avra_runtime.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_STATS | stage.av, fns_adversarial_test.av, main.av +16 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MEM_WIDE | avra_runtime.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_MERGED_APART_FROM | worked_ahead.av, share_merge_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_MERGED_HERE | worked_ahead.av, share_merge_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_N | inherit_env.av | not config | — | a test fixture's name |
| AVRA_NO_SUCH_TOOL_VAR | process_test.av | not config | — | a test fixture's name |
| AVRA_NO_SUCH_VAR | workspace_test.av | not config | — | a test fixture's name |
| AVRA_NO_SUCH_VARIABLE | externs.av | not config | — | a test fixture's name |
| AVRA_NO_SUPERVISOR_TESTS | work_test.sh, checks.yml | internal | merge: wisp flag | read by tools alone |
| AVRA_NULL_PAGE | avra_hot.h | not config | — | a C macro, enum or guard |
| AVRA_OBJ_MAX_BYTES | tapes.av, pack.av, store_bound_attack.sh | user | keep: typed setting | compiler: one @std/config record |
| AVRA_OBSERVED | avra_box.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_ONCE_MAX | libs.py | internal | merge: wisp flag | read by tools alone |
| AVRA_P | inherit_env.av | not config | — | a test fixture's name |
| AVRA_PLATFORM_H | avra_platform.h | not config | — | a C macro, enum or guard |
| AVRA_PREFIX | census.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_PRINTS_MAX_AGE_DAYS | store.av | user | keep: typed setting | compiler: one @std/config record |
| AVRA_PROBE | process_adversarial_test.av, process_test.av | not config | — | a test fixture's name |
| AVRA_PROBE_BUILD | sprite-remote.sh, work | internal | merge: wisp flag | read by tools alone |
| AVRA_PROGRAM | check_program.av, build_report_test.av, ahead_edit_attack.sh +24 | internal | delete | no reader since the old path died (b6dce5f); 23 tool sites still set it |
| AVRA_PROGRAM_MODE | tapes.av, build_mode_test.av, avra_tools.sh +14 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_PROGRAM_NET | build_report_test.av, build_tools_test.av, check_dir_test.av +26 | internal | delete | no reader; 24 tool sites still set it |
| AVRA_PRUNE_PCT | sprite-remote.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_QTRACE | compiler_print_adversarial_test.av, debug.av, runtime_api.av +22 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_QUERY_FAMILIES | tapes.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_QUERY_TIMES | check_program.av, lowered.av, tapes.av +9 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_QUEUE_TOKEN | auto-merge.yml, pr-watcher.yml | internal | merge: wisp flag | read by tools alone |
| AVRA_RAMP_S | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RANDOM_H | avra_random.h | not config | — | a C macro, enum or guard |
| AVRA_RAN_TRAP | tapes.av, witness_program_runs.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_RC_GUARD | tapes.av, packed_guard_test.av, stage.av +18 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_RC_LOG_BUDGET | tapes.av, avra_runtime.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_RC_REASONS | memory.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_READS_DIR | store_reads_process_test.av, store_reads_attack.sh | not config | — | a test fixture's name |
| AVRA_READS_PHASE | store_reads_process_test.av, store_reads_attack.sh | not config | — | a test fixture's name |
| AVRA_REATTACH_S | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RECLAIM_FREE_GB | reclaim.sh, reclaim_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RECLAIM_SCRIPT | reclaim_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RELEASE_API | compiler_release.py | internal | merge: wisp flag | read by tools alone |
| AVRA_REMOTE_SCRIPT | sprite-lib.sh, sprite-remote.sh, sprite_remote_test.sh +2 | internal | merge: wisp flag | read by tools alone |
| AVRA_RT | runtime_header.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_F64 | runtime_header.av, runtime_header_test.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_H | runtime_header.av, runtime_header_test.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_HOST | ffi.c, runtime_header.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_I32 | runtime_header.av, runtime_header_test.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_I64 | runtime_header.av, runtime_header_test.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_LABEL | runtime_header.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_POINTER | runtime_header.av, runtime_header_test.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_PTR | runtime_header.av, runtime_header_test.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_SET | process_adversarial_test.av | not config | — | a C macro, enum or guard |
| AVRA_RT_SPELLED | runtime_header.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_TEXT | runtime_header.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_U32 | runtime_header.av, runtime_header_test.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RT_VOID_SEAT | runtime_header.av, runtime_header_test.av, avra_rt.h | not config | — | a C macro, enum or guard |
| AVRA_RUN | sprite-remote.sh, sprite_remote_test.sh, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_RUNTIME_H | avra_runtime.h | not config | — | a C macro, enum or guard |
| AVRA_RUN_FLOOR_MB | sprite-remote.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SAMPLE | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SAMPLE_AFTER | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SAMPLE_FILE | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SCHED_PATH | avra_fiber.c, avra_runtime.c, seed_test.c +1 | internal | merge: settings.debug | runtime instrument |
| AVRA_SCHED_RUNS | avra_fiber.c, avra_fiber.h, seed_test.c +2 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_SCHED_SEED | suite.av, avra_fiber.c, avra_fiber.h +4 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_SCOPE_IDS | avra_fiber.c, avra_runtime.c, avra_runtime.h +2 | not config | — | a C macro, enum or guard |
| AVRA_SEED_BEHIND | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SHARED_KILL_AT | avra_cores.c, wave_share_attack.sh | internal | merge: settings.debug | runtime instrument |
| AVRA_SHARED_TRAP_AT | avra_cores.c, wave_share_attack.sh | internal | merge: settings.debug | runtime instrument |
| AVRA_SHARE_UNMERGED | worked_ahead.av, share_merge_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_SIGN_TABLES | sig_restore_attack.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SITES_ELF_SECTION | llvm_wrapper.c, avra_box.h, flow_test.c | not config | — | a C macro, enum or guard |
| AVRA_SITES_MACHO_SECTION | llvm_wrapper.c, avra_box.h, avra_fiber.c +1 | not config | — | a C macro, enum or guard |
| AVRA_SITES_MACHO_SEGMENT | llvm_wrapper.c, avra_box.h, avra_fiber.c +1 | not config | — | a C macro, enum or guard |
| AVRA_SLABS | avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_SLOTS_MAX | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SLOT_ASKER | avra_runtime.c, avra_runtime.h | not config | — | a C macro, enum or guard |
| AVRA_SLOT_CTX | interp_tasks.av, avra_fiber.c, avra_runtime.c +1 | not config | — | a C macro, enum or guard |
| AVRA_SLOT_DIR | std_io.c, io.av, compile_slots.sh | user | keep: typed setting | compiler: one @std/config record |
| AVRA_SLOT_FLOW | avra_runtime.c, avra_runtime.h | not config | — | a C macro, enum or guard |
| AVRA_SLOT_HEARD | interp_tasks.av, avra_runtime.c, avra_runtime.h | not config | — | a C macro, enum or guard |
| AVRA_SLOT_MB | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SOUNDNESS | stage.av, inputs.baseline | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_SOUND_CHECK | check_program.av, sound_check_cache_test.av, memory.av +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_SPEED_BIN | speed_measure.sh, warm_edit_bench.sh, witness_warm_edit.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SPRITES | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SPRITE_CLI | sprite-lib.sh, sprite-rsh.sh, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_SPRITE_HOME | sprite-remote.sh, sprite_remote_test.sh, work +1 | internal | merge: wisp flag | read by tools alone |
| AVRA_SP_EXCLUDE | work | internal | merge: wisp flag | read by tools alone |
| AVRA_SP_TREE | sp | internal | merge: wisp flag | read by tools alone |
| AVRA_STAMP_AT | avra_box.h | not config | — | a C macro, enum or guard |
| AVRA_STAMP_MASK | avra_box.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_STAMP_ONE | avra_box.h, avra_runtime.c | not config | — | a C macro, enum or guard |
| AVRA_STD_ANSWERS | gate.sh, Makefile | internal | merge: wisp flag | read by tools alone |
| AVRA_STORE_HOLD_MS | pack.av, store_attacks.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_STORE_KEPT_HERE | tapes.av, census.sh, census_types.sh +46 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_STORE_KILL | pack.av, store_attacks.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_STORE_MAX_AGE_S | pack.av | user | keep: typed setting | compiler: one @std/config record |
| AVRA_STORE_MAX_MB | pack.av, action.yml | user | keep: typed setting | compiler: one @std/config record |
| AVRA_STORE_REVISIONS | pack.av, action.yml | user | keep: typed setting | compiler: one @std/config record |
| AVRA_STORE_SEAL_FRAMES | pack.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_STREAM_PIECES | http_stream_download.av, http_stream_upload.av | not config | — | a test fixture's name |
| AVRA_STRICT_EXTERN_GUARD | llvm_wrapper.c | internal | merge: settings.debug | runtime instrument |
| AVRA_SUITE_ALL | shared.av, stage.av, stage_test.av +4 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_SURELY_UNSET_NAME | inherit_env.av | not config | — | a test fixture's name |
| AVRA_SYM | avra_fiber.c | not config | — | a C macro, enum or guard |
| AVRA_SYNC_S | work | internal | merge: wisp flag | read by tools alone |
| AVRA_SYNC_UNTRACKED_KB | work | internal | merge: wisp flag | read by tools alone |
| AVRA_SYS_SEARCH | avra.toml, whole.av, avra +2 | user | keep: typed setting | compiler: one @std/config record |
| AVRA_TAG | llvm_wrapper.c, avra_box.h, avra_hot.h +3 | not config | — | a C macro, enum or guard |
| AVRA_TAPE_SCHEMA | tape_roots.av, taped_derive.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_TARGET_CACHE | llvm_wrapper.c | not config | — | a C macro, enum or guard |
| AVRA_TASKS_DIR | tasks.av, avra_fiber.c, tasks_door_test.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_TASKS_DIR_NEXT | tasks_door_test.c | not config | — | a test fixture's name |
| AVRA_TASK_SLOTS | avra_fiber.c, avra_runtime.c, avra_runtime.h +1 | not config | — | a C macro, enum or guard |
| AVRA_TICK_US | avra_fiber.c | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_TIMER_TURNS | avra_fiber.c, avra_fiber.h, flow_test.c +1 | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_TOOLS_COMPILER | avra_tools.sh, checks.yml | internal | merge: wisp flag | read by tools alone |
| AVRA_TRAP_TRACE | avra_runtime.c, gate.sh | user | keep: typed setting | runtime: constructor-read, named by the generated header |
| AVRA_TYPE_MEMO_CHECK | type_memos.av | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_UNWIND_CAP | avra_fiber.c, avra_runtime.c, avra_unwind.h +1 | not config | — | a C macro, enum or guard |
| AVRA_UNWIND_H | avra_unwind.h | not config | — | a C macro, enum or guard |
| AVRA_VERDICT_DIR | std_answers.av, std_answers.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_VERIFY_LLVM | llvm.av, gate.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_WAIT_POLL | witness_work_wait.sh, work | internal | merge: wisp flag | read by tools alone |
| AVRA_WAIT_SECONDS | witness_work_wait.sh, work | internal | merge: wisp flag | read by tools alone |
| AVRA_WAKE_S | work, work_test.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WALL_API | ci_wall.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WATCHER_STATE | pr_watcher.py | internal | merge: wisp flag | read by tools alone |
| AVRA_WATCH_HELD | avra, hist_point.sh, store_two.sh +10 | internal | merge: shim flag | the shim and the compiler agree by argv, not ambient env |
| AVRA_WATCH_TRACE | watch.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WAVE_ALONE | disk_store.av, wave_share_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_WITNESS_LOG | witness_warm_edit.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WITNESS_TIMES | witness_machine_store.sh | internal | merge: wisp flag | read by tools alone |
| AVRA_WORK_AHEAD_CORES | tapes.av, wave_share_attack.sh | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_WORK_AHEAD_OFF | tapes.av, beside_attack.sh, cost.sh +3 | internal | merge: settings.debug | a switch the compiler reads; an oracle reading sets it |
| AVRA_WORLD_LIB | world_test.av | not config | — | a test fixture's name |
| AVRA_X | inherit_env.av, inputs.py | not config | — | a test fixture's name |
| AVRA_Y | inherit_env.av | not config | — | a test fixture's name |


## cli commands (packages/cli/src/commands)

| Command / file | Class | Action | Note |
|---|---|---|---|
| check | user | keep |  |
| build | user | keep |  |
| run | user | keep |  |
| test | user | keep |  |
| fmt | user | keep |  |
| fix | user | keep |  |
| docs | user | keep |  |
| explain | user | keep | P7: the layer's answers, inspectable |
| dev | user | keep |  |
| expand | user | keep | P7: generated declarations |
| ir | user | keep | P7; ask lead: or `explain --ir` |
| emit | user | keep | P7; ask lead: or `explain --llvm` |
| process | user | keep | a package's declared tools |
| tasks | user | keep | a running process's tasks |
| trace | user | keep | reads a flow trace a user program wrote |
| db | user | keep | LEAD LISTED IT TO MOVE: `db diff` is the ORM's migration plan, a user verb |
| cache | user | keep | `clean` is user; `families` moves to census |
| diagnostics | user | merge: avra docs | the error index; `docs <code>` already looks one up |
| census | internal | merge: census |  |
| tapes | internal | merge: census tapes |  |
| settled | internal | merge: census settled |  |
| repr | internal | merge: census repr |  |
| parsers | internal | merge: keepers parser |  |
| writes | internal | merge: census writes |  |
| rules | internal | merge: idioms rules | the gate reads its JSON |
| licences | internal | merge: keepers licences |  |
| voices | internal | merge: voices |  |
| new | internal | merge: wisp new | scaffolds a compiler feature / IR instruction |
| attack | internal | merge: oracle attack |  |
| language | internal | merge: census grammar | prints the assembled grammar |
| runtime_header | internal | merge: keepers rt-header |  |
| runtime_namespace | internal | merge: keepers rt-ns |  |
| lowered.av | internal | merge: census lowered | support file of ir/emit/explain |
| std_answers.av | internal | merge: seed std-answers | support file |
| refuses.av | user | keep | support file of test |
| check_program.av | user | keep | support of check |
| fix_program.av | user | keep | support of fix |
| dev_backend.av | user | keep | support of dev |
| idiom_baseline.av | internal | merge: idioms | `check --baseline` moves to `wisp idioms` |
| disk_host.av | user | keep | support |
| shared.av | user | keep | support |
| mod.av | user | keep | support |
