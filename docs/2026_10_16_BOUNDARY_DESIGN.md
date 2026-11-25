# The boundary — the whole design, in one file

*2026-10-16 · CHANNELS campaign · the companion code sketch to
`2026_10_16_BOUNDARY_CONTRACTS.md`.*

This is the design **in the language we intend rather than the one we have**. It is
deliberately NOT a `.av` file: it is not compilable (it carries `…`, prose and
unbuilt syntax), and the gate runs `fmt --check` over every changed `.av`, so a
sketch in that extension would refuse the gate and read as a broken tree to any
tool that walks them. One fenced block below holds all of it.

Every block is marked:

- **BUILT** — the tree does this today, with a real signature cited
- **PARTIAL** — some exists, spelled differently
- **PROPOSED** — nothing builds this yet

```avra
// ─── THE BOUNDARY — the whole design as one program ──────────────────────────
//
// NOT COMPILED. This file is the design's single spelling: the frame, the three
// directions, the twelve axes, the three tiers and the crossing, in the language
// we intend rather than the one we have. Every block is marked
//   BUILT     — the tree does this today (real signature, cited)
//   PARTIAL   — some of it exists, spelled differently
//   PROPOSED  — nothing builds this yet
//
// Sources: docs/2026_10_15_MEMORY_AND_REPRESENTATION.md (Parts 6–9, the frame),
// docs/2026_10_16_BOUNDARY_CONTRACTS.md (the axes, from the two surveys), and
// the packages themselves.

// ═══════════════════════════════════════════════════════════════════════════════
// A BOUNDARY has five parts, and a value crosses in ONE OF THREE DIRECTIONS.
//
//   locality · transport · codec · contract · failure domain
//
// The DIRECTION is the only distinction that matters — the other four are
// transport-shaped, and every axis below is shared by all three.
// ═══════════════════════════════════════════════════════════════════════════════

// ── DIRECTION 1 · A CALL — ask, then answer ───────────────────────────────────
// BUILT (std-http/fetch.av). It answers a Result, it can fail in the transport's
// ways, and it owes a patience (an axis, not an argument — see below).
//
//   fn fetch(method: Method, url: string, body: Body?, o: Options) -> Fetched
//   type Fetched = Result<Answer, ClientError>
//
// BUILT (std-sqlite): Db.open -> Result<Db, SqlError>; Stmt.prepare/step.
// BUILT (std-process): Command { tool, args, timeout, drain_grace, … }.run().

// ── DIRECTION 2 · A SEND — one way, no answer ─────────────────────────────────
// BUILT (std-task/task.av, std-queue/queue.av). The verdict is readable AT the
// pipe, so backpressure is not a hidden policy:
//
//   type Posted = Taken or Full or Ended        // BUILT, task.av
//   fn open_channel<T>(cap: int) -> Ch<T>       // BUILT
//
//   let q = queue<Job> { capacity: 8, dead: letters.sink }     // BUILT (#797)
//   jobs.sink(job)                                            // BUILT
//
// A SEND carries a CONTRACT (the axes); a CALL carries a RESULT.

// ── DIRECTION 3 · A ROLE — the far side asks us ───────────────────────────────
// BUILT (std-http/server.av), and the handler is a CALL, deliberately:
//
//   fn served<A>(l: Listener, isolated make: fn() -> A,
//                limits: Limits, timing: Timing,
//                handle: fn(mut A, Request<Unrouted>) -> Response) -> Server<A>
//
// A Source<Request>/Sink<Response> pair would force every handler to be a loop
// the framework already owns. What a role needs instead is a LAYER:
//
//   component layer { wraps: fn(Request<Unrouted>, Handler) -> Response }   // BUILT
//   fn compressed(q: Quality, next: Handler) -> Response                    // BUILT, http_compress
//
// PROPOSED: `limits`/`timing` become declared TERMS (see the axes), so the
// compiler can read them; docs/2026_09_30_HTTP_ROUTES_DX.md §5 already lists
// `limits()`/`timing()` under "what goes away".

// ═══════════════════════════════════════════════════════════════════════════════
// THE TWELVE AXES, in four families. Six was a first cut; the evidence is that
// the tree already answers these questions FIVE DIFFERENT WAYS in places
// (patience: Timeouts · Timing · Bounds.deadline · Command.timeout · connect()).
// A boundary need not answer all twelve — it must answer them DELIBERATELY.
// ═══════════════════════════════════════════════════════════════════════════════

// ── FAMILY A · BEHAVIOUR — under time, loss, contention, death ────────────────

// 1 · CAPACITY — what happens when the far side is slower?
//   BUILT as three spellings today: Terms.capacity · Ring.cap · Stream.pull ·
//   Timing.requests. BUILT as terms on the queue (#805):
//     overflow: .park | .latest | .drop_oldest | .drop_newest | .fail
//   read by the library at run time: on a full ring, park blocks, fail answers
//   null, drop_newest answers the id of an item never kept.

// 2 · PATIENCE — how long will I wait, and at which stage?
//   PARTIAL, and the WORST duplication in the tree: five spellings.
//   The richest existing shape is the client's per-stage patience:
//     type Timeouts = { connect, tls, first_byte, total }        // BUILT, fetch.av
//   PROPOSED: one axis, spelled once, with the stages kept — per-stage patience
//   is a real need, not redundancy.

// 3 · DELIVERY — how many times, and where does a failure go?
//   BUILT for the queue: delivery: .at_least_once | .exactly_once, retries:,
//   dead: <sink>, release/bury, and the lease's epoch fence (#797).
//   BUILT for the client: Retry { attempts, backoff, factor }.
//   PROPOSED, and it is the sharp edge: an idempotency KEY that rides the hop,
//   so a retry is safe. Today NO package carries one.
//   And the law it makes possible (the /unnamed_key decision):
//     a keyed call outside its handler's straight line must be named
//       — key.at(label) — because a RETRY MAY TAKE THE OTHER BRANCH.

// 4 · ORDERING — must things arrive in order?
//   BUILT as a LAW for HTTP ("responses go out in the order requests came in")
//   and as FIFO in the Ring. BUILT as a term (#805):
//     order: .fifo | .by_key      // by_key = one per key, head-of-line blocking

// 5 · PRIORITY — who goes first under contention?
//   ABSENT. h2 PRIORITY is "parsed and ignored" (FRAMING_LAWS §5.3.1).

// 6 · LIFETIME — who owns it, and what happens when it dies?
//   PARTIAL: `@owns Source` · OpenConfig mode/threading · Timing.drain (30 s) ·
//   "a request owns its ordinary child work" (STD_HTTP_DESIGN law 2).
//   PROPOSED, as a DECLARATION rather than a try/catch:
//     supervise { restart: .always | .on_failure | .never,
//                 budget: 5 within secs(60), escalate: .parent }

// 7 · RESILIENCE — what does it do when the far side is SICK?
//   BUILT: Rate -> 429 + retry-after (quota.av) · Readiness/probes.
//   ABSENT: a circuit breaker. Without one a dead peer costs EVERY caller its
//   full patience, which is why D7 below matters.

// ── FAMILY B · AUTHORITY — who may cross, and whose data it is ────────────────

// 8 · IDENTITY — who is calling us?
//   THREE spellings survive in the tree, which is the finding:
//     (a) header minters      bearer(token) / basic(user, pass)   // std-http/auth.av
//     (b) signed cookies      Signer · Session { signer, name, max_age }  // http_session
//     (c) an annotation       @action(auth: member_of(b), impact: routine)  // std-action
//   And a FOURTH, proposed by the HTTP design and never built — the one to adopt,
//   because it is the fit-check the boundary model wants, written in Avra's idiom:
//     "a Session<User>, Bearer, Header<"x"> | is extracted by a trait;
//      a route nothing can extract for does not compile"      // ROUTES_DX §2
//   PROPOSED: identity is an EXTRACTED PARAMETER, never an `auth:` term —
//     fn handler(req: Request, who: Session<User>) -> Response
//   so a route that cannot present a caller is REFUSED AT COMPILE TIME.
//
//   NOTE: the design doc for this — docs/2026_09_29_AUTHORITY_AND_RECEIPTS.md —
//   is referenced up to §14 by four docs and two packages and EXISTS NOWHERE ON
//   DISK. Its implementation survives in packages/std-action.

// 9 · TENANCY — whose is it?
//   ABSENT everywhere. Every row and every wire must be able to name its owner.

// ── FAMILY C · AGREEMENT — what the two sides must share ──────────────────────

// 10 · CODEC — how does a value become bytes, both ways?
//   BUILT: std-url · std-json · std-validate (Issue { path, rule, message,
//   received, fix }), and ONE value class across HTTP/1.1 and h2
//   (FRAMING_LAWS §5.6). PROPOSED: one derived codec per type, with the crossing
//   law below deciding what may change.

// 11 · VERSION — what may change without breaking the peer?
//   PARTIAL: Api.version (openapi) + the crossing law —
//     GROWTH crosses, MOVING breaks: a reader takes the slots it knows by
//     order and never looks at the trailing ones, so appending a field is ONE
//     commit and moving a shape is TWO.

// ── FAMILY D · VISIBILITY — what it says about itself ─────────────────────────

// 12 · OBSERVABILITY — what can be seen, and by whom?
//   BUILT for HTTP only (std-http/observe.av, ~+1.95 µs/request): validates
//   `traceparent`, mints trace+span from a once LCG seeded by entropy32(),
//   reads/echoes x-request-id, one JSON line. The context rides the work, so
//   "a call it makes forwards the header".
//   ABSENT: trace outside HTTP · metrics · spans · audit.
//   PROPOSED: trace: .propagate as a term, plus record/replay —
//     fn record<T>(src: Source<T>) -> Source<T>
//     fn replay<T>(path: string) -> Source<T>
//   which is the cheap big win: it makes EVERY guarantee above testable.

// ═══════════════════════════════════════════════════════════════════════════════
// THE THREE TIERS — how a contract becomes the LANGUAGE's, not a doc's.
// ═══════════════════════════════════════════════════════════════════════════════

// TIER 1 — FIELDS/TERMS. The values above. No machinery.

// TIER 2 — A `check`, written by the library author IN AVRA, run at each
// instance, its diagnostic spoken THERE. BUILT (#797, #805):
//
//   export component queue<T> {
//       capacity = 1000
//       delivery = Guarantee.at_least_once
//       retries  = 3
//       dead: Sink<Dead<T, string>>? = null
//       overflow = Overflow.park
//       order    = Order.fifo
//
//       fn check() {
//           if self.capacity < 1 { fail "capacity must be at least 1" }
//           if self.retries < 0  { fail "retries cannot be negative" }
//           if self.delivery == Guarantee.exactly_once && self.dead == null {
//               fail "a fate is named when delivery is exactly_once"
//           }
//           // THE LAW THIS SLICE ADDED: the two promises cannot both hold.
//           if self.overflow != Overflow.park && self.delivery == Guarantee.exactly_once {
//               fail "a queue that drops on overflow cannot promise exactly once"
//           }
//       }
//   }
//
//   THE TIER BOUNDARY, stated where the tiers meet: a check reads ONE
//   declaration's FIELD VALUES and nothing else. It cannot see a type or a
//   signature — that is the typer's — and it cannot see a shape no single
//   declaration owns — that is a rule's.

// TIER 3 — THE TYPER, for laws that need types/signatures. BUILT (the first):
//   flow.no_fate — "a component whose field VALUE answers Result and declares
//   dead: must set it" (features/components/check.av, golden-pinned).
//   It is STRUCTURAL, never a name test.

// A `rule` (avra check) is only for a cross-cutting SHAPE no single declaration
// owns — BUILT: lists.removed_at_front. Not a fourth tier; the shape's.

// ═══════════════════════════════════════════════════════════════════════════════
// THE CROSSING — a wire between machines, and the adaptor that appears
// ═══════════════════════════════════════════════════════════════════════════════

// PROPOSED. Note there is NO QUEUE IN THE WIRE — locality forces the async and
// the compiler generates the hop:
//
//   // machine A                          // machine B
//   component feed { fn readings() -> Source<Reading> { … } }
//   worker analyse { reads: feed.readings, each: classify }
//
//   feed.readings |> analyse.ingest        // Source<Reading> |> a seat
//
//   avra explain --topology
//     feed.readings → [crossing(Reading)] → analyse.ingest
//       crossing: remote site-b · codec Reading.wire · trace .propagate
//       reason:   source is local, sink is remote — a hop is unavoidable
//
// THE LAW THAT BOUNDS "SMART": the compiler inserts an adaptor ONLY where an
// adaptor can strengthen the fit, and REFUSES where it cannot.
//   ADAPTABLE   — capacity/rate (a buffer) · locality (a bridge) · sync/async
//   NOT         — delivery and ordering: nothing invents at-least-once from
//                 at-most-once, nor FIFO from unordered. REFUSED BY NAME.
// And it NEVER invents a buffer size — a rate is dynamic, so the minimal hop is
// a rendezvous or a crossing; a buffer is the author's decision.

// ═══════════════════════════════════════════════════════════════════════════════
// THE LAW THE WHOLE DESIGN INHERITS FROM THE HTTP WORK
// ═══════════════════════════════════════════════════════════════════════════════
//
//   "a guard is not a place, it is a property of every crossing"
//                                        — docs/HTTP_WORKING.md, review round
//
// Every axis here is a guard. So it belongs AT THE CROSSING — never in whichever
// package happens to sit closest to the wire.
```
