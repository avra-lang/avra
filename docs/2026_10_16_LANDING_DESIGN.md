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

Recommended (owner ruling 2026-10-16: no optimistic merge, no auto-revert,
because it reruns everything after the damage and leaves a reverted PR with
no owner): **batch before merge with parallel bisection**, below. Row D above
is kept as the rejected alternative.

### 3.1 Target process: the integrator

Main moves only to a tree that a full gate has already passed. Nothing is
ever reverted; a PR that fails is never merged and keeps its author.

1. **Candidates.** Open, non-draft PRs that merge cleanly into main, are green
   on their own gate (`test` on the head sha, as today), are not `hold`, and
   are not quarantined (4 below). Own gates stay: they give an author feedback
   in one gate time and keep a red batch rare. "Require up to date" is lifted;
   the integrator is the only thing that merges.
2. **Batch.** Up to N candidates (cap below), oldest first, merged one by one
   (`git merge --squash`, one commit per PR, author kept, subject `title (#n)`)
   onto `integrate/<k>` off main. A PR that conflicts with the batch so far is
   left out of this batch with a comment naming the PR it conflicts with: only
   that PR rebases, never everyone behind it. A **ladder PR** (by diff: the
   crossing rows, the lexer or grammar's own source, `bootstrap/**`; the list is
   one file, `tools/ladder_paths`) batches alone.
3. **One full gate** on the batch tip (the existing `checks` workflow, dispatched
   on the integration ref; it already runs the whole gate on a dispatch).
   Failed jobs are re-run once before the batch is judged red, so a flake does
   not split a batch.
4. **Green: land all, in one go.** Verify every head sha still equals the sha
   in the batch (else drop that PR and re-gate the rest), then merge each PR
   through the API **as a squash, in batch order**. Because the integration was
   built by the same squash order, the resulting tree equals the tested tree;
   the integrator asserts tree equality after the last merge and, if it differs,
   raises an alarm and runs the main verify (stage 1, kept as the backstop).
   Per-PR squash, not one batch commit: attribution, `git blame`, per-PR revert
   and the "(#n)" history all stay as they are. Main is never red.
5. **Red: split, run both halves at once, recurse.** Batch B of size > 1 splits
   into halves L, R (compiler-touching PRs spread across both: a docs-only PR
   cannot fail the gate, so it rides with whichever half is green). Both halves
   are gated concurrently on main (runners are idle).
   - one green, one red: land the green half at once; the red half recurses on
     the new main.
   - both green (the interaction is between halves): land L, re-gate R on
     main+L (one gate); a red R recurses on that base.
   - both red: recurse on both, concurrently; whichever half finishes green
     first lands, and the other half's gate, now on a stale base, is re-run.
   A batch of one that fails is the **culprit**: re-run once to exclude a flake.
   An interaction is blamed on the later PR (the one that fails on top of the
   earlier), and the comment names both.
6. **The culprit is told, not reverted.** The integrator comments on the PR with
   the failing job, its first `##[error]` line, the log link and (for an
   interaction) the PR it failed on top of, labels it `quarantined`, and leaves
   it out of every batch until its head sha changes (a push, or `retry` label).
   Its author is exactly who they were before.
7. **Seed as a release.** After main's verify is green, CI builds the seed from
   main's compiler and publishes it as the immutable release asset `seed-<key>`
   (the same mechanism as `avrac-<key>`). `bootstrap/seed.ref`, one line naming
   the key and its sha256, replaces `seed.ll` + `seed.sources` in the tree;
   `make bootstrap` and `seed-check` fetch the asset it names. Feature PRs never
   carry a seed; the integrator refreshes `seed.ref` itself, in its own batch,
   only when a ladder PR has landed. The cost is that a cold bootstrap needs
   the network or a cached asset (the sha256 makes a stale one unmistakable);
   the ref is committed, so every historical commit still names the seed that
   built it. Moving the seed out of the PR path removes the most frequent text
   conflict (5 of the last 27 commits touched it).

