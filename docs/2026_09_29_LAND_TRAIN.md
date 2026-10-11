# The land train — a speculative merge queue over `tools/land.sh`

> NOT BUILT. `tools/land.sh` and `tools/land_train.sh` are not in the
> tree; the landing mechanism is GitHub's native merge queue plus
> `tools/work`. The committed single source is
> `docs/2026_10_11_THE_PIPELINE.md`.

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
candidates are dispatched **in parallel**, up to
`AVRA_LAND_TRAIN_SLOTS` (default 2) per Sprite (least-loaded first,
slots filled level by level so a wave spreads before it stacks), running the same portable gate
subset land.sh runs today. `Ck`'s tree is really `main + b1..bk`, not
a diff against `Ck-1` — nothing here assumes `Ck-1` passed before `Ck`
is built; that assumption is only made when deciding what to *believe*
about `Ck`'s verdict (see below), never when constructing it. This is
what makes the concurrency sound: `C7` does not wait for `C1..C6` to
finish before it starts.

All N run as one WAVE, bounded by the pool size (a Sprite free's up,
the next queued candidate starts on it — the same job-slot shape
`land.sh`'s own `job_launch`/`job_wait_all` already use, one pool per
wave). The wave is read in **candidate order** once every job in it
has answered: the longest green PREFIX `C1..Ck` is the wave's verdict.
If every candidate is green, `Ck` (=`CN`) is the fast-forward target
and the train is done. If `Cj` is the first failure, `bj` is dropped
WITH land.sh's own verdict words (the same report a session polling
`land.sh bj` would read), and a NEW wave is built for the tail:
`Cj' = (good prefix) + b(j+1)`, `Cj+1' = Cj' + b(j+2)`, ... up to
`CN'`, dispatched concurrently again. This repeats wave over wave
until a wave is entirely green (fast-forward to its last candidate) or
empty (nothing left to land). Deciding wave-by-wave rather than
cutting a wave short the instant a prefix is known costs at most one
extra round of Sprite time per failure — simple, and it means a
verdict is never read from a candidate whose SIBLINGS in the same
wave haven't finished, which would otherwise need cancelling
in-flight remote jobs to get the fine-grained version right.

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

A watchdog wraps every remote step — land.sh's OWN `watched()`, never
a second one: a hard wall-clock cap (`AVRA_LAND_TRAIN_CAP_S`, default
generous enough for a cold bootstrap) AND a no-progress window
(`AVRA_LAND_TRAIN_QUIET_S`, checked against a heartbeat the candidate
body itself prints — `land-train: progress N`, `train_progress`'s own
twin of `linux_gate_step`'s `linux_progress`) — either one firing
kills the remote job (`kill_tree`) and tells the Sprite to stop that
run (`stop_remote`), and the candidate retries on another Sprite
before being filed as a tool failure. A Sprite that fails before
printing its own start marker (`sprite-build.sh`'s existing
convention, `land-train: body started`) was never reached in the
first place — same tell `linux_gate_step` already uses for
`land-linux: body started`.

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

BOTH FACTS WERE STILL TRUE, DIFFERENTLY, DURING STAGE 1's REAL PROOF
RUN (below): `avra-idioms-pay` never answered a single `sprite exec`
all session — a standing connectivity problem, not a one-off timeout.
`avra-comptime` answered a plain `exec` instantly throughout, but its
FILE PUSH (`sprite file push`, tools/sprite-build.sh's own tarball
transfer) failed three attempts running with "context deadline
exceeded," and `ps` named the cause while the proof was still
red: another session's REAL landing (`avra-docs`) had been running its
own Linux gate against the SAME `avra-comptime` for over 35 minutes,
via a plain `tools/sprite-build.sh` call with no serialization of its
own — the doc-comment at the top of that file says so outright
("nothing here serialises concurrent callers"). So the landing pool's
own steady-state load is not zero: a Sprite named "idle" by `uptime`
a minute ago can be mid-push for a real landing the next, and a POOL
OF TWO SERVES AT MOST TWO CONCURRENT LANDINGS TODAY BEFORE ANY TRAIN
EXISTS — the train's own appetite (up to N candidates wanting a
Sprite each) is additional demand on top of that, not instead of it.
THIS IS A REAL ARGUMENT FOR GROWING THE POOL, not just a nuisance the
proof ran into: two Sprites already contend under ordinary traffic,
and a train's whole value proposition (many candidates verified at
once) is throttled to the pool's size regardless of how parallel the
scheduler is.

