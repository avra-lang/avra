# HANDOFF — evalrc4 / avra-8sb5.1.24.3 (evaluator frees aggregates; UNION over-free)

Written 2026-10-02 by `evalrc4` on request. **Not close to done** — the trap is
reproduced and narrowed to one line, but the cause is not yet pinned and no fix
has landed.

## Where things are

- Worktree: `/Users/tristan/projects/tristanMatthias/avra-eval-rc`
- Branch: `eval-rc` @ `2e8e93b` ("fix(eval): hold a box a live task names; budget the h2 park")
- PR **#196 is DRAFT** — keep it draft until `sh tools/work test` is green.
- Commits on the branch: `f234dc7` (free aggregates at zero refs) + `2e8e93b` (the `named_by_task` guard + h2 timing budget).
- **Uncommitted local change**: `packages/std-avrac/src/compiler/backend/interp.av`
  has my TEMPORARY instrumentation (13 insertions, 2 deletions). It must be
  reverted before any commit/land. `git diff` shows it; it is:
  - a `probe_tag(site, tag, counted)` helper that eprintlns when `tag < 0 || tag >= 64`,
  - calls to it in the `avra_array_push_tagged` / `avra_slot_set_tagged` arm of `kept_seat`,
  - a call to it in `enum_boxed_val`.
  Revert with `git checkout -- packages/std-avrac/src/compiler/backend/interp.av`.
- No other dirty/untracked files. `git status --porcelain` = that one path.

## Objective (from the ticket + BOSS brief)

Find the UNION over-free in the evaluator freeing change, fix the imbalance,
prove `avra test packages/std-avrac` is STAT=0 and `sh tools/work test` green,
add a focused regression test for the union case, then (with the guard +
eval-aware timing) measure std-http suite wall time cold and land #196.

## Reproduction (WORKS, reproduces every time)

Run **on a Sprite** (never locally). Compiler is content-hash cached on the
Sprite, so after the first build a probe is ~28s.

```
cd /Users/tristan/projects/tristanMatthias/avra-eval-rc
AVRA_SPRITES="avra-cores avra-phase-c avra-phase-d avra-reuse" \
  sh tools/work run "build/avra run packages/std-avrac/src/features/results/tests/error_union/error_union.av; echo EXIT=\$?"
```

Output tail:
```
avra: a shift count must be between 0 and 63
EXIT=2
```

Wider evidence (from ticket comments, not re-verified this session):
`build/avra test packages/std-avrac` → prints `199 rule examples proved` then the
same trap, exit 2. Scope: `.../src/features` traps; `.../src/compiler` and
`.../src/features/expr_spine` pass. `f234dc7` alone (without the guard) reproduces
identically, so **the guard is exonerated**; the defect is in the freeing commit.

## THE KEY FINDING so far (new this session)

I instrumented the three callers of `counted_word` (interp.av): `kept_seat`'s two
`*_tagged` rows and `enum_boxed_val`. The trap fires exactly once:

```
TRACE push_tagged tag=2569 counted=0 arrays=19
avra: a shift count must be between 0 and 63
```

So the failing shift is in the **`avra_array_push_tagged`** path
(`kept_seat("avra_array_push_tagged", vals)` → `counted_word(whole(vals[2]), whole(vals[3]))`),
**not** `enum_boxed_val`, and:
- `tag = 2569` — a **global TypeId index**, not a small variant tag.
- `counted = 0` — `counted_mask(ty)` is 0 for whatever `ty` push_leaf computed.
- `arrays = 19` at the moment of the trap.

`avra_array_push_tagged` is emitted only from `push_leaf` / `leaf_write`
(`packages/std-avrac/src/features/values.av:375-405`):

```
mut fn push_leaf(box: Reg, v: Reg) {
    let ty = self.out.type_of_reg(v)
    if !self.valued(ty) { return self.push_slot(box, v) }
    let tag = self.extracted(v, 0, self.mint_shape(Type.Int))   // <-- 2569
    self.array_push(box, tag)
    self.array_push_tagged(box, self.extracted(v, 1, ...), tag,
                           self.const_int(self.view.types.counted_mask(ty)))
}
```

`valued(ty)` is `Types.valued_carrier(ty)` (features/emit.av:261), which is
`is_valued(machine_type(ty))`, else `.Opt(inner)` of a valued type, else false.
For a **union** it *should* be false (its shape is `.Union`). So the value `v`
whose slot 0 is `2569` reached the tagged path either because:

- **(A) `valued_carrier(unionType)` returned true** — the union's TypeId was
  marked `valued` in the layout registry (`mark_valued` is called only from
  `Decls.laid_out` for declared ENUMs, features/decls.av:1697; a union is
  `intern(Type.Union([...]))` and should never be marked) — i.e. a real
  layout/`valued` bug, or
