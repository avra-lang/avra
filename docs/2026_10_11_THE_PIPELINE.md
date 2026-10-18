# The pipeline — how work lands, on Sprites, through the gates

One document for the path from a branch to `main`: how a change lands,
Sprites, the deterministic watcher, the keepers and gates, the speed
budgets, the known traps, and what to run when a step fails. It is
written for a reader who has never seen this repo.

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

`main` is protected by a ruleset: squash merges, linear history, no
direct pushes. It requires the `test` check **and** that a branch be
**up to date with `main`** before merging, and every green PR has
auto-merge armed, so merges happen **one at a time, hands-off**. There
are three layers of proof:

1. **Dev — a Sprite.** Every heavy build and test runs on a remote
   Ubuntu microVM bound to the lane, warm between runs. This is the
   fast loop.
2. **The PR — the gate.** A PR's own `test` check runs on the
   combination of `main` and the PR, because "up to date" makes its
   branch hold current `main`: `fmt` on its changed files, `check` on
   the affected package closure, the static and compiler-dependent
   keepers, the seed check, the cache attacks where the store moved, the
   runtime latency gate where `runtime/` moved, and the affected
   packages' suites (sharded). A PR that touches no `.av`, no package and
   no compiler source builds nothing and owes nothing.
3. **`main`'s own push run** caches the compiler every run starts from
   and publishes the release asset.

**THERE IS NO MERGE QUEUE (dropped 2026-10-11).** Its only real value
was testing `main` plus every PR ahead of it, which "require up to date"
gives back for free one PR at a time. What it cost was trains that
tested many PRs at once (one red suite killed them all), HEADGREEN
batching, and a rebase treadmill where every landing re-conflicted
everything behind it. True line conflicts are unavoidable in any model;
the queue only made them more expensive to discover.

`.github/workflows/checks.yml` is the one definition of the gate.
`tools/work` is the one command surface a lane uses. Nothing in
`tools/work` writes `main`.

---

## 1. How a change lands

### The lane's day

From a fresh checkout:

    sh tools/work new <name>     # a worktree ../avra-<name> off main, and its Sprite

Work there, commit, then:

    sh tools/work land            # rebase, fmt-check, push, open PR, ready, strip a DO NOT MERGE title, arm auto-merge

`land` does, in order: refuses to run on `main`; refuses a dirty tree;
`git fetch origin main`; `git rebase origin/main` (onto `main` only);
checks the changed `.av`'s formatting with the compiler the worktree
already holds; force-with-lease pushes; opens a PR against `main` if one
is not open; and **arms auto-merge** (`gh pr merge <n> --auto --squash`).
It prints the PR URL and says what it armed.

### What auto-merge does

**A hold is a hold.** A draft, or a title that says `DO NOT MERGE`, is not
armed. `.github/workflows/auto-merge.yml` checks the title and skips the
arming step, and the watcher (rule (j)) disarms one that was armed anyway.

**Landing is one verb.** `sh tools/work land` pushes, marks the PR ready if
it is a draft, strips a leading `DO NOT MERGE` from its title (through the
REST API, since `gh pr edit` lacks the scope), and arms auto-merge. A title
that is only the hold phrase is refused: name the change first.

**Landing waits its turn.** `sh tools/work land` refuses while another
non-draft PR's `test` check is still running: landing moves `main`, so that PR
restarts. `sh tools/work land --batch` lands beside it on purpose.
`make pipeline-status` prints LANDING NOW WOULD: one line per open PR naming
the mid-CI PRs its landing would restart.

**Nothing rots unseen.** `make pipeline-status` prints a section
WAITING ON A HUMAN/LEAD: each green draft with its age, each red non-draft
PR past two hours with its failing jobs, each PR BEHIND `main` past an hour
(with how long `main` has moved), and each PR with no push for a day. A cap
line says how many PRs are open and how old the oldest is. It exits 1 when
any green draft is older than six hours, so a heartbeat can alarm on it.

There is no queue. An armed PR merges **itself** the moment both
requirements hold: its required `test` check is green, and its branch is
up to date with `main`. Merges are serialized by the second requirement:
while one PR merges, every other armed PR that is now behind waits, and
the watcher refreshes it (§3). Nothing polls `main` to decide a landing.

`sh tools/work status` prints every open PR with its checks, its merge
state, and whether auto-merge is armed, then one line per lane and its
Sprite.

