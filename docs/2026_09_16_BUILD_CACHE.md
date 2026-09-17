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