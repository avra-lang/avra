# Graph lane handover — 2026-10-20

This is the state a successor needs to continue the personal graph work
without re-deriving it. Read it with the design sources it names; every
claim here was checked against the tree or the PRs at the time of writing.

## 1. What this project is

An embeddable, model-driven personal knowledge graph written in Avra:

- An application declares ordinary model types (People, Messages,
  WorkItems, …); `collect` gathers their generated descriptors.
- A local agent feeds observations (raw source items) and publishes
  claims; classifiers (including Jev or an NER model) are ordinary
  producers outside the engine.
- The engine stores evidence: observations, runs, claims, support,
  conflicts, external identities, merges, choices, tombstones,
  confidence, and (in progress) mention spans.
- The engine contains no ontology names and creates **no table per user
  model**. User values are generic claim rows.
- SQLite is the durable authority. Engine rows are `@std/db` models
  (derived DDL and CRUD, typed links, `Many`, nullable history columns).
  No hand SQL remains in `graph/src`.

Design sources:

- `graph/DESIGN.md` — architecture, std boundary, persistence.
- `graph/ROADMAP.md` — milestones and remaining work.
- `graph/README.md` — protocol, durability, verification commands.
- `graph/WORKERS.md` — Milestone 4 design for durable classifier jobs
  and the NER producer flow (new; design only, no code).

The old hand-SQL prototype is preserved on branch
`legacy/graph-hand-store` in worktree `/Users/tristan/projects/tristanMatthias/avra-graph`.
Do not revive it; the std-first store replaced it.

## 2. Repositories, worktrees, branches (exact)

Repository: `avra-lang/avra` (GitHub). Main is protected: no direct
pushes, squash merges, PR must be up to date and green.

| Worktree | Branch | Head | State |
| --- | --- | --- | --- |
| `/Users/tristan/projects/tristanMatthias/avra` | `main` | `b1e59ff3` | main checkout; do not commit here |
| `/Users/tristan/projects/tristanMatthias/avra-graph-v2` | `feat/graph-selection` | `e6fbd235` | active graph lane, pushed |
| `/Users/tristan/projects/tristanMatthias/avra-graph` | `legacy/graph-hand-store` | `6f0dfe65` | old hand-SQL prototype, preserved |
| `/Users/tristan/projects/tristanMatthias/avra-graph-mentions` | `feat/graph-mentions` | `b9c89ffd` + dirty | stopped mention prototype, uncommitted |
| `/Users/tristan/projects/tristanMatthias/avra-graph-workers` | `feat/graph-workers-design` | `0f8270b6` | WORKERS.md design branch |
| `/Users/tristan/projects/tristanMatthias/avra-field-projections` | merged | — | #1140 |
| `/Users/tristan/projects/tristanMatthias/avra-tools-sync` | merged | — | #1142 |
| `/Users/tristan/projects/tristanMatthias/avra-collect-nested` | merged | — | #1137 |

Sprite for the graph lane: **`avra-ux2`**, bound to `avra-graph-v2`
(`sh tools/work status`). Other lanes use the same pool; never run two
heavy things at once on the Mac.

## 3. PRs and landed state

