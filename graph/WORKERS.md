# Durable worker and classifier jobs

This document designs milestone 4: durable processing and classifiers.
The graph remains a generic evidence store. Classifiers, including a
local NER model, are ordinary producers that read observations, do work
outside the engine, and publish records.

The engine persists work and enforces its transitions. It does not run
classifiers, choose models, schedule processes, or contain a scheduler.
The local agent owns invocation and policy. This keeps model vocabulary
and retry policy out of graph storage and query logic.

## 1. Ownership boundary

| Concern | Owner |
| --- | --- |
| Job rows, dependency requirements, leases, attempts, terminal outcomes | Engine |
| Atomic claim, heartbeat, complete, fail, cancel transitions | Engine |
| Lease expiry, token checks, stale completion rejection | Engine |
| Idempotent run identity, optimistic graph revision, publication admission | Engine |
| Observations, claims, support, identities, merge/choice/tombstone decisions | Engine |
| Schema fingerprint and producer/code version recorded on a job | Engine |
| Deciding what work exists and when to enqueue it | Agent |
| Choosing a classifier, prompt, model version, and runtime | Agent |
| Retry policy: attempt limit, backoff schedule, poison handling | Agent |
| Candidate generation and mention extraction | Classifier/producer |
| Interpreting an observation's payload | Classifier/producer |
| Process supervision, concurrency, transport, secrets | Agent |

The engine never parses an observation, never infers that two entities
are the same, and never uses confidence to select a winner. Entity
linking is expressed only through producer-owned external identities
and explicit merge/choice decisions. There is no automatic similarity
matching in the engine.

An NER producer follows this shape:

1. The agent records a source as an observation.
2. The agent enqueues extraction work for that observation revision,
   producer version, and schema fingerprint.
3. A worker claims the job and reads the observation at that revision.
4. The worker extracts mentions and candidate external identities.
5. The worker publishes records, partial records, locators, identities,
   and confidence. It does not publish an empty result for a failure.
6. A human or agent resolves ambiguity with merge, split, or choice
   decisions. The classifier may propose evidence; it does not decide
   identity silently.

Records are the engine's only contribution unit. What a mention is
belongs to the application's declared models, not to the engine.

## 2. Durable job model

Recent engine rows use the `@std/db` model subset. Every row below has
at most six fields, counting its `id`, links, and `@unique` stamp. The
cap is why one logical job is several rows: identity and requirements,
mutable lifecycle, leases, and outcomes have different lifetimes and
different readers.

| Row | Fields | Purpose |
| --- | --- | --- |
| `JobRow` | `id`, `@unique decision`, `producer`, `scope`, `input`, `input_revision` | Immutable job identity and primary input |
| `JobInputRow` | `id`, `job`, `input`, `input_revision`, `@unique stamp` | Additional observation dependencies |
| `JobQueryRow` | `id`, `job`, `query`, `revision`, `digest`, `@unique stamp` | Graph query dependencies and the answer they were built from |
| `JobStateRow` | `id`, `@unique job`, `schema`, `code`, `phase`, `ready_at` | Mutable lifecycle; one row per job |
| `JobLeaseRow` | `id`, `job`, `attempt`, `token`, `owner`, `deadline` | One row per claim; the attempt record |
| `JobCompletionRow` | `id`, `job`, `attempt`, `run`, `revision`, `@unique stamp` | Successful terminal outcome and its publication |
| `JobFailureRow` | `id`, `job`, `attempt`, `phase`, `message`, `@unique stamp` | Failed attempt, terminal failure, or cancellation |

Why the split:

- `JobRow` names the work and its immutable primary input. It never
  changes. A changed input revision is a different job decision.
- `JobStateRow` is the only mutable row. `phase`, `ready_at`, schema,
  and code are read on every claim.
- `JobLeaseRow` is append-only history except for heartbeat, which
  extends `deadline`. The current lease is the row with the greatest
  `attempt`; no separate "current lease" pointer is needed.
- `JobCompletionRow` and `JobFailureRow` keep terminal evidence out of
  the mutable state row. A nullable `run` link is avoided by splitting
  success from failure/cancellation.
