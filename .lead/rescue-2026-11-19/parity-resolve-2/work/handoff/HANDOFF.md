# HANDOFF — avra-lane-parity-resolve-2

## Lane and scope
- **Lane:** avra-lane-parity-resolve-2, the Avra compiler's program layer.
- **Goal:** the program layer (AVRA_PROGRAM_NET=0) says what the old path (AVRA_PROGRAM=0) says: kind, words, place and count.
- **My families:** resolve.* (imports, re-exports, scope), plus laws routed to me by the lead.
- **Rules (LANE_BRIEF):**
  - one definition per law;
  - no `rm` (use `find … -delete`), no `git stash`, no `reset --hard`, no `--no-verify`;
  - push nowhere; commit as you go;
  - run fmt --write on every .av you touch;
  - one heavy build at a time;
  - post to the lead only at a bundle, a blocker or a ruling.
- **Lead contact:** the claude-bridge tools `post_to_controller` and `send_files`. The session token was in the bridge note; a new session gets its own.

## Base
- **Repo:** /work/avra, branch `avra-lane-parity-resolve-2`, HEAD 324fd3c59.
- **Landed:** everything through 7e717b29 (my merge of batch52 572c1d99) was sent and landed as batch 52's first merge.
- **batch53:** d5062c32, local ref `batch53`, which I hold. My lane is NOT merged onto batch53. Commit c0493354 (= ec9d036e cherry-picked) was sent ON batch53 as one commit and is gating in batch 53.
- **lane.bundle** = `avra-lane-parity-resolve-2 ^d750dfa70`.
- **Working tree:** clean; uncommitted.patch is empty.

## Commits ahead of the last landed bundle (7e717b29), not yet sent as a lane bundle
- 5cebcb116: a named top-level instance is a declaration (ruled). Built once through the once slot, readable by name from any fn, exported/imported like a declaration. The entry builds it where written (`runs_in_entry`); a module file builds it lazily. Also:
  - the layer's instance unit is `once` (fixes a wrong answer: an exported instance was rebuilt at every read);
  - `let`→`const` fix on resolve.runtime_binding (Remedy.Fix, High; `let_made_const`, `const_fix`, `made_const`; `FoundFix.item`);
  - instance builds and untyped un-typable consts are checked as bodies;
  - const.cycle widened to builds (`build_reads_itself_law`).
- c226844e4: witnesses for the above, the std-queue services_shape program test, and migrated programs. The std-queue tests flow07_failure_dead, flow07_handler_acks, home_refuses and typed_dead now use typed `state` channels/cells; event_holder and children_named changed too.
- 97a803d37: one `check` judgement per declared instance on the layer. The old path builds every declared instance at run time (dropped `settles`). Three component tests move to the ruling.
- ad8e9daab: differs.why texts. Cycle cases: the old path recurses at run time. handler_assigns_capture: two voices.
- ec9d036ea: COST FIX. A file's `use` lines are judged once (an item without `use` lines returns early; clash pre-filter; `imports_refused` file query). Cold law_findings 40.8→23.0, item_unknown_types 10.6→1.2 CPU-s. ALSO SENT as c0493354 on batch53.
- fee7b8a7b: COST/soundness. `implements` asks written impls first and generated ones only if none answers. Witness builds_dyn_over_collect_enum. The earlier annotated-only shortcut was UNSOUND (collect enum, @delegates), now replaced.
- c35746831: resolver loop fix. A name a module's `use` line binds (exported or not) is no generator's (`imports_name` in item_scope.av; `reexports_name` kept for other laws). Fixes importing `Loc` into testing/held.av looping file_scope↔package_impls.
- ce6bd57f0: witness import_of_a_private_import.
- 324fd3c59: a module's own declaration re-exported by a sibling file of the same module is no duplicate (`if prior.is(d) { continue }` in `module_bindings`). Witness builds_reexport_of_a_sibling. The component test now uses `refused_in(built(…))`.

## In flight when stopped
- **Receipts at ce6bd57f** (before 324fd3c5):
  - gates a, c–g PASS; check std-avrac exit 0; cli exit 0; idioms 0 NEW;
  - fmt: 2 differing, both batch52's own hunks in item_context.av and features/contexts.av, not mine;
  - avrac-b had 1 failure, my component test using the wrong helper, fixed in 324fd3c5;
  - the witness run then died: disk full.