- **(B) the static type `ty` really is a value enum, but the runtime register
  holds a *union* box** — i.e. a value-flow / over-free type confusion (the
  over-free framing in the ticket).

`2569` is almost certainly `fsides.err.index` — the plain member enum's global
TypeId — which is exactly what `propagated` writes into a union box's slot 0:
see `features/values.av` `fn propagated` (~line 696):

```
mut fn propagated(r: Reg) -> Reg {
    ...
    // A PLAIN member meeting a UNION promise is the one real mismatch — it is
    // LIFTED into the union's own tagged box.
    .tagged_value(self.view.types.shape_of(isides.err), fsides.err.index, [payload])
}
```

`tagged_value` (features/values.av:539) writes `const_int(tag)` at slot 0 and
lays the payload with `push_leaf`. So **a union box's discriminant is a global
TypeId** (by design, per the doc comment on `propagated` and
`switched_union_reg` in features/results/lower.av). That tag then feeds
`counted_word`'s `>>` when the union box is laid as a leaf into an enclosing
tagged box. `counted_word` is NEW in `f234dc7`:

```
fn counted_word(tag: int, counted: int) -> bool {
    tag >= 0 && (counted >> tag) & 1 != 0
}
```

**This may therefore NOT be an over-free at all.** The new `counted_word`
assumes `tag` is a small variant index (0..63). Any path that lays a union box
(a `tagged_value` whose slot 0 is a TypeId) as a value-enum leaf will shift by a
TypeId and trap — independent of refcounts. The clean compiler passes only
because `counted_word` does not exist there. This contradicts the ticket's
"over-free reused a union box's slot" framing and should be **verified before
chasing refcount balance**.

## NEXT STEP (cheapest decisive probe)

Distinguish (A) vs (B) with one more instrumented run. In `push_leaf` (and
`leaf_write`), when `tag >= 64`, print `ty.index` and the shape kind:

```
let tag = self.extracted(v, 0, self.mint_shape(Type.Int))
if self.whole(tag) >= 64 {
    let kind = match self.view.types.shape_of(ty) {
        .Union(_) -> "union", .Enum(_, _) -> "enum", .Res(_, _) -> "res",
        .Opt(_) -> "opt", rest -> "other",
    }
    eprintln("TRACE push_leaf ty=${ty.index} kind=${kind} valued=${self.valued(ty)} counted=${self.view.types.counted_mask(ty)} tag=${self.whole(tag)}")
}
```

- If `kind=union` and `valued=true` → **hypothesis A**: find why a `.Union`
  TypeId is `is_valued`/`valued_carrier` true. Check `mark_valued`/`laid_out`
  and whether `intern(Type.Union)` can collide with, or be handed, a declared
  enum's TypeId. Fix in the layout/`valued` predicate (union must never be a
  value-enum leaf); this is a `values.av` layout fix, probably not a refcount
  fix.
- If `kind=enum`/`opt` and `valued=true` but the value on the register is a
  union box → **hypothesis B**: value-flow corruption; then pursue the over-free
  (see sites below). The `named_by_task` guard already scans frames; a
  register-holding-a-wrong-box is a different defect (a missing retain letting
  the box be freed and the register reused, or a Release on a value still held).

Either way, the likely *minimal correct* fix for the shift itself is to make
`counted_word` total — but per CLAUDE.md, do NOT paper over it with a guard that
hides a real over-free. The tag being a TypeId is the tell; decide which of A/B
is true first.

## Candidate over-free sites (from f234dc7) — if hypothesis B wins

All in `packages/std-avrac/src/compiler/backend/interp.av`:
1. `slot_written` — `self.releases_val(self.arrays[id][at])` before `set`.
   Possibly releases an element the same value still names (self-assignment /
   reuse-in-place).
2. `map_write` — `if s >= 0 { self.releases_val(entry.vals[s]) }` before
   overwriting the old map value.
3. `cell_unique_val` — clones `held`, stores the clone, then
   `self.releases_val(held)`.
4. The Lift widen path: `propagated` / `tagged_value` / `enum_boxed_val` child
   retains (`enum_boxed_val` retains `vals[1]` when `counted_word` says the
   variant carries a counted word).

Balance witness ideas: a temporary count-balance trace in `retained`/`released`
printing `(id, count)` transitions, or an assert in `reclaimed(id)` printing the
id, `kids.length` and contents. `named_by_task` already guards boxes live tasks
name, so if the union trap persists with the guard, the offending box is not
named in any frame at free time (a genuine over-release or a missing retain).

## Commands / environment notes

- Sprite pin: `AVRA_SPRITES="avra-cores avra-phase-c avra-phase-d avra-reuse"`.
  (`avra-unions-p2` is excluded/broken.)
