# The pipeline — how work lands, on Sprites, through the gates

One document for the path from a branch to `main`: the merge queue and
how a change lands, Sprites, the deterministic watcher, the keepers and
gates, the speed budgets, the known traps, and what to run when a step
fails. It is written for a reader who has never seen this repo.

Everything here was read against the tree it describes — the Makefile,
`.github/workflows/`, and each `tools/` script named — never assembled
from an older note. Where an older document disagreed with the code, the
code is kept and the older claim is called out in "Provenance".

This doc is held by a keeper: `make pipeline-doc`
(`tools/pipeline_doc.py`) refuses if it names a `make` target or a
`tools/` path that does not exist. A command that is not in the tree is
therefore either fixed here or recorded as a known gap, never left to rot.

---

## 0. The one-paragraph model

`main` is protected and moves **only through GitHub's native merge
queue**, squash-merged, linear history, no direct pushes. A pull request
lands only when it is **mergeable, based on `main`, unstacked, and its
required check `test` is green**. There are three layers of proof:

1. **Dev — a Sprite.** Every heavy build and test runs on a remote
   Ubuntu microVM bound to the lane, warm between runs. This is the
   fast loop.
2. **PR — a fast floor.** A PR's own check is `fmt` on the files it
   changed plus `check` on the affected package closure. It builds no
   compiler, runs no keepers and runs no suites — it is a floor under
   the train, not the gate.
3. **The train — the gate.** When the queue advances, `checks.yml` runs
   the static keepers, the seed check, the cache attacks, the changed
   files' gate, the affected packages' suites (sharded), and the
   runtime latency gate where `runtime/` moved, over the **combination**
   of `main` and every queued PR ahead of it. A passing train lands it
   and everything ahead of it together (HEADGREEN).

`.github/workflows/checks.yml` is the one definition of what a train
does. `tools/work` is the one command surface a lane uses. Nothing in
`tools/work` writes `main`.

---

## 1. The merge queue: how a change lands

### The lane's day

From a fresh checkout:

    sh tools/work new <name>     # a worktree ../avra-<name> off main, and its Sprite

Work there, commit, then:

    sh tools/work land            # rebase, fmt-check, push, open PR, queue it

`land` does, in order: refuses to run on `main`; refuses a dirty tree;
`git fetch origin main`; `git rebase origin/main` (onto `main` only);
checks the changed `.av`'s formatting with the compiler the worktree
already holds; force-with-lease pushes; opens a PR against `main` if one
is not open; waits (up to ~5 minutes) for the PR's own `test` check to go
green; and enqueues it. It prints the PR URL.

### Entering the queue

Three independent mechanisms put a green PR in the queue, so a green PR
never sits unqueued:

- **`sh tools/work land`** pushes, opens the PR, waits for its own
  `test` check, and enqueues it directly (`enqueuePullRequest`).
- **`.github/workflows/auto-merge.yml`** runs on every `opened`,
  `ready_for_review`, `synchronize` and `reopened` event and runs
  `gh pr merge --auto --squash`. A draft is skipped, and a fork's PR is
  skipped (its token cannot enqueue).
- **`tools/pr_watcher.py`** enqueues a green, mergeable, unmerged PR
  under the queue cap — enabling auto-merge when it is not set, or
  enqueuing directly when it is (§3).

### What the queue does

The queue is GitHub's **native merge queue**, not a script. When the
front of the queue is ready, GitHub creates a `merge_group` ref holding
`main` plus that PR and every PR ahead of it, and runs `checks.yml` on
it. If the whole train passes, every PR on it merges together; if it
fails, the failing PR is dropped to its owner and the rest are
re-enqueued. One red PR drops the whole train, so a lane runs the
check's own scope before pushing.

`sh tools/work status` prints every open PR with its checks and its
queue position, then one line per lane and its Sprite. It also
re-enqueues a stuck entry on sight.

`sh tools/work wait <branch>` waits for one branch's PR to merge. **The
oracle is the PR's state, asked of `gh`, never `main`.** `main` only
moves when a train passes, so polling it to infer a landing waits on the
wrong clock — and it deadlocked the queue once. `MERGED` is the only
success; `CLOSED` is a failure. The deadline is `AVRA_WAIT_SECONDS`
(default 120 s) and the poll `AVRA_WAIT_POLL` (default 15 s).

