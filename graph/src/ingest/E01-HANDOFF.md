# E01 receipt: provider-neutral extraction admission

Base: `42ad0b7a`; the commit adding this receipt is the task head.

Implemented: `admit_extraction(catalog, request_json, response_json)`, a pure
embedding boundary over the C01 v1 codecs. The trusted composition root
supplies the original authorized request; the worker supplies only its
response. No SDK, model weights, database handle or ontology-specific branch
is involved. This is validation of recorded proposals, not measured NLP.

Admission binds request/source revision, installed catalog fingerprint AND
descriptor, producer, code and weight versions. Standard model field
validators remain authoritative. Only supplied properties become proposed
evidence; embedded decoder defaults are removed too. Reference values must
name a local proposal or explicitly offered candidate of the declared target
type. Candidate suggestions never select or merge an entity. Identity keys
and quoted-speaker handles remain unverified linking proposals.

Anchors use exact original UTF-8 bytes and complete code points. Each anchor
names its innermost quotation frame and cannot blend quotation contexts.
Proposed frames pass the same parent/containment/quote checks as source
frames. Polarity, modality, confidence, frames and individual anchors survive
normalization. Failure and complete-empty are separate enum cases; malformed
or failed responses cannot masquerade as empty replacement success.

Verification from the worktree root (standing `./build/avra`):

```sh
sh tools/watch.sh 3500 ./build/avra test graph/src/tests
# exit 0; 151/151 tests, including 25 admission tests
# chunk_windows AND extraction_gate: eval == native == expected
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph
# exit 0; no baseline growth
sh tools/watch.sh 3500 ./build/avra build graph
python3 graph/tests/smoke.py
python3 graph/tests/durability.py
# all exit 0; native CLI/HTTP/source revisions and store durability pass
```

Negative witnesses include invented properties/models/quotes, wrong reference
shapes and targets, unoffered entities/candidates, duplicate local ids/fields,
candidate id collisions, missing quotation context, crossed quote boundaries,
dangling frame parents, partial Unicode, invalid field rules/scores, stale
source/schema/code/model/request identity, forged descriptors and record
budget exhaustion. Native proof prints `planned denied 1 true`: qualifiers
and missing fields survive; fabricated evidence is refused.

Admission bounds: each JSON envelope ≤4 MiB, ≤256 records, ≤4096 fields,
≤16384 field/identity anchors, ≤256 combined quotation frames and ≤64 nested
value steps, in addition to C01/std.validate limits. Exhaustion refuses the
whole response. Lookup is bounded but not claimed indexed or large-scale.

Remaining: the v1 request covers a full source/scope. Window-level worker
transport and a coverage manifest require explicit contract evolution, not
opaque JSON in `scope` or pretend source coordinates. E00 must persist field
qualifiers before J03 can publish these proposals atomically. L01/L03 must
ground identities and speaker handles; this admission does not grant their
authority. No CLI extraction operation, scheduler, provider invocation,
reconciliation or English query path is added here.