- Additional inputs and query dependencies are separate rows because a
  model cannot hold a list of links and still stay within six fields.

`JobInputRow` records inputs beyond the primary one. The primary input
lives in `JobRow`; duplicating it in `JobInputRow` would be a second
projection of the same requirement.

### Phase

Persist `phase` as an integer code, not a string tag:

| Code | Phase | Meaning |
| --- | --- | --- |
| 0 | `Pending` | Claimable when `now >= ready_at` |
| 1 | `Leased` | One attempt holds a live lease |
| 2 | `Done` | A publication committed |
| 3 | `Failed` | Terminal failure |
| 4 | `Cancelled` | Withdrawn by an explicit decision |

The protocol projects these codes to a `JobPhase` enum at the boundary.
Engine code compares the enum, never a string.

`ready_at` is epoch milliseconds supplied by the caller. It carries
retry backoff without a separate table. Terminal phases ignore it.
Attempt counts are derived from `JobLeaseRow`; storing a counter in
`JobStateRow` would be a second copy that can drift.

### Time

The engine takes `now` as an argument on `enqueue`, `claim`,
`heartbeat`, `complete`, `fail`, `cancel`, and `jobs`. It never reads
the process clock. This keeps lease tests deterministic and makes the
clock an explicit agent responsibility. The local trust domain is one
machine or one Sprite; lease authority is the stored deadline, not a
worker's claim to be alive.

## 3. Dependencies and the work feed

A job's requirements are:

- one primary observation id and revision (`JobRow`);
- any additional observation id and revision (`JobInputRow`);
- any graph query and the graph revision and answer digest it used
  (`JobQueryRow`);
- the schema fingerprint installed when the job was made
  (`JobStateRow.schema`);
- the producer/code version (`JobStateRow.code`).

A job decision is immutable. The agent derives it from the full
requirement set, for example a digest of producer, scope, input
revisions, query digests, schema, and code. `enqueue` is idempotent on
`decision`:

- same decision and same immutable requirements: answer the existing
  job, whatever its phase;
- same decision and different requirements: refuse;
- a changed input, schema, or producer version: derive a new decision.

This mirrors the existing run-id replay rule. It also means a completed
job is never resurrected by a stale enqueue call. The engine enforces
the decision's uniqueness; the agent owns the derivation convention.

### From `dirty` to a feed

`dirty` remains a read-only projection. It answers "which latest
interpretations have a stale input revision or schema". It is not a
scheduler and it does not create jobs.

The loop is explicit:

1. `dirty`, or the `observe` answer, gives the agent a candidate.
2. The agent derives a decision from the candidate's requirements.
3. `enqueue` persists a job or returns the one already there.
4. `jobs` with `phase = pending` and `now >= ready_at` is the durable
   feed a worker polls or is handed.
5. `claim` takes one or more due jobs atomically.

Two gaps are deliberate:

- A brand-new observation has no previous run, so `dirty` cannot see
  it. The agent that calls `observe` enqueues; the write is the
  notification.
- A job whose requirements changed after enqueue is not silently
  rewritten. `claim` and `complete` detect staleness and refuse. The
  agent enqueues a new decision.

A later producer-registration or demand table can make step 1
automatic for a known producer/scope without changing the job model.

### Stale results

`complete` verifies before committing:

- the lease token still names the current attempt and `now` is within
  the deadline;
- the job is `Leased`, not terminal;
- `schema` equals the engine's current catalog fingerprint and the
  job's recorded schema;
- `code` equals the job's recorded code;
- every observation dependency still matches its recorded revision;
- every query digest presented at completion equals the recorded
  digest, and the worker has rechecked any query whose graph revision
  moved;
- `expected_revision` equals the current graph revision for the
  publication.

Outcomes differ by cause:

- wrong token, expired lease, or a non-current attempt: refuse with no
  state change; the current attempt (if any) owns the job;
- input revision, schema, or code changed: the attempt is superseded.
  Record a failure for that attempt and move the job to `Failed` with a
  "superseded" message. A new decision carries the new requirements;
- query digest changed: superseded, same treatment;
- graph revision conflict only: the work may still be valid. Record
  the attempt failure and return the job to `Pending` at `ready_at =
  now`, so a worker can retry the publication against the new
  revision;
