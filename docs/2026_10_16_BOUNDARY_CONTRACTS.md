# The boundary's contracts — the axes, the directions, the spellings

*2026-10-16 · CHANNELS campaign · the companion to
`2026_10_15_MEMORY_AND_REPRESENTATION.md` (Parts 6–9 are the FRAME: what a
boundary is). This settles what the frame left loose — the number of axes, the
shape of a role, and where identity belongs. It was written from two surveys of
the tree: the HTTP/network **designs** under `docs/`, and the
**implementations** of every package that crosses a process or network boundary.*

Every claim cites the tree: a doc (file + section) or a symbol (file + name).
Where the evidence is a gap it says **gap**. Nothing here is invented.

---

## 1. Why this exists: the same concern, five ways

The model is not justified by elegance. It is justified because the tree already
answers these questions — **differently in each package**:

| concern | spellings found in the tree | count |
|---|---|---|
| **patience** (deadline) | `Timeouts { connect, tls, first_byte, total }` (`std-http/fetch.av`) · `Timing { handshake, head, body, idle, requests, drain }` (`std-http/server.av`) · `Bounds.deadline` (`std-http/quota.av`) · `Command.timeout` + `drain_grace` (`std-process/process.av`) · `connect(host, port, timeout, …)` (`std-net/net.av`) | **5** |
| **retry** | `Retry { attempts, backoff, factor }` (`fetch.av`) · `Terms.retries` + `release`/`bury` (`std-queue/queue.av`) | **2** |
| **capacity** | `Terms.capacity` (`queue.av`) · `Ring.cap` (`std-task/task.av`) · `Stream.pull` — "one piece in memory per stream" (`std-http/http.av`) · `Timing.requests` | **3–4** |
| **identity** | `bearer`/`basic` header minters (`std-http/auth.av`) · `Signer`/`Session` signed cookies (`std-http_session`) · `@action(auth: …, impact: …)` (`std-action`) | **3** |
| **address / origin** | `url.parse` + `fetch.Aim`/`aimed` (`fetch.av`) · `net.resolve`/`Address` (`net.av`) · `pool.origin_of` (`pool.av`) | **3** |
| **"the transport died" vs "the far side refused"** | `NetError { timed_out, reset, closed, interrupted }` (`net.av`) · `TlsError` wrapping `.Net(e)` (`tls.av`) · `ClientError { Net, Refused, Closed, TimedOut, Exhausted }` (`client.av`) · `ProcessError { TimedOut, StageFailed }` (`process.av`) · `Cause { Busy, Io, Defect, Constraint }` (sqlite) · `ModelError { Unique, Ambiguous, Other(SqlError) }` (`std-db`) | **4 wrappers re-wrapping** |

And these are **absent everywhere** — a model with no answer, not a second
answer:

> no shared boundary or `Caller` value · **no idempotency key** · no delivery
> semantics · no priority · no tenancy · no circuit breaker · no deadline on the
> DB boundary · no remote cancellation (task cancel is local only: `std-task`) ·
> no trace outside HTTP · no `record`/`replay` · no versioned-codec compatibility
> law.

**Five patience spellings is the argument.** Any one is defensible alone; five
means the language never named the concept.

---

## 2. The three directions

`2026_10_15_MEMORY_AND_REPRESENTATION.md` Part 9 said a server "answers a
`Source<Request>` and consumes a `Sink<Response>`". **The tree does not do that,
and should not.**

| direction | shape in the tree |
|---|---|
| **CALL** — ask, then answer | `fetch(…) -> Fetched` where `Fetched = Result<Answer, ClientError>` (`fetch.av`) · `Db.open` · `Stmt.prepare/step` · `Command.run` |
| **SEND** — one way | `Sink<T>`/`Source<T>` + `open_channel(cap)` (`std-task/task.av`), answering `Posted { Taken, Full, Ended }` · `Terms { capacity, lease, retries, dead }` (`std-queue/queue.av`) |
| **ROLE** — the far side asks us | **`served<A>(l, isolated make, limits, timing, handle: fn(mut A, Request<Unrouted>) -> Response) -> Server<A>`** (`std-http/server.av`) |

