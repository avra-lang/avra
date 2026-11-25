# HANDOFF — avra-lane-parallel-main

## Lane and scope
`avra-lane-parallel-main`: program-layer query engine and pack performance, the compiler's own RC traffic
(architecture item #10), and urgent measurements for the lead. Reports to the lead through the bridge. Rules:
commit on own branch, push nowhere, no `rm` (use `find -delete`), no stash, no `reset --hard`, no `--no-verify`,
fmt touched `.av` files, one heavy build at a time, idioms check with 0 NEW sites.

## Base
batch 53 = `d5062c32` (its prerequisite is `d750dfa7`). The bundle `/work/handoff/lane.bundle` holds 3 branches,
cut against `^d5062c32`.

## Commits ahead of d5062c32

### Branch `avra-lane-parallel-main` (for batch 54)
- `751ef11d` A value of parts is held and passed as its leaves; a level-0 object answers one through a lent pointer
  (leaf scalars; gate.sh conflict resolved as a union adding `level_mix_attack`)
- `a391030b` Every pack keeps its tables' slots: a lookup probes, never searches (pack hash index, seal `avrapak7`;
  `avrapak6` still read)
- `0f078f1c` tools/bodies_wave.sh: the bodies wave's table, by query family on the engine's clock

### Branch `lent-answers` (on top of 0f078f1c)
- `56654d45` WIP: lent answers. **Never compiled yet.**

### Branch `rc-kinds` (on top of 0f078f1c)
- `76d99c36` WIP: census by kind (`AVRA_RC_KINDS`). A measurement instrument; not meant to land as is.

## In flight
1. **Proof R53 of the batch-54 branch** (`OLD=$PWD/build/avra-base bash /work/lane/proofR.sh R53` in `/work/avra`).
   Summary: `/work/lane/proof-R53/summary`, copied to `notes/proof-R53-summary.txt`.
   - Passed so far: binary held to itself (ahead off, after dev, 1/2/3 cores); findings; fixed point;
     the dev-built cli; gen2; the verified build; guarded verdicts identical to base (90 ok, 13 BUILD-FAIL, 2 DIFF on both).
   - Was in "suites and witnesses" when the session ended.
   - The batch-54 bundle was NOT sent yet. To send it: finish or rerun the proof, then
     `git bundle create /work/avra-lane-parallel-main.bundle avra-lane-parallel-main ^d5062c32` and post the path.
2. **#10, lent answers (step 4)**: design posted and APPROVED. The code is written in commit `56654d45`, never built.
   - Where the mark lives: `SeatMark.lent` (core/types.av; not part of type identity / `mark_word`).
     It is inferred per lowered instance in `item_lowered.av` (`lendable_seats`, `in_own_impl`) from the IR by
     `memory.av` `lent_seats`/`answer_chain`. Every answer must be a field/index/arm projection of an eligible
     seat, every chain register `.Boxed` with no cell, and no chain register written in place.
   - How it travels: `LoweredFn.lent` → `BodySeen.lent` → `seat_marks()` in item_program.av.
   - Caller side: `lent_reads` rewrites `Call(dst)` into `Call(tmp)` + `CallRt(dst, "avra_lent_view", [src, tmp])`,
     one per lent seat, chained. The new rows are in runtime_api.av, with the C bodies in avra_hot.c and the
     interp host `RtHost.LentView`. Twin-or-view is decided by the existing machinery, plus two rules:
     - `lent_exposed`: a source reaching a cell takes the owned twin;
     - `held_over`: releases of views held across the call wait until after the lent views.
   - Callee side: `lent_answer` chain registers take no owned twin, no yield retain, no adoption, no merge
     management, and no early-answer retain.
   - Soundness (soundness.av): `lent_chain` treats a verified chain as immortal; `read_as_lent` means a lent call's
     tmp is not owning; `unlent_reads` is a defect for a view read over a seat the callee doesn't lend.
   - Attack test: `features/fns/tests/lent_answers/` (`.expected` reasoned by hand). It covers overwritten,
     rebound, consumed, yielded, stored in a cell and in a list, temporaries, two seats, early returns, a `mut` seat
     emptying the source, the arena methods, recursion, dyn, a fn value, and the generic `head<string>`/`head<int>`.

