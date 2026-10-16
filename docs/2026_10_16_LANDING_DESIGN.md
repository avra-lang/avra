# Landing design — measured baseline, options, target

Scope: how a branch reaches `main` today, where the minutes go, and a
staged plan to land many streams at once. Numbers are from GitHub's API
over the 60 newest `checks` runs (2026-10-15..16) and per-job timings of
13 of them. Run ids are quoted; re-derive with `gh api
repos/avra-lang/avra/actions/runs/<id>/jobs`.

## 1. Baseline

### 1.1 One gate, wall time

Runner queue wait is ~0 on every job of every sampled run (max 0.1 min):
capacity is not the limit. The wall is a critical path:

    prepare (compiler + objects)  ->  slowest downstream job  ->  test

| Run | Kind | prepare | slowest job | wall |
|---|---|---|---|---|
| 38963299820 | compiler PR, cache-attacks on | 9.8 | cache-attacks (b) 13.7 | 24 |
| 38948023504 | compiler PR, runtime-keep on | 12.8 | std-avrac 16.6 | 31 |
| 38887718623 | compiler PR | 13.7 | std-avrac 18.1 | 32 |
| 38888850561 | compiler PR | 9.2 | std-avrac 14.1 | 24 |
| 38873807764 | compiler PR | 15.3 | std-avrac 10.9 | 27 |
| 38882677678 | compiler PR | 9.0 | std-avrac 10.1 | 20 |
| 38860887542 | docs only | 0.7 | keepers-static 0.9 | 2 |
| 38952434682 | dispatch on main | 21.0 | std-avrac 19.1 | 40 |

Compiler-touching PR: **20-32 min wall, ~110 runner-minutes**. Docs-only: 2 min.
Nearly every code PR touches `packages/**`, which is the compiler's source,
so nearly every code PR owes the full path.

### 1.2 Where prepare's 9-15 min goes

| Step | Time | Run |
|---|---|---|
| compiler (gen1 + gen2 from "newest published" after a release miss) | 315-450 s | 38963299820, 38887718623, 38948023504 |
| artifact upload of the store + build tar (see 1.3) | 257-266 s | 38887718623, 38948023504 |
| cache restore | 47-63 s | all |
| objects and libs | 37-97 s | all |
| container init | 19-26 s | all |

Every sampled compiler PR printed `compiler release ... missed ... starting
the build from the newest published compiler` (38887718623, 38963299820):
a PR's own tree never has a release (only main publishes), so the miss is
structural, not a bug. The cost is paid once per PR run: two generations.

### 1.3 Artifact hand-down was the biggest single waste, and moved

