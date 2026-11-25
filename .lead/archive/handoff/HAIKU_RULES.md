# Lane rules (read once, obey always)

You are a lane under team-lead (the Compiler DB lead). Repo: Avra, a self-hosting compiler. Main is
github avra-lang/avra, moved ONLY by the lead through the merge queue.

## The loop: ONE task, then report, then stop
1. Do exactly the task the lead gave. Nothing else. No extra refactors, no "while I'm here".
2. Bound: ~10 minutes. If it takes longer, stop and report where you are.
3. Report with SendMessage to `team-lead`: ≤8 lines. Quote REAL output (the exact error line,
   the test count line, the commit hash copied from git output — never typed from memory).
4. End your turn. The lead replies with the next task.
5. If something surprises you, or the task seems wrong, STOP and report. Never guess at a design.
   Never invent a workaround. Never weaken a test, a law, or a refusal to make something pass.

## Never
- Never `git push --force` without `--force-with-lease`. Never push to main. Never `--no-verify`.
- Never `git stash` (worktrees share one stash). Never `rm -rf`. Never `pkill`/`killall`.
- Never rebase onto anything but `origin/main`.
- Never run a whole test suite on a Sprite (`avra test packages/<pkg>` with no file path).
  Run the named test files only.
- Never commit untracked probe scripts; `git add` named paths only.
- Never edit CLAUDE.md, settings, or another lane's worktree.

## Building and testing
- **EVERY BUILD AND TEST RUNS ON YOUR SPRITE**, via `sh tools/work run <cmd>` from inside the worktree. That is the default, not the exception — the Mac has ONE build slot and eight lanes starve on it. The Mac runs ONLY: (a) `gate_changed`/`keepers-static`/`keepers-pr` (they need `origin/main`), and (b) sub-second single-file checks (`./avra-try check <file>`). Never run `make try`, `make avra`, a package-scale `./avra`, or a test file on the Mac unless the Sprite is genuinely unavailable — and say so in your report.
- Every Mac shell: `export LLVM_PREFIX=/opt/homebrew/opt/llvm` first (manifests and the gate need it).
- `--refs origin/main` does NOT work on a Sprite (no origin/main there, exit 129): run gate_changed + keepers-pr on the Mac.
- Your worktree is your only workspace. NEVER use /Users/tristan/projects/tristanMatthias/avra (the shared primary checkout) for branches, builds or commits.
- Fast loop: `make try` builds `build/avra-try` (~5–60 s); run it as `./avra-try ...`.
- `make avra` only when told (it replaces build/avra; first `cp build/avra build/avra.pre`).
- cli tests (packages/cli/...) SPAWN `build/avra`: install your product there first
  (`cp build/avra-try build/avra` after saving the old one), or the test checks a stale compiler.
- Run one test file: `./avra-try test <path/to/x_test.av>` or a program dir `.../tests/<name>`.
- Before ANY push: `sh tools/gate_changed.sh --refs origin/main HEAD --no-keepers`, `make keepers-static` and `make keepers-pr`.
  Both must be clean. Quote their last lines in your report.
- Heavy runs on the Mac (`make try`, `make avra`, a package-scale `./avra`) queue on a machine-wide lock
  (tools/watch.sh), so just run them in the foreground; they wait their turn. Never bypass `./avra` with a bare
  `build/avra` over a whole package.
- Sprite runs: `sh tools/work run <cmd>` from inside the worktree. It is one run per Sprite.
  If it says 76 (busy), report it; do not retry in a loop.

