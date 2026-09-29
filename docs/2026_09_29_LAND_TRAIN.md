# The land train — a speculative merge queue over `tools/land.sh`

## The problem

`tools/land.sh <branch>` is fail-closed and correct, and strictly
serial: one FIFO ticket queue, one lock, one merge, one build (twice,
when the compiler moved), one round of every gate. About 7-16 minutes
per branch. Ten queued branches is hours, all of it spent waiting for
a lock that only ever runs ONE branch's checks at a time on ONE Mac.

`land.sh` already has a batch mode (`main_batch`, `AVRA_LAND_ABSORB=1`):
whoever holds the lock absorbs every branch queued behind it and
checks them together, in ONE integration, bisecting a failure out by
dropping-by-file or by half. That collapses N *simultaneously queued*
branches into one build — but it is still one build, still serial, and
it still runs the whole gate set locally before it can tell you
anything. A batch of 10 still pays for the slowest single gate (the
Linux suite run, or a full second compile) once per *bisection attempt*,
on one machine.

The train changes what "waiting behind the lock" means. Instead of one
process building candidates one at a time, it builds and verifies every
prefix candidate **concurrently**, each on its own Sprite, and only
takes the lock for the few seconds the real fast-forward needs.

## The shape

The queue is the same FIFO ticket order `land.sh` already keeps
(`/tmp/avra-land.lock/tickets`). Given branches `b1, b2, ..., bN` in
that order, the train builds candidates:

    C1 = main + b1
    C2 = main + b1 + b2
    C3 = main + b1 + b2 + b3
    ...
    Ck = main + b1 + ... + bk

Each `Ck` is a real merge (`merge_ref_in`, land.sh's own function,
reused) into its own throwaway branch `land/train-C<k>-<run-id>`, in
its own worktree, so ten candidates never share a tree. All N
candidates are dispatched **in parallel**, one Sprite each (round-robin
over the pool, least-loaded first), running the same portable gate
subset land.sh runs today. `Ck`'s tree is really `main + b1..bk`, not
a diff against `Ck-1` — nothing here assumes `Ck-1` passed before `Ck`
is built; that assumption is only made when deciding what to *believe*
about `Ck`'s verdict (see below), never when constructing it. This is
what makes the concurrency sound: `C7` does not wait for `C1..C6` to
finish before it starts.

Verdicts arrive out of order (Sprites differ in speed and warmth). The
train reads them in **candidate order**: it looks for the longest
green PREFIX `C1..Ck` — every one of `C1..Ck` green — the moment enough
verdicts are in to know it, and does not wait for `Ck+1..CN` before
fast-forwarding to `Ck`, EXCEPT that a still-running `Cj` for `j <= k`
blocks the decision until it answers (you cannot call a prefix green
while one of its members is still unknown). If `Cj` (the first failure
in order) turns red, every `Cj+1..CN` is dropped and **rebuilt without
`bj`**: new candidates `Cj' = (good prefix) + b(j+1)`, `Cj+1' = ... +
b(j+2)`, etc., re-dispatched in parallel again. This repeats until the
tail is empty or entirely green. `bj` is reported with land.sh's own
verdict words, so a session polling `land.sh bj` sees exactly what it
sees today.

This is bors/marge-bot's "batch build, bisect on failure, restart the
tail" shape, with the bisection width turned all the way up (every
candidate its own build) because concurrency is cheap here (a Sprite
per candidate) where it is expensive in `land.sh`'s local bisection
(one Mac, one build per attempt).

## Failure handling

Two failure kinds, told apart exactly as `land.sh` already tells them
apart (`tool_failed` vs. an ordinary red step):

- **A branch's own failure** (a red test, a lint, a merge conflict
  outside the seed): `bj` is dropped, reported with the real log tail,
  and the tail re-verifies without it. This is a VERDICT, not a retry.
- **A tool failure** (a Sprite unreachable, a sync that died, a
  timeout with no progress): the candidate is retried on a different
  Sprite from the pool, at most twice, before the whole candidate is
  itself reported as a tool failure (never blamed on the branch it
  carries) and the train stops rather than guessing — the same
  contract `land.sh`'s own `tool_failed` already gives a caller reading
  its scratch dir.

