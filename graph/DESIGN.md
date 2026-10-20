# Model-driven graph

See [ROADMAP.md](ROADMAP.md) for the full implementation sequence and status.

## Scope

A standalone Avra project under `graph/`, outside `packages/`. The
application consists of ordinary model declarations, a collection of
their generated descriptors, and startup configuration. An agent edits
the source and rebuilds. The graph engine contains no ontology names.

Use `./build/avra` for checks, builds, and runs. Wrap substantial runs
with the repository watchdog. Treat the old six-field model limitation
as resolved; do not constrain the graph design around it.

## Declaration contract

- `@model` composes standard validation with graph descriptor and codec
  generation. Model-specific handlers and a second validation engine
  are not part of the design.
- `Ref<T>` is an independently identified, typed relationship; optional
  references and lists of references preserve their declared types.
- Nested records are embedded values. Lists retain order.
- Standard validation annotations perform checks and normalization.
- Descriptions, constraints, references, and model definitions project
  into an introspection schema for the feeding agent.
- Derives emit annotated descriptor factories, gathered with `collect`.
  Metadata and validation behavior are constructed once by the catalog;
  a runtime function value is not a computed const.
  Generated descriptor collection already has a precedent in
  `packages/std-ui/src/tree/seats.av`.
- Keep domain declarations in one models module. `Task` is currently a
  built-in language type; use `WorkItem` for that example domain model.

## Persistence and publication

SQLite is the durable authority. Generic tables represent schema
revisions, entities, external identities, input observations, producer
runs, statements, support, and derived current selections. Adding an
ontology property does not add an SQL column.

Statements and their evidence are distinct. Several contributions may
support one statement. A successful replacement closes only the old
support owned by its producer and scope. Failure is not replacement
with an empty set. Historical statements remain interpretable under
their schema revision.

Publication is transactional and idempotent. Bind each run to input
and schema revisions, reject stale publications, and advance one graph
revision on commit. Relationships are checked against the transaction
snapshot, including entities introduced by that same publication.

Complete-record ingestion runs standard decode and record validation.
Individual assertions validate a property's value without inventing
unobserved fields. Typed reads assemble and validate complete records;
generic reads can expose missing fields and conflicts. Defaults on
complete-record construction are not extracted evidence.

Resolution policy is generic and explicit; confidence is not authority.
Retain competing supported statements and their explanations. A
materialized selection is a projection, never the evidence store.

After durable commit, update tracked inputs for incremental queries.
`@std/relation` is a computation dependency system, not an automatic
SQLite backend. Its cache must be reconstructible from durable data.

## Delivery sequence

1. Prove standard validation composition, typed references, generated
   codecs, and collected model descriptors using a small model program.
2. Implement generic transactional storage and schema registration.
3. Verify replay, stale revision rejection, reference checks, rollback,
   replacement, independent support, conflicts, and reopening the file.
4. Add generic entity/property queries, reverse references, bounded
   traversal, and explanations with indexed SQL.
5. Add thin CLI and local HTTP adapters over the same library operations.
6. Prove ontology independence with an unrelated model fixture, then
   document the agent protocol and model evolution behavior.
7. Extend assertions without a second validation engine: partial properties,
   opaque evidence locators, and producer-owned external identities.

## Substrate issues

Task **avra-8sb5.63.23**: `Decode discards generic arguments when calling
named field decoders`. Fixed on the parent branch; PR
https://github.com/avra-lang/avra/pull/1132 is queued for integration.
Related existing task: `avra-8sb5.63.15` covers broader generic derives,
which are not required by the graph's manually defined generic `Ref<T>`.

Before that fix, the nongeneric `Message` record in
`repro/generic-ref/src/main.av` with `author: Ref<Person>` produced three
errors: `got` declared `Ref<Person>?`, but the uninstantiated receiver
answered `Ref<T>?`.

Reproduce from the repository root:

```sh
sh tools/watch.sh 2500 ./build/avra run graph/repro/generic-ref/src/main.av
```

The fixed compiler prints `p1`. Acceptance also covers nullable,
list, and nested generic fields through both Value and direct JSON
decoding, on the interpreter and native engine. Preserve target-type
checking.

Task **avra-8sb5.63.24**: package collections included nested function
declarations inside derive quotes. Their placeholder names were treated
as callable factories with no body. The collection membership fix is
committed on the graph branch, with an interpreter/native regression and
102 passing existing collect tests. No manual registry is needed.

Task **avra-8sb5.63.25**: renaming the prototype package from `graph` to
the dependency-compatible `@avra/graph` left stale held generic symbols.
The warm link failed; a cold rebuild succeeded. The worktree's old cache
was moved to `build/cache-before-graph-package-rename`, not deleted.
The package name is now stable; this issue remains open.

## Implemented boundary

The first executable slice includes collected model metadata and standard
validation, SQLite persistence, observations and immutable input history,
atomic producer/scope replacement, replay and stale-publication checks,
typed reference indexes, candidate/conflict reads, partial property
assertions, opaque per-record evidence locators, producer-owned external
identities, validated record reads, bounded traversal, explanations, and a
shared CLI/HTTP protocol.

Schema installation conservatively invalidates all older interpretations;
it preserves their claims, support, and source payloads. `dirty` exposes
reprocessing work but does not run a classifier. Explicit merge/split and
tombstone decisions, compatibility-aware migrations, multi-input
derivations, and relation-backed incremental projections remain separate
slices. `README.md` describes the actual protocol and guarantees.