## Code quality — the bar for EVERY PR (not just green)
- **IDIOMATIC AVRA** (see `DOGFOODING.md` + CLAUDE.md's idiom bar): comprehensions over loops; `any`/`find`/`index_of` over flag-loops; `??`/`?.`/if-null early return for absence; `it` for a one-value lambda (`xs.any(it.mark == null)`); a list's `concat` METHOD / core's free `flatten(xs)` over push-ceremony; a projection spelled ONCE (the second spelling names a verb).
- **IMPL OVER FUNCTIONAL**: a state struct's vocabulary is its impl — verbs as METHODS (`cx.accepts`, `ws.sig`, `speak`/`bind`/`mint`), never a free fn taking the state as an argument. A feature's rule body lives in the feature's own dir and reaches state through general verbs. A pass entry point keeps its one standard signature.
- **CENTRALIZED**: ONE definition of each shape, registry or dispatch. The THIRD copy of a shape names the concept and the copies die; two may wait, three never do. No parallel enums/flags for one meaning; no string tags to detect behavior.
- **A LICENSE IS AT THE SITE**, spelled `// LICENSED <id>: <law>`, never prose somewhere else. A refusal is a NAMED VOICE fn whose body is the one `spoken`/`emit` — a rule body reads as guard + verb, never assembled prose.
- **BEFORE PUSHING**: `make idioms` (ratchet) + `gate_changed.sh --refs origin/main HEAD --no-keepers` + `make keepers-static`/`keepers-pr` all clean, AND run the CHECK'S OWN SCOPE — the affected package's tests — not only the files you touched (a red check means the whole train bounces).

## Performance — the hard per-phase ratchet (applies to ALL in-flight work)
- **A HOT-PATH CHANGE QUOTES BEFORE/AFTER PER-PHASE TIMES.** `./avra build packages/cli
  --time` and a warm one-edit `check --time` print `analyze/lower/keep/emit/link`; quote
  the phase you moved, before and after. "It feels the same" is not a receipt.
- **`make speed-ratchet` is a KEEPER** (in `KEEPERS_A` and `keepers-pr`): each phase is
  held against `tools/speed.budget` and REFUSES past it, naming the phase with its
  ceiling and its measured ms. This is the HARD ratchet the soft 25% job note
  (`tools/speed_note.sh`) is not — a sum of small per-phase regressions slips under the
  note and blocks the ratchet.
- It measures on the machine it runs on; **on the Mac it uses your lane's Sprite**
  (`tools/work run`), so a loaded Mac supplies no number. A cold store SKIPS with a word —
  run `make try` once, then re-run.
- `make speed-accept` lowers a ceiling to what was measured and **never raises one**.
  Raising a ceiling is a human edit of `tools/speed.budget`, and that diff is the review.
  Never raise one to excuse a regression — fix the phase.

## Code style (the repo is strict; the gate checks)
- Comments: terse, evergreen, state the invariant. No tickets, no dates, no "now"/"fix".
- Prefer comprehensions, `any`/`find`, `??`, `?.`. A lambda over one value: `it` (`xs.any(it.mark == null)`),
  not `(s) -> s.mark == null` (rule closures.pronoun_lambda).
- New diagnostics need a golden + `docs/DIAGNOSTICS.md` entry (`./avra-try diagnostics > docs/DIAGNOSTICS.md`).

## Never sit idle on a background run
- NEVER put a command in the background and end your turn waiting for it — you may never be woken.
  Run everything in the FOREGROUND with the Bash timeout at 600000 ms (10 min).
- A Sprite run longer than that: start it with `sh tools/work run …` in the foreground anyway; if the
  Bash call times out, the run keeps going on the Sprite — read it with `timeout 590 sh tools/work attach`.
- When you finish a task, report and end your turn. The lead ALWAYS answers with the next task.

## Squashing (main moves under you)
- `git reset --soft $(git merge-base HEAD origin/main)`, commit, THEN `git rebase origin/main`.
- Compare scope with `git diff --stat origin/main...HEAD` (three dots), never `--cached origin/main` after main moved.

## Tasks CLI
- Always `export TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db` before `tasks` (without it, it tries a server).
- Probe output: the qtrace lines are `Q<TAB>…`; grep with `$(printf "^Q\t")` or `grep -P`.
- Note: Push named branches explicitly (`git push --force-with-lease origin <branch>:<branch>`), never `HEAD:<branch>`.

## Keepers must run with YOUR product as build/avra
- Before keepers-pr/gate: `make try && cp build/avra build/avra.pre && cp build/avra-try build/avra`. Keepers that
  compare generated files (rt-header, rt-ns, DIAGNOSTICS) read build/avra — an old one passes a stale tree.
- A new runtime row needs `./avra runtime-header > runtime/avra_rt.h` and `./avra runtime-namespace > packages/std-avrac/src/features/rt.av`.
- Restore build/avra from build/avra.pre only AFTER gate_changed and the keepers have run.

## Disk is tight (the Mac sits near its 2 GB build floor)
- A cache copy or scratch dir YOU made under /tmp for a measurement: `rm -r` it as soon as the measurement is done, and say so in your report. Never touch anything you did not make.
- Prefer your Sprite for heavy runs; the Mac is for gate_changed/keepers (they need origin/main) and quick checks.
- After main moves, ALWAYS build two generations before trusting a test (`make try && cp build/avra-try build/avra && make try`): a one-generation compiler can carry stale baked rule shapes (#448) and fail rules tests that main passes.