`sh tools/work wait <branch>` waits for one branch's PR to merge. **The
oracle is the PR's state, asked of `gh`, never `main`.** `MERGED` is the
only success; `CLOSED` is a failure. The deadline is `AVRA_WAIT_SECONDS`
(default 120 s) and the poll `AVRA_WAIT_POLL` (default 15 s).

### Entering and staying armed

Two independent mechanisms arm auto-merge, so a green PR never sits
unmerged:

- **`.github/workflows/auto-merge.yml`** runs on every `opened`,
  `ready_for_review`, `synchronize` and `reopened` event and runs
  `gh pr merge --auto --squash`. A draft is skipped, and a fork's PR is
  skipped (its token cannot arm it).
- **`tools/pr_watcher.py`** arms the next green, mergeable PR in order
  on its next pass, and refreshes it when it has fallen behind (§3).

`tools/work land` also arms auto-merge directly, so a lane that pushes
and moves on needs nothing else.

### The compiler in CI

`checks.yml`'s `prepare` job decides what a run owes and gets a compiler
before anything else. The compiler is **keyed by its own source**
(`sh tools/compiler_paths.sh --key`), so a tree whose compiler is
`main`'s takes `main`'s binary and builds nothing. In order:

1. **Cache** (`.avra-cache` rides with the binary) — a hit is 0 s of
   build.
2. **Release asset** — `python3 tools/compiler_release.py fetch`, a
   binary `main` published under its own source digest. This exists
   because a GitHub cache is **scope-bound**: a run restores from its
   own branch and `main`, never a sibling's. A release asset crosses
   refs.
3. **Build twice** (`make avra` twice) — one `make avra` advances the
   compiler by one generation, so a compiler carrying a change must
   build the tree twice before it is the tree.
4. **Bootstrap** (`make bootstrap`) — when the nearest binary is too old
   to read the source (new syntax, or a new refusal about the compiler's
   own source), fall back to the committed seed.

Only a push to `main` saves the cache and publishes the release asset,
so no PR run publishes a binary.

### What each job runs

| job | when it runs |
|---|---|
| `prepare` | every run; plan, then a compiler and the objects/libs when `build=1` |
| `keepers-a` / `keepers-b` | any non-push run with `build=1`; `keepers-a` is two shards (`keepers-a1`, `keepers-a2`) and `keepers-b` one, each on its own runner |
| `seed-check` | any non-push run with `build=1`; the committed seed must compile HEAD |
| `gate` | any non-push run with a changed `.av` or an affected package; `fmt` + idioms |
| `cache-attacks` | whenever `cache=1` (a push to `main`, a hand-run gate, or a PR that reaches the store or the attacks); two shards: `cache-attacks-a` (`tools/cache_attacks.sh`) and `cache-attacks-b` (the other attacks, plus `code-hash-attacks`) |
| `flow-gate` | whenever `runtime/` moved |
| `runtime-keep` | the C runtime's own tests and mutation breaks: on a PR only when `runtime/`, the Makefile or `tools/memcap.sh` changed (`tools/ci_path_gate.py`); always on main's push and a hand-run |
| `suites` | any non-push run with a non-empty affected closure; sharded (4 shards) |
| `codecs` | a PR whose diff reaches the compiler source or the reader |
| `test` | the aggregate required check, every run |

**A draft runs the light gate.** A draft PR's run builds the compiler when
its diff owes one, and runs only the compiler-free keepers, the changed-file
`gate` and the codecs scan. The heavy legs (`keepers-a`, `keepers-b`,
`runtime-keep`, `seed-check`, `flow-gate`, `cache-attacks`, `suites`) are
gated on `needs.prepare.outputs.full`, which is `0` for a draft without the
`full-ci` label. `test` refuses a light run by name (`NOT A VERDICT`), so a
draft never shows a green required check it did not earn, and the watcher
and the batcher, which read `test` for SUCCESS, refuse it. A light run
judges `fmt` and the idioms with the tree's own compiler only. When the tree's
compiler is not the published one, the `gate` job is skipped and the light run
says so: a skipped gate is not a pass, and the full run on ready is the verdict.
The mode is read from the PR's API answer at run time (`tools/pr_mode.py`), so a
queued run cannot keep the light mode after the PR is ready. Readying the PR,
or labelling it `full-ci`, is what starts the whole run; the `ready_for_review`
and `labeled` events are in the trigger list for that reason.

### Batches

A batch is built straight from light-green members, and its own run is the
test. A ready member needs `test` SUCCESS. A draft member needs its light gate
green by name (`gate`, `keepers-static`, and `codecs` SUCCESS or SKIPPED), and
its heavy legs did not run, so it also needs evidence from the Sprite:
`--attacks-ran` or `--attacks-na` for cache-attacks, and `--suites-ran` for the
suites. The batch PR is a ready PR, so CI runs the full gate on the composed tree.
No composed Sprite pre-run is owed, except cache-attacks evidence when CI skipped
that job for the members.