Proposed additions, from `sprite list` against SPRITES.md's table (an
assigned pool is that session's; only spares are candidates):
- `avra-unions-p2` / `avra-unions-p2-b` — present but NOT in
  SPRITES.md's table at all (undocumented, or newly provisioned).
  Both read idle just now (load < 1, ~7 GB free). Worth asking their
  owner directly before the train claims them — an undocumented
  Sprite may simply be between uses, not spare. NOT wired into the
  code at all: `land_pool()` (below) answers only main's own list.
- `avra-bench` is PERF's, reserved for quiet census runs — a train
  candidate's build would add noise to exactly the measurements that
  Sprite exists to keep clean. Not proposed.
- Every other listed Sprite (avra-phase-c, avra-sq-ffi, avra-dev,
  avra-reuse, avra-phase-i) is assigned to a live session's own work;
  the train must not schedule onto them without that session's
  say-so, load or no load — the failure mode ("no session runs
  ad-hoc work here") is a policy statement, not a load threshold.

RETRACTED IN PART BY THE TIME OF THE REBASE: `avra-phase-d` and
`avra-cores` are no longer proposals — IDIOMS' own landed work
(`land_sprite_pool="avra-idioms-pay avra-comptime avra-phase-d
avra-cores"`, real main) already widened the pool to four while this
was being built. The train claims no Sprite of its own: `pool_list`
answers `AVRA_LAND_SPRITE` when set, else `sh land.sh --call
land_pool` — a one-line accessor for `land_sprite_pool` added beside
`sprites_by_load`, so growing the pool from here on is a ONE-LINE
change to that ONE variable in land.sh, read by the Linux gate and
the train alike, never a second list to keep in sync.

SUPERSEDED FOR THE TRAIN: unset, `pool_list` now answers `tools/sp
--pool` — every awake Sprite but `avra-bench` and `web-terminal`, and
sleepers only while the org's cap of 10 running has room — asked once
per run, falling back to `land_pool` when the Sprites API answers
nothing. A lease is one of `sp`'s own slots (`sp --lease <n> <pid>
<sprites…>`, under `/tmp/avra-sp-slots`), so train candidates and `sp`
jobs count against one per-Sprite budget. Each candidate syncs into its
own remote tree: sprite-build.sh keys the tree by the candidate
worktree's name, which carries the run, wave and candidate. A
candidate's step logs live in its own temporary directory on the
Sprite, never a fixed `/tmp` name two candidates would share.

PROGRESS IS WORK, NOT ONLY WORDS: a package suite prints nothing while it
builds its suite binary — measured on a shared Sprite, `avra test
packages/std-avrac` said one line after eight minutes and then nothing
for fourteen more, line-buffered, and wrote no cache file in that time. A
byte count alone called that wedged at the 420 s quiet window. The
heartbeat now also reports the CPU ticks the body's process tree has
spent (`/proc/<pid>/stat`, the heartbeat's own subtree excluded), and
`train_progress` reads both, plus every line that is NOT a heartbeat: a
busy quiet step keeps moving, a blocked one spends nothing and is cut
off. A heartbeat line alone never counted as progress should — it
only says the heartbeat beat, so counting it (as the line count did)
kept a wedged step alive for the whole cap. Suites run under `stdbuf -oL`
so the lines they do print arrive as they are said.

Placement is main's own `sprites_by_load` — load per core, then free
memory, unreachable last — never a scheme of this file's own.
`claim_sprite` re-ranks the pool at most every
`AVRA_LAND_TRAIN_PROBE_INTERVAL_S` (default 10s) while it waits for a
lease, a cache added after a real measurement during this rebase (see
"a real load problem", staged build, below) — the FREENESS check (a
lease directory) is still read fresh every single iteration, never
cached, since a Sprite going from free to claimed between two ranking
refreshes is the exact race the lease exists to close. No explicit
memory floor of this file's own remains: `sprites_by_load`'s own
ordering already reads `MemAvailable` and sorts accordingly, and
duplicating a threshold on top of a ranking that already accounts for
it would be a second, driftable copy of the same judgment.

## Expected wall time

MEASURED, not estimated — a scratch clone of this repo, `main` reset
to `c27db18`, three real already-landed commits played as three
queued branches (`land-proof-1/2/3` = `b0fd739`, `41c6515`,
`a702869`), verified for real by `tools/land_train.sh --dry-run`
against a real Sprite (`avra-unions-p2`, a spare, idle Sprite outside
the documented landing pool — both pool members were degraded when
this was run; see "The Sprite pool" above). Six real attempts total,
kept because each answered a different question:

- **Cold Sprite, this exact compiler hash never cached:**
  `sprite-build.sh`'s own pre-command `advance_and_cache` bootstraps
  from nothing before the timed run even starts — the FIRST proof run
  (candidate 1 alone) took **5:25 wall**, of which the timed command
  itself was only 55.2s; the other ~4:30 was the cold bootstrap plus
  the local tar/push. This is the one-time cost of a Sprite that has
  never built this source before.
- **Warm Sprite, compiler hash cached, candidate genuinely red:** a
  real, then-latent bug (below) failed `fmt-lossless` after 55s of
  `objects`+`libs` — **2:08 wall** total, most of it now the
  tar/push/sync (~1:10) rather than any build.
- **Warm Sprite, all green — the number that matters:** after fixing
  the bug, one candidate's FULL portable gate set, per step:
  `objects` 52s, `libs` 4s, `fmt-lossless` 27s, `seed-check` 67s,
  `cache-attacks` 73s — **223s (3:43) timed**, plus ~1:10 of
  tar/push/sync overhead — **~4:50 wall for one candidate on a warm
  Sprite**, `land-proof-1` alone (no affected packages, so idioms and
  the suites loop were no-ops for it — a candidate that touches real
  packages pays more there, not less elsewhere).

So: **cold-Sprite tax ~4:30, one-time per (Sprite, compiler-hash)
pair; warm per-candidate cost ~5 minutes** for a small, package-light
change, dominated by `seed-check`'s link and `cache-attacks`'
fixtures, not by the compiler build itself (`objects`+`libs` together
were under a minute). A candidate touching more packages adds its own
suites on top, run in parallel inside the SAME Sprite call the way
`linux_gate_step` already does.

The Mac finalization pass (the two-generation compile plus the
Mac-only gates) is UNMEASURED here on purpose — the rules for this
build were "don't run the compiler's heavy builds on the Mac; use
Sprites," so this number is carried over from `land.sh`'s own,
already-measured serial run: **~7-16 minutes**, unchanged, because it
is the exact same steps over the exact same tree, run once instead of
once per branch.

**N=5, one Sprite pool of 2, all green, each candidate ~5 min warm:**
five candidates queue two at a time — three waves — **~15 min of
Sprite time**, plus the one Mac pass (~10 min) = **~25 min**, versus
5 x (7-16 min) = 35-80 min serial today. At a 5-Sprite pool: one wave,
~5 min, then ~10 min Mac = **~15 min**.

**N=10, pool of 2:** five waves, **~25 min** of Sprite time, plus one
~10 min Mac pass = **~35 min**, versus 70-160 min serial. At a
4-Sprite pool (adding the two idle unions Sprites, if their owner
agrees): three waves, ~15 min, plus Mac = **~25 min**.

**The cold-Sprite tax matters more than N** once a pool member is
genuinely new to a tree: growing the pool with a Sprite that has
never built this compiler pays ~4:30 on its FIRST candidate,
one-time, then joins the warm ~5-minute rate — worth knowing before
reading a fresh Sprite's first landing as evidence the pool addition
was a bad idea.

RETRACTED, TRACED, AND RESOLVED — not an ordering artifact, not a
cache-key gap. The entry above claimed candidate 2's diff over
candidate 1 "touched only `packages/std-relation/src/tests/*`," read
from a `git show --stat -1 e3fa5c9 | tail -6` during the original
proof session — a `tail` that cut the diff's OWN interesting lines,
exactly the law this repo's own CLAUDE.md names ("A PROBE THAT
TRUNCATES ITS OWN OUTPUT REPORTS THE ABSENCE OF WHAT IT CUT"). Traced
for real: `sprite-build.sh`'s own `compiler_source_paths` +
`compiler_hash` functions, run byte-for-byte against two real
worktrees (`b0fd739` and `41c6515`, i.e. candidate 1 and candidate 2's
own trees) reproduce the EXACT two hashes seen live
(`dd484e4f…` and `77c5cfc6…`) — confirming the two candidates really
do have different compiler-hash identities, not a race. Diffing the
two hash lists file-by-file names it precisely: `e3fa5c9`'s own full
diff (not its last 6 stat lines) changes
`packages/std-relation/src/db.av` and `.../rows.av` — real,
non-test source ("a Db's owner names its running query; a frame's
repeat read is told once") — alongside the test files that were all
`tail -6` had left visible. `std-relation` is inside `cli`'s own
`use`-graph closure (the DB/workspace unification work), so
`compiler_source_paths` was RIGHT to hash it, and the fresh build for
candidate 2 was the cache answering correctly to a genuine source
change, not a defect. The general lesson survives the retraction: a
ladder's later candidates are NOT guaranteed as cheap as its warmed
first ONLY WHEN one of them touches a file inside the compiler's own
`use`-graph closure — which is exactly when `land.sh`'s own serial
pipeline would ALSO pay for a second build (`compiler_reached`,
`affected_packages.sh`'s own compiler-changed case) — so this is the
train correctly inheriting an existing cost, never a new one it
invented.

**A failure mid-train costs a re-wave**, not a re-run of everything
before it: dropping `bj` and rebuilding `Cj'..CN'` re-dispatches only
the tail, on top of the already-known-good prefix's merge (which is
not rebuilt — it is the SAME tree bj was merged onto, minus bj). The
worst case (every candidate but the first is a culprit, one at a time)
degrades toward the serial bound; the common case (zero or one bad
branch in a batch) stays close to the numbers above — and the real
run above IS that mid-train-failure case (candidate 1 failed real
fmt-lossless, got fixed, re-ran green), so the "drop and re-verify"
path is not just fixture-tested, it happened for real while proving
this document.

A REAL BUG WAS THE PAYLOAD OF THIS MEASUREMENT, WHICH IS THE POINT OF
MEASURING RATHER THAN ASSUMING: `tools/fmt_lossless.sh`'s `shift ||
true` is an ordinary catchable failure under bash (macOS's `/bin/sh`)
and a FATAL, uncatchable one under dash (Ubuntu's `/bin/sh`, and so
every Sprite's) — `make fmt-lossless` calls it with zero arguments,
so every real Linux run died at that line, every time, until fixed
(`[ "$#" -gt 0 ] && shift`). Nothing in the EXISTING Linux gate had
ever run `make fmt-lossless` on a Sprite before this proof did, so the
bug was real, latent, and would have bitten the first production use
of a wider Linux gate regardless of who built it.

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
