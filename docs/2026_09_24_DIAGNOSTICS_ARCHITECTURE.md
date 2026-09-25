# Diagnostics architecture — one system, not three

**Status:** design, awaiting the owner's sign-off before any implementation.
**Date:** 2026-09-24
**Depends on:** the Error trait's `cause()`/`context()`/`trace()` and `Traced<E>`
(landed, lane/errors@1df0c2d). Feeds: avra-8sb5.40.3 (internal error typing),
avra-8sb5.40.4 (`? context`), avra-8sb5.40.12 (failure topology,
`explain-failures`), avra-8sb5.38 (F-code collisions).

## Why this doc exists

Ticket .40.3 started as "convert 218 `Result<T, string>` sites to typed
errors." Triage found that framing was wrong — 168 of those sites are a
domain (grammar builders) whose refusal wording is deliberately the
diagnostic, and converting it would fight this codebase's own documented
law. Only ~10 sites are real candidates. That's a correct, narrow finding
for the narrow question — but the owner's actual ask is bigger: "the
world's best error reporting for a compiler," including fixes/ideas and
the failure-topology work, and "some of the docs might be out of date."

A survey of what already exists answers why the narrow question kept
producing narrow answers: **the compiler already has three diagnostic
mechanisms that don't talk to each other**, and the new `Error` trait
machinery is a fourth, also disconnected. Fixing .40.3 in isolation would
have added a fifth. This doc designs the one system all of them should
have been.

## What exists today (confirmed by direct reading, not doc claims)

1. **`Diag`** (`std-avrac/diagnostics/mod.av`) — the compiler's diagnostic
   for a user's `.av` file: `kind`, `severity` (Error/Warning only),
   `primary`/`secondary: List<Frame>`, `message`, `help`, `suggestions`.
   Flat — no nested cause, no chain. It `impl Error`s but only overrides
   `describe()`; `.cause()`/`.context()`/`.trace()` fall through to the
   trait's empty defaults. It does not use `Traced<E>` anywhere.
2. **`Suggestion`/`Edit`/`Confidence`** (`std-errors`) — a fix-it type with
   four real call sites, rendered as *at most one* plain-text `fix: …`
   line (first suggestion, first edit only), never machine-applied.
   `Confidence` is assigned and never read. Zero of 174 registered
   diagnostic codes' live witnesses produce a `fix:` line today.
