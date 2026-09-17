# The build cache — design and plan

Make Avra's builds incremental, fast and small — and get the correctness **by
construction** rather than by discipline.

Status: the whole-program cache is landed and paying; the identity laws are
understood, witnessed and partly landed; the interface's foundation is landed and
witnessed; the split's dedup is landed and verified inert. The map below is the
whole design, in the order it has to be built, with what is done and what is not
marked as such.

---

## 1. Measured

`build packages/cli` (the compiler's own build), **user CPU, never wall** — this box
runs at load 10–175 from other campaigns, and wall is the machine's number, not the
tree's.

| | user CPU |
|---|---|
| where the campaign began | 93.0 s |
| **no-op** (nothing changed) | **0.25 s** — 372× |
| edit / clean | ~30–35 s |
| lone-file no-op | 0.019 s |

An edit's cost splits like this:

| stage | cost | redone on an edit? |
|---|---|---|
| parse | ~7.5 s | every file, statelessly |
| resolve + typecheck | **~14 s** | yes — the WHOLE program, every time |
| lower + emit | ~5 s | could be per changed file |
| **link** (clang) | **~10 s** | yes |

**THE EDIT CASE IS ANALYSIS-BOUND**, and that single fact decides the whole design.
Resolve-plus-typing is ~14 s of ~35 s; any plan that only caches IR has aimed at the
`lower+emit` slice (~5 s, ≈1.2×).

Cache sizes, for the arithmetic: **19 MB per key** (16 MB `.ll` + 3.3 MB `.bin`), cap
8 keys ≈ 149 MB.

---

## 2. The diagnosis

The compiler re-does **the whole frontend** on every build. It does not need to.

**The derivation tree already exists — it is the query kernel.** `parsed → resolved →
typed → lowered` are its nodes; dependencies are discovered by execution; `ask` is
the red-green walk ("verify my inputs; if none changed, reuse me"). The kernel *is*
the graph this campaign wants. There is nothing to invent.

So two things are wrong, and only two:

1. **The tree dies when the process exits.**
2. **The bottom node's "did my inputs change?" test does not cover the whole value** —
   `parsed` cuts off on structural fingerprints while its value carries the source
   text and every span. Sound while compiles are one-shot (the ROADMAP's recorded
   trigger `avra-8sb5.9.2`); fatal the moment anything edits.

**Do NOT serialize the middle of the tree.** The AST and typed tables are live
structures keyed by per-run integer ids and holding closures. Writing them to disk
means inventing a binary format for the compiler's memory, and it breaks every time
an internal shape moves.

---

## 3. The architecture

### 3.1 The pipeline

```
   bytes ──► INTERFACE ──► IMPLEMENTATION ──► OBJECT ──► BINARY
  (on disk)   (tiny)        (IR text)        (bytes)     (bytes)

  interface_key(f) = digest( f's bytes + interfaces of f's imports + language )
  impl_key(f)      = digest( f's bytes + interfaces f can see    + language )
```

Everything persisted is small and already hashed.

### 3.2 The waist

Ask what must cross a file boundary. Not the AST. Not the typed facts. **Only the
interface** — the names a file exports and their signatures.

A file calling `twice` needs `twice`'s *signature*. Never its AST, never its type
tables. Everything else a file computes is private to itself. **Interfaces are the
only thing that must learn to persist, and they are simple by construction.**

### 3.3 What an edit costs once this holds

Re-check whether the interface moved, re-type and re-lower only the files whose
`impl_key` moved (usually one) → recompile one object → relink.

**AND BE PRECISE ABOUT WHAT THIS DOES *NOT* SAVE.** Parse is per-file, but its result
is a live structure (arena ids, spans), so *statelessly* the parse still re-runs for
every file (~7.5 s). Resolve and typing ARE skippable, because a file's resolve reads
only `(its bytes + the interfaces it sees)` and both are in the key. So the honest
ladder is:

* **interfaces** remove ~14 s of resolve + typing;
* **per-file objects** remove ~5 s of emit;
* **parse** (~7.5 s) needs a resident engine or persisted trees;
* **link** (~10 s) needs an incremental linker.

Those last two are why a truly instant edit is four rungs, not one.

A **signature** change propagates to exactly the files that can see it and nothing
else — automatically, because the interface hash is *in* the downstream keys. That is
the seat-change witness, one level up.

This is **stateless**: no daemon, and it shares across processes, worktrees, machines
and CI. A resident engine gets the same win but only within a session.

---

## 4. The laws of a key

Four laws, each paid for by a defect or a measurement. Together they are the whole
correctness argument, and every one is about **what a key may and may not contain**.

### 4.1 A KEY COVERS THE WHOLE VALUE

An early-cutoff hash that covers less than the value it certifies claims "unchanged"
about something that changed. `parsed` settles on a structural fingerprint while its
value carries the text and every span, so **a reindent leaves later spans stale and
certified fresh**. Sound while compiles are one-shot; the ROADMAP records the trigger
(`avra-8sb5.9.2`).

The answer is not one hash over everything — that re-runs typing on a blank line — it
is **a cutoff PER CONSUMER**: what a dependent READ decides which fingerprint may cut
it off. That is the resident engine's prerequisite (§9.5). Persistence bypasses it
instead, because its keys are whole-value by construction.

### 4.2 A KEY MUST NOT COVER GLOBAL STATE — the dual

**FOUND BY THE CONTROL.** The three-leg interface witness was run end to end and
**leg 3 failed**: an unrelated file's key MOVED. Leg 3 is the leg with no link
whatsoever to the change.

Isolated by discriminating the change:

| change | an UNRELATED file's key | |
|---|---|---|
| a BODY in an unrelated module | **stable** | so it is not "any change" |
| a SEAT (`int` → `string`) in an unrelated module | **MOVES** | a new type enters interning |
| editing the file itself | moves | correct |

**`sig_hash` folds interned `TypeId` ORDINALS.** A `TypeId` is a dense index into the
workspace's type registry, so introducing `string` anywhere in the program shifts the
ordinals, and every signature mentioning a type shifts with them. The key is a
function of the **global interning order**, not of the program's meaning.

Both halves are key defects, and they are opposites:

* too **little** coverage (structure without text or spans) **reuses a stale
  artifact** — a wrong binary;
* covering **global state** (an interning ordinal, a revision, a clock)
  **invalidates everything** — a useless cache.

Neither is a deliberate choice anyone made; both are what a convenient number happened
to include. And the second is **invisible to every witness that only checks a hit is
not wrongly given** — it takes a control that says a key must NOT move.

### 4.3 A TYPE'S PERSISTENT IDENTITY IS ITS SPELLING

`stable_type` / `stable_sig` (`build_cache.av`) render a type by **name and structure**
rather than by interned ordinal, so an unrelated change cannot move a persistent key.
`sig_hash` stays exactly right for the memo kernel's in-process early cutoff, where
the ordinals are fixed within the run; **it is only a persistent key that may not use
it.**

The interface key must fold `stable_sig`. Where a named type is rendered by NAME only,
the rendering is **transitively incomplete** for nested named types — which is why the
interface over-approximates by folding the whole **visible namespace** (§5.1). The
over-approximation is deliberate and sound; the alternative is a key that names less
than the contract.

### 4.4 TWO LIFETIMES

One number can be right in one lifetime and wrong in another:

| | in-process | persisted |
|---|---|---|
| a type's identity | the interned ordinal (`sig_hash`) | its spelling (`stable_sig`) |
| `parsed`'s cutoff | structural fingerprint | the whole value, by construction |

**This distinction has now decided two designs.** `CACHE_FORMAT` covers the serialized
side of the same idea: a format change is a language change.

---

## 5. Rung 2 — the interface, in full

### 5.1 The two-level key

```
bytes_key(m)   = digest( sorted (relative path, bytes) of m's files )     # the LOOKUP key
surface_key(m) = digest( bytes_key(m) + [surface_key(m') for m' in imports(m)] + language )
```

The entry is stored under `bytes_key` and **validated** by recomputing the imports'
current `surface_key`s and comparing them with the recorded ones. Equal → the surface
is reused with **no parse and no resolve**; different → re-parse. `bytes_key` needs no
parse (the bytes are on disk), so the lookup itself is free.

`surface_key` is a digest of:

```
    ITS OWN FILES' BYTES
  + THE surface_keys OF EVERY MODULE IT IMPORTS
  + THE LANGUAGE HASH
```

The imports are in it because **a signature can name a type from an import**: a module
whose surface says `fn f(x: util.Pair)` must move when `util.Pair` changes, and a key
over its own bytes alone misses exactly that. **A surface key that names less than the
contract reuses a stale body on precisely the change the interface exists to catch.**

### 5.2 The record

One record per MODULE:

```
{ imports: [ (module, the surface_key it had) ],
  surface: [ (name, kind, stable_sig) ] }
```

Keyed by `bytes_key` (no parse), invalidated by content in exactly two ways — its own
files' bytes and any import's surface. No clock, no flags, no configuration.

### 5.3 Validation: the bounded walk

The recursion is real: validating M needs its imports' current `surface_key`s, and
each of those is a digest over its own imports. Unbounded, a per-module transitive
closure would hand back the resolve time the interface exists to save — and it would
stay invisible until a deep graph arrived.

It is bounded by one property that makes the walk **free of parsing**: the imports come
from a record keyed by `bytes_key`, a digest of **file bytes alone**, so every module's
import list is readable without parsing anything. Therefore:

1. **A MEMO.** `surface_key(m)` is computed once per module and held for the walk's
   duration. Cost per module: one small read plus one digest. **O(modules), not a
   closure per module.**
2. **AN ITERATIVE TOPOLOGICAL PASS**, not recursion — no depth limit, no reliance on
   native stack depth.
3. **AND THE WALK IS THE BUILD PLAN.** Every module must be visited anyway to decide
   what to rebuild, so validation is not extra work; it is the same pass that says
   "this one re-parses, that one is reused".

### 5.4 Cycles

Two different cycles exist and only one is already refused:

* a **PACKAGE** dependency cycle is refused by the language, in its own words
  (`dependency_cycle` at `admitted`) — so a package graph the compiler accepts is
  acyclic;
* a **MODULE** cycle inside one package is *tolerated* today (two files importing each
  other is a memo cycle the kernel answers rather than recurses into), so the walk must
  tolerate it too — and a surface graph with a cycle has no well-founded digest.

**THE RESOLUTION IS TO COLLAPSE IT, NOT TO ORDER IT.** The memo doubles as a VISIT
MARK; re-entering a module still in flight identifies a cycle, and **every module on
that cycle takes a BYTES-ONLY key** — a digest of the members' own file bytes, with no
surface reference among them. That is **sound because it over-approximates**: a change
to any byte of any member moves every member's key, so nothing inside the cycle can be
reused across a real change. The cost is over-invalidation *within the cycle only*, and
cycles are rare, small, and already a shape the language tolerates rather than
encourages.

### 5.5 The witness

The seat-change witness, one level up. **All three legs pass** (`module_surface`, end to
end on a real package):

1. change a SEAT in module M → `surface_key(M)` **moves**
2. a module **importing** M → **its** `surface_key` moves — *the closure,
   load-bearing; a key over own-bytes-alone fails exactly here*
3. an **unrelated** module → its `surface_key` does **not** move — *the control*

Leg 3 is the leg that found §4.2 one level down, and it passes now because of that fix.
**The control has earned its place twice**, which is why it is in every witness this
campaign writes.

**Saving:** parse and resolve of every unchanged module is skipped — the resolve and
typing half (~14 s) plus the parse of unchanged modules (~7 s).

---

## 6. Rung 1, the disk half — measured, reverted, and the dedup that unblocks it

### 6.1 The measurement

The per-file split was built, measured and **reverted**. For `packages/cli`: **257
modules, 210 MB for ONE key**, against **19 MB** for a single whole-program module —
and the compiler's own no-op went from **0.25 s to 21 s**. The split inflated the IR
**11–13×**, because every module repeated EVERY declaration and EVERY static.

**SMALLER UNITS ARE NOT SMALLER BYTES.** A rung that was supposed to reduce disk
multiplied it. Found and not landed, with the measurement, is the right outcome for a
rung that sounded good.

Two smaller defects surfaced with it and both are real: the modules were written
**beside the source** (`packages/cli/src/main.av.ll.<i>.ll`) rather than in the cache
directory; and the cache's artifacts must go to the **disk** host, never the source
host (§13).

### 6.2 Why the duplication was structural, and the dedup that fixes it

**LLVM requires a called symbol to be declared in the module that CALLS it**, so
declarations cannot live in one module and be referenced from others. They need not be
**repeated** either — and repeating them is the whole inflation, because declarations
are the bulk of a module's text, not its bodies.

So a split module declares, lays out and defines exactly what it carries (`9bd531d`):

| | |
|---|---|
| bodies it **owns** | declared + defined |
| bodies it **names** (a callee, a fn value's address) | declared only |
| hosted rows it **calls** (runtime, extern) | declared only |
| statics it **addresses** | laid out only |

The projections for all of this already existed — `body_symbol`, `hosted_symbol` — and
the one missing was the static's, so **`static_symbol` joined them in `core/ir.av`,
beside the two it is the sibling of.**

Two seats, not one: `whole` is a **field** of `Refs` rather than an absent value, and
`bodies_of` is the ONE place the optional file is opened — so no caller guards a
nullable and no two callers can disagree about which bodies are the module's. (The
idiom gate refused the nullable spelling three times; the field is the honest answer,
not a licence to write the guard out.)

**VERIFIED INERT:** a whole-program module is byte-identical before and after — both the
lowered IR and the emitted `.ll` (6265 bytes) — because `only == null` takes the `whole`
path. The split path is the only behaviour that changed, and it is not yet invoked, so
nothing here can regress the running compiler.

### 6.3 The pending measurement

**The split's TOTAL BYTES with this dedup, against the 210 MB it measured without.**
That needs a driver — one `emit_module(l, path, false, f)` per file — and **that number
decides whether the split is worth building at all.** It is the next thing to do, and it
is a measurement rather than a code change.

---

## 7. Rung 3 — per-file objects

Recompile one object, relink. This is the **safe** form of "binary patching": patching
machine code in place needs fixed addresses and no inlining, and breaks on any layout
move; the linker patching one changed object does not.

It is gated on §6.3: per-file objects are the second half of the same split, and the
split's disk cost decides when they are worth it. The link (~10 s) is the floor an edit
lands on, which is why this rung matters even after the interface rung.

---

## 8. Rung 4 — semantic addressing

The IR is a **closed, curated vocabulary** (~40 instruction shapes, catch-all-free), so
it is tractable here and nowhere else to NORMALIZE it: α-rename registers, canonicalize
commutative operands, canonicalize block order, drop provably-dead definitions — and key
the cache on the **normalized** hash. Then a rename, an extraction, a reformat, or a
reorder of independent code **does no work**, because the meaning is byte-identical. No
build system on earth does this.

**THE CAVEAT IS THE WHOLE GAME: normalization must be SOUND and CONSERVATIVE — collapse
only what is provably identical. Missing an equality forever is fine; inventing one is a
silently wrong binary.**

### 8.1 The pair that must NOT be equal

Two runtime rows with **the same host and the same params**:

```
avra_array_get        ret: I64   owns_result: false   lends: true    host: RtHost.ArrayGet
avra_array_get_owned  ret: Ptr   owns_result: true    lends: false   host: RtHost.ArrayGet
```

A normalizer keyed on "which operation is this" — and `RtHost.ArrayGet` is *literally
the same value* for both, which is the temptation — maps them to one identity. They are
not equal: **one borrows, one retains**, and conflating them changes a reference count,
which is a leak or a use-after-free, silently.

The failing case is written before anything builds (`normalization_test.av`), and both
halves are asserted so the witness fails if EITHER stops holding: a key over the
OPERATION must conflate them (that is the temptation, and the reason the rule exists),
and a key over the ROW must keep them apart. **The rule: identity comes from what the
ROW says — `owns_result`, `lends`, `ret`, `name` — never from the host.**

### 8.2 The temptation a normalizer reaches for first — already closed

`a + b` vs `b + a` is commutative *by opcode*, and `expr_spine/lower.av` lowers a string
`+` to `CallRt("avra_str_concat", [a, b])` and an int `+` to `Bin(Add, a, b)`. The
temptation is neutralised **by the IR's shape**, not by a convention someone must
remember — which is the strongest argument for the closed vocabulary.

---

## 9. Persistence vs resident — the review

The step after the interface's foundation owes a review, because it turns on a
capability the tree does not have. Its spec is the tree's own recorded trigger.

### 9.1 The trigger

> **`avra-8sb5.9.2`**: "`parsed`'s early cutoff covers structural fingerprints only —
> sound while compiles are ONE-SHOT; fires when anything edits."

The trigger is precise: `parsed` settles on a structural hash while its VALUE carries
the source text and every span, so a reindent leaves later spans stale and certified
fresh. Two options follow — and one of them sidesteps the trigger entirely.

### 9.2 The options, against the same questions

| | **RESIDENT** (a long-lived engine) | **PERSISTENCE** (content-addressed artifacts) |
|---|---|---|
| **what is retained** | the whole in-memory workspace: `Db` cells with deps/revisions, every memo family (Parsed, sigs, type facts, units, settlements), the decls tables | the IR (per unit) and the OBJECT, plus the INTERFACE — and NOT the AST, NOT the typed facts |
| **keyed by** | nothing new — the kernel's existing (family, arg) dense keys | `unit_key` (a file's bytes + the sigs it can see, **by spelling**) and `module_surface` |
| **invalidated how** | `Db.set_input` on re-read bumps the revision; the red-green walk propagates | content alone, by construction |
| **how the one-shot assumption is replaced** | it must be **REPLACED**: the daemon relies on `parsed`'s cutoff, so the per-consumer cutoff must be built first (the trigger) | it is **BYPASSED**, not replaced: the keys already cover the whole value — every byte, and the sigs by spelling — so nothing depends on `parsed`'s structural cutoff, and that cutoff keeps its correct one-shot life |
| **staleness** | the process holds state it must be TOLD about; a file changed behind its back is served stale | impossible by construction: a key that covers the whole value cannot certify a changed one |
| **shares across** | one process | processes, worktrees, machines, CI |
| **lifecycle** | new: start/stop, a process older than the binary it was built from, a client that must invalidate | none — the existing one-shot CLI, plus files |
| **risk** | MEDIUM: a stale process answers in the right SHAPE | LOW: a wrong reuse requires a hash collision |