A run that touches no `.av`, no package and no compiler source **builds
nothing and owes nothing**. The compiler source paths are
`sh tools/compiler_paths.sh` (the `cli` package plus every `@std`
package it reaches, the runtime, the backend, the seed and the
Makefile). Affected packages are `sh tools/affected_packages.sh`
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
    AVRA_PROBE_BUILD=one sh tools/work run <cmd>

Each run prints the source hash it ran (`sprite-run: compiler … source <hash>,
binary <sha>`), so a lane can compare it with `sh tools/work compiler-hash`.
`AVRA_PROBE_BUILD=one` builds ONE generation from the standing compiler, never
cached, and says `one generation, not a fixed point`. It needs a standing
compiler (`sh tools/work run make bootstrap` first).

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
There is no queue; the watcher keeps every open PR able to merge itself:

- **(a)** a PR whose required `test` failed — comment the exact
  `job — line`, and re-run the failed jobs **once** (a second rerun of
  the same head changes nothing, so it is refused by state).
- **(b)** the **next** green, mergeable, unconflicted PR — **arm**
  auto-merge (`gh pr merge --auto --squash`) when it is not already armed.
- **(c)** that same PR, when **behind** `main` — **refresh** its branch
  (`gh pr update-branch`), so "up to date" is met without a human. The
  refresh is deduped per head, and the update moves the head, so it
  refreshes again only if `main` moved again.
- **(l)** the **order**: one PR at a time, because "up to date" already
  makes it one at a time — every merge puts every other PR behind `main`,
  so arming and refreshing them all re-ran every gate once per merge. Only
  the front PR is armed and refreshed (green, mergeable, not held, the
  `priority` label first, then the lowest number); while a PR is armed and
  awaiting its run, or armed and clean about to land, nobody else is
  touched and the rest are named `#N waits behind #F`. A PR's own run is
  still its gate. A **`hold` label** (or a DO NOT MERGE title) keeps a PR
  out of the order: never armed, never refreshed, disarmed if armed.
- **(d)** a PR that **conflicts** with `main` — name the rebase its owner
  owes, once.
- **(e)** a **draft** — name it so it is never invisible. The watcher
  **never readies a draft**: a draft is a hold, and only a landing takes
  it.
- **(j)** a **held title** — a non-draft PR whose title says `DO NOT MERGE`
  is never armed, and one already armed is **disarmed**
  (`gh pr merge --disable-auto`) once per head. Either signal alone holds
  it; the auto-merge workflow refuses to arm such a title too.
- **(k)** a **green draft held past two hours** — named once with its age,
  and once more each UTC day after, so a draft that could land is never
  silent.
- **(f)** a **doomed run** — cancel a `pull_request` run whose PR is no
  longer open. A superseded run is already cancelled by `checks.yml`'s
  own concurrency.
- **(g)** a **blocked** PR — name the check it waits on, once.
- **(h)** an **unvalidated `main`** — a merge the bot pushed fires no
  workflow (`GITHUB_TOKEN` pushes trigger none), so `main` can stand with no
  `checks` run; once its head is older than three minutes with none, dispatch
  `checks` on `main`, once per SHA.
- **(i)** a **held run** — a bot-pushed head fires a `checks` run that waits
  in `action_required`; approve it, once per run id, when its PR is same-repo
  and the run is on the PR's current head. A fork's run is never approved.

Every open PR gets an action or a loud name. Every comment is deduped by
`(pr, head, reason)` and carries its own marker, so a lost state file
cannot re-post it and two watchers never double-comment. State (which
heads were re-run, which failures and refreshes were told, which runs
were cancelled) is a JSON file in `~/.avra-pr-watcher/state.json`,
restored and saved by the workflow's cache.

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

`auto-merge.yml` and `pr-watcher` are the two independent mechanisms
that make "nothing is landing" hard.

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
| `make keepers-static` | the keepers that need no compiler, ~half a minute | a PR before it builds anything; a lane before pushing |
| `make keepers-pr` | the keepers a PR can break alone | a lane before pushing |
| `make keepers-a` / `make keepers-b` | the two halves a gate run splits onto separate runners | the PR's `test` check |
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
| `make families-left` | the hand-written families may only fall, and a family is keyed by its name |
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
| `make voices` | every kind and rule carries what its row owes — a witness, help, a structured fix where declared — and no gap is new (`tools/voices.baseline` only shrinks; `docs/VOICES.md` is the generated inventory) |
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
owes", shared by a lane and a PR's own check so they can never be two
instruments:

    sh tools/gate_changed.sh --refs <base> <head> [--no-keepers] [--pr-minimum]
    sh tools/gate_changed.sh --files <f…> --packages <p…> [--pr-minimum]

