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

### The signature row (probed, reverted twice)

A signature is the biggest per-declaration cost on a warm run (`sigs` 2.3 s of a 5 s edit),
and `FnSig` is two fields — so a row looks free. It is not, and both attempts say why:

1. **A row keyed by the declaration and its syntax, restored into `decls.sigs`** breaks
   generic code: a signature carrying a `Type.Var` means something only inside the scope that
   declared that parameter, so it restores as a different type wearing the same spelling
   (`rule` lost its `check` method).
2. **Restricting to monomorphic, top-level declarations** still breaks, for a different and
   more important reason: **`declare_one` is not only a signature** — it also REGISTERS the
   declaration (its methods, its namespace entry). Restoring the sig skips the registration,
   so a declaration whose sig was restored is invisible to everything that looks it up.

So the row must restore the DECLARATION, not the signature: `declare_one` needs to accept a
signature it does not have to compute, and the row must carry whatever else that door
registers. That is the slice, and it is why this is not a cache entry.

### Two predicates, two questions — do not merge them (probed)

`stands_in(store, okey, want)` asks **are the rows PRESENT** (said, asks, codes, and the object
under a binary want). `file_rows_stand(store, path, want)` asks **do the rows' READS still
stand** — it judges each row against its recorded digests (`unsuspected` / `file_judged`) and
requires `file_ruled`. Pointing `stands_in`'s callers at `file_rows_stand` was tried and is
wrong: the `adrift` check then reports every file whose rulings were never computed, and the
build fails (`index -1 is out of bounds`). The pair is not duplication — the names must say
which question they answer, and a call site must pick one deliberately.

### Where the 4 s edit goes, and the only three ways down

```
ast 2.19 s · sigs 2.29 s · load 0.90 s · interfaces 0.35 · sublang 0.34 · bodies 0.29
lower 0.46 · keep 0.35 · names 0.21 · resolve 0.13      (held 578/580)
```

Both big numbers are **work on two files**, not cache misses:

1. **sigs** — a signature row is not a cache entry: `declare_one` also REGISTERS a
   declaration, so the row must restore the declaration (probed three times; see above).
   The slice is: `declare_one` accepts a signature it need not compute, and the row carries
   what that door registers.
2. **ast** — the dependent file is parsed because its rows say a read moved. It must not be
   parsed at all: the per-file **analysis row**.
3. **load 0.9 s** — the interface of the modules that moved is rebuilt; a module record that
   stands should answer instead (`record_of` already returns text; the row feeds it).
