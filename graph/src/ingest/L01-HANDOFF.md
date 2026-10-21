# L01: declared exact identity linking

Base: `df8a43f6`; the commit adding this receipt is the task head.

Implemented embedding boundary: `Graph.link_exact(request_json, response_json)`.
It first admits the untrusted provider response through E01, verifies the full
current stored source envelope, then resolves model-declared identity keys
against one read snapshot. It never publishes, allocates entities, writes
aliases or merges. Its revision must be checked again by a future publisher.

Only supplied affirmed/asserted fields grant keys. Missing/null, denied,
planned and reported fields do not. Identity-only proposals and candidate
scores remain unverified, not authority. Explicit model policies select exact,
trimmed or ASCII-lower-trimmed normalization; no email/phone/domain heuristic
is built into the engine. Conflicting proposals and cross-model key collisions
are refused. Shared local keys form deterministic transitive groups; `New`
names a local group, not an allocated persistent entity. Multiple existing
targets remain `Ambiguous`; existing explicit merges resolve to their root.

Unwithdrawn historical aliases can establish continuity only within the same
source, producer, scope and schema. They never become current facts merely
because linking found them. Withdrawn aliases cannot be revived. Match proofs
retain each key, bound entity, canonical entity, run and source revision.

Verification with the rebuilt native compiler:

```sh
sh tools/watch.sh 3500 ./build/avra test graph/src/tests
# 185/185; includes 20 exact-link cases; two eval/native proof programs
sh tools/watch.sh 3500 ./build/avra build graph/tests/linking
python3 graph/tests/linking/restart.py
# native consumer; independent processes, current and historical association;
# complete persisted SQL snapshots unchanged by repeated linking reads
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/tests/linking
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/acceptance/app
# all exit 0, no baseline growth; combined local gate peak 1084 MB
```

The changed display-name and corrected secondary-contact witnesses use
recorded extraction proposals. Contact replacement is a separate manual
publication witness: current support changes while history remains. This is
not automatic NLP, worker publication or a claim that L02/L03 are complete.
The unrelated Instrument consumer exercises the public API without personal
ontology names. Test helper names were not changed to conceal the compiler
default-symbol collision; see `docs/2026_10_21_DEFAULT_SYMBOL_OWNERS.md`.

Limits: 2048 declared keys, 8192 retained match proofs, 4096 aliases per key
after lookup. **These are not a bounded/indexed storage-access guarantee**:
the generated DB accessor materializes history before the row check, and
merge/tombstone reads still scan tables. Indexed/bounded access remains
`avra-8sb5.44.8`. No scalability claim or graph-local SQL bypass is made.

Next: A02 annotations and L02/L03 for measured fuzzy/context linking; E00
must preserve qualifiers before J03 can publish admitted linked proposals.