## Next 3 items, in order
1. Build `lent-answers` (`AVRA_FRAME_POINTERS=1 make try` in a worktree; a compiler copied into the tree's `build/`).
   Fix compile errors. Then:
   - run lent_answers under `avra test` (eval == native) and under `AVRA_RC_GUARD=1`;
   - run `/work/lane/guarded.sh`;
   - run `AVRA_SOUND_CHECK=1` on a cli build;
   - add the lead's extra attacks if not covered (both-lent arms: done as `either`; generic per instance: done as
     `head`, which could be strengthened);
   - measure the cut with the rc-kinds census;
   - post, then run the full proof (`proofR.sh`).
2. Finish proof R53 and send the batch-54 bundle (above).
3. #10 step (3): move at last use, extended. Expected about 0.16 G retains: outer-scope owned 0.03, params 0.12
   (needs consumed marks), dying pack parts 0.04. After that, reuse-in-place for record rebuilds (not yet measured).

## Open rulings and asks
- Lead approved (4) and then (3). Conditions on (4):
  - the mark is inferred, never written by the user;
  - it is part of the signature facts;
  - the GUARD attack suite, eval == native, and soundness proof all pass.
- Two extra attacks were asked: arms projecting different seats, and a generic whose instances differ.
- One deviation from the posted design, to tell the lead: the mark is inferred from the lowered IR per instance,
  not the AST. That makes it exact per generic fill and consistent with the memory pass.
- Bisect results were posted. The lead routed both law_findings regressions to resolve-2: fc14b4b6 is fixed by c0493354;
  3d48160f's generator forcing is still open.

## #10 numbers (cold cli build, ONE process via `taskset -c 0`)
- Retains 3.40 G and releases 4.65 G in total. By kind (`notes/census-kinds1.out`, `census-kinds2.raw`, `census-kinds3.raw`;
  read them with `python3 notes/kinds.py <raw>`):
  - owned reads 1.33 G real: yielded 0.76, held across a call/bracket 0.57, into a cell 0.28, answered 0.10;
  - consuming seats 0.91 (a borrowed view 0.50, read again after 0.29, a param 0.11);
  - cell stores 0.24; loads outliving the cell 0.20; yields 0.19; packs 0.14;
  - releases: reclaim cascades 1.38, cells 0.20.

## Trip wires
- **Disk allowance**: about 39 GB. Delete `packages/cli/.avra-cache` in old worktrees; `/work/avra-fp` and
  `/work/avra-b` (bisect trees) are deletable.
- **The census sums RSS across forks**. Run it as
  `taskset -c 0 env CENSUS_CAP_MB=14000 CENSUS_BUILDER=<builder> sh tools/census.sh build packages/cli`.
  The census only reports the parent process, so forks lose counts.
- **Kinds census builder**: `notes/kb.sh` sets `AVRA_RC_KINDS=1` for the builder only.
- **`make try` in a worktree** can leave `build/llvm_wrapper.o`, `ffi.o` and `std_*.o` missing. Rebuild them with
  `make build/llvm_wrapper.o build/ffi.o build/std_io.o build/std_io_watch.o build/std_net.o build/std_process.o build/std_time.o`.
- **"No std stands beside this compiler"**: run compilers from inside a tree's `build/`.
- **Kept binaries in `/work/avra/build`**: `avra-try` (the batch-54 branch) and `avra-base` (batch 53).
  The bisect compilers are in `/work/bisect/`.
- **`LLVM_PREFIX=/usr/lib/llvm-22`**; `. /etc/profile.d/avra.sh`.
- **Worktrees**: `/work/avra-lent` (lent-answers) and `/work/avra-kinds` (rc-kinds).