The `avra-build` artifact carried the whole `.avra-cache`: **2,428 MB** in
38948023504 (62 MB in 38963299820, after the timing-split PR #823 landed).
At 2.4 GB: upload 4.3 min in prepare, then **3-5 min of download on each of
~10 downstream jobs** (std-avrac in 38887718623: download 293 s, run 733 s;
in 38963299820: download 1 s, run 398 s). Per-run transfer was ~25 job-minutes
and ~5 min of wall. The latest runs already show it fixed; keep an eye on the
artifact size as a budget (a keeper: fail a PR whose `avra-build` > 150 MB).

### 1.4 Reruns, cancellations, failures (60 runs)

| Outcome | Count |
|---|---|
| PR runs success | 23 |
| PR runs cancelled (superseded by a push or a refresh) | 15 |
| PR runs failure | 10 |
| main push runs: failure / success / cancelled | 5 / 2 / 2 |
| manual dispatch on main (to cache the compiler) | 2 (40 min each) |

- ~13 branches produced 48 PR runs: **3.7 runs per landed PR**; each cancelled
  or refreshed run burns up to a full gate.
- Failed PR runs, by the job that failed (13 failed runs sampled): cache-attacks
  (b) 6 (3 of them on main's own push: 38891615850, 38884931683, 38876904580 — the
  #813 class, found only after merge), keepers-b 3, gate 4, prepare 2.
  Failures cluster in the **long, late jobs**: the red arrives at minute 12-15.
- Landing is serial. Merges per day (10-15 and 10-16): 11 and 11, of which ~7
  per day are code PRs; ~half the code landings are the lead's hand batches
  (#822 batch-1, #809 wave-2, #788 mega-integrate 4.4 h). Median PR open to merge
  0.9 h, tail 4-5 h (#788, #776, #780).
- Serial ceiling with "require up to date": one landing per gate = 2-3 per hour
  at 100% efficiency, and every landing makes each other green PR BEHIND, so its
  green gate is void and the watcher refreshes it (a second full gate, ~25 min).
  With K ready PRs the last one waits roughly K x 25 min plus failures.

### 1.5 Where the minutes actually go (one compiler PR, ~110 runner-min, ~25 wall)

| Bucket | Runner-min | Wall-min (critical path) |
|---|---|---|
| compiler generations (2) | 6-7.5 | 6-7.5 |
| artifact transfer (before #823) | ~25 | ~5 |
| keepers (a1, a2, b, static, codecs) | ~25 | 0 (parallel, <= 7) |
| seed-check | 2.5-7 | 0 (parallel) |
| suites (4 shards; std-avrac alone 7-18) | 25-45 | 7-18 |
| cache-attacks (a, b) | 17-20 | 13.7 when it runs |
| gate | 3-4 | 0 |
| runtime-keep | 13.4 | 0 (rare) |

The wall is prepare + the one indivisible job: **std-avrac (a single package
never split)** or **cache-attacks (b)**.

## 2. First principles

What does a landing need to prove? (1) the PR is correct, (2) the PR combined
with whatever else is on main is correct, (3) main stays a base that other
PRs can trust (a compiler that builds itself). The present design buys (2)
by serialising every landing behind a full gate, which is the most expensive
possible way: it spends the gate's whole latency per PR on the one property
that fails rarely. Measured here: the interaction failures that reached main
(#813 on cache-attacks b, 5 push failures) were caught by a gate scope hole,
not by the up-to-date ordering. The failures "up to date" prevents are text
conflicts (a refresh surfaces them anyway, GitHub does that without the
rule) and rare semantic collisions.

Questioned and the answer:

| Piece | Verdict |
|---|---|
| "Require up to date" | Drop for PRs whose last gate was green on a base within N commits and which merge cleanly; replace by post-merge verification of main (3 below). The per-landing cost it imposes is the whole serial ceiling. |
| Merge queue / trains | Already tried. Failure was batching without isolating (one red kills all) and a rebase treadmill. Speculation fixes the first only if the runner pool is big. Not needed if "up to date" goes. |
| Four suite shards | Keep, but add a fifth: split std-avrac (7-18 min, sole critical-path job) by directory. |
| seed-check every PR | It owes nothing when no seed input moved. Skip unless `bootstrap/**`, `runtime/**`, `backend/**`, or a symbol the seed names changed (`tools/compiler_paths.sh` already hashes inputs; add a seed-inputs digest). Parallel today, so saves cost, not wall. |
| Keepers split a/b/static | Fine; they run beside the suites, not on the critical path. |
| Two compiler generations in prepare | Gen2 is the fixed-point proof, not an input to most jobs. Hand gen1 to the suites and keepers; run gen2 + equality check beside them. Saves ~3-4 min of the critical path. |
| Publish model | Publishes at the start of main's push run, before main is proven (a red main publishes a bad compiler to every PR). Publish after main's verdict, as "latest-green". |
| The watcher | Stays: arm, refresh only when the PR does not merge cleanly or is > N behind, never as a ritual. |
| Sprites vs runners | Runners are the gate and have 0 queue wait; Sprites are the dev loop. No change. |
| GitHub Actions itself | Not the bottleneck: wait is ~0, the work is 6-18 min of real compute. A bigger/self-hosted runner buys little for 1-2 vCPU-bound compiles; revisit after the shape changes. |

## 3. Techniques for landing many streams, evaluated here

Assume G = 20-25 min gate (18 after stage 1), runner pool not binding.

| Technique | Wall to land K ready PRs | Landings/hr | Cost | How it fails on this repo |
|---|---|---|---|---|
| A. Today: serial, up to date, watcher refresh | K x G | 2-3 at best, 1-2 observed | ~K^2/2 gates when refreshes void greens | refresh treadmill; each failure restarts the line behind it |
| B. Merge train / queue, N PRs per train | G per train if green | high if green | 1 gate per train | one red kills N; bisect serially = N x G; seed/generation ladder PRs poison the train (the 8-PR train history) |
| C. Hand batches by the lead (today's workaround) | G + lead's hours | bursty | lead time | the toil the owner is paying; conflicts resolved by one head |
| D. **Optimistic merge + post-merge verify + parallel bisect + auto-revert** | each PR lands at its own G; K land in ~G | limited by pool, 10+ | 1 gate per PR (no refresh) + 1 main verify per coalesced batch | main red for a window; interactions revert one PR; generation ladder must be marked (below) |
| E. Speculative stacked queue (bors/Mergify/SubmitQueue) | G if every ahead-PR is green | high | K^2-ish runner-min, but ~K gates actually used | needs a bot; a red mid-stack invalidates its successors' runs; our gate is ~110 runner-min so K=8 speculation = ~900 runner-min per cycle |
| F. Affected-target selective testing | smaller G for narrow PRs | n/a | tooling | almost every PR touches the compiler's source, so the affected set is "everything"; the compiler's query DB could prune std-* suites for leaf-package-only edits (docs tier already does) — worth it for leaf PRs, not for the common case |
| G. Result cache by input digest | skips jobs whose (tree-inputs, compiler) digest passed before | helps reruns, reverts, refreshes | keys per job | misses when the compiler source changes, i.e. mostly; useful exactly for refresh/revert re-runs and for keepers that read no compiler (static) |
| H. One integration branch the lead feeds | one gate per integration | bursty | lead time | = C with a name |
| I. Bigger/self-hosted runners | -20% wall maybe | ~ | $ | compile is mostly single-thread + memory; unproven |

Recommended: **D, with G and the stage-1 shaving, and E's one good idea:
run bisect candidates in parallel.**

### 3.1 Target process (D)

1. A PR is gated on its own merge-ref (as now). When green and mergeable it is
   armed. **No "up to date" requirement**; GitHub still refuses a conflicting
   merge, and the watcher refreshes only a PR that conflicts or whose base is
   more than N (say 5) code merges stale (then the stale gate is not evidence).
2. Every merge to main triggers one **main verify** (a `push` run, already
   exists; make the merge fire it — #823 did the publish half). Coalesce: while
   a verify runs, later merges queue behind it; when it ends, one run starts on
   the newest main. The verify runs the full gate, including suites (today's
   push run skips suites and the seed check).
3. Green verify -> publish compiler as `latest-green`, tag the commit
   `main-green`. Red verify -> **parallel bisect**: start one gate per merge
   since `main-green` on that merge's own first-parent prefix, all at once
   (runners are idle, G wall, K gates of cost). The first red prefix names the
   culprit PR. The watcher opens its revert, labelled `revert`.
4. Revert fast path: a revert whose resulting tree equals the tree of a
   `main-green` commit merges with no gate (the proof already exists: tree
   digest, not hope). Otherwise it takes the normal gate with priority.
5. While main is red and a revert is in flight, the watcher stops arming
   (everything gated now would carry the breakage). Expected freeze:
   verify (G) + bisect (G) + revert (0 or G) = 40-75 min, versus today where a
   red main goes unnoticed for hours and its failure is read as a PR's.
6. **Ladder PRs are marked.** A PR that grows a compiler-read shape or needs a
   seed refresh carries a `ladder` label (the watcher can detect: diff touches
   `bootstrap/seed.*` or `features/crossing.av` rows). Ladder PRs merge only when
   nothing else is armed and main is green, i.e. they still serialise; ordinary
   PRs never do. This keeps the one rule that genuinely needs ordering without
   charging it to everyone.
7. Generated files out of the PR path: `bootstrap/seed.ll` and
   `seed.sources` conflict with every other PR that touches the compiler
   (5 of the last 27 commits). Refresh the seed only in its own bot PR on a
   schedule or on a ladder request; feature PRs that touch compiler source do
   not include it, and seed-check proves HEAD still builds from the committed
   seed, which stays valid until a ladder PR.

Expected result: wall to land a ready PR = its own G (18-24 min) regardless of
how many others are ready; K=8 ready PRs land in ~25 min instead of ~3 h;
runs per landed PR 3.7 -> ~1.3 (no refresh or cancel waste); main red windows
bounded and automatic.

What it costs: ~1 main verify per merge-batch (full gate, ~110 runner-min,
amortised over the batch) and, on red only, K prefix gates. At 11 landings/day
it is roughly half of today's runner-minutes (3.7 -> 1.3 gates per PR) even
with the verify.

How it fails here, honestly:
- Two individually green PRs whose combination is red: caught by the verify
  (minutes, not hours) and auto-reverted; today the same case is caught by the
  later PR's gate and read as that PR's defect. Net: the blame is correct.
- A compiler regression merged green (#813): the verify now runs cache-attacks
  and suites for every compiler change (lesson 2 made structural), and a red
  main publishes nothing.
- A flaky std-avrac failure on a verify triggers a bisect that finds nothing:
  the bisect re-runs each prefix once; all-green prefixes + red head = flake,
  unfreeze, open an issue, never revert. A flake budget needs the flake list;
  the first month of verify logs makes it.
- Revert conflicts when later PRs touched the same lines: the watcher stops and
  pages the lead (rare; the freeze then lasts until a human acts).

## 4. Staged plan

Stage 1 - cheap wins, each landable alone, none changes how PRs land.

| # | Change | Saves | Risk |
|---|---|---|---|
| 1a | Publish the compiler only after main's own verdict (needs the main jobs), as `latest-green` | removes the "bad compiler served to every PR" class | low; the release key is the digest, only the trigger moves |
| 1b | Split std-avrac's suite by directory into 2 shards (it is a single weight today, 7-18 min, the critical path in 6 of 8 sampled runs) | 3-8 wall-min | low; `tools/shards.py` packs by package, extend to a weighted row |
| 1c | Split cache-attacks (b) (13.7 min, critical path in 38963299820) into 2: link/turn-memory vs gathered/store/stamp/docs/code-hash | up to 6 wall-min on store PRs | low; make targets are already a list |
| 1d | Hand gen1 to downstream jobs, run gen2 + fixed-point check beside them | 3-4 wall-min on compiler PRs | medium: suites judge with gen1; the fixed-point job still fails the PR |
| 1e | Skip seed-check unless a seed input moved (runtime/, backend/, bootstrap/, Makefile) | 2.5-7 runner-min | low; keep it on main verify |
| 1f | Budget keeper: fail if `avra-build` > 150 MB | protects 1.3 | none |
| 1g | Make the main verify run suites + seed-check (today push skips them) | closes the post-merge hole | low; cost only |

Stage 1 target: compiler PR wall 24-32 -> ~14-18 min.

Stage 2 - landing model (needs the lead's ruling).

| # | Change |
|---|---|
| 2a | Drop "require up to date"; require `test` only. Keep auto-merge. |
| 2b | Watcher: refresh only conflicts or > N stale; stop arming while main is red; label `ladder` PRs and serialise only those. |
| 2c | Main verify coalescing + `main-green` tag + parallel prefix bisect + auto-revert PR (new `tools/` script, fixture-tested like pr_watcher). |
| 2d | Revert fast path by tree digest. |
| 2e | Seed out of feature PRs: scheduled/on-demand seed refresh bot. |

Stage 3 - only if still slow after stages 1-2.

- Digest-keyed result cache per job (G), starting with keepers-static, codecs
  and the suites of packages the compiler diff provably does not reach.
- Selective testing driven by the compiler's own query DB for leaf-package PRs.
- Larger runners for std-avrac and cache-attacks (b).

## 5. Open questions for the lead

1. Is "main red for 40-75 min, auto-reverted" acceptable in exchange for no
   serial ceiling? (This is the one real trade; everything else is cost.)
2. May the watcher open and merge a revert PR unattended, with the tree-digest
   fast path as its only gate exemption?
3. Ladder detection by diff (seed files, crossing rows) or by an explicit label
   the author sets?

## 6. Not measured, to be read as questions

- Time a green PR sat BEHIND/BLOCKED: the API records neither state history;
  inferred from runs per PR (3.7), cancelled runs (15 of 60) and merge spacing.
  `tools/pr_watcher.py` logs would answer it exactly; stage 2 should record it.
- Flake rate of std-avrac and cache-attacks (b): needs reruns of one tree;
  sampled failures were attributable to real changes except possibly
  38879358151 (keepers-a (1)), not read.
