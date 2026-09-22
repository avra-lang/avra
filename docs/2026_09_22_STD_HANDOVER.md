# STD handover — 2026-09-22

A new STD task master reads this and takes the work. State first,
then what landed, then what is left, then how to run it, then the
lessons this arc paid for.

## STATE at main `dcbed37`

Everything below is on `origin/main` = `dcbed37` (pushed). The primary
worktree is at `dcbed37`. The primary's `build/avra` is older than the
last landing — rebuild before trusting a local `./avra` number.

Tracker: `export TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db
TASKS_ACTOR="STD MASTER"`. Epic `avra-ms0j`.

### Landed this arc
- **H3** (`avra-8sb5.4.5`) — the borrow soundness hole: `mut ys =
  self.xs; ys.push(v)` wrote through an immutable place with no
  diagnostic, both engines answering `1 2 2` where spec 11.5 demands
  `1 1 0`. Fixed by making the borrow lawful only over a place the body
  may write; three oracle cases on main
  (`features/tests/borrow_{param,local,reread}`).
- **S2a** (`avra-8sb5.4.4`) — the borrow MECHANISM deleted: `mut ys =
  <place>` copies wherever the place lives; the 6 sites that meant
  sharing became PATH WRITES; the other 20 were already copy-shaped.
- **S2b** (`avra-8sb5.4.4.1`) — the capture-wall identity tables are
  `Cell`s the capture shares (`asks`/`settle_asks`/`lift_asks`,
  `externs`, `hold.runs`), the redundant name→id maps deleted,
  `spec_id` is `fn` not `mut fn`. F2047 `196 → 60`.
- **Seed guard** (`avra-8sb5.17`) — `tools/seed_guard.sh`, wired as the
  first line of `seed-check`; `tools/sources_hash.sh` gained `--head`.
  A committed seed that names another tree is REFUSED. Caught two real
  stale-seed landings in one night, on two authors.
- **`stems` portability** (`avra-8sb5.13`, `avra-8sb5.19`) — the symbol
  reader reads ELF and Mach-O; the first fix used a GNU-sed `\?` that
  BSD/macOS does not take, caught by its own `seen>0/looked=0` branch.
- **cache/cas + the sprite-archive exclusion** reconciled onto main
  (`9e18cfa`, `8f3a6f8`), plus the formatter/cost-model docs.

## WHAT IS LEFT (the original STD relaunch set)

1. **S2c** — `avra-8sb5.4.4.2`: the receiver/parameter cell-seat ABI,
   the runtime row and its host, flat receivers unboxed, the corpus
   pair. The last third of the S2 split (S2a, S2b done).
2. **The 60 remaining F2047 capture sites** — S2b's deliberate residue:
   other capture sites of the same class, each needing its own state
   celled. Its own slice.
3. **LANGUAGE-CORE small work** — `avra-ewei` (P2, a user `fn main`
   recurses), `avra-qx1k` (P1, a range-`for` as the last statement
   traps), `avra-ismf`, `avra-mtrh`, `avra-39bs`, `avra-o9dc`,
   `avra-3cvq`, `avra-8sb5.4.3` (opaque handles), `avra-8sb5.4.6`,
   `avra-8sb5.4.7`.
4. **SUGAR** — `avra-70jh`, never launched: sugars 3–5 (typed `rt`
   rows, emission as expression, named args), then triage `.10`/`.11`.
5. **`avra-8sb5.9.1`** — the text→int parse row (deferred; the HTTP
   lead's, not the STD master's).
6. **Filed while working, open** — `avra-8hmj` (P2, `parallel`/`race`
   collect on stop with no grace → lost child output), `avra-8sb5.18`
   (P1, `@std/process` intermittently red on a clean tree — child
   output lost, ORDER law capture-drain), `avra-8sb5.16` (P2, the build
   lock defaults to 3 slots and thrashes on a shared machine),
   `avra-7k8t` (P2, the receipt cannot name its tree on a gitless
   Sprite).
7. **Owner queue** — `avra-8sb5.8.1` ONLY: validate lane/http before it
   reaches main.

