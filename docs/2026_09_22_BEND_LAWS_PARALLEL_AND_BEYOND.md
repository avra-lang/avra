# Bend, laws, parallelism, and the world after

**Status:** assessment + design proposal, 2026-09-22. Not ratified.
**Frame (2026-09-22, later):** every campaign here is a PLACEMENT of
the fibers' scope algebra (docs/2026_09_22_FIBERS_DESIGN.md §8): a
scope joins at `}`, cancels at a pause point and takes deadlines
wherever its work runs; each placement adds only the proof it needs.
Worked programs: docs/2026_09_22_FIBERS_TOUR.md Part II.
**Question asked:** can Avra build what Bend 2 ships, natively (no C
detour), and how far past it can we go?
**Short answer:** yes to all three pillars. Two are cheap because the
compiler already holds the facts Bend has to demand by contract. The
third (GPU) is a research lane with a narrow first landing.

Sources read: bend-lang.com, the bendlang/bend README and GUIDE,
`paper/BendRT.pdf`, `paper/BendTT.pdf` (all 2026-09), the FULL_SPEC
(Axes 9, 13, 14, 18, 24), COST_MODEL, COMPILER, STD_PROCESS_VISION,
the ROADMAP, and the compiler's own `core/ir.av`, `runtime/avra_box.h`,
`runtime/avra_runtime.c`. Every "Avra has X today" line below was
grepped in this tree, not remembered.

---

## 1. What Bend 2 actually is

Three pillars, one type discipline under all of them.

### 1.1 Speed: affinity, not interaction nets

BendRT §11: "Readers of the author's earlier runtimes may expect
interaction nets here; there are none." HVM is gone. What replaced it:

- A value has ONE owner. `match` consumes its scrutinee and frees the
  node on the spot. No GC. "Deallocation is compiled code."
- Refcounts exist only for `+` binders at kind `Data` (functions,
  arrays, handles can never be copied). Whole-program **share
  inference** finds which constructor types ever wear a count; the
  rest compiles to moves. **Borrow inference** finds arguments a
  callee only reads; they are lent raw. "A fold over a reused tree
  costs no count traffic."
- Counts live in a redirect word beside the node, so an unshared
  value carries no count anywhere.
- No C stack: every def is a segment of one worklist function; a
  call is a `musttail` jump; the value stack bounds recursion.

### 1.2 Parallelism: a contract, not a scheduler

One primitive, the parallel let: `a b = f(x) g(y)`. Runtime: a fixed
128x128 grid of 1024-slot rings ("the cube"), grow phase forks along
rows, work phase drains down columns, bulk-synchronous. No shared
queue, no lock, **no work stealing**. The price is written into the
language: "the program's forks must split their work evenly." §12:
"The equal-parts contract is unverified: a skewed program silently
loses its parallelism."

### 1.3 GPU: one C file is also the shader

The emitted C is compiled by clang for the CPU and by Metal/CUDA for
the device. `f!(x)` detaches a call whole onto the GPU at a sequential
program point; CPU and GPU never compute together. Works because the
evaluator has no C stack, no GC, flat memory.

### 1.4 Proofs: LAWS.bend

BendTT: one universe (`Type : Type`), no positivity check, consistent
because no closure is ever copied (affinity at kind `Data`). Proofs
are ordinary `def`s, `match` is the eliminator, no tactics, no
inference ("everything is annotated"). Recursion passes a syntactic
descent test. Dead code (types, erased args) is free and may diverge.

The product: `LAWS.bend` holds claims the human writes; `PROOF.bend`
holds defs the AI writes; `bend PROOF.bend` fails until every law is
proven. "`LAWS.bend` is `AGENTS.md` backed by proof."

### 1.5 The numbers (M4 Max, pin 2026-08-31, their suite of 12)

| executor | vs hand-written C twin |
|---|---|
| 1 thread | 0.8x to 1.5x of C |
| 16 threads | 8.8x to 12.1x over 1 thread |
| GPU (Metal) | 52x to 67x on uniform work; LOSES to 16 threads on n-queens, symbolic regression |

### 1.6 What Bend says it lacks (README, verbatim list, abridged)

