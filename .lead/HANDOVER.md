# HANDOVER — hold deletion + warm-edit performance

**Written 2026-11-05. ALL WORK STOPPED.** No agents running, no builds running, nothing queued.
This file supersedes `.lead/STATUS_2026_11_05.md` and every older handover in `.lead/`.

**The line:** `origin/hold-out` = **`2d8e6224`**, checked out in
`/Users/tristan/projects/tristanMatthias/avra-ho` on branch `ho-base`.
Correct. Suite **1813/1814**. The one red is `tests/decl_grain_test.av:189` (known ticket).

> The local branch ref `hold-out` in `avra-ho` is STALE at `de7660f3` (69 commits behind
> `origin/hold-out`). Do not read it. `origin/hold-out` = `2d8e6224` is the truth.

---

## 1. What the goal was, and where it stands

Finish deleting the "hold" (a second cache ledger beside the query store) and make a one-edit
warm `check` fast. Target: **≤300 ms**.

| `./build/avra-try check --time packages/cli` | base `c7c6feb8` | start of day | now `2d8e6224` |
|---|---|---|---|
| cold | 80.4 s | 105.8 s | **69.2 s** |
| unchanged | 206 ms | 209 ms | **117 ms** |
| one comment edit | 58.1 s | 99.5 s (**wrong**: 15 errors) | **55.5 s (0 errors)** |

The warm answer is now **correct** — the edited run reports 0 errors where it used to lose an
enum's variants (`TomlValue has no static fn Bool`). That correctness bug was the bigger risk and
it is closed.

Remaining gap to goal: **55.5 s → ≤300 ms**. That is one defect, fully diagnosed below.

---

## 2. What landed today (all on `origin/hold-out`)

| commit | what it did |
|---|---|
| `70a9213e` | A settlement's refusal speaks **once per lowering pass**, not once per workspace. A cached `Unsettled.Spoken` collapse outlived its pass, so `check` then `check_every` in one workspace silently kept a unit that had spoken nothing. `check_every_test` 3/3. |
| `4de44a4e` | **The signing fix was never in the tree.** A prior merge stopped at `fc6e1cf6`; `f03ce906` ("a cycle's answer is not a signing") was missing. The previous ledger's "0 errors" was a stale-store reading. Merged → warm edit 15 errors → 0. |
| `6e45022f` | `L-record` — the record loading walk and the held-reference cluster deleted. |
| `d263370e` | `L-names2` — `Family.Names` → `@query @lasting fn names_in`; family, verifier, durable slice, `cache_walk` arm deleted (−75/+42). Correct; **no speed gain** (not the bottleneck). |
| `d808fbd2` | `L-hold3` — 5 commits, **−354 lines**: the hold's file set (`held_paths` + its 8 dead loops), its tables, its per-attempt records; `store_test` cases for those rows deleted (6 fewer tests, verified legitimate). |
| `dc5ca0b5` | `L-lowercost` — **the win.** A lowered unit is `in_process_only()`. It was saving every unit's answer each run (21 089 recomputes, 9 658 records, **178 MB**) with leaves that can never verify in a new process. +7/−2 lines in one file. `lower`: 52.5 → 20.3 cold, 49.1 → 13.6 edited. |
| `726958d4` | `L-identity` — `syntax_in` is `@lasting`; `names_in` folds its **window's** offsets instead of the whole file. Removes a live unsoundness; **the wall was flat** (58.0 → 57.5 s). |
| `2d8e6224` | Ledger: the arena-identity diagnosis was **wrong in part** (see §3). |

Diffstat vs base `c7c6feb8`: **63 files, +754 / −2343.**

Metrics now: hold/held mentions in `compiler/*.av` **710** (1 325 at session start, 1 765 before the
campaign); `@family` **20**; `@query` 45; `@lasting` 3. `compiler/db.av` 613 lines and
`kept_settle.av` 903 lines still present.

---

## 3. The one defect left (fully diagnosed — read this first)

**A saved answer that embeds a declaration's arena position can never be reused by the next
process, so every declaration-grain answer recomputes on every warm run.**

Evidence — `AVRA_QTRACE=1`, warm edited check of `packages/std-io`:

```
12741 refs_index     reuse       1892 placement_of   reuse  (758 compute)
 8196 signed         reuse        755 names_in       compute (868 reuse)
 1042 parsed_in      reuse        755 typed_body     compute
                                  758 syntax_in      compute, ZERO reuse
```

`placement_of` is `@scoped_by(in_arena)` — its own doc: *"where this process's arena put it, which
names nothing past the process."* `typed_body` is `@scoped_by(in_scope)`. A unit's answer embeds
those ids, so it is un-reusable by construction — which is exactly why `L-lowercost` stopped writing
it. The write was pure cost.

