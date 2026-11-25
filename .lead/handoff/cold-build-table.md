# The cold build's map: `AVRA_PROGRAM=1 build packages/cli`, -O1, 4 cores (trunk e2bce925)

This is measurement only; no code changes.
- **Cold** means package and tree stores are emptied and there is no machine cache at all. Products are built at -O1.
- **Sources:**
  - Wall time comes from the plain -O1 compiler: 130.6 s wall, 356 s user, 12.8 s sys.
  - CPU time comes from a frame-pointer -O1 compiler under `perf record --inherit` at 199 Hz: 70 770 samples, about 355 CPU-s, with timing within 2 s of the plain run.
  - Each phase is the window between the engine's own timer lines (`AVRA_QUERY_TIMES` and `--time`, stamped as they print).
  - Processes, threads and CPU per process were sampled every 0.25 s from /proc.

## Phases

| # | Phase | Wall (s) | CPU-s | Processes (threads) | Parallel? | Bound | Floor @4 / @8 cores |
|---|---|---|---|---|---|---|---|
| 1 | files parsed (4 import waves, each forked) | 0–5.0 (5.0) | 12.7 | 4 per wave (1 each) | yes, ~2.5 cores | each wave's fork and merge, waves in series | 3.2 / 1.6 |
| 2 | generators run (`generated` 11.5, `file_marks` 3.4, `file_declares` 2.9, item_tape 2.7) | 5.0–12.3 (7.3) | 35.4 | 4 | yes, 3.5 cores | CPU | 8.9 / 4.4 |
| 3 | parent: work merged, impls filed | 12.3–17.8 (5.5) | ~4 | 1 | **serial** | parent | 4 / 4 |
| 4 | bodies lowered + laws (`item_misses` **24.4**, `law_findings` 9.6, `item_methods_taken` 8.2, lowering itself (`lowered_under` + method) ~11, `item_ungiven` 3.0, `item_unmet` 2.9, …) | 17.8–45.5 (27.7) | 93.1 | 4 | yes; 4 cores, then a 3–4 s single-worker tail | CPU, plus imbalance | 23.3 / 11.6 |
| 5 | parent: work merged / published (`avra_mmap_word_at`, disk_store carried / placed_runs, io poured) | 45.5–50.5 (5.0) | ~4 | 1 | **serial** | parent, store copying | 4 / 4 |
| 6 | **parent alone**: `program_refused` 67 % (refused body 4.5, `unit_facts` 4.8 over 43 729 units, `program_reached` 2.7); `program_binary` 22 % (placed_code 1.8, code hashes 1.1, placed_names 1.0, body 1.7) | 50.5–70 (~20) | 21.7 | 1 | **serial** | parent | 20 / 20 as written |
| 7 | **emit**: 4 forked processes × 4 LLVM threads (16 threads on 4 cores). 96 % LLVM: IR passes ~70 (inliner 22, InstCombine 16, SimplifyCFG 6, other 25), codegen ~82 (SelectionDAG 34.5, machine passes 37, regalloc 10), malloc/free 17; Avra module making 6.5 | 70–118 (48) | 177.1 | 4 (16 threads) | yes, 4 cores; one process alone for the last ~4 s | CPU; **memory peak 5.8 GB here** | 44 / 22 at -O1 |
| 8 | link (clang + ld.lld), then store saved 4.3 s (frontier placed_reads / written_entry, hash table) | 118–130.6 (~12) | ~7 | 1–2 | mostly serial | parent | ~7 / ~7 |

- **Sum of floors with perfect parallelism and today's serial parent:**
  - 4 cores: about **116 s**. The build is already within 1.13× of its 4-core floor.
  - 8 cores: about **76 s**.
- **Parallel scaling stops paying fast:** the CPU itself has to shrink.
- **Serial parent:** phases 3, 5, 6 and 8 add up to about 40 s on one core.

## Product at -O0 (same build, `AVRA_PROGRAM_OPT=-O0`; measured once, not paired)
82.7 s wall, 188 s user. Emit shrinks from 48 s to about 5 s; everything else is the same.

## Old path (cold `make try`, same tree)
255 s wall, 432 s user, 7.0 GB max RSS. Its serial phases:

| analyze | emit | lower | keep | expand | owed | bodies | parse | ast |
|---|---|---|---|---|---|---|---|---|
| 67.8 | 69.1 | 54.7 | 35.3 | 20.5 | 18.2 | 13.6 | 11.6 | 6.4 |

The new path is 2.0× faster cold. Its emit is 48 s against 69 s; the front end is parallel instead of serial.

## What the cli build is
- 96.5 % of the items read back belong to std packages: @std/avrac 86 645, @std/relation 4 074, @std/http 4 072, @std/program 3 814, … The cli itself is 3 867.
- The cli's own source is 9.5 k lines; std-avrac's is 203 k. A "cold build of the cli" is mostly a cold build of the compiler's std reach.
- The read path (`read_item`) is 19.6 CPU-s: read-back 7.9, BoundedCache bookkeeping 3.4 (held-items' own overhead, mine to trim), key making (`fp_str` of the item text) 3.1, lookups the rest.

## The top 3 costs and what each would take
1. **Emit at -O1: 48 s wall, 177 CPU-s (50 % of all CPU), almost all LLVM.**
   - (a) A dev/cold build at -O0: measured 130.6 → 82.7 s. This is the owner's dev/release decision.
   - (b) Objects keyed by bucket content in the MACHINE store, per compiler binary. A cold build in a fresh worktree would then reuse std's objects, which are about 96 % of the product.
   - (c) Emit width: `run_across` forks one process per core and each runs `emit_width()` = cores threads, so 16 threads on 4 cores. Same CPU, but 16 modules are in flight, and that makes the 5.8 GB peak. Width should be cores in total.
2. **Bodies round, 27.7 s wall / 93 CPU-s, of which the laws are ~55 and lowering ~11.**
   - `item_misses` alone is 24.4 CPU-s. It reads each item back again (untape, alloc_expr, `settle_prints` / fingerprints 5.6 s) and `entry_nodes`, separately from the lowering that already typed it.
   - Laws that read the lowering's typed result, instead of re-reading and re-walking each item, would remove most of it.
3. **The serial parent: about 40 s wall on one core** (phases 3, 5, 6, 8).
   - The largest part is `program_refused` (~14.5 s); its `unit_facts` are per unit, so they could run in the workers ahead of time.
   - Then placement and code hashes (~5 s), merging and publishing packs (~9 s), and store save (4.3 s).
   - At 8 cores this serial part would be over half the wall.

## Against the target (5 s on the Mac ≈ 10 s here)
10 s on 4 cores needs at most ~40 CPU-s of perfectly parallel work and almost no serial parent. Today's numbers:
- **CPU:** 356 CPU-s at -O1, 188 at -O0.
- **Serial parent:** ~40 s.

No single phase change reaches 10 s. Two paths do:
- **Std reach answered once per compiler binary on the machine.** Answers and objects for the 96.5 % that is std would come from the machine store, so a cold cli build does only the cli's 3.5 % plus link.
- **About 9× less CPU across the board**, plus the serial parent made parallel.

The first is the only one in sight. It means the "cold build" the owner times is cold for the project but warm for std.
