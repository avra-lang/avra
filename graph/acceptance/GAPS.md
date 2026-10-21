# Implementation dependencies discovered after C01/I01/I02

These are remaining requirements, not features supplied by the codecs or
the fixture declarations. They supplement the original task queue without
narrowing the text-to-facts product. Owned integration points remain one
writer lane even where two tasks touch them.

## E00: preserve field semantics through persistence

C01 proposals have per-field anchors, polarity, modality and frame. The
existing `Record` in `graph/src/store/publish.av` instead has one opaque
locator and confidence for an entire record. `SupportRow` has no typed
polarity/modality. `standing` in `store/state.av` only checks withdrawal,
schema and current input revision. Therefore passing these proposals
straight to today's publication path would either lose distinctions or
present hypothetical/negated statements as unqualified facts.

E00 must extend that path, include field semantics in replay identity,
preserve them in evidence/history, and keep unqualified reads from silently
asserting them. Opaque legacy locator JSON must remain opaque: do not start
interpreting arbitrary user keys named `modality` as truth policy. E01 can
validate proposals first, but J03 cannot publish them until E00 exists.
This is real persistence behavior, not merely adding a metadata struct.

The field-cap implementation is in open PR #1161. If wider engine rows are
needed, integrate it after landing; do not add cap-driven companion rows.
Use other ready work while that dependency is external. Existing supported
formats need an explicit tested upgrade, not reinterpretation of old rows.

## P01: machine-readable model semantics

`graph/src/schema.av` currently exposes shapes, descriptions, validation
rule source strings and decoder functions. `derive/model.av` projects those
from the declarations. It does not yet expose typed bindings for identity
keys, relation endpoints/labels, valid-time fields or quantity/unit fields.
M01's descriptions explain these concepts, but do not execute them.

P01 adds the minimal declaration metadata and catalog checks real consumers
need, without a provider registry or per-domain engine handlers. A field or
model named `wife`, `Person`, `currency`, `validity`, `minor` or `invoice`
must not be a special case. Source actor handles must not become graph
identities merely by matching a model name. Semantic metadata participates
in the catalog fingerprint and standard validation remains authoritative.

## P02/P03: declared derived answers

M02 and Q02 require inventory/deposit/remaining-amount calculations and unit
checks. The current wire plan has scan/filter/follow/search/project/count/
sum, not a complete model-declared derivation mechanism. Free-text policy
descriptions alone cannot implement the required arithmetic generically.

P02 defines bounded, typed, inspectable read/derivation declarations at the
model boundary, validates symbols, dependencies and unit contracts, and
version-controls any wire evolution. P03 executes those declarations over
one authorized snapshot with budgets and source proofs. No arbitrary SQL,
question-provided code, unit guessing or fixture answer table is allowed.
M02 declares its business rules through that mechanism. V01 cannot claim
all 50 oracle projections until the derived-answer path is exercised.

These tasks deliberately separate metadata, declarations and execution.
They do not authorize building an abstract plugin framework or replacing
the whole store before a real consumer needs a seam.
