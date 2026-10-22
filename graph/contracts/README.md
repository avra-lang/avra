# C01: graph boundary contracts, version 1

Canonical wire declarations are the Avra types exported by
[`src/api.av`](src/api.av), package `@avra/graph_contracts`. Standard
`std.validate.Decode`, field annotations and whole-record rules implement
decoding; there is no separately maintained Python/JSON-schema validator.
`T.from_json` rejects unknown/duplicate envelope fields and unsupported
contract versions, preserving structured `Issues` paths.

These are **boundary contracts**, not a new running HTTP service, query
executor, extractor, worker queue or fact scorer. The existing graph CLI
protocol remains unchanged. Do not present passing codec tests as a passing
acceptance suite. Q01/E01/I01 and their dependents implement admission and
execution against these shapes; capability discovery must reject operations
that an installed executor does not yet support.

The package is dependency-light: only standard metadata/validation, no graph
store, application models, inference runtime or provider SDK. See
[../MODULARITY.md](../MODULARITY.md) for replacement boundaries and evolution
rules. Boundary compatibility does not make persistence formats or classifier
semantics interchangeable.

## Wire conventions

- Every top-level source/request/result/plan/answer explicitly supplies
  integer `contract: 1`. Defaults only initialize infrastructure containers,
  never missing application properties or source assertions.
- IDs are opaque strings. No production field accepts fixture question IDs,
  expected answers or a gold entity dictionary. Example IDs in tests are
  arbitrary data, not a domain vocabulary or registry.
- All `*_at_ms` values are signed Unix milliseconds in UTC. Authored and
  received time are different; unknown authored time stays null. Earlier
  historical dates may have negative epochs. The adapter preserves original
  date spelling/precision/zone in source content and application properties;
  it must not silently reinterpret date-only values as instants.
- `Context.known_revision` is a graph read revision, **not** an observation
  revision or a corpus checkpoint. `valid_at_ms` is an explicit validity
  instant. Date-only queries require a declared timezone/interval convention
  in the adapter; the fixture uses UTC. Ingestion prefix replay establishes
  checkpoint knowledge without preloading future sources.
- Strings and lists have explicit field/cardinality bounds. Wire parsing
  does not replace the transport's encoded-body/depth/item limits or the
  executor's work/deadline counters. Enforce the lower trusted server cap.
- `JsonValue` is an opaque literal leaf, not an executable expression or
  permission to bypass model validation. It preserves explicit JSON null;
  absent required literals fail. E01 must check finite values, nesting/work
  budgets, and the declared model's validator before publication.
- Boundary discriminator strings are closed with standard `one_of` rules.
  Internal consumers lower these to typed enums/ASTs, not stringly typed
  ontology handlers. Tagged-enum Decode is not assumed implemented.

## Source, coordinates and discourse

`SourceEnvelope` carries a `SourceRef`, content, original author, known
participants/conversation and optional known quotation frames. Revision is
the engine observation revision assigned/admitted by ingestion; a business
document's own revision is a separate application property. Receipt time
alone must not force reprocessing of otherwise identical source content and
extraction-relevant metadata.

`Span { start, end, text }` uses **half-open UTF-8 byte offsets into the
original content**, before normalization/chunking. `text` must match those
bytes exactly. A provider returning code points, UTF-16 units or token
offsets must convert them before admission. For `Aé🙂Z`, `é🙂` is `[1,7)`,
not `[1,3)`. Wire frame validation checks bounds, byte length and content.
I02 must preserve mappings through whitespace/normalization/chunk overlap.

Frames identify quoted discourse: unique IDs, parents preceding children,
with their own optional speaker. Children stay inside their parents;
sibling frames (including roots) cannot overlap. This preserves an
unambiguous innermost speaker at each source coordinate. Envelope author is not automatically the
speaker of each quote. `Context.principal` identifies the authenticated
caller; changing `speaker` never changes authentication/permissions. The
source/candidate/frame IDs a worker proposes are not trusted identity grants.

`previous_answer` is an opaque handle to an actual previous answer in the
authorized conversation. It is not text containing a benchmark answer.
Consumers must check ownership, conversation, graph revision and ambiguity
before reusing referents. Coreference alone does not invent relationships.

