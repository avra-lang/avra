# avra-lane-switch-rehearsal — stage A rehearsal (the compiler builds itself on the new pipeline)

Linux sandbox, 4 cores / 15 GB. Builder P0 = the prebuilt `build/avra` (from 3b610bc7).
Final tree: `program` e8760228 + 9d68581 (this lane's one fix), branch `avra-lane-switch-rehearsal`.
Every generation: `AVRA_PROGRAM=1 <compiler> build packages/cli --time` through `./avra` (AVRA_BIN),
cold = `packages/cli/.avra-cache` removed first; no-op = the same build again. Numbers are `/usr/bin/time -v`.

## Answer

**Stage A could be switched on today for the compiler building itself on this machine, with three caveats that do not block self-hosting:**
`avra dev` and every TCP connect by host name in a new-path-built compiler trap (`Select` not lowered — the lowering-gap lane's);
a new-path-built compiler is ~25–30 % slower than the old-path-built one doing the same work;
and the new path prints none of the 108 warnings the old path prints over the cli.
Nothing I measured fails in the new-path product that passes in the old-path product.

## Fixed point and equivalence (e8760228)

| run | product sha256 (prefix) |
|---|---|
| P0 → P1 (new path) | 626a739f; `AVRA_PROGRAM=1 make try` → build/avra-try is byte-identical to P1 |
| P1 → P2 (new path) | 4829ca61 |
| P2 → P3 (new path) | 4829ca61 — **P2 == P3 byte-identical** |

Also held on 31f3d60 (P2 == P3, 73b21849) and on baa28a8 (P2 == P3, 5fbb83bc).
Cross-pipeline checks on baa28a8 — Q1 = the old-path product (P0, no AVRA_PROGRAM):
- N2 = Q1 building cli on the NEW path == P2 (byte-identical).
- O2 = P2 building cli on the OLD path == Q2 = Q1 building cli on the OLD path (byte-identical).
- A no-op build is byte-identical to its cold build for P1, P2, P3 and Q1.
- `AVRA_PROGRAM=1 make try` with P2 installed as build/avra: exit 0, build/avra-try == P3.

So a new-path-built compiler and an old-path-built compiler produce the same bytes on both pipelines.

## Generations: wall / user / peak RSS

| e8760228 | cold | no-op |
|---|---|---|
| P0 → P1 | 70.3 s / 129.5 s / 4.23 GB | 5.0 s / 4.3 s / 3.53 GB (P0 is pre-fix) |
| P1 → P2 | 96.2 s / 182.0 s / 4.54 GB | **0.24 s / 0.13 s / 296 MB** |
| P2 → P3 | 92.3 s / 177.6 s / 4.58 GB | **0.23 s / 0.12 s / 290 MB** |
| `AVRA_PROGRAM=1 make try` (P0) | 69.4 s / 128.0 s / 4.23 GB | |

| baa28a8 (before the no-op fix) | cold | no-op |
|---|---|---|
| P0 → P1 | 69.9 s / 127.3 s / 4.24 GB | 5.21 s / 4.55 s / 3.53 GB |
| P1 → P2 | 95.1 s / 181.1 s / 4.64 GB | 2.65 s / 2.04 s / 1.26 GB |
| P2 → P3 | 94.4 s / 181.8 s / 4.64 GB | 2.53 s / 2.05 s / 1.25 GB |
| old path P0 → Q1 | 158.1 s / 180.6 s / 7.53 GB | 0.40 s / 0.11 s / 368 MB |
| old path Q1 → Q2 | 209.7 s / 319.6 s / 7.28 GB | |
| old path P2 → O2 | 261.7 s / 388.7 s / 7.38 GB | |
| new path Q1 → N2 | 73.9 s / 140.1 s / 4.63 GB | |

31f3d60 (before the refusal rule landed): P1 → P2 cold 92.3 s / 159.7 s / 4.11 GB — the whole-program refusal rule costs a cold self-build ~+21 s user.

## Receipts with P2 as the compiler (e8760228 unless marked)

| check | P2 | old-path product Q1 (baa28a8) |
|---|---|---|
| `make runtime-tests` | exit 0 after 9d68581 (failed on Linux before it, see 2.) | — (C only) |
| `tapes <abs cli> --built` | 43247 of 43251 made, 4 not yet (baa28a8: 43140/43144) | 43140/43144 |
| `test packages/std-program` | 395/396 (baa28a8: 394/395) | 394/395 |
| `tapes <abs std-relation> --ran` | 42 made, 42 eval, 42 native, 0 failing | same |
| `tapes <abs std-avrac> --ran` | 489 tests: 422 made, 420 eval, 422 native, 0 failing (517 s wall / 431 s user / 0.97 GB) | 421 made, 419 eval, 421 native, 0 failing |
| new-path `make try` with P2 standing | exit 0, product == P3 | |

On baa28a8 the outputs of `--built`, `test std-program`, `--ran std-relation` and `--ran std-avrac` are IDENTICAL
between P2 and Q1 once times are masked.

## Ranked list: what fails or differs

1. **`Select` is not lowered: `avra dev` and `Net.connect` trap in a new-path-built compiler.** (lowering-gap lane's)
   Every new-path build says: `avra: built on the program layer; 3 bodies not lowered yet trap where they're reached: @std/net/src/net.av.raced, cli/src/commands/dev.av.Page.clocked, cli/src/commands/dev.av.Page.watching`.
   `raced` is the dial behind `Net.connect(host, …)`; in the cli only `dev`/`dev_backend` reach these three.
   Smallest reproducer (a package `selpk`, `[bin] path = "src/main.av"`):
   ```
   use @std.time.{ms, quiet}

   fn waited(stop: Task<bool>) -> string {
       select {
           quiet(ms(10)) -> "quiet"
           stop -> "stopped"
       }
   }

   let stop = spawn { true }
   waited(stop)
   ```
   `AVRA_PROGRAM=1 build/avra build selpk && selpk/src/main` → `avra: a body not lowered yet was reached: selpk/src/main.av.waited: \`Select\`` exit 2.
   Old path → prints `stopped`, exit 0. Same with P2 and Q1 as the builder.
   I could not reach the trap through `avra dev` here: this sandbox's clang has no WASI libc, so both products stop earlier with
   `avra: no C compiler here links a wasm module …` (exit 2, identical).
   `--ran std-avrac` lists `Select` 10 among its not-made tests.

2. **`make runtime-tests` failed on Linux: FIXED (9d68581, test-only).**
   a) `runtime/tests/cores_test.c:348: error: call to undeclared function 'posix_openpt'` (and grantpt/unlockpt/ptsname) — no feature macro on glibc. Added `_GNU_SOURCE` under `__linux__`, as `runtime/avra_cores.c` does.
   b) Then `cores_test: FAILED a core holds no descriptor it was not given (runtime/tests/cores_test.c:634)`, deterministic. Cause: `holds()` matched by dev+inode, and Linux gives both ends of a pipe one inode, so the served write end `report[1]` read as the forbidden read end `report[0]`. `holds()` now compares the access mode too (`O_RDONLY`/`O_WRONLY`; -1 for a path). Result: exit 0, 38 suites `0 failed`.
   This is not a stage-A issue: it fails the same with any compiler.

3. **A new-path-built compiler is ~25–30 % slower than an old-path-built one doing the same work** (codegen of the new path; rc elision/lowering lanes'). Same source, same builder (P0), the two pipelines' products:
   - new-path cli build, cold: Q1 140.1 s user vs P1-equivalent (P1 → P2) 181.1 s (+29 %).
   - old-path cli build, cold: Q1 → Q2 319.6 s vs P2 → O2 388.7 s (+22 %).
   - `tapes cli --built`: 59.3 vs 76.6 s user (+29 %); `test std-program`: 97.0 vs 122.4 s (+26 %); `--ran std-relation`: 18.8 vs 24.4 s (+30 %).
   - `--ran std-avrac` (mostly child builds and runs): 410.9 vs 396.5 s (−3 %).
   Products are behaviourally the same (see Equivalence), so this is code quality, not correctness.

4. **The new path prints no warnings; the old path prints 108 over the cli** (refusal/law lanes').
   Old path, `build packages/cli`: 38 type.alias_copy, 29 type.mut_fn_unused, 17 type.receiver, 14 type.registry_hole, 7 type.coalesce_never, 3 type.seat_unused. New path: 0 lines. E.g.
   `warning[type.coalesce_never]: \`??\` never fires — \`string\` is never absent` at packages/cli/src/commands/tapes.av:174:34 (`args.option("only") ?? ""`).

5. **A compiler binary outside `build/` (or an install's `bin/`) finds no std on the new path, and says so as a parse error or an unresolved name.** The old path builds the same thing.
   `cp build/P2-cold /work/rehearsal/loose/avra; AVRA_PROGRAM=1 /work/rehearsal/loose/avra build selpk` →
   `error[resolve.unresolved]: no \`fn quiet\` is defined` (exit 1); without AVRA_PROGRAM → builds, prints `stopped`.
   On packages/cli it is `error[parse.expected]: expected BREAK while parsing \`stmt\`` at every `export command …` (the `command` form comes from @std.cli).
   Cause: `std_root()` (packages/cli/src/commands/disk_host.av:199) is binary-relative and null for a bare binary, and nothing says "no std root".
   Low impact for stage A (`build/avra` is always in place), but it cost me the first build here.

6. **`test packages/std-program` fails one test for BOTH products: environmental.** `frontier — attacked / a store that can't write / …` (frontier_adversarial_test.av:836) chmods a directory 555 and expects writes to fail; the sandbox runs as root (uid 0), so they succeed.

7. **Environment (not the repo):** the tarball carried 7180 macOS `._*` AppleDouble files (6038 under packages/, including `._*.av` and `runtime/tests/._*.c`, which `make runtime-tests`' wildcard would compile), and `.git/objects/pack/._pack-*.idx` broke every git command ("index file … is too small"). Removed with `find -delete`; none were tracked. The tarball should be made with `COPYFILE_DISABLE=1 tar …` on the Mac.

Not seen: no difference in any compiler output, no refusal on the new path that the old path lacks, no crash of a new-path-built compiler, no fixed-point drift.

## Unproven
- Timings are one sample each on a 4-core VM; the cross-pipeline ratios (item 3) are from runs minutes apart on the same idle machine.
- RC_GUARD was not run (the lead's gate does it for memory-pass changes; nothing here touched it).
- `avra dev` end-to-end was not reachable (no WASI libc).