A watchdog wraps every remote step: a hard wall-clock timeout (bounded
by `AVRA_TRAIN_STEP_TIMEOUT`, default generous enough for a cold
bootstrap) AND a no-progress check (the remote log's mtime must move
every `AVRA_TRAIN_HEARTBEAT` seconds once the command has started) —
either one firing kills the remote job, frees the Sprite, and files a
tool failure for that attempt. A Sprite that fails before printing its
own start marker (`sprite-build.sh`'s existing convention, `land-linux:
body started`) was never reached in the first place — same tell
`linux_gate_step` already uses.

## Which gates run where, and why

Read against `tools/land.sh` and `tools/sprite-build.sh` directly
(not assumed):

**Runs per candidate, on its Sprite (Linux-native, already how the
existing Linux gate works):**
- the compiler build itself — `make bootstrap` / `make objects` / `make
  -o avra libs`, exactly `linux_gate_step`'s own body, fixed-point
  cached per Sprite by `sprite-build.sh`'s content-hash cache
- every affected package's test suite (`build/avra test packages/X`)
- `idioms_step` (`build/avra check --baseline tools/idioms.baseline`)
  — pure compiler + text file, no OS dependency
- `fmt-lossless` (`avra fmt --check`) — same
- `seed-check` / the seed policy (`make seed-check`, `make seed` on a
  miss) — same; a Sprite already runs this today via `make
  sprite-check`'s own fast path
- `cache-attacks` (`tools/cache_attacks.sh`) — pure `sh` + the compiler
  it just built, no macOS tool in its body

None of these five touch a macOS-only binary. `linux_gate_step` already
proves the first two run on a Sprite for a real landing today; the
train's per-candidate job is that same shape, widened to the other
three checks land.sh runs locally today, because "same gates, same
thresholds" means idioms/fmt/seed/cache-attacks do not get a free pass
just because they happen to run on the Mac now.

**Stays a Mac step, run ONCE on the train's winning head, not per
candidate:**
- **the speed gate.** `speed_one_run` shells out to `/usr/bin/time -l`
  and reads `instructions retired` / `peak memory footprint` from its
  output — a BSD/macOS-only format (the code says so directly:
  `tool_failed ".../usr/bin/time -l\` is macOS-only"`). Beyond the
  tool: `tools/speed.baseline` is one column of historical numbers,
  and every one of them so far was measured on THIS Mac's arm64 core.
  A Sprite is x86_64 Linux — an instruction count there is not the
  same currency as an instruction count here, even holding the source
  fixed, because the ISA differs. The task's own hint — "it's a
  Linux-safe measurement if base and candidate are on the SAME
  Sprite" — is true and does not rescue the EXISTING baseline file:
  it would make a NEW, Sprite-relative baseline sound, comparable
  landing to landing on Linux, but mixing it into `tools/speed.baseline`
  would silently compare two different machines' instruction counts
  under one column. So the speed gate keeps running where its history
  lives: once, on the Mac, on the train's final combined candidate,
  right before the fast-forward — identical to what a serial `land.sh`
  run does today. (A Sprite-relative speed baseline, measured
  per-candidate on whichever Sprite ran it, is a real future gate —
  it answers a different question, "did THIS change regress on
  Linux", and wants its own file. Left for later; noted in "what's
  left".)
- **the codesign step inside `build_generation`** (`codesign -f -s -
  build/avra`) — meaningless on Linux, and only the Mac-built product
  ever becomes `main`'s own `build/avra`. The train's per-candidate
  Sprite build produces a Linux `build/avra` that only ever proves the
  suites there; it is never the artifact that reaches `main`.
- **the actual fast-forward and `refresh_main_compiler`** — git
  plumbing against the real `main` worktree, which only exists on the
  Mac, and the compiler binary `main`'s own tree needs afterward is a
  macOS binary. This always was the one step no Sprite could do.
- **the warm-reuse gate.** Nothing in `warm_gate_step` calls a
  macOS-only tool (it is `cmp`/`sed`/`grep` plus the compiler), so it
  COULD run on a Sprite per candidate. It is kept as a once-only Mac
  step instead for a narrower reason: it measures the compiler's OWN
  cache behavior (`held N/M`) against `tools/land.baseline`'s
  `warm_held_floor`, a single ratcheted number with the same
  cross-machine-identity problem the speed gate has once you look
  closely — a Sprite's fresh clone starts cold every time a candidate
  changes (a new merge is a new tree), so "warm" there would mean
  "warm within one candidate's own two checks," not comparable to the
  floor recorded from Mac runs. Run once, on the Mac, on the winning
  head, exactly as today.

**Everything else in `check_phase`/`local_checks`/`run_checks`** —
`build_generation`'s two compiles, `run_checks`'s job pool, the
tools-only fast paths (`gate_scripts_step`, `diff_touches`) — is
subsumed by the per-candidate Sprite run for the Linux-portable checks,
and by the single Mac finalization pass for the codesign'd product and
the two Mac-only gates. The Mac finalization pass is a real,
compiler-changed `land.sh`-style local run (`build_generation` x2,
`run_checks` minus the Linux gate it already ran, speed gate, warm
gate, cache-attacks if not already trusted from the Sprite pass) over
the WINNING combined head alone — one Mac build for the whole train,
not one per candidate, which is exactly where the wall-clock savings
come from: the two-generation compile and the Mac-only gates were
always the expensive, unavoidably-serial tail; everything upstream of
them is now parallel.

## The Sprite pool

Today: `avra-idioms-pay`, `avra-comptime` (SPRITES.md's landing pool;
"no session runs ad-hoc work here" — the train IS that pool's work,
not ad-hoc use of it).

Checked directly (`sprite -s <name> exec -- sh -c 'nproc; MemAvailable;
uptime'`) while writing this doc: `avra-comptime` idle (load ~0.6,
7.7 GB free of 8). `avra-idioms-pay` did not answer inside 20s
(network timeout, not a load reading) — the train's Sprite-selection
step must treat "did not answer" as a tool failure and fall back, the
same as `linux_gate_step` already does for an unreachable Sprite.

