# avra-lane-lowering-rows-b — hand-over

Branch avra-lane-lowering-rows-b-3, on next-base cd4738e6 (head: the commit adding this file).

DONE and handed back:
- avra-lane-lowering-rows-b.bundle: rows-b (or-pattern binds, unions, walk stages, capture lanes, dyn writes, format scan). LANDED.
- avra-lane-lowering-rows-b-walkfix.bundle: the `while` + early-ending walk crash. LANDED.
- avra-lane-lowering-rows-b-2.bundle: typed format holes, single scan, pattern homes, inferred error `Result<T, _>`. LANDED in 15c4576b.
- avra-lane-lowering-rows-b-3.bundle (cd4738e6..branch): union order across packages (reader's own first) + 19 kind-pinning program tests. Sent, waiting for a batch.

IN PROGRESS: nothing (nothing was in flight at the stop order). Final bundle: /work/avra-lane-lowering-rows-b-final.bundle = cf1b3e2c..avra-lane-lowering-rows-b-3. To resume: fetch it, merge onto the current trunk, re-run the infer cases + the 19 kind tests + the cli self-build. The branch builds; the receipts were green on cd4738e6 (infer cases 9/9, 19 tests made, cli self-build 0, AVRA_SOUND_CHECK=1 AVRA_PROGRAM=1 build packages/cli 0 defects).

Findings not yet acted on:
- Old path: `~x` in any program test makes `avra test` abort ("@std/avrac:src/features/expr_spine/semantics.av does not exist"). Recorded, not fixed (the old path is being replaced).
- Union order among SEVERAL dependency packages is unprobed (they sort by package:path).
- The kind table: every body-level kind probed with a valid program builds; Env has no grammar rule.
- Commit fba2d766's message mentions a spread law fix that the cf1b3e2c merge replaced with decl-shape's.

Files others must not touch: none held.
