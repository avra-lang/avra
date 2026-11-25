# avra-lane-ci-speed — the PR gate, measured and cut

Branch `avra-lane-ci-speed` on `program` e8760228 (4 commits, no `.av` touched → idioms: n/a, 0 NEW by construction).
Bundle: `/work/avra-lane-ci-speed.bundle` (`program..avra-lane-ci-speed`).

## Result

- A PR's compiler is now taken **by its source's key** and built at most **once, through the program layer, from the base's own binary over the base's own store**. Measured here on a compiler-file edit: **6 s** for the compiler step (dry run). The old flow pays 2 old-path generations: **268.6 s + 264.2 s cold**.
- `keepers-static` no longer `needs: prepare`. It starts with the run and refuses in **~1 min** (55–58 s here).
- `seed-check` is kept by compiler key, so a PR that leaves compiler source alone does no seed build (that build is ~4.5 min).
- A compiler change's **second generation** moves out of prepare into a parallel `self-build` job, beside the suites.

## 1. Each CI step's command, timed here (4 cores, 15 GB; single samples; every `.avra-cache` and `AVRA_CACHE_DIR` cleared before each cold run)

| step (job) | command | wall | CPU | peak | waits on |
|---|---|---|---|---|---|
| C compiler/package objects, cold (prepare) | `make -j4 -o avra objects` | 36.4 s | 65.7 s | 0.25 GB | checkout (cached by C hash on a hit) |
| **old compiler gen 1, cold** (prepare) | `make avra` (prebuilt → trunk) | **268.6 s** | 442 s | 6.9 GB | objects |
| **old compiler gen 2, cold** (prepare) | `make avra` (gen 1 → trunk) | **264.2 s** | 441 s | 6.9 GB | gen 1 |
| warm the store (prepare) | `build/avra check packages/cli` cold | **191.1 s** | 189 s | 7.1 GB | compiler |
| libs (prepare) | `make -j4 -o avra libs` | 7.8 s | 8.1 s | 0.1 GB | compiler |
| hand-down pack (prepare) | `tools/hand_down.sh pack` | 16.4 s → 360 MB | | | libs; then upload, and a download per job |
| keepers-static | `make keepers-static` | 55–58 s (externs is 43 s of that) | | | tools binary (fetched by key; built here in 6 s) |
| gate, std package | `gate_changed.sh --files … --packages std-text` | 1.1 s (std-queue 3 s) | | | prepare |
| suite, std package | `avra test packages/std-text` | 4.0 s (std-queue 3 s) | | | prepare |
| new path, cold | `AVRA_PROGRAM=1 make try` | **93.8 s** | 190 s | 4.5 GB | objects |
| new path, store **another binary** filled | new product builds over it | **142.6 s** | 265 s | **10.7 GB** | — |
| new path, no-op, same binary | | 1.5 s direct / 8.2 s via `make try` | | | — |
| new path, warm edit std-text body | same binary, own store | **10.9 s** (revert 6.6 s) | | 1.4 GB | — |
| new path, warm edit std-avrac `build.av` body | same binary, own store | **10.2 s** (revert 7.7 s) | | 1.4 GB | — |
| program store (cli) | `packages/cli/.avra-cache/tapes` | 1.0 GB raw, 505 MB gzip -1 (20 s) | | | — |

These numbers explain the ~8 min: two old-path generations (~4.5 min each when cold, less when the restored store is warm for gen 1), plus objects, pack and upload, plus the cold warm-store `check` whenever no store came with the binary.

The finding that shaped the design: **a program store only helps the binary that filled it.** Read by another binary, it was slower than an empty one and used 2.4× the memory. So the cached store must be the starting compiler's own.

## 2. The design (implemented)

**Keys** (`tools/ci_gate.sh keys`, built on the new `tools/compiler_paths.sh --key-at <rev>`, which needs no checkout):
- `key` is this tree's compiler source. `base_key` is the merge-base's: a PR merge ref's first parent, otherwise `git merge-base`.
- `store_restore=pstore-<base_key>`. A store holds what one binary answered while building one compiler source, so every merge-base with the same compiler source shares it. Keying by compiler key rather than by sha is the same thing as "keyed by the merge-base", without duplicate entries.

**prepare's compiler** (`tools/ci_gate.sh compiler`, the `compiler by key` step):
1. Restore `avrac-<key>` (build/avra + .avra-cache), else fetch the release for `key` → **kept**, no build. This covers a docs PR, a non-compiler std PR, and a re-push. A PR's own built compiler is saved under its key, so its next push hits.
2. Otherwise start from the base's binary (`avrac-<base_key>` cache or release) and restore `pstore-<base_key>`. Then run **one** `AVRA_PROGRAM=1 make try`, which pays only for what the PR moved.
3. If the base's binary is missing, start from the standing compiler or main's newest release, and **set the restored store aside** so a foreign store is never read. If no compiler can start, or the tree has `Rung:` commits, the step exits 3 and the existing `.github/actions/compiler` ladder action runs unchanged. A light (draft) run also goes to the action, as before.
4. **Main's run:** `CI_GENS=2` builds the fixed point. `CI_FILL=1` then has the binary being published build the tree once more: this fills the store under that binary's own print and compares (`cmp`) the rebuild with the published bytes. The store is saved under `pstore-<key>`.

