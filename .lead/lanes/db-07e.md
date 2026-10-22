# DB 07e lane — delete the hold/attempts

Base: `origin/db-slice` @ `ec276593` (S4c, the by-name load).
Worktree: `/Users/tristan/projects/tristanMatthias/avra-db07e` (branch `db-07e`).
Plan: `.lead/DB_DELETION_PLAN.md` (07e) §2 order.

## Log

- 2026-10-15 start: worktree created off `origin/db-slice` @ `ec276593`. Reading derive.av/record.av/workspace.av for the deletion sites.
- Base compiler built: `main`'s `build/avra` (built-from `b0d98c49`, db-slice's merge-base) into `build/avra`; `make try` OK. The newer `daaa335f` binary REFUSES db-slice's `std-http` (the `within -> TimedOut` flip, #710), so the pre-flip builder is required.
- Base `cache-attacks-a` (`sh tools/cache_attacks.sh`, build/avra): **1 failed** — `lk: and put back ... wanted built, got hit` (`tools/cache_attacks.sh:563`), pre-existing on db-slice; 449 builds, 145 under a hold. (The full `make cache-attacks` also runs the b-shard, whose `fn-add-attack` reds the landing plan records for db-slice; not re-run.)
- **STEP 1 attempted, per plan §2.** (a) Delete the whole `holding` hold block (lines 639–665: `if at.hold { ... }`, incl. the home_moved re-ask) and the `settle_holds` call. `make try` builds. cache-attacks: **27 failed**. (b) Isolate: restore the block, delete ONLY `self.settle_holds(store, at.want)` (:664). cache-attacks: **20 failed** (19 new + the pre-existing `lk`). Reverted; tree clean at `ec276593`.
- The 19 new failures are the read law: `pk` (a moved embedded text, its reader not read), `rp` (a held file parsed to judge a pending read), `mh` x5 (stale signature rows held when they must be read), `nd` x3, `ee` x2, `rx`, `zp` (warm check parsed 4 wanted 2), `bw`, `gc`, `d`, and a leaf hold-count. All trace to work only `settle_holds` does.
- **Why it breaks, exactly.** db-slice's S4c (`ec276593`) replaced only `holding`'s eager `for m in held_modules { load_interface }` with on-demand `bare_interface` + selective `load_interface` + `hold_only`. It KEPT `settle_holds`. `settle_holds` is still load-bearing: it consumes the seeding that `meet_file` (record.av:915–939) writes only on the `load_interface` path (`hold_asked`, `read_with`, `read_seeds` from `forced_runs`), runs `read_unkept(resolve_pending_reads())`, and walks `forced_runs` for compile-time-run reads. For a held module S4c calls `hold_only` and never `meet_file`, so nothing else seeds those reads. Deleting `settle_holds` — even just its call — drops that work and the cache answers from stale rows.
- The plan's §5 prerequisites for 07e are **absent on db-slice**: S2 `CancelBits` (0 hits), S3 `ReadFound`/`Consumed` References split (no `ReadFound`), S5 `Family.Placed`/`Resolved`/`Folded` per declaration (no `Placed`). Only S4a/S4b/S4c are here. So 07e cannot be built on this base: step 1 needs a 07d that MOVES `settle_holds`'s read-seeding and pending-read resolution into by-name loading, which S4c did not do.
- STOPPED per the lane rule; no attack or law weakened. Branch `db-07e` left at `ec276593`, nothing pushed (pre-flight not green).

## Report

head `db-07e` @ `ec276593` — no commits, not pushed (pre-flight not green).
Attempted plan §2 **step 1** (`settle_holds` + `holding`'s hold block).
Receipt of the break: base cache-attacks = 1 failed (pre-existing `lk`); delete `settle_holds` call alone = **20 failed** (19 new); delete the whole hold block too = **27 failed**.
The 19 new are the read law — `pk`/`rp`/`mh`×5/`nd`×3/`ee`×2/`rx`/`zp`/`bw`/`gc`/`d`/leaf-hold — every one a reader not read, or stale rows held.
Cause: db-slice's S4c replaced only the eager `load_interface` loop; it kept `settle_holds`, which still consumes `meet_file`'s seeding (`hold_asked`/`read_with`/`read_seeds` from `forced_runs`), `resolve_pending_reads`, and the forced-run worklist. A held module takes `hold_only`, never `meet_file`, so nothing else seeds those reads.
Blocker: the plan's §5 prerequisites are absent — S2 `CancelBits`, S3 `ReadFound` (References split), S5 `Placed`/`Resolved`/`Folded`; only S4a/S4b/S4c are on db-slice.
So 07e needs a 07d that MOVES `settle_holds`'s seeding + pending-read resolution into by-name loading; S4c did not. STOPPED, no attack/law weakened.