It runs the keepers (unless `--no-keepers`), `fmt --check` on the changed
`.av`, `check <pkg> --baseline tools/idioms.baseline` on each affected
package, and — where a wasm toolchain stands — the wasm target's proof.
`--pr-minimum` is a fast floor: fmt and idioms only, skipping the wasm
proof. A lane runs it as
`sh tools/work run sh tools/gate_changed.sh --files … --packages …`.

### The lane's pre-push scope

Before pushing, a lane runs, in this order:

    sh tools/gate_changed.sh --refs origin/main HEAD --no-keepers
    make keepers-static
    make keepers-pr

and the affected package's suites (on the Sprite). A green PR is cheaper
than a red one. Note `--refs origin/main` does not work on a Sprite (no
`origin/main` there); run it on the Mac.

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
0 s. These are dated measurements, not guarantees: re-measure with the
same Sprite before relying on them.

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

**A green PR is not automatically a green `main`.** Its check runs the
full gate on the combination, but the PR can still be behind a merge
that landed a moment ago; "up to date" and the watcher's refresh keep it
current. Run the affected closure's suites before pushing to save a
round.

**A red keeper on `main` blocks everything.** Every PR's gate fails, so
nothing lands no matter what you do to it. If `main` is red, fix `main`
first — one lane, one PR.

**A stack is never rebased onto another unlanded branch.** A PR whose
base is not `main` is not tested against the combination; land the
dependency first, then rebase onto `main` (`git rebase --onto origin/main
main <branch>`).

**A stale PR is refreshed by the watcher, but a conflicted one is not.**
`gh pr update-branch` resolves staleness, never a line conflict; a
conflicting PR is named on the PR with the rebase its owner owes.

**`land` reads the PR, never `main`.** Polling `main` to infer a landing
waits on the wrong clock.

**Do not add a job "to close the gap."** The gap is closed by dev-time
Sprite runs and by the watcher, not by making a PR run something extra.

**The cron is best-effort.** GitHub's `schedule` is a floor, not a
promise; that is what the local driver is for.
`.github/workflows/pr-watcher.yml` says `*/5 * * * *`, and that is what
runs.

**A GitHub cache is scope-bound.** A PR's own ref cannot read a
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

**A budget that counts the machine's whole heap makes a run's fate depend
on its neighbours, and the PR route finds it first.** A compile-time run
(a derive, a const) is cut off past `[lifted] memory`, measured as the
process's live bytes against where the run began. The workspace answers
`type_named` from inside the run, and what it builds to answer (types,
signatures) stays — so the same derive settled in 2 MB or in 5.6 MB by how
much the compiler had already loaded. A PR's job restores a big store and a
suite that compiles a whole directory, which is the second shape; main's push
runs the first, so main was green and the PR red: `SyntaxArena has no method
expr_children` at seven sites with no refusal naming a budget, because a run
cut inside a re-entrant expansion is hushed and its declarations are simply
absent. A failure that reads as a MISSING DECLARATION with no voice is this
shape until proven otherwise: run the failing group with `AVRA_DEBUG=1` and
read the `settle:` lines — a step count lower than the same run's usual, with
bytes just over 5242880, is the cut. The run is billed only for what it
makes (`Machine.named_unbilled`: `type_named` and `embed` are the run's only
doors into the compiler, and the first is the only one that builds kept
state); `compiler/tests/settle_bill_test.av` pins it. A cut derive now SPEAKS
on every expansion, not only its first (`Workspace.lift_refusal`): a refused
lift answers `Spoken` on reuse, and an expansion's voices are wiped when it
runs again, so the second expansion used to say nothing
(`compiler/tests/silent_cut_test.av`).
To reproduce a PR-route failure, download the run's `avra-compiler` and
`avra-build` artifacts, unpack them over a copy of the PR's tree on a Sprite,
and run the failing job's groups IN ITS ORDER: the compiler group alone
passed on the same artifacts, and the ordered run of the job's groups
reproduced it.

