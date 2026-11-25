# avra-lane-select-lowering — hand-over
Branch `avra-lane-select-lowering-6`, on next-base cd4738e6 (merged at d96ca688). Bundle: /work/avra-lane-select-lowering-final.bundle = program cf1b3e2c..-6.
DONE, handed back: -4 (landed in 15c4576b), -5 (sleep→parked-read tests, landed in cd4738e6), -6 part 1 (/work/avra-lane-select-lowering-6.bundle: keepers-static all 20 green).
ON -6 SINCE part 1, now PROVEN (2026-11-16): trap-marks (tools/traps.py), codecs (instances_word), read-lists ceiling, fmt of 9 files. Receipts: `make avra` (cli self-build) exit 0; `make -s -o avra` codecs-static trap-marks fmt-lossless rt-ns vocab layers cited externs ci-invariants vendored-fixture: all exit 0.
LEFT (not this item): KEEPERS from tool-witnesses on were never run (warm-edit pool-check runtime-tests runtime-mutations speed-ratchet h2spec ui-* wasm-*). Resume: `make -s -o avra keepers-b` / `keepers-a`.
COMPILER-KEEPER FAILURES TO ROUTE (not mine):
- voices: `manifest.link_name` spoken, no registry row/witness (833fb925 emit-speed-3c).
- defects: warm `check` traps "index 0 out of bounds" — Workspace.rechecked -> moved_bodies -> syntax_in -> syntax_made -> stmt_fingerprint: a kept decl whose stmt the re-parse dropped (verdict.av / workspace.av:2233). Repro: `make defects` (needs machine-store history).
- inputs: 31 new world reads outside the door (tapes.av program-layer env/tool/spawn reads; `@std.program` in neither WORLD nor INERT).
- whole-reads: 7 new all_files/all_decls sites (tapes.av x2, derive.av x2, signed.av, verdict.av, workspace_analysis.av).
- read-lists: 8 families over 3000 (refs_index 20287, file_refs_made 5385, Lifted 4352, file_visible_made 4165, module_names_made 4004, file_said 3360, signed 3011, Resolved 3001).
- clock-holds: runtime/avra_pool.c flock x3 + nanosleep unheld (memory-pool lane).
- census-gate: census compiler `check --counts packages/cli` killed at 4009 MB (cap 4000).
- read-cost: segfault in box_alloc only under load (MAP_NORESERVE slab range); passed alone — rerun alone.
LOCAL-ONLY: avra-tools keepers need AVRA_TOOLS_COMPILER=build/avra here (release API 403).
WARNING: a build/avra built by the 3d35d216-era ladder compiler from current source is miscompiled (`check` of `@derive` traps).
SELECT ROWS (differential-2.md) not started: flow.arm_binder, flow.no_fate, flow.spent_arm ACCEPTED; flow.arm UNBUILT.
Files others must not touch: none held.
