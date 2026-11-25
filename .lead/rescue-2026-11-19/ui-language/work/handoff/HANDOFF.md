# Handoff: avra-lane-ui-language (the ctx lane)

## Lane and scope
The `ctx` language feature (context values, set by a line, read as `ctx.name`), built in steps:
1 the frame and its rows; 2 the survey and laws (`ctx.required`, `ctx.unread` warning);
3a capture (a lambda runs under the frame it was made under); 3b A2 (a `@placed` trait's boxes
carry the frame they are placed under, which UI's `View` uses); then 4 cached-fn keys, 5 the board.
Plus the follow-ons the lead routes here (std-ui `field`/`checkbox`/`dialog` state seats, below).
Lane rules: no `rm` word in commands (use `find … -delete`), no git stash, no reset --hard,
no --no-verify, push nowhere, post to the lead only at a bundle, blocker or ruling, in at most 12
lines. fmt --write touched .av files. One heavy build at a time.

## Base and branch
- Worktree `/work/b53`, branch `ctx-spawn`, base **batch53** (d5062c327). It also holds
  `batch54` (dc28e8445) as a ref.
- Landing (the lead's ladder): f66a1971e went alone, R4 000e335c3 and 0bb96dc18 are in batch 54,
  and A2 31c02d8aa lands in batch 55, built by 54's compiler. Everything after 0bb96dc18 is unsent.

## Commits ahead of batch53 (oldest first)
- f66a1971e features/rt.av regenerated: ctx_reframed takes its slot (sent alone; in batch 53/54)
- 000e335c3 R4 runtime: MARK_FRAME cell mark + row avra_ctx_frame_pushed (Rung; rt.av and avra_rt.h regenerated in it)
- 31c02d8aa A2 ctx step 3b: placed boxes [value, table, frame], restamped at joins, entered at dyn calls; `rehomed` door; framing per entry
- 0bb96dc18 check: the old path sets aside a test program only the program layer builds (idioms fix)
- 0d54db3d8 cases: a spawned method or handler reads its spawn's frame (UNSENT)
- 57efbc947 R5 runtime: entering a made frame lays its pairs OVER the caller's (ruling (b)); evaluator alike (UNSENT)
- 03a7aab3e ctx: every entry judged (program, spec case, host fn) and suites framed from their cases (fixes the services' spec-case spawn trap); lambdas' unmet reads owed at calls; doc 2026_11_16_UI.md capture rule (UNSENT)
- b463b0d1d runtime_header_test counts rows + cell marks (a cherry-pick of 8d67e5e71, which was SENT alone as the batch-54 fix on branch rh-54)

## In flight
Gate for 57efbc947..b463b0d1d on /work/b53 (script /tmp/claude-0/s/gate55.sh, results /tmp/claude-0/gate55.sum).
These PASSED: ctx programs (4), ctx cases 19/19, IR normalized diff 0 vs A2 for closures/term/knob/ui-board/std-ui board,
NET=0 cli, std-ui 1022/1022 + 85 + 1. Still to see: cli suite, idioms (cli, std-ui, std-avrac old path with
AVRA_MEM_POOL_MB=15000), the std-avrac suite (FIRST time it's in the gate: the R4 miss), the witness, rt-ns/rt-header, fmt.
Then bundle 0d54db3d8..b463b0d1d (on A2) for the lead, with receipts.

## Next 3, in order
1. Finish that gate; send the bundle (R5 + every-entry/suite-framing + cases). Note the services repros:
   /work/ctxspawn/ctx_spawn_lambda/src/tests/shrink_test.av now passes 8/8; /work/ctxspawn2 park passes;
   schedule/queue need the services branch's std (`@std.queue.schedule`, `@std.time` cron) to run here.
2. std-ui field/checkbox/dialog (ASSIGNED, ruled): `state value`/`state checked`/`state open` seats (a place
   shares, unplaced is its own, seeded from `initial`; a plain non-place refused) + one plain `shown: T?` seat
   on every control, told each paint, never written. Ruled conditions: a control with `shown` is HELD to it
   after the gesture's handler fires, on every target (the DOM realizer writes it back), with a browser claim;
   refusing `shown` beside a placed `value` names both and says which to drop. Wire/hydration carry `shown ?? value`.
   Callers to update: std-ui tests (board, terminal, components), terminal/headless tests, forms/form_inputs.
3. Then the UI lead's head-seat ask: `component tab(label: string, state chosen: Show)` takes the first head
   value positionally and the rest by name in the block (`tab "All" { chosen: filter }`). Design note to the UI
   lead (through the lead) if not small. After that: ctx steps 4 (cached-fn keys) and 5 (the board).

## Open rulings / asks
- None pending from me. Rulings in force: A2; R4 MARK_FRAME; per-entry gate; `shown` (with conditions);
  R5 laid-over enter; every entry kind judged.
- Known limits to keep in mind: a suite frames from its cases (no entry file); framing skips field/seat
  defaults and trait statics; `rehomed` call sites owe all lambda reads in a program that rehomes.

## Trip wires for a fresh session
- Each compiler finds std BESIDE its binary: build a worktree with a compiler copied into THAT worktree's
  build/ (e.g. build/avra-base), or it compiles against another tree's packages.
- A worktree's build/ needs the runtime objects and archives (build/*.o, *.a). `make` may delete objects;
  restore with `cp -pn <other>/build/*.o build/`. Rebuild build/libavra_runtime.a after any runtime C change,
  or programs link a stale runtime (it cost a segfault once).
- Every row change carries `./avra runtime-namespace > packages/std-avrac/src/features/rt.av` and
  `runtime-header > runtime/avra_rt.h` in the same commit; `make rt-ns rt-header` must pass with ./avra = the new compiler.
- Ladder: a commit adding a row is a Rung (rows + C + test, RtHost.Unhosted), built by the previous product;
  the arms and lowering follow, built by the rung's product.
- The old-path std-avrac idioms check needs AVRA_MEM_POOL_MB=15000 here (16 GB machine).
- Disk is ~25 GB free at best; .avra-cache dirs grow to GBs (cli's ~3-5 GB). Delete caches of idle worktrees.
- IR zero-cost receipt: compare `avra ir` from base vs new, each compiler in its own worktree, normalizing
  lambda numbers and source-site offsets (sed in gate55.sh); raw diffs from moved offsets are expected.
- Kept binaries in /work/b53/build: avra-a2 (A2's product), avra-rungR4, avra-rtns (batch53+rt fix), avra-try (current).
- Scratch: /tmp/claude-0/s/*.sh (gate and build scripts), /tmp/claude-0/*.sum (gate results).