- publication validation failure: nothing commits; the job stays
  `Leased` until the worker calls `fail` or the lease expires.

A stale completion must never overwrite a newer publication. That is
already true of `publish`; `complete` additionally binds the
publication to a current lease and current requirements.

## 4. Lifecycle and crash recovery

### Transitions

All transitions run in one SQLite immediate transaction. The engine
uses the same std-first store and rollback discipline as publication.

`enqueue`:

- insert `JobRow`, `JobInputRow` rows, `JobQueryRow` rows, and
  `JobStateRow` with `phase = Pending`, `ready_at = now` (or a supplied
  delay);
- replay an existing decision as described above.

`claim(job or due feed, owner, now, lease_ms)`:

- select due `Pending` jobs in `ready_at` order;
- validate the job's current requirements; supersede a job whose
  requirements no longer stand instead of handing it out;
- compute `attempt = max(JobLeaseRow.attempt for job) + 1`;
- insert a `JobLeaseRow` with a fresh random `token`, `owner`, and
  `deadline = now + lease_ms`;
- set `JobStateRow.phase = Leased`;
- answer the job, its requirements, schema, code, attempt, token, and
  deadline.

`heartbeat(token, now, lease_ms)`:

- the token must name the current attempt, the job must be `Leased`,
  and `now` must be before the deadline;
- set `deadline = now + lease_ms`;
- return the job's phase so a cancelled worker can stop.

`complete(token, publication, now)`:

- verify lease, token, deadline, state, requirements, and expected
  graph revision;
- admit the publication inside the same transaction: validate records,
  check references and identities, close the producer/scope's previous
  support, insert claims/support, advance the graph revision;
- insert `JobCompletionRow` with the attempt, run, and committed
  revision;
- set `JobStateRow.phase = Done`;
- commit all of it at once.

`fail(token, message, retry_at?, now)`:

- verify the current lease;
- insert `JobFailureRow` for the attempt with phase `Failed`;
- if `retry_at` is supplied, set `phase = Pending` and
  `ready_at = retry_at`;
- otherwise set `phase = Failed` and leave `ready_at` unused;
- commit.

`cancel(decision, decider, now)`:

- if already `Cancelled`, answer idempotently;
- if `Done` or `Failed`, refuse; a completed result is not withdrawn
  by cancellation;
- otherwise insert a `JobFailureRow` with phase `Cancelled`, set
  `phase = Cancelled`, and leave any lease row as history. The next
  heartbeat or completion from that token is refused. The engine
  cannot kill the worker; the agent's worker checks heartbeat and
  `jobs` for cancellation.

Lease expiry is not an active transition. A `Leased` job whose
deadline has passed becomes claimable again; the next `claim` inserts a
new attempt with a new token. The old token is permanently stale.

### What a worker may conclude after a crash

- `complete` is one transaction. Either the publication, completion
  row, and `Done` state all committed, or none did. There is no
  "published but not completed" state for a job.
- If a worker died after the commit and before receiving the answer,
  it retries `complete` with the same attempt and run id. The existing
  completion (or existing run id) is replayed and its revision is
  returned.
- If a worker died before the commit, a new claim gets a new attempt.
  The old token cannot complete.
- If a worker died after `publish` was called separately from
  `complete`, the run id is the recovery key: republishing the same
  run request returns the original committed revision. The job still
  needs its completion transition, so the recommended path is the
  atomic `complete`.
- A worker must not read "no answer" as "no commit". On reconnect it
  reads the job or completion, or replays the same run id.

### At-least-once and deduplication

The protocol is at-least-once:

- a lease may expire while a worker is still running, so two workers
  may hold the same logical work at different attempts;
- only the current attempt's completion is accepted;
- run ids are derived from the job decision and attempt, so a replay of
  one attempt deduplicates against the existing `RunRow`;
- records, claims, and support are replaced per producer and scope, so
  a successful re-run does not duplicate evidence;
- merge, choice, and tombstone decisions are explicit replayable
  decisions, never a side effect of job retry.

