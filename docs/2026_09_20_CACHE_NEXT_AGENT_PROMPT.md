# Prompt for the next cache-layer session

You are continuing the Avra build-cache campaign on worktree
`/Users/tristan/projects/tristanMatthias/avra-cache-cas`, branch `cache/cas`.
The gate is **green** right now. Your job is the ordered list in §1 — do them in
order, because each one removes a hazard the next would otherwise trip on.

## 0. Read, in this order

1. `docs/2026_09_20_CACHE_AUDIT_AND_HANDOFF.md` — **the state** (this is the
   one that matters; it has the compromises, the hazards and the traps).
2. `docs/2026_09_20_CODEGEN_UNITS.md` — **the design** (§2–5 are your target).
3. `CLAUDE.md` — the laws. They are not style; they are enforced by keepers and
   by the compiler. Skim "The subset today" too: it is a cache of what the
   compiler REFUSES, and writing against a form it refuses wastes a build.
4. Only if you need history: the four older handoffs listed in the audit's §7.
   They supersede each other; a fact quoted from an older one may be retracted.

## 1. Your task, in order

### Task 1 — the hold's ordering (audit §2.2, then §2.1/§2.3)

`build_program_attempt` calls `held_modules` (`build_cache.av:230`) before
`seed_content_keys` (`:264`). `held_modules` calls `obj_key_cached` for every
file, which MEMOIZES into `ws.object_keys`, so `hold_only` (`record.av:275`)
reads a **pre-seed** key. And a held file's content digest is `""` (its bodies
are never lowered), so nothing is held at all.

Decide and implement ONE of:
- the content key is known before the hold decision (which per-function units
  give you for free — see Task 4), or
- the hold is genuinely disabled and SAID so (delete the dead path, keep the
  reason at the site).

Either way: **measure first.** Record `held modules`, and cold/warm
`./avra build packages/cli` times, before and after. A perf claim without a
before/after is not a finding.

### Task 2 — a declaration's STATEMENT range (audit §2.4)

