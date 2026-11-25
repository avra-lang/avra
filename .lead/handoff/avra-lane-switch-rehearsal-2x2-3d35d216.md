# The emit-level 2×2, trunk 3d35d216 (after emit-speed's lld link + forked-share emit)

Builder for both columns: S5 = an old-path `make try` of 3d35d216. Package: cli, new path. `AVRA_PROGRAM_OPT` is the
word (default `-O0`). Linux sandbox, 4 cores / 15 GB; one sample per cell unless stated.

| | emit `-O0` (default) | `AVRA_PROGRAM_OPT=-O1` |
|---|---|---|
| cold build, wall / user / RSS | **70.2 s / 165.1 s / 4.90 GB** | **109.8 s / 308.7 s / 4.90 GB** |
| warm one-literal edit (cache.av), wall / user / RSS | **3.09 s / 2.87 s / 1.03 GB** | **9.39 s / 9.11 s / 1.06 GB** |
| product size | 92,832,696 B | 94,312,728 B |
| product doing cold `tapes cli --built`, wall / user | 82.2 / 82.5 s | 67.2 / 67.3 s |
| product doing `test packages/std-program`, wall / user | 135.2 / 144.8 s | 103.1 / 112.9 s |
| fixed point: P → P2 → P3, P2 == P3 | yes, sha fd2e858d…, 92,832,696 B | yes, sha 97410b6a…, 94,312,728 B |
| self-build by that product, cold, wall / user / RSS | 91.9 s / 217.4 s / 4.92 GB | 109.5 s / 307.2 s / 4.91 GB |

Reference, the old-path product S5 on the same jobs: `--built` 61.2 / 61.2 s; `std-program` 103.6 / 113.5 s;
103.2 MB class.
Every product: `--built` 44826 of 44826 made; std-program 414/415 (the one failure is the read-only-directory test,
which cannot hold as root).

## Emit and link phases

Emit now runs inside the forked work-ahead shares, and the parent's `AVRA_QUERY_TIMES` phases no longer see it:
`emit (outside)` reads 0.1 s cold at both levels, `link (outside)` 0.0 s, `the store saved` 4.0 / 4.2 s (was 17.3 /
15.9 s). The cold cost of `-O1` is therefore stated as the difference: **+39.6 s wall, +143.6 s user** over `-O0`.
Warm, the edited bucket's emit IS in the parent: `emit` 0.2 s at `-O0`, **6.0 s at `-O1`**.
Getting per-share emit seconds needs a timer from emit-speed in the shares.

## What changed since the first 2×2 (763009d7, before emit-speed)

| | -O0 then → now | -O1 then → now |
|---|---|---|
| cold wall | 78.7 → 70.2 s (−11 %) | 109.4 → 109.8 s (same) |
| cold user | 147.8 → 165.1 s (+12 %: more work in parallel) | 268.2 → 308.7 s (+15 %) |
| warm edit wall | 4.65 → 3.09 s (−34 %) | 7.76 → 9.39 s (**+21 %**) |
| `--built` user, product vs old-path product | +23 % → +35 % (82.5 vs 61.2) | +4.5 % → **+10 %** (67.3 vs 61.2) |
| `std-program` user, product vs old-path product | +22 % → +28 % (144.8 vs 113.5) | +0.4 % → −0.5 % (112.9 vs 113.5) |
| size | 92.2 → 92.8 MB | 93.8 → 94.3 MB |

Reading:
- emit-speed made `-O0` builds faster (cold wall −11 %, warm −34 %), and did nothing for a `-O1` cold build's wall.
- A `-O1` warm edit got SLOWER, 7.76 → 9.39 s: the edited bucket's `-O1` emit is 6.0 s now, against 3.6 s then. The
  bucket a literal edit re-emits may be bigger since emit-speed. Not proven; that is the first thing to look at if
  release-mode warm edits matter.
- The products at both levels are relatively slower than the old-path product than before on `--built` (+10 % at
  `-O1`). The old-path product got faster between the trunks (65.4 → 61.2 s), and the `-O1` new-path product did not
  (68.3 → 67.3 s).
- On `std-program`, `-O1` still equals the old path.

For the dev/release decision: dev (`-O0`) costs 70 s cold and 3.1 s per warm edit, and gives a compiler about 35 %
slower than the release one on the compiler's own heavy job. Release (`-O1`) costs 110 s cold and 9.4 s per warm edit,
and gives a compiler within 10 % of the old path's.

Unproven: single samples; the earlier run-to-run spread on this VM was 1.5–4.3 % on `--built`.
