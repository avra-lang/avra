# Compiler DB — inventory of everything tried, built and left behind

2026-10-06 · branch `db-design` · reference main = `origin/main` @ `05fe643` (2026-10-05)
Companion docs: [`2026_10_06_COMPILER_DB.md`](2026_10_06_COMPILER_DB.md) (the design) ·
[`2026_10_06_DB_HANDOFFS.md`](2026_10_06_DB_HANDOFFS.md) (what to do with each lane).

**Evidence labels.** `READ` = I opened the file/line myself. `READ(agent)` = a read-only
sub-agent read it; its full report is an appendix under
[`2026_10_06_DB_INVENTORY/`](2026_10_06_DB_INVENTORY/). `PROBED` = run with a built
compiler. `MEASURED (source)` = a number someone measured, with where it is recorded.
`ESTIMATED` = arithmetic, not a measurement. Nothing was built for this inventory.

---

## 0. The answer to "was more already done?"

**Yes — but it is on main already, not stranded in worktrees.** The surprise runs the
other way: almost nothing valuable is unlanded, and the finished pieces on main were
never joined up.

| | finding | evidence |
|---|---|---|
| 1 | Of **277 worktrees**, 241 have commits not on main by patch-id, but after checking squash-merges only **~8 hold DB work that is not on main**, and only one of those is committed code (`avra-keepers-green@01c219c`). | §1; appendices G1–G4 |
| 2 | The **consumer API already exists and works for a third-party package**: `@relation` / `@key` / `@index` / `@query` / `@input` in `packages/std-relation`. A scratch package using all five ran in 0.76 s. | PROBED `/tmp/db-design/pk` with `avra-ui-own-state/build/avra` @ `6c9add3` |
| 3 | The compiler **barely uses it**: 12 `@relation`, 2 `@query`, 2 `@input` in `std-avrac`; its 32 query families use an internal `@family` mark instead, and `Db.answers` (the durable door for `@query`) has **no production caller**. | READ `compiler/doc_rows.av`, `compiler/inputs.av`, `compiler/families/families.av:149`, `compiler/answers.av`; grep `.answers(` |
| 4 | The owner's rule ("value + what it read with digests, valid iff all match") is **already implemented by hand three times**, each with its own format: `KeyParts` (the hold), `DocFacts`+`FileWitness` (`avra docs`), and kept settlements' `u/c/m/f/b/e` lines. | READ `compiler/record.av:1097`, `compiler/db.av:84-123,658-668`, `compiler/kept_settle.av:171-180` |
| 5 | The **general** version (kernel deps persisted) was built 09-28, **measured to be infeasible at kernel grain** (≥51.6 M deps on the cli, 279 MB pack, +62…216 % time), and deleted 10-01. That measurement is the fact every later design must respect. | READ townhall §6.5a (stale checkout `avra/docs/2026_09_26_COMPILER_DB_TOWNHALL.md:2402-2446`); PR #104 `85f1046` READ(agent) |
| 6 | The epic's design doc (**the townhall, 2,973 lines**) is **not in git anywhere** — one untracked copy in the stale `avra/` checkout — yet code and tickets cite it. (This branch now commits that copy unchanged, as history.) | READ `git ls-files docs \| grep -ci townhall` → 0 |

**The three most valuable unlanded pieces**

1. **`avra-m3-redteam` — 17 red-team cases against durable witnesses** (`.rt/attack5.log`: 11/17 passed, 2026-09-28). The code they attacked is gone; the cases are the acceptance suite for the saved-answer rule. READ(agent G3)
2. **`avra-sources-design` — `docs/2026_10_05_BUILD_TIME_SOURCES.md` §1 + D1–D13** and the two independent reviews of it. The best statement of what a real consumer needs from the two doors, including the 13 questions it parked on "the DB lead". READ(agent G4); READ reviews `REVIEW.md §D`, `REVIEW2.md §C`
3. **`avra-q148-prototype` (uncommitted) — typed `it.mark.args[N]` projection in `collect`**: what turns `@family`/`@query` marks into a typed, queryable catalog and deletes the 32-arm `family_word`. READ(agent G3)

Runners-up: `avra-keepers-green@01c219c` (the 7th hand witness line — proof the hand
format keeps growing); `avra-docfact-side`'s uncommitted kernel-witness test; ticket
`avra-8sb5.57.9.7`'s five walls against "doc facts as relations" (requirements, not code).

---

## 1. Worktree table (all 277)

Columns: `ahead`/`behind` vs `origin/main`; `unlanded` = `git cherry origin/main HEAD`
lines starting `+` (patch-id only — main squash-merges, so a non-zero count does **not**
mean unlanded; the verdict column is the judgement after checking subjects and symbols);
`dirty` = `git status --porcelain` lines excluding `.DS_Store`.
Mechanical columns: MEASURED by `sweep.sh`, 2026-10-05 19:50–19:53. Verdicts: READ(agent G1–G4).

