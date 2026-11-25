# HANDOFF — warm lane ("fold" / engine lane), 2026-11-19

## Lane and scope
The warm-edit lane for the Lead (controller over the claude-bridge). Goal: cheap, correct warm edits
of packages/cli; the ITEM × PHASE ENGINE design of record (`meas/ITEM_PHASE_DESIGN.md`, filed in the
lead's ARCHITECTURE_FOR_BOTH as #1/#3/#4); engine cost work (packed reads, dense keys).
Ownership: program_code_hashes and start-up are parallel-main's; pack search/index is parallel-main's;
laws fold is laws-fusion's; exact-count gate (tools/cost.sh, cost_ratchet.py) is wrong-answers'.

## Base
`batch54` = 99def0d2 (bundle /work/batch54.bundle, prereq d750dfa7). Branch `engine-54` in the
worktree /work/wt-t, head **846ae956**. Bundles here:
- `lane.bundle` = engine-54 ^d750dfa70 (everything)
- `lane-since-batch54.bundle` = engine-54 ^batch54 (the 12 commits below)
- `uncommitted.patch` is empty: nothing uncommitted.

## Commits ahead of batch54 (oldest first)
- 9c76559e names: per-name/per-item cut queries over a file's declarations (file_declares_named/_at,
  item_held, written_fields, seats_written, declares_extern, grammar_declared, home_gives_named; resolved cuts)
- 06969a2e decl_grain spec: an edit's own-cost queries named per case, each once and cut (12/13 pass)
- 53e458de Merge batch52 (per-name reads over resolve-2's marks/problems/members)
- 964cf5c7 Merge batch52 d7102ad5 (sugars fix)
- 72e18dd1 engine: packed ReadTable (reads as columns; census cold tapes --findings 725.3M -> 704.9M boxes)
- ebdc15c5 step 2a: a file's items as parts (item_parts: text part and start part per item)
- f416b51f step 2a: item_front / item_said per item (ran_before, use_faults, first_running, worn_in_item)
- 2828a6d1 step 2a: laws read per-name answers (contexts_declared, records_with_field, method_owners)
  and the entry only where the item runs (runs_in guard)
- e07c0e04 read table idioms (pushes unrolled)
- 2e0fb566 Merge batch53 (holds_manifest kept)
- df52f711 Merge batch54 (item_uses: batch54's `lines.is_empty()` early return + item_front reads)
- 846ae956 step 2c: earlier use lines reach later items without places; item_start a plain part read

engine-54 up to df52f711 was SENT as /work/engine-54.bundle (for batch 54). 846ae956 is NOT sent yet.

## In flight when stopped
- Proofs of 846ae956: avrac-a, -g, program, -f, -b, -c PASS; idioms std-avrac rc=0; cold time
  82.2 -> 78.5 user-s (no regression). avrac-d/-e were running; edit witness NOT run yet on 846ae956.
- cli slice FAILS on `avra db diff` (db_diff_test.av): it fails identically on batch54 ALONE (0/7),
  so it's batch54's/environment's, unpinned. Report it with the 846ae956 bundle.
- witness section `derived` fails on batch53 and batch54 ALONE (parity-values' fix not yet landed).

Warm re-runs (count.py, parent-only, cache.av; laws phase), before step 2 -> now:
noop 0, inline 81->43, literal 69->39, comment 69->39, body 70->40, signature 103->65,
added-before 303->266, added-after 148->70. Each edit's own-item laws re-run: 1 (signature 2).
NOTE: the gate counts ALL processes with work-ahead off (Lead's numbers: signature 172, added-before
418, added-after 244 before). Re-base the design budgets on tools/cost.sh once it lands (batch 54).

## Next 3, in order
1. Finish proofs of 846ae956 (avrac-d/e, full edit witness minus `derived`), bundle batch54..HEAD.
2. Step 2b: STABLE ITEM IDS under laws-fusion's fold (their bundle 7, keyed (file, at)): replace `at`
   with the item id inside the fold's key (Lead: never a parallel key). Positional sites: 34 loops over
   0..item_count, 105 item_held guards, 5 "items before at" readers (now item_front/item_said),
   generated-item numbering (generated_at: at - item_count). Target: added-before 266 -> ~8.
3. summary(item) as the interface firewall (design §2/§5), then engine dense (phase, item) keys
   (engine steps 2/3/5: one-probe reused ask, skip known reads, settled answers as columns).

## Open asks / rulings
- tools/cost.sh exact invocation (ask the Lead until batch 54 lands).
- parity-values' fix for the `derived` witness section.
- bodies-wave instrumentation: /work/lead/bodies-wave/ (README, measure.patch, families.py, bwsplit3.py).
- Engine plan approved: steps 2, 3, 5 GO; #4 (no decode) measure first (~1 s); #6 only the claim skip.

## Trip wires for a fresh session
- Build a tree: `AVRA_PROGRAM_NET=0 make avra` (builder = build/avra of the same lineage). batch52+ needs a
  batch-52-lineage builder; the committed seed is too old (don't `make bootstrap`). Kept binaries in
  /work/wt-t/build: avra-964 (batch52 merge), avra-53, avra-54 (df52f711), avra-2c (846ae956),
  avra-trace (why-trace build). /work/avra/build/avra-b53, avra-b54 = batch53/54 alone.
- `make avra` rewrites the tracked packages/cli/src/.main.print — `git checkout -- packages/cli/src/.main.print`.
- Names are flat across a package's modules AND clash across packages in derived code (ItemPlace in
  std-program broke a build with only "a seat refuses a value here"; `AVRA_PROGRAM=0 build/avra check`
  names such clashes).
- My per-name rewrite (regex in meas/ notes) re-applied after merges turns item_held's and
  file_declares_named's own definitions into self-calls: fix them back every time.
- Measurement: `python3 meas/count.py <compiler> <tag> <tree>` (tapes --findings, cache.av edits).
  Why-trace: apply meas/why-trace.patch to std-program query_engine.av, build, run with
  AVRA_WHY_TRACE=1 (each re-run's moved reads) or AVRA_STOP_READ/_READ2/_ASKER/_ASKER2 +
  AVRA_STOP_REPLAY=1 + AVRA_TRAP_TRACE=1 (backtrace at a named read). Never commit that patch.
- Census: `CENSUS_CAP_MB=12000 sh tools/census.sh tapes --findings packages/cli` (4 GB cap kills it).
- Edit witness: meas/proofH.sh (runs in /work/wt-t with build/avra-e3; clear .avra-cache first;
  ~1.6 h; split slices and witness into separate jobs: background job limit 2 h).
- Disk fills: clear /work/avra/build/scratch and old build/avra-* with find -delete.
- Rules: commit as you go, push nowhere, no rm/stash/reset --hard, fmt touched .av, hand back via
  git bundle + bridge send_files + a ≤12-line post.
