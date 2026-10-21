# C01 receipt

Task: C01, based on `376f3c98` in `feat/graph-selection`.
The commit adding this receipt is the task head (`git log -- graph/contracts`).

Implemented: standalone Avra `@avra/graph_contracts` library, standard
Decode-based v1 boundary types and coherence rules; exact UTF-8 source
coordinates; anchored extraction proposals; closed read-only plan algebra;
structured uncertainty, policy provenance and citations. No ontology names,
provider SDKs, model downloads, graph-store imports or gold answer registry.
`../MODULARITY.md` records replacement boundaries and migration rules.

Prerequisite: `376f3c98` adds standard generic `@items` cardinality validation
(`avra-8sb5.63.27`). This preserves the existing Counted and List.count APIs;
legacy task `avra-8sb5.63.14` for @length on lists is not thereby resolved.

Verification from the worktree root, all exit 0:

```sh
./build/avra fmt --write graph/contracts
sh tools/watch.sh 3500 ./build/avra test graph/contracts/src/tests
# 52/52 tests passed
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/contracts
# No new idiom baseline entries; existing std-toml warnings only.
sh tools/watch.sh 3500 ./build/avra build graph/contracts/tests/native/src/main.av
./graph/contracts/tests/native/src/main
# true true true
python3 graph/acceptance/validate.py --self-test
# 30 sources, 25 entities, 50 questions, 30 task briefs; 13 invalid fixtures refused.
git diff --check
```

The native consumer proves cross-package generated decoding, explicit null,
policy-only refusal and rejected write operations, without linking the graph
store. The 52 library tests include malformed Unicode coordinates/frames,
missing literal versus null, unsupported versions/unknown fields, failed
extraction versus empty completion, required property/identity anchors,
confidence bounds, duplicate properties, invalid plan slots/forward inputs,
step budgets, citation references and ambiguity/unknown/refusal shapes.

Limits: codec validity is not semantic admission, authorization, truth,
durability, classifier accuracy or English understanding. Catalog binding,
actual proposal spans/reference targets, trusted policies, query type checks,
runtime work meters, unit semantics and provenance proofs belong to later
tasks. Existing Graph.Record storage does not yet preserve the new modality
contract: E01 must extend that path or refuse unsupported projection, never
silently flatten it. Existing transport remains unchanged. No acceptance
question is claimed end-to-end passing here.

Ready next: A02 annotations; M01 model declarations; I01 source ingestion;
J01 durable job identity; Q01 typed semantic plan validation. Choose one
small slice; separate readiness does not authorize concurrent shared edits.
