# Formatter campaign — kickoff prompt

Paste everything below the line into a fresh session started in
`/Users/tristan/projects/tristanMatthias/avra` (main).

---

You own the FORMATTER campaign: epic `avra-8sb5.25`. Read, in order:
`CLAUDE.md` whole; `docs/2026_09_21_FORMATTER_DESIGN.md` (the design —
§2 and §2a are the spec); `docs/2026_09_21_COMPILER.md` §1–§2 (the pipeline
and the store your work rides) and §7 (every open item; §7e is yours).
Then `DOGFOODING.md`'s registry and `tools/idioms.py` — the 55 idioms and
~35 matchers you are replacing.

## The goal

One rule engine inside the compiler: layout, idiom rewrite, lint. A rule is a
`rule` DECLARATION in ordinary Avra — `quote` patterns that bind holes, arm
guards, analysed `Code` whose holes answer facts as properties, `@fixes`/
`@keeps` as tests and docs — living in its feature's directory and found by
directory, never listed. `avra fix` applies every rewrite the compiler PROVES
(IR fingerprint equal before and after) and shows the rest; `avra check`
reports the same findings with the fix attached; `--json` teaches a model from
its own diff. `tools/idioms.py`, its baseline and the hand registry die.
Design §2a lists what the language gains, in build order: arm guards, quote
patterns, analysed Code, `rule`, `@foreign` grammar marks. You have FULL
authority to change the language and any architecture; no sacred cows. Ask the
owner only where the design says OWNER'S CALL.

## How the owner works (read this twice)

- ADHD mode: lead with the action, numbered steps, ≤5 items, restate state
  every turn, no preamble or closers. Short.
- Commit as you go. Every slice: red-team + review round, gate, commit,
  `make seed`, commit the seed, `make seed-check` at HEAD. Never merge to
  main; the owner says when.
- **Delegate.** The owner said "you're too expensive": you PLAN and REVIEW,
  a Sonnet agent does the code slices. One agent per slice, in the
  foreground, in ONE worktree; never edit that worktree while its agent
  runs. Give the agent the full slice protocol below verbatim.
- Tasks live in the LOCAL db: `export TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db`,
  the `tasks` CLI. NEVER the MCP Agent Tasks tools.
- Ask every agent, at the end of its life, what it wanted from the language
  or the tools; file the answers as a comment on `avra-8sb5.11`.
- `ROADMAP.md` belongs to another session in whatever worktree you share:
  never edit or commit it.

## The machine (fragile — these are absolute)

- ONE heavy process at a time, in the FOREGROUND, under
  `sh tools/watch.sh 4000 <cmd>`. Never `build/avra` directly. The harness
  kills backgrounded gates, so run gate STEPS one by one:
  `seed-check stems vocab fingerprints rt-header witnesses externs idioms
  cited attack tested traps witness cache-attacks`.
