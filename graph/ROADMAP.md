# Personal graph roadmap

## Destination and invariants

An embeddable, generic, self-updating personal knowledge graph. An
application declares models, collects their generated descriptors, and
starts the engine. Local adapters/workers supply observations; an agent may
edit the model source and rebuild. Classifiers, including Jev, are
interchangeable producers outside the engine. Ingestion should not require
a reasoning agent or generative LLM. Contextual English questions are a
separate, evidence-grounded query layer; see [RESEARCH.md](RESEARCH.md).

- Ontology-specific names and behavior belong in model declarations and
  their declarative validation/policy layer, never engine handlers.
- Models are the source of truth for validation, codecs, introspection,
  references, and eventual migration planning.
- SQLite is the durable authority. Computation caches are reconstructible.
- Claims are distinct from their support. Replacement withdraws only the
  contribution owned by one producer and scope.
- Unknown, null, withdrawal, and conflict are different states.
- Defaults are construction behavior, not observations of omitted facts.
- Publication is atomic, idempotent, and tied to input/schema revisions.
- Failed extraction is not a successful replacement with an empty result.
- Historical evidence remains interpretable under its original schema.
- Confidence does not silently become authority.
- Fundamental substrate gaps get tasks-db issues, not ontology-specific
  workarounds or a duplicate validation engine.

## Current checkpoint

