# Deletion rehearsal: the old path deleted per DELETION_MAP, on a scratch branch

Branch `rehearsal-delete`, unlanded: f794bbdc..dd1c60b9, 6 commits, based on the lane head before base57.
Scope: map rows **A, B, C, D**; the gate's net and old-path rows; my 12 INTERNAL `*_workspace_test`s.
Then **E**, the cli tests over the old path. It was out of scope, but without it `avra check packages/cli` refuses. Row F (the old Workspace itself) was not touched.

## Headline numbers

- **5,034 lines removed, 113 added.**
- **Builds:** compiler built twice; fixed point holds (`GATE build PASS`, rows 6/6).
- **Gate:** every slice was run, 30 in all. Final state:
  - 27 PASS
  - 3 fail (avrac-b, cli, cost), none caused by a deleted mechanism:
    - **avrac-b:** one case that already failed on f794bbdc.
    - **cli:** 9 cases held up only by the net's words, listed in §1.
    - **cost:** an environment failure.
- **Timings:** cold check of cli −9%, cold build −12%, warm one-edit build −16%.

| measure (fresh store and machine cache, net off, same edit) | before (f794bbdc, gen-2) | after (rehearsal, gen-2) |
|---|---|---|
| `avra check packages/cli`, cold | 92.3 s, RSS 3.37 GB | **83.7 s**, RSS 3.34 GB |
| `avra build packages/cli`, cold | 57.5 s, RSS 3.48 GB | **50.3 s**, RSS 3.44 GB |
| the same build after one edit, warm (fmt.av gains an enum and a fn, as witness_program_warnings edits it) | 9.72 s, RSS 2.07 GB | **8.21 s**, RSS 2.02 GB |

How the numbers were taken:
- The after-check is on ea3266a8, with E set aside. On 81e706d7, without E, the check refuses with 15 errors in 63 s; that run is not comparable.
- The before-build ran the net-off branch. A user's default (net on) pays the old path's judgement on top of it.
- Script: `scratchpad/measure.sh`. Logs: `scratchpad/meas/{before,after2}`.

## (1) What failed to compile or test, and why each piece was still alive