`writes_receiver` (`compiler/typing_impls.av`) scans `0..store.stmts.count()`
and filters by the expression range — O(all statements) per impl, because
`Decl.lo..hi` is an EXPRESSION range and statements are a separate arena
(`NodeStore.stmts` vs `.exprs`; see audit §5.5). Add a statement-range query to
the store (or reuse the receivers pass's own walk) and use it. Measure
`check packages/std-avrac` before/after.

### Task 3 — the held-build seal question (audit §2.5)

`declare_impl_block` seals (boxes) a target when a method writes through its
receiver. A held impl has no body, so `writes_receiver` is false there. Find
where the flat/unflat mark is carried (the type registry's `mark_flat` /
`unflatten`) and prove whether it survives the interface, or restore the
warning and treat the hole as live. The original comment named the failure: a
type boxed in a parsed build and bare in a held one makes the link mix `ptr`
with `i64` in silence.

### Task 4 — the design: per-function codegen units

`docs/2026_09_20_CODEGEN_UNITS.md` §2–5. The current cache is FILE granularity
with a content key; the design is BODY granularity:

```
unit_id(u) = digest(CACHE_FORMAT, mangled(u.name), u.body_fp, u.type_args_fp)
obj_key(u) = digest(CACHE_FORMAT, "obj", unit_id(u), opt, runtime, toolchain)
```

One LLVM module per unit (declare everything the unit can name, define exactly
this body), then the object. In-process object emission
(`avra_llvm_emit_object`) so a unit is not a clang spawn — **that is a runtime
row, which is a TWO-LANDING change**: land the row alone first (hosted
`Unhosted`, which is true), refresh the seed, THEN the declaration and the
callers. See CLAUDE.md "A REGISTRY ROW THE COMPILER'S OWN SOURCE DECLARES
CANNOT BE GATED IN THE COMMIT THAT ADDS IT".

This task makes Tasks 1–3 moot. If you have the budget, do it first.

### Task 5 — the multi-derive corruption (audit §3.5)

`@derive(Roles)` + `@derive(Fingerprint)` on `Ins` compiles clean and produces
WRONG CODE. Isolated to that pair (`DeclSig` with `Projections` + `Fingerprint`
works). `Ins`'s fold is hand-written today, which is the trait's sanctioned
exit but a hand-maintained second spelling. Root-cause it, or leave it and say
so. Do not "fix" it by weakening the hand fold.

## 2. What is true now (do not re-litigate)

- The reachability collision is CLOSED by the content key (`4df71e4`): an
  object's key digests the bodies its file emits, via `seed_content_keys` +
  `obj_key_of` folding `ws.content_keys`.
- The IR carries its content identity: `@derive(Fingerprint)` on `Reg`,
  `Level`, `UnOp`, `BinOp`, `FileId`, `Body`, plus a hand `impl Ins`; the tag
  lives in ONE exported helper `derived(parts)` (`core/fingerprint.av`).
- A signature is signed from the file's NAMESPACE (`sign_cx_for`), never from
  its mid-flight `resolved` (`type_cx_for` is for BODY typing).
- `methods(target)` resolves the target's file first, because a generated impl
  is minted into the target's file.
- The gate is green: `std-avrac` 5329/5329, `traps` 24/24, idioms debt 0.

## 3. The commands

```sh
# a compiler-source change, in order:
cp build/avra build/avra.pre          # the way back; a broken product leaves no compiler
rm -rf .avra-cache && make bootstrap   # cache poison reads as "interface records did not stabilize"
./avra check packages/std-avrac        # the standing binary's own source
./avra emit packages/cli > /dev/null   # STRICTER than check/build — it catches codegen gaps
sh tools/watch.sh 4000 make gate       # the bar; ONE heavy process at a time
python3 tools/idioms.py                # debt must stay 0; annotate // LICENSED I<n>: <reason> at the site
make fingerprints                      # a tag names one kind; a parts list is fixed arity

# the seed law (seed-guard compares BOTH sides at HEAD):
git commit <source>  &&  sh tools/watch.sh 4000 make seed  &&  git commit bootstrap/seed.ll bootstrap/seed.sources  &&  re-gate
```

Scratch probes (`./avra check <one file>`) are sub-second and need no lock.
`build/scratch/probe` is a throwaway package for a 3-line probe.

## 4. The traps, as symptom → cause → move

- **`avra: interface records did not stabilize`** → the cache holds a stale
  interface. `rm -rf .avra-cache && make bootstrap`.
- **`avra: index N is out of bounds (length M)`** → the IR EVALUATOR
  (`compiler/interp.av`), not the compiler's tables: a settled const or a lifted
  annotation whose shape moved.
- **`make seed` fails but the tree builds** → `emit packages/cli` is not clean.
  `emit` is stricter than `check`/`build`; run it directly and read its codes.
- **`seed-guard: a committed seed that is not this tree`** → the seed is not
  committed, or the tree is uncommitted. Both sides are read from HEAD.
- **A trap in the suite with no message** → `traps.sh` rows and `avra test`
  binaries exit 2 (`avra_trap`) or segfault. Build the row by hand with a
  cleared cache to tell a cache collision from a real bug.
- **`check <pkg>` shows defects that are not that package's** → it reports its
  DEPENDENCIES' bodies. Dedup by identity before quoting a count.
- **A probe answers about the old compiler** → the standing binary had not been
  rebuilt. `make bootstrap` first.
- **`>>` / `|` / a trailing comma** → the grammar munches `>>` as two tokens and
  every comma list takes a trailing comma. Probe in `build/scratch` before
  writing a form you are unsure of.
- **A lint or keeper fires on your change** → fix the code, or annotate AT THE
  SITE. Never widen the keeper.

## 5. Acceptance

- `make gate` exit 0 (it prints `gate: green`).
- `std-avrac` 5329/5329 (or more, never fewer), `traps` 24/24.
- `python3 tools/idioms.py` debt 0; `make fingerprints` clean.
- `./avra emit packages/cli` exit 0.
- The seed committed, and `seed-check` green.
- For every perf change: a before/after number, measured under the watchdog.

## 6. Do NOT

- Do not ship a workaround. If a fix needs a coarser key, a body scan, or a
  forced resolve, say so in the code and in the commit, and leave the root-cause
  note (the audit's §2 is the model).
- Do not quote a count without naming the scope and deduping by identity.
- Do not add an import/field/parameter "because the symptom moved" — prove it
  is needed, or drop it (the audit's §3 records one such change that landed and
  was then removed).
- Do not run two heavy processes. Nothing runs `build/avra` directly.
- Do not touch `ROADMAP.md` (another session owns it).
- Do not widen a keeper, weaken a law, or delete a warning to make a build pass.
