# Model-driven personal graph

An embeddable Avra library and a small local application. All example
ontology declarations live in `src/models.av`; storage, validation
integration, queries, CLI, and HTTP contain no domain model names.

This is an executable first slice, not a completed inference platform.

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

## Agent protocol

CLI request files and HTTP use exactly the same JSON operations:

| `op` | Other fields | Answer |
| --- | --- | --- |
| `schema` | — | Fingerprint, graph revision, model metadata |
| `observe` | `id`, `payload` string | Input revision and graph revision |
| `observation` | `id`, optional `revision` | Current or historical raw payload |
| `publish` | See below | Committed graph revision |
| `get` | `id` | Supported candidates per property, including conflicts |
| `value` | `id` | Validated complete record, or refusal |
| `find` | `model`, optional `limit` | Active entity ids |
| `edges` | `id`, optional `incoming` | Typed reference paths |
| `traverse` | `id`, optional `depth`, `limit` | Breadth-first reachable ids |
| `explain` | `id`, `property` | All historical supporting runs |
| `dirty` | — | Latest interpretations with stale input or schema |

A publication is a successful *complete replacement* of one producer's
output in one scope. An empty `records` list withdraws that contribution.
A classifier failure must not be published as an empty success.

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
    {"id": "stable-entity-id", "model": "declared-model-name", "value": {}}
  ]
}
```

The empty object above is schematic: `value` must satisfy that model's
standard decoder. Use application-owned, preferably namespaced stable
ids; ids are global across models. References can target identities from
the same publication regardless of record order, or previously committed
identities. Target models must match. Identity existence is distinct from
having current supported properties.

Read schema, record an observation, classify against its revision, then
publish against the latest graph revision. A stale graph revision calls
for a retry; stale input/schema calls for reclassification. An identical
run-id/request pair returns its original committed revision. Reusing a
run id with different content is refused.

Jev or another classifier is an ordinary producer. No classifier SDK or
model vocabulary belongs in the engine. The local feeding agent owns
invocation, retries, scheduling, and the meaning of scopes.

## Durable behavior

SQLite is the authority, with fixed generic tables for catalog revisions,
entity identities, versioned observations, producer runs, claims, support,
and reference indexes. Model properties never become SQL columns. WAL,
foreign keys, immediate write transactions, and explicit storage-format
versioning are used. Failed publications roll back identities, support
withdrawals, claims, references, and the revision together.

Claims and support are distinct. Two producers can support the same value
without duplicating it. Replacing one scope cannot withdraw another
producer's support. Different supported values remain conflicts; confidence
does not silently select a winner. `value` refuses conflicts or incomplete
records; `get` exposes them. Lists are atomic property values and retain
their order, including duplicate reference positions.

Defaults construct complete records but omitted top-level fields are not
extracted evidence. Only supplied properties become claims; an explicitly
supplied list or embedded record is one normalized atomic value, including
its constructed elements. Normalizers should be idempotent. Changing an observation immediately
excludes its old interpretations from current queries. Historical payloads
and explanations remain available. Empty successful interpretations also
appear in `dirty` after an input changes.

Editing models and rebuilding changes the catalog fingerprint. The
fingerprint includes metadata, constraint calls, defaults, and compiler
code hashes of the validators. Installing the new catalog advances the
graph revision and quarantines old-schema interpretations; `dirty` names
work to reprocess. No data is deleted or destructively migrated. Existing
handles reject publication after another catalog is installed. `attach`
opens without installing a catalog; the server uses it per request.

This policy is conservative: even an additive schema change requires
reprocessing. Compiler code hashes can also conservatively change with
other reachable code. They hash external calls by symbol, not C bodies;
runtime upgrades require an explicit application/schema revision policy.

## Verify

```sh
sh tools/watch.sh 3500 ./build/avra test graph/src/tests/storage_test.av
sh tools/watch.sh 3500 ./build/avra build graph
python3 graph/tests/smoke.py
sh tools/watch.sh 3500 ./build/avra build graph/tests/unrelated/src/main.av
graph/tests/unrelated/src/main
```

The smoke test uses private temporary files and stops its local server.
The unrelated library consumer has only shelf/specimen models, a cycle,
and an eight-field record. Expected output: `2 true 2 2`.
Interpreter execution of SQLite programs additionally needs the package's
shared library (`python3 tools/libs.py --build std-sqlite` after building
its native objects). Native builds link those objects directly.

## Next slices

- Partial-property assertions without manufacturing required fields;
  preserve record-level validation separately from property validation.
- External identity aliases, explicit merge/split operations, and deletion
  policy; ids currently come from the feeding agent.
- Durable pending work and multi-input dependency tracking; `dirty` is
  one-input, whole-scope invalidation, not a background scheduler.
- Generic, declared conflict-resolution policies and evidence spans;
  the default deliberately refuses competing answers.
- Indexed property predicates, search, bounded pagination, and historical
  revision reads. Traversal is bounded BFS over supported reference paths.
- Reconstructible `std.relation` projections and fine-grained incremental
  rules once workload measurements justify them. SQLite is not secretly
  integrated with the relation dependency engine.
- Compatibility-aware model evolution and richer machine-readable
  validation constraints. Custom validator source is not JSON Schema.

Substrate issues and the design rationale are tracked in `DESIGN.md`.