| # | what broke | why it was still alive | what the rehearsal did |
|---|---|---|---|
| 1 | `make try`: `leg_or_host`, `tested_env`, `compiler_env` unresolved (tapes.av ~2146) | **refuses.av is not reached only through `checked_refuses`** (map row B is wrong). The layer's child-run legs (`children_wrong`, the `.refuses` children) call its runners. | Kept refuses.av's runners. Only `one_refuses`, `checked_refuses` and `refuses_binary` go (−55 of 154 lines). |
| 2 | `make try`: stage.av imports `program_door`, `root_workspace` | the old `refuse_eval` leg | Imports dropped. |
| 3 | (by reading) `hit_line` | **the layer's tapes build calls it** (tapes.av :570, :3395); row B lists it to go | Kept. |
| 4 | (by reading) `parsed_new_only` | **`Workspace.set_aside` in modules.av** (an F1 file) is the old Workspace's own copy of the step-aside list | The filter is cut (−13 lines), so `item_new_only` can go before F. It must go with C. |
| 5 | cold `check packages/cli`: 15 errors | **Row E**: build_tools, check_reuse, check, findings_rows, idiom_baseline, provider_words, rule_self_match_probe, shared, and warm_component_form / warm_deleted / warm_order. They reach `checked_at`, `root_workspace`, `root_program`, `file_workspace`, `toolchain(ws…)` and `accepted`. | E set aside: 11 files, −1,014 lines. **E must land with B.** shared_test is ALL `file_workspace` routing; it has no `file_home` cases, contrary to the map. |
| 6 | avrac-a: `print_workspace` ×4, `real_binary` ×17 unresolved in compiler/tests/build_mode_test.av | **A deleted test file's helpers.** Test files of one module share names. build_mode_test (lowering lane, 8ae128b1; an old-path test of class F3, untagged) used helpers defined in my INTERNAL compiler_print_workspace_test. | The 4 helpers moved into build_mode_test (17/17). Every INTERNAL deletion needs a check of what its siblings borrow from it. |
| 7 | witness-b: flow-trace and flow-trace-swap-attack ("the compiler spawned a task of its own while it evaluated", 4 refused) | **tools/flow_trace_engines.sh runs the evaluated leg as `AVRA_PROGRAM=0 avra run`.** It is called from `make flow-trace`, not from a gate.sh row, so the map's tools row missed it. With the switch gone the env is ignored; `run` builds on the layer and the trace records the compiler's own tasks. | That leg is now `avra run --eval` (the layer's evaluator): 0 refused, 115 events. **Grep every tool and Makefile recipe for `AVRA_PROGRAM=0`, not only gate.sh.** |
| 8 | idioms-cli: 6 `modules.unused_import`, 1 `fns.dead_parameter` | what the deletion left unread | `avra fix --only modules.unused_import`; `held`'s `root` parameter dropped. PASS. |
| 9 | cli suite: 9 unpinned cases — ui_view ×4, generated_view ×2, sibling_programs ×2, build_report ×1 | **They were held up only by the net's words.** The cli suite ran with the net ON (gate `slice_cli`), so a refusal was the old path's, said first. On f794bbdc with its own compiler: net on, all 4 files are green; net off, 8 of the 9 fail the same way. The 9th, build_report "both diagnostics print", reads the build's **stdout**: the net says the old path's refusal with `println` (15 lines on stdout), the layer says it on **stderr**. That case's child does not take the runner's `AVRA_PROGRAM_NET`, which is why my net-off run of it still passed. | Not fixed: these are layer refusal gaps, plus one change a user will see (a build refusal moves from stdout to stderr). They must be closed or pinned before the net goes. Logs: `scratchpad/runs/recheck/`. |
| 10 | avrac-b: annotations defaults_test, "an explicit wrong type is still refused" | **Already failing on f794bbdc** (9/10 with f794bbdc's own compiler). base57 changes features/annotations/check.av. | Not the rehearsal's. |
| 11 | cost: "snapshot 161e52bf is not in this clone and could not be fetched" | an environment failure: the lane's tools/cost.baseline names a snapshot this clone lacks (base57 moves it to a6d0d0a0) | Not the rehearsal's. |

Also lost by construction, not run:
- **Map G's stale `// LICENSED` law.** `refused_licenses` and `rendered_licenses` went with check.av's old branch. The layer check has no form of it, so a layer form must land first, as G says.
- **`program_door_refused`'s words.** They said "with AVRA_PROGRAM=0 the old path does"; that clause is dropped. No golden held it.
- **`direct_test_workspace_test`** is the lowering lane's (8ae128b1), so it was left in place.

## (2) Line count removed (f794bbdc..dd1c60b9, `git diff --numstat`)

| part | removed | added |
|---|---|---|
| tapes.av: D's ~70 differential items, the net threading, `--new_only`, `--lowered`, `--signatures`, the link-words comparison, and 107 dead import lines | 1,211 | 19 |
| shared.av: B's 14 helpers, the net (C), `built_binary`'s old branch | 313 | 18 |
| check.av, test.av, fix.av, run.av, stage.av, check_program.av, db.av (A switches, B helpers, net parameters) | 238 | 12 |
| refuses.av (part), phase.av (whole) | 79 | 0 |
| std-avrac item_new_only.av (whole), modules.av `set_aside`, item_tapes.av | 237 | 1 |
| my 12 INTERNAL `*_workspace_test`s | 1,877 | 0 |
| row E: 11 cli test files | 1,014 | 0 |
| tools/gate.sh: the net, `old_row`, slices refusal-a/b/c and warnings-a/b/c; flow_trace_engines.sh | 64 | 17 |
| build_mode_test.av: the helpers moved in | 1 | 46 |
| **total** | **5,034** | **113** |

A+B+C+D alone come to about 2,140 lines. F (the old Workspace, about 4,860 whole-file lines plus the mixed files) is still to come.

## Gate, slice by slice (tree ea3266a8, then dd1c60b9 for the 2 slices re-run)

- **PASS:** build, avrac-a, avrac-g, avrac-c, avrac-d, avrac-e, avrac-f, program, idioms-avrac, idioms (no other package touched), fmt, sound, doors-a, doors-b, findings-a, findings-b, findings-c, findings-d, edit-a through edit-g; idioms-cli and witness-b after the fixes in §1.
- **FAIL:** avrac-b (#10, already failing on f794bbdc), cli (#9, net-held), cost (#11, environment).
- Gone with their rows: refusal-a/b/c and warnings-a/b/c held only `old_row` rows. Also gone: witness-b's fixes, ledger, suites, doors and differential witnesses, the build slice's net-on build, and the findings slices' net-on builds.

## What landing it needs (in order)

1. A layer form of the stale `// LICENSED` law (map G).
2. The 9 net-held cli cases closed on the layer, or pinned with a reason. That includes the decision on which stream a build refusal goes to.
3. E landed together with B: ported or deleted per the map's fates.
4. Before each INTERNAL test file goes: grep its sibling test files for the names it defines.
5. Every tool and Makefile recipe swept for `AVRA_PROGRAM=0` and `AVRA_PROGRAM_NET`: flow_trace_engines.sh, and the ~20 attack and witness tools that set them (`grep -rl AVRA_PROGRAM tools`).
6. Corrections to the map: refuses.av is partial; `hit_line` stays; shared_test has no `file_home` cases; modules.av `set_aside` reaches item_new_only; flow_trace_engines.sh belongs on D's tools row.
