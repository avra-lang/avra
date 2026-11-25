# Autonomous systems and state — the database is the constitution

> 2026-09-24. Research note beside `2026_09_24_ORM.md`. This is a design
> finding, not a commitment to build the later phases. Here **state** means
> durable computational and business state, not the government. The question:
> how will future agents, swarms, autonomous businesses, and machine economies
> read, change, share, and recover state?
>
> The NORMATIVE protocol this note argues for — principals, the action
> lifecycle, impact, safeguards, receipts, effects, mandates — lives in
> `2026_09_29_AUTHORITY_AND_RECEIPTS.md`. This note is its rationale and
> scale-out research.

## 0. The answer

Future autonomous systems should not interact with authoritative state by
freely reading and writing rows. They should:

1. observe a named, versioned snapshot;
2. deliberate speculatively against that snapshot;
3. submit a typed **command** describing the intended transition;
4. have a deterministic boundary re-check authority, freshness, budgets, and
   invariants at commit time;
5. atomically record the transition, its cause, and an idempotency identity;
6. receive a durable receipt; and
7. drive non-transactional effects through retryable work with explicit
   compensation.

The model proposes; the state boundary disposes.

That distinction gets more important as autonomy grows. An LLM is an excellent
planner over possibilities and an unsafe source of serialization, authority,
or truth. The durable state system is therefore not passive memory for the
agent. It is the autonomous system's constitution: the place where legal
transitions, delegated power, conservation laws, evidence, and dispute rules
are made executable.

The conclusion is not LLM-specific. A learned controller, optimizer, robot,
market maker, or conventionally programmed service may be a better or worse
planner, but none gets to manufacture authority or make a stale observation
current. The same boundary applies whenever a fallible actor can create
durable or externally visible effects.

The ORM document has three important pieces of this answer already: the schema
as a type, capability-shaped access, and temporal history. But those pieces do
not yet form the write protocol an autonomous business needs. The missing
center is **typed transitions plus durable execution**. A temporal ORM can say
what the rows were. It cannot by itself say whether a write was authorized,
whether a tool call happened once, whether a swarm raced, or how an external
payment is corrected.

## 1. “State” is several different things

Calling all persistent information “memory” loses the boundaries that make an
autonomous system safe. At least six kinds of state exist:

| Kind | Example | Truth status | Required treatment |
|---|---|---|---|
| **Working context** | prompt, scratch plan, retrieved passages | disposable hypothesis | bounded, lossy, cheap to rebuild |
| **Belief** | “supplier A probably has stock” | attributed assertion | source, confidence, observed time, expiry |
| **Workflow state** | awaiting quote, retry 3, approval required | durable control position | resumable state machine and event history |
| **Authoritative business state** | inventory reserved, invoice due, account balance | current institutional truth | transactions, invariants, serialization |
| **Evidence** | command, approval, model/tool result, receipt | what was observed or agreed | append-only provenance, retention policy |
| **External commitment** | signed order, shipment, payment settlement | truth shared with another authority | protocol state, signatures, receipts, disputes |

These are related but not interchangeable. A model output is evidence that a
model emitted text; it is not automatically a fact. A CRM row can be the
business's current view without being an objective claim about the world. A
payment request is an intention; a processor receipt is evidence of a result.
A workflow checkpoint says where execution may resume; it does not prove that
the business transition it was attempting committed.

This yields the first structural law:

> **Every value crossing into authoritative state names what kind of claim it
> is, who made it, what observation or mandate supports it, and when that
> support was valid.**

Plain record types describe shape. Autonomous state also needs epistemic type:
fact versus assertion versus intention versus commitment versus receipt.

## 2. The universal interaction loop

Across one agent, a swarm, a company, and an economy, the same loop recurs:

```text
observe(version, authority)
        |
        v
speculate on a private branch
        |
        v
propose Command(expected_version, mandate, idempotency_key, cause)
        |
        v
deterministic commit boundary
  - authority still valid?
  - observation still fresh?
  - transition legal?
  - invariants and budgets preserved?
        |
        +---- refuse with a typed conflict ----> observe again
        |
        v
atomic transition + event + durable work item
        |
        v
receipt(version, result, evidence hash)
        |
        v
retry effects / compensate / project / notify
```

