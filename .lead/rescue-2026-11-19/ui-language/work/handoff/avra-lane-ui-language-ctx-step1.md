# avra-lane-ui-language: ctx step 1, as R then S

Two bundles, one per landing, as the ladder asks (CLAUDE.md: a row the compiler's own source reads
can't be gated in the commit that adds it).

- **R** — `/work/avra-lane-ui-language-ctx-R.bundle` = `batch45c..avra-lane-ui-language-ctx-rows`.
  Bundle 6's commits (through 60d84aa1), then **ed53cbb9** "runtime: the contexts a task runs under,
  as rows", with a `Rung:` trailer. It holds:
  - the three rows `avra_ctx_read`/`avra_ctx_set`/`avra_ctx_back` in `rt_sigs`, `RtHost.Unhosted`;
  - their C bodies in avra_runtime.c, with the guard saving and restoring the frame (avra_guard_run);
  - `AVRA_SLOT_CTX = 2`;
  - the generated avra_rt.h claims;
  - runtime/tests/ctx_frame_test.c: 16 checks covering read/set/shadow/back, memory back to its
    baseline, a caught trap under two sets restoring the guard's frame, and a guarded body that
    ends.
- **S** — `/work/avra-lane-ui-language-ctx-S.bundle` = `avra-lane-ui-language-ctx-rows..ctx-step1`.
  **d0b4af70**, on R. It holds:
  - `RtHost.CtxRead/CtxSet/CtxBack` and the evaluator's arms; the evaluator's guard keeps and
    restores the frame too;
  - the `ctx` soft keyword, `CtxDecl`/`CtxSet`/`CtxRead` nodes, typing, lowering, and the
    `Ending.Restored` scope end;
  - the old path's refusal (`ctx.old_path`), `NewOnly.Ctx` (the net steps aside), and the laws
    `ctx.unknown` and `ctx.where`;
  - export/import by name, and the formatter's forms;
  - the soundness walk's binding `ctx` renamed `facts`, because `ctx.x` always reads a context.

Ladder proven here: R built by the base compiler (batch38's avra-base), S built by R's product.

## What step 1 is
- `ctx name: T = v` at a module's top level declares a context. It's required where no `= v` is
  written (step 2 checks this; step 1 traps at a read nothing set).
- `ctx name = v` sets it until its scope ends, by any way out (block end, `return`, a loop turn's
  end, an unwind).
- `ctx.name` reads what the nearest set still in force gave it, else the default, kept once as a
  module `state`'s start.
- The frame lives in the running task's context slot: `[prev, key, cell, key, cell, …]`, never
  written once made. The key is a number of the declared symbol, so a library's context has one key
  in every program.
- A spawned task starts from an empty frame (capture is step 3).

## Cost, for step 2 to decide
- A set copies the frame's distinct pairs (shadowed ones dropped) into a new frame of 1 + 2k words,
  where k is the number of contexts set at once.
- A read walks those k pairs.
- So both cost the number of distinct contexts in force, **not** the depth of nested sets. Nesting
  depth costs memory only: each frame holds the one it replaced until its scope's back.
- The board sets one context (k = 1); an app with theme, locale and log has k = 3.
- If step 2 wants O(1) reads it can number contexts densely per program. That would tie units to a
  program, which this keying avoids.

## Receipts (S's product, built by R's)

| Receipt | Result |
|---|---|
| ctx program tests | frames, trap_back: eval == native == expected |
| refusal cases | ctx_unknown, ctx_declared_in_body, ctx_set_at_top, ctx_set_mistyped, builds_ctx_imported: 5 of 5 hold, all held on the layer alone (new-only) |
| runtime C tests (`make runtime-tests`) | all pass, ctx_frame_test 16 checks |
| `AVRA_PROGRAM_NET=0 build packages/cli` | exit 0 |
| std-ui suite | 1022/1022, 83 programs proved |
| std-ui check | clean |
| std-relation and std-program checks (they bind a `ctx`) | clean |
| idioms | cli exit 0, std-ui exit 0 |
| fmt --check | 50 touched files clean |

## Found on the way (not this lane's to fix)
An or-pattern that binds one name at two nullabilities (`.Return(v) or .CtxSet(_, v) -> v`, `v` both
`ExprId?` and `ExprId`) is accepted, and the compiler built from it segfaults. It should be refused at
the pattern.

## Next
- Step 2: `ctx_reads`, the required check at entries (dyn rule (i)), the unread-set warning.
- Then step 3 (capture), step 4 (cached-fn keys), step 5 (the board).

---

# ctx step 2 (478bce5e, on S)

`/work/avra-lane-ui-language-ctx-S.bundle` = `avra-lane-ui-language-ctx-rows..ctx-step1` now carries S
(d0b4af70) and step 2 (478bce5e). They land together, after batch 47.

- **What a program reads** (compiler/item_context_reads.av) is read off the lowered code. The lowering
  now marks each set by its statement, each call through a `dyn` box by its method, and each method a
  box takes (which makes no fn value). Reads are owed:
  - at a call;
  - at the point a lambda or fn value is made;
  - at a `dyn` call, the reads of every boxed type's method of that name (rule (i)).
  Branches and loops scope their sets, and a recursion settles by asking again (≤ 8 rounds).
- **`ctx.required`**: a required context the program reaches with nothing setting it is refused where
  the program starts, with the chain. Through a `dyn`, the refusal names the type whose method reads it:
  "`db` is required, and this program reaches `ctx.db` with nothing setting it (`drawn` → `show`):
  `Report` reads it, and a `dyn Shows` called there may be it". Both cures are in its help.
- **`ctx.unread`** (warning): a set nothing under it reads.
- **Cost:** the survey runs only for a program that declares a required context (the entry check),
  and for an item that writes a set (the warning). A program without contexts pays nothing.

## Proofs

| Proof | Result |
|---|---|
| new cases | ctx_required_unset, ctx_required_dyn, builds_ctx_required_set (prints 4), builds_ctx_set_unread (warns, prints 1) |
| all 9 ctx cases | hold |
| step 1's programs | frames and trap_back draw no warning |
| receipts | std-ui 1022/1022 + 83; NET=0 cli exit 0; idioms cli + std-ui 0 NEW; fmt 58 files clean; witnesses_test 13/13 |

## Limits, so the next steps can decide
- **Entries:** the program's entry is the only one judged so far. A test, an exported host fn and a
  detached task are not judged as entries yet. An owned spawn's body counts where it is made, which is
  step 3's inheritance.
- **dyn impls:** found as the types the reached code boxes in a `dyn`, matched by method name, not by
  trait. This is sound, but may name a type boxed for another trait whose method has that name.
- **Unread warning:** covers fns and their lambdas; methods and component bodies are not covered yet. A
  missed warning is the cost, never a false one.


---

# On batch48: R's reach fix, S, step 2, and the slot fix

`/work/avra-lane-ui-language-ctx-S.bundle` = `batch48..avra-lane-ui-language-ctx` (tip 459e37f2).

- **0c98badb** (on ed53cbb9, R's fix, sent alone first): the ctx rows reach the world. The test's
  `worldly` names `avra_ctx_*`, and the world count is 93.
- **95235687 S**, **ef97f4cd step 2**: as before, rebased on 0c98badb.
- **05e9499b**: a `dyn` call reads by the trait method's slot, never by name.
  - Each box marks the type it holds and the method of that type in each of the trait's slots.
  - Each dyn call marks its slot.
  - A call reads the method each box of the same trait type (compared by declaration) holds in that
    slot.
  - New case builds_ctx_dyn_two_traits: `Shows.show` and `Draws.show`; only `dyn Shows` is called,
    and `Report` (a `Draws`) reads a required ctx. It builds and prints, where name matching would
    have refused it.
- **459e37f2**, the merge of batch48. item_generators (`Component` → true, `Ctx` among the false
  kinds), and item_annotations' new match (`Ctx` → "a context").

## Receipts

| Receipt | Result |
|---|---|
| ctx cases | 10 of 10 hold |
| ctx programs | 2 proved |
| runtime_reach_test | 3/3 |
| std-ui | 1022/1022 + 83 |
| NET=0 cli | exit 0 |
| idioms | cli + std-ui 0 NEW |
| fmt | 61 files clean |
