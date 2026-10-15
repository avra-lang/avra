# Memory, ownership and representation — RC with non-RC speed
2026-10-15 · design note (draft) · CHANNELS lead, on the owner's questions

## The premise
Refcounting is a **semantic** choice (deterministic destruction, no collector, no
pause, nothing to link when nothing needs it). The **counts** are a **codegen**
choice. Keeping the first while paying for the second only where unavoidable is a
solved design — this note names it, says what Avra already has, and what is missing.

## Three separate overheads (they are usually conflated)
| | what it is | addressed by |
|---|---|---|
| **(a) counts** | a retain/release per hop | **RC elision** (below) |
| **(b) headers** | 16 bytes (tag, kind, rc, len) before every payload | **representation** (a layout choice) |
| **(c) indirection** | a pointer per element vs inline storage | **specialisation** (a layout choice) |

**RC elision removes (a) and nothing else.** A stream of boxed records pays (b) and
(c) no matter how perfect the counts are. So the two questions are separate, and
Avra needs an answer to both.

## Part 1 — RC semantics, ownership-typed codegen (the (a) answer)
**Perceus** (Reinking/Xie/de Moura/Leijen, PLDI 2021; the runtime behind Koka) shows
RC can be GC-competitive — ~**1.0 counts per allocation** vs naive ARC's 2–4× — by
moving the decisions to the compiler:
1. **Borrow inference** — infer which seats are borrowed, so a read-only call emits
   ZERO counts. **Avra has this** (`A PARAMETER IS BORROWED`; callee-cleans cost 1.3
   billion counts in one `check` and 15% of its CPU before removal).
2. **Dup/drop specialisation** — emit a count only where a value is actually
   duplicated or dropped; a value whose last use is a store into a fresh slot is a
   **MOVE**. **Missing.**
3. **Reuse** (FBIP, "functional but in-place") — hand a **dying** value's storage to
   its replacement, so the heavy path is no free + alloc at all. **Missing.**

With all three, ownership is **inferred** — the author writes plain code, the
compiler proves borrow/own/consume exactly as a linear-type system would. That is
linear-type performance with refcount semantics and no ceremony (P6: not a trade).

**Avra today:** ✅ borrow, ✅ uniqueness (`rc == 1` → in-place write,
`avra_cell_unique`), ✅ unboxed scalar slabs; ❌ last-use moves, ❌ reuse, ❌ weak
captures (CYCLE leaks — 922 MB in the test binary, sugar backlog).

## Part 2 — Representation (the (b)+(c) answer, and where the owner's instinct is right)
A stream of values that are all boxes pays the header and the indirection whatever
the counts do, and **this generalises far past channels** — lists, maps, queues,
streams, every container of records.

The substrate already has the tools (`runtime/avra_box.h`):
- an `AvraArray` is a **slab of `int64` cells with one mark byte each** — scalars are
  **unboxed** ("a nullable int lives in one word and one bit, with no box");
- a managed element is a **pointer + a mark**, not a fresh box;
- static aggregates are laid-out globals (`Ins.StaticAddr`) — the binary's own data;
- a record of ONE scalar field **flattens** to the field.

What is missing is **generality**: the layout is chosen per shape today, not by rule.
The design rule to adopt:
> **The element type decides the representation, and the compiler picks the cheapest
> layout that preserves the semantics.**
- unmanaged (`int`/`float`/`bool`/`Ptr`) → a **slab** of that width;
- a record of scalars → a **flat struct array** (AoS), not pointers to boxes;
- a managed value → a **handle** (pointer + one count) — the honest cost;
- a **stream** → a ring that carries the element's layout, so a producer and a
  consumer share one buffer with **no per-item allocation at all** (the SPSC ring);
- and an **escape hatch** where it matters: a way to force a layout at a seat,
  because a rule with no exception is a rule people work around.

This is P12 (one source of truth, many projections) applied to memory: the value is
one thing; its **layout is a projection**.

## Part 3 — Where the passes live, and whether to iterate ("rolling")
Passes have ONE signature (`pass(parsed, ...upstream) -> Facts`), each OWNS its fact
tables (and its diagnostics), and `analyze` is the **only** place the order exists.
So this work is not one pass but a small family, and their homes are:

1. **An `Ownership` facts table** — per register: borrowed / owned / dying /
   shared. **Consumed by memory**, not merged into it (a fact table owns its facts).
2. **The memory pass** (`compiler/memory/memory.av`) is where counts are PLACED —
   so dup/drop specialisation and last-use moves are an enhancement of *it*, driven
   by (1).
3. **A cell read-modify-write pass** — recognise `let t = c.get(); …; c.set(t)` and
   lower it to an in-place update behind a uniqueness check. This removes the
   **whole-buffer copy** that makes a `Cell`-held collection quadratic, and it is
   the P6 collapse: value semantics stay, the copy moves from read to write and
   disappears when unique.
4. **A reuse pass** (last) — pairs a dying allocation with the new value's shape.

**On iterating ("rolling"): yes, and Avra is unusually well placed for it.** Some
optimisations feed each other (inlining exposes constant folding exposes inlining),
so a pass manager runs a small pipeline to a **fixpoint**. The trap is that
iteration is unbounded and its cost is compile time. What makes it cheap here: the
passes are **pure queries over a memoized DB**, so re-running one whose inputs did
not change costs a cache hit — iteration is almost free in this architecture
precisely because of the DB campaign. So: iterate where the gain compounds, bound
the rounds, and measure the compile-time cost with the same instruments
(`explain --stats`, `make census`) as the runtime cost.

**Guiding principle, from the campaign's own ledger:** *price the frame-to-body
ratio before paying.* These are optimisations paid for in COMPILE time to buy RUN
time — so each one needs a counted before/after on both sides, never a stopwatch.

## Part 4 — The measurement that decides the order (all three counts)
One channel drain, measured as THREE per-item counts — **allocations, retains +
releases, copies** — with the sites for whichever dominates:
- dominated by **copies** → the cell-RMW pass (§Part 3.3) + the in-place API;
- dominated by **counts** → ownership elision (§Part 1.2–3);
- dominated by **allocations** → reuse (§Part 3.4).

**All three are wanted in the end; the census decides the ORDER, not the choice.**

---

## Part 5 — Performance by default, or: remove the foot guns
A foot gun here is not a mistake an author makes; it is a **shape the language makes
easy that costs more than it looks**. The census found one in its purest form:
`removed_at(0)` reads like "take the first", and it rebuilds the whole list.

**The six ways a foot gun gets in, and the answer to each.**

1. **An innocuous NAME on an expensive verb.** `removed_at(0)` vs a ring's `pop`.
   → The fast path takes the ordinary name; the expensive one is named for its cost.
2. **A DEFAULT that is slow.** A buffer that shifts on every pop.
   → **The type says its cost: a queue IS a ring.** If the carrier's buffer were a
   `Ring<T>`, the shift could not be written. Type = contract = cost.
3. **A LAW THAT IS PROSE, NOT A RULE.** *"A read-modify-write through `get` is a
   copy"* was already written in this tree — and the carrier broke it anyway,
   because prose is read by people and enforced by nobody. The campaign already owns
   the cure: **`rule` declarations, found by `avra check`.** Every foot gun the
   language can STATE becomes a rule (a rule that fires on every run, not a
   baseline entry).
4. **A SCALING PATH NOBODY MEASURES.** The benchmark's bounded drain hid the
   quadratic for months: at cap 64 the rebuild is ≤64 cells and looks linear.
   → **Every hot verb gets a SCALING row (1k/10k/20k) and the gate refuses a
   ratio.** A foot gun that appears in a scaling row cannot ship.
5. **A REPRESENTATION THE AUTHOR HAS TO CHOOSE.** Asking a person to pick a slab,
   a ring or a handle is asking them to be a compiler.
   → **The element type and the use decide the layout** (Part 2); plain code is fast
   code because the compiler picked.
6. **NO ESCAPE HATCH.** A rule with no exception gets routed around.
   → The escape hatch is explicit (P8) — and *named*, so the slow shape is a
   deliberate, visible choice.

**The doctrine in one line:** *the default is the fast path; the slow path is named,
measured, and refused where the language can state it.*