### 9.3 The conclusion, and the reason is the trigger

**PERSISTENCE.** The resident engine's most attractive property — that the incremental
machinery already exists and only needs to stop dying — is exactly what makes it a trap
here: **THE MACHINERY IT WOULD REUSE IS THE UNSOUND ONE.** A daemon leans on `parsed`'s
cutoff, so it must first BUILD the per-consumer cutoff the trigger names. Persistence
does not lean on it: its keys already absorb the whole value, so the trigger stops being
a prerequisite and becomes an **irrelevance** — the same lifetime distinction that
governs `sig_hash`, one level up.

### 9.4 Lifecycle and staleness — the resident engine's new failure surface

A long-lived process holding state can be WRONG about the world in ways a one-shot
process cannot, and the tree already contains the hole:

**`Memo.input` NEVER RE-READS ONCE LOADED.** Its body matches the value table first
and, on `.Present`, records the dependency and RETURNS the memoized value — the host is
never asked again. Loading is a `Missing`-only path. That is correct for ONE-SHOT,
where nothing can change under the process, and it is a **silent stale world** for a
daemon: a file edited on disk is never re-read, so the daemon keeps compiling the old
bytes and has no way to notice. **The same hole covers manifests** — a dependency added
to an `avra.toml` is never seen — so a daemon's package set is stale too.

