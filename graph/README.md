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
sh tools/watch.sh 3500 ./build/avra build graph
graph/src/main request --db /tmp/personal-graph.db graph/examples/schema.json
graph/src/main request --db /tmp/personal-graph.db graph/examples/observe.json
```

For HTTP, provide a private token file containing at least 24 bytes:

```sh
graph/src/main serve --db /tmp/personal-graph.db --port 7331 --token-file /path/to/private-token
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
| `get` | `id` | Supported candidates per property, including conflicts |
| `value` | `id` | Validated complete record, or refusal |
| `find` | `model`, optional `limit` | Live entity ids, one per merge group |
| `edges` | `id`, optional `incoming` | Typed reference paths |
| `traverse` | `id`, optional `depth`, `limit` | Breadth-first reachable ids |
| `explain` | `id`, `property` | All historical supporting runs and their locators |
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

### Structured input

`ingest` admits the provider-neutral envelope in
[contracts/README.md](contracts/README.md). This stores source data, not
extracted facts. For example:

```json
{
  "op": "ingest",
  "source": {
    "contract": 1,
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

Spans are exact half-open UTF-8 byte coordinates in original content.
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

## Durable behavior

SQLite is the authority. Every engine row is an `@std/db` model — its DDL
and CRUD are derived, its links are typed — while model properties never
become SQL columns: user ontology values land in the generic `ClaimRow`.
The engine models are `Meta`, `Schema`, `EntityRow`, `ObservationRow`,
`ObservationVersionRow`, `RunRow`, `RunTrailRow`, `ClaimRow`, `SupportRow`,
`EdgeRow`, `AliasRow`, `MergeRow`/`MergeEndRow`, and
`TombstoneRow`/`TombstoneEndRow`. WAL, foreign keys, and immediate write
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
sh tools/watch.sh 3500 ./build/avra build graph
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
