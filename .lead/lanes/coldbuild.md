# coldbuild — compiler self-build slowdown (speed.compiler 176s -> 313s)

Lane: re-measure a cold `make avra` on current `origin/main` on a Sprite with
`.avra-cache` moved aside. Settle whether the CI `speed.compiler` 313s (run
38583324673, head 09c9c7d3) is a real regression or the runner/stale-cache.

## 23:2xZ — start
- Main checkout at b0d98c49 (behind origin/main 439c9579). Read-only.
- Context found: `.lead/CI_RULE.md` (move cache aside before a rebuild after a
  merge), `.lead/GOAL_2026_10_10.md` (old cold-build: 517s/gen at -O1 on Oct 10;
  now ~176s), `.lead/lanes/slow-gen1.md` (stale cross-tree cache -> 4-5 turns,
  771-991s, 4.36GB; cold 132-176s).
- CI: `.github/workflows/checks.yml` "compiler" step writes `speed compiler N` as
  `gen; gen` (two `make -s avra`) starting from a fetched `latest` compiler, over
  the restored `.avra-cache`.
- BLOCKER: every pool Sprite (52/53) is bound to a lane; the two unbound
  (`web-terminal`, `avra-bench`) are excluded. `work new` cannot allocate.

## 23:3xZ — Sprite acquired; measurement started
- Pool was fully bound (52/53); created a task-scoped Sprite `avra-coldbuild`
  (`sprite create`), then `sh tools/work new coldbuild` bound it.
- Worktree `../avra-coldbuild`, branch `coldbuild`, HEAD 439c9579 (origin/main).
- CI history read (via `gh`), whole prepare "speed compiler" step = TWO `make avra`:
  `09c9c7d3` (Oct 14) 313s vs main baseline 176s [warned]; `38744609337` d815252a
  (Oct 15) 293s vs 156s [warned]; adjacent pushes 38690375545 171s, 38716068577
  156s, 38723210296 159s; 38818012798/38821914099 exact release hit -> skipped.
  So the two slow runs are outliers among ~156-171s neighbours.
- Running: cold two-gen build with `.avra-cache` aside (tools/_cb_measure.sh).

## 23:5xZ — cold measurement: NO regression
- Sprite `avra-coldbuild`, branch `coldbuild`, HEAD 439c9579 (origin/main).
- Cold two-gen `make -s avra` (store moved aside / absent), peak RSS by RUSAGE_CHILDREN:
  - current main 439c9579: gen1 109s, gen2 113s (sum 222s), peak 2.32 / 2.36 GB.
  - baseline commit bf314960 (the 176s CI baseline): gen1 132s, gen2 133s (sum 265s), peak 2.07 GB.
  - current main OVER bf314960's store (303M): gen1 112s, gen2 117s (sum 229s) — no turn storm.
- So current main's cold self-build is FASTER than the baseline commit's; not slower.
- #716 (02cd6ad6) is an ancestor of BOTH bf314960 and 09c9c7d3, so it cannot
  explain 176->313. #788 (d815252a) and #759 are NOT ancestors of 09c9c7d3.
- Seed refresh not in play: 09c9c7d3's log says `starting compiler: latest`.
- Measuring pre/post #716 next for completeness.

## 00:1xZ — DECISIVE: the 313s was not the code
Sprite `avra-coldbuild` (8 vCPU AMD EPYC). Cold two-gen `make -s avra`, peak RSS:
| commit | note | gen1 | gen2 | sum | peak |
|---|---|---|---|---|---|
| 439c9579 | current origin/main | 109s | 113s | 222s | 2.32/2.36 GB |
| bf314960 | the 176s CI baseline commit | 132s | 133s | 265s | 2.07 GB |
| d4ee91f8 | pre-#716 | 124s | 127s | 251s | 2.03 GB |
| 02cd6ad6 | #716 itself | 150s | 143s | 293s | 2.06 GB |
| 09c9c7d3 | 313s run's head, OVER bf314960's 303M store | 127s | 130s | 257s | 2.06 GB |
- A FULLY COLD build is 222s; the CI's warm-store run took 313s — a warm run must be
  <= cold, so 313s cannot be the code. Over-cache builds show no turn storm (store
  303M -> 599M).
- CI series (same step, same ~14-17G store): 38690375545 171s, 38716068577 156s,
  38723210296 159s, 38744609337 293s, 38583324673 313s. Fast neighbours bracket it.
- #716 is ancestor of BOTH bf314960 and 09c9c7d3 (#766 is the only commit between);
  #759 and #788 are NOT ancestors of 09c9c7d3. Seed refresh not used (started `latest`).
- `explain --time` skipped: direct `./avra build` failed at link (runtime libs not
  warmed); not needed for the verdict.
- Sprite `avra-coldbuild` + worktree `../avra-coldbuild` (branch `coldbuild`) left
  standing; free with `work done` when done. No code changed.