## Extraction request and result

`ExtractionRequest` binds a source envelope, scope, exported model catalog,
request ID, producer/code/checkpoint identity and a bounded candidate list.
`CatalogBinding.descriptor` is the engine-generated catalog document (the
existing model/property descriptions and shapes), never a hand-kept second
ontology. Admission checks descriptor/fingerprint against the installed
catalog. The codec alone does not establish that authenticity.

`ExtractionResult` echoes request, source revision, schema and extractor
versions (`contract: 2`). It proposes local records, fields, anchored
identities, optional frames and, per record, an entity-resolution proposal
(`resolution`: an offered `candidate`, `new` or `abstain`). No proposal
forces an existing identity; exact-key resolution belongs to linking. Scores
(raw producer probabilities) never authorize a merge or select truth.

Each `ProposedField` has the normalized, model-shaped `value`; `evidence`,
one or more passages, each a list of W3C Web Annotation selectors naming the
same text — exactly one `TextPositionSelector` (Unicode code points of the
source revision, half-open) and at most one `TextQuoteSelector` (`exact`,
optional `prefix`/`suffix`, checked against the source); FactBank
`factuality` (`CT+`, `CT-`, `PR+`, `PR-`, `PS+`, `PS-`, `Uu`); a separate
`speech_act` (`assert`, `report`, `plan`, `request`, `condition`, `draft`);
and an optional `normalization`: `{"kind":"TIMEX3","timex_type":"DATE|TIME|DURATION|SET","value":<ISO 8601>}`
or `{"kind":"ISO4217","currency":"EUR","minor_units":1250,"exponent":2}`.
A TIMEX3 normalization may carry `reference`, the ISO 8601 instant a
relative expression was resolved against (the source's anchor time).
Admission accepts a DATE value that is an ISO 8601 calendar date and a TIME
value that is an instant with its offset; DURATION and SET are not admitted
yet. A passage need not contain the value ("next Friday" normalized to a date).
A result may also carry `unplaced` statements: anchored passages stating
what no declared model or property holds, with the extractor's best guess
(`kind` `property` with its `model`, or `model`; a `label`; an optional
`record` and `value`). They are never facts. An envelope may name its `timezone` (an IANA zone name or a `±HH:MM`
offset); an extraction request may carry the host's `default_timezone` for a
source that names none. An envelope and each frame may declare an `audience`; absent is unknown,
never inferred from `participants`. Every identity key also has its own passages. A quotation frame names its
quoted text the same way (`passage`), so one unit runs through a result. Local IDs are unique within a
result; a record proposes each property once. Multiple source mentions can
anchor the same field without creating multiple identities.

Where the catalog shape is `Ref<T>`, a proposal literal can use
`{"reference":{"scope":"local","id":"m1"}}` or
`{"reference":{"scope":"entity","id":"stored-id"}}`. Lists/embedded
values follow their declared shapes. Only a reference-shaped position can
interpret this syntax; arbitrary JSON/text is never scanned for commands.
E01 resolves/checks local targets, candidate authority and target model,
then lowers to the graph's existing string-ID Ref representation. The wire
codec does not perform this semantic binding.

`status: complete` means all requested windows/scope were processed. An
empty complete result is an intentional empty contribution. Failed results
require problems and cannot carry publishable records. Partial properties
are allowed; partial processing is **not** complete scope replacement.
Version-one has no streaming, half-success or implicit retry semantics.

E01 must verify request/source/schema/code/model matches, frame graph,
actual source anchors, schema symbols, all property rules and identity
permissions together before publication. Preserve factuality/speech act and
source/speaker provenance: never flatten a draft, denial or future plan into
an unconditional selected fact. If the current persistence/model path cannot
carry that meaning, refuse the projection rather than discard it. C01 does
not extend the current `Graph.Record` or claim storage to carry it yet.

## Read-only plans

`ReadPlan` is a small ordered dataflow plan with one output step and explicit
rows/work/depth/time/step budgets. Inputs name earlier steps, never arbitrary
code or cyclic forward references. The wire algebra is:

| Operation | Input | Required arguments | Result |
| --- | --- | --- | --- |
| scan | none | model | Authorized entities of a model. |
| filter | one | property, comparison, one literal in arguments | Matching input rows; no implicit conflict winner. |
| follow | one | reference property, direction in/out | Related entities with path evidence. |
| search | one | text property, one text literal in arguments | Scoped text matches with evidence. |
| project | one | properties | Supported property projections. |
| count | one | none | Count of a bounded, fully evaluated input set. |
| sum | one | numeric property | Aggregate with the declared type/unit policy. |

Only applicable slots are allowed. Literal arrays preserve explicit null
(`arguments: [null]`) without confusing it with an omitted argument. There
is no SQL, write, shell, export or arbitrary-function operator. Search is
scoped by a graph input, not permission to scan all private data.

Q01 validates schema and type compatibility and lowers the wire plan. Q02
executes one consistent read snapshot, meters work/rows/depth/deadlines and
returns source evidence. Limit exhaustion is a structured refusal/unknown,
not a truncated set silently presented as a complete aggregate. Count/sum
need explicit handling of duplicates, conflicts and units; no implicit FX,
money/unit mixing or application-specific inventory rule lives in this
algebra. A declaration/policy must supply any domain computation.

## Answers and provenance

`Answer` carries a request/read revision, status, field projections,
candidate identities, citations, trusted policies and structured problems.

- `answered`: at least one supported field, no unresolved problems or
  candidate selection waiting on the user.
- `unknown`: a reason code, optionally supported partial fields. Missing
  evidence is not a false or zero field.
- `ambiguous`: a reason and at least two distinct candidate identities;
  preserve clarification rather than selecting the highest score.
- `refused`: trusted policy provenance and a reason; no disclosed fact
  fields/candidates are needed. No source retrieval is required.

Each `AnswerField` has JSON-pointer path tokens, a literal value and basis:
`observed`, `derived`, `record_status` or `policy`. Source-backed fields cite
known citation IDs. Derived fields also name a **declared rule ID**, not
untrusted executable code. Citation source revisions and optional claim/run,
frame/speaker and Web Annotation selectors trace multi-hop answers to original evidence.

`record_status` describes the bounded read view, e.g. confirmation is absent
in the searched records. It must not be rendered as an unsupported global
negative. Policy-only fields cite trusted policies, not document text.
R01 verifies the returned projection against execution proofs and policy
registry; a codec-accepted fabricated citation/policy is not thereby true.
The read-only executor and test harness establish no-side-effects, not a
worker's self-reported `side_effects: []` claim.

## Acceptance mapping and verification

The ambiguity, monetary literal, missing-completion and policy-refusal tests
in `answer_test.av` represent q08, q22, q43 and q49 respectively. They use
generic record labels; they are codec examples, not English understanding.
Source tests exercise Unicode offsets, quotes, unknown/duplicate fields and
separate principal/speaker. Extraction tests preserve null, bound scores,
separate empty success/failure and anchor properties/identities. Query tests
reject writes, SQL, forward references and invalid operation arguments.

```sh
sh tools/watch.sh 3500 ./build/avra test graph/contracts/src/tests
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/contracts
```

Standard list bounds use `std.validate.items` (task `avra-8sb5.63.27`), not
graph-local validators or a breaking change to `Counted.count`. Native
consumer and library receipts are recorded in the task handoff. Freeze a
contract revision only after tests pass; semantic admission/execution tasks
must still supply their own negative witnesses.

## Provenance vocabulary

An `Answer` citation is a PROV-O entity: `source` is `prov:wasDerivedFrom`
(one observation revision), `run` is `prov:wasGeneratedBy`, `speaker` is
`prov:wasAttributedTo`. `selectors` are Web Annotation `TextQuoteSelector` and
`TextPositionSelector` values locating the passage in that revision; their
positions count Unicode code points, unlike extraction `Span` byte offsets.
[jsonld/answer.context.jsonld](jsonld/answer.context.jsonld) maps every wire
key to a PROV-O, Web Annotation or `avra.dev` term, so an answer is JSON-LD
by adding `@context` with no rename (`kind` aliases `@type`).
`jsonld/check.py` verifies that every key of given answer documents has a term.