Branch `feat/graph-selection`, worktree
`/Users/tristan/projects/tristanMatthias/avra-graph-v2`, rebased onto main
`846e8a84` (batch #1152, incorporating #1141). `git log graph/` is the
receipt for each slice; the original foundation is `f87d7312`.

The first slice is a usable model-driven evidence store, not yet an
autonomous extraction or inference system.

| Area | Baseline state |
| --- | --- |
| Model-only ontology; generated registration | Working |
| Standard validation and generated codecs | Working |
| Scalars, optionals, lists, embedded records, typed references | Working |
| Std-first SQLite storage (`@std/db` engine models) | Working; format 8 |
| Immutable observation history | Working |
| Atomic replacement, replay, stale input/schema/revision rejection | Working |
| Independent support, conflicts, and explanations | Working |
| Entity reads, model listing, edges, bounded breadth-first traversal | Working |
| Shared CLI and authenticated loopback HTTP protocol | Working |
| Model evolution | Conservative whole-catalog invalidation |
| Reprocessing | `dirty` inspection; no worker or durable job scheduler |
| Partial assertions | Working; field rules only, record rules on assembly |
| Evidence locators | Working; opaque per-record JSON, returned by `explain` |
| External identities | Working; namespace/key names, owned by producer and scope |
| Confidence metadata | Working; finite 0..1, returned by `explain`, never authority |
| Explicit choices | Working; one per entity/property, reversible, never evidence |
| Merge/split | Working; explicit decisions, read groups, reversible split |
| Deletion/tombstones | Working; hides live reads, history and revival kept |
| Selection policy, derived rules | Not in baseline |

Baseline verification: 11 store tests, 7 partial-assertion tests, 6
evidence-locator tests, 10 external-identity tests, 9 merge tests, 8
tombstone tests, and `std/validate`'s
projection suite; native CLI/HTTP smoke tests covering persistence, partial
assertions, evidence locators, external identities, replay, validation,
rollback, traversal, authentication, and stale-input invalidation; an
unrelated library consumer with an eight-field model, a cyclic reference, and
a record-level rule. These are foundation tests, not a production readiness
claim.

Stabilization adds interaction witnesses for retained/refreshed identities,
group-wide choices, conflicting pre-merge choices, historical source
revisions, tombstoned incoming sources, nested read snapshots and page
overflow. Native durability witnesses cover additive formats 6/7→8,
unsupported/missing-format refusal before catalog mutation, WAL, lock
waiting, established reader snapshots, and a killed uncommitted writer.
These are focused checks, not full concurrent/fuzz/soak coverage.

The engine's tables are `@std/db` models with links, many-relations and
nullable history columns; only user ontology rows are generic. The six-field
cap is split (`RunRow`/`RunTrailRow`) and composite identity is a derived
`@unique stamp`; both are filed as surface asks.

The working API and operational instructions live in [README.md](README.md).
Architecture and substrate receipts live in [DESIGN.md](DESIGN.md).

## Milestone 0 — stabilize and integrate

Status: local foundation verified; integration and hardening ongoing.

- [x] Fix generic static-owner inference for typed reference codecs.
- [x] Fix collections gathering nested quoted template declarations.
- [x] Complete compiler-fix integration through the protected PR workflow.
- [ ] Fix package-rename invalidation of held generic/collection identities.
- [ ] Add cold/warm rebuild tests for source model edits and schema changes.
- [ ] Exercise concurrent connections, interrupted transactions, and recovery.

Exit: fresh checkouts and warm rebuilds produce equivalent correct behavior;
the required fixes are integrated, not merely present in one worktree.

Substrate tracking:

- `avra-8sb5.63.23`: generic named field decoding; parent PR
  https://github.com/avra-lang/avra/pull/1132.
- `avra-8sb5.63.24`: quoted nested functions entering collections; local fix
  and interpreter/native regression, with 102 existing collect tests passing.
- `avra-8sb5.63.25`: stale held symbols after a manifest package rename;
  open, with a cold rebuild verified and the old cache preserved.
- `avra-8sb5.63.15`: broader generic derive support; separate from the
  manually implemented generic relationship type.

## Milestone 1 — complete the assertion model

Status: partial assertions work; structured validation errors remain open.

- [x] Accept partial properties without constructing a complete record.
- [x] Use standard validation for supplied field shapes and rules; never
  invent missing required fields or use defaults as evidence.
- [x] Keep record-level validation at complete-record assembly boundaries.
- [x] Test missing, explicit null, replacement/withdrawal, and conflict
  independently, including sibling-dependent validation.
- [x] Add generic evidence locators: source offsets, sections, attachments,
  or other source-native locations, linked to immutable input revisions.
- [ ] Expose structured validation/incompleteness issues (codes and paths;
  current public failures are formatted strings).

Exit: an agent can publish incomplete knowledge honestly; a typed read either
constructs a validated record or explains why it cannot. Evidence can be
traced to a specific place in the source.

## Milestone 2 — identity and conflict policy

Status: external names, merge/split, and tombstones implemented; selection
selection policy remains.

- [x] Resolve `(namespace, external_key)` identities and aliases.
- [x] Add explicit, reversible merge/split decisions with provenance.
- [x] Define tombstones, deletion, and dangling-reference behavior.
- [x] Explicit user choice: a decision names the claim a property reads
  through, one per entity and property, and is revocable.
- [ ] Declare source priority and recency policies where the model/policy
  asks for them.
- [x] Store confidence as evidence metadata, separate from authority.

Exit: different sources can identify the same entity without silent
duplication or irreversible automatic merging. No domain-specific merge code.
External names are owned by their producer and scope, so replacement keeps
provenance; a merge is a reversible decision rather than a rewritten row, and
a tombstone hides reads without deleting evidence or its history.

## Milestone 3 — useful generic queries

Status: basic reads and traversal implemented; richer queries planned.

- [ ] Add indexed property predicates and reverse-reference filters.
- [ ] Add pagination, deterministic ordering, and explicit work budgets.
- [ ] Add bounded multi-hop pattern queries.
- [ ] Add historical revision reads and change feeds.
- [ ] Start text search with SQLite FTS5 where workload warrants it.
- [ ] Explain query answers through statements and supporting observations.

Start with parameterized SQL and measured indexes. Basic traversal is
breadth-first with cycle detection and node/depth bounds; introduce more
elaborate algorithms only for demonstrated queries.

Exit: an agent can ask useful questions through the public API without SQL
access, and costs remain bounded on adversarial or cyclic inputs.

## Milestone 4 — durable processing and classifiers

Status: `dirty` exposes stale interpretations; orchestration remains external.

- [ ] Persist pending jobs, leases, retries, cancellation, and failures.
- [ ] Track dependencies on multiple observations and graph query results.
- [ ] Track producer/code/model versions and reprocessing requirements.
- [ ] Define the generic local-agent/classifier worker protocol.
- [ ] Exercise repeated delivery, worker crashes, and stale completion.
- [ ] Connect a real classifier through the protocol, without adding its
  ontology or SDK to graph storage/query logic.

Exit: changed inputs reliably refresh knowledge after restarts and classifier
failures, and old work cannot overwrite newer results.

## Milestone 5 — incremental derived knowledge

Status: planned; no inference engine is claimed by the current slice.

- [ ] Declare derived properties and relationships in the model/policy layer.
- [ ] Record fact/query dependencies and target invalidation precisely.
- [ ] Establish correct recomputation before optimizing incremental updates.
- [ ] Withdraw conclusions when their support disappears.
- [ ] Handle cycles and bounded fixed points where explicitly appropriate.
- [ ] Trace derived conclusions all the way back to observations.
- [ ] Integrate reconstructible `std.relation` projections after measuring
  actual workloads; SQLite is not automatically a relation backend.

Exit: a changed fact updates affected conclusions, removed support retracts
unsupported conclusions, and cache reconstruction preserves the answers.

## Milestone 6 — safe source-edited model evolution

Status: source edit/rebuild works; every catalog change currently invalidates
older interpretations conservatively. Basic migration safety applies earlier
too; compatibility optimization is this milestone.

- [ ] Give model/property identity a stable representation independent of
  display names, with explicit rename semantics.
- [ ] Classify additions, renames, removals, type changes, and rule changes.
- [ ] Target revalidation and re-extraction instead of invalidating everything.
- [ ] Require explicit migration plans for incompatible changes.
- [ ] Stage edit -> compile -> inspect schema diff -> test -> activate.
- [ ] Roll back executable/catalog activation safely.
- [ ] Preserve interpretation of original historical schemas and evidence.
- [ ] Define runtime/native-library upgrade invalidation; compiler code hashes
  currently hash external calls by symbol, not by C implementation.

Exit: additive changes do not invalidate unrelated knowledge, and incompatible
changes cannot silently reinterpret existing facts.

## Milestone 7 — dependable daily operation

Status: basic local CLI/HTTP and security boundary implemented; hardening planned.

- [ ] Backup/restore and integrity/recovery commands.
- [ ] Retention, compaction, and storage-format upgrades.
- [ ] Structured errors and clearer command ergonomics.
- [ ] Resource limits, benchmarks, concurrency tests, fuzzing, and soak tests.
- [ ] Sensitive-data handling and explicit access boundaries.
- [ ] Optional inspection UI over the same generic API.

Exit: the service can run continuously, recover from failures, and explain
its state and decisions. A UI is optional, not an engine dependency.

## Language and library work

No additional fundamental language feature is known to be necessary for the
baseline. Enums, generic model derives, record spreads, and arbitrary maps
remain unsupported by this graph slice and need explicit standard-library
and graph integration work. The graph itself has no fixed field-count limit.

The protocol's request parser is hand-written because `@derive(Decode)` over a
tagged enum is still open (`avra-8sb5.63.15`); model validation itself is
derived. `@std/db`'s `@model` IS the graph engine's storage: one derived table per
engine row, typed links, `Many<T>` batched reads, nullable `until` history,
and `where`/`in_<link>`/`with_<many>` accessors. User ontology types never
become tables; their claims are rows of `ClaimRow`. The remaining asks are
surface: a 7+/8-field row without splitting (`RunRow`+`RunTrailRow`,
`MergeRow`+`MergeEndRow`) and composite `@unique` (today a derived `stamp`).
The field-ceiling fix is independently owned; graph correctness and NLP
evaluation do not wait for it. Indexed/bounded generated reads are tracked
in `avra-8sb5.44.8`; this milestone does not claim indexed query performance.

Future substrate requests must identify a concrete wanting site and a
reproducer. Partial assertions and external identities have boundary tests;
do not assume relation invalidation or retraction is solved until its own
boundary test passes.

## Execution order and progress discipline

The concrete acceptance scenario, gold answer projections and small
dependency-ordered agent assignments live in
[acceptance/PLAN.md](acceptance/PLAN.md). That plan is the next vertical-slice
work queue, not a claim that extraction or English querying already works.

Stabilize -> identity -> richer queries -> durable workers -> incremental
derivations -> compatibility-aware evolution. Partial assertions, evidence
locators, and external names landed with the foundation.
Operational and migration safety accompany every milestone.

Keep this roadmap current as changes are verified. Check off behavior, not
just code written; record what remains. Keep protocol details in README and
architectural decisions in DESIGN rather than maintaining conflicting copies.