3. **The `rule { }` DSL's `Candidate`/`Fix`/`Application`** (`compiler/
   rule_pass.av`, `rule_fix.av`) — a *separate* fix pipeline, the only one
   `avra fix` actually reads. It proof-gates every application (IR-equality
   against the rule's own `@fixes`/`@keeps` examples) before writing
   anything. This is the real, working "fix" mechanism — it just isn't
   connected to `Diag.suggestions` at all.
4. **`Cause`** (`grammar/diagnostics.av`) — classifies only the grammar
   engine's own ~6 shapes (lex, parse-expected, trailing, builder, defect,
   block), projects one-way into `Diag.kind` at the driver boundary, then
   disappears. The other 168 of 174 codes never touch it.
5. **F-codes** — a `kind: string` (feature-scoped, e.g. `"type.catch"`) is
   the thing every internal mechanism actually keys on (witnesses, user
   packages, `avra explain`). The **id** (`"F2029"`) is a separate,
   globally-assigned sequential number, hand-picked per feature as "highest
   + 1," validated for uniqueness only *within one tree* at assembly time.
   Two lanes picking the same next-free number is exactly avra-8sb5.38's
   two real collisions in one day.
6. **`avra explain-failures`** — sketched in `docs/2026_09_23_AVRA_TOUR.md`
   with hop counts and a "because" trace at panic time. Not built. No file
   exists for it.

Four systems, one shared shape they're all reaching for: **something
caused this, here's the chain, and here's what to do about it** — built
four times, none of them finished, none of them talking to the others.

## The design: one identity, one chain, one fix channel

### 1. No numbers. A diagnostic's identity is its kind string, qualified by where it lives — never hand-picked, never counted.

Owner's call, 2026-09-24: no numbering scheme at all, not even a derived
one — a hash still needs a tie-break rule and still LOOKS like the thing
that collides. The kind string should do the whole job, made
collision-proof BY CONSTRUCTION rather than by convention.

It almost already is. `code_defects()` (features/coherence.av) already
refuses a duplicate `kind` tree-wide at assembly time, not just a
duplicate `id` — so today's actual, silent, cross-lane failure mode is
narrower than it first looks: two lanes cannot collide on a *string*
they both had to type out and think about; they collide on a *number*
neither of them thought about at all, because "highest + 1" is a race
with no semantic content to disagree over. Removing the number removes
the only thing that was ever actually racing.

**RETRACTED (2026-09-25), the auto-prepend-the-feature-name mechanism
below — a migration-size investigation for avra-8sb5.40.13 found the
premise wrong before any code moved.** Measured, not assumed: of 169
feature-owned kinds, 140 (83%) already share a CATEGORY prefix
(`type.`, `resolve.`, `manifest.`) across MANY different owning
features on purpose — `type.mismatch` alone is emitted as a literal
string from 14 different files across 13 features via shared,
feature-agnostic helpers (`features/checks.av` and siblings) that have
no "current feature" to qualify from even in principle. These are not
mis-named strays to correct; they are genuinely shared concepts (a
type mismatch is not owned by whichever feature happened to trigger
it). Forcing every kind into `<owning-feature>.<tag>` would have meant
inventing an arbitrary owner for a dozen-plus shared diagnostics and
rewriting roughly 420 emission call sites for a category that was
never actually at risk.

**It was never at risk, which is what makes the mechanism unnecessary
rather than merely expensive.** `code_defects()` (features/coherence.av)
already refuses a duplicate `kind` tree-wide at assembly time, and
always has — for every one of the 185 rows, category-prefixed or not.
Two lanes cannot collide on a *string* they both had to type out and
think about; they collide on a *number* neither of them thought about
at all, because "highest + 1" is a race with no semantic content to
disagree over. Removing the number removes the only thing that was
ever actually racing — no auto-qualification mechanism is needed to
finish the job, because the job was already done by an existing check.
A feature (or a user's own package — same check, same guarantee, no
separate scheme to learn) picks whatever kind string fits its domain,
same as today, and `code_defects()` catches a real accidental
duplicate exactly as it always has.

**Migration is small and mechanical because NO kind string changes.**
Every one of the 185 existing kinds keeps its exact spelling — this
was the actual point of retracting the rename: it turns a ~420-call-site
rewrite into three bounded, scriptable pieces: (1) drop `DiagCode.id`
and the two `id`-only lookup paths that ride it (the diagnostics
witness table, 83 rows keyed by number; `avra explain`'s numeric
argument), rekeying both to the kind string each row already carries;
(2) update the ~52 test goldens that assert a rendered `error[F1234]:`
string to assert the kind instead, a 1:1 substitution from the current
registry; (3) `avra explain <kind>` already accepts a kind directly, so
only the numeric alternative is deleted, nothing about the kind lookup
path changes. `docs/DIAGNOSTICS.md` regenerates itself (`make
witnesses`) and needs no manual edit. Rendering drops `F2029` and shows
the kind alone: `error[results.catch]: …` — more meaningful to a reader
AND to a model reading the output (P1, P11), which is the whole reason
a dotted string beats an opaque incrementing integer for this compiler
specifically.

Tier 3 (a user package's own `@scope/name:E1` kind) already rides the
same `id`-as-derived-echo-of-`kind` pattern (`kind.replace(":", ": ")`)
— dropping the concept of a separate numeric identity reaches it too,
for free, with no new mechanism a package author has to adopt: a
package's own kind was already namespaced by its own name, the same
way a feature's already was.

**Same law for idiom I-numbers, confirmed with IDIOMS** (leads the
formatter/idiom engine, mid-migration to a component architecture for
`rule` declarations): idiom numbers hit the identical collision (I33 and
I56 each landed twice), and idioms are already mostly `rule`s whose real
identity is a string — `<module>.<rule>` (e.g.
`nullable.if_null_ternary`), which the native finding ratchet already
keys on as `rule.<module>.<name>`. IDIOMS has no attachment to their own
earlier per-feature-number-block proposal and agreed: one answer for the
tree. Drop the I-number the same way — the module-qualified name was
already the real identity, the number was always the redundant part.

### 2. `Diag` carries a real cause chain, through the mechanism that already exists.

`Diag` should hold `cause: dyn Error?` and actually populate it, so
`.cause()`/`.context()`/`.trace()` answer something real instead of
silently falling through to the trait's defaults. Concretely:

- A `Diag` produced from an internal compiler failure (a `BuildError` from
  .40.3, say) carries that `BuildError` as its `cause`, so a link-failure
  diagnostic can render the *actual* underlying defect, not a flattened
  string that already lost the structure.
- `Traced<E>`'s frames become `Diag.secondary`'s natural source once
  `? context` (.40.4) exists — a context frame attached during
  propagation is a `Frame`, and `Diag` already has a `List<Frame>` slot
  for exactly this. Today those two lists exist in parallel and never
  meet; they should be the same list.
- Rendering gains a **real chain**: `error: X` / `caused by: Y (at
  file:line)` / `caused by: Z`, walking `.cause()` until it returns
  `null`, each hop showing its own `Frame` if it has one. This is the
  "because" trace `AVRA_TOUR.md` already mocks up for panic-time
  reporting — same walk, same primitive, two call sites (compile-time
  diagnostic render, runtime panic render).

This is the direct answer to "dogfood the error syntax more" for the
compiler's own diagnostic engine specifically: `Diag` should be built
*out of* `@std.errors`' vocabulary, not sit beside it as a fifth
reimplementation.

### 3. One fix channel, one proof gate.

`Diag.suggestions` and the rule DSL's `Fix`/`Application` should be the
same mechanism, not two. Concretely: `Suggestion`'s `edits: List<Edit>`
is already exactly what `Application.edit` needs, and `source.av`'s
`spliced()` already applies edits mechanically — the only piece the rule
DSL has that `Diag.suggestions` lacks is **proof**: an edit that isn't
checked against a real example before/after is a suggestion for a human,
never something `avra fix` writes.

So: a `Suggestion` gains an optional proof obligation (the same
`@fixes`/`@keeps`-style IR-equality check — `compiler/rule_proof.av`'s
`ir_proved`, which re-lowers the enclosing declaration before/after in a
throwaway Program and compares an α-renamed instruction fold, generalized
off the rule DSL so it isn't rule-specific machinery), and `avra fix`
reads `Diag.suggestions` (all of them, all their edits — not just the
first) wherever a proof exists, exactly as it reads rule-derived fixes
today. Rendering shows every suggestion, not just the first, and names
its confidence.

**Confidence and proof are independent, not the same gate** — confirmed
against IDIOMS' own measurement: `ir_proved` proves roughly 1 in 10 real
rewrites in practice, because a sound rewrite usually changes the
instructions it's comparing. `Confidence.High` means a human should trust
the suggestion; PROVED means `avra fix` may write it unattended. A
suggestion can be High and unproved (shown, never auto-applied) — that is
the common case, not an edge case, and the design must not let
`Confidence.High` read as "safe to apply automatically." The general gate
also carries `rule_fix.av`'s existing `// LICENSED`/`licensed_just_above`
respect forward as a hard requirement: a site marked licensed refuses
*any* automated fix over it, rule-derived or Diag-derived, unconditionally.

