# HANDOFF — avra-lane-spec-harness

## Lane and scope
- Lane: `avra-lane-spec-harness`, on the Avra compiler (`/work/avra`, branch `avra-lane-spec-harness`).
- Job: move std-avrac's spec suite off the OLD pipeline (Workspace, analyze_source, TypeCx, LowerCx…) onto the PROGRAM LAYER, through ONE harness (`packages/std-avrac/src/testing/held.av` + `testing/mod.av`), so the old path can be deleted.
- Never weaken a spec. A layer/old difference is a finding: post it, or pin the case name in `tools/gate/std-avrac.names`. That list only shrinks.
- A case that kills the suite process goes in `tools/gate/std-avrac.traps`. The gate strips ` @ …` from the `avra: while running` line before matching.
- Owner of the switch list: the 51 GUARANTEE files in `/work/handoff/old-path-files-tagged.tsv`. INTERNAL files are deleted with the old path, never ported.

## Base
- Branch base: **batch53 = d5062c32** (`git fetch /work/batch53.bundle batch53:batch53`).
- Newest batch held: **batch55 = f47b89965** (`refs/heads/batch55`, from `/work/batch55d.bundle`, prerequisite d750dfa7). It does NOT hold kind 5.
- The bundle `lane.bundle` is cut against d750dfa70.

## Commits ahead of batch53 (oldest first)
- d4debc25 specs: program_files + parse_refusal on the layer; `avra test` discovery as a CLI spec (cli/src/commands/tests/program_files_suite_test.av)
- a720d93a specs: means_test on the layer via new door `file_compiled_items` (compiler/item_expanded.av) / `Judged.items_at`
- dec83eb6 specs: specs_test on the layer via `Judged.suite` (made_suite)
- 504d9578 specs: host_fns on the layer; the harness's `files_said` now asks `program_hosts_owed` (as `avra build` does)
- af1a52e8 specs: annotations_adversarial on the layer (55 pass / 21 pinned / 1 trap listed)
- 2a1eb3fd gate: 70 pins dropped after a full pass on batch53; `explain_annotation`/`kind_rows` deleted from compiler/program.av (ruling: dead)
- eb476d29 **WIP** cancel_reach_test on the layer via `Judged.cancel_bits(name)` (methods named `Owner.method`), 28/28. Its 5 record-line/explain cases moved to `compiler/tests/cancel_reach_workspace_test.av` (INTERNAL). The holder file has NOT been run yet, and idioms were not run on this commit.

kind 5 = d4debc25..2a1eb3fd, already sent to the lead as a bundle against batch53. eb476d29 has not been sent.

## In flight
1. **Merge onto batch55 (asked by the lead, not started):** put kind 5 (2a1eb3fd) and eb476d29 onto `batch55`, then send `batch55..HEAD`.
   - The only conflict is `tools/gate/std-avrac.names`.
   - Resolution: batch 55's list MINUS the 70 pins kind 5 dropped. That list is `/work/handoff/pins-dropped-70.txt`; filter with `grep -vxFf`.
   - Also KEEP the pins kind 5 ADDED. All of them are in the 2a1eb3fd list: program_files ×2, parse_refusal ×1, specs ×1, annotations ×21, host_fns none.
   - batch55 itself deleted 7 lines from the list vs batch53.
   - After merging: `make avra`; run the files kind 5 touched; idioms; bundle `batch55..HEAD`.
2. cancel_reach: run `cancel_reach_workspace_test.av` (old path; it should pass 5/5), run idioms, then update the TSV row (cancel_reach → ON THE LAYER 28/28 + 5 INTERNAL).

## Next 3, in order
1. Finish the batch55 merge above and send the bundle (`batch55..HEAD`).
2. The remaining GUARANTEE rows, biggest first. After batch 54 lands, `avra fix` is on the layer (defects lane 8386d7a6), so do these first:
   - rule_fix_test (40)
   - rule_proof_test (27)
   Then:
   - read_set_test (29), features/tests
   - references_test (29)
   - input_host_test (22)
   - error_sites (18)
   - structural / consumes (16)
   - unbroken / pure_decl (12)
   - the tail
   - The reasons are in the TSV's last column.
