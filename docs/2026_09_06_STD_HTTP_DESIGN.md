# @std.http — An endpoint is a contract

Status: design discussion, not an implemented API. Discovery base: `85e6344`
on `lane/http`. Source inspection below is not a compiler probe or a
performance measurement. Example syntax is proposed and does not compile today.

## The application shaping the design

An agent project manager combines documents, issues, discussions, and code
reviews. An idea becomes a terse specification, then issues, then reviewed
changes. Humans and agents observe and contribute to the same work.

The owner's constraints:

- Design client and server together; compose model and auth integrations.
- Agent-first, minimal ceremony, idiomatic expressions, small cohesive modules.
- Rust-level performance is a requirement to measure.
- Linux production and macOS development are the initial targets.
- Build missing language foundations; do not entrench workarounds in the API.
- Every implementation slice gets `/red-team`, then `/review-round`.
- Coordinate with the SQLite lane no earlier than 14:00 America/Los_Angeles.
- Safety and serious optimization apply across the whole library, intended
  as foundational Internet infrastructure. Durability is part of this bar.
- Project-scoped agent permissions and revision-bound approvals are accepted
  for the example application; HTTP must supply general authorization seams.

## The proposed center

An operation has an identity, typed input, typed success and failure, and a
declared HTTP binding. Input positions distinguish path, query, headers, and
body. The compiler can derive routing, decoding, encoding, client calls, and
contract documentation from that declaration. Publishing an agent tool uses
the same contract, with explicit exposure and authorization policy.

The operation name earns its characters: it names the generated client
method, traces, and tool description without guessing a name from a URL.
Separate listening from the API value so a contract can serve on a socket,
run through an in-process HTTP test transport, or be consumed by a client.
The in-process transport must still exercise serialization and decoding;
calling a domain function alone cannot prove a wire contract.

Illustrative operation spelling, with application imports and implementations
omitted. The `api` component and its route grammar are proposals:

```avra
api Projects {
    POST /ideas create(body: NewIdea) -> Result<Idea, IdeaError> {
        ideas.create(body)
    }

    POST /ideas/:id/runs start(id: IdeaId) -> Result<Run, RunError> {
        runs.start(id)
    }
}
```

The route spelling above is an initial sketch. The owner's pointer to
*Strings From the Future* supplies the stronger foundation: typed captures
and a single format used for parsing and printing. The follow-on design in
`2026_09_06_STD_HTTP_TYPED_ROUTES.md` replaces colon parameters with typed
format captures and treats query decoding as its own structured component.

The expansion should be ordinary Avra declarations. The generic component
expansion mechanism belongs to the compiler; HTTP grammar and policy belong
to the library. Error-to-status mappings belong to the HTTP contract, not
to a compiler list of application errors.

Remote calls retain their boundary: a generated client answers a result
that distinguishes declared application errors from transport and decoding
failures. Connection loss after sending a mutation may mean its outcome is
unknown. A pleasant call spelling cannot erase that uncertainty.

## Laws to design before sugar

1. A body has one consumption lifetime. A byte buffer and a live body stream
   are distinct values. Collecting a stream is explicit and bounded.
2. A request owns its ordinary child work. Cancellation and deadlines reach
   I/O through a general task scope. Cleanup completes before resources are
   reused; bounded cleanup needs its own cancellation policy.
3. Durable work has a durable owner. Disconnecting an observer releases the
   subscription. Surviving a process restart requires persisted acceptance,
   execution state, and recovery in a jobs/workflow package.
4. Replay is a storage contract. An SSE event ID is a cursor, not persistence.
   A subscriber must learn when its cursor has expired instead of silently
   losing events. Broadcast and competing-consumer queues are different.
5. Retrying a mutation requires declared replay semantics. A key by itself
   is insufficient: principal and operation scope, payload identity,
   concurrent claims, retention, and crash behavior all need contracts.
   External side effects need reconciliation or their own idempotency support.
6. Partial input preserves absence independently of the field's nullability.
   Omitting an assignee and clearing an assignee are different operations.
7. Authorization is enforced for each operation and resource. Tool discovery
   cannot confer authority. Revision preconditions protect concurrent edits;
   approval of a revision must not silently authorize a changed revision.
8. Bounds cover bytes and work: headers, bodies, decoded expansion, queues,
   concurrent operations, and connection lifetimes. Defaults must be named,
   inspectable, and adjustable at the boundary that owns them.

## Foundations and module boundaries

Historical: the source as inspected on 2026-09-06.