Main today: **`b1e59ff3`** — batch P (#1144): work sync, field
projections, unkeyed owner, node seats, page errors, dialog dismissal.
No graph package on main yet.

Landed prerequisites:

| PR | Branch | Squash/head | What |
| --- | --- | --- | --- |
| #1132 | `fix/graph-validate-generics` | `5e98a543` | generic static owners + decoder element types |
| #1137 | `fix/collect-nested-templates` | `5763e068` | nested template declarations excluded from collections |
| #1140 | `fix/validate-field-projections` | batch P | `Decode.fields` partial-record projections |
| #1142 | `fix/work-sync-top-level` | batch P | Sprite sync carries every top-level entry, with a 64 MiB untracked cap |
| #1108 | batch O | `543526b6` | data chain: @std/db relations, `Many`, nullable columns, `where`, `@soft_delete`, etc. |

Graph landing:

- **PR #1141** `graph: a model-driven personal evidence graph on @std/db`
- Branch `feat/generic-personal-graph`, head **`46cc7d39`**, base `main`.
- Graph-only: no `Decode.fields`, no collect, no tools patch.
- **61/61** graph tests on Sprite `avra-ux2`; native smoke green; unrelated
  8-field cyclic fixture `2 true 2 2 true`; idiom gate clean.
- It is **in batch Q, PR #1152**, open and blocked on checks. Do not
  rebase or edit #1141 while the batch holds it. Wait for the merge sha.

Next branch, based on `46cc7d39` and pushed:

- **`feat/graph-selection`**, head **`e6fbd235`**:
  - `83e0b3b2` — confidence as evidence metadata (store format 7).
  - `8def9391` — explicit choices (store format 8).
  - `b9c89ffd` — filtered property queries + paging.
  - `e6fbd235` — `graph/WORKERS.md` durable worker/NER design.
- **71/71** on `avra-ux2` after confidence + choices; the query slice
  has `query_test.av` 4/4 and `check graph` clean, but the **full suite
  was not re-run after the query commit**, and the idiom gate was not
  re-run after it either. Verify before landing.
- This branch has **no PR yet**. It waits for #1141/batch Q to land, then
  rebases onto main and opens its own PR (or joins a batch). One branch
  per lane.

## 4. Architecture as built

`Graph` = `{ db: @std.sqlite.Db, catalog: Catalog }`. Engine rows are
`@std/db` `@model` types in `graph/src/store/engine.av`:

- `Meta` — key/value: graph revision, format, current schema.
- `Schema` — fingerprint + catalog document.
- `EntityRow` — `@unique name` (the stable external entity id), model,
  born revision; `claims: Many<ClaimRow>`.
- `ObservationRow` — `@unique name`, current revision, payload, digest.
- `ObservationVersionRow` — one immutable row per observation revision.
- `RunRow` — `@unique name` (run id), producer, scope, revision, input
  observation.
- `RunTrailRow` — run, input revision, schema, request fingerprint.
- `ClaimRow` — entity link, property, encoded JSON value, schema,
  `@unique stamp`.
- `SupportRow` — run, claim, nullable `until`, nullable `locator`, stamp.
- `ConfidenceRow` — support, float value, stamp (format 7).
- `EdgeRow` — claim, target entity, path, stamp.
- `AliasRow` — entity, namespace, key, run, nullable `until`.
- `MergeRow` / `MergeEndRow` — explicit merge decisions and withdrawal.
- `ChoiceRow` / `ChoiceEndRow` — explicit property selection and
  withdrawal (format 8).
- `TombstoneRow` / `TombstoneEndRow` — hide/revive decisions.

Rules the store enforces:

- One generic claim store; user models never become tables.
- Claims distinct from support; a producer/scope replacement closes only
  its own old supports/aliases.
- Replay: a run id with different content is refused; same content
  returns its original revision.
- Stale input revision, stale graph revision, stale schema refused.
- Schema change: old interpretations are quarantined (standing filter),
  rows retained; `dirty` names stale runs.
- References checked against existing entities; tombstoned targets
  refused; publications onto tombstoned entities refused.
- Merge is a reversible read group; split withdraws the decision.
- Choice is one per entity/property, reversible, and never changes
  evidence; `get` marks `chosen`; `value` reads through it.
- Confidence is metadata in `0..1`; never authority.
- Old hand-table stores (format < 6) are refused by `attach` and `open`.
- Negative witnesses exist for withdrawn decisions, stale claims, stale
  schema, decision replay with other rows, unknown decisions, old stores,
  and schema quarantine through generated accessors.

Constraints of the ORM today:

- `@std/db` `MAX_FIELDS = 6`. Rows are split where the natural shape is
  wider (`RunRow`+`RunTrailRow`, `MergeRow`+`MergeEndRow`,
  `TombstoneRow`+`TombstoneEndRow`).
- Composite `@unique` does not exist. Each logical key uses a synthetic
  `@unique stamp` string derived by one `stamp()` verb.
- `@index` is not available; lookups use generated `where`/`in_<link>`
  and are scans at personal scale.
- File surfaces: asks are filed as `avra-8sb5.44.7` (composite unique)
  and `avra-8sb5.59.44.19` (>6 fields). Do not grow the idiom baseline.

`@std/relation`: in-memory rows under a `Db`; durable answers refuse
record types today, so a relation projection over graph rows would be
recomputed. It is deferred; SQLite rows are the authority.

## 5. Verification and commands

The graph worktree has a compiler and built libs in `build/` (copied
from the lane). After main moves or a new worktree, run `make libs`.

```sh
cd /Users/tristan/projects/tristanMatthias/avra-graph-v2

./build/avra check graph
./build/avra check --baseline tools/idioms.baseline graph   # must be clean
sh tools/watch.sh 3500 ./build/avra test graph/src/tests
sh tools/watch.sh 3500 ./build/avra build graph
python3 graph/tests/smoke.py
sh tools/watch.sh 3500 ./build/avra build graph/tests/unrelated/src/main.av
./graph/tests/unrelated/src/main          # expect: 2 true 2 2 true
```

On the Sprite:

```sh
sh tools/work run --for 30 'make -s libs && ./build/avra test graph/src/tests'
```

Test files in `graph/src/tests/`: storage, partial, evidence, identity,
merge, tombstone, format, refusal, confidence, choice, query. The full
count at the last verified points: 61 on #1141, 71 on selection before
the query slice, query slice 4/4.

Formatting / commit:

```sh
./build/avra fmt --write graph
git add graph
git commit
```

The pre-commit hook formats with the compiler built from the tree; never
use `--no-verify`.

## 6. Hard-won gotchas (read these)

1. **`rerere.enabled = true` in this repo.** It silently replays a
   recorded resolution from a *different* conflict. Every landing rebase
   uses:

   ```sh
   git -c rerere.enabled=false rebase --onto <main> <old-base>
   git range-diff <old-base>..<old-head> <new-main>..<new-head>
   ```

   A green suite does not prove a replayed patch is whole. On #1140 a
   rerere replay staged a partial `Decode.fields`; the proof was the
   added lines being byte-identical (145/145), not the build. After any
   conflicted rebase, name the expected hunks and check them.

2. **Scripted/Bulk edits in this session mangled some type arguments**
   (`List<Candidate>` became `List[Candidate]`), which parses as a
   different construct. After bulk edits, grep for `List[`, `Map[`,
   `Result[`, `Cell[` and fix them. Verify the exact line, not just the
   compile.

3. **`tools/work` sync**: it now derives top-level paths from
   `git ls-tree` plus non-ignored untracked entries, with a 64 MiB cap
   per untracked top-level entry. `graph/` now reaches a Sprite. The
   self-test is `sh tools/work_test.sh` (72 checks).

4. **One heavy process at a time.** Use `sh tools/watch.sh`; the Mac is
   shared. Sprite runs are preferred for whole suites. Disk was ~12 GiB
   free at handover; a full build copy is ~200 MB.

5. **Do not touch #1141 while batch Q (#1152) holds it.** It is frozen
   at `46cc7d39`. Do not push to `feat/generic-personal-graph`.
   The batch process closes/merges it; wait for main's merge sha.

6. **Main's census gate had a stale baseline.** A PR may refuse
   `keepers-a (1)` on `retains/releases` because main's published
   `census-main.txt` is older than the committed budget. Do not waive
   on graph PRs; get both numbers (the PR's per-declaration count and
   main's current published count) and give them to the DB lead.

7. **`make avra` advances the compiler by one generation.** After a
   language/front-end change, a product built immediately runs with the
   old compiler's behavior. `make avra` twice, or `make bootstrap` after
   a language change. A stale `build/avra` in a Sprite answers old
   questions; suspect the binary before the source.

8. **`.avra-cache` can serve a different binary's cached check/build.**
   Remove `.avra-cache` before any differential comparison.

9. **`mut` locals vs the receiver law.** `let g = Graph.memory(...)` is
   accepted and the idiom gate prefers it, but the compiler may warn
   that a writing method writes through a non-`mut` binding (the store
   is a `Db` identity/Cell). Do not add `mut` just to silence the
   warning if the idiom gate flags it as unmutated; this tension is
   known.

10. **Do not add to `tools/idioms.baseline`.** Pay the site or license
    it at the site (`// LICENSED <rule>: reason`). A prose exemption is
    not a licence.

11. **Format versions**: #1141 is format 6; selection bumps to 7
    (confidence) and 8 (choices). The query slice does not bump. If you
    add tables/fields, bump the format and update `format_test.av` and
    `graph/tests/smoke.py`.

12. **Model mentions (unresolved).** The stopped prototype
    (`avra-graph-mentions`, uncommitted) assumed record-level
    `Record.mentions` + a `MentionRow` (support, start, end, surface,
    stamp), format 9. It was stopped before review/commit. See open
    questions.

## 7. Remaining work (against ROADMAP)

Milestone 0 — stabilize: package-rename cache invalidation
(`avra-8sb5.63.25`), cold/warm model-edit tests, concurrent connections,
interrupted transactions, crash recovery.

Milestone 1 — assertion model: complete (partial fields, record-level
validation on assembly, evidence locators, machine-readable issues).

Milestone 2 — identity/conflict: external identities, merge/split,
tombstones, explicit choices, confidence done. **Left:** declared source
priority and recency policies (beyond explicit choice); any automatic
resolution is not designed and should not be assumed.

Milestone 3 — queries: `find`, exact property `where` with limit/offset,
edges, bounded BFS, `explain`, `dirty` done. **Left:** as-of/historical
entity reads, change feeds, FTS5 text search, multi-hop pattern queries,
query explanations (which claims/supports answered a query), work
budgets beyond simple limits.

Milestone 4 — durable processing/classifiers: **design only** in
`graph/WORKERS.md` (jobs, leases, retry/cancel, dependencies, stale
completion, crash recovery, NER flow, protocol sketch). No code.
Suggested first slice is in the doc.

Milestone 5 — derived knowledge: not started. Derived properties/
relationships, dependency recording, precise invalidation, recomputation,
retraction, cycles, derivation tracing, reconstructible `@std/relation`
projection.

Milestone 6 — model evolution: source edit + rebuild and conservative
whole-catalog invalidation work. **Left:** stable model/property identity,
rename semantics, change classification, targeted revalidation,
migration plans, staging/rollback, historical schema as-of reads.

Milestone 7 — operations: basic CLI/HTTP/security only. **Left:** backup/
restore/integrity, retention/compaction/format upgrades, structured
errors (the graph uses strings), resource limits, benchmarks,
concurrency/crash/soak/fuzz, stronger access boundaries, UI.

Engine/library asks: composite `@unique`, >6-field rows, enum `Decode`
for the protocol parser (`avra-8sb5.63.15`), durable relation rows /
projection.

NER/entity recognition: NER and linking are producer work. Today:
- `observe` records a source revision.
- A classifier (external) extracts mentions and publishes `Record`s with
  `identities` `(namespace, key)`, `locator`, `confidence`, and (once
  designed) `mentions`.
- Same external identity collapses to one entity; different names stay
  distinct until an explicit merge; conflicts stay until a choice.
- No automatic similarity matching, no in-engine ML, no scheduler.
- **Gap:** `locator` is per record and a publication declares an entity
  once, so multiple mentions of one entity cannot each carry a span.
  The mention prototype addressed this but was not reviewed/committed.

## 8. Open design questions (need owner decisions)

1. **Mention model**: record-level spans, per-claim spans, or a
   first-class mention table with its own identity and resolver link?
   The stopped prototype assumed record-level.
2. **Keep or revert `graph/WORKERS.md`** (`e6fbd235`). It is design only;
   open questions inside it: clock authority, atomic completion vs
   publish-then-complete, job decision derivation, query digest
   verification, coarse graph revision, retry ownership, cancellation
   latency, automatic feed, retention, mention identity.
3. **Resolution policy**: explicit merge/choice only, or declared source
   priority/recency? Automatic embedding/similarity matching is a
   separate, larger decision.
4. **Next implementation slice order**: jobs implementation, as-of/change
   feed, FTS, or model evolution. Do not start without a written brief.
5. **Mention prototype**: review, discard, or commit? It is uncommitted
   in `avra-graph-mentions`.

## 9. Coordination and workflow

- **DB compiler lead**: intercom session `01a15807` (the session earlier
  named as UI is the DB lead now; `01a15804` died, `01a11cef` stood
  down). Batch Q is **PR #1152**, which includes #1141. The lead sends
  the main merge sha; do not rebase before it.
- A lane commits only in its worktree; main is never committed to
  directly. A PR lands through the gate; the batch/lead merges.
- One Sprite per lane. `sh tools/work run` for heavy work; `work test`
  for a lane's affected tests; `work land` pushes/opens/arms (not used
  for batch members).
- Before landing: `avra check --baseline`, `avra fmt --check`, full suite
  on the Sprite, smoke, unrelated fixture, and a `range-diff` after any
  rebase.
- Use the task DB for substrate asks; the graph's engine asks are
  `avra-8sb5.44.7` and `avra-8sb5.59.44.19`.

## 10. Immediate next steps, in order

1. Wait for batch Q (#1152) to merge; get main's sha.
2. Rebase `feat/graph-selection` onto that main with
   `git -c rerere.enabled=false rebase`, then range-diff. Resolve only
   the query/docs commits; #1141's commit is already in main.
3. Re-run the full graph suite on `avra-ux2`, smoke, unrelated, idiom
   gate. Fix the query slice if it regressed.
4. Open the `feat/graph-selection` PR (confidence, choices, queries,
   WORKERS.md) and queue it. If census refuses, bring both numbers.
5. Decide the mention model and whether to keep/revert the mention
   prototype.
6. Start Milestone 4 jobs implementation from `graph/WORKERS.md`, or
   Milestone 3 as-of/change feed/FTS, one written slice at a time.
