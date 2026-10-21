# I01 receipt: structured source ingestion

Base: `5adc6d03`, rebased onto actual main `3896b7c1` (batch R).
The commit adding this receipt is the task head (`git log -- graph/src/ingest`).

Implemented: standard-decode admission of C01 source envelopes; canonical
infrastructure serialization; immutable consecutive observation revisions;
first-receipt preservation; exact historical replay; shared CLI/HTTP ingest
and structured-read operations. Author/participants/frames remain data, not
entity creation or caller authority. Raw observation compatibility stays.

Observation mutation now has one transaction-borrowing helper; the public
raw and structured boundaries each own their transaction. No new engine
tables, storage version, domain vocabulary, classifier, worker or ontology
registry. Receipt time and JSON spelling alone are not invalidation inputs.

Verification from the worktree root:

```sh
./build/avra fmt --write graph/src/ingest/envelope.av graph/src/store/open.av graph/src/api.av graph/src/transport/request.av graph/src/transport/dispatch.av graph/src/tests/ingest_envelope_test.av
sh tools/watch.sh 3500 ./build/avra test graph/src/tests
# exit 0: 103/103 tests passed (83 prior + 20 source witnesses)
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph
# exit 0, baseline unchanged
sh tools/watch.sh 3500 ./build/avra build graph
# exit 0
python3 graph/tests/smoke.py
# CLI process-restart persistence and authenticated HTTP, including structured sources
python3 graph/tests/durability.py
# storage upgrades, WAL contention and crash rollback
```

Negative witnesses: nonconsecutive revisions, altered current/historical
replay, future contract, undeclared gold fields, malformed Unicode spans,
raw-observation collision and embedded identity mismatching its observation.
Metadata-only author/quoted-speaker corrections advance a revision without
rewriting original payloads. A historical no-op returns its historical
reference with the current graph receipt revision, never makes it current.

No extraction or natural-language answering is claimed. I02 supplies
bounded windows with coordinate mapping; E01 verifies actual proposals;
J04 owns durable automatic scheduling. Providers must use the source
reference returned in the receipt, including unchanged proposed revisions.
