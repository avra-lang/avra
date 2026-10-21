# Agent execution plan: text → personal/business graph → structured answers

## Start here

This is a synthetic acceptance suite and a work plan, **not a working NLP
pipeline**. The graph foundation exists; most tasks below are future work.
The machine-readable task queue is [tasks.jsonl](tasks.jsonl). Its states
are planning states, not automatically synchronized with the tasks DB.

Current lane: `/Users/tristan/projects/tristanMatthias/avra-graph-v2`, branch
`feat/graph-selection`, rebased onto main `3896b7c1` (batch R). Stabilization and fixture
audit work is committed. Read `git status`, preserve unrelated changes, and do not
start by resetting, cleaning, rebasing or replacing this worktree.
`HANDOVER.md` is an older receipt, not the current operational authority.
Check current branch/main state before any eventual landing.

Read, in order:

1. [README.md](README.md): fixture semantics and scoring.
2. [manifest.json](manifest.json): source, answer, time and currency contract.
3. Your one row in [tasks.jsonl](tasks.jsonl), plus its dependencies' outputs.
4. [../DESIGN.md](../DESIGN.md) and [../RESEARCH.md](../RESEARCH.md).
5. [../MODULARITY.md](../MODULARITY.md): replacement boundaries and versioning.
6. [GAPS.md](GAPS.md): evidence for additional persistence/semantic-policy prerequisites.

## Product contract

An ordinary local service ingests text/structured items and automatically
builds evidence-backed knowledge. Extraction uses deterministic adapters
and non-generative classifiers/encoders. No reasoning agent or generative
LLM is required to extract facts. English question planning is separate;
an optional question-only LLM can emit a constrained plan, not the answer's
facts. SQLite evidence and generic query execution remain authoritative.

Ontology-specific names, relationships, linguistic labels, extraction hints
and policies belong in application model declarations. Fixture text, gold
answers and test assertions naturally mention their domain; generic engine,
adapter and query code must not branch on that vocabulary.

Keep extraction, linking, question interpretation, execution, storage and
presentation independently replaceable at the boundaries in MODULARITY.md.
Do not leak provider SDK types into the engine or couple codecs to SQLite.
Introduce narrow seams when their consumers exist, not a speculative plugin
framework. Provider replacement must preserve admission/safety checks and
evidence semantics; storage replacement additionally requires migration and
durability proofs. V05 tests provider replacement separately from V04's
ontology portability.

The existing `Person`, `Message`, `WorkItem` sample alone is insufficient
for this acceptance suite. Add an independent fixture application under
`acceptance/app`, not production special cases or per-user-model SQL tables.
The fixture's entity dictionary is grader metadata, not a runtime registry.

## First vertical slice

Prove a small path before attempting all 50 questions:

1. Ingest s01, s02, s09, s22, s30 in a small named demonstration scenario.
2. Extract and ground people, spouse/parent relationships and commitments.
3. Ask who Rowan's wife is and what she requested about dinner/guest limits.
4. Change the speaker to Alex Chen; “my wife” must now refer to Sora.
5. Demonstrate “unknown” for a dinner confirmation, not a made-up booking.

This selected-input demo is **not** a scored checkpoint run. Scored runs
must always ingest the entire prefix 1..checkpoint, without cherry-picking.
An oracle-fed demo is a storage/query witness, not text extraction working.

Then add the s13→s17 invoice correction and s10→s20 appointment revision.
The final slice runs all sources, restarts workers and asks the full suite.

## Work breakdown and parallelism

The dependency list in each task row is authoritative. Do not mark a task
ready until dependencies have real outputs and acceptance receipts.

| Wave | Task IDs | Coordination |
| --- | --- | --- |
| Fixture audit and interfaces | A01 → C01 → A02 | Freeze coordinates/context before annotating spans. |
| Application model declarations | M01; then M02 and M03 | Separate owned files; agree cross-model names through C01. |
| Input/extraction plumbing | I01 → I02 → E01 | Use recorded proposals, not downloaded models, for contract tests. |
| Model semantics and derivations | P01 → P02 → P03 (execution after Q02) | Metadata is not an interpreter; M02 declares policies after P02. |
| Identity and context | L01; then L02 and L03 | Share contracts, not ad hoc provider-specific types. |
| Durable processing | E00 plus J01 → J02 → J03 → J04 | Preserve field semantics before atomic worker publication; one storage writer lane. |
| Query execution | Q01 → Q02; Q03 after model declarations | Manual plans first; language understanding separately measured. |
| Context/time/answers | Q04, Q05, R01 after their dependencies | Own separate modules; integration owner handles dispatch changes. |
| Model experiments | E02 and E03 after contracts/annotations/models | Separate artifacts; serialize heavy runs on shared hardware. |
| Evaluation/integration | V01 → V02 → V03; V04/V05 when their deps stand | Preserve oracle separation; test ontology and provider portability separately. |

