# Warm edit of packages/cli on the program layer — where the time goes (MEASURE ONLY)

Trunk 4a740f4e. Standing compiler: ladder rung 2. Stores cleared. Measured compiler: `AVRA_PROGRAM_OPT=-O1 AVRA_PROGRAM=1 make try`,
with two local measurement-only patches: the `time:` line lists 200 queries (`spoken(200)`), and the engine
prints milliseconds (`query_times.av seconds`). The products were emitted at the default -O0. Box: 4 cores, 15 GB.

Each run: cold build → edit → **measured warm build** → take-back → rebuild → next edit. The tables are medians
of 3 fresh runs (`/usr/bin/time -v` plus `AVRA_QUERY_TIMES`). Start-up and child CPU come from `perf`
(a flat run at 499 Hz, plus call-graph runs at 249–999 Hz, `--call-graph dwarf`). Bytes come from a strace run.

**The engine's counters start after `program_worked`**, so store open / frontier open / input check never
show up in `split:`. perf attributes them.

## 1. Literal in a leaf fn: cache.av, the `cache clean` message
**wall 3.50 s · user 3.09 s · sys 0.60 s · max RSS 1.06 GB** (runs: 3.69 / 3.23 / 3.50 wall)

| rank | phase | CPU s | wall s | note |
|---|---|---|---|---|
| 1 | start-up: `program_worked` → `frontier_opened` → `suspects_of` → **`Frontier.readers_of`** | 0.82 (readers_of 0.69) | ≈0.8 | not in engine counters; perf call graph |
| 2 | **link**: ld.lld | 0.64 (4 threads) | **0.34** | full relink: 42 bucket objects (73 MB) + runtime → 93 MB binary, every edit |
| 3 | emit (LLVM, owed buckets) | 0.40 | 0.40 | |
| 4 | the store saved (`frontier_written` / `written_over`) | 0.31 | 0.31 | |
| 5 | the shape | 0.23 | | |
| 6 | the keys (bucket keys) | 0.20 | | |
| 7 | program_code_hashes (folded 0.15) | 0.18 | | |
| 8 | the refusals (program_refused) | 0.15 | | |
| 9 | the buckets asked | 0.08 | | |
| — | other queries asked (package_closure 0.07, file_items, package_impls, lowered_under ×4 …) | ≈0.15 | | `asking the program layer` 0.31 s in all |
| — | forked child m-O1 (emit share) | ≈0.2 | | 6% of samples |
| — | cp 93 MB binary / mv / clang driver | 0.04 / 0.01 / 0.02 | 0.03 / 0.01 / 0.02 | |
| — | "in neither" (inside timers) | 0.15 | | |

## 2. Body edit of a mid-reached fn: shared.av `rooted`, one added `let _ = path.length`
**wall 6.62 s · user 5.96 s · sys 0.85 s · max RSS 1.81 GB** (6.62 / 6.29 / 7.34)

| rank | phase | CPU s | note |
|---|---|---|---|
| 1 | **`program_refused`** (own) | **1.92** | the whole-program refusal step, worked out again because one body read moved |
| 2 | start-up (`readers_of` ≈0.60) | ≈0.74 | |
| 3 | emit | 0.79 | |
| 4 | link (lld) | 0.70 CPU / 0.34 wall | full relink |
| 5 | program_reached (folded 0.32 + own 0.11) | 0.44 incl | |
| 6 | the store saved | 0.41 | |
| 7 | program_code_hashes (3 asks) | 0.22 incl | |
| 8 | the buckets asked 0.19 · the keys 0.18 | 0.37 | |
| 9 | lowered_under ×104 0.13 · item_methods_taken ×88 0.06 · item_misses ×88 0.05 · law_findings ×56 0.09 incl | ≈0.35 | the bodies the edit reaches, re-typed and lowered |

## 3. Signature edit: shared.av `timed(args)` gains `quiet: bool = false` (referenced from 11 files)
**wall 13.35 s · user 13.89 s · sys 2.23 s · max RSS 2.74 GB** (13.35 / 13.22 / 14.45)

