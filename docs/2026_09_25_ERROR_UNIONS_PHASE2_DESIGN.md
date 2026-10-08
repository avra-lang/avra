# Error unions, Phase 2 — inferred unions (`Result<T, _>`)

**Status:** design, awaiting owner sign-off before implementation.
**Date:** 2026-09-25
**Scope:** `Result<T, _>` — the compiler computes the fn's error side by
walking its body, instead of the author spelling `Result<T, A or B>`
by hand (Phase 1, avra-8sb5.40.10.1, landed on main). NOT in scope:
catch-chain narrowing (avra-8sb5.9.29) or the failure-topology /
`explain-failures` feature (avra-8sb5.40.12) — this doc's query is
built so that a later design *can* share its shape with .40.12's, but
it does not build .40.12's feature.

Ticket: avra-8sb5.40.10.2.

## 0. Why this needs new machinery, not `join_of`

Every existing body-driven type inference in this compiler (a lambda's
return type, `features/checks.av`'s `join_of`) REDUCES: it looks at N
branches, demands they agree on one type, and refuses when they don't
— "two incompatible types is always an error, never synthesized into
a union" is the law everywhere else in the compiler today. This
ticket needs the opposite operation: walk every `fail` and `?`
site reachable from a fn body and COLLECT the SET of distinct error
types, never reducing, never refusing on disagreement — disagreement
is exactly the expected case, and it's *why* the fn needs a union in
the first place. There is no existing consumer of `join_of` doing
this, and bending it to would mean adding a "don't refuse, collect
instead" mode to a fn whose entire contract today is "refuse or
answer one type" — a parallel operation, not a flag.

## 1. The grammar question — probed, no grammar change needed

Probed directly (`build/avra check` on scratch files, from outside
`packages/`):

```
$ cat underscore1.av
type NotFound = { key: string }

fn f(k: string) -> Result<int, _> {
    fail NotFound { key: k }
}
$ build/avra check underscore1.av
error[type.unknown]: `_` names no type
  ╭─[…/underscore1.av:3:1]
3 │ fn f(k: string) -> Result<int, _> {
  · ┬
  · ╰── in this signature
──╯
help: the types today are `int`, `string`, `bool`, and your declared types
```

`_` already parses as an ordinary type-position NAME — the grammar
makes no distinction between `_` and `Foo` or `decimal`; every one of
them reaches `compiler/typing/declare.av:517`'s `named_type`, which
runs through type-var / builtin / declared-decl / width lookups and
falls through to the same `type.unknown` refusal
(`compiler/typing/declare.av:526`) on failure. Confirmed the failure
is generic, not `Result`-specific, by probing the same shape in three
other positions — all three refuse with the byte-identical message:

```
fn f(k: string) -> Result<_, E> { … }      // arg 0 instead of arg 1
fn f(xs: List<_>) -> int { … }             // a different applied type
fn f(k: string) -> Result<int, _> { g()? } // through a call, not a literal fail
```

**No grammar change, no syntax-change protocol.** This is a pure
resolution-layer change: teach ONE call site — the per-argument
resolution loop inside `compiler/typing/declare.av`'s `applied` (the
fn that already special-cases `Result`'s two argument slots via its
`TypeRow` — arity, `res_law`, `res_shape`) — to recognize a BARE `_`
(`name == "_"`, `args.is_empty()`, `!optional`, `!dynamic`,
`alternatives.is_empty()` — Phase 1's own `TypeRef.alternatives`
field must be empty too, so `_ or E` still falls through to the
ordinary refusal) written specifically as the SECOND argument of a
`Result` application, and route it to the new machinery below instead
of calling `self.full_type`/`named_type` on it.

**Scoped deliberately narrow**: `_` stays an ordinary unresolved name
everywhere else — `Result<_, E>` (arg 0), `List<_>`, a bare `let x: _`
— exactly as today. Widening `_` into a general inference hole is a
different, much bigger feature (unify-driven inference over arbitrary
positions) that this ticket does not touch and should not accidentally
back into. Named as an open question in §9.

## 2. The shape to imitate, and where it diverges