`sh tools/queue_keeper.sh`, run by `.github/workflows/queue-keeper.yml`
every five minutes, keeps the queue moving without an agent: an entry
GitHub marked `UNMERGEABLE` leaves the queue; a PR conflicting with
`main` gets one "rebase onto `origin/main`" comment; a PR a failed train
dropped is told once per failure to land again; a PR whose head has
failed three trains is held as a **draft** with its failing lines on the
PR. **It never enqueues** — a workflow token cannot start the
`merge_group` workflow it would cause, so an entry it added would stall.
A PR enters the queue from its lane.

### The compiler in CI, and why a train is cheap

`checks.yml`'s `prepare` job decides what a run owes and gets a compiler
before anything else. The compiler is **keyed by its own source**
(`sh tools/compiler_paths.sh --key`), so a tree whose compiler is
`main`'s takes `main`'s binary and builds nothing. In order:

1. **Cache** (`.avra-cache` rides with the binary) — a hit is 0 s of
   build.
2. **Release asset** — `python3 tools/compiler_release.py fetch`, a
   binary `main` published under its own source digest. This exists
   because a GitHub cache is **scope-bound**: a run restores from its
   own branch and `main`, never a sibling's, and every train stands on
   its own `gh-readonly-queue/...` ref. A release asset crosses refs.
3. **Build twice** (`make avra` twice) — one `make avra` advances the
   compiler by one generation, so a compiler carrying a change must
   build the tree twice before it is the tree.
4. **Bootstrap** (`make bootstrap`) — when the nearest binary is too old
   to read the source (new syntax, or a new refusal about the compiler's
   own source), fall back to the committed seed.

Only a push to `main` saves the cache and publishes the release asset,
so a train never publishes a binary.

### What a PR runs vs what a train runs

| job | PR (`pull_request`) | train (`merge_group`) |
|---|---|---|
| `prepare` | plan + compiler only if `build=1` | plan + compiler + objects/libs |
| `keepers-a` / `keepers-b` | — | the static keepers, two halves on two runners |
| `seed-check` | — | the committed seed must compile HEAD |
| `gate` | `fmt` + idioms on the affected closure | the same, on the combination |
| `cache-attacks` | only if the diff reaches the store or the attacks | always |
| `flow-gate` | only if `runtime/` moved | only if `runtime/` moved |
| `suites` | — | affected packages, sharded (4 shards) |
| `test` | the aggregate required check | the aggregate required check |

A **plain PR pays no object build at all** — no `.av`, no package and no
compiler source changed means no compiler is built. A PR that changes
the store (or the attacks) runs the cache attacks too. The compiler
source paths are `sh tools/compiler_paths.sh` (the `cli` package plus
every `@std` package it reaches, the runtime, the backend, the seed and
the Makefile). Affected packages are `sh tools/affected_packages.sh`
(touched plus every dependent).

---

## 2. Sprites: the build machines

A **Sprite** is a persistent, stock-Ubuntu Linux microVM. It is not a
container and not a custom base image: the platform creates one from
nothing, the tree provisions it once (`tools/sprite-provision.sh` treats
it as stock Ubuntu), and it wakes warm rather than being recreated — the
wake is bounded at `AVRA_WAKE_S` (150 s). The Mac has one build slot and
a loaded desktop; the Sprites are where heavy work runs.

### Provisioning

    make sprite                   # sh tools/sprite-provision.sh; no-op on macOS

Installs the checks' toolchain (`.github/ci/packages.txt`, the same list
the CI image reads), points the tree's `${LLVM_PREFIX}` at the distro
LLVM, and leaves a working `build/avra`. Idempotent, so it is safe on
every start. A run started by `tools/sp` is provisioned by
`tools/sprite-remote.sh` instead.

    make sprite-check             # does a fresh Sprite need a build?

The seed path: `bootstrap/seed.sources` records a hash of every input
the build reads. When the tree **is** the seed's source, a fresh Sprite
needs no build; when the tree has moved, it takes one. `make seed`
refreshes the seed (and `seed.sources`), restoring the fast path.
`make recover` links the seed into a compiler (~20 s, no build);
`make bootstrap` recovers and then rebuilds from source twice (gen-1
from the seed, gen-2 from gen-1). The seed is refreshed on a cadence and
whenever it can no longer compile HEAD — never on every landing, since a
per-landing refresh conflicts every other branch.