**The ROLE's handler is a CALL, and that is right.** A `Source`/`Sink` pair would
force every handler to be a loop — the caller's loop, written by the author, in a
place the framework already owns. What a role actually needs is the **layer**:

```avra
component layer { wraps: fn(Request<Unrouted>, Handler) -> Response }
```

That is the tree's real composition idiom for a cross-cutting concern — the shape
`std-http_compress` already uses (`compressed(q, next)`) — and it subsumes what
the frame wanted `Source`/`Sink` for. **So a ROLE is a `served`-style loop the
boundary owns, whose handler is an ordinary fn, and whose cross-cutting concerns
are LAYERS.**

---

## 3. The axes: four families, twelve axes

"Six" was a first cut. The evidence supports twelve, grouped so that each family
answers one KIND of question. An axis is a thing a boundary may have to promise.
A boundary need not answer all twelve — it must answer them **deliberately**.

### A · BEHAVIOUR — under time, loss, contention and death

| axis | the question | today | evidence |
|---|---|---|---|
| **capacity** | what happens when the far side is slower? | `Terms.capacity` · `Ring.cap` · `Stream.pull` · `Timing.requests` | 3–4 spellings |
| **patience** | how long will I wait, and at which stage? | `Timeouts` · `Timing` · `Bounds.deadline` · `Command.timeout` · `connect(timeout)` | **5 spellings** |
| **delivery** | how many times, and where does a failure go? | `Retry` · `Terms.retries` · `dead:` · `release`/`bury` | 2 spellings + semantics **absent** |
| **ordering** | must things arrive in order? | a **law** ("responses go out in the order requests came in") + `Ring` FIFO | 1 law, no term |
| **priority** | who goes first under contention? | nothing — h2 `PRIORITY` is *"parsed and ignored"* (`HTTP_FRAMING_LAWS` §5.3.1) | **absent** |
| **lifetime** | who owns it; what happens when it dies? | `@owns Source` · `OpenConfig` mode/threading · `Timing.drain` (30 s) · *"a request owns its ordinary child work"* (`STD_HTTP_DESIGN` law 2) | partial; **graceful drain "not built"** (`HTTP_ROADMAP`) |
| **resilience** | what does it do when the far side is *sick*? | `Rate` → 429 + `retry-after` (`quota.av`) · `Readiness`/`probes` | rate + health only; **no circuit breaker** |

### B · AUTHORITY — who may cross, and whose data it is

| axis | the question | today | evidence |
|---|---|---|---|
| **identity** | who is calling us? | **three surviving spellings** (§6) | authentication is a declared **gap** (`PLATFORM_MAP` §Behaviour → `avra-8sb5.64.4`) |
| **tenancy** | whose is it? | nothing | **absent** |

### C · AGREEMENT — what the two sides must share

| axis | the question | today | evidence |
|---|---|---|---|
| **codec** | how does a value become bytes, both ways? | `std-url`, `std-json`, `std-validate` (`Issue { path, rule, message, received, fix }`) · *"one format, two directions"* (`HTTP_ROUTES_DX` §2) · **one value class across 1.1 and h2** (`HTTP_FRAMING_LAWS` §5.6) | decided for HTTP; no general law |
| **version** | what may change without breaking the peer? | `Api.version` (`openapi.av`) · the crossing law: *growth crosses, moving breaks* | 1 field + 1 law; no compat law per codec |

### D · VISIBILITY — what it says about itself

| axis | the question | today | evidence |
|---|---|---|---|
| **observability** | what can be seen, and by whom? | **HTTP only**: `std-http/observe.av` — validates `traceparent`, mints trace+span from a `once` LCG seeded by `entropy32()`, reads/echoes `x-request-id`, two `now_ns()` reads, one JSON line on stderr; ~**+1.95 µs/request** | 1 package; **no trace elsewhere** |