### The correction the last lane proved

The "it is all arena identity" story is **too simple**, and acting on it would have been wasted work:

- `placement_of` appears in **ONE** `typed_body` record. It is not the wall.
- The real blockers, traced, are three:
  1. **`Named` bucket digests are snapshots of what has been minted so far** —
     **17 272 leaf occurrences across 6 898 records**. A bucket digest is read while writers are
     still filling the table (`envs`' name→files is never filed; `note_producers` has no caller).
     **A partial read of a table a writer is still filling is a race recorded as a fact.**
  2. **Unsettled `Writes`/`Lifted` leaves read −999 forever.** `hash_asked` exists for query answers,
     but a `@family` row read as a leaf can never settle its own hash.
  3. In-process `parsed_in` / `marks_of` reached via `signed`.

So the fix order changed: make a bucket's content complete and order-independent before anything
folds it, and give `@family` rows the `hash_asked` a query answer already has. That is
`bodies 15.5 s` — the last big number.

### This was known and deferred — and the estimate was 30× too small

Ledger, 2026-11-29: *"kept 517/519 files; the edited file's 583 declarations all recompute; no
per-declaration cache is retained across processes (DB 07b/c); only the edited file pays it, est.
1.8–1.6 s of a 4.5 s edit."* The estimate was right; its **scope** was one file. With the hold
gone the same defect applies to all 582 files, so it went from 1 file to 582 and is now the whole
edit. You cannot measure the true restore rate through a hold that skips 99% of files — the
sequencing was right, the price was misjudged.

---

## 4. Architecture assessment — the decisions that are wrong

1. **Durability is declared by hand and is derivable.** 63 `@query`, **3 `@lasting`**. Already
   inconsistent **both ways in one day**: `syntax_in` is documented durable but was unmarked;
   `names_in` IS marked `@lasting` while folding `decls.ids()` (process-local) into its answer.
   *Fix: infer the leaf closure; refuse an unprovable `@lasting`.*
2. **`@family` is a second store with its own law** — ~6 hand-written sites per row (verifier, mint
   pair, durable slice, `cache_walk` arm, ceiling row). 20 left. Delete to 0, then `db.av` +
   `kept_settle.av` (**1 516 lines**) go.
3. **Answers carry process-local ids** (§3). Never key or hash by arena position.
4. **Five verification modes** (`@recursive`, `@cycled_by`, `@scoped_by`, `@lasting`, `@over`) whose
   pairings produced every wrong answer this week. Reduce to `@query` + one explicit cycle handler.

The deepest: **the hold was a cache ledger beside the store** (`file_said`). Two ledgers of validity
drift, and when they drift the symptom is a **slow** run, not a wrong one — so it survived.

---

## 5. Carried findings (real, unfixed)

- **Sound-check trap (new):** with `AVRA_SOUND_CHECK=1`, `check packages/std-avrac` against a store
  warmed by `check packages/cli` traps *"a source text was read before the workspace staged it"* —
  judging a saved `manifest_in` record asks its `file_text` leaf, a lazy load the `unstaged` law
  forbids. Exposed when `L-lowercost` ended that record's dormancy. A record-shape defect.
- **`kg` (cache_attacks):** wrong answer — `native 'a=0 r=0 c=0'` vs `eval 'a=0 r=1 c=0'`. A saved
  answer served for the wrong program. Same class as the two-seat `const_typed` collision.
- **`dt`:** staged-text trap at `answers.av:17` `file_text`.
- **Library-vs-app divergence** in `cache_attacks`.
- `cache_attacks.sh` on base `c7c6feb8`: 529 builds, 92 failed, **mostly stale hold-era assertions**.
  Do not chase green until the harness is ported. Base failure list: `/tmp/base_attack_fails.txt`
  (may be gone — regenerate).
- **Known red at base and now:** `decl_grain_test.av:189` — whole-program `refs_index` read; own
  ticket.

---

## 6. The stopped agent's work (preserved, not lost)

Worktree `/Users/tristan/projects/tristanMatthias/avra-bd`, branch `L-buckets` at `2d8e6224`.
It made **uncommitted probe edits only**; nothing was pushed. The diff is saved at:

    /Users/tristan/projects/tristanMatthias/avra/.lead/avra-bd-probes.patch   (182 lines)

and the worktree has been **reverted clean** (`git checkout -- .`, 0 modified files). What it did:

- `packages/std-relation/src/db.av` — probe `leaf_holds`/`probe_leaf` tracing a mismatch.
- `packages/std-avrac/src/compiler/decl_rows.av` — `named_refs` → a program-wide `named_index`.
- `packages/std-avrac/src/compiler/workspace.av` — `Records`: `named_index`/`named_index_ready`
  replacing `named_refs`.
- `packages/std-io/src/io.av`, `packages/cli/src/commands/shared.av` — line-1 comment edits (probe).

Its diagnosis: *a bucket digest is a snapshot of what is minted so far* — read before writers
finish, so the dependency it records differs on every later run. The `named_index` idea (one
program-wide index instead of per-window `named_refs`) is a candidate fix for blocker #1; it was
never finished or measured. **Start there if you want to continue.**

---

## 7. Next steps, in order

| # | Slice | Effect |
|---|---|---|
| 1 | Complete/order-independent `Named` bucket content; `hash_asked` for `@family` leaves | removes `bodies 15.5 s` — the last big number |
| 2 | Stable declaration identity → delete `@scoped_by` | turns decl-grain answers into restore hits; the only route to ≤300 ms |
| 3 | Infer durability; refuse unprovable `@lasting` | makes #2's mistakes impossible; catches today's two |
| 4 | Fix `manifest_in`/`file_text` staged-text defect | unblocks `AVRA_SOUND_CHECK` over warm stores |
| 5 | `@family` 20 → 0; delete `db.av` + `kept_settle.av` | one law, one store, ~1 500 lines |
| 6 | `L-attacks` (`1bbb9257`, partial): finish `cache_attacks` port; fix `kg`, `dt`, lib-vs-app | proof the store is sound |
| 7 | Gate → `hd-clean` → main via `sh tools/work land` | landing |
| 8 | Close PR #1371, ~1 877 origin branches, ~284 worktrees | cleanup |

Not touched this campaign: the `closes` audit (`close()` / `Relation.close`), `make hooks-released`,
`make turn-memory-attack`.

---

## 8. Branches and worktrees

Campaign branches (pushed; only `hold-out` matters):

```
hold-out          2d8e6224  ← the line (origin/hold-out)
hold-integrated   1283a655  ← stale; retarget to 2d8e6224 or delete
L-buckets         2d8e6224  ← stopped agent's branch, no commits, probes saved as patch
L-names2          ffacda97  merged
L-hold3           a6c3aff8  merged
L-lowercost       537cf531  merged
L-record          2b2fc0df  merged
L-typed-const     902ccc94  merged
L-driver2         f9726b74  merged
L-syntax          bdf34b60  merged
L-attacks         1bbb9257  NOT merged (cache_attacks port, partial)
L-names           28308899  superseded by L-names2
```

Worktrees: **284** on this machine. Campaign ones: `avra-ho` (integration, `ho-base`),
`avra-ho-names`, `avra-ho-del`, `avra-lc`, `avra-bd`, `avra-id`, `avra-hd-attacks`,
`/tmp/ho-908` (scratch, deletable).

---

## 9. How to rebuild and measure

```sh
# build — never `make avra` on a lane; `try` keeps the standing builder warm
LLVM_PREFIX=/opt/homebrew/opt/llvm AVRA_CACHE_DIR=/tmp/store AVRA_BUILD_SLOTS=1 \
  sh tools/watch.sh 8000 make try

# suite — AVRA_SOUND_CHECK is required, or you get a spurious staged-text defect
LLVM_PREFIX=/opt/homebrew/opt/llvm AVRA_SOUND_CHECK=1 AVRA_CACHE_DIR=/tmp/store \
  ./build/avra-try test packages/std-avrac/src/compiler      # 1813/1814, one known red

# warm measurement — isolated store, idle machine
export AVRA_CACHE_DIR=/tmp/measure
find . -name .avra-cache -type d -prune -exec find {} -mindepth 1 -delete \;
./build/avra-try check --time packages/cli     # cold
./build/avra-try check --time packages/cli     # unchanged (cache hit)
# add one comment line to packages/cli/src/commands/shared.av, then:
./build/avra-try check --time packages/cli     # edited — MUST be status 0, 0 errors
```

Script `/tmp/ho_warm3.sh` does exactly this and restores the file (may be gone — it is in the
session record and easy to rewrite).

---

## 10. Machine constraints that shape all of this

- **DISK IS CRITICAL: 4.4 GiB free of 926 GiB.** Two agents died on ENOSPC today. Before any long
  run, sweep: `~/.avra/cache/prints`, `/tmp/*store*`, each lane's `.avra-cache`. Never `rm -rf`.
- **One heavy process at a time** (watchdog lock). Numbers taken under load mean nothing — warm
  readings swing 58–105 s for one tree.
- **A stale store lies.** A second binary on unchanged source can hit the first's cache. `rm -rf
  .avra-cache` before every run whose ANSWER is being compared. That is how the previous session's
  "0 errors" was fabricated.
- A probe must live OUTSIDE the tree (a file under a workspace with `avra.toml` above it checks
  nothing and says nothing).