Proposed additions, from `sprite list` against SPRITES.md's table (an
assigned pool is that session's; only spares are candidates):
- `avra-unions-p2` / `avra-unions-p2-b` — present but NOT in
  SPRITES.md's table at all (undocumented, or newly provisioned).
  Both read idle just now (load < 1, ~7 GB free). Worth asking their
  owner directly before the train claims them — an undocumented
  Sprite may simply be between uses, not spare.
- `avra-bench` is PERF's, reserved for quiet census runs — a train
  candidate's build would add noise to exactly the measurements that
  Sprite exists to keep clean. Not proposed.
- Every other listed Sprite (avra-phase-c, avra-sq-ffi, avra-phase-d,
  avra-cores, avra-dev, avra-reuse, avra-phase-i) is assigned to a
  live session's own work; the train must not schedule onto them
  without that session's say-so, load or no load — the failure mode
  ("no session runs ad-hoc work here") is a policy statement, not a
  load threshold.

So: build and prove the train against the CURRENT pool
(`avra-idioms-pay`, `avra-comptime`), and treat pool growth as a
config change (`AVRA_LAND_TRAIN_SPRITES`, space-separated, same
convention `AVRA_LAND_SPRITE` already uses) — not a code change —
once whoever owns a spare Sprite says it can join.

Placement: least-loaded first (load average per core, then free
memory — `MemAvailable`), read fresh before EVERY dispatch, never
cached across the train's own run (a Sprite that was idle when
candidate 1 started may be the one candidate 2 lands on, or may not).
A Sprite under 512 MB `MemAvailable` is skipped for new work (the task
brief: 8 cores / ~8 GB, and a cold bootstrap alone has been measured
elsewhere in this repo's own history spiking well past a naive guess —
better to queue a candidate behind a busy Sprite than to start a build
that gets OOM-killed and reads as a false red).