A worker that cannot finish within its lease should heartbeat, fail
with a retry time, or let the lease expire. It should not keep a token
past expiry and assume completion will be accepted.

## 5. NER producer flow

This section names NER only as a concrete producer. The engine sees
records, claims, identities, locators, confidence, and decisions.

1. **Observe.** The agent records text or a source item as an
   observation. The observation id and revision are the job's primary
   input.
2. **Enqueue.** The agent derives a job decision from the observation
   revision, producer/code version, schema fingerprint, and any query
   dependencies. It enqueues one job per source scope.
3. **Claim.** A worker receives the job, source id, revision, schema,
   code, candidate limits, and lease token.
4. **Extract mentions.** The worker reads the observation at exactly
   the recorded revision. It produces mentions with source spans. What
   a mention is belongs to the application's models: text, type,
   candidates, or a separate evidence record. The engine never
   interprets the span.
5. **Link candidates.** Candidate identities are producer-owned
   `(namespace, key)` names. The worker calls `resolve` for an existing
   name. A resolved name yields an entity id; the worker publishes
   evidence onto that id. An unresolved name can create a new entity
   with the identity, but only if no active run already binds it
   elsewhere.
6. **Publish.** The worker calls `complete` with partial or complete
   records. Each record may carry:
   - `id`: the stable entity id;
   - `model` and `value`: the asserted properties;
   - `locator`: source-native evidence, for example the mention span
     and section;
   - `identities`: external names this entity wears;
   - `confidence`: evidence metadata in `0..1`.
7. **Resolve.** Ambiguity is not resolved by similarity. A merge
   decision joins two entities into one read group; split withdraws it.
   A choice decision selects the claim a contested property reads
   through; unchoose restores the default rule. A tombstone hides an
   entity without deleting evidence. All are explicit, reversible, and
   carry a decider.

Mentions and their evidence:

- a mention's source position belongs in `locator`, which the engine
  stores opaquely and returns through `explain`;
- confidence belongs to the record's support, never to selection;
- a mention may be a partial record: only supplied properties become
  claims, so an uncertain field is omitted rather than invented;
- repeated publication from the same producer and scope replaces that
  producer's contribution, so a corrected extraction does not
  accumulate duplicates;
- an empty publication withdraws the contribution. A classifier
  failure must call `fail`, never publish an empty success.

Unresolved and ambiguous mentions:

- **Unresolved.** Publish the mention with no external identity, or
  leave the identity field absent. Do not bind a name to an arbitrary
  entity.
- **Ambiguous.** Publish candidate evidence as separate records or as
  application-declared candidate fields. Do not auto-merge. A later
  merge or choice decision settles it, with provenance.
- **Conflicting names.** If an identity is already bound to another
  entity, the publication is refused. The worker must use the resolved
  entity or wait for an explicit merge; it may not rebind another
  producer's name.
- **Tombstoned entity.** Publication onto it is refused. The agent
  must revive it or choose another target.

## 6. API and protocol sketch

Every operation is a graph operation, reachable through the same JSON
dispatch used by the CLI and authenticated loopback HTTP. The engine
library holds the semantics; transports only parse and render.

| Operation | Essential arguments | Answer |
| --- | --- | --- |
| `enqueue` | `decision`, `producer`, `scope`, `input`, `input_revision`, optional `inputs`, optional `queries`, `schema`, `code`, optional `ready_at` | Job summary and phase |
| `claim` | `owner`, `now`, `lease_ms`, optional `producer`, `limit` | Claimed jobs with requirements, token, attempt, deadline |
| `heartbeat` | `token`, `now`, `lease_ms` | Job phase and new deadline, or a stale-lease refusal |
| `complete` | `token`, `now`, publication fields (`id`, `producer`, `scope`, `input`, `input_revision`, `schema`, `expected_revision`, `records`) | Committed graph revision and job phase |
| `fail` | `token`, `now`, `message`, optional `retry_at` | Job phase |
| `cancel` | `decision`, `decider`, `now` | Job phase |
| `jobs` | optional `decision`, `producer`, `scope`, `phase`, `input`, `due`, `limit`, `offset` | Job summaries and dependency metadata |
| `dirty` | — | Stale interpretations, as today; no jobs created |