No traits, no inference, no macros beyond templates, no tactics,
strings are linked lists, no separate compilation or incremental
builds, no test framework, no LSP diagnostics, no HTTP/JSON/TLS, one
GPU, one event loop, no multi-machine execution, "parallelism
requires balanced calls", numbers are Nat/U32/F32 only, "the compiler
is 99% AI-written and has not been fully audited."

Both papers state they were written by Claude Fable 5.1 from the
author's design notes.

---

## 2. Where Avra stands, measured in this tree

### 2.1 Built

- **Memory:** a pass places every retain/release by liveness. A
  parameter is BORROWED and a reading call costs no count (CLAUDE.md,
  `features/fns/tests/borrowed_params`). This is Bend's borrow
  inference, already paid for.
- **Header:** sixteen bytes before every payload, `{tag, kind, rc,
  len}` (`runtime/avra_box.h:37`). `rc` is a plain `int32_t`,
  non-atomic (`avra_runtime.c:518`). Immortal kinds (`kind < 0`) skip
  counting already. That is the hook a lane-shared kind hangs on.
- **Purity is a registry column:** `Reach { Pure, Embed, World }` on
  every runtime row (`core/ir.av:421`). The const settler refuses World
  (F2060), budgets (F2061), traps (F2062). That is a comptime evaluator
  with fuel and an effect fence, used today for `const` only.
- **Backend:** LLVM in-process, one module per file, four workers.
- **Tests:** `spec`/`given`/`then`, program tests with `eval == native
  == expected` held by `make gate` forever.
- **Derives:** `@derive(X)` over `@std/meta` generates declarations
  from shapes. `Declares`/`Records`/`Validates` annotation kinds.
- **Cost model:** `docs/2026_09_21_COST_MODEL.md`, a static cost
  derivation. Designed, not built.

### 2.2 Designed, not built

- FULL_SPEC 18.3: `parallel { }` fork-join on a pool, `spawn cpu { }`,
  `parallel_map`/`parallel_reduce`. 9.4: RC non-atomic in v1, "inferred
  atomic when CPU parallelism lands."
- FULL_SPEC 13.3: `@pure`, opt-in, compiler-verified, transitive.
- FULL_SPEC 14: refinement types staged (none, runtime `where`, SMT
  v2), `@requires`/`@ensures` runtime then SMT, `@total` v2. **Full
  dependent types ruled out** (14.3): "incompatible with Avra's
  accessibility and LLM-first goals."
- FULL_SPEC 24.2: `Arbitrary<T>` derivation, shrinking, refined-type
  aware generation.

### 2.3 Absent

- Any scheduler. ROADMAP: "Nobody owns Axis 18 ... a runtime scheduler
  is in no lane's plan."
- Any law/contract the compiler discharges for a USER program. The
  culture exists (every CLAUDE.md law is a diagnostic plus an
  adversarial test), but only for the compiler's own source.
- GPU, SIMD: LLVM multi-target bullets only.

### 2.4 The structural difference to keep in view

Bend is pure and affine; every fork is sound by construction. Avra has
mutation, `mut` seats, aliasing, and an open hole: **the borrow
channel (ROADMAP H3)** lets a write through a borrowed local report
nothing. A fork law cannot be sound over that hole. H3 closes before
parallelism ships. Not negotiable.

---

## 3. Campaign 1: LAWS (the part people are going nuts over)

**Value:** the highest. It is P1 (correct on first generation) turned
into a gate an agent cannot talk its way past.
**Cost:** 2 to 4 weeks to an honest v1. Rungs 3 and 4 are later slices.

### 3.1 The shape

```avra
law add_zero {
    for x: int
    add(x, 0) == x
}

law sorted_is_ascending {
    for xs: List<int>
    ascending(sort(xs))
}

law no_wrap_around {
    for moves: List<Move>
    !is_won(replay(start(), moves))
}
```

- A `law` is a declaration, module-wide, order-free, exportable, like
  a `const`. One `for` clause per quantified binder, then ONE `bool`
  expression. A `where` on a binder narrows its domain
  (`for n: int where n >= 0`).