---

## 4. The decisions this forces

**D1 · The axes are twelve, in four families** (§3), not six. The families name
the *kind* of question. **Adopt.**

**D2 · A ROLE's handler is a call; layers compose.** `Source<Request>`/
`Sink<Response>` goes (§2). `served` and `component layer` already exist.
**Adopt.**

**D3 · Identity is an extracted parameter, never a term.** Adopt the idiom the
HTTP design already wrote — *"a `Session<User>`, `Bearer`, `Header<"x">` is
extracted by a trait; a route nothing can extract for does not compile"*
(`HTTP_ROUTES_DX` §2). That sentence **is** "the fit is checked at the wire", in
Avra's own words, months earlier. **Adopt**, and settle the lost authority doc
first (§6).

**D4 · One patience axis, one spelling.** The five existing spellings migrate to
one. The client's per-stage `Timeouts { connect, tls, first_byte, total }` is the
*richest* existing shape and the likely survivor — per-stage patience is a real
need, not redundancy. **Adopt the axis; the spelling is open.**

**D5 · `Limits`/`Timing` become declared terms, or they do not.** The code passes
them as records to `served(…)`; the model wants them where the compiler can read
them, and `HTTP_ROUTES_DX` §5 already lists `limits()`/`timing()` under *"what
goes away"*. **Recommend terms on the declaration, derived into the call** — a
migration with a real cost.

**D6 · One error vocabulary per KIND of failure, not per transport.** Today four
wrappers re-wrap each other, and *"the transport died"* vs *"the far side
refused"* is re-named at every layer. The unification must keep each layer's
detail (a TLS failure still says TLS). **Adopt, with the layer's own error as the
variant's payload.**

**D7 · Every axis a boundary does NOT answer is answered by a STATED DEFAULT,
not by silence.** The platform caps the model never named are the evidence:
*"macOS caps a listen backlog at 128 whatever was asked"* (`HTTP_WORKING`), the
1 MiB body default, 1000 requests/connection. **A default is a value the compiler
can print** — `avra explain` shows the contract a boundary ended up with.

---

## 5. What this does NOT change

The **three tiers** stand (`2026_10_15_MEMORY_AND_REPRESENTATION.md` Part 6):
**(1) fields/terms** → **(2) a `check`** written in Avra, run per instance, its
diagnostic spoken there → **(3) the typer**, for laws needing types or signatures
(`flow.no_fate` is the first, and it is structural, never a name test). A `rule`
(`avra check`) is only for a cross-cutting SHAPE no single declaration owns
(`lists.removed_at_front`) — not a fourth tier; the shape's.

And one law is inherited wholesale from the HTTP work, because it is the same law:

> **"a guard is not a place, it is a property of every crossing"**
> — `HTTP_WORKING.md`, review round

Every axis here is a guard, so it belongs **at the crossing** — never in whichever
package happens to sit closest to the wire.

---

## 6. The authority design is LOST — and three spellings of identity survive

**`2026_09_29_AUTHORITY_AND_RECEIPTS.md` is referenced by at least four docs and
two packages, quoted up to §14 (mandate signing, trust root, revocation epoch),
and EXISTS NOWHERE ON DISK** — not in this repo, not in this repo's git history,
not in any worktree, not in the older `forge-crafting-intepreters` tree or its
siblings. A search of the whole project directory by name returns nothing.

`2026_09_29_WEB_UI.md` names it *"the normative home"* for *"principals, the
action lifecycle, impact, … safeguard, receipt, waiver and mandate laws"*, and
defers to it for at least nine sections. That design was written and lost. **It
must be found or rewritten before the identity axis is implemented** — a
compatibility contract with a document nobody can read is folklore.

**The implementation survives, and it is a third spelling.** (`packages/std-action`):

```avra
// packages/std-action/src/action.av
//!     @action(auth: member_of(b), impact: routine)
//!
//! `impact` is REQUIRED and is a profile over the record below; a
//! `speculative` node stays so until the receipt.
```