### One Sprite per lane

`sh tools/work new <name>` claims a free Sprite and binds it to the
worktree (recorded in the worktree's own git dir, `avra-sprite`). A
Sprite belongs to one worktree until `sh tools/work done`. The pool is
`sprite list` minus `AVRA_SP_EXCLUDE` (default `web-terminal
avra-bench`), or `AVRA_SPRITES` when set.

    sh tools/work bind [<sprite>]   # give this worktree a Sprite, or move it
    sh tools/work sprites [--fix]   # every Sprite at a glance; --fix repairs one
    sh tools/work done              # remove this lane, end its run, free its Sprite

`--fix` repairs a Sprite that is silent or unprovisioned (re-provisions
it and wakes it).

### Running

    sh tools/work run <cmd>
    sh tools/work run --for <minutes> <cmd>

`run` rsyncs the worktree to the lane's Sprite and proves the Sprite
holds **exactly** this tree (every path's hash must match, or it refuses
with `SPRITE — sync:` and exit 75), keeps that tree's compiler built
there (warm after the first run), then starts the command under a
supervisor and follows it to its exit status. **One run per Sprite.** A
second `run` answers 76 until the first ends. The default bound is 15
minutes; `--for` raises it. A dropped connection does **not** end the
run — the supervisor holds the Sprite awake and `run` reattaches from
the byte it stood at. `Ctrl-C` and `sh tools/work stop` end it.

Exit codes from `run` (the run answers the command's status, or one of):

| code | meaning |
|---|---|
| 0 | the command succeeded |
| 75 | `SPRITE` — the Sprite did not answer |
| 74 | `CONNECTION` — the provider did not answer, or the tree did not sync |
| 76 | `BUSY` — the lane's Sprite is already running something |
| 70 | the tree's compiler does not build |
| 124 | the command passed its bound |
| 125 | the build passed its bound |
| 130 | `Ctrl-C`, and the run stopped |
| 137 | the Sprite ran out of memory |
| 143 / 129 | this client was terminated or hung up; the run goes on |

A failure's last line begins with the one of three that failed:
`SPRITE`, `CONNECTION` or `COMMAND`. `sh tools/work attach` follows a
run again from its first line and answers its status.

    sh tools/work test             # what this branch touches, on its Sprite

`test` is the lane's convenience: it runs what the affected closure owes
on the Sprite.

### The old spelling

`tools/sp` is the old spelling of `tools/work run`: it execs `tools/work
run` against this worktree's Sprite. New work uses `tools/work`.

---

## 3. The deterministic watcher

**A watcher must not be powered by the activity it watches.** That is
the law the watcher exists to honour. The first version fired only on
`workflow_run` — i.e. when another workflow *completes*. A stalled
pipeline completes nothing, so it slept through a five-hour stall. Its
GitHub cron is best-effort: a `*/5` schedule has fired once in hours.
So the clock comes from somewhere that is not the thing being watched.

### The committed watcher

`tools/pr_watcher.py`, run by `.github/workflows/pr-watcher.yml`. Its
triggers: the `schedule` cron (`*/5 * * * *`, GitHub's floor,
best-effort), `workflow_run` after `checks` or `auto-merge` completes, a
push to `main`, and `workflow_dispatch`.

Its decision is a **pure function** (`plan`), proved against fixtures
with no network and no LLM (`python3 tools/pr_watcher.py --self-test`).
It does four things:

- **(a)** a PR whose required `test` failed — comment the exact
  `job — line`, and re-run the failed jobs **once** (a second rerun of
  the same head changes nothing, so it is refused by state).
- **(b)** a green, mergeable, unmerged PR not in the queue — enqueue it
  (enable auto-merge when it is not set, or a direct enqueue when it
  is), but only while the queue holds fewer than `AVRA_QUEUE_MAX` entries
  (default 3). A full train is ~40 min of the shared runner pool, so
  more entries make the queue land *slower*. A green PR over the cap is
  held and named, never dropped.
- **(c)** a queued entry with no `merge_group` run — dequeue and put it
  back, since an entry with no train starts nothing by waiting.
- **(d)** a failed train — name its failing `job — line` on the PR.

State (which heads were re-run, which failures were told) is a JSON file
in `~/.avra-pr-watcher/state.json`, restored and saved by the workflow's
cache and shared across harnesses, so no two post the same comment.

### The local driver (uncommitted)

The repo has no local daemon; a harness may run one. The machine this
was written on runs `.lead/scripts/watchdog.sh` from a `launchd` agent
(`~/Library/LaunchAgents/lang.avra.watchdog.plist`, `StartInterval`
120 s). It exports a real `PATH` (launchd's is minimal, so `gh` must be
found or the script exits silently) and always fetches `origin/main`'s
copy of `tools/pr_watcher.py` (`git show
origin/main:tools/pr_watcher.py`), so a stale worktree can never drive a
stale watchdog. `~/.avra-pr-watcher/watchdog.log` is the liveness check.

**What it does not do, stated so it is not mistaken for coverage:** it
messages no session and no human; it runs only while that Mac is awake;
it is one machine. A second driver off this machine is wanted.

`tools/queue_keeper.sh` is the third, independent path (see §1). Three
independent mechanisms — `auto-merge.yml`, `pr-watcher`, `queue-keeper`
— are what make "nothing is landing" hard.

---

## 4. Gates and keepers

A **keeper** is a mechanical refusal: a script that reads the tree (or
runs the compiler over it) and refuses a shape the project decided is
wrong. Keepers are declared in the Makefile, in **one list**, and that
list is what decides where each runs. A keeper not in the list is held
by nobody.

### The three keeper layers

| target | what it is | who runs it |
|---|---|---|
| `make keepers-static` | the keepers that need no compiler, ~half a minute | a lane before pushing |
| `make keepers-pr` | the keepers a PR can break alone | a lane before pushing |
| `make keepers-a` / `make keepers-b` | the two halves the train runs on separate runners | the train |
| `make keepers` | every keeper, union of the above | `tools/gate_changed.sh` when not told `--no-keepers` |
| `make gate` | the full local gate: keepers plus suites plus the vocabulary proofs | a lane proving a whole tree |

`KEEPERS_STATIC` and `KEEPERS_PR` are quoted in `make keepers-static` and
`make keepers-pr`, so a keeper named there but absent from the one
`KEEPERS` list is refused by the target itself.

### What each keeper protects

| keeper | protects |
|---|---|
| `make fingerprints` | every node kind's fingerprint tag is unique inside its fold space |
| `make vocab` | every `Ins` consumer stays exhaustive, so an instruction cannot ship half-implemented |
| `make families` | the node family ordinals are append-only (a durable address) |
| `make layers` | layering is one-way: `core -> grammar -> features -> compiler`, and `@std/relation` never names the compiler |
| `make inputs` | every read of the world is an input through one door; a new site is refused and the baseline only falls |
| `make clock-holds` | every blocking C call holds the world (a virtual clock flows across, or it says why it waits on no time) |
| `make cited` | the names the live doctrine cites (`CLAUDE.md`, `DOGFOODING.md`) resolve |
| `make http-cites` | every `<suite> › "<then>"` in the HTTP framing laws names a test that exists |
| `make externs` | Avra's 64-bit `int` and C's 32-bit `int` — a C body answering narrow and a negative reading large |
| `make suites` | the test roster derives with no cycle and no missing package |
| `make rt-header` | `runtime/avra_rt.h` is what `rt_sigs()` says (generated, never edited) |
| `make rt-ns` | `packages/std-avrac/src/features/rt.av` is what `rt_sigs()` says |
| `make witnesses` | every diagnostic code's golden in `docs/DIAGNOSTICS.md` is the compiler's own words, and each witness still triggers its kind |
| `make dogfooding-rules` | DOGFOODING.md's generated registry block is current (`avra rules --check-markdown`) |
| `make attack` | the set of malformed mutants the compiler accepts has not moved (`tools/attack.baseline`) |
| `make speed-ratchet` | each phase of `packages/cli`'s build/check is under its ceiling (§5) |
| `make read-cost` | retains, releases and list reads/writes per read are over no budget |
| `make codecs` | every record's encoder and decoder agree (`decode(encode(x)) == x`) |
| `make traps` | a trap is a verdict (exit 2) and its words name the fault, held exactly |
| `make compile-slots` | the parallel build's slot accounting |
| `make witness` | Avra and C agree reading the same object — the extern width seam |
| `make stems` | the Makefile's tree-stem law, driven with synthetic sources |
| `make fmt-lossless` | `fmt(x) == x` byte-exact over every `.av` file (never idempotence) |
| `make flow-trace` | the scheduler's trace contract |
| `make hash-door` | the hash package's C door |
| `make footprint` | a program that spawns nothing links no scheduler, and small programs stay under a relative byte cap |
| `make tick-object` / `make no-threads` | the hosted source's undefined symbols; the scheduler's C free of threads and thread-locals |
| `make ui-host` / `make ui-host-test` / `make ui-board` / `make ui-browser` | the UI host's generated table, the JS host, the wasm board, the board in a real browser |
| `make tool-witnesses` | each instrument the gate and lanes lean on, proved on its own fixtures |
| `make runtime-tests` / `make runtime-mutations` | the runtime's C tests; and each test broken one line at a time, some test must fail |
| `make seed-check` | the committed seed still compiles HEAD (a seed that cannot is a fossil) |
| `make pipeline-doc` | this document names only targets and `tools/` paths that exist |

### The seed law

`make seed-check` links `bootstrap/seed.ll` and has it compile
`packages/cli`. It is the guard against the committed seed drifting away
from the tree. A seed refusal reads "the seed cannot compile HEAD — run
`make seed`", and the failure is fixed by refreshing the seed on the
removing/growing commit that broke it, never by weakening the check. It
stands alone on its own runner because it is itself a compiler build —
run beside the two keeper halves on one runner, the OOM killer took the
whole job with nothing said.

### The changed-file gate

`sh tools/gate_changed.sh` is the one definition of "what a changed tree
owes", shared by a lane and the train so they can never be two
instruments:

    sh tools/gate_changed.sh --refs <base> <head> [--no-keepers] [--pr-minimum]
    sh tools/gate_changed.sh --files <f…> --packages <p…> [--pr-minimum]

It runs the keepers (unless `--no-keepers`), `fmt --check` on the changed
`.av`, `check <pkg> --baseline tools/idioms.baseline` on each affected
package, and — where a wasm toolchain stands — the wasm target's proof.
`--pr-minimum` is a PR's fast floor: fmt and idioms only, skipping the
wasm proof, which belongs to the train. A lane runs it as
`sh tools/work run sh tools/gate_changed.sh --files … --packages …`.

### The lane's pre-push scope

Before pushing, a lane runs, in this order:

    sh tools/gate_changed.sh --refs origin/main HEAD --no-keepers
    make keepers-static
    make keepers-pr

and the affected package's suites (on the Sprite). A green PR is cheaper
than a red one: one red PR drops a whole train. Note `--refs origin/main`
does not work on a Sprite (no `origin/main` there); run it on the Mac.

---

## 5. Speed budgets

### The hard ratchet

`make speed-ratchet` (`tools/speed_ratchet.py`) holds each **phase** of
`packages/cli`'s own build and check against a recorded ceiling in
`tools/speed.budget`, and refuses past it, naming the phase, its ceiling
and what it measured. The phases are `analyze`, `lower`, `keep`, `emit`,
`link`. A ceiling **may only fall**: `make speed-accept` writes a
measured value only when it is lower than the ceiling already there, and
a raise is a human edit of `tools/speed.budget`, whose diff is the
review. A host with no row is measured and printed, never gated.

Like for like: a row is keyed `<platform>-<machine>-<cpu>`, so a Mac, a
Sprite and a runner are never compared. The measurement is the least of
`SPEED_ROUNDS` warm one-edit rounds (`tools/speed_measure.sh`). It runs
on the host it measures; on macOS it runs on the lane's Sprite through
`sh tools/work run`, because a loaded Mac supplies no number. A cold
store skips with a word — run `make try` once, then re-run.

The **soft** note is `tools/speed_note.sh`: it reads the seconds each CI
job already prints and warns (`::warning::`) over a 25% move. It never
fails a run. The hard ratchet exists because a sum of small per-phase
regressions slips under the soft note.

### Where the CI time goes

Measured on a Sprite (2026-10-10) — the cold path was ~1050 s and 95%
of it was the two self-compiles:

| step | time |
|---|---|
| C objects | 10 s |
| seed link (`make recover`, a 44 MB `seed.ll`) | 58 s |
| gen-1 `make avra` | 517 s |
| gen-2 `make avra` | 514 s |

Inside one self-compile (~508 s): `parse 24, analyze 39, lower 368, keep
54, emit 43, link 2.5` — **`lower` is the whole cost**. The cache hit is
0 s; the cold path is why a train rebuilds. These are dated measurements,
not guarantees: re-measure with the same Sprite before relying on them.

### Memory and the build lock

Every heavy step runs through `sh tools/watch.sh <cap_mb> <cmd…>`: it
holds a machine-wide lock in `/tmp` (one heavy step at a time, across
every worktree and session), polls the footprint of the step and all its
descendants, kills the whole tree past the cap, and prints the peak. The
lock dies with the step. `./avra` takes this lock itself for any
package-scale run (an argument that is a directory), so no path bypasses
it. A step does not start while the machine has less than
`AVRA_MEM_FLOOR` percent available. Profiling runs under the lock too:
`AVRA_SAMPLE=<secs>` samples into `AVRA_SAMPLE_FILE`.

**A log is capped; an artifact being compared is not.** `sh
tools/capped.sh <file> <bytes> <cmd…>` caps a build log and answers the
command's own status (a bare pipe would answer the pipe's). Artifacts
compared for equality — `witness`, `native-check` — are deliberately
**uncapped**, since truncating both could manufacture agreement. The
rule is stated at each redirect.

Memory is answered by the runtime's accounting, not by guessing:
`AVRA_MEM_STATS=1 ./avra check <pkg>` reports live bytes by category and
allocation site, and `make census CMD="check <pkg>"` gives exact
retain/release/list-write counts with the callers that cause them (the
census compiler is built beside `build/avra`; the shipping compiler is
never removed).

---

## 6. Known traps

**A green PR is not a green train.** A PR runs the fast floor; the train
runs the gate over a combination no single PR's tree can. Run the
affected closure's suites before pushing.

**A red keeper on `main` blocks everything.** Every train fails, so no
PR can land no matter what you do to it. If `main` is red, fix `main`
first — one lane, one PR.

**A stack can never enter the queue.** A PR whose base is not `main`
fails with "No merge queue found for branch …". Land the dependency
first, then rebase onto `main`.

**A queued entry with no train is stuck, and waiting does not start
one.** Take it out and put it back (`queue-keeper` and `tools/work
status` do this).

**`land` reads the PR, never `main`.** Polling `main` to infer a landing
waits on the wrong clock and once deadlocked the queue.

**Do not make a PR run the train's jobs "to close the gap."** It costs
an hour per PR. The gap is closed by dev-time Sprite runs and by the
watcher.

**The cron is best-effort.** GitHub's `schedule` is a floor, not a
promise; a stalled watcher or a stalled queue is what the local driver
and `queue-keeper` are for. `tools/pr_watcher.py`'s own docstring still
says "every two minutes"; `.github/workflows/pr-watcher.yml` says
`*/5 * * * *`, and that is what runs.

**A GitHub cache is scope-bound.** A train's own ref cannot read a
sibling's compiler cache; the release asset is what crosses refs. Save
the cache only on `push` to `main`.

**A build cache hit can cross binaries.** `.avra-cache` is keyed by the
compiler's own bytes, so building or checking with a second binary over
the same source can read the first binary's kept answer. `rm -rf
.avra-cache` before any run whose answer is being compared.

**After a language change merges, a lane's first build is
`make bootstrap`, never `make avra`.** A stale compiler cannot read the
new syntax, so the build fails pointing at the new code and reads as
"the merge is broken" when it means "my binary predates it".

**`make try`, never `make avra`, in a lane.** `make try` builds
`build/avra-try` with the standing `build/avra` and never replaces the
builder, so the store stays warm. `make avra` replaces the builder.

**Two generations after a compiler-source change.** A compiler built
right after a pass change carries that fix as source but its own body
was compiled by the pre-fix pass; build twice before trusting a
measurement.

**One heavy process at a time, in the foreground, under the watchdog.**
The machine is shared and has panicked under two heavy runs outside the
lock. A launched run may be moved to the background by a harness and is
still inside the lock; a heavy process *outside* the lock, or launched
into the background to run *beside* another, is the thing forbidden.

**Do not run a whole package suite on the Mac.** It is a whole-package
compile plus a linked binary spawning children. Use the Sprite.

**A probe lives outside the tree.** `./avra check build/scratch/x.av`
under a directory with an `avra.toml` above it can answer exit 0 and
nothing for a file full of errors — the file is not a program of that
workspace. Probe from `/tmp`.

**Older notes name scripts that are not in the tree.** The speculative
land-train design (`docs/2026_09_29_LAND_TRAIN.md`) named `tools/land.sh`
and `tools/land_train.sh`; neither was built — the mechanism is GitHub's
native merge queue plus `tools/work`. A ticket once named
`tools/warm_edit_bench.sh`, which does not exist. The retired queue
pollers `tools/qwatch.sh` and `tools/qfill.sh` are in the local archive;
GitHub's auto-merge replaces them. None of these is a command to run.

---

## 7. Command table

### A lane

| command | what it does |
|---|---|
| `sh tools/work new <name>` | a worktree `../avra-<name>` off `main`, and its Sprite |
| `sh tools/work run <cmd>` | run `<cmd>` on this lane's Sprite, followed to its status |
| `sh tools/work run --for <minutes> <cmd>` | the same, with a raised bound |
| `sh tools/work test` | what this branch touches, on this lane's Sprite |
| `sh tools/work land` | rebase, fmt-check, push, open PR, queue it |
| `sh tools/work status` | PRs and the queue; each lane and its Sprite |
| `sh tools/work sprites [--fix]` | every Sprite at a glance; `--fix` repairs |
| `sh tools/work bind [<sprite>]` | give this worktree a Sprite, or move it |
| `sh tools/work wait <branch>` | wait until the branch's PR merges |
| `sh tools/work attach` | follow this lane's run again, from its first line |
| `sh tools/work stop` | end this lane's run on its Sprite |
| `sh tools/work done` | remove this lane, end its run, free its Sprite |
| `sh tools/work command <stage> …` | the hand-off's words: stage word then link plans |
| `sh tools/gate_changed.sh --refs origin/main HEAD --no-keepers` | the changed-file gate |
| `make keepers-static` | the compiler-free keepers |
| `make keepers-pr` | the keepers a PR can break alone |
| `make try` | build `build/avra-try` with the standing compiler |
| `make bootstrap` | the cold path: recover the seed, then build twice |
| `make recover` | link the seed into a compiler, no build |
| `make seed` | refresh `bootstrap/seed.ll` and `seed.sources` |
| `make sprite` | provision this machine (no-op on macOS) |
| `make sprite-check` | does a fresh Sprite from this tree need a build? |
| `make census CMD="check <pkg>"` | exact retain/release/list-write counts and their callers |

### The gates

| command | what it does |
|---|---|
| `make gate` | the full local gate |
| `make keepers` | every keeper |
| `make keepers-a` / `make keepers-b` | the train's two keeper halves |
| `make seed-check` | the committed seed must compile HEAD |
| `make speed-ratchet` | hold each build/check phase under its ceiling |
| `make speed-accept` | lower a ceiling to what was measured (never raises) |
| `make idioms` | the idiom ratchet over every package |
| `make fmt-lossless` | `fmt(x) == x` over every `.av` file |
| `make attack` | the accepted-mutant baseline |
| `make pipeline-doc` | this document's commands resolve |

### The queue and CI

| command | what it does |
|---|---|
| `gh pr merge <n> --auto --squash` | queue a PR by auto-merge (a lane's `land` and the watcher enqueue directly; `auto-merge.yml` sets this on PR events) |
| `gh pr view <n> --json autoMergeRequest` | confirm auto-merge is set |
| `gh run list -R avra-lang/avra --branch main` | is `main` itself green? |
| `gh workflow run checks --ref <branch>` | run a whole train by hand on a branch |
| `python3 tools/pr_watcher.py --self-test` | prove the watcher's decision on fixtures |
| `sh tools/queue_keeper.sh` | one queue-keeper pass |

### Measurement

| command | what it does |
|---|---|
| `AVRA_MEM_STATS=1 ./avra check <pkg>` | live bytes by category and site |
| `AVRA_SAMPLE=<secs> sh tools/watch.sh 4000 ./avra …` | sample under the lock |
| `sh tools/watch.sh <cap_mb> <cmd…>` | run one heavy step under the lock and cap |
| `sh tools/capped.sh <file> <bytes> <cmd…>` | cap a log, keep the command's status |
| `sh tools/compiler_paths.sh --key` | the compiler's source digest (the cache key) |

---

## 8. If X happens, run Y

**A PR's `test` is red.** Read the job the watcher named
(`job — line`), reproduce that job's scope locally, and fix the cause.
Never weaken a keeper or a test. `tools/work status` shows the checks.

**A PR is green but not queued.** `sh tools/work status` re-enqueues a
stuck entry on sight. If it is not stuck, either set auto-merge with `gh
pr merge <n> --auto --squash` or let the watcher's next pass pick it up.

**A PR will not enqueue.** The message is the diagnosis: "No merge queue
found" means it is stacked (base is not `main`); "Required status check
`test` is failing" means a check is red; "merge conflicts" means rebase
onto `origin/main`.

**A train fails on someone else's PR.** Read the failing job's log; the
PR that caused it is the one to fix, not yours. `queue-keeper` drafts a
PR whose head has failed three trains.

**`main` itself is red.** Stop feature work. Check out `origin/main`,
reproduce the keeper refusal on a fresh build, fix `main`, one PR. Until
it is green, nothing lands.

**A lane's Sprite is busy or silent.** `sh tools/work sprites` shows
every Sprite; `sh tools/work sprites --fix <sprite>` repairs one. A
`run` that answers 76 means the lane's Sprite is already running
something — do not retry in a loop.

**A run's client died.** The run goes on. `sh tools/work attach` follows
it again from where it stood; `sh tools/work stop` ends it.

**A build refuses and the tree looks clean.** A stale compiler: run
`make bootstrap`, or check `make sprite-check` for the seed path. After
a language change merges, `make bootstrap` is the first build.

**A measurement reads wrong.** A cache hit can cross binaries —
`rm -rf .avra-cache` and re-run. A profile must end before the step does,
and `AVRA_SAMPLE_FILE` is per-worktree.

**A gate is too slow to run in full.** Fix the runtime cost; do not
shrink the claim to a chosen corpus. Profile under the lock.

---

## Provenance: what this consolidates, and what was kept

This document replaces, as the single source, the landing/Sprite/watcher
material that was spread across four places:

- `CLAUDE.md`'s "How work lands" section — kept as doctrine; this doc is
  its expansion, and `CLAUDE.md` remains the law of the language.
- `docs/2026_09_29_LAND_TRAIN.md` — a **design** for a speculative merge
  queue over `tools/land.sh`. The scripts it named (`tools/land.sh`,
  `tools/land_train.sh`) are not in the tree, and the mechanism that
  actually runs is GitHub's native merge queue plus `tools/work`. Kept:
  nothing operational; the design is history.
- `docs/2026_09_16_SPRITE_SESSIONS.md` — kept in substance (what a
  Sprite is, provisioning, the seed fast/slow path), folded into §2.
- `.lead/LANDING_GUIDE.md` and `.lead/WATCHDOG.md` — uncommitted local
  notes, now superseded by this doc. Two of their claims disagreed with
  the code and the code was kept: the watcher's cadence (the workflow
  cron is `*/5`, best-effort, not ~2 minutes), and the PR check's scope
  (the code runs `gate_changed --no-keepers --pr-minimum` — fmt and
  idioms — not the keepers; a lane runs the keepers locally before
  pushing).

Local material that is not part of this doc's subject (the DB05 store
explainer, the local launchd driver and its scripts, one-off code
patches, old handoffs) stays in `.lead/`, with the superseded notes moved
under `.lead/archive/`.