- The body's REACH must be `Pure`. Not annotated: **inferred**, by
  folding `Reach` over the call graph from the registry column that
  already exists. This is the spec's `@pure`, delivered with zero
  ceremony (P3). A law that reaches the world is F-refused by a voice
  that names the row (`… reads the clock through avra_time_now`).
- Laws live where tests live: `laws/` beside `tests/`, or inline in
  the module. `avra laws <pkg>` is the gate. A package's laws are part
  of its public surface (P9): a dependency's laws are checked in the
  dependent's gate against the dependency's bodies.

### 3.2 The discharge ladder

Each law is discharged by the FIRST rung that can, and its status is
a projection of which rung did (P7: visible magic).

| rung | when | status word |
|---|---|---|
| 1. exhaustive comptime | every binder's domain is finite and small: `bool`, payload-free enums, `int where lo..hi`, `List<T>` up to a bounded length | `proven` |
| 2. generated cases + shrinking | any domain with a derived generator (`@derive(Arbitrary)` from `@std/meta`; the derive framework is the macro) | `checked (n cases)` |
| 3. SMT | the scalar fragment: int/bool/float arithmetic, comparisons, payload-free enums, no lists | `proven` |
| 4. open | none of the above | `open` and the gate is red |

Rungs 1 and 2 run on the settler (F2060/61/62 machinery) and the native
`avra test` runner respectively, both existing. Rung 3 is FULL_SPEC
14.1(c), Z3 through the extern host, a later slice.

