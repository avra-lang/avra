# M01 receipt

Task: M01, based on `178ca62d`, branch `feat/graph-selection`.
The commit adding this receipt is the task head (`git log -- graph/acceptance/app`).

Implemented: six fixture-only declarations, standard validation and generated
descriptors/registration, directed family links, independent temporal roles,
and explicit negative membership. One model-local validation function checks
interval ordering. No production engine/transport change, gold dictionary
load, extraction service, English lookup table or field-ceiling workaround.

Verification from the worktree root:

```sh
./build/avra fmt --write graph/acceptance/app
# exit 0; all 3 Avra files examined
sh tools/watch.sh 3500 ./build/avra test graph/acceptance/app/src/tests
# exit 0; 12/12 tests passed; 1 eval == native == expected program proved
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph
# exit 0; existing warnings, no new baseline entries
```

The manual store witness publishes 16 records to an in-memory generic graph
and verifies distinct spouse and mother links, preserved old/new roles and
explicit false membership. Reversed/empty intervals, bad email, absent
membership booleans and undeclared relationship labels are negative
witnesses. The native proof checks generated catalog descriptions, typed
reference decoding and interval refusal. This proves representation and
storage of hand-authored facts, **not** text extraction, speaker resolution,
temporal querying or q01–q07 end-to-end correctness.

Isolated idiom gate remains **nonzero**, not silently waived:

```sh
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/acceptance/app
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/tests/unrelated
# Both exit 1 with the same existing graph/src/api.av finding:
# [modules.unused_import] export use transport.cli.{run}
```

Tracked as `avra-8sb5.25.74`: a public facade binding is incorrectly treated
as unused when a particular consumer imports only other API members. Neither
that API nor the baseline was changed. M01's specified representation and
runtime witnesses are complete; resolving this separate substrate issue is
still required for a fully green isolated-consumer lint gate. Do not report
all gates green.

Remaining: M02/M03 add business and personal declarations/startup; L01
implements identity normalization. Q04/Q05 implement contextual and temporal
evaluation generically through declared semantics; model descriptions are
metadata, not an existing policy interpreter. A02 annotations remain ready.

Update: the separate compiler issue is now fixed and verified with a rebuilt
compiler; see [REEXPORT-FIX.md](REEXPORT-FIX.md). The nonzero outputs above
remain the historical M01 receipt, not the latest source-fix status.