So the resident engine's first prerequisite is **not the cutoff, it is that INPUTS
VERIFY**: re-read, fingerprint, and let `set_input` bump the revision only when the
bytes moved (the kernel already bumps and propagates). Cheap — a read and a hash per
input — and it is the mechanism `Workspace.sources` already anticipates in a comment
("a live host clears an entry when its file changes").

**THE INVALIDATION WITNESS FOR IT, WHICH FAILS FIRST.** Two legs, both against a
resident process:

1. change a file's BYTES and ask for a build again **in the same process** — the answer
   must MOVE, and on today's `Memo.input` it does not;
2. add a DEPENDENCY ROW to a manifest and ask again — the package set must grow.
   *Leg 2 is the control.*

Two more sources, each with its own answer. **The binary it was built from**: a daemon
IS its own generation, so a rebuilt `build/avra` leaves it serving an older LANGUAGE —
an identity check at the request boundary and a clean exit, never a silent answer.
**A build tool it cannot see** (clang, the runtime object): already handled by being
stateless about it, since the link plan is rebuilt per request.

### 9.5 The one-shot assumption, replaced vs bypassed

* **RESIDENT must replace it.** A cutoff per consumer: `parsed` owes TWO fingerprints
  and a dependent's cutoff names which it read. Bounded, but it touches every cutoff
  DECISION — the kernel's correctness argument, not just its code.
