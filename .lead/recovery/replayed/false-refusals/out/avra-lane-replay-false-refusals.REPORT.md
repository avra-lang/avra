# Replay: false-refusals (transcript cse_01QBqJujuUjfCYmCnDDGZzWu)

Bundle: /work/out/avra-lane-replay-false-refusals.bundle (verified; prerequisites are the same 30
boundary commits as all-lanes.bundle, every one an ancestor of e2bce925).

| original | rebuilt | branch | on | subject | verified against | notes |
|---|---|---|---|---|---|---|
| 11812d5c | a4031db9 | avra-lane-replay-false-refusals-crossing | d00e7c64 | WIP (parked, for 58's head) meta: a field crosses its written type whole, and a variant its marks as annotations | `git diff HEAD~1 --stat` = 1 file, +57/−1 (transcript: same); fmt --check clean; witnesses print as the transcript's did | — |
| bbe1efeb | cfb7de89 | avra-lane-replay-false-refusals-nullable-probe | a9f3d50f (stepf3) | WIP (parked) nullable: a nullable of a named type compares beside its own type | nullable_test.av 92/94, the same two failures at :152 and :473 (transcript: identical); fmt --check clean | transcript printed no stat; mine is 2 files +24/−1 |

The message texts are the lane's own, byte for byte. Only author dates differ, so the shas differ.
Nothing was uncommitted at the end, so there is no -wip branch. The transcript ends at 04:16, just
after 11812d5c was parked.

## Sweep kit (rebuilt into /work/sweep-share, copy in /work/out/avra-lane-replay-false-refusals-sweep-share)
- list.txt, fixtures-A.txt, fixtures-B.txt: regenerated from `git ls-tree d00e7c64` with the lane's own
  commands; 128848 / 54065 / 74783 bytes, the sizes the transcript's `ls -la` printed.
- one.sh (1336 B), rank.py (1674 B), struck.txt (544 B), README.md (1945 B): exact first-version sizes.
  Then the lane's revisions: one.sh 03:25 (a library gets the layer's check; delete only the fixture's own
  cache), README 03:25 (sqlite, REVISED note) and 03:35 (compress/tls).
- reexport_repro/: the 3-file repro from its printed files.
- results-A.RECONSTRUCTED.md: everything the transcript printed of half A (counts, category heads,
  triage tables, posted list, the 162 rerun). The 1,191-row TSV itself is NOT recoverable (UNCERTAIN →
  absent); the full rerun the lead asked for replaces it.

## Receipts
- Compiler chain from /opt/avra-tc (e2bce925): a73903d2 → 6abff86d → d00e7c64 gen-1 → gen-2, each
  `make avra` exit 0 (b56→b57 needed no manifest edit here). The d00e7c64 gen-2 is 108,126,120 B, the
  size of the lane's own avra-sweep build/avra. Saved: /work/avra-sweep/build/avra.{b56,b57,d00-g1,d00}.
- crossing: `make` 0, self-build (touch + make) 0, `avra check packages/std-avrac` 0.
  Witnesses (AVRA_PROGRAM=1 NET=0 `avra run`): doc_and_annotations `5 1 a`, field_spelled `ok`,
  flat_nested_crossing `ok`. On clean d00e7c64: annotation.said / annotation.unsettled ×2 (red).
- nullable-probe: `make try` 0 (from the d00 gen-2). nullable_test.av 92/94 with the fix; 90/94
  without it (the two new cases red), so the witness is red before and green after.
- Not run: the cost slice and gate (brief), and the lane's 162-fixture regression rerun (that comes
  with the full sweep next).