3. workspace_test (81, "mostly on the layer") and packages_test (3 cases on the old API: module_of, root_files, entry_of): finish them or tag their remnants.

## Open rulings / asks waiting on others
- parity-values has the 21 annotation laws the layer never speaks: `/work/handoff/annotation-silent-21.txt`. One of them is not silent but wrong: the layer reads `o: Self` as `Named T`.
- resolve-2 (routed by the lead) has three of my findings:
  1. A whole-package check passes an unreached module file that runs statements (program_files ×2 and specs ×1 pins).
  2. The "add this `use`" help for an unimported component word exists in Workspace only (parse_refusal pin).
  3. Importing the type `Loc` into testing/held.av loops the resolver: `/work/handoff/held-loc-loop-repro.md`.
- Trap listed and not yet routed: annotations "a lookalike answer does not declare" — `file_generated` re-entered through fn_signature → resolved → generated_names (a same-file annotation fn whose answer names `Decl`).
- rule_fix / rule_proof wait for batch 54.

## Things a fresh session trips on
- **THE NET:** the CLI runs the old path FIRST (`AVRA_PROGRAM_NET`, default on), and the old path's refusals stop the command in its words. To see the layer alone, use `AVRA_PROGRAM_NET=0`. `AVRA_PROGRAM=0` takes the old path. Most "the CLI says it" checks need `NET=0`.
- Harness differential: `AVRA_SPEC_DIFFERENTIAL=1` (`=ir` adds IR). It prints `=====DIFF … --OLDK/--NEWK … =====END` blocks to stdout.
- Running specs:
  - `build/avra test <file or dir>` for std-avrac; `./avra test <file>` (the shim, run from the tree) for cli specs.
  - Failing names: `grep '^    ✗' | sed 's/ @ .*//; s/^    ✗ //'`.
  - A trap stops the file; every case after it never runs.
  - The cli tests share one namespace with neighbours (`avra_ran_in`, `scratch_dir`, `exit_is_zero`, `tree_root`, `hang_bound` live in neighbouring test files).
- Full pass: `/work/handoff/rundirsK.sh` runs per directory into /tmp/runsK. Its dir list is `/work/handoff/dirs.txt`, which was MISSING 4 dirs: src/compiler/store/tests, src/compiler/tests/subset, src/diagnostics/tests, src/grammar/tests. Add them. A full run is ~3h.
- Builds:
  - `make avra` (if "Text file busy": `AVRA_STORE_KEPT_HERE=1`, or `cp packages/cli/src/main build/avra`).
  - Only one heavy build at a time.
  - Never edit sources while a pass runs; it compiles from the tree.
- Rules:
  - `build/avra fmt --write` before every commit.
  - Idioms: `build/avra check packages/<pkg> --baseline tools/idioms.baseline`; exit 0 means 0 NEW.
  - No `rm` (delete with `find … -delete`), no `git stash`, no `reset --hard`, no push.
- Language gotchas:
  - No `List.sorted` on the layer.
  - `_` can't be a loop name.
  - `it` binds to the nearest call.
  - `x with {…}.m()` doesn't parse (bind first).
  - `==` on List<string> is refused (compare `.join`).
- Scratch:
  - Probes write under `build/scratch/` and `packages/.print-adversarial/` (the compiler_print CLI spec removes its copies).
  - Notes: /tmp/inv (not durable); the useful ones are copied here.
- Bridge (old account): session cse_01F8zAGd5yK6kN5yfwLQpwjY.c0e25440ac5947132a21. TOKEN RULE: post only at a bundle, a blocker, or a ruling needed; ≤12 lines, numbers first.
