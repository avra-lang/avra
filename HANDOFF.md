# HANDOFF — evalrc5 / avra-8sb5.1.24.3 (evaluator frees aggregates)

Written 2026-10-06 by `evalrc5` at lane close-out. **Not landed.** The
union trap is now ROOT-CAUSED (not an over-free at all). Read this whole
file; it supersedes evalrc4's HANDOFF (which ended at "hypothesis A/B,
next probe specified").

## Worktree / branch state

- Worktree: `/Users/tristan/projects/tristanMatthias/avra-eval-rc`
- Branch: `eval-rc`, base `2e8e93b`. PR **#196 is DRAFT** (open, not queued).
- Commits: `f234dc7` (free aggregates at zero refs) + `2e8e93b` (the
  `named_by_task` guard + h2 timing budget) + the WIP commit on top of this
  handoff (diagnostic TRACE probes).
- **Diagnostic probes are committed as WIP and MUST be reverted before any
  landing**: `packages/std-avrac/src/compiler/backend/interp.av` (`probe_tag`
  + its 3 call sites) and `packages/std-avrac/src/features/values.av`
  (TRACE prints in `push_leaf`/`leaf_write`/`tagged_value`). Revert with
  `git checkout 2e8e93b -- packages/std-avrac/src/compiler/backend/interp.av
  packages/std-avrac/src/features/values.av`.

## THE FINDING (decisive, reproduced on Sprite `avra-reuse`, compiler hash 3f18e55f)

The trap is **NOT an over-free**. It is a **mis-tagged value produced by
`propagated` on the union→plain narrowing path**.

Repro (one command, ~30s once built):

```
cd /Users/tristan/projects/tristanMatthias/avra-eval-rc
AVRA_SPRITES="avra-cores avra-phase-c avra-phase-d avra-reuse" \
  sh tools/work run "build/avra run packages/std-avrac/src/features/results/tests/error_union/error_union.av 2>&1 | tail"
```

Trace tail (with the probes in place):

```
TRACE tagged_value ty=2573 name=Result<int, NotFound or Timeout or Denied> tag=1
TRACE tagged_value ty=808 name=Timeout tag=2569          <-- BAD: dest shape Timeout, tag = union TypeId 2569
TRACE push_leaf ty=808 name=Timeout counted=0
TRACE push_tagged tag=2569 counted=0
avra: a shift count must be between 0 and 63
```

### Mechanism

`selective(kind) -> Result<int, Timeout>` does
`let v = two_member(kind) catch .NotFound(e) -> -1`.
`two_member` returns `Result<int, NotFound or Timeout>` (union TypeId **2569**).

The catch lowers via `switched_union_reg` (`features/results/lower.av:96`).
Its SELECTIVE default arm calls `cx.propagated(r)` to re-raise the unmatched
member into the enclosing fn's return type `Result<int, Timeout>` — i.e. a
**union → plain** conversion.

`propagated` (`features/values.av:696`) assumes the ONLY mismatch is
plain-source → union-destination:

```
self.tagged_value(self.view.types.shape_of(isides.err), fsides.err.index, [payload])
```

- `isides.err` = the DESTINATION side (here plain `Timeout`, 808)
- `fsides.err` = the SOURCE side (here the union, 2569)

For the documented widening (source plain, dest union) that is right: the
union's discriminant IS the plain member's global TypeId. For the narrowing
(source union, dest plain) it is **backwards**: it builds an array shape
tagged with the union TypeId 2569 and presents it as a plain value enum
`Timeout`. A plain `Timeout` value must be `[variantTag=0, word]`, not
`[2569, 0, word]`.

That value is then laid as a leaf (`push_leaf`, `features/values.av:375`):
`ty = Timeout` is a value enum, so it extracts slot 0 as the tag → **2569**.
`avra_array_push_tagged(box, word, tag=2569, counted=0)` is emitted.

- **Native** (`runtime/avra_runtime.c:1816` / main:1971) does
  `(counted >> 2569) & 1` — undefined C shift, silently shifts by 2569&63,
  and because `counted == 0` answers false → pushes raw. **Silently wrong
  but non-trapping; the defect exists on clean main natively too.**