**Batch size cap.** Start at N = 6. Green batch: N = min(N + 2, 10); red batch:
N = max(N / 2, 2). Two reasons for a ceiling: the bisection depth is log2(N)
gate times, and the concurrent gates are about 2 x 16 jobs per level, so the
runner pool (to be confirmed: the org's concurrent-job limit) bounds how deep a
recursion can run at once.

**What happens to a PR that arrives mid-batch.** Main is frozen while a batch
is in flight (a merge under a running gate would make the landed tree differ
from the tested one), so a late PR joins the next batch. Its wait is the rest of
the current batch plus its own: about G to 2G (16-32 min) once green. A batch
of only light PRs (docs, no compiler) gates in 2 minutes, so a docs PR behind a
heavy batch waits for it but not for another heavy one. If that wait matters,
stage 2d speculates: the next batch is gated on main + the in-flight batch, and
lands the instant the first one does (a wasted gate when the first goes red).

**How this avoids the old queue's three failures.**
- One red killed the train: a red batch splits and only the culprit is dropped;
  the green halves land at the first level they are proved.
- HEADGREEN batching: no proxy. The gate runs on the exact tree that lands, so
  there is no "head green" to infer and no trains tested in parallel with other
  trains' contents.
- The rebase treadmill: a PR's evidence is its own gate, which a landing
  elsewhere does not void, so nothing is refreshed and no gate is re-run
  because someone else merged. A true line conflict names the one PR that must
  move.

**Numbers** (G = gate wall, 16 min after stage 1; K ready PRs, cap 8):

| Case | Wall until all green PRs are on main | Gates run beyond the PRs' own |
|---|---|---|
| all green | G (own gates, parallel) + G = ~32 min | 1 |
| one culprit among 8 | 4 land at ~2G after the batch starts, 2 at 3G, 1 at 4G; the culprit is named at 4G (~64 min) | 1 + 2 per level = 7 |
| today, serial | K x ~25 min plus refresh gates (3.7 runs per PR observed) | K refreshes |

Landings per hour: about 8 per 16-32 min = 15-30/hr green, against 1-2.5 now.

**Failure modes, and what holds them.**
- A partial landing (a PR gets a push between the gate and the merge): heads are
  checked immediately before the first merge, merges follow in seconds, and the
  tree-equality assertion plus the main verify catch what slips.
- A flake splits a batch: one re-run of the failed jobs first; the flake list
  from the first month sizes a budget.
- Integrator state: it is a pure decision function over (state, observations),
  fixture-tested as `pr_watcher` is; the state is a small JSON on a `batcher`
  branch, so a crash resumes.
- Someone merges by hand under a running batch: the post-merge tree assertion
  fails loudly, and the batch is re-gated on the new main.
- The ruleset: `test` stays required on the PR head; only "up to date" is lifted.


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

Stage 2 - the integrator (owner-ruled: batch before merge, parallel bisection).

| # | Change |
|---|---|
| 2a | `tools/batcher.py`: pure `advance(state, observations)`, fixture-tested; SHADOW MODE first (forms batches, dispatches gates on `integrate/<k>`, comments, lands nothing) beside the real landings for a week; compare its verdicts to what main did. |
| 2b | Lift "require up to date"; the integrator lands a green batch by squash through the API in batch order and asserts tree equality. The watcher stops arming normal PRs (it still arms docs-only light PRs between batches). |
| 2c | Seed as a release: `seed-<key>` published after a green verify, `bootstrap/seed.ref` in the tree, `make bootstrap`/`seed-check` fetch it; seed.ll leaves the PR path. Two landings (the ref first, the removal second), per the ladder rule. |
| 2d | Speculative next batch on main + the in-flight batch. |
| 2e | Adaptive cap, culprit comments with job and log line, `quarantined` label, `tools/ladder_paths`. |

Stage 3 - only if still slow after stages 1-2.

- Digest-keyed result cache per job (G), starting with keepers-static, codecs
  and the suites of packages the compiler diff provably does not reach.
- Selective testing driven by the compiler's own query DB for leaf-package PRs.
- Larger runners for std-avrac and cache-attacks (b).

## 5. Open questions for the lead

1. The org's concurrent-job limit (it bounds the recursion's width).
2. Cold bootstrap needing the network or a cached seed asset: acceptable?
3. May the integrator be the only merger (a repo ruleset bypass is not needed;
   it merges through the API as the existing bot identity)?

## 6. Not measured, to be read as questions

- Time a green PR sat BEHIND/BLOCKED: the API records neither state history;
  inferred from runs per PR (3.7), cancelled runs (15 of 60) and merge spacing.
  `tools/pr_watcher.py` logs would answer it exactly; stage 2 should record it.
- Flake rate of std-avrac and cache-attacks (b): needs reruns of one tree;
  sampled failures were attributable to real changes except possibly
  38879358151 (keepers-a (1)), not read.