The private branch is where nondeterminism belongs. An agent can generate ten
plans, simulate them against a snapshot, cost them, and discard nine without
touching reality. The commit boundary is deliberately boring deterministic
code. It accepts a closed vocabulary of commands rather than arbitrary SQL and
checks the live state, not the state the model happened to see seconds or hours
ago.

This is optimistic concurrency generalized from a row version to a business
decision. The expected version says “my reasoning was based on this world.” A
failed compare-and-set is not an infrastructure error to retry blindly; it is a
semantic signal to reconsider the plan.

Five properties fall out of the loop:

- **No ambient mutation.** The strongest autonomous interface is not
  `db.update(any row)` but `reserve_inventory(order, quantity)`.
- **Authority is checked twice.** Static typing bounds what code could request;
  a live witness proves what this principal may do now.
- **Every retry has an identity.** The same command identity returns the same
  committed result rather than performing the action again. Amazon's account
  of idempotent APIs makes the atomicity requirement explicit: recording the
  token and performing the mutation must be one ACID operation
  ([AWS Builders' Library](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/)).
- **Effects follow commits.** Email, shipping, payment, and other remote calls
  are not hidden inside the database transaction. A committed work item drives
  them and records their remote receipt.
- **Correction is a new fact.** Once another authority has observed an action,
  “undo” means reversal or compensation, not erasure.

## 3. What changes at each scale

### 3.1 One long-running agent

A useful agent outlives a process, context window, model version, and often a
deployment. Its execution position must therefore be durable independently of
its conversational memory. Durable-execution systems already reconstruct
workflow state from an append-only event history and record nondeterministic
results rather than invoking them again during replay
([Temporal event history](https://github.com/temporalio/documentation/blob/main/docs/encyclopedia/workflow/workflow-execution/event.mdx)).

For an agent, every model call and tool call is such a nondeterministic result.
The durable record needs the request identity, selected model/tool version,
result or failure, cost, and the command that eventually consumed it. Replaying
the orchestration must reuse the recorded result; deliberately asking a model
again is a new branch, not recovery.

An agent session trace is valuable observability, but a trace is not the
business ledger. Current agent platforms already distinguish session, turn,
and step traces ([OpenAI tracing](https://developers.openai.com/api/docs/guides/agents-api/tracing)).
Avra should preserve that distinction: execution evidence may explain a
decision, while only a committed command changes business truth.

### 3.2 A swarm

A swarm adds concurrent, duplicated, late, and partitioned workers. It needs
more than shared memory:

- work claims with leases;
- monotonically increasing epochs or fencing tokens so a timed-out worker
  cannot make a late “zombie” write;
- compare-and-set on the state the plan observed;
- idempotent command identities stable across retries and delegation;
- a causal parent for every delegated task and resulting write;
- bounded sub-capabilities and sub-budgets;
- join semantics that say whether one, all, quorum, or the best result wins;
- cancellation that revokes future authority without pretending already
  committed effects vanished.

The swarm should exchange tasks and artifacts, not raw access to one another's
memory. The current A2A specification independently arrives at stateful tasks,
lifecycle states, artifacts, history, and opaque agents that need not reveal
their internal state ([A2A specification](https://a2a-protocol.org/v0.3.0/specification/)).
That is a transport envelope, however, not a correctness model. The receiving
business still has to validate a task result before it becomes authoritative.

Not all swarm updates need global serialization. Commutative facts, grow-only
evidence, and many counters can merge; scarce inventory, uniqueness, and a
non-negative balance may require coordination, reservation, or escrow. CRDTs
show how replicas can accept some updates independently and converge
([CRDT overview](https://crdt.tech/)); invariant confluence gives the stronger
criterion: coordinate exactly when independently valid local states could
merge into an invalid global state
([Coordination Avoidance](https://www.vldb.org/pvldb/vol8/p185-bailis.pdf)).

This is a particularly good fit for Avra. If invariants and operations are
declarations in a deliberately analyzable fragment, the compiler can classify
known cases: transitions that commute, transitions that need an optimistic
version check, and transitions that require one serialization domain. An
unknown proof must conservatively coordinate or require an explicit, checked
strategy; general program semantics are not magically decidable. “Strong
versus eventual consistency” stops being one database-wide switch and becomes
a property of each typed transition.

### 3.3 An autonomous business

An autonomous business is not one large agent. It is a durable graph of roles,
budgets, workflows, ledgers, and external obligations, with replaceable agents
occupying short-lived seats.

The identity of the business must not be the identity of a model invocation.
The business owns durable keys and policies; agents receive attenuated,
expiring mandates. A purchasing agent can be replaced halfway through an order
without changing who owes money. A model upgrade can change future decisions
without rewriting the evidence for old ones.

The core state is best modeled as legal state machines:

```text
Quote --accept(mandate)--> Order --reserve--> Fulfillable
  |                           |                    |
 expire                     cancel              ship(receipt)
  v                           v                    v
Closed                      Canceled            Fulfilled
```

Fields remain useful projections, but the public write vocabulary is the set of
legal arrows. Every arrow states its preconditions, authority, conserved
quantities, emitted facts, durable effects, and compensation. Directly setting
`order.status = "fulfilled"` is as invalid as jumping into the middle of a
function.

Long-lived business processes cannot hold a database transaction open while a
supplier, bank, or person responds. Sagas split the process into committed
steps with compensating transactions if later steps fail
([original Sagas paper](https://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf)).
Compensation is semantic, not temporal deletion: refunding a charge does not
make the original charge never have occurred.

### 3.4 An economy of autonomous businesses

There is no single database at this scale and usually no single agreed present.
Each organization keeps its own authoritative view. Coordination happens
through signed protocol messages:

```text
offer -> quote -> mandate -> acceptance -> performance -> settlement -> receipt
```

The shared unit is therefore not a row. It is a versioned contract instance
with identities, terms, deadlines, authority chains, state transitions, and
receipts. Each party atomically records the message in its own ledger before
acting. The counterpart's signature proves what it said; it does not force both
databases to commit atomically.

Emerging agent-payment work has the right shape. AP2 distinguishes an open
mandate containing a person's constraints from a closed mandate bound to a
particular checkout, requires deterministic verification even when a role is
agentic, and returns signed receipts that can be assembled as dispute evidence
([AP2 specification](https://github.com/google-agentic-commerce/AP2/blob/main/docs/ap2/specification.md)).
This is more revealing than the payment details: future machine commerce is
likely to exchange **constrained mandates and receipts**, not broad API keys
and prose prompts.

Economic state remains plural even with signatures. One party may record
“shipped,” another “not received,” and a carrier a third fact. A protocol must
name the authority for each transition and the evidence accepted in a dispute.
A transparency log can prove inclusion and detect equivocation; it cannot
decide whether goods conformed, create atomicity across firms, or replace a
settlement/dispute authority. The IETF SCITT architecture likewise builds on
signed statements, append-only logs, and receipts rather than treating the log
as an oracle of semantic truth
([SCITT architecture](https://datatracker.ietf.org/doc/draft-ietf-scitt-architecture/05/)).

## 4. The primitives this implies

### 4.1 Commands and transitions, not agent-authored CRUD

The schema type is necessary but not sufficient. A model tells the compiler
what states are representable. A transition tells it which changes are legal.
The autonomous-facing API should be generated from declarations resembling:

```avra
@model
type Account = {
    balance: decimal
    version: Revision
}

@transition
fn transfer(
    from: Account,
    to: Account,
    amount: Positive<decimal>,
    using authority: Spend<from>,
    because mandate: Mandate,
) -> Receipt<Transfer>
requires from.balance >= amount
preserves total(from.balance + to.balance)
```

The spelling is illustrative. The semantic requirements are not: the compiler
must know the read set, write set, invariant, authority class, idempotency
identity, and evidence emitted by a transition. Generated SQL is one projection
of that declaration. The agent tool schema, authorization check, audit event,
simulation interface, and documentation are others—P12 applied to behavior,
not only records.

Raw typed SQL remains the P8 escape hatch for trusted implementation code. It
should not silently become the public tool granted to an autonomous planner.

### 4.2 Assertions with provenance

Agent-derived information should be first-class attributed data:

```avra
type Assertion<T> = {
    value: T
    source: EvidenceRef
    observed_at: Time
    valid_during: Interval?
    confidence: Probability?
}
```

This is not a demand that every ordinary field carry confidence. It is a
boundary between an observation and an adopted business fact. A deterministic
transition may accept an assertion after checking its source and policy, then
emit a fact naming the assertion it relied on. Provenance is a graph of causes,
not a debug string attached after the decision.

### 4.3 Invariants choose the coordination model

The storage primitive should follow the invariant:

| Transition property | Cheapest correct mechanism |
|---|---|
| append-only fact | local append, asynchronous replication |
| commutative/idempotent merge | CRDT or deterministic merge |
| conflict visible and reconsiderable | optimistic version check |
| scarce resource can be partitioned | escrow or preallocated rights |
| global uniqueness/conservation | serialization or consensus domain |
| multi-row invariant in one authority | serializable transaction |
| multi-party long-lived process | protocol state machine plus compensation |

This classification is more useful than promising one universal distributed
database. The compiler can refuse a requested availability mode when a
declared invariant makes it impossible, naming the invariant that requires
coordination.

### 4.4 Durable work and effect receipts

A committed transition often creates work outside the database. The state
system needs an atomic outbox/effect journal: commit business state and the
intent to perform an effect together, then let a durable worker retry it.

Each effect needs:

- a stable idempotency key understood by the remote service;
- attempt history and backoff policy;
- an authority witness valid for that effect;
- a result receipt or durable uncertain state;
- an explicit compensation when one exists;
- a terminal escalation path when neither retry nor compensation is safe.

There is no general exactly-once remote call. Exactly-once business effect
requires either one transactional authority or cooperation from the remote
protocol through idempotency and receipts. “Request timed out” means “outcome
unknown,” not “nothing happened.” The type/state machine should make that
uncertainty representable.

### 4.5 Static capability plus live mandate

The ORM document's `Capability<Model, Fields>` is useful for compile-time data
minimization: code that cannot name `balance` cannot leak it accidentally. It
is not sufficient authorization for an autonomous business.

Real authority is dynamic. It expires, is revoked, has spend/rate limits,
depends on the resource's current owner, and crosses process and organization
boundaries. The complete shape is:

```text
static capability  = maximum authority this code can express
live mandate       = authority this principal has for this action now
commit check       = mandate still fresh and bound to this exact transition
```

Attenuation should work in both layers. A parent can compile a child against a
narrower capability and mint a shorter-lived mandate with a smaller budget.
Macaroons demonstrate decentralized credentials with contextual caveats and
attenuation ([Macaroons paper](https://research.google/pubs/macaroons-cookies-with-contextual-caveats-for-decentralized-authorization-in-the-cloud/));
Zanzibar demonstrates why authorization decisions must preserve causal order
with the object changes they protect
([Zanzibar paper](https://research.google/pubs/zanzibar-googles-consistent-global-authorization-system/)).

The check belongs at commit, after the final payload is known. Checking when a
plan begins leaves a time-of-check/time-of-use hole in every long-running agent.

### 4.6 History, snapshots, branches, and corrections

An append-only transaction history enables audit and reconstruction; Datomic's
model of immutable atomic facts and an indelible chronological transaction log
is strong prior art ([Datomic overview](https://docs.datomic.com/datomic-overview.html)).
But four operations must remain distinct:

- **snapshot**: a read-only view of recorded state at transaction time;
- **valid-time query**: what the system now believes was true at a past real
  time;
- **branch**: a private hypothetical future based on a snapshot;
- **correction/compensation**: a new committed event that changes the current
  interpretation or counteracts an earlier effect.

`as_of(t)` is therefore a view, not an ordinary copy of `Db`. Writing from it
must either be refused or create an explicit branch. Globally distributed
systems already use multiversion state to support non-blocking reads in the
past while retaining externally consistent transactions
([Spanner paper](https://research.google/pubs/spanner-googles-globally-distributed-database-2/)).

Likewise, `replay(excluding: mistaken_writes)` is safe only for a private
counterfactual. Later decisions may have read those writes, models may produce
different results, and external parties may have acted on them. Production
recovery needs causal invalidation plus explicit corrective transitions; it
cannot pretend history was unobserved.

Append-only is also not permission to retain everything forever. Evidence
classes need retention, encryption, selective disclosure, and a deletion or
crypto-erasure policy. Model prompts and tool results can contain far more
sensitive data than the business transition they justify.

### 4.7 Contracts are more than schema hashes

A content hash of a type is an excellent identity for its exact structural
shape. It does not express:

- field meaning, units, or legal jurisdiction;
- invariants and allowed transitions;
- compatible evolution versus exact equality;
- which party has authority for each transition;
- deadlines, cancellation, compensation, and dispute rules;
- delivery, replay, and idempotency semantics;
- signatures over a particular contract instance.

Cross-organization interoperability therefore needs a typed **protocol**, not
only a shared model. The type remains the source of truth, but the compiler
fingerprints the whole protocol declaration and derives wire schema, state
machine, verifier, compatibility relation, mandate, and receipt formats from
it. Exact hash equality is one compatibility mode, not the only one.

## 5. What the ORM proposal gets right

The ORM direction is unusually well aligned with autonomous systems:

1. **Schema as a type.** An agent should select over a compiler-known
   vocabulary, not rediscover a database through prose or live introspection.
2. **One source, many projections.** DDL, migrations, query tools, protocol
   schemas, documentation, simulations, and policies should derive from the
   same declarations.
3. **Dialect fidelity.** Hidden weakening is especially dangerous when the
   caller is a machine that will trust the declared contract literally.
4. **Typed escape hatch.** Autonomous systems will meet queries no builder
   anticipated; refusing untyped strings without refusing power is right.
5. **Capabilities and attenuation.** Least authority must survive delegation
   across a swarm.
6. **Temporal state.** Agents need to explain, simulate, recover, and learn from
   prior decisions.
7. **Signed cross-company evidence without blockchain.** Known counterparties
   normally need attributable messages and receipts, not anonymous consensus.

The central insight—make an agent choose among compiler-checked meanings rather
than synthesize unchecked syntax—is the right foundation.

## 6. Where the ORM proposal should change

### 6.1 Put transitions between queries and time travel

Phases 1–6 build data access. Before the frontier moves to temporal databases
and cross-company negotiation, it needs a transactional command layer:

- declared state transitions and invariants;
- optimistic expected versions;
- idempotency identities;
- commit-time mandates;
- causal events and receipts;
- atomic durable work creation.

Without this layer, Phase 8 records arbitrary CRUD more carefully. With it,
Phase 8 records business decisions.

### 6.2 Split capability into visibility and authority

Keep field capabilities for static read/write vocabulary, but do not claim
that their type parameter is authorization. Add a runtime mandate/witness
checked against current state at commit. The compiler should ensure code cannot
ask for more than its static ceiling; the commit kernel should ensure the
particular request remains allowed.

### 6.3 Replace database “copy” and agent undo

The identity-versus-copy law for ordinary Avra values should not make a
historical database handle behave as if it were a cheap independent database.
Use explicit `Snapshot<Db>` and `Branch<Db>` concepts. A branch can support
simulation and counterfactual comparison. Merging it is a set of new commands
revalidated against current state, never pointer-like replacement of reality.

Replace `replay(... excluding: writes.by(agent))` as a production promise with:

- `counterfactual(excluding: ...)` for analysis;
- causal descendants to identify affected decisions;
- corrective transitions for internal facts;
- compensation/reversal for external commitments.

### 6.4 Promote bitemporality to provenance

Valid time and transaction time are necessary, but agents also need the source
and causal path of a claim. Make temporal metadata part of an evidence model,
not only hidden shadow-table columns. “When did we know?” and “why did we
believe it?” are different queries.

### 6.5 Expand Phase 9 from model agreement to protocol agreement

Fingerprint transitions, invariants, role authority, and wire semantics along
with record shapes. Generate signed mandates and receipts. Treat the shared log
as evidence transport, not global semantic truth. Define version negotiation,
timeouts, duplicate delivery, cancellation, compensation, and dispute before
calling the contract interoperable.

### 6.6 Do not make shadow tables the abstraction

SQLite shadow tables may be one storage projection, but the language-level
abstraction should be a transaction/event/evidence history with explicit
semantics. Otherwise backend mechanics leak into the model and later make
Postgres logical decoding, native temporal tables, or an event store look like
incompatible concepts.

## 7. Recommended frontier sequence

Leave ORM Phases 1–6 substantially as written. They make the typed vocabulary
real before asking it to carry autonomy. Replace the current frontier with:

| Phase | Ships | Why it precedes the next |
|---|---|---|
| **7 — transactional authority** | state transitions, invariants, expected versions, static capability + live mandate, idempotent receipts | establishes the only legal path into authoritative state |
| **8 — durable work** | workflow state machines, atomic effect journal, retry policy, uncertain outcomes, compensation | makes long-running agency survive crashes and remote failure |
| **9 — temporal evidence** | immutable transaction history, valid/recorded time, provenance graph, snapshots and speculative branches | history now records meaningful transitions rather than raw row edits |
| **10 — swarm coordination** | leases, fencing epochs, causal delegation, joins, invariant-directed merge/serialization | safely permits many agents and disconnected replicas |
| **11 — inter-organization protocols** | typed roles and protocol states, negotiation, mandates, signed messages and receipts, compatibility, disputes | projects the same transition laws across trust boundaries |

This sequence does not require building a workflow engine or replicated
database during the ORM campaign. It does require leaving the right seam:
generated model mutation must be able to move behind a command/transaction
boundary without changing what a model means.

The first real consumer for Phase 7 should be deliberately small: an agent may
reserve and release a scarce resource under a bounded mandate. Two concurrent
agents race; one observes a typed version conflict and replans. A repeated
command returns the same receipt. Revocation between planning and commit is
honored. That single example exercises the architecture more honestly than a
large agent-memory demo.

## 8. Failure tests the design must pass

| Event | Correct outcome |
|---|---|
| agent retries after losing the response | same command receipt, no duplicate mutation |
| worker lease expires, old worker returns late | fencing epoch rejects the zombie write |
| authority revoked while model is reasoning | commit-time check refuses the transition |
| two agents reserve the last item | invariant chooses one winner or a declared allocation policy |
| model/tool result changes during recovery | replay consumes recorded result; a fresh call creates a branch |
| remote payment times out after local commit | state becomes `outcome_unknown`; reconcile by idempotency key/receipt |
| cancellation arrives after shipment | future steps stop; shipment remains history; compensation policy begins |
| mistaken fact influenced later decisions | causal descendants are surfaced; correction does not erase evidence |
| replica merges independently valid changes | merge is accepted only if the declared invariant is confluent |
| counterparty sends the same message twice | protocol instance deduplicates by signed message identity |
| schema grows compatibly | negotiated compatibility accepts the projection without exact-hash equality |
| sensitive evidence reaches retention limit | policy erases/redacts protected payload while preserving allowed proof |

If an API cannot state one of these outcomes, it is not yet an autonomous-state
API. It is CRUD with an agent in front of it.

## 9. Decisions to carry back into the ORM design

1. Keep the type as the single source of structural truth.
2. Add behavior as another single source: typed transitions and invariants,
   from which SQL, tools, authorization checks, events, and docs project.
3. Treat an agent as an untrusted nondeterministic planner, even when it belongs
   to the same business.
4. Separate speculative branches from canonical snapshots and committed
   corrections.
5. Pair static capability with dynamic, attenuable, expiring mandates checked
   at commit.
6. Make idempotency, causality, provenance, and effect receipts structural—not
   optional columns remembered by application authors.
7. Let invariants determine coordination rather than choosing one consistency
   model for the entire database.
8. Model an autonomous business as durable state machines and ledgers occupied
   by replaceable agents, not as one immortal agent with a large memory.
9. Model an autonomous economy as protocols among plural authorities, not as a
   shared database.
10. Use append-only history to explain and correct the world, never to pretend
    externally observed history did not happen.

The shortest form of the finding is:

> **Future AI will interact safely with state by proposing typed, attributable,
> replay-safe transitions under bounded authority. The database will accept,
> serialize, remember, and prove those transitions; durable workflows will
> carry their effects into the world; signed protocols will carry them across
> organizations.**