- **Evaluator** (`f234dc7`'s `counted_word`, `interp.av:1786`) does
  `counted >> tag` in Avra, whose shift traps for count ≥ 64.

So: `counted_word` did not INTRODUCE the defect; it EXPOSED a pre-existing
mis-tagging bug by trapping where native silently shifted. The evaluator is
the messenger.

### Why `counted == 0`

`counted_word(tag, counted)` = "does variant `tag` carry a counted word".
For the mis-tagged value `ty = Timeout`, `counted_mask(Timeout)==0` (Timeout's
payload is an `int`). Consistent.

## THE FIX (not started — precise proposal)

Fix in `propagated`, NOT in `counted_word`.

`propagated`'s lift branch must distinguish the two directions:

- source plain, dest union (widening): unchanged —
  `tagged_value(shape_of(isides.err), fsides.err.index, [payload])`.
- source union, dest plain (narrowing — the `selective` catch remainder):
  the union box's slots 1.. ARE the member's value-enum leaf
  (`[variantTag, word]`). The plain value is that leaf; do NOT rebuild it
  with the union's TypeId as tag. Concretely, build the destination Result
  with the member value read from the union box:
  `self.failed(into, <member value at union slot 1 laid as fsides.err>)` —
  i.e. `self.unboxed_at` / `payload_at` on the union box for the member
  type, then wrap into `Result<int, Timeout>`.

Open question to settle at the fix: is `propagated` even the right verb for
the narrowing, or should `switched_union_reg`'s SELECTIVE default construct
the narrowed Result directly? The doc comment on `switched_union_reg` claims
"the discriminant is valid under any wider union that still claims the live
member, so no repack is owed here either — `propagated` already knows this"
— which is TRUE for a narrower UNION dest but FALSE for a plain member dest.
Settle which door owns the narrowing before patching.

**Do NOT** widen `counted_word` to accept arbitrary tags as a fix — that
papers over a real mis-tagging. (A defensive `tag < 64` guard to mirror
native's UB would hide the bug; refuse it unless the narrowing is proven
impossible.)

## Remaining acceptance work (after the fix)

1. `avra test packages/std-avrac` STAT=0 (the shift trap gone).
2. `sh tools/work test` green, incl. `parked_borrow` and `h2_body_wakes`.
3. `tools/cache_attacks.sh` = the 2 pre-existing `Line` defects only.
4. A focused regression test for the union→plain narrowing (the
   `selective`-style catch remainder re-raised into a plain Result).
5. Revert the WIP probes; land #196 (un-draft when its check is green).
6. `.1.24.9` (encode the kept seat at lowering) is the perf follow-up.

Keep the GUARD (`interp.av` `named_by_task` + `interp_host.av` `names_box`)
and the eval-aware h2 timing constant — both are needed.

## LESSONS LEARNED

- **The clean compiler's silence is not a proof of correctness.** Native
  has the same mis-tag; it survives only because `counted == 0` makes the
  outlawed shift harmless and C shifts mask the count. Differential
  agreement (eval == native) would NOT have caught this — one engine traps,
  the other does not shift at all. The trap was the *oracle*, not a
  regression.
- **The handoff's central framing was wrong.** evalrc4 wrote "may NOT be an
  over-free at all" — correct — but still labelled BOTH survivors as
  "value-flow corruption". The truth is a deterministic LOWERING bug in a
  named verb, reproducible from first principles, not corruption.
- **Instrument the LOWERING, not the runtime, to name a static type.** The
  runtime knows the tag (2569); only lowering knows WHICH `tagged_value`
  call site minted it (`ty=808 name=Timeout tag=2569` named the site in one
  run). evalrc4's proposed "probe in push_leaf printing ty/kind/valued" was
  the right instinct but framed as runtime; the useful probe is at lowering,
  and `name_of` (hook-free) is the safe field to print.
- **`name_of` is hook-free; `is_flat`/`is_valued` are NOT.** Printing
  `is_valued(ty)` in a probe would itself arm `LayoutFact.Valued` and can
  move answers. Print names/indices only.

## Environment / commands

- Sprite pin: `AVRA_SPRITES="avra-cores avra-phase-c avra-phase-d avra-reuse"`
  (`avra-unions-p2` is excluded/broken).
- `sh tools/work run "<cmd>"` runs one command on a Sprite; first build after
  a source edit ≈ 20–200s, later runs ~30s. Sprite tree:
  `/home/sprite/avra-build/avra-eval-rc/tree`.
- Owner rule: nothing over ~2 min except a full test run (~5 min) on a Sprite.
- BOSS intercom: `01a0f8d7`.

## Tickets

- `avra-8sb5.1.24.3` — **[BUG] evaluator never frees an aggregate** —
  **IN_PROGRESS**. The freeing change (`f234dc7`) is done and correct for
  the free-at-zero machinery; the blocker is this pre-existing union lift
  bug, exposed by the evaluator's trapping shift. Update the ticket title/
  scope: the blocker is a `propagated` narrowing defect, not an over-free.
- `avra-8sb5.1.24.4` — native `Cell.get` / `slot_unique` copy-on-write in
  eval — **NOT STARTED', blocked on .3.
