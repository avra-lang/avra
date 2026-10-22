# Model-driven personal graph

An embeddable Avra library and a small local application. All example
ontology declarations live in `src/models.av`; storage, validation
integration, queries, CLI, and HTTP contain no domain model names.

This is an executable first slice, not a completed inference platform.

The full milestones, current checkpoint, and acceptance criteria are in
[ROADMAP.md](ROADMAP.md).

The non-generative ingestion pipeline, contextual references (such as
“my wife”), research candidates and evaluation plan are in
[RESEARCH.md](RESEARCH.md). They are direction, not implemented NLP features.

A synthetic personal/luxury-fashion-business acceptance set (30 inputs,
50 questions) and an agent-ready task queue start at
[acceptance/PLAN.md](acceptance/PLAN.md).

Embeddings can validate classifier proposals with
`admit_extraction(catalog, original_request_json, worker_response_json)`.
It returns distinct complete/failed outcomes, checks exact source anchors
and versions, and preserves field qualifiers without publishing anything.
The original request must come from the trusted caller, not the worker.
See [the admission receipt](src/ingest/E01-HANDOFF.md) for limits and what
still needs implementing before automatic extraction is usable.

`graph.link_exact(original_request_json, worker_response_json)` additionally
admits those proposals and resolves declared exact identity keys against one
current read snapshot. It returns links, ambiguity and historical-continuity
proofs without publishing or merging. Names and classifier scores never grant
identity authority. See [the linking receipt](src/ingest/L01-HANDOFF.md) for
scope and limits, including the remaining indexed-read substrate work.

## Application surface

The models module declares ordinary types and collects their generated
factories. No central entity enum, hand-written codec, SQL migration, or
per-model route is needed.

```avra
use @avra.graph.{model, Ref, Registration, registered}
use @std.validate.{length}

@model
export type Folder = {
    @length(min: 1) title: string,
}

@model
export type Note = {
    body: string,
    folder: Ref<Folder>?,
}

export collect models: List<Registration> = @registered in package
    as Registration { make: it } by it.name
```

The executable imports that collection and `run` from `@avra.graph`, then
calls `run(models)`. An embedding instead opens `Graph.open(path, models)` and
calls its methods. The library package is `@avra/graph`, physically here
under `graph/`, not under `packages/`.

`@model` composes `std.validate.Decode` with a value writer and metadata.
Optional typed identity, relation, time and unit bindings belong beside
these same declarations; see [MODEL-SEMANTICS.md](MODEL-SEMANTICS.md).
Validation annotations remain ordinary standard/custom validators.
`Ref<T>` reads a string entity id; a nested model is an embedded value.
Scalars, optional values, ordered lists, typed references, and nested
models are supported. Enums, generic model declarations, record spreads,
and arbitrary maps are not part of this slice. Models have no field-count
ceiling; the unrelated-domain fixture includes eight fields.

Keep declarations in a models module, not the executable entry file.
A package collection reaches its package's generated declarations;
closure collections intentionally exclude the program entry.

## Run

From the worktree root, using its compiler:

```sh
# Rebuild first if the standing compiler predates this branch's language fixes:
sh tools/watch.sh 3500 make avra
sh tools/watch.sh 3500 ./build/avra build graph/examples/notes
graph/examples/notes/src/main request --db /tmp/personal-graph.db graph/examples/schema.json
graph/examples/notes/src/main request --db /tmp/personal-graph.db graph/examples/observe.json
```

For HTTP, provide a private token file containing at least 24 bytes:

```sh
graph/examples/notes/src/main serve --db /tmp/personal-graph.db --port 7331 --token-file /path/to/private-token
```

The only endpoint is authenticated `POST /graph` on `127.0.0.1`.
Send `Authorization: Bearer …` and `Content-Type: application/json`.
The standard HTTP reader bounds bodies to 1 MiB. There is no public bind
option or CORS support. The database, observations, and explanations are
plaintext personal data: restrict filesystem permissions; validation's
`@secret` is not encryption or a read authorization system.

## Producer protocol

CLI request files and HTTP use exactly the same JSON operations:

| `op` | Other fields | Answer |
| --- | --- | --- |
| `schema` | — | Fingerprint, graph revision, model metadata |
| `observe` | `id`, `payload` string | Input revision and graph revision |
| `observation` | `id`, optional `revision` | Current or historical raw payload |
| `ingest` | `source`: v1 SourceEnvelope | Admitted source reference, graph revision, changed flag, first receipt time |
| `source` | `id`, optional `revision` | Current or historical structured SourceEnvelope |
| `publish` | See below | Committed graph revision |
| `admit` | `source`: SourceRef, `result`: C01 v2 ExtractionResult, optional `scope`, `candidates` | Committed revision, run id, replay flag, each record's entity, link and the extractor's resolution |
| `get` | `id` | Current plain candidates per property, including conflicts; `qualified` statements apart |
| `value` | `id` | Validated complete record, or refusal |
| `find` | `model`, optional `limit` | Live entity ids, one per merge group |
| `edges` | `id`, optional `incoming` | Typed reference paths |
| `traverse` | `id`, optional `depth`, `limit` | Breadth-first reachable ids |
| `explain` | `id`, `property` | Every historical support: locator, qualifiers, anchor, voice, valid time, supersession |
| `resolve` | `namespace`, `key` | `{"entity": …}` for the one entity that name means |
| `aliases` | `id` | The entity's active external names as `{namespace, key}` |
| `merge` | `id`, `left`, `right`, `decider` | Committed graph revision |
| `split` | `id` | Withdraw a merge decision; the entities read apart |
| `merges` | optional `id` | Decisions, active or withdrawn, touching that entity |
| `tombstone` | `id`, `entity`, `decider` | A decision hiding that entity and its group |
| `revive` | `id` | Withdraw a tombstone decision |
| `tombstones` | optional `id` | Tombstone decisions touching that entity |
| `choose` | `decision`, `claim`, `decider` | A decision to read a property through one claim |
| `unchoose` | `decision` | Withdraw a choice; the property reads by its rule again |
| `choices` | optional `claim` | Choice decisions, active or withdrawn |
| `dirty` | — | Latest interpretations with stale input or schema |
| `correct` | `id`, `decider`, `kind` (`same`, `different`: `left`, `right`; `wrong`, `true`: `entity`, `property`, `value`) | Committed graph revision |
| `uncorrect` | `id` | Undo one correction; committed graph revision |
| `corrections` | — | Every correction: kind, decider, request, effects, revisions |

### Structured input

`ingest` admits the provider-neutral envelope in
[contracts/README.md](contracts/README.md). This stores source data, not
extracted facts. For example:

```json
{
  "op": "ingest",
  "source": {
    "contract": 2,
    "source": {"observation": "note:example", "revision": 1},
    "authored_at_ms": null,
    "received_at_ms": 1792573200000,
    "author": null,
    "participants": [],
    "conversation": null,
    "media_type": "text/plain",
    "content": "Original text, preserved verbatim.",
    "frames": []
  }
}
```

Use observation IDs stable across updates. A new source proposes revision
1; changed content/context proposes the next consecutive revision. This is
the engine's admission revision, not a business document's version number.
A changed payload cannot reuse a known revision or skip history. Exact
replays of admitted revisions are no-ops, even after a newer revision exists;
they never revive older content. A receipt carries the reference actually
admitted and `changed`, not an assertion that new work ran.

JSON whitespace/key order and later receipt timestamps do not reprocess an
unchanged source. First receipt time stays immutable. A proposed next
revision with identical extraction-relevant content/context returns the
existing reference instead of creating an empty revision. Changes to original
text, authored time, author, participants, thread, media type or quoted frames
are material. Participant/frame order is currently preserved and material.