* **PERSISTENCE bypasses it.** Its keys absorb every byte, so no consumer cuts off on
  `parsed`'s structural hash, and `parsed` keeps its correct one-shot life. **Nothing in
  the tree changes** — which is why it is the lower-risk of the two.

### 9.6 Cost and risk, as numbers where they exist

| | resident | persistence |
|---|---|---|
| prerequisite work | inputs that verify + the per-consumer cutoff + a protocol and a client | per-file IR + **dedup** + per-file objects |
| measured cost of the dedup gap | — | **19 MB → 210 MB** without it (built, measured, reverted) |
| what it saves | the whole analysis, in-process | the whole analysis, across runs |
| expected edit | **~10 s, link-bound** | **~10 s, link-bound** |
| risk of a wrong answer | MEDIUM — a stale process answers in the right SHAPE | LOW — needs a hash collision |
| new lifecycle | a daemon to start, stop, age out | none |
| sharing | one process | processes, worktrees, machines, CI |

**THE CASE FOR PERSISTENCE, STATED FAIRLY:** it does NOT avoid the hard part — the
analysis must become incremental either way, and the same keys serve both. It avoids two
things: writing a second invalidation mechanism beside the kernel's, and owning a
process. Its cost is that IR must be STORED, which is why dedup comes first.