Publication through `complete` reuses the existing `publish` request
shape. `producer`, `scope`, primary `input`, `input_revision`, and
`schema` must agree with the job; `expected_revision` is the current
graph revision. A completion that disagrees is refused.

What stays outside the engine:

- the classifier invocation: process, prompt, weights, device, batch
  size, model download;
- the decision id derivation and the enqueue loop;
- retry limits, backoff values, poison-job policy, and whether an
  attempt is worth retrying;
- candidate generation, string matching, embeddings, and any other
  similarity heuristic;
- reading and parsing an observation payload;
- worker identity, authentication, and process lifecycle.

A worker may use CLI request files or HTTP; both speak these
operations. A worker that wants a job is the only caller that receives
its token.

## 7. Open questions

- **Clock authority.** The engine currently takes `now` from the
  caller. That is deterministic and testable but trusts one local
  clock. Is a monotonic lease generation enough, or does a Sprite need
  a store-owned timestamp?
- **Atomic completion.** Should `complete` always perform the
  publication, or may a worker publish first and complete second? The
  design prefers atomic, because it removes the
  published-but-unfinished window. Separate publishing would rely on
  run-id replay and a completion retry.
- **Job decision derivation.** Is the decision derived by the agent,
  the engine, or a shared helper? Derivation in the engine would need
  a canonical requirement encoder; derivation in the agent risks two
  spellings of one identity.
- **Query dependency verification.** `JobQueryRow` stores a query and
  its answer digest, but the engine cannot recompute a digest unless it
  runs the query through its own generic operations. Should it, or is
  a trusted local worker's digest acceptable?
- **Coarse graph revision.** A graph-wide `expected_revision` causes
  retries for unrelated changes. Fine-grained query result revisions
  or per-read consistency points would reduce contention.
- **Retry ownership.** `ready_at` and `fail` expose backoff, but the
  attempt limit and terminal decision remain agent policy. Should the
  engine cap attempts so a poison job cannot spin forever?
- **Cancellation latency.** Cancellation is immediate in storage but
  cooperative in the worker. Does a running classifier need a
  checkpoint protocol, or is lease expiry plus a heartbeat check
  enough?
- **Automatic feed.** `dirty` cannot see a brand-new observation and
  only sees prior runs. Is a producer registration/demand table the
  next slice, or does the agent's observe-then-enqueue loop stay
  canonical?
- **Retention.** How long are failed attempts, cancellations, and
  completed jobs kept? Evidence is never deleted; job history may be
  compacted separately.
- **Mention identity.** Are stable mention ids the producer's
  responsibility (source id plus span), or should the engine offer a
  derivation? The design leaves ids application-owned, like entity
  ids today.

## Suggested first slice

Small, engine-only, no compiler work, no scheduler:

1. Add `JobRow`, `JobStateRow`, `JobLeaseRow`, `JobCompletionRow`, and
   `JobFailureRow`. Keep `JobInputRow` and `JobQueryRow` for the next
   slice; the first slice accepts one primary observation.
2. Add `enqueue`, `claim`, `heartbeat`, `complete`, `fail`, `cancel`,
   and `jobs` to the library and the JSON dispatch.
3. Let `complete` admit the existing publication in the same
   transaction. Derive the run id from the job decision and attempt.
4. Bump the store format additively and create the new tables. No
   existing evidence row moves.
5. Test:
   - idempotent enqueue and conflicting requirements;
   - two claims cannot take one pending job;
   - lease expiry allows a new attempt and rejects the old token;
   - heartbeat extends only the current attempt;
   - completion is atomic and replayable;
   - stale input revision, schema, code, and graph revision are
     distinguished;
   - cancellation beats completion and refuses a done job;
   - failure with `retry_at` returns to the feed;
   - a crash between publish and completion is recovered by the same
     run id (or is impossible when `complete` is atomic).
6. Then add `JobInputRow` and `JobQueryRow`, multiple dependency
   validation, and the producer registration/feed question.

This slice makes changed inputs refresh after a restart, records
classifier failure honestly, and prevents an old worker from
overwriting newer knowledge. It does not yet run an NER model, choose a
retry policy, or add a scheduler.