## Expected wall time

Per-candidate cost on a Sprite (from SPRITES.md's own numbers): a
COLD tree (any merge — which every candidate is, by construction)
bootstraps in ~4-5 minutes; the portable gate set (suites, idioms,
fmt-lossless, seed-check, cache-attacks) on a warm compiler is on the
order of 1-3 minutes more, depending on how many packages the merge
touches. Call it **6-9 minutes per candidate**, mostly bootstrap.

The Mac finalization pass (the two-generation compile plus the
Mac-only gates) is what `land.sh` measures today for one branch:
**~7-16 minutes**, unchanged, because it is unchanged — same steps,
same tree, run once instead of once-per-branch.

**N=5, one Sprite pool of 2, all green:** five candidates queue two at
a time on two Sprites — three waves — call it 3 x 8 min = ~24 min of
Sprite time, PLUS the one Mac finalization pass (~10 min) for the
final combined head. Total **~30-35 min**, wall clock, versus 5 x
(7-16 min) = 35-80 min serial today. The saving grows with the pool:
at 5 Sprites all 5 run at once, ~8 min, then ~10 min Mac = **~18 min**.

**N=10, pool of 2:** five waves of two, ~40 min of Sprite time, plus
one ~10 min Mac pass = **~50 min**, versus 70-160 min serial. At a
4-Sprite pool (adding the two idle unions Sprites, if their owner
agrees): three waves, ~27 min, plus Mac = **~37 min**.

**A failure mid-train costs a re-wave**, not a re-run of everything
before it: dropping `bj` and rebuilding `Cj'..CN'` re-dispatches only
the tail, on top of the already-known-good prefix's merge (which is
not rebuilt — it is the SAME tree bj was merged onto, minus bj). The
worst case (every candidate but the first is a culprit, one at a time)
degrades toward the serial bound; the common case (zero or one bad
branch in a batch) stays close to the numbers above.

These are estimates from the existing Linux-gate timings recorded in
this repo (SPRITES.md, land.sh's own comments) and the honest CLAUDE.md
law that a prediction is not a measurement — stage 1's real proof run
(below) records ACTUAL wall times from a real scratch clone and real
Sprites, and this section gets corrected against them once that run
completes, not left standing on the estimate alone.

## Staged build (each stage its own commit on `tools/land-train`)

1. **Parallel candidate verification + ordered fast-forward, dry-run
   only.** Builds the candidate ladder, dispatches to Sprites, reads
   verdicts, decides the green prefix, prints what it WOULD
   fast-forward to. Never touches real `main`. Proven against a
   SCRATCH CLONE of this repo (never the real remotes/worktrees),
   playing three already-landed real commits as three fake queued
   branches against an older `main` inside that clone, run for real
   on real Sprites, with real wall times recorded.
2. **Failure and rebase handling.** A red candidate drops its branch
   and rebuilds the tail; a tool failure retries on another Sprite
   before being reported as a tool failure. Fixtures, not a live
   Sprite, prove the ordering logic (stubbed `sprite-build.sh`, the
   same convention `land_test.sh` already uses for the Linux gate).
3. **Wire `land.sh`'s queue through the train.** The smallest possible
   diff to `land.sh` itself — `IDIOMS` is editing that file right now
   for timeouts and Sprite load-picking, so this stage stays additive
   and small (one opt-in env var branch in `main_batch`/the absorb
   path), never a restructuring.

`land_test.sh` stays green throughout; `land_train_test.sh` is new,
with fixtures for ordering, a mid-train failure, and a tool failure
retried on a different Sprite.

## What this does not change

- `sh tools/land.sh <branch>` is still the one command every session
  calls, unchanged in its own words and exit codes.
- The lock is still the FIFO ticket queue; the train serves the queue
  faster, it does not replace the queue.
- Real `main` moves exactly once per train run, by a fast-forward,
  exactly as it does today — the train changes how long it takes to
  KNOW a fast-forward is safe, never the mechanics of making one.