**Sequencing**: IDIOMS' rule-as-component migration (`export component
rule { run, doc, fixes, keeps }`, landing on lane/formatter) touches
`rule_pass.av`/`rule_fix.av`'s callers but not the pass, the fix pipeline,
or the proof itself — so it doesn't block this design, but this
generalization should land AFTER that migration merges rather than in
parallel with it, to avoid two lanes editing the same two files. IDIOMS
will signal when it's in.

### 4. Failure topology and `explain-failures` are the compile-time twin of the same chain-walk.

The runtime "because" trace (§2) walks a *value's* `.cause()` chain at
the moment it's printed. `explain-failures <fn>` walks the *type-level*
question — which error variants can statically reach this function, and
through which calls — using the same underlying idea (a directed graph of
"this can cause that") but over declared types instead of runtime values.
They should share one graph primitive: a `causes: X -> List<Y>` walk,
instantiated once over `dyn Error` values (the runtime trace) and once
over declared error unions (the static topology). Building the static
half is real, separate work (needs error unions to be worth it, per the
epic's own R4 note) — but the mechanism it's built on should be the one
this doc describes, not a bespoke third thing.

### 5. Severity — flagged, not resolved here.

Only `Error`/`Warning` exist; the old epic's F9xxx range implies a warning
tier was anticipated but even that's binary. A richer ladder (Info/Hint,
the way rustc/clippy have) is a reasonable "best in class" ask but touches
every diagnostic call site for no correctness gain — lower priority than
§1–4, noted so it isn't lost, not proposed as part of this slice.

## What this means for the epic's tickets

- **.40.3** narrows to what triage found (compiler/build.av's ~7-10
  sites) **plus** giving those new `BuildError` variants a real home in
  §2's cause chain — so the ticket becomes "type build.av's failures AND
  wire them into Diag as a real cause," not just "type them."
- **.40.4** (`? context`) feeds §2 directly — the frames it attaches are
  the same `Frame` list `Diag.secondary` should be reading.
- **.40.12** (failure topology) is §4 — this doc gives it a concrete
  mechanism (the shared `causes` walk) instead of starting from nothing.
- **avra-8sb5.38** (F-code collisions) is resolved by §1, as a byproduct
  of the identity question rather than a bolted-on fix.
- **New work this doc surfaces, not yet ticketed**: unifying
  `Suggestion`/`Fix` (§3) and wiring `Diag.cause` (§2) are real, separate
  slices from anything currently in the epic — pending sign-off, they get
  their own tickets under avra-8sb5.40.

## Resolved

- **No numbers, anywhere** (owner, 2026-09-24) — settled. Diagnostics and
  idioms alike are identified by a kind string qualified by its owning
  feature/module, derived automatically at registration, never
  hand-picked and never counted. Rendering shows the kind alone
  (`error[results.catch]: …`), superseding IDIOMS' earlier "keep the
  number for explain/search" opinion from before this call — `avra
  explain <kind>` already works off the string with no number involved.
- I-numbers fold into the same identity law as diagnostic kinds (§1) —
  one answer for the tree, confirmed with IDIOMS, not two fixes for the
  same problem.
- §3's proof generalization is welcomed by IDIOMS and not blocked by
  their component migration, sequenced to land after it merges.

## Open question for the owner

1. §3: is generalizing the rule DSL's proof mechanism off rules
   specifically in scope for THIS epic, or its own campaign (it touches
   formatter-owned files — IDIOMS should co-review whichever answer)?