`compiler/receivers.av` (the ticket's own pointer) is the right model
for the MECHANISM — a `Summary` per fn, `edges` between fns, a Kleene
fixpoint over a whole-program table (`Decls.settle_writers`) — but
NOT for the mechanism's PLACE in the pipeline, and that difference
drives most of this design.

Receivers is a downstream analysis: nothing types a body differently
because of what Receivers finds, and it runs on-demand, lazily, from
a handful of consumers (`avra docs writes`, a witness). Reading its
own guard —

```
if self.db.family_active(ordinal(Family.Resolved)) { return 0 }
```

— it depends on `Family.Resolved` (name resolution) and reads
`self.decls.sig(d)` for declared seat types, but never forces
`Family.Typed`. It is, today, already living at the Resolved+Sig
layer, not the Typed layer — which is the one property Phase 2's walk
needs too, for a different reason: **a fn's inferred error union has
to be part of its SIGNATURE**, because every caller's own typing reads
`sig(callee).ret` to know what a `?` on that call propagates. If the
union were only known after `Family.Typed` ran, every caller would
have typed itself against a placeholder first. So the failure walk
must run **before** `Family.Typed`, off exactly the same
structural/declared-type information Receivers already proves is
enough for a body-shaped question that doesn't require unification.

This is also why it must be its own family rather than folded into
`Family.Receivers`'s existing per-fn `Survey`: Receivers is invoked
*lazily*, by specific diagnostics, whenever they happen to ask; Phase
2's walk must be invoked *eagerly*, the first time ANY `_`-declared
fn is signed, because `Family.Sig` cannot finish building that fn's
`FnSig` without it. Same fixpoint shape, different trigger contract —
folding them would force Receivers to move earlier for no benefit to
its own consumers, or force Sig to wait on a lazy pass it can't
control. They should share the *structural-type-of-an-expression*
helpers (§4) as a real extraction, not share the pass.

## 3. The new family

```
enum Family { …, Failures }          // ordinal 19, appended (never inserted — CLAUDE.md's family law applies to this enum the same as any other registry)
```

One whole-program key, exactly like `Family.Receivers`'s
`key(Family.Receivers, 0)` — not one memo entry per decl. The
computation is a single Kleene fixpoint over every `_`-declared fn in
the program at once; a per-decl `Memo<List<TypeId>>` was considered
and rejected (§8).

Storage mirrors `Decls.written_seats` exactly:

```
inferred_errs: Cell<List<Cell<List<TypeId>>>>   // one growable set per DeclId
```

with `record_inferred_error(d, ty)` (push if not already present —
`same_type` dedup, same check `Union` construction already uses),
`inferred_errors_so_far(d) -> List<TypeId>`, and `clear_inferred()`
resetting every non-held decl's cell to `[]`, word-for-word matching
`clear_written`'s own held-file exception:

> A held file's settled bits are the interface's, not this pass's to
> clear: the pass never surveys a held body, so wiping them loses
> what a caller's decision reads.

## 4. The walk

Per `_`-declared fn `d`, two structural scans over its RESOLVED body
(never its typed one):

- **`Stmt.Fail(v)`** — found the way `receivers()`'s `assigns()` finds
  assignment targets: iterate `store.stmt_ids()` (whole-program, cheap
  — it's a list index), match `Stmt.Fail`, keep the ones whose `v.index`
  falls in `[x.lo, x.hi)`. `v`'s structural type is the direct
  contribution.
- **`Expr.Propagate(v)`** — found the way `receivers()`'s
  `site_evidence` finds call sites: iterate `x.lo..x.hi` as `ExprId`s,
  match `Expr.Propagate`. `v`'s structural type must be a `Result`
  (`res_parts`); its ERR side is the contribution.

Both need "the structural type of an arbitrary expression, no
unification" — which `receivers.av`'s `Survey` already has, just
under a narrower name: `place_type`/`root_type`/`bound_type`/
`constructed_type`/`field_type`/`carried_type`/`element_type`
together answer exactly this question for method-call subjects and
assignment targets today. **Proposed extraction**: lift this cluster
out of `receivers.av` into a shared helper (`core` or a new small
module both `receivers.av` and the new walk import), taking a
`Decls`/`NameFacts` pair rather than a `Survey`'s full field set —
the CLAUDE.md law this pays down directly: "the third copy of a shape
names the concept... two copies may wait; three never do." This is
the second consumer, which is the point where extracting stops being
premature.

**When a site can't be structurally resolved** (the value's type
depends on unification the structural walk can't do — a generic call
whose error type only concretizes at the call site, a `match`/`if`
producing different error types per arm bound to one local, and
similar): **refuse `_` for this fn**, naming the site, rather than
silently omitting the contribution. This is the same law as every
registry catch-all in CLAUDE.md's Rules section: a hole in a set that
should be exhaustive is a `_ -> null` in different clothes, and it
would be *worse* here than a compile error, because the silent form
is a soundness hole — a real error the runtime can raise that the
inferred union doesn't list, so a caller's exhaustive `catch` is
provably wrong and the compiler said nothing. The remedy the
diagnostic offers is exactly what's already there for the author to
fall back to: spell the union by hand (`Result<T, A or B>`), Phase 1's
form, which doesn't need structural resolution because the author
supplied the types directly.

A call to another `_`-declared fn `g` (recognized purely syntactically
— `g`'s own `ret: TypeRef` in its `Stmt.FnDecl` node is
`Result<_something_, _>`-shaped, checked the same way §1's probe
found the shape, no signing of `g` required) is NOT resolved via
structural type lookup at all — it becomes an EDGE (`calls: [g, ...]`)
into the fixpoint, exactly mirroring `receivers()`'s `Flow`, simplified
because there's one set per fn rather than one bit per seat: no
`from`/`to` needed, just "this fn's set is a superset of `g`'s."

```
type FailSummary = { direct: List<TypeId>, calls: List<DeclId> }
```

(`direct` may itself contain an already-multi-member `Union` — e.g. a
`?` through an EXPLICITLY-unioned callee, Phase 1's form — and that's
fine to leave un-flattened here: `union_of`'s own flattening,
Phase 1's `union_members`, handles it identically whether the input
list holds plain types or nested unions.)

## 5. The fixpoint

```
fn settle_failures(fns: List<DeclId>, sums: Map<DeclId, FailSummary>) {
    mut changed = true
    while changed {
        changed = false
        for d in fns {
            let before = self.decls.inferred_errors_so_far(d).length
            let grown = union_members_of(sums[d].direct)
                .concat(flatten([self.decls.inferred_errors_so_far(g) for g in sums[d].calls]))
            for ty in grown { self.decls.record_inferred_error(d, ty) }
            if self.decls.inferred_errors_so_far(d).length != before { changed = true }
        }
    }
}
```

Same proof `receivers.av` already states for its own loop, unchanged
because the lattice shape is the same (a growing SET under union,
instead of a growing set of TRUE bits under OR): "deterministic and
order-free; cycles resolve to the least answer, which is the true
one." A self-recursive `_`-declared fn is not a special case — it's
just an edge from `d` to itself; the loop adds `d`'s own direct
contributions on the first pass (an edge to itself contributes nothing
new after that), and any *mutually* recursive pair converges the same
way any cyclic SCC in `settle_writers` does today.

## 6. Why the kernel's own `Cycle`/`start_recursive` isn't used here

The ticket's own pointer to `query/memo.av`'s per-key `Cycle` handling
is worth answering directly rather than silently sidestepping.
`Memo<T>.ask`'s `Cycle` verdict answers ONE re-entrant call within a
single kernel pass with a snapshot value (`cycle_value`, "whatever the
table holds right now") — it's built for a query that's read again
while still computing itself, once, inside one `ask`. That's the
right tool for a self-referential VALUE computed once. It is not the
right tool for finding a MONOTONE FIXPOINT over an unknown-in-advance
set of mutually-dependent fns, which needs to re-visit every member of
a cycle repeatedly until nothing grows — exactly why `receivers()`
doesn't use it either, and builds `settle_writers`'s explicit outer
loop instead. Phase 2 makes the same choice for the same reason:
the OUTER whole-program pass is one kernel key
(`key(Family.Failures, 0)`), asked once per revision, computed by an
explicit Kleene loop internally; the kernel's cycle machinery plays no
role inside it, matching Receivers precisely.

## 7. Wiring into `Family.Sig`

`applied()`'s new branch (§1), on seeing `Result<T, _>`, does not mint
a placeholder `TypeId` at all — there's no field anywhere for a
"pending" `FnSig.ret` (it's a plain `TypeId`, and `@derive(Fingerprint)`
means every field is folded into the sig hash, so a placeholder would
have to be a real, distinct, meaningless type that every consumer
would need to know to treat specially — the exact "an encoding spends
the empty value" shape CLAUDE.md warns about, and worse, spent for a
reason no reader would guess). Instead it forces the fixpoint
synchronously:

```
touch(self.failures())   // runs Family.Failures if not already settled this revision
self.view.types.union_of(self.decls.inferred_errors_so_far(current_decl))
```

`self.failures()` is the whole-program pass (§3–§5): pre-scan every
decl's raw `Stmt.FnDecl.ret` (no signing — pure AST read, §1) for the
`Result<_, _>` shape, build every `_`-declared fn's `FailSummary`,
run the fixpoint, and settle. Because this all happens through
`self.decls.sig(d)`'s ALREADY-established re-entrancy rule — "a sig
reached from inside its own computation is simply not there yet" —
`Family.Sig` asking `Family.Failures` asking (indirectly, via the
structural walk's callee-shape check) nothing that calls back into
`Family.Sig` is safe by construction: the walk never calls
`self.sig(callee)`, it reads `callee`'s raw AST return-type shape and,
if `callee` is itself `_`-declared, an EDGE into the SAME fixpoint
table `Failures` already owns — never a nested kernel `ask`.

By the time `sig(d)` returns, `d`'s `FnSig.ret` is a fully concrete
`Type.Res(ok, union_of(...))` — never a sentinel. This is the load
-bearing consequence: **`Family.Typed`'s `check_fail` and
`propagate_res_type` need ZERO changes.** `cx.enclosing_ret()` for a
`_`-declared fn answers exactly the same shape a hand-written
`Result<T, A or B>` answers, and every `accepts`/`covers` check
succeeds by construction — the union WAS BUILT from these exact sites,
so checking them against it can't fail. (If it somehow could, that
would mean the structural walk and the real typing walk disagree
about a site's type, which would be its own defect to chase, not
something `_`-inference should paper over — this is the same
CLAUDE.md law about a check that can only pass because of a bug,
inverted into a design constraint: the two walks *should* be able to
disagree in principle, so a passing `accepts` here is real evidence,
not a tautology. See §9 for the one case where they might legitimately
diverge.)

## 8. Explicit unions — nothing changes

A fn declaring `Result<T, A or B>` (Phase 1) never enters any of the
above: `applied()`'s new branch only fires when arg 1 is the literal
bare name `_`; `A or B` resolves through Phase 1's existing `type =
t:type_atom ( "or" t2:type_atom )+` path exactly as it does today, and
its `FnSig.ret` is fixed at signing time with no dependency on
`Family.Failures` at all.

The one interaction: when an inferred fn's body calls an
EXPLICITLY-unioned fn `g` and propagates via `?`, `g`'s return type is
already a concrete `Type.Union` by the time the structural walk asks
for it (`sig(g)` — a plain, ordinary, already-settled ask, no edge
needed since `g` isn't itself pending) — it becomes a `direct`
contribution, not a `calls` edge. The distinguishing test is
purely syntactic (§4): does `g`'s OWN written return type spell `_`
or a real type/union.

## 9. Open questions for the owner

1. **The zero-member union.** A `_`-declared fn with no `fail`/`?`
   sites and no edges settles `union_of([])`. `core/types.av`'s
   `union_of` does not special-case the empty list — `members.length
   == 1` is false for zero, so it interns `Type.Union([])`, a shape
   that has never existed in the tree before (Phase 1's own hand-
   written form always has >=2 written members, so it never reaches
   zero from that side). Phase 1's doc explicitly punted on "a Result
   that can't fail" as "a compound question for a later pass, not
   solved here" — Phase 2 is the first path that can actually produce
   one, and it needs an answer before implementation, because
   `covers`/pattern-matching/runtime layout over a zero-member union
   are all unexplored. Candidates, not decided here: (a) refuse `_`
   outright when no site is found ("nothing here can fail — write the
   fn's true answer type, not `Result<T, _>`"), which is probably the
   friendlier failure mode and sidesteps the representation question
   entirely; (b) mint the empty union and make every consumer treat it
   as "no `.Err` tag exists," which is a real feature (a documented
   dead `catch` arm, a `?` that can be proven to never actually
   propagate) but touches shared machinery Phase 1 never had to.
   I'd lean (a) for this ticket and file (b) as a follow-up, but this
   is the owner's call.
2. **Depth of the transitive walk.** The fixpoint as designed has no
   depth limit — it follows `calls` edges through the WHOLE reachable
   graph of `_`-declared fns. Is there a practical concern (compile
   time on a large program, a diagnostic that's unreadable because a
   deeply-nested union has 40 members) that wants a cap, and if so
   what does hitting it do — refuse `_`, or silently stop growing
   (which would be the same soundness hole §4 refuses)? I don't have
   a measurement to justify a cap yet; recommend shipping uncapped and
   measuring on a real program before adding one speculatively (per
   CLAUDE.md's "measure, then change").
3. **Cross-package boundary.** Reasoned through, not yet verified end
   to end: a held (already-compiled) package's `_`-declared fn must
   have had `Family.Failures` settle BEFORE its interface/record was
   written (`compiler/interface.av`'s `record_line`), so its `FnSig`
   is already concrete by the time a downstream package reads it back
   — exactly the same requirement Receivers already has for its own
   written-seat bits ("a held file is not surveyed... a call to a held
   fn reads its recorded bits"). If that ordering holds (interface
   writing happens after the whole package's Sig/Typed settle, which
   it should, but I haven't traced the exact build-completion sequence
   to confirm), cross-package `_`-inference needs no new
   serialization: `FnSig.ret` is a plain `TypeId`-shaped field like
   any other, and the interface format doesn't know or care whether it
   came from an annotation or a fixpoint. Worth a direct confirmation
   from whoever owns `compiler/interface.av`/`compiler/record.av`
   before implementation starts, since I'm inferring the ordering
   from Receivers' comment rather than having traced it myself.
4. **Should `_` ever be allowed to widen an ALREADY-explicit union?**
   E.g. `Result<T, A or _>` — "at least `A`, plus whatever else the
   body raises." Not asked for by the ticket, not designed here,
   flagging only so it's a deliberate non-goal rather than an
   oversight: `applied()`'s branch as designed only fires when arg 1
   is a BARE `_` with no alternatives, so `A or _` falls through to
   the ordinary `or`-parsing path today and `_` inside it hits the
   ordinary `type.unknown` refusal (verified — `_` as one alternative
   of an explicit `or` chain is exactly the `alternatives.is_empty()`
   guard's job in §1's predicate).

## 10. Sequencing

1. Extract the structural-type-of-an-expression helper cluster out of
   `receivers.av`'s `Survey` into a shared home; land it alone,
   `receivers.av` calling the extracted form, gate green, zero
   behavior change — a pure refactor commit, easiest to review and
   revert independently of everything below.
2. Add `Family.Failures`, its storage on `Decls`
   (`inferred_errs`/`record_inferred_error`/`inferred_errors_so_far`/
   `clear_inferred`, mirroring `written_seats`'s four), and the
   pre-scan + `FailSummary` walk + Kleene loop, wired into
   `refetched()` the same way `Family.Receivers` is — but with NO
   caller yet (dead code path, gate green, a program test calling
   `self.failures()` directly to pin the fixpoint's own behavior on a
   few hand-built cyclic/acyclic graphs before anything depends on
   it).
3. Wire `applied()`'s `Result<T, _>` branch to force it and mint the
   final `Type.Res`. This is the first commit where `_` actually
   compiles. Land the owner's answer to §9.1 (the empty-union
   question) as part of this step, since `applied()`'s branch is
   exactly where "no sites found" is first observed.
4. Program tests, `eval == native`, for: a fn with one `fail` site
   (degenerates to a plain type, no `Union` minted — Phase 1's own
   "a one-member union is not a union" rule firing here for free); a
   fn with two incompatible `fail` sites; a `?`-chain through another
   `_`-declared fn (the `calls` edge); a mutually-recursive pair of
   `_`-declared fns; a `?`-chain through an EXPLICITLY-unioned callee
   (§8); a `catch` over an inferred union (should need no changes at
   all — Phase 1's `catched_union_type` reads whatever `Type.Union`
   sits in the `Result`'s err side without caring how it got there,
   which is itself a good test that this design's "Typed needs zero
   changes" claim in §7 actually holds); the refusal path from §4 for
   a structurally-unresolvable site; the refusal (or acceptance, per
   §9.1's resolution) for zero sites found.
5. Cross-package program test once §9.3 is confirmed: a held package
   exporting a `_`-declared fn, a fresh package `catch`-ing its callers
   union.