| worktree | branch | HEAD | date | ahead | behind | unlanded (patch-id) | dirty | DB? | verdict | note |
|---|---|---|---|---|---|---|---|---|---|---|
| avra | main | 4385ae7 | 2026-10-01 | 0 | 153 | 0 | 156 | DB | READ ME | STALE main checkout (153 behind). Holds the ONLY copy of the townhall doc (untracked), HANDOFF_COMPILER_DB_2026_10_01.md, MY_PLAN.md, docs/2026_09_24_ORM.md — _test(loops): break and continue in a lambda at a list verb's seat refu_ |
| kp | scratch/keeper-externs | 0b37f05 | 2026-10-01 | 1 | 161 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _scratch: a package-C seat narrowed under its Avra width (keeper witnes_ |
| uib | measure | bbf4460 | 2026-10-03 | 8 | 46 | 6 | 0 | — | — | no DB work (appendix G4 §3) — _measure: merge wasm-flat_ |
| uib2 | measure2 | d539f71 | 2026-10-03 | 36 | 63 | 34 | 1 | — | — | no DB work (appendix G4 §3) — _Merge branch 'wasm-size' into measure2_ |
| uib_base | HEAD | 3304553 | 2026-10-03 | 6 | 46 | 5 | 0 | — | — | no DB work (appendix G4 §3) — _Merge remote-tracking branch 'origin/main' into measure_ |
| uibm | measure-main | 2e448a9 | 2026-10-03 | 1 | 43 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _perf(wasm32): flat child rows in a settled static_ |
| avra-248-stackdoc | stackdoc-248 | 8d7e90e | 2026-10-01 | 1 | 149 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(fibers): the growable-stacks trigger was probed and not met (avra_ |
| avra-arm-decl-rows-gh | fix-embed-fns-test | 51fc38c | 2026-10-01 | 10 | 198 | 10 | 0 | DB | LANDED | #72 (51bfc7d) or a prefix of it — _fix(test): embed's refusal tests need @std/meta actually vendored_ |
| avra-arm-nobump | scratch/arm-nobump | 6e1b3c6 | 2026-09-30 | 3 | 506 | 2 | 2 | DB | ABANDON | settle-loop (`settled_analyses`) negative result; redone as #72 — _wip(db): settle loop and pins_ |
| avra-arm-noloop | scratch/arm-noloop | 6e1b3c6 | 2026-09-30 | 3 | 506 | 2 | 2 | DB | ABANDON | settle-loop (`settled_analyses`) negative result; redone as #72 — _wip(db): settle loop and pins_ |
| avra-arm-rows | lane/arm-decl-rows | 71f402b | 2026-09-30 | 24 | 242 | 16 | 1 | DB | ABANDON | settle-loop (`settled_analyses`) negative result; redone as #72 — _fix(db): every Db owner spells how it takes a late write_ |
| avra-arm47 | arm-decl-rows-gh | e9946b1 | 2026-10-01 | 14 | 122 | 14 | 0 | DB | LANDED | #72 (51bfc7d) or a prefix of it — _fix(hold): every held declaration is minted at hold-settle, before any_ |
| avra-arm47-dbg | HEAD | 9da77ea | 2026-10-01 | 5 | 198 | 5 | 2 | DB | LANDED | #72 (51bfc7d) or a prefix of it — _fix(admit): a read file reaches the components its directory declares_ |
| avra-arm47-fold | arm47-fold | 8d1149b | 2026-10-01 | 3 | 198 | 3 | 0 | DB | LANDED | #72 (51bfc7d) or a prefix of it — _fix(admit): admit lists a module's files uncached, so the reading quer_ |
| avra-ast-relations-s1 | ast-relations-s1 | fbd6541 | 2026-09-30 | 1 | 193 | 0 | 0 | DB | LANDED / superseded | see appendix G1 — _feat(relation): @arena/@side, a relation owned by its own partition_ |
| avra-bench-methodology | bench-methodology | a083b9f | 2026-10-01 | 1 | 142 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(http): the public benchmark's methodology (avra-8sb5.1.31.12)_ |
| avra-bisA | HEAD | bda20d4 | 2026-09-30 | 1 | 216 | 1 | 2 | DB | LANDED (scratch) | bisect copies at a prefix of #72; bisE holds an uncommitted qtrace probe — _feat(db): the compiler's relation Db records through the kernel (avra-_ |
| avra-bisB | HEAD | bda20d4 | 2026-09-30 | 1 | 216 | 1 | 2 | DB | LANDED (scratch) | bisect copies at a prefix of #72; bisE holds an uncommitted qtrace probe — _feat(db): the compiler's relation Db records through the kernel (avra-_ |
| avra-bisC | HEAD | bda20d4 | 2026-09-30 | 1 | 216 | 1 | 2 | DB | LANDED (scratch) | bisect copies at a prefix of #72; bisE holds an uncommitted qtrace probe — _feat(db): the compiler's relation Db records through the kernel (avra-_ |
| avra-bisD | HEAD | bda20d4 | 2026-09-30 | 1 | 216 | 1 | 2 | DB | LANDED (scratch) | bisect copies at a prefix of #72; bisE holds an uncommitted qtrace probe — _feat(db): the compiler's relation Db records through the kernel (avra-_ |
| avra-bisE | HEAD | f4b6246 | 2026-09-30 | 1 | 198 | 1 | 4 | DB | LANDED (scratch) | bisect copies at a prefix of #72; bisE holds an uncommitted qtrace probe — _feat(db): the compiler's relation Db records through the kernel (avra-_ |
| avra-bracket | lane/bracket-lint | 628c42f | 2026-09-29 | 3 | 622 | 3 | 0 | — | — | no DB work (appendix G4 §3) — _chore(cache-attacks): the seat-bit witness names what it asserts_ |
| avra-cache-dead-param | cache-dead-param | 601efc4 | 2026-10-01 | 1 | 160 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _cli(cache): a held file's disagreements read the workspace alone_ |
| avra-cache-readonly | cache-readonly | 00811b8 | 2026-10-01 | 1 | 167 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _compiler(cache): an `avra cache` mode keeps nothing — its store sets e_ |
| avra-cache-red | HEAD | 3f073ba | 2026-10-01 | 0 | 168 | 0 | 1 | DB | LANDED / scratch | see appendix G2 — _fix(compiler): a relation's cache-soundness bug — a hash read as a rev_ |
| avra-cache-walk | cache-walk | a1da8fe | 2026-10-01 | 1 | 173 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _cli(cache): why, changed, dependents and the summary refuse until the _ |
| avra-cache-walk-2 | cache-walk-2 | 7b45fa1 | 2026-10-01 | 1 | 171 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _compiler(cache): every `avra cache` mode is a projection of one lazy i_ |
| avra-canon-flake | canon-flake | 384ca89 | 2026-10-01 | 1 | 153 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(shim, fmt): a small package's fmt --check is light, never queued o_ |
| avra-cb-0600b2c | HEAD | 0600b2c | 2026-09-30 | 0 | 429 | 0 | 1 | DB | LANDED / scratch | see appendix G2 — _feat(db): @index kind on every arena relation; range scans read bucket_ |
| avra-cb-33dcdb5 | HEAD | 33dcdb5 | 2026-09-30 | 0 | 372 | 0 | 1 | DB | LANDED / scratch | see appendix G2 — _perf(m5-index): collect gathers off Decl's word and marks buckets; int_ |
| avra-cb-441d58e | HEAD | 441d58e | 2026-09-30 | 0 | 430 | 0 | 1 | DB | LANDED / scratch | see appendix G2 — _tools(land): absorb the queue and verify it as a train by default_ |
| avra-cb-c3275b7 | HEAD | c3275b7 | 2026-09-30 | 0 | 376 | 0 | 1 | DB | LANDED / scratch | see appendix G2 — _refactor(m5-decl): Decl is the relation row itself; DeclRow and its co_ |
| avra-cb-e8d1641 | HEAD | e8d1641 | 2026-09-30 | 0 | 429 | 0 | 1 | DB | LANDED / scratch | see appendix G2 — _feat(db): NameFacts gains a declaration-grain door for foreign readers_ |
| avra-cell-set-at | cell-set-at | efd26e5 | 2026-09-30 | 3 | 202 | 3 | 1 | CONSUMER | LANDED / no DB | see appendix G4 — _memory: a step that may answer its own box keeps the depth below a bor_ |
| avra-cell-shared-empty | cell-shared-empty | 375e358 | 2026-09-30 | 1 | 223 | 0 | 1 | CONSUMER | LANDED / no DB | see appendix G4 — _test(cells): two cells seeded from one empty list each own their list_ |
| avra-census-linux | census-linux | 250f2c5 | 2026-09-30 | 1 | 217 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _tools(census): the census symbol is found on Linux too_ |
| avra-census-sites | census-sites | f148662 | 2026-09-30 | 1 | 210 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _runtime, tools(census): a site's name resolves on Linux too_ |
| avra-channels-design | channels-design | 2d716bd | 2026-10-05 | 5 | 9 | 5 | 1 | CONSUMER | LANDED / no DB | see appendix G4 — _docs(flow): v4 — the third review's seven items; ten decisions for the_ |
| avra-ci-checks | ci-checks | 650503b | 2026-09-30 | 6 | 242 | 6 | 0 | — | — | no DB work (appendix G4 §3) — _ci: runs start from the ready image, fetch twenty commits, and key the_ |
| avra-ci-idioms-all | ci-idioms-all | 3a8076a | 2026-10-01 | 1 | 161 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _ci, tools(work): idioms are checked for every affected package, not on_ |
| avra-ci-keepers | ci-keepers | 1a20c34 | 2026-10-01 | 1 | 165 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _ci: the train runs the static keepers, and a dispatched run runs them _ |
| avra-ci-main-cache | ci-image-main | 24254c9 | 2026-09-30 | 1 | 240 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _ci: the image builds from main only_ |
| avra-ci-shards | ci-shards | ae7d7bb | 2026-09-30 | 2 | 238 | 2 | 0 | — | — | no DB work (appendix G4 §3) — _ci: one job per train, so ten trains test at once_ |
| avra-claude-md-names | claude-md-names | 618b24f | 2026-10-01 | 1 | 168 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(CLAUDE.md): the impl name read is impls_named; AVRA_QTRACE also t_ |
| avra-claude-pr-gate | claude-pr-gate | fa0e8db | 2026-10-02 | 1 | 95 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(CLAUDE.md): a PR tests itself first; the train tests the combinat_ |
| avra-claude-timeout-rule | claude-timeout-rule | 3984cb6 | 2026-10-01 | 1 | 110 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(CLAUDE.md): nothing runs longer than a couple of minutes_ |
| avra-cleanup-land-sh | cleanup-land-sh | e26b6e2 | 2026-09-30 | 1 | 223 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _tools: land.sh and its queue retire; sp ranks Sprites itself; local ma_ |
| avra-cli-fresh-roots | fix/cli-tests-fresh-roots | 42cb36a | 2026-09-30 | 1 | 290 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _test(cli): every cli test that writes under /tmp runs in its own direc_ |
| avra-client-method | client-method | e418c81 | 2026-10-01 | 1 | 111 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _refactor(std-http): the client derives the request method from the hea_ |
| avra-collect148 | collect161-witness | 697673d | 2026-10-01 | 1 | 122 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _test(collect): a family mark's rank arg orders a collect enum, not sou_ |
| avra-collections-bench | collections-bench | 67c8c09 | 2026-09-30 | 2 | 201 | 2 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _docs(collections): 3.8.1, the bench's baseline on a Sprite_ |
| avra-collections-chains | HEAD | 44922a2 | 2026-10-04 | 0 | 21 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _fix(pipeline): a Bytes or Str head's element is int (#259)_ |
| avra-collections-pipeline | collections-pipeline | 06eca3a | 2026-10-01 | 1 | 147 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _feat(lists): comprehensions lower through a pipeline (E1)_ |
| avra-const-div | const-div | da0ba9a | 2026-09-30 | 1 | 217 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _backend: a division by a plain constant is sdiv/srem, with no runtime _ |
| avra-consume74 | perf/consume74 | 06522bd | 2026-09-30 | 3 | 217 | 3 | 0 | DB | LANDED / scratch | see appendix G3 — _fix(control): a bytes literal runs no children_ |
| avra-consumed-ir-of | consumed-ir-of | cc75716 | 2026-09-30 | 1 | 205 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _fix(compiler): ensure_consumed stays armed past disarm, as ensure_refs_ |
| avra-cse-old | HEAD | 5725537 | 2026-10-01 | 0 | 223 | 0 | 1 | — | — | no DB work (appendix G4 §3) — _docs: collection vocabulary — one protocol, fused chains, lists/maps/s_ |
| avra-db-119 | lane/db-importer-names | dc0507f | 2026-09-30 | 1 | 430 | 1 | 0 | DB | LANDED / superseded | see appendix G1 — _fix(cache): an importer keys on the files its uses reach, never a pack_ |
| avra-db-125 | lane/db-impl-reach | fc3b23d | 2026-09-30 | 4 | 195 | 4 | 47 | DB | LANDED / superseded | see appendix G1 — _fix(cache): an added file nothing reaches holds its readers; the reach_ |
| avra-db-design | db-design | 05fe643 | 2026-10-06 | 0 | 0 | 0 | 0 | DB | THIS | this design branch — _ui: a component's body is its view, and an instance owns its state (#2_ |
| avra-db159-collect | db159-collect | c79c7d6 | 2026-10-01 | 1 | 141 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _feat(compiler): collect's `by` compares typed literals, and `dense` or_ |
| avra-db160-cellget-rule | db160-cellget-rule | 72df24a | 2026-10-01 | 1 | 133 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _idiom(compiler.cell_get_copy): a Cell get/write/set round trip copies _ |
| avra-decl-ids-side | decl-ids-side | 31a4ab8 | 2026-10-01 | 1 | 182 | 0 | 0 | DB | LANDED / superseded | see appendix G1 — _features(decls): decl_ids is a partition-owned @side relation_ |
| avra-decl-owner-column | decl-owner-column | 4107a8f | 2026-10-01 | 1 | 177 | 0 | 0 | DB | LANDED / superseded | see appendix G1 — _feat(compiler): DeclAt — a node's owning decl, an O(1) read not a resc_ |
| avra-decl-replace | decl-replace | 8c6b8bd | 2026-10-01 | 5 | 180 | 5 | 0 | DB | LANDED / superseded | see appendix G1 — _test(db): the re-admission witness builds each parse's files fresh, no_ |
| avra-decl-replace-red | HEAD | acf083c | 2026-10-01 | 0 | 180 | 0 | 5 | DB | LANDED / superseded | see appendix G1 — _features(decls): decl_ids is a partition-owned @side relation (#99)_ |
| avra-decl-rows-grain | decl-rows-grain | 8f53fab | 2026-10-01 | 1 | 110 | 0 | 0 | DB | LANDED / superseded | see appendix G1 — _feat(decls): declaration row reads at name-bucket grain (avra-8sb5.57._ |
| avra-decl-rows-red | HEAD | f3b604a | 2026-10-01 | 0 | 152 | 0 | 3 | DB | LANDED / superseded | see appendix G1 — _fix(shim, fmt): a small package's fmt --check is light, never queued o_ |
| avra-decl-unadmit | decl-unadmit | 413b0af | 2026-10-02 | 2 | 83 | 2 | 0 | DB | LANDED / superseded | see appendix G1 — _fix(gate): the compiler build gets a higher wreck-cap, and the preflig_ |
| avra-declares-arg | lane/declares-arg | 2242b17 | 2026-09-30 | 0 | 428 | 0 | 1 | DB | LANDED | zero ahead — _fix(annotations): a declaring annotation's call argument is refused, n_ |
| avra-decls-fence | lane/decls-fence | 83603ca | 2026-09-30 | 2 | 245 | 0 | 0 | DB | LANDED / superseded | see appendix G1 — _Merge branch 'refs/heads/main' into lane/decls-fence_ |
| avra-deepwalks | deepwalks | 47122b5 | 2026-10-02 | 1 | 77 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _feat(lists): the inline-lambda lowering half (avra-8sb5.65.3.3)_ |
| avra-deepwalks-range | deepwalks-rangetype | 260bd2d | 2026-10-02 | 1 | 72 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _feat(lists): Type.Range — a range's own receiver identity (avra-8sb5.6_ |
| avra-deepwalks-rangetest | deepwalks-rangetest | 33e995e | 2026-10-04 | 2 | 21 | 2 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _fix(types): a range's element is its counting int (avra-8sb5.65.3.4)_ |
| avra-deepwalks-seed | deepwalks-seed | 84c6de1 | 2026-10-02 | 1 | 73 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _chore(seed): refresh over (lo..hi) as a value (avra-8sb5.65.3.4)_ |
| avra-derived-merge | lane/orm-derived-merge | 5796907 | 2026-09-25 | 2 | 1561 | 1 | 0 | DB | LANDED / superseded | see appendix G1 — _chore(seed): the compiler re-emitted for Declared_ |
| avra-docfact-side | docfact-side | 3f073ba | 2026-10-01 | 0 | 168 | 0 | 2 | DB | KEEP (uncommitted test) | doc_fact kernel-witness test: edit of decl A reruns only A's reader — _fix(compiler): a relation's cache-soundness bug — a hash read as a rev_ |
| avra-docs-collections | docs/collections | 87e27cb | 2026-09-30 | 3 | 291 | 3 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _docs(collections): the tracker epic_ |
| avra-docs-platform | docs/platform-map | c9d4035 | 2026-09-30 | 2 | 291 | 2 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _docs(platform): §5 — what the language and std need, smallest first_ |
| avra-docs-render | docs-render | 7747fb2 | 2026-10-02 | 0 | 110 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _refactor(std-http): the client derives the request method from the hea_ |
| avra-docs-validate | docs/validate-and-routes | a5f6fba | 2026-09-30 | 5 | 291 | 4 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _Merge branch 'main' into docs/validate-and-routes_ |
| avra-docset-close | docset-close | a41777e | 2026-10-01 | 1 | 133 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _docs(http): the H9 doc set is closed — source of truth named, the rest_ |
| avra-dyn | lane/dyndispatch | 4efd4db | 2026-09-30 | 23 | 430 | 22 | 1 | — | — | no DB work (appendix G4 §3) — _fix(traits): a type's same-named members are asked through the hook, s_ |
| avra-dyn-dispatch | dyn-dispatch | ecb1643 | 2026-09-30 | 3 | 217 | 3 | 0 | — | — | no DB work (appendix G4 §3) — _style(dyn): type identity through core's same_type, not a licensed ind_ |
| avra-e2e-train-scratch-1 | e2e-train-scratch-1 | c136f57 | 2026-09-29 | 1 | 521 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _docs(e2e): land-train proof scratch file 1 of 3 (to be dropped)_ |
| avra-e2e-train-scratch-2 | e2e-train-scratch-2 | 2cb2c7f | 2026-09-29 | 1 | 521 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _docs(e2e): land-train proof scratch file 2 of 3 (to be dropped)_ |
| avra-e2e-train-scratch-3 | e2e-train-scratch-3 | 34359f0 | 2026-09-29 | 1 | 521 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _docs(e2e): land-train proof scratch file 3 of 3 (to be dropped)_ |
| avra-env-inherit | env-inherit | 92dd625 | 2026-10-01 | 2 | 180 | 2 | 0 | — | — | no DB work (appendix G4 §3) — _test(cli): the two spawning tests ask for the inherited environment by_ |
| avra-eval-rc | eval-rc | 2e8e93b | 2026-10-02 | 2 | 89 | 2 | 1 | — | — | no DB work (appendix G4 §3) — _fix(eval): hold a box a live task names; budget the h2 park_ |
| avra-families2 | families2 | 9320642 | 2026-10-01 | 1 | 116 | 0 | 2 | DB | LANDED / scratch | see appendix G3 — _feat(db): the DeclId-keyed family markers (avra-8sb5.57.148 wave 2b)_ |
| avra-families2b | families2b | a539d85 | 2026-10-01 | 1 | 115 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _feat(db): the non-dense family markers complete the set (avra-8sb5.57._ |
| avra-families2c | families2c | 583f93c | 2026-10-01 | 1 | 111 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _feat(db): the family collect orders by rank, append-stable (avra-8sb5._ |
| avra-families2d | families2d | 1ea19b2 | 2026-10-01 | 1 | 110 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _feat(enums): E.all — every variant of a payload-free enum (avra-8sb5.5_ |
| avra-family-order-keeper | family-order-keeper | e810cc2 | 2026-10-01 | 1 | 153 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _ci(tools): the Family ordinal order is append-only — a moved variant i_ |
| avra-files-stream | files-stream | 31e620c | 2026-10-01 | 1 | 110 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _feat(std-http): a large static file is served as a pulled stream (avra_ |
| avra-fix-4647 | fix/46-47 | 745c383 | 2026-09-28 | 1 | 925 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _fix(decls_mint): a batch's later declaration wears its own floor_ |
| avra-fix-kept-package-key | fix-kept-package-key | 51767ad | 2026-09-30 | 1 | 211 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _fix(build): a program's key covers its reached packages' own objects_ |
| avra-fix-suite-paths | fix-suite-paths | 8b2c67d | 2026-09-30 | 1 | 240 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _ci, tools(work): a suite runs by its package path; affected_packages a_ |
| avra-fix-witness-base | fix-witness-base | 5725537 | 2026-10-01 | 0 | 223 | 0 | 1 | DB | LANDED / scratch | see appendix G2 — _docs: collection vocabulary — one protocol, fused chains, lists/maps/s_ |
| avra-flip175 | flip175 | da685a5 | 2026-10-02 | 1 | 92 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _feat(db): Family is the collected enum (avra-8sb5.57.12.4)_ |
| avra-fmt-bugs | lane/wrap | 03bddfa | 2026-09-27 | 0 | 1243 | 0 | 13 | — | — | no DB work (appendix G4 §3) — _refactor(nodes): Param's span moves off the value into a ParamId-keyed_ |
| avra-fp-tags | fp-tags | 2eb7da5 | 2026-10-01 | 1 | 165 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _compiler(voices): a dispatch choice's fingerprint takes its own tags_ |
| avra-from-trait | from-trait | 92d3226 | 2026-09-30 | 3 | 197 | 3 | 0 | — | — | no DB work (appendix G4 §3) — _fix(traits): an abstract static's `Self` is each signatory's type — ev_ |
| avra-gate-preflight2 | land-oom-guard | e36514a | 2026-10-02 | 1 | 90 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(land): a Sprite build OOM is not a gate refusal_ |
| avra-gates-fix | gates-fix | 65760d3 | 2026-09-30 | 1 | 211 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _compiler(voices): opt_decl_fp takes its own tags, 183 and 184; 181 and_ |
| avra-generic-traits | generic-traits | a84093e | 2026-09-30 | 2 | 223 | 2 | 0 | — | — | no DB work (appendix G4 §3) — _style(format): canonical formatting of the trait printer_ |
| avra-gimpls | gimpls | 66f5c79 | 2026-10-01 | 1 | 133 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(compiler): a trait impl over a user generic type lands, one body _ |
| avra-gimpls2 | gimpls2 | c98cd82 | 2026-10-01 | 1 | 125 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(compiler): a trait impl over a built-in generic type lands too_ |
| avra-gtraits | lane/gtraits | 397a75d | 2026-09-30 | 13 | 289 | 12 | 0 | — | — | no DB work (appendix G4 §3) — _style(format): canonical formatting of the spread printer_ |
| avra-h2-laws-index | h2-laws-index | f625b24 | 2026-10-01 | 1 | 140 | 0 | 0 | — | not DB | HTTP docs — _docs(http): the doc set says the framing laws' H2 section is there (av_ |
| avra-h2-task-stack | h2-task-stack | e644067 | 2026-10-01 | 1 | 185 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(std-http): an HTTP/2 body reader waits in place, never recursing p_ |
| avra-h2client | h2client | 80a0ae3 | 2026-10-01 | 1 | 122 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(std-http): an HTTP/2 client connection — Role on H2Conn, two requ_ |
| avra-h2clients | h2pump2 | eed38e1 | 2026-10-02 | 1 | 84 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _refactor(std-http): fetch's h2 pump is the driver's, leaving one pump_ |
| avra-h2pool | h2pool | e5faa11 | 2026-10-01 | 1 | 110 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(std-http): the client prefers HTTP/2 by ALPN, falling back to 1.1_ |
| avra-hardening-doc | hardening-doc | 5eb9d71 | 2026-10-01 | 1 | 144 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(http): the server hardening reference — every bound and deadline _ |
| avra-hashfix | fix/map-hash | be776a2 | 2026-09-30 | 1 | 203 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _fix(runtime): a map's cost is set by its key count, never by who chose_ |
| avra-held-findings | held-findings | 9ba5fd5 | 2026-09-30 | 1 | 223 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _fix(check): a held file's rule findings reach the ratchet_ |
| avra-held-path | perf/held-path | 74f963b | 2026-09-30 | 3 | 245 | 1 | 0 | DB | LANDED / scratch | see appendix G2 — _Merge branch 'refs/heads/main' into perf/held-path_ |
| avra-heldsettle | fix/held-settle | 6469b85 | 2026-09-28 | 1 | 1092 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _Merge branch 'refs/heads/main' into fix/held-settle_ |
| avra-hold-new-decl | hold-new-decl | bc049cd | 2026-10-01 | 1 | 173 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _hold: a held collect carries its type, so a re-read file that names it_ |
| avra-http-app | lane/http-app | d1ac1d4 | 2026-09-30 | 54 | 242 | 39 | 0 | — | — | no DB work (appendix G4 §3) — _chore(land): the ratchet baseline moved for lane/http-app's landing_ |
| avra-http-app-warm | HEAD | 413d526 | 2026-09-30 | 53 | 242 | 38 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'refs/heads/main' into lane/http-app_ |
| avra-http-client | lane/http-client | 7f17e5d | 2026-09-30 | 12 | 291 | 10 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'main' into lane/http-client_ |
| avra-http-coding | http-coding | cdbe723 | 2026-10-02 | 1 | 95 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(http_compress): a streamed response is coded incrementally (avra-_ |
| avra-http-conformance | lane/http-conformance | 6120659 | 2026-09-30 | 24 | 291 | 19 | 0 | — | — | no DB work (appendix G4 §3) — _fix(http): the conformance laws across the client merge, on main's str_ |
| avra-http-flagloops | http-flagloops | 1dd3e3a | 2026-10-01 | 1 | 156 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _idiom(loops.flag_loop): four h2 test loops are break, not a flag_ |
| avra-http-h2fix | lane/http-h2fix | d87c840 | 2026-09-30 | 24 | 291 | 19 | 0 | — | — | no DB work (appendix G4 §3) — _perf(std-http): the HTTP/2 request path builds 42% fewer boxes_ |
| avra-http-harden | lane/http-harden | 20964fa | 2026-09-30 | 29 | 291 | 24 | 0 | — | — | no DB work (appendix G4 §3) — _feat(net, http): a Signal tasks park on; the pool waits for a slot, SS_ |
| avra-http-http2 | lane/http-http2 | 78fbd2b | 2026-09-30 | 14 | 291 | 9 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'main' into lane/http-http2_ |
| avra-http-hygiene | lane/http-hygiene | 9d5e5a9 | 2026-09-30 | 26 | 291 | 21 | 1 | — | — | no DB work (appendix G4 §3) — _Merge branch 'main' into lane/http-hygiene_ |
| avra-http-hygiene-fix | http-hygiene-fix | c843cc0 | 2026-09-30 | 2 | 217 | 2 | 0 | — | — | no DB work (appendix G4 §3) — _cells: Cell.new opens only a list or map seed_ |
| avra-http-idiomfix | fix/http-client-flag | 65c5d53 | 2026-09-30 | 1 | 430 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _std-http: the client's reply wait seeds on its first read, not a null _ |
| avra-http-perf | lane/http-perf | af431d2 | 2026-09-30 | 16 | 291 | 13 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'main' into lane/http-perf_ |
| avra-http-streaming | lane/http-streaming | f365ab9 | 2026-09-30 | 0 | 417 | 0 | 5 | — | — | no DB work (appendix G4 §3) — _refactor(http): the review round over the streaming arc_ |
| avra-http-wave2 | http-wave2-land | f29be62 | 2026-09-30 | 1 | 218 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(http): HTTP/2 RFC fixes, hardening, client and conformance — one _ |
| avra-https-tour | https-tour | 467cdac | 2026-10-01 | 1 | 141 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(http): the HTTPS tour — serve a site in ten lines, with its progr_ |
| avra-impl-closure-trace | impl-closure-trace | ac4d4bb | 2026-09-30 | 1 | 227 | 1 | 2 | DB | ABANDON | .57.127 closed: could not reproduce — _scratch: trace127.sh for avra-8sb5.57.127's open question_ |
| avra-importer-reach | importer-reach-pins | f719dd8 | 2026-10-01 | 1 | 188 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _test(cache): an impl's reach is pinned across packages, through a move_ |
| avra-integrate-c-s2b | HEAD | 34bb3f4 | 2026-09-21 | 1 | 2224 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _merge: lane c-s2b — chore(seed): the S2b compiler, re-emitted on the r_ |
| avra-keeper-drafts | keeper-drafts | ee9f656 | 2026-09-30 | 1 | 201 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _tools(queue_keeper): a PR that keeps failing is held as a draft, so th_ |
| avra-keeper-stuck | keeper-stuck | bc23e1b | 2026-09-30 | 1 | 198 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _tools(queue_keeper): an UNMERGEABLE entry leaves the queue it stalls; _ |
| avra-keepers-green | keepers-green | 5f495f5 | 2026-10-05 | 4 | 0 | 4 | 0 | DB | KEEP (active) | 01c219c: kept settlement gains an `l` (layout) line — 7th hand witness line kind — _ci: the keepers are one list, and codecs, fmt-lossless and cache-attac_ |
| avra-kept-settle | perf/kept-settle | 25b4780 | 2026-09-30 | 6 | 312 | 4 | 1 | DB | LANDED / scratch | see appendix G2 — _fix(hold): a refused hold rebuilds quietly — one line, the words kept_ |
| avra-land-batch-wt | land/batch-integration | 73b7cd6 | 2026-09-30 | 16 | 223 | 8 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'refs/heads/fix/http-client-flag' into land/batch-integra_ |
| avra-land-batch-wt-warm | HEAD | a8af992 | 2026-09-30 | 57 | 242 | 39 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'refs/heads/lane/docs-decl-query-v2' into land/batch-inte_ |
| avra-land-enqueue | land-enqueue | 5b1320e | 2026-10-01 | 1 | 177 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _tools(work): land queues the PR directly once its own check passes, so_ |
| avra-land-speed-wt | HEAD | a8af992 | 2026-09-30 | 57 | 242 | 39 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'refs/heads/lane/docs-decl-query-v2' into land/batch-inte_ |
| avra-land-stable | tools/land-stable | 13d1079 | 2026-09-30 | 4 | 245 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _idioms(compiler): a test's fixed /tmp/ path is refused, and every test_ |
| avra-lang-loops | lang-loops-2 | 3ae5bb7 | 2026-10-01 | 2 | 185 | 2 | 0 | — | — | no DB work (appendix G4 §3) — _feat(text): `with_room(n)` — an empty `Bytes` that appends grow in pla_ |
| avra-lang-names | lane/lang-names | 0b26d5c | 2026-10-01 | 4 | 185 | 4 | 0 | — | — | no DB work (appendix G4 §3) — _fix(cache): a file that re-exports a name is reached by its importers_ |
| avra-licenses | fix/licenses-by-decl | d79c729 | 2026-09-29 | 2 | 532 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'refs/heads/main' into fix/licenses-by-decl_ |
| avra-licenses-warm | HEAD | d79c729 | 2026-09-29 | 2 | 532 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'refs/heads/main' into fix/licenses-by-decl_ |
| avra-link-8d1149b | HEAD | 8d1149b | 2026-10-01 | 3 | 198 | 3 | 1 | DB | LANDED / scratch | see appendix G2 — _fix(admit): admit lists a module's files uncached, so the reading quer_ |
| avra-link-c004703 | HEAD | c004703 | 2026-10-01 | 4 | 198 | 4 | 1 | DB | LANDED / scratch | see appendix G2 — _fix(embed): a file is data only when an embed named it_ |
| avra-lock-order | lane/lock-order | 29185c8 | 2026-09-29 | 1 | 541 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(land-test): lock-fifo proves arrival order by the order of holds, _ |
| avra-lone-0448e89 | HEAD | 0448e89 | 2026-10-01 | 2 | 198 | 2 | 1 | DB | LANDED / scratch | see appendix G2 — _fix(compiler): embed()'s file is admitted at parse, its path refused u_ |
| avra-lone-6a7d90f | HEAD | 6a7d90f | 2026-10-01 | 1 | 198 | 1 | 1 | DB | LANDED / scratch | see appendix G2 — _feat(db): the compiler's relation Db records through the kernel (avra-_ |
| avra-lone-main | HEAD | 61721c7 | 2026-10-01 | 0 | 162 | 0 | 1 | DB | LANDED / scratch | see appendix G2 — _docs(dogfooding): AVRA_QTRACE's declare line and typing's pass order (_ |
| avra-loops-lambda-seat | loops-lambda-seat | 04dcc47 | 2026-10-01 | 1 | 156 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _test(loops): break and continue in a lambda at a list verb's seat refu_ |
| avra-loops-stack | tmp/loops-stack | b05b0dd | 2026-09-30 | 3 | 198 | 3 | 0 | — | — | no DB work (appendix G4 §3) — _fix(control): a jump runs nothing of its own — the consumes pass needs_ |
| avra-m3-close | m3-close | 35dbf0f | 2026-10-01 | 4 | 177 | 4 | 1 | DB | LANDED / scratch | see appendix G3 — _test(fixtures): name ordinals by their place in Family_ |
| avra-m3-red | HEAD | 2bfdc10 | 2026-10-01 | 1 | 180 | 1 | 2 | DB | LANDED / scratch | see appendix G3 — _compiler(hold): a gone file's record keys on bytes; the flattened witn_ |
| avra-m3-redteam | redteam/m3-witness-attacks | a644ba4 | 2026-09-28 | 1 | 1185 | 1 | 1 | DB | REWORK (keep cases) | 17 red-team cases vs durable witnesses, 11/17 passed; attacked code deleted by #104 — _test(compiler/witness): red-team cases for durable witnesses — each as_ |
| avra-m5-s2 | lane/m5-decl | b49cf16 | 2026-09-30 | 16 | 378 | 6 | 3 | DB | LANDED / scratch | see appendix G3 — _Merge branch 'lane/db-impl-reach' into lane/m5-decl_ |
| avra-m5-s2-census-base | HEAD | 5c08d15 | 2026-09-29 | 0 | 511 | 0 | 1 | DB | LANDED / scratch | see appendix G3 — _Merge branch 'refs/heads/main' into tools/main-guard_ |
| avra-m5b-base | HEAD | 441d58e | 2026-09-30 | 0 | 430 | 0 | 1 | DB | LANDED / scratch | see appendix G3 — _tools(land): absorb the queue and verify it as a train by default_ |
| avra-m5b-facts | lane/m5b-facts | 6371f8c | 2026-09-30 | 2 | 353 | 1 | 0 | DB | LANDED / scratch | see appendix G3 — _perf(db): name_slice_fp folds a declaration's columns in one pass_ |
| avra-m5b-index | lane/m5b-index | ba4a682 | 2026-09-30 | 0 | 428 | 0 | 1 | DB | LANDED / scratch | see appendix G3 — _test(failures): the syntax-edge witness reads error sites after a full_ |
| avra-m5s2-cand | HEAD | 64c0e09 | 2026-09-30 | 5 | 511 | 2 | 0 | DB | LANDED / scratch | see appendix G3 — _perf(m5-decl): a declaration read is one cell and one index — Decls pi_ |
| avra-mainbc | HEAD | bc2d64a | 2026-09-30 | 0 | 331 | 0 | 1 | DB | LANDED / scratch | see appendix G3 — _chore(seed): the compiler re-emitted for batch(perf/view93 perf/once10_ |
| avra-mapswalks | mapswalks | ba4504c | 2026-10-02 | 2 | 75 | 2 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _fix(maps): the nullable-values spec uses one coalesce, not two_ |
| avra-mapswalks-order | mapswalks-order | 8f34741 | 2026-10-04 | 1 | 25 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _test(maps): an insertion-order guarantee under adversarial keys (avra-_ |
| avra-mapswalks-pair | mapswalks-pair | b208e93 | 2026-10-04 | 1 | 21 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _feat(loops): `for k, v in m` — a map walks paired (avra-8sb5.65.3.10)_ |
| avra-mapswalks-remove | mapswalks-remove | d7c0aa9 | 2026-10-02 | 1 | 73 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _feat(maps): remove and is_empty (avra-8sb5.65.3.10)_ |
| avra-measure124 | HEAD | 146bdee | 2026-09-30 | 3 | 430 | 3 | 0 | DB | LANDED / scratch | see appendix G3 — _wip: measure split_ |
| avra-mem-ceiling | perf/mem-ceiling | 67eefdb | 2026-09-30 | 4 | 223 | 4 | 0 | DB | LANDED / scratch | see appendix G2 — _runtime: the memory ceiling confirms against the allocator before it t_ |
| avra-mh-held | HEAD | bc2d64a | 2026-09-30 | 0 | 331 | 0 | 35 | DB | REWORK (salvage tests) | stuck mid-rebase; 4fef2a3 entry-file confound fix to four assertions not on main — _chore(seed): the compiler re-emitted for batch(perf/view93 perf/once10_ |
| avra-n3-apply | lane/n3-apply | af411a2 | 2026-09-29 | 1 | 684 | 1 | 0 | DB | REWORK | `DbKind` as a `collect enum` (dual `@family @db_kind` marks); orders by name -> moves ordinals — _feat(N3): synthesize Family and DbKind via collect enum_ |
| avra-n3-family | lane/n3-family | 4262aa6 | 2026-09-30 | 6 | 511 | 3 | 0 | DB | LANDED / scratch | see appendix G3 — _refactor(N3): Family's ordinal is its place in the declaration_ |
| avra-n3-ordinal | n3-ordinal | 6332a17 | 2026-10-01 | 1 | 178 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _refactor(N3): Family's ordinal is its place in the declaration_ |
| avra-net-copies | net-copies | cd9653b | 2026-10-01 | 1 | 116 | 0 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _fix(std-net): a closed Listener or Poller is closed in every copy (avr_ |
| avra-os-watch | os-watch-dev2 | 7a3b708 | 2026-10-05 | 4 | 7 | 3 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _feat(cli): `avra dev` is woken by the host's file events — `--interval_ |
| avra-perf-g1merge | HEAD | 9aa59b8 | 2026-09-30 | 5 | 331 | 3 | 0 | DB | LANDED / scratch | see appendix G2 — _Merge commit '811eab7' into HEAD_ |
| avra-perf-hang-timeouts | perf/hang-timeouts | ea85625 | 2026-10-01 | 1 | 161 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _test(cli): a run of the compiler is bounded as a hang, never as a slow_ |
| avra-perf-hold-keys | perf/hold-keys | 9aabcb1 | 2026-10-01 | 1 | 151 | 1 | 3 | DB | ABANDON | hand `view_print` key: unsound (23 cache-attack fails) or slow (1019->3824 ms) — _perf(warm): a module's view is kept under the closure it is a function_ |
| avra-perf-kvm-revert | HEAD | bc2d64a | 2026-09-30 | 0 | 331 | 0 | 1 | DB | ABANDON | reverts of kernel fix 0be202b still on main — _chore(seed): the compiler re-emitted for batch(perf/view93 perf/once10_ |
| avra-perf-load-named | perf/load-named | 81cc3d9 | 2026-10-01 | 1 | 156 | 0 | 2 | DB | LANDED / scratch | see appendix G2 — _perf(warm): a minted declaration's doc fact is written in place_ |
| avra-perf-m5b-cand | perf/m5b-names | b633486 | 2026-09-30 | 3 | 353 | 2 | 0 | DB | LANDED / scratch | see appendix G2 — _perf(db): a name slice folds its own cells; the namespace rides Visibl_ |
| avra-perf-speed-gate | perf/speed-gate | 8d528c5 | 2026-09-30 | 0 | 240 | 0 | 2 | — | — | no DB work (appendix G4 §3) — _ci: main caches its compiler, so every PR and train starts from it (#3_ |
| avra-perf-warm-124 | perf/kept-settle-141 | e61260b | 2026-10-01 | 1 | 161 | 0 | 9 | DB | LANDED / scratch | see appendix G2 — _perf(warm): a read file's const reuses its kept verdict while everythi_ |
| avra-perf-warm-parse | perf/warm-parse | fb53cec | 2026-10-01 | 1 | 188 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _perf(warm): a module's block words and a file's wire siblings are read_ |
| avra-perf101-slice2 | perf101-slice4 | be10ece | 2026-10-01 | 1 | 110 | 0 | 5 | DB | LANDED / scratch | see appendix G2 — _perf(warm): a warm edit no longer parses the held provider files_ |
| avra-perf101-warm | perf101-loadadmit | 9add691 | 2026-10-01 | 1 | 139 | 0 | 0 | DB | LANDED / scratch | see appendix G2 — _perf(warm): a module's record fault is read once, not per importer_ |
| avra-pipe-op | pipe-op | ce535fd | 2026-10-05 | 4 | 0 | 4 | 1 | DB-adjacent | ACTIVE | `|>` parse mark restamps a fingerprint — _wip: pipe — voice helper renamed, README_ |
| avra-q148-prototype | q148-prototype | 51d36f4 | 2026-10-01 | 0 | 161 | 0 | 12 | DB | REWORK | typed `it.mark.args[N]` projection in `collect` (uncommitted, +422/-85) — _feat(compiler): Expr and Stmt as @relation @arena — checked, not rewir_ |
| avra-reach-chain | perf/reach-chain | 9bd94de | 2026-09-30 | 5 | 312 | 3 | 0 | DB | LANDED / scratch | see appendix G3 — _tools(land): the timed warm edit is anchored on its line's text_ |
| avra-recordview | fix/record-view | bbe4daa | 2026-09-27 | 1 | 1219 | 1 | 0 | DB | LANDED / superseded | see appendix G1 — _fix(features/decls): mut_param_names never reads a held decl's parse_ |
| avra-rel | trace/dbfork | 8254155 | 2026-09-28 | 0 | 928 | 0 | 6 | DB | LANDED / superseded | see appendix G1 — _fix(decl_rows): export DeclRow, needed by the parity keeper outside fe_ |
| avra-revert-45 | revert-45 | b921a74 | 2026-09-30 | 2 | 217 | 2 | 6 | DB | ABANDON | reverts of kernel fix 0be202b still on main — _cells: a new cell owns what it holds_ |
| avra-revert-mark | lane/revert-verify-mark | 1885f06 | 2026-09-30 | 1 | 331 | 1 | 1 | DB | ABANDON | reverts of kernel fix 0be202b still on main — _Revert "fix(query): a cell under verification is marked before its dep_ |
| avra-s3-index | lane/m5-index | 319584f | 2026-09-30 | 24 | 378 | 8 | 0 | DB | LANDED / scratch | see appendix G3 — _Merge branch 'fix/warm-recheck' into lane/m5-index_ |
| avra-seed-162 | seed-162 | a4bcf9a | 2026-10-01 | 1 | 122 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _chore(seed): refresh the seed over #140's collect order forms (avra-8s_ |
| avra-seed-loops | seed-loops | ae0bef5 | 2026-10-01 | 1 | 192 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _chore(seed): re-emit the seed over #74 (break/continue, avra_bytes_wit_ |
| avra-seed-pid | seed-pid | cf66caa | 2026-09-30 | 1 | 195 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _chore(seed): re-emit the seed over #77 and #85 (avra_pid_alive, avra_o_ |
| avra-seed175 | seed175 | 2646d1e | 2026-10-01 | 1 | 98 | 0 | 0 | DB | LANDED / scratch | see appendix G3 — _chore(seed): refresh over E.all (avra-8sb5.57.148 prep)_ |
| avra-sign-order-base | HEAD | 9140cf2 | 2026-09-28 | 0 | 917 | 0 | 2 | DB | LANDED / scratch | see appendix G3 — _chore(seed): the compiler re-emitted for lane/n8-refs's landing_ |
| avra-skill-warm | HEAD | 430bd06 | 2026-09-29 | 2 | 511 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _Merge branch 'refs/heads/main' into docs/skill-cache-why_ |
| avra-sources-design | sources-design | 06594b4 | 2026-10-05 | 6 | 9 | 6 | 1 | CONSUMER | KEEP (doc) | BUILD_TIME_SOURCES.md: the pending consumer; its §1 two doors + D1–D13 answered by the design — _docs(sources): the owner's decisions on §15_ |
| avra-sp-build-fails | sp-build-fails | f966836 | 2026-09-30 | 1 | 217 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _tools(sprite-build): a tree whose compiler does not build runs no comm_ |
| avra-sp-dryrun | tools/sp-dryrun | cadf20e | 2026-09-30 | 1 | 430 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _docs(std-ui_html): note the realizer emits no inline style_ |
| avra-sp-exclude | sp-exclude | c5410fd | 2026-10-02 | 1 | 82 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(sp): exclude the persistent-disk-fault Sprite from the pool_ |
| avra-spread | lane/spread | a69120a | 2026-09-30 | 5 | 430 | 5 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _test(structs): escape the ownership case's holes so the program text c_ |
| avra-sprites-fix | run-attach | 42551d8 | 2026-10-05 | 4 | 0 | 4 | 2 | — | — | no DB work (appendix G4 §3) — _wip: fixtures end to end on Linux; paths sync under their own names_ |
| avra-spx-1 | spx-1 | 801b719 | 2026-10-05 | 2 | 5 | 1 | 5 | — | — | no DB work (appendix G4 §3) — _wip: runs belong to the Sprite; the client follows by offset_ |
| avra-sql | lane/sql-fast | d23eccb | 2026-09-26 | 0 | 1359 | 0 | 1 | CONSUMER | REWORK | SQL grammar as a compile-time `const`; 1359 behind — _Merge branch 'main' into lane/sql-fast_ |
| avra-srcstamps | fix/source-stamps | 8016ea7 | 2026-09-27 | 1 | 1287 | 1 | 0 | DB | LANDED / scratch | see appendix G2 — _fix(features/decls): mut_param_names never reads a held decl's parse_ |
| avra-stamp56-base | HEAD | 1c20088 | 2026-09-30 | 0 | 245 | 0 | 3 | DB | LANDED / scratch | see appendix G2 — _chore(land): the ratchet baseline moved for batch(lane/arm-error-sites_ |
| avra-stringlenses | stringlenses | 329ef09 | 2026-10-02 | 1 | 78 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _voice(loops,lists): a walk over a `string` names its view_ |
| avra-stringlenses-lens | stringlenses-lens | d9ec18d | 2026-10-04 | 1 | 21 | 1 | 1 | — | — | no DB work (appendix G4 §3) — _feat(str): a Bytes source walks octets_ |
| avra-test-onmain | test/401b298-on-main | 1f98788 | 2026-09-28 | 1 | 826 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _test: cherry-pick 401b298 onto main to check if the crash still reprod_ |
| avra-test-single | test-single | c5da450 | 2026-10-01 | 1 | 161 | 0 | 1 | — | — | no DB work (appendix G4 §3) — _fix(cli): avra test on one path proves what stands at or under it, and_ |
| avra-test-single-red | HEAD | 51d36f4 | 2026-10-01 | 0 | 161 | 0 | 1 | — | — | no DB work (appendix G4 §3) — _feat(compiler): Expr and Stmt as @relation @arena — checked, not rewir_ |
| avra-tls-readme | tls-readme | 6427192 | 2026-10-01 | 1 | 147 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(std-tls): a README — surface, verification default, C boundary (a_ |
| avra-tour-client | tour-client | 1754639 | 2026-10-01 | 1 | 134 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(http): the tour gains the client (avra-8sb5.1.31.10)_ |
| avra-tour-streaming | tour-streaming | 9eb53ea | 2026-10-01 | 1 | 137 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(http): the tour gains streaming, SSE and WebSocket (avra-8sb5.1.3_ |
| avra-train-diff-main | train-diff-main | 55b68b1 | 2026-09-30 | 1 | 218 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _ci: a train is judged against main, so every PR it lands was tested_ |
| avra-train-slots | tools/train-slots | b6ebd94 | 2026-09-30 | 5 | 293 | 5 | 0 | — | — | no DB work (appendix G4 §3) — _tools(land_train, sp): calls into land.sh inherit a scratch instead of_ |
| avra-trait-bounds | trait-bounds | 109a9e1 | 2026-09-30 | 3 | 201 | 3 | 0 | — | — | no DB work (appendix G4 §3) — _test(impls): the arity voice counts "1 argument"_ |
| avra-typed-decl-grain | typed-decl-grain | f9b251f | 2026-10-01 | 1 | 166 | 0 | 1 | DB | LANDED / superseded | see appendix G1 — _compiler: a use reads the declaration it names, never its file's parse_ |
| avra-ui-a11y | ui-a11y | 51faf8a | 2026-10-01 | 1 | 147 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(ui): the accessible-name contract as data_ |
| avra-ui-assets-design | ui-assets-design | 0b5bd64 | 2026-10-05 | 2 | 10 | 2 | 0 | CONSUMER | SUPERSEDED | by sources doc §9.4; one ask: `collect … reached` — _docs(ui): assets — one word over a file or a folder, homes, fetched ar_ |
| avra-ui-bisect | bis-172-181 | 81bd928 | 2026-10-01 | 2 | 98 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _feat(lang): find_map on List and payload-binding `is` under an if (avr_ |
| avra-ui-charter | ui-charter-flex | 38189dc | 2026-10-01 | 1 | 133 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(ui): the charter's flexibility — a fixed substrate and an open su_ |
| avra-ui-core | lane/ui-core | 3cbebda | 2026-10-01 | 2 | 151 | 2 | 0 | — | — | no DB work (appendix G4 §3) — _docs(ui): Phase 0b redone with the owner — LIBRARIES.md (eleven rules)_ |
| avra-ui-declared | ui-declared | a65ae37 | 2026-10-02 | 1 | 80 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(avrac): a Declared-answering @derive emits the impls it made_ |
| avra-ui-dev | ui-dev | 895027e | 2026-10-05 | 14 | 9 | 13 | 0 | — | — | no DB work (appendix G4 §3) — _docs(std-net): `bound`'s contract stands on `bound`_ |
| avra-ui-diff-fuzz | ui-host-owned | c5f7a48 | 2026-10-05 | 2 | 0 | 2 | 1 | — | — | no DB work (appendix G4 §3) — _wip(ui): the oracle, the hosts and the named cases under the naming la_ |
| avra-ui-docs-web | ui-docs-web | 63319e6 | 2026-10-01 | 1 | 150 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(ui): track WEB_UI.md, the web constitution the plan references_ |
| avra-ui-dom | ui-dom | d71eacb | 2026-10-02 | 31 | 80 | 31 | 0 | — | — | no DB work (appendix G4 §3) — _fix(ui): Live.diff remembers the BARE tree, so no_change can fire_ |
| avra-ui-emit | ui-emit | 4db0545 | 2026-10-04 | 1 | 21 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(ui): a Hoist or Direct site must be closed, not merely read no sta_ |
| avra-ui-findis | ui-findis | d227899 | 2026-10-02 | 1 | 96 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(lang): find_map on List and payload-binding `is` under an if (avr_ |
| avra-ui-h | lane/ui-h | 792a260 | 2026-09-29 | 0 | 471 | 0 | 23 | — | — | no DB work (appendix G4 §3) — _chore(land): the ratchet baseline moved for lane/ui's landing_ |
| avra-ui-i | lane/ui-i | 5765678 | 2026-09-29 | 1 | 471 | 1 | 18 | — | — | no DB work (appendix G4 §3) — _runtime: compiles for wasm32-wasip1 — make wasm32_ |
| avra-ui-l2b | ui-l2b | 7b89116 | 2026-10-02 | 36 | 82 | 36 | 0 | — | — | no DB work (appendix G4 §3) — _fix(ui): the L2 fields map to their attributes_ |
| avra-ui-lib | ui-lib | 66c41a6 | 2026-10-01 | 1 | 148 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(ui): Style and Theme as data — the look, and what its tokens mean_ |
| avra-ui-own-state | ui-own-state | 6c9add3 | 2026-10-05 | 17 | 1 | 14 | 0 | — | — | no DB work (appendix G4 §3) — _Merge remote-tracking branch 'origin/main' into ui-own-state_ |
| avra-ui-primargs | ui-primargs | d6b3222 | 2026-10-01 | 1 | 110 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(annotations): a bare variant argument sees its seat's type, and i_ |
| avra-ui-render2 | ui-render | ab255ca | 2026-10-02 | 1 | 93 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(ui): the data-driven render — a component projects to a neutral N_ |
| avra-ui-runstream | ui-runstream | 685e539 | 2026-10-01 | 1 | 110 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(runtime): a printed line is on its stream when the call returns_ |
| avra-ui-splice | ui-splice | 3330e52 | 2026-10-01 | 1 | 110 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(meta): list_of builds a list literal of any length from List<Code_ |
| avra-ui-state | ui-state | deec663 | 2026-10-03 | 1 | 62 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _feat(state): a capture reads and writes the place, transparently_ |
| avra-ui-testdiff | ui-testdiff | 75d5a99 | 2026-10-01 | 5 | 110 | 5 | 0 | — | — | no DB work (appendix G4 §3) — _refactor(specs): the case-failure rule lives with its feature_ |
| avra-ui-tree | ui-l2 | a6a410a | 2026-10-02 | 7 | 105 | 6 | 3 | — | — | no DB work (appendix G4 §3) — _feat(ui): @attribute field override, and the View derive refuses what _ |
| avra-url-readme | url-readme | e9240ce | 2026-10-01 | 1 | 149 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _docs(std-url): a README — surface, laws, per-component encoding (avra-_ |
| avra-validate | lane/validate | 4adfe22 | 2026-09-30 | 8 | 291 | 7 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _Merge branch 'main' into lane/validate_ |
| avra-validate-c | lane/validate-compiler | 8145d15 | 2026-09-30 | 7 | 293 | 7 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _feat(validate): @derive(Decode) — §11's Signup as written, cross-field_ |
| avra-validate-perf | lane/validate-perf | e0c255b | 2026-09-30 | 8 | 192 | 8 | 0 | CONSUMER | LANDED / no DB | see appendix G4 — _fix(validate): the direct reader on main's @std/json — RFC 8259 number_ |
| avra-verdict124 | perf/verdict124 | 602c153 | 2026-09-30 | 6 | 430 | 6 | 0 | DB | LANDED / scratch | see appendix G3 — _perf: reuse only a kept structural refusal — a value's transitive read_ |
| avra-verify101 | HEAD | 5a885d8 | 2026-09-30 | 1 | 430 | 1 | 0 | DB | LANDED / scratch | see appendix G3 — _wip: measurement script_ |
| avra-wants-modules | wants-modules | 726cf54 | 2026-10-05 | 2 | 0 | 2 | 1 | DB-adjacent | ACTIVE | adds `facts.hosted` to verify_held.av; hold wire unchecked — _wip: host fns (bodied extern fn) — unverified_ |
| avra-wants-values | wants-values | 3da7a56 | 2026-10-05 | 14 | 0 | 12 | 3 | — | — | no DB work (appendix G4 §3) — _wip(tests): red-team survivors pinned; two idiom sites paid_ |
| avra-warm-diag | fix/warm-recheck | 3fcf3a3 | 2026-09-30 | 5 | 312 | 3 | 1 | DB | LANDED / scratch | see appendix G2 — _Merge branch 'refs/heads/main' into fix/warm-recheck_ |
| avra-warm-memory | warm-memory | 9437242 | 2026-10-05 | 5 | 0 | 5 | 0 | DB | KEEP (active) | one derivation alive at a time; `Workspace.discarded()`; tools/memsites.py — L8 of the design — _wip: the registry's declare hook lets its table go_ |
| avra-warm-settle | warm-settle | dd33cdc | 2026-10-02 | 1 | 89 | 0 | 3 | DB | LANDED / scratch | see appendix G2 — _fix(types): a read while a type's own declaration is in flight is prov_ |
| avra-warm101-11 | warm101-11 | 0e67451 | 2026-10-02 | 0 | 98 | 0 | 5 | DB | REWORK | hand `ReachWitness` (uncommitted): worked 70/70, won ~3% — whole-record digests cost what the walk saved — _feat(db): the family collect orders by rank, append-stable (avra-8sb5._ |
| avra-warm4-base | warm4-base | 0e67451 | 2026-10-02 | 0 | 98 | 0 | 2 | DB | LANDED / scratch | see appendix G2 — _feat(db): the family collect orders by rank, append-stable (avra-8sb5._ |
| avra-wasm-flat | wasm-flat | 2e448a9 | 2026-10-03 | 1 | 43 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _perf(wasm32): flat child rows in a settled static_ |
| avra-wasm-pkgc | wasm-pkgc | e21dcf1 | 2026-10-03 | 1 | 64 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _wasm32: a package's C can build for the target_ |
| avra-wasm-size | wasm-guard | 80696f1 | 2026-10-03 | 1 | 42 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _wasm32: the size guard caps the FLOOR tightly and reports the BOARD_ |
| avra-wasm32 | wasm32 | 8e77884 | 2026-10-02 | 11 | 77 | 11 | 0 | — | — | no DB work (appendix G4 §3) — _runtime: restore the live-run flush on both print paths_ |
| avra-watch-dash | watch-dash | 7f8b210 | 2026-10-01 | 1 | 125 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _fix(watch): the guarded command gets its own process group with no tty_ |
| avra-witness-delete | perf/witness-delete | 14e1a47 | 2026-09-29 | 2 | 511 | 1 | 0 | DB | LANDED / scratch | see appendix G2 — _Merge branch 'refs/heads/main' into perf/witness-delete_ |
| avra-won-orm | perf/won-orm | 0e6b5b4 | 2026-09-29 | 1 | 539 | 1 | 0 | DB | ABANDON | flips `witness_enabled`, deleted on main (#104) — _measure: witness ON_ |
| avra-work-land-existing | work-land-existing | 38f7a02 | 2026-09-30 | 1 | 223 | 0 | 0 | — | — | no DB work (appendix G4 §3) — _tools(work): land finds a branch's open PR by its head, so a re-land r_ |
| avra-work-watch | work-watch | 6dca48c | 2026-09-30 | 2 | 203 | 2 | 0 | — | — | no DB work (appendix G4 §3) — _ci: GitHub runs the queue keeper after every train and every 5 minutes_ |
| avra-wrap-method | lane/wrap-method2 | 794c763 | 2026-09-30 | 1 | 430 | 1 | 0 | — | — | no DB work (appendix G4 §3) — _feat(annotations): WRAP over a method splices its wrapper as a method _ |
| agent-a4866be31854b20a3 | worktree-agent-a4866be31854b20a3 | 9f30b28 | 2026-09-22 | 0 | 2121 | 0 | 2 | DB | ABANDON | 2121 behind; old std-relation snapshot — _chore(seed): the compiler re-emitted for the named-seat fix_ |

**Per-worktree detail** (what each attempted, how far, what is unlanded):
[G1 decl/rows](2026_10_06_DB_INVENTORY/G1_decl_rows.md) ·
[G2 holds/cache](2026_10_06_DB_INVENTORY/G2_holds_cache.md) ·
[G3 families/index](2026_10_06_DB_INVENTORY/G3_families_index.md) ·
[G4 consumers + the 137-worktree remainder](2026_10_06_DB_INVENTORY/G4_consumers_rest.md).

Four `/private/tmp` worktrees (`uib`, `uib2`, `uib_base`, `uibm`) vanished during the sweep. READ(agent G4)

---

## 2. Timeline — every attempt to standardize the layer

| date | what was proposed | where | fate |
|---|---|---|---|
| 06-14 | Old tree: AST as source of truth, node facts in side tables, ≤200 ms warm **with a daemon** | `forge-crafting-intepreters/docs/2026_06_14_AST_SOURCE_OF_TRUTH_EPIC.md` READ(agent D) | carried as CLAUDE.md rules; daemon refused by `COMPILER.md` |
| 09-21 | `docs/2026_09_21_COMPILER.md`: the memo kernel, the hold, "a store is ONE compiler's", "a hold bug costs time, never a wrong answer" | main | on main; law 6 contradicted by the stale-embed bug (fixed by hand #282) |
| 09-24 | `docs/2026_09_24_DB_REDESIGN.md`: one process-singleton Db; "`Memo`/`Store`/`Family` don't survive"; "`Analysis` never a Row" | main | **reversed** — `db.av:8-17` records the singleton premise as checked and FALSE; `Analysis` is a `DbRow` variant (READ `db.av:288`) |
| 09-26 | **Townhall**: `@relation`/`@query`, four marks, 10 lead decisions, witness = kernel deps as `(stable name, hash)`, one append-only pack per package, nine slices M0–M6 | untracked, stale checkout only | ~60 % built (D's estimate); the durability half reversed |
| 09-27 | `collect enum` pulled forward (owner go) | ticket .57.12 | landed; `Family` is one (#192); `DbKind` half open (.57.12.5) |
| 09-27 | Stamps deleted: "`text_digest` always hashes, no measurable cost" | `92b24db` | on main. MEASURED warm check ~36–42 ms at 37 and 730 files (READ(agent G2)) |
| 09-28 | M3 built: flattened witness + pack + `avra cache` over the pack, behind `witness_enabled=false` | .57.6, .57.48–.58 | **measured, then deleted** (next two rows) |
| 09-28 | §6.5a: flattened witness = 74,600 edges/file median, 33.3 M edges, 279 MB, +62…216 %; direct deps = ≥51.6 M on the cli | townhall §6.5a READ | the binding measurement |
| 09-30 → 10-01 | **The pivot**: "the durable witness IS the hold path's `KeyParts`; kernel-grain deps stay in-process; the flattened recording and its switch are DELETED" | .57.4.6, .57.55, PR #104 `85f1046` | on main |
| 09-30 | std-relation armed from the Kernel; late writes **refused**, not re-analysed ("NO pass-2 re-analysis") | #72 `51bfc7d` | on main. First attempt (`avra-arm-rows`, settle-loop) abandoned: gen-2 trapped |
| 09-30 | `@query` answers persist per file under `KeyParts` (`Db.answers`); only no-row-writing first runs | .57.4.6 | built, **unarmed**; recorded deadline: an imported query whose body changes reads back stale |
| 09-30 | Kept settlements (const verdicts + `#lines`) | .57.141 "DEFERRED (lead)" — built anyway, #119 | on main: a third witness format |
| 10-01 | Families: "the 28 families do NOT fit `@query fn`" → internal `@family(rank, key, answer)` marks | .57.148 | on main (32 markers); the `@query` fork never closed |
| 10-01 | `view_print` hand key for kept views — three attempts, all unsound or slower | `avra-perf-hold-keys`, .57.101 | **abandoned by decision**, on the false premise that M3 witnesses exist |
| 10-01 | S3 per-declaration durable reuse: approved 13:00, closed unbuilt 13:51 ("≤~5–15 % of warm-check wall") | .57.18 | not built |
| 10-02 | "The M3 witness layer does not exist … NEEDED: the M3 layer itself" | .57.101.11 / .57.101.12 | **open, unowned, contradicts §6.5a unless scoped** |
| 10-02 | Doc facts as Db-owned relations — two attempts reverted, five walls | .57.9.7 | parked |
| 10-05 | BUILD_TIME_SOURCES: "two half-doors and five persistence paths"; proposes door 1 (inputs) + door 2 (kept runs); two reviews rule "**not one mechanism**" | `avra-sources-design`; `sources-review/REVIEW*.md` | pending this design |
| 10-05 | Stale embedded file in a kept binary fixed **by hand**: `embeds` remembered row + `e` line | #282 `04a6a89` | on main — a 4th bespoke path, self-described as provisional (READ(agent C2)) |
| 10-05 | Layout line `l` for kept settlements | `avra-keepers-green@01c219c` | unlanded, active |
| 10-05 | Warm-rebuild memory: "one derivation alive at a time" | `avra-warm-memory` (7 wip commits) | unlanded, active |

Full decision register with BUILT / PARTLY / NOT BUILT / REVERSED per item and file:line:
[D §3](2026_10_06_DB_INVENTORY/D_docs_timeline.md). Ticket-by-ticket timeline with exact
quotes: [T §2](2026_10_06_DB_INVENTORY/T_tickets.md).

### 2.1 Townhall decisions — status in code today

| decision | status | evidence |
|---|---|---|
| §4.1 one Db per command | BUILT | `514c5f9`; MEASURED cold check-cli 590.5B → 338.7B instr (townhall §4.1) |
| §4.2 dense addressing only | BUILT | READ `query/kernel.av:20` `Key = { family: int, arg: int }` |
| §4.3 witness covers everything read + compiler digest | PARTLY | compiler digest = store root (READ(agent C1)); "everything read": ~160 of ~177 world reads are in no key or dep (C1) |
| §4.4 Db is an identity behind a Cell | BUILT | READ `kernel.av:119-141` `@identity` |
| §4.5 witness = list of (stable name, value hash) | **REVERSED at kernel grain**; survives only as `KeyParts` | §6.5a |
| §4.6 a durable row reads only through `ask` | PARTLY | audit exists (READ `kernel.av:94-236`); `Db.answers` unarmed |
| §4.7 row and witness settle in one step | **NOT BUILT** | READ `kept_settle.av:152-153`: two `store.keep` calls; READ `store/store.av:137-149`: data file then `.deps` file |
| §4.8 the compiler's DB is not `@std/db` | holds | — |
| §4.9 accessors are static fns on the relation | BUILT | PROBED `Route.insert/by_verb/all` |
| §4.10 typed ids encode as keys; `@local`; `<T>Stored` | PARTLY | `decl_wire` (.57.107); several family fingerprints still fold dense ids (READ(agent C1 #11)) |
| §6.2 `Workspace` shrinks to `{ db, host, lang }` | **NOT BUILT** | 36 fields (READ(agent D)) |
| §6.5 durable by default, witness = kernel deps | **REVERSED** | §6.5a; #104 |
| §6.5a durable witness = `KeyParts` | BUILT | READ `record.av:1097-1113` |
| §6.6 one packed append-only file per package | built, **deleted** (#109) | READ(agent G2) |
| N1 comprehension picks a declared index | BUILT for comprehension heads only | `features/lists/plan.av`; avra-8sb5.65.3.2.1 open |
| N2 multi-valued `@index` | BUILT | `@index marks` on `Decl` (READ(agent G3)) |
| N3 `collect enum` | `Family` BUILT; `DbKind` hand-written | READ `db.av:155-216`, `families.av:149` |
| N4 WRAP directives | BUILT | READ `std-relation/src/query.av:56` `wraps: true` |
| N5 `@query(fixpoint)` | NOT BUILT (kernel fixpoint exists: `query/fixpoint.av`) | READ(agent D) |
| N6 `avra explain why` | built as `avra cache`, pack-backed modes deleted; one in-process walk | `compiler/cache_walk.av`; no `explain` command (READ `cli/src/commands/`) |
| N7 `@input` | BUILT in std-relation; **not the compiler's input path** | READ `compiler/inputs.av:8-15` (its own RECORDED TRIGGER says so) |
| N8 references and findings as relations | BUILT (`Ref`, `Finding`), rebuilt whole per ask | READ(agent C2 §7) |

---

## 3. What is on main today (the picture)

```
                         THE WORLD
   files · listings · exists · env · tools · self-digest · target · clock
        │  ~177 read sites (READ(agent C1))
        │  2 recorded as kernel inputs (Source, Manifest) · 1 after the fact (embed)
        │  ~14 folded into a hand key · ~160 in no key and no dep
        ▼
 ┌─ Host (54 call sites) ──┐   ┌─ @std.io called directly ─┐   ┌─ extern rows (env, spawn) ─┐
 └────────────┬────────────┘   └──────────────┬────────────┘   └───────────────┬────────────┘
              ▼                               ▼                                ▼
 ┌──────────────────────────── one compile (a Workspace, 36 fields) ───────────────────────────┐
 │  Kernel (query/kernel.av)        cells[family][arg] · deps: List<Key> · rev · verifiers     │
 │    32 families (@family marks → `collect enum Family`)                                      │
 │      16 keep a typed value in Db.families (Relation<DbRow>)                                 │
 │      16 use raw ask/begin/settle with the value in a hand table                             │
 │  std-relation Db (armed by kernel_hooks)   Decl File Module DocFact DeclAt Ref Expr Stmt    │
 │                                            AssignRoot ErrorSite Raised Finding (12)         │
 │  ~95 hand caches outside the kernel (Keys 10, Records 12, Hold 10, Workspace 17, Decls ~27) │
 └───────────────┬─────────────────────────────────────────────────────────────────────────────┘
                 ▼  18 Store write sites, 27 persisted row kinds
 ┌─ .avra-cache/<compiler digest>/ {rows unit obj warn bin}/<shard>/<4×u64> (+ empty .deps) ───┐
 │  validated on recall:  Decl (listing + file digests) · Bin (links_unchanged)                │
 │                        kept-settle lines u/c/m/f/b/e · module record lines                  │
 │  "hold unconditionally" (content-keyed): 17 kinds                                           │
 │  name-keyed, mutable, NOT validated: parts, seen, homes, closure, embeds                    │
 └─────────────────────────────────────────────────────────────────────────────────────────────┘
```

MEASURED here (read-only `du`/`wc` over `avra-ui-own-state/.avra-cache/<one store>`, 2026-10-05):
`rows` 571 files, 28.9 MB, median **1 byte**, max 4.57 MB; **every `.deps` file is 0 bytes**
(571 of 571); `unit` 2,499 files; `obj` 460; `warn` 459; one store ≈ 96 MB; two stores present.

### 3.1 Six addressing schemes (READ(agent C2 §0), spot-checked)

| # | scheme | key | survives the process | validated by |
|---|---|---|---|---|
| 1 | kernel cell | `(family: int, arg: int)` | no | red-green on deps |
| 2 | `Relation<DbRow>` | same | no | — |
| 3 | durable `Db` row | `(DbKind, name: string)` | yes | `still_valid`: `Decl` only; 7 kinds `-> true` (READ `db.av:658-668`) |
| 4 | content store | `Stored` family + digest | yes | the key is the content |
| 5 | `@std/relation` row | id / `@key` / `@index` bucket | no (answers via `Durable`, unarmed) | kernel cell per bucket |
| 6 | string-keyed maps on the Workspace | a digest / path / call site | no | nothing — `db.av:253-260` calls it "a THIRD addressing scheme" |

### 3.2 Three hand-written witness formats (the owner's rule, three times)

| | saved answer | witness (what it read) | "stands" rule | where |
|---|---|---|---|---|
| A | a file's check / object (the hold) | `KeyParts { module, path, text, runs, seen: [module, bytes_key, files] }` | recompute parts, compare digest of parts (it is a KEY, not a list checked entry by entry) | READ `record.av:1097-1113` |
| B | `avra docs <name>` | `DocFacts { root, listing_digest, files: [path, digest] }` | every digest equal | READ `db.av:658-661` |
| C | a const's settled verdict | lines `u` unit · `c` const · `m` module file list · `f` file · `b` budgets · `e` embed (· `l` layout, unlanded) | per-letter fn: `kept_unit_stands`, `kept_const_stands`, list equality, `kept_file_stands`, budget equality, `embed_said` | READ `kept_settle.av:144-180` |
| D | a kept binary | `program_key` = digest(compiler, entry, every source in a **remembered** closure, embeds, package objects) + `links_unchanged` | recompute key | READ `build.av:589-609` |

D's `closure`/`embeds` rows are "the inputs read last time", remembered because the key is
asked before anything is parsed — i.e. a witness list stored under a different name.

### 3.3 Counts (READ(agent C1); full tables with file:line in the appendix)

| quantity | count |
|---|---|
| outside-read sites, std-avrac + cli, non-test | ~177 |
| … recorded as a kernel input | 2 (+1 after the fact) |
| … folded into a durable key, no dep | ~14 |
| … neither | ~160 (every `exists`/`is_dir`, 8 of 10 listings, 18 of 19 env reads, every tool lookup) |
| Store write call sites | 18 |
| persisted row kinds | 27 (8 `Rows`, 12 `Unit`, 4 `Warn`, 2 `Obj`, 1 `Bin`) |
| … re-digested at recall | 4 |
| … content-addressed, hold unconditionally | 17 |
| … name-keyed, mutable, unvalidated | 5 |
| kernel families | 32 (READ `families.av`: ranks 0–31) |
| kernel cells or deps persisted | 0 |
| `DbKind` variants | 24 (READ `db.av:160-185`) |
| hand-rolled caches outside the kernel | ~95 |
| `@relation` / `@query` / `@input` in std-avrac | 12 / 2 / 2 |
| bespoke whole-program walks a relation+index would replace | 28 (C2 list (b)) |
| CLI commands | 22; **no `explain`**, `hover`, `definition` or LSP |

### 3.4 Consumers (READ(agent C2) — one line each; full sections in the appendix)

| consumer | reads facts through | cached how | gap |
|---|---|---|---|
| `collect` | `Decl`'s `word`/`marks` index buckets (`Decls.gathered`) | member list re-gathered at 4 sites; a held collect is a stub | bucket read "unrecorded" |
| idiom `rule` engine | one tree walk per file (`rule_candidates`) | findings → throwaway Db → tab text under the `Warn` key | no kernel family; `fingerprint_siblings` walks the file per candidate |
| `avra docs` | 2 `@query` over `Decl` (full scan though `by_name` exists) | the only witnessed durable row | dump path uncached |
| `check` / `build` | families | hold (`KeyParts`) + `program_key` | two remembered rows; linker/`CC`/env in no key |
| `avra test` | build's key + `proved` row | text of every file of every seen module | discovery by `exists` on marker files, unrecorded |
| `avra fmt` | parse | `Canon` row by content | the key derivation parses, despite "a hit answers without a parse" |
| references | `Ref` rebuilt whole under one unit cell | none | held files' rows lose position |
| derives / const / embed | `Lifted` family keyed by a string of dense ids | **never persisted**; consts via format C | every derive re-runs per process; embed bespoke in 3 places |
| manifests | kernel input by admission ordinal | — | 2 readers bypass; `[link]` `${ENV}` unrecorded |
| ORM `@model` (std-db) | runtime SQLite, no typed queries | — | not a compiler consumer today |
| UI `View` derive | `type_exported` ×6 | — | `wire.gen.js` committed, outside every key |
| a plugin via `@std/meta` | exactly 3 ask verbs: `embed`, `type_named`, `type_exported` | — | cannot ask "all `@model` types" or "all impls of T" |

### 3.5 Live defects, placed in the picture

| defect | where it sits | status |
|---|---|---|
| stale embedded file in a kept binary (.57.164) | no input door → fixed by hand: `embeds` row + `e` line + `admit_embeds` walk (#282) | fixed on main; **yes, one more bespoke path** (three sites) |
| warm rebuild > 5 GB, top site `Kernel.newly_read` (.57.163, avra-8sb5.76, .78) | (1) several derivations alive at once (warm-memory's finding); (2) each dep is a boxed `Key`: MEASURED "363 MB in 5.1 M boxes" = 71 B/box (avra-8sb5.76) | open; `avra-warm-memory` active on (1) |
| cache-attacks 2/186 "a compile-time value did not cross as `Line`" (.57.165) | a kept value depending on a program-wide layout no digest names — `avra-keepers-green@01c219c` adds an `l` line | open; keepers not in CI (READ `checks.yml:110`) |
| imported `@query` body change read back stale (.57.4.6) | key = the CALLING file's `KeyParts` | latent while `Db.answers` is unarmed |
| linker / `CC` / `WASM_OPT` / `${ENV}` in no key (avra-8sb5.68, .69) | no input door for tools and env | open |
| suite key omits package C objects (three tickets) | hand key | open |
| weak hashes: linear fold (avra-8sb5.79), 30-bit `fp_mix` (avra-8sb5.46) | early-cutoff and store keys | open |
| 4 host reads inside `Parsed`/`Plain` frames with no dep | `voices.av:680,701,713`, `workspace.av:1315` (READ(agent C1)) | unfiled |

---

## 4. Already done but not on main

| # | what | tree @ sha | state | value |
|---|---|---|---|---|
| 1 | Kept settlement stands only under the layout it was laid out in (`l` line; `kept_layout`, `Decls.crossing_layout`) | `avra-keepers-green` @ `01c219c` | committed, active lane | fixes .57.165's cache-attack; evidence for a non-input witness atom |
| 2 | One derivation alive at a time; `Workspace.discarded()`; `tools/memsites.py` | `avra-warm-memory` @ `abf52f0` (7 wip) | active lane | the memory half of "partly-held never worse than cold" |
| 3 | Doc-fact kernel-witness test (`features/tests/doc_fact_test.av` +71, `doc_fact_kernel_witness/`) | `avra-docfact-side`, uncommitted on `3f073ba` | no `.expected`; never confirmed green | a per-slot dependency witness test |
| 4 | Typed `by it.mark.args[N]` projection (`fp2`/`fidx` grammar, `ProjField.index`, `mark_arg_reg`) | `avra-q148-prototype`, uncommitted (+422/−85) | no evidence it compiled | typed catalog of queries from their marks |
| 5 | `DbKind` as a `collect enum` via dual `@family @db_kind` marks | `avra-n3-apply` @ `af411a2` | orders by name → moves every ordinal | the model, not the code |
| 6 | 17 witness red-team cases | `avra-m3-redteam` @ `a644ba4`, `.rt/attack5.log` | 11/17 on deleted code | acceptance suite |
| 7 | Hand `ReachWitness { seen: [module, digest], deps: [dep, files] }` | `avra-warm101-11`, uncommitted on `0e67451` | worked 70/70; ~3 % win (3.90 s → 3.78 s) | a negative result: whole-record digests cost what the walk saved |
| 8 | Entry-file confound fix to four hold assertions | `perf/mh-held` @ `4fef2a3` (`avra-mh-held`, stuck mid-rebase) | committed, unlanded | test honesty: `--time`'s "read:" always names the entry file |
| 9 | BUILD_TIME_SOURCES design, v2.1 | `avra-sources-design`, 6 commits | doc only | the consumer brief |
| 10 | Debug aids: `Kernel.open_top()` qtrace line, `AVRA_TRAP_BT`, `tools/.held.sh` three-package held-chain repro, `corpus/edges.awk` per-family edge counter | `avra-bisE`, `avra-bisD`, `avra-decl-rows-red` (uncommitted) | scratch | measuring rigs |

Everything else in the 277 is landed (often under a squash with a different sha), superseded,
or scratch. Per-worktree proof: appendices G1–G4.

---

## 5. Decided but never built

| decided | where | why it matters now |
|---|---|---|
| A row and its witness settle in ONE step | townhall §4.7 | two `keep` calls today; two writers can interleave |
| `Workspace` = `{ db, host, lang }` | §6.2 | 36 fields, ~95 hand caches |
| One witness shape | §4.5 | three formats + `program_key` |
| Every world read is an input with a recorded dep | §4.3, N7 | 2 of ~177 |
| `DbKind` derived from declarations | N3 / .57.12.5 | blocked on the enum-variant splice |
| Families as `@query` declarations | §6.2 | .57.148 chose internal `@family`; fork open |
| Persisted rows keyed by stable name, never ordinal | .57.12 | `collect enum … dense` + `tools/families.py` append-only keeper |
| `<T>Stored` decoded row type without `@local` columns | §4.10 | partial |
| Per-declaration durable reuse (S3) | .57.18 | closed unbuilt on a 5–15 % estimate |
| `avra explain` | CLAUDE.md, N6 | the command is `avra cache`; `explain` does not exist |
| Doc facts as Db-owned relations | .57.9.7 | five walls recorded |
| Pay .57.4.6 before arming `Db.answers` | .57.4.6 | still unpaid |
| cache-attacks / codecs / fmt-lossless in CI | .57.165 | local `make gate` only |
| The owner's ~300 ms warm-edit bar | HANDOFF 10-01 | last MEASURED warm edit 4.27 s (#124); a resident compiler is refused |

---

## 6. Contradictions

### Doc vs doc
| # | A | B |
|---|---|---|
| 1 | townhall §4.5/§6.5: witness = the kernel's deps | townhall §6.5a (same file): "kernel grain cannot persist" — §6.5 never amended |
| 2 | §6.5a | ticket .57.101.12: "write a cell's deps as (stable name, hash) into a durable row" |
| 3 | DB_REDESIGN: Db is a process singleton | `db.av:8-17`: claim checked and found false |
| 4 | COMPILER.md law 6: "a hold bug costs time, never a wrong answer" | stale-embed probe (REVIEW2 §C.10, PROBED there): a wrong binary |
| 5 | COMPILER.md §8 refuses a resident compiler | HANDOFF's ~300 ms warm bar; old tree met ≤200 ms only with a daemon |
| 6 | .57.12: "variants keyed by stable name, never a dense ordinal" | `families.av:149` `… by it.mark.args[0] dense` |
| 7 | townhall status line: "no open blockers" | everything in §5 above |
| 8 | SOURCES v1: "`read` passed `[]` by every caller but tests" | REVIEW2 §C.3: five non-test callers pass edges (and nobody reads them back) |

### Doc vs code
| # | doc says | code says |
|---|---|---|
| 1 | `db.av:36-38`: "`record.av` and `voices.av` declare their OWN `DbRow` types" | they do not (READ(agent D)) |
| 2 | `db.av:220-234`: "the last three (`Decl`, `Sig`, `Warn`) are Db's own durable rows" | eight durable kinds (READ `db.av:292-323`) |
| 3 | `memo.av:28-30`: "22 in-process query families" | 32 |
| 4 | `ADDING_A_PROJECTION.md`: persistence → .57.6 | .57.6's product is deleted |
| 5 | `fmt.av`: a hit "answers without a parse" | `canon_key` calls `ws.parsed(f)` first (READ(agent C1 #8); not run) |
| 6 | `workspace.av:814-819`: the revision never moves in a compile | `Named` input set by hand mid-compile via `input_unread`/`set_input` (`features/decls.av:1021-1057`, READ(agent C1 #10)) |
| 7 | CLAUDE.md: "`explain @name` and `explain process` rooted at `.`…" | no `explain` command |
| 8 | ticket: `family_word` deleted | `compiler/workspace.av:523` (READ(agent T)) |
| 9 | tickets .57.164, avra-8sb5.67 open | fixes on main (#282, #272) |
| 10 | two types named `Db` | `compiler.db.Db` (kernel + durable rows) and `@std.relation.db.Db` (relation store) |

More: [T §5](2026_10_06_DB_INVENTORY/T_tickets.md) (16 ticket-vs-ticket contradictions, 26 spot
checks), [D §4](2026_10_06_DB_INVENTORY/D_docs_timeline.md).

---

## 7. Measurements carried into the design

| what | value | source | kind |
|---|---|---|---|
| kernel-grain direct deps, `check packages/cli` | ≥2.54 M keys, ≥51.6 M deps | townhall §6.5a | MEASURED |
| flattened witness, cold `check packages/std-avrac` | 74,600 edges/file median; 33.3 M edges; pack 279 MB; +62…216 % | townhall §6.5a (`ef0d957`) | MEASURED |
| `KeyParts` hold on a warm cli edit | 397/399 files held "at near-zero cost" | townhall §6.5a | MEASURED |
| `check packages/cli` | cold 41.2 s · no-op 0.22 s · body edit 5.1 s (held 404/408) | ticket .57.6.5 | MEASURED |
| warm no-edit check | 0.36B instructions, peak 7 MB | townhall §6.6 (`1c0cad6`) | MEASURED |
| always-hash sources | warm check ~36–42 ms at 37 and 730 files | `92b24db` (READ(agent G2)) | MEASURED |
| warm one-line edit | 20.9 s → 2.3 s (#48); 8.06 → 5.93 s (#119); 6.30 → 4.27 s (#124) | commit bodies (G2) | MEASURED |
| warm-edit phases, 2026-10-01 | wall 4.43 s; ast, sublang, load, admit each ~1.0–1.4 s | G2 table | MEASURED |
| kernel read | ~125 instr unrecorded · ~315 stamped hit · ~1,900 new dep | ticket .57.30 | MEASURED |
| relation recorded read | ~938 instr vs ~90 raw | ticket .57.8.1 | MEASURED |
| partly-held rebuild peak | 3,442 / 3,371 MB vs cold 2,168 / 2,177 MB | ticket .57.163 | MEASURED |
| `Kernel.newly_read` | 363 MB in 5.1 M boxes, all live → **71 B per recorded dep** | avra-8sb5.76 (division mine) | MEASURED / derived |
| per-edge cost from layouts | ~89 B (80 B boxed `Key` + 9 B slot) + 8 B stamp per distinct key | C1 from `runtime/avra_box.h` | ESTIMATED |
| unpersisted lifts | 0.04 s → 0.25 s per comment edit for 1,000 generated types; 75–140 KB compiler memory per generated declaration | SOURCES doc C.26 | PROBED there |
| a comment edit with a provider | 0.05 s → 1.02 s | REVIEW.md §D | PROBED there |
| one `.avra-cache` store | ~96 MB; 571 row files median 1 byte; all `.deps` empty | this inventory, §3 | MEASURED |
| `.avra-cache` across worktrees | ~15.9 GB over ~140 worktrees | ticket .57.18.4 | MEASURED |
| hand `ReachWitness` | 3.90 s → 3.78 s; load 2,231 → 1,667 ms | .57.101.11 | MEASURED |
| `view_print` made sound | load 1,019 → 3,824 ms | `avra-perf-hold-keys` | MEASURED |

**Not measured anywhere** (owed by the design's first PRs): bytes per relation row; size of a
persisted `KeyParts`; lines per kept settlement; digest throughput in MB/s (`digest_bytes`
is an Avra loop — REVIEW2 D6).

All 34 + ~250 measurements with command, commit and date:
[G2 "all measurements"](2026_10_06_DB_INVENTORY/G2_holds_cache.md),
[T appendix B](2026_10_06_DB_INVENTORY/T_tickets.md),
[D §7](2026_10_06_DB_INVENTORY/D_docs_timeline.md).

---

## Appendices (sub-agent reports, verbatim — READ(agent), spot-checked where §0–§7 say READ)

| file | what |
|---|---|
| [`G1_decl_rows.md`](2026_10_06_DB_INVENTORY/G1_decl_rows.md) | 29 worktrees: arming, decl rows, relations |
| [`G2_holds_cache.md`](2026_10_06_DB_INVENTORY/G2_holds_cache.md) | 42 worktrees: holds, kept, warm, cache; 34 measurements |
| [`G3_families_index.md`](2026_10_06_DB_INVENTORY/G3_families_index.md) | 35 worktrees: families, N3, M3, M5, indexes, collect |
| [`G4_consumers_rest.md`](2026_10_06_DB_INVENTORY/G4_consumers_rest.md) | 33 consumer worktrees + the 137-worktree remainder scan; the sources doc digest |
| [`T_tickets.md`](2026_10_06_DB_INVENTORY/T_tickets.md) | 263 tickets under avra-8sb5.57 + 186 related: table, timeline, measurements, defects |
| [`D_docs_timeline.md`](2026_10_06_DB_INVENTORY/D_docs_timeline.md) | every design doc, the decision register, contradictions |
| [`C1_infra_counts.md`](2026_10_06_DB_INVENTORY/C1_infra_counts.md) | every world read, persist site, family, DbKind, hand cache — file:line |
| [`C2_consumers.md`](2026_10_06_DB_INVENTORY/C2_consumers.md) | 12 consumers, the matrix, 28 bespoke walks |