Positions are W3C Web Annotation selectors: half-open Unicode code points of
the original content, with an optional exact quote (a frame's `passage`, an
extracted field's `evidence`). Envelope `contract` is 2; a stored
version-one revision, whose frames held byte spans, reads as the same
passages without its payload being rewritten.
Quoted speakers are separate from source authors and confer no identity or
authorization grant. Standard Decode rejects unsupported versions, unknown
fields and invented coordinates before writing. There is no gold-answer or
fixture-identity input channel.

`source` reads admitted envelopes, including immutable historical revisions.
Legacy `observe`/`observation` remain available for opaque producer payloads;
do not mix the two formats under one observation ID. A structured read
refuses raw or mismatched envelopes rather than guessing metadata. The
HTTP bearer token still authorizes ingestion; source text never authorizes
an operation. Automatic scheduling/extraction is a later task, not a side
effect claimed by this ingestion receipt.

Embedders can call `windows(source, WindowPolicy {})` to build bounded
extraction inputs. Windows preserve original spans and quoted speakers;
optional whitespace collapse keeps a coordinate map. `window.anchor(...)`
converts a provider's declared UTF-8/code-point/UTF-16 span into original
source bytes and verifies its text. `mention_key` deduplicates the same
anchor across overlapping windows without assigning an entity. See
[src/ingest/I02-HANDOFF.md](src/ingest/I02-HANDOFF.md) for limits and witnesses.

### Publications

A publication replaces one producer's whole contribution in one scope,
whether its records are complete or partial. An empty `records` list
withdraws that contribution. A classifier failure must not be published as
an empty success.

```json
{
  "op": "publish",
  "id": "unique-run-id",
  "producer": "extractor-version",
  "scope": "source-item-id",
  "input": "source-item-id",
  "input_revision": 1,
  "schema": "fingerprint returned by schema",
  "expected_revision": 2,
  "records": [
    {
      "id": "stable-entity-id",
      "model": "declared-model-name",
      "value": {},
      "locator": {"section": "body", "span": [12, 18]},
      "identities": [{"namespace": "mail", "key": "ada@example.com"}],
      "confidence": 0.82
    }
  ]
}
```

The empty object above is schematic. A record's `mode` is `"complete"`
(the default) or `"partial"`. A complete `value` must satisfy that
model's whole-record decoder. A partial `value` is validated field by
field: supplied properties use the same shapes, annotations, sibling
rules, and issue paths as the complete decoder, while missing properties
stay missing and defaults are not applied as evidence. Record-level
validators run only when a complete record is assembled. Partial records
still replace the producer/scope contribution; `mode` is part of the
replay fingerprint.

A record's optional `identities` name it in producer-owned namespaces.
`resolve` answers the one entity an active run binds a `(namespace, key)` to,
and refuses a name no active run holds or one that names two entities.
Binding a name an active run already binds elsewhere refuses the whole
publication. A replacement withdraws the names its run owned, so a producer
may correct or rebind its own name while another producer's binding survives.
Names are lookups, never extracted properties.

A record's optional `confidence` is a finite number in `0..1`. It is
evidence metadata, never authority: it is stored beside the support the run
created, returned by `explain`, and never used to pick a winner. It is part
of the run's replay identity.

A record's optional `locator` is opaque JSON: the engine stores it beside
every claim that record supports and returns it through `explain`, but never
interprets or indexes it. Use it for source offsets, message sections,
attachments, or whatever the producer's source has. An absent locator stays
absent, and a locator is part of the run's replay identity.

An explicit merge decision joins two entities of one model into one read
group without moving a row: `get`, `value`, `edges`, `traverse`, `explain`,
`aliases`, and `find` all answer over the group. Equal supported values
collapse to one candidate; different values remain conflicts. `split`
withdraws the decision and the entities read apart again, with the decision
and its revisions kept as provenance. References and aliases are unaffected
by the group until read through it.

A tombstone decision hides an entity and its merge group from live reads:
`get`, `value`, `find`, `edges`, `traverse`, `aliases`, and `resolve` treat
it as absent, references to it do not surface as live edges, and
publications onto or into it are refused. Nothing is deleted: observations,
claims, support, explanations, and the decision itself stay readable, so
`explain` still traces the evidence. `revive` withdraws the decision and the
entity reads again.

Use application-owned, preferably namespaced stable ids; ids are global
across models. References can target identities from the same publication
regardless of record order, or previously committed identities. Target
models must match. Identity existence is distinct from having current
supported properties.

Read schema, record an observation, classify against its revision, then
publish against the latest graph revision. A stale graph revision calls
for a retry; stale input/schema calls for reclassification. An identical
run-id/request pair returns its original committed revision. Reusing a
run id with different content is refused.

Jev or another classifier is an ordinary producer. No classifier SDK or
model vocabulary belongs in the engine. An ordinary local worker can own
invocation, retries, scheduling, and the meaning of scopes; no reasoning
agent or generative LLM is required. Automatic extraction is not yet built.

### Extraction admission

`admit` takes a C01 `ExtractionResult` for an ingested source revision and,
in one transaction, admits it (E01: exact anchors, catalog, versions), links
declared identity keys exactly (L01) and publishes it. The trusted request
is rebuilt from the stored source, the installed catalog, the result's own
`extractor` and `request`, `scope` (default: the source's observation id)
and the `candidates` the caller offered. The run is one per producer and
request id; replaying the same admission answers `replayed: true` with its
revision, and changed content under that request id is refused. A failed
result is recorded as a failed run (`status: "failed"` with its `problems`):
nothing is published or withdrawn, and `dirty` lists it (`failed: true`)
until a later run of that producer and scope succeeds. A complete empty one
replaces the producer's earlier admission in that scope.

Each record lands on an entity: `existing` (its keys name one), `new` or
`unresolved` (a new local entity, stable per producer, scope, source revision
and local id), or `ambiguous` (keys name several; a new local entity, the
`candidates` listed, nothing merged and no key rebound). An extractor's
`resolution` (an offered candidate, `new` or `abstain`) is echoed, never
applied: only declared exact keys grant identity. Local ids in reference
positions become those entity ids. Records sharing an entity may repeat a
property only with identical value, qualifiers and normalization.

### Field evidence and valid time

A field published through `admit` keeps its evidence passages, FactBank
`factuality` (`CT+`, `CT-`, `PR+`, `PR-`, `PS+`, `PS-`, `Uu`), `speech_act`
(`assert`, `report`, `plan`, `request`, `condition`, `draft`), optional
`normalization` (TIMEX3 type and ISO 8601 value, or ISO 4217 currency and
minor units) and voice: the quotation frame's speaker, else the source
author, with the author and (unquoted) the other participants as audience.
A null speaker or audience is unknown. All of it is part of the run's replay
identity. `get`, `value`, `find`, `where`, `edges` and `traverse` read only
plain facts: `CT+` and `assert`, standing and not superseded. Other standing
statements appear under `qualified`; an asserted `CT-` of a value marks that
candidate `denied`, and `value` refuses it unless chosen. `explain` keeps
everything, with `standing` (transaction time) and `active` (counts as a
current fact).

Each of a support's `anchors` in `explain` is one passage in the Answer
contract's Citation shape:
`{"source": {"observation", "revision"}, "frame", "speaker", "selectors": [...]}`,
its W3C Web Annotation selectors being alternative descriptions of that one
passage: a `TextPositionSelector` (Unicode code points of that source
revision, half-open) and, when the extractor gave one, its `TextQuoteSelector`. The
normalized value ("next Friday" as a date) is the claim; its passages need
not contain it. Legacy publications have no anchor and read as plain
asserted statements; their opaque `locator` is never interpreted.

Valid time comes only from a model's declared validity binding, as UTC
milliseconds (`valid_from`, `valid_until`, half-open). When two plain
standing claims for one entity property differ and both declare a start, the
later start supersedes the earlier claim from that instant if it was still
open; `superseded_by` records it and it applies while the superseding support
stands. Tied or unknown starts stay a contradiction: both remain candidates.

### Corrections

A correction is evidence and decisions, never an edit. `same` is a merge
decision; `different` ends the merges the request names in `ends`, or else
those joining the two directly, and refuses when they would still read as
one group, so the decider says which merges were wrong. It keeps them apart
(a later merge rejoining them is refused). `wrong` and `true`
publish the decider's own denial or assertion (`CT-`/`CT+`, `assert`) as a
run over an observation of the correction itself. `uncorrect` reverses it
the same way — splitting, rejoining the ended merges under new decision
ids, or withdrawing the run — and the correction stays listed as undone.
An id replays its correction; changed content or an undone id is refused.

Which statements read as current depends on declared policy, not on who
wrote them. Among standing statements of a property, only plain claims whose
best support ranks with the property's best read as current, and the denial
rule decides when a denial removes a claim. `explain` shows each support's
`authority`. `corrections` exports every correction with what was asked,
what it did, and the graph's reading before and after, for training.

### As-of reads

Any read takes `"as_of": {"revision": n, "valid_at": "<ISO 8601>"}` (either
or both). `revision` reads the graph as it stood at that graph revision
(transaction time): supports published by then and not yet withdrawn, under
the input revision then current, with merges, tombstones, choices and
entity births as they stood. `valid_at` keeps only statements whose declared
valid time holds at that instant, and a supersession closes a claim only
once the superseding start has come. Statements of unknown valid time
always hold. A write under `as_of` is refused. Reads interpret history under
the installed schema; input revisions observed before format 12 count as
current for their observation's earliest recorded epoch.

### Model evolution

Opening a store under a changed catalog classifies the change by diffing
the stored model descriptors against the declared ones:

| Change | Effect |
| --- | --- |
| model or property added | nothing; every claim keeps reading |
| shape made optional around the old one | claims are revalidated |
| rules, allowed values or default changed | claims of that property are revalidated; those that fail retire |
| property removed | refused, unless `Migration.Remove(model, property)` retires its claims or `Migration.Rename(model, from, to)` carries them to an added property |
| shape changed otherwise | refused, unless `Migration.Remove` retires its claims |
| model removed | refused, unless `Migration.RemoveModel(model)` retires its claims |

Migrations are declared in `EnginePolicy.migrations`. A rename restates each
claim under the new name, supported by the same runs with the same evidence,
confidence and references; nothing is rewritten. A refused change leaves the
store untouched. Each accepted change is a `SchemaEdgeRow`; claims under any
schema it leads from keep reading unless retired, and `explain` shows a
retired claim's `retired` reason under its own `schema`. Changes made before
storage format 13 left no edge, so claims under those older catalogs do not
read.

### Engine policy

Every rule and bound a host may choose is one value, `EnginePolicy`
(`src/store/policy.av`), passed as `run(models, EnginePolicy { … })`; each
default reproduces the behaviour described above.

| Field | Default | Meaning |
| --- | --- | --- |
| `authority` | `[]` | `Authority { producer, rank }` per producer |
| `default_rank` | `0` | Rank of an undeclared producer |
| `denial` | `.Outranks` | A denial removes a claim only when ranked strictly above its best support (`.Matches`: at or above); otherwise it is a flagged contradiction |
| `supersession` | `.LaterStart` | A strictly later declared start closes an earlier open rival (`.Never`: rivals stay a contradiction) |
| `migrations` | `[]` | Declared answers to incompatible catalog changes (see Model evolution) |
| `admission` | `AdmissionBudget {}` | Per-admission bounds: `envelope_bytes` 4 MiB, `records` 256, `fields` 4096, `passages` 16384, `frames` 256, `value_depth` 64 |

Valid times are exact: `valid_from`/`valid_until` are normalized ISO 8601
in UTC, keeping every fractional digit given; an instant may carry `Z` or
an offset `±HH`, `±HHMM` or `±HH:MM`. An audience is only what the envelope
(`audience`) or a frame declares; otherwise it is unknown.

## Durable behavior

SQLite is the authority. Every engine row is an `@std/db` model — its DDL
and CRUD are derived, its links are typed — while model properties never
become SQL columns: user ontology values land in the generic `ClaimRow`.
The engine models are `Meta`, `Schema`, `EntityRow`, `ObservationRow`,
`ObservationVersionRow`, `RunRow`, `RunTrailRow`, `ClaimRow`, `SupportRow`,
`EdgeRow`, `AliasRow`, `MergeRow`/`MergeEndRow`, and
`TombstoneRow`/`TombstoneEndRow`, and `VoiceRow`, `EvidenceRow` and
`SupersessionRow`, `CorrectionRow`/`CorrectionEndRow`, `FailedRunRow`,
`InputEpochRow`, `SchemaEdgeRow` and `ClaimRetiredRow` (storage format 13;
older formats upgrade by adding them). WAL, foreign keys, and immediate write
transactions are used. Failed publications roll back identities, support
withdrawals, claims, references, aliases, and the revision together.
Connections wait up to three seconds for lock contention. Public multi-query
reads use one deferred snapshot and preserve a caller-owned transaction.

`open` upgrades formats 6 and 7 to 8 by adding the missing tables and
updating the format marker atomically; existing evidence is not rewritten.
`attach` requires the current format and never installs a catalog. Future,
missing, and legacy hand-table formats are refused, not silently adopted.
Preserve legacy files: converting the hand-table store still needs a migration.

Claims and support are distinct. Two producers can support the same value
without duplicating it. Replacing one scope cannot withdraw another
producer's support. Different supported values remain conflicts; confidence
does not silently select a winner. `value` refuses conflicts or incomplete
records; `get` exposes them. Lists are atomic property values and retain
their order, including duplicate reference positions.

Defaults construct complete records but omitted top-level fields are not
extracted evidence. Only supplied properties become claims; an explicitly
supplied list or embedded record is one normalized atomic value, including
its constructed elements. Partial records claim exactly the properties they
supply: no defaults, no required-field errors for omitted fields, and no
record-level rule until `value` assembles a complete record. An explicit
`null` on a nullable property is evidence; `null` on a required property is
refused rather than read as missing. Normalizers should be idempotent.
Changing an observation immediately excludes its old interpretations from
current queries. Historical payloads, identities, and explanations remain
available. Empty successful interpretations also appear in `dirty` after an
input changes.

Editing models and rebuilding changes the catalog fingerprint. The
fingerprint includes metadata, constraint calls, defaults, and compiler
code hashes of the validators. The std-first store writes format `8` in
`Meta`; a database from the earlier hand-table prototype is not migrated —
`attach` and `open` both refuse it. Installing the new catalog advances the graph revision
and quarantines old-schema interpretations; `dirty` names work to reprocess. No data is deleted or
destructively migrated. Existing handles reject publication after another
catalog is installed. `attach` opens without installing a catalog; the server
uses it per request.

This policy is conservative: even an additive schema change requires
reprocessing. Compiler code hashes can also conservatively change with
other reachable code. They hash external calls by symbol, not C bodies;
runtime upgrades require an explicit application/schema revision policy.

## Verify

```sh
sh tools/watch.sh 3500 ./build/avra test graph/src/tests/evidence_test.av
sh tools/watch.sh 3500 ./build/avra test graph/src/tests/identity_test.av
sh tools/watch.sh 3500 ./build/avra test graph/src/tests/merge_test.av
sh tools/watch.sh 3500 ./build/avra test graph/src/tests/partial_test.av
sh tools/watch.sh 3500 ./build/avra test graph/src/tests/storage_test.av
sh tools/watch.sh 3500 ./build/avra test graph/src/tests/tombstone_test.av
sh tools/watch.sh 3500 ./build/avra build graph/examples/notes
python3 graph/tests/smoke.py
python3 graph/tests/durability.py
sh tools/watch.sh 3500 ./build/avra build graph/tests/unrelated/src/main.av
graph/tests/unrelated/src/main
```

The engine's rows are declared in `src/store/engine.av`; tables and CRUD
come from models. Infrastructure catalog inspection and connection PRAGMAs
use parameterized SQL. User ontology types are
declared in a models module and never become tables — their claims are
rows in `ClaimRow`.

The smoke test uses private temporary files and stops its local server.
The unrelated library consumer has only shelf/specimen models, a cycle,
and an eight-field record. Expected output: `2 true 2 2 true`.
Interpreter execution of SQLite programs additionally needs the package's
shared library (`python3 tools/libs.py --build std-sqlite` after building
its native objects). Native builds link those objects directly.

## Next slices

- Declared selection policy beyond explicit choice (source priority, recency
  where asked). Choices and confidence are in; tombstones define deletion,
  and nothing removes evidence yet.
- Durable pending work and multi-input dependency tracking; `dirty` is
  one-input, whole-scope invalidation, not a background scheduler.
- Generic, declared conflict-resolution policies; the default deliberately
  refuses competing answers.
- Indexed property predicates, search, bounded pagination, and historical
  revision reads. Traversal is bounded BFS over supported reference paths.
- Reconstructible `std.relation` projections and fine-grained incremental
  rules once workload measurements justify them. SQLite is not secretly
  integrated with the relation dependency engine.
- Compatibility-aware model evolution and richer machine-readable
  validation constraints. Custom validator source is not JSON Schema.

Substrate issues and the design rationale are tracked in `DESIGN.md`.