**THE CASE FOR RESIDENT, STATED JUST AS FAIRLY:** the kernel ALREADY IS the incremental
engine — dependency capture, red-green verification, cycle detection — and a persisted
cache re-derives a coarse approximation of that graph **by hand**, which is two engines
and potentially two truths. `unit_key` is exactly that coarse hand-derivation, and it
will drift from the kernel the day the kernel changes.

### 9.7 The Sprite model — where the two fail differently

The landing gate is one-shot clang on a Sprite under "one COLD receipt per landing". A
resident engine is the OPPOSITE of cold, and that is not a performance objection, it is
a **contradiction**: a cold receipt's whole purpose is "this tree builds from nothing",
so a receipt taken through a warm process is not that receipt. Therefore:

* the cold receipt must be taken by a ONE-SHOT process, daemon or not — **the rule does
  not change**;
* a daemon would not participate in the landing path, and would ADD a service to start
  and age out inside a Sprite that needs none today;
* persistence composes with the model UNCHANGED — a cache directory and one-shot
  processes, riding the Sprite the way the seed does.

### 9.8 The synthesis (P6) — both, at different scopes

The two are not rivals. They serve different SCOPES and **share the same keys**, which is
the reason to build the keys first and the reason neither choice is wasted:

* **PERSISTENCE** — CI, the landing gate, cold receipts, cross-machine and cross-worktree
  sharing. Stateless, no lifecycle, composes with the Sprite rule.
