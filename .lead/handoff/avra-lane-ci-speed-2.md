# avra-lane-ci-speed-2 — the CI series, for the owner's review

**What this series does.**
- A PR's compiler is taken by its source's key. When the compiler source changed, it is built once, from the base's own binary over the base's own store.
- main proves that its compiler rebuilds itself byte for byte (`cmp`) and saves that binary's store for every PR after it.
- Each slow leg is split by measured seconds: the gate, keepers-b and runtime-keep.
- The compiler-free keepers start with the run.
- The new path's program runs ride beside every suite.

Branch `avra-lane-ci-speed-2`, on `program` 3d35d216 (merged), one reviewable series of 18 commits:
`program..avra-lane-ci-speed-2`, bundle `/work/avra-lane-ci-speed-2.bundle`. It touches no `.av` files, so the idiom gate has nothing of this lane's to check (0 NEW).

| commit | what |
|---|---|
| ca8d5b2 | `compiler_paths.sh --key-at`; `tools/ci_gate.sh` (keys, compiler, objects, suites) and `tools/ci_dry_run.sh`; keepers-static needs no job |
| 03a7392 | the program store keyed by the compiler source that filled it; `self-build` job; the old-path warm step moves to keepers-a2 |
| a25ee97, 47e1e28 | a foreign store is set aside; seed-check kept per compiler key (`seedok-<key>`) |
| 0c871c2 | pipeline doc: the compiler by key and **the store law** |
| 866fd9f, dc26d22 | the gate sharded by package on measured `check` seconds; `AVRA_GATE_CHECK=old\|program\|both` |
| 3f99b1e | the store is dropped before every build by a binary that did not fill it (main's gen 2 and fill) |
| a2e9abb, 8614edb | `tapes --ran` per suite item over the item's own paths (advisory while std-http disagreed) |
| 00ed6f3 | pipeline doc: where the CI time goes, measured |
| 2aa69e3 | each witness is bounded (`tools/bounded.sh`, `WITNESS_S` 600 s): a hang refuses by name |
| 4b75363 | keepers-b in three thirds (Makefile `KEEPERS_B1/B2/B3`, workflow matrix; gdb only where defects runs, browser setup only where the browser runs) |
| 8c2785d | runtime-keep in four parts; the mutation bound stays at 60 s, measured |
| 58422e1 | the program layer's edit witness out of tool-witnesses: `make edit-witness` (KEEPERS_EDIT), `WITNESS_PART=k/n`, its own job in five parts |
| 2d08679 | the edit witness puts every file back when ended by a signal (a bound or a cancel left its edit in the tree) |
| 27a21ff | the edit witness kept per compiler key and witness (`editok-…`), as seed-check is |
| ab890f9 | the suites' program-layer half is a verdict (std-http agrees since a0ef1a00: 55 made, 0 failing) |

## The law it rests on (docs/2026_10_11_THE_PIPELINE.md, "The compiler in CI")

A program store answers only the binary that filled it.

| builder | over | wall | peak |
|---|---|---|---|
| old-path-built | nothing | 93.8 s | 4.5 GB |
| old-path-built | the new-built compiler's store | 110.4 s | 11.0 GB |
| new-path-built | nothing | 122.7 s | 4.5 GB |
| new-path-built | the old-built compiler's store | 142.6 s | 10.7 GB |
| either | its own store, one body edit | 10–11 s | 1.4 GB |

## Proven here (4 cores; single samples)

- **Main mode** (`ci_dry_run.sh --main`, a compiler edit):
  - gen 1 from the base's store: 9 s;
  - gen 2 cold: 133 s;
  - fill: "the published compiler rebuilds itself **byte for byte**" (`cmp`), 128 s;
  - store saved. Peak 4.6 GB.
- **PR handoff:** the next compiler edit took main's published binary and its store and built in **14 s** (that binary cold: 133 s).
- **Gate:**
  - cold serial `check --baseline` of every package (one job today on a compiler PR): **929 s**;
  - four shards by measured weight: 253 / 201 / 200 / 200 s, bounded by std-avrac alone.
- **`--ran`:**
  - std-avrac in one process: 590 s;
  - over its suite items: 236 / 167 / 156 / 44 / 5 / 3 / 1 s, 500 tests, 0 failing.
- **keepers-b:**
  - 478 s on one runner on 763009d7, excluding a 13-min `work_test.sh` hang.
  - Thirds measured separately on 5e7ff03b: **B1 221 s, B2 190 s, B3 741 s**.
  - B3's tool-witnesses had begun running the 9-edit `witness_program_edit.sh`; the new 600 s bound refused it by name.
  - That witness is now its own job in five parts. Part 0/3 (edits 1, 4, 7) took 694 s, every edit warm == cold. That works out to ~120 s for the first cold build and ~190 s per edit, so ~8 min per part.
  - tool-witnesses without it: **70 s**.
- **runtime-keep:**
  - all 359 breaks: 622 s over 4 workers (1050 test runs); four parts ≈ 155 s each.
  - **BOUND stays 60 s:** the slowest passing run is 4.68 s, but 14 breaks are killed by their failing check only after 15–50 s (flow ×5, tick ×4, tasks_door ×3, case, verdict). A 15 s bound would name the clock instead of the check.

## Expected PR wall on GitHub (estimates: ~1 min per job start and hand-down)

| PR | before | after |
|---|---|---|
| docs-only | ~2 min | ~2 min (static keepers ~1 min, in parallel) |
| std package outside the compiler | prepare ~3, then keepers-b ~8 (now ≥ 20 with the edit witness inside it) / runtime-keep ~9–10 (if runtime moved) | prepare ~3, then the longest leg: keepers-b third ~4, suites, gate shard ~1–2; seed-check and edit-witness kept by key → **~7 min** |
| compiler PR | prepare ~8 + gate 15.5 (serial cold) + keepers-b (now ≥ 20 with the edit witness inside it) | prepare ~3–4 (compiler 6–14 s), then the longest of: gate shard ~4.2, suites ~5–6 plus their `--ran` half (≤ 236 s an item), edit-witness part ~8, keepers-b third ~4, runtime-keep part ~2.5 → **~12 min** |

## Receipts (trunk 3d35d216 merged)

- Standing compiler rebuilt from trunk (old-path `make try`, 302 s), installed as build/avra.
- `AVRA_PROGRAM=1 make try`:
  - the first try died in the link: "clang: unable to execute command: Bus error", with the new lld link;
  - after I freed 3.2 GB of my own dry-run caches, the retry exited 0 (29 s, warm);
  - not reproduced, cause unknown.
- `tapes $PWD/packages/cli --built`: **44826 of 44826**.
- Self-tests:
  - `tools/ci_gate.sh --self-test`: passed;
  - `tools/tool_witnesses.sh --self-test`: passed (6 fixtures, including a hang refused at its bound);
  - `ci_verdict` and `ci_invariants --self-test`: clean;
  - `workflows_yaml` clean, `pipeline_doc` resolves.
- `ci_invariants` live: the same 2 refusals as trunk.
- `witness_program_edit.sh`, part 0/3: every edit warm == cold. Ended by TERM mid-edit, it exits 143 with the tree restored.
- The idiom gate: no `.av` touched, so 0 NEW. Sound check: not applicable (no memory, ownership-lowering or runtime change).

## A new trunk defect found (kept for you)

`tapes packages/std-http/src/tests/h2_reads_beside --ran` **traps**: "avra: index 1 is out of bounds (length 1)".
- It happens cold and warm, with an old-path-built and a new-path-built compiler, on db94aa87 and on 3d35d216. On a0ef1a00 std-http's `--ran` was 55 made, 0 failing.
- The old path's `avra run` of the same test prints its third line as `false`, not the expected `true` ("stream 5 read its body and answered before stream 1"). That part looks timing-dependent on this 4-core sandbox.
- Kept: `/work/avra-lane-ci-speed-std-http-cache-db94aa8` (std-http's `.avra-cache` and the machine cache from the db94aa87 run).
- Because the suites' `--ran` half is now a **verdict** (ab890f9), this trap would fail the std-http suite item on any PR that reaches std-http. That is the half doing its job. Setting `CI_RAN=advisory` on the suites step turns it back into a warning.

## Open, for the owner

- No run on GitHub Actions yet. Keys, conditions and matrices are checked as YAML and by `ci_invariants` (the same 2 refusals as trunk: `object-gone-attack` and `pool-check` are not wired).
- `AVRA_GATE_CHECK=program`: the program layer's `check --baseline` landed (a0ef1a00, steps 0–2), but its fact rules are not all moved, so the old path stays the verdict. `both` proves the switch before it is thrown.
- The light-package gate weights are serial-pass costs.
- The ui-browser keeper's and the edit witness's times on a real runner are unmeasured.
- `work_test.sh`'s hang did not reproduce on a rerun. Bounding every witness covers any recurrence. An attempt to bound inside `work_test.sh` broke its "follower killed outright" check, so it was reverted and the bound lives in `tool_witnesses.sh`.