**Older notes name scripts that are not in the tree.** The speculative
land-train design (`docs/2026_09_29_LAND_TRAIN.md`) named `tools/land.sh`
and `tools/land_train.sh`; neither was built. A ticket once named
`tools/warm_edit_bench.sh`, which does not exist. The retired queue
pollers `tools/qwatch.sh` and `tools/qfill.sh` are in the local archive;
the merge queue itself was dropped in favour of "up to date" plus
auto-merge (§0). None of these is a command to run.

---

## 7. Command table

### A lane

| command | what it does |
|---|---|
| `sh tools/work new <name>` | a worktree `../avra-<name>` off `main`, and its Sprite |
| `sh tools/work run <cmd>` | run `<cmd>` on this lane's Sprite, followed to its status |
| `sh tools/work run --for <minutes> <cmd>` | the same, with a raised bound |
| `sh tools/work test` | what this branch touches, on this lane's Sprite |
| `sh tools/work land` | rebase, fmt-check, push, open PR, mark ready, strip a `DO NOT MERGE` title, arm auto-merge |
| `sh tools/work status` | PRs and their merge state; each lane and its Sprite |
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
| `make keepers-a` / `make keepers-b` | the two keeper halves a run splits across runners |
| `make seed-check` | the committed seed must compile HEAD |
| `make speed-ratchet` | hold each build/check phase under its ceiling |
| `make speed-accept` | lower a ceiling to what was measured (never raises) |
| `make idioms` | the idiom ratchet over every package |
| `make fmt-lossless` | `fmt(x) == x` over every `.av` file |
| `make attack` | the accepted-mutant baseline |
| `make pipeline-doc` | this document's commands resolve |

### Landing and CI

| command | what it does |
|---|---|
| `gh pr merge <n> --auto --squash` | arm auto-merge (a lane's `land` and the watcher do this; `auto-merge.yml` sets it on PR events) |
| `gh pr view <n> --json autoMergeRequest` | confirm auto-merge is set |
| `gh pr update-branch <n>` | refresh a branch that is behind `main` |
| `gh run list -R avra-lang/avra --branch main` | is `main` itself green? |
| `gh workflow run checks --ref <branch>` | run a whole gate by hand on a branch |
| `python3 tools/pr_watcher.py --self-test` | prove the watcher's decision on fixtures |

### Measurement

| command | what it does |
|---|---|
| `AVRA_MEM_STATS=1 ./avra check <pkg>` | live bytes by category and site |
| `AVRA_SAMPLE=<secs> sh tools/watch.sh 6000 ./avra …` | sample under the lock |
| `sh tools/watch.sh <cap_mb> <cmd…>` | run one heavy step under the lock and cap |
| `sh tools/capped.sh <file> <bytes> <cmd…>` | cap a log, keep the command's status |
| `sh tools/compiler_paths.sh --key` | the compiler's source digest (the cache key) |

---

## 8. If X happens, run Y

**A PR's `test` is red.** Read the job the watcher named
(`job — line`), reproduce that job's scope locally, and fix the cause.
Never weaken a keeper or a test. `tools/work status` shows the checks.

**A PR is green but unarmed.** Either set auto-merge with
`gh pr merge <n> --auto --squash` or let the watcher's next pass arm it.

**A PR is green, armed, and will not merge.** It is behind `main`:
the watcher refreshes it (`gh pr update-branch <n>`) on its next pass, or
do it by hand. If it is blocked instead, `tools/work status` names the
merge state.

**A PR conflicts with `main`.** Rebase onto `origin/main` (the watcher
comments the exact command) and land again.

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
  `tools/land_train.sh`) are not in the tree. Kept: nothing operational;
  the design is history.
- `docs/2026_09_16_SPRITE_SESSIONS.md` — kept in substance (what a
  Sprite is, provisioning, the seed fast/slow path), folded into §2.
- `.lead/LANDING_GUIDE.md` and `.lead/WATCHDOG.md` — uncommitted local
  notes, now superseded by this doc.

**Dropped 2026-10-11: the merge queue.** This doc previously described
GitHub's native merge queue, its trains, HEADGREEN batching and the
queue keeper. All of that is gone. `main`'s ruleset now requires the
`test` check **and** that a branch be up to date with `main`, and
auto-merge lands every green PR one at a time — the queue's real value
(the combination test) for free, without its batching cost. A repo that
re-enables a queue needs its events and its enqueue path back; the
prose above is the state of the tree, not of a queue.

Local material that is not part of this doc's subject (the DB05 store
explainer, the local launchd driver and its scripts, one-off code
patches, old handoffs) stays in `.lead/`, with the superseded notes moved
under `.lead/archive/`.
