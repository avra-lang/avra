# I02 receipt: bounded windows and coordinate grounding

Base: `dcb3f739`; the commit adding this receipt is the task head.

Implemented: source windows split at quotation boundaries; byte-bounded
UTF-8-safe windows with overlap and complete-failure budgets; optional
space/tab/CR/LF collapse with retained original-byte mapping; explicit
UTF-8-byte, code-point and UTF-16 coordinate conversion; exact source
anchors and overlap-stable mention keys distinct from entity identities.
Source revision, frame and normalization mode participate in identities.

The public embedding surface exports `windows`, `WindowPolicy`, `TextWindow`
and `CoordinateUnit`. No provider SDK, ontology vocabulary, source execution,
entity assignment, extraction score or fact publication is involved.

C01's quotation validator now also requires child containment and
nonoverlapping siblings. This enforces its existing parent/child semantics,
not a new wire shape. Unknown nested speakers stay unknown rather than
falling back to the enclosing author. Invalid typed source constructors are
revalidated through the standard source codec before indexing their bytes.

Verification from the worktree root:

```sh
./build/avra fmt --write graph/contracts/src/source.av graph/contracts/src/tests/source_test.av graph/src/ingest/chunks.av graph/src/tests/chunks_test.av graph/src/tests/chunk_windows/chunk_windows.av graph/src/api.av
sh tools/watch.sh 3500 ./build/avra test graph/contracts/src/tests
# 55/55 tests passed
sh tools/watch.sh 3500 ./build/avra test graph/src/tests
# 126/126 tests passed; chunk_windows eval == native == expected
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph
```

Negative witnesses: surrogate halves, partial UTF-8 sequences, negative,
oversized and empty spans, fabricated model text/anchors, invalid window
policy, count/total-byte exhaustion, invalid typed sources, child frames
outside their parent, overlapping roots and source-looking instructions.
Limits never return a partial list as successful complete extraction.

Bounds: source ≤1 MiB (C01); window 4..65536 bytes; ≤2048 windows and ≤4 MiB
total original bytes across windows. Defaults: 4096 bytes, 128-byte overlap,
512 windows, 4 MiB total. Quotation partitioning scans ≤256 frames and
normalization is a linear walk over bounded emitted source bytes. Maps
retain one entry per normalized code-point boundary. No scalability claim
about embedding inference or graph querying follows from these bounds.

Limits: no PDF/CSV reader, sentence segmentation, Unicode normalization
other than the explicitly described whitespace collapse, coreference or
model inference. Grapheme coordinates are not accepted as code points.
E01 still binds actual worker results to source/schema/window requirements
and verifies proposals before publication; A02 supplies independent gold.
