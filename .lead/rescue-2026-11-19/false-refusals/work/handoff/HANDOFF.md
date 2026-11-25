# Handoff — lane `avra-lane-parity-false-refusals`

## Lane and scope

The Avra compiler's PROGRAM LAYER and its parity with the old path, in `/work/avra`, branch
`avra-lane-parity-false-refusals`. The lane owns false refusals and missing refusals between the
two paths, plus flow, tasks and channels engine defects (the lead assigned these to the lane).

Rules the lead set, kept verbatim in spirit:
- Push nowhere: no `git push` and no `gh`. Never print or forward a credential or token.
- No `rm` in commands (use `find … -delete`). No `git stash`, no `git reset --hard`, no `--no-verify`.
- Run `build/avra-try fmt --write <files>` on touched `.av` files before committing. The formatter
  sometimes needs a second pass; run `fmt --check` after it.
- Never silence a law to pass a case: fix the judgment. One definition per law or voice.
- A gate red that isn't from your own commits is REPORTED to the lead, never fixed by you.
- Post to the lead only at a bundle, a blocker or a ruling, in at most 12 lines.
- The gate reads the WORKING TREE: never edit sources while it runs.

## Base

- Branch is on **batch53** (`d5062c3274`, "Merge remote-tracking branch 'ui/r3' into program-land-53").
- **batch55** (`912fc732d7`) was fetched as ref `batch55`. It contains batch53 and NONE of the
  commits below. The lead says to base new work on the newest batch bundle, so rebase onto batch55
  next. Expect conflicts only in `tools/gate/std-avrac.names` and the Seating match lists in
  `compiler/item_refused.av`; resolve them as unions, as before.
- Each bundle's prerequisite is `d750dfa7`.

## Commits ahead of batch53 (oldest first), NOT yet sent to the lead

The lead is waiting for these as `batch53..HEAD`, for batch 54.

| sha | what |
|---|---|
| 31b50976b | program layer: a `collect enum E: T` names a trait, and every member implements it (2 laws; 4 pins removed) |
| 36395d0a8 | program layer: a `produce`/`channel` capacity that is no `int` says so in the old path's words (`Seating.Capacity`, law `capacity_mismatch`, voice `capacity_unint`; 1 pin removed) |
| 935e69727 | engine (a1): `avra_guard_run` is a cancel point (`waits: true`), so a cut `contained` body unwinds to its `within` |
| 5ab319d1a | std-task (d): `next()` takes a value left in `handed`, whoever's claim left it |
| 067134e8f | select (e): taking an arm cancels each task a head made that still runs; a list literal of spawns in a head counts as made there (layer `lowers.av` and old `lower.av`) |
| 1dd870e10 | engine (c, a2, b): the evaluator's tick obeys the shield; a caught trap ends the `within`s its body opened; evaluator guards are per task |

Program tests added in `packages/std-time/src/tests/`: `deferred_whole`, `contained_cut`,
`contained_trap_within`, `contained_interleaved`, `next_after_claim`, `select_head_cancelled`.

**Gate on 1dd870e1**, in `/tmp/claude-0/gate17.log`:
- PASS: `make try`, `fmt --check` (19 files, 0 differing), idioms 0 new.
- PASS: all 39 `std-time` and `std-task` program tests, in both evaluator and native.
- PASS: gate avrac-a to g, all 0 failed.
- PASS: `check std-avrac` exit 0, cli build (`AVRA_PROGRAM_NET=0`) exit 0.
- NOT FINISHED when the budget ran out: `witness_program_refusal` and `witness_program_runs`.
  Re-run these two before sending, or the whole receipt set after the rebase onto batch55.

## In flight

Nothing is uncommitted; the tree was clean at handoff. Work investigated but not started:

**Scope-join fix**. Ruling: "nothing outlives its scope". Every task a scope made is joined at
each of that scope's exits, a normal end included, never only released.
- Cause, found by reading only: `features/block/lowers.av` has a shortcut. A block holding only its
  tail (`lead.is_empty()`) lowers the tail with no `opened()`/`closed()`. So `owns()` of a `select`
  head files its `Ending.Joined` in the body's BASE endings frame (`core/lowering.av:513`).
- That frame is ended only by unwinding exits (`unwound_exit`/`answer_exit` → `ended_from(0, …)`).
  The normal end in `compiler/item_lowered.av` `signed_lowered` (~line 313–320) only does
  `scope_exit(r)` and `RetVal(r)`. The task handle is merely released, and `avra_task_release`
  joins only if it holds the last handle, which a filed waiter can prevent.