* **RESIDENT** — the interactive dev loop (an editor, `avra serve`), where the same keys
  let the kernel answer in-process with **no serialization at all**.

Both sit on `unit_key` and `module_surface`. Building those first is the step that is
right under either ruling; the ruling chooses which to **land** first, not which to have.

**The ruling taken: PERSISTENCE.** The build order is therefore §6.3 → §7 → §8:
the split's measurement, then per-file IR, then per-file objects.

---

## 10. The vision — build on meaning, and observe dependencies rather than declare them

All of these are one move: **a thing's identity comes from what it MEANS and from what
it actually READ, never from a label a human wrote.** Each is enabled by something the
language already has.

1. **Observed invalidation.** The kernel already records deps by execution; take it one
   field down and record *which fields of which values were read*. Then the cutoff is
   DERIVED, not declared, and "a hash that forgets a payload" becomes unrepresentable.
   Highest value: it turns an entire bug class into a structural impossibility.
2. **Interfaces as the persisted waist** (§5). Bounded, provable.
3. **Per-file objects** (§7). The safe "patching".
4. **Semantic addressing** (§8). The headline — sound only once 1–3 hold.
5. **Evidence and derived code as cached derivations.** A test is a derivation over its
   subject, so a rename re-runs nothing and a real change re-runs exactly what it
   touched; the receipt names the derivation it proved. A `@derive`'s output is keyed by
   (the annotated type's derivation + the trait's own + the language), so
   metaprogramming stops being paid for twice — ever, on the machine.

