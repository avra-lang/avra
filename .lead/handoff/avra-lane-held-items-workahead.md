# avra-lane-held-items (2): work-ahead, the per-worker cap, and the four copies

No code change to land: the numbers say the cap is not the lever, and neither is the duplication. All runs are the real cold `AVRA_PROGRAM=1 build packages/cli`, -O1, tree d12f29ce plus held-items, package and tree stores cleared. The knob is `AVRA_WORK_AHEAD_CORES`. The measurement build added two env hooks (cap and per-miss trace); they are not committed.

## Workers and cap (2 rounds each)

| Workers @ cap | Wall (s) | User (s) | Peak machine-wide (GB) |
|---|---|---|---|
| off | 187 / 184 | 323 / 315 | 5.96 / 5.71 |
| 2 @ 320 MB | 154 / 159 | 334 / 346 | 4.80 / 4.82 |
| 4 @ 320 MB | 137 / 133 | 379 / 365 | 4.73 / 4.69 |
| 8 @ 320 MB | 140 / 139 | 398 / 392 | 4.92 / 4.88 |
| 4 @ 80 MB | 231 / 229 | 479 / 461 | 4.56 / 4.59 |
| 4 @ 160 MB | 133 / 136 | 370 / 375 | 4.70 / 4.67 |
| 4 @ 640 MB | 130 / 145 | 363 / 404 | 4.77 / 4.75 |

- **What work-ahead buys:** 4 workers save about 50 s of wall (−28 %). 2 workers save about 30 s. 8 workers are no better than 4 on this 4-core machine.
- **A cap sized by worker count** (320/4 = 80 MB) costs about +95 s of wall for −0.15 GB of peak. 160 MB is within noise of 320 MB, for −0.03 GB. Keep 320 MB per process.

## The four copies (per-miss trace with pid and read-back time, 4 workers)
- Only 2 of the 6 fork rounds read items back. In each, 4 workers each read about 14 k (first) and about 8 k (second) distinct items.
- Duplication factor: 2.1× and 1.6× within a round. 14 k items read in the first round are read again in the second, by workers that have since exited. 10.5 k items are read by all four workers.
- **Price:** read-back costs about 100 µs per item. All processes together spend about 10.8 s of CPU reading back 91 k + 3.5 k misses. Reading each of the 25 865 distinct items once would cost about 2.6 s. The whole duplication is worth at most about 8 s of CPU, roughly 2 s of wall: under 2 % of the build. Sharing a read-back world across workers is not worth a restructure today.

## What sets the peak (sampled every 0.25 s; idle machine 0.7 GB)
- **4 workers:**
  - Parse and generate forks: up to 2.8 GB.
  - Bodies-lowered workers (25–50 s): up to 4.3 GB.
  - Parent alone (55–75 s): grows to 2.6 GB.
  - The phase from 80 to 125 s, 7 processes: **5.7 GB used**. This is the peak. It sits just before the link, so I read it as emit; I did not label phases by name.
- **Work-ahead off:** the parent alone for 0–120 s, growing to 2.4 GB, then the same late phase peaks at **6.7 GB** with 7 processes.
- The peak and about 45 s of wall are in that late phase, which belongs to emit-speed / memory. Work-ahead lowers the peak because the parent it forks from is smaller.

## Next
(2) When hot-writes lands, re-run the read trace: the fixed ~10 KB per item should shrink the 1.11 GB working set.