Current source inspected: `features/components/mod.av` implements config-only
record sugar; `std-json/src/json.av` provides a dynamic JSON value with integer
numbers. Neither is evidence that general expansion or typed codecs exist.
The ROADMAP records `Bytes` as pending at this base. Re-probe each capability
against the lane and compiler version before scheduling its implementation.

The older component V2 design supplies the direction: generic compile-time
expansion, hygienic AST construction, inspectable expansion, and ordinary
values beneath the syntax. Its shipped-status claims describe the old tree.

Likely general foundations: owned byte buffers and views, resource lifetimes,
fallible streams, task scopes, a nonblocking I/O scheduler, typed codecs,
and component expansion. Task scopes and the scheduler are designed in
docs/2026_09_22_FIBERS_DESIGN.md: every block is a scope, so law 2's
"a request owns its ordinary child work" holds by construction, and
cancellation and deadlines (`within`) reach I/O at its pause points. Each needs a concrete HTTP witness before its scope
is settled. SQLite, process, and other lanes may already own portions.

The concurrency spec's channel section assigns capacity zero to both an
unbounded queue and a rendezvous. Proposed resolution: separate named
constructors. Neither HTTP nor another consumer should inherit that ambiguity.

Proposed responsibility boundaries, not empty directories to scaffold:

- `std.net` and TLS support: sockets, resolution, transport security.
- `std.http` message modules: methods, status, fields, URI, bodies, failures.
- Protocol modules: incremental framing and connection state, separate from
  routing and application handlers.
- Client modules: pools and request execution; explicit retry/redirect policy.
- Server modules: admission, dispatch, connections, graceful shutdown.
- Contract modules: route declarations and compiler-derived projections.
- Streaming modules: SSE and WebSocket framing and lifecycle.
- Sibling packages: codecs, auth, model projections, durable jobs and events.

Backend choices remain open pending ABI, dependency, protocol, and performance
research. No custom cryptography is implied by owning the Avra interface.

## Initial design attacks

These are thought experiments, not executed tests or a completed `/red-team`.
They become executable adversarial fixtures as their subjects are built.

| Scenario | Required distinction or proof |
| --- | --- |
| A run is accepted but its response is lost | Unknown outcome; retry cannot start a second run under a deduplication contract |
| Two agents update the same document revision | A stale precondition returns a typed conflict |
| A reviewer approves revision A, then revision B appears | Approval remains bound to A |
| An SSE observer reconnects after retention expires | Explicit cursor-expired result and resynchronization path |
| Two observers attach to one event source | Each subscription sees its promised events; a shared queue must not divide them |
| Middleware verifies a signature and the handler decodes JSON | Both inspect the same bytes under a defined, bounded body ownership plan |
| A slow peer stops reading a large stream | Bounded memory, cancellable waits, and no stalled unrelated requests |
| A producer fails after response headers are sent | Stream failure semantics; no attempt to replace an already-sent status |

## Product questions resolved

The owner requested extreme safety and serious optimization throughout, in
response to the durability question. The design therefore targets restart-safe
acceptance for durable jobs and resumable observation. This is a design target,
not a claim that HTTP transport can ensure durable external side effects.

The example application's project-scoped permissions and revision-bound
approvals are accepted. They do not define a universal Internet identity
model or require the HTTP library to embed that application's workflow.

There is enough product direction to proceed with the foundation design and
capability probes. Remaining questions concern precise semantics and evidence.

## Sources informing the proposal

Local: the full spec's Part 0 and Axes 18/22; the older
`feat_std_http.md` and `2026_05_08_COMPONENTS_V2_DESIGN.md`; current process,
SQLite, and documentation vision documents. These are design sources, not
proof of capabilities in this compiler.

Primary external sources checked on 2026-09-06:

- [Axum extraction](https://docs.rs/axum/latest/axum/extract/index.html):
  single-consumer request bodies and separation of parts/body extraction.
- [Hyper server guide](https://hyper.rs/guides/1/server/hello-world/):
  service, connection, and executor boundaries.
- [Reqwest Client](https://docs.rs/reqwest/latest/reqwest/struct.Client.html):
  reusable clients own connection pools.
- [RFC 9110, idempotency](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.2.2):
  automatic retries of non-idempotent methods require additional knowledge.
- [SSE reconnection](https://html.spec.whatwg.org/multipage/server-sent-events.html#the-last-event-id-header):
  the client sends its last event ID on reconnection; durable storage is a
  separate design requirement.