So identity is spelled **three** ways in the tree today — a header minter
(`std-http/auth.av`), a signed cookie (`std-http_session`), and an annotation
(`std-action`) — plus a fourth that was designed and never built
(`HTTP_ROUTES_DX` §2's trait-extracted parameter).

**The recommendation (D3): build the fourth.** It is the only one that *refuses*
a route it cannot satisfy, it is already written in the tree's own idiom, and the
other three can be expressed as extractors rather than as rivals.

---

## 7. Open questions

1. **D5** — do `Limits`/`Timing` become declared terms (a migration), or stay as
   the values passed to `served(…)`? `HTTP_ROUTES_DX` §5 says they go.
2. **D3** — confirm identity by trait-extraction, and whether the lost authority
   design is rewritten before anything lands (§6).
3. **Ordering, priority and tenancy** are the axes with the least evidence — terms
   now, or a stated default until a surface needs them?
4. **Eight of the twelve axes have no compiler-checked law today.** Which axes
   earn the typer (tier 3), and which are content to be a `check` (tier 2)?

---

*The single-file spelling of all of this — the frame, the three directions, the
twelve axes, the three tiers and the crossing, each block marked BUILT / PARTIAL /
PROPOSED — is `2026_10_16_BOUNDARY_DESIGN.av` beside this file. It is not compiled;
it is the design in the language we intend rather than the one we have.*

---

## 8. Tier 2 IS `@std/validate` — the `check` spelling is a re-spelling

§5 says a value law is "a `check` written in Avra". Reading `@std/validate`'s own
module doc shows that machinery not only exists — it is **richer** than a bespoke
checker:

> Each field is read at its slot by its kind, then each annotation is CALLED over
> what was read — `@range(13, 130)` is `range(age, 13, 130)` — so a rule on the
> wrong type is refused **where the annotation is written**, and a rule naming a
> **sibling field** reads that field's value. A rule on the **record itself** reads
> the whole value once every field has passed — the **cross-field rules**. A
> `type Name = shape` carrying rules reads its shape, then wraps it: **a
> `Username` is proof it passed.**

So a value law has ONE spelling, not two:

| what | spelled |
|---|---|
| a constraint on one field | `@rule(…)` on the field — shared with `decode` |
| a relation between fields | a rule **on the record** — run "once every field has passed" |
| "this value passed" | a **named type** carrying the rules — its existence is the proof |
| any logic at all | a rule is a **plain fn**: `fn at_least(v: int, n: int) -> Result<int, string>` |

The compiler and `decode` call the **same fn**; only the clock differs — a
declaration versus the edge. And because a rule answers the value the field
receives, a rule may **normalise**.

**Consequences.**

- The `fn check()` tier should **migrate to these annotations**. It is the same
  mechanism with a second spelling, which is exactly the defect this document was
  written to name.
- **A `require` keyword is NOT wanted.** It was proposed (a per-declaration law
  block) and then **struck**: `@std/validate` already has cross-field rules, rules
  that read a sibling, and proof types — a `require` would have been a second
  mechanism for a question already answered.
- **A constraint belongs on the field it constrains, and nowhere else** — which
  also means the surface is smaller than it looked: where a field's TYPE is already
  precise (every enum: `overflow: Overflow`, `order: Order`), the constraint is
  free and needs no spelling at all. An annotation earns its place only where the
  type is too wide (`capacity: int` cannot say "≥ 1").
- **One open point, and it is real:** a component declaration is not a *named
  record type*, so a record-level rule's parameter is undecided. `self` is the
  candidate — it is what `fn check()` already has, and it avoids minting a terms
  type per component.

Tickets: `avra-8sb5.34.53.26` (`law` declarations: a spec-level law with a
proven/checked/trusted/open ladder, property-checked in `avra test`) is a
**different, larger** feature and is unaffected by this — a per-declaration
constraint is not a law about the language's semantics.
