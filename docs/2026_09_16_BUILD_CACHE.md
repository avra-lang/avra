# The build cache — design

The campaign: make Avra's builds incremental, fast and small — and get the
correctness by construction rather than by discipline.

## Measured

`build packages/cli` (the compiler's own build), **user CPU**, never wall — this
box runs at load 10–175 from other campaigns and wall is the machine's number,
not the tree's.

| | user CPU |
|---|---|
| where the campaign began | 93.0 s |
| **no-op** (nothing changed) | **0.25 s** — 372× |
| edit / clean | ~35 s |
| lone-file no-op | 0.019 s |

An edit's 35 s splits:

| stage | cost | redone on an edit? |
|---|---|---|
| parse / resolve / typecheck (**analysis**) | **~14–18 s** | yes — the WHOLE program, every time |
| lower + emit | ~5 s | only for changed files |
| **link** (clang) | **~10 s** | yes |

**The edit case is ANALYSIS-BOUND.** This is the measurement that decides the
design: per-declaration *IR* caching buys only the `lower+emit` slice (~1.2×), and
any plan that only caches IR has aimed at the smaller half.

## What is already built

| | |
|---|---|
| content-addressed whole-program module cache | `build_cache.av` — key over every byte a build reads |
| the key is derived once, used for store and lookup | `build_key` |
| **the linked binary is kept** | a hit is a `cp`, not a clang run |
| cap + dead-key collection | cap 8, `recent` file, clock-free LRU, **witnessed evicting** |
| `unit_key` + `avra keys` | the per-file identity, inspectable |
| the perf work (not caching) | 5.8× on every compile — `Cell.push`/`Cell.set_at` |

## The diagnosis

The compiler re-does **the whole frontend** on every build. It does not need to.

**The derivation tree already exists — it is the query kernel.** `parsed →
resolved → typed → lowered` are its nodes; dependencies are discovered by
execution; `ask` is the red-green walk ("verify my inputs; if none changed, reuse
me"). The kernel *is* the graph this campaign wants.

So two things are wrong, and only two:

1. **The tree dies when the process exits.**
2. **The bottom node's "did my inputs change?" test does not cover the whole
   value** — `parsed` cuts off on structural fingerprints while its value carries
   the source text and every span. Sound while compiles are one-shot (the
   ROADMAP's recorded trigger `avra-8sb5.9.2`); fatal the moment anything edits.

**Do NOT serialize the middle of the tree.** The AST and typed tables are live
structures keyed by per-run integer ids and holding closures. Writing them to disk
is inventing a binary format for the compiler's memory, and it breaks every time an
internal shape moves.

## The waist

Ask what must cross a file boundary. Not the AST. Not the typed facts. **Only the
interface** — the names a file exports and their signatures.

A file calling `twice` needs `twice`'s *signature*. Never its AST, never its type
tables. Everything else a file computes is private to itself.

```
   bytes ──► INTERFACE ──► IMPLEMENTATION ──► OBJECT ──► BINARY
  (on disk)   (tiny)        (IR text)        (bytes)     (bytes)

 interface_key(f) = digest( f's bytes + interfaces of f's imports + language )
 impl_key(f)      = digest( f's bytes + interfaces f can see    + language )
```

Everything persisted is small and already hashed. Interfaces are the only thing
that must learn to persist, and they are simple **by construction**.

An edit then costs: re-if-the-interface-moved, re-type/re-lower only files whose
`impl_key` moved (usually one) → recompile one object → relink.

**AND BE PRECISE ABOUT WHAT THIS DOES NOT SAVE.** Parse is per-file, but its
result is a live structure (arena ids, spans), so statelessly the parse still
re-runs for every file (~7.5s) — only a resident engine (or persisted trees) skips
it. Resolve and typing ARE skippable, because a file's resolve reads only
`(its bytes + the interfaces it sees)`, and both are in the key. So the honest
ladder is: interfaces remove ~14s of resolve+typing, per-file objects remove ~5s
of emit, and **parse (~7.5s) and link (~10s) need the daemon and an incremental
linker respectively** — the last two are why a truly instant edit is three rungs,
not one.

A **signature** change propagates to exactly the files that can see it, and nothing
else — automatically, because the interface hash is *in* the downstream keys. That
is the seat-change witness, one level up.

This is **stateless**, so it needs no daemon and shares across processes,
worktrees, machines and CI. A resident engine gets the same win but only within a
session.

## The vision — build on meaning, and observe dependencies rather than declare them

All five are one move: **a thing's identity comes from what it MEANS and from what
it actually READ, never from a label a human wrote.** Each is enabled by something
this language already has.

1. **Observed invalidation.** The kernel already records deps by execution; take it
   one field down and record *which fields of which values were read*. Then the
   cutoff is DERIVED, not declared, and "a hash that forgets a payload" becomes
   unrepresentable. Highest value: it turns today's entire bug class into a
   structural impossibility.
2. **Interfaces as the persisted waist** (§ above). Bounded, provable.
3. **Per-file objects.** Recompile one object, relink. This is the SAFE form of
   "binary patching" — patching machine code in place needs fixed addresses and no
   inlining, and breaks on any layout move; the linker patching one changed object
   does not.
4. **Semantic addressing.** The IR is a CLOSED, CURATED vocabulary (~40 instruction
   shapes, catch-all-free), so it is tractable to NORMALIZE it — α-rename
   registers, canonicalize commutative operands, canonicalize block order, drop
   provably-dead definitions — and key the cache on the NORMALIZED hash. Then a
   rename, an extraction, a reformat, a reorder of independent code **does no
   work**, because the meaning is byte-identical. No build system on earth does
   this. **THE CAVEAT IS THE WHOLE GAME: normalization must be SOUND and
   CONSERVATIVE — collapse only what is provably identical. Missing an equality
   forever is fine; inventing one is a silently wrong binary.**
5. **Evidence and derived code as cached derivations.** A test is a derivation over
   its subject, so a rename re-runs nothing and a real change re-runs exactly what
   it touched; the receipt names the derivation it proved. A `@derive`'s output is
   keyed by (the annotated type's derivation + the trait's own + the language), so
   metaprogramming stops being paid for twice — ever, on the machine.

And because the **language is a value**, keying by language hash makes grammar
changes cheap (only nodes that READ the changed rule invalidate) and lets two
language versions coexist in one store. No other compiler can offer that.

The endgame is **verifiable build receipts**: a peer verifies by re-hashing
inputs, so you ship proofs rather than trust.

## The laws this work paid for

- **A `Cell`'s read-modify-write round trip is a copy per element, and the fix is a
  verb.** Measured: `get`→push→`set` = 0.453 s for 20,000 appends; `Cell.push` =
  0.001 s. Copy-on-write IS amortized, `List`/`Table`/`Namespace` are fine; the one
  slow shape is the round trip, and `Cell` existed precisely to make
  mutation-through-sharing cheap while `lower_set` already emitted the in-place
  slot write.
- **The idiom's own advice can be the quadratic.** I3 recommends a comprehension or
  `concat` for a build loop; both are O(n) per call, so following it literally
  re-introduces the defect. Licensed at the sites with the reason.
- **A verb and its first use are two generations, so the seed rides the slice.**
  Three instances in one day, in two consecutive commits.
- **A perf change that makes a declaration honest is the tree saying the shape
  improved** — the only diagnostic difference was a new F2050, and it was right.
- **A compiler under test must stand where a compiler stands.** Running it from
  `packages/cli/src/` moves `avra_self_dir()`, the std root resolves elsewhere, and
  `println` disappears — the artifact looks broken when the harness moved the
  ground under it.
- **A generated artifact is not a concern to review.** The seed alone is
  +25991/−21632; the landing is 1222 lines without it.
- **The key must cover what the unit READ** — witnessed end to end on a real
  package, with a control: change only a called fn's parameter type, the importer's
  bytes are byte-identical, its key moves, and an unrelated file's key does not.
- **Measure the anvil too.** Four instruments lied in one session (wall for user
  CPU, a harness that did not exercise the path, `avra run` which INTERPRETS, and a
  link failing silently). Every one produced a confident wrong answer.

## Order

| # | what | why here |
|---|---|---|
| 1 | observed invalidation | kills the bug class; everything after relies on the key being complete |
| 2 | interfaces as the waist | bounded; the only thing that must persist |
| 3 | per-file objects | per-file recompilation; the safe "patching" |
| 4 | semantic addressing | the headline — sound only once 1–3 hold |
| 5 | evidence + comptime caching | the compounding payoff |

## Known defects, filed

- **A `Store`/`Host` seam is missing.** The library's cache writes artifacts through
  `Host`, and a LONE FILE's host is in memory — its `.ll`/`.plan`/`.warn` vanish
  with the process while the binary reaches the real disk. **WITNESSED INERT**:
  delete the `.bin` and the build REBUILDS, so nothing consumes the wrong path. ~45
  lines; folds into the per-file work, which rewrites exactly this path.
- **`tools/census.sh` deletes `build/avra_runtime.o` and does not restore it** —
  broke linking twice in one day.
- **`@std/process` is flaky under load** — three runs of a gated tree gave rc=1,
  rc=1, rc=0, and the differing bytes are LOST CHILD OUTPUT. The gate is
  intermittently red for reasons unrelated to any landing.

## DESIGN REVIEW — PERSISTENCE vs RESIDENT (for the interface's next rung)

The step after the interface's foundation owes a review, because it is the one the
CEO reserved and because it turns on a capability the tree does not have. Its spec is
the tree's own recorded trigger:

> **`avra-8sb5.9.2`**: "`parsed`'s early cutoff covers structural fingerprints only —
> sound while compiles are ONE-SHOT; fires when anything edits."

The trigger is precise: `parsed` settles on `program_hash` (structure) while its VALUE
carries the source text and every span, so a reindent leaves later spans stale and
certified fresh. Two options follow, and the review's conclusion is that ONE OF THEM
SIDESTEPS THE TRIGGER ENTIRELY.

### The options, against the same questions

| | **RESIDENT** (a long-lived engine) | **PERSISTENCE** (content-addressed artifacts) |
|---|---|---|
| **what is retained** | the whole in-memory workspace: `Db` cells with deps/revisions, every memo family (Parsed, sigs, type facts, units, settlements), the decls tables | the IR (per unit) and the OBJECT, plus the INTERFACE — and NOT the AST, NOT the typed facts |
| **keyed by** | nothing new — the kernel's existing (family, arg) dense keys | `unit_key` (a file's bytes + the sigs it can see, by SPELLING) and `module_surface` |
| **invalidated how** | `Db.set_input` on re-read bumps the revision; the red-green walk propagates | content alone, by construction |
| **how the one-shot assumption is replaced** | it must be REPLACED: the daemon relies on `parsed`'s cutoff, so the per-consumer cutoff must be built first (the trigger) | it is BYPASSED, not replaced: the cache's keys already cover the whole value — every byte, and the sigs by spelling — so nothing depends on `parsed`'s structural cutoff, and that cutoff stays exactly as it is for one-shot compiles |
| **staleness** | the process holds state it must be TOLD about; a file changed behind its back is served stale | impossible by construction: a key that covers the whole value cannot certify a changed one |
| **shares across** | one process | processes, worktrees, machines, CI |
| **lifecycle** | new: start/stop, a process older than the binary it was built from, a client that must invalidate | none — the existing one-shot CLI, plus files |
| **risk** | MEDIUM: a stale process that answers correctly-shaped but stale results | LOW: a wrong reuse requires a hash collision |

### The conclusion, and the reason is the trigger

**PERSISTENCE.** The resident engine's most attractive property — that the incremental
machinery already exists and only needs to stop dying — is exactly what makes it a trap
here: THE MACHINERY IT WOULD REUSE IS THE UNSOUND ONE. A daemon leans on `parsed`'s
cutoff, so it must first build the per-consumer cutoff the trigger names. Persistence
does not lean on it: its keys already absorb the whole value (text and spans, since
they digest every byte), so the trigger is not a prerequisite but an IRRELEVANCE, and
`parsed`'s cutoff keeps its correct one-shot life — the same lifetime distinction that
governs `sig_hash`, one level up.

### What persistence therefore needs, in order

1. **The IR cached per FILE, keyed by `unit_key`** (built and witnessed: it moves on a
   seat change and does NOT move on an unrelated one).
2. **DEDUP, and this is not optional** — measured: splitting the IR per file without it
   took the compiler's cache from **19 MB to 210 MB**, because every module repeats
   every declaration and every static. So the disk rung (shared declarations, statics
   emitted once) is a PREREQUISITE OF PERSISTENCE, not an alternative to it.
   **AND IT IS PAID, so the rung is affordable — the after-number, measured on the
   compiler's own build (272 modules):**

   | | before dedup | **after** |
   |---|---|---|
   | whole-program module | 19 MB | **16.4 MB** |
   | per-file modules | **210 MB** (257 mods, 11x) | **17.3 MB** (272 mods, **1.06x**) |

   A 6% overhead buys the ability to re-emit ONE file instead of all of them, which is
   what the whole disk rung was waiting on. The declarations the emitter itself needs —
   the runtime rows a backend adds rather than an instruction names — are declared whole
   in every module; the USER declarations and the STATICS are what actually duplicated,
   and those are filtered to what each module names.
3. **Per-file objects**, so re-emission and recompilation are per-file too.

### What an edit should then cost

    parse + resolve + type ....... SKIPPED for every unchanged file (the interface is unchanged)
    lower + emit ................. the changed file's unit only
    link ......................... still runs, ~10s                      <-- THE FLOOR

So ~30s becomes ~10s on this machine from the IR cache alone, and the floor is the
LINK — which is why per-file objects (and eventually the linker's own incremental
mode) are the rung after, not a detail.

### The load-bearing assumption, and how it would be witnessed

The key must cover what the unit READ or the saving is a stale body. `unit_key`
over-approximates with the file's whole VISIBLE namespace, which is sound and coarse;
the refinement — the sigs actually read — is the "observed invalidation" idea, and it
becomes worth building only when the coarseness measurably costs rebuilds. THE WITNESS
ALREADY EXISTS and is the seat-change one: change only a called fn's parameter type,
the importer's bytes are byte-identical, its key moves, and an unrelated file's does
not. Persistence inherits it.

## Rung 2 — the interface, in full

**What persists.** One record per MODULE: `{ imports: [(module, the surface_key it
had)], surface: [(name, kind, sig_hash)] }`.

**Keyed by what — two levels, which is what makes it work without parsing:**

```
bytes_key(m)   = digest( sorted (relative path, bytes) of m's files )      # the LOOKUP key
surface_key(m) = digest( bytes_key(m) + [surface_key(m') for m' in imports(m)] + language )
```

The entry is stored under `bytes_key` and **validated** by recomputing the imports'
current `surface_key`s and comparing them with the recorded ones. Equal → the surface
is reused with **no parse and no resolve**; different → re-parse. `bytes_key` needs no
parse (the bytes are on disk), so the lookup itself is free.

**How the interface's identity is derived — the whole design.**

```
surface_key(m) = digest( ITS OWN FILES' BYTES
                       + THE surface_keys OF EVERY MODULE IT IMPORTS
                       + THE LANGUAGE HASH )
```

The imports are in it because **a signature can name a type from an import**: a module
whose surface says `fn f(x: util.Pair)` must move when `util.Pair` changes, and a key
over its own bytes alone misses exactly that. **A surface key that names less than the
contract reuses a stale body on precisely the change the interface exists to catch.**

**Invalidated** by content in exactly two ways — its own files' bytes, and any import's
surface. No clock, no flags, no configuration.

**The witness** (the seat-change witness, one level up; leg 2 is what a key over
own-bytes-alone would fail):

1. change a SEAT in module M → `surface_key(M)` **moves**
2. a module **importing** M → **its** `surface_key` moves (imports are in the key)
3. an **unrelated** module → its `surface_key` does **not** move *(the control)*

**Saving:** parse + resolve of every unchanged module is skipped — the resolve and
typing half (~14s) plus the parse of unchanged modules (~7s).

## Rung 3 — the pair that must NOT be equal

Two runtime rows with **the same host and the same params**:

```
avra_array_get        ret: I64   owns_result: false   lends: true    host: RtHost.ArrayGet
avra_array_get_owned  ret: Ptr   owns_result: true    lends: false   host: RtHost.ArrayGet
```

A normalizer keyed on "which operation is this" — and `RtHost.ArrayGet` is *literally
the same value* for both, which is the temptation — maps them to one identity. They are
not equal: **one borrows, one retains**, and conflating them changes the reference
count, which is a leak or a use-after-free, silently. The failing case, written before
anything builds:

```
A: a body whose read lowered as `avra_array_get`        (borrowed)
B: the same source bytes, lowered under a liveness choice that retains
   -> `avra_array_get_owned`
assert normalized_key(A) != normalized_key(B)
```

The normalizer must consult `owns_result` / `lends` / `ret`, never the host.

**And the pair a normalizer is MOST tempted by is already closed.** `a + b` vs `b + a`
is commutative by opcode, and `expr_spine/lower.av` lowers a string `+` to
`CallRt("avra_str_concat", [a, b])` and an int `+` to `Bin(Add, a, b)`. The
temptation is neutralised **by the IR's shape**, not by a convention someone must
remember — which is the strongest argument for the closed vocabulary, and why
normalization is tractable here and nowhere else.

## A KEY MUST NOT COVER GLOBAL STATE — the dual of the whole-value law

FOUND BY THE CONTROL. The three-leg interface witness was run end to end and **leg 3
failed**: an unrelated file's key MOVED. Leg 3 is the control — the leg with no link
whatsoever to the change — and it is the leg that found this.

What it is, isolated by discriminating the change:

| change | an UNRELATED file's key | |
|---|---|---|
| a BODY in an unrelated module | **stable** | so it is not "any change" |
| a SEAT (`int` -> `string`) in an unrelated module | **MOVES** | a new type enters interning |
| editing the file itself | moves | correct |

**`sig_hash` folds interned `TypeId` ORDINALS.** A `TypeId` is a dense index into the
workspace's type registry, so introducing `string` anywhere in the program shifts the
ordinals, and every signature that mentions a type shifts with them. The key is
therefore a function of the GLOBAL INTERNING ORDER, not of the program's meaning —
and an unrelated edit invalidates every file.

**THIS IS THE DUAL OF THE LAW THIS CAMPAIGN RUNS ON**, and both halves are key defects:

- too LITTLE coverage (structure without text or spans) **reuses a stale artifact** — a
  wrong binary;
- covering GLOBAL STATE (an interning ordinal, a revision, a clock) **invalidates
  everything** — a useless cache.

Neither is a deliberate choice anyone made; both are what a convenient number happened
to include. The first is a correctness failure, the second a performance failure, and
**the second is invisible to every witness that only checks a HIT is not wrongly given**
— it takes a control that says a key must NOT move.

**THE FIX, and it is bounded:** any key that outlives one run must fold a type's
STABLE IDENTITY — its spelling, or a structural digest of its shape — and never its
interned ordinal. `sig_hash` stays exactly right for the memo kernel's in-process early
cutoff, where the ordinals are fixed within the run; it is only a PERSISTENT key that
may not use it.

**BLAST RADIUS TODAY: none.** `unit_key` is consumed by `avra keys` and by nothing else,
so the defect is inert — which is why it is recorded rather than patched in a hurry.
It MUST be fixed before rung 2 builds on it, because the interface key inherits it: an
interface hash that moves whenever any new type is interned would invalidate every
dependent, which is precisely the resolve time the interface exists to save.

## Rung 2 — how the validation walk is BOUNDED, and what happens on a cycle

The recursion is real: validating M needs its imports' current `surface_key`s, and each
of those is a digest over its own imports. Unbounded, a per-module transitive closure
would hand back the resolve time the interface exists to save — and it would stay
invisible until a deep graph arrived.

**IT IS BOUNDED BY ONE PROPERTY THAT MAKES THE WHOLE WALK FREE OF PARSING:** the imports
themselves come from a record keyed by `bytes_key` — a digest of **file bytes alone** —
so every module's import list is readable without parsing anything. Therefore:

1. **A MEMO.** `surface_key(m)` is computed once per module and held in a table for the
   walk's duration. Cost per module: one small file read (`bytes_key` → its record) and
   one digest. **O(modules), not a closure per module.**
2. **AN ITERATIVE TOPOLOGICAL PASS**, not recursion — so there is no depth limit and no
   reliance on native stack depth.
3. **AND THE WALK IS THE BUILD PLAN.** Every module must be visited anyway to decide
   what to rebuild, so validation is not extra work — it is the same pass that says
   "this one re-parses, that one is reused".

**ON A CYCLE.** Two different cycles exist and only one is already refused:

- A **PACKAGE** dependency cycle is refused by the language, in its own words
  (`dependency_cycle` at `admitted`) — so a package graph the compiler accepts is
  acyclic.
- A **MODULE** cycle inside one package is *tolerated* today (two files importing each
  other is a memo cycle the kernel answers rather than recurses into), so the walk must
  tolerate it too — and a surface graph with a cycle has no well-founded digest.

**THE RESOLUTION IS TO COLLAPSE IT, NOT TO ORDER IT.** The memo doubles as a VISIT MARK;
re-entering a module that is still in flight identifies a cycle, and **every module on
that cycle takes a BYTES-ONLY key** — a digest of the members' own file bytes, with no
surface reference among them. That is **SOUND because it over-approximates**: a change to
any byte of any member moves every member's key, so nothing inside the cycle can be
reused across a real change. The cost is over-invalidation *within the cycle only*,
and cycles are rare, small, and already a shape the language tolerates rather than
encourages.


### 1. LIFECYCLE AND STALENESS — the resident engine's new failure surface

A long-lived process holding state can be WRONG about the world in ways a one-shot
process cannot, and the tree already contains the hole:

**`Memo.input` NEVER RE-READS ONCE LOADED.** Its body matches the value table first and,
on `.Present`, records the dependency and RETURNS the memoized value — the host is not
asked again. Loading is a `Missing`-only path. That is correct for ONE-SHOT, where
nothing can change under the process, and it is a SILENT STALE WORLD for a daemon: a
file edited on disk is never re-read, so the daemon keeps compiling the old bytes and has
no way to notice. THE SAME HOLE COVERS MANIFESTS — a dependency added to an `avra.toml`
is never seen — so a daemon's PACKAGE SET is stale too.

So the resident engine's first prerequisite is not the cutoff, it is that INPUTS VERIFY:
re-read, fingerprint, and let `set_input` bump the revision only when the bytes moved
(the kernel already bumps and propagates). Cheap — a read and a hash per input — and it
is the mechanism `Workspace.sources` already anticipates in a comment ("a live host
clears an entry when its file changes").

**THE INVALIDATION WITNESS FOR IT, WHICH FAILS FIRST.** Two legs, both against a resident
process: (1) change a file's BYTES and ask for a build again IN THE SAME PROCESS — the
answer must MOVE, and on today's `Memo.input` it does not; (2) add a DEPENDENCY ROW to a
manifest and ask again — the package set must grow. Leg 2 is the control.

TWO MORE SOURCES, each with its own answer: **the binary it was built from** — a daemon
IS its own generation, so a rebuilt `build/avra` leaves it serving an older LANGUAGE, and
the answer is an identity check at the request boundary and a clean exit, never a silent
answer; and **a build tool it cannot see** — clang, the runtime object — already handled
by being stateless about it, since the link plan is rebuilt per request.

### 2. THE ONE-SHOT ASSUMPTION, REPLACED vs BYPASSED

* **RESIDENT must replace it.** `parsed` settles on the STRUCTURAL hash while its value
  carries text and spans, so a reindent leaves spans stale and certified fresh. The
  recorded fix is a cutoff PER CONSUMER: `parsed` owes TWO fingerprints and a dependent's
  cutoff names which it read. Bounded, but it touches every cutoff DECISION — the
  kernel's correctness argument, not just its code.
* **PERSISTENCE bypasses it.** Its keys absorb every byte, so no consumer cuts off on
  `parsed`'s structural hash, and `parsed` keeps its correct one-shot life. Nothing in
  the tree changes — which is why it is the lower-risk of the two.

### 3. COST AND RISK, AS NUMBERS WHERE THEY EXIST

| | resident | persistence |
|---|---|---|
| prerequisite work | inputs that verify + the per-consumer cutoff + a protocol and a client | per-file IR + **dedup** + per-file objects |
| measured cost of the dedup gap | — | **19MB -> 210MB** without it (built, measured, reverted) |
| what it saves | the whole analysis, in-process | the whole analysis, across runs |
| expected edit | **~10s, link-bound** | **~10s, link-bound** |
| risk of a wrong answer | MEDIUM — a stale process answers in the right SHAPE | LOW — needs a hash collision |
| new lifecycle | a daemon to start, stop, age out | none |
| sharing | one process | processes, worktrees, machines, CI |

**THE CASE FOR PERSISTENCE, STATED FAIRLY:** it does not avoid the hard part (the analysis
must become incremental either way — the same keys serve both); it avoids TWO things —
writing a second invalidation mechanism beside the kernel's, and owning a process. Its
cost is that IR must be STORED, which is why dedup comes first.

**THE CASE FOR RESIDENT, STATED JUST AS FAIRLY:** the kernel ALREADY IS the incremental
engine — dependency capture, red-green verification, cycle detection — and a persisted
cache re-derives a coarse approximation of that graph BY HAND, which is two engines and
potentially two truths. `unit_key` is exactly that coarse hand-derivation, and it will
drift from the kernel the day the kernel changes.

### 4. THE SPRITE MODEL — where the two FAIL DIFFERENTLY

Today's landing gate is ONE-SHOT clang on a Sprite under "one COLD receipt per landing".
A resident engine is the OPPOSITE of cold, and that is not a performance objection, it is
a CONTRADICTION: a cold receipt's whole purpose is "this tree builds from nothing", so a
receipt taken through a warm process is not that receipt. Therefore: the cold receipt
must be taken by a ONE-SHOT process, daemon or not — THE RULE DOES NOT CHANGE; a daemon
would not participate in the landing path, and would ADD a service to start and age out
inside a Sprite that needs none today; and persistence composes with the model UNCHANGED,
a cache directory and one-shot processes, riding the Sprite the way the seed does.

### THE SYNTHESIS (P6) — BOTH, AT DIFFERENT SCOPES

The two are not rivals. They serve different SCOPES and SHARE THE SAME KEYS, which is the
reason to build the keys first and the reason neither choice is wasted:

* **PERSISTENCE** — CI, the landing gate, cold receipts, cross-machine and cross-worktree
  sharing. Stateless, no lifecycle, composes with the Sprite rule.
* **RESIDENT** — the interactive dev loop (an editor, `avra serve`), where the same keys
  let the kernel answer in-process with NO serialization at all.

Both sit on `unit_key` and `module_surface`. Building those first — which this campaign
has done — is the step that is right under either ruling; the ruling then chooses which
one to LAND FIRST, not which one to have.

## The DRIVER — what skips the parse, and the prerequisite it revealed

Rung 2's walk answers, parse-free, whether a module's contract still holds. The driver
is what CONSUMES that answer: an unchanged module is not parsed and not resolved.
Written down before it is built, because writing it down changed what it is.

### The shape

```
1. the walk over the program's modules      -> held (record still true) / fresh (parse it)
2. for a HELD module, the record IS its interface: mint its declarations from it
3. for a FRESH module, parse and resolve as today
4. the program is held ⊎ fresh, and every consumer cannot tell which was which
```

Step 2 is the whole of it. `ws.program(entry)` today parses every file because RESOLVE
asks for the signatures of imported declarations, and a declaration's signature lives in
its file's parse. So a held module's interface must be answerable WITHOUT its `Parsed` —
which means the record must hold enough to MINT its declarations.

### THE PREREQUISITE THIS REVEALED — the record is missing its entries

The design's record is `{ imports: [(module, surface_key)], surface: [(name, kind, sig)] }`.
**What is built writes only the first half.** `surface <key>` and `import <module> <key>`
are what validation needs; the `surface` ENTRIES — one per exported name, carrying what
that name IS — are what a driver would need to mint a declaration, and they are not
written yet. That is the first piece of the driver and it is an extension of the writer
rather than a new mechanism.

### How a declaration is minted from an entry

An entry names a name, its kind, and its seats as SPELLINGS. Loading re-PARSES those
spellings as types and interns them — reusing the type grammar that already exists rather
than inventing a decoder — so a held module's declarations are the same `Decl`s a parse
would have produced, with no body and no statements.

**AND THAT IS THE CORRECTNESS RISK, STATED PLAINLY: a held module's declarations must be
indistinguishable from parsed ones to EVERY consumer.** Typing, seating, ownership,
diagnostics and the emitter each read declarations, and any one that can tell the
difference is a defect that appears as a wrong answer rather than a slow build. The
witness is therefore a differential, not a speed: **a build with every record held must
produce the byte-identical `.ll` and the byte-identical diagnostics of a build with no
records at all.** The whole-program cache already holds that property; the driver must
extend it one level down.

### The gap that follows from it — a held module's WARNINGS

A fresh module's warnings are computed during its analysis. A held module is not
analysed, so **its warnings must be STORED beside its record or they vanish** — and a
build that quietly drops a warning is exactly the silent wrongness this whole design is
arranged against. The whole-program cache already keeps `.warn`; the per-module record
needs the same, and it is part of the driver rather than a later refinement.

### Measurement

The number the driver must move is the one the diagnosis named: **resolve plus typing is
~14s of an edit's ~35s.** With the walk holding N−1 of N modules, that slice should fall
in proportion to the modules held — and the honest check is that the `.ll` and the
warnings do NOT move at all. A speed measured without that differential is a speed of
unknown correctness, which is the one thing this campaign has refused throughout.

## (c) MEASURED: SAFE, AND NOT YET FASTER — and why the order is IR first

`(c)` is wired: before analysis, every module whose record holds contributes its exported
signatures without being parsed. **The differential is green** — a build that mints and one
that does not produce the byte-identical `.ll` and the identical diagnostics.

**AND THE SPEEDUP IS ZERO, MEASURED, NOT FEARED:**

| | check packages/cli |
|---|---|
| records present (the walk mints) | 15.8s / 15.1s |
| records gone (the walk mints nothing) | 15.6s / 14.5s |

**THE MINTING IS SAFE AND NOTHING WAS SKIPPED**, and the reason is one function:
`analyze_all` parses through `items(f)` — which a held module now answers from its record —
but it then does, for EVERY file:

    for fi in self.decls.files { let _ = self.resolved(fi.id) }        # calls parsed(f)
    for fi in self.decls.files { let _ = self.sig_diagnostics(fi.id) }
    let out = [self.analysis(fi.id) for fi in self.decls.files]       # calls parsed(f)

and `resolved` and `analyzed` both call `parsed(f)`. **So a held module is not parsed for its
items and IS parsed for its resolve** — the work is saved in the one place it is cheap and
paid in the two places it is expensive.

**AND THIS IS THE HAZARD THE DESIGN NAMED, ARRIVING AS A NUMBER RATHER THAN A WORRY:** a
registration that fills the tables and leaves the passes reaching for a parse is CORRECT AND
NOT FASTER — the differential green, every keeper green, the saving absent. It would have
looked like a finished rung.

**WHY THE SKIP CANNOT BE TAKEN NEXT, WHICH IS THE ORDER THIS ESTABLISHES.** Skipping
`resolve` for a held file means `Program.files` no longer contains an analysed entry for it,
which means LOWERING DOES NOT EMIT ITS BODIES — a program missing its functions. So the
resolve skip is only sound once a held module's BODIES come from somewhere, and that
somewhere is the per-file IR. **THE PER-FILE IR COMES FIRST, NOT THE SKIP** — and the split's
own measurement (16.4MB whole against 17.3MB for 272 modules, 1.06x) is what says it is
affordable.