- Planned fix: add a helper in `core/endings.av`, e.g. `body_ended(r)`, that ends frame 0's
  endings with `Leaving.Answering(r)` and clears it. Call it before `RetVal` in `signed_lowered`
  and in `core/closures.av` (after `if framed { body.closed() }`). Check the other
  `RetVal` sites in `compiler/item_lowered.av` (state, collect and enum bodies) and
  `core/dyn_boxes.av`.
- Repro: `/work/q3run/eprobe4` (a fn whose body is a lone `select`; `avra-try ir .` shows the
  normal exit has only `release`, no `avra_task_settle`) and `/work/q3run/eprobe3`.
- Then: add a program test that reads at once, with no 50 ms wait, passing in both engines. Remove
  the `sleep(ms(50))` in `std-time/src/tests/select_head_cancelled` once joins hold. Fix the
  wording in `docs/2026_10_05_CHANNELS.md` §5.2 (around line 733): replace "It is never joined"
  with "cancelled when the select is left, and joined by its scope like any task".

## Next 3 items, in order

1. Re-run the two witnesses on HEAD (or the full receipts). Bundle `batch53..HEAD`, send it with
   `send_files`, and post the receipts. If the lead now wants it on batch55, rebase first.
2. Rebase onto batch55. Do the scope-join fix above as its own commit, with a test and the docs
   wording.
3. On batch55, update the `flow.no_fate` help as its own small commit. The voice is `fate_unnamed`
   in `packages/std-avrac/src/features/components/check.av:287`; its help says
   ``name the letter a failed item is buried in — `dead: <sink>` ``. In batch55 (services slice
   17) the worker takes the letter queue itself, so change the help to the current form, e.g.
   `dead: undeliverable`, after checking the worker's `dead` field type in batch55's
   `std-queue/src/queue.av`. Also update its golden: the remedy row at
   `compiler/dev/remedies.av` ~602 (its `applied` writes `dead: "letter"`) and any spec asserting
   the help text.

After those, from the lead's earlier list: type.lacks (3 programs), type.embed_literal (1),
type.guard_value (1), language.defect (1). They are rows of `/work/package-245.tsv`: 207–209,
147, 146 and 174.

## Open rulings and asks

- RULED (e): cancel on leaving the select AND join at the enclosing scope. The CHANNELS 5.2
  wording is to be fixed (item 2 above).
- WITHDRAWN: `then` as a field name. Every path refuses it alike; drop it.
- Told to the lead, no action pending:
  - A collect-enum member declared in ANOTHER file than its enum (package scope) is refused at the
    enum, not at its own declaration: a law finding can't land in another file.
  - n13–n16 spec-harness `@std/task` stand-in problem, sent to the spec-harness lane via the lead.

## Things a fresh session would trip on

- Environment: `source /etc/profile.d/avra.sh` before builds.
- Build with `make try`, which produces `build/avra-try`; test with it. `build/avra` is the older
  binary the gate scripts use; it was last built at 01:24 and predates today's runtime changes.
- Gate and receipt commands, exactly as run (see `/work/handoff/receipts.sh`):
  - `sh tools/gate.sh avrac-a` … `avrac-g`
  - `AVRA_PROGRAM=1 build/avra check packages/std-avrac`
  - `AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 build/avra build packages/cli`
  - `sh tools/witness_program_refusal.sh build/avra`
  - `sh tools/witness_program_runs.sh`
  - `AVRA_MEM_CEILING_MB=12000 build/avra check packages/cli --baseline tools/idioms.baseline`
    (idioms; must report 0 NEW)
  - `build/avra fmt --check $(git diff --name-only <base>..HEAD -- '*.av')`
  - Program tests: `build/avra-try tapes packages/std-time --program-runs [--only src/tests/<name>] [--left]`
- Pin list: `tools/gate/std-avrac.names` lists cases the layer fails. It ONLY SHRINKS: remove a pin
  when its case passes, and keep the header comments accurate.
- Probing a spec: write a temporary `zz_*_test.av` beside the tests (a `spec "…" { given … { then … } }`
  block). Old-path diagnostics come from
  `h.old_program(h.standing("app","src/main.av"))` → `flatten([a.diagnostics for a in p.files]).concat(p.voices).concat(p.defects)`;
  the layer's from `h.judged_at(path)`. Delete the probe afterwards with `find … -delete`.
- Scratch: `/work/q3run/` holds the repro copies and probes (`engine_repros/`, `eprobe*`).
  `/work/q3repro/engine_repros/` holds the reporter's originals, each with a `REPRO.txt`.
- Backup branches: `backup-pre45`, `backup-pre45c`, `backup-pre51`, `backup-pre53` (states before
  each rebase).
- Bridge: `mcp__claude-bridge__post_to_controller` and `send_files`. The new account will give a
  new session token.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` plus the
  `Claude-Session` line for the new session.