**Jobs:**
- `keepers-static` needs nothing, so it fails in ~1 min.
- `self-build` (new, PR, only when prepare built a compiler): the product builds the tree again and must run. It sits beside the suites instead of in front of them.
- `seed-check` is skipped by a `seedok-<key>` cache mark. Its verdict is a function of compiler source; the seed, runtime, backend, Makefile and every reached package are all in the key.
- The old-path "warm the store" (`check packages/cli`, 191 s) no longer runs in prepare after a program-layer build. `keepers-a` group 2, which holds `warm-edit`, warms its own store.

**Dry run:** `sh tools/ci_dry_run.sh [--base <ref>] [--main] [--no-gate] [--no-suites] [--cold]` runs the same `ci_gate.sh` / `gate_changed.sh` / `make` commands in the workflow's order. A local directory stands in for the Actions cache and the release fetch is off. It prints a row per step (job, wall, what it waits on) and the critical path.

Dry runs here (cache seeded as main's run would leave it; base = this branch):

| scenario | static | prepare | gate | suites | notes |
|---|---|---|---|---|---|
| docs-only | 55 s | 0 (build=0) | — | — | plan only |
| std-queue (non-compiler std package) | 58 s | 10 s (compiler kept 1 s, objects 8 s) | 3 s | 3 s | |
| std-avrac `build.av` edit (compiler) | 55 s | 16 s (store restore 2 s, **compiler 6 s**, objects 8 s) | not run | not run | every package is affected |

## 3. Expected minutes on GitHub (estimates)

Assumptions: ~0.5–1 min of runner and container start per job, ~0.5 min per job to upload or download the 360 MB hand-down, cache restores of 100–500 MB taking 10–20 s.

- **Docs-only PR: ~2 min.** prepare plans and builds nothing; `keepers-static` ~1 min of work; then `test`.
- **std package PR outside the compiler** (std-queue, std-sql, std-tls, …): **gate and suites verdict in ~4–5 min** (prepare ~3, then gate/suites ~1.5). Note that every std package the cli reaches (std-text, std-io, std-http, …) **is** compiler source by `compiler_paths.sh`, so it takes the compiler-PR path below with a small edit cost.
- **Compiler PR: prepare ~3–4 min** (it was ~8). Measured compile cost here is 6–11 s for a body edit; a wide change is bounded by a cold new-path build, ~1.6 min. Then suites over every package in 6 shards: ~5–6 min, since the heaviest single suite is about 230 s per the seed weights. → **gate and suites verdict ~9–10 min.**
- In all full runs the wall is still bounded by the existing keeper legs: keepers-b ~8 min and runtime-keep ~9–10 min per the speed.budget notes. I did not touch those legs and could not measure them here, so a full PR's total stays ≥ ~11 min until they are split further.

## Receipts

- `AVRA_PROGRAM=1 make try`: exit 0.
- `tapes $PWD/packages/cli --built`: **43247 of 43251** (4 not yet; same as trunk).
- `tools/ci_gate.sh --self-test` passes: docs keep the key, a reached package moves it, tests do not, `--key-at HEAD` = `--key`, the store restores from the base, a kept compiler is taken, a foreign store is set aside. `tool-witnesses` picks it up from its `# tool-witness: --self-test` header.
- `workflows_yaml` clean; `ci_verdict --self-test` clean; `pipeline_doc` resolves; `ci_invariants --self-test` holds.
- `ci_invariants`, live: the same 2 refusals as clean trunk (`object-gone-attack` and `pool-check` are not wired; both are in the Makefile, not my files).
- `keepers-static` refuses vocab, layers, cited, externs and ci-invariants **on clean trunk e8760228 too** (checked in a trunk worktree), so these are trunk debt.
- A program-layer-built compiler runs the gate's commands: `test packages/std-program` gives **395/396 with both** the old-path build and the new-path build, with the same failure in each (`frontier_adversarial_test.av:836`, "a store that can't write"; this sandbox runs as root). Wall was 132 s vs 160 s, one sample, so the new-path product may run suites ~20% slower; unproven.
- idioms: no `.av` touched → nothing to check (0 NEW).

## Unproven / open

- Nothing ran on GitHub Actions. The cache keys, the `continue-on-error` saves and the `hashFiles` conditions are checked as YAML and by the invariant tool only.
- `CI_FILL`'s `cmp` of the published binary against its own rebuild has not run here (main mode was not dry-run, to spare a 6.9 GB build pair). Whether the program layer reaches a byte-for-byte fixed point is unknown. If it does not, the step warns and the store is still the published binary's own.
- The suites still run the old evaluation (`avra test`). The new path covers `build` only; `tapes --ran` is its program-test runner, which I have not wired as the suites' command.
- For a compiler PR, `gate` runs old-path `check` on every package with a cold store. That is now ~191 s for cli alone, in parallel with the suites. The next step would be to shard the gate like the suites, or move idioms to `tapes --findings`.
- The **top defect** in the handover (memo hits record no read) makes warm new-path builds after type edits suspect. A PR's compiler built warm over the base store inherits that hazard until the defect is fixed. The cold fallback (`--cold` / store aside) is always available.

## What I'd take next

1. Shard `gate` for compiler PRs, and measure keepers-a/b on a runner to split the longest leg.
2. Run `ci_dry_run.sh --main` once to prove the fixed-point `cmp`.
3. Wire `tapes --ran` as the suites' new-path half once the lead says the program layer is the gate's instrument.