- `sh tools/work test` → builds the branch compiler on Sprites and runs affected
  suites + idioms baseline.
- `sh tools/work run "<cmd>"` → runs one command on a Sprite against this
  worktree. The Sprite tree is `/home/sprite/avra-build/avra-eval-rc/tree`;
  compilers cache under `/home/sprite/avra-compilers/<source-hash>/`.
- First instrumented build after a source edit: `compiler=built build≈20s`,
  run `≈28s`. Repeated identical source is instant (`compiler=cached`).
- Owner rule: nothing over ~2 min except a full test run (~5 min) on a Sprite.
  Scratch `./avra check /tmp/x.av` is sub-second and local-safe; do NOT run
  `make gate` / `make avra` / `make test` locally.
- BOSS intercom: `01a0f8d7` (`subagent-chat-01a0f8d7-efe6-723f`).
- Ticket db: `export TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db; tasks show avra-8sb5.1.24.3`.

## File/line map

- Trap site: `packages/std-avrac/src/compiler/backend/interp.av:1776` `counted_word`;
  callers `kept_seat` (~1752-1753) and `enum_boxed_val` (~1780).
- Freeing machinery: same file — `fresh_array` (~1668), `retained`/`released`
  (~1680-1700), `reclaimed`/`named_by_task` (~1702-1725), `kept_seat`,
  `answer_owned`, `shares_answer`, `cell_released`/`cell_forgotten`,
  `slot_written`, `map_write`, `cloned_val`, `propagated`-related.
- `named_by_task` helper `names_box` in `.../backend/interp_host.av`.
- Union lift: `packages/std-avrac/src/features/values.av` `propagated` (~696),
  `tagged_value` (~539), `push_leaf`/`leaf_write` (~375-405),
  `valued` (features/emit.av:261), `valued_carrier`/`is_valued`/`counted_mask`
  (core/types.av:403-435), `mark_valued` (core/types.av:557,
  called from features/decls.av:1697 `laid_out`).
- Union catch switch: `packages/std-avrac/src/features/results/lower.av`
  `switched_union_reg`.

## Lessons learned (for evalrc5 and future lanes)

- **`counted_word`'s contract is untested for non-variant tags.** It is written
  for a value-enum variant index (0..63) but is reachable with a union box's
  discriminant, which is a GLOBAL TypeId by design (`propagated` writes
  `fsides.err.index` into slot 0). The new code assumed the old invariant held.
  The clean compiler never trapped because `counted_word` did not exist there —
  "the trap is new so the bug must be in the new thing" is only half true: the
  new code revealed a pre-existing freedom (a TypeId used as a tag), it did not
  necessarily create it.
- **A tag that is a TypeId should be a smell, not a number to bound.** The
  ticket framed this as an over-free; instrumenting the three callers in 5 min
  moved it from "audit 4 refcount sites" to "one line with a TypeId". Always
  get the actual failing argument before auditing a mechanism.
- **Sprites cache the compiler by source hash.** First probe after an edit ≈ 50 s
  (20 s build + 28 s run); every repeat is ~28 s. Budget probes, not builds.
- The `named_by_task` guard is NOT the cause (f234dc7 alone traps); do not spend
  time there.

## Tickets touched

- `avra-8sb5.1.24.3` — [BUG] evaluator never frees an aggregate. State:
  **IN_PROGRESS, not merged.** PR **#196 DRAFT**. Nothing to close.

## Open questions / blockers

1. Hypothesis (A) vs (B) in "NEXT STEP" above is undecided — run the `push_leaf`
   probe first. Do not start "fixing refcounts" until it says (B).
2. If the fix is in `counted_word`, per BOSS: it must refuse a TypeId as a shift
   WITHOUT broadening into a catch-all that swallows arbitrary tags.
3. After the trap fix, the remaining landing blockers from earlier lanes still
   stand: h2_body_wakes timing budget (already applied in `2e8e93b`), a focused
   union regression test, and a cold std-http wall-time measurement.

## Close-out (2026-10-06, owner directive)

- WIP committed as `wip: evalrc4 handoff + union-trap instrumentation` and pushed
  to `origin/eval-rc` so nothing lives only in this worktree.
- Worktree and branch LEFT IN PLACE for BOSS cleanup, as instructed.
- Temp instrumentation is in the WIP commit and MUST be reverted (or built on)
  before any landing.

## State summary

- Reproduced: YES (exit 2, shift trap).
- Narrowed: YES — `avra_array_push_tagged` with `tag=2569` (a TypeId), `counted=0`.
- Hypothesis written; decisive next probe specified above.
- Fix: NOT started.
- Regression test for the union case: NOT added.
- std-http wall-time measurement (cold): NOT done.
- PR #196: still DRAFT; local instrumentation must be reverted before commit.