- **Rerun at 324fd3c5** (full witness + avrac-b, background) was in progress, result unknown. NEXT: rerun `sh tools/witness_program_refusal.sh build/avra-try` and `sh tools/gate.sh avrac-b`, then the full receipts (handoff/scripts/gates.sh), then bundle `batch52..HEAD` (or merge batch53 first if the lead says so) and send.

## Next 3 items, in order
1. **Finish receipts and send the lane bundle** (all commits above). Merge onto batch53 if the lead asks (c0493354 is already in it; drop or skip the duplicate ec9d036e).
2. **(a) entry_only judges every module file, reached or not.** A whole-package `check` passes a module file that runs statements when the program doesn't reach it. Sits next to `runs_in_entry` / `strays_of` (item_program.av:853) and the old path's `entry_only` (lower.av).
3. **(b) Component import remedy on the layer.** "add this `use`" (`use @acme.kit.{c3}`) exists only on the old path; parse_refusal_test pins it. Search the program's packages by name, bounded, each file read at most once per lookup.

Also queued earlier, still pending:
- type.catch: `fail` inside a `catch` arm's block. The layer builds it unjudged; native LLVM PHI crash, a P0. Old voice `arm_not_ok`; subset case compiler/tests/subset/refusals_test.av:307.
- workspace_adversarial_test 11 pins, entry_only pair first.
- Generated-bodies measurement table: the lead's step 1. Branch `measure-generated` in /work/dev is stale; redo on the current HEAD with `judged_count`.
- `let xs = []; xs.map(it)` is silent on the layer.

## Open rulings / asks waiting on others
- **Lone-file prelude question:** held for the owner's ruling.
- **Remaining law cost** (context_set_before_read, arity_mismatch, declaration_warning_at_use, bitwise_mixed_law, alias_copy_held, ~0.3–0.5 s each): the lead is routing them to their lanes.
- **Suites "4 cases lowered again":** CLOSED by the defects lane (holds_manifest cut in batch 52).
- **item_instances_checked own row** (lead's 1.1→14.2): I couldn't show it with the 15-row timing. I offered an instrumented build or parallel-main's bodies_wave.sh.

## Known gaps found, not fixed
- An untyped `state` whose start is a generic call has no type on the layer; instance builds reading it don't lower ("an untyped `const`"). Workaround: write the type.
- On the old path, a build that reads itself has no law: it recurses at run time (the three cycle cases carry differs.why). Since 97a803d3 the old path builds declared instances at run time, like the layer.

## Things a fresh session would trip on
- **A build reads the std packages beside the HOST binary.** Building a worktree with `AVRA_BIN=/work/avra/build/avra-try` compiles /work/avra/packages, not the worktree's. Copy the host into `<worktree>/build/avra` and run `make try` there with no AVRA_BIN.
- **Builds:**
  - `AVRA_MEM_POOL_MB=12000 AVRA_MEM_CEILING_MB=12000 AVRA_PROGRAM=0 make try` builds build/avra-try (~25 min);
  - the gate's gen1 uses build/avra;
  - NEVER edit sources while a build or the gates run: they read sources mid-run, and I lost runs that way.
- **Disk:** the session's allowance fills fast. Each cold copy's `.avra-cache` is several GB, and the witness died on a full disk. Clean /tmp/claude-0/cold and old worktrees' `.avra-cache` (/work/base, /work/snap: caches already cleared).
- **Old path:** it can't check packages/std-avrac any more (`ctx` is layer-only). Use NET=0 layer checks there.
- **Scripts** (handoff/scripts):
  - gates.sh: check, slices a..g, cli, witness, idioms;
  - gates52.sh: no witness/cli;
  - coldtapes.sh: cold `ir packages/cli --time`;
  - coldtapes_findings.sh: cold `tapes packages/cli --findings`;
  - hunk.py / union.py: diff3 conflict helpers.
- **Kept binaries:**
  - /work/avra/build/avra-try: HEAD-ish (built at 324fd3c5);
  - /work/avra/build/avra-before: a pre-cost-fix copy, deletable;
  - /work/b52 worktree (branch fix53 = c0493354 on batch53);
  - /work/dev worktree (branch lawtime at ad8e9daa, timer reverted, clean);
  - /work/suites-binary, /work/suites-repro: sent, deletable.
- **Witness:** `PIN=1 sh tools/witness_program_refusal.sh build/avra-try <case…>` pins a case that has no expectation from the OLD path's words. Where the paths differ by ruling, write prints/refuses.expected from the layer by hand, with a differs.why.
- **Merge history:** handoff/handbacks-history.md is the running handback notes (handbacks 1–8).