And because **the language is a value**, keying by language hash makes grammar changes
cheap (only nodes that READ the changed rule invalidate) and lets two language versions
coexist in one store. No other compiler can offer that.

The endgame is **verifiable build receipts**: a peer verifies by re-hashing inputs, so
you ship proofs rather than trust.

---

## 11. Order, and what is done

| # | what | status |
|---|---|---|
| 0 | whole-program cache, cap + GC, linked binary kept, seam fixed | **LANDED** |
| 0 | the perf work behind the cache (`Cell` verbs) — 5.8× on every compile | **LANDED** |
| 0 | `stable_type` / `stable_sig` — a persistent key folds a SPELLING | **LANDED** |
| 0 | `unit_key` + `avra keys` — the per-file identity, inspectable | **LANDED** |
| 0 | `module_surface` — the interface's identity, all three legs witnessed | **LANDED** |
| 0 | the split's **dedup** (`static_symbol`, `Refs`, `bodies_of`) | **LANDED, verified inert** |
| 1 | the split's **measurement** — total bytes with the dedup, vs 210 MB | **NEXT** |
| 2 | per-file IR cache keyed by `unit_key`, interfaces validated by the bounded walk | design complete (§5) |
| 3 | per-file objects | gated on 1 |
| 4 | semantic addressing — the failing case already committed | gated on 1–3 |
| 5 | evidence + comptime caching — the compounding payoff | last |

