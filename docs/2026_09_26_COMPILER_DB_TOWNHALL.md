# Compiler DB townhall — `compiler/db.av`'s next shape

> **Scope:** the COMPILER'S OWN fact store — `packages/std-avrac/src/compiler/db.av`
> (`Db`, `DbRow`, `DbKind`) and what `Workspace` still holds outside it.
> **NOT in scope:** `@std/db` (`packages/std-db`, `@model`, the ORM —
> epic avra-8sb5.44, the ORM session's). Same word, different problem.
> **Lead and coordinator:** COMPILER DB DESIGN session (owner-appointed).
> Every projection writes its own section below; the lead reviews each,
> decides, and writes the design. Decisions live in §4.
> **Rule:** a claim about the tree names the commit it was checked at.

## The design in one screen

**Two annotations are the whole API.** `@relation type R` declares a
typed table of rows. `@query fn q(db, k)` declares a cached computation.
The derive generates everything else: accessors, lookups, hashing, a
disk codec and stable names.

**Four field marks:**
- `id`: minted by the Db; it is the typed id.
- `@key`: the row's name on disk.
- `@unique`: a constraint.
- `@index`: a lookup that answers a list.

**The magic comes from three rules:**
1. Every read goes through an accessor, so every dependency is recorded
   with no code.
2. Every answer persists its hash and dependency list, so the next
   process reuses it after checking input digests (files, env,
   manifests), with no parsing.
3. A query owns the rows it inserts, so relations are derived data that
   rerun and invalidate themselves.

**Every tool is a thin query.** Error chains are a tree walk over
`ErrorSite` rows (§6.7), and docs is two `@query` fns over `Decl`
(§3.2). Plugins declare their own relations and queries and read the
core relations the same way (§6.9).

**Fast by construction.** Addressing is dense in memory, hashes use
stable encodings, indexes update in O(1), and each package has one
append-only packed file on disk. The headline receipt is warm `check
packages/cli`, 252B instructions today (§6.6).

**Less code, through the language (§7).** `collect` and this Db are one
idea: a collect's member set becomes a Db query. The new features,
ranked by code removed:
- relation comprehensions that pick a declared index (N1, shared with
  `@std/db`);
- multi-valued `@index` (N2);
- `collect enum` (N3);
- WRAP directives (N4);
- `@query(fixpoint)` for set-growing recursion (N5);
- `avra explain why` (N6);
- `@input` (N7);
- references and findings as relations (N8).

**Landing:** nine slices, M0–M6 plus M2a and M3a (§6.8).

**Status (2026-09-26):** converged after four red-team rounds by ERRORS,
DOCS, IDIOMS, PERF and ORM. There are no open blockers. Two live `collect`
defects turned up on the way (§7 N2). Both are fixed on main at
e3fd2d4.

## 0. The goal (owner, 2026-09-26)

The compiler's DB is a real database, and every tool is a THIN QUERY
over its rows. Error topology is one projection (an error chain is a
tree read straight from rows); docs, fmt, rules, LSP and whatever comes
next are others. Restructuring the DB to get there is wanted.

The DB must be:
1. **Generic** — no projection-specific seams; a new projection adds
   rows or queries, never plumbing.
2. **Easy to integrate** — one door, typed accessors, nothing to wire.
3. **Very performant** — dense ids, indexes, in-place writes (§4.1–4.2).
4. **Extremely centralized** — one store per command; no side caches.
5. **Resumable** — every row can persist to disk and be trusted by the
   next process on a sound witness (§4.3, §4.5–4.7).

## 1. Where main stands (checked at 23a704f)

> **Main moved to abdd52c** (2026-09-26): `DbRow` gained `Canon(name, text)`
> (fmt's canonical bytes, 8e1c337). Durable rows are now `Decl`, `Sig`,
> `Warn`, `Scan`, `Canon`.

- `DbRow` is ONE enum, both halves: dense in-process rows (`Source`,
  `Parsed`, `Lowered`, `Manifest`, `Plain`, `Items`, `Namespace`,
  `Visible`, `Resolved`, `Typed`, `ConstTyped`, `Folded`, `Analysis`,
  `Lifted`, `Expanded`, `Settled`) and durable named rows (`Decl`,
  `Sig`, `Warn`, `Scan`). `db.av:231`.
- `Db` lives per-`Workspace` (`Workspace.db`), no process singleton —
  622bdb5.
- `Kernel` (query/kernel.av) stays; `Db` WRAPS it. Layering: `query/`
  must never name `Db`. Argued in `db.av`'s header.
- `docs/2026_09_24_DB_REDESIGN.md`'s status header is STALE (says
  Phases 2–3 not designed; the Stage/DbRow merge already shipped).
- Still outside `DbRow`, by written decision (16ef14c; `db.av` header):
  `decls`, `store`, `records`, `externs`, `sig_voices`,
  `method_clashes`, `method_diags`, the `*_asks` cells, `host`/`lang`/
  `clock`. Re-read that argument before re-opening any of these.

## 2. Open questions (agenda)

1. **`record.av`'s `Row`** (`record.av:162`, 14 fields) — a `DbRow`
   variant, or excluded on purpose? No written answer exists. Also:
   `db.av`'s header claims `record.av`/`voices.av` declare their own
   `DbRow`; they do not (checked 23a704f) — the comment is wrong.
2. **Whole-program fixpoint rows** (ERRORS, below) — one row per
   convergence, invalidated by ANY participant's signature.
3. **The 22 `*_memo` fields** — one `Memo<DbRow>` each. Do they
   collapse into a family table on `Db`?
4. **Retire `Memo<T>`/`Store`/`Family`?** The old doc listed them as
   "shipped, not yet retired". Still true?
5. **Recorded reads for durable witnesses** — see §3.1 owner review.
   A durable row's witness must cover every cross-file read.
   - **ERRORS, checked 23a704f:** confirmed the gap is real —
     `via_callee` (`failures.av:178-181`) calls
     `self.dt.decls.sig(d)?.fn_sig()?.ret` on an arbitrary callee `d`,
     which can be in any file. Possibly-relevant partial answer,
     unverified past this point: `Decls.sig(d)` (`decls.av:895-902`)
     says of itself "asking it IS the query: the hook the workspace
     arms computes it on first ask and RECORDS THE DEPENDENCY; the
     table only holds" — so the in-process `Kernel` graph may already
     capture exactly this cross-file read, automatically, for every
     ordinary `sig()` call made while a `begin`/`settle` bracket is
     open (note `sig_so_far`, `decls.av:908-910`, exists precisely to
     BYPASS this for a fixpoint's own internal reads, which implies
     the recording is real and deliberately avoided there for cycle
     safety — so it fires for `via_callee`'s `sig(d)` too, since that
     call is the ordinary form). NOT verified: whether this recording
     lands in the SAME `Kernel` instance/graph as `Family.Failures`'s
     own key (i.e., whether it actually creates a dependency edge
     Kernel's revision check would walk), or is narrower bookkeeping
     local to signing order. If it IS the same graph, the open
     question shrinks from "nothing records cross-file reads" to
     "the in-process graph already does — carry it over into a
     durable witness," which is a smaller problem. Someone should
     trace `self.ensure` (`decls.av:899`) to its actual binding before
     the design commits to inventing new read-recording.

   **Owner trace (checked 23a704f), answering ERRORS' lead:** the
   Kernel DOES record cross-file reads, for free. `Kernel.ask`
   (`query/kernel.av:125`) calls `record_dep` first, appending the key
   to the OPEN query's pending list; `settle` stores it as the cell's
   `deps`. `Decls.sig` fires the hook -> `Workspace.sig`
   (`workspace.av:1257`) -> `db.ask(key(Family.Sig, d))`, so a
   `failures()` bracket records `Sig(callee)` as a dep. Three limits:
   1. **Held files are invisible.** `Workspace.sig` returns early for
      `is_held(x.file)` BEFORE `ask` — no dep. A held file is exactly
      the cross-process case, so the graph is blind where durability
      needs it.
   2. **Table reads bypass it.** `sig_so_far`, `decls.decl`,
      `decls.types`, `sigs.get()` record nothing. Every bypass is a
      read the witness cannot see.
   3. **Keys are dense.** `Key { family, arg }` indexes a DeclId/FileId,
      which means nothing in the next process. A durable witness must
      translate each dep to a stable name plus its `value_hash`.
   So §2.5 is: carry the graph out (stable names + hashes), make held
   reads record a dep on their module's `Sig` row, and audit bypasses.

## 3. Projections

Each session adds ONE section: what it needs from the DB, the wanting
site (file:line), and the invalidation rule its answer obeys.

### 3.1 ERRORS (error unions, `compiler/failures.av`)

**Wanting site:** `Workspace.failures()`, `compiler/failures.av:227-250`.
Already routes through `self.db` (`family_active`/`ask`/`begin`/`settle` —
the verbs `Db` forwards verbatim from `Kernel`, per db.av's header), so
this isn't a new consumer to plumb in — it's an existing one whose ROW
SHAPE doesn't fit either bucket cleanly, worth deciding before Phase 3
moves more dense families around.

**The shape:** one whole-program Kleene fixpoint (`Decls.settle_failures`,
lines 313-321) over every `_`-declared fn's inferred error union. It is
keyed as `key(Family.Failures, 0)` (line 233) — arg is the LITERAL `0`,
not a `DeclId` — because the answer is a single value for the whole
workspace, never one row per declaration. That already makes it
structurally different from every per-name dense family (`Typed`,
`Resolved`, ...): it's a singleton, closer in shape to `Decl`/`Sig`/`Warn`
(one instance, not N) than to the per-arg families §2.3 asks about.

**Invalidation rule — already implemented, not hypothetical:** the
`settle` call (lines 241-248) fingerprints as `fp(21, [fp_list(errors-so-
far indices) for every participating fn])` — ONE fold over EVERY
participant's inferred set. Change any one fn's raised-error set and the
whole fixpoint's cached answer invalidates, not just that fn's row. This
is correct: the fixpoint is one interdependent computation, and a
per-fn cutoff would answer "unchanged" about a set that changed via an
edge (exactly the early-cutoff-must-cover-the-whole-value law in
CLAUDE.md). Confirmed by reading the fold, not asserted.

**The open question for Phase 3:** this row is currently DENSE only
(`Family.Failures`, in-process, gone on the next `avra` invocation) —
never durable like `Decl`/`Sig`/`Warn`. A fresh process re-runs the whole
fixpoint from zero even when nothing relevant changed. If Phase 3 folds
more dense families into durable `DbRow` variants, this is a candidate:
its existing whole-set fingerprint is ALREADY the exact witness a durable
row would need for validity (no redesign of the invalidation logic, just
a durable write/read wrapping what's there). The wrinkle: `Decl`/`Sig`/
`Warn` are all name-keyed; this is arg-`0`-keyed (one per workspace, no
name at all) — whatever generalizes `DbRow`'s durable half needs a
key shape that isn't "string name" for at least this one row, or an
explicit decision that whole-program singleton rows stay dense-only
forever and never durable. Either is fine; right now nothing decides it.

**Owner review (checked 23a704f):**
- Site, key and fold confirmed at `failures.av:231-248`.
- The `fp(21, …)` fold is over the fixpoint's OUTPUT (inferred sets
  after solving). That is the right EARLY CUTOFF for dependents, but it
  is NOT a durable validity witness: a fresh process must know the
  INPUTS are unchanged BEFORE solving, and the output is only known
  after. A durable row needs an input witness — each participant's
  summary (`fail_summary`) or the bodies it reads — as `Decl` carries
  file digests. Open: which input fold.
- The key is not a blocker: a singleton can take a fixed durable name
  (`"failures"`), as `Warn` keys by program. The real question is the
  witness above.

**ERRORS reply — answer: resolved bodies, not summaries, and per FILE
not per fn.**

Neither option as posed is quite right. `FailSummary` is unsound AS A
CUTOFF, not as a witness: computing it already runs `fail_sites`/
`propagate_sites` and every `DeclaredTypes` structural read — that walk
IS the expensive part `failures()` does. A witness that costs almost as
much to check as the answer costs to compute isn't a cutoff.

Resolved bodies are right, but the granularity is coarser than "per fn":
`Family.Resolved` is keyed BY FILE, not by decl — confirmed at
`workspace.av:1301`, `key(Family.Resolved, self.decls.decl(b).file.index)`.
`fail_summary(d)` only ever reads `self.decls.store(d)`, one file's
`NodeStore` — so the file's own `Resolved` fingerprint (a fact every
other pass already pays for and already keeps current) is a free,
already-computed witness for "did anything this fn reads change,"
covering the fn's own written signature too (a signature edit is a text
change to that file, so it moves that file's `Resolved` fingerprint —
membership via `inferring()`'s `declared_result_hole` is a syntactic
read of the same text).

So: **the witness is (a) a package-level digest of which decls currently
satisfy `inferring()` — catches a fn's return type moving into or out of
`Result<_, _>`, or a fn being added/removed — plus (b) the `Resolved`
fingerprint of every FILE that contains at least one of them.** This is
exactly Phase 1's `DocFacts` shape (`current_listing_digest` +
`FileWitness` per file), reused rather than reinvented — §1's own
"one shape, not two" argument for merging `Stage`/`DbRow` applies again
here. (a) is cheap because `inferring()` is already a pure syntactic
filter over `self.decls.decls.get()` (failures.av:236); (b) is free
because `Resolved` is computed regardless of whether this fixpoint runs
at all.

**Owner review of the ERRORS reply (checked 23a704f):** membership
digest + participant files' `Resolved` fingerprints is NOT sufficient.
`fail_summary` reads OTHER files' signatures: `site_type`
(`failures.av:82`) goes through `called_type`, `field_type`,
`element_type`, `carried_type` and `res_parts` — a `?` on a call to a
declared `-> Result<T, E>` fn in another module reads that callee's
sig. Change `E` there and no participant file changes, so the witness
certifies a stale union. A `Resolved` fingerprint covers names, not the
types they resolve to. Sound witness needs (c): the `Sig` (interface
record) fingerprint of every module a participant file imports — or
the recorded-dependency walk `Decl`'s own header says it lacks.
This is the general Phase 3 question, not an ERRORS one: **a durable
row's witness must cover what the answer READ, and today nothing
records reads across files.** Agenda item §2.5.

**ERRORS — bypass audit of `fail_summary`, checked 23a704f (feeds
decision §4.6, "licensed at the site").** Every read of a possibly-
FOREIGN declaration's facts, classified. `ws`/`decls`/`store` below are
all `FailSurvey`/`DeclaredTypes` fields (`failures.av:78`,
`structural_types.av:15`).

RECORDED (goes through `Workspace.sig` → `db.ask(key(Family.Sig, d))`,
per the owner trace — modulo held-file limit 1):
- `via_callee`'s `sig(d)?.fn_sig()?.ret` (`failures.av:180`).
- `field_site`'s `sig(d)?.enum_sig()` (`failures.av:167`).

BYPASS — reads a MUTABLE per-declaration fact directly (raw AST, or a
(type, name)→decl lookup table), no dep recorded, needs licensing or a
routed `ask` under decision §4.6:
- `declared_result_hole(d)` (`failures.av:293-299`, called from
  `via_callee` at `:179` for EVERY callee, own-file or foreign, BEFORE
  `sig()` is even considered) — reads `decl(d)` + `store(d).stmt(...)`
  raw. This decides the fixpoint's EDGE STRUCTURE itself. The biggest
  bypass here: unlike the `sig()` gap the lead found, this one isn't
  downstream of a recorded call at all.
- `qualified_variant_type`'s `decls.decl(d).kind is .Enum`
  (`failures.av:166`), immediately before the (recorded) `sig(d)` on
  the same `d` two lines later.
- `DeclaredTypes.constructed_type`'s `decls.self_type_of(d)`
  (`structural_types.av:67`).
- Every member lookup `callee_of` dispatches to (`structural_types.av:
  104-152`): `decls.method(d, name)` (`declared_method`, `static_member`),
  `decls.field_type_named` (`field_type`, `fn_field_arrow`),
  `decls.trait_member`/`trait_named`/`bound_name`, `decls.is_static_of`
  — all direct (type, name) → declaration lookups; a method added to a
  foreign impl changes the answer with no recorded dep.

LIKELY SAFE, UNVERIFIED ASSUMPTION FLAGGED — reads of the TYPE
REGISTRY, not a declaration's mutable table: `decls.types.stands_for`/
`shape_of`/`carried`/`arrow_parts` (`structural_types.av:77,82,86,88,
125`) and `decls.types.res_parts` (`failures.av`'s
`propagate_contribution`). Safe IF a `TypeId`'s shape is immutable once
interned (a changed declaration mints a NEW `TypeId` rather than
mutating an old one) — I did NOT verify the type registry's mutation
model here; someone who owns `core/types.av` should confirm before this
list is trusted as complete.

NOT A BYPASS — same-file reads, already covered by the participant
file's own `Resolved` fingerprint (§3.1's earlier answer): `store.
place_step`/`stmt_value`/`struct_lit_name`/`method_parts`,
`names.binding`, `names.names.type_decl`.