| rank | phase | CPU s | note |
|---|---|---|---|
| 1 | **`program_reached`** | **2.70 own / 5.20 incl** | the shape worked out whole (its fold declines on a signature change) |
| 2 | the walk (3 asks) | 2.12 | |
| 3 | the store saved | 1.79 | many answers moved |
| 4 | program_code_hashes | 1.15 | full; trunk's fold declines |
| 5 | start-up (`readers_of` ≈0.60) | ≈0.74 | |
| 6 | the buckets asked | 0.70 | |
| 7 | link (lld) | 0.61 CPU / 0.34 wall | full relink |
| 8 | program_refused | 0.46 | |
| 9 | the keys 0.22 · program_code_shape 0.17 · emit 0.10 · resolved (reused) ×996 | ≈0.5 | |
| — | forked work-ahead children | ≈1–2 | many m-O1 pids at 3–4% each |

## Bytes (strace run 5; reads and writes by syscall, mmaps counted apart)
| edit | read by syscall | written by syscall | files mmapped | opens | minor faults (×4 KB touched) | FS blocks out |
|---|---|---|---|---|---|---|
| literal | 18.6 MB | 5.3 MB | 2.0 GB | 4768 | 155 k (≈620 MB) | 374 k (≈183 MB: the 93 MB binary written, then copied) |
| body | 18.6 MB | 32.3 MB | 2.1 GB | 4780 | 319 k | 427 k |
| sig | 18.7 MB | 89.6 MB | 2.3 GB | 5236 | 864 k | 539 k |

The store is 1.1 GB on disk (packages/cli/.avra-cache: tapes 937 MB, tapes-build 89 MB). It is mmapped whole and
read through `avra_mmap_word_at` (the top self symbol, 9%). The 4768 opens are the input check walking every
package directory, test directories included.

## The top three costs, and what removing each would take
1. **Start-up `Frontier.readers_of`: 0.6–0.7 s on EVERY warm edit, invisible to the engine's counters.**
   `suspects_of` builds the readers of the changed inputs with one pass over every edge of the whole
   frontier (plus `avra_slot_unique` / array growth). To remove it: keep the reverse edges (readers by
   question) saved in the frontier, so suspects are a lookup from the changed inputs. Or walk forward
   from the changed inputs only. noop-speed's 90f80ccd made the no-op cheap (0.15–0.23 s); an edit still
   pays this pass. noop-speed-3 (inputs held by stamp, in next-base a752d694) cuts input checking, not
   this pass; re-measure on it.
2. **The link: a full relink of a 93 MB binary on every edit.** lld takes 0.34 s wall and 0.6–0.7 s CPU, then
   the binary is copied (`cp`, about 93 MB more written), whatever the edit. 41 of the 42 bucket objects are
   unchanged on a literal edit. To remove it: link the unchanged buckets once into one prelinked
   relocatable and link only that plus the owed buckets; or, for dev builds, load the owed buckets as
   shared objects (relink one .so); or place by rename instead of `cp`. Emit has the same shape:
   0.4–0.8 s re-emits a whole bucket (about 1/42 of the program) to change one body, so smaller or
   per-body objects would shrink both.
3. **Whole-program queries worked out again on body and signature edits.**
   - Body edit: `program_refused` takes **1.92 s own** for one changed body. The refusal step is not
     folded per body.
   - Signature edit: `program_reached` takes **2.70 s own / 5.20 s incl**, `the walk` 2.12 s,
     `program_code_hashes` 1.15 s (full) and the store save 1.79 s.

   To remove it: fold `program_refused` per unit (re-ask only the units whose facts moved), and make
   `program_reached` fold through a signature change (re-walk only the callers of the changed
   signature). The store save then follows the number of answers moved.

Smaller, on every edit: emit 0.4–0.8; the store saved 0.3–0.4 on literal and body edits (`frontier_written`
rewrites the frontier); the shape 0.23; the keys 0.2; the buckets asked 0.08–0.7.

## Caveats
- The call-graph perf runs re-applied edits already seen once, so some answers were saved; their
  percentages are used only for start-up and store-write attribution, converted to seconds against
  the same run's samples. The ranked phase numbers come from the 3 fresh runs.
- `forked child` CPU is attributed by pid (perf), not by phase.
