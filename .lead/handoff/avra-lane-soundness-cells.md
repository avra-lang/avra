# avra-lane-soundness-cells — hand-over
Branch: avra-lane-soundness-cells-guard (base: trunk cf1b3e2c). Final bundle: /work/avra-lane-soundness-cells-final.bundle (cf1b3e2c..this branch).
DONE and handed back (bundles in /work):
- avra-lane-soundness-cells-coverage: forget-taker / emptied-cell / uncounted-yield checks (landed).
- avra-lane-soundness-cells-attacks: 18 lent_answer program tests (landed via next-base).
- avra-lane-soundness-cells-hot: unopened-write check ON + 9 cell_writes tests (in next-base 15c4576b).
- avra-lane-soundness-cells-program: L2 reads layouts; program-layer `handed` refuses a bucket the proof refused (in next-base cd4738e6).
- avra-lane-soundness-cells-guard: runtime refuses writes into the binary's own data, always on, +0.167% Ir; receipts tools/witness_frameless_writes.sh, runtime/tests/static_write_test.c, tools/program-runs/static_write. Gate green on cf1b3e2c.
PARKED (not for trunk): avra-lane-soundness-cells-lent (Rule T checker K1–K4, f93c064f); avra-lane-soundness-cells (unshared-slot relaxation, local idiom fix afeb489/fb469c4 unsent).
IN PROGRESS: nothing.
Findings not yet fixed: the evaluator writes into a program's literal when a row is driven past its open (prints 3/9 where native traps) — routed to the lead, unowned.
Files others must not touch: packages/std-avrac/src/compiler/soundness/*.
