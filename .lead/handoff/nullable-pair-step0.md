# Step 0: the paired-nullable miscompile — what is known, for (2)'s design

Author: avra-lane-alloc. Status: investigation stopped at its bound; not localized. Read before
laying any nullable flat record as `Maybe(...)` in registers.

## The change that exposes it

One rule in `core/layout.av` `nullable_laid`: a one-word flat record's nullable (`ExprId?`,
`TypeId?`, `Reg?`, any `type X = { f: int }`) laid as `Maybe(carried)` — presence beside the word —
instead of the one-slot box `Boxed(BoxKind.Slot)`. Branches (not for landing): `pair-repro` on
5422d284 and `pair45` / `pair45g` on batch 45c, in /work/avra and the /work/cut45 worktree.

## What the paired compiler does

- gen1 (built by an unpaired compiler, carrying the rule) behaves: its own code is unpaired.
- gen2 (built by gen1, its own code paired) builds, and gen3 == gen2 (fixpoint).
- gen2's OWN old-path lowering sometimes loses facts: `a chain link without its stage survived
  typing` (the stage a chain's typing recorded reads back absent), and the cascade `register rN
  defines out of mint order` (one register never recorded, every later one off by one).
- The count varies run to run on the SAME bytes, cold and warm: std-avrac 641, 1395, 2078, 1, 0;
  std-program 114, 114, then 0 on every later run. At times it fired on a warm rerun after a clean
  cold run. On the night it was last measured it no longer fired at all, in any configuration.
- Unpaired compilers never showed it in any run.

## Ruled out (each with its receipt in the lane's posts)

| Hypothesis | Test | Result |
|---|---|---|
| A cache key hole (another binary's answers) | gen1/gen2 rebuilt with every store and object cache emptied | byte-identical products (`5b475ef9…`, `173d6280…`): the binary is a function of its source |
| Identity key absent from the base | `f5788c3f9` (own_print in every key) | present in both repro trees; absent only from the old WIP base `e271f0548` |
| Machine prints shared across binaries | `~/.avra/cache/prints/<digest>` | per compiler print, trimmed to a budget |
| Use-after-free | `AVRA_RC_GUARD=1` | no stale-box trap |
| An unbalanced pair in the emitted module | every `{ i1, … }` pack in gen1's paired cli module | 1323 presence-first packs, every one followed by its word insert; absent pairs fold to zeroinitializer |
| A load of a pair before its store | `opt -passes=mem2reg` on the paired module | no phi takes an undef pair |
| Indirect-call fn-type mismatch | each indirect call's type vs every address-taken definition | 0 unmatched |
| Optimizer UB (-O0 clean, -O1 not) | `AVRA_PROGRAM_MODE=release,opt=-O0` | 0 vs 114 once; RETRACTED: the -O1 binary later gave 0 under identical settings |
| Torn read across processes | `AVRA_WORK_AHEAD_OFF=1`, `AVRA_WORK_AHEAD_CORES=1`, with and without `AVRA_WAVE_ALONE=1` | 0 everywhere — but nothing fired that night without them either, so it isn't decided; the two check processes share exactly one 4 KB page |
| The Saved derive misreading a pair | `saved_derive.av` | type-driven (`value == null` / `holds_child_at`), ordinary code the same compiler lowers on both sides |
| Undef word from `pack_value` (parallel-main's lead) | per-pack scan above | no absent pair in the module lacks its word insert; zero-fill test not run (nothing fired to compare) |

## What remains

A fact computed or read differently between runs inside the paired binary, with a trigger that
moves with state not yet identified. Every static check of the emitted module is clean, so the
next probe needs a dynamic hook, run while it fires: the old path's `mark_stage` / `stage_at`
pair (features/facts.av) logging the expression and table window on every write and read, so the
first stage lost is caught where it goes missing rather than where the lowering trips over it.

## What (2) must carry

1. **A stress acceptance, not a single run.** `check` of std-avrac and std-program on a cold store,
   then warm twice, three times over, all at 0; and the same under `AVRA_WORK_AHEAD_OFF=1
   AVRA_SCHED_SEED=0`. One clean run proved nothing here.
2. **Zero-fill every aggregate part no element fills** (parallel-main's rewrite does this by
   design). Even where no pair is affected, the module holds partial packs of other shapes
   (`{ i1 false, i64 undef, i1 undef, i64 undef }`), and anything that hashes or compares words
   must never read undef.
3. **The regression:** two absent `ExprId?` values fingerprint, compare and save equal; a
   `SideTable<V?>` at a paired `V` written, folded (`lay`) and read back keeps every cell.
4. **Keep every built binary** under a unique name. The first failing gen2 of this investigation
   was overwritten by a rebuild, and could never be examined again.