## HOW TO RUN IT

### ONE WRITER TO MAIN AT A TIME
A campaign ANNOUNCES its landing and HOLDS until the previous one is on
main. Two integrators pushing to main invalidate each other's receipts
by construction, and on a loaded host a rebase + re-seed + re-gate is
~an hour. The window is the mechanism. This includes infrastructure
commits: an out-of-turn commit to main diverges it (it happened).

### LANDING, directly (the owner's rule: no `make avra`)
A lane whose tip is based on main fast-forwards:
    git merge --ff-only lane/<x>
    git push origin main
For a lane that has diverged, reconcile first — stash the primary's
dirty docs (tracked only, never `-u`: `.claude/` and `.pi/` are
unignored and huge), `git rebase origin/main`, `git stash pop`.
`tools/integrate.sh` still exists and does the fixed-point + seed cycle,
but it runs `make avra` locally and can be outrun; the direct
fast-forward is the path the owner asked for.

### GATING
Heavy work goes to a Sprite, never the box:
    AVRA_BUILD_SLOTS=1 sh tools/sprite-build.sh avra-dev <worktree> \
        --receipt --prebuild -- make gate
`--receipt` writes the caller's `build/.gate-green` on exit 0, and
`integrate.sh` trusts a receipt only when `merge-tree main lane/<x>`
equals the receipt's tree. A pre-rebase green is not a receipt for the
rebased tree. Use the ABSOLUTE path to `tools/sprite-build.sh` (a lane's
older helper may not resolve `gate_receipt.sh`).

### THE SEED
A slice that changes compiler SOURCES must carry a refreshed
`bootstrap/seed.ll` + `bootstrap/seed.sources`, or `seed-guard` refuses
the gate. Never hand-merge a generated seed: drop the seed commit and
re-emit it (`make seed` on a Sprite, pull the pair back, commit).
`make sprite-check` says whether the seed is the tree.

## MECHANISMS NOW ON MAIN
- `tools/seed_guard.sh` — HEAD-vs-HEAD committed-seed check; falls back
  to the synced tree's own hash on a gitless Sprite and SAYS which mode
  it ran. First line of `seed-check`.
- `tools/sources_hash.sh --head` — the same file-set predicate over
  HEAD's committed bytes (the default output is unchanged).
- `tools/stems.sh` — platform-neutral symbol reader (`_*`, not `_\?`),
  and it FAILS when objects are on disk and none read back.

## SESSIONS / WORKTREES (2026-09-22)
- **STD-DATA** — `../avra-lane-sq-ffi` (idle after S2b). Did S2a/S2b.
- **COMPTIME** — `../avra-lane-comptime`; landed cache/cas. The
  comptime program's `file_names` + `Cell.push` perf win landed too.
- **FORMATTER** — `../avra-lane-fmt`.
- **DERIVE** — `../avra-derive`; **NAME-OF** — `../avra-name-of`;
  **CACHE-CAS** — `../avra-cache-cas`.
- Integrate worktrees (`avra-integrate-*`) are transient; a killed
  integrator leaves one standing.

## LESSONS THIS ARC PAID FOR
- **A cross-platform tool is witnessed on BOTH platforms**, not only the
  one the gate ran on: the Sprite is GNU sed, macOS is BSD. The `stems`
  fix shipped green on the Sprite and red on macOS.
- **The guard caught its own author**: the `seen>0/looked=0` branch
  failing is what found the `\?` bug — a check that examined nothing is
  not a check that passed.
- **A check cannot see the thing it does not compare**: `seed-check`
  compiled HEAD and never compared the hash, so J/K landed a stale seed
  silently (`avra-8sb5.17` fixed the checker; `avra-8sb5.14` fixed the
  stager).
- **A receiver's read wears the type of what is READ**, and a seat law
  is asked of the BINDING, not the name — see CLAUDE.md's register.
- **Measure before proposing**: STD-DATA's S2 measurement falsified the
  brief's premise (there was no speaking-only slice), which is why the
  ruling is DELETE rather than a smaller step.