**Why this order.** Observed invalidation and the keys kill the bug class and everything
after relies on the key being complete; interfaces are the only thing that must persist
and they are bounded; the split and objects are what make an edit cheap; semantic
addressing is sound only once the identity is trustworthy; evidence caching compounds
only when the layers under it are stable.

---

## 12. The laws this work paid for

- **A `Cell`'s read-modify-write round trip is a copy per element, and the fix is a
  verb.** Measured: `get`→push→`set` = 0.453 s for 20,000 appends; `Cell.push` = 0.001 s.
  Copy-on-write IS amortized, `List`/`Table`/`Namespace` are fine; the one slow shape is
  the round trip, and `Cell` existed precisely to make mutation-through-sharing cheap
  while `lower_set` already emitted the in-place slot write.
- **The idiom's own advice can be the quadratic.** I3 recommends a comprehension or
  `concat` for a build loop; both are O(n) per call, so following it literally
  re-introduces the defect. Licensed at the sites with the reason.
- **A verb and its first use are two generations, so the seed rides the slice.** Three
  instances in one day, in two consecutive commits.
- **A perf change that makes a declaration honest is the tree saying the shape improved**
  — the only diagnostic difference was a new F2050, and it was right.
- **A compiler under test must stand where a compiler stands.** Running it from
  `packages/cli/src/` moves `avra_self_dir()`, the std root resolves elsewhere, and
  `println` disappears — the artifact looks broken when the harness moved the ground
  under it.
- **A generated artifact is not a concern to review.** The seed alone is +25991/−21632;
  the landing is 1222 lines without it.
- **A key must cover what the unit READ** — witnessed end to end on a real package, with
  a control: change only a called fn's parameter type, the importer's bytes are
  byte-identical, its key moves, and an unrelated file's key does not.
- **A positive-only witness cannot see over-invalidation.** It takes a leg asserting a
  key must NOT move. **Two of this campaign's four findings came from that leg.**
- **When a nullable keeps needing a guard, the structure is wrong, not the guard.** A
  field that says `whole` beats a null that every caller must open. (The idiom gate
  refused the nullable spelling three times, correctly.)
- **Measure the anvil too.** Four instruments lied in one session (wall for user CPU, a
  harness that did not exercise the path, `avra run` which INTERPRETS, and a link failing
  silently). Every one produced a confident wrong answer.
- **A control is what turns a witness from a demonstration into an instrument.**

---

## 13. Known defects, filed

- **AN UNRESOLVABLE NAME IN A FILE'S OWN `use` LIST AMPUTATES THE FILE.** `use core.{…,
  Lowered}` where `Lowered` lives in the module itself made ALL of `build_cache.av`'s
  exports vanish, and the errors were reported against other files ("does not export
  `unit_key`", "does not export `build_program`"). A file-level typo, a module-level
  amputation, reported against innocents. **Filed as P2.**
- **A `Store`/`Host` seam is missing.** The library's cache writes artifacts through
  `Host`, and a LONE FILE's host is in memory — its `.ll`/`.plan`/`.warn` vanish with the
  process while the binary reaches the real disk. **WITNESSED INERT**: delete the `.bin`
  and the build REBUILDS, so nothing consumes the wrong path. ~45 lines; folds into the
  per-file work, which rewrites exactly this path.
- **`tools/census.sh` deletes `build/avra_runtime.o` and does not restore it** — broke
  linking twice in one day.
- **`@std/process` is flaky under load** — three runs of a gated tree gave rc=1, rc=1,
  rc=0, and the differing bytes are LOST CHILD OUTPUT. The gate is intermittently red for
  reasons unrelated to any landing.
