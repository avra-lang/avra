# Replaceable approaches without replacing the product

Modularity is a product requirement. We must be able to change extraction,
linking, question interpretation or storage strategy without rewriting the
application ontology or silently changing what stored evidence means.

This is a direction for implementation, **not a claim that the existing
graph engine already exposes every port below**. C01 supplies independently
buildable boundary declarations. Later tasks implement the integrations and
their replacement witnesses. Start with one implementation per boundary;
no dynamic plugin loader, dependency-injection framework or microservices
requirement is justified yet.

## Boundaries and authority

| Replaceable part | Boundary | What remains authoritative |
| --- | --- | --- |
| Input adapters (CLI, HTTP, document readers) | Original source content, metadata, version and byte coordinates | Immutable source revisions; transport is not fact authority. |
| Extraction (rules, classifier, encoder service) | Catalog + source/context → anchored proposals | Admission verifies model rules, anchors and modality; workers cannot commit facts or identities directly. |
| Candidate retrieval/ranking and coreference | Bounded candidates and evidence-bearing link proposals | Identity decisions remain explicit, reversible and distinct from similarity scores. |
| Question parser (constrained parser, optional question-only LLM) | Catalog + authorized context + question → read-only plan | Plan validator and executor; a parser cannot supply answer facts or write operations. |
| Query execution/indexes | Validated plan + fixed read revision → projections and support evidence | Snapshot, authorization, completeness and budget semantics; an index is rebuildable, not truth. |
| Selection/derived policies | Declared, versioned model policies → supported projections | Evidence history; no domain-specific winner or calculation hidden in engine code. |
| Durable storage | Sources, claims, supports, identity decisions, revisions and atomic publication | Stable evidence semantics and migration/restore verification; SQLite is the first implementation. |
| Scheduling/inference hosting | Versioned work requirements → complete or failed attempt | Engine-owned fencing, staleness checks and atomic publication, not worker clocks or transport success. |
| Answer presentation | Supported structured answer → JSON/CLI/UI | No renderer may invent facts, erase uncertainty or manufacture provenance. |

Provider types stop at the adapter. Inference runtimes can run out-of-process
behind C01 JSON contracts; in-process implementations need not serialize
internally. A local encoder service is an ordinary worker, not a reasoning
agent. Source text is always data, regardless of provider.

The composition root chooses implementations and infrastructure settings.
Application code stays model declarations plus minimal startup. Ontology
names, extraction hints, relationship labels and domain policies belong in
those declarations, never provider-selection switches or engine branches.
Infrastructure configuration may choose a provider or resource budget, not
introduce a second hand-maintained ontology.

## Implementation discipline

1. Domain-neutral declarations and boundary types depend on standard
   libraries, not concrete inference or persistence implementations.
2. Provider adapters depend on contracts. The engine consumes validated
   contracts, not a provider's private labels, tensors or SDK objects.
3. Isolate SQLite connection/transaction/generated-row details in the
   existing store layer. Introduce small semantic repository operations as
   real consumers need them; do not mirror every SQL method in a speculative
   universal storage interface. J03's transaction-borrowing publication is
   part of this boundary, not a provider-specific transaction escape hatch.
4. Deterministic admission and execution own safety. Their policies are
   separate from retrieval/ranking heuristics and replaceable model scores.
5. Prefer plain modules and ordinary typed calls. Add a trait/implementation
   seam when a second implementation or test double actually needs it. A
   remote boundary uses the same versioned data, not a new protocol per SDK.
6. Existing CLI compatibility is separate from the new C01 wire contracts.
   Translate deliberately at an adapter; do not silently reinterpret clients.

## What changes when an approach changes

- A new extractor checkpoint/code version produces a new versioned attempt
  over retained source revisions. Compare it in shadow mode first; only an
  explicitly selected producer/scope replaces that producer's contribution.
  Never relabel old claims as if the new model had produced them. Failed
  extraction cannot withdraw valid evidence as an empty success.
- A new linker can propose different decisions without rewriting source
  mentions or deleting prior identity decisions. Confidence alone cannot
  authorize merges. Existing citations remain interpretable.
- A new planner still emits validated plans. Executors advertise supported
  operations and refuse unsupported ones. Model capability differences are
  explicit; a common JSON shape does not imply equal extraction quality.
- A new schema is a versioned catalog produced from edited model source.
  Historical evidence retains its original schema association. Renames and
  type changes require an explicit mapping/migration or re-extraction; no
  guessed equivalence between similarly named properties.
- A new index can rebuild from evidence. A new persistence engine is a real
  migration: prove stable IDs/provenance, atomicity, replay, revision/time
  reads and crash recovery before cutover. Do not promise a zero-cost DB
  swap simply because a repository boundary exists.
- New wire behavior requires an explicit contract version/capability change
  and tests. Current strict decoders reject unknown fields/versions; even an
  additive field is not automatically backward compatible. Support old
  readers via a deliberate adapter or coordinated upgrade, not silent
  permissive parsing. Persisted storage versions evolve separately.

Version-one evidence semantics (sources versus proposed claims versus
identity decisions versus selected truth, modality, provenance and explicit
unknown/ambiguity) are invariants across these swaps. A deliberate product
change to an invariant requires a design decision and migration, not an
implementation secretly redefining the same contract.

## Replacement gates

E02/E03 exercise the same extraction boundary with independent adapters.
V04 proves ontology portability; it does **not** prove provider portability.
V05 separately exercises recorded extractor and planner implementations with
the same consumer, including malformed outputs and refused unsupported
operations. Recorded adapters prove wiring, not model accuracy.

As implementations arrive, keep tests for: provider selection without engine
edits; identical admitted proposals yielding identical semantic facts;
unchanged old evidence after an upgrade; failure leaving prior facts intact;
and restart/replay preserving provenance and revision reads. Safety and
authorization checks run for every implementation, never only the default.
Any future non-SQLite backend must run the durability and snapshot contract
suite before being called compatible. No such backend is in the first slice.