- `cp build/avra build/avra.pre` before every rebuild; `make avra` twice
  (one generation per run). Your work is a FRONT-END change — the first
  build passes and the second is the one that reads the new grammar; a red
  second build is answered by `build/avra.pre`, never by `make bootstrap`.
  A new DSL word needs the ladder in CLAUDE.md ("A SYNTAX CHANGE TO THE
  COMPILER'S OWN SOURCE").
- Scratch probes: `build/scratch/<name>/{avra.toml,src/main.av}`,
  `./avra run build/scratch/<name>`. Never park drafts under `packages/`.
- zsh does not word-split `$var`, and an unmatched glob aborts the command.
- `git checkout -- <file>` reverts uncommitted work in that file — an agent
  lost a real edit that way. Back up with `cp`, restore with `cp`.
- A commit touching `packages/`, `runtime/` or `backend/` owes `make seed`;
  `seed-check` compares HEAD to HEAD, so run it AFTER the commit.
- `std-http`'s `client_adversarial_test.av:219` flaked once under load
  (433/434); rerun before believing it.

## Lessons from the cache campaign, for this one

1. **Probe before you draft.** Every ugly-but-safe shape in the tree came
   from fear of a trap nobody had checked. Reserved words that bit: `as`,
   `level`, `owned`. `it` binds to the NEAREST method call. `slice` clamps.
   A multi-parameter untyped lambda does not infer from its slot; a typed
   multi-param trailing-block lambda with several statements scopes its
   params over the FIRST statement only (bug — use paren-call form).
2. **The precedent for quote patterns is `features/formats`**: a STRING in
   pattern position parses and binds holes (`match b { "{x}|{y}" -> … }`),
   one anchored pass, no backtracking. Read `formats/mod.av`, `format.av`,
   `builders.av` before designing quote patterns; the `pattern` grammar
   rule is already open to features.
3. **Lossless is `fmt(x) == x`, never `fmt(fmt(x))`** — idempotence went
   green while every comment was deleted. Today's `avra fmt` drops a
   TRAILING `//` (avra-8sb5.11.112) and a `///` off a declaration is lost at
   lex (avra-8sb5.11.104); the trivia side table is where that goes.
4. **Wrong answers hide under agreement.** A spot-checked subagent claim was
   false (`writes_receiver` "does not exist" — it is in `typing/impls.av`).
   Verify every "absent"/"open" claim with a grep before it enters a doc.
5. **The keeper you replace has two surfaces.** `tools/idioms.py`'s SPECIMENS
   and CLEAN tables are its refuse/accept fixtures; every rule you port
   needs both `@fixes` and `@keeps`, or it is half a rule. Port the tables,
   then delete the tool in the same commit the last matcher moves.
6. **A hold can refuse a correct program** (COMPILER.md §7b, unreproduced):
   a type error naming a FUNCTION where a type belongs means clear
   `.avra-cache` first, then believe the error.
7. **Measure rules like everything else**: a rule's true-positive rate is
   its spec (CLAUDE.md, "A LINT COUNTS WHAT ITS DOCTRINE COUNTS"). Run each
   new rule tree-wide and read a sample before it may FIX.
8. **Names.** Every match over your own enum is a registry or a projection
   — count the answering arms (style.registry_catchall, F2040). A pass entry keeps the standard
   signature; everything else on a state struct is a method (style.free_state_verb).

## The slice protocol, for every agent (paste verbatim)

1. `./avra check packages/std-avrac` and `packages/cli`: 0 `^error` lines
   (F2047 warnings are pre-existing). Never `head`/`tail` compiler output —
   `grep -E '^error'`.
2. `python3 tools/idioms.py` ends "no new violations. debt 0". Idiomatic
   form or `// LICENSED I<n>: reason` at the site; remove a licence your
   change made untrue.
3. `cp build/avra build/avra.pre`; `sh tools/watch.sh 4000 make avra` twice.
4. `sh tools/watch.sh 4000 ./avra test packages/std-avrac` → status 0;
   `sh tools/watch.sh 4000 make cache-attacks` → `0 failed`, hold count not
   dropped (today 62 builds, 27 under a hold).
5. Commit (law-stating subject, a WHY body, trailer
   `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`);
   `make seed`; commit the seed; `make seed-check` says "compiles HEAD".
6. Red twice → revert your files one by one, restore `build/avra.pre`, move
   on, report the exact error.

## First slices (each its own agent)

1. **Arm guards** — `pattern if cond -> value` in `match` (features/enums
   owns `arm`). Grammar + typing + lowering + a program test + the
   `formats` string pattern gets it free. Sweep the tree's `if` bodies that
   are guards.
2. **`quote` in pattern position** — holes bind (`Code`), `${..xs}` a run,
   same name twice = same fingerprint, match over nodes never text. Needs
   the ladder (the compiler's own source carries quotes).
3. **Analysed `Code`** — a bound hole's facts as properties (`x.pure`,
   `x.type`, `e.type.is_registry`), answered from the store and keyed as
   query dependencies.
4. **`rule`** — the declaration, `Fix`, `@fixes`/`@keeps` checked at
   assembly, rules found by directory, `avra fix` with span-splice edits
   and the IR-equality gate. Port the first ten matchers.
5. Then the rest of `tools/idioms.py`, `--json`, `@foreign`, the derived
   printer (design §10).

Start by reading the four docs, then write the plan for slice 1 as a task
under `avra-8sb5.25` and hand it to a Sonnet agent.