**And the corollary that keeps it honest:** a foot gun removed at the TYPE or the
VOCABULARY disappears for every caller; one removed in a document disappears for
none. Prefer the type, then the verb, then the rule, then the measurement — and
documentation last, because documentation is the only one of the four that nobody's
tooling reads.

## Part 3 addendum — where in the pipeline the family sits
`parse → resolve → typing → lower → [the family] → memory → backend`
- **`Ownership`** (facts) is computed over the LOWERED body, before memory places
  counts.
- **The cell read-modify-write** is a canonicalisation on the lowered body, before
  memory — it changes WHICH instructions exist, so memory must see the result.
- **`memory`** consumes `Ownership` and places counts.
- **`reuse`** runs last, pairing a dying allocation with its replacement's shape.
Each owns its fact table and its diagnostics; `analyze` is still the only place the
ORDER exists, and iteration to a fixpoint is bounded and priced (Part 3).

---

# Part 6 — Events and contracts: the interface model
(2026-10-15, from the CHANNELS campaign's review; the same primitives as Parts 1–5,
seen from the CALLER's side)

## There is no event system
An `on` seat **is a fn field**: `on click(x: int)` ≡ `click: fn(int) -> void? = null`,
and `button { on click { … } }` ≡ `button { click: (x) -> … }`. So `on` is a
DECLARATION spelling for a seat the **user** fills — a button cannot know what a click
means — and it is the host seam and may carry a replaceable default. A **method** is
the component's OWN behaviour. **`on … { pattern -> … }` already gives match-style
dispatch**, because a one-seat fn field takes a body of arms.

## Two mechanisms, ONE spelling
There are **UI events** (function calls) and **distributed events** (queues); the
language unifies the SPELLING, never the mechanism. **The seat's TYPE says which:**
a **fn seat** is a synchronous CALL the host or a peer makes; a **channel/queue seat**
(`Sink<T>`, `worker { reads: q }`) is a SEND with that queue's contract.

## Wiring: one operator
A send is a call (`sink(x)`), so it is the same operation as piping: **`|>` and
nothing else** — no second arrow, one direction. `x |> f` yields a value;
`x |> charges.sink` yields a **verdict** (`Posted`/`Full`/`Ended`), so backpressure is
readable at the pipe. **A connection is a NAMING** (a field), so it needs no operator:
`worker settle { reads: charges each: pay }` IS the connection.

## Contracts are TERMS (values), never annotations
An annotation is for a **mark that is not a value** (`@sealed`, `@owns`, `@derive`).
A contract is a **setting**, so it is an argument the author writes, the compiler can
reason about, and `check` can judge:
```avra
let keys   = channel<string>(1, overflow: .latest)     // keep the newest (coalesce)
let cmds   = channel<MotorCmd>(0)                      // 0 = rendezvous: handed over
let frames = every(fps(60))                            // a clock is a SOURCE
```
TERMS to add: `overflow` (`.park`/`.latest`/`.drop_oldest`/`.drop_newest`/`.fail`),
`order` (`.fifo`/`.by_key`), `priority`, `remote`, `trace`, `sample`.

## Three tiers make a contract the LANGUAGE'S, not a doc's
1. **Fields/terms** — the values above.
2. **`check`** — value laws **written by the library author in Avra**, run by the
   compiler at each instance, each diagnostic spoken there (`capacity >= 1`; "a fate is
   named when `delivery` is `exactly_once`").
3. **The typer** — laws needing TYPES/signatures (`flow.no_fate`: a failing handler
   needs a `dead:`, which a `check` cannot see).
A `rule` (`avra check`) is for cross-cutting SHAPES no single declaration owns
(`lists.removed_at_front`). **The door refuses the NEW shape, the `check` judges the
instance, the type refuses the wire** — the Lego fit, enforced.

## Fan-out: two types, two honest semantics
A **channel distributes** (two consumers compete, one item each — the WORK-QUEUE
semantic). An **`on` seat BROADCASTS** once `heard_twice` is lifted, so N handlers
attach in order (a logger, a counter, the app — the SIGNAL semantic). Cross-COMPONENT
fan-out is **composed** (an owner forwards), never built in.

## The six contracts every surface argues about
`capacity/backpressure` · `delivery` · `ordering` · `priority` · `lifetime/restart` ·
`observability bind`. A browser, an ISR, a motor loop and a remote queue differ almost
entirely in WHICH VALUES of these six they need — not in the shape. So the six are the
surface's contract, and they are terms.

| surface | additionally needs |
|---|---|
| UI | `overflow: .latest`, `every(fps)` + paint-at-frame, cancel-the-stale, dynamic children |
| systems/kernels | the **no-runtime path**: fn seats only, no task/channel/allocation (held by `make footprint`) |
| robotics | `priority:`, a stated worst case (the terms ARE the bounds), `on fault`, `supervise`, `sample` |
| distributed | `order: .by_key`, `remote:` (same type, one field), per-hop flow control, `trace:` riding the `Delivery` |
| all | **`record(src)`/`replay(path)`** — one construct; makes every other guarantee testable |
| all | **`supervise { restart:, budget: N within d, escalate: }`** — a declaration, not a try/catch |

## Part 7 — The intermediate adaptor (a compiler-inserted queue)
Where `a |> b` does not fit — the source's terms differ from the sink's — the compiler
may **insert an adaptor between them**, visibly. It is the same shape as an implicit
widening (`int` into a `float` seat inserts a conversion); here the inserted thing is a
QUEUE.

**Use cases:** a rate mismatch (a fast producer, a slow consumer → a buffer); a
locality boundary (two cores or two machines → a crossing queue); a sync→async
boundary (a sync caller into an async handler → a task + a ring); failure isolation
(the consumer may die → a durable queue); batching (one-at-a-time into a batch
consumer); lifetime decoupling (the producer must finish before the consumer starts).

**THE LAW — the compiler may insert an adaptor ONLY where an adaptor can strengthen
the fit, and must REFUSE where it cannot:**
- **Adaptable axes** — capacity/rate (a buffer), locality (a bridge), sync/async (a
  task). An inserted queue is TRANSPARENT here.
- **Non-adaptable axes** — `delivery` (nothing invents at-least-once from
  at-most-once) and `ordering` (nothing re-invents FIFO from unordered). These are
  **refused by name**, never silently bridged.
An inserted adaptor **changes what is observable** (a queue can buffer, reorder
nothing, but it DOES add a hop and can drop where its terms allow), so it is spoken:
`avra explain` names every inserted adaptor and its terms, and a program that would
need one where the fit is unbridgeable is refused at the wire. **P7: the magic is
visible; P8: the adaptor is the explicit form of what the compiler would insert.**

---

# Part 8 — The crossing: components on different machines, and production
(2026-10-15 · the deployment half of Part 7)

## A wire between machines has no queue in it
An author writes a SOURCE into a SEAT, and that is all:
```avra
// machine A: the sensor site                 // machine B: the analysis site
component feed { fn readings() -> Source<Reading> { … } }
worker analyse { reads: feed_readings, each: classify }

feed.readings |> analyse.ingest      // Source<Reading>  |>  a seat — one pipe, no queue named
```
**Locality forces the async.** A same-machine seat can be a direct call; across a machine
(LATENCY, a separate failure domain) it CANNOT be — so the compiler **generates the
crossing**: serialize, transport, de-serialize, deliver. That generated thing *is* a
queue (a transport always buffers), and it is **visible** (`avra explain --topology`:
the graph, the machine boundaries, every generated hop and its terms).

**"Smart" has a precise meaning, and it is bounded.** The compiler derives the terms it
can PROVE from the endpoints (locality, sync/async, the value's crossability, the sink's
declared `delivery`/`order`) and **never invents what it cannot see**:
- it never chooses a **buffer size** (a rate is dynamic — a buffer is the author's
  decision);
- it never fabricates a **guarantee** — `delivery` and `ordering` are NOT adaptable, so a
  wire that needs them un-bridged is **refused by name**, not silently upgraded;
- it never copies a value that **cannot cross** (`flow.crossing` — a `Sink`, a closure, a
  fn value). **The refusal is the feature:** the adaptor is insertable only because the
  compiler already knows what may cross.

## The deployment terms
Placement is a TERM, so topology is data:
```avra
queue<Reading> uplink { delivery: .exactly_once, order: .by_key, remote: "site-b",
                        trace: .propagate, auth: .required("ingest") }
component feed { on: .machine("site-a") }
worker analyse { on: .cores, reads: uplink, each: classify }
```
Move a component and every wire to it re-derives its crossing. A remote sink asking for
`.exactly_once` with **no durable home** (the store, FLOW 09) is REFUSED — main's
in-memory queue cannot promise it across a failure domain.

## Auth: identity is a VALUE that rides the crossing
Like the trace context, the CALLER rides the work — never an ambient global:
```avra
fn classify(d: Delivery<Reading>, who: Caller) -> Result<Kind, string> {
    if !who.may("ingest") { fail "not permitted to ingest" }
    …
}
```
- `auth:` on the wire is a TERM (`.required(scope)`, `.inherited`, `.none`), and the
  callee's seat declares what it needs — so **the fit is checked**: a wire into a seat
  requiring `"ingest"` from a caller that cannot present it is refused at the wire.
- A `Caller` is a value (a principal + its claims + the trace context), minted where the
  program's edge authenticates and carried by the `Delivery`. **Secrets are never in the
  code**: they are read through the input door at the edge, like any world read.
- The same shape serves a local call (a `Caller` for an in-process dispatch) — one
  concept, no "this one is remote" branch in the handler.

## Error handling: a remote call FAILS IN MORE WAYS
A local call answers its own errors; a remote one adds a transport's:
```avra
enum CallError = Unreachable | Refused | TimedOut | Remote(E)
```
- **Every remote call carries a deadline.** A `within` is the default, not an option — a
  call with no bound is a hang dressed as a call, and the terms say so.
- **A retry needs an idempotency key or it is a double effect.** The `Delivery`'s key is
  the dedupe handle (FLOW 08); a wire that retries into a handler with effects and no key
  is REFUSED, not retried hopefully.
- **The failure domain is a term.** `on_crash`/`supervise` (Part 6) is how a peer that
  died comes back; a caller that must not wait forever pairs a deadline with a **circuit
  breaker** (a term: after N failures, refuse at once rather than time out) — otherwise a
  dead peer costs every caller its deadline.

## The production checklist (every item is a term, a type, or a refusal)
| concern | the answer |
|---|---|
| identity / permissions | `auth:` term + a `Caller` value; the fit is checked at the wire |
| secrets | the input door at the edge; never a literal in source |
| deadlines | a remote call carries `within` by default (`TimedOut`) |
| retries / idempotency | a key on the `Delivery`; no key + effects ⇒ refused |
| ordering | `order: .by_key` (per-partition FIFO); unordered is stated, never assumed |
| delivery | the queue's `delivery:`; un-bridgeable ⇒ refused |
| backpressure across the wire | the sink's `overflow:` (park / latest / drop) |
| rate limits / quotas | terms on the wire (`rate:`, `quota:`) — a world read at the edge tells the current use |
| circuit breaking | a term: after N failures, refuse at once |
| service discovery | the `remote:` term resolves through the input door (never a hard-coded address) |
| versioning | the crossing law: GROWTH (append fields) is safe, MOVING is breaking; the codec is derived, so a peer's older shape is a compile-time fact, not a runtime surprise |
| observability | `trace: .propagate` + the state-read model (Part 6); `observe.av` is replaced |
| health / readiness | a source (`every(secs(5)) -> Health`) — a service's health is data |
| graceful shutdown | `supervise` + a `Cancelled` value to whoever watches (FLOW 03) |
| audit | a queue whose `delivery: .exactly_once` and `dead:` record what was done |
| tenancy | a key part / a `Caller` claim; every row and every wire names whose it is |
| capacity planning | the generated crossings are COUNTED (`avra explain --topology`), so the fan-out is a number, not a hope |

**One line:** everything a production system argues about is either a **term** (a value
the author writes), a **law** (a `check`, the typer, or a `rule`), or a **refusal** (the
wire that cannot be bridged). None of it is a convention, and none of it is a doc the
compiler does not read.
