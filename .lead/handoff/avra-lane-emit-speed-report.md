# avra-lane-emit-speed — emit and link of a new-pipeline cold build of packages/cli

Branch avra-lane-emit-speed on program e8760228 (commits bee6a5e, 6b69080, merges 5a02680, e867d52).

## Measured (trunk, Linux, 4 cores; AVRA_EMIT_TIMES=1 is a new instrument)
- The `emit` phase figure is the process's CPU across all threads, not wall.
- 32 bucket modules, 24.3k fns, 1.33 M IR instructions. Opt level 0, so the optimizer takes 0.00 s.
- IR build: 4.3 s CPU, serial on the main thread. This was the wall bottleneck.
- Codegen: 6.6 s CPU, already parallel on 4 LLVM threads.
- First hand-off to last object: 4.0–4.7 s wall.
- Before emit, `the buckets made` takes 3.2–3.5 s cold, serial.
- Link: GNU ld.bfd (the new path passed an empty ld), 2.2–2.5 s wall.
- About 25% of the main thread's emit samples were one `mv` spawn per object, each running avra_mem_settle → mallinfo2 (a walk of the whole heap).

## Changed (files: backend/llvm_wrapper.c; std-avrac compiler/backend/llvm.av, compiler/build.av; cli commands/tapes.av)
1. The link runs ld.lld: beside the clang that links, else on the PATH, else empty. It stays empty on ld64 hosts, so the Mac is unchanged.
2. Each object is written once: the C writer already writes to a temp file and renames it, so the second staging and the per-object `mv` are gone.
3. Owed buckets (4 or more) are split by instruction count across one forked process per core (runtime avra_cores). A child reads only the made Lowered, never the engine. An atfork hook resets the LLVM worker pool in a child.

## Receipts
- Link wall, cold, 3 runs: 2.30 / 2.34 / 2.49 s → 0.30 / 0.28 / 0.33 s.
- Emit-only rebuild (objects and binary dropped, warm store), wall, 3 runs: 18.3 / 16.8 / 15.5 s → 14.9 / 12.2 / 12.6 s.
- First hand-off to last object: 4.0–4.7 s → 2.1–3.1 s in each of 4 processes.
- Generated code is unchanged. The 32 objects are byte-identical between the trunk compiler and the new one on one fixed tree. Each compiler's binary is identical across its own cold runs.
- The binary's bytes differ, because the linker changed. `tapes std-avrac --program_runs` with each linked product prints identical summary lines: 488 tests, 421 made, 419 evaluator, 421 native, 0 failing.
- Gate on the merge with e8760228: make try exits 0. `tapes cli --built` is 43265/43269, 4 not yet (the extra bodies are this lane's new fns).
- witness_program_edit, run on the merge with baa28a8e only, before e8760228: it matches the trunk result. No-op and the first two edits are warm == cold; it fails at the next edit with the known `program_reached` / `enum_signature` fold defect. It was not rerun after the merge with e8760228.

## Not proven
- The whole cold build is still about 90 s of wall. Most of it comes before emit (the walk, plus about 15 s of `the store saved`).
- The fork's cost on a warm 1–3 bucket edit was not measured. Under 4 owed buckets nothing forks, so that path is unchanged.
- The Mac (ld64) was not measured.

## Next
- Move `the buckets made` (3.2 s cold / 5.2 s warm, serial) off the main thread. It asks the engine, so it needs the asks recorded in the parent first. One option is to fork after the asks and run only the memory pass in the children.
- Cut IR-build CPU in emit_mode, for example by declaring the runtime once per module instead of scanning.
- Shrink 50 MB of .text built at opt level 0.