**The honest claim.** `proven` is only spoken by rungs 1 and 3. A
`checked` law is a checked law and the render says so. We never print
"mathematically impossible" for rung 2. Bend's laws ARE proofs; ours
are proofs where a decision procedure exists and checks elsewhere. For
an LLM this is the better loop: Bend requires the model to write a
tactic-free dependent proof (its README: "proving theorems takes extra
effort"); Avra hands the model a shrunk counterexample.

### 3.3 The agent loop

```
# AGENTS.md / CLAUDE.md
- run `avra laws` before committing; a red law is a stop
- a law you cannot satisfy is a question for the human, never an edit to laws/
```

A law file is the human's; the compiler refuses a commit hook that
edits it? No: the compiler cannot see git. What it CAN do is what the
receipt culture already does: `avra laws` writes a receipt into
`build/` naming the law set's fingerprint; `make gate` refuses a
receipt over a different law set. Same mechanism as `receipt_trusts`.

### 3.4 Diagnostics (registry rows, F-codes are projections)

| kind | code | words |
|---|---|---|
| law.reach | new | "a law reads the world through `<row>`" |
| law.type | new | "a law states a `bool`, this is `<T>`" |
| law.domain | new | "`<T>` has no generator and no bound — add `where` or `@derive(Arbitrary)`" |
| law.false | new | "`<name>` fails: <shrunk binding>" with the binding as a structured fix payload |
| law.budget | reuse F2061 | "`<name>` ran past its budget" |

### 3.5 Dogfooding is the proof

The compiler is the first user. `eval == native` for every corpus
program IS a law. `fingerprint(a) == fingerprint(b) => a == b` over the
enumerated splice shapes IS a law (the ARITY law, currently a Python
keeper). `fmt(x) == x` over canonical files IS a law. Each of those
moves from `tools/*.py` into a `law` in the package that owns it, and
CLAUDE.md shrinks by exactly the laws that became code. That is the
measure of the campaign: **how many prose laws became declarations.**

### 3.6 Slices, in order

1. `law` grammar + feature dir + typing (bool, Pure reach fold).
   Program tests. `avra laws` listing them as `open`.
2. Rung 1 on the settler; `proven` status; F2061 reused.
3. `@derive(Arbitrary)` in `@std/testing`; rung 2 with shrinking;
   `checked (n)`; the counterexample voice.
4. Receipt + gate integration; AGENTS.md line; the compiler's first
   three prose laws converted.
5. Rung 3, SMT, as its own lane.

New keyword `law`: the four-generation build ladder + `make seed`.

---

## 4. Campaign 2: CPU fork-join, native

**Value:** high. Sixteen cores for one keyword, and a differentiator
over Bend on day one (no balance contract).
**Cost:** 4 to 8 weeks after H3 closes.

### 4.1 The shape

Two spellings, both from FULL_SPEC 18.3, both lower to one IR shape.

```avra
parallel {
    let a = hash(file_a)
    let b = hash(file_b)
}
// a and b are bound after the block

let hashes = [hash(f) par for f in files]
let total  = [cost(x) par for x in xs].sum()
```

`parallel { }` IS A SCOPE, the cores placement of the fibers' `all
{ }`: a trapping lane cancels its siblings and re-raises at `}`, and
the same deterministic test mode explores its schedules.

`par for` is the Avra-native form: the compiler halves the INDEX SPACE
recursively down to a grain, so the balance Bend asks the programmer
to keep is met by construction for data-parallel loops. Every leaf
writes its own disjoint slice of the answer list: no contention.

### 4.2 The fork law (what the compiler already knows)

A forked body must satisfy, and each refusal is a named voice:

1. **Pure or Embed reach.** No World row inside a fork. Same fold as
   laws (§3.1).
2. **No `mut` capture, no write through a seat.** The typer holds both
   (`TypeFacts.captures`, `SeatMark`).
3. **Arguments are borrowed.** Already the calling convention. The
   parent is blocked at the join and no other writer exists, so a
   borrowed read is a read of stable memory.

Bend demands 1 to 3 by purity + affinity. We compute them from facts
the compiler already records (P10).

### 4.3 Memory across a fork

- A child that only READS its arguments does no count traffic. Already
  true.
- A child that KEEPS an argument (stores it, returns it inside its
  answer) retains a box the parent also holds. That retain must be
  atomic. Two designs, pick by census:
  - (a) **region flag:** the memory pass knows it is emitting inside a
    forked region; `Retain`/`Release` there lower to the atomic rows.
    Cost lands only inside forks.
  - (b) **kind bit:** at the fork, each argument root's header is
    marked lane-shared (like immortal kinds skip counting, shared kinds
    count atomically). Cost is a walk at the fork. Transitive marking
    is a walk over the whole value, so (a) is the default; (b) is what
    the spec's "inferred atomic per type" becomes if (a) measures badly.
- Each lane owns its free lists (`avra_box.h`'s size classes, per
  thread). A box freed on a lane other than its minter goes to the
  freeing lane's list; the allocator does not care.
- A REDUCTION TREE IS FIXED BY THE DATA LENGTH, never the worker
  count, so `[x par for x in xs].reduce(0.0, add)` answers the same
  bits on 1 core or 64 (floats do not reassociate). A `law` proving
  associativity (ints) licenses reshaping the tree: the law unlocks
  the optimisation.
- The join receives OWNED answers. `parallel { let a = … }` binds
  them into the parent scope as ordinary owned registers.

### 4.4 IR (by the vocabulary protocol)

One new control shape, justified as a control shape AND a memory
boundary:

```
/// A forked call: the callee runs on another lane; `dst` is the
/// TASK, not the answer. Arguments are lent exactly as `Call`'s.
Spawn(@dst dst: Reg, @body callee: string, @seats @lent args: List<Reg>)
/// The answer of a spawned task, owned. Blocks the parent.
Join(@dst @owns dst: Reg, task: Reg)
```

Every consumer pays: interp runs `Spawn` as a `Call` and `Join` as the
identity (so `eval == native` holds by construction and the
differential still bites), memory treats `Spawn` as `Call` for lending
and `Join` as an owned mint, ir_text prints them, llvm lowers to the
pool rows, facts validates the rows. `par for` lowers to a recursive
halving fn the compiler mints, spawning both halves, joining, writing
its slice.

### 4.5 Runtime

- A pool of `num_cpus` workers in `avra_runtime.c`, opened at the
  first `Spawn`, Cilk-style: per-worker deques, **stealing**. We have
  no GPU lane constraint yet, so we can afford what Bend cannot, and a
  skewed fork degrades gracefully instead of silently idling. When the
  GPU lane lands (§5) the same tasks can be dealt into a wave-structured
  driver; the IR does not change.
- A task is a headered box: `{fn address, args, answer slot, remaining}`.
  Delivery is one release-decrement; whoever reaches zero runs the join.
- Trap on a lane: first failing lane writes the trap word, every lane
  polls it at its next task boundary, the parent re-raises. Exit 2 as
  today.

### 4.6 Measure

- `make census` gains a per-lane column. Retain/release counts inside
  forks are the number to watch.
- Port Bend's `bench/runtime/` twelve programs with their C twins into
  `bench/` here. Their pinned checksums become our `.expected`. Three
  numbers per program: 1 thread vs C, 16 threads vs 1, and later GPU.
  This is the FIRST action of the whole plan: sequential parity is
  measured before anything parallel is claimed.

### 4.7 Slices

0. Close H3. (Owner: the mutation lane.)
1. Bench port, sequential numbers published in this doc.
2. `Spawn`/`Join` in the IR, interp + ir_text + facts; runtime pool;
   `parallel { }` over named fns only.
3. The fork law voices; `par for`; the halving mint.
4. Atomic retains by region flag; census column; the 16-thread numbers.
5. `on .cores { }` (FULL_SPEC 18.3's `spawn cpu`, as a placement) and
   `Task<T, E>` on the same pool — the fibers' Task, not a second one.
Prerequisite: fibers F2 (every block a scope) and F3 (the
deterministic scheduler), so forks inherit both.

---

## 5. Campaign 3: GPU, native, no C

**Value:** the demo. **Cost:** months; a research lane, not a slice.
**Constraint from the owner:** no C detour. Avra emits LLVM; that is
the route.

### 5.1 The kernel fragment

Do not try to run the whole language on the device. Bend pays for that
with a stackless flat evaluator and loses on every divergent
benchmark anyway. Carve the fragment where its wins are:

A `par for` body is a **kernel** when the typer can certify: scalar
arithmetic and comparisons only, reads of flat numeric lists (a
`List<float>` is one contiguous block already), no allocation, no
`CallRt` beyond the math rows marked `Embed`, no recursion. The same
`Reach` fold plus one new fact (`allocates`) answers it. Mandelbrot,
n-body, game of life, k-means are all in the fragment.

### 5.1b Vectors first, then the device

The fragment has TWO targets, and the nearer one ships first: SIMD
lanes on the CPU (LLVM's vector types, no new backend), then a device.
Both are driven by one rule: a `par for` over the fragment either
vectorises or `explain` names the line that stopped it. Vectorisation
is a CHECKED CLAIM, never a silent autovectoriser miss, and never an
intrinsic the author writes by hand.

- FUSION: two `par for`s over the fragment in sequence (softmax's
  exp then divide) fuse into one pass. Legal because the fragment is
  pure; reported by `explain --kernels`.
- PLACEMENT is a scope property: `on .gpu { }` pins, unpinned work is
  placed by the cost model (a 10-row loop stays on the cores because
  a launch costs more). The refusal when a pinned body leaves the
  fragment names the row: "allocates through `avra_array_push`".
- SHAPES: `Tensor<float, [R, C]>` with const-generic shapes settled at
  comptime, so `matmul(w, a)` is refused at the seat with the fix.

### 5.2 Targets

| device | route | status |
|---|---|---|
| NVIDIA | LLVM NVPTX target from our own module, `cuda` driver rows through the extern host | native, first |
| AMD | LLVM AMDGPU target, HIP rows | native, second |
| Apple | no public LLVM Metal target. LLVM SPIR-V target + a cross to MSL, or Metal's own compiler on generated MSL text | not native; the one place Bend's C detour buys what we cannot |

Honest note: for Apple silicon the "one file is also the shader" trick
has no LLVM-native equivalent today. The lane's first deliverable is
CUDA, on the machine the benchmarks will be run on. Apple is a second
decision once the fragment exists.

### 5.3 Memory

- v1 kernels allocate nothing. Inputs are flat lists mapped as device
  buffers (unified memory where the chip has it, a copy where not).
  The answer list is preallocated by the parent, one slot per element.
- Kernels never touch a header. The headered box law holds because the
  device only ever sees a payload span the host lent it.

### 5.4 Slices

1. The `allocates` fact and the kernel-fragment voice ("this body
   allocates through `<row>`, so it runs on the CPU").
2. NVPTX emission for a fragment body; the `cuda` rows; a `par for`
   dispatched to the device when `--gpu` is on and the body qualifies.
3. Bench numbers on the four uniform programs.
4. Apple decision.

---

## 6. Sequential parity (the quiet campaign)

Bend's sequential story is 0.8x to 1.5x of C by moves-not-counts. Ours
is borrowed params + liveness. What we do not have and Bend does:

- **Share inference**: counts only on types that are ever shared.
  Ours: every managed box carries `rc`. A whole-program pass marking
  never-shared types and eliding their retain/release entirely is a
  memory-pass slice, measurable by census. Perceus-style reuse (free
  then allocate the same size class in one step) is the sibling.
- **A packed word for one-field constructors**: a `Leaf{x}` never
  touches memory. Ours: named types are already FLAT records over one
  field ("a name is free at runtime"). Extend to payload-carrying enum
  variants of one scalar field.

Neither is claimed until the bench port (§4.6) says where we stand.

---

## 7. Pushing further: the world where Avra is the lingua franca

Bend's thesis is right and its scope is small: "humans will stop
writing and reading code, but we still need an ambiguity-free language
to communicate our intents to the AIs." It answers with one artifact,
a law file over pure functions, for one program at a time. Avra's
principles (P2, P5, P9, P10, P12, P13) already describe the rest of
that world. Here is what it looks like when every layer is written by
agents and adjudicated by one compiler.

### 7.1 The human writes laws and budgets; agents write bodies

The unit of human intent becomes: a `law` (what must hold), a **cost
budget** (what it may cost: `docs/2026_09_21_COST_MODEL.md` already
derives cost statically; a budget is a law over the cost projection,
"`handle_request` allocates O(1) per call", "this endpoint's work is
under 2 ms of derived cost"), and a **boundary** (P9: the types at
the seam). Everything under those three is the agent's, and the
compiler is the reviewer that never tires: a red law with a shrunk
counterexample, a red budget with the allocating line named, a red
seat with the fix payload. Code review as a human activity is
replaced by law review.

### 7.2 Laws compose across boundaries

A package ships its laws. A service's API is a set of laws over its
request and response types, and P2's "services negotiate contracts at
runtime" is those laws checked at the boundary when two agent-written
services meet: the caller's assumptions are laws it asserts, the
callee's guarantees are laws it exports, and the compiler (or the
runtime at a `dyn` seam) proves one implies the other or refuses the
call. That is the piece nobody has: Bend's laws stop at the program's
edge; ours cross the wire because the wire is a typed seat already.

### 7.3 Distribution is the same word

`parallel { }` over a thread pool (§4), over the process substrate
(`@std/process`'s `parallel(limit)`, built), and over machines
(`@std/net`, built) is ONE fork-join with three placements. The cost
model decides placement: a task whose derived cost is under the
transfer cost stays local. P13 (collapse dev/ops/infra): the deploy
manifest, the permission set (FULL_SPEC 13.6 already infers it from the
import graph), and the placement are projections of the same program.
Bend lists "no multi-machine execution" as a limitation; for a
services language it is the whole point.

Concretely, on the fibers' algebra: a CLUSTER is an owner value, as a
server is (`cluster.spawn(on: rank(r)) { }`), so remote tasks join at
`}` and die with their owner. The placement's proof is PLAIN DATA:
a capture holding a local handle (`Db`, `Cell`) is refused, because
value semantics make every other crossing a copy and serialisation is
that copy. A dead node or a straggler (`within`) is one failure with
one recovery: `durable "run" { }` checkpoints at its `}` and restarts
the failed step with the ranks still alive. Elastic training is
cancellation plus a durable scope, not a framework.

### 7.4 AI/ML on Avra

What a training stack needs, mapped to what exists or is designed:

| need | Avra answer |
|---|---|
| tensors | a value category with a flat payload (`List<float>` is one block today); shapes as const generics settled at comptime, so a shape mismatch is F-refused at the seat, which is the useful half of dependent types without the half 14.3 rules out |
| autodiff | `@derive(Grad)` over `@std/meta`: the derive framework IS the macro system, and a gradient is a rewrite of a pure body, which the Reach fold certifies |
| kernels | §5's fragment, dispatched per `par for`; the math rows (`Embed`) are the device vocabulary |
| data | `table<Row>` literals exist; `@std/sqlite` and `@std/json` are built; a dataset is a typed table with laws over it |
| training loop | `par for` over batches, a reduction, a `mut` seat for the parameters, the fork law guaranteeing the only writer is the join |
| serving | `@std/http` (built) over the same model value; the model artifact is a build product in the content-addressed cache (the cache/cas campaign) |
| foreign accelerators | the extern host + `RtSig` rows: cuBLAS, MPS, oneDNN arrive as rows with `Reach` and `Box` columns, and `make externs` keeps them honest |
| reproducible training | fixed reduction trees (§4.3): gradients are bit-identical across 1, 3 or 32 ranks |
| failure and stragglers | scopes: a dead rank fails the step's `all`, `within` turns a straggler into the same failure, `durable` restarts from the checkpoint |
| overlap of exchange and compute | a hint (H0302) with the fix, from the same independence fact as fibers' H0301 |
| testing a cluster | the deterministic scheduler simulates N nodes × G devices in one process on virtual time, faults injected by seed |
| laws about models | "loss is non-increasing over a step at lr 0", "the softmax sums to one", "no NaN leaves the forward pass": rung 2 checks today, rung 3 proves the scalar ones |

The language does not need a tensor type in `core/`. It needs the
kernel fragment, const-generic shapes, and derives. Everything else is
a package.

### 7.5 The compiler as the only reviewer

In an all-agent codebase the compiler is the sole entity that reads
every line. So every review activity migrates into it, in this order,
and each one is a thing this tree already does for itself:

1. Laws with counterexamples (§3).
2. Cost budgets as laws over the cost projection.
3. Receipts: a package's gate is part of the package, and a consumer
   refuses a dependency whose receipt does not cover its law set.
4. `explain`: the compiler answers "why is this here" from its facts,
   which is what a human reviewer asks first.
5. Docs, tests, agent tool definitions, permission manifests, deploy
   plans: projections of one source (P12), never written twice.

### 7.6 The measure of the whole program

The CLAUDE.md of this tree is 1,500 lines of laws in prose, each one a
diagnostic and an adversarial test. Every one that becomes a `law`
declaration is a line that leaves the prose. When the file is short,
the compiler holds the doctrine and the agents inherit it by compiling
against it. That is what "lingua franca" means operationally: the
language carries the standards, so a new agent does not have to be
told them.

---

## 8. Sequence and ownership

| order | campaign | gate | blocked on |
|---|---|---|---|
| 0 | fibers F1–F3: runtime core, scopes, deterministic scheduler | docs/2026_09_22_FIBERS_DESIGN.md §6 | nothing |
| 1 | bench port + sequential numbers (§4.6 slice 1) | numbers in this doc | nothing; one day |
| 2 | LAWS slices 1 to 4 (§3.6) | `avra laws` green over the compiler's first three converted laws | nothing |
| 3 | H3 close | ROADMAP H3 | the mutation lane |
| 4 | fork-join slices 2 to 5 (§4.7) | 16-thread numbers on the bench | 0, 3 |
| 4b | SIMD: the fragment on vector lanes, fusion, `explain --kernels` (§5.1b) | vectorised bench programs | 4 |
| 5 | GPU slices 1 to 3 (§5.4) | CUDA numbers on the four uniform programs | 4 |
| 6 | LAWS rung 3 (SMT) | scalar laws `proven` | 2 |
| 7 | share inference (§6) | census delta | 1 |

New keywords (`law`, `parallel`, `par`): each rides the four-generation
build ladder and a `make seed`. `spawn`, `channel`, `select`, `await`
are reserved today (`resolve.av:26`); `parallel` and `law` are not,
and claim their words when their grammar fragments land.

## 9. Open questions for the owner

1. `par for` versus `parallel for`: the short word reads as a
   comprehension mark; the long one matches the block. One word.
2. Does a `law` live in `laws/` (Bend's file convention, human-owned by
   convention) or inline beside what it governs? Proposal: both, with
   the receipt keyed on the union.
3. Apple GPU: SPIR-V cross, generated MSL text, or wait. Decide after
   the CUDA numbers exist.
4. Should a `checked` law ever be allowed to gate a release? Proposal:
   yes, with the word `checked` in the receipt, never `proven`.