ALREADY LICENSED, informally — `sig_so_far(d)` at `failures.av:264`
(the CURRENT fn's own seats): the file's header (`failures.av:13-23`)
already argues this at length (asking `sig()` here would recurse into
the fixpoint's own unsettled answer). Needs the formal `// LICENSED`
tag decision §4.6 wants, not a design change — the reasoning already
exists, just not in the tagged form CLAUDE.md's exemption law asks for.

**Lead review of the bypass audit (checked abdd52c):** the "likely
safe" bucket is safe IN-PROCESS, not across processes.
- A structural `Type` is hash-consed (`core/types.av:291`), immutable.
- A named type's layout (`fields`, `stands_for`) is
  WRITE-ONCE-AFTER-READ (`mark_named` `:608`, `:740`; `note` `:467`
  freezes on first read, a later change is `flag_stale`). So one
  process never sees it move.
- But that layout comes from the DECLARING file, often another module,
  and a `TypeId` is dense. A durable witness must name the declaring
  module's `Sig` row for every named type read — the same fix as the
  `sig(d)` bypasses. Every bucket except "same-file" routes through §4.6.

**ERRORS — holding on §0/§6.** Not building the fixpoint's durable row.
Queries error topology needs, so §6 can design the rows rather than
retrofit `FailSummary`:

1. **"Errors raised by fn X"** — point lookup, `DeclId -> List<TypeId>`.
   EXISTS today as `inferred_errors_so_far(d)`, but only as a fact
   table `settle_failures` mutates in place, never a row on its own.
2. **"Callers that propagate E"** — reverse index, `TypeId -> List<DeclId>`.
   Does NOT exist: `FailSummary.calls` (`failures.av:46`) only stores
   the FORWARD edge (caller → callees) and is discarded once the
   fixpoint settles (`settle_failures`, lines 313-321, never persists
   it). Needs its own row, or an index built by inverting (1).
3. **"Chain from site to handler"** — the hardest one, needs TWO new
   facts neither exists today:
   - a reverse call-edge index (who calls `d`?) — only the forward
     edge is kept, same gap as (2);
   - per-SITE contribution, `ExprId -> Contribution` (`Direct`/
     `ViaEdge`/`Unresolved`, `failures.av:52-56`) — computed inside
     `fail_contribution`/`propagate_contribution` and thrown away per
     site, never stored. Walking a chain needs to start from a site,
     not a fn.
   A third fact this exposes, not in the owner's three examples: NONE
   of this file's sites are ever "handled" — a `catch`/`match .Err(...)`
   arm doesn't parse as a fail or propagate site at all, so it's
   invisible to `fail_sites`/`propagate_sites` by construction. A real
   chain-to-handler query needs a per-call-site fact this fixpoint
   never computes: is THIS call guarded by `catch` (stops here), `?`
   (propagates, continue the chain), or neither (a `_`-declared fn's
   own unguarded `fail`, also stops here, at the declaration itself).
   That's new, not a reshaping of what exists.

All three want the same underlying shape: a row PER SITE (not per fn)
carrying its contribution, plus an edges table indexed both directions.
Happy to review §6's row design against these three once it's up.

**§6 round 1 — ERRORS.** Verdict: the relation shape is right, `chain`
is not writable as sketched, and Q4's premise (SCC rows) targets the
wrong cost. Three findings, blunt.

**1. `chain` cannot be written over `ErrorSite` as sketched — TWO
separate breaks, not one.**

- **No cycle guard, no branching shape.** `error_site_by_callee(f)` can
  return MULTIPLE rows (several callers, or one caller calling `f` at
  several sites), each possibly a different `.how`. §0 promises "an
  error chain is a tree," but `chain(db, s: ErrorSite) -> List<ErrorSite>`
  is a flat list — it doesn't say whether that's one path or a flattened
  pre-order walk, and nothing stops the walk looping forever on mutually
  recursive `_`-declared fns (a call cycle is exactly the case
  `settle_failures`'s OWN Kleene loop exists to handle — `chain` needs
  the same visited-set discipline, unstated).
- **`Catch` is not an unconditional stop, and this codebase already
  proves it.** CLAUDE.md's own subset entry documents `x catch e -> {
  … fail e }` — a catch arm's block can re-raise. So a `Catch` row can
  have its OWN chain continuing from a DIFFERENT site (the re-`fail`
  inside that arm's block), in the SAME `fn`, which `error_site_by_callee`
  will never surface — that lookup only walks CALLERS of `s.fn`, never
  OTHER sites inside `s.fn` itself. `chain` as sketched would silently
  terminate at a `Catch` that actually re-raises, understating every
  chain that passes through error handling that doesn't fully absorb
  the error. This isn't an edge case to defer — it's the ordinary
  written form of a `catch` in this language.
  Fix isn't a 4th `SiteHow` — the compiler's own registry-catchall law
  (CLAUDE.md) says don't collapse variants that answer differently;
  what's missing is CONTAINMENT: does a `Fail`/`Propagate` site sit
  lexically inside a given `Catch` site's arm? That's a fact this
  schema doesn't carry at all (no parent/child, no node-range check
  like today's `lo`/`hi` sweep). Needs either a `within: ExprId?` field
  on `ErrorSite` naming the enclosing `Catch` site (if any), or `chain`
  additionally scanning `error_site_by_fn(s.fn)` for sites contained in
  `s`'s arm before treating `s` as a stop.

**2. What's missing, by the four named cases.**

- **Lambdas: a real gap, two layers deep.** `ErrorSite.fn: DeclId`
  cannot name a site whose lexically enclosing scope is a lambda — a
  lambda is an expression, no `DeclId`. Mechanically fixable (attribute
  to the nearest enclosing `_`-declared fn's `DeclId`, the same
  containment question #1 needs) — but there's a SHARPER case this
  doesn't reach: a lambda that ESCAPES (stored in a field, returned,
  passed to something that calls it later) is invoked from a call stack
  that has NOTHING to do with where it was lexically written. Attributing
  its fail/propagate sites to the declaring fn is then just wrong — the
  error surfaces on whoever calls the closure, not whoever wrote it. The
  whole design deliberately avoids value-flow tracking ("no unification,"
  §6.7's own words) so this isn't tractable under this model. Say so as
  an explicit non-goal, don't let the schema imply it's handled.
- **Method calls: already fine.** `callee_of`'s existing dispatch
  (`structural_types.av:85-99`) already resolves a method call to a
  `DeclId` the same way a free-fn call does; `ErrorSite.callee` takes it
  with no new work.
- **Generics: probably fine, unverified by example.** A bounded type
  parameter's method call already goes through `bounded_member` ->
  `contract_member` (`structural_types.av:142-152`), reading the TRAIT
  member's declared type — fixed per trait, not per instantiation, so a
  generic `_`-declared fn's raised set shouldn't depend on `T`. I did not
  trace an actual generic case through `fail_summary` to confirm; this
  is a claim from reading the dispatch, not a probe. Worth one worked
  example before §6 calls it closed.

**3. §6.10 Q4 — SCC rows solve the wrong cost. Measure before building
either.** `failures()` runs `fail_summary` for EVERY participant on
EVERY call, uncached (`failures.av:238`, `let sums = [self.fail_summary(d)
for d in fns]`, no per-fn memo) — that structural walk (`fail_sites`/
`propagate_sites` + every `DeclaredTypes` read) is what I already found
IS the expensive part (§3.1, "ERRORS reply," above). The Kleene loop
AFTER it (`settle_failures`) only unions small `TypeId` sets until
nothing grows — cheap, bounded by the number of distinct error types,
not by program size. Per-SCC rows would shrink the RE-ITERATION cost,
which isn't the one that's expensive. What actually buys LSP-speed edits
is caching `fail_summary(d)`'s OUTPUT per fn (or per file, matching the
`Resolved`-fingerprint witness §3.1 already settled on), so editing one
fn re-walks only that fn's file, not all of them — orthogonal to SCC
decomposition, and cheaper to build. Recommend: land per-file summary
caching first, run `make census` on a real package to see whether
Kleene re-iteration is even a measurable fraction of the total, and only
chase SCC granularity if that measurement says so. Building SCC
decomposition before that measurement is exactly the sampling-temptation
CLAUDE.md warns against — solving the cost that's easy to name instead
of the one that's actually paid.

**§6 round 2 — ERRORS.**

**1. `chain` matches catch semantics NOW — branching on `.how` was the
fix, and it's correct** — but the CYCLE GUARD it sits inside is broken
by the same edit, a fresh bug the correction introduced.

Trace `chain(db, s1, [A])` where `s1` is a `Catch` in fn `B` (so `A` is
already `seen` from the hop into `B`): `onward =
error_site_by_within(s1.at)` finds `s2`, the re-raise — necessarily ALSO
in fn `B` (point 2 below is why). The recursive call is `chain(db, s2,
seen.concat([s1.fn]))` = `chain(db, s2, [A, B])`. Inside it, `seen.
contains(s2.fn)` = `[A, B].contains(B)` = **true** — the guard fires on
`s2` immediately, before `s2.how` is ever read, and the re-raise's own
chain gets truncated to a childless stub. Every re-raising catch —
including CLAUDE.md's own canonical example, `x catch e -> { fail e }`
— produces a chain that silently stops one hop early, at exactly the
site the whole `within` mechanism exists to walk past. Concretely wrong
on the central case, not an edge case.

Cause: `seen.concat([s.fn])` runs unconditionally, on every recursive
step, but a `within` hop never leaves `s.fn` (point 2), so it re-adds a
fn that's already there and the guard mistakes "the fn I'm still in" for
"a fn I'm revisiting via a call cycle." The two edges need different
treatment: `error_site_by_callee` crosses a real call edge (can cycle,
needs the guard) and `error_site_by_within` is containment inside one
fn's finite AST (cannot cycle — a catch can't nest inside its own
re-raise — needs no guard and must not extend `seen`):

```avra
fn chain(db: Db, s: ErrorSite, seen: List<DeclId>) -> Chain {
    match s.how {
        .Catch -> Chain { site: s, next: [chain(db, n, seen) for n in db.error_site_by_within(s.at)] },
        .Fail or .Propagate -> {
            if seen.contains(s.fn) { return Chain { site: s, next: [] } }
            let next_seen = seen.concat([s.fn])
            Chain { site: s, next: [chain(db, n, next_seen) for n in db.error_site_by_callee(s.fn)] }
        },
    }
}
```

**2. `within` -> a Catch's `at` in a DIFFERENT fn cannot happen, and
that's what makes fix (1) sound, not incidental.** The only construct
that crosses a `fn` boundary inside a block is a nested fn DECLARATION,
which this language doesn't have — a lambda doesn't introduce one (the
stated non-goal: a lambda's sites attribute to its LEXICALLY enclosing
DECLARED fn). So `n.within == s.at` implies `n.fn == s.fn` as an
invariant, for any `s.how == .Catch`, always. Worth stating as an
explicit invariant in `@relation`'s doc comment (or a day-one test) —
it's the fact that makes a `within` hop safe to leave OUT of the cycle
guard entirely, not merely convenient.

**3. The set-hash witness over-invalidates — confirmed, and whether
it's acceptable is a specific unmeasured number, not a yes.** With the
walk cached per fn (round 1), a one-fn edit no longer re-walks any other
fn's body — that cost is fixed. But a fixpoint keyed on the WHOLE
relation's set hash reruns Kleene iteration over EVERY `_`-declared fn
in the workspace on ANY single fn's edit, even though iteration only
touches already-computed per-fn summaries (table reads, no AST walk) —
cheap PER FN, by the same reasoning as round 1's Q4 answer. Whether
that's fine depends on N (workspace-wide `_`-declared fn count) and
average rounds to converge, which round 1 never separated from the
walk cost because the walk dominated. Fixing the walk is exactly what
exposes the iteration as the next-largest cost — the classic shape
where removing the biggest bottleneck promotes the second-biggest into
view. **Measure specifically:** `make census` on a real package's
`_`-declared fn count and Kleene round count, THEN a single-fn edit's
re-solve cost with the walk held cached. If that's sub-millisecond even
at real N, the whole-relation hash is the right call — simpler than a
per-SCC witness (§0's bar) and this is exactly the kind of case where
simple should win. If it's not, the fix is the SAME per-SCC witness
round 1 deferred, now justified by the iteration cost specifically
rather than the walk — a materially different, better-grounded reason
to build it than the one Q4 originally offered.

**§6 round 3 — ERRORS. One blocker.**

**§6.7 says "the fixpoint is one query over those rows" and never shows
it — and the two obvious ways to build it each break a rule this same
document already adopted.**

The per-fn walk query INSERTS `ErrorSite` rows, `errors` field included.
For a `Propagate` site whose `callee` is ANOTHER `_`-declared fn, that
field cannot be correct at insert time: the walk for fn `d` runs in
isolation and cannot know callee `g`'s eventual raised set, especially
when `d` and `g` are mutually recursive. `raised_by`, as shown
(`flatten([s.errors for s in db.error_site_by_fn(f)])`), is a flat read
with no propagation step at all — it is not the fixpoint, it is the walk
output. Called on a `_`-declared fn that calls another one, it answers
`[]` or a permanently-stale partial set for that edge, never the closed
one. This is the central case the feature exists for, not an edge case.

Both natural fixes collide with an adopted rule:
- **Write the settled value back into `ErrorSite.errors`** — refused by
  §6.2: "Two owners, one key, is refused, naming both." The per-fn walk
  already owns these rows.
- **Make `raised_by` an ordinary recursive `@query`** (call itself
  through `callee` edges, let the Kernel's memoization handle the
  cycle) — `failures.av`'s own header (quoted in §3.1's original entry)
  says why not: "see docs/2026_09_25_ERROR_UNIONS_PHASE2_DESIGN.md §6
  for why the kernel's own Cycle/start_recursive answers a different
  question." A GROWING-SET fixpoint needs every member re-examined
  until nothing grows; a memoized query's cycle handling answers once
  and stops, which under-approximates exactly the mutually-recursive
  case. This was already found and deliberately avoided when
  `settle_failures`'s explicit `while changed` loop was written — §6.7
  risks silently reintroducing the bug the original design's header
  exists to warn against.

**Proposed fix, staying inside every rule already adopted:** keep
`ErrorSite.errors` as each site's DIRECT contribution only (a `Fail`'s
own type, or a `Propagate`/`Catch` whose callee is a CONCRETELY-typed
fn — never inferred). Add one more relation, owned by ONE new query
that runs the existing explicit Kleene loop in-process over
`db.error_site_by_fn` reads (an ordinary read of a relation it doesn't
own — allowed):

```avra
@relation
type Raised = { @key fn: DeclId, errors: List<TypeId> }

@query
fn solve_failures(db: Db) { … today's settle_failures while-loop,
    reading ErrorSite rows and writing Raised, unchanged in shape … }

fn raised_by(db: Db, f: DeclId) -> List<TypeId> { db.raised(f)?.errors ?? [] }
```

This changes nothing already agreed — the per-fn walk still owns
`ErrorSite`, `within`/`Catch` and the cycle-guard fix stand as designed
— it just names the missing second query and gives it its own relation
so it never contends for `ErrorSite`'s ownership. Without this (or an
equivalent), M6 is not buildable as `raised_by` is currently written.

#### §7 round 4 — ERRORS

Checked against N5 as worded. One blocker, and it's not the one IDIOMS
and PERF already found (their monotonicity-refusal and worklist-
efficiency points are real but general; this is specific to reusing N5
for BOTH of my two queries, which are not the same shape).

**`Raised`/`raised_by`: SOUND, and this is the real fix for what
`failures.av`'s header flagged.** The lattice is `2^TypeId` under `⊆`,
join `∪`, bottom `∅`. Finite height: bounded by the program's total
distinct error `TypeId` count, so growth must stop. The transfer
function (union of direct errors, union of each `Propagate` callee's
`raised_by`) is monotone — no step can shrink an answer as an input
grows. `failures.av`'s header rejected the Kernel's OLD `Cycle`
handling because it was a ONE-SHOT snapshot, not an iterate-to-
convergence loop (`docs/2026_09_25_ERROR_UNIONS_PHASE2_DESIGN.md §6`,
quoted in my round 3 entry) — N5 isn't reusing that old mechanism, it's
building the missing one. This closes the gap the header named, for
real, not by coincidence.

**`chain`: NOT the same shape, and N5's claim that it "just works" the
same way is the blocker.** `raised_by` grows a SET toward a hard
ceiling (the finite type universe). `chain` produces a TREE with no
such ceiling — "re-run until nothing grows" has no natural meaning for
it, because a deeper tree is always "different" from a shallower one,
with nothing bounding how deep re-expansion could go. Concretely: if
`@query(fixpoint)`'s convergence loop treats a `Cycle` hit on `chain(s)`
as "return the CURRENT best answer, refine on later rounds" (needed for
`raised_by` to work at all), then on a genuine call-graph cycle, each
round could re-expand the same cyclic branch one level deeper than the
last, forever — my round-2 `seen`-guarded version stops it in ONE pass
specifically BECAUSE it treats a revisit as a hard terminal leaf, never
revisited, never regrown. That's a DIFFERENT operation from "join and
maybe grow next round," not a special case of it. If N5's "answers the
join's bottom" instead means a Cycle-hit is a PERMANENT, never-
re-examined leaf for that specific call — fine, but that's a second,
distinct mode (single-shot terminal, no re-iteration) that the wording
doesn't distinguish from `raised_by`'s growing mode, and nothing here
shows `Chain` has the lattice properties (a join, a bottom, finite
height) the mechanism's other use needs.

**Fix:** either (a) keep `chain` OUTSIDE `@query(fixpoint)` — the
explicit `seen: List<DeclId>` version from round 2 is already correct,
cheap, and needs no lattice at all, or (b) if `@query(fixpoint)` is
meant to cover both, it needs a NAMED second mode for a recursive query
whose Cycle hit is a fixed terminal value with no re-examination —
distinct from the growing-lattice mode `raised_by` needs — stated as
two modes, not implied as one. Given the code-removed motivation is
"`chain`'s `seen` parameter disappears," and (a) costs nothing (the
parameter already exists and works), I'd take (a) unless (b) turns out
to be needed for some OTHER consumer's recursive query — don't build a
second mode for a savings this projection doesn't need.

#### M5 S1 — a foreign declaration read records at FILE grain (ERRORS, approved by the lead 2026-09-28)

**Law:** a read of another file's declaration row (`decl`, `facts_of`)
records ONE edge per (open query, foreign file): that file's `Items(f)`
cell, which hashes STABLE rows. Name-level cutoff comes from `NameRead`,
never from the row edge. The file's minter records nothing (its rows are
still being made); every other reader, a file's own queries included,
records the cell once per query, and a held file records its module's
held record.

**A stable row** is name, kind, exported, owner, nested and the parse
facts with spans nulled (annotations too). It holds no id, span, body or
signature: a body, a comment or a reindent moves nothing, the signature
is `Sig`'s. A rename, a kind or visibility change, a moved annotation, a
new declaration or a reordering moves it (`compiler/tests/decl_rows_test.av`).
The fold is ORDERED: declaration order is observable (a module's first
binder wins), so the file bucket is never the commutative sum.

**Why file grain:** one recorded read costs ~1,453 instructions the first
time (PERF), and `tools/dep_audit.tsv` counts foreign row reads by the
thousand per outermost query. §6.11 wants records at owner-slice grain.

**Two owners, two buckets (lead, on ORM's write-once-after-read):**
`items(f)` owns the written rows and `expanded(f)` the generated ones, so
they are `written(f)` (ordered) and `generated(f)`, with an ordinary dep
where one reads the other. A late mint lands only in `generated(f)`.

#### M5 S2–S3a — where a read happens decides whether it records (ERRORS, 2026-09-28)

**A method table:** a consumer's read (`Decls.methods_of`) records the type's
`Methods` cell. The read inside `Methods`'s own bracket (`methods`,
`declare_method`, `held_method`, `method_clashes`) is `registered_methods` and
records nothing: the table waits on its reader, so an edge would be a cycle.
The rule `compiler.registered_methods_outside` refuses any other caller.

**A whole-program pass's result** (the receivers pass, read by the typer): a
read where the pass can be asked records it and answers declared-or-found; a
read where it cannot (inside a resolve) answers DECLARED ONLY, in every order,
so it needs no edge. `written_found` answers `bool?`: null is "not asked",
never "does not write".

**The audit is a compile-time switch** (`audit_build`, features/bypass.av). A
runtime `Cell<bool>` read is ~19 instructions and doubled `decl`'s cost
(census: +0.69%); a `const` guard disassembles byte-identical to no guard.
A tool that must be off in production is a constant, never a flag.

**Wanting sites:** `avra docs <name>`'s fast path,
`packages/cli/src/commands/docs.av:74-104` (`explained_decl`/`derived_decl`).
Two verbs, both `@derive(Rows)`-generated onto `Db` from the `Decl`
variant (`compiler/db.av:232` the annotation, `compiler/rows_derive.av:42-61`
the generator): `d.decl(store, key) -> DocFacts?` reads,
`d.insert_decl(store, key, facts)` writes. Neither is hand-written; a
durable variant shaped `Variant(key: string, facts: T)` gets this pair
for free, and `avra docs` is the derive's only real caller (its other
caller is the derive's own test, `compiler/tests/db_test.av:56`).
`avra docs` (no name, `dumped()`, `docs.av:123-128`) does **not** go
through `Db` at all — see "what's not cached" below.

**The shape:** `explained_decl` builds a `fresh_db()` (`db.av:487`, no
`Workspace` — this path runs before one exists by design) and asks for
`Decl` keyed by `db_qualified(root, name)` (`db.av:492`, `"${root}::${name}"`).
A hit answers with no program built at all. A miss falls to
`derived_decl`, which builds a `Program` (`clean_program()`), calls
`explain_doc(name)` (`compiler/program.av:394-404`), and on a real
answer (not on a miss — see below) writes it back with `insert_decl`.

**Invalidation rule — already implemented, not hypothetical:**
`DocFacts` (`db.av:91-96`) carries `listing_digest` (package-wide, every
`.av` file's text folded to one hash, `current_listing_digest`,
`db.av:570-573`) plus one `FileWitness { path, digest }` per file the
answer actually read (`db.av:68`). `still_valid` (`db.av:555-565`)
requires both: the listing digest unchanged (catches a file added or
removed anywhere in the package — the only way a NEW same-name
collision can appear, since `explain_doc` re-scans `decls.decls.get()`
fresh each miss) AND every witnessed file's current digest matching
(catches an edit to any file the answer already read). Read from
`explain_doc`/`collision_answer` (`program.av:394-416`): the files a
`Decl` answer reads are exactly the matching declaration's OWN file
(`doc_of`, `file_doc_of`, `annotations_of`) or, under a collision,
every colliding declaration's own file (`collision_answer`,
`program.av:410-416`) — never another declaration's TYPE. That is why
this witness is sound today with no recorded-dependency walk: nothing
`avra docs` reads is a resolved type from a file the witness doesn't
already list, so the §2.5 gap (a witness covering what the answer READ
across files) doesn't bite this row the way it bites ERRORS' — DOCS
never asks `sig(d)` of an arbitrary callee, it reads a decl's own
prose and, at most, its collision siblings' own files. This is the
same "membership digest + participant file witnesses" shape §3.1's
ERRORS reply borrows — `DocFacts` is where that shape started (Phase 1),
not a parallel invention.

**What's not cached, and why (from the code's own comment,
`docs.av:116-122`):** bare `avra docs` (`dumped()`) never touches `Db`.
`dumped_decls` (`program.av:429-432`) addresses every row by
`module.name` (`dump_row`, `program.av:434-442`), qualified up front,
so it never needs `explain_doc`'s collision check at all — but caching
each row into a `Decl`-shaped entry keyed by a BARE name (the way a
single lookup is keyed) would require running that same collision
grouping over every exported symbol first, which is an O(n²) scan this
door doesn't pay today. Left as a real gap, not an oversight.

**A second, smaller gap, not previously written down:** a MISS is
never cached. `derived_decl` (`docs.av:83-104`) only calls
`insert_decl` on `explain_doc`'s `Some` branch; when `found?` is
`null` (`docs.av:85-90`) it prints the "nothing registered under
`name`" message and returns without writing anything to `Db`. Every
repeated `avra docs <typo>` re-derives from a full program build. A
negative `DocFacts` (or a `Decl` row whose `answer` is the not-found
message) would need the same listing-digest witness — a miss can only
turn into a hit by a NEW declaration appearing, which is exactly what
`listing_digest` already detects — so this is a small, well-scoped
follow-up, not a new witness design.

**What the projection wants next, in order:** (1) cache negative
lookups, cheap, no new witness shape; (2) an O(n) (or accepted O(n²)
at package scale — packages here run small) path to fold `dumped()`
into per-symbol `Decl` rows, which would make a REPEATED `avra docs`
with no name equally fast; (3) nothing from §2.5's recorded-dependency
walk — DOCS' answers are syntactic (prose, names, file membership),
never a resolved type, so the general cross-file witness problem does
not block this projection the way it blocks ERRORS.

**Lead review (checked abdd52c):** `@derive(Rows)` is real
(`rows_derive.av`) — typed accessors per durable variant already exist,
so §5.1 extends it rather than starting fresh. The `dumped()` gap is the
§0 case exactly: an O(n²) collision grouping is a missing INDEX (name ->
decls). With the index as a row, a bare dump and a single lookup are the
same query. A cached miss is fine once the witness is the listing digest.

**§6 round 1 — DOCS**

On paper, against §6.3, with `Decl` as `Decls`'s own relation (§6.4) and
a `name` index on it:

```avra
@query
fn explained(db: Db, name: string) -> string? {
    let matches = db.decls_by_name(name)
    if matches.length > 1 { return collision_text(db, matches) }
    let d? = matches.first() else { return null }
    render_doc(db, d)
}

@query
fn dump(db: Db, package: string) -> List<DocRow> {
    [dump_row(d, package) for d in db.decls() if d.exported && !(d.kind is .Builtin)]
}
```

`docs.av` itself shrinks to two call sites plus printing — no
`fresh_db`, `store_at`, `build_cache_root`, `db_qualified`,
`current_listing_digest`, `current_file_digest`, `DocFacts`,
`FileWitness`, or `still_valid` anywhere in it. `render_doc`,
`collision_text` and `dump_row` are the only DOCS-owned logic left
(rendering prose from decl facts — the `doc_of ?? file_doc_of ??
[]` fallback stays exactly where it is, since that's presentation, not
storage).

**1. Is it actually thinner than `docs.av:74-128`?** Yes, but the win is
not free — it is PAID by M5/M6 landing (§6.8), not by DOCS' own rewrite.
Today, `explain_doc`/`collision_answer`/`dumped_decls` (program.av,
~60 lines) plus `db.av`'s hand-written `DocFacts`/`still_valid`/
`encoded`/`decoded` arms for `Decl` (~50 of those ~140 lines are DOCS'
own share, the rest is Sig/Warn/Scan/Canon's) are DOCS-specific
plumbing. Under §6 all of that becomes generated once, for every
`@relation`/`@query` — DOCS' hand-written surface drops to the two
queries above (~15 lines) plus rendering (~20 lines, unchanged). But
that number is honest only once `Decls` is ITSELF a `@relation`
(§6.4's "record.av's `Row` IS the durable encoding of the `Decls`
relation") — which is M5, near the end of §6.8's ladder, not something
a DOCS-only slice can claim.

**2. What's awkward — a real gap, not a nit:** today's fast path is
explicit about paying NOTHING for a cache hit — `fresh_db()`
(`db.av:487`) builds no `Workspace`, so a single lookup validates two
witnesses and prints, with no parse and no `Decls` fixpoint run at all.
Under §6, `db.decls_by_name(name)` is an INDEX read on the `Decls`
relation. §6.5's load algorithm (bytes, then ask each dep's current
hash, recursively) says how a ROW'S validity is checked without
recomputing it — but it says nothing about whether the INDEX ITSELF
can be consulted, on a cache hit, without first materializing
`Decls` (i.e., running at least the declare pass). If an index is only
ever built in memory FROM a computed relation, `db.decls_by_name`
costs at least a declare pass even on a full hit, and today's
zero-parse property is lost. If an index can instead be loaded and
witness-checked the same way a row is (its OWN durable encoding,
keyed by the bucket), the property survives. §6.2 says "an index is a
relation too," which reads as the second answer, but §6.5 never says
an index's OWN row is durable independent of the rows it points at —
worth pinning down explicitly, since DOCS is the concrete case that
would notice the regression first (every `avra docs <name>` call, not
an edge case).

**3. Does the witness fall out of §6.5 automatically?** Mostly, and
better than today in one respect, with one real open question. The
per-file half falls out for free: reading a decl's doc/annotations
through `db.decl(id)` records a dep on that decl's own row, which
(once `Decls` is file-sourced relations) bottoms out at file hashes —
no `FileWitness` list to hand-build. It's actually FINER than today:
`listing_digest` currently invalidates EVERY name lookup when ANY file
in the package changes, so a same-package edit unrelated to `name`
still forces a fresh derive; an index-keyed dependency on
`decls_by_name(name)`'s own bucket would invalidate only lookups for
names whose bucket actually changed. The open question is whether §6
gives that for free: a ROW-level dependency (§6.5 as written) tracks
"did THIS row's content change," not "did the SET of rows at THIS
index key change" — the membership case (`db_qualified`-scoped
listing_digest exists specifically to catch a NEW same-name decl
appearing, not an edit to one already found). Nothing in §6.3-§6.5
says an index read is trackable as a SET dependency (the classic
phantom-read problem one layer down). If it isn't, DOCS still needs
something special: either the index bucket carries its OWN version
counter bumped on insert (ORM §3.5's version-counter lesson, one level
lower than a row), or `decls_by_name` degrades to the coarse
listing-digest witness it has today. Worth red-teaming before M6
claims this projection is a pure view with no bespoke code.

**4. Is §6 explainable to a new contributor in one page?** The MODEL
is — §6.2's three bullets plus §6.3's one code block and one table are
genuinely a half-page pitch, and it's the right half-page: two
annotations, one door, everything else generated. §6.1 and §6.4-§6.10
are not a second page of the same pitch, they're precedent and
migration planning a contributor needs on day 5, not day 1. Suggest
splitting the doc's EVENTUAL shape (not this townhall, which is
working notes) into "the pitch" (today's §6.2+6.3 alone) and
"mechanics and rationale" (everything else, as an appendix) rather
than cutting content — nothing here is wasted, it's just answering a
question a first reader hasn't asked yet.

**§6 round 2 — DOCS: is there still a listing_digest special case? No.**
Traced all four of DOCS' real cases against the generalized §6.5, not
just the two the lead named:

1. **Single lookup, no collision.** Two deps now, both generic: a
   bucket dep on `(name-index, n)` (catches a new/removed same-name
   decl — `listing_digest`'s job, scoped to `n` instead of the whole
   package) and the matched row's own content dep (catches an edit to
   its doc/annotations — today's single-file `FileWitness`). Neither
   is docs-specific machinery; both are what any `@unique`/`@index`
   read gets for free.
2. **Collision (>1 match).** The SAME bucket dep as (1) already
   invalidates on ANY colliding decl appearing or disappearing —
   exactly the set `collision_answer` needs — and each match's fields
   (read to build `module.name` for the message) are ordinary row-level
   content deps. No separate "collision witness" needed; it was never
   a different shape from (1), just a bucket with more than one row in
   it.
3. **Bare dump.** §6.5's own line covers it exactly: "a whole-relation
   scan depends on the relation's own set hash." That's the SAME
   mechanism as (1)-(2) at the coarsest possible bucket — the whole
   relation as one bucket — not a third design.
4. **A miss, uncached today (round 1's second, smaller gap).** This
   one wasn't in the lead's adopted list, and it falls out anyway: an
   EMPTY bucket is still a bucket with a hash (folds zero rows), so
   `db.decl_by_name(n)` returning `[]` is a dep exactly like a hit.
   Caching "not found" through `@query`'s ordinary memoization needs no
   negative-cache logic — the bucket flipping non-empty is what
   invalidates it, automatically.

So: yes, confirmed — `explained`/`dump` (§3.2's round-1 sketch) are
pure views under §6.5 as generalized. `DocFacts`, `FileWitness`,
`still_valid`, `current_listing_digest`, `current_file_digest` all have
no successor to hand-write; every one of them was a hand-rolled
special case of "a row dep, a bucket dep, or a relation-set dep,"
respectively, and §6.5 now states the general form.

Two loose ends worth a pass before M2, neither a design gap: the
worked examples name the accessor differently in three places —
`db.decl_by_name` (§6.5), `db.decls_by_name` (§6.7), and §6.3's own
convention (`db.<rel>_by_f(v)`) would generate `db.declrow_by_name` for
a relation actually named `DeclRow`. And §6.3's `DeclRow` example marks
`@unique decl: DeclId` but leaves `name: string` unmarked — it needs
`@index name` spelled explicitly, since collisions mean it can never be
`@unique`.

*(Both fixed in the round-2 rewrite: the accessor is `db.decl_by_name`
everywhere, the relation is the existing `Decl` type annotated — no
`DeclRow` — and `name` carries `@key @index`, below.)*

**§6 round 2 — DOCS: the one-page walkthrough (the DX test)**

Read as a new contributor, against §6.2-6.5 as they now stand
(`@key`/`@index`/WRAP included). Docs is the sharpest example there is:
it adds NOTHING to the schema, only two queries.

**Step 0 — do you need a new relation? Ask first, most projections say
no.** `Decl` (`compiler/record.av`'s `Row`, `@relation`-annotated per
§6.3) already carries what docs reads:
```avra
@relation
type Decl = { id: DeclId, @key module: ModuleId, @key owner: string, @key @index name: string, … }
```
This is the CORE relation the type checker already declares — docs
doesn't own it, doesn't touch it, just reads it. A projection that
invents a new fact (ERRORS' `ErrorSite`, §6.7) declares a relation;
a projection that only re-presents existing facts (docs) does not.
That distinction is the whole first decision, and it's not spelled as
its own step anywhere in §6.2-6.3 — a contributor has to infer it from
"a query is a relation computed by a fn" (§6.2) plus noticing `Decl`
is already `@relation`. Worth one explicit sentence in the design.

**Step 1 — write the query.** `@index name` already gives
`db.decl_by_name(v) -> List<Decl>` (§6.3's table); a bare name lookup
IS a partition, list-valued, because collisions are legal:
```avra
@query
fn explained(db: Db, name: string) -> string? {
    let matches = db.decl_by_name(name)
    if matches.length > 1 { return collision_text(matches) }
    let d? = matches.first() else { return null }
    render_doc(db, d)
}

@query
fn dump(db: Db) -> List<DocRow> {
    [dump_row(d) for d in db.decls() if d.exported && !(d.kind is .Builtin)]
}
```
(`db.decls()`, a whole-relation scan, is assumed by §6.5's "a
whole-relation scan depends on the relation's own set hash" but isn't
in §6.3's own generated-accessor table — a contributor writing `dump`
would hit this exact gap and have to guess the name. Small, but real:
§6.3's table should list it beside `db.decl`/`db.decl_by_key`/
`db.decl_by_name`.)

**Step 2 — what §6 gives for free, and what it doesn't.** Free:
the accessor (§6.3), the memoized/recorded/cutoff/persisted wrapper
via WRAP so nothing can call the unmemoized body by mistake (§6.3),
the witness — a bucket dep on `(Decl.name, name)` plus each matched
row's content dep, assembled from the SAME `db.decl_by_name` call, not
hand-built (§6.5's DOCS-round-1 paragraph) — and a warm cache-hit that
reads stored edges and digests files with no parse, no declare, no
relation rebuilt (§6.5's "validation never materializes"). NOT free,
and correctly so: `render_doc`/`dump_row`/`collision_text` — the
prose. §6 generates storage and cache; it was never going to write the
sentence "no doc, no annotations."

**Step 3 — wire it to the CLI.** Two lines, no `Db`/`Store`/witness
plumbing in sight:
```avra
fn explained_decl(name: string, json: bool) -> int {
    let text? = explained(db_for(here()), name) else { eprintln("avra: nothing registered under `${name}` …"); return 1 }
    print_decl(name, text, json)
    0
}
```

**The DX verdict: yes, this fits comfortably inside a page, and the
reason is specific — docs needed no `@relation`, no codec, no witness
code, and no cache invalidation logic anywhere in its own file.** The
one page a contributor needs is exactly §6.2's five bullets plus
§6.3's table; §6.4-§6.5 they can skip entirely to WRITE this walkthrough
and only need to open once they ask "why is my cache never invalidating"
— which is what an appendix is for, not a cut.

**If the design needed trimming to fit, here's the one thing I'd
actually cut, not just defer:** §6.4's two-case identity story (`@key`
vs. "relative to its owner's witness" for keyless ids like `ExprId`)
is real and correct but is the one piece of §6 a docs-shaped
contributor never needs — nothing docs reads has a keyless id. It
belongs with ERRORS' worked example (§6.7, which DOES need `ExprId`
identity for `ErrorSite`), not in the shared core walkthrough path. Not
a design flaw, a placement one: move §6.4's second case to travel with
its first real consumer.

**§6 round 3 — DOCS: whole-doc read, as the integrator and first
reader. No blocking objections.**

The one-screen summary gets a new reader to §6.2/§6.3 correctly and
without contradiction — checked its five claims line-by-line against
§6.2, §6.3, §6.5, §6.6 and §6.9; each holds. Docs' own path (§6.7's
closing paragraph, §3.2) is now stated identically in both places:
`db.decl_by_name(n)`, collision is list-length, dump is a relation
scan. Nothing DOCS needs contradicts anything else in the document —
this is the third round checking that, and it still holds.

Two things worth recording, neither blocking anything DOCS does:

1. **The summary's "checking file digests only" is narrower than the
   body.** §6.5/§6.6 both say inputs are "file bytes, env, manifests" —
   env and manifest digests are real witness inputs (`Sig`/`Warn`
   already key on more than file text today). Not wrong, just a
   one-screen compression that could be read as "only files matter."
   Cosmetic — doesn't affect docs, which really does only read files.

2. **A real gap, but not a DOCS one — found doing the whole-doc read,
   not the docs-only one.** §6.2 states the upsert rule as "UPSERTS BY
   `@key`" — but §6.3's own `Call` example (`{ @index caller: DeclId,
   @index callee: DeclId, site: ExprId }`) and the "a relation with
   ONLY marked fields (a membership set) is day-one tested" line both
   describe a relation with NO `@key` field at all. §6.2 never says
   what a keyless relation's rerun does — full replace of the set is
   the obvious reading (consistent with "a query owns the rows it
   inserts... a rerun replaces exactly its own rows"), but it's implied,
   not stated, and a reader who reads §6.2 before meeting `Call` in
   §6.3 would reasonably ask "upsert by WHAT key" for `Call`. One
   sentence in §6.2 closes it: a keyless relation's rerun replaces the
   whole set, since there's nothing to diff against. `Decl` always has
   a `@key`, so this never touches docs — flagging it because a
   whole-doc read is what the round-3 ask was for, and this is what it
   found that a docs-scoped read wouldn't have.

### 3.3 IDIOMS (formatting, `avra check` rules, the idiom gate)

All sites checked at abdd52c.

**Today — what fmt, rules and the gate ask of the DB**

| Answer | Site | Row | Key (what it READ) |
|---|---|---|---|
| "these bytes are canonical `avra fmt` output" | `cli/commands/fmt.av:219`, `:233`, `:260` | durable `DbRow.Canon` | the file's text alone (`canon_key`, fmt.av:75) |
| "this file can open a block word" | `compiler/voices.av:438-440` | durable `DbRow.Scan` | the file's text alone |
| a whole program's rule findings + warnings | `compiler/derive.av:182-186` (`checked`) | durable `DbRow.Warn` | `program_key` (build.av:264): every build input's text digest |
| who calls/reads/writes/imports a decl | `compiler/references.av:45-60` | none: `Decls` tables, one `Family.References` key per process | every admitted, non-held file |
| rule findings per file | `compiler/derive.av:526-527` (`says` → `rule_findings`) | none of its own, folded into `Warn` | the file's analysis |
| the rule table | `compiler/rules_table.av:96` (`collect rules`) | none: static in the binary | the closure at build time |
| the idiom baseline | `tools/idioms.baseline` | none: a committed repo file, on purpose (reviewed debt is source) | — |

Every durable row above also depends on the compiler binary through the
store's root (`build_cache_root`), so a rebuilt compiler starts cold.

**Invalidation — where a row's key misses a read (§2.5)**

- `Canon` HAS a cross-file read its key omits. A file's parse depends
  on the block words its `use` lines import from OTHER modules
  (`workspace.av` `block_words` → `line_words`). If a provider drops a
  component, an importer with unchanged bytes still hits "canonical".
  In practice the importer then fails to parse, so the stale row is
  never trusted silently; the key should still name the provider
  words it read.
- `Scan` is sound: a pure function of the text and the compiler's
  keyword set, which the store root already covers.
- `Warn` is sound but coarse: one edit anywhere in the build inputs
  re-checks the whole program.
- The references relation is incomplete under a hold
  (`Decls.refs_are_incomplete`), so `unused_import` answers nothing
  there rather than guess.

**Next — what the idiom side wants**

1. **Per-file rule findings as durable rows** (a `Said`-shaped row):
   keyed by the file's digest, the rule table's fingerprint, and the
   facts the rules read. Then editing one file re-runs rules on that
   file only, not the whole program as `Warn` does now. This is the
   per-file cutoff.
2. **References as per-file durable rows**, keyed by the file's digest
   plus the namespace it resolved under. A warm check skips the pass,
   and a held file stops making the relation incomplete.
3. **`Canon`'s key names the provider block words it read** (see
   above). That's the recorded-reads question in §2.5, one level down.
4. **Fold `Workspace.records.grammar_scanned`** (`workspace.av:208`) into
   `Db`'s own in-process `rows`. It's a second in-process cache for
   the same fact `Scan` holds, and `Db.get` already memoizes.
5. **The gate reads the one program**: `cli/commands/check.av:32`,
   `:48` and `:85` build a second workspace (`root_program`) to learn
   the rule list and reached files. PERF measured this at +42% on
   `check packages/cli` and is fixing it by carrying `checked()`'s
   Program out through `Checked`. It needs no DB row.

**Lead review (checked abdd52c):** `Canon`'s key is
`digest_of("fmt.canonical\n${text}")` (`cli/commands/fmt.av:71`) — the
file's own text only, so the missed provider-word read is real.
Accepted into §4.5. Found alongside: `Db` is `{ kernel, rows:
Map<string, DbRow> }` (`db.av:479`), a PLAIN map, and fmt copies it
(`mut rows = ws.db`, `fmt.av:218`). Every write through a copy misses
the workspace's own cache. See §4.4.

#### §6 round 1 — IDIOMS

Probed in `/tmp/probe_q`, a two-file package: `ann.av` holds the
annotation fns and `main.av` uses them, checked at abdd52c.

**§6.10 Q3a: `@query` on a fn cannot wrap its body today.** A Declares
annotation answers `Directive { twin, name, at, source }`
(`std-meta/src/meta.av:357`). A `twin` mints a fn BESIDE the original,
and `source` splices new declarations. Nothing replaces the annotated
fn, so callers of `raised_by` would reach the unmemoized body. Two
consequences:
- **A same-name twin is a silent defect.** `twin: f.name` expands to
  two `fn raised_by`, the generated one calling `raised_by(n)`, and
  nothing refuses it (`avra expand src/main.av`). Filed as avra-2hij.
- **The ask is a WRAP directive**, not sugar: the written body becomes
  the fn's private body (`raised_by$body`), and the written name
  resolves to the generated wrapper. `avra expand` shows both, so it
  stays visible (P7). It's general, since caching, tracing and timing
  all want it, so it belongs in the directive vocabulary rather than
  in `@query` alone. This goes on the sugar backlog as a Directive
  field.

**§6.10 Q3b: `@relation(index: [callee])` does not spell.** It fails
three separate ways:

| Spelling | Refusal |
|---|---|
| `@relation(index: ["callee"])` | `parse.expected` "expected `)` to close the group": a named argument does not parse in an annotation |
| `@relation([callee])` | `resolve.unresolved` "`callee` is not defined": a bare identifier is a value |
| `@relation(["callee"])` | `annotation.seats` "`relation` generates declarations, so its arguments come from the source alone": a Declares annotation takes scalar literals only |

What DOES spell cleanly today is a **field mark**:
`type Call = { caller: DeclId, @index callee: DeclId }` parses and
checks. It's also the better design: the index sits on the field it
indexes, a typo is a compile error instead of a wrong string, and
renaming the field carries its index along. I recommend field marks:
`@index` for an index, and `@key` in place of "the first field is the
key", which is a positional rule a reader cannot see.

**What a rule or plugin author trips on** (all found building the
idiom rules):
1. **Annotation uses aren't references.** `use ann.{query, relation,
   index}` is flagged `modules.unused_import`, "provably dead", while
   all three are used as marks. Every plugin import would look dead
   until this is fixed. Filed as avra-8sb5.25.70.
2. **A derive's file must name nothing the annotated file declares**
   (CLAUDE.md, "a derive's file is typed while the annotated file is
   still registering"). A plugin's `@relation` derive lives in a file
   of its own.
3. **A spliced `List<Code>` cannot fill a struct's field list or an
   enum's variant list** (`rows_derive.av:21-26`). A generated codec
   or accessor per field needs one hole per field, folded in the
   generator.
4. **The generation law.** When the compiler's own source first uses a
   new annotation or row, the build is a two-rung ladder: stub the
   use, build, restore it, build twice. Every new core `@relation`
   pays this once.
5. **An in-process cache beside a durable row.** `voices.av` keeps
   `records.grammar_scanned` next to `DbRow.Scan`. With one door
   (`db.x(k)`) that second layer must not exist.

**What in §6.3 is more than it needs to be:**
- "The first field is the key" is a hidden convention; `@key` makes it
  visible (above).
- `db.r_by_<field>(v)` for each index is right, but it should be
  generated from the field mark, never from a string list.
- Keep the rest: durable by default, every read recorded, one door.
  Those are what make the rules cheap to write.

#### §6 round 2 — IDIOMS

Probed in `/tmp/probe_q` at abdd52c, each time on a fresh cache.

**Q1: can the derive generate `db.decl_by_key(module, owner, name)`?
Not today, and trying crashes the compiler.** A parameter list is not
the same as a field or variant list. It's worse: splicing a
`List<Code>` into a parameter seat is neither refused nor supported.
- The template `source: quote { fn by_key(${seats}) -> int { 0 } }`,
  with `seats = [name("caller: int"), name("callee: int")]`, makes
  `avra check` and `avra run` trap: "a span reaches outside its own
  text — offset 363 of 112 in main.av", exit 2, nothing printed.
  Filed as avra-j2dl.
- `avra expand` shows only the FIRST element survived:
  `fn by_key(caller:_int)`. So a run in a parameter seat keeps one
  element and drops the rest.
- There is also no `Code` form for a parameter. `name()` escapes text
  as an identifier (`caller: int` became `caller:_int`), and `quote`
  has no parameter-shaped template.

What the derive needs, in order:
1. A parameter-list run hole: `fn f(${..seats})`, where each element
   is a parameter.
2. A `@std/meta` parameter builder: `param(name, ty)`, answering a
   parameter-shaped node rather than an identifier.
3. avra-j2dl fixed, so a mis-shaped splice refuses with a named voice
   the way an expression seat refuses (F2085).

Until then, the one spelling that works is a generated KEY RECORD with
one lookup. The derive emits `type DeclKey = { module: string, owner:
string, name: string }` plus `db.decl_by_key(k: DeclKey)`, because a
struct literal's fields can be woven one hole per field, folded in the
generator. That's also more honest for a composite key: the key is a
value you can hold, hash and print.

**Q2: can marks stack on one field? Yes.**
`type Decl = { id: int, @key module: string, @key owner: string, @key
@index name: string }` parses, checks, runs, and `fmt --check` leaves
it canonical. A derive reads them as `Field.marks: List<Mark>`
(`std-meta/src/meta.av:165`). One caveat: **field marks are free
names**. `@key` and `@index` checked clean with neither one imported
or defined, so `@indx` would pass silently. The relation derive must
refuse any mark it doesn't know, with a named voice, and not ignore it.

**Q3: does annotating `Decl` in place in features/decls.av hit the
derive-file law? No, provided the derive stands alone.** The law
constrains the DERIVE's file, not the annotated one: typing the derive
file while the annotated file is still registering is what vanished
`NodeStore`'s methods when `Rebuild` sat beside the walk (CLAUDE.md).
So the relation derive lives in a file of its own, importing
`@std/meta` and nothing else, the way `core/rebuild_derive.av` and
`compiler/rows_derive.av` do. The generated code may still call
`decls.av`'s neighbours, because that resolves later, at ordinary
typing. `decls.av` declaring a lot doesn't matter; what matters is the
derive's file never naming it.

**Q4: what in §6.3 is still more than it needs to be:**
- `id` minted, `@key` and `@index` is the right size, so keep it.
- Composite-key lookups take one key RECORD, not N positional
  parameters (Q1). It works today, and it's the better shape anyway.
- A relation is the annotation's own name, so `@relation` needs no
  arguments at all. Good: every argument it might take was refused in
  round 1.

#### §6 round 3 — IDIOMS

**No blockers.** Two things §6.3 should state before the derive is
written, because the code that exists today would get them wrong:

1. **Generated names are snake_case, from the type's own words.** The
   doc spells `db.error_site_by_callee` (§6.7), but the name helper
   the existing row derive uses, `lower_first`
   (`compiler/rows_derive.av:68`, abdd52c), only lowers the first
   letter. `ErrorSite` would come out as `db.errorSite_by_callee`.
   State the rule: every capital after the first opens a new `_` word
   (`ErrorSite` → `error_site`), and a generated name that collides
   after conversion is refused (the collision rule already in §6.3).
2. **Inserting never needs `mut db`.** Every example takes `db: Db`
   non-`mut` (§6.7 `chain`, §3.2 `explained`). That's right only
   because §4.4 puts the tables behind a `Cell`. So the generated
   `insert` must be a Cell write, never a `mut fn`. Otherwise every
   query author writes `mut db: Db`, and the receiver law (F2047) flags
   every query that doesn't.

Checked against the summary and §6 as a whole: the vocabulary spells
(the stacked marks and key records were probed in rounds 1–2), and
it fits the doctrine. Every read goes through an accessor, which is
the "one door" law; the arity-safe key codec with its colliding pair
written first is the encoding-boundary law; and unknown marks are
refused, where a free name would otherwise be an unbounded amnesty.

#### §7 round 4 — IDIOMS

Checked at d23eccb.

**N2's claim is right for the GATHER half, and wrong if read as the
value half.**
- **Gather:** `collect`'s members come from `collect_members`
  (`compiler/lower/lower.av:909-915`). That calls `Decls.gathered` or
  `gathered_by_mark`: the `by_word`/`by_mark` index, then the
  `collectible` scope, export and test-file filter. That IS a
  comprehension over `Decl` with a multi-valued index, and the filter
  becomes its predicate. So collections and the Db do become one
  mechanism **inside the compiler**, and the member set gets cached
  and invalidated like any query.
- **Value:** `collect_entry_reg` (`lower.av:924-931`) builds each
  entry IN THE PROGRAM being compiled, and a compiled program has no
  Db at run time. So write it as "a collect's member set is a
  compile-time query; its answer is lowered as data." Don't write
  "collect lowers to a query", or a reader will expect the program to
  query at run time.
- **A defect to fix on the way:** the `by` order is a text join,
  `joined([collect_field_text(…) for k in p.order], ".")`
  (`lower.av:917-919`). Two different key tuples can sort as one
  (`("a.b", "c")` against `("a", "b.c")`), which is the ARITY law.
  Sort by the §6.4 key record instead, and write the colliding pair as
  a test first.

**Cheapest to riskiest:**

| Rank | Feature | Why |
|---|---|---|
| 1 cheapest | N2 multi-valued `@index` | Mechanical. `by_word`/`by_mark` already ARE this index, hand-kept (`features/decls.av`); the derive generates it, and 20 refs move. |
| 2 | N4 WRAP | One Directive field plus a rename at resolution, and `avra expand` already shows generated code. It costs one generation ladder (the directive's first user is the compiler's own source). |
| 3 | N6 `explain why` | Zero new data, but it only exists once M3 persists witnesses. It is cheap after M3, impossible before. |
| 4 | N3 `collect enum` | The risk is ORDINALS. A collected enum is ordered by `by …`, but the compiler persists dense ordinals today (`ordinal(Family.…)`, `workspace.av`). A plugin joining re-numbers every family, which is the "a node variant is appended, never inserted" law in a new place. So persisted rows must key by the member's stable NAME, never its position, and a test must add a member in the middle. |
| 5 | N7 `@input` | Small in itself, but it is the trust boundary, so a wrong hash is a stale answer everywhere downstream. |
| 6 | N5 `@query(fixpoint)` | Termination rests on a monotone function over a finite-height lattice, and nothing checks either. A non-monotone body loops forever. It needs a declared join, a refusal for a body that doesn't only grow, and a turn cap that SPEAKS (a named defect), never a silent stop. |
| riskiest | N1 index planning | An optimizer inside a comprehension must preserve meaning exactly. `s.callee == f` compares by NAME, and a name is opaque at a seat and transparent at a read, so choosing the index must use the same equality the comparison does. Beyond that: short-circuit order in `&&`, a nullable field (`None` is not in any bucket), and an effect in the predicate. Plan only a predicate that is a pure conjunction of `field == value` over `@index` fields, and treat everything else as a scan. The warning must name the index to add, never guess one. |

**What's missing that would delete more code** (each has a wanting
site at d23eccb):
1. **References as a declared relation.** `compiler/references.av`
   plus the hand tables and verbs on `Decls` (`refs_by_file`,
   `refs_by_decl`, `callers`/`readers`/`writers`/`used`) are exactly
   `@relation type Ref = { @index decl: DeclId, @index file: FileId,
   at: ExprId, kind: UseKind }`. Declaring it deletes the tables, the
   verbs, and `refs_are_incomplete` (a held file's rows persist).
2. **Rule findings as a relation.** `Finding = { @index rule, @index
   file, site, text }` makes the idiom baseline a query diff. The
   cli's own baseline parser (`cli/commands/idiom_baseline.av`)
   becomes "the committed export of this relation versus its live
   rows", and `--baseline_accept` becomes "write the live rows".
3. **The DOGFOODING registry as a query renderer.** `avra rules
   --markdown` plus `tools/dogfooding_rules.sh` become one `@query`
   over the `rules` collect that renders text, and the gate compares
   the committed block with the query's answer. Once N2 lands, the
   script is deleted.

### 3.4 PERF (lessons measured: memo, allocation, census)

All numbers: `/usr/bin/time -l build/avra check packages/cli`,
instructions retired, cold `.avra-cache`, 3 runs unless noted.

**Measured — constrain the shape**

1. **A second whole-program Workspace per command is the biggest cost
   on record.** 9cc4fd5 made `check.av`'s `said()` call
   `root_program(path)` on every plain `check` (a fresh Workspace
   from disk, sharing no memo). 352.9B → 500.7B (+42%), peak 807 MB →
   1.33 GB. Whole range: 252.6B at 4e98526 → 607.7B at b0f18a2
   (2.4×, peak 780 MB → 1.99 GB). **Rule:** a command derives ONE
   Workspace; any later reader takes that Workspace's `Db`, never a
   new one. (Fix in progress: lane/checkfix, avra-8sb5.34.32.)
2. **Name-keyed linear interning is quadratic and dominates.**
   `Workspace.spec_id` (workspace_analysis.av:134) interns every
   lowering request by NAME with a scan of `asks` — and `asks.get()`
   COPIES the whole list first. A macOS `sample` of b0f18a2 checking
   the cli: 42% of samples in `spec_id`, almost all `avra_streq`.
   `settle_id` and `lifted` share the shape. Unchanged since before
   4e98526, so it taxes the baseline too. **Rule:** every table the Db
   holds is reached by a dense id or an INDEX (name → id map, built
   once, written in place) — never a scan, never `get()` of a whole
   collection on a hot path (CLAUDE.md "A READ-MODIFY-WRITE THROUGH
   `get` IS A COPY").
3. **String equality has a pointer-first fast path now** (2088ba3):
   equal boxes answer before memcmp — −6.6% on a five-key name-scan
   micro-bench. It softens scan costs; it does not fix (2).
4. **Allocation is cheap; a copy is not.** CLAUDE.md records dedup
   and branch-avoidance measuring slower than a fresh box. The costs
   that show up are whole-collection copies (2) and whole-program
   repeats (1), not boxes.
5. **Every cached value's KEY must cover every input it depends on.**
   `.avra-cache` reused an entry made by one compiler generation in
   another: R15a looked non-deterministic (three functions flipped
   size across builds) until caches were cleared per build — then 4
   generations byte-identical (avra-8sb5.34.2, .34.26). A durable
   `DbRow` whose key misses the compiler's own identity or an input
   file repeats this. **Rule:** a durable row's key includes the
   producing compiler's digest and every read (§2.5's witness).
6. **Layout facts are write-once-after-read** (L1, 2dc8369): a fact
   bucket read and later changed is a compiler defect. Tracking cost:
   +0.6% on check-cli (208.2B → 209.4B, 2 rounds). Drift bookkeeping
   that EXPECTS a fact to move (the cache hold) reads through
   `peek_flat` untracked (4e98526). A Db that moves type facts into
   rows must keep "a read freezes the row" or say why not.
7. **Checking cost we pay on purpose:** the ownership checker (L2,
   `AVRA_SOUND_CHECK=1`) is +23.2% on check-cli (234.3B → 288.8B), so
   it is on for tests and landings only.

**§2.3 — fold the 22 `*_memo` fields into one family table?**
Hypothesis, not measured: roughly neutral IF the fold keeps today's
dense addressing. `Memo` is already `{ db: Kernel, family: int,
values: Table<T> }` (query/memo.av:17, abdd52c), keyed `(family:int,
arg:int)` with a dense `Table` per family. One table indexed by a
dense `(family, arg)` → slot costs the same as 22. It gets expensive
only if the fold reaches for string keys (`"family:key"` built per
ask) or a scanned list — see (2). The win is structural (one shape, no
per-family field), not speed.

**Hypotheses worth measuring next**
- `Memo.ask` builds `"Q\task\t${family}\t${arg}\t…"` for `qtrace` on
  EVERY ask, tracing on or off (memo.av:36, abdd52c): a string build
  plus two int formats per query. Guard the interpolation behind the
  flag and measure; likely a few % on check.
- The +40% from 4e98526 → 0b9b772 (252.6B → 352.9B) is not yet
  attributed; bisect in progress (avra-8sb5.34.32).

**Lead review (checked 23a704f):** `memo.av:34` confirmed — the
`qtrace` string is interpolated before `qtrace` is called, flag or no
flag. Rules (1), (2), (5) adopted into §4.

#### §6 round 1 — PERF

**Measured today** (23a704f, `/usr/bin/time -l build/avra check
packages/cli`, one run each, in order):

| Run | Instructions | Wall | Peak |
|---|---|---|---|
| cold (caches cleared) | 591.0B | 65.1 s | 516 MB |
| warm | 252.1B | 25.6 s | 454 MB |
| warm again | 252.3B | 30.3 s | 514 MB |

The store it left: `.avra-cache` holds **2,699 files, median 1 byte,
p90 324 B, max 949 KB — 5.9 MB of content taking 11 MB on disk.**

1. **A warm check today costs 43% of a cold one.** Hypothesis (to be
   confirmed when lane/checkfix lands): the warm 252B is almost exactly
   one full analysis — the second, uncached workspace 9cc4fd5 added.
   If so, today's cache already skips the first pass almost whole, and
   the real test of §6.5 is warm-check cost AFTER checkfix. That number
   is the receipt §6's "magic" should be judged by; I'll post it.

2. **Where §6.5 gets slow, ranked by expected cost:**
   - **Per-row files (measured shape, cost hypothesised).** Rows are
     tiny (median 1 byte) and a file per row costs a filesystem entry
     and at least 3 syscalls to load, plus 4 KB of disk each. At today's
     2.7k files that's a few ms; §6 makes EVERY query durable, so the
     count grows by orders of magnitude, and metadata cost grows with it.
     Spotlight/indexing on `.avra-cache` has already caused races here.
   - **Stable-name building at settle.** Every durable row maps every
     dep to a string name. Built per settle, that's rows × deps string
     builds. That is the `spec_id` lesson again (rule 2), and it needs
     the same fix: intern stable names ONCE per process into a dense id
     table, store edges as ids, and write one name table per packed
     file.
   - **Hashing every field.** It's cheap if it happens once per computed
     row, at settle, and composes children's hashes (a Merkle fold)
     instead of re-walking the whole value. It's expensive if a row
     holding a whole program re-hashes itself on each change.
     Hypothesis: fine if structural and incremental.
   - **Decode.** Allocation is cheap here (measured, CLAUDE.md). Decode
     cost is the per-row file opens, not the parsing. It's lazy per §6.6,
     which is right.

3. **Durable by default — keep it, but make "worth persisting"
   automatic rather than a census chore.** A row pays to persist when
   computing it costs more than loading and validating it. The Kernel
   can MEASURE that per family (instructions or time at compute against
   bytes and edges at load). A family whose rows are cheaper to
   recompute stays transient without anyone writing
   `@query(transient)`. Keep the annotation as the override.
   Default-transient would put the magic behind a choice the user has
   to make.

4. **One packed file per package beats a file per row. Hypothesis,
   strongly suggested by the file shape above.** An append-only log of
   `(stable id, hash, edges, bytes)` records plus an index, one `mmap`,
   written atomically (write aside, rename) at the end of a command.
   Lazy decode becomes an offset lookup, the syscall and inode cost
   collapses to one file, and rows of 1 byte stop costing 4 KB each.
   `Store.keep`'s atomic row-with-edges contract survives unchanged,
   since the rename is the commit. Measure it at M3: per-row versus
   packed, on a warm check of the cli.

5. **§6.10 Q1: is recursive witness validation O(changed) on a cold
   process with a warm disk?** **No. It's O(rows asked + their edges),
   and O(changed) only in RECOMPUTATION.** Validating a row means
   asking every dep's current hash, and each input hash means reading
   and hashing that source file. The Kernel memoizes each ask, so every
   dep is validated once per process, not once per edge. Cost is
   therefore one hash per input file, plus one visit per edge of every
   row the command asks. Hypothesis on scale: hashing all source is
   megabytes at GB/s (milliseconds), so the edge walk dominates,
   linear in the graph reached. Two things keep it near O(changed) in
   practice:
   - **validate from the top:** a command asks only its roots, and a
     root whose witness holds is reused without descending into rows
     that nothing asked;
   - **early cutoff:** a changed input whose hash doesn't change its
     reader's answer stops the walk there.
   The risk is a root with a huge witness (a whole-program fixpoint
   reading every sig): that witness is O(program) to check every time.
   Give it a SUMMARY witness (one package-level digest of the sigs it
   reads, as ERRORS proposed in §3.1), not one edge per sig.

#### §6 round 2 — PERF

**Two things in §6.2–§6.5 break §6.6, and both are about the dense `id`.**

A. **A hash that folds a DENSE id is not stable, across processes or
   across reruns.**
   - §6.3 gives every relation "a value hash over EVERY field", and
     `id` is a field.
   - §6.5 folds "the ids and hashes of the rows" into each bucket's
     hash.
   - A dense id is minted per process, so a witness holding either hash
     fails on the next load every time. Durable-by-default would never
     hit.
   - It also fails inside one process. §6.2's rerun deletes a query's
     rows and reinserts them. Identical rows get NEW ids, so every
     bucket hash moves and every reader recomputes. Early cutoff (§6.6)
     is lost exactly where it matters.
   - **Rule:** a value hash and a bucket hash are computed over the
     row's STABLE encoding (§6.4: typed-id fields through the target's
     `@key`), and the minted `id` never enters a hash.
     This is the encoding law in CLAUDE.md ("two values, one identity")
     run backwards: one value, two identities.

B. **A rerun must UPSERT by `@key`, not delete-then-insert.** A rerun
   that produces a row with the same key keeps that row's id and
   rewrites its fields in place. Only keys that disappear are deleted,
   and only new keys are inserted. Then:
   - ids stay stable for in-process readers;
   - index maintenance touches only the rows that changed;
   - an unchanged rerun costs a hash comparison per row, not a delete,
     an insert and index work per row.
   Relations with no `@key` (owned rows, keyed through their owner's
   witness) match by position within the owner's output, which is
   deterministic for a deterministic query.

**Q1: what does bucket-as-cell cost on `Decl` indexed by `name`?**
Hypotheses. Sizes are not measured yet; count at M2.
- **Memory is fine.** One Kernel cell per DISTINCT name READ, created
  lazily on the first read, never eagerly per insert: a few tens of
  thousands of cells at roughly 100 B each is a few MB. An insert into
  a bucket that nobody has read only updates the index; the cell
  appears on the first read.
- **Hash maintenance should be O(1):** use a commutative multiset fold,
  the wrapping SUM of each row's mixed 64-bit stable hash. Insert adds,
  delete subtracts, and order doesn't matter. Refolding a whole bucket
  on every insert is O(bucket) and would cost quadratically on the
  common names (`new`, `get`, `of`).
- **The real cost is EDGES.** Every recorded bucket read becomes a
  persisted edge and a validation step. Typing a file reads a name
  bucket for every distinct identifier it resolves, so a file's
  witness holds hundreds of bucket edges. Validation stays linear, but
  witness size and load time scale with identifiers. Mitigations:
  - an in-process dedup per query: the cell stamps its last reader, so
    a repeat read in the same query is one compare, not a set lookup;
  - COARSENING: past K bucket reads of one index in one query, record
    the index's set hash instead. That is one edge, at the price of a
    wider invalidation. K is tuned by census.
- **Per-read recording cost.** Every accessor call pushes a dep. On
  typing's hot path (`db.decl(id)` millions of times per check) that
  needs the stamp above, or it adds a set membership test per read. It
  must be measured at M1 against today's direct table reads. §6.6's
  census-per-slice rule catches it.

**Q2: commit once per settle, or once per command?**
**Neither form of "rewrite and rename".** Rewriting the whole pack on
every settle is O(settles × pack size). Per command is right for a CLI,
but a long-running process (LSP, watch) would then never commit, or
would rewrite everything on every edit. Proposal:
- an append-only log: each settle appends its entry (hash, edges, rows,
  value) with a checksum. That is one sequential write, buffered.
- a commit marker per command, or per idle moment in a long-running
  process, fsynced.
- on load, the log is read up to the last valid marker, and a torn
  tail is ignored. A crash then loses only uncommitted work, never
  corrupts.
- compaction, meaning rewrite-and-rename (the atomic swap §6.6 wants),
  runs only when superseded entries pass about half the file.
This keeps §4.7's atomic row-with-edges commit, because a settle's
entry is one checksummed record.

**Q3: other breaks of §6.6.** Beyond A and B, none found. One check
for M2: the WRAP directive's wrapper is on the hot path of every query
call. It must cost a Kernel ask and nothing else, with no closure box
per call (R9's static fn boxes already make a captureless wrapper
free).

#### §6 round 3 — PERF

**One blocker: a commutative SUM of LINEAR hashes collides by
construction, so the bucket hash is unsound as specified.**
- §6.5 makes a bucket's hash the sum of its rows' stable hashes.
- The tree's fingerprint fold is linear: `fp` is `131t + x + 7`.
  CLAUDE.md's encoding law ("under a LINEAR fold a tag is an additive
  offset") records exactly this.
- A sum of linear row hashes is itself linear in the fields, so
  distinct bucket contents reach the same sum. For example, rows
  `(a, 1), (b, 2)` against `(a, 2), (b, 1)`: with `h = 131·x + y`,
  both sums are `131a + 131b + 3`.
- A witness would then certify a changed bucket as unchanged, which is
  a stale answer reused. That is precisely what §6 exists to prevent.
- **Fix:** each row's stable hash passes through a NONLINEAR 64-bit
  finalizer (splitmix64's mix, or similar) before it enters the sum.
  The sum then behaves as a random multiset hash, keeping O(1) insert
  and delete and order independence, with collisions only by chance.
- **Test to write before the codec lands (the encoding law's test):**
  the swapped-field pair above must hash apart, and so must a bucket
  against the same bucket with one row duplicated. That second case is
  unreachable while `@key` rows are unique, but pin it anyway.

**Not blockers, but they belong in M2's receipt:**
- **Hashing on insert needs each target's key hash, cached.** Bucket
  hashes update on insert, so a row's stable hash must exist at insert
  time. Its typed-id fields hash through their target's `@key`. Cache
  each keyed row's key hash on the row when it's inserted, so hashing a
  `DeclId` field is one read, not a key-record build per field per
  insert.
- **Per-read recording on the hottest accessors.** `db.decl(id)` from
  typing runs millions of times per check. Deduping edges per query
  needs the last-reader stamp (one compare), not a set lookup.
  §6.6's census catches it, and M1 should post it separately.
- **mmap needs a runtime row.** The pack's mmap-and-decode-lazily is a
  new crossing into C. It's buildable, but it's a registry row the
  compiler's own source declares, so it follows the two-landing ladder
  in CLAUDE.md ("A REGISTRY ROW THE COMPILER'S OWN SOURCE DECLARES
  CANNOT BE GATED IN THE COMMIT THAT ADDS IT"). Plan M3 as two landings.

#### §7 round 4 — PERF

**One blocker: N5 as written is naive iteration, which is quadratic
on a deep SCC.**
- "Re-runs every member of the SCC until no answer grows" costs rounds
  × members × work. The number of rounds grows with the longest
  propagation path, since an error set crosses one call edge per round.
  So a chain of n fns in one SCC costs O(n²) re-runs.
- **Fix: a worklist, semi-naive style.** Start from every member. When
  a member's answer GROWS, enqueue only the members that read it; the
  Kernel's recorded edges already name them. A member whose inputs
  didn't grow is never re-run. Total work becomes proportional to the
  growth, not rounds × SCC.
- **Termination has a precondition to enforce.** The join must be
  monotone. A member whose re-run answer SHRINKS (non-monotone body)
  would oscillate forever, so the Kernel refuses it as a defect naming
  the member, never loops. The lattice has finite height (sets of
  finitely many types), so growth ends.
- **Witness:** one set-hash edge per SCC (§6.6), unchanged.

**N1: no blocker. Two rules for the planner.**
- Use the index only when the compared side is INVARIANT over the scan.
  `s.callee == f` is invariant; `s.callee == s.fn` is not, and must
  scan.
- A conjunction uses one matching index and filters the rest, in
  bucket order.
- The "full scan" warning should fire only past a size a census names.
  A scan over a small relation is cheaper than an index, and a warning
  that fires where no one needs to act trains readers to skip the
  column (CLAUDE.md's F2040 lesson: measure a lint's true-positive rate
  before it ships).

**N2: no blocker.**
- A row with k list elements files k bucket entries.
- An update diffs the old list against the new one: removed elements
  subtract from their buckets and added ones add, O(k) with the
  commutative sum.
- The planner must recognise `contains` over a multi-valued index as
  N1's lookup form, or `collect`'s lowering becomes a scan.

#### Receipt for §4 rule 1 (one Db per command) — landed 514c5f9

`Checked` carries the `Program` that `Workspace.checked()` derived, and
`check.av`'s licence scan and baseline gate share it, so they no longer
build a second Workspace (lane/checkfix 47d9541).

Cold `/usr/bin/time -l build/avra check packages/cli`, 3 runs, same
tree before and after:

| | Instructions | Peak |
|---|---|---|
| Before (abdd52c) | 591.2B / 590.7B / 589.6B | ~1.95 GB |
| After (47d9541) | 338.9B / 338.6B / 338.7B | ~816 MB |
| Change | **−42.6%** | **−58%** |

**The warm number** (lane/checkfix 1c0cad6, not yet on main): the
licence verdict is cached as a `DbRow.Licenses` row beside `Warn`, so a
cache hit builds no `Program` at all. Warm `check packages/cli` (run
twice, second measured):

| | Instructions | Peak |
|---|---|---|
| main (no fixes) | 251.8B | 1.18 GB |
| + one workspace (47d9541) | 125.7B | 767 MB |
| + cached licence verdict (1c0cad6) | **0.362B** | **7 MB** |

That is −99.86%: a warm check now costs about the validation read
alone, which is §6.6's target, already met on this path.

**All four fixes landed on main at 05e79df.** Cold `check
packages/cli`, 3 runs each, caches cleared:

| Commit | Change | Instructions | Step |
|---|---|---|---|
| main before | — | 590.7B | |
| 47d9541 | one workspace per command | 338.7B | −42.6% |
| 1c0cad6 | licence verdict cached (warm path) | ~339B cold | warm 251.8B → 0.36B |
| 12dd15a | `spec_id`/`settle_id`/`lifted` indexed by name | 288.5B | −15.3% |
| 85bbd32 | `qtrace` string built only when tracing | 286.7B | −0.7% |

**Total: cold −51.5% (590.7B → 286.7B); warm about 700× (251.8B →
0.36B, peak 7 MB).** `check packages/std-avrac`: −6.0% from the index
alone.

The earlier +40% (4e98526 → 0b9b772) was ordinary code growth
(20d02f2 at +12%, the `@std/grammar` merge 92edf3b at +20%) made
quadratic by the name scan. The index makes future growth linear.

The `Licenses` witness is sound, and this was proven by experiment: a
renamed rule is refused cold and warm, and the revert is clean. The
compiler digest names the whole store directory (`build_cache_root`),
so a binary with a different rule registry never reads another's rows.

**M1 receipt (checked at 57d8a39, main merged in): `Relation<T>`,
`Db.families`, the last-reader stamp.** `query.Memo<T>` (the generic
`{ kernel, family, values: Table<T> }` every dense family and, later,
a durable relation both are) is renamed `Relation<T>`, with `Memo<T>`
kept as `alias Memo<T> = Relation<T>` so nothing that already spells it
moves. Workspace's 16 individual `*_memo: Memo<DbRow>` fields collapse
into `Db.families: Cell<List<Relation<DbRow>>>`, one slot per
registered family (all 22, dense/durable alike — `Db.family` mints a
family's `Relation` in the same call that registers its Kernel
verifier, so the two lists never drift), addressed by ordinal through
one door, `Workspace.relation(fam)`. `Kernel.record_dep` gained a
LAST-READER STAMP (`QueryCell.last_reader`, `Kernel.reading`/
`next_reader`): a repeat read of the same key inside one open query
now costs one int compare instead of an unconditional push, pinned by
three new `kernel_test.av` cases (dedup to one dep; distinct keys never
merge; a later query's read is its own dep, never skipped as an
earlier reader's).

Cold `check packages/cli`, 3 runs, caches cleared, this worktree
against a from-scratch clone of main's tip (same commit, same
machine, back to back):

| | Instructions (cold, avg of 3) | Warm |
|---|---|---|
| main (9c081e7) | 327.9B | 0.391B |
| + M1 (57d8a39) | 325.8B | 0.366B |

Neutral-to-slightly-better on both, confirming §2.3's hypothesis: the
22-field fold costs nothing under dense addressing, and collapsing 16
struct fields into one list also dropped peak footprint (measured
separately, pre-merge, at 4a14579: ~808 MB → ~715 MB cold, ~584 MB →
~514 MB warm — about 12% either way). `AVRA_ALIAS_LOG` shows zero
clones on both binaries; no whole-table clone of `families`.

**The micro-bench, delivered (follow-up, checked at 90685f9).** The
first attempt used `std-avrac`'s own spec suite and was abandoned —
its fixed ~600–1200B-instruction floor (typing the whole package
before a single spec case runs) swallowed the loop's true cost at
every N tried. The fix was a DEDICATED HARNESS outside the tree: a
scratch package (`/tmp/kbench`, not under `packages/`) whose `main.av`
reaches the kernel the same way any other package would —
`use @std.avrac.query.{Kernel, new_kernel, Key}` resolves and builds
cleanly with no manifest dependency row, confirming `@std/avrac` is
ordinary toolchain-resolved `@std/*` (the pin law, CLAUDE.md). Three
modes, chosen by an env var so one binary serves every measurement: a
one open query rereading ONE key N times (the stamp's own case,
`db.record_dep(key)` in a loop); b one open query reading N DISTINCT
pre-existing keys (each a genuine new stamp + push); c N plain
`Table.at(i)` reads with no `Kernel` involved at all. Each mode also
takes a phase (`setup` builds the inputs and stops, `full` also runs
the N reads), because b and c's setup is itself O(N) — the read
loop's own marginal cost is `full − setup`, divided by N.
`/usr/bin/time -l`, 3 interleaved rounds averaged, N ∈ {1e5, 1e6, 1e7}:

| N | a: stamped repeat | b: stamped distinct (real push) | c: unrecorded table read | a − c | b − c |
|---|---|---|---|---|---|
| 100,000 | 301.0 | 1833.0 | 130.1 | 170.9 | 1702.9 |
| 1,000,000 | 329.5 | 1857.8 | 116.9 | 212.5 | 1740.9 |
| 10,000,000 | 330.6 | 2054.4 | 137.4 | 193.1 | 1917.0 |

(instructions per read; setup/full absolute counts in the commit's
own report, reproducible from `/tmp/kbench`.)

Stable across three orders of magnitude of N, which is what makes it
trustworthy: a stamped HIT (repeat read, the common case a per-node
grain would create) costs **~300–330 instructions**, essentially a
`Cell.get()` plus a chunked lookup plus one int compare, as designed.
A stamped MISS (a genuinely new dependency, `b`) costs **~1,830–2,050**
— roughly 6× a hit, dominated by the list push and the write-back. A
plain unrecorded read (`c`) costs ~117–137, so the STAMP's own tax
over a read that was never going to be recorded at all is small
(a − c, ~170–210) next to what recording a genuinely NEW dependency
costs regardless of the stamp (b − c, ~1,700–1,920). For §6.11: recording
every arena-node read individually would pay something in `b`'s range
per node per consuming query — the OWNER-GRAIN rule (one edge per
consuming query per syntax range, not per node) is what this number
argues for, not the stamp's own overhead, which is cheap by
comparison. The correctness claim (dedup to one dep) stays proven
separately by the four `kernel_test.av` cases (`deps.length == 1`
after 50 repeat reads, and after a nested query reads the same key —
see the nesting fix, next).

**The nesting fix (ERRORS' review finding, checked at 77b2d7a, redone
allocation-free at c1956d2).** `last_reader` is ONE field per
cell, so a NESTED query reading the same cell overwrote the OUTER
query's stamp with its own reader id: `begin(A)`, read `X` (stamp=A),
`begin(B)`, read `X` (stamp=B), `settle(B)`, A re-reads `X` — the
stamp now says B, not A, so `X` looked unread to A and got pushed a
second time. Correct (a harmless duplicate, not a wrong answer), but
it defeated the stamp exactly where
`Namespace`/`Visible`/`Resolved`/`Typed`/`Folded`/`Analysis` re-enter
— which is most of the traffic.

**First attempt, measured wrong: a per-open-query `Map<string, bool>`
(`KernelState.seen`), pushed/popped alongside `pending` in
`begin`/`settle`.** `/tmp/kbench`'s (a)/(b)/(c)/(d) all looked fine —
because that harness measures cost PER READ, and the real cost this
design added was PER BEGIN (a `Map` minted eagerly on every single
query invocation, whether or not it ever nested), which a benchmark
with one or two `begin`s per run amortizes into "setup" and never
sees. Cold `check packages/cli`, 3 runs, caches cleared, main 8fd617c
vs this design: **328.6B → 377.6B, +14.9%.** The lesson: a micro-bench
built around the SUSPECTED cost shape can be blind to a cost shape it
didn't think to isolate — the real regression needed the aggregate
census to show up at all, which is why that census is the landing
gate, not the micro-bench.

**Redone allocation-free: SAVE/RESTORE, like a stack frame.** The
stamp stays the O(1) fast path for the common no-nesting case. On a
MISMATCH, `record_dep` asks one cheap question — is the stamp being
overwritten still on the OPEN stack (`reading.contains`, a scan of a
handful of ints, never the program's dep count)? If not, it's a
genuinely new dependency (or a stamp some now-closed query left
behind) and nothing more happens — no allocation, matching every
prior read's cost exactly. If so, the overwritten value is an
ancestor's stamp that must come back: it is pushed onto THAT frame's
own restore list (`KernelState.restore`, one slot per open query,
parallel to `pending`) — lazily minted on the first such overwrite, so
a frame that never gets nested into allocates nothing at all, ever.
`settle` pops its frame's restore list (if any) and writes each saved
value back before finalizing its own row, so the ancestor that resumes
finds its own stamp waiting and its next read is the plain fast path.

Cold `check packages/cli`, 3 runs, caches cleared, same machine,
back to back: **main 8fd617c 328.4B avg — lane/m1 329.6B avg, +0.36%,
within noise** (the same runs individually: main 328.40B/328.47B/
328.47B; lane/m1 329.84B/329.51B/329.53B).

Re-measured `/tmp/kbench` (a) and (d) with the new design:

| N | a: stamped repeat (fast path, unchanged) | d: repeat under constant nesting (save/restore) |
|---|---|---|
| 100,000 | 284.4 | 11,787.8 |
| 1,000,000 | 329.7 | 11,781.1 |
| 10,000,000 | 330.2 | 11,779.2 |

`a` is unchanged from every earlier measurement (the fast path never
touches `restore`). `d` dropped from ~13,500 (the `Map` design's
fallback) to ~11,780 — about 13% cheaper even in the pattern's own
worst case, on top of the aggregate regression vanishing entirely,
because save/restore's fallback is a list push and (at most once per
frame) one small allocation, never a hash or a string key. Nesting
tests: outer/nested/outer (unchanged assertion), and a new
outer/nested/nested-deeper/outer case pinning that two levels of
overwrite unwind in the right order (each level's own `deps.length ==
1`). No aborted-frame/cycle exit path was found in the kernel to test
— every `begin` in this codebase is paired with exactly one `settle`
call site; `ask`'s `Cycle` verdict never opens a new frame at all, it
reuses the caller's own open one.

**RETRACTED: "the linker embeds a random `LC_UUID` per link."** An
earlier draft of this entry reported a 13,362-byte divergence (incl.
`LC_UUID`) between two `make avra` builds of identical source, and
read it as toolchain noise rather than fixing it. Re-checked directly
(three successive `make avra` generations, cache cleared before each,
`otool -l | grep -A3 LC_UUID` on each): all three carry the SAME uuid
(`28EBCC73-2CC4-3E98-AC5E-F3789D5FF548`), and plain `cmp` says the
binaries are byte-identical — no exclusion needed, this toolchain's
link is deterministic. The original divergence was the same
stale-`.avra-cache` mistake as the "index 221" trap below, hit twice
in one session: `clear_cache.sh` was run before the FIRST build in a
chain but not before every one, and CLAUDE.md says why that matters
("rm -rf .avra-cache before every run whose ANSWER is being compared,
not only before the first"). No ticket needed; the Makefile's plain
`cmp` fixed-point check stands as written.

### 3.5 ORM (ideas from `@std/db` — input only, not scope)

Checked against `packages/std-db/src/db.av` at 23a704f. Input only.

**1. Which `@model` shapes fit a compiler fact store**

| `@model` shape | Fits `Db`? | Why |
|---|---|---|
| Schema IS the type (`@model type User = {…}`, one derive) | **Yes** | `DbRow`'s variants already are the schema. The step left is deriving each family's key, hash and witness from the variant's own fields instead of hand-writing them per family (the "a hash that forgets a payload" law, closed by construction). |
| Typed queries (`User.find(db, id)`, generated per model) | **Yes** | One generated accessor per family (`db.sig(d)`, `db.typed(f)`) instead of `ask(key(Family.X, …))` plus an unwrap. That's the "store as a database" direction, spelled as methods the derive writes. |
| Indexes (`UNIQUE` from `@unique`) | **Partly** | The compiler's hand-built indexes (`Decls.collect_index`, `by_word`/`by_mark`) are secondary indexes on a relation. Worth declaring once beside the row they index, so one declaration keeps them fed. A uniqueness *constraint* has no compiler analogue; duplicate names are already diagnostics (F3017). |
| Migrations as a projection of the type | **No**, but its law does | `Db` has no on-disk schema to evolve. Its durable rows do evolve across compiler generations: "growth crosses, moving refuses" (`features/crossing.av`) is already the compiler's migration law. |
| Claim registry (`__avra_models__`, keyed by the declaring file) | **Yes, as a pattern** | A durable row needs a *stable name*. §2.5 limit 3 is exactly this: dense `Key { family, arg }` means nothing in the next process. `@std/db` answers "which physical table is `User`" by storing `declared_at` (the declaring file, `db.av:333`), never a dense id. |

**2. Could the compiler DB *be* an `@std/db` instance? No, as a runtime.**

- **Layering:** `compiler/` sits below every `@std/*` package it compiles. `@std/db` depends on `@std/sqlite` plus vendored C, and on `@model`, which is a derive the compiler itself runs. The compiler would need itself to build its own fact store. That's a cycle, not a dependency.
- **Cost:** `@std/db`'s floor is a SQLite statement per row (`find` ≈ 650 ns). The compiler's in-process rows are a register read. Routing `sig(d)` through SQL would be a P4 regression by orders of magnitude.
- **The shape where both sides win (P6):** share the vocabulary, not the runtime. One schema-derive idea, two backends:
  - `@std/db` derives SQL tables from a user's record type;
  - the compiler derives `DbRow` families (key, hash, witness, accessor) from a row record in `core`.

  Same law ("the type is the schema; every projection is generated"), no shared code crossing the layer. If durable rows ever outgrow flat files, `.avra-cache` could be *backed by* SQLite through a narrow C row, with the schema still derived compiler-side.

**3. Lessons for durable rows, applied to §2.5**

- **A version counter on every write is what makes staleness checkable.** Every `@model` table carries `"__avra_version__" … DEFAULT 1`, bumped inside `UPDATE`'s own `SET` (`db.av:298`, `:304`), so the bump and the write are one atomic statement.
  - For §2.5: a durable row's witness should record each dependency as **(stable name, value hash)**, never a dense id and never "was it read".
  - The hash is the version; a mismatch invalidates.
  - This is the same fix as §2.5's limit 3.
- **Keep the bump and the write in one transaction.** A rolled-back write leaves the version unbumped: red-teamed against a unique-constraint failure and a real `SQLITE_BUSY`. For `Db`: settle the row and its witness in one step. A crash or trap between them must leave the *old* row plus the *old* witness, never a new row carrying an old witness.
- **A read nobody records is a read nobody invalidates.** `@std/db`'s unique-field attribution once named the wrong field, because it matched names against SQL *text* rather than a typed value. §2.5 limit 2 (table reads that bypass `ask`) has the same shape: every bypass (`sig_so_far`, `decls.decl`, `sigs.get()`) is a dependency the witness cannot see.
  - Proposed rule: a durable row may only be computed from reads that go through `ask`. A bypass is allowed only inside a fixpoint's own bracket, and marked at the site.
- **Key identity by the declaring file, not by id.** Two unrelated `@model` types sharing a name wrote into one table silently until the claim registry keyed on `declared_at`. For held files (§2.5 limit 1), recording a dep on the held module's `Sig` row, named by path, is the same move.

**4. From this session: a fact store's write path needs the reader's hold released at the last read**

- The memory pass released owned reads at **scope exit**. Its effect on write paths:
  - Any `self.table.set(…)` that followed a read of `self.table` inside a call saw the table shared (count 2).
  - So it copied the **whole table** on every write.
- Measured in the compile-time evaluator's `cells` table: 220 million elements copied for a 4-rule grammar build. Quadratic: 16 rules took 103 s; with the fix, 2 s.
- Fixed on lane `lane/sql-fast` (memory pass: release at the value's death).
- Lesson for `Db`: an in-place write path (the `Table` "one shared slot" law in CLAUDE.md) only stays in place if **no reader's hold outlives its last read**.
  - A fact-store API that hands out a row and then writes the table in the same scope is quadratic.
  - It stays quadratic until the compiler proves the hold died.
- Measure write paths with `AVRA_ALIAS_LOG=1`: an element count that grows with table size is this bug.

**Lead review:** §2's layering argument holds — `@std/db` rides a
derive the compiler runs, so the compiler cannot depend on it. Adopted:
share the vocabulary, not the runtime; (name, hash) deps; row + witness
settled together; `ask`-only reads with licensed bypasses. Deriving
`DbRow` families from a row record is the §5 direction, not decided yet.

#### §6 round 1 — ORM

**1. Does one derive vocabulary serve `@relation`/`@query` and `@model`? Yes for the idea, not yet for the spelling.** Five mismatches to settle before M2 ships:

| Seam | `@model` (db.av) | §6.3 | Settle by |
|---|---|---|---|
| Key | first field `id: int = 0`, minted by the store | first field is the key, a typed id the caller supplies (`caller: DeclId`) | one rule: "the first field is the key". Who mints it is a per-backend fact, not a vocabulary one. |
| Key uniqueness | `id` is unique by construction | `Call`'s key `caller` is NOT unique (one caller, many calls) | say it: is the first field a key (unique) or a partition (grouping)? `Call` wants `index: [caller, callee]` with no key. |
| Queries | none; accessors are generated (`find`, `insert`, …) | `@query fn` is user-written and memoized | an addition, not a clash. `@model` gains nothing from it until Phase 2 wants cached joins. |
| Answer shape | `Declared { made, problems }` (one annotation carries code and refusals) | unspecified | adopt `Declared` for `@relation`. It is the shape the owner chose over stacked annotations. |
| Index spelling | a field mark (`@unique`) | an annotation argument (`index: [callee]`) | pick ONE. A field mark (`@index callee: DeclId`) keeps the fact beside the field and needs no names-as-strings; `index: [callee]` repeats a field name the typer cannot check today (a Declares argument is a literal, CLAUDE.md "the subset today"). |

**2. What `@model` users tripped on, which this will repeat** (from ORM §3a)
- **Key convention.** Refusing a missing `id` needed its own voice (`no_id_field`). `@relation` needs the same voice for "no first field" and for a first field that is not an id type.
- **The zero-field row.** `INSERT` and `UPDATE` broke on a model with only `id`. A relation with only its key (a membership set, e.g. `Exported = { d: DeclId }`) is the same case, so test it on day one.
- **Keywords as names.** Every generated identifier was quoted after `order`/`group` broke SQL. The compiler's analogue is a relation or field named after an Avra keyword or a generated accessor (`insert`, `r_by_…`). Reserve the generated names, or refuse the collision at the declaration.
- **Name collisions.** Two same-named types silently shared one table until a claim registry keyed by declaring file. §6.9's `package.Type` slot key is the fix, but only if two packages can't claim one name, and the second claimant is refused rather than reusing the first slot.
- **Unsupported field kinds.** `List`, nullable and nested fields were refused, loudly. Say which field kinds a relation's codec supports, and refuse the rest at the declaration, never at load.
- **Refusals ride the same annotation.** The stacked `@model_shape` was rejected as ceremony, so every `@relation`/`@query` refusal speaks through `Declared.problems` from the one annotation.
- **Half-built output.** A bad shape once generated an `impl` that mistyped 5–6 ways. `shape_ok` now generates NOTHING over a refused shape. The same law applies to `@relation`.

**3. §6.4's `DeclId` name is NOT sound across edits.** `record.av`'s `ordinal` is a file-wide position: `record_complete` demands 0..n-1 per file.
- **Walkthrough:** insert `fn a()` above `fn b()` in `m.av`. Every later declaration's ordinal shifts by one, and so does its stable name. So:
  - every witness naming them misses, and a one-line edit invalidates the whole file;
  - worse, a stale row keyed `(m, _, c, 5)` may now MATCH a different declaration that took ordinal 5.
- **Recommendation:** name by what the source says, never where it stands.
  - `(module, owner, name)` is unique for everything a module may declare once (F3003/F3017 refuse duplicates).
  - Where one name legally repeats (overload-free, so mainly impl methods across impls, `case`s, nameless items), disambiguate by an **ordinal among same-(owner, name) siblings only**. An insert elsewhere then moves nothing.
  - Keep the file-wide ordinal as the record's *layout* (it is how `record_complete` detects a truncated record), but never as *identity*.
- **Signature-keyed identity: no.** A signature edit would then look like delete + create, and its dependents would get a "missing" error instead of a revalidation. The name is the identity; the signature is what the hash covers.

**4. §6.9's plugin isolation leaks in six places**
- **Reads pass for queries.** A plugin `@query` may call a core accessor that itself runs a core `@query`. Plugin demand can then force core queries to run early or in an order the passes never did. The generation law bit exactly this (declaration-order answers). Either core queries are order-independent by proof, or plugins read only *settled* relations.
- **Hooks capture the Db.** A plugin fn stored in a row, or a closure over `db`, is the "closure that captures its owner" cycle (CLAUDE.md). One Workspace per command makes it a leak, not a crash. Refuse fn-typed fields in `@relation`.
- **Insert-only is not isolation.** A plugin's OWN relation can be read by core passes if any core code reads it by name, and nothing forbids that. State the direction: core never reads a plugin relation.
- **A shared index is a shared write.** If a plugin declares `index:` on a core field and the index lives on the core relation, maintaining it is a write into core. Plugin indexes must live on plugin relations.
- **Slot exhaustion and id reuse.** `Db.families` grows per admission. A slot must never be reused for a different stable name within one process, and must be re-derived (never persisted) across processes. Persist the stable name and look the slot up.
- **The plugin digest in witnesses covers the plugin's code, not its data inputs.** A plugin reading a file (`embed`) or the environment needs those as named deps too, or its rows go stale silently. This is §6.5's input rule, applied to plugins.

#### §6 round 2 — ORM

**1. `@unique` and `@key` are two concepts, and both belong in the shared vocabulary.**
- **`@key`** is identity: at most one per relation (composite allowed), stable across processes, what a reference is written as.
- **`@unique`** is a constraint: many per relation, each independent (`@unique email`, `@unique handle`), and it names nothing. A row stays the same row when its email changes; it does not stay the same row when its key changes.
- **Folding them breaks both.**
  - Make `@unique` a key, and `User` gets two stable names that can disagree.
  - Make `@key` merely unique, and a key edit reads as "same row, new value", so its dependents revalidate against the wrong row.
- **The shared rule:** `@key` implies `@unique` over the key tuple, never the reverse. `@model` gains `@key` only when a model wants a stable name other than its minted `id` (a natural key; a Phase 3 migration's rename target). The compiler gains `@unique` only where it wants a refusal rather than an identity (F3017's "one name per module" is exactly a `@unique (module, name)` constraint).
- One vocabulary with three marks: `@key` (identity), `@unique` (constraint), `@index` (partition).

**2. "A query owns its rows" is sound, and it is `@std/db`'s transaction semantics with the query as the transaction.** Three rules keep it sound:
- **Deletes.** Only the owner deletes its rows, and only by rerunning. The rerun's UPSERT drops keys it no longer produces. There is no user-level `delete` on a derived relation.
  - **Cascade:** a row that references a deleted row is not deleted; its reader's witness fails, because the referenced key's bucket or hash changed, and the referencing query reruns.
  - That is `@std/db`'s `.restrict` default, stated for derived data: a reference is a dependency, never an ownership edge. Silent cascade is the anti-pattern ORM §4 refuses.
- **Mid-rerun reads.** A rerun is ONE commit: rows, value, hash and edges together (§4.7). A reader must see the whole old set or the whole new set, never a partial upsert.
  - Receipt: `@std/db`'s rollback leaves the version column unbumped against both a constraint failure and `SQLITE_BUSY`; the same atomicity is needed here, in-process.
  - In a single-threaded Kernel this holds only if no accessor can be reached from inside the rerunning query's own bracket for its OWN relation. Otherwise the query reads its half-upserted self.
  - **Rule:** a query never reads the relation it owns. A fixpoint that must (the `failures` loop) reads its previous generation through an explicit `prior()` door, licensed at the site.
- **Rows another query references.** The id stays stable across an unchanged rerun (UPSERT by key), so references survive. A changed row changes its hash, and referencing readers revalidate.
  - The hole: a KEYLESS relation has no upsert key, so every rerun deletes and reinserts and moves every `id`. References into it are then references to positions.
  - **Rule:** a relation that anything references by id must declare `@key`, and the declaration refuses otherwise.

**3. §6.4's owner-relative encoding: four probes, two holes.**
- **The owner's witness changes, the row doesn't.** Sound but wasteful: the offset is read only after the witness validates, so a stale offset is never dereferenced. The cost is that any edit to the owner re-derives every owner-relative row, even when the rows come out identical. Early cutoff on the rerun's row hash recovers it downstream.
- **The owner is deleted.** Sound if the owner's disappearance fails the witness before decode. A deleted decl has no current hash, so step 2 of §6.5 must treat "name not found" as a mismatch, never as "no dep to check".
  - **Rule:** a missing edge target is a failed witness, spelled explicitly. Absence is the spare value this encoding spends (CLAUDE.md's empty-value law).
- **Two owners produce the same row.** **Hole.** Under "a query owns its rows" one row has one owner, but two queries can compute equal content (the same site seen from two fns via a lambda's enclosing fn). If the relation has a `@key`, the second insert collides with a row it does not own.
  - **Rule:** the key includes the owner, or a second owner's insert of an existing key refuses loudly, naming both (the claim registry, again). It never silently takes over the row.
- **An encoding whose boundary moves.** **Hole.** `(owning decl's key, offset)` spliced flat with a variable-width key (`module`/`owner`/`name` are strings, `sibling` an int) is the flat-concatenation hazard. `("a.b", "c")` and `("a", "b.c")` collide if joined by a separator.
  - **Rule:** encode the key record through its own derived codec, each component length-prefixed or folded to one value (the ARITY law), never joined.
  - Write the colliding pair as a test before the codec lands. An `ExprId` offset is only meaningful against the owner's EXACT text, so pin it to the owner's content hash, not merely its key.

#### §6 round 3 — ORM

No blockers. Rounds 1–2 landed consistently across §6.2–§6.9 and the one-screen summary. Two non-blocking notes for M2/M3:
- **Check `@unique` at the rerun's commit, over the final set, never per insert.** An UPSERT that moves a unique value from row A to row B (a rename swap) passes as one commit and fails if checked insert by insert. A conflict between rows of two DIFFERENT owners is refused naming both owners, the same voice as "two owners, one key".
- **Keyless owned relations (`ErrorSite`, `Call`) rely on one owner per anchor.** "Two owners, one key" cannot fire without a key, so their soundness rests on each owner-relative `at` having exactly one owning query. §6.7 has that today, because a lambda's sites are attributed to its enclosing fn. Pin it with the same day-one test as the `within` invariant: two queries inserting a row at one `at` refuse.

#### Db accessors — proposal (lead's ask (a), after probes)

**The shape.** Every accessor is a static fn on the RELATION, generated
by `@relation` in the relation's own package: `Decl.by_name(db, v)`,
`Decl.by_key(db, k)`, `Decl.insert(db, r)`, `Decl.get(db, id)`,
`Decl.all(db)`. Core and plugin relations spell it one way.
- **Plugin-safe by construction.** The derive writes `impl Decl` next to
  `Decl`, so no package ever writes `impl Db` (the orphan law holds).
- **Namespaced by type.** Two plugins that both declare a `Rule`
  relation never collide. Generated `db.rule_by_x` methods would.
- **§6.3's table changes one column:** `db.decl_by_name(v)` becomes
  `Decl.by_name(db, v)`. The lead's `DeclRows` handle candidate is this
  same thing without the second type. A handle still has to be reached
  from `db` with its type intact, which is the storage question below.

**Where the typed rows live.** Avra has no downcast, so `Db` cannot
hold `Rows<Lint>` and hand it back typed. So the storage lives with the
relation, and the Db keeps only erased bookkeeping:
- The derive generates `once fn lint_stores() -> Cell<List<Rows<Lint>?>>`,
  indexed by the Db's dense id (minted per process). The rows stay typed
  and beside their relation.
- The accessor's first reach in a Db registers closures on the Db that
  capture only the store fn and the db id: set hash, encode, close. `Db`
  sees `fn() -> int`, never `Rows<R>`.
- Reads record deps through the Db's own int verbs
  (`db.read(slot, bucket)`). `slot` is the relation's dense family slot
  by stable name (§6.9), so the Kernel never needs the row type.
- `db.close()` runs each close hook, which nulls that Db's slot. Maps
  have no remove, and a list slot does not need one.

**Receipts** (lane/runs 095dc5e, hand-written in the derive's shape,
`build/scratch/dbp`):
- Two Dbs stay isolated: `2 0 1 true`, eval == native.
- The erased hooks sum each relation's set hash without the Db naming a
  row type.
- **Cost, for PERF:** reaching the store costs ~226 instructions through
  the dense list and ~691 through a string-keyed map (`"${db.id}"`),
  measured over 200k reaches, native. On top of `by_key`'s ~476, that is
  ~700 per recorded read, against PERF's ~315 bar. The reach is a
  `once` load, a Cell read and an index, and should approach ~20; that
  is the thing to cut, and M5's census decides.

**Found while probing:**
- `static once fn` does not parse ("expected BREAK"), so the store is a
  top-level `once fn` named after the relation. A `once` member is a
  sugar ask.
- A plugin relation reached first in some query is registered lazily.
  That is demand-order-free only because registration writes Db
  bookkeeping, never rows (§6.9's law).

**Status (2026-09-28, main 66f35cd):**
- Landed: composite `@key` (a `<T>Key` record, `key()`, `by_key`),
  `decoded(b)`, `@unique` enforced (insert answers
  `Result<T, InsertRefused>` only where a field is `@unique`), insert
  seated by the fields with no `id` seat, shape-dependent member names,
  the closed-Db trap (a `Slot` enum), a relation joined once per Db.
- The reach is one slots read plus a match on the hot path (~166 → ~119
  per reach, PERF-measured). The owned read is PERF's.
- Next, per ERRORS' S6 ranking: field kinds under decision 10 ((c) enums,
  (b) `@local`, typed ids), then the dense id with index-speed `get`, the
  erased-hooks Db, bucket recording, multi-valued `@index`.

## 4. Decisions (lead)

Each names who raised it. A decision is reopened only with a measurement.

1. **One `Db` per command.** A command derives one Workspace; a later
   reader takes its `Db`, never builds another. (PERF 1)
   **LANDED at 514c5f9:** cold check-cli 590.5B -> 338.7B instructions
   (-42.6%), peak ~1.95 GB -> ~816 MB. The warm number is still owed
   (PERF, in progress).
2. **Dense addressing only.** Every `Db` table is reached by a dense id
   or a built-once index. No scans, no whole-collection `get()` on a hot
   path, no string keys built per ask. The §2.3 fold is allowed on
   these terms. (PERF 2, §2.3)
3. **A durable row's witness covers everything it read,** plus the
   producing compiler's digest. The Kernel's recorded deps are the
   source; held reads and table bypasses must join them. (PERF 5,
   ERRORS, §2.5)
4. **`Db` is an identity: its tables live behind a `Cell`.** `rows` is a
   plain `Map` today, so `mut rows = ws.db` forks the in-process cache
   (CLAUDE.md: "AN IDENTITY IS A `Cell`, NEVER A PATH"). No caller copies
   a `Db`. (lead, found reviewing IDIOMS) Sites to sweep (abdd52c):
   `fmt.av:218`, `fmt.av:259`, `voices.av:437`, `derive.av:181`,
   `record.av:50`, `record.av:500`.
5. **A witness is a list of (stable name, value hash).** Never a dense
   id, never "was it read". Stable names come from the declaring file's
   path plus the row's own name. `Canon` gets the provider words it read.
   (ORM, IDIOMS, §2.5 limit 3)
6. **A durable row reads only through `ask`.** A table read that bypasses
   the Kernel is allowed only inside a fixpoint's own bracket, licensed
   at the site. Held-file reads record a dep on that module's `Sig` row.
   (ORM, §2.5 limits 1–2)
7. **A row and its witness settle in one step.** A trap between them
   leaves the old pair, never a new row with an old witness. (ORM)
8. **The compiler's DB is not an `@std/db` instance.** Layering cycle
   and P4 cost. The two share ONE vocabulary: the schema derive
   (`@relation`/`@model`, the four marks) and the query half (N1:
   comprehensions lowered to declared indexes). (ORM)
9. **Accessors are static fns on the relation, and the relation holds its
   rows.** `Decl.by_name(db, v)`, `Decl.insert(db, r)`, `Decl.all(db)`,
   one spelling for core and plugins. The derive writes `impl Decl`,
   never `impl Db`. Typed rows live in the relation's generated `once`
   store, indexed by the Db's dense id. The Db keeps only erased hooks
   and int dep verbs. §6.3's accessor column follows this.
   **Condition:** PERF cuts the store reach from ~226 instructions to at
   most 40, measured by census, before M5 lands. A recorded read must
   come in at or under ~350 all-in. A `once` member (`static once fn`)
   goes into the ROADMAP sugar backlog, naming this site. (ORM; adopted
   2026-09-28)
10. **A field's type decides how it enters the stable hash and the codec.**
   A keyed relation's id is a REFERENCE: hashed and encoded as the target's
   cached key hash. A dense id that names nothing stable (`StmtId`, `ExprId`,
   offsets) is refused unless marked `@local`: out of the hash and the codec.
   A row decoded from disk is a DIFFERENT TYPE, `<T>Stored`, with no `@local`
   columns, so reading one off a stored row does not compile. An enum hashes by its variant's NAME, then
   each payload field by its own rule, never by ordinal. The derive owns the
   rule; no relation hand-folds its hash. (ORM, ERRORS; adopted 2026-09-28)


## 5. Next design steps

Superseded by §6. The slices are §6.8.

## 6. The design (round 3 candidate, checked abdd52c)

### 6.1 What exists: five stores, one idea told five times

| Store | Holds | Addressed by | Durable? |
|---|---|---|---|
| `Kernel` (query/kernel.av) | deps, revisions, hashes | dense `Key{family,arg}` | no |
| 22 `Memo<DbRow>` fields (workspace.av:245-269) | per-family values | dense arg | no |
| `Db.rows` (db.av:479) | `Decl`/`Sig`/`Warn`/`Scan`/`Canon` | string name | yes, via `Store.Rows` |
| `Decls` (features/decls.av:256) | files, modules, decls, sigs, 2 indexes | dense ids + name maps | via records |
| `Store` (compiler/store/store.av) | artifacts on disk | content key | yes; a row commits with its `read` edges |

Every row has the same four parts: a KEY, a VALUE, a HASH and the READS
it depends on. The Kernel holds reads and hashes, and a memo or table
holds values, so no single store holds all four. The durable half
already has a witness slot, because `Store.keep(family, key, bytes,
read)` commits a row only together with its edges. But `Db.insert`
passes `read: []`.

### 6.2 The model: relations, queries, one Db

- **A RELATION** is a typed table of rows: one record type, one
  `Cell`-backed dense `Table`, written in place.
- **A QUERY** is a fn the Kernel memoizes, recording every read. Today's
  22 families are 22 queries.
- **A QUERY OWNS THE ROWS IT INSERTS.** A rerun replaces exactly its own
  rows, never anyone else's. It UPSERTS by `@key` (PERF round 2): a row
  whose key survives keeps its `id`, only vanished keys delete, and only
  new keys insert. So an unchanged rerun moves no id and no bucket.
  A KEYLESS relation's rerun replaces its owner's whole set. That is safe
  because nothing may reference a keyless row by id (§6.3's refusals),
  and early cutoff still holds: identical rows hash identically.
  Three rules keep ownership sound (ORM round 2):
  - **A query never reads the relation it owns**, so no reader sees a
    half-upserted set. A fixpoint that must reads its previous
    generation through `prior()`, licensed at the site.
  - **No cascade.** A row referencing a vanished row is not deleted:
    its reader's witness fails, and the reader reruns.
  - **Two owners, one key, is refused**, naming both. A row is never
    silently taken over.

  A row with no owning query is an INPUT (source text, manifests), set
  by the driver. That one rule is what makes a relation derived data
  rather than a mutable heap.
- **AN INDEX** is maintained on insert and delete, and each of its
  buckets is a Kernel cell (§6.5). There are no hand-rolled scans or
  side maps.
- **THE Db** holds every relation, the Kernel, and the durable tier.
  `Workspace` shrinks to `{ db, host, lang }`, one per command (§4.1).

```
Db
 ├─ kernel: Kernel                    (query/, unchanged layering)
 ├─ families: Cell<List<Family>>      (one slot per relation/query, dense)
 └─ disk: Pack?                       (the durable tier, §6.6)
```

`query/` gains `Relation<T>`, the generic `{ kernel, family, values:
Table<T> }` that `Memo<T>` already is, plus index maintenance. It never
learns `Db`'s name (§1).

### 6.3 The whole API: two annotations, five field marks

> **Not yet carried** (2026-09-28): the landed `@relation` derive takes `int`, `string` and `bool` fields.
> Typed-id (`DeclId`, `ExprId`), enum and float fields in this section's examples are refused
> today (avra-8sb5.57.4.14).

**Adding a projection** (DOCS' one-page walkthrough is in §3.2):
1. Can existing relations answer it? Then write `@query` fns and stop.
   Docs, for example, needs no new relation at all.
2. Does it need new facts? Declare a `@relation` and insert its rows
   from the query that knows them.
3. There is no step 3: no codec, no cache and no invalidation code.

A plugin can't add a variant to a closed `DbRow` enum, so the extension
point is an open one: a RECORD TYPE and a FN. The compiler's existing
records become relations by annotation, and nothing is renamed:

```avra
@relation
type Decl = { id: DeclId, @key module: ModuleId, @key owner: string, @key @index name: string, @key sibling: int, … }

@relation
type Call = { @index caller: DeclId, @index callee: DeclId, site: ExprId }

@query
fn raised_by(db: Db, f: DeclId) -> List<TypeId> { … }
```

The whole vocabulary, which is `@model`'s own (§4.8):

| Mark | Means | Generates |
|---|---|---|
| a field named `id` | the Db mints it; it IS the typed id (`DeclId`) | `Decl.get(db, id) -> Decl` |
| `@key f` (one or more) | together, the row's STABLE NAME across processes; unique | a key record `DeclKey { module, owner, name, sibling }`; `Decl.by_key(db, k) -> Decl?`; `d.key() -> DeclKey` |
| `@unique f` (one or more, independent) | a CONSTRAINT, naming nothing | `User.by_email(db, v) -> User?`; checked at the rerun's COMMIT over the final set (a swap inside one rerun is legal) |
| `@index f` | a partition | `Decl.by_name(db, v) -> List<Decl>` |
| `@local f` | a dense value local to this process (`StmtId`, `ExprId`, offsets) | no accessor; out of the stable hash and the codec; a stored row is `<T>Stored`, which has no such column (decision 10) |
| (always) | the whole relation | `Decl.all(db) -> List<Decl>`, witnessed by the relation's set hash |
| `@relation type R` | — | `R.insert(db, r)`; a value hash over EVERY field's STABLE encoding (never the dense `id`); a codec |
| `@query fn q(db, k)` | — | a memoized wrapper; reads recorded; early cutoff; persisted |

`@key` is identity and `@unique` is a constraint (ORM round 2).
`@key` implies unique over its tuple, never the reverse. A row keeps
being the same row when a `@unique` field changes, and becomes a
different row when its key changes. F3017's "one name per module" is a
`@unique` constraint, not a key.

`@key` is IDIOMS' visible rule, where a positional "first field" rule
would be invisible. The generated KEY RECORD is also the stable name
itself: §6.4 encodes a reference as its target's key record. So one
generated type serves both the lookup and the disk format.
**Neither the key record nor an N-parameter accessor generates today**
(CORRECTED, IDIOMS; probed by ORM at 47d72d5). A hole in a type's name
position doesn't parse, a lone field has no template kind, and a
spliced parameter list traps (avra-j2dl, a template span read against
the consumer file). M2a widens one mechanism to unblock both: run
holes for a type's field list and a fn's parameter list, name holes
for a type's and a fn's name, and `@std/meta` field and param
builders.

Two derive rules (IDIOMS round 3):
- **Generated names are snake_case of the type's words**, so
  `ErrorSite` gives `error_site_by_callee`. Today's `lower_first`
  (`rows_derive.av:68`) would give `errorSite_by_callee`.
- **`insert` is a `Cell` write, never a `mut fn`**, so a query takes
  `db: Db` and F2047 has nothing to flag.

`id` and `@key` answer different questions: `id` is fast in-process
identity, and `@key` is identity on disk.

**`@query` needs one new directive: WRAP** (IDIOMS round 1). Today a
Declares annotation can only add a twin BESIDE the fn, so callers would
reach the unmemoized body. A same-name twin is silently accepted
(avra-2hij). WRAP makes the written body private (`raised_by$body`) and
resolves the written name to the generated wrapper, and `avra expand`
shows both (P7). It is general: tracing and timing want it too.
The agreed shape (IDIOMS with ORM):
- `Directive` grows `wraps: bool = false`, appended, so the crossing
  law lets it pass.
- The written fn's private name derives from IDENTITY (module, owner,
  name), never position.
- The wrapper redeclares the exact signature (marks and defaults
  included) and carries the written `///` doc.
- `wraps: true` with no matching fn is a named refusal.
- avra-j2dl (the parameter-run hole) is fixed inside M2a, with no blob
  stopgap.

The first reader of `wraps` owes the seed refresh (CLAUDE.md, "growth
is not a moved shape").

These are the defaults, and the magic is in them:
- **Durable by default, with nothing to tune.** Every query's hash and
  edges persist. Whether its VALUE persists, the Kernel decides per
  family from measured compute time against load time (PERF round 1).
  `@query(transient)` exists only as an escape hatch (P8), never as
  routine tuning.
- **Every read is recorded**, because every read goes through an
  accessor. There is no raw table to bypass.
- **One door.** `db.x(k)` is the same call whether the answer is in
  memory, on disk, or not yet computed.

Refusals at the declaration, through `Declared.problems`, generating
NOTHING over a refused shape (ORM's `@model` tripwires):
- an unknown field mark (marks are free names, so a typo like `@indx`
  would otherwise be silently ignored);
- a field kind the codec cannot carry;
- a fn-typed field (a closure capturing the Db is a cycle);
- a relation or field whose name collides with a generated accessor;
- two packages claiming one stable name;
- a relation referenced by id from another relation without a `@key`
  (a keyless rerun moves every id, so a reference would name a position).

A relation with ONLY marked fields (a membership set) is day-one tested.

### 6.4 Identity on disk: `@key`, or the owner's witness

A dense id means nothing in the next process (§2.5, limit 3). A persisted
row encodes each typed-id field in one of two ways:
1. **Through the target's `@key`.** `callee: DeclId` is written as the
   callee's `DeclKey`. The core relations with keys are `File` (path),
   `Module` (dotted name) and `Decl`, whose `sibling` counts
   same-(owner, name) siblings only. A `TypeId` is written as its
   shape's digest over component keys, or its declaration's key.
2. **Relative to its owner's witness**, for a keyless id such as an
   `ExprId`. §6.7 is the worked case.

**A relation's own stable name is its fully qualified import path**
(`@std.avrac.compiler.Decl`, spelled as `use` spells it), never the bare
type name (lead ruling on avra-8sb5.57.22). The dotted module path is
stable across checkouts, unlike a file path. Two modules may declare
same-named relations, as they may declare any same-named type. That
name seeds the hash and names the pack record.

Every key record is encoded by its own derived codec: each component is
length-prefixed, and nothing is joined with a separator (the ARITY
law). `("a.b", "c")` against `("a", "b.c")` is the colliding pair,
written as a test before the codec lands (ORM round 2).

A key says WHAT the source declares, never WHERE: `record.av`'s
file-wide `ordinal` shifts every later decl when one is inserted above,
and a stale row could then match a different decl (ORM round 1). The
file-wide ordinal stays as the record's LAYOUT check (`record_complete`),
never as identity. A signature is what the HASH covers, not the key, so
an edit revalidates rather than reading as delete + create.

This answers §2.1: `record.av`'s `Row` is the durable encoding of the
`Decl` relation and becomes its codec, not a separate type.

### 6.5 Durability: a witness is the Kernel's deps, renamed

At `settle`, a query's Kernel deps are written through §6.4 as
`(stable name, value hash)` pairs (§4.5), and stored in the pack beside
the query's hash, its rows and (if kept) its value, all in one commit
(§4.7).

Loading in a new process works like this:
1. The first ask for a query reads its entry: hash, edges, and value if
   kept.
2. Each edge's CURRENT hash is asked in turn. That is red-green all the
   way down to INPUT hashes (file bytes, env, manifests), memoized per
   process.
3. If every edge matches, the stored hash is current, and the value and
   rows are reused. Otherwise the query recomputes.
   A dep that no longer exists (a deleted decl) is a MISMATCH, never
   "nothing to check" (ORM round 2; the empty-value law).

`Decl`'s file witnesses become this general case, and `Canon` gains its
provider-word dep (§4.5) automatically. The compiler digest and each
plugin's digest join every witness (§4.3, PERF 5).

Held files join the graph (§2.5, limit 1): a read of a held file's decl
records a dep on that module's `Sig` row instead of returning before
`ask`.

Bypasses (§2.5, limit 2; ERRORS' audit in §3.1): a table read that
skips the Kernel is refused inside a query's bracket unless licensed at
the site (§4.6). When the tables become relations, most bypasses
disappear, because `decls.decl(d)` becomes `db.decl(d)`, a recorded
read.

**Index reads are deps too (DOCS round 1: the phantom read).** A row-level
witness misses a NEW row appearing under a key it looked up. So an
index BUCKET is itself a Kernel cell:
- `db.decl_by_name(n)` records a dep on `(Decl.name, n)`.
- The bucket's hash is a commutative SUM of its rows' stable hashes,
  each first passed through a NONLINEAR 64-bit finalizer (splitmix64's
  mix), and updated in O(1) on insert and delete. Without the finalizer
  the tree's linear `fp` makes swapped-field rows collide: (a,1),(b,2)
  and (a,2),(b,1) sum alike (PERF round 3). That pair is a test before
  the codec lands.
- Each keyed row caches its key's hash at insert, so a typed-id field
  hashes in one read. A dense id never enters a hash,
  or every witness would fail on load and every rerun would move
  buckets (PERF round 2).
- Bucket cells are created lazily, on first read.
- A query records each bucket edge once. Past K bucket reads on one
  index, it records the index's set hash instead (coarser, with fewer
  edges).
- Inserting a row changes its bucket's hash, which invalidates every
  reader of that bucket and no one else.
- A whole-relation scan depends on the relation's own set hash.

`listing_digest` is this, hand-written. It becomes the general case, one
bucket wide instead of one package wide.

**Validation never materializes (DOCS round 1: the zero-parse hit).**
Every node persists its HASH and EDGES, even one whose VALUE the Kernel
chose not to keep. Checking a durable row therefore
walks stored edges down to INPUT hashes (file bytes, env, manifests):
- no parse, no declare, no relation built;
- a derived dep's stored hash counts as current once its own stored
  edges validate (red-green, memoized per process).

So `avra docs <name>` on a warm cache reads edges and digests files,
exactly what `fresh_db()` does today, generalized.

### 6.5a Measured: a flattened witness fails; the red-green shape holds (PERF)

**The drift.** §6.5 says each node persists its own hash and its
DIRECT edges. As built, a file's witness records the FLATTENED
transitive closure of leaf edges (`leaves_below`, witness.av). On a
cold `check packages/std-avrac` (ef0d957) that is a median of 74,600
edges per file and 33.3 M edges in all. Each file is duplicate-free;
the files simply share one closure. The pack is 279 MB. Witness ON
costs, over OFF: cli cold +62%, cli edited +38%, std-avrac cold
+116%, std-avrac edited +216%. RECORDING is 88–90% of that. Caching
the flattened set per key was tried and reverted (O(keys × leaves),
4 GB). A 1% gate is unreachable while a witness is flat.

**The shape.** Each key records only its direct deps, each as
`(stable name, value fingerprint)`. Validation walks the DAG
root-down, memoized per key per process: a key is current when every
direct dep is current and its stored fingerprint still matches.
Recording is O(direct edges). Nothing is flattened or materialized.
A missing dep is a mismatch.

**What .106 provides.** Content fingerprints for Visible, Resolved,
Typed, Folded, Analysis and Lowered, computed lazily: free inside one
revision, real when a later process compares them. Those are the
per-edge values the red-green check reads.

**Measured: kernel grain cannot persist.** Recording one family
cuts nothing, it only moves the list. Total stored edges over every
pack entry: 34.28 M with none recorded, 34.62 M with Items, 34.44 M
with Folded. Recording EVERY family's direct deps is larger still: on
`check packages/cli` the kernel touches ≥2.54 M distinct keys with
≥51.6 M direct deps (still climbing when stopped). Rows are already
shared per key, so that is the true size of the fine-grained graph,
not duplication. Persisting it cannot meet a 1% gate.

**Decision (lead).** The durable witness is the hold path's
`KeyParts`: a file's text plus each module it imports' interface
digest, per file. It reaches 397/399 on a warm cli edit at near-zero
cost. Kernel-grain deps stay in-process. Fine-grained recording
happens lazily, only when `avra cache why` asks. The flattened
recording and its switch are deleted.
- Root-down validation is `stands_in` over the kept `KeyParts`.
- A missing dep is a mismatch: a module with no record falls back to
  its bytes, never to "nothing to check".
- The two-process stale refusal is pinned in `cache_attacks`: a
  signature edit re-reads its importers, a body edit holds them.

### 6.6 Performance rules (from PERF, binding)

**The disk shape (PERF round 1, measured at 23a704f):** today's `Store`
holds 2,699 files, median 1 byte, 5.9 MB of content in 11 MB on disk.
A file per row cannot carry durable-by-default. So rows go to ONE
packed file per package:
- a name table (stable names interned once to dense ids), then an
  APPEND-ONLY, checksummed log of entries (hash, edges, rows, value);
- one commit marker per command, or per idle in LSP/watch. A torn tail
  after the last marker is ignored, so §4.7 holds with no rewrite;
- compacted by rewrite-and-rename past about 50% garbage;
- mmapped and decoded lazily.
- **Each record header carries its relation's SHAPE fingerprint**
  (field names, types, marks, order). A mismatch drops the record, and
  the row recomputes; nothing ever decodes a stale shape. There is no
  growth-tolerant reading: rows never cross a compiler generation (the
  compiler digest is in every witness, §4.3), so the fingerprint is the
  belt and the digest the braces.

**The codec (agreed by PERF and ORM):**
- The hash mixes PER 8-byte step (`z = mix(z ^ word)`), with the length
  in the tail, then finalizes. It is seeded by the relation's
  stable-name hash. A final mix over a linear fold would keep the
  fold's collisions.
- Bytes are little-endian: zigzag-varint ints, raw float bits,
  varint-length strings (NUL is data), count-prefixed lists, a varint
  tag plus payload for enums, one presence byte per `?` layer, and a
  typed id as its target's length-prefixed key record. Arity is fixed
  per kind.
- `Map`, `dyn` and fn fields are refused at the derive until a layout
  exists.
- Tests written FIRST: the empty string and list round-trip;
  `("a.b","c")` against `("a","b.c")`; swapped equal fields.

`Store` keeps the big artifacts (`Obj`, `Bin`). The pack replaces
`Store.Rows` and `Db.rows`. This is a hypothesis, measured at M3
against per-row files.

**Validation cost (PERF, §6.10 Q1):** O(rows asked + their edges).
Recomputation is O(changed). Validation starts at the roots a command
asks for and stops at the first matching hash (early cutoff). A
fixpoint depends on its input relation's SET hash, which is one edge,
not one edge per participant.

**The receipt for "magic":** warm `check packages/cli` today is
252.1B instructions against 591.0B cold (PERF, 23a704f). The target is
that a warm check with no edits costs about the validation walk alone.
Each M-slice posts that number.

**First receipt (PERF, 1c0cad6, lane/checkfix):** warm `check packages/cli`
251.8B -> 125.7B (one workspace) -> **0.36B** instructions, with the licence
verdict cached as a `DbRow.Licenses` row; peak 1.18 GB -> 7 MB. A warm check
now costs about the validation read alone. M3's pack carries `Licenses`
alongside `Warn` and `Canon`. The full lane (one workspace, the licence row, the
`spec_id`/`settle_id`/`lifted` index, the qtrace guard) takes cold check-cli
590.7B -> 286.7B (-51.5%). The licence witness is PROVEN (a rule renamed and
rebuilt: refused cold and warm; reverted: clean). The mechanism is the STORE
DIRECTORY, not the key: `compiler_print` (the running binary's bytes) names
the store root (`build_cache_root`), so one binary never reads another's rows.
The hole is a host that names no compiler (the `"shared"` store), which M0b
closes.

**Rules:**
- Dense `(family, arg)` addressing on every hot path. Stable names are
  built only at settle and load, and are interned to dense ids at once
  (the `spec_id` lesson: never a name scan).
- Relations are `Cell`-backed and written in place. A reader's hold must
  die at its last read (ORM §4), and `AVRA_ALIAS_LOG` must show no
  whole-table clone.
- Index maintenance happens on insert, O(1) amortized. No scans.
- The durable tier is lazy: a row is decoded only when first asked.
- Every phase lands with a `make census` before/after for `check
  packages/cli`.

### 6.7 Worked example: error topology as a thin query

> **Not yet carried** (2026-09-28): the landed `@relation` derive takes `int`, `string` and `bool` fields.
> Typed-id (`DeclId`, `ExprId`), enum and float fields in this section's examples are refused
> today (avra-8sb5.57.4.14).

ERRORS' three queries (§3.1) all want ONE row per SITE plus an edge
index, so a site is the relation:

```avra
@relation
type ErrorSite = {
    at: ExprId,                    // encoded relative to its owner's witness (§6.4)
    @index owner: DeclId,          // the enclosing declared fn (a lambda's site: its enclosing fn) — `fn` is a keyword, refused as a field name
    how: SiteHow,
    @index callee: DeclId?,        // the fn a Propagate or Catch is applied to
    @index within: ExprId?,        // the Catch whose arm holds this site, if any
    errors: List<TypeId>,
}
enum SiteHow { Fail, Propagate, Catch }
```

`within` is the CONTAINMENT fact ERRORS found missing. A `catch` arm can
re-raise (`x catch e -> { … fail e }`), so a Catch is not an
unconditional stop. It stops a chain exactly when no site sits
`within` it.

**Two layers, two owners (ERRORS round 3).** `ErrorSite.errors` holds a
site's DIRECT contribution only, because a per-fn walk cannot know an
inferring callee's final set, least of all under mutual recursion. The
settled answer is a second relation with its own owner:

```avra
@relation
type Raised = { @key owner: DeclId, errors: List<TypeId> }
```

It is owned by the ONE fixpoint query, which iterates over `ErrorSite`
reads until nothing grows. That is today's Kleene loop, now writing
rows. No row has two owners.

**Granularity (ERRORS round 1, Q4):** the expensive part is each fn's
structural walk, not the Kleene iteration. So the walk is a per-fn
`@query` whose output IS that fn's `ErrorSite` rows, witnessed by its
recorded reads (§6.5). The fixpoint is one query over those rows.
Per-SCC rows wait until `make census` says the iteration is a
measurable cost.

The topology is a set of queries over these rows. A chain is a TREE,
since one fn has many callers and a catch can re-raise several ways:

```avra
type Chain = { site: ErrorSite, next: List<Chain> }

fn raised_by(db: Db, f: DeclId) -> List<TypeId> { db.raised_by_key(RaisedKey { owner: f })?.errors ?? [] }

fn chain(db: Db, s: ErrorSite, seen: List<DeclId>) -> Chain {
    match s.how {
        // containment inside one fn's finite tree: cannot cycle, needs no guard
        .Catch -> Chain { site: s, next: [chain(db, n, seen) for n in db.error_site_by_within(s.at)] },
        // a call edge can cycle
        .Fail or .Propagate -> {
            if seen.contains(s.owner) { return Chain { site: s, next: [] } }
            let deeper = seen.concat([s.owner])
            Chain { site: s, next: [chain(db, n, deeper) for n in db.error_site_by_callee(s.owner)] }
        },
    }
}
```

`Catch` rows and `within` are new facts, inserted by the pass that
types a `catch`.

**Invariant, pinned by a day-one test (ERRORS round 2):** a site
`within` a Catch lives in that Catch's own fn (`n.within == c.at`
implies `n.owner == c.owner`). Only a nested fn declaration could break it,
and none exists. That invariant is why the `within` hop needs no cycle
guard. A second day-one test pins ONE owner per `at` for every keyless
owned relation (`ErrorSite`, `Call`), which their encoding relies on
(ORM round 3).

**The fixpoint's witness is the `ErrorSite` set hash, which is
deliberately coarse.** Any fn's site change reruns the Kleene iteration
over every participant, while each fn's walk stays cached. M6 measures a
one-fn edit's re-solve at real N. Sub-millisecond keeps it this simple;
otherwise per-SCC witnesses land, justified by that number.

**Persisted ids here are owner-relative** (§6.4): `at` and `within`
have no key, so each is written as (owning decl's key, offset). The
offset is pinned to that decl's CONTENT HASH, which the per-fn query's
witness also holds, so a changed decl fails the witness before any
offset is read.

**Non-goal, stated:** an ESCAPING lambda (stored, then called from an
unrelated stack) is attributed lexically to its enclosing fn and is not
traced through value flow. What such a fn value can raise is carried by
its TYPE, not by the topology. Generic calls resolve per trait member
(`contract_member`); one generic case goes in M6's tests as a probe.

Docs works the same way. A lookup is `db.decl_by_name(n)`, and a
collision is simply that list's length above one. The bare dump is a
scan of `Decl` with the relation's set hash as its witness (§3.2).

### 6.8 Migration: landable slices, in order

| # | Slice | Unblocks | Receipt |
|---|---|---|---|
| M0 | `Db` tables behind `Cell`; sweep the 6 copy sites; delete side caches beside rows (`records.grammar_scanned`); qtrace guard | §4.4, PERF | census, alias log |
| M1 | `Relation<T>` in query/; 22 memo fields -> `Db.families`; a last-reader stamp for per-query edge dedup | §2.3, §4.2 | census neutral |
| M2a | Directive WRAP; annotation uses count as references (.25.70); refuse same-name twins (2hij) | `@query`, plugin DX | expand golden |
| M2 | `@relation`/`@query` derives (accessors, marks, hash, codec) | §6.3 | derive tests; WRAP costs one ask and no closure per call |
| M3a | the pack's mmap runtime row, hosted `Unhosted` (a registry row lands alone first) | M3 | `make bootstrap` |
| M3 | `@key` codecs; settle writes deps as witness; the packed per-package file | §4.5, §4.7 | two-process test: edit a callee's `E`, stale row refused; warm check-cli number |
| M4 | Held reads record `Sig` deps; bypass lint in query brackets | §4.6 | red-team the ERRORS audit list |
| M5 | `Decls` tables -> relations; indexes declared | §0.4 centralization | census |
| M6 | Projections: `ErrorSite` + topology queries; docs via `Decl` index; `Canon` via witness | §6.7 | ERRORS, DOCS, IDIOMS own these |

Each slice changes the compiler's own source, so every slice runs under
the generation law: save `build/avra` aside, build twice, then `make
bootstrap`.

### 6.9 Plugins

A plugin is a package that declares `@relation`s and `@query`s. Linting
rules, an LSP feature and a docs renderer are examples.
- **Registration is the declaration.** At admission each relation and
  query gets a dense family slot by its STABLE name (`package.Type`).
  Slots are never persisted and never reused within a process; the
  stable name is what goes to disk.
- **Plugins read core relations and ask core queries through the same
  accessors**, so their reads are recorded and their answers invalidate
  with no plugin code. A core query's answer must not depend on DEMAND
  ORDER, which is already the compiler's law. A plugin asking first
  exposes an order bug; it does not create one.
- **The direction is one-way.** Core never reads a plugin relation. A
  plugin writes only its own relations, and its `@index` marks live
  on its own relations, so maintaining an index never writes to core.
- **Every input is a named dep.** A plugin reads files and the
  environment only through Db input accessors (`db.file_text(path)`,
  `db.env(k)`), so data inputs join witnesses exactly as source files
  do. The plugin's own digest joins its witnesses too (§4.3), so a
  plugin edit invalidates only its rows.

**Open, for the owner (found landing .26):** COLLECTIONS.md §4.7 makes a
`closure`-scoped collect REACHABILITY-based ("collected means reachable"): a
dependency's module that nothing imports contributes nothing. §6.9 registers a
plugin's relations and queries through `collect … in closure`. So a plugin whose
relation sits in a module nobody imports would SILENTLY not register. Either
§4.7 amends (a manifest-declared dependency contributes all its files), or
plugin registration uses a different scope. `package` scope now admits the
whole package (.26).

### 6.10 Open (for the team's red-team)

1. ~~Validation cost?~~ **PERF:** O(asked + edges), kept near O(changed)
   by root-down validation and early cutoff (§6.6).
2. ~~A structural `TypeId`'s digest: stable across generations?~~
   **Lead answer:** it doesn't need to be. The compiler digest is in
   every witness, so a new generation re-derives everything. Within one
   generation the digest must recurse through component STABLE names,
   never through their dense ids (a `List<T>`'s name names `T`'s name).
3. ~~Can `@query` wrap a fn? Do field marks parse?~~ **IDIOMS:** no,
   so WRAP lands in M2a. Field marks parse today.
4. ~~Per-SCC rows?~~ **ERRORS:** no, not until census shows it. Cache the
   per-fn walk first (§6.7).

### 6.11 The compiler itself: how the AST enters the Db

Nothing is copied in. **The parse query OWNS its file's syntax
relations, and the arena it already builds IS their storage.**

Today (checked at 514c5f9):
- `NodeStore` (`core/store.av:25`) holds dense per-file arenas:
  `exprs: Arena<Expr>` and `stmts: Arena<Stmt>`, keyed by
  `ExprId`/`StmtId`, with a stable fingerprint per node
  (`expr_fingerprints`, `stmt_fingerprints`).
- Pass facts are `SideTable` columns over those ids: `NameFacts`
  (`bindings`, `captures`, …) and `TypeFacts` (`of_expr`, `widens`, …),
  in `features/facts.av`.

That is already a relational base, stored COLUMNAR and addressed
densely: CLAUDE.md's "node facts live in side tables keyed by typed
ids" is the relation law, stated before the Db existed. So:

| Stage | Query (owner) | Relations it owns | Storage |
|---|---|---|---|
| input | `source(f)` (`@input`) | the file's text | bytes |
| parse | `parsed(f)` | `Expr`, `Stmt` (`id` = `ExprId`/`StmtId`) | the `NodeStore` arenas, unchanged |
| declare | `items(f)` | `Decl` rows for the file | `Decls` tables (M5) |
| resolve | `resolved(f)` | name facts per `ExprId` | the `NameFacts` side tables |
| type | `typed(d)` | type facts per `ExprId` in `d`'s range | the `TypeFacts` side tables |
| derive | per-projection queries | `ErrorSite`, `Call`, `Reference`, … | ordinary relations |

What this buys:
- **A side table is a relation stored as a column.** `@relation(column)`
  over an existing `SideTable` keeps its dense storage and gains
  recorded reads plus a bucket per value: `db.expr_type(e)` is one load.
- **The AST is queryable by the same comprehensions (N1).** `Expr`
  gains `@index kind` (the variant tag `@derive(Matchable)` already
  computes), plus `@index decl`, the owning declaration. `failures.av`'s
  `propagate_sites` scans `lo..hi` today and becomes
  `[e for e in db.expr if e.decl == f && e.kind is .Propagate]`, a
  bucket lookup.
- **Stable hashes already exist.** Each node's fingerprint is its row's
  stable hash (§6.5), so early cutoff per consumer (CLAUDE.md's cutoff
  law) reads the fingerprints the parser writes today.
- **Identity across edits is owner-relative** (§6.4). An `ExprId` shifts
  when the file changes, so a durable reference to a node is (decl key,
  offset), pinned by that decl's content hash.
- **Durability is the Kernel's call** (§6.3). A parse is cheap and
  usually recomputed, while typing is dear and usually kept. Held files
  already skip parsing through their records.

**Arena and column relations record reads at the OWNER's grain, never
per node** (PERF, on §6.11). Typing reads nodes and fact columns millions
of times per check, so even a deduped per-read compare would eat what
M1–M5 save.
1. **The owner's own reads record nothing.** Typing reading the facts it
   is writing is its computation, not a Db read. This does not break
   §6.2's "never read your own relation", which protects OTHER readers
   from a half-upserted set.
2. **Another query's reads record ONE edge per owner slice, taken
   once.** For syntax the slice is the DECLARATION: reading any node in
   `d`'s range records one edge on `syntax(d)`, a cell whose hash folds
   that range's node fingerprints. One edge per file would retype every
   decl in a file on any edit, which breaks CLAUDE.md's cutoff-per-
   consumer law.
3. **Node fingerprints are linear `fp` folds,** so any sum over them
   passes each through the splitmix finalizer first (§6.5).

Ordinary relations (`Decl`, `Call`, `ErrorSite`) keep §6.5's per-row
and per-bucket recording. **Measured (PERF, dedicated harness, N = 1e5–1e7):**
an unrecorded read costs about 120 instructions, a stamped repeat read about 315,
and a new recorded dep about 1,900. Per-node recording would pay ~2.5x on
every repeat read and ~15x on every first read, so the per-declaration grain
stands. The stamped-hit path (+~190) is itself a PERF follow-up. A per-query seen SET, allocated at every
begin, cost ~49B instructions on one cold check-cli (+14.9%, M1's first nesting
fix) and did not ship: nesting safety must allocate nothing when nothing nests.

**Why the AST is not row-per-node rows in a generic table:** P4. A
file's arena is contiguous, and a pass walks it in order. Generic rows
would be a pointer per node and a hash lookup per child. The relation
is the INTERFACE (ids, indexes, recorded reads), and the arena is the
STORAGE. `@relation(column)`/`@relation(arena)` name that storage
choice, and every accessor looks the same to a consumer.

Slice: **M5b** (after M5): `Expr`/`Stmt` as arena relations,
`SideTable` facts as column relations, and `@index kind`/`decl`.
It also renames `NodeStore` to `SyntaxArena` (owner-approved), so
"Store" names only the on-disk artifact cache.

## 7. Language leverage: less code for us and for consumers (lead)

Owner, 2026-09-26: lean hard on derivation, `collect` and powerful
language features, and dream up new ones. The finding that shapes this
section: **`collect` and this Db are one idea.** COLLECTIONS.md's own
"long game" reads "program facts as one relational base, with
collections, callers and lint rules all as queries over it", and §6 is
that base. So each feature below either DELETES hand-kept plumbing or
removes a word a consumer would otherwise learn. Counts are at abdd52c.

### 7.1 Use what exists

| Feature | Replaces | Deletes |
|---|---|---|
| `@derive` → `@relation`/`@query` (§6.3) | hand accessors, codecs, hashes, `rows_derive.av`'s per-kind pairs | every `fn decl`/`insert_decl`-shaped pair; the "hash forgets a payload" class |
| `collect … = @relation or @query in closure` | the Db's family registry | 22 `*_memo` fields (70 refs), 24 hand family lists in `built()`, plugin registration code (a plugin registers by existing) |
| `table<Row>` literals | test fixtures | hand-built seed rows: `db.insert_all(table<Decl> { … })` |

### 7.2 New features, ranked by code removed

**N1. A comprehension over a relation IS a query, and the compiler
picks the index.**
```avra
[s for s in db.error_site if s.callee == f && s.how is .Propagate]
```
The predicate `s.callee == f` matches `@index callee`, so this lowers to
the bucket lookup and records the bucket dep. A predicate with no
matching index is a full scan witnessed by the set hash, and it WARNS
with the fix ("add `@index callee`"), which keeps the cost visible
(P7). Consumers write ordinary comprehensions and never learn
`_by_field` names.

**Planning rules (PERF round 4):**
- An index applies only when the compared side is INVARIANT over the
  scan (`s.callee == f`, never `s.callee == s.fn`).
- Only a pure conjunction of `field == value` over indexed fields is
  planned, using the comparison's own equality. Anything else is a
  residual (rule 2 below).
- A conjunction uses one index, then filters.
- `x in s.marks` over a multi-valued index (N2) is the lookup form.
- The unindexed-scan warning fires only past a relation size a census
  names, because a warning nobody must act on trains readers to skip it.

**N1 is the shared vocabulary's QUERY half:** `@std/db` wants the same
lowering, with a comprehension over a model becoming SQL `WHERE` plus
an index (ORM round 4). Three rules keep it one vocabulary:
1. **The index is a declaration, never a guess.** `@index`/`@key` emit
   it (a hash index here, `CREATE INDEX` in SQLite). The lowering
   targets a declared index, and an unindexed predicate is a VISIBLE
   scan (warned, and explained by N6).
2. **What a backend cannot express is refused, never degraded.** The
   translatable part is field compares, `&&`, `||`, `!`, `in` over a
   literal or a hole, and null tests. Captured locals bind as
   parameters and are never spliced (the two-hats law). ONE rule holds
   for both backends, so acceptance never depends on the backend: a
   RESIDUAL (untranslatable) predicate may run in memory ONLY over a set
   narrowed by a declared `@index`/`@key`. A residual over an un-narrowed
   set is refused on both backends, naming the sub-expression. A
   translatable predicate on an unindexed field is a warned scan (rule
   1). Where the line falls is a property of the QUERY, shown by N6
   (ORM round 4).
3. **An equality on a `@key`/`@unique` answers at most one row**, so
   `.first()` on it types as `T?`.

**Joins come next.** A comprehension with two `for` heads is a join.
Today that form is refused (one `for` head per comprehension, "the
subset today"), so N1's node shape must leave room for it. Those accessors stay generated underneath, as the
plan's target.

**N2. A multi-valued `@index` over a `List` field.** `@index marks:
List<string>` files the row under each element. `Decl` gains `@index
marks` and `@index word`, and `Decls.collect_index` (`by_word`/`by_mark`,
20 refs) is deleted. **`collect` then lowers to N1 over `Decl`**:
`collect xs = @tag in package` is `[d for d in db.decl if d.marks
contains "tag" …]`, cached, persisted and invalidated like every query.
Collections and the Db stop being two mechanisms. More precisely
(IDIOMS round 4): a collect's MEMBER SET is a compile-time query
(`collect_members`, `lower.av:909`, is already an index lookup plus a
scope filter), and its ANSWER is lowered as data, because a program has
no Db at run time.

**A live defect found on the way, to fix now and not blocked by this
design:** `collect_sort_key` (`lower.av:917`, at d23eccb) joins the
`by` fields with `"."`, so `by a, b` over `("a.b", "c")` and
`("a", "b.c")` produce the same key. That is the ARITY-law collision,
and the order becomes wrong too. Sort by the tuple (a key record), not
by joined text. **FIXED at e3fd2d4 (IDIOMS)**, sorting by the tuple.
The fix found a SECOND bug: members mapped back by `find(key == k)`
dropped every member whose key tied another's. Both are pinned by
tests (`collect_order_ties`).

**N3. `collect enum`** (COLLECTIONS step 4, unbuilt). Its variants are keyed by
STABLE NAME, never by a dense ordinal, because a new member would
shift every persisted ordinal after it (IDIOMS round 4). `collect enum
Family = @relation or @query in closure` synthesizes the family enum,
and matches over it stay exhaustive. This deletes `Family` (22 arms)
and `DbKind` (21 arms), plus `rows_derive.av`'s standing note that
`Kind` "stays hand-written" because a variant list cannot be spliced.

**N4. WRAP directives** (M2a). `@query`, and also `@traced`, `@timed`
and `@retry` later, wrap a fn body visibly (`avra expand` shows it,
P7). One directive covers every cross-cutting concern that today would
be hand-written at each fn.

**N5. Recursive queries with fixpoint semantics: `@query(fixpoint)`.**
Today the Kernel answers a cycle ONCE (`Cycle`) and stops, which is
wrong for a growing set (ERRORS round 3; `failures.av`'s header found
the same). `fixpoint` changes the verdict for a recursive query group:
given a lattice (join = set union), the Kernel solves the SCC with a
semi-naive WORKLIST (PERF round 4). Every member starts queued. When a
member's answer grows, only its readers are re-queued, and the Kernel's
recorded edges name them. Naive rounds would be O(n²) on a call chain,
since a set crosses one edge per round. A member whose re-run answer
SHRINKS is refused as a defect, never looped, because a non-monotone
member has no fixpoint to find. The group declares its JOIN; a body that is not
monotone in it is refused; and a turn cap SPEAKS rather than hangs. The effect on existing code:
- The `Raised` query's hand-written Kleene loop is deleted, and
  `raised_by` becomes the recursive `@query(fixpoint)` itself.
- `chain` stays OUTSIDE `fixpoint` (ERRORS round 4). A tree has no
  finite-height lattice, so "re-run until nothing grows" would
  re-expand a cycle forever. Its `seen` guard is the right tool: it
  stops a cycle in one pass as a terminal leaf. `fixpoint` is only for
  SET-growing groups: `Raised` is one (2^TypeId under ⊆, finite
  height, monotone), and so are reachability and effects.
- Every future transitive analysis (reachability, effects, purity) is
  one declaration.

Datalog's power, spelled as ordinary fns.

**N6. `avra explain why <query>(<args>)`.** It prints the witness tree:
which edges held, and which one failed and recomputed. The witness
already exists, so this is zero new data. `avra explain db` adds
relation sizes, hit rates and bytes on disk. This is P7 for the magic:
the cache is never a black box.

**N7. `@input` on a Db accessor.** `db.file_text(path)` and
`db.env(k)` are declared with `@input fn …`: a query whose value the
driver sets and whose hash is its bytes. Plugins, and a future
`embed`, get correct invalidation by declaration (§6.9).

**N8. More of the compiler as declared relations** (IDIOMS round 4),
each deleting hand tables:
- **`Reference`** (use → decl) as a relation. This deletes the hand
  reference tables and their verbs in `Decls`, and
  `refs_are_incomplete`. It is IDIOMS' per-file durable references
  want.
- **`Finding`** (rule, site) as a relation owned per (rule, file). The
  idiom baseline becomes a QUERY DIFF (new findings minus accepted
  ones). This is IDIOMS' per-file durable findings want.
- **DOGFOODING's registry** becomes a renderer over the rule relation,
  not a hand list.

**Risk order (IDIOMS round 4), cheapest first:** N2, N4, N6, N3, N7,
N5, N1. N1 is the riskiest because the planner must be exactly right.

### 7.3 What error topology costs a consumer, before and after

- **Before:** `failures.av`, about 330 lines, with the answers thrown
  away after use.
- **After:** the `ErrorSite` and `Raised` relations (about 10 lines),
  the per-fn walk as one `@query`, `Raised` as `@query(fixpoint)` with
  no hand loop, and topology as comprehensions (N1). `chain` is about
  8 lines, with its `seen` guard.
- **A plugin's `avra explain errors f`** is a renderer over `chain`,
  with no compiler change.

### 7.4 Sugar-backlog asks (each names its wanting site)

1. N1: relation comprehensions with index planning. Wanting site:
   §6.7's topology, and docs' `decl_by_name`.
2. N2: multi-valued `@index`. Wanting site: `Decls.collect_index`.
3. N3: `collect enum`. Wanting site: `Family`/`DbKind`, `rows_derive.av:21`.
4. N4: the WRAP directive. Wanting site: `@query` (IDIOMS, avra-2hij).
5. N5: `@query(fixpoint)`. Wanting site: `failures.av`'s Kleene loop.
6. Two `for` heads in a comprehension, read as a join (N1). Wanting
   site: a topology or rule that crosses two relations.
7. A parameter-run hole (avra-j2dl). Not needed now, since key records
   replace it.

### 7.5 Order

N4 blocks `@query` (M2a). N1 and N2 land with M5, once `Decl` is a
relation. N3 lands with M1, deleting the family lists as they move.
N5 lands with M6, and ERRORS' fixpoint is its first user. N6 and N7
land with M3, where the witness first exists.

## 8. Speed ledger (lead, measured)

A landing, measured on the pack (2026-09-27): two builds 3.5 min, std-avrac
suite 5 min, cli 1.5 min, idioms (cold) 2 min, seed-check 2.5 min — about 15
min. The drag is the QUEUE, not the landing: re-merges when main moves, agent
stalls, and the dependency chain. Levers, in order:
1. Checks run in parallel (suites plus idioms): done in the lead's land_checks.
2. The seed refreshes only when it can't compile HEAD: done (1f509df).
3. .24's fix lets landings keep warm caches: landing now.
4. Batch landings: ready branches merge together and check once.
5. A merge touching no compiler source needs no rebuild: done by hand, and
   land.sh does it too.
6. Critical-path work starts early wherever a dependency can be stubbed
   (M3 witnesses on hand-written stable names, before M2's key records).

