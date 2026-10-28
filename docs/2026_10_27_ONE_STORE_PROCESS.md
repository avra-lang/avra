# The one-store migration — the process

The only file that says where this migration stands. Update it in the same commit that
changes the state. The design and its evidence live in
[`2026_10_27_ONE_STORE.md`](2026_10_27_ONE_STORE.md).

## The goal, in four testable parts

1. **One store.** Every durable answer lives in the one store (`.avra-cache`).
2. **Everything derived.** No answer is kept anywhere but that store.
3. **Zero duplicates.** One fact, one place. Two copies of a fact is a defect, not tidiness.
4. **One place per decision.** Each question is answered by exactly one definition.

## State (2026-10-27, `hd-clean`)

| # | goal | state |
|---|---|---|
| 1 | One store | **done on main** — one `.avra-cache`, one pack + CAS, one wire stamp |
| 2 | Everything derived | **partial** — kernel families hold many answers; `Parsed`/`Resolved`/`Typed` have no rows, so they recompute |
| 3 | Zero duplicates | **1 removed** (`hold.standing` was a second copy of `is_held`); remaining: `decls.held` + the row judgement, and ~60 ad-hoc `Keys` maps |
| 4 | One place per decision | **not yet** — "is this file held?" is answered in ~65 places |

Latency, one-comment edit in `packages/cli`, measured on this machine:

| | wall |
|---|---|
| `origin/main` | 17 s (exit 1) |
| `hd-clean` @ `bc1b4f8e` | **5 s (exit 0)** |
| repeat, nothing changed | 0 s |
| cold (store removed) | 38 s |

## Branches

- **`hd-clean`** — the live branch: `origin/main` + the landable commits. Work happens here.
- **`hd-sigfix`** — evidence, not code: the whole hold deletion (−1006 lines, zero
  `is_held`) on a base whose store layer main has since **renamed** into `compiler/store/*`.
  Its commits cannot be applied mechanically; they are the reference for the target shape.

## The rule that governs every deletion here

**A flag that answers a question the store cannot is not a cache — it is data.** `is_held`
answers "does this file's body exist in this run?", which the store cannot answer: a file
can have standing rows and still be read (it was read this run, forced, or its module is
loading). Swapping it for a row judgement **crashed the compiler**
(`index 219 is out of bounds (length 40)`), and the crash poisoned the store.

So each deletion lands in this order: (a) give the one definition its inputs, (b) make it the
only writer, (c) delete the other copies, (d) measure.

## Order of work

- [x] one measurable win: `keep_codes` row skip — 17 s → 5 s
- [x] one duplicate fact deleted: `hold.standing`
- [x] the design, its evidence, and this process written down
- [ ] give `mint_files` a row-judgement hook (default: not held) → then delete `decls.held`
      and the ~65 reads follow it
- [ ] `sigs` 2.2 s: a signature whose row stands answers instead of being re-derived
- [ ] `ast` 2.0 s: the dependent file is parsed only when a row it stands on moved
- [ ] the ~60 `Keys` maps, one at a time, each into a family (start: `seen_views`,
      `viewed`, `view_parts`, `object_keys`, `typed_files` — the hot ones)
- [ ] `Typed`/`Parsed` rows, re-expressed on main's store (the old branch's codecs are the
      reference)

Gate: a warm edit over 10 s is a failure. Target 300 ms.

## The loop (and its traps)

1. `make -s recover` (seed) → `make -s avra` — **the only reliable builder here**; the
   shipped "released compiler" route fails on this tree.
2. Measure: warm, edit, repeat — wall + `--time`.
3. Commit only green; push `hd-clean`.
4. Traps, all of which cost hours this week:
   - a **stale `avra-try`** silently measured an old binary: always build in the same run;
   - a **trapping run poisons `.avra-cache`**: `rm -rf .avra-cache` before re-measuring;
   - the branch being **behind main** breaks `@std` resolution: check `git merge-base` first.

## Measured, 2026-10-27 late: what `hd-sigfix` actually does

`hd-sigfix` (the holds deleted) was built from the seed and run, so this is not an
assumption:

| test | `hd-sigfix` | `hd-clean` (main + 3) |
|---|---|---|
| builds from the seed | yes | yes |
| cold `check packages/cli` | **killed at 600 s (timeout)** | 39 s, exit 0 |
| one-comment edit | **exit 2 (crash), 55 s** | **5 s, exit 0** |
| `check packages/std-avrac` | dies: `@std/relation:src/input.av` | exit 0 |

Both branches sit on today's main (`merge-base` = `5f65f027`), so the deletion is not
"stranded on an old base" — it is **entangled with the branch's other changes** (the facts
codec, `TextDigest`, the 5-argument `store_stamped`). Copying the 25 deletion files onto
`hd-clean` fails to compile because those APIs do not exist there; copying the whole set
reproduces the broken compiler.

**Therefore the deletion lands by PORT, one file per commit, each behind the gate**
(cold exit 0, edit ≤ 5 s): start with the files that only carry the deletion
(`whole.av`, `references.av`, `receivers.av`, `consumes.av`, `unit_rows.av`, `leaves.av`),
leaving `workspace.av`/`build.av`/`kept_settle.av` for last since they also carry the
entangled changes.

Constraint to plan around: the machine has ~1.2–1.4 GB free, so a compiler build is the
scarce step; batch several ported files per build.
