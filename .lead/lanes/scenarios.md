# Scenarios

## Scenario table (origin/main 708e712b, gen-2 compiler, warm store, Sprite)

Measured by `tools/db_measure/scenarios.py` on the `scenarios` branch. Each scenario is ONE edit to one file applied to the ORIGINAL text. Each round makes two fresh edits: one timed with no trace (wall), one under `AVRA_QTRACE=1` (counts). The base is warmed (untimed) before each scenario, and the file is restored after it. Three rounds per scenario.

Columns: `wall` is the timed run (ms, rounds 1/2/3). `held` is held/total from the compiler's own line. `parsed` counts `Q parse` lines in the traced run. `att` counts derivation attempts. `comp` counts all memo computes (every family; the lowering family alone is not separated). `lower` / `load` / `keep` / `ast` are the `--time` phase values in ms.

### check packages/cli

| # | scenario | wall ms (r1/r2/r3) | held | parsed | att | comp | dominant phase (r1/r2/r3) |
|---|---|---|---|---|---|---|---|
| 1 | body literal, `cli/src/commands/shared.av` | 7951 / 7016 / 7115 | 502/504 | 7 | 1 | 713 | load 3089 / 2814 / 2949 (lower 2856 / 2409 / 2360) |
| 2 | body literal, leaf `cli/src/commands/attack.av` (named only by `mod.av`) | 16005 / 16064 / 15212 | 497/504 | 26 | 2 | 2317 | lower 2531 / 2291 / 2208 (keep 1163 / 1203 / 1067) |
| 3 | body literal, std-avrac core `core/digest.av` (`clear_sign`) | 15782 / 7158 / 6966 | 496–501/504 | 8 | 1 | 774 | lower 2265 / 2331 / 2229 (load 2829 / 2760 in r2–r3) |
| 4 | add a private fn to `shared.av` | 72114 / 73664 / 74103 | 415/504 | 309 | 4 | 12330 | lower 16843 / 16253 / 16867 (keep 5684 / 5974 / 5586) |
| 5 | add an exported fn to `shared.av` | 88030 / 76065 / 72257 | 415/504 | 309 | 4 | 12330 | lower 17577 / 17445 / 16913 (keep ~5500) |
| 6 | signature: rename param of `slotted_path` (3 files use it) | 86087 / 34164 / 35679 | 405–427/504 | 135 | 2 | 5763 | lower 17086 / 12925 / 13249 (keep ~5000–5900) |
| 7 | add a defaulted field to `Asked` (`explain.av`) | 54954 / 45503 / 44505 | 403–410/504 | 209 | 3 | 11836 | lower 13678 / 13017 / 12982 (keep ~5100–5400) |
| 8 | comment only, `shared.av` | 19503 / 6498 / 6412 | 477/502/502 | 14 / 7 / 7 | 2 / 1 / 1 | 1569 / 713 / 713 | load 2852 (r2–r3); lower 3564 / 2320 / 2291 |
| 9 | rename a local (`ws`) in `built_binary`, `shared.av` | 10444 / 10517 / 10911 | 494/504 | 22 | 1 | 1768 | lower 4429 / 4351 / 4580 (ast ~950) |

### build packages/cli (owner's bar: ≤ 500 ms after one body edit)

| # | scenario | wall ms (r1/r2/r3) | parsed | att | comp |
|---|---|---|---|---|---|
| B1 | body literal, `shared.av` | 69011 / 50600 / 53376 | 78 | 2 | 7271 |
| B4 | add a private fn to `shared.av` | 100535 / 91763 / 92437 | 240 | 4 | 9112 |
| B8 | comment only, `shared.av` | 21686 / 10704 / 11161 | 17 | 1 | 866 |

The build's `--time` line carries no phases (`lower+emit · built`, `cache hit`), so there is no phase split for build.

### test packages/std-text, and fmt

| # | scenario | wall ms (r1/r2/r3) | held | parsed | att | comp | dominant |
|---|---|---|---|---|---|---|---|
| T1 | test: body literal in `std-text/src/text.av` | 2284 / 2115 / 2071 | 0/14 | 22 | 4 | 1079 | analyze 135 / 123 / 118 (ast ~100, lower ~25) |
| F1 | fmt --check of all 71 cli files, after the `shared.av` body literal | 2430 / 2407 / 2674 | n/a | 104 | 0 | 336 | no phases printed |

### Reading the table

- A body edit in `shared.av` (1) costs about 7 s. Nearly all of it is `load` and `lower`, with `keep` under 0.4 s.
- A new fn (4, 5) or a signature change (6) or a new record field (7) costs 45–90 s. Each re-parses 135–309 files and runs 2–4 attempts over 5000–12000 memo computes. That is the 10x the owner asked about.
- A comment (8) and a local rename (9) are cheap in round 2–3. Round 1 of 8 is slow (19.5 s) because it ran straight after scenario 7's restore; treat round 1 as a warm-base artefact.
- `--time` phases are not a partition of the wall. In heavy rows they cover only about half of the wall (scenario 4: 36.5 s of 72 s); in cheap rows they sum slightly above it (scenario 9: 11.5 s against 10.4 s). Read the phase columns as indicative, not exact.
- Build's one-edit cost (B1, 50–69 s) is 100–140 times the owner's 500 ms bar, and the build has no phase line, so the split is unknown.
- Caveats: the base is restored and re-warmed between scenarios, not rebuilt from scratch; the first measured round of a scenario is sometimes slower; and `comp` counts all families, not only lowering.