This is a work queue, not an instruction to launch every lane now. Start
with A01 and C01, then choose one small end-to-end slice. The field-ceiling
fix is separately owned (#1161, still open at the last GitHub check): don't duplicate it, wait idly for it, or add new
six-field row workarounds. Most contracts, fixtures, adapters and query
tests can proceed independently. A truly blocked row construction gets
a dependency on the existing substrate task, not a graph-local hack.

Each task is intended as one reviewable patch, roughly a 30–90 minute
implementation/test slice after prerequisites are available. Estimates are
not guarantees: if a language/library gap or model research makes it larger,
split off a reproducer or experiment task rather than quietly expanding scope.

## Agent assignment template

Pass the following with one task ID:

```text
Read graph/acceptance/PLAN.md and your tasks.jsonl row.
Task: <ID>. Implement only its deliverable and acceptance witnesses.
Base: <verified commit or integration branch>.
Worktree: <dedicated worktree>; preserve any inherited dirty files.
Owned paths: <the row's owns list>.
Dependency receipts: <commits/artifacts, not promises>.
Do not edit shared contracts, sample ontology, transport dispatch, unrelated
packages, or another lane's files without coordinating with the integrator.
Use ./build/avra; wrap substantial commands in tools/watch.sh.
No generative fact extraction. No model/weight downloads unless the resource
budget is explicitly agreed. No fixture-gold data in runtime requests.
Return the handoff receipt described below. Do not land or force-push a
shared branch; the integrator owns landing.
```

`owns` describes the starting write boundary, not an excuse to invent an
incompatible API. For shared wiring changes, request an integration patch.
Use feature worktrees rather than several agents editing one directory.

## Handoff receipt

Every task returns:

- Task ID, base/head commit and owned paths actually changed.
- What is implemented versus recorded, mocked, oracle-fed or design-only.
- Exact verification commands, exit codes and relevant output/artifact paths.
- Negative witnesses exercised, not just the happy-path demonstration.
- Contract changes or substrate issues, with a minimal reproducer and task ID.
- Remaining limitations and safe next task IDs; do not mark dependents ready
  if their required behavior is missing.

No partial task silently becomes “done” because a scaffold compiles. An
experiment that cannot load or run a model reports setup failure, not 0%
accuracy and not success. Full scoring never receives hand-authored answers.

## Verification discipline

Existing lightweight checks:

```sh
python3 graph/acceptance/validate.py
python3 graph/acceptance/validate.py --self-test
git diff --check
```

Existing graph verification, using one heavy process at a time:

```sh
sh tools/watch.sh 3500 ./build/avra test graph/src/tests
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph
sh tools/watch.sh 3500 ./build/avra build graph
python3 graph/tests/smoke.py
python3 graph/tests/durability.py
```

At plan creation the graph has 83 passing tests, native smoke/durability
witnesses, and a passing unrelated eight-field fixture. These receipts do
not mean the new acceptance suite or an NLP adapter passes. Run again on
the actual task base. New tasks name behavior to verify; runner/test paths
inside their deliverables are **planned until implemented**.

The baseline cannot grow to hide a new idiom violation. Check formatting
before handoff. Preserve caches when diagnosing compiler disagreements;
use isolated cache locations or a fresh worktree rather than blanket deletion.

## Evaluation ladder and release gates

1. Fixture integrity: JSON, identities, source revisions, chronology,
   evidence/checkpoint references and an acyclic task queue. Implemented now.
2. Oracle facts + oracle plans: require exact normalized projections and
   provenance on all 50 questions. This isolates storage, time and execution.
3. Real extraction/linking + oracle plans: attribute misses to extraction,
   identity, modality or source interpretation.
4. Real extraction + English plans: score actual end-to-end behavior;
   oracle mode must never be presented as this stage.

Initial demo gate: 100% oracle correctness; all ambiguity, quotation,
scope, unknown/negative, prompt-injection and no-side-effect witnesses pass;
no silent false identity merge. Publish exact per-question full-path results,
including errors, before choosing a numeric shipping target. A 50-question
synthetic suite is too small to justify a production/SOTA claim.

Report extraction precision/recall, wrong-link rate, abstention/clarification,
structured answer match, provenance correctness and work-budget failures
separately. Include cold/warm CPU, RAM, model size and p50/p95 timing with
hardware/version details. Do not compare different windows or schemas and
call the result a model bake-off. Preserve failed examples and confidence
scores for calibration; confidence is not truth-selection authority.

## Substrate and scope boundaries

- Wider model rows: `avra-8sb5.59.44.19`, implemented in #1161 (`acef6dba`).
  GitHub still reports the PR open, not merged; current main is `3896b7c1`.
  Integrate after it lands, before new wide engine rows.
  Consolidation of old companion tables is a separate tested migration,
  not a reason to block model/codec/annotation work.
- Composite uniqueness: `avra-8sb5.44.7`.
- Indexed/bounded generated reads: `avra-8sb5.44.8`.
- Isolated-consumer lint: `avra-8sb5.25.74`, public graph re-exports reported
  unused when a consumer imports a subset. Reproduces in the old unrelated
  consumer too. Keep the public API and baseline; report this gate honestly.
- Structured field-level graph failures remain open; R01 defines the public
  boundary rather than treating today's error strings as sufficient.
- `WORKERS.md` remains a provisional design. Do not implement its old
  six-field row layouts or trust worker-supplied clocks/query digests as
  authoritative. J01–J04 deliberately start with one input and no arbitrary
  query dependencies; multi-input dependency verification is a later slice.
- Do not restore the parked mention prototype wholesale. Decide coordinate,
  mention identity and support anchoring through C01/I02/A02 first.
- Keep source data, mentioned claims, identity decisions and selected truth
  distinct. Corrections are reversible evidence-bearing operations, not
  destructive edits to historic facts.
